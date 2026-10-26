class_name Surroundings
## Världen runt våningen man tittar på, så att det aldrig är tomt runt huset: marken,
## gården, gatan, grannarnas hus och träd långt bort. Det man ser genom fönster och
## dörrar är riktig 3D, så utsikten stämmer med var rummet ligger.
##
## Bilden byggs i lager, bakifrån och fram:
##   1. Himmel och dis: bakgrunden och djupdimma i tidszonens färg (TimeOfDayRig "haze"),
##      så att världen tonar bort i stället för att sluta i en kant.
##   2. Fjärran: en ring av trädklungor långt bort, utan skuggor.
##   3. Tomten: platsens omgivning (gata, trottoar, grannhus, häckar, parkering ...).
##   4. Byggnaden utifrån: grund, våningarna under som block med fönster, jord runt källaren.
##   5. Rummen (StyleKit/FurnitureKit), med fasad på ytterväggarnas utsida.
##   6. Glaset i fönstren, som man ser lager 1–4 genom.
## Dockhusregeln gäller hela världen: allt mellan kameran och våningen (söder om den) hålls
## lågt, så att inget skymmer rummen. Höga saker där hoppas över och byggnader skärs av
## som de södra väggarna.
## Varje våning hör till en plats (SITES) och ligger på en bestämd punkt på platsens tomt,
## så husets våningar delar samma omgivning: från övervåningen ser man ned på gården och
## entréplanets tak, och från källaren ser man gräsmattan ovanför.
## Allt på tomten byggs i tomtens koordinater (entréplanets golv = 0) under en nod som
## flyttas så att våningen man tittar på hamnar där HouseView3D bygger den.

const STOREY := 2.8
## Så högt (över våningens golv) får saker framför våningen vara.
const FRONT_MAX := 0.7
const FAR := 130.0

## Ute i full sol blir färgerna mycket ljusare än inne, så markens färger är mörkare
## än de ser ut (samma gräs som gräsvåningarna i StyleKit.floor_mat).
const GRASS := Color(0.45, 0.63, 0.36)
const SOIL := Color(0.6, 0.46, 0.36)
const GRAVEL := Color(0.66, 0.64, 0.6)
const ASPHALT := Color(0.32, 0.33, 0.37)
const PAVING := Color(0.74, 0.72, 0.68)
const FOUNDATION := Color(0.68, 0.66, 0.64)
const ROOF := Color(0.45, 0.37, 0.4)
## Platta tak (våningar under den man står på, butiker).
const FLAT_ROOF := Color(0.62, 0.57, 0.58)
const HEDGE := Color(0.32, 0.54, 0.34)
const GLASS := Color(0.52, 0.64, 0.74)
const WINDOW_GLOW := Color(1.0, 0.78, 0.48)
const FAR_LEAF := Color(0.36, 0.55, 0.42)
const FLOWERS := [Color(0.9, 0.56, 0.6), Color(0.98, 0.86, 0.48), Color(0.76, 0.66, 0.9), Color(0.98, 0.96, 0.94)]
## Grannhusens färger: dämpade, som resten av huset ("mellanvägen").
const HOUSE_COLORS := [Color(0.95, 0.88, 0.66), Color(0.74, 0.82, 0.7), Color(0.9, 0.74, 0.68), Color(0.82, 0.8, 0.9), Color(0.96, 0.94, 0.9)]
const CAR_COLORS := [Color(0.86, 0.52, 0.48), Color(0.95, 0.95, 0.93), Color(0.4, 0.42, 0.48), Color(0.55, 0.7, 0.6), Color(0.95, 0.82, 0.5)]

## Platserna: markens höjd (entréplanets golv = 0) och fasaden. Tomten byggs i build().
const SITES := {
	"home": {"grade": -0.45, "siding": Color(0.78, 0.84, 0.87)},
	"school": {"grade": -0.3, "siding": Color(0.8, 0.56, 0.46), "brick": true},
	"neighbor": {"grade": -0.45, "siding": Color(0.95, 0.88, 0.66)},
	"gym": {"grade": -0.15, "siding": Color(0.88, 0.89, 0.9)},
	"mall": {"grade": -0.15, "siding": Color(0.95, 0.9, 0.82)},
	"park": {"grade": 0.0},
}
## Varje våning: platsen den hör till och var våningens nollpunkt ligger på tomten
## (x österut, y uppåt, z söderut). Husets våningar ligger rakt ovanför varandra.
## Gårdarna (Utanför) är ritade i husets koordinater och ligger i markens höjd
## (SITES["home"]["grade"]), så att framsidan och trädgården sluter an mot huset.
const FLOORS := {
	"Entréplan": {"site": "home", "at": Vector3(0, 0, 0)},
	"Övervåning": {"site": "home", "at": Vector3(0, 2.8, 0)},
	"Vind": {"site": "home", "at": Vector3(0, 5.6, 0)},
	"Källare": {"site": "home", "at": Vector3(0, -2.8, 0)},
	"Utanför": {"site": "home", "at": Vector3(0, -0.45, 0)},
	"Skolan": {"site": "school", "at": Vector3.ZERO},
	"Grannen": {"site": "neighbor", "at": Vector3.ZERO},
	"Gymmet": {"site": "gym", "at": Vector3.ZERO},
	"Köpcentret": {"site": "mall", "at": Vector3.ZERO},
	"Parken": {"site": "park", "at": Vector3.ZERO},
}

# Bygget pågår: tomtens nod, riggen och vad som redan står på tomten.
static var _root: Node3D
static var _rig: TimeOfDayRig
static var _rng := RandomNumberGenerator.new()
static var _grade := 0.0
## Våningens golv på tomten (y) och dess yta.
static var _level := 0.0
static var _bbox := Rect2()
## Ytor där tomten inte får bygga (våningens rum och gårdar som ritas från planen).
static var _taken: Array[Rect2] = []
## Zonen mellan kameran och våningen, och hur högt saker där får vara (tomtens y).
static var _front := Rect2()
static var _front_top := 0.0
static var _site := {}
static var _lit_glass: ShaderMaterial


## Fasaden för ytterväggarna på en våning (StyleKit.siding).
static func facade(floor_name: String) -> Material:
	if not FLOORS.has(floor_name):
		return null
	var site: Dictionary = SITES[FLOORS[floor_name]["site"]]
	if _floor_at(floor_name).y < 0.0:
		return StyleKit.mat(FOUNDATION)
	if not site.has("siding"):
		return null
	return _siding(site["siding"], site.get("brick", false))


## Bygger omgivningen runt en våning under `parent` (våningens koordinater).
static func build(parent: Node3D, rig: TimeOfDayRig, floor_name: String) -> void:
	if not FLOORS.has(floor_name):
		return
	var site_id: String = FLOORS[floor_name]["site"]
	_site = SITES[site_id]
	_rig = rig
	_rng.seed = hash(floor_name)
	_grade = _site["grade"]
	var at := _floor_at(floor_name)
	_level = at.y
	_root = Node3D.new()
	_root.name = "Surroundings"
	_root.position = -at
	parent.add_child(_root)
	_lit_glass = StyleKit.own_mat(GLASS)
	_lit_glass.set_shader_parameter("gloss", 0.6)
	_lit_glass.set_shader_parameter("emission", WINDOW_GLOW)
	rig.register_lamp_shade(_lit_glass)

	var rooms := _lot_rooms(floor_name)
	_taken.clear()
	_bbox = rooms[0]
	for room in rooms:
		_bbox = _bbox.merge(room)
		_taken.append(room.grow(0.15))
	var below := _level < _grade
	if below:
		# Under marken: allt söder om våningen är avskuret ned till de södra väggarnas höjd.
		_front = Rect2(-FAR, _bbox.end.y + 0.05, FAR * 2, FAR)
		_front_top = _level + StyleKit.CUT_HEIGHT
	else:
		_front = Rect2(_bbox.position.x - 8, _bbox.end.y + 0.3, _bbox.size.x + 16, FAR)
		_front_top = _level + FRONT_MAX

	# Gårdar på samma tomt (gräsvåningar) ritas ur sin plan, med möblerna.
	for other in FLOORS:
		if other == floor_name or FLOORS[other]["site"] != site_id or not _is_open_air(other):
			continue
		var other_at := _floor_at(other)
		var yard := Node3D.new()
		yard.position = other_at
		_root.add_child(yard)
		var plans: Dictionary = PlanDrawer.FLOOR_PLANS[other]
		var shift := Vector2(other_at.x, other_at.z)
		for room_id in plans:
			var plan: Rect2 = plans[room_id]
			var lot := Rect2(plan.position + shift, plan.size)
			if below and _front.intersects(lot):
				continue  # Från källaren är marken framför avskuren (tårtbiten); gården syns inte.
			StyleKit.build_room_shell(yard, rig, plans, room_id, GameState.get_exits(room_id))
			# Dockhusregeln: höga saker på gården mellan kameran och våningen hoppas över.
			FurnitureKit.furnish(yard, rig, room_id, plan, plans, func(kind: String, rect: Rect2) -> bool:
				return _front.intersects(Rect2(rect.position + shift, rect.size)) and other_at.y + HomeKit.height(kind) > _front_top)
			_taken.append(lot.grow(0.1))

	_ground(below, floor_name)
	_building(floor_name)
	match site_id:
		"home":
			_home()
		"school":
			_school()
		"neighbor":
			_neighbor()
		"gym":
			_gym()
		"mall":
			_mall()
		"park":
			_park()
	_far_ring()


## Var en vånings nollpunkt ligger på tomten.
static func _floor_at(floor_name: String) -> Vector3:
	return FLOORS[floor_name]["at"]


static func _is_open_air(floor_name: String) -> bool:
	for room_id in PlanDrawer.FLOOR_PLANS[floor_name]:
		if FloorPlanArt.FLOOR_MATERIALS.get(room_id, "") != "grass":
			return false
	return true


## Våningens rum på tomten.
static func _lot_rooms(floor_name: String) -> Array[Rect2]:
	var at := _floor_at(floor_name)
	var result: Array[Rect2] = []
	for room_id in PlanDrawer.FLOOR_PLANS[floor_name]:
		var plan: Rect2 = PlanDrawer.FLOOR_PLANS[floor_name][room_id]
		result.append(Rect2(plan.position + Vector2(at.x, at.z), plan.size))
	return result


# --- Material -----------------------------------------------------------------

static func _siding(color: Color, brick := false) -> ShaderMaterial:
	if brick:
		return StyleKit.mat(color, 0.0, 8, 0.14, color.darkened(0.12))
	return StyleKit.mat(color, 0.0, 6, 0.2, color.darkened(0.1))


static func _grass() -> ShaderMaterial:
	return StyleKit.mat(GRASS, 0.0, 7, 3.0)


# --- Marken -------------------------------------------------------------------

## Marken: en stor gräsyta i markens höjd. Under marken (källaren) byggs den av rutor
## runt våningen: gräs i markhöjd på sidorna och bakom, ljusgårdar framför fönstren och
## en avskuren jordkant söder om våningen, som snittet i en tårta.
static func _ground(below: bool, floor_name: String) -> void:
	if not below:
		var ground := StyleKit.box(_root, Vector3(FAR * 2, 0.4, FAR * 2), Vector3(_bbox.get_center().x, _grade - 0.22, _bbox.get_center().y), _grass(), false, 0.0)
		ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		return
	var rooms: Array[Rect2] = []
	for room in _lot_rooms(floor_name):
		rooms.append(room.grow(StyleKit.WALL))
	var wells := _window_wells(floor_name)
	var xs: Array[float] = [-FAR + _bbox.get_center().x, FAR + _bbox.get_center().x]
	var zs: Array[float] = [-FAR + _bbox.get_center().y, FAR + _bbox.get_center().y]
	var edges: Array = rooms.duplicate()
	edges.append_array(wells.keys())
	for rect: Rect2 in edges:
		xs.append_array([rect.position.x, rect.end.x])
		zs.append_array([rect.position.y, rect.end.y])
	xs = _unique(xs)
	zs = _unique(zs)
	var cut := _level + StyleKit.CUT_HEIGHT
	var bottom := _level - 0.3
	var soil := StyleKit.mat(SOIL, 0.0, 6, 0.5, SOIL.darkened(0.06))
	var cap := StyleKit.mat(SOIL.darkened(0.08), 0.0, 7, 1.2)
	var outer := Rect2()
	for room in rooms:
		outer = room if outer.size == Vector2.ZERO else outer.merge(room)
	for i in xs.size() - 1:
		for j in zs.size() - 1:
			var cell := Rect2(xs[i], zs[j], xs[i + 1] - xs[i], zs[j + 1] - zs[j])
			var c := cell.get_center()
			if rooms.any(func(r: Rect2) -> bool: return r.has_point(c)):
				continue
			var top := _grade
			var surface := _grass()
			var well: Array = wells.keys().filter(func(r: Rect2) -> bool: return r.has_point(c))
			if not well.is_empty():
				top = _level + wells[well[0]] - 0.15
				surface = StyleKit.mat(GRAVEL, 0.0, 7, 0.4)
			elif outer.has_point(c) or c.y > outer.end.y:
				top = cut
				surface = cap
			var layer := 0.1 if surface != cap else 0.03
			_slab_box(Rect2(cell.position, cell.size), bottom, top - layer, soil)
			_slab_box(Rect2(cell.position, cell.size), top - layer, top, surface)


## Ljusgårdar utanför källarfönstren, så att fönstren inte ligger mot jorden:
## {ljusgårdens yta: fönstrets bröstningshöjd}.
static func _window_wells(floor_name: String) -> Dictionary:
	var at := _floor_at(floor_name)
	var plans: Dictionary = PlanDrawer.FLOOR_PLANS[floor_name]
	var result := {}
	for room_id in plans:
		var plan: Rect2 = plans[room_id]
		plan.position += Vector2(at.x, at.z)
		for window in FloorPlanArt.windows(room_id):
			var side: String = window["side"]
			if side == "south":
				continue
			var from: float = window["start"] - 0.15
			var width: float = window["width"] + 0.3
			var w := StyleKit.WALL
			match side:
				"north":
					result[Rect2(plan.position.x + from, plan.position.y - w - 0.8, width, 0.8)] = window["sill"]
				"west":
					result[Rect2(plan.position.x - w - 0.8, plan.position.y + from, 0.8, width)] = window["sill"]
				"east":
					result[Rect2(plan.end.x + w, plan.position.y + from, 0.8, width)] = window["sill"]
	return result


static func _unique(values: Array[float]) -> Array[float]:
	values.sort()
	var result: Array[float] = []
	for v in values:
		if result.is_empty() or v - result[-1] > 0.001:
			result.append(v)
	return result


## En låda över en yta mellan två höjder (tomtens koordinater).
static func _slab_box(rect: Rect2, bottom: float, top: float, material: Material, shadows := false) -> MeshInstance3D:
	if top - bottom < 0.001:
		return null
	var box := StyleKit.box(_root, Vector3(rect.size.x, top - bottom, rect.size.y), Vector3(rect.get_center().x, (bottom + top) / 2, rect.get_center().y), material, shadows, 0.0)
	return box


## En platta på marken (gång, asfalt, uteplats), `height` över marken.
static func _paving(rect: Rect2, material: Material, height := 0.02) -> void:
	if _free(rect, _grade + height):
		_slab_box(rect, _grade - 0.05, _grade + height, material)


## Ett rum som är avskuret mot kameran (dockhuset): grund, golv och låga mörka väggkrön
## runt om, som de södra väggarna.
static func _cutaway(rect: Rect2, floor_top: float, floor_material: Material) -> void:
	var w := StyleKit.WALL
	_slab_box(rect.grow(w + 0.04), _grade - 0.05, floor_top - 0.1, StyleKit.mat(FOUNDATION), true)
	_slab_box(rect, floor_top - 0.1, floor_top, floor_material, true)
	var cap := StyleKit.mat(StyleKit.WALL_TOP)
	var top := floor_top + StyleKit.CUT_HEIGHT
	for side in [Rect2(rect.position.x - w, rect.position.y - w, rect.size.x + w * 2, w), Rect2(rect.position.x - w, rect.end.y, rect.size.x + w * 2, w),
			Rect2(rect.position.x - w, rect.position.y, w, rect.size.y), Rect2(rect.end.x, rect.position.y, w, rect.size.y)]:
		_slab_box(side, floor_top - 0.1, top, cap, true)


# --- Byggnaden utifrån --------------------------------------------------------

## Grunden under våningen och våningarna under den som block med fönster. Står man på
## gårdarna ligger huset mitt emellan dem och ritas avskuret som ett dockhus (golven och
## låga väggkrön), så att det inte skymmer framsidan bakom.
static func _building(floor_name: String) -> void:
	var site_id: String = FLOORS[floor_name]["site"]
	var open_air := _is_open_air(floor_name)
	if _level == 0.0 and not open_air:
		for room in _lot_rooms(floor_name):
			_slab_box(room.grow(StyleKit.WALL + 0.04), _grade - 0.05, -0.02, StyleKit.mat(FOUNDATION), true)
		_front_steps(floor_name)
	for other in FLOORS:
		if FLOORS[other]["site"] != site_id or _is_open_air(other):
			continue
		var other_level := _floor_at(other).y
		if other_level < 0.0 or (other_level >= _level and not open_air):
			continue
		if open_air and other_level > 0.0:
			continue
		_storey(other, _grade if other_level == 0.0 else other_level - 0.12, other_level + STOREY - 0.12, open_air)


## En våning sedd utifrån: ett block per rum med fasad, platt tak, fönstren där de sitter
## inne i rummen (tända på kvällen) och ytterdörrarna med trappsteg. Med `cut` (sedd från
## gårdarna) visas alla rum avskurna.
static func _storey(floor_name: String, bottom: float, top: float, cut := false) -> void:
	var at := _floor_at(floor_name)
	var plans: Dictionary = PlanDrawer.FLOOR_PLANS[floor_name]
	var walls: Material = facade(floor_name)
	for room_id in plans:
		var plan: Rect2 = plans[room_id]
		plan.position += Vector2(at.x, at.z)
		var outer := plan.grow(StyleKit.WALL + 0.03)
		if cut or (_front.intersects(outer) and top > _front_top):
			# Framför kameran: rummet visas avskuret, med golvet synligt.
			if cut or at.y + StyleKit.CUT_HEIGHT <= _front_top:
				_cutaway(plan, at.y, StyleKit.floor_mat(FloorPlanArt.FLOOR_MATERIALS.get(room_id, "wood")))
			continue
		_slab_box(outer, bottom, top, walls, true)
		_slab_box(outer.grow(0.04), top, top + 0.06, StyleKit.mat(FLAT_ROOF, 0.0, 7, 1.0), true)
		if at.y == 0.0:
			_slab_box(outer.grow(0.03), _grade - 0.05, bottom + 0.3, StyleKit.mat(FOUNDATION), true)
		for window in FloorPlanArt.windows(room_id):
			var side: String = window["side"]
			if StyleKit.is_interior(plans, room_id, side):
				continue
			var mid: float = window["start"] + window["width"] / 2.0
			_facade_window(_wall_point(outer, side, mid + 0.03 + StyleKit.WALL, at.y + (window["sill"] + window["top"]) / 2), _outward(side), window["width"], window["top"] - window["sill"], not window["frosted"])
		for door in PlanDrawer.exterior_doors(room_id):
			var side: String = door["side"]
			var offset: float = door["at"] + 0.03 + StyleKit.WALL
			# Ytterdörren i blågrått; dörrar ut till trädgården är glasade.
			var color := Color(0.42, 0.55, 0.62) if door["front"] else GLASS
			_door(_wall_point(outer, side, offset, at.y + StyleKit.DOOR_HEIGHT / 2), _outward(side), color, null, door["width"])
	# Trappsteg upp till ytterdörrarna (också när man står inne i huset).
	_front_steps(floor_name)


static func _front_steps(floor_name: String) -> void:
	if _floor_at(floor_name).y != 0.0:
		return
	var plans: Dictionary = PlanDrawer.FLOOR_PLANS[floor_name]
	for room_id in plans:
		for door in PlanDrawer.exterior_doors(room_id):
			_door_steps(plans[room_id], door)


## Trappsteg från en ytterdörr ned till marken.
static func _door_steps(plan: Rect2, door: Dictionary) -> void:
	var out := _outward(door["side"])
	var door_at := _wall_point(plan, door["side"], door["at"], 0) + out * (StyleKit.WALL + 0.03)
	var stone := StyleKit.mat(PAVING.darkened(0.04), 0.0, 1, 0.5)
	var span: float = door["width"] + 0.6
	var steps := 3
	for i in steps:
		var depth := 0.32 * (steps - i)
		var height := _grade - _grade * (i + 1) / steps - 0.02
		var center := door_at + out * depth / 2
		var size := Vector3(span, 0, depth) if absf(out.z) > 0.5 else Vector3(depth, 0, span)
		_slab_box(Rect2(center.x - size.x / 2, center.z - size.z / 2, size.x, size.z), _grade - 0.05, height, stone, true)


static func _outward(side: String) -> Vector3:
	return {"north": Vector3(0, 0, -1), "south": Vector3(0, 0, 1), "west": Vector3(-1, 0, 0), "east": Vector3(1, 0, 0)}[side]


## En punkt på utsidan av en rektangels sida, `along` meter från sidans början.
static func _wall_point(rect: Rect2, side: String, along: float, y: float) -> Vector3:
	match side:
		"north":
			return Vector3(rect.position.x + along, y, rect.position.y)
		"south":
			return Vector3(rect.position.x + along, y, rect.end.y)
		"west":
			return Vector3(rect.position.x, y, rect.position.y + along)
	return Vector3(rect.end.x, y, rect.position.y + along)


## Ett fönster på en fasad: vit karm, glas och spröjs. Tända fönster lyser varmt på
## kvällen och natten (riggen).
static func _facade_window(center: Vector3, outward: Vector3, width: float, height: float, lit: bool, parent: Node3D = null) -> void:
	if parent == null:
		parent = _root
	var across := absf(outward.z) > 0.5
	var frame := StyleKit.mat(StyleKit.WHITE)
	StyleKit.box(parent, Vector3(width + 0.14, height + 0.14, 0.04) if across else Vector3(0.04, height + 0.14, width + 0.14), center + outward * 0.02, frame, false, 0.0)
	StyleKit.box(parent, Vector3(width, height, 0.04) if across else Vector3(0.04, height, width), center + outward * 0.035, _lit_glass if lit else StyleKit.mat(GLASS, 0.6), false, 0.0)
	StyleKit.box(parent, Vector3(0.05, height, 0.05) if across else Vector3(0.05, height, 0.05), center + outward * 0.05, frame, false, 0.0)
	StyleKit.box(parent, Vector3(width + 0.24, 0.05, 0.12) if across else Vector3(0.12, 0.05, width + 0.24), center + outward * 0.06 - Vector3(0, height / 2 + 0.03, 0), frame, false, 0.0)


## En ytterdörr med karm.
static func _door(center: Vector3, outward: Vector3, color := Color(0.42, 0.55, 0.62), parent: Node3D = null, width := 0.9) -> void:
	if parent == null:
		parent = _root
	var across := absf(outward.z) > 0.5
	StyleKit.box(parent, Vector3(width + 0.16, 2.16, 0.05) if across else Vector3(0.05, 2.16, width + 0.16), center + outward * 0.02 + Vector3(0, 0.03, 0), StyleKit.mat(StyleKit.WHITE), false, 0.0)
	StyleKit.box(parent, Vector3(width, 2.08, 0.05) if across else Vector3(0.05, 2.08, width), center + outward * 0.04, StyleKit.mat(color, 0.2), false, 0.0)
	if width > 1.2:
		# Dubbeldörr: en post i mitten.
		StyleKit.box(parent, Vector3(0.06, 2.08, 0.06) if across else Vector3(0.06, 2.08, 0.06), center + outward * 0.06, StyleKit.mat(StyleKit.WHITE), false, 0.0)
	StyleKit.sphere(parent, 0.035, center + outward * 0.08 + (Vector3(width * 0.36, 0, 0) if across else Vector3(0, 0, width * 0.36)), StyleKit.mat(StyleKit.BRASS, 0.8))


# --- Byggnader på tomten ------------------------------------------------------

## Om något på en yta, med en viss topphöjd, får stå där: inte i rummen och inte högt
## mellan kameran och våningen.
static func _free(rect: Rect2, top: float) -> bool:
	for taken in _taken:
		if taken.intersects(rect):
			return false
	return not (top > _front_top and _front.intersects(rect))


## Ett hus med sadeltak, fönster på varje våning och en dörr. Står det framför kameran
## skärs det av som de södra väggarna.
static func _house(rect: Rect2, storeys: int, color: Color, door_side: String, roof := ROOF, storey_height := STOREY) -> void:
	for taken in _taken:
		if taken.intersects(rect):
			return
	var height := storeys * storey_height
	if _front.intersects(rect) and _grade + height > _front_top:
		# Framför kameran: huset skärs av som ett dockhus, med golvet synligt.
		var floor_top := minf(_grade + 0.45, _front_top - StyleKit.CUT_HEIGHT)
		if floor_top > _grade + 0.05:
			_cutaway(rect.grow(-StyleKit.WALL), floor_top, StyleKit.floor_mat("wood"))
		return
	var node := Node3D.new()
	_root.add_child(node)
	var walls := _siding(color)
	StyleKit.box(node, Vector3(rect.size.x, height, rect.size.y), Vector3(rect.get_center().x, _grade + height / 2, rect.get_center().y), walls, true, 0.0)
	StyleKit.box(node, Vector3(rect.size.x + 0.08, 0.35, rect.size.y + 0.08), Vector3(rect.get_center().x, _grade + 0.15, rect.get_center().y), StyleKit.mat(FOUNDATION), true, 0.0)
	_gable(node, rect, _grade + height, roof, walls)
	var door_along := -1.0
	if door_side != "":
		var length := rect.size.x if door_side in ["north", "south"] else rect.size.y
		door_along = length * 0.35
		_door(_wall_point(rect, door_side, door_along, _grade + 0.3 + StyleKit.DOOR_HEIGHT / 2), _outward(door_side), color.darkened(0.45), node)
		var step := _wall_point(rect, door_side, door_along, 0) + _outward(door_side) * 0.3
		StyleKit.box(node, Vector3(1.3, 0.3, 0.6) if door_side in ["north", "south"] else Vector3(0.6, 0.3, 1.3), Vector3(step.x, _grade + 0.15, step.z), StyleKit.mat(PAVING.darkened(0.05)), true, 0.0)
	for s in storeys:
		var y := _grade + 0.3 + s * storey_height + storey_height * 0.55
		for side in ["north", "south", "west", "east"]:
			var length := rect.size.x if side in ["north", "south"] else rect.size.y
			var count := maxi(1, int(length / 2.6))
			for i in count:
				var along := length * (i + 0.5) / count
				if side == door_side and s == 0 and absf(along - door_along) < 1.0:
					continue
				_facade_window(_wall_point(rect, side, along, y), _outward(side), 0.9, 1.1, _rng.randf() < 0.55, node)


## Sadeltak över en rektangel, med nocken längs den längre sidan och gavlar i väggfärg.
static func _gable(parent: Node3D, rect: Rect2, base: float, roof: Color, walls: Material) -> void:
	var along_x := rect.size.x >= rect.size.y
	var length := (rect.size.x if along_x else rect.size.y) + 0.5
	var span := (rect.size.y if along_x else rect.size.x) + 0.6
	var wall_length := length - 0.5
	var rise := span * 0.36
	var l := length / 2
	var s := span / 2
	var b := -rise / 2
	var t := rise / 2
	var slopes := SurfaceTool.new()
	slopes.begin(Mesh.PRIMITIVE_TRIANGLES)
	StyleKit._polygon(slopes, [Vector3(-l, b, -s), Vector3(l, b, -s), Vector3(l, t, 0), Vector3(-l, t, 0)])
	StyleKit._polygon(slopes, [Vector3(-l, b, s), Vector3(l, b, s), Vector3(l, t, 0), Vector3(-l, t, 0)])
	StyleKit._polygon(slopes, [Vector3(-l, b, -s), Vector3(l, b, -s), Vector3(l, b, s), Vector3(-l, b, s)])
	var ends := SurfaceTool.new()
	ends.begin(Mesh.PRIMITIVE_TRIANGLES)
	var g := wall_length / 2
	var inset := s - 0.3
	for x in [-g, g]:
		StyleKit._polygon(ends, [Vector3(x, b, -inset), Vector3(x, b, inset), Vector3(x, t - 0.02, 0)])
	var at := Vector3(rect.get_center().x, base + rise / 2, rect.get_center().y)
	var roof_mesh := StyleKit.add(parent, slopes.commit(), at, StyleKit.mat(roof, 0.0, 6, 0.3, roof.darkened(0.15)))
	var end_mesh := StyleKit.add(parent, ends.commit(), at, walls)
	if not along_x:
		roof_mesh.rotation_degrees.y = 90
		end_mesh.rotation_degrees.y = 90


## Ett lågt kommersiellt block med platt tak och kant, med fönsterrader eller skyltfönster
## med markis mot `front`.
static func _block(rect: Rect2, height: float, color: Color, rows: int, front := "", awning := Color(0, 0, 0, 0), brick := false) -> void:
	for taken in _taken:
		if taken.intersects(rect):
			return
	if _front.intersects(rect) and _grade + height > _front_top:
		var floor_top := minf(_grade + 0.15, _front_top - StyleKit.CUT_HEIGHT)
		if floor_top > _grade + 0.05:
			_cutaway(rect.grow(-StyleKit.WALL), floor_top, StyleKit.floor_mat("tile"))
		return
	var node := Node3D.new()
	_root.add_child(node)
	StyleKit.box(node, Vector3(rect.size.x, height, rect.size.y), Vector3(rect.get_center().x, _grade + height / 2, rect.get_center().y), _siding(color, brick), true, 0.0)
	StyleKit.box(node, Vector3(rect.size.x + 0.12, 0.25, rect.size.y + 0.12), Vector3(rect.get_center().x, _grade + height, rect.get_center().y), StyleKit.mat(color.darkened(0.3)), true, 0.0)
	StyleKit.box(node, Vector3(rect.size.x - 0.2, 0.05, rect.size.y - 0.2), Vector3(rect.get_center().x, _grade + height + 0.1, rect.get_center().y), StyleKit.mat(FLAT_ROOF, 0.0, 7, 1.0), true, 0.0)
	for side in ["north", "south", "west", "east"]:
		var length := rect.size.x if side in ["north", "south"] else rect.size.y
		if side == front and awning.a > 0:
			# Skyltfönster med markis och skylt.
			var shops := maxi(1, int(length / 4.0))
			for i in shops:
				var along := length * (i + 0.5) / shops
				var base := _wall_point(rect, side, along, _grade + 1.3)
				_facade_window(base, _outward(side), length / shops - 1.0, 2.0, true, node)
				var tint: Color = awning if i % 2 == 0 else awning.lerp(Color.WHITE, 0.45)
				var canopy := StyleKit.box(node, Vector3(length / shops - 0.6, 0.06, 1.1) if side in ["north", "south"] else Vector3(1.1, 0.06, length / shops - 0.6),
						base + _outward(side) * 0.55 + Vector3(0, 1.3, 0), StyleKit.mat(tint), true)
				canopy.rotation_degrees = Vector3(12 if side == "north" else (-12 if side == "south" else 0), 0, 12 if side == "east" else (-12 if side == "west" else 0))
				StyleKit.box(node, Vector3(length / shops * 0.5, 0.5, 0.08) if side in ["north", "south"] else Vector3(0.08, 0.5, length / shops * 0.5),
						base + _outward(side) * 0.05 + Vector3(0, 2.2, 0), StyleKit.mat(tint.lightened(0.2)), true)
			continue
		var count := maxi(1, int(length / 3.0))
		for row in rows:
			for i in count:
				var along := length * (i + 0.5) / count
				_facade_window(_wall_point(rect, side, along, _grade + 1.5 + row * STOREY), _outward(side), 1.6, 1.2, _rng.randf() < 0.5, node)


# --- Saker på tomten ----------------------------------------------------------

## Ett träd i full storlek (FurnitureKit-trädet uppskalat).
static func _tree(x: float, z: float, size := 1.6) -> void:
	var r := 0.6 * size
	if not _free(Rect2(x - r, z - r, r * 2, r * 2), _grade + 2.5 * size):
		return
	var node := Node3D.new()
	node.position = Vector3(x, _grade, z)
	node.scale = Vector3.ONE * size
	node.rotation.y = _rng.randf() * TAU
	_root.add_child(node)
	FurnitureKit.build(node, _rig, "tree", 1.2, 1.2)


## Ett träd långt bort: stam och tre stora kronor, utan skuggor.
static func _far_tree(x: float, z: float, size: float) -> void:
	var node := Node3D.new()
	node.position = Vector3(x, _grade, z)
	node.scale = Vector3.ONE * size
	_root.add_child(node)
	var leaf := StyleKit.mat(FAR_LEAF.lightened(_rng.randf() * 0.12))
	StyleKit.cylinder(node, 0.1, 0.14, 1.2, Vector3(0, 0.6, 0), StyleKit.mat(StyleKit.WALNUT), 8).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 3:
		var angle := TAU * i / 3.0
		StyleKit.sphere(node, 0.75, Vector3(cos(angle) * 0.4, 1.8 + i * 0.2, sin(angle) * 0.4), leaf).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Trädridån långt bort, runt hela platsen utom mellan kameran och våningen.
static func _far_ring() -> void:
	var center := _bbox.get_center()
	for i in 70:
		var angle := _rng.randf_range(PI * 0.9, PI * 2.1)
		var r := _rng.randf_range(36.0, 62.0)
		var p := center + Vector2(cos(angle), sin(angle)) * r
		if _front.has_point(p):
			continue
		_far_tree(p.x, p.y, _rng.randf_range(2.0, 3.4))


## En låg häck.
static func _hedge(rect: Rect2, height := 0.7) -> void:
	if not _free(rect, _grade + height):
		return
	StyleKit.box(_root, Vector3(rect.size.x, height, rect.size.y), Vector3(rect.get_center().x, _grade + height / 2, rect.get_center().y), StyleKit.mat(HEDGE), true, 0.08)


## En rabatt: kant av jord med gröna tuvor och blommor i några färger.
static func _flower_bed(rect: Rect2) -> void:
	if not _free(rect, _grade + 0.4):
		return
	_slab_box(rect, _grade - 0.05, _grade + 0.12, StyleKit.mat(SOIL.darkened(0.1)), true)
	var long_x := rect.size.x >= rect.size.y
	var length := maxf(rect.size.x, rect.size.y)
	var count := int(length / 0.32)
	for i in count:
		var t := (i + 0.5) / count
		var at := Vector3(rect.position.x + (rect.size.x * t if long_x else rect.size.x / 2), _grade + 0.2, rect.position.y + (rect.size.y / 2 if long_x else rect.size.y * t))
		StyleKit.sphere(_root, 0.14, at, StyleKit.mat(StyleKit.LEAF.lightened(0.05 * (i % 3))))
		StyleKit.sphere(_root, 0.07, at + Vector3(_rng.randf_range(-0.06, 0.06), 0.12, _rng.randf_range(-0.06, 0.06)), StyleKit.mat(FLOWERS[i % FLOWERS.size()]))


## En gatlykta som lyser på kvällen och natten.
static func _lamp(x: float, z: float) -> void:
	if not _free(Rect2(x - 0.3, z - 0.3, 0.6, 0.6), _grade + 3.4):
		return
	var node := Node3D.new()
	node.position = Vector3(x, _grade, z)
	_root.add_child(node)
	var iron := StyleKit.mat(StyleKit.DARK.lightened(0.1), 0.3)
	StyleKit.cylinder(node, 0.05, 0.07, 3.2, Vector3(0, 1.6, 0), iron, 10)
	StyleKit.cylinder(node, 0.12, 0.14, 0.2, Vector3(0, 0.1, 0), iron, 10)
	var shade := StyleKit.own_mat(Color(1.0, 0.94, 0.8))
	shade.set_shader_parameter("emission", Color(1.0, 0.85, 0.6))
	StyleKit.cylinder(node, 0.14, 0.22, 0.32, Vector3(0, 3.3, 0), shade, 10)
	StyleKit.cylinder(node, 0.05, 0.24, 0.12, Vector3(0, 3.5, 0), iron, 10)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 3.1, 0)
	light.light_color = Color(1.0, 0.8, 0.55)
	light.omni_range = 8.0
	node.add_child(light)
	_rig.register_lamp(light, shade, 1.8)


## En bil: kaross, kupé med rutor, hjul och lyktor. `along_x` = parkerad längs x.
static func _car(x: float, z: float, color: Color, along_x: bool) -> void:
	var w := 1.15
	var d := 2.5
	var rect := Rect2(x - d / 2, z - w / 2, d, w) if along_x else Rect2(x - w / 2, z - d / 2, w, d)
	if not _free(rect, _grade + 1.0):
		return
	var n := Node3D.new()
	n.position = Vector3(x, _grade, z)
	n.rotation_degrees.y = 90 if along_x else 0
	_root.add_child(n)
	StyleKit.box(n, Vector3(w, 0.45, d), Vector3(0, 0.4, 0), StyleKit.mat(color, 0.6), true, 0.08)
	StyleKit.box(n, Vector3(w * 0.86, 0.38, d * 0.5), Vector3(0, 0.8, -d * 0.04), StyleKit.mat(color.lightened(0.05), 0.6), true, 0.08)
	StyleKit.box(n, Vector3(w * 0.88, 0.28, d * 0.46), Vector3(0, 0.8, -d * 0.04), StyleKit.mat(Color(0.7, 0.85, 0.95), 0.9), true, 0.05)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			StyleKit.cylinder(n, 0.17, 0.17, 0.14, Vector3(sx * w / 2, 0.17, sz * d * 0.32), StyleKit.mat(StyleKit.DARK), 16).rotation_degrees = Vector3(0, 0, 90)
	for sx in [-1, 1]:
		StyleKit.box(n, Vector3(0.16, 0.06, 0.02), Vector3(sx * w * 0.3, 0.45, d / 2 + 0.005), StyleKit.mat(Color(1.0, 0.95, 0.75), 0.9), false, 0.0)


## En möbel ur FurnitureKit ute på tomten (bänk, cykel, damm ...).
static func _prop(kind: String, x: float, z: float, w: float, d: float, turn := 0.0, top := 1.0) -> void:
	var half := maxf(w, d) / 2
	if not _free(Rect2(x - half, z - half, half * 2, half * 2), _grade + top):
		return
	var node := Node3D.new()
	node.position = Vector3(x, _grade, z)
	node.rotation_degrees.y = turn
	_root.add_child(node)
	FurnitureKit.build(node, _rig, kind, w, d)


## Trottoar, gata med streckad mittlinje och trottoar på andra sidan, längs x. `z` är
## den närmaste trottoarens kant mot tomten.
static func _street(z: float, x0 := -70.0, x1 := 90.0) -> void:
	var walk := StyleKit.mat(PAVING, 0.0, 1, 1.6, PAVING.darkened(0.12))
	var curb := StyleKit.mat(PAVING.darkened(0.08))
	_paving(Rect2(x0, z - 1.8, x1 - x0, 1.8), walk, 0.1)
	_paving(Rect2(x0, z - 1.86, x1 - x0, 0.12), curb, 0.12)
	_paving(Rect2(x0, z - 8.2, x1 - x0, 6.4), StyleKit.mat(ASPHALT, 0.0, 7, 1.5), 0.0)
	var line := StyleKit.mat(Color(0.97, 0.95, 0.88))
	var x := x0
	while x < x1:
		_paving(Rect2(x, z - 5.08, 2.2, 0.16), line, 0.01)
		x += 4.5
	_paving(Rect2(x0, z - 10.0, x1 - x0, 1.8), walk, 0.1)
	_paving(Rect2(x0, z - 8.34, x1 - x0, 0.12), curb, 0.12)


## En rad villor längs gatans andra sida, med träd framför. `z` = husens framsida.
static func _houses_across(z: float, x0: float, x1: float) -> void:
	var x := x0
	var i := 0
	while x < x1:
		var width := 8.0 + _rng.randf() * 3.0
		_house(Rect2(x, z - 7.5, width, 7.5), 2 if i % 3 != 1 else 1, HOUSE_COLORS[i % HOUSE_COLORS.size()], "south")
		_tree(x + width + 1.5, z + 1.8, 1.4 + _rng.randf() * 0.5)
		x += width + 5.0
		i += 1


# --- Platserna ----------------------------------------------------------------

## Hemma: tomten runt huset. Gårdarna (framsidan och trädgården) byggs ur planen; här
## kommer resten: gatan med trottoar och villor på andra sidan i norr, uppfartens
## anslutning och brevlådan, stigen längs husets västra sida från uppfarten till
## trädgårdsgrinden (förbi köksdörren), en rabatt längs östra gaveln, häckar längs
## tomtgränserna och grannarnas hus på sidorna. Bakom trädgården (mot kameran) bara låga
## saker.
static func _home() -> void:
	var plans: Dictionary = PlanDrawer.FLOOR_PLANS["Entréplan"]
	var house := Rect2()
	for room_id in plans:
		house = plans[room_id] if house.size == Vector2.ZERO else house.merge(plans[room_id])
	_taken.append(house.grow(StyleKit.WALL + 0.05))
	var shift := Vector2(_floor_at("Utanför").x, _floor_at("Utanför").z)
	var front: Rect2 = PlanDrawer.FLOOR_PLANS["Utanför"]["outside"]
	var back: Rect2 = PlanDrawer.FLOOR_PLANS["Utanför"]["backyard"]
	front.position += shift
	back.position += shift
	var lot := front.merge(back)
	var stone := StyleKit.mat(PAVING.darkened(0.03), 0.0, 1, 0.5)
	# Gatan i norr, med trottoaren precis utanför tomtens staket.
	var street_z := front.position.y - 0.15
	_street(street_z)
	_houses_across(street_z - 11.5, lot.position.x - 26.0, lot.end.x + 26.0)
	var driveway := FloorPlanArt.furniture_rect("outside", "driveway")
	driveway.position += front.position
	var path := FloorPlanArt.furniture_rect("outside", "path")
	path.position += front.position
	# Uppfarten och gången fortsätter över trottoaren ut till gatan.
	_slab_box(Rect2(driveway.position.x, street_z - 1.86, driveway.size.x, 1.86), _grade - 0.05, _grade + 0.11, StyleKit.mat(ASPHALT.lightened(0.1), 0.0, 7, 1.5))
	_mailbox(path.end.x + 0.9, street_z - 0.35)
	_lamp(lot.position.x + 1.0, street_z - 0.9)
	_lamp(lot.end.x - 1.0, street_z - 0.9)
	_car(lot.end.x + 3.0, street_z - 3.0, CAR_COLORS[0], true)
	_car(lot.position.x - 10.0, street_z - 6.0, CAR_COLORS[3], true)
	# Västra sidan: stigen från uppfarten längs huset, förbi köksdörren, till grinden.
	var side_path := Rect2(house.position.x - 1.5, front.end.y + 0.15, 1.2, back.position.y - front.end.y - 0.3)
	_paving(side_path, stone, 0.03)
	var gate_z := back.position.y - 0.25
	if _level < _grade:
		return  # Från källaren är allt söder om huset avskuret.
	var white := StyleKit.mat(StyleKit.WHITE)
	StyleKit._fence(_root, Vector3(lot.position.x, _grade, gate_z), Vector3(1, 0, 0), side_path.position.x - lot.position.x)
	StyleKit._fence(_root, Vector3(side_path.end.x, _grade, gate_z), Vector3(1, 0, 0), house.position.x - side_path.end.x - StyleKit.WALL)
	# Grindstolpar där stigen går in i trädgården.
	for x in [side_path.position.x, side_path.end.x]:
		StyleKit.box(_root, Vector3(0.09, 0.6, 0.09), Vector3(x, _grade + 0.3, gate_z), white)
	# Östra sidan: ett stängt staket mot trädgården och en rabatt längs gaveln.
	StyleKit._fence(_root, Vector3(house.end.x + StyleKit.WALL, _grade, gate_z), Vector3(1, 0, 0), lot.end.x - house.end.x - StyleKit.WALL)
	_flower_bed(Rect2(house.end.x + 0.3, house.position.y + 0.6, 0.55, house.size.y - 1.4))
	# Tomtgränserna: häckar från gatan till trädgårdens slut, och en låg häck bakom.
	_hedge(Rect2(lot.position.x - 0.75, front.position.y + 0.2, 0.6, lot.size.y - 0.2), 1.1)
	_hedge(Rect2(lot.end.x + 0.15, front.position.y + 0.2, 0.6, lot.size.y - 0.2), 1.1)
	_hedge(Rect2(lot.position.x - 6.0, lot.end.y + 0.2, lot.size.x + 12.0, 0.5), 0.6)
	# Grannarna på var sida, med träd mellan tomterna.
	_house(Rect2(lot.position.x - 13.5, house.position.y - 1.0, 10.0, 9.0), 2, HOUSE_COLORS[1], "north")
	_house(Rect2(lot.end.x + 3.5, house.position.y - 1.0, 10.0, 9.0), 2, HOUSE_COLORS[2], "north")
	_tree(lot.position.x - 2.2, front.get_center().y, 1.6)
	_tree(lot.end.x + 2.2, front.get_center().y + 1.0, 1.4)
	_tree(lot.position.x - 2.5, back.position.y + 2.0, 1.5)
	_tree(lot.end.x + 2.4, back.position.y + 1.5, 1.6)


## Brevlådan vid trottoaren.
static func _mailbox(x: float, z: float) -> void:
	if not _free(Rect2(x - 0.2, z - 0.2, 0.4, 0.4), _grade + 1.2):
		return
	StyleKit.box(_root, Vector3(0.08, 1.0, 0.08), Vector3(x, _grade + 0.5, z), StyleKit.mat(StyleKit.WALNUT))
	StyleKit.box(_root, Vector3(0.3, 0.24, 0.42), Vector3(x, _grade + 1.08, z), StyleKit.mat(Color(0.25, 0.42, 0.58), 0.4), true, 0.04)
	StyleKit.box(_root, Vector3(0.03, 0.14, 0.06), Vector3(x + 0.17, _grade + 1.16, z + 0.08), StyleKit.mat(Color(0.9, 0.35, 0.3)))


## Skolan: skolgården med basketplan, flaggstång och cykelställ framför (norr), flyglar på
## sidorna och gatan bortom staketet.
static func _school() -> void:
	var b := _bbox
	var site_color: Color = _site["siding"]
	var yard := Rect2(b.position.x - 14.0, b.position.y - 18.0, b.size.x + 28.0, 17.6)
	_paving(yard, StyleKit.mat(ASPHALT.lightened(0.12), 0.0, 7, 1.5))
	var court := Rect2(b.get_center().x - 7.0, b.position.y - 14.5, 14.0, 8.0)
	var paint := StyleKit.mat(Color(0.97, 0.96, 0.92))
	_paving(court, StyleKit.mat(Color(0.86, 0.55, 0.45), 0.0, 7, 2.0), 0.03)
	for rect in [Rect2(court.position.x, court.position.y, court.size.x, 0.12), Rect2(court.position.x, court.end.y - 0.12, court.size.x, 0.12),
			Rect2(court.position.x, court.position.y, 0.12, court.size.y), Rect2(court.end.x - 0.12, court.position.y, 0.12, court.size.y),
			Rect2(court.get_center().x - 0.06, court.position.y, 0.12, court.size.y),
			Rect2(court.position.x, court.get_center().y - 1.2, 2.4, 2.4), Rect2(court.end.x - 2.4, court.get_center().y - 1.2, 2.4, 2.4)]:
		_paving(rect, paint, 0.04)
	for side in [-1, 1]:
		_hoop(court.get_center().x + side * (court.size.x / 2 - 0.4), court.get_center().y, -side)
	_flagpole(b.position.x - 2.0, b.position.y - 2.5)
	for i in 4:
		_prop("bike", b.end.x + 0.8 + i * 0.7, b.position.y - 1.6, 1.3, 0.55, 90.0)
	_prop("bench", b.position.x - 2.5, b.position.y - 9.0, 1.4, 0.5, 90.0)
	_prop("bench", b.end.x + 6.0, b.position.y - 10.0, 1.4, 0.5, -90.0)
	for p in [Vector2(-11, -15), Vector2(-11, -9), Vector2(11, -16), Vector2(12, -9)]:
		_tree((b.position.x if p.x < 0 else b.end.x) + p.x, b.position.y + p.y, 1.7)
	var fence_z := yard.position.y - 0.3
	StyleKit._fence(_root, Vector3(yard.position.x, _grade, fence_z), Vector3(1, 0, 0), yard.size.x)
	_street(fence_z - 0.6)
	_houses_across(fence_z - 12.5, yard.position.x - 10.0, yard.end.x + 10.0)
	_lamp(b.position.x - 8.0, fence_z - 1.4)
	_lamp(b.end.x + 8.0, fence_z - 1.4)
	# Flyglarna: samma tegel, två våningar, med en gård emellan. De slutar i linje med
	# klassrummen, så att de inte står mellan kameran och rummen.
	_block(Rect2(b.position.x - 14.0, b.position.y - 6.0, 10.0, b.size.y + 6.0), STOREY * 2, site_color, 2, "", Color(0, 0, 0, 0), true)
	_block(Rect2(b.end.x + 4.0, b.position.y - 6.0, 10.0, b.size.y + 6.0), STOREY * 2, site_color, 2, "", Color(0, 0, 0, 0), true)
	_flower_bed(Rect2(b.position.x + 0.3, b.position.y - 0.8, 3.0, 0.45))


## En basketkorg: stolpe, platta och ring, vänd mot planen (`facing` ±1 längs x).
static func _hoop(x: float, z: float, facing: float) -> void:
	if not _free(Rect2(x - 0.4, z - 0.4, 0.8, 0.8), _grade + 3.4):
		return
	StyleKit.cylinder(_root, 0.06, 0.08, 3.0, Vector3(x - facing * 0.35, _grade + 1.5, z), StyleKit.mat(StyleKit.METAL, 0.4), 10)
	StyleKit.box(_root, Vector3(0.06, 1.0, 1.6), Vector3(x, _grade + 3.0, z), StyleKit.mat(StyleKit.WHITE), true, 0.02)
	StyleKit.box(_root, Vector3(0.08, 0.4, 0.5), Vector3(x + facing * 0.01, _grade + 2.85, z), StyleKit.mat(Color(0.86, 0.4, 0.3)), true, 0.0)
	StyleKit.cylinder(_root, 0.24, 0.24, 0.04, Vector3(x + facing * 0.3, _grade + 2.7, z), StyleKit.mat(Color(0.95, 0.5, 0.25)), 16)


## En flaggstång med en flagga som vajar (riggen).
static func _flagpole(x: float, z: float) -> void:
	if not _free(Rect2(x - 0.3, z - 0.3, 0.6, 0.6), _grade + 6.0):
		return
	StyleKit.cylinder(_root, 0.04, 0.06, 6.0, Vector3(x, _grade + 3.0, z), StyleKit.mat(StyleKit.WHITE, 0.3), 10)
	StyleKit.sphere(_root, 0.08, Vector3(x, _grade + 6.05, z), StyleKit.mat(StyleKit.BRASS, 0.8))
	var flag := Node3D.new()
	flag.position = Vector3(x, _grade + 5.5, z)
	_root.add_child(flag)
	StyleKit.box(flag, Vector3(1.3, 0.8, 0.03), Vector3(0.68, 0, 0), StyleKit.mat(Color(0.35, 0.55, 0.85)), true, 0.0)
	StyleKit.box(flag, Vector3(1.3, 0.18, 0.035), Vector3(0.68, 0, 0), StyleKit.mat(Color(0.98, 0.86, 0.4)), true, 0.0)
	_rig.register_sway(flag)


## Grannen: vardagsrummet är en flygel med trädgård runt, resten av huset är avskuret
## framför kameran. Vårt eget hus syns i väster, och flyttbilen står på gatan.
static func _neighbor() -> void:
	var b := _bbox
	var site_color: Color = _site["siding"]
	_house(Rect2(b.position.x - 1.0, b.end.y + 0.25, b.size.x + 2.0, 4.0), 1, site_color, "")
	var street_z := b.position.y - 6.0
	_paving(Rect2(b.get_center().x - 0.45, street_z, 0.9, 6.0 - 0.2), StyleKit.mat(PAVING.darkened(0.03), 0.0, 1, 0.5))
	_street(street_z)
	_houses_across(street_z - 11.5, b.position.x - 32.0, b.end.x + 32.0)
	_moving_truck(b.end.x + 1.0, street_z - 3.0)
	for i in 4:
		var size := 0.4 + (i % 2) * 0.15
		_slab_box(Rect2(b.end.x + 1.0 + i * 0.6, street_z + 1.2 + (i % 2) * 0.5, size, size), _grade, _grade + size * 0.8, StyleKit.mat(Color(0.8, 0.65, 0.45)), true)
	_lamp(b.position.x - 3.0, street_z - 0.9)
	_lamp(b.end.x + 9.0, street_z - 0.9)
	# Vårt hus i väster, i husets egen färg, med en häck mellan tomterna.
	_hedge(Rect2(b.position.x - 4.5, street_z + 0.4, 0.6, b.size.y + 12.0), 0.8)
	_house(Rect2(b.position.x - 21.5, b.position.y - 5.0, 15.6, 9.0), 2, SITES["home"]["siding"], "north")
	_house(Rect2(b.end.x + 8.5, b.position.y - 4.5, 9.0, 9.0), 2, HOUSE_COLORS[3], "north")
	_tree(b.position.x - 2.0, b.position.y - 2.5, 1.5)
	_tree(b.end.x + 4.5, b.position.y - 1.5, 1.3)
	_flower_bed(Rect2(b.position.x + 0.3, b.position.y - 0.8, b.size.x - 0.6, 0.45))
	_prop("bench", b.end.x + 1.4, b.position.y + 3.8, 1.2, 0.45, -90.0, 0.0)


## Flyttbilen: hytt och skåp, parkerad längs gatan.
static func _moving_truck(x: float, z: float) -> void:
	if not _free(Rect2(x - 3.0, z - 1.2, 6.0, 2.4), _grade + 3.0):
		return
	var n := Node3D.new()
	n.position = Vector3(x, _grade, z)
	_root.add_child(n)
	StyleKit.box(n, Vector3(4.0, 2.4, 2.1), Vector3(-0.8, 1.6, 0), StyleKit.mat(StyleKit.WHITE), true, 0.05)
	StyleKit.box(n, Vector3(4.0, 0.4, 2.12), Vector3(-0.8, 1.6, 0), StyleKit.mat(Color(0.9, 0.55, 0.35)), true, 0.0)
	StyleKit.box(n, Vector3(1.5, 1.6, 2.0), Vector3(2.0, 1.2, 0), StyleKit.mat(Color(0.9, 0.55, 0.35), 0.5), true, 0.08)
	StyleKit.box(n, Vector3(0.05, 0.7, 1.8), Vector3(2.76, 1.55, 0), StyleKit.mat(Color(0.7, 0.85, 0.95), 0.9), true, 0.0)
	for wx in [-2.2, 0.6, 2.1]:
		for wz in [-1, 1]:
			StyleKit.cylinder(n, 0.38, 0.38, 0.22, Vector3(wx, 0.38, wz * 1.0), StyleKit.mat(StyleKit.DARK), 16).rotation_degrees = Vector3(90, 0, 0)


## Parkering med rutor, bilar, lyktor och trädöar framför (norr), en gata bortom.
static func _parking(b: Rect2, depth: float) -> float:
	var lot := Rect2(b.position.x - 12.0, b.position.y - depth, b.size.x + 24.0, depth - 0.4)
	_paving(lot, StyleKit.mat(ASPHALT, 0.0, 7, 1.5))
	var paint := StyleKit.mat(Color(0.97, 0.96, 0.92))
	for row in 2:
		var z := lot.position.y + 2.0 + row * 7.5
		var x := lot.position.x + 1.0
		var i := 0
		while x < lot.end.x - 2.6:
			_paving(Rect2(x, z, 0.12, 5.0), paint, 0.01)
			if _rng.randf() < 0.45:
				_car(x + 1.3, z + 2.5, CAR_COLORS[_rng.randi() % CAR_COLORS.size()], false)
			x += 2.6
			i += 1
	_lamp(b.position.x - 2.0, lot.position.y + 7.8)
	_lamp(b.end.x + 2.0, lot.position.y + 7.8)
	_tree(lot.position.x + 1.5, lot.position.y + 8.0, 1.4)
	_tree(lot.end.x - 1.5, lot.position.y + 8.0, 1.4)
	return lot.position.y - 0.2


## Gymmet: parkering framför, grannlokaler på sidorna.
static func _gym() -> void:
	var b := _bbox
	var street_z := _parking(b, 17.0)
	_street(street_z)
	_houses_across(street_z - 11.5, b.position.x - 30.0, b.end.x + 30.0)
	_block(Rect2(b.position.x - 14.0, b.position.y - 1.0, 11.0, b.size.y + 1.0), 4.2, Color(0.82, 0.84, 0.86), 1, "north", Color(0.45, 0.62, 0.7))
	_block(Rect2(b.end.x + 3.0, b.position.y - 1.0, 11.0, b.size.y + 1.0), 4.2, Color(0.9, 0.86, 0.8), 1, "north", Color(0.86, 0.6, 0.45))
	# Entrén vid receptionen: rabatter på var sida om trappan, en skylt i gymmets färg
	# ovanför dörren och ett cykelställ intill.
	var door_x := b.position.x + PlanDrawer.front_door_offset("gym", PlanDrawer.plan_of("gym").size.x)
	_flower_bed(Rect2(b.position.x + 0.2, b.position.y - 0.8, door_x - b.position.x - 1.0, 0.45))
	_flower_bed(Rect2(door_x + 1.0, b.position.y - 0.8, b.end.x - door_x - 1.3, 0.45))
	var face := b.position.y - StyleKit.WALL - 0.06
	StyleKit.box(_root, Vector3(2.4, 0.34, 0.06), Vector3(door_x + 0.4, _level + 2.4, face - 0.03), StyleKit.mat(GymKit.ACCENT), true, 0.01)
	StyleKit.box(_root, Vector3(1.4, 0.06, 0.01), Vector3(door_x + 0.4, _level + 2.4, face - 0.065), StyleKit.mat(StyleKit.WHITE), false, 0.0)
	for i in 3:
		_prop("bike", b.position.x - 0.9 - i * 0.7, b.position.y - 1.6, 1.3, 0.55, 90.0)


## Köpcentret: huvudingången med skärmtak mot parkeringen i norr, en skylt vid infarten,
## kundvagnsgård, bänkar och rabatter längs fasaden, och fler butiker på sidorna.
static func _mall() -> void:
	var b := _bbox
	var street_z := _parking(b, 19.0)
	_street(street_z)
	_houses_across(street_z - 11.5, b.position.x - 30.0, b.end.x + 30.0)
	_block(Rect2(b.position.x - 16.0, b.position.y - 1.0, 13.0, b.size.y + 1.0), 4.6, Color(0.95, 0.9, 0.82), 1, "north", Color(0.86, 0.5, 0.48))
	_block(Rect2(b.end.x + 3.0, b.position.y - 1.0, 13.0, b.size.y + 1.0), 4.6, Color(0.92, 0.9, 0.86), 1, "north", Color(0.48, 0.66, 0.6))
	var entrance: Rect2 = PlanDrawer.FLOOR_PLANS["Köpcentret"]["entrance"]
	var door_x := entrance.get_center().x
	_entrance_canopy(Rect2(entrance.position.x - 0.5, b.position.y - 2.4, entrance.size.x + 1.0, 2.3))
	_paving(Rect2(entrance.position.x - 0.5, b.position.y - 6.0, entrance.size.x + 1.0, 5.8), StyleKit.mat(PAVING, 0.0, 1, 0.8), 0.03)
	_mall_sign(door_x, street_z + 1.0)
	# Kundvagnsgården vid grocery-änden och bänkar vid ingången.
	for i in 3:
		_slab_box(Rect2(b.position.x + 9.0, b.position.y - 3.0 + i * 0.25, 0.7, 0.2), _grade, _grade + 0.9, StyleKit.mat(StyleKit.METAL, 0.5), true)
	_prop("bench", entrance.position.x - 1.6, b.position.y - 1.2, 1.4, 0.5, 180.0)
	_prop("bench", entrance.end.x + 1.6, b.position.y - 1.2, 1.4, 0.5, 180.0)
	_flower_bed(Rect2(b.position.x + 0.3, b.position.y - 0.8, 7.4, 0.45))
	_flower_bed(Rect2(b.end.x - 7.7, b.position.y - 0.8, 7.4, 0.45))


## Skärmtaket över huvudingången: ett platt tak på två pelare med en skylt i fronten.
static func _entrance_canopy(rect: Rect2) -> void:
	var height := 3.0
	var white := StyleKit.mat(StyleKit.WHITE)
	StyleKit.box(_root, Vector3(rect.size.x, 0.22, rect.size.y), Vector3(rect.get_center().x, _grade + height, rect.get_center().y), white, true, 0.02)
	StyleKit.box(_root, Vector3(rect.size.x + 0.04, 0.08, rect.size.y + 0.04), Vector3(rect.get_center().x, _grade + height + 0.14, rect.get_center().y), StyleKit.mat(StyleKit.DARK.lightened(0.2)), true, 0.0)
	for x in [rect.position.x + 0.25, rect.end.x - 0.25]:
		StyleKit.cylinder(_root, 0.1, 0.1, height, Vector3(x, _grade + height / 2, rect.position.y + 0.25), white, 16)
	# Skylten på takets framkant, i köpcentrets varma orange.
	StyleKit.box(_root, Vector3(rect.size.x * 0.6, 0.5, 0.08), Vector3(rect.get_center().x, _grade + height + 0.4, rect.position.y + 0.1), StyleKit.mat(Color(0.9, 0.6, 0.3)), true, 0.02)
	var light := OmniLight3D.new()
	light.position = Vector3(rect.get_center().x, _grade + height - 0.3, rect.get_center().y)
	light.light_color = Color(1.0, 0.85, 0.6)
	light.omni_range = 5.0
	_root.add_child(light)
	_rig.register_lamp(light, null, 1.2)


## Skyltpelaren vid infarten från gatan, med en upplyst skylt överst.
static func _mall_sign(x: float, z: float) -> void:
	if not _free(Rect2(x - 0.8, z - 0.4, 1.6, 0.8), _grade + 5.0):
		return
	StyleKit.box(_root, Vector3(1.0, 4.0, 0.5), Vector3(x, _grade + 2.0, z), StyleKit.mat(StyleKit.STONE.darkened(0.1)), true, 0.03)
	var face := StyleKit.own_mat(Color(0.9, 0.6, 0.3))
	face.set_shader_parameter("emission", Color(1.0, 0.7, 0.35))
	StyleKit.box(_root, Vector3(1.5, 1.1, 0.6), Vector3(x, _grade + 4.4, z), face, true, 0.04)
	_rig.register_lamp_shade(face)
	for i in 3:
		StyleKit.box(_root, Vector3(0.8, 0.22, 0.02), Vector3(x, _grade + 1.6 + i * 0.5, z - 0.26), StyleKit.mat([Color(0.9, 0.95, 0.88), Color(0.98, 0.88, 0.88), Color(0.95, 0.87, 0.76)][i]), true, 0.0)


## Parken: gången fortsätter åt båda hållen, fler träd, en damm, en lekplats och lyktor
## längs gången. Gatan och husen syns bortom.
static func _park() -> void:
	var b := _bbox
	var path := FloorPlanArt.furniture_rect("park", "path")
	var gravel := StyleKit.mat(Color(0.64, 0.58, 0.48), 0.0, 7, 0.8)
	var py := b.position.y + path.position.y
	_paving(Rect2(b.position.x - 60.2, py, 60.0, path.size.y), gravel, 0.01)
	_paving(Rect2(b.end.x + 0.2, py, 60.0, path.size.y), gravel, 0.01)
	_paving(Rect2(b.get_center().x - 0.45, b.position.y - 14.0, 0.9, 13.8), gravel, 0.01)
	for x in [-18.0, -9.0, 18.0, 27.0]:
		_lamp(b.position.x + x, py - 0.5)
		_prop("bench", b.position.x + x + 2.0, py - 0.6, 1.2, 0.45, 0.0)
	_prop("pond", b.position.x - 10.0, b.position.y - 6.0, 5.0, 3.2, 0.0, 0.2)
	_playground(b.end.x + 6.0, b.position.y - 7.0)
	for p in [Vector2(-6, -3), Vector2(-15, -2), Vector2(-4, -12), Vector2(-20, -10), Vector2(14, -2), Vector2(20, -6), Vector2(16, -13), Vector2(-8, 3.5), Vector2(17, 3.5)]:
		var x: float = b.position.x + p.x if p.x < 0 else b.end.x + p.x - 9.0
		_tree(x, b.position.y + p.y, 1.5 + _rng.randf() * 0.6)
	_flower_bed(Rect2(b.position.x - 6.0, py + 1.4, 4.0, 0.6))
	_flower_bed(Rect2(b.end.x + 2.0, py + 1.4, 4.0, 0.6))
	_street(b.position.y - 16.0)
	_houses_across(b.position.y - 27.5, b.position.x - 30.0, b.end.x + 30.0)


## En liten lekplats: rutschkana och gungställning på sand.
static func _playground(x: float, z: float) -> void:
	if not _free(Rect2(x - 3.0, z - 2.0, 6.0, 4.0), _grade + 2.6):
		return
	_slab_box(Rect2(x - 3.0, z - 2.0, 6.0, 4.0), _grade - 0.05, _grade + 0.05, StyleKit.mat(Color(0.93, 0.85, 0.66), 0.0, 7, 0.6), true)
	var red := StyleKit.mat(Color(0.88, 0.45, 0.4), 0.3)
	var metal := StyleKit.mat(StyleKit.METAL, 0.4)
	# Rutschkana: torn, trappa och kana.
	StyleKit.box(_root, Vector3(1.0, 0.08, 1.0), Vector3(x - 1.6, _grade + 1.5, z), red)
	for sx in [-0.45, 0.45]:
		for sz in [-0.45, 0.45]:
			StyleKit.box(_root, Vector3(0.08, 1.5, 0.08), Vector3(x - 1.6 + sx, _grade + 0.75, z + sz), metal)
	var slide := StyleKit.box(_root, Vector3(0.6, 0.06, 2.4), Vector3(x - 1.6, _grade + 0.85, z + 1.45), StyleKit.mat(Color(0.98, 0.82, 0.4), 0.6))
	slide.rotation_degrees.x = 36
	# Gungställning: två A-ben, en bom och två gungor.
	for sx in [0.2, 2.6]:
		for sz in [-0.5, 0.5]:
			var leg := StyleKit.box(_root, Vector3(0.08, 2.4, 0.08), Vector3(x + sx, _grade + 1.15, z + sz * 0.5), metal)
			leg.rotation_degrees.x = sz * 24
	StyleKit.box(_root, Vector3(2.5, 0.08, 0.08), Vector3(x + 1.4, _grade + 2.3, z), metal)
	for sx in [0.9, 1.9]:
		for side in [-0.18, 0.18]:
			StyleKit.box(_root, Vector3(0.02, 1.6, 0.02), Vector3(x + sx + side, _grade + 1.5, z), metal, false, 0.0)
		StyleKit.box(_root, Vector3(0.45, 0.05, 0.2), Vector3(x + sx, _grade + 0.7, z), red)
