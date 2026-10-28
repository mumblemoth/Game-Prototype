class_name StyleKit
## Husets 3D-stil, gemensam för alla rum: anime-shading (toon.gdshader), färgpalett,
## lådor med fasade kanter, rummets skal (golv, väggar med fönster och dörrar, lister),
## utsikt genom fönstren, partiklar och tuschkonturer för kameran.
## 1 enhet = 1 meter. Planens x är X och planens y är Z (söderut); y är uppåt.

const TOON := preload("res://shaders/toon.gdshader")
const INK := preload("res://shaders/ink_outline.gdshader")

const WALL_HEIGHT := 2.6
## Höjden på de avskurna väggarna mot kameran (dockhus).
const CUT_HEIGHT := 0.16
## Höjden på låga innerväggar (när bara ytterväggarna står i full höjd).
const LOW_WALL_HEIGHT := 0.45
const WALL := 0.12
const DOOR_WIDTH := 0.9
const DOOR_HEIGHT := 2.1

const CREAM := Color(0.98, 0.93, 0.84)
const WALL_TOP := Color(0.42, 0.3, 0.27)
const TILE := Color(0.97, 0.9, 0.8)
const TEAL := Color(0.38, 0.62, 0.6)
const STONE := Color(0.96, 0.95, 0.92)
const OAK := Color(0.82, 0.6, 0.4)
const WALNUT := Color(0.55, 0.36, 0.26)
const WHITE := Color(0.97, 0.97, 0.96)
const BRASS := Color(0.9, 0.72, 0.38)
const METAL := Color(0.78, 0.8, 0.84)
const DARK := Color(0.22, 0.22, 0.26)
const SAGE := Color(0.62, 0.72, 0.56)
const TERRACOTTA := Color(0.86, 0.5, 0.36)
const LEAF := Color(0.36, 0.62, 0.36)
const CURTAIN := Color(0.96, 0.86, 0.66)
const ROSE := Color(0.86, 0.55, 0.45)

## Väggfärg per rum (annars CREAM).
const WALL_COLORS := {
	"kitchen": CREAM,
	"hall": Color(0.95, 0.9, 0.86),
	"living_room": Color(0.9, 0.93, 0.88),
	"guest_wc": Color(0.9, 0.94, 0.96),
	"home_office": Color(0.94, 0.9, 0.84),
	# Övervåningen: varje rum har sin ton, så att sönernas rum och sovrummet känns olika.
	"son_room_1": Color(0.87, 0.89, 0.94),
	"son_room_2": Color(0.95, 0.91, 0.83),
	"upstairs_hall": Color(0.95, 0.9, 0.86),
	"bathroom": Color(0.9, 0.94, 0.96),
	"bedroom": Color(0.96, 0.9, 0.88),
	"laundry": Color(0.92, 0.94, 0.95),
	"hobby_room": Color(0.93, 0.93, 0.89),
	# Gymmet: sval ljusgrå hall, varm sal och ett ljust omklädningsrum.
	"gym": Color(0.92, 0.93, 0.93),
	"yoga_studio": Color(0.97, 0.92, 0.86),
	"locker_room": Color(0.9, 0.94, 0.95),
	# Köpcentret: ljusa gångar, och varje butik har sin egen färg så att de känns igen.
	"entrance": Color(0.97, 0.95, 0.91),
	"center_court": Color(0.97, 0.95, 0.91),
	"west_promenade": Color(0.97, 0.95, 0.91),
	"east_promenade": Color(0.97, 0.95, 0.91),
	"grocery": Color(0.9, 0.95, 0.88),
	"boutique": Color(0.96, 0.93, 0.92),
	"restaurant": Color(0.9, 0.8, 0.72),
	"salon": Color(0.98, 0.88, 0.88),
	"cafe": Color(0.95, 0.87, 0.76),
	"bookstore": Color(0.8, 0.86, 0.78),
}

## Fasaden på ytterväggarnas utsida (sätts av Surroundings per våning; null = ingen).
static var siding: Material = null
## Målad utsikt bakom fönstren. Av när Surroundings bygger riktig omgivning runt huset,
## så att man ser den genom glaset i stället.
static var painted_views := true


# --- Material -----------------------------------------------------------------

static var _materials := {}


## Toon-materialet för en färg (delas mellan alla som använder samma färg).
## `gloss` ger en hård blank fläck; `pattern` 1 = kakel, 2 = tegelkakel (xy),
## 3 = plankor, 4 = tegelkakel (zy).
static func mat(color: Color, gloss := 0.0, pattern := 0, pattern_size := 0.4, line := Color(0, 0, 0, 0)) -> ShaderMaterial:
	var key := "%s_%s_%d_%s_%s" % [color.to_html(), gloss, pattern, pattern_size, line.to_html()]
	if _materials.has(key):
		return _materials[key]
	var material := ShaderMaterial.new()
	material.shader = TOON
	material.set_shader_parameter("albedo", color)
	material.set_shader_parameter("gloss", gloss)
	material.set_shader_parameter("pattern", pattern)
	material.set_shader_parameter("pattern_size", pattern_size)
	material.set_shader_parameter("line_color", line if line.a > 0 else color.darkened(0.18))
	_materials[key] = material
	return material


## Ett eget material som inte delas (för sådant som ändras per tidszon).
static func own_mat(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = TOON
	material.set_shader_parameter("albedo", color)
	return material


## Golvets material efter rummets golvtyp i FloorPlanArt.FLOOR_MATERIALS.
static func floor_mat(kind: String) -> ShaderMaterial:
	match kind:
		"tile_warm":
			return mat(TILE, 0.0, 1, 0.42)
		"tile":
			return mat(Color(0.93, 0.95, 0.96), 0.15, 1, 0.3)
		"concrete":
			return mat(Color(0.8, 0.8, 0.82))
		"vinyl":
			# Gymmets golv: ljusgrå vinylplattor, en meter stora.
			return mat(Color(0.8, 0.8, 0.79), 0.05, 1, 1.0, Color(0.72, 0.72, 0.71))
		"maple":
			# Salens ljusa lönngolv med smala stavar.
			return mat(OAK.lightened(0.3), 0.1, 3, 0.12)
		"terrazzo":
			# Blankt stengolv i stora plattor, som i köpcentrets gångar.
			return mat(Color(0.86, 0.82, 0.76), 0.25, 1, 1.2, Color(0.74, 0.69, 0.62))
		"checker":
			return mat(Color(0.92, 0.84, 0.84), 0.2, 1, 0.5, Color(0.78, 0.68, 0.68))
		"wood_old":
			return mat(OAK.darkened(0.1), 0.0, 3, 0.16)
		"grass":
			return mat(Color(0.45, 0.63, 0.36), 0.0, 7, 3.0)
		_:
			return mat(OAK.lightened(0.15), 0.0, 3, 0.16)


# --- Former -------------------------------------------------------------------

## En låda med fasade kanter (som ljuset fångar, likt anime-rekvisita). `bevel` < 0
## väljer en fas efter storleken; 0 ger en vass låda (väggar, golv).
static func box(parent: Node3D, size: Vector3, center: Vector3, material: Material, shadows := true, bevel := -1.0) -> MeshInstance3D:
	if bevel < 0.0:
		bevel = clampf(minf(size.x, minf(size.y, size.z)) * 0.2, 0.0, 0.022)
	var mesh: Mesh
	if bevel < 0.003:
		mesh = BoxMesh.new()
		(mesh as BoxMesh).size = size
	else:
		mesh = bevel_box(size, bevel)
	return add(parent, mesh, center, material, shadows)


static func cylinder(parent: Node3D, top: float, bottom: float, height: float, center: Vector3, material: Material, sides := 24) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	return add(parent, mesh, center, material)


static func sphere(parent: Node3D, radius: float, center: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	return add(parent, mesh, center, material)


static func add(parent: Node3D, mesh: Mesh, center: Vector3, material: Material, shadows := true) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = center
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if material is ShaderMaterial and (material as ShaderMaterial).shader == TOON:
		instance.set_instance_shader_parameter("depth_rank", depth_rank(mesh))
	parent.add_child(instance)
	return instance


## Rangen mot z-fighting (se toon.gdshader): ju mindre volym, desto högre rang, så att
## en tavla vinner över väggen, en mattkant över golvet och ett armstöd över soffan.
## Ett steg per halvering av volymen; tunna skivor räknas som minst 1 cm tjocka.
const DEPTH_RANK_MAX := 40.0
const DEPTH_RANK_ZERO_VOLUME := 1024.0

static func depth_rank(mesh: Mesh) -> float:
	var s := mesh.get_aabb().size.max(Vector3.ONE * 0.01)
	return clampf(log(DEPTH_RANK_ZERO_VOLUME / (s.x * s.y * s.z)) / log(2.0), 0.0, DEPTH_RANK_MAX)


static var _bevel_cache := {}


## Låda med fasade kanter och hörn: sex inskjutna sidor, tolv fasade kanter och åtta
## hörntrianglar, med platta normaler.
static func bevel_box(size: Vector3, bevel: float) -> ArrayMesh:
	var key := "%s_%s" % [size, bevel]
	if _bevel_cache.has(key):
		return _bevel_cache[key]
	var h := size / 2.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var signs := [-1, 1]
	for axis in 3:
		for d in signs:
			var u := (axis + 1) % 3
			var v := (axis + 2) % 3
			var points: Array[Vector3] = []
			for uv in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]:
				var s := Vector3i.ZERO
				s[axis] = d
				s[u] = uv.x
				s[v] = uv.y
				points.append(_bevel_point(h, bevel, s, axis))
			_polygon(st, points)
	for a in 3:
		for b in range(a + 1, 3):
			var c := 3 - a - b
			for da in signs:
				for db in signs:
					var s1 := Vector3i.ZERO
					s1[a] = da
					s1[b] = db
					s1[c] = -1
					var s2 := s1
					s2[c] = 1
					_polygon(st, [_bevel_point(h, bevel, s1, a), _bevel_point(h, bevel, s2, a),
							_bevel_point(h, bevel, s2, b), _bevel_point(h, bevel, s1, b)])
	for sx in signs:
		for sy in signs:
			for sz in signs:
				var s := Vector3i(sx, sy, sz)
				_polygon(st, [_bevel_point(h, bevel, s, 0), _bevel_point(h, bevel, s, 1), _bevel_point(h, bevel, s, 2)])
	var mesh := st.commit()
	_bevel_cache[key] = mesh
	return mesh


static func _bevel_point(h: Vector3, bevel: float, s: Vector3i, axis: int) -> Vector3:
	var p := Vector3(s.x * (h.x - bevel), s.y * (h.y - bevel), s.z * (h.z - bevel))
	p[axis] = s[axis] * h[axis]
	return p


## Lägger till en konvex yta med utåtriktad normal, vänd medurs (Godots framsida).
static func _polygon(st: SurfaceTool, points: Array) -> void:
	var center := Vector3.ZERO
	for p in points:
		center += p
	center /= points.size()
	var a: Vector3 = points[0]
	var normal := ((points[1] as Vector3) - a).cross((points[2] as Vector3) - a).normalized()
	var ordered := points.duplicate()
	if normal.dot(center) > 0.0:
		ordered.reverse()
	else:
		normal = -normal
	for i in range(1, ordered.size() - 1):
		for p in [ordered[0], ordered[i], ordered[i + 1]]:
			st.set_normal(normal)
			st.add_vertex(p)


# --- Rummets skal -------------------------------------------------------------

## Golv, väggar, lister och ett skuggtak för ett rum i en våningsplan. Väggar mot
## söder skärs av (dockhus) så att kameran ser in; de andra är hela, med fönster ur
## FloorPlanArt.WINDOWS och dörrar mot grannrummen i `exits`.
## Med `low_interior` blir innerväggarna (mot ett annat rum) låga, så att bara
## ytterväggarna står i full höjd och man ser in i alla rum samtidigt.
static func build_room_shell(parent: Node3D, rig: TimeOfDayRig, plans: Dictionary, room_id: String, exits: Dictionary, low_interior := true) -> void:
	var plan: Rect2 = plans[room_id]
	var origin := Vector3(plan.position.x, 0, plan.position.y)
	var wall_color: Color = WALL_COLORS.get(room_id, CREAM)
	box(parent, Vector3(plan.size.x, 0.1, plan.size.y), origin + Vector3(plan.size.x / 2, -0.05, plan.size.y / 2),
			floor_mat(FloorPlanArt.FLOOR_MATERIALS.get(room_id, "wood")), true, 0.0)
	if FloorPlanArt.FLOOR_MATERIALS.get(room_id, "") == "grass":
		# Utomhus: gräsmatta inramad av ett lågt vitt staket, utan väggar och tak. Hemmets
		# gårdar har staket bara mot tomtgränsen (FloorPlanArt.YARD_FENCES), med en öppning
		# där en gång eller uppfart går igenom.
		var fenced: Array = FloorPlanArt.YARD_FENCES.get(room_id, ["north", "west", "east", "south"])
		for side in fenced:
			var length := plan.size.x if side in ["north", "south"] else plan.size.y
			_wall(parent, rig, plan, side, length, FloorPlanArt.yard_gaps(room_id, side), WHITE, "fence")
		return
	# Tak som bara kastar skugga, så att solen kommer in genom fönstren.
	var ceiling := box(parent, Vector3(plan.size.x + 0.4, 0.1, plan.size.y + 0.2), origin + Vector3(plan.size.x / 2, WALL_HEIGHT + 0.05, plan.size.y / 2 - 0.1), mat(wall_color), true, 0.0)
	ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	for side in ["north", "west", "east", "south"]:
		var holes := _openings(plans, room_id, side, exits)
		var length := plan.size.x if side in ["north", "south"] else plan.size.y
		var mode := "full"
		var interior := is_interior(plans, room_id, side)
		if side == "south":
			mode = "cut"
		elif low_interior and interior:
			mode = "low"
		_wall(parent, rig, plan, side, length, holes, wall_color, mode, null if interior else siding)


## Om en sida av rummet gränsar mot ett annat rum (mätt mitt på väggen).
static func is_interior(plans: Dictionary, room_id: String, side: String) -> bool:
	var plan: Rect2 = plans[room_id]
	var probe: Vector2 = {"north": Vector2(plan.get_center().x, plan.position.y - 0.1), "south": Vector2(plan.get_center().x, plan.end.y + 0.1),
			"west": Vector2(plan.position.x - 0.1, plan.get_center().y), "east": Vector2(plan.end.x + 0.1, plan.get_center().y)}[side]
	for other in plans:
		if other != room_id and (plans[other] as Rect2).has_point(probe):
			return true
	return false


## Öppningarna i en vägg: [{start, width, bottom, top, kind}] längs väggen.
static func _openings(plans: Dictionary, room_id: String, side: String, exits: Dictionary) -> Array:
	var plan: Rect2 = plans[room_id]
	var holes := []
	for window in FloorPlanArt.windows(room_id):
		if window["side"] == side:
			holes.append({"start": window["start"], "width": window["width"], "bottom": window["sill"], "top": window["top"], "kind": "window", "window": window})
	for target in exits:
		if not plans.has(target):
			continue
		var shared := PlanDrawer.shared_edge(plan, plans[target])
		if shared.is_empty():
			continue
		var a: Vector2 = shared[0]
		var b: Vector2 = shared[1]
		var horizontal := absf(a.y - b.y) < 0.01
		var on_side := ""
		if horizontal:
			on_side = "north" if absf(a.y - plan.position.y) < 0.01 else "south"
		else:
			on_side = "west" if absf(a.x - plan.position.x) < 0.01 else "east"
		if on_side != side:
			continue
		var middle := PlanDrawer.door_middle(room_id, target, a, b)
		var along := (middle.x - plan.position.x) if horizontal else (middle.y - plan.position.y)
		# Butiksfronter och öppningar mellan gångar är bredare än en dörr (PlanDrawer.door_width).
		var width := PlanDrawer.door_width(room_id, target, a.distance_to(b))
		holes.append({"start": along - width / 2, "width": width, "bottom": 0.0, "top": DOOR_HEIGHT, "kind": "door"})
	for door in PlanDrawer.exterior_doors(room_id):
		if door["side"] == side:
			holes.append({"start": door["at"] - door["width"] / 2, "width": door["width"], "bottom": 0.0, "top": DOOR_HEIGHT, "kind": "front_door"})
	holes.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x["start"] < y["start"])
	return holes


## En vägg längs en sida, uppdelad runt öppningarna. `mode` är "full" (hel vägg med
## fönster och dörrkarmar), "cut" (avskuren mot kameran: en låg mörk sockel) eller
## "low" (låg innervägg i väggfärg med mörkt krön, dörröppningarna kvar).
## `skin` klär en hel yttervägg på utsidan (fasaden), runt hörnen och ned över bjälklaget.
static func _wall(parent: Node3D, rig: TimeOfDayRig, plan: Rect2, side: String, length: float, holes: Array, color: Color, mode: String, skin: Material = null) -> void:
	var cut := mode != "full"
	var horizontal := side in ["north", "south"]
	var outward := {"north": Vector3(0, 0, -1), "south": Vector3(0, 0, 1), "west": Vector3(-1, 0, 0), "east": Vector3(1, 0, 0)}[side] as Vector3
	var start := Vector3(plan.position.x, 0, plan.position.y)
	if side == "south":
		start.z = plan.end.y
	elif side == "east":
		start.x = plan.end.x
	start += outward * WALL / 2
	var along := Vector3(1, 0, 0) if horizontal else Vector3(0, 0, 1)
	var wall_mat := mat(color)
	if mode == "fence":
		# Staketet i bitar mellan öppningarna (grindar för gångar och uppfarter).
		var from := 0.0
		for hole in holes:
			if hole["start"] - from > 0.3:
				_fence(parent, start + along * from, along, hole["start"] - from)
			from = hole["start"] + hole["width"]
		if length - from > 0.3:
			_fence(parent, start + along * from, along, length - from)
		return
	var height := WALL_HEIGHT
	if mode == "cut":
		height = CUT_HEIGHT
	elif mode == "low":
		height = LOW_WALL_HEIGHT
	# Delar: från vänster till höger, med hål där öppningarna är.
	var cursor := 0.0
	var pieces := []  # [start, längd, botten, topp]
	for hole in holes:
		if hole["start"] > cursor:
			pieces.append([cursor, hole["start"] - cursor, 0.0, height])
		if not cut:
			if hole["bottom"] > 0.0:
				pieces.append([hole["start"], hole["width"], 0.0, hole["bottom"]])
			pieces.append([hole["start"], hole["width"], hole["top"], height])
		cursor = hole["start"] + hole["width"]
	if cursor < length:
		pieces.append([cursor, length - cursor, 0.0, height])
	var thickness := Vector3(0, 0, WALL) if horizontal else Vector3(WALL, 0, 0)
	if skin and mode == "full":
		# Fasaden: en tunn skiva utanpå varje del, förlängd runt hörnen och ned till
		# bjälklaget så att huset är helt utifrån.
		var corner := WALL + 0.03
		for piece in pieces:
			var from: float = piece[0] - (corner if piece[0] <= 0.0 else 0.0)
			var to: float = piece[0] + piece[1] + (corner if piece[0] + piece[1] >= length - 0.001 else 0.0)
			var bottom: float = piece[2] if piece[2] > 0.0 else -0.12
			var skin_size: Vector3 = along * (to - from) + Vector3(0, piece[3] - bottom, 0) + (Vector3(0, 0, 0.03) if horizontal else Vector3(0.03, 0, 0))
			box(parent, skin_size, start + outward * (WALL / 2 + 0.015) + along * (from + to) / 2.0 + Vector3(0, (bottom + piece[3]) / 2.0, 0), skin, true, 0.0)
	for piece in pieces:
		var size: Vector3 = along * piece[1] + Vector3(0, piece[3] - piece[2], 0) + thickness
		var center: Vector3 = start + along * (piece[0] + piece[1] / 2.0) + Vector3(0, (piece[2] + piece[3]) / 2.0, 0)
		box(parent, size, center, mat(WALL_TOP) if mode == "cut" else wall_mat, true, 0.0)
		if mode == "low":
			# Mörkt krön ovanpå den låga väggen, som i en planritning.
			box(parent, size * Vector3(1, 0, 1) + Vector3(0, 0.03, 0) + Vector3(0.012, 0, 0.012), center + Vector3(0, size.y / 2 + 0.015, 0), mat(WALL_TOP), true, 0.0)
		# Vit golvlist på insidan där väggen når golvet.
		if not cut and piece[2] <= 0.0:
			var base: Vector3 = along * piece[1] + Vector3(0, 0.08, 0) + (Vector3(0, 0, 0.02) if horizontal else Vector3(0.02, 0, 0))
			box(parent, base, start - outward * (WALL / 2 + 0.01) + along * (piece[0] + piece[1] / 2.0) + Vector3(0, 0.04, 0), mat(WHITE), true, 0.0)
	if mode == "low":
		# Trösklar i dörröppningarna, så att öppningen läses som en dörr.
		for hole in holes:
			if hole["kind"] != "window":
				var mid: Vector3 = start + along * (hole["start"] + hole["width"] / 2.0) + Vector3(0, 0.012, 0)
				box(parent, along * hole["width"] + Vector3(0, 0.024, 0) + thickness * 1.3, mid, mat(OAK.darkened(0.1), 0.2), true, 0.006)
	if cut:
		return
	# Väggens avskurna överkant i en mörkare ton, som i ett dockhus.
	var cap: Vector3 = along * (length + WALL) + Vector3(0, 0.03, 0) + thickness + Vector3(0.01, 0, 0.01) - along * 0.01
	var cap_at := start + along * length / 2 + Vector3(0, WALL_HEIGHT + 0.015, 0)
	if skin:
		# Krönet täcker fasaden och hörnen också.
		cap += along * (WALL + 0.06) + (Vector3(0, 0, 0.035) if horizontal else Vector3(0.035, 0, 0))
		cap_at += outward * 0.0175
	box(parent, cap, cap_at, mat(WALL_TOP), true, 0.0)
	for hole in holes:
		var at: Vector3 = start + along * (hole["start"] + hole["width"] / 2.0)
		if hole["kind"] == "window":
			HouseWindow.build(parent, rig, hole["window"], at, -outward)
		else:
			_door_frame(parent, at + Vector3(0, (hole["bottom"] + hole["top"]) / 2.0, 0), horizontal, outward, Vector2(hole["width"], hole["top"] - hole["bottom"]))


## Ett lågt vitt staket längs en sida: stolpar och två slanor.
static func _fence(parent: Node3D, start: Vector3, along: Vector3, length: float) -> void:
	var white := mat(WHITE)
	var count := maxi(2, int(length / 0.3))
	for i in count + 1:
		box(parent, Vector3(0.05, 0.42, 0.05), start + along * (length * i / count) + Vector3(0, 0.21, 0), white)
	for y in [0.16, 0.32]:
		var rail: Vector3 = along * length + Vector3(0, 0.04, 0) + (Vector3(0, 0, 0.03) if along.x > 0.5 else Vector3(0.03, 0, 0))
		box(parent, rail, start + along * length / 2 + Vector3(0, y, 0), white)


## Den målade utsikten en bit bakom glaset (när det inte finns riktig omgivning).
## Används av HouseWindow; `mid` och `outward` är i förälderns koordinater.
static func _painted_view(parent: Node3D, rig: TimeOfDayRig, mid: Vector3, outward: Vector3, size: Vector2) -> void:
	var view := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size + Vector2(0.5, 0.4)
	view.mesh = quad
	var sky := StandardMaterial3D.new()
	sky.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky.albedo_texture = outdoor_texture()
	view.material_override = sky
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.position = mid + outward * 0.22
	view.rotation_degrees = Vector3(0, 0, 0) if outward.z < 0 else (Vector3(0, 90, 0) if outward.x < 0 else (Vector3(0, -90, 0) if outward.x > 0 else Vector3(0, 180, 0)))
	parent.add_child(view)
	if rig:
		rig.register_sky(sky)


## Dörrkarm runt en dörröppning.
static func _door_frame(parent: Node3D, mid: Vector3, horizontal: bool, outward: Vector3, size: Vector2) -> void:
	var frame := mat(WHITE)
	var t := 0.06
	var depth := WALL + 0.03
	for s in [-1, 1]:
		var side := Vector3(s * (size.x / 2 + t / 2), 0, 0) if horizontal else Vector3(0, 0, s * (size.x / 2 + t / 2))
		box(parent, Vector3(t, size.y, depth) if horizontal else Vector3(depth, size.y, t), mid + side, frame)
	box(parent, Vector3(size.x + t * 2, t, depth) if horizontal else Vector3(depth, t, size.x + t * 2), mid + Vector3(0, size.y / 2 + t / 2, 0), frame)


# --- Utsikt, partiklar och konturer -------------------------------------------

static var _outdoor: Texture2D


## Utsikten målas i kod: himmel som ljusnar mot horisonten, en blå kulle långt bort,
## gröna kullar, rundade trädkronor och ett vitt staket. Tonas per tidszon av riggen.
static func outdoor_texture() -> Texture2D:
	if _outdoor != null:
		return _outdoor
	var w := 320
	var h := 240
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var horizon := 150
	for y in h:
		var sky := Color(0.45, 0.68, 0.95).lerp(Color(0.92, 0.96, 1.0), clampf(float(y) / horizon, 0.0, 1.0))
		for x in w:
			image.set_pixel(x, y, sky)
	var hill := func(base: int, amplitude: float, frequency: float, phase: float, color: Color) -> void:
		for x in w:
			var top := base - int(amplitude * (0.5 + 0.5 * sin(x * frequency + phase)))
			for y in range(maxi(top, 0), h):
				image.set_pixel(x, y, color.darkened(0.08 * float(y - top) / 40.0))
	hill.call(150, 26.0, 0.018, 1.0, Color(0.62, 0.75, 0.86))
	hill.call(175, 22.0, 0.03, 2.4, Color(0.55, 0.78, 0.45))
	hill.call(205, 10.0, 0.05, 0.3, Color(0.48, 0.72, 0.36))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 9:
		var cx := rng.randi_range(10, w - 10)
		var cy := rng.randi_range(150, 185)
		var r := rng.randi_range(12, 20)
		for y in range(cy - r, cy + r):
			for x in range(cx - r, cx + r):
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				if Vector2(x - cx, (y - cy) * 1.15).length() < r:
					var lit := Vector2(x - cx + r * 0.3, y - cy + r * 0.3).length() < r * 0.7
					image.set_pixel(x, y, Color(0.4, 0.66, 0.32) if lit else Color(0.3, 0.52, 0.27))
	for x in range(0, w, 10):
		image.fill_rect(Rect2i(x, 212, 5, 24), Color(0.97, 0.97, 0.95))
	image.fill_rect(Rect2i(0, 218, w, 3), Color(0.97, 0.97, 0.95))
	image.fill_rect(Rect2i(0, 228, w, 3), Color(0.97, 0.97, 0.95))
	_outdoor = ImageTexture.create_from_image(image)
	return _outdoor


static var _dot: Texture2D


## En mjuk rund prick (partiklar och skuggor under figurer).
static func soft_dot() -> Texture2D:
	if _dot == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		_dot = texture
	return _dot


## Mjuka partiklar (damm i solljus, ånga) i en låda kring `at`.
static func particles(parent: Node3D, amount: int, lifetime: float, extents: Vector3, at: Vector3, color: Color, size: float, velocity: Vector3, wobble: float) -> GPUParticles3D:
	var node := GPUParticles3D.new()
	node.amount = amount
	node.lifetime = lifetime
	node.preprocess = lifetime
	node.position = at
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = extents
	process.direction = velocity.normalized() if velocity.length() > 0 else Vector3.UP
	process.initial_velocity_min = velocity.length() * 0.6
	process.initial_velocity_max = velocity.length() * 1.2
	process.spread = 25.0
	process.gravity = Vector3.ZERO
	process.turbulence_enabled = true
	process.turbulence_noise_strength = wobble * 10.0
	var fade := Gradient.new()
	fade.set_color(0, Color(color.r, color.g, color.b, 0.0))
	fade.set_color(1, Color(color.r, color.g, color.b, 0.0))
	fade.add_point(0.3, color)
	fade.add_point(0.7, color)
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	process.scale_min = 0.6
	process.scale_max = 1.4
	node.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = soft_dot()
	quad.material = material
	node.draw_pass_1 = quad
	parent.add_child(node)
	return node


## Tuschkonturerna: en heltäckande fyrkant som alltid ritas framför kameran.
## Materialet lämnas tillbaka så att linjernas bleknande kan följa kameran.
static func add_ink_outline(camera: Camera3D) -> ShaderMaterial:
	var ink := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	ink.mesh = quad
	var material := ShaderMaterial.new()
	material.shader = INK
	# Konturerna ritas först bland de genomskinliga sakerna (de läser skärmbilden och
	# skriver över allt som redan ritats). Annars försvann glas, golvmarkeringar,
	# skuggor under figurerna och damm under dem.
	material.render_priority = Material.RENDER_PRIORITY_MIN
	ink.material_override = material
	ink.extra_cull_margin = 16384.0
	ink.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	camera.add_child(ink)
	return material
