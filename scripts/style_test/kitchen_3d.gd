extends Node3D
## Stiltest: köket i riktig 3D, byggt med husets gemensamma satser. StyleKit ger skalet
## (golv, väggar med fönster och dörr, lister), FurnitureKit möblerar rummet från
## planens möbeldata och lägger till kökets detaljer, och TimeOfDayRig sköter ljuset per
## tidszon. Rummet är ett dockhus: södra väggen är avskuren så att kameran ser in.
## Tryck 1–4 för att byta tidszon (morning, afternoon, evening, night).

const ROOM_ID := "kitchen"
const FLOOR := "Entréplan"
const MOM_IMAGE := "res://Assets/portraits/mom_casual_full.png"

var _rig: TimeOfDayRig
var _mom: Sprite3D
var _camera: Camera3D
var _time := 0.0
var _center := Vector3.ZERO


func _ready() -> void:
	_rig = TimeOfDayRig.new()
	add_child(_rig)
	var plans: Dictionary = PlanDrawer.FLOOR_PLANS[FLOOR]
	var plan: Rect2 = plans[ROOM_ID]
	var exits: Dictionary = GameState.get_exits(ROOM_ID) if has_node("/root/GameState") else {}
	StyleKit.build_room_shell(self, _rig, plans, ROOM_ID, exits)
	FurnitureKit.furnish(self, _rig, ROOM_ID, plan)
	FurnitureKit.decorate(self, _rig, ROOM_ID, plan)
	# En bit av hallens golv syns genom dörren.
	var hall: Rect2 = plans["hall"]
	StyleKit.box(self, Vector3(1.6, 0.1, hall.size.y), Vector3(hall.position.x + 0.8, -0.05, hall.size.y / 2), StyleKit.floor_mat("wood"), true, 0.0)
	_center = Vector3(plan.get_center().x, 0, plan.get_center().y)
	_build_mom()
	# Hunden sover i sin bädd (i spelet placeras den efter schemat).
	var bed := FloorPlanArt.furniture_rect(ROOM_ID, "dog_bed")
	FurnitureKit.sleeping_dog(self, _rig, Vector3(plan.position.x + bed.get_center().x, 0, plan.position.y + bed.get_center().y))
	_camera = Camera3D.new()
	_camera.fov = 36.0
	add_child(_camera)
	StyleKit.add_ink_outline(_camera)
	_place_camera()


func set_period(period: String) -> void:
	_rig.set_period(period)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var keys := {KEY_1: "morning", KEY_2: "afternoon", KEY_3: "evening", KEY_4: "night"}
		if keys.has(event.keycode):
			set_period(keys[event.keycode])


func _process(delta: float) -> void:
	_time += delta
	_mom.scale = Vector3(1.0, 1.0 + sin(_time * 1.6) * 0.004, 1.0)
	_place_camera()


## Kameran står söder om rummet, högt upp, och glider långsamt fram och tillbaka.
func _place_camera() -> void:
	var position := _center + Vector3(sin(_time * 0.12) * 0.25, 5.1, 6.85)
	_camera.look_at_from_position(position, _center + Vector3(0, 0.8, -0.25))


## Mamman som en uppstående bild (Anima) i rummet, med en mjuk skugga under fötterna.
func _build_mom() -> void:
	var texture: Texture2D = load(MOM_IMAGE)
	_mom = Sprite3D.new()
	_mom.texture = texture
	_mom.pixel_size = 1.68 / texture.get_height()
	_mom.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_mom.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_mom.shaded = false
	_mom.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_mom.centered = false
	_mom.offset = Vector2(-texture.get_width() / 2.0, 0)
	_mom.position = Vector3(4.1, 0.0, 3.5)
	add_child(_mom)
	_rig.register_tinted(_mom)
	var shadow := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.75, 0.32)
	quad.orientation = PlaneMesh.FACE_Y
	shadow.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.25, 0.18, 0.3, 0.35)
	material.albedo_texture = StyleKit.soft_dot()
	shadow.material_override = material
	shadow.position = Vector3(4.1, 0.012, 3.52)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
