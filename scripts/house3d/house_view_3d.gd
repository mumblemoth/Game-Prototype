class_name HouseView3D
extends SubViewportContainer
## Husets planvy i 3D, en våning i taget: rummen byggs med StyleKit och FurnitureKit,
## ljuset följer tidszonen (TimeOfDayRig) och kameran ser in snett ovanifrån som i ett
## dockhus. Man klickar på rummen som förut; kameran glider in mot rummet man valt.
## Rummens namn står som skyltar ovanför golvet, rummet under musen och rummet mamman
## är i markeras på golvet, och familjen står i rummen enligt sina scheman. Mamman
## visas som sin bild (AppearanceData), de andra som enkla figurer tills bilder finns.
## Klick och rörelse skickas vidare som signaler; house.gd sköter menyer och tid.

signal room_hovered(room_id: String)
signal room_clicked(room_id: String)

const FOV := 38.0
## Kamerans riktning från det den tittar på: snett ovanifrån, söderifrån.
const VIEW_DIRECTION := Vector3(0, 0.66, 0.75)
const GLIDE_SECONDS := 0.55
## Skärmytan som inte täcks av HUD:en (våningsknappar till vänster, textruta nedtill).
## Kameran centrerar huset här i stället för mitt på skärmen.
const VIEW_AREA := Rect2(230, 80, 1030, 520)
const LABEL_BG := Color(0.98, 0.95, 0.9, 0.92)
const LABEL_BORDER := Color(0.45, 0.32, 0.22, 0.8)
const LABEL_TEXT := Color(0.33, 0.22, 0.14)
const HOVER_TINT := Color(1.0, 1.0, 1.0, 0.22)
const CURRENT_TINT := Color(1.0, 0.82, 0.45, 0.2)
## Mammans bild är så här hög i rummet (meter).
const MOM_HEIGHT := 1.68
## Var diset och tuschlinjernas bleknande börjar och slutar, i meter bortom det kameran
## tittar på (följer zoomen).
const FOG_BEGIN := 6.0
const FOG_END := 42.0
const INK_FADE_BEGIN := 4.0
const INK_FADE_END := 28.0
## Panorering med WASD: farten är en andel av kamerans avstånd per sekund (samma känsla
## inzoomad som i översikten), och hur snabbt farten når målet (högre = kvickare).
const PAN_SPEED := 0.85
const PAN_RESPONSE := 12.0
## Hur långt (meter) mitten av bilden får gå utanför platsens rum innan den stannar.
## Husets våningar får titta lite ut genom väggarna, tomten och de stora platserna
## lite mer; allt bortom det är kulisser som inte är byggda för att ses på nära håll.
const PAN_MARGIN_DEFAULT := 1.5
const PAN_MARGINS := {
	"Vind": 1.0,
	"Övervåning": 2.0,
	"Entréplan": 2.0,
	"Källare": 1.0,
	"Utanför": 2.5,
	"Gymmet": 2.0,
	"Köpcentret": 2.0,
	"Skolan": 1.5,
	"Grannen": 1.0,
	"Parken": 3.0,
}
const PAN_KEYS := {KEY_W: Vector2(0, -1), KEY_S: Vector2(0, 1), KEY_A: Vector2(-1, 0), KEY_D: Vector2(1, 0)}
## Saker man kan stå på när figurerna placeras ut.
const WALKABLE := ["rug", "field_rug", "path", "patio", "driveway", "gym_mat", "poster", "pennant", "photo_wall", "whiteboard", "mirror_wall", "entry_mat", "rubber_floor", "turf"]

var floor_name := ""
var current_room := ""
var hover_room := ""
var _viewport: SubViewport
var _camera: Camera3D
var _ink: ShaderMaterial
var _floor_root: Node3D
var _rig: TimeOfDayRig
var _plans := {}
var _room_nodes := {}
## Fönstren med gardiner per rum (HouseWindow), som följer Curtains.
var _windows := {}
var _overlays := {}
var _people: Node3D
## Mammans bild och hunden som de står just nu (för aktiviteternas animationer).
var _mom: Node3D
var _dog: Node3D
var _labels: Control
var _labels_tween: Tween
## Skyltar i 2D som följer punkter i 3D: [{node: Control, at: Vector3}].
var _tags: Array[Dictionary] = []
var _target := Vector3.ZERO
var _distance := 15.0
var _overview_target := Vector3.ZERO
var _overview_distance := 15.0
var _glide: Tween
## Spelarens panorering ovanpå det kameran glider mot (bara x och z), farten den har
## just nu och rutan (x, z) som mitten av bilden måste hålla sig inom på våningen.
var _pan := Vector3.ZERO
var _pan_velocity := Vector2.ZERO
var _pan_bounds := Rect2()
## Sätts av house.gd: får spelaren panorera just nu (inga menyer eller scener öppna)?
var can_pan := Callable()


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_viewport = SubViewport.new()
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_SMAA
	_viewport.positional_shadow_atlas_size = 4096
	add_child(_viewport)
	_camera = Camera3D.new()
	_camera.fov = FOV
	_viewport.add_child(_camera)
	_ink = StyleKit.add_ink_outline(_camera)
	_labels = Control.new()
	_labels.set_anchors_preset(Control.PRESET_FULL_RECT)
	_labels.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	# Skyltarna ritas i ett eget lager ovanpå 3D-bilden (men under menyer och HUD).
	get_parent().add_child.call_deferred(_labels)
	gui_input.connect(_on_input)
	mouse_exited.connect(func() -> void: _set_hover(""))
	GameState.time_of_day_changed.connect(func(_period: String) -> void:
		refresh_people()
		refresh_curtains()
		Backyard.refresh_plants(get_tree()))
	GameState.appearance_changed.connect(refresh_people)
	GameState.schedules_changed.connect(refresh_people)
	GameState.schedules_changed.connect(refresh_curtains)


func _process(delta: float) -> void:
	_update_pan(delta)
	var aim := _target + _pan
	_camera.position = aim + VIEW_DIRECTION.normalized() * _distance
	_camera.look_at(aim)
	if _rig:
		_rig.environment.fog_depth_begin = _distance + FOG_BEGIN
		_rig.environment.fog_depth_end = _distance + FOG_END
	_ink.set_shader_parameter("fade_begin", _distance + INK_FADE_BEGIN)
	_ink.set_shader_parameter("fade_end", _distance + INK_FADE_END)
	for tag in _tags:
		var node: Control = tag["node"]
		var at: Vector3 = tag["at"]
		node.visible = not _camera.is_position_behind(at)
		node.position = (_camera.unproject_position(at) - node.size / 2).round()


# --- Våningen -----------------------------------------------------------------

## Bygger en våning (om det inte redan är den som visas) och ställer kameran över den.
func show_floor(new_floor: String) -> void:
	if new_floor == floor_name:
		return
	floor_name = new_floor
	if _floor_root:
		_floor_root.free()
	_tags.clear()
	for child in _labels.get_children():
		child.free()
	_room_nodes.clear()
	_windows.clear()
	_overlays.clear()
	_plans = PlanDrawer.FLOOR_PLANS[floor_name]
	_floor_root = Node3D.new()
	_viewport.add_child(_floor_root)
	_rig = TimeOfDayRig.new()
	_rig.environment.fog_enabled = true
	_floor_root.add_child(_rig)
	# Omgivningen syns genom fönstren, så ingen målad utsikt; ytterväggarna får fasad.
	StyleKit.painted_views = false
	StyleKit.siding = Surroundings.facade(floor_name)
	for room_id in _plans:
		var room := Node3D.new()
		room.name = room_id
		_floor_root.add_child(room)
		_room_nodes[room_id] = room
		var plan: Rect2 = _plans[room_id]
		StyleKit.build_room_shell(room, _rig, _plans, room_id, GameState.get_exits(room_id))
		FurnitureKit.furnish(room, _rig, room_id, plan, _plans)
		FurnitureKit.decorate(room, _rig, room_id, plan)
		_overlays[room_id] = _floor_overlay(room, plan)
		_add_room_tag(room_id, plan)
		var curtained := room.get_children().filter(func(child: Node) -> bool: return child is HouseWindow and child.has_curtains())
		if not curtained.is_empty():
			_windows[room_id] = curtained
	Surroundings.build(_floor_root, _rig, floor_name)
	_people = Node3D.new()
	_floor_root.add_child(_people)
	refresh_people()
	refresh_curtains(false)
	_update_overlays()
	_frame_floor()
	_target = _overview_target
	_distance = _overview_distance
	_pan = Vector3.ZERO
	_pan_velocity = Vector2.ZERO
	# Takens skuggor håller solen ute ur rummen; de måste nå hela våningen även när
	# kameran står långt bort över en stor plats (köpcentret), annars blir rummen solbelysta.
	_rig.sun.directional_shadow_max_distance = maxf(_rig.sun.directional_shadow_max_distance, _overview_distance + 20.0)


## Hoppar över ljusets övergång till tidszonen (t.ex. för skärmbilder).
func settle_lighting() -> void:
	if _rig:
		_rig.set_period(_rig.period)


## Drar gardinerna på våningen till det läge Curtains säger (efter tid, vem som är var
## och mammans egna val). Utan `animate` hoppar de dit direkt (när våningen byggs).
func refresh_curtains(animate := true) -> void:
	for room_id in _windows:
		for window: HouseWindow in _windows[room_id]:
			window.set_curtains(Curtains.state_for(room_id, window.spec["default"]), animate)


## Ett genomskinligt lager på golvet som visar rummet under musen och mammans rum.
func _floor_overlay(room: Node3D, plan: Rect2) -> MeshInstance3D:
	var quad := PlaneMesh.new()
	quad.size = plan.size
	var overlay := MeshInstance3D.new()
	overlay.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay.material_override = material
	overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	overlay.position = Vector3(plan.get_center().x, 0.02, plan.get_center().y)
	overlay.visible = false
	room.add_child(overlay)
	return overlay


func _update_overlays() -> void:
	for room_id in _overlays:
		var overlay: MeshInstance3D = _overlays[room_id]
		var tint := Color(0, 0, 0, 0)
		if room_id == hover_room:
			tint = HOVER_TINT
		elif room_id == current_room:
			tint = CURRENT_TINT
		overlay.visible = tint.a > 0
		(overlay.material_override as StandardMaterial3D).albedo_color = tint
	for tag in _tags:
		if tag.has("room"):
			var here: bool = tag["room"] == current_room
			(tag["here"] as Label).visible = here


## Kamerans översikt: hela våningen inom den del av skärmen som HUD:en inte täcker.
func _frame_floor() -> void:
	var outer := Rect2()
	var first := true
	for room_id in _plans:
		outer = _plans[room_id] if first else outer.merge(_plans[room_id])
		first = false
	# Lite extra avstånd: den närmaste kanten ser bredare ut i perspektiv.
	_overview_distance = _fit_distance(outer.size, 0.8) * 1.12
	_pan_bounds = outer.grow(PAN_MARGINS.get(floor_name, PAN_MARGIN_DEFAULT))
	_overview_target = Vector3(outer.get_center().x, 0.3, outer.get_center().y + 0.3) - _area_offset(_overview_distance)


## Avståndet där en yta (meter) får plats i VIEW_AREA, med lite luft runt omkring.
func _fit_distance(size: Vector2, margin: float) -> float:
	var half_v := tan(deg_to_rad(FOV / 2.0))
	var half_h := half_v * 1280.0 / 720.0
	var tilt := VIEW_DIRECTION.normalized().y
	var by_width := (size.x + margin) / 2.0 / (half_h * VIEW_AREA.size.x / 1280.0)
	var by_depth := ((size.y + margin) * tilt + StyleKit.WALL_HEIGHT * 0.8) / 2.0 / (half_v * VIEW_AREA.size.y / 720.0)
	return maxf(by_width, by_depth)


## Hur långt (i världen) kameran ska förskjutas för att det den tittar på hamnar mitt
## i VIEW_AREA i stället för mitt på skärmen.
func _area_offset(distance: float) -> Vector3:
	var meters_per_pixel := 2.0 * distance * tan(deg_to_rad(FOV / 2.0)) / 720.0
	var shift := VIEW_AREA.get_center() - Vector2(640, 360)
	var tilt := VIEW_DIRECTION.normalized().y
	return Vector3(shift.x * meters_per_pixel, 0, shift.y * meters_per_pixel / maxf(tilt, 0.3))


# --- Kameran ------------------------------------------------------------------

## Kameran glider in mot ett rum.
func focus_room(room_id: String) -> void:
	if not _plans.has(room_id):
		return
	var plan: Rect2 = _plans[room_id]
	_glide_to(Vector3(plan.get_center().x, 0.4, plan.get_center().y + 0.2), maxf(_fit_distance(plan.size, 1.4) * 0.9, 6.0))
	# Skyltarna tonas bort medan rummets meny ligger över planen.
	_fade_labels(0.0)


## Kameran glider tillbaka till hela våningen.
func focus_overview() -> void:
	_glide_to(_overview_target, _overview_distance)
	_fade_labels(1.0)


func _fade_labels(alpha: float) -> void:
	if _labels_tween:
		_labels_tween.kill()
	_labels_tween = create_tween()
	_labels_tween.tween_property(_labels, "modulate:a", alpha, GLIDE_SECONDS * 0.5)


## Panoreringen glider tillbaka till noll samtidigt, så att rummet hamnar mitt i bild.
func _glide_to(target: Vector3, distance: float) -> void:
	if _glide:
		_glide.kill()
	_pan_velocity = Vector2.ZERO
	_glide = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_glide.tween_property(self, "_target", target, GLIDE_SECONDS)
	_glide.tween_property(self, "_distance", distance, GLIDE_SECONDS)
	_glide.tween_property(self, "_pan", Vector3.ZERO, GLIDE_SECONDS)


## WASD flyttar kameran längs marken (W bort mot norr, S mot söder, A väster, D öster).
## Farten mjukas upp åt båda hållen och mitten av bilden hålls inom våningens ruta.
## Medan kameran glider mot ett rum väntar panoreringen.
func _update_pan(delta: float) -> void:
	var wanted := Vector2.ZERO
	var gliding := _glide != null and _glide.is_running()
	if not gliding and _pan_allowed():
		for key in PAN_KEYS:
			if Input.is_physical_key_pressed(key):
				wanted += PAN_KEYS[key]
	wanted = wanted.normalized() * PAN_SPEED * _distance
	_pan_velocity = _pan_velocity.lerp(wanted, 1.0 - exp(-PAN_RESPONSE * delta))
	if _pan_velocity.length_squared() < 0.0001:
		_pan_velocity = Vector2.ZERO
		return
	_pan += Vector3(_pan_velocity.x, 0, _pan_velocity.y) * delta
	# Mitten av den synliga ytan (inte skärmens mitt) får inte lämna rutan.
	var center := _target + _pan + _area_offset(_distance)
	var clamped := Vector2(clampf(center.x, _pan_bounds.position.x, _pan_bounds.end.x), clampf(center.z, _pan_bounds.position.y, _pan_bounds.end.y))
	if clamped.x != center.x:
		_pan.x += clamped.x - center.x
		_pan_velocity.x = 0.0
	if clamped.y != center.z:
		_pan.z += clamped.y - center.z
		_pan_velocity.y = 0.0
	# Rummet under musen byts när golvet glider förbi under den.
	var mouse := get_local_mouse_position()
	if Rect2(Vector2.ZERO, size).has_point(mouse):
		_set_hover(room_at(mouse))


func _pan_allowed() -> bool:
	if not is_visible_in_tree() or _pan_bounds.size == Vector2.ZERO:
		return false
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_ALT) or Input.is_key_pressed(KEY_META):
		return false
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return false
	return not can_pan.is_valid() or can_pan.call()


# --- Musen --------------------------------------------------------------------

func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_hover(room_at(event.position))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var room_id := room_at(event.position)
		if room_id != "":
			room_clicked.emit(room_id)


## Rummet under en punkt på skärmen: strålen från kameran träffar golvet i rummet.
func room_at(point: Vector2) -> String:
	var origin := _camera.project_ray_origin(point)
	var direction := _camera.project_ray_normal(point)
	if absf(direction.y) < 0.0001:
		return ""
	var t := -origin.y / direction.y
	if t < 0:
		return ""
	var hit := origin + direction * t
	for room_id in _plans:
		if (_plans[room_id] as Rect2).has_point(Vector2(hit.x, hit.z)):
			return room_id
	return ""


func _set_hover(room_id: String) -> void:
	if room_id == hover_room:
		return
	hover_room = room_id
	_update_overlays()
	room_hovered.emit(room_id)


func set_current(room_id: String) -> void:
	current_room = room_id
	_update_overlays()
	refresh_people()


## Var en sak i ett rum syns på skärmen (för markeringen av valets sak i menyn).
func object_screen_rect(room_id: String, kind: String) -> Rect2:
	if not _room_nodes.has(room_id) or kind == "":
		return Rect2()
	var bounds := AABB()
	var found := false
	for child in _room_nodes[room_id].get_children():
		if child.get_meta("kind", "") != kind:
			continue
		for mesh in child.find_children("*", "MeshInstance3D", true, false):
			var box: AABB = (mesh as MeshInstance3D).global_transform * (mesh as MeshInstance3D).get_aabb()
			bounds = box if not found else bounds.merge(box)
			found = true
		break
	if not found:
		return Rect2()
	var rect := Rect2()
	for i in 8:
		var point := _camera.unproject_position(bounds.get_endpoint(i))
		rect = Rect2(point, Vector2.ZERO) if i == 0 else rect.expand(point)
	return rect


# --- Skyltar ------------------------------------------------------------------

## Rummets namn som en liten skylt mitt i rummet, med "You are here" i mammans rum.
func _add_room_tag(room_id: String, plan: Rect2) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = LABEL_BG
	style.border_color = LABEL_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	style.shadow_color = Color(0, 0, 0, 0.15)
	style.shadow_size = 3
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", -2)
	panel.add_child(column)
	var name_label := Label.new()
	name_label.text = GameState.ROOMS[room_id]["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", LABEL_TEXT)
	column.add_child(name_label)
	var here := Label.new()
	here.text = "You are here"
	here.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	here.add_theme_font_size_override("font_size", 11)
	here.add_theme_color_override("font_color", LABEL_TEXT.lightened(0.25))
	here.visible = false
	column.add_child(here)
	_labels.add_child(panel)
	_tags.append({"node": panel, "at": Vector3(plan.get_center().x, 0.3, plan.get_center().y), "room": room_id, "here": here})


## En liten namnbricka ovanför en familjemedlem.
func _add_person_tag(text: String, color: Color, at: Vector3) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.15)
	style.set_corner_radius_all(9)
	style.content_margin_left = 7
	style.content_margin_right = 7
	label.add_theme_stylebox_override("normal", style)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_meta("person", true)
	_labels.add_child(label)
	_tags.append({"node": label, "at": at, "person": true})


# --- Familjen -----------------------------------------------------------------

## Ställer ut familjen i rummen på den här våningen enligt scheman och tidszon.
func refresh_people() -> void:
	if _people == null:
		return
	for child in _people.get_children():
		child.free()
	_mom = null
	_dog = null
	for i in range(_tags.size() - 1, -1, -1):
		if _tags[i].get("person", false):
			_tags[i]["node"].free()
			_tags.remove_at(i)
	var by_room := {}
	for character_id in GameState.CHARACTERS:
		var room := GameState.get_character_room(character_id)
		if _plans.has(room):
			by_room.get_or_add(room, []).append(character_id)
	for room_id in by_room:
		var spots := _free_spots(room_id, by_room[room_id].size())
		var i := 0
		for character_id in by_room[room_id]:
			if character_id == "dog":
				_place_dog(room_id)
				continue
			_place_person(character_id, spots[mini(i, spots.size() - 1)])
			i += 1


func _place_person(character_id: String, at: Vector3) -> void:
	var info: Dictionary = GameState.CHARACTERS[character_id]
	if character_id == "mom":
		var texture := AppearanceData.preview_image(GameState.appearance)
		var sprite := Sprite3D.new()
		sprite.texture = texture
		sprite.pixel_size = MOM_HEIGHT / texture.get_height()
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.shaded = false
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.centered = false
		sprite.offset = Vector2(-texture.get_width() / 2.0, 0)
		sprite.position = at
		_people.add_child(sprite)
		_rig.register_tinted(sprite)
		_mom = sprite
		_shadow(at, 0.7)
		return
	# Familjen som enkla figurer i sin färg tills det finns bilder av dem.
	var figure := Node3D.new()
	figure.position = at
	_people.add_child(figure)
	var color: Color = info["color"]
	var body := StyleKit.cylinder(figure, 0.15, 0.2, 1.0, Vector3(0, 0.5, 0), StyleKit.mat(color))
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	StyleKit.sphere(figure, 0.17, Vector3(0, 1.2, 0), StyleKit.mat(Color(0.98, 0.84, 0.72)))
	_shadow(at, 0.5)
	_add_person_tag(GameState.character_initials(character_id), color, at + Vector3(0, 1.65, 0))


## Hunden sover i sin bädd om rummet har en, annars hoprullad på golvet. När han leker
## står han i stället vaken och viftar på svansen, framför kojan om rummet har en.
func _place_dog(room_id: String) -> void:
	var plan: Rect2 = _plans[room_id]
	if GameState.whereabouts.get("dog", {}).get("activity", "") == "playing":
		var house := FloorPlanArt.furniture_rect(room_id, "dog_house")
		var spot: Vector3
		if house.size != Vector2.ZERO:
			spot = Vector3(plan.position.x + house.get_center().x - 0.9, 0, plan.position.y + house.end.y + 0.5)
		else:
			var spots := _free_spots(room_id, 6)
			spot = spots[spots.size() - 1]
		_dog = FurnitureKit.playful_dog(_people, spot)
		_shadow(spot, 0.6)
		return
	var bed := FloorPlanArt.furniture_rect(room_id, "dog_bed")
	var at: Vector3
	if bed.size != Vector2.ZERO:
		at = Vector3(plan.position.x + bed.get_center().x, 0, plan.position.y + bed.get_center().y)
	else:
		var spots := _free_spots(room_id, 6)
		at = spots[spots.size() - 1] - Vector3(0, 0.1, 0)
	_dog = FurnitureKit.sleeping_dog(_people, _rig, at)


func _shadow(at: Vector3, width: float) -> void:
	var shadow := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(width, width * 0.45)
	quad.orientation = PlaneMesh.FACE_Y
	shadow.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.25, 0.18, 0.3, 0.35)
	material.albedo_texture = StyleKit.soft_dot()
	shadow.material_override = material
	shadow.position = at + Vector3(0, 0.025, 0.02)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_people.add_child(shadow)


## Lediga platser på golvet där figurer kan stå: inte på möbler, en bit från
## väggarna, gärna nära mitten och mot kameran, och en bit isär.
func _free_spots(room_id: String, count: int) -> Array[Vector3]:
	var plan: Rect2 = _plans[room_id]
	var inner := plan.grow(-0.45)
	var blocked: Array[Rect2] = []
	for item in FloorPlanArt.FURNITURE.get(room_id, []):
		if not item[0] in WALKABLE:
			var rect: Rect2 = item[1]
			blocked.append(Rect2(plan.position + rect.position, rect.size).grow(0.22))
	var candidates: Array[Vector2] = []
	var y := inner.position.y
	while y <= inner.end.y:
		var x := inner.position.x
		while x <= inner.end.x:
			var point := Vector2(x, y)
			var free := true
			for rect in blocked:
				if rect.has_point(point):
					free = false
					break
			if free:
				candidates.append(point)
			x += 0.25
		y += 0.25
	if candidates.is_empty():
		candidates.append(plan.get_center())
	var focus := plan.get_center() + Vector2(0, plan.size.y * 0.2)
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_to(focus) < b.distance_to(focus))
	var chosen: Array[Vector3] = []
	for point in candidates:
		var spaced := true
		for other in chosen:
			if Vector2(other.x, other.z).distance_to(point) < 0.65:
				spaced = false
				break
		if spaced:
			chosen.append(Vector3(point.x, 0, point.y))
		if chosen.size() >= count:
			break
	while chosen.size() < count:
		chosen.append(chosen[0] if not chosen.is_empty() else Vector3(plan.get_center().x, 0, plan.get_center().y))
	return chosen


# --- Aktiviteter --------------------------------------------------------------

## Spelar en aktivitet i trädgården (RoomActions "fx") på ungefär Backyard.FX_SECONDS:
## mamman går till saken och gör det där. Returnerar när den är klar; house.gd genomför
## handlingen efteråt och ställer ut familjen igen.
##   swim  – hon kliver ned i poolen och simmar en bit, med plask
##   sun   – hon lägger sig på solstolen i ett varmt sken
##   water – hon vattnar rabatten med slangen
##   fetch – hon kastar bollen och Rex springer efter (han kommer ut om han är inne)
func play_activity(room_id: String, object: String, fx: String) -> void:
	var rect := FloorPlanArt.furniture_rect(room_id, object)
	if _mom == null or not _plans.has(room_id) or rect.size == Vector2.ZERO:
		await get_tree().create_timer(Backyard.FX_SECONDS * 0.4).timeout
		return
	var plan: Rect2 = _plans[room_id]
	var center := Vector3(plan.position.x + rect.get_center().x, 0, plan.position.y + rect.get_center().y)
	var walk := Backyard.FX_SECONDS * 0.3
	var act := Backyard.FX_SECONDS - walk
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	match fx:
		"swim":
			var edge := center + Vector3(-rect.size.x * 0.3, 0, 0)
			tween.tween_property(_mom, "position", edge, walk)
			tween.tween_property(_mom, "position:y", -0.95, act * 0.25)
			tween.tween_callback(func() -> void: _burst(edge + Vector3(0, 0.15, 0), Color(0.88, 0.97, 1.0), 40, 2.4, 50.0))
			tween.tween_property(_mom, "position:x", center.x + rect.size.x * 0.3, act * 0.75)
			tween.parallel().tween_callback(func() -> void: _trail(_mom, Color(0.9, 0.98, 1.0), act * 0.75))
		"sun":
			# Fötterna mot solstolens fotände; hon lägger sig på rygg med huvudet mot ryggstödet.
			var feet := center + Vector3(0, 0.38, rect.size.y / 2 - 0.1)
			tween.tween_property(_mom, "position", feet - Vector3(0, 0.38, -0.25), walk)
			tween.tween_callback(func() -> void:
				var sprite := _mom as Sprite3D
				sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
				sprite.rotation_degrees = Vector3(-84, 0, 0)
				sprite.position = feet
				_glow(center + Vector3(0, 0.5, 0), Color(1.0, 0.85, 0.45), act))
			tween.tween_interval(act)
		"water":
			# Hon står på gräset framför rabatten och sprutar mot den.
			var stand := center + Vector3(-rect.size.x * 0.25, 0, -0.75)
			tween.tween_property(_mom, "position", stand, walk)
			tween.tween_callback(func() -> void:
				_spray(stand + Vector3(0.2, 0.9, 0.1), center - stand, Color(0.55, 0.8, 1.0), act))
			tween.tween_interval(act)
		"fetch":
			var door := center + Vector3(0, 0, rect.size.y / 2 + 0.4)
			var stand := door + Vector3(-1.0, 0, 0.3)
			var landing := door + Vector3(-4.0, 0, -0.6)
			var dog := _dog if _dog != null and GameState.get_character_room("dog") == room_id else FurnitureKit.playful_dog(_people, door)
			tween.tween_property(_mom, "position", stand, walk)
			tween.tween_callback(func() -> void: _throw_ball(stand + Vector3(0, 1.2, 0), landing, act * 0.45))
			tween.tween_callback(func() -> void: _face(dog, landing))
			tween.tween_property(dog, "position", landing, act * 0.5).set_delay(act * 0.1)
			tween.tween_callback(func() -> void: _face(dog, stand))
			tween.tween_property(dog, "position", stand + Vector3(0.45, 0, 0.1), act * 0.4)
		_:
			tween.tween_interval(Backyard.FX_SECONDS * 0.4)
	# En timer i stället för tween.finished: byggs figurerna om mitt i (schemat ändras)
	# försvinner tweenens mål, och då får house.gd ändå inte vänta för evigt.
	await get_tree().create_timer(Backyard.FX_SECONDS).timeout


## Vänder hunden (huvudet längs +x) mot en punkt.
func _face(dog: Node3D, toward: Vector3) -> void:
	var direction := toward - dog.position
	dog.rotation.y = atan2(-direction.z, direction.x)


## Ett plask: droppar som skjuts uppåt och faller tillbaka.
func _burst(at: Vector3, color: Color, amount: int, speed: float, spread: float) -> void:
	var particles := _particles(at, color, amount, 0.9, 0.045)
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.spread = spread
	particles.initial_velocity_min = speed * 0.5
	particles.initial_velocity_max = speed
	particles.emitting = true


## Små vågor efter den som simmar.
func _trail(follow: Node3D, color: Color, seconds: float) -> void:
	var particles := _particles(Vector3(0, 0.15, 0), color, 30, 0.6, 0.035)
	particles.spread = 70.0
	particles.initial_velocity_min = 0.6
	particles.initial_velocity_max = 1.2
	# Följer med figuren, strax ovanför vattenytan när hon har sjunkit ned.
	_people.remove_child(particles)
	follow.add_child(particles)
	particles.position = Vector3(0, 1.1, 0)
	particles.emitting = true
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if is_instance_valid(particles):
			particles.emitting = false)


## Solens varma sken: ljusa korn som stiger långsamt, och ett mjukt ljus.
func _glow(at: Vector3, color: Color, seconds: float) -> void:
	var particles := _particles(at, color, 24, 1.4, 0.03)
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(0.4, 0.1, 0.9)
	particles.gravity = Vector3(0, 0.25, 0)
	particles.initial_velocity_min = 0.05
	particles.initial_velocity_max = 0.2
	particles.emitting = true
	var light := OmniLight3D.new()
	light.light_color = color
	light.omni_range = 2.0
	light.light_energy = 0.0
	light.position = at + Vector3(0, 0.6, 0)
	_people.add_child(light)
	var shine := light.create_tween()
	shine.tween_property(light, "light_energy", 1.2, seconds * 0.5)
	shine.tween_property(light, "light_energy", 0.4, seconds * 0.5)


## Vatten ur slangen i en båge mot en punkt.
func _spray(at: Vector3, toward: Vector3, color: Color, seconds: float) -> void:
	var particles := _particles(at, color, 60, 0.7, 0.03)
	particles.direction = Vector3(toward.x, 1.2, toward.z).normalized()
	particles.spread = 8.0
	particles.initial_velocity_min = 3.0
	particles.initial_velocity_max = 3.4
	particles.emitting = true
	get_tree().create_timer(seconds * 0.9).timeout.connect(func() -> void:
		if is_instance_valid(particles):
			particles.emitting = false)


## Tennisbollen i en båge från handen till marken.
func _throw_ball(from: Vector3, to: Vector3, seconds: float) -> void:
	var ball := Node3D.new()
	_people.add_child(ball)
	StyleKit.sphere(ball, 0.06, Vector3.ZERO, StyleKit.mat(Color(0.85, 0.95, 0.35), 0.3))
	var arc := ball.create_tween()
	arc.tween_method(func(t: float) -> void:
		ball.position = from.lerp(to + Vector3(0, 0.06, 0), t) + Vector3(0, sin(t * PI) * 1.6, 0), 0.0, 1.0, seconds)


## Partiklar i husets stil: små, oskuggade kulor som tas bort när de är klara.
func _particles(at: Vector3, color: Color, amount: int, lifetime: float, radius: float) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.emitting = false
	particles.gravity = Vector3(0, -7.0, 0)
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	mesh.material = material
	particles.mesh = mesh
	particles.position = at
	_people.add_child(particles)
	return particles
