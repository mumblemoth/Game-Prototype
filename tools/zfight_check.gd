extends Node
## Letar efter ytor som ligger i samma plan och täcker varandra (z-fighting): de flimrar
## när kameran rör sig, eftersom djupbufferten inte kan avgöra vilken som ligger närmast.
## Ytor med olika depth_rank (se StyleKit.depth_rank) räknas inte: där vinner den mindre.
## Bygger varje våning i HouseView3D och jämför alla raka lådors, cylindrars och plans
## sidor i världskoordinater. Körs med:
##   Godot --headless --path . res://tools/zfight_check.tscn [-- våning ...]

## Två sidor räknas som samma plan om de ligger närmare än så här (meter).
const PLANE_EPS := 0.0003
## Minsta överlapp (m²) som räknas; mindre än så syns inte.
const MIN_OVERLAP := 0.0004
## Så här stor skillnad i depth_rank räcker för att djupbufferten ska välja säkert.
const MIN_RANK_GAP := 0.25


func _ready() -> void:
	var floors: Array = Array(OS.get_cmdline_user_args())
	if floors.is_empty():
		floors = PlanDrawer.FLOOR_PLANS.keys()
	var view := HouseView3D.new()
	add_child(view)
	await get_tree().process_frame
	var total := 0
	for floor_name: String in floors:
		view.show_floor(floor_name)
		await get_tree().process_frame
		var hits := _check(view)
		total += hits.size()
		print("== %s: %d" % [floor_name, hits.size()])
		for line in hits:
			print("   ", line)
	print("zfight_check: %d par totalt" % total)
	get_tree().quit()


func _check(view: Node) -> Array[String]:
	var faces: Array = []
	for node in view.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if not mi.is_visible_in_tree() or mi.mesh == null:
			continue
		faces.append_array(_faces(mi))
	# Sortera per (axel, riktning, plan) så att bara grannar behöver jämföras.
	faces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["key"] != b["key"]:
			return a["key"] < b["key"]
		return a["plane"] < b["plane"])
	var hits: Array[String] = []
	var seen := {}
	for i in faces.size():
		var a: Dictionary = faces[i]
		for j in range(i + 1, faces.size()):
			var b: Dictionary = faces[j]
			if b["key"] != a["key"] or b["plane"] - a["plane"] > PLANE_EPS:
				break
			if a["mi"] == b["mi"] or a["color"].is_equal_approx(b["color"]):
				continue
			# Olika rang (toon.gdshader) avgör vem som vinner; bara lika rang flimrar.
			if absf(_rank(a["mi"]) - _rank(b["mi"])) >= MIN_RANK_GAP:
				continue
			var overlap: Rect2 = (a["rect"] as Rect2).intersection(b["rect"])
			if overlap.get_area() < MIN_OVERLAP:
				continue
			var pair := "%s|%s" % [_path(a["mi"]), _path(b["mi"])]
			if seen.has(pair):
				continue
			seen[pair] = true
			hits.append("%s %s @%.3f  %.4f m²  at %s  %s %s  <>  %s %s" % ["xyz"[a["axis"]], "+" if a["dir"] > 0 else "-", a["plane"], overlap.get_area(), overlap.get_center(), _path(a["mi"]), _size(a["mi"]), _path(b["mi"]), _size(b["mi"])])
	return hits


## En maskas plana sidor i världen: {key, axis, dir, plane, rect, color, mi}. Bara maskor
## som står rakt (vridna i hela kvartsvarv) tas med.
func _faces(mi: MeshInstance3D) -> Array:
	var xf := mi.global_transform
	if not _axis_aligned(xf.basis):
		return []
	var aabb: AABB = xf * mi.mesh.get_aabb()
	var local_axes: Array[int] = []
	if mi.mesh is BoxMesh or mi.mesh is ArrayMesh:
		local_axes = [0, 1, 2]
	elif mi.mesh is CylinderMesh:
		local_axes = [1]
	elif mi.mesh is PlaneMesh:
		local_axes = [[0, 1, 2][(mi.mesh as PlaneMesh).orientation]]
	elif mi.mesh is QuadMesh:
		local_axes = [2]
	else:
		return []
	var out: Array = []
	var color := _color(mi)
	for local_axis in local_axes:
		var world := xf.basis[local_axis].abs()
		var axis := 0 if world.x > 0.5 else (1 if world.y > 0.5 else 2)
		var u := (axis + 1) % 3
		var v := (axis + 2) % 3
		var rect := Rect2(aabb.position[u], aabb.position[v], aabb.size[u], aabb.size[v])
		var dirs := [1, -1]
		if mi.mesh is PlaneMesh or mi.mesh is QuadMesh:
			dirs = [1 if xf.basis[local_axis][axis] > 0 else -1]
		for d: int in dirs:
			# Kameran tittar alltid snett ner från söder: sidor mot norr och nedåt syns aldrig.
			if (axis == 1 or axis == 2) and d < 0:
				continue
			var plane: float = aabb.end[axis] if d > 0 else aabb.position[axis]
			out.append({"key": axis * 2 + (1 if d > 0 else 0), "axis": axis, "dir": d, "plane": plane, "rect": rect, "color": color, "mi": mi})
	return out


func _rank(mi: MeshInstance3D) -> float:
	var r: Variant = mi.get_instance_shader_parameter("depth_rank")
	return r if r != null else 0.0


func _axis_aligned(basis: Basis) -> bool:
	for i in 3:
		var c := basis[i].normalized().abs()
		if maxf(c.x, maxf(c.y, c.z)) < 0.999:
			return false
	return true


func _color(mi: MeshInstance3D) -> Color:
	var m := mi.material_override
	if m == null and mi.mesh.get_surface_count() > 0:
		m = mi.mesh.surface_get_material(0)
	if m is ShaderMaterial:
		var c: Variant = (m as ShaderMaterial).get_shader_parameter("albedo")
		return c if c is Color else Color(randf(), randf(), randf())
	if m is StandardMaterial3D:
		return (m as StandardMaterial3D).albedo_color
	return Color(randf(), randf(), randf())


func _size(mi: MeshInstance3D) -> String:
	var s := mi.mesh.get_aabb().size
	return "(%.3f %.3f %.3f)" % [s.x, s.y, s.z]


func _path(mi: MeshInstance3D) -> String:
	var parts: PackedStringArray = []
	var n: Node = mi
	while n and not (n is SubViewport):
		var kind: Variant = n.get_meta("kind") if n.has_meta("kind") else null
		parts.insert(0, "%s%s" % [n.name, "(%s)" % kind if kind else ""])
		n = n.get_parent()
	return "/".join(parts.slice(2))
