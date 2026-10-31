extends Control
## Mäter flimmer när kameran rör sig: tar en bild, flyttar kameran en bråkdel av en pixel
## och tar en till. Vanlig rörelse ändrar bara kanterna lite; z-fighting och linjer som
## blinkar byter färg helt. Pixlar som ändras mer än THRESHOLD räknas. Körs med:
##   Godot --path . res://tools/flicker_test.tscn -- <utmapp> [våning ...]
## Skriver en bild per våning där de hoppande pixlarna är röda.

const THRESHOLD := 0.25
## Hur långt kameran flyttas mellan bilderna (meter), och hur många steg.
const NUDGE := 0.004
const STEPS := 4

var _view: HouseView3D


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("flicker")
	DirAccess.make_dir_recursive_absolute(out)
	var floors: Array = Array(args.slice(1))
	if floors.is_empty():
		floors = PlanDrawer.FLOOR_PLANS.keys()
	_view = HouseView3D.new()
	add_child(_view)
	var total := 0
	for floor_name: String in floors:
		_view.show_floor(floor_name)
		_view.settle_lighting()
		_view.focus_overview()
		await _frames(60)
		_freeze()
		if OS.has_environment("FLICKER_FIND"):
			var v := OS.get_environment("FLICKER_FIND").split_floats(",")
			await _find(Rect2i(int(v[0]), int(v[1]), int(v[2] - v[0]), int(v[3] - v[1])))
			continue
		var before := await _shot()
		var marked := before.duplicate() as Image
		before.save_png(out.path_join("%s_raw.png" % floor_name))
		var count := 0
		for step in STEPS:
			_view._pan += Vector3(NUDGE, 0, NUDGE * 0.5)
			var after := await _shot()
			count += _compare(before, after, marked)
			before = after
		total += count
		print("%-12s %6d" % [floor_name, count])
		marked.save_png(out.path_join("%s.png" % floor_name))
	print("flicker_test: %d totalt" % total)
	get_tree().quit()


## Stänger av det som rör sig av sig självt (damm, gardiner, andning), så att bara
## kamerans rörelse syns.
func _freeze() -> void:
	# Skyltarna avrundas till hela pixlar och hoppar därför med flit.
	_view._labels.visible = false
	if OS.has_environment("FLICKER_NOINK"):
		_view._ink.set_shader_parameter("strength", 0.0)
	if OS.has_environment("FLICKER_MSAA8"):
		_view._viewport.msaa_3d = Viewport.MSAA_8X
	if OS.has_environment("FLICKER_NOSHADOW"):
		_view._rig.sun.shadow_enabled = false
	for node in _view.find_children("*", "", true, false):
		if node is GPUParticles3D or node is CPUParticles3D:
			node.visible = false
		elif node is TimeOfDayRig or node is AnimationPlayer:
			node.process_mode = Node.PROCESS_MODE_DISABLED
	for tween in get_tree().get_processed_tweens():
		tween.pause()


## Letar upp maskan som flimrar inom `region` (FLICKER_FIND="x0,y0,x1,y1"): döljer
## grupper av maskor och går ned i den grupp som tar bort flest hoppande pixlar.
func _find(region: Rect2i) -> void:
	var meshes: Array = _view._floor_root.find_children("*", "MeshInstance3D", true, false).filter(func(m: Node) -> bool: return m.visible)
	print("find: %d maskor, %d hoppande pixlar" % [meshes.size(), await _jumps(region, [])])
	while meshes.size() > 1:
		var half: Array = meshes.slice(0, meshes.size() / 2)
		var rest: Array = meshes.slice(meshes.size() / 2)
		var a := await _jumps(region, half)
		var b := await _jumps(region, rest)
		meshes = half if a < b else rest
		print("find: %d kvar (%d / %d)" % [meshes.size(), a, b])
	var m: MeshInstance3D = meshes[0]
	print("find: %s  mesh %s  aabb %s  parent %s" % [m.get_path(), m.mesh, m.global_transform * m.mesh.get_aabb(), m.get_parent().name])


## Hoppande pixlar inom `region` när `hidden` är dolda.
func _jumps(region: Rect2i, hidden: Array) -> int:
	for m: Node3D in hidden:
		m.visible = false
	var pan: Vector3 = _view._pan
	var a := await _shot()
	_view._pan += Vector3(NUDGE, 0, NUDGE * 0.5)
	var b := await _shot()
	_view._pan = pan
	for m: Node3D in hidden:
		m.visible = true
	var count := 0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if maxf(absf(ca.r - cb.r), maxf(absf(ca.g - cb.g), absf(ca.b - cb.b))) > THRESHOLD * 0.3:
				count += 1
	return count


func _shot() -> Image:
	await _frames(3)
	return get_viewport().get_texture().get_image()


func _compare(a: Image, b: Image, marked: Image) -> int:
	var count := 0
	for y in a.get_height():
		for x in a.get_width():
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if maxf(absf(ca.r - cb.r), maxf(absf(ca.g - cb.g), absf(ca.b - cb.b))) > THRESHOLD:
				count += 1
				marked.set_pixel(x, y, Color.RED)
	return count


func _frames(count: int) -> void:
	for i in count:
		await RenderingServer.frame_post_draw
