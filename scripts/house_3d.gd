class_name House3D
extends Node3D
## Bygger en våning av huset i 3D ur planens data (PlanDrawer och FloorPlanArt):
## golv med material, väggar med dörröppningar och fönster, och egna möbler
## (Furniture3D). 1 enhet = 1 meter; planens x är X och planens y är Z.
## Ytterväggar i norr och väster är hela, övriga väggar är avskurna som i ett dockhus
## så att kameran ser in i rummen.

const WALL_HEIGHT := 2.5
const CUT_HEIGHT := 0.35
const OUTER_THICKNESS := 0.2
const INNER_THICKNESS := 0.12
const DOOR_WIDTH := 0.9
const DOOR_HEIGHT := 2.1
const WINDOW_SILL := 0.9
const WINDOW_TOP := 2.1
const WALL_COLOR := Color(0.95, 0.9, 0.83)
const WALL_TOP_COLOR := Color(0.55, 0.4, 0.3)
const GLASS_COLOR := Color(0.7, 0.85, 0.95, 0.45)
const FLOOR_COLORS := {
	"wood": Color(0.86, 0.7, 0.52),
	"wood_old": Color(0.76, 0.6, 0.44),
	"tile": Color(0.9, 0.9, 0.88),
	"tile_warm": Color(0.93, 0.87, 0.8),
	"concrete": Color(0.82, 0.8, 0.77),
	"grass": Color(0.62, 0.76, 0.5),
}

@export var floor_name := "Entréplan"

var _plans: Dictionary
## Dörrar per rum: room_id -> {målrum: restid}. Hämtas från GameState när spelet körs.
var _exits := {}


func _ready() -> void:
	build()


func build() -> void:
	for child in get_children():
		child.queue_free()
	_plans = PlanDrawer.FLOOR_PLANS[floor_name]
	_exits.clear()
	if not Engine.is_editor_hint():
		for room_id in _plans:
			_exits[room_id] = GameState.get_exits(room_id)
	for room_id in _plans:
		_build_floor(room_id)
		_build_walls(room_id)
		_build_furniture(room_id)


# --- Golv ---------------------------------------------------------------------

func _build_floor(room_id: String) -> void:
	var plan: Rect2 = _plans[room_id]
	var kind: String = FloorPlanArt.FLOOR_MATERIALS.get(room_id, "wood")
	var mesh := BoxMesh.new()
	mesh.size = Vector3(plan.size.x, 0.1, plan.size.y)
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = mesh
	floor_node.position = Vector3(plan.get_center().x, -0.05, plan.get_center().y)
	floor_node.material_override = _floor_material(kind)
	add_child(floor_node)


static var _floor_materials := {}


## Golvmaterial med ett enkelt mönster (plankor eller kakel) i en genererad textur.
static func _floor_material(kind: String) -> StandardMaterial3D:
	if _floor_materials.has(kind):
		return _floor_materials[kind]
	var base: Color = FLOOR_COLORS[kind]
	var image := Image.create(256, 256, false, Image.FORMAT_RGB8)
	image.fill(base)
	var line := base.darkened(0.12)
	if kind.begins_with("wood"):
		# Plankor 0,2 m breda med förskjutna skarvar; texturen täcker 1,6 × 1,6 m.
		for row in 8:
			var y := row * 32
			image.fill_rect(Rect2i(0, y, 256, 2), line)
			var shade := base.darkened(0.03 * (row % 3))
			image.fill_rect(Rect2i(0, y + 2, 256, 30), shade)
			var joint := (row * 96) % 256
			image.fill_rect(Rect2i(joint, y, 2, 32), line)
	elif kind.begins_with("tile"):
		for i in 4:
			image.fill_rect(Rect2i(i * 64, 0, 2, 256), line)
			image.fill_rect(Rect2i(0, i * 64, 256, 2), line)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(image)
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE / 1.6
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.roughness = 1.0
	_floor_materials[kind] = mat
	return mat


# --- Väggar -------------------------------------------------------------------

## Bygger rummets fyra väggar. En vägg mellan två rum byggs bara av det ena rummet.
## Varje vägg delas upp i bitar: hel vägg, dörröppning eller fönster.
func _build_walls(room_id: String) -> void:
	var plan: Rect2 = _plans[room_id]
	for side in ["north", "east", "south", "west"]:
		var a := _corner(plan, side, false)
		var b := _corner(plan, side, true)
		var along := (b - a).normalized()
		var outward := _outward(side)
		var length := a.distance_to(b)
		var openings := _openings(room_id, side, a, along, length)
		# Gå längs väggen i små steg och samla ihop bitar av samma sort.
		var step := 0.05
		var t := 0.0
		while t < length - 0.001:
			var probe := a + along * (t + step / 2)
			var neighbor := _room_at(probe + outward * 0.1)
			var kind: String = _opening_at(openings, t + step / 2)
			var run_start := t
			while t < length - 0.001:
				var p := a + along * (t + step / 2)
				if _room_at(p + outward * 0.1) != neighbor or _opening_at(openings, t + step / 2) != kind:
					break
				t += step
			# Väggar mellan två rum byggs av rummet med "lägst" id.
			if neighbor != "" and neighbor < room_id:
				continue
			_build_wall_piece(a + along * run_start, a + along * t, outward, neighbor == "", side, kind)


func _build_wall_piece(from: Vector2, to: Vector2, outward: Vector2, exterior: bool, side: String, kind: String) -> void:
	var thickness := OUTER_THICKNESS if exterior else INNER_THICKNESS
	var full := exterior and side in ["north", "west"]
	var height := WALL_HEIGHT if full else CUT_HEIGHT
	# Ytterväggen ligger utanför rummets kant, innerväggen centrerad på den.
	var shift := outward * thickness / 2 if exterior else Vector2.ZERO
	var center := (from + to) / 2 + shift
	var length := from.distance_to(to)
	var horizontal := absf(to.x - from.x) > absf(to.y - from.y)
	var size_xz := Vector2(length + (thickness if exterior else 0.0), thickness) if horizontal else Vector2(thickness, length + (thickness if exterior else 0.0))
	match kind:
		"wall":
			_wall_box(center, size_xz, 0.0, height)
		"door":
			if full:
				_wall_box(center, size_xz, DOOR_HEIGHT, height)
		"window":
			_wall_box(center, size_xz, 0.0, WINDOW_SILL)
			var glass_top := minf(WINDOW_TOP, height)
			if glass_top > WINDOW_SILL:
				var glass := _wall_box(center, size_xz * Vector2(1, 0.3) if horizontal else size_xz * Vector2(0.3, 1), WINDOW_SILL, glass_top)
				glass.material_override = _glass_material()
			if full:
				_wall_box(center, size_xz, WINDOW_TOP, height)


func _wall_box(center: Vector2, size_xz: Vector2, bottom: float, top: float) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size_xz.x, top - bottom, size_xz.y)
	var wall := MeshInstance3D.new()
	wall.mesh = mesh
	wall.position = Vector3(center.x, (bottom + top) / 2, center.y)
	wall.material_override = Furniture3D.material(WALL_COLOR)
	add_child(wall)
	return wall


static var _glass: StandardMaterial3D


static func _glass_material() -> StandardMaterial3D:
	if _glass == null:
		_glass = StandardMaterial3D.new()
		_glass.albedo_color = GLASS_COLOR
		_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _glass


## Öppningar längs en vägg som intervall [början, slut, sort] i meter från väggens start.
func _openings(room_id: String, side: String, a: Vector2, along: Vector2, length: float) -> Array:
	var result := []
	var plan: Rect2 = _plans[room_id]
	for target in _exits.get(room_id, {}):
		if not _plans.has(target):
			continue
		var shared := PlanDrawer.shared_edge(plan, _plans[target])
		if shared.is_empty():
			continue
		var middle: Vector2 = (shared[0] + shared[1]) / 2
		if _on_side(plan, side, middle):
			var t := (middle - a).dot(along)
			result.append([t - DOOR_WIDTH / 2, t + DOOR_WIDTH / 2, "door"])
	if PlanDrawer.FRONT_DOORS.get(room_id, "") == side:
		result.append([length / 2 - DOOR_WIDTH / 2, length / 2 + DOOR_WIDTH / 2, "door"])
	for window in FloorPlanArt.windows(room_id):
		if window["side"] == side:
			result.append([window["start"], window["start"] + window["width"], "window"])
	return result


func _opening_at(openings: Array, t: float) -> String:
	for opening in openings:
		if t >= opening[0] and t <= opening[1]:
			return opening[2]
	return "wall"


func _on_side(plan: Rect2, side: String, point: Vector2) -> bool:
	match side:
		"north":
			return absf(point.y - plan.position.y) < 0.01
		"south":
			return absf(point.y - plan.end.y) < 0.01
		"west":
			return absf(point.x - plan.position.x) < 0.01
		_:
			return absf(point.x - plan.end.x) < 0.01


## Väggens start- eller slutpunkt. Väggar går väst→öst och norr→söder, som fönstren.
func _corner(plan: Rect2, side: String, at_end: bool) -> Vector2:
	match side:
		"north":
			return Vector2(plan.end.x if at_end else plan.position.x, plan.position.y)
		"south":
			return Vector2(plan.end.x if at_end else plan.position.x, plan.end.y)
		"west":
			return Vector2(plan.position.x, plan.end.y if at_end else plan.position.y)
		_:
			return Vector2(plan.end.x, plan.end.y if at_end else plan.position.y)


func _outward(side: String) -> Vector2:
	return {"north": Vector2.UP, "south": Vector2.DOWN, "west": Vector2.LEFT, "east": Vector2.RIGHT}[side]


func _room_at(point: Vector2) -> String:
	for room_id in _plans:
		if _plans[room_id].has_point(point):
			return room_id
	return ""


# --- Möbler -------------------------------------------------------------------

func _build_furniture(room_id: String) -> void:
	var plan: Rect2 = _plans[room_id]
	var items: Array = FloorPlanArt.FURNITURE.get(room_id, [])
	for item in items:
		var kind: String = item[0]
		var rect: Rect2 = item[1]
		var facing := _facing(kind, rect, plan.size, items)
		# Möbler som står mot en vägg i öster eller väster vrids 90°, så bredd och djup byter plats.
		var sideways := facing in ["west", "east"]
		var node := Furniture3D.build(kind, rect.size.y if sideways else rect.size.x, rect.size.x if sideways else rect.size.y)
		if node == null:
			continue
		var center := plan.position + rect.get_center()
		node.position = Vector3(center.x, 0, center.y)
		node.rotation.y = {"north": 0.0, "south": PI, "west": PI / 2, "east": -PI / 2}[facing]
		add_child(node)


## Åt vilket håll möbelns baksida vetter: mot närmaste vägg, eller för stolar bort från bordet.
func _facing(kind: String, rect: Rect2, room_size: Vector2, items: Array) -> String:
	if kind == "chair":
		for item in items:
			if item[0] in ["table", "desk"]:
				var to_table: Vector2 = (item[1] as Rect2).get_center() - rect.get_center()
				if absf(to_table.x) > absf(to_table.y):
					return "west" if to_table.x > 0 else "east"
				return "north" if to_table.y > 0 else "south"
	if kind == "stairs":
		return "north"
	var distances := {
		"north": rect.position.y,
		"south": room_size.y - rect.end.y,
		"west": rect.position.x,
		"east": room_size.x - rect.end.x,
	}
	var best := "north"
	for side in distances:
		if distances[side] < distances[best]:
			best = side
	return best
