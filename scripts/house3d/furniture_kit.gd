class_name FurnitureKit
## Möblerna i husets 3D-stil, byggda ur planens möbeldata (FloorPlanArt.FURNITURE).
## Varje möbel byggs lokalt med framsidan mot +z och vänds sedan bort från närmaste
## vägg (stolar vänds mot bordet). Rumsspecifika detaljer (köksskåp, lampor,
## småsaker) läggs till i decorate().

## Möblerar ett rum. `plan` är rummets rektangel i våningsplanen (meter).
## Med `plans` (våningens alla rum) hoppas tavlor och affischer på låga innerväggar och
## avskurna södra väggar över, eftersom de annars skulle sväva i luften.
## `skip` (valfri) får typen och möbelns yta i planen och svarar true för saker som inte
## ska byggas (Surroundings hoppar så över höga saker på gården framför kameran).
static func furnish(parent: Node3D, rig: TimeOfDayRig, room_id: String, plan: Rect2, plans := {}, skip := Callable()) -> void:
	var items: Array = FloorPlanArt.FURNITURE.get(room_id, [])
	var tables: Array[Rect2] = []
	for item in items:
		if item[0] in ["table", "desk", "gaming_desk", "vanity", "coffee_table"]:
			tables.append(item[1])
	for item in items:
		var kind: String = item[0]
		var rect: Rect2 = item[1]
		var front := _facing(rect, plan.size)
		if kind in ["chair", "gaming_chair", "stool"] and not tables.is_empty():
			# Sittplatser vänds mot närmaste bord.
			var table := tables[0]
			for other in tables:
				if other.get_center().distance_to(rect.get_center()) < table.get_center().distance_to(rect.get_center()):
					table = other
			var to_table := table.get_center() - rect.get_center()
			front = Vector3(signf(to_table.x), 0, 0) if absf(to_table.x) > absf(to_table.y) else Vector3(0, 0, signf(to_table.y))
		if skip.is_valid() and skip.call(kind, Rect2(plan.position + rect.position, rect.size)):
			continue
		if item.size() > 2 and item[2] != "":
			# Bestämd riktning i möbeldatan (t.ex. en soffa mitt i ett stort rum).
			front = {"north": Vector3(0, 0, -1), "south": Vector3(0, 0, 1), "west": Vector3(-1, 0, 0), "east": Vector3(1, 0, 0)}[item[2]]
		var style := FloorPlanArt.item_style(item)
		if kind == "basin" and style == "" and not plans.is_empty():
			# Handfat mot en låg innervägg eller den avskurna södra väggen får ingen spegel,
			# som annars skulle sväva i luften.
			var back: String = {Vector3(0, 0, 1): "north", Vector3(0, 0, -1): "south", Vector3(1, 0, 0): "west", Vector3(-1, 0, 0): "east"}.get(front, "")
			if back == "south" or StyleKit.is_interior(plans, room_id, back):
				style = "no_mirror"
		if kind in FloorPlanArt.WALL_ITEMS:
			var side: String = {Vector3(0, 0, 1): "north", Vector3(0, 0, -1): "south", Vector3(1, 0, 0): "west", Vector3(-1, 0, 0): "east"}.get(front, "")
			if side == "south" or (not plans.is_empty() and StyleKit.is_interior(plans, room_id, side)):
				continue
			# Inte heller över ett fönster.
			var along_from := rect.position.x if side == "north" else rect.position.y
			var along_to := rect.end.x if side == "north" else rect.end.y
			if FloorPlanArt.overlaps_window(room_id, side, along_from, along_to):
				continue
		var node := Node3D.new()
		node.set_meta("kind", kind)
		var center := plan.position + rect.get_center()
		node.position = Vector3(center.x, 0, center.y)
		node.rotation.y = atan2(front.x, front.z)
		parent.add_child(node)
		# Lokala mått: bredd längs väggen, djup ut från väggen.
		var sideways := absf(front.x) > 0.5
		var w := rect.size.y if sideways else rect.size.x
		var d := rect.size.x if sideways else rect.size.y
		if kind == "stairs":
			_prepare_stairs(room_id, rect, plan.size, items)
		build(node, rig, kind, w, d, style)


## Hur trappan i ett rum ska se ut, räknat ur rummets dörrar till andra våningar:
## uppåt (en trappa som försvinner upp genom taket), nedåt (ett trapphål med räcke)
## eller båda (trappa upp med en källardörr under). Finns en vindsstege i rummet går
## vägen upp via den. Sidan som vetter mot rummet får räcket.
static var _stair_up := false
static var _stair_down := false
static var _stair_open_side := -1.0
static var _stair_hatch := false


static func _prepare_stairs(room_id: String, rect: Rect2, room: Vector2, items: Array) -> void:
	var here := PlanDrawer.FLOORS.find(PlanDrawer.floor_of(room_id))
	var has_ladder := items.any(func(item: Array) -> bool: return item[0] == "attic_ladder")
	_stair_up = false
	_stair_down = false
	_stair_hatch = false
	for target in GameState.get_exits(room_id):
		var there := PlanDrawer.FLOORS.find(PlanDrawer.floor_of(target))
		if there < 0 or PlanDrawer.floor_of(target) == "Utanför" or there == here:
			continue
		if there < here and not has_ladder:
			_stair_up = true
		elif there > here:
			_stair_down = true
			var below: Array = FloorPlanArt.FURNITURE.get(target, [])
			_stair_hatch = below.any(func(item: Array) -> bool: return item[0] == "attic_ladder")
	if not _stair_up and not _stair_down:
		_stair_up = true
	# Trappor står med framsidan mot söder (+z); den öppna sidan är den med mest plats.
	_stair_open_side = -1.0 if rect.position.x > room.x - rect.end.x else 1.0


## Framsidan pekar bort från närmaste vägg.
static func _facing(rect: Rect2, room: Vector2) -> Vector3:
	var distances := {
		Vector3(0, 0, 1): rect.position.y,
		Vector3(0, 0, -1): room.y - rect.end.y,
		Vector3(1, 0, 0): rect.position.x,
		Vector3(-1, 0, 0): room.x - rect.end.x,
	}
	var best := Vector3(0, 0, 1)
	for direction in distances:
		if distances[direction] < distances[best] - 0.01:
			best = direction
	return best


## Bygger en möbel lokalt: bredd w längs x, djup d längs z, framsidan mot +z.
## `style` väljer en variant (HomeKit), t.ex. en mattas färg eller en låg skänk.
static func build(n: Node3D, rig: TimeOfDayRig, kind: String, w: float, d: float, style := "") -> void:
	if kind in GymKit.KINDS:
		GymKit.build(n, rig, kind, w, d)
		return
	if kind in HomeKit.KINDS:
		HomeKit.build(n, rig, kind, w, d, style)
		return
	if style != "" and HomeKit.build_variant(n, rig, kind, w, d, style):
		return
	match kind:
		"counter":
			var body := HomeKit.tint(style, StyleKit.TEAL)
			StyleKit.box(n, Vector3(w, 0.1, d - 0.08), Vector3(0, 0.05, -0.04), StyleKit.mat(body.darkened(0.4)))
			StyleKit.box(n, Vector3(w, 0.78, d - 0.02), Vector3(0, 0.49, -0.01), StyleKit.mat(body))
			var doors := maxi(1, roundi(w / 0.5))
			var door_w := w / doors
			for i in doors:
				var x := -w / 2 + door_w * (i + 0.5)
				# Luckorna ligger tätt; deras fasade kanter ritar skarven som en hel linje
				# (en smal spalt blir prickig och flimrar när kameran rör sig).
				StyleKit.box(n, Vector3(door_w - 0.006, 0.68, 0.02), Vector3(x, 0.48, d / 2), StyleKit.mat(body.lightened(0.06)), true, 0.008)
				StyleKit.box(n, Vector3(0.14, 0.025, 0.03), Vector3(x, 0.74, d / 2 + 0.02), StyleKit.mat(StyleKit.BRASS, 0.8))
			StyleKit.box(n, Vector3(w + 0.04, 0.05, d + 0.04), Vector3(0, 0.905, 0.02), StyleKit.mat(StyleKit.STONE, 0.3))
		"sink":
			StyleKit.box(n, Vector3(w * 0.8, 0.02, d * 0.82), Vector3(0, 0.925, 0), StyleKit.mat(StyleKit.METAL.darkened(0.35)))
			StyleKit.cylinder(n, 0.015, 0.015, 0.32, Vector3(0, 1.08, -d / 2 + 0.04), StyleKit.mat(StyleKit.METAL, 0.9))
			StyleKit.box(n, Vector3(0.03, 0.03, 0.18), Vector3(0, 1.23, -d / 2 + 0.12), StyleKit.mat(StyleKit.METAL, 0.9))
		"stove":
			StyleKit.box(n, Vector3(w, 0.02, d + 0.06), Vector3(0, 0.94, 0), StyleKit.mat(StyleKit.DARK, 0.6))
			for i in 4:
				StyleKit.cylinder(n, 0.08, 0.08, 0.008, Vector3((-0.15 if i % 2 == 0 else 0.15) * w / 0.6, 0.953, (-0.12 if i < 2 else 0.12) * d / 0.44), StyleKit.mat(Color(0.35, 0.35, 0.4)))
			var front := d / 2 + 0.075
			StyleKit.box(n, Vector3(w - 0.02, 0.6, 0.02), Vector3(0, 0.44, front), StyleKit.mat(StyleKit.DARK.lightened(0.1), 0.5))
			StyleKit.box(n, Vector3(w * 0.7, 0.25, 0.01), Vector3(0, 0.46, front + 0.01), StyleKit.mat(Color(0.3, 0.22, 0.2)))
			StyleKit.box(n, Vector3(w * 0.8, 0.025, 0.03), Vector3(0, 0.71, front + 0.03), StyleKit.mat(StyleKit.METAL, 0.8))
			StyleKit.cylinder(n, 0.12, 0.11, 0.14, Vector3(-w * 0.25, 1.03, d * 0.25), StyleKit.mat(Color(0.85, 0.35, 0.3), 0.6))
		"fridge":
			var c := Color(0.88, 0.94, 0.93)
			StyleKit.box(n, Vector3(w - 0.04, 1.95, d), Vector3(0, 0.975, 0), StyleKit.mat(c, 0.5))
			StyleKit.box(n, Vector3(w - 0.06, 0.015, 0.02), Vector3(0, 1.25, d / 2 + 0.005), StyleKit.mat(StyleKit.DARK))
			StyleKit.box(n, Vector3(0.03, 0.5, 0.04), Vector3(-w / 2 + 0.1, 1.55, d / 2 + 0.03), StyleKit.mat(StyleKit.METAL, 0.9))
			StyleKit.box(n, Vector3(0.03, 0.4, 0.04), Vector3(-w / 2 + 0.1, 0.95, d / 2 + 0.03), StyleKit.mat(StyleKit.METAL, 0.9))
			StyleKit.box(n, Vector3(0.14, 0.18, 0.005), Vector3(w * 0.17, 1.45, d / 2 + 0.005), StyleKit.mat(Color(1.0, 0.95, 0.75)), true, 0.0)
			StyleKit.box(n, Vector3(0.12, 0.09, 0.005), Vector3(-w * 0.22, 1.6, d / 2 + 0.005), StyleKit.mat(Color(0.5, 0.75, 0.95)), true, 0.0)
			for spot in [[Vector3(w * 0.28, 1.7, d / 2 + 0.01), Color(0.95, 0.3, 0.35)], [Vector3(-w * 0.17, 0.85, d / 2 + 0.01), Color(0.35, 0.75, 0.4)], [Vector3(w * 0.22, 1.0, d / 2 + 0.01), Color(1.0, 0.8, 0.2)]]:
				StyleKit.cylinder(n, 0.02, 0.02, 0.01, spot[0], StyleKit.mat(spot[1], 0.6)).rotation_degrees = Vector3(90, 0, 0)
		"table":
			_table(n, w, d, 0.75, StyleKit.OAK)
			if w > 1.2 and DETAIL >= 1:
				StyleKit.box(n, Vector3(w * 0.75, 0.005, 0.3), Vector3(0, 0.778, 0), StyleKit.mat(StyleKit.SAGE))
				StyleKit.cylinder(n, 0.16, 0.1, 0.08, Vector3(0.05, 0.82, 0), StyleKit.mat(StyleKit.WHITE, 0.5))
				for fruit in [[Vector3(0.0, 0.88, 0.02), Color(1.0, 0.6, 0.15)], [Vector3(0.1, 0.89, -0.04), Color(0.9, 0.2, 0.2)], [Vector3(0.08, 0.88, 0.07), Color(0.65, 0.85, 0.3)]]:
					StyleKit.sphere(n, 0.05, fruit[0], StyleKit.mat(fruit[1], 0.6))
				for x in [-w * 0.28, w * 0.28]:
					for z in [-d * 0.29, d * 0.29]:
						StyleKit.cylinder(n, 0.12, 0.12, 0.01, Vector3(x, 0.78, z), StyleKit.mat(StyleKit.WHITE, 0.4))
		"coffee_table":
			_table(n, w, d, 0.42, StyleKit.OAK.lightened(0.08))
			StyleKit.box(n, Vector3(0.3, 0.04, 0.22), Vector3(-w * 0.2, 0.46, 0), StyleKit.mat(Color(0.95, 0.45, 0.35)))
			StyleKit.box(n, Vector3(0.26, 0.03, 0.2), Vector3(-w * 0.2, 0.495, 0.01), StyleKit.mat(Color(0.35, 0.5, 0.85)))
			StyleKit.cylinder(n, 0.04, 0.035, 0.09, Vector3(w * 0.25, 0.49, -0.05), StyleKit.mat(StyleKit.WHITE, 0.5))
		"desk":
			_table(n, w, d, 0.75, StyleKit.OAK)
			StyleKit.box(n, Vector3(0.4, 0.68, d - 0.06), Vector3(w / 2 - 0.24, 0.36, 0), StyleKit.mat(StyleKit.OAK.darkened(0.05)))
			for y in [0.55, 0.3]:
				StyleKit.box(n, Vector3(0.36, 0.2, 0.02), Vector3(w / 2 - 0.24, y, d / 2 - 0.02), StyleKit.mat(StyleKit.OAK.lightened(0.05)))
				StyleKit.box(n, Vector3(0.1, 0.02, 0.03), Vector3(w / 2 - 0.24, y + 0.05, d / 2), StyleKit.mat(StyleKit.BRASS, 0.8))
			StyleKit.box(n, Vector3(0.34, 0.015, 0.24), Vector3(-0.05, 0.785, 0.05), StyleKit.mat(Color(0.72, 0.74, 0.78), 0.4))
			var screen := StyleKit.box(n, Vector3(0.34, 0.22, 0.012), Vector3(-0.05, 0.89, -0.08), StyleKit.mat(Color(0.25, 0.26, 0.3), 0.5))
			screen.rotation_degrees = Vector3(-12, 0, 0)
			StyleKit.box(n, Vector3(0.2, 0.01, 0.28), Vector3(-w / 2 + 0.25, 0.785, 0.02), StyleKit.mat(StyleKit.WHITE))
			StyleKit.cylinder(n, 0.04, 0.035, 0.09, Vector3(w / 2 - 0.2, 0.82, 0.08), StyleKit.mat(Color(0.95, 0.4, 0.35), 0.5))
		"chair":
			var wood := StyleKit.mat(StyleKit.OAK.darkened(0.08))
			StyleKit.box(n, Vector3(0.42, 0.05, 0.42), Vector3(0, 0.45, 0), wood)
			StyleKit.box(n, Vector3(0.38, 0.04, 0.38), Vector3(0, 0.49, 0), StyleKit.mat(Color(0.95, 0.62, 0.55)))
			for corner in [Vector2(-0.18, -0.18), Vector2(0.18, -0.18), Vector2(-0.18, 0.18), Vector2(0.18, 0.18)]:
				StyleKit.box(n, Vector3(0.04, 0.45, 0.04), Vector3(corner.x, 0.225, corner.y), wood)
			StyleKit.box(n, Vector3(0.42, 0.42, 0.04), Vector3(0, 0.7, -0.19), wood)
			StyleKit.box(n, Vector3(0.36, 0.08, 0.05), Vector3(0, 0.82, -0.19), StyleKit.mat(StyleKit.OAK.lightened(0.1)))
		"sofa", "armchair":
			_sofa(n, w, d, kind == "sofa", HomeKit.tint(style, StyleKit.SAGE))
		"tv":
			StyleKit.box(n, Vector3(w, 0.45, d), Vector3(0, 0.225, 0), StyleKit.mat(StyleKit.WALNUT))
			for x in [-w / 4, w / 4]:
				StyleKit.box(n, Vector3(w / 2 - 0.06, 0.35, 0.02), Vector3(x, 0.225, d / 2), StyleKit.mat(StyleKit.WALNUT.lightened(0.08)))
				StyleKit.box(n, Vector3(0.12, 0.02, 0.03), Vector3(x, 0.36, d / 2 + 0.01), StyleKit.mat(StyleKit.BRASS, 0.8))
			StyleKit.box(n, Vector3(0.3, 0.04, 0.2), Vector3(0, 0.47, 0), StyleKit.mat(StyleKit.DARK))
			StyleKit.box(n, Vector3(w * 0.8, w * 0.46, 0.05), Vector3(0, 0.5 + w * 0.23, -0.02), StyleKit.mat(Color(0.12, 0.12, 0.15), 0.7))
			StyleKit.cylinder(n, 0.07, 0.06, 0.12, Vector3(w / 2 - 0.12, 0.51, 0), StyleKit.mat(StyleKit.TERRACOTTA))
			StyleKit.sphere(n, 0.09, Vector3(w / 2 - 0.12, 0.62, 0), StyleKit.mat(StyleKit.LEAF))
		"shelf":
			var h := 1.8
			var wood := StyleKit.mat(StyleKit.WALNUT)
			StyleKit.box(n, Vector3(w, h, d), Vector3(0, h / 2, 0), wood)
			var colors := [Color(0.85, 0.35, 0.35), Color(0.3, 0.5, 0.85), Color(0.95, 0.75, 0.3), Color(0.45, 0.7, 0.45), Color(0.95, 0.92, 0.85)]
			for row in 4:
				var y := 0.25 + row * 0.42
				StyleKit.box(n, Vector3(w - 0.06, 0.32, 0.02), Vector3(0, y + 0.16, d / 2 - 0.01), StyleKit.mat(StyleKit.WALNUT.darkened(0.3)), true, 0.0)
				var x := -w / 2 + 0.06
				var i := row * 3
				while x < w / 2 - 0.08:
					var book_w := 0.04 + 0.03 * ((i * 7) % 3)
					var book_h := 0.22 + 0.06 * ((i * 5) % 3)
					StyleKit.box(n, Vector3(book_w, book_h, d * 0.7), Vector3(x + book_w / 2, y + book_h / 2 + 0.02, 0.0), StyleKit.mat(colors[i % colors.size()]))
					x += book_w + 0.005
					i += 1
		"shoe_rack":
			StyleKit.box(n, Vector3(w, 0.45, d), Vector3(0, 0.225, 0), StyleKit.mat(StyleKit.OAK))
			for i in int(w / 0.18):
				var c: Color = [Color(0.95, 0.3, 0.3), Color(0.25, 0.25, 0.3), Color(0.98, 0.98, 0.98), Color(0.3, 0.55, 0.95)][i % 4]
				StyleKit.box(n, Vector3(0.08, 0.07, 0.24), Vector3(-w / 2 + 0.12 + i * 0.18, 0.49, 0), StyleKit.mat(c, 0.3))
		"rug":
			StyleKit.box(n, Vector3(w, 0.012, d), Vector3(0, 0.006, 0), StyleKit.mat(StyleKit.ROSE, 0.0, 1, 0.35, Color(0.95, 0.8, 0.65)), true, 0.0)
			StyleKit.box(n, Vector3(w - 0.16, 0.014, d - 0.16), Vector3(0, 0.007, 0), StyleKit.mat(StyleKit.ROSE.lightened(0.15), 0.0, 1, 0.35, Color(0.95, 0.8, 0.65)), true, 0.0)
		"gym_mat":
			# Mattorna får olika färger efter var de ligger, så att en sal full av dem inte
			# ser upprepad ut.
			var colors := GymKit.SOFT_COLORS
			var color: Color = colors[int(absf(n.position.x * 3.0 + n.position.z * 7.0)) % colors.size()]
			StyleKit.box(n, Vector3(w, 0.03, d), Vector3(0, 0.015, 0), StyleKit.mat(color), true, 0.0)
			StyleKit.box(n, Vector3(w - 0.06, 0.032, 0.05), Vector3(0, 0.016, d / 2 - 0.08), StyleKit.mat(color.darkened(0.15)), true, 0.0)
		"plant":
			var r := minf(w, d) * 0.35
			StyleKit.cylinder(n, r, r * 0.75, r * 1.6, Vector3(0, r * 0.8, 0), StyleKit.mat(StyleKit.TERRACOTTA))
			for i in 8:
				var angle := TAU * i / 8.0
				StyleKit.sphere(n, r * 0.7, Vector3(cos(angle) * r * 0.6, r * 2.2 + (i % 3) * r * 0.4, sin(angle) * r * 0.6), StyleKit.mat(StyleKit.LEAF.lightened(0.08 * (i % 2))))
			StyleKit.sphere(n, r * 0.8, Vector3(0, r * 3.0, 0), StyleKit.mat(StyleKit.LEAF.lightened(0.05)))
		"dog_bed", "basket":
			var rim := Color(0.62, 0.45, 0.68) if kind == "dog_bed" else Color(0.85, 0.65, 0.4)
			var r := minf(w, d) / 2
			StyleKit.cylinder(n, r, r * 1.05, 0.14 if kind == "dog_bed" else 0.35, Vector3(0, 0.07 if kind == "dog_bed" else 0.175, 0), StyleKit.mat(rim))
			StyleKit.cylinder(n, r * 0.75, r * 0.75, 0.15 if kind == "dog_bed" else 0.36, Vector3(0, 0.08 if kind == "dog_bed" else 0.18, 0), StyleKit.mat(Color(1.0, 0.92, 0.8)))
		"stairs":
			_stairs(n, w, d)
		"attic_ladder":
			_attic_ladder(n, w, d)
		"toilet":
			StyleKit.box(n, Vector3(w * 0.8, 0.4, 0.18), Vector3(0, 0.75, -d / 2 + 0.1), StyleKit.mat(StyleKit.WHITE, 0.4))
			StyleKit.cylinder(n, w * 0.38, w * 0.3, 0.4, Vector3(0, 0.2, 0.05), StyleKit.mat(StyleKit.WHITE, 0.4))
			StyleKit.cylinder(n, w * 0.42, w * 0.42, 0.04, Vector3(0, 0.42, 0.05), StyleKit.mat(StyleKit.WHITE.darkened(0.05), 0.4))
		"basin":
			StyleKit.box(n, Vector3(w, 0.8, d), Vector3(0, 0.4, 0), StyleKit.mat(StyleKit.OAK))
			StyleKit.box(n, Vector3(w + 0.04, 0.05, d + 0.02), Vector3(0, 0.825, 0), StyleKit.mat(StyleKit.WHITE, 0.4))
			StyleKit.cylinder(n, minf(w, d) * 0.32, minf(w, d) * 0.28, 0.02, Vector3(0, 0.855, 0.02), StyleKit.mat(Color(0.82, 0.88, 0.92), 0.6))
			StyleKit.cylinder(n, 0.015, 0.015, 0.2, Vector3(0, 0.95, -d / 2 + 0.05), StyleKit.mat(StyleKit.METAL, 0.9))
			StyleKit.box(n, Vector3(w * 0.8, 0.6, 0.02), Vector3(0, 1.5, -d / 2 + 0.01), StyleKit.mat(Color(0.8, 0.9, 0.95), 0.9))
		"bed":
			var head := -d / 2
			StyleKit.box(n, Vector3(w, 0.3, d), Vector3(0, 0.15, 0), StyleKit.mat(StyleKit.WALNUT))
			StyleKit.box(n, Vector3(w + 0.04, 0.9, 0.08), Vector3(0, 0.45, head + 0.04), StyleKit.mat(StyleKit.WALNUT.lightened(0.05)))
			StyleKit.box(n, Vector3(w - 0.06, 0.18, d - 0.1), Vector3(0, 0.39, 0.02), StyleKit.mat(StyleKit.WHITE))
			StyleKit.box(n, Vector3(w - 0.04, 0.08, d * 0.62), Vector3(0, 0.5, d * 0.17), StyleKit.mat(HomeKit.tint(style, Color(0.45, 0.65, 0.85))))
			StyleKit.box(n, Vector3(w - 0.04, 0.09, 0.2), Vector3(0, 0.505, d * 0.17 - d * 0.31 + 0.1), StyleKit.mat(StyleKit.WHITE))
			var pillows := 2 if w > 1.2 else 1
			for i in pillows:
				var x := 0.0 if pillows == 1 else (-w / 4 if i == 0 else w / 4)
				StyleKit.box(n, Vector3(w / pillows - 0.15, 0.12, 0.32), Vector3(x, 0.54, head + 0.3), StyleKit.mat(Color(0.98, 0.97, 0.94)))
		"wardrobe":
			var h := 2.0
			StyleKit.box(n, Vector3(w, h, d), Vector3(0, h / 2, 0), StyleKit.mat(StyleKit.WHITE))
			StyleKit.box(n, Vector3(0.01, h - 0.1, 0.01), Vector3(0, h / 2, d / 2 + 0.005), StyleKit.mat(StyleKit.WHITE.darkened(0.15)), true, 0.0)
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.025, 0.25, 0.03), Vector3(s * 0.06, 1.05, d / 2 + 0.02), StyleKit.mat(StyleKit.BRASS, 0.8))
		"nightstand":
			StyleKit.box(n, Vector3(w, 0.5, d), Vector3(0, 0.25, 0), StyleKit.mat(StyleKit.OAK))
			StyleKit.box(n, Vector3(w - 0.06, 0.16, 0.02), Vector3(0, 0.35, d / 2), StyleKit.mat(StyleKit.OAK.lightened(0.06)))
			StyleKit.cylinder(n, 0.05, 0.07, 0.2, Vector3(0, 0.6, -0.02), StyleKit.mat(StyleKit.DARK))
			var shade := StyleKit.own_mat(Color(1.0, 0.92, 0.7))
			shade.set_shader_parameter("emission", Color(1.0, 0.82, 0.5))
			StyleKit.cylinder(n, 0.09, 0.13, 0.15, Vector3(0, 0.77, -0.02), shade).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_lamp_light(n, rig, Vector3(0, 0.75, 0.05), 1.6, 0.5, shade)
		"shower":
			# Duschhörna: låg platta med brunn, takdusch på en stång och en glasvägg på ena
			# sidan som bara syns som sin metallram (inga höga skivor som skymmer rummet).
			StyleKit.box(n, Vector3(w, 0.06, d), Vector3(0, 0.03, 0), StyleKit.mat(StyleKit.WHITE, 0.4))
			StyleKit.box(n, Vector3(w - 0.1, 0.012, d - 0.1), Vector3(0, 0.066, 0), StyleKit.mat(Color(0.82, 0.88, 0.9), 0.5), true, 0.0)
			StyleKit.cylinder(n, 0.04, 0.04, 0.01, Vector3(0, 0.075, 0), StyleKit.mat(StyleKit.METAL, 0.9))
			StyleKit.cylinder(n, 0.012, 0.012, 1.9, Vector3(-w * 0.25, 1.0, -d / 2 + 0.06), StyleKit.mat(StyleKit.METAL, 0.9))
			StyleKit.cylinder(n, 0.11, 0.11, 0.02, Vector3(-w * 0.25, 1.95, -d / 2 + 0.2), StyleKit.mat(StyleKit.METAL, 0.9))
			StyleKit.box(n, Vector3(0.02, 0.02, 0.16), Vector3(-w * 0.25, 1.95, -d / 2 + 0.11), StyleKit.mat(StyleKit.METAL, 0.9))
			var glass_x := w / 2 - 0.02
			for z in [-d / 2 + 0.02, d / 2 - 0.15]:
				StyleKit.box(n, Vector3(0.025, 1.85, 0.025), Vector3(glass_x, 0.985, z), StyleKit.mat(StyleKit.METAL, 0.9))
			StyleKit.box(n, Vector3(0.025, 0.025, d - 0.15), Vector3(glass_x, 1.9, -0.065), StyleKit.mat(StyleKit.METAL, 0.9))
		"bathtub":
			StyleKit.box(n, Vector3(w, 0.55, d), Vector3(0, 0.275, 0), StyleKit.mat(StyleKit.WHITE, 0.4))
			StyleKit.box(n, Vector3(w - 0.14, 0.02, d - 0.14), Vector3(0, 0.5, 0), StyleKit.mat(Color(0.55, 0.82, 0.95), 0.8), true, 0.0)
			StyleKit.cylinder(n, 0.02, 0.02, 0.2, Vector3(-w / 2 + 0.1, 0.65, 0), StyleKit.mat(StyleKit.METAL, 0.9))
		"washer":
			StyleKit.box(n, Vector3(w - 0.02, 0.85, d - 0.02), Vector3(0, 0.425, 0), StyleKit.mat(StyleKit.WHITE, 0.4))
			StyleKit.cylinder(n, 0.2, 0.2, 0.03, Vector3(0, 0.4, d / 2), StyleKit.mat(StyleKit.METAL.darkened(0.2), 0.6)).rotation_degrees = Vector3(90, 0, 0)
			StyleKit.cylinder(n, 0.15, 0.15, 0.035, Vector3(0, 0.4, d / 2 + 0.005), StyleKit.mat(Color(0.45, 0.65, 0.85), 0.8)).rotation_degrees = Vector3(90, 0, 0)
			StyleKit.box(n, Vector3(w - 0.08, 0.08, 0.02), Vector3(0, 0.77, d / 2 - 0.005), StyleKit.mat(StyleKit.WHITE.darkened(0.08)))
		"boxes":
			# Julpyntets lådor har röda lock; resten är vanlig kartong.
			var cardboard := Color(0.85, 0.35, 0.32) if style == "holiday" else Color(0.85, 0.65, 0.42)
			StyleKit.box(n, Vector3(w * 0.9, 0.45, d * 0.9), Vector3(0, 0.225, 0), StyleKit.mat(cardboard))
			StyleKit.box(n, Vector3(w * 0.6, 0.35, d * 0.6), Vector3(w * 0.1, 0.625, -d * 0.05), StyleKit.mat(cardboard.lightened(0.08)))
			StyleKit.box(n, Vector3(0.06, 0.005, d * 0.9), Vector3(0, 0.452, 0), StyleKit.mat(Color(0.92, 0.85, 0.65)), true, 0.0)
		"trunk":
			StyleKit.box(n, Vector3(w, 0.5, d), Vector3(0, 0.25, 0), StyleKit.mat(StyleKit.WALNUT))
			for x in [-w * 0.3, w * 0.3]:
				StyleKit.box(n, Vector3(0.05, 0.52, d + 0.02), Vector3(x, 0.25, 0), StyleKit.mat(StyleKit.METAL.darkened(0.3)))
			StyleKit.box(n, Vector3(0.06, 0.08, 0.03), Vector3(0, 0.38, d / 2 + 0.01), StyleKit.mat(StyleKit.BRASS, 0.8))
		"rack":
			for x in [-w / 2 + 0.02, w / 2 - 0.02]:
				for z in [-d / 2 + 0.02, d / 2 - 0.02]:
					StyleKit.box(n, Vector3(0.03, 1.4, 0.03), Vector3(x, 0.7, z), StyleKit.mat(StyleKit.METAL.darkened(0.15)))
			for y in [0.3, 0.75, 1.2]:
				StyleKit.box(n, Vector3(w, 0.03, d), Vector3(0, y, 0), StyleKit.mat(StyleKit.METAL))
			StyleKit.box(n, Vector3(0.3, 0.25, d * 0.7), Vector3(-w * 0.2, 0.44, 0), StyleKit.mat(Color(0.85, 0.65, 0.42)))
			StyleKit.box(n, Vector3(0.25, 0.2, d * 0.6), Vector3(w * 0.2, 0.87, 0), StyleKit.mat(Color(0.4, 0.6, 0.85)))
		"easel":
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.04, 1.5, 0.04), Vector3(s * 0.25, 0.75, 0), StyleKit.mat(StyleKit.OAK)).rotation_degrees = Vector3(-8, 0, s * -6)
			StyleKit.box(n, Vector3(0.7, 0.55, 0.03), Vector3(0, 1.1, 0.06), StyleKit.mat(StyleKit.WHITE))
			StyleKit.box(n, Vector3(0.5, 0.3, 0.01), Vector3(0, 1.12, 0.08), StyleKit.mat(Color(0.55, 0.75, 0.9)), true, 0.0)
		"bike":
			for x in [-w * 0.32, w * 0.32]:
				var wheel := StyleKit.cylinder(n, 0.3, 0.3, 0.04, Vector3(x, 0.32, 0), StyleKit.mat(StyleKit.DARK), 32)
				wheel.rotation_degrees = Vector3(90, 0, 0)
			var frame := HomeKit.tint(style, Color(0.9, 0.3, 0.3))
			StyleKit.box(n, Vector3(w * 0.64, 0.04, 0.04), Vector3(0, 0.55, 0), StyleKit.mat(frame, 0.5))
			StyleKit.box(n, Vector3(0.04, 0.4, 0.04), Vector3(-w * 0.05, 0.5, 0), StyleKit.mat(frame, 0.5))
			StyleKit.box(n, Vector3(0.2, 0.04, 0.08), Vector3(-w * 0.05, 0.72, 0), StyleKit.mat(StyleKit.DARK))
		"vanity":
			# Sminkbord: bänk med lådor, spegel med glödlampor, flaskor och en sminkväska.
			var cream := Color(0.95, 0.9, 0.86)
			StyleKit.box(n, Vector3(w, 0.05, d), Vector3(0, 0.76, 0), StyleKit.mat(cream, 0.3))
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.3, 0.72, d - 0.04), Vector3(s * (w / 2 - 0.16), 0.36, 0), StyleKit.mat(cream.darkened(0.04)))
				StyleKit.box(n, Vector3(0.26, 0.2, 0.02), Vector3(s * (w / 2 - 0.16), 0.55, d / 2), StyleKit.mat(cream))
				StyleKit.sphere(n, 0.015, Vector3(s * (w / 2 - 0.16), 0.55, d / 2 + 0.02), StyleKit.mat(StyleKit.BRASS, 0.8))
			StyleKit.box(n, Vector3(w * 0.7, 0.75, 0.04), Vector3(0, 1.2, -d / 2 + 0.03), StyleKit.mat(StyleKit.BRASS, 0.6))
			StyleKit.box(n, Vector3(w * 0.62, 0.67, 0.02), Vector3(0, 1.2, -d / 2 + 0.06), StyleKit.mat(Color(0.82, 0.9, 0.96), 0.9), true, 0.0)
			for i in 6:
				var bulb := StyleKit.own_mat(Color(1.0, 0.97, 0.88))
				bulb.set_shader_parameter("emission", Color(1.0, 0.85, 0.6))
				var side := -1 if i < 3 else 1
				StyleKit.sphere(n, 0.022, Vector3(side * w * 0.33, 0.95 + (i % 3) * 0.24, -d / 2 + 0.07), bulb)
				if rig:
					rig.register_lamp_shade(bulb)
			for bottle in [[Vector3(-w * 0.25, 0.83, 0.0), Color(0.95, 0.6, 0.7)], [Vector3(-w * 0.12, 0.82, -0.05), Color(0.8, 0.7, 0.9)], [Vector3(w * 0.2, 0.83, 0.02), Color(0.95, 0.85, 0.6)]]:
				StyleKit.cylinder(n, 0.025, 0.03, 0.1, bottle[0], StyleKit.mat(bottle[1], 0.7))
			StyleKit.box(n, Vector3(0.2, 0.08, 0.12), Vector3(w * 0.05, 0.82, 0.08), StyleKit.mat(Color(0.85, 0.55, 0.6)))
			_lamp_light(n, rig, Vector3(0, 1.2, 0.2), 1.6, 0.5)
		"stool":
			StyleKit.cylinder(n, 0.18, 0.18, 0.08, Vector3(0, 0.46, 0), StyleKit.mat(Color(0.93, 0.68, 0.72)))
			for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				StyleKit.box(n, Vector3(0.03, 0.42, 0.03), Vector3(corner.x * 0.11, 0.21, corner.y * 0.11), StyleKit.mat(StyleKit.BRASS, 0.6))
		"gaming_desk":
			# Gamingskrivbord: svart skiva, två skärmar, rgb-list, tangentbord, mus och burkar.
			var black := Color(0.2, 0.2, 0.24)
			StyleKit.box(n, Vector3(w, 0.05, d), Vector3(0, 0.75, 0), StyleKit.mat(black, 0.3))
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.05, 0.73, d - 0.1), Vector3(s * (w / 2 - 0.05), 0.365, 0), StyleKit.mat(black.darkened(0.2)))
			var rgb := StyleKit.own_mat(Color(0.6, 0.4, 1.0))
			rgb.set_shader_parameter("emission", Color(0.6, 0.4, 1.0))
			rgb.set_shader_parameter("emission_energy", 1.2)
			StyleKit.box(n, Vector3(w - 0.04, 0.015, 0.012), Vector3(0, 0.735, d / 2 + 0.005), rgb, false, 0.0)
			for s in [-1, 1]:
				var monitor := Node3D.new()
				monitor.position = Vector3(s * w * 0.2, 0.78, -d / 2 + 0.17)
				monitor.rotation_degrees = Vector3(0, -s * 12, 0)
				n.add_child(monitor)
				StyleKit.box(monitor, Vector3(0.05, 0.16, 0.05), Vector3(0, 0.08, -0.03), StyleKit.mat(black))
				StyleKit.box(monitor, Vector3(0.58, 0.34, 0.03), Vector3(0, 0.33, 0), StyleKit.mat(Color(0.1, 0.1, 0.12), 0.5))
				var screen := StyleKit.own_mat(Color(0.25, 0.45, 0.85) if s < 0 else Color(0.45, 0.3, 0.75))
				screen.set_shader_parameter("emission", Color(0.3, 0.55, 1.0) if s < 0 else Color(0.6, 0.35, 0.95))
				screen.set_shader_parameter("emission_energy", 0.7)
				StyleKit.box(monitor, Vector3(0.54, 0.3, 0.005), Vector3(0, 0.33, 0.017), screen, false, 0.0)
			StyleKit.box(n, Vector3(0.44, 0.02, 0.14), Vector3(-0.05, 0.785, 0.12), StyleKit.mat(Color(0.15, 0.15, 0.18)))
			StyleKit.box(n, Vector3(0.42, 0.006, 0.12), Vector3(-0.05, 0.797, 0.12), rgb, false, 0.0)
			StyleKit.box(n, Vector3(0.3, 0.004, 0.25), Vector3(0.3, 0.778, 0.12), StyleKit.mat(Color(0.25, 0.25, 0.32)), true, 0.0)
			StyleKit.sphere(n, 0.03, Vector3(0.3, 0.79, 0.12), StyleKit.mat(black, 0.5)).scale = Vector3(1, 0.6, 1.4)
			for can in [Vector3(w / 2 - 0.12, 0.84, 0.1), Vector3(w / 2 - 0.2, 0.84, 0.18)]:
				StyleKit.cylinder(n, 0.033, 0.033, 0.12, can, StyleKit.mat(Color(0.35, 0.85, 0.45), 0.6))
			# Datorlåda under skrivbordet, med glas och fläktar.
			StyleKit.box(n, Vector3(0.22, 0.48, 0.46), Vector3(w / 2 - 0.2, 0.24, 0), StyleKit.mat(black))
			StyleKit.box(n, Vector3(0.005, 0.4, 0.38), Vector3(w / 2 - 0.31, 0.26, 0), rgb, false, 0.0)
		"gaming_chair":
			var black := Color(0.15, 0.15, 0.18)
			var red := Color(0.85, 0.25, 0.3)
			StyleKit.cylinder(n, 0.25, 0.25, 0.03, Vector3(0, 0.06, 0), StyleKit.mat(black), 5)
			StyleKit.cylinder(n, 0.03, 0.03, 0.35, Vector3(0, 0.25, 0), StyleKit.mat(StyleKit.METAL, 0.6))
			StyleKit.box(n, Vector3(0.5, 0.1, 0.46), Vector3(0, 0.46, 0.02), StyleKit.mat(black))
			StyleKit.box(n, Vector3(0.5, 0.75, 0.1), Vector3(0, 0.86, -0.2), StyleKit.mat(black))
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.08, 0.7, 0.11), Vector3(s * 0.15, 0.88, -0.2), StyleKit.mat(red))
				StyleKit.box(n, Vector3(0.05, 0.05, 0.3), Vector3(s * 0.25, 0.62, 0.02), StyleKit.mat(black.lightened(0.1)))
		"beanbag":
			var purple := Color(0.5, 0.42, 0.75)
			StyleKit.sphere(n, minf(w, d) * 0.5, Vector3(0, 0.2, 0), StyleKit.mat(purple)).scale = Vector3(w / minf(w, d), 0.6, d / minf(w, d))
			StyleKit.sphere(n, minf(w, d) * 0.3, Vector3(0, 0.38, -d * 0.15), StyleKit.mat(purple.lightened(0.08))).scale = Vector3(1.3, 0.8, 0.8)
			StyleKit.box(n, Vector3(0.16, 0.04, 0.1), Vector3(0.08, 0.36, 0.12), StyleKit.mat(Color(0.2, 0.2, 0.24), 0.4)).rotation_degrees = Vector3(0, 20, 0)
		"media_stand":
			StyleKit.box(n, Vector3(w, 0.45, d), Vector3(0, 0.225, 0), StyleKit.mat(StyleKit.WALNUT))
			StyleKit.box(n, Vector3(0.36, 0.06, 0.24), Vector3(-w * 0.2, 0.48, 0.05), StyleKit.mat(StyleKit.WHITE, 0.4))
			StyleKit.box(n, Vector3(0.24, 0.05, 0.18), Vector3(w * 0.25, 0.475, 0.05), StyleKit.mat(Color(0.2, 0.2, 0.24), 0.4))
			# Tv:n vinklas lite mot rummet (och kameran), så att skärmen syns.
			var tv := Node3D.new()
			tv.position = Vector3(0, 0, -d / 2 + 0.12)
			tv.rotation_degrees = Vector3(0, 30, 0)
			n.add_child(tv)
			var tv_w := w * 0.9
			StyleKit.box(tv, Vector3(0.18, 0.04, 0.14), Vector3(0, 0.47, 0), StyleKit.mat(StyleKit.DARK))
			StyleKit.box(tv, Vector3(tv_w, tv_w * 0.56, 0.05), Vector3(0, 0.5 + tv_w * 0.28 + 0.06, 0), StyleKit.mat(Color(0.12, 0.12, 0.15), 0.7))
			var game := StyleKit.own_mat(Color(0.3, 0.7, 0.5))
			game.set_shader_parameter("emission", Color(0.35, 0.8, 0.55))
			game.set_shader_parameter("emission_energy", 0.6)
			StyleKit.box(tv, Vector3(tv_w - 0.06, tv_w * 0.56 - 0.06, 0.005), Vector3(0, 0.5 + tv_w * 0.28 + 0.06, 0.026), game, false, 0.0)
		"collectible_shelf", "trophy_shelf":
			# Låg hylla med samlarfigurer eller pokaler på två plan.
			var h := 1.1
			StyleKit.box(n, Vector3(w, h, d), Vector3(0, h / 2, 0), StyleKit.mat(StyleKit.WALNUT if kind == "collectible_shelf" else StyleKit.OAK))
			for row in 2:
				var y := 0.35 + row * 0.5
				StyleKit.box(n, Vector3(w - 0.06, 0.38, 0.02), Vector3(0, y + 0.19, d / 2 - 0.02), StyleKit.mat(StyleKit.WALNUT.darkened(0.3)), true, 0.0)
				var count := int(w / 0.18)
				for i in count:
					var x := -w / 2 + 0.12 + i * (w - 0.24) / maxf(count - 1, 1)
					if kind == "trophy_shelf":
						var gold := Color(0.95, 0.78, 0.3) if (i + row) % 3 else Color(0.82, 0.82, 0.86)
						StyleKit.box(n, Vector3(0.08, 0.04, 0.08), Vector3(x, y + 0.04, 0), StyleKit.mat(StyleKit.WALNUT))
						StyleKit.cylinder(n, 0.035, 0.012, 0.12, Vector3(x, y + 0.12, 0), StyleKit.mat(gold, 0.9))
						StyleKit.cylinder(n, 0.05, 0.035, 0.06, Vector3(x, y + 0.2, 0), StyleKit.mat(gold, 0.9))
					else:
						var figure: Color = [Color(0.9, 0.35, 0.35), Color(0.35, 0.6, 0.95), Color(0.95, 0.85, 0.35), Color(0.5, 0.85, 0.5), Color(0.8, 0.5, 0.9)][(i + row * 2) % 5]
						StyleKit.cylinder(n, 0.03, 0.04, 0.12, Vector3(x, y + 0.08, 0), StyleKit.mat(figure, 0.4))
						StyleKit.sphere(n, 0.035, Vector3(x, y + 0.17, 0), StyleKit.mat(figure.lightened(0.2), 0.4))
			if kind == "trophy_shelf":
				# En inramad lagbild ovanpå.
				StyleKit.box(n, Vector3(0.36, 0.26, 0.03), Vector3(0, h + 0.14, -d / 2 + 0.1), StyleKit.mat(StyleKit.DARK)).rotation_degrees = Vector3(-10, 0, 0)
				StyleKit.box(n, Vector3(0.3, 0.2, 0.005), Vector3(0, h + 0.145, -d / 2 + 0.118), StyleKit.mat(Color(0.4, 0.6, 0.4)), true, 0.0).rotation_degrees = Vector3(-10, 0, 0)
		"poster", "pennant", "photo_wall":
			_wall_decor(n, kind, w)
		"field_rug":
			StyleKit.box(n, Vector3(w, 0.012, d), Vector3(0, 0.006, 0), StyleKit.mat(Color(0.36, 0.62, 0.36)), true, 0.0)
			var zone := w * 0.12
			StyleKit.box(n, Vector3(zone, 0.014, d), Vector3(-w / 2 + zone / 2, 0.007, 0), StyleKit.mat(Color(0.2, 0.32, 0.62)), true, 0.0)
			StyleKit.box(n, Vector3(zone, 0.014, d), Vector3(w / 2 - zone / 2, 0.007, 0), StyleKit.mat(Color(0.85, 0.3, 0.3)), true, 0.0)
			for i in range(1, 6):
				var x := -w / 2 + zone + (w - zone * 2) * i / 6.0
				StyleKit.box(n, Vector3(0.015, 0.015, d - 0.08), Vector3(x, 0.008, 0), StyleKit.mat(StyleKit.WHITE), true, 0.0)
		"dumbbells":
			for i in 2:
				var z := -d * 0.2 + i * d * 0.4
				StyleKit.cylinder(n, 0.015, 0.015, w * 0.6, Vector3(0, 0.06, z), StyleKit.mat(StyleKit.METAL, 0.7)).rotation_degrees = Vector3(0, 0, 90)
				for s in [-1, 1]:
					StyleKit.cylinder(n, 0.06, 0.06, 0.06, Vector3(s * w * 0.32, 0.06, z), StyleKit.mat(Color(0.2, 0.2, 0.24), 0.4)).rotation_degrees = Vector3(0, 0, 90)
		"weight_bench":
			var black := Color(0.15, 0.15, 0.2)
			StyleKit.box(n, Vector3(w * 0.5, 0.1, d), Vector3(0, 0.42, 0), StyleKit.mat(black.lightened(0.1)))
			for z in [-d / 2 + 0.12, d / 2 - 0.12]:
				StyleKit.box(n, Vector3(0.05, 0.38, 0.05), Vector3(0, 0.19, z), StyleKit.mat(StyleKit.METAL.darkened(0.2)))
			# Ställning med skivstång vid bänkens huvudände.
			var head := -d / 2 + 0.1
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.05, 1.05, 0.05), Vector3(s * (w / 2 - 0.03), 0.525, head), StyleKit.mat(StyleKit.METAL.darkened(0.2)))
			StyleKit.cylinder(n, 0.015, 0.015, w + 0.5, Vector3(0, 1.0, head), StyleKit.mat(StyleKit.METAL, 0.8)).rotation_degrees = Vector3(0, 0, 90)
			for s in [-1, 1]:
				StyleKit.cylinder(n, 0.16, 0.16, 0.05, Vector3(s * (w / 2 + 0.16), 1.0, head), StyleKit.mat(Color(0.2, 0.2, 0.24), 0.4)).rotation_degrees = Vector3(0, 0, 90)
		"football_gear":
			# Sportbag med en hjälm ovanpå och en amerikansk fotboll bredvid.
			StyleKit.box(n, Vector3(w * 0.62, 0.3, d * 0.9), Vector3(-w * 0.18, 0.15, 0), StyleKit.mat(Color(0.2, 0.3, 0.55)))
			StyleKit.box(n, Vector3(w * 0.62, 0.03, 0.03), Vector3(-w * 0.18, 0.2, d * 0.45), StyleKit.mat(Color(0.95, 0.75, 0.25)))
			StyleKit.sphere(n, 0.14, Vector3(-w * 0.18, 0.42, 0), StyleKit.mat(Color(0.85, 0.25, 0.25), 0.7))
			StyleKit.box(n, Vector3(0.16, 0.05, 0.02), Vector3(-w * 0.18, 0.4, 0.13), StyleKit.mat(Color(0.95, 0.95, 0.95)))
			StyleKit.box(n, Vector3(0.02, 0.1, 0.02), Vector3(-w * 0.18, 0.37, 0.14), StyleKit.mat(Color(0.95, 0.95, 0.95)))
			var ball := StyleKit.sphere(n, 0.09, Vector3(w * 0.3, 0.07, 0.02), StyleKit.mat(Color(0.6, 0.35, 0.2), 0.3))
			ball.scale = Vector3(1.0, 0.65, 0.65)
			StyleKit.box(n, Vector3(0.06, 0.008, 0.01), Vector3(w * 0.3, 0.13, 0.02), StyleKit.mat(StyleKit.WHITE), false, 0.0)
		"car":
			# Familjens bil på uppfarten: kaross, kupé med rutor, hjul och strålkastare.
			var paint := Color(0.4, 0.55, 0.75)
			StyleKit.box(n, Vector3(w, 0.45, d), Vector3(0, 0.4, 0), StyleKit.mat(paint, 0.6), true, 0.08)
			StyleKit.box(n, Vector3(w * 0.86, 0.38, d * 0.5), Vector3(0, 0.8, -d * 0.04), StyleKit.mat(paint.lightened(0.05), 0.6), true, 0.08)
			StyleKit.box(n, Vector3(w * 0.88, 0.28, d * 0.46), Vector3(0, 0.8, -d * 0.04), StyleKit.mat(Color(0.7, 0.85, 0.95), 0.9), true, 0.05)
			for x in [-1, 1]:
				for z in [-1, 1]:
					StyleKit.cylinder(n, 0.17, 0.17, 0.14, Vector3(x * w / 2, 0.17, z * d * 0.32), StyleKit.mat(StyleKit.DARK), 16).rotation_degrees = Vector3(0, 0, 90)
			for x in [-1, 1]:
				StyleKit.box(n, Vector3(0.16, 0.06, 0.02), Vector3(x * w * 0.3, 0.45, d / 2 + 0.005), StyleKit.mat(Color(1.0, 0.95, 0.75), 0.9), false, 0.0)
		"tree":
			var r := minf(w, d) / 2
			StyleKit.cylinder(n, 0.08, 0.12, 1.4, Vector3(0, 0.7, 0), StyleKit.mat(StyleKit.WALNUT))
			for i in 7:
				var angle := TAU * i / 7.0
				StyleKit.sphere(n, r * 0.55, Vector3(cos(angle) * r * 0.45, 1.75 + (i % 2) * 0.2, sin(angle) * r * 0.45), StyleKit.mat(StyleKit.LEAF.lightened(0.06 * (i % 3))))
			StyleKit.sphere(n, r * 0.7, Vector3(0, 2.1, 0), StyleKit.mat(StyleKit.LEAF.lightened(0.1)))
		"bench":
			var wood := StyleKit.mat(StyleKit.OAK.darkened(0.1))
			for i in 3:
				StyleKit.box(n, Vector3(w, 0.03, 0.1), Vector3(0, 0.45, -d / 2 + 0.08 + i * 0.13), wood)
			StyleKit.box(n, Vector3(w, 0.1, 0.03), Vector3(0, 0.72, -d / 2 + 0.03), wood)
			StyleKit.box(n, Vector3(w, 0.1, 0.03), Vector3(0, 0.6, -d / 2 + 0.03), wood)
			for x in [-w / 2 + 0.1, w / 2 - 0.1]:
				StyleKit.box(n, Vector3(0.05, 0.45, d - 0.05), Vector3(x, 0.22, 0), StyleKit.mat(StyleKit.DARK))
		"picnic_table":
			_table(n, w, d * 0.5, 0.75, StyleKit.OAK)
			for z in [-d * 0.4, d * 0.4]:
				StyleKit.box(n, Vector3(w, 0.05, 0.22), Vector3(0, 0.45, z), StyleKit.mat(StyleKit.OAK.darkened(0.08)))
				for x in [-w / 2 + 0.12, w / 2 - 0.12]:
					StyleKit.box(n, Vector3(0.05, 0.45, 0.05), Vector3(x, 0.22, z), StyleKit.mat(StyleKit.OAK.darkened(0.2)))
		"pond":
			var water := StyleKit.mat(Color(0.45, 0.7, 0.85), 0.9)
			var rim := StyleKit.cylinder(n, 0.5, 0.52, 0.06, Vector3(0, 0.03, 0), StyleKit.mat(Color(0.75, 0.72, 0.66)), 32)
			rim.scale = Vector3(w, 1, d)
			var surface := StyleKit.cylinder(n, 0.46, 0.46, 0.07, Vector3(0, 0.035, 0), water, 32)
			surface.scale = Vector3(w, 1, d)
			for i in 3:
				StyleKit.cylinder(n, 0.09, 0.09, 0.01, Vector3(-w * 0.2 + i * 0.25, 0.075, d * (0.1 - i * 0.08)), StyleKit.mat(StyleKit.LEAF.lightened(0.15)), 12)
		"store_shelf":
			# Butikshylla med varor i färgglada förpackningar på tre plan.
			StyleKit.box(n, Vector3(w, 1.5, d * 0.5), Vector3(0, 0.75, 0), StyleKit.mat(StyleKit.WHITE))
			for row in 4:
				StyleKit.box(n, Vector3(w, 0.03, d), Vector3(0, 0.22 + row * 0.45, 0), StyleKit.mat(StyleKit.WHITE.darkened(0.05)))
			var goods := [Color(0.95, 0.45, 0.35), Color(0.95, 0.8, 0.3), Color(0.4, 0.65, 0.9), Color(0.5, 0.8, 0.45), Color(0.85, 0.55, 0.8)]
			for row in 3:
				var y := 0.25 + row * 0.45
				var x := -w / 2 + 0.1
				var i := row * 2
				while x < w / 2 - 0.1:
					var size := Vector3(0.12, 0.2 + 0.06 * (i % 2), 0.12)
					# Varor på båda sidor, så att hyllor mitt i butiken också ser fyllda ut.
					for side in [-1, 1]:
						StyleKit.box(n, size, Vector3(x + 0.06, y + size.y / 2, side * (d / 2 - 0.02)), StyleKit.mat(goods[(i + (side + 1)) % goods.size()]))
					x += 0.15
					i += 1
		"clothes_rack":
			for x in [-w / 2 + 0.04, w / 2 - 0.04]:
				StyleKit.box(n, Vector3(0.04, 1.4, 0.04), Vector3(x, 0.7, 0), StyleKit.mat(StyleKit.BRASS, 0.7))
			StyleKit.cylinder(n, 0.015, 0.015, w, Vector3(0, 1.38, 0), StyleKit.mat(StyleKit.BRASS, 0.7)).rotation_degrees = Vector3(0, 0, 90)
			var clothes := [Color(0.95, 0.85, 0.75), Color(0.85, 0.4, 0.45), Color(0.4, 0.5, 0.7), Color(0.55, 0.7, 0.5), Color(0.25, 0.25, 0.3)]
			var count := int(w / 0.12)
			for i in count:
				StyleKit.box(n, Vector3(0.05, 0.75, 0.38), Vector3(-w / 2 + 0.1 + i * (w - 0.2) / maxf(count - 1, 1), 0.98, 0), StyleKit.mat(clothes[i % clothes.size()]))
		"whiteboard":
			StyleKit.box(n, Vector3(w, 1.0, 0.03), Vector3(0, 1.45, -0.05), StyleKit.mat(StyleKit.METAL.darkened(0.1)), false, 0.0)
			StyleKit.box(n, Vector3(w - 0.08, 0.92, 0.01), Vector3(0, 1.45, -0.03), StyleKit.mat(StyleKit.WHITE, 0.3), false, 0.0)
			for i in 3:
				StyleKit.box(n, Vector3(w * (0.5 - i * 0.1), 0.02, 0.005), Vector3(-w * 0.1, 1.7 - i * 0.15, -0.022), StyleKit.mat(Color(0.3, 0.4, 0.7)), false, 0.0)
		"mirror_wall":
			StyleKit.box(n, Vector3(w, 1.6, 0.02), Vector3(0, 1.1, -0.05), StyleKit.mat(Color(0.8, 0.9, 0.96), 0.9), false, 0.0)
		"path":
			# Stenplattor i en rad.
			var stones := int(maxf(w, d) / 0.5)
			var long_x := w > d
			for i in stones:
				var t := -maxf(w, d) / 2 + (i + 0.5) * maxf(w, d) / stones
				var at := Vector3(t, 0.012, 0) if long_x else Vector3(0, 0.012, t)
				StyleKit.box(n, Vector3(0.42, 0.024, 0.38) if long_x else Vector3(minf(w, d) * 0.8, 0.024, 0.38), at, StyleKit.mat(Color(0.86, 0.82, 0.74)), true, 0.01)
		"produce_stand", "freezer", "checkout", "shopping_carts":
			_grocery_fixture(n, kind, w, d)
		"planter", "fountain", "kiosk", "directory":
			_concourse_fixture(n, rig, kind, w, d)
		"salon_station", "color_bar", "wash_station", "hood_dryer":
			_salon_fixture(n, rig, kind, w, d)
		"reception_desk", "mannequin", "display_shelf", "display_table", "display_case", "fitting_room", "espresso_bar":
			_shop_fixture(n, kind, w, d)
		_:
			StyleKit.box(n, Vector3(w, 0.6, d), Vector3(0, 0.3, 0), StyleKit.mat(Color(0.75, 0.62, 0.5)))


static func _table(n: Node3D, w: float, d: float, height: float, color: Color) -> void:
	StyleKit.box(n, Vector3(w, 0.05, d), Vector3(0, height, 0), StyleKit.mat(color, 0.2))
	StyleKit.box(n, Vector3(w - 0.12, 0.06, d - 0.12), Vector3(0, height - 0.055, 0), StyleKit.mat(color.darkened(0.1)))
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		StyleKit.box(n, Vector3(0.06, height - 0.02, 0.06), Vector3(corner.x * (w / 2 - 0.08), (height - 0.02) / 2, corner.y * (d / 2 - 0.08)), StyleKit.mat(color.darkened(0.15)))


## Soffa med ryggstöd mot väggen (-z), sittdynor, armstöd och kuddar.
static func _sofa(n: Node3D, w: float, d: float, wide: bool, c := StyleKit.SAGE) -> void:
	var arm := 0.18
	StyleKit.box(n, Vector3(w, 0.32, d), Vector3(0, 0.22, 0), StyleKit.mat(c.darkened(0.12)))
	# Ryggen är en aning smalare och grundare än soffan, så att armstödens sidor och
	# baksidor inte ligger i samma plan som den (z-fighting).
	StyleKit.box(n, Vector3(w - 0.02, 0.5, 0.22), Vector3(0, 0.6, -d / 2 + 0.115), StyleKit.mat(c))
	for s in [-1, 1]:
		StyleKit.box(n, Vector3(arm, 0.55, d), Vector3(s * (w / 2 - arm / 2), 0.33, 0), StyleKit.mat(c.darkened(0.05)))
	var seats := 3 if wide and w > 1.8 else (2 if wide else 1)
	var seat_w := (w - arm * 2) / seats
	for i in seats:
		var x := -w / 2 + arm + seat_w * (i + 0.5)
		StyleKit.box(n, Vector3(seat_w - 0.03, 0.14, d - 0.26), Vector3(x, 0.45, 0.1), StyleKit.mat(c.lightened(0.08)))
		StyleKit.box(n, Vector3(seat_w - 0.04, 0.36, 0.14), Vector3(x, 0.64, -d / 2 + 0.28), StyleKit.mat(c.lightened(0.04)))
	for s in [-1, 1]:
		StyleKit.box(n, Vector3(0.05, 0.08, 0.05), Vector3(s * (w / 2 - 0.08), 0.03, d / 2 - 0.08), StyleKit.mat(StyleKit.WALNUT))
	if wide:
		StyleKit.box(n, Vector3(0.32, 0.28, 0.12), Vector3(-w / 2 + arm + 0.22, 0.66, -d / 2 + 0.38), StyleKit.mat(Color(1.0, 0.82, 0.5))).rotation_degrees = Vector3(-10, 10, 0)
		StyleKit.box(n, Vector3(0.32, 0.28, 0.12), Vector3(w / 2 - arm - 0.22, 0.66, -d / 2 + 0.38), StyleKit.mat(Color(0.95, 0.5, 0.5))).rotation_degrees = Vector3(-10, -10, 0)


# --- Köpcentret -----------------------------------------------------------------

## Livsmedelsbutikens inredning: fruktdiskar, frysdiskar, kassor och kundvagnar.
static func _grocery_fixture(n: Node3D, kind: String, w: float, d: float) -> void:
	match kind:
		"produce_stand":
			# Lådor med frukt och grönt, lutade mot kunden på en låg träbänk.
			StyleKit.box(n, Vector3(w, 0.55, d), Vector3(0, 0.275, 0), StyleKit.mat(StyleKit.OAK.darkened(0.1)))
			var produce := [Color(0.95, 0.45, 0.3), Color(0.6, 0.82, 0.35), Color(0.98, 0.8, 0.3), Color(0.55, 0.35, 0.6), Color(0.95, 0.6, 0.25)]
			var crates := maxi(2, int(w / 0.5))
			var crate_w := w / crates
			for i in crates:
				var crate := Node3D.new()
				crate.position = Vector3(-w / 2 + (i + 0.5) * crate_w, 0.6, 0)
				crate.rotation_degrees = Vector3(14, 0, 0)
				n.add_child(crate)
				StyleKit.box(crate, Vector3(crate_w - 0.04, 0.12, d - 0.06), Vector3(0, 0.06, 0), StyleKit.mat(StyleKit.OAK.lightened(0.1)))
				var color: Color = produce[(i * 2) % produce.size()]
				for row in 3:
					for col in 3:
						var at := Vector3(-crate_w / 2 + 0.1 + col * (crate_w - 0.2) / 2.0, 0.16, -d / 2 + 0.16 + row * (d - 0.32) / 2.0)
						StyleKit.sphere(crate, 0.06, at, StyleKit.mat(color.lightened(0.06 * ((row + col) % 2)), 0.4))
		"freezer":
			# Frysdisk: vit låda med glaslock och färgglada förpackningar under glaset.
			StyleKit.box(n, Vector3(w, 0.8, d), Vector3(0, 0.4, 0), StyleKit.mat(StyleKit.WHITE, 0.3))
			var packs := [Color(0.4, 0.65, 0.9), Color(0.95, 0.85, 0.7), Color(0.9, 0.4, 0.4), Color(0.95, 0.95, 0.95)]
			var count := int(w / 0.22)
			for i in count:
				StyleKit.box(n, Vector3(0.16, 0.06, d * 0.6), Vector3(-w / 2 + 0.16 + i * (w - 0.32) / maxf(count - 1, 1), 0.77, 0), StyleKit.mat(packs[i % packs.size()]))
			StyleKit.box(n, Vector3(w - 0.08, 0.02, d - 0.08), Vector3(0, 0.815, 0), StyleKit.mat(Color(0.78, 0.9, 0.96), 0.9), true, 0.0)
			StyleKit.box(n, Vector3(w, 0.06, 0.03), Vector3(0, 0.6, d / 2 + 0.01), StyleKit.mat(Color(0.4, 0.65, 0.9)))
		"checkout":
			# Kassa: disk med rullband, kassaapparat och en lampa med kassans nummer.
			StyleKit.box(n, Vector3(w, 0.85, d), Vector3(0, 0.425, 0), StyleKit.mat(StyleKit.WHITE.darkened(0.04)))
			StyleKit.box(n, Vector3(w * 0.6, 0.02, d - 0.16), Vector3(-w * 0.18, 0.86, 0), StyleKit.mat(StyleKit.DARK), true, 0.0)
			StyleKit.box(n, Vector3(0.3, 0.2, 0.26), Vector3(w * 0.3, 0.95, -d * 0.1), StyleKit.mat(StyleKit.DARK.lightened(0.15), 0.4))
			StyleKit.box(n, Vector3(0.28, 0.16, 0.02), Vector3(w * 0.3, 1.16, -d * 0.1 + 0.08), StyleKit.mat(Color(0.45, 0.72, 0.9), 0.6)).rotation_degrees = Vector3(-15, 0, 0)
			StyleKit.cylinder(n, 0.02, 0.02, 1.25, Vector3(w / 2 - 0.06, 1.47, -d / 2 + 0.06), StyleKit.mat(StyleKit.METAL, 0.6))
			var lane := StyleKit.own_mat(Color(0.98, 0.86, 0.42))
			lane.set_shader_parameter("emission", Color(1.0, 0.85, 0.4))
			lane.set_shader_parameter("emission_energy", 0.6)
			StyleKit.cylinder(n, 0.1, 0.1, 0.12, Vector3(w / 2 - 0.06, 2.12, -d / 2 + 0.06), lane, 12)
		"shopping_carts":
			# Kundvagnar inskjutna i varandra.
			var wire := StyleKit.mat(StyleKit.METAL, 0.6)
			var red := StyleKit.mat(Color(0.86, 0.35, 0.32), 0.3)
			for i in 3:
				var cart := Node3D.new()
				cart.position = Vector3(0, 0, -d / 2 + 0.45 + i * 0.28)
				n.add_child(cart)
				StyleKit.box(cart, Vector3(w * 0.75, 0.42, 0.72), Vector3(0, 0.72, 0), wire)
				StyleKit.box(cart, Vector3(w * 0.7, 0.36, 0.66), Vector3(0, 0.75, 0), StyleKit.mat(StyleKit.METAL.darkened(0.25)), true, 0.0)
				StyleKit.box(cart, Vector3(w * 0.8, 0.04, 0.04), Vector3(0, 1.0, 0.4), red)
				for x in [-w * 0.3, w * 0.3]:
					StyleKit.box(cart, Vector3(0.03, 0.5, 0.03), Vector3(x, 0.3, 0.25), wire)
					StyleKit.cylinder(cart, 0.05, 0.05, 0.04, Vector3(x, 0.05, 0.25), StyleKit.mat(StyleKit.DARK), 12).rotation_degrees = Vector3(0, 0, 90)


## Gångarnas inredning: planteringar, fontänen, kiosk-vagnen och vägvisaren.
static func _concourse_fixture(n: Node3D, rig: TimeOfDayRig, kind: String, w: float, d: float) -> void:
	match kind:
		"planter":
			# Upphöjd plantering i sten med ett litet träd och buskar.
			StyleKit.box(n, Vector3(w, 0.5, d), Vector3(0, 0.25, 0), StyleKit.mat(StyleKit.STONE.darkened(0.06)))
			StyleKit.box(n, Vector3(w + 0.06, 0.05, d + 0.06), Vector3(0, 0.52, 0), StyleKit.mat(StyleKit.WALNUT, 0.2))
			StyleKit.box(n, Vector3(w - 0.12, 0.02, d - 0.12), Vector3(0, 0.54, 0), StyleKit.mat(Color(0.45, 0.33, 0.25)), true, 0.0)
			var r := minf(w, d) / 2
			for i in 7:
				var angle := TAU * i / 7.0
				StyleKit.sphere(n, r * 0.3, Vector3(cos(angle) * r * 0.62, 0.66, sin(angle) * r * 0.62), StyleKit.mat(StyleKit.LEAF.lightened(0.06 * (i % 3))))
			StyleKit.cylinder(n, 0.04, 0.06, 1.1, Vector3(0, 1.05, 0), StyleKit.mat(StyleKit.WALNUT))
			for i in 5:
				var angle := TAU * i / 5.0
				StyleKit.sphere(n, r * 0.42, Vector3(cos(angle) * r * 0.3, 1.7 + (i % 2) * 0.12, sin(angle) * r * 0.3), StyleKit.mat(StyleKit.LEAF.lightened(0.05 * (i % 2))))
			StyleKit.sphere(n, r * 0.5, Vector3(0, 1.95, 0), StyleKit.mat(StyleKit.LEAF.lightened(0.1)))
		"fountain":
			# Fontänen mitt i ljusgården: rund stenkant, vatten, en skål på en pelare med en
			# stråle, och mynt på botten från alla som har önskat något.
			var r := minf(w, d) / 2
			var stone := StyleKit.mat(StyleKit.STONE.darkened(0.04))
			var water := StyleKit.mat(Color(0.5, 0.75, 0.88), 0.9)
			StyleKit.cylinder(n, r, r + 0.04, 0.34, Vector3(0, 0.17, 0), stone, 40)
			StyleKit.cylinder(n, r - 0.04, r - 0.04, 0.04, Vector3(0, 0.36, 0), water, 40)
			var rim := TorusMesh.new()
			rim.inner_radius = r - 0.1
			rim.outer_radius = r + 0.06
			rim.rings = 48
			StyleKit.add(n, rim, Vector3(0, 0.4, 0), StyleKit.mat(StyleKit.STONE, 0.2)).scale = Vector3(1, 0.7, 1)
			for i in 9:
				var angle := TAU * i / 9.0 + 0.4
				var coin := StyleKit.cylinder(n, 0.025, 0.025, 0.006, Vector3(cos(angle) * r * (0.35 + 0.1 * (i % 3)), 0.383, sin(angle) * r * (0.35 + 0.1 * (i % 3))), StyleKit.mat(StyleKit.BRASS if i % 3 else StyleKit.METAL, 0.9), 10)
				coin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			StyleKit.cylinder(n, 0.14, 0.2, 1.0, Vector3(0, 0.9, 0), stone, 16)
			StyleKit.cylinder(n, r * 0.4, r * 0.14, 0.2, Vector3(0, 1.45, 0), stone, 24)
			StyleKit.cylinder(n, r * 0.36, r * 0.36, 0.03, Vector3(0, 1.54, 0), water, 24)
			StyleKit.cylinder(n, 0.04, 0.07, 0.4, Vector3(0, 1.74, 0), water, 10)
			var spray := StyleKit.particles(n, 50, 0.9, Vector3(0.04, 0.02, 0.04), Vector3(0, 1.9, 0), Color(0.88, 0.96, 1.0, 0.7), 0.05, Vector3(0, 0.9, 0), 0.05)
			spray.emitting = true
		"kiosk":
			# Kiosk-vagn med solglasögon och mobilskal: disk på hjul och en randig markis.
			var body := Color(0.95, 0.88, 0.78)
			StyleKit.box(n, Vector3(w, 0.85, d * 0.7), Vector3(0, 0.55, 0), StyleKit.mat(body))
			StyleKit.box(n, Vector3(w + 0.04, 0.05, d * 0.7 + 0.04), Vector3(0, 1.0, 0), StyleKit.mat(StyleKit.WALNUT, 0.2))
			StyleKit.box(n, Vector3(w * 0.8, 0.22, 0.02), Vector3(0, 0.7, d * 0.35 + 0.01), StyleKit.mat(Color(0.86, 0.5, 0.48)))
			for x in [-w / 2 + 0.18, w / 2 - 0.18]:
				StyleKit.cylinder(n, 0.1, 0.1, 0.05, Vector3(x, 0.1, d * 0.36), StyleKit.mat(StyleKit.DARK), 16).rotation_degrees = Vector3(0, 0, 90)
			for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				StyleKit.box(n, Vector3(0.03, 1.0, 0.03), Vector3(corner.x * (w / 2 - 0.04), 1.5, corner.y * (d * 0.35 - 0.03)), StyleKit.mat(StyleKit.BRASS, 0.6))
			var stripes := maxi(4, int(w / 0.2))
			for i in stripes:
				# Varannan rand en millimeter högre, så att överlappen inte flimrar.
				StyleKit.box(n, Vector3(w / stripes + 0.005, 0.04 + (i % 2) * 0.002, d), Vector3(-w / 2 + (i + 0.5) * w / stripes, 2.02, 0), StyleKit.mat(Color(0.86, 0.5, 0.48) if i % 2 == 0 else StyleKit.WHITE), true, 0.0)
			var goods := [Color(0.2, 0.2, 0.24), Color(0.95, 0.6, 0.7), Color(0.45, 0.7, 0.9), Color(0.95, 0.85, 0.4)]
			for i in 6:
				StyleKit.box(n, Vector3(0.1, 0.03 + 0.02 * (i % 2), 0.16), Vector3(-w / 2 + 0.2 + i * (w - 0.4) / 5.0, 1.05, 0.0), StyleKit.mat(goods[i % goods.size()], 0.5))
		"directory":
			# Vägvisaren: en stående tavla med köpcentrets karta, butikerna i sina färger och
			# en röd prick för "du är här".
			StyleKit.box(n, Vector3(w + 0.1, 0.1, 0.3), Vector3(0, 0.05, 0), StyleKit.mat(StyleKit.DARK))
			StyleKit.box(n, Vector3(w, 1.7, 0.12), Vector3(0, 0.95, 0), StyleKit.mat(StyleKit.DARK.lightened(0.15), 0.3))
			var face := StyleKit.own_mat(StyleKit.WHITE)
			face.set_shader_parameter("emission", Color(1.0, 0.98, 0.94))
			face.set_shader_parameter("emission_energy", 0.25)
			StyleKit.box(n, Vector3(w - 0.12, 1.1, 0.01), Vector3(0, 1.15, 0.065), face, false, 0.0)
			var plan: Dictionary = PlanDrawer.FLOOR_PLANS["Köpcentret"]
			var scale := (w - 0.2) / 32.0
			for room_id in plan:
				var rect: Rect2 = plan[room_id]
				var color: Color = StyleKit.WALL_COLORS.get(room_id, StyleKit.CREAM).darkened(0.12)
				var center := Vector3(-16.0 + rect.get_center().x, 1.35 - (rect.get_center().y - 7.5) * scale, 0.072)
				center.x *= scale
				StyleKit.box(n, Vector3(rect.size.x * scale - 0.01, rect.size.y * scale - 0.01, 0.006), center, StyleKit.mat(color), false, 0.0)
			StyleKit.sphere(n, 0.025, Vector3((-16.0 + 16.0) * scale, 1.35 - (1.25 - 7.5) * scale, 0.08), StyleKit.mat(Color(0.9, 0.25, 0.25)))
			if rig:
				rig.register_lamp_shade(face)


## Frisörsalongens inredning: arbetsplatser, färgbaren, tvättstolar och torkhuven.
static func _salon_fixture(n: Node3D, rig: TimeOfDayRig, kind: String, w: float, d: float) -> void:
	var black := Color(0.18, 0.18, 0.22)
	match kind:
		"salon_station":
			# Arbetsplats: spegel med glödlampor på väggen, en hylla med borstar, spray och
			# en hårtork, och en pumpstol i svart läder som vänder sig mot spegeln.
			var back := -d / 2
			StyleKit.box(n, Vector3(w * 0.8, 1.0, 0.04), Vector3(0, 1.45, back + 0.03), StyleKit.mat(StyleKit.WHITE))
			StyleKit.box(n, Vector3(w * 0.72, 0.92, 0.02), Vector3(0, 1.45, back + 0.055), StyleKit.mat(Color(0.82, 0.9, 0.96), 0.9), true, 0.0)
			for i in 4:
				var bulb := StyleKit.own_mat(Color(1.0, 0.97, 0.88))
				bulb.set_shader_parameter("emission", Color(1.0, 0.88, 0.65))
				bulb.set_shader_parameter("emission_energy", 0.4)
				StyleKit.sphere(n, 0.025, Vector3(-w * 0.3 + i * w * 0.2, 2.0, back + 0.06), bulb)
			StyleKit.box(n, Vector3(w * 0.9, 0.05, 0.32), Vector3(0, 0.85, back + 0.18), StyleKit.mat(StyleKit.WHITE, 0.3))
			StyleKit.box(n, Vector3(w * 0.32, 0.8, 0.3), Vector3(-w * 0.28, 0.42, back + 0.17), StyleKit.mat(StyleKit.WHITE.darkened(0.05)))
			for bottle in [[Vector3(-w * 0.3, 0.95, back + 0.12), Color(0.95, 0.6, 0.7)], [Vector3(-w * 0.22, 0.94, back + 0.14), Color(0.55, 0.75, 0.9)], [Vector3(w * 0.32, 0.96, back + 0.12), Color(0.95, 0.9, 0.75)]]:
				StyleKit.cylinder(n, 0.03, 0.035, 0.16, bottle[0], StyleKit.mat(bottle[1], 0.6))
			StyleKit.box(n, Vector3(0.18, 0.08, 0.08), Vector3(w * 0.12, 0.92, back + 0.18), StyleKit.mat(black, 0.4))
			StyleKit.cylinder(n, 0.035, 0.035, 0.12, Vector3(w * 0.12 + 0.11, 0.92, back + 0.18), StyleKit.mat(black, 0.4)).rotation_degrees = Vector3(0, 0, 90)
			StyleKit.box(n, Vector3(0.2, 0.012, 0.04), Vector3(-w * 0.05, 0.882, back + 0.22), StyleKit.mat(Color(0.95, 0.5, 0.6))).rotation_degrees = Vector3(0, 20, 0)
			_styling_chair(n, Vector3(0, 0, d / 2 - 0.35), black)
		"color_bar":
			# Färgbaren: hylla med tuber i alla nyanser salongen gör (AppearanceData), skålar
			# och penslar på disken, och en ring med hårslingor att välja färg ur.
			var h := 1.6
			var white := StyleKit.mat(StyleKit.WHITE)
			StyleKit.box(n, Vector3(w, 0.88, d), Vector3(0, 0.44, 0), white)
			StyleKit.box(n, Vector3(w + 0.04, 0.04, d + 0.06), Vector3(0, 0.9, 0.03), StyleKit.mat(StyleKit.STONE, 0.3))
			StyleKit.box(n, Vector3(w, h - 0.92, 0.06), Vector3(0, (h + 0.92) / 2, -d / 2 + 0.03), white)
			for x in [-w / 2 + 0.02, w / 2 - 0.02]:
				StyleKit.box(n, Vector3(0.04, h - 0.92, d * 0.55), Vector3(x, (h + 0.92) / 2, -d / 2 + d * 0.275), white)
			var shades: Array[Color] = []
			for option in AppearanceData.OPTIONS["hair_color"].values():
				shades.append(option["swatch"])
			for row in 2:
				var y := 1.12 + row * 0.26
				StyleKit.box(n, Vector3(w - 0.06, 0.025, d * 0.5), Vector3(0, y, -d / 2 + d * 0.25 + 0.03), white)
				var count := int((w - 0.14) / 0.07)
				for i in count:
					var shade: Color = shades[(i / 3 + row) % shades.size()]
					StyleKit.cylinder(n, 0.022, 0.022, 0.15, Vector3(-w / 2 + 0.09 + i * 0.07, y + 0.088, -d / 2 + 0.16), StyleKit.mat(shade.lightened(0.15), 0.5), 8)
			for i in 2:
				StyleKit.cylinder(n, 0.07, 0.05, 0.05, Vector3(-w * 0.15 + i * 0.2, 0.945, 0.12), StyleKit.mat(black, 0.4), 12)
				StyleKit.box(n, Vector3(0.18, 0.01, 0.025), Vector3(-w * 0.15 + i * 0.2 + 0.05, 0.93, 0.22), StyleKit.mat(StyleKit.WHITE), true, 0.0)
			for i in shades.size():
				var lock := StyleKit.box(n, Vector3(0.03, 0.22, 0.012), Vector3(w * 0.32, 1.48, d / 2 + 0.03), StyleKit.mat(shades[i]))
				lock.rotation_degrees = Vector3(0, 0, -30 + i * 15)
				lock.position += Vector3(sin(deg_to_rad(-30 + i * 15)) * 0.1, 0, 0.003 * i)
		"wash_station":
			# Två tvättstolar: svarta handfat mot väggen och bakåtlutade stolar framför.
			var seats := 2
			for i in seats:
				var x := -w / 2 + (i + 0.5) * w / seats
				StyleKit.box(n, Vector3(0.5, 0.82, 0.34), Vector3(x, 0.41, -d / 2 + 0.17), StyleKit.mat(StyleKit.WHITE))
				var bowl := StyleKit.cylinder(n, 0.2, 0.14, 0.12, Vector3(x, 0.86, -d / 2 + 0.2), StyleKit.mat(black, 0.6), 20)
				bowl.scale = Vector3(1, 1, 0.8)
				StyleKit.cylinder(n, 0.012, 0.012, 0.18, Vector3(x, 0.98, -d / 2 + 0.05), StyleKit.mat(StyleKit.METAL, 0.9))
				StyleKit.box(n, Vector3(0.36, 0.38, 0.5), Vector3(x, 0.19, -d / 2 + 0.62), StyleKit.mat(black.lightened(0.1)))
				StyleKit.box(n, Vector3(0.5, 0.12, 0.48), Vector3(x, 0.45, -d / 2 + 0.62), StyleKit.mat(black, 0.3))
				StyleKit.box(n, Vector3(0.5, 0.62, 0.1), Vector3(x, 0.72, -d / 2 + 0.38), StyleKit.mat(black, 0.3)).rotation_degrees = Vector3(-35, 0, 0)
				StyleKit.box(n, Vector3(0.44, 0.08, 0.36), Vector3(x, 0.4, d / 2 - 0.2), StyleKit.mat(black, 0.3)).rotation_degrees = Vector3(18, 0, 0)
		"hood_dryer":
			# Torkhuv: en fåtölj med en stor rosa huv på en stolpe ovanför.
			StyleKit.box(n, Vector3(w * 0.8, 0.42, d * 0.7), Vector3(0, 0.21, 0.04), StyleKit.mat(black.lightened(0.1)))
			StyleKit.box(n, Vector3(w * 0.8, 0.12, d * 0.7), Vector3(0, 0.48, 0.04), StyleKit.mat(black, 0.3))
			StyleKit.box(n, Vector3(w * 0.8, 0.55, 0.1), Vector3(0, 0.8, -d / 2 + 0.1), StyleKit.mat(black, 0.3))
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.08, 0.2, d * 0.6), Vector3(s * w * 0.42, 0.62, 0.04), StyleKit.mat(black, 0.3))
			StyleKit.cylinder(n, 0.025, 0.025, 1.4, Vector3(0, 0.7, -d / 2 + 0.02), StyleKit.mat(StyleKit.METAL, 0.7), 10)
			var hood := StyleKit.sphere(n, 0.27, Vector3(0, 1.38, -0.04), StyleKit.mat(Color(0.95, 0.76, 0.8), 0.5))
			hood.scale = Vector3(1, 0.8, 1)
			hood.rotation_degrees = Vector3(-15, 0, 0)


## En frisörstol: rund fot, pumppelare, sits, rygg och armstöd. Den vänder sig mot -z.
static func _styling_chair(n: Node3D, at: Vector3, black: Color) -> void:
	var chair := Node3D.new()
	chair.position = at
	n.add_child(chair)
	StyleKit.cylinder(chair, 0.24, 0.26, 0.04, Vector3(0, 0.02, 0), StyleKit.mat(StyleKit.METAL, 0.8), 24)
	StyleKit.cylinder(chair, 0.04, 0.05, 0.36, Vector3(0, 0.22, 0), StyleKit.mat(StyleKit.METAL, 0.8), 12)
	StyleKit.box(chair, Vector3(0.5, 0.12, 0.48), Vector3(0, 0.46, 0), StyleKit.mat(black, 0.3))
	StyleKit.box(chair, Vector3(0.5, 0.58, 0.1), Vector3(0, 0.78, 0.22), StyleKit.mat(black, 0.3))
	StyleKit.box(chair, Vector3(0.18, 0.1, 0.08), Vector3(0, 1.12, 0.22), StyleKit.mat(black, 0.3))
	for s in [-1, 1]:
		StyleKit.box(chair, Vector3(0.06, 0.05, 0.4), Vector3(s * 0.27, 0.64, 0.02), StyleKit.mat(StyleKit.METAL, 0.8))
	StyleKit.box(chair, Vector3(0.3, 0.03, 0.12), Vector3(0, 0.12, -0.32), StyleKit.mat(StyleKit.METAL, 0.8))


## Butikernas inredning: kassadiskar, skyltdockor, hyllor och bord, glasdisken,
## provhytterna och kaféets espressobar.
static func _shop_fixture(n: Node3D, kind: String, w: float, d: float) -> void:
	match kind:
		"reception_desk":
			# Kassadisk: vit front, träskiva, kassaskärm och kortläsare.
			StyleKit.box(n, Vector3(w, 0.95, d), Vector3(0, 0.475, 0), StyleKit.mat(StyleKit.WHITE))
			StyleKit.box(n, Vector3(w + 0.06, 0.04, d + 0.06), Vector3(0, 0.97, 0), StyleKit.mat(StyleKit.OAK, 0.3))
			StyleKit.box(n, Vector3(0.05, 0.14, 0.05), Vector3(w * 0.22, 1.06, -d * 0.15), StyleKit.mat(StyleKit.DARK))
			StyleKit.box(n, Vector3(0.32, 0.22, 0.02), Vector3(w * 0.22, 1.2, -d * 0.15), StyleKit.mat(StyleKit.DARK, 0.5)).rotation_degrees = Vector3(-12, 0, 0)
			StyleKit.box(n, Vector3(0.08, 0.03, 0.12), Vector3(-w * 0.2, 1.005, 0.05), StyleKit.mat(StyleKit.DARK.lightened(0.2), 0.4))
		"mannequin":
			# Skyltdocka i en klänning på en fot; klänningens färg skiftar mellan dockorna.
			var dresses := [Color(0.85, 0.4, 0.45), Color(0.4, 0.62, 0.62), Color(0.95, 0.85, 0.7)]
			var dress: Color = dresses[int(absf(n.position.x * 7.0 + n.position.z * 3.0)) % dresses.size()]
			var skin := Color(0.96, 0.93, 0.89)
			StyleKit.cylinder(n, 0.18, 0.2, 0.04, Vector3(0, 0.02, 0), StyleKit.mat(StyleKit.DARK), 20)
			StyleKit.cylinder(n, 0.015, 0.015, 0.5, Vector3(0, 0.27, 0), StyleKit.mat(StyleKit.METAL, 0.8))
			StyleKit.cylinder(n, 0.14, 0.27, 0.75, Vector3(0, 0.85, 0), StyleKit.mat(dress), 20)
			StyleKit.cylinder(n, 0.16, 0.13, 0.42, Vector3(0, 1.43, 0), StyleKit.mat(dress), 20)
			StyleKit.sphere(n, 0.11, Vector3(0, 1.62, 0), StyleKit.mat(skin)).scale = Vector3(1.6, 0.5, 1.0)
			StyleKit.cylinder(n, 0.035, 0.04, 0.12, Vector3(0, 1.72, 0), StyleKit.mat(skin))
			StyleKit.sphere(n, 0.1, Vector3(0, 1.86, 0), StyleKit.mat(skin)).scale = Vector3(0.85, 1.1, 0.95)
		"display_shelf":
			# Hylla med skor och väskor.
			var h := 1.5
			StyleKit.box(n, Vector3(w, h, d), Vector3(0, h / 2, 0), StyleKit.mat(StyleKit.OAK.lightened(0.12)))
			var colors := [Color(0.85, 0.4, 0.45), Color(0.25, 0.25, 0.3), Color(0.95, 0.85, 0.7), Color(0.55, 0.4, 0.3)]
			for row in 3:
				var y := 0.25 + row * 0.42
				StyleKit.box(n, Vector3(w - 0.06, 0.34, 0.02), Vector3(0, y + 0.17, d / 2 - 0.01), StyleKit.mat(StyleKit.OAK.darkened(0.15)), true, 0.0)
				var count := int(w / 0.34)
				for i in count:
					var x := -w / 2 + 0.2 + i * (w - 0.4) / maxf(count - 1, 1)
					var color: Color = colors[(i + row) % colors.size()]
					if (i + row) % 2 == 0:
						for s in [-1, 1]:
							StyleKit.box(n, Vector3(0.07, 0.06, 0.2), Vector3(x + s * 0.045, y + 0.05, 0.02), StyleKit.mat(color, 0.4))
					else:
						StyleKit.box(n, Vector3(0.22, 0.17, 0.09), Vector3(x, y + 0.1, 0.02), StyleKit.mat(color, 0.2))
						StyleKit.box(n, Vector3(0.12, 0.05, 0.015), Vector3(x, y + 0.21, 0.02), StyleKit.mat(color.darkened(0.2)))
		"display_table":
			# Ett lågt bord med högar av vikta plagg eller böcker.
			_table(n, w, d, 0.7, StyleKit.WHITE.darkened(0.05))
			var colors := [Color(0.85, 0.4, 0.45), Color(0.4, 0.55, 0.8), Color(0.95, 0.92, 0.85), Color(0.55, 0.7, 0.5), Color(0.95, 0.75, 0.4)]
			var stacks := maxi(2, int(w / 0.35))
			for i in stacks:
				var x := -w / 2 + (i + 0.5) * w / stacks
				for level in 2 + i % 2:
					var z := -d * 0.18 if i % 2 == 0 else d * 0.15
					StyleKit.box(n, Vector3(0.26, 0.05, 0.22), Vector3(x, 0.75 + level * 0.05, z), StyleKit.mat(colors[(i + level) % colors.size()])).rotation_degrees = Vector3(0, (level - 1) * 4, 0)
		"display_case":
			# Glasdisk med smycken och klockor på mörk sammet, i en ram av mässing.
			StyleKit.box(n, Vector3(w, 0.6, d), Vector3(0, 0.3, 0), StyleKit.mat(StyleKit.WALNUT))
			StyleKit.box(n, Vector3(w - 0.06, 0.02, d - 0.06), Vector3(0, 0.61, 0), StyleKit.mat(Color(0.25, 0.2, 0.3)), true, 0.0)
			var brass := StyleKit.mat(StyleKit.BRASS, 0.8)
			for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				StyleKit.box(n, Vector3(0.025, 0.35, 0.025), Vector3(corner.x * (w / 2 - 0.015), 0.78, corner.y * (d / 2 - 0.015)), brass)
			for z in [-d / 2 + 0.015, d / 2 - 0.015]:
				StyleKit.box(n, Vector3(w, 0.025, 0.025), Vector3(0, 0.95, z), brass)
			for x in [-w / 2 + 0.015, w / 2 - 0.015]:
				StyleKit.box(n, Vector3(0.025, 0.025, d), Vector3(x, 0.95, 0), brass)
			var count := int(w / 0.25)
			for i in count:
				var x := -w / 2 + 0.15 + i * (w - 0.3) / maxf(count - 1, 1)
				if i % 2 == 0:
					var ring := StyleKit.cylinder(n, 0.07, 0.07, 0.008, Vector3(x, 0.625, 0), StyleKit.mat(StyleKit.METAL if i % 4 else StyleKit.BRASS, 0.9), 16)
					ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					StyleKit.sphere(n, 0.018, Vector3(x, 0.63, 0.07), StyleKit.mat(Color(0.75, 0.85, 0.95), 0.9))
				else:
					StyleKit.cylinder(n, 0.035, 0.035, 0.015, Vector3(x, 0.63, 0), StyleKit.mat(StyleKit.BRASS, 0.9), 16)
					StyleKit.box(n, Vector3(0.025, 0.006, 0.16), Vector3(x, 0.622, 0), StyleKit.mat(StyleKit.DARK), true, 0.0)
		"fitting_room":
			# Två provhytter: väggar, en stång och draperier, det ena halvt fördraget.
			var h := 2.0
			var wall := StyleKit.mat(StyleKit.WHITE.darkened(0.03))
			StyleKit.box(n, Vector3(w, h, 0.05), Vector3(0, h / 2, -d / 2 + 0.025), wall)
			for x in [-w / 2 + 0.025, 0.0, w / 2 - 0.025]:
				StyleKit.box(n, Vector3(0.05, h, d), Vector3(x, h / 2, 0), wall)
			StyleKit.box(n, Vector3(w, 0.03, 0.03), Vector3(0, h - 0.08, d / 2 - 0.06), StyleKit.mat(StyleKit.BRASS, 0.7))
			for i in 2:
				var booth_x := -w / 4 + i * w / 2
				var drawn := 0.85 if i == 0 else 0.35
				var cloth := w / 2 * drawn
				StyleKit.box(n, Vector3(cloth, h - 0.2, 0.05), Vector3(booth_x - w / 4 + cloth / 2 + 0.03, (h - 0.2) / 2 + 0.06, d / 2 - 0.06), StyleKit.mat(Color(0.62, 0.32, 0.38), 0.0, 5, 0.12))
				StyleKit.box(n, Vector3(0.35, 1.1, 0.02), Vector3(booth_x, 1.2, -d / 2 + 0.06), StyleKit.mat(Color(0.82, 0.9, 0.96), 0.9), true, 0.0)
				StyleKit.box(n, Vector3(0.35, 0.04, 0.04), Vector3(booth_x, 1.5, -d / 2 + 0.3), StyleKit.mat(StyleKit.WALNUT))
		"espresso_bar":
			# Espressobar: träfront, en blank espressomaskin, en monter med bakverk och muggar.
			StyleKit.box(n, Vector3(w, 0.95, d), Vector3(0, 0.475, 0), StyleKit.mat(StyleKit.WALNUT))
			StyleKit.box(n, Vector3(w + 0.05, 0.05, d + 0.05), Vector3(0, 0.975, 0), StyleKit.mat(StyleKit.STONE, 0.3))
			var machine := Vector3(-w * 0.28, 0, -d * 0.12)
			StyleKit.box(n, Vector3(0.6, 0.42, 0.38), machine + Vector3(0, 1.21, 0), StyleKit.mat(StyleKit.METAL, 0.8))
			StyleKit.box(n, Vector3(0.6, 0.05, 0.38), machine + Vector3(0, 1.44, 0), StyleKit.mat(StyleKit.DARK))
			for s in [-1, 1]:
				StyleKit.cylinder(n, 0.035, 0.03, 0.08, machine + Vector3(s * 0.15, 1.08, 0.2), StyleKit.mat(StyleKit.DARK, 0.5))
			for i in 3:
				_mug(n, machine + Vector3(-0.18 + i * 0.12, 1.47, 0.0), [Color(0.95, 0.95, 0.92), Color(0.85, 0.55, 0.45), Color(0.95, 0.95, 0.92)][i])
			var case_at := Vector3(w * 0.22, 0, 0)
			StyleKit.box(n, Vector3(0.9, 0.3, d - 0.1), case_at + Vector3(0, 1.15, 0), StyleKit.mat(Color(0.86, 0.93, 0.97), 0.9), true, 0.01)
			var pastries := [Color(0.88, 0.62, 0.32), Color(0.95, 0.85, 0.65), Color(0.55, 0.32, 0.2), Color(0.95, 0.6, 0.65)]
			for i in 4:
				StyleKit.sphere(n, 0.06, case_at + Vector3(-0.3 + i * 0.2, 1.36, 0.0), StyleKit.mat(pastries[i], 0.3)).scale = Vector3(1.3, 0.6, 1.0)


## Trappan i ett rum, efter vart den leder (se _prepare_stairs): upp, ned eller båda.
static func _stairs(n: Node3D, w: float, d: float) -> void:
	if _stair_up:
		_stairs_up(n, w, d, _stair_down)
	elif _stair_hatch:
		_ladder_hatch(n, w, d)
	else:
		_stairwell_down(n, w, d)


## Trappans mått (samma på alla våningar, så att trappan i hallarna går rakt upp och ned):
## 14 steg på en våningshöjd (2,6 m ger ca 19 cm per steg), sex steg i varje lopp med
## 30 cm djupa trappsteg och ett vilplan på halva höjden längst in.
const STAIR_RISERS := 14
const STAIR_FLIGHT_STEPS := 6
## Mittväggen mellan U-trappans två lopp (meter).
const STAIR_SPINE := 0.08


## En U-trappa (halvsvängd med vilplan) upp till nästa våning. Första loppet går på den
## öppna sidan från foten (+z) in mot vilplanet längst in (-z), andra loppet vänder och
## stiger tillbaka mot +z längs väggen och kommer upp på övervåningen ovanför foten.
## Varje steg är ett massivt block från golvet, så sidorna blir vita trappstegsformade
## väggar med trästeg och löpare ovanpå. Ledstång med balustrar på första loppets och
## vilplanets öppna sida och längs andra loppets innerkant; en bit av övervåningens golv
## sticker ut ovanför andra loppets topp, så att man ser vart trappan leder. Leder trappan
## också ned sitter källardörren i andra loppets höga ände (där det är takhöjd under).
## Smala trappor (äldre planer) blir en rak trappa.
static func _stairs_up(n: Node3D, w: float, d: float, cellar_door: bool) -> void:
	if w < PlanDrawer.U_STAIR_MIN_WIDTH:
		_straight_stairs_up(n, w, d)
		return
	var height := StyleKit.WALL_HEIGHT
	var rise := height / STAIR_RISERS
	var landing := PlanDrawer.STAIR_LANDING
	var run := (d - landing) / STAIR_FLIGHT_STEPS
	var s := _stair_open_side
	var half := (w - STAIR_SPINE) / 2
	var x1 := s * (STAIR_SPINE / 2 + half / 2)
	var x2 := -x1
	var panel := StyleKit.mat(StyleKit.WHITE.darkened(0.03))
	# Första loppet: steg 1–6 från foten in mot vilplanet.
	for i in STAIR_FLIGHT_STEPS:
		_stair_step(n, x1, half, rise * (i + 1), d / 2 - run * (i + 0.5), run, 1.0, panel)
	# Vilplanet över hela bredden på steg 7.
	var landing_top := rise * (STAIR_FLIGHT_STEPS + 1)
	var landing_z := -d / 2 + landing / 2
	StyleKit.box(n, Vector3(w, landing_top, landing), Vector3(0, landing_top / 2, landing_z), panel, true, 0.0)
	StyleKit.box(n, Vector3(w + 0.04, 0.035, landing + 0.02), Vector3(0, landing_top + 0.017, landing_z + 0.01), StyleKit.mat(StyleKit.OAK.lightened(0.08), 0.2), true, 0.006)
	StyleKit.box(n, Vector3(w * 0.8, 0.012, landing * 0.7), Vector3(0, landing_top + 0.04, landing_z + 0.04), StyleKit.mat(Color(0.72, 0.3, 0.32)), true, 0.0)
	# Andra loppet: steg 8–13 från vilplanet tillbaka mot +z; steg 14 är övervåningen.
	# Blocken tar med mittväggen, så att det inte blir någon smal spalt mellan loppen.
	var toward_wall := signf(x2)
	for i in STAIR_FLIGHT_STEPS:
		_stair_step(n, x2 - toward_wall * STAIR_SPINE / 2, half + STAIR_SPINE, rise * (STAIR_FLIGHT_STEPS + 2 + i), -d / 2 + landing + run * (i + 0.5), run, -1.0, panel)
	var walnut := StyleKit.mat(StyleKit.WALNUT, 0.3)
	# Ledstång längs första loppet (öppna sidan) från en grövre stolpe vid foten.
	var rail_x := s * (w / 2 - 0.03)
	var foot := Vector3(rail_x, rise, d / 2 - run * 0.5)
	var top1 := Vector3(rail_x, rise * STAIR_FLIGHT_STEPS, -d / 2 + landing + run * 0.5)
	_stair_rail(n, foot, top1, STAIR_FLIGHT_STEPS)
	StyleKit.box(n, Vector3(0.11, 1.05, 0.11), foot + Vector3(0, 0.52, 0), walnut, true, 0.004)
	StyleKit.sphere(n, 0.065, foot + Vector3(0, 1.08, 0), StyleKit.mat(StyleKit.WALNUT, 0.4))
	# Räcke längs vilplanets öppna sida, in till väggen.
	_balustrade(n, Vector3(rail_x, landing_top, -d / 2 + landing), Vector3(rail_x, landing_top, -d / 2 + 0.02))
	# Ledstång längs andra loppets innerkant (mot första loppet, som ligger lägre).
	var inner_x := toward_wall * (0.03 - STAIR_SPINE / 2)
	_stair_rail(n, Vector3(inner_x, rise * (STAIR_FLIGHT_STEPS + 2), -d / 2 + landing + run * 0.5),
			Vector3(inner_x, rise * (STAIR_RISERS - 1), d / 2 - run * 0.5), STAIR_FLIGHT_STEPS)
	# Övervåningens golvkant som sticker ut ovanför andra loppets topp.
	var slab := Vector3(half + 0.12, 0.18, 0.45)
	var slab_center := Vector3(x2, height - 0.09, d / 2 + slab.z / 2)
	StyleKit.box(n, slab, slab_center, StyleKit.mat(StyleKit.OAK.darkened(0.05)), true, 0.0)
	StyleKit.box(n, Vector3(slab.x + 0.02, 0.06, 0.02), slab_center + Vector3(0, -0.06, slab.z / 2 + 0.005), StyleKit.mat(StyleKit.WHITE), false, 0.0)
	# Källardörr i andra loppets höga ände, mot rummet (+z).
	if cellar_door:
		var door_w := minf(half - 0.14, 0.78)
		var door_z := d / 2 + 0.012
		StyleKit.box(n, Vector3(door_w + 0.1, 2.0, 0.02), Vector3(x2, 1.0, door_z), StyleKit.mat(StyleKit.WHITE.darkened(0.08)), true, 0.0)
		StyleKit.box(n, Vector3(door_w, 1.92, 0.025), Vector3(x2, 0.96, door_z + 0.004), StyleKit.mat(StyleKit.WALNUT.lightened(0.15)), true, 0.0)
		for y in [0.55, 1.4]:
			StyleKit.box(n, Vector3(door_w * 0.62, 0.55, 0.03), Vector3(x2, y, door_z + 0.008), StyleKit.mat(StyleKit.WALNUT.lightened(0.05)), true, 0.0)
		StyleKit.sphere(n, 0.025, Vector3(x2 + s * (door_w / 2 - 0.08), 0.98, door_z + 0.03), StyleKit.mat(StyleKit.BRASS, 0.8))


## Ett trappsteg som massivt block från golvet: trästeg med nos åt det lägre hållet
## (`down` är +1 när trappan går nedåt mot +z), löpare och en mässingsstång.
static func _stair_step(n: Node3D, x: float, width: float, top: float, z: float, run: float, down: float, panel: Material) -> void:
	StyleKit.box(n, Vector3(width, top, run), Vector3(x, top / 2, z), panel, true, 0.0)
	StyleKit.box(n, Vector3(width + 0.03, 0.035, run + 0.03), Vector3(x, top + 0.017, z + down * 0.015), StyleKit.mat(StyleKit.OAK.lightened(0.08), 0.2), true, 0.006)
	StyleKit.box(n, Vector3(width * 0.62, 0.012, run - 0.01), Vector3(x, top + 0.04, z + down * 0.01), StyleKit.mat(Color(0.72, 0.3, 0.32)), true, 0.0)
	StyleKit.box(n, Vector3(width * 0.66, 0.012, 0.012), Vector3(x, top + 0.045, z + down * (run / 2 - 0.01)), StyleKit.mat(StyleKit.BRASS, 0.8), false, 0.0)


## En sluttande ledstång 0,9 m över stegen från `a` till `b` (stegens överkanter), med en
## vit baluster på varje steg.
static func _stair_rail(n: Node3D, a: Vector3, b: Vector3, steps: int) -> void:
	var height := 0.9
	_slanted(n, a + Vector3(0, height, 0), b + Vector3(0, height, 0), 0.06, StyleKit.mat(StyleKit.WALNUT, 0.3))
	for i in steps:
		var p := a.lerp(b, float(i) / maxf(1, steps - 1))
		StyleKit.box(n, Vector3(0.03, height, 0.03), p + Vector3(0, height / 2, 0), StyleKit.mat(StyleKit.WHITE), true, 0.004)


## En rak trappa (för smala trappor): 12 steg bakåt (-z) upp till nästa våning.
static func _straight_stairs_up(n: Node3D, w: float, d: float) -> void:
	var steps := 12
	var rise := StyleKit.WALL_HEIGHT / steps
	var run := d / steps
	var panel := StyleKit.mat(StyleKit.WHITE.darkened(0.03))
	for i in steps:
		_stair_step(n, 0.0, w, rise * (i + 1), d / 2 - run * (i + 0.5), run, 1.0, panel)
	var x := _stair_open_side * (w / 2 - 0.03)
	_stair_rail(n, Vector3(x, rise, d / 2 - run * 0.5), Vector3(x, rise * steps, -d / 2 + run * 0.5), steps)


## Trapphålet ned till våningen under, ovanför en U-trappa: en mörk öppning där man ser
## andra loppet gå ned från framkanten (+z) mot vilplanet längst in och första loppet
## under det, allt mörkare längre ned. Räcke runt hålet utom där andra loppet kommer upp.
static func _stairwell_down(n: Node3D, w: float, d: float) -> void:
	var s := _stair_open_side
	var u := w >= PlanDrawer.U_STAIR_MIN_WIDTH
	var landing := PlanDrawer.STAIR_LANDING if u else 0.0
	var run := (d - landing) / STAIR_FLIGHT_STEPS
	var half := (w - STAIR_SPINE) / 2 if u else w
	var x2 := -s * (STAIR_SPINE / 2 + half / 2) if u else 0.0
	var dark := Color(0.16, 0.13, 0.13)
	# Hålets kant: en mörk ram och botten.
	StyleKit.box(n, Vector3(w + 0.1, 0.02, d + 0.1), Vector3(0, 0.005, 0), StyleKit.mat(StyleKit.WALNUT.darkened(0.2)), false, 0.0)
	StyleKit.box(n, Vector3(w, 0.022, d), Vector3(0, 0.007, 0), StyleKit.mat(dark), false, 0.0)
	# Andra loppet nedåt från framkanten, allt mörkare mot vilplanet.
	for i in STAIR_FLIGHT_STEPS:
		var t := float(i + 1) / (STAIR_FLIGHT_STEPS + 3)
		var z := d / 2 - run * (i + 0.5)
		StyleKit.box(n, Vector3(half - 0.04, 0.025, run * 0.62), Vector3(x2, 0.015, z + run * 0.1), StyleKit.mat(StyleKit.OAK.lerp(dark, t)), false, 0.0)
		StyleKit.box(n, Vector3((half - 0.04) * 0.6, 0.027, run * 0.6), Vector3(x2, 0.016, z + run * 0.1), StyleKit.mat(Color(0.72, 0.3, 0.32).lerp(dark, t)), false, 0.0)
	if u:
		# Vilplanet längst in och första loppet under, nästan i mörker.
		StyleKit.box(n, Vector3(w - 0.04, 0.024, landing - 0.04), Vector3(0, 0.014, -d / 2 + landing / 2), StyleKit.mat(StyleKit.OAK.lerp(dark, 0.75)), false, 0.0)
		StyleKit.box(n, Vector3(STAIR_SPINE, 0.03, d - landing), Vector3(0, 0.018, landing / 2), StyleKit.mat(StyleKit.WHITE.lerp(dark, 0.4)), false, 0.0)
	# Räcke runt hålet; framkanten ovanför andra loppet är öppen, där kommer man upp.
	var front := d / 2 + 0.02
	var back := -d / 2 - 0.02
	var open_x := s * (w / 2 + 0.02)
	var wall_x := -open_x
	_balustrade(n, Vector3(wall_x, 0, back), Vector3(open_x, 0, back))
	_balustrade(n, Vector3(open_x, 0, back), Vector3(open_x, 0, front))
	if u:
		_balustrade(n, Vector3(open_x, 0, front), Vector3(s * STAIR_SPINE / 2, 0, front))
		_balustrade(n, Vector3(wall_x, 0, back), Vector3(wall_x, 0, front))
	else:
		_balustrade(n, Vector3(wall_x, 0, back), Vector3(wall_x, 0, front))


## Vindsluckan i golvet ovanför vindsstegen: en mörk öppning med stegens toppar som
## sticker upp och ett räcke på ena sidan.
static func _ladder_hatch(n: Node3D, w: float, d: float) -> void:
	var hole := Vector2(minf(w, 0.7), minf(d, 0.9))
	StyleKit.box(n, Vector3(hole.x + 0.12, 0.02, hole.y + 0.12), Vector3(0, 0.005, 0), StyleKit.mat(StyleKit.WALNUT.darkened(0.2)), false, 0.0)
	StyleKit.box(n, Vector3(hole.x, 0.022, hole.y), Vector3(0, 0.007, 0), StyleKit.mat(Color(0.16, 0.13, 0.13)), false, 0.0)
	var wood := StyleKit.mat(StyleKit.OAK.lightened(0.05))
	for s in [-1, 1]:
		_slanted(n, Vector3(s * (hole.x / 2 - 0.06), 0, hole.y / 2 - 0.1), Vector3(s * (hole.x / 2 - 0.06), 0.85, hole.y / 2 - 0.3), 0.05, wood)
	StyleKit.box(n, Vector3(hole.x - 0.12, 0.03, 0.05), Vector3(0, 0.45, hole.y / 2 - 0.2), wood, true, 0.005)
	var side := _stair_open_side
	_balustrade(n, Vector3(-side * (hole.x / 2 + 0.03), 0, hole.y / 2), Vector3(-side * (hole.x / 2 + 0.03), 0, -hole.y / 2))
	# Luckan ligger uppfälld bredvid hålet.
	StyleKit.box(n, Vector3(hole.x + 0.1, 0.04, hole.y), Vector3(0, 0.02, -hole.y - 0.08), StyleKit.mat(StyleKit.WHITE.darkened(0.08)), true, 0.0)


## Ett räcke mellan två punkter på golvet: vita pinnar, en ledstång i valnöt och en
## grövre stolpe i varje ände.
static func _balustrade(n: Node3D, a: Vector3, b: Vector3) -> void:
	var height := 0.9
	var length := a.distance_to(b)
	var count := maxi(2, int(length / 0.13))
	for i in count + 1:
		var p := a.lerp(b, float(i) / count)
		var end := i == 0 or i == count
		var size := 0.07 if end else 0.025
		StyleKit.box(n, Vector3(size, height, size), p + Vector3(0, height / 2, 0), StyleKit.mat(StyleKit.WALNUT if end else StyleKit.WHITE), true, 0.004)
	_slanted(n, a + Vector3(0, height, 0), b + Vector3(0, height, 0), 0.055, StyleKit.mat(StyleKit.WALNUT, 0.3))


## En rak list mellan två punkter (ledstänger).
static func _slanted(n: Node3D, a: Vector3, b: Vector3, thickness: float, material: Material) -> void:
	var length := a.distance_to(b)
	var mesh := StyleKit.box(n, Vector3(thickness, thickness, length), (a + b) / 2, material, true, 0.008)
	mesh.look_at_from_position((a + b) / 2, b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)


## En nedfällbar vindsstege mot väggen (-z) upp till en lucka i taket.
static func _attic_ladder(n: Node3D, w: float, d: float) -> void:
	var height := StyleKit.WALL_HEIGHT
	var foot := Vector3(0, 0, d / 2)
	var top := Vector3(0, height, -d / 2 + 0.05)
	var wood := StyleKit.mat(StyleKit.OAK.lightened(0.05))
	for s in [-1, 1]:
		var offset := Vector3(s * (w / 2 - 0.04), 0, 0)
		_slanted(n, foot + offset, top + offset, 0.05, wood)
	var rungs := 9
	for i in range(1, rungs):
		var p := foot.lerp(top, float(i) / rungs)
		StyleKit.box(n, Vector3(w - 0.08, 0.03, 0.05), p, wood, true, 0.005)
	# Luckan i taket hänger öppen på gångjärn.
	var hatch := StyleKit.box(n, Vector3(w + 0.1, 0.04, 0.55), top + Vector3(0, 0.02, 0.32), StyleKit.mat(StyleKit.WHITE.darkened(0.05)), true, 0.0)
	hatch.rotation_degrees = Vector3(-35, 0, 0)
	StyleKit.box(n, Vector3(w + 0.2, 0.03, 0.62), top + Vector3(0, 0.08, 0.28), StyleKit.mat(Color(0.16, 0.13, 0.13)), false, 0.0)


## En lampa som tänds på kvällen och natten.
static func _lamp_light(n: Node3D, rig: TimeOfDayRig, at: Vector3, light_range: float, strength: float, shade: ShaderMaterial = null) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.light_color = Color(1.0, 0.78, 0.5)
	lamp.omni_range = light_range
	n.add_child(lamp)
	if rig:
		rig.register_lamp(lamp, shade, strength)


# --- Rummens detaljer ---------------------------------------------------------

## Hur mycket småsaker rummen får: 0 = renare (bara möbler), 1 = som köket var från
## början (några saker), 2 = bott-i (familjens saker överallt).
static var DETAIL := 2

## Detaljer som hör till ett visst rum, och en taklampa i alla rum (gardinerna sitter
## på fönstren, se HouseWindow). Med `low_interior` hoppas saker som hänger på
## innerväggarna över (de är låga då).
static func decorate(parent: Node3D, rig: TimeOfDayRig, room_id: String, plan: Rect2, low_interior := true) -> void:
	var o := Vector3(plan.position.x, 0, plan.position.y)
	if room_id == "kitchen":
		_kitchen(parent, rig, o, plan.size, low_interior)
		return
	# En enkel taklampa i mitten som tänds på kvällen.
	var light := OmniLight3D.new()
	light.position = o + Vector3(plan.size.x / 2, 2.2, plan.size.y / 2)
	light.light_color = Color(1.0, 0.8, 0.55)
	light.omni_range = maxf(plan.size.x, plan.size.y) * 0.9
	parent.add_child(light)
	if rig:
		rig.register_lamp(light, null, 0.8)
	if PlanDrawer.floor_of(room_id) == "Köpcentret":
		_mall_lighting(parent, rig, room_id, o, plan.size)
	if PlanDrawer.floor_of(room_id) == "Gymmet":
		GymKit.decorate(parent, rig, room_id, o, plan.size)
	if room_id == "son_room_1":
		# Rgb-belysningen färgar gamingrummet lila på kvällen.
		var glow := OmniLight3D.new()
		var desk := FloorPlanArt.furniture_rect(room_id, "gaming_desk")
		glow.position = o + Vector3(desk.get_center().x, 0.9, desk.end.y + 0.3)
		glow.light_color = Color(0.6, 0.4, 1.0)
		glow.omni_range = 2.2
		parent.add_child(glow)
		if rig:
			rig.register_lamp(glow, null, 1.2)


## Köpcentrets egna ljus: restaurangens bord har levande ljus som tänds på kvällen.
static func _mall_lighting(parent: Node3D, rig: TimeOfDayRig, room_id: String, o: Vector3, _size: Vector2) -> void:
	if room_id == "restaurant":
		for item in FloorPlanArt.FURNITURE[room_id]:
			if item[0] != "table":
				continue
			var at: Vector3 = o + Vector3((item[1] as Rect2).get_center().x, 0.78, (item[1] as Rect2).get_center().y)
			StyleKit.cylinder(parent, 0.035, 0.04, 0.06, at + Vector3(0, 0.03, 0), StyleKit.mat(Color(0.75, 0.85, 0.9), 0.9))
			var flame := StyleKit.own_mat(Color(1.0, 0.85, 0.5))
			flame.set_shader_parameter("emission", Color(1.0, 0.75, 0.4))
			StyleKit.sphere(parent, 0.012, at + Vector3(0, 0.075, 0), flame).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var glow := OmniLight3D.new()
			glow.position = at + Vector3(0, 0.25, 0)
			glow.light_color = Color(1.0, 0.7, 0.4)
			glow.omni_range = 1.3
			parent.add_child(glow)
			if rig:
				rig.register_lamp(glow, flame, 0.9)


## Köket: överskåp, fläkt, kakel bakom bänken, taklampa över bordet, klocka, tavla,
## dörrmatta och småsaker på bänken.
static func _kitchen(parent: Node3D, rig: TimeOfDayRig, o: Vector3, size: Vector2, low_interior := true) -> void:
	var k := Node3D.new()
	k.position = o
	parent.add_child(k)
	StyleKit.box(k, Vector3(3.5, 0.62, 0.01), Vector3(1.75, 1.23, 0.005), StyleKit.mat(Color(0.92, 0.95, 0.94), 0.25, 2, 0.1), true, 0.0)
	# Överskåp med två fyllningsluckor var, krönlist och mässingsknoppar.
	for x in [0.5, 3.0]:
		StyleKit.box(k, Vector3(0.96, 0.7, 0.34), Vector3(x, 1.95, 0.17), StyleKit.mat(StyleKit.WHITE))
		StyleKit.box(k, Vector3(1.02, 0.05, 0.38), Vector3(x, 2.325, 0.19), StyleKit.mat(StyleKit.WHITE.darkened(0.04)))
		for s in [-1, 1]:
			var door_x: float = x + s * 0.24
			StyleKit.box(k, Vector3(0.45, 0.64, 0.015), Vector3(door_x, 1.95, 0.345), StyleKit.mat(StyleKit.WHITE.darkened(0.03)), true, 0.006)
			StyleKit.box(k, Vector3(0.31, 0.46, 0.012), Vector3(door_x, 1.95, 0.355), StyleKit.mat(StyleKit.WHITE.darkened(0.08)), true, 0.004)
			StyleKit.sphere(k, 0.018, Vector3(x + s * 0.04, 1.7, 0.37), StyleKit.mat(StyleKit.BRASS, 0.8))
	# Fläktkåpa: en avsmalnande kåpa med mässingsband och en skorsten upp mot taket.
	var stove := FloorPlanArt.furniture_rect("kitchen", "stove")
	var hood_x := stove.get_center().x
	var hood := StyleKit.cylinder(k, 0.16, 0.42, 0.32, Vector3(hood_x, 1.86, 0.3), StyleKit.mat(StyleKit.WHITE, 0.3), 4)
	hood.rotation_degrees = Vector3(0, 45, 0)
	StyleKit.box(k, Vector3(0.6, 0.05, 0.6), Vector3(hood_x, 1.69, 0.3), StyleKit.mat(StyleKit.BRASS, 0.7))
	StyleKit.box(k, Vector3(0.22, 0.6, 0.22), Vector3(hood_x, 2.3, 0.2), StyleKit.mat(StyleKit.WHITE, 0.3))
	# Fönstret över diskbänken: kryddörter på bänken och en rutig gardinkappa.
	for herb in [[1.25, Color(0.95, 0.9, 0.82)], [2.05, StyleKit.TERRACOTTA]]:
		var hx: float = herb[0]
		StyleKit.cylinder(k, 0.055, 0.045, 0.1, Vector3(hx, 0.98, 0.08), StyleKit.mat(herb[1]))
		for i in 5:
			var angle := TAU * i / 5.0
			StyleKit.sphere(k, 0.04, Vector3(hx + cos(angle) * 0.03, 1.07 + (i % 2) * 0.03, 0.08 + sin(angle) * 0.025), StyleKit.mat(StyleKit.LEAF.lightened(0.12 * (i % 2))))
	StyleKit.box(k, Vector3(1.42, 0.18, 0.05), Vector3(1.6, 2.2, 0.06), StyleKit.mat(StyleKit.WHITE, 0.0, 5, 0.06, StyleKit.ROSE))
	var steam := StyleKit.particles(k, 24, 2.4, Vector3(0.08, 0.02, 0.08), Vector3(hood_x - 0.14, 1.12, 0.42), Color(1.0, 1.0, 1.0, 0.35), 0.09, Vector3(0, 0.35, 0), 0.05)
	steam.emitting = true
	# Taklampa över bordet: liten kupa högt upp så att den inte skymmer fönstret.
	var table := FloorPlanArt.furniture_rect("kitchen", "table")
	var over := Vector3(table.get_center().x, 0, table.get_center().y)
	# Pendellampa: en opalglob under en mässingskupa, i en tunn sladd från taket.
	StyleKit.cylinder(k, 0.004, 0.004, 0.36, over + Vector3(0, 2.42, 0), StyleKit.mat(StyleKit.DARK))
	StyleKit.cylinder(k, 0.03, 0.06, 0.05, over + Vector3(0, 2.23, 0), StyleKit.mat(StyleKit.BRASS, 0.8))
	var shade := StyleKit.own_mat(Color(0.98, 0.95, 0.88))
	shade.set_shader_parameter("emission", Color(1.0, 0.82, 0.55))
	StyleKit.sphere(k, 0.13, over + Vector3(0, 2.1, 0), shade).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lamp_light(k, rig, over + Vector3(0, 1.9, 0), 4.5, 1.0, shade)
	_lamp_light(k, rig, Vector3(1.6, 1.5, 0.5), 2.0, 1.0)
	# Damm som svävar i solljuset.
	if rig:
		rig.register_dust(StyleKit.particles(k, 80, 9.0, Vector3(1.6, 1.0, 1.4), Vector3(1.6, 1.2, 2.0), Color(1.0, 0.95, 0.8, 0.55), 0.018, Vector3(0, 0.02, 0), 0.03))
	if DETAIL >= 1:
		_kitchen_props(k, size, low_interior)
	if DETAIL >= 2:
		_kitchen_lived_in(k, size)


## Kökets småsaker: klocka, vattenkokare, bröd, redskap, handduk, dörrmatta och en kruka.
static func _kitchen_props(k: Node3D, size: Vector2, low_interior: bool) -> void:
	var hood_x := FloorPlanArt.furniture_rect("kitchen", "stove").get_center().x
	# Klocka på västra väggen.
	StyleKit.cylinder(k, 0.18, 0.18, 0.03, Vector3(0.02, 1.95, 0.7), StyleKit.mat(StyleKit.WHITE)).rotation_degrees = Vector3(0, 0, 90)
	StyleKit.cylinder(k, 0.15, 0.15, 0.035, Vector3(0.025, 1.95, 0.7), StyleKit.mat(Color(1.0, 0.98, 0.94))).rotation_degrees = Vector3(0, 0, 90)
	StyleKit.box(k, Vector3(0.012, 0.11, 0.012), Vector3(0.045, 1.98, 0.7), StyleKit.mat(StyleKit.DARK))
	StyleKit.box(k, Vector3(0.012, 0.012, 0.08), Vector3(0.045, 1.95, 0.73), StyleKit.mat(StyleKit.DARK))
	# Vattenkokare, skärbräda med bröd och redskapsburk på bänken.
	StyleKit.cylinder(k, 0.08, 0.1, 0.2, Vector3(0.35, 1.03, 0.3), StyleKit.mat(Color(0.95, 0.55, 0.5), 0.7))
	StyleKit.cylinder(k, 0.05, 0.08, 0.04, Vector3(0.35, 1.15, 0.3), StyleKit.mat(Color(0.95, 0.55, 0.5), 0.7))
	StyleKit.box(k, Vector3(0.1, 0.03, 0.03), Vector3(0.45, 1.06, 0.3), StyleKit.mat(Color(0.95, 0.55, 0.5), 0.7)).rotation_degrees = Vector3(0, 0, 30)
	StyleKit.box(k, Vector3(0.03, 0.14, 0.03), Vector3(0.25, 1.06, 0.3), StyleKit.mat(StyleKit.DARK))
	StyleKit.box(k, Vector3(0.4, 0.025, 0.26), Vector3(2.15, 0.94, 0.34), StyleKit.mat(StyleKit.OAK.lightened(0.1)))
	StyleKit.sphere(k, 0.1, Vector3(2.15, 1.0, 0.34), StyleKit.mat(Color(0.88, 0.6, 0.32), 0.3)).scale = Vector3(1.4, 0.6, 0.8)
	StyleKit.cylinder(k, 0.06, 0.06, 0.16, Vector3(3.3, 1.01, 0.22), StyleKit.mat(StyleKit.SAGE, 0.4))
	for i in 3:
		StyleKit.cylinder(k, 0.008, 0.008, 0.3, Vector3(3.28 + i * 0.02, 1.15, 0.22), StyleKit.mat([StyleKit.OAK, StyleKit.METAL, StyleKit.DARK][i])).rotation_degrees = Vector3(0, 0, -10 + i * 10)
	# Kökshandduk på ugnsluckan.
	var oven_x := hood_x + 0.1
	StyleKit.box(k, Vector3(0.2, 0.32, 0.015), Vector3(oven_x, 0.56, 0.63), StyleKit.mat(Color(0.95, 0.95, 0.92)))
	for y in [0.5, 0.6]:
		StyleKit.box(k, Vector3(0.2, 0.04, 0.017), Vector3(oven_x, y, 0.63), StyleKit.mat(Color(0.85, 0.35, 0.35)))
	# Tavla på östra väggen och dörrmatta vid dörren till hallen.
	var east := size.x
	if not low_interior:
		StyleKit.box(k, Vector3(0.03, 0.5, 0.4), Vector3(east - 0.02, 1.6, 0.75), StyleKit.mat(StyleKit.WALNUT))
		StyleKit.box(k, Vector3(0.01, 0.42, 0.32), Vector3(east - 0.04, 1.6, 0.75), StyleKit.mat(Color(0.98, 0.94, 0.86)), true, 0.0)
		StyleKit.sphere(k, 0.06, Vector3(east - 0.045, 1.68, 0.7), StyleKit.mat(Color(0.95, 0.6, 0.35))).scale = Vector3(0.1, 1, 1)
		StyleKit.box(k, Vector3(0.01, 0.12, 0.26), Vector3(east - 0.046, 1.5, 0.75), StyleKit.mat(Color(0.55, 0.72, 0.6)), true, 0.0)
	StyleKit.box(k, Vector3(0.5, 0.015, 0.8), Vector3(east - 0.35, 0.008, size.y / 2), StyleKit.mat(Color(0.62, 0.5, 0.4), 0.0, 1, 0.08))
	# En liten kruka på västra fönsterbrädan.
	StyleKit.cylinder(k, 0.06, 0.045, 0.1, Vector3(0.1, 0.96, 2.5), StyleKit.mat(Color(0.95, 0.9, 0.82)))
	for i in 5:
		var angle := TAU * i / 5.0
		StyleKit.sphere(k, 0.045, Vector3(0.1 + cos(angle) * 0.03, 1.06 + (i % 2) * 0.03, 2.5 + sin(angle) * 0.04), StyleKit.mat(StyleKit.LEAF.lightened(0.1)))


## Familjens saker, så att köket ser bott-i ut: kaffebryggare och muggar, disk i hon,
## mammans rättningshög med röd penna, en matkasse på en stol, sönernas ryggsäckar och
## skor vid dörren, hundens skålar och leksaker och sönernas flingpaket på kylen.
## Bara saker som berättar något om familjen eller hör till spelet, inte utfyllnad.
static func _kitchen_lived_in(k: Node3D, size: Vector2) -> void:
	# Sakerna på och kring bordet och bädden följer möblerna (räknat från där de stod
	# i det ursprungliga köket), och skorna står vid dörren mitt på östra väggen.
	var table := FloorPlanArt.furniture_rect("kitchen", "table")
	var at_table := Vector3(table.position.x - 1.3, 0, table.position.y - 1.9)
	var bed := FloorPlanArt.furniture_rect("kitchen", "dog_bed")
	var at_bed := Vector3(bed.position.x - 0.3, 0, bed.position.y - 3.3)
	var door := Vector3(size.x, 0, size.y / 2)
	var mug_colors := [Color(0.95, 0.85, 0.4), Color(0.45, 0.65, 0.9), Color(0.95, 0.55, 0.55)]
	# Kaffebryggare med kanna och muggar.
	StyleKit.box(k, Vector3(0.2, 0.32, 0.2), Vector3(0.78, 1.09, 0.2), StyleKit.mat(StyleKit.DARK, 0.4))
	StyleKit.box(k, Vector3(0.2, 0.05, 0.26), Vector3(0.78, 1.22, 0.23), StyleKit.mat(StyleKit.DARK, 0.4))
	StyleKit.cylinder(k, 0.06, 0.07, 0.12, Vector3(0.78, 0.99, 0.32), StyleKit.mat(Color(0.35, 0.22, 0.15), 0.8))
	for i in 2:
		_mug(k, Vector3(0.98 + i * 0.1, 0.93, 0.42), mug_colors[i])
	# Disk i hon: tallrikar på sned och ett glas.
	for i in 3:
		var plate := StyleKit.cylinder(k, 0.11, 0.11, 0.012, Vector3(1.42 + i * 0.05, 0.99, 0.28), StyleKit.mat(StyleKit.WHITE, 0.5))
		plate.rotation_degrees = Vector3(70, 0, 0)
	StyleKit.cylinder(k, 0.035, 0.03, 0.12, Vector3(1.72, 0.99, 0.36), StyleKit.mat(Color(0.75, 0.88, 0.95), 0.8))
	# Rättningshög med röd penna och en kaffemugg på bordet.
	for i in 4:
		var paper := StyleKit.box(k, Vector3(0.24, 0.012, 0.31), at_table + Vector3(1.55 + i * 0.006, 0.786 + i * 0.012, 2.12), StyleKit.mat(StyleKit.WHITE), true, 0.0)
		paper.rotation_degrees = Vector3(0, -6 + i * 5, 0)
	StyleKit.box(k, Vector3(0.14, 0.012, 0.012), at_table + Vector3(1.6, 0.84, 2.3), StyleKit.mat(Color(0.9, 0.2, 0.2), 0.5)).rotation_degrees = Vector3(0, 30, 0)
	_mug(k, at_table + Vector3(1.85, 0.775, 2.15), mug_colors[2])
	# Matkasse på en stol, med en baguette och blad som sticker upp.
	StyleKit.box(k, Vector3(0.26, 0.3, 0.17), at_table + Vector3(1.75, 0.66, 1.72), StyleKit.mat(Color(0.82, 0.68, 0.48)))
	StyleKit.cylinder(k, 0.03, 0.03, 0.3, at_table + Vector3(1.68, 0.85, 1.7), StyleKit.mat(Color(0.88, 0.62, 0.32), 0.3)).rotation_degrees = Vector3(0, 0, 15)
	StyleKit.sphere(k, 0.06, at_table + Vector3(1.8, 0.84, 1.74), StyleKit.mat(StyleKit.LEAF.lightened(0.15)))
	# Ryggsäckar: en mot stolen i söder och en vid kylen.
	_backpack(k, at_table + Vector3(1.15, 0, 3.38), Color(0.3, 0.45, 0.75), 20)
	_backpack(k, Vector3(4.15, 0, 1.0), Color(0.85, 0.45, 0.3), -70)
	# Skor vid dörrmattan.
	for pair in [[door + Vector3(-0.45, 0, 0.62), Color(0.95, 0.95, 0.95)], [door + Vector3(-0.2, 0, 0.66), Color(0.25, 0.25, 0.3)]]:
		for s in [-1, 1]:
			var at: Vector3 = pair[0] + Vector3(s * 0.05, 0.035, 0)
			StyleKit.box(k, Vector3(0.08, 0.07, 0.24), at, StyleKit.mat(pair[1], 0.3)).rotation_degrees = Vector3(0, s * 8, 0)
	# Hundens skålar vid västra väggen och leksaker vid bädden.
	StyleKit.cylinder(k, 0.1, 0.08, 0.06, at_bed + Vector3(0.22, 0.03, 2.95), StyleKit.mat(Color(0.95, 0.4, 0.45), 0.6))
	StyleKit.cylinder(k, 0.07, 0.07, 0.005, at_bed + Vector3(0.22, 0.062, 2.95), StyleKit.mat(Color(0.55, 0.35, 0.2)))
	StyleKit.cylinder(k, 0.1, 0.08, 0.06, at_bed + Vector3(0.22, 0.03, 3.2), StyleKit.mat(Color(0.4, 0.65, 0.95), 0.6))
	StyleKit.cylinder(k, 0.075, 0.075, 0.005, at_bed + Vector3(0.22, 0.062, 3.2), StyleKit.mat(Color(0.7, 0.88, 1.0), 0.8))
	StyleKit.sphere(k, 0.05, at_bed + Vector3(1.18, 0.05, 3.72), StyleKit.mat(Color(0.75, 0.9, 0.3), 0.4))
	StyleKit.box(k, Vector3(0.2, 0.04, 0.05), at_bed + Vector3(0.95, 0.025, 3.15), StyleKit.mat(Color(0.95, 0.5, 0.6))).rotation_degrees = Vector3(0, 35, 0)
	# Flingpaket ovanpå kylen.
	for box_spec in [[Vector3(3.75, 2.08, 0.25), Color(0.95, 0.75, 0.25), 0.26], [Vector3(3.92, 2.05, 0.28), Color(0.4, 0.7, 0.45), 0.2], [Vector3(4.12, 2.06, 0.25), Color(0.9, 0.4, 0.4), 0.22]]:
		StyleKit.box(k, Vector3(0.14, box_spec[2], 0.07), box_spec[0], StyleKit.mat(box_spec[1]))


static func _mug(k: Node3D, at: Vector3, color: Color) -> void:
	StyleKit.cylinder(k, 0.04, 0.036, 0.09, at + Vector3(0, 0.045, 0), StyleKit.mat(color, 0.5))
	StyleKit.cylinder(k, 0.032, 0.032, 0.005, at + Vector3(0, 0.088, 0), StyleKit.mat(Color(0.35, 0.22, 0.15)))
	StyleKit.box(k, Vector3(0.015, 0.05, 0.03), at + Vector3(0.045, 0.045, 0), StyleKit.mat(color, 0.5))


## En ryggsäck som står på golvet: kropp, framficka och axelremmar.
static func _backpack(k: Node3D, at: Vector3, color: Color, turn: float) -> void:
	var bag := Node3D.new()
	bag.position = at
	bag.rotation_degrees = Vector3(-8, turn, 0)
	k.add_child(bag)
	StyleKit.box(bag, Vector3(0.3, 0.4, 0.16), Vector3(0, 0.2, 0), StyleKit.mat(color))
	StyleKit.box(bag, Vector3(0.24, 0.16, 0.05), Vector3(0, 0.13, 0.09), StyleKit.mat(color.darkened(0.12)))
	StyleKit.box(bag, Vector3(0.12, 0.02, 0.06), Vector3(0, 0.22, 0.1), StyleKit.mat(StyleKit.DARK))
	for s in [-1, 1]:
		StyleKit.box(bag, Vector3(0.04, 0.32, 0.03), Vector3(s * 0.08, 0.22, -0.09), StyleKit.mat(StyleKit.DARK))


## Familjens hund som sover hoprullad i sin bädd: kropp, huvud på tassarna, hängande
## öron, nos och en svans runt kroppen. Den andas lugnt (riggen). `at` är bäddens mitt.
## Hunden placeras av den som vet var den är enligt schemat, inte av rummet.
static func sleeping_dog(parent: Node3D, rig: TimeOfDayRig, at: Vector3, fur := Color(0.62, 0.42, 0.28)) -> Node3D:
	var dog := Node3D.new()
	dog.position = at + Vector3(0, 0.12, 0)
	dog.rotation_degrees = Vector3(0, 25, 0)
	parent.add_child(dog)
	var body := Node3D.new()
	dog.add_child(body)
	if rig:
		rig.register_breathe(body)
	var light_fur := fur.lightened(0.25)
	var dark_fur := fur.darkened(0.25)
	StyleKit.sphere(body, 0.17, Vector3(0, 0.1, 0), StyleKit.mat(fur)).scale = Vector3(1.35, 0.62, 1.0)
	StyleKit.sphere(body, 0.1, Vector3(0.05, 0.08, 0.1), StyleKit.mat(light_fur)).scale = Vector3(1.5, 0.6, 0.8)
	# Huvudet vilar på framtassarna.
	StyleKit.sphere(dog, 0.035, Vector3(0.17, 0.04, 0.13), StyleKit.mat(light_fur)).scale = Vector3(1.8, 0.8, 1.0)
	StyleKit.sphere(dog, 0.035, Vector3(0.15, 0.04, 0.2), StyleKit.mat(light_fur)).scale = Vector3(1.8, 0.8, 1.0)
	StyleKit.sphere(dog, 0.09, Vector3(0.2, 0.12, 0.12), StyleKit.mat(fur))
	StyleKit.sphere(dog, 0.05, Vector3(0.28, 0.1, 0.15), StyleKit.mat(light_fur)).scale = Vector3(1.3, 0.85, 1.0)
	StyleKit.sphere(dog, 0.018, Vector3(0.33, 0.11, 0.17), StyleKit.mat(StyleKit.DARK, 0.6))
	for side in [-1, 1]:
		var ear := StyleKit.sphere(dog, 0.045, Vector3(0.17, 0.12, 0.12 + side * 0.075), StyleKit.mat(dark_fur))
		ear.scale = Vector3(1.4, 0.45, 0.9)
		ear.rotation_degrees = Vector3(side * 25, 0, -20)
	# Slutna ögon som små mörka streck.
	StyleKit.box(dog, Vector3(0.025, 0.006, 0.01), Vector3(0.25, 0.15, 0.065), StyleKit.mat(StyleKit.DARK), false, 0.0)
	StyleKit.box(dog, Vector3(0.025, 0.006, 0.01), Vector3(0.26, 0.15, 0.175), StyleKit.mat(StyleKit.DARK), false, 0.0)
	# Svansen ligger runt kroppen.
	for i in 5:
		var angle := PI * 0.6 + i * 0.32
		StyleKit.sphere(dog, 0.035 - i * 0.003, Vector3(cos(angle) * 0.22, 0.05, sin(angle) * 0.17), StyleKit.mat(fur if i < 4 else light_fur))
	return dog


## Samma hund vaken och lekfull: står på fyra ben med huvudet högt, tungan ute och en
## svans som viftar. Huvudet pekar mot +x; noden vänds lite mot kameran. `at` är på marken.
static func playful_dog(parent: Node3D, at: Vector3, fur := Color(0.62, 0.42, 0.28)) -> Node3D:
	var dog := Node3D.new()
	dog.position = at
	dog.rotation_degrees = Vector3(0, -25, 0)
	parent.add_child(dog)
	var light_fur := fur.lightened(0.25)
	var dark_fur := fur.darkened(0.25)
	for x in [-0.13, 0.13]:
		for z in [-0.07, 0.07]:
			StyleKit.cylinder(dog, 0.032, 0.028, 0.22, Vector3(x, 0.11, z), StyleKit.mat(fur if x < 0 else light_fur), 8)
	StyleKit.sphere(dog, 0.15, Vector3(0, 0.29, 0), StyleKit.mat(fur)).scale = Vector3(1.55, 0.8, 0.85)
	StyleKit.sphere(dog, 0.08, Vector3(0.08, 0.25, 0), StyleKit.mat(light_fur)).scale = Vector3(1.6, 0.8, 1.0)
	var head := Node3D.new()
	head.position = Vector3(0.25, 0.42, 0)
	dog.add_child(head)
	StyleKit.sphere(head, 0.1, Vector3.ZERO, StyleKit.mat(fur))
	StyleKit.sphere(head, 0.055, Vector3(0.09, -0.025, 0), StyleKit.mat(light_fur)).scale = Vector3(1.3, 0.85, 1.0)
	StyleKit.sphere(head, 0.02, Vector3(0.15, -0.01, 0), StyleKit.mat(StyleKit.DARK, 0.6))
	StyleKit.box(head, Vector3(0.04, 0.008, 0.03), Vector3(0.11, -0.075, 0), StyleKit.mat(Color(0.92, 0.45, 0.5)), false, 0.0).rotation_degrees.z = -30
	for side in [-1, 1]:
		StyleKit.sphere(head, 0.016, Vector3(0.07, 0.03, side * 0.055), StyleKit.mat(StyleKit.DARK, 0.6))
		var ear := StyleKit.sphere(head, 0.045, Vector3(-0.02, 0.0, side * 0.09), StyleKit.mat(dark_fur))
		ear.scale = Vector3(0.9, 1.4, 0.45)
	# Svansen viftar så länge han leker.
	var tail := Node3D.new()
	tail.position = Vector3(-0.22, 0.34, 0)
	dog.add_child(tail)
	for i in 4:
		StyleKit.sphere(tail, 0.03 - i * 0.004, Vector3(-0.03 - i * 0.035, 0.03 + i * 0.03, 0), StyleKit.mat(fur if i < 3 else light_fur))
	var wag := tail.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	wag.tween_property(tail, "rotation:y", 0.6, 0.14)
	wag.tween_property(tail, "rotation:y", -0.6, 0.14)
	return dog


## Saker på väggen, sedda framifrån: affischer (spel eller lag), en vimpel och en
## fotovägg. Noden står en bit från väggen med framsidan ut i rummet.
static func _wall_decor(n: Node3D, kind: String, w: float) -> void:
	var back := -0.05
	match kind:
		"poster":
			var h := w * 1.35 if w < 0.75 else 0.8
			var palettes := [[Color(0.18, 0.2, 0.42), Color(0.95, 0.55, 0.3), Color(0.5, 0.85, 0.95)],
					[Color(0.85, 0.3, 0.3), Color(0.95, 0.85, 0.4), Color(0.15, 0.15, 0.2)]]
			var pal: Array = palettes[int(absf(n.position.x * 7.0 + n.position.z * 3.0)) % palettes.size()]
			StyleKit.box(n, Vector3(w, h, 0.012), Vector3(0, 1.55, back), StyleKit.mat(pal[0]), false, 0.0)
			StyleKit.sphere(n, w * 0.22, Vector3(0, 1.6, back + 0.008), StyleKit.mat(pal[1])).scale = Vector3(1, 1, 0.05)
			StyleKit.box(n, Vector3(w * 0.7, 0.06, 0.004), Vector3(0, 1.55 + h * 0.36, back + 0.009), StyleKit.mat(pal[2]), false, 0.0)
			StyleKit.box(n, Vector3(w * 0.5, 0.03, 0.004), Vector3(0, 1.55 - h * 0.38, back + 0.009), StyleKit.mat(pal[2]), false, 0.0)
		"pennant":
			var flag := StyleKit.cylinder(n, w * 0.3, w * 0.3, 0.01, Vector3(0, 1.6, back), StyleKit.mat(Color(0.15, 0.3, 0.6)), 3)
			flag.rotation_degrees = Vector3(90, 0, 90)
			flag.scale = Vector3(1, 1, 0.35)
			StyleKit.box(n, Vector3(0.03, 0.22, 0.02), Vector3(-w * 0.32, 1.6, back), StyleKit.mat(Color(0.95, 0.75, 0.25)), false, 0.0)
		"photo_wall":
			var frames := [[-0.25, 1.6, 0.22, 0.28], [0.05, 1.68, 0.26, 0.2], [0.3, 1.5, 0.18, 0.24], [0.02, 1.38, 0.2, 0.16]]
			for f in frames:
				StyleKit.box(n, Vector3(f[2], f[3], 0.02), Vector3(f[0] * w / 0.8, f[1], back), StyleKit.mat(StyleKit.WALNUT), false, 0.0)
				StyleKit.box(n, Vector3(f[2] - 0.04, f[3] - 0.04, 0.005), Vector3(f[0] * w / 0.8, f[1], back + 0.012), StyleKit.mat(Color(0.9, 0.82, 0.7)), false, 0.0)