class_name Furniture3D
## Egna 3D-möbler byggda av enkla former, i planritningens färger. Varje möbel byggs
## i ett lokalt läge där baksidan vetter mot -Z (norr) och mitten ligger i origo;
## House3D vrider och flyttar den till rätt plats. Mått i meter.

const WOOD := Color(0.66, 0.46, 0.3)
const OAK := Color(0.86, 0.7, 0.52)
const TEAL := Color(0.4, 0.64, 0.62)
const STONE := Color(0.92, 0.9, 0.86)
const WHITE := Color(0.97, 0.96, 0.93)
const SAGE := Color(0.58, 0.67, 0.55)
const DARK := Color(0.3, 0.29, 0.29)
const RUG := Color(0.85, 0.72, 0.62)
const LEAF := Color(0.45, 0.62, 0.4)
const TERRACOTTA := Color(0.76, 0.5, 0.36)
const CARDBOARD := Color(0.78, 0.62, 0.42)
const METAL := Color(0.75, 0.76, 0.78)

## Höjden på köksbänken; sådant som står på bänken (diskho, spis) placeras ovanpå.
const COUNTER_HEIGHT := 0.9
## Möbler som ligger ovanpå en bänk i planen.
const ON_COUNTER := ["sink", "stove"]

static var _materials := {}


## Bygger möbeln `kind` med fotavtrycket w × d (bredd längs X, djup längs Z).
## Returnerar null för typer som inte har någon 3D-form.
static func build(kind: String, w: float, d: float) -> Node3D:
	var root := Node3D.new()
	root.name = kind
	match kind:
		"counter":
			_box(root, Vector3(w, 0.08, d), Vector3(0, 0.04, 0), TEAL.darkened(0.3))
			_box(root, Vector3(w, COUNTER_HEIGHT - 0.12, d - 0.03), Vector3(0, 0.08 + (COUNTER_HEIGHT - 0.12) / 2, 0.015), TEAL)
			_box(root, Vector3(w + 0.02, 0.04, d + 0.03), Vector3(0, COUNTER_HEIGHT - 0.02, 0), STONE)
			# Skåpluckor: tunna linjer mellan luckorna.
			var doors := maxi(1, roundi(w / 0.6))
			for i in range(1, doors):
				_box(root, Vector3(0.01, COUNTER_HEIGHT - 0.2, 0.01), Vector3(-w / 2 + w * i / doors, 0.48, d / 2 + 0.005), TEAL.darkened(0.25))
			# Överskåp längs väggen.
			_box(root, Vector3(w, 0.65, 0.35), Vector3(0, 1.85, -d / 2 + 0.175), TEAL.lightened(0.08))
		"sink":
			_box(root, Vector3(w, 0.03, d), Vector3(0, COUNTER_HEIGHT + 0.005, 0), Color(0.82, 0.84, 0.85))
			_box(root, Vector3(w * 0.75, 0.02, d * 0.65), Vector3(0, COUNTER_HEIGHT + 0.015, 0.02), Color(0.65, 0.7, 0.74))
			_cylinder(root, 0.025, 0.25, Vector3(0, COUNTER_HEIGHT + 0.12, -d / 2 + 0.05), METAL)
			_box(root, Vector3(0.04, 0.03, 0.16), Vector3(0, COUNTER_HEIGHT + 0.24, -d / 2 + 0.12), METAL)
		"stove":
			_box(root, Vector3(w, 0.03, d), Vector3(0, COUNTER_HEIGHT + 0.005, 0), DARK)
			for i in 4:
				var p := Vector3((i % 2 - 0.5) * w * 0.45, COUNTER_HEIGHT + 0.03, (i / 2 - 0.5) * d * 0.45)
				_cylinder(root, minf(w, d) * 0.13, 0.015, p, Color(0.5, 0.5, 0.52))
		"fridge":
			_box(root, Vector3(w, 1.95, d), Vector3(0, 0.975, 0), TEAL)
			_box(root, Vector3(w * 0.96, 0.015, 0.02), Vector3(0, 1.25, d / 2), TEAL.darkened(0.3))
			_box(root, Vector3(0.03, 0.5, 0.04), Vector3(w * 0.38, 1.5, d / 2 + 0.02), METAL)
			_box(root, Vector3(0.03, 0.4, 0.04), Vector3(w * 0.38, 0.85, d / 2 + 0.02), METAL)
		"table", "coffee_table", "desk":
			var height := 0.42 if kind == "coffee_table" else 0.75
			var top := WOOD if kind == "table" else WOOD.lightened(0.12)
			_box(root, Vector3(w, 0.05, d), Vector3(0, height - 0.025, 0), top)
			for sx in [-1, 1]:
				for sz in [-1, 1]:
					_box(root, Vector3(0.06, height - 0.05, 0.06), Vector3(sx * (w / 2 - 0.06), (height - 0.05) / 2, sz * (d / 2 - 0.06)), top.darkened(0.15))
			if kind == "desk":
				_box(root, Vector3(0.32, 0.02, 0.22), Vector3(0, height + 0.01, 0.02), Color(0.62, 0.64, 0.68))
				_cylinder(root, 0.06, 0.03, Vector3(w * 0.38, height + 0.015, -d * 0.2), DARK)
				_cylinder(root, 0.012, 0.35, Vector3(w * 0.38, height + 0.2, -d * 0.2), DARK)
				_sphere(root, 0.08, Vector3(w * 0.38, height + 0.4, -d * 0.15), Color(0.98, 0.9, 0.62))
			if kind == "table":
				_cylinder(root, 0.14, 0.06, Vector3(0, height + 0.03, 0), Color(0.93, 0.9, 0.84))
				for i in 3:
					_sphere(root, 0.05, Vector3(-0.05 + i * 0.05, height + 0.09, (i % 2) * 0.04), [Color(0.9, 0.35, 0.3), Color(0.95, 0.75, 0.3), Color(0.55, 0.75, 0.35)][i])
		"chair":
			_box(root, Vector3(w, 0.05, d), Vector3(0, 0.45, 0), WOOD.darkened(0.05))
			for sx in [-1, 1]:
				for sz in [-1, 1]:
					_box(root, Vector3(0.04, 0.43, 0.04), Vector3(sx * (w / 2 - 0.04), 0.215, sz * (d / 2 - 0.04)), WOOD.darkened(0.2))
			_box(root, Vector3(w, 0.45, 0.05), Vector3(0, 0.7, -d / 2 + 0.025), WOOD.darkened(0.05))
		"sofa", "armchair":
			var arm := minf(0.16, w * 0.12)
			_box(root, Vector3(w, 0.4, d), Vector3(0, 0.2, 0), SAGE.darkened(0.08))
			_box(root, Vector3(w, 0.5, 0.22), Vector3(0, 0.55, -d / 2 + 0.11), SAGE.darkened(0.12))
			for side in [-1, 1]:
				_box(root, Vector3(arm, 0.6, d), Vector3(side * (w / 2 - arm / 2), 0.3, 0), SAGE.darkened(0.1))
			var cushions := 3 if kind == "sofa" and w > 1.8 else 1
			var seat_w := (w - arm * 2) / cushions
			for i in cushions:
				_box(root, Vector3(seat_w - 0.03, 0.12, d - 0.26), Vector3(-w / 2 + arm + seat_w * (i + 0.5), 0.46, 0.1), SAGE.lightened(0.08))
			if kind == "sofa":
				_box(root, Vector3(0.32, 0.3, 0.12), Vector3(-w / 2 + arm + 0.25, 0.65, -d / 2 + 0.3), Color(0.93, 0.8, 0.62))
				_box(root, Vector3(0.32, 0.3, 0.12), Vector3(w / 2 - arm - 0.25, 0.65, -d / 2 + 0.3), Color(0.85, 0.6, 0.55))
		"tv":
			_box(root, Vector3(w, 0.45, d), Vector3(0, 0.225, 0), DARK.lightened(0.15))
			_box(root, Vector3(w * 0.75, 0.6, 0.05), Vector3(0, 0.78, -d / 2 + 0.06), DARK)
		"rug", "gym_mat":
			var color := RUG if kind == "rug" else Color(0.5, 0.62, 0.68)
			_box(root, Vector3(w, 0.015, d), Vector3(0, 0.0075, 0), color.darkened(0.08))
			_box(root, Vector3(w - 0.16, 0.017, d - 0.16), Vector3(0, 0.0085, 0), color)
		"shelf", "wardrobe", "nightstand", "shoe_rack":
			var height: float = {"shelf": 1.8, "wardrobe": 2.0, "nightstand": 0.5, "shoe_rack": 0.45}[kind]
			_box(root, Vector3(w, height, d), Vector3(0, height / 2, 0), WOOD.lightened(0.05))
			if kind == "shelf":
				# Hyllplan och färgglada böcker på framsidan.
				for row in 4:
					var y := 0.2 + row * 0.42
					_box(root, Vector3(w * 0.9, 0.28, 0.02), Vector3(0, y + 0.14, d / 2), [Color(0.75, 0.35, 0.3), Color(0.35, 0.55, 0.65), Color(0.85, 0.7, 0.35), Color(0.5, 0.65, 0.45)][row])
			elif kind == "wardrobe":
				_box(root, Vector3(0.01, height - 0.1, 0.01), Vector3(0, height / 2, d / 2 + 0.005), WOOD.darkened(0.2))
		"bed":
			_box(root, Vector3(w, 0.28, d), Vector3(0, 0.14, 0), WOOD)
			_box(root, Vector3(w + 0.04, 0.85, 0.08), Vector3(0, 0.425, -d / 2 + 0.04), WOOD.darkened(0.1))
			_box(root, Vector3(w - 0.06, 0.18, d - 0.12), Vector3(0, 0.37, 0.03), WHITE)
			var pillows := 2 if w > 1.3 else 1
			for i in pillows:
				_box(root, Vector3(w / pillows - 0.16, 0.12, 0.35), Vector3(-w / 2 + w / pillows * (i + 0.5), 0.52, -d / 2 + 0.3), Color(0.98, 0.97, 0.95))
			_box(root, Vector3(w - 0.02, 0.2, d * 0.62), Vector3(0, 0.39, d / 2 - d * 0.31), TEAL.lightened(0.25))
			_box(root, Vector3(w - 0.02, 0.21, 0.18), Vector3(0, 0.395, d / 2 - d * 0.62 + 0.09), TEAL.lightened(0.42))
		"toilet":
			_box(root, Vector3(w * 0.8, 0.4, d * 0.28), Vector3(0, 0.6, -d / 2 + d * 0.14), WHITE)
			_cylinder(root, minf(w, d) * 0.38, 0.42, Vector3(0, 0.21, d * 0.08), WHITE)
			_cylinder(root, minf(w, d) * 0.3, 0.02, Vector3(0, 0.43, d * 0.08), Color(0.86, 0.9, 0.92))
		"basin":
			_box(root, Vector3(w, 0.8, d), Vector3(0, 0.4, 0), WHITE.darkened(0.05))
			_box(root, Vector3(w * 0.7, 0.02, d * 0.6), Vector3(0, 0.81, 0.03), Color(0.85, 0.88, 0.9))
			_cylinder(root, 0.02, 0.2, Vector3(0, 0.9, -d / 2 + 0.06), METAL)
		"bathtub":
			_box(root, Vector3(w, 0.55, d), Vector3(0, 0.275, 0), WHITE)
			_box(root, Vector3(w - 0.12, 0.02, d - 0.12), Vector3(0, 0.55, 0), Color(0.75, 0.86, 0.9))
		"washer":
			_box(root, Vector3(w, 0.85, d), Vector3(0, 0.425, 0), WHITE)
			var door := _cylinder(root, minf(w, 0.85) * 0.3, 0.03, Vector3(0, 0.45, d / 2 + 0.01), Color(0.7, 0.78, 0.82))
			door.rotation.x = PI / 2
		"plant":
			var radius := minf(w, d) / 2
			_cylinder(root, radius * 0.55, 0.3, Vector3(0, 0.15, 0), TERRACOTTA)
			for i in 6:
				var angle := TAU * i / 6.0
				_sphere(root, radius * 0.5, Vector3(cos(angle) * radius * 0.4, 0.45 + (i % 2) * 0.1, sin(angle) * radius * 0.4), LEAF.darkened(0.08 * (i % 2)))
			_sphere(root, radius * 0.5, Vector3(0, 0.62, 0), LEAF.lightened(0.12))
		"dog_bed":
			_cylinder(root, minf(w, d) / 2, 0.16, Vector3(0, 0.08, 0), Color(0.72, 0.55, 0.45))
			_cylinder(root, minf(w, d) / 2 * 0.7, 0.17, Vector3(0, 0.09, 0), Color(0.88, 0.78, 0.68))
		"basket":
			_cylinder(root, minf(w, d) / 2, 0.35, Vector3(0, 0.175, 0), Color(0.8, 0.68, 0.5))
		"boxes", "trunk":
			var color := CARDBOARD if kind == "boxes" else WOOD
			_box(root, Vector3(w, 0.5, d), Vector3(0, 0.25, 0), color)
			_box(root, Vector3(w * 0.6, 0.35, d * 0.6), Vector3(w * 0.1, 0.675, -d * 0.1), color.lightened(0.08))
		"rack":
			for side in [-1, 1]:
				_box(root, Vector3(0.03, 0.9, d), Vector3(side * w / 2, 0.45, 0), METAL)
			for i in 5:
				_box(root, Vector3(w, 0.015, 0.015), Vector3(0, 0.9, -d / 2 + d * (i + 0.5) / 5), METAL)
		"stairs":
			# Steg som stiger mot norr (-Z).
			var steps := 10
			for i in steps:
				var step_d := d / steps
				var height := 0.25 * (i + 1)
				_box(root, Vector3(w, height, step_d), Vector3(0, height / 2, d / 2 - step_d * (i + 0.5)), WOOD.lightened(0.15 + 0.02 * (i % 2)))
		_:
			return null
	return root


static func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		mat.roughness = 1.0
		_materials[key] = mat
	return _materials[key]


static func _box(parent: Node3D, size: Vector3, center: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, center, color)


static func _cylinder(parent: Node3D, radius: float, height: float, center: Vector3, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	return _add(parent, mesh, center, color)


static func _sphere(parent: Node3D, radius: float, center: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	return _add(parent, mesh, center, color)


static func _add(parent: Node3D, mesh: Mesh, center: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = center
	instance.material_override = material(color)
	parent.add_child(instance)
	return instance
