class_name GymKit
## Gymmets utrustning i husets 3D-stil och som symboler i planritningen: kondition, fria
## vikter, maskiner, funktionell träning, receptionen och omklädningsrummet. FurnitureKit
## och FloorPlanArt lämnar över de här sorterna hit.
## Varje sak byggs lokalt med bredden w längs x, djupet d längs z och framsidan mot +z
## (bort från väggen). Maskinernas viktmagasin, konsoler och svänghjul står mot -z, så att
## den som tränar vänder sig mot dem och man ser in i maskinen från rummet.

const KINDS := ["treadmill", "elliptical", "stair_climber", "recumbent_bike", "spin_bike", "air_bike", "rower",
		"power_rack", "plate_tree", "dumbbell_rack", "adjustable_bench", "kettlebell_rack", "roman_chair",
		"lat_pulldown", "seated_row", "chest_press", "shoulder_press", "leg_press", "leg_extension", "leg_curl",
		"smith_machine", "cable_station", "heavy_bag", "sled", "battle_ropes", "plyo_boxes", "medball_rack",
		"foam_rollers", "exercise_balls", "front_desk", "drinks_fridge", "merch_shelf", "access_gate",
		"water_fountain", "spray_station", "speaker", "yoga_shelf", "lockers", "locker_bench",
		"entry_mat", "rubber_floor", "turf"]
## Golvytor som markerar zonerna. De ligger platt på golvet och man kan stå på dem.
const FLOORS := ["entry_mat", "rubber_floor", "turf"]

## Pulverlackerade ramar, svart konstläder, gymmets accentfärg (platsens färg på kartan).
const FRAME := Color(0.27, 0.28, 0.32)
const PAD := Color(0.17, 0.17, 0.2)
const ACCENT := Color(0.33, 0.68, 0.6)
const IRON := Color(0.15, 0.15, 0.17)
const RUBBER := Color(0.29, 0.3, 0.33)
const TURF := Color(0.34, 0.58, 0.36)
## Bumperskivor, kettlebells och medicinbollar i tävlingsfärger, dämpade som resten av stilen.
const WEIGHT_COLORS := [Color(0.85, 0.36, 0.36), Color(0.36, 0.55, 0.85), Color(0.95, 0.8, 0.35), Color(0.45, 0.72, 0.45), Color(0.7, 0.5, 0.85)]
## Yogamattor, rullar och block.
const SOFT_COLORS := [Color(0.4, 0.6, 0.8), Color(0.62, 0.52, 0.8), Color(0.48, 0.7, 0.58), Color(0.88, 0.58, 0.52), Color(0.86, 0.76, 0.5)]

static var _screen_mat: ShaderMaterial
static var _green_mat: ShaderMaterial


## Bygger en sak lokalt: bredd w längs x, djup d längs z, framsidan mot +z.
static func build(n: Node3D, rig: TimeOfDayRig, kind: String, w: float, d: float) -> void:
	var frame := StyleKit.mat(FRAME, 0.3)
	var steel := StyleKit.mat(StyleKit.METAL, 0.7)
	match kind:
		# --- Kondition ---------------------------------------------------------
		"treadmill":
			StyleKit.box(n, Vector3(w, 0.16, d), Vector3(0, 0.08, 0), StyleKit.mat(StyleKit.DARK))
			StyleKit.box(n, Vector3(w - 0.18, 0.02, d - 0.45), Vector3(0, 0.17, 0.15), StyleKit.mat(Color(0.12, 0.12, 0.14)), true, 0.0)
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.07, 0.025, d - 0.45), Vector3(s * (w / 2 - 0.045), 0.172, 0.15), steel, true, 0.0)
			# Motorkåpan längst fram med en rand i accentfärg.
			StyleKit.box(n, Vector3(w, 0.24, 0.42), Vector3(0, 0.2, -d / 2 + 0.21), frame)
			StyleKit.box(n, Vector3(w + 0.006, 0.04, 0.3), Vector3(0, 0.24, -d / 2 + 0.25), StyleKit.mat(ACCENT), true, 0.0)
			for s in [-1, 1]:
				_strut(n, Vector3(s * (w / 2 - 0.05), 0.3, -d / 2 + 0.3), Vector3(s * (w / 2 - 0.05), 1.22, -d / 2 + 0.14), 0.06, frame)
				StyleKit.box(n, Vector3(0.045, 0.045, 0.5), Vector3(s * (w / 2 - 0.05), 1.02, -d / 2 + 0.45), StyleKit.mat(PAD))
			_console(n, Vector3(0, 1.28, -d / 2 + 0.16), w * 0.9)
		"elliptical":
			StyleKit.box(n, Vector3(0.22, 0.08, d - 0.1), Vector3(0, 0.04, 0.05), frame)
			StyleKit.box(n, Vector3(w * 0.8, 0.06, 0.12), Vector3(0, 0.03, d / 2 - 0.1), frame)
			StyleKit.box(n, Vector3(0.34, 0.55, 0.45), Vector3(0, 0.33, -d / 2 + 0.25), StyleKit.mat(StyleKit.DARK), true, 0.05)
			StyleKit.cylinder(n, 0.2, 0.2, 0.36, Vector3(0, 0.36, -d / 2 + 0.25), StyleKit.mat(ACCENT, 0.3), 20).rotation_degrees = Vector3(0, 0, 90)
			for s in [-1, 1]:
				# Pedalerna står på olika höjd, som mitt i ett steg.
				var pedal_z: float = 0.15 + s * 0.12
				StyleKit.box(n, Vector3(0.13, 0.04, 0.36), Vector3(s * 0.14, 0.3 + s * 0.06, pedal_z), StyleKit.mat(PAD))
				_strut(n, Vector3(s * 0.14, 0.32 + s * 0.06, pedal_z - 0.15), Vector3(s * 0.13, 0.42, -d / 2 + 0.42), 0.04, frame)
				_strut(n, Vector3(s * 0.2, 0.45, -d / 2 + 0.44), Vector3(s * 0.25, 1.55, -d / 2 + 0.55 + s * 0.08), 0.04, frame)
				StyleKit.box(n, Vector3(0.05, 0.22, 0.05), Vector3(s * 0.25, 1.5, -d / 2 + 0.55 + s * 0.08), StyleKit.mat(PAD))
			_strut(n, Vector3(0, 0.6, -d / 2 + 0.25), Vector3(0, 1.28, -d / 2 + 0.3), 0.06, frame)
			_console(n, Vector3(0, 1.33, -d / 2 + 0.32), 0.42)
		"stair_climber":
			StyleKit.box(n, Vector3(w, 0.1, d), Vector3(0, 0.05, 0), StyleKit.mat(StyleKit.DARK))
			# Trappbandet stiger in mot maskinen.
			for i in 5:
				StyleKit.box(n, Vector3(w - 0.2, 0.05, 0.24), Vector3(0, 0.22 + i * 0.19, d / 2 - 0.22 - i * 0.17), StyleKit.mat(IRON.lightened(0.12)), true, 0.01)
			StyleKit.box(n, Vector3(w - 0.12, 1.1, 0.14), Vector3(0, 0.6, -d / 2 + 0.1), frame)
			StyleKit.box(n, Vector3(w - 0.1, 0.08, 0.15), Vector3(0, 1.1, -d / 2 + 0.1), StyleKit.mat(ACCENT))
			for s in [-1, 1]:
				_strut(n, Vector3(s * (w / 2 - 0.04), 0.12, d / 2 - 0.05), Vector3(s * (w / 2 - 0.04), 1.1, -d / 2 + 0.18), 0.08, StyleKit.mat(StyleKit.DARK))
				_strut(n, Vector3(s * (w / 2 - 0.03), 1.05, d / 2 - 0.25), Vector3(s * (w / 2 - 0.03), 1.5, -d / 2 + 0.25), 0.04, steel)
				_post(n, s * (w / 2 - 0.03), d / 2 - 0.25, 1.05, steel, 0.04)
			_console(n, Vector3(0, 1.58, -d / 2 + 0.2), 0.45)
		"recumbent_bike":
			StyleKit.box(n, Vector3(0.16, 0.12, d - 0.3), Vector3(0, 0.12, 0.05), frame)
			for z in [-d / 2 + 0.12, d / 2 - 0.12]:
				StyleKit.box(n, Vector3(w * 0.8, 0.05, 0.1), Vector3(0, 0.025, z), frame)
			StyleKit.box(n, Vector3(0.3, 0.5, 0.45), Vector3(0, 0.32, -d / 2 + 0.28), StyleKit.mat(StyleKit.DARK), true, 0.05)
			StyleKit.box(n, Vector3(0.31, 0.06, 0.4), Vector3(0, 0.45, -d / 2 + 0.3), StyleKit.mat(ACCENT), true, 0.0)
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.1, 0.03, 0.18), Vector3(s * 0.2, 0.35 + s * 0.06, -d / 2 + 0.45), StyleKit.mat(PAD))
				StyleKit.box(n, Vector3(0.04, 0.04, 0.3), Vector3(s * 0.3, 0.56, d / 2 - 0.45), StyleKit.mat(PAD))
			StyleKit.box(n, Vector3(0.06, 0.4, 0.06), Vector3(0, 0.3, d / 2 - 0.45), frame)
			_pad(n, Vector3(0.48, 0.09, 0.42), Vector3(0, 0.52, d / 2 - 0.45))
			_pad(n, Vector3(0.46, 0.55, 0.09), Vector3(0, 0.84, d / 2 - 0.2)).rotation_degrees = Vector3(15, 0, 0)
			_strut(n, Vector3(0, 0.55, -d / 2 + 0.3), Vector3(0, 0.95, -d / 2 + 0.35), 0.05, frame)
			_console(n, Vector3(0, 1.0, -d / 2 + 0.38), 0.36)
		"spin_bike":
			for z in [-d / 2 + 0.1, d / 2 - 0.1]:
				StyleKit.box(n, Vector3(w, 0.05, 0.09), Vector3(0, 0.03, z), frame)
			_strut(n, Vector3(0, 0.06, d / 2 - 0.1), Vector3(0, 0.8, 0.05), 0.07, frame)
			_strut(n, Vector3(0, 0.06, -d / 2 + 0.1), Vector3(0, 0.95, -d / 2 + 0.3), 0.07, frame)
			_strut(n, Vector3(0, 0.45, 0.12), Vector3(0, 0.78, -d / 2 + 0.27), 0.06, frame)
			# Svänghjulet fram med ett skydd i accentfärg.
			StyleKit.cylinder(n, 0.24, 0.24, 0.04, Vector3(0, 0.3, -d / 2 + 0.28), steel, 24).rotation_degrees = Vector3(0, 0, 90)
			StyleKit.cylinder(n, 0.19, 0.19, 0.07, Vector3(0, 0.3, -d / 2 + 0.28), StyleKit.mat(ACCENT, 0.3), 24).rotation_degrees = Vector3(0, 0, 90)
			StyleKit.box(n, Vector3(0.26, 0.03, 0.03), Vector3(0, 0.33, 0.05), StyleKit.mat(StyleKit.DARK))
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.09, 0.02, 0.06), Vector3(s * 0.15, 0.33 + s * 0.06, 0.05 + s * 0.06), StyleKit.mat(PAD))
			StyleKit.box(n, Vector3(0.04, 0.25, 0.04), Vector3(0, 0.9, 0.08), steel)
			StyleKit.box(n, Vector3(0.16, 0.06, 0.28), Vector3(0, 1.03, 0.1), StyleKit.mat(PAD), true, 0.025)
			StyleKit.box(n, Vector3(0.04, 0.22, 0.04), Vector3(0, 1.04, -d / 2 + 0.3), steel)
			StyleKit.box(n, Vector3(0.44, 0.035, 0.035), Vector3(0, 1.15, -d / 2 + 0.33), StyleKit.mat(PAD))
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.035, 0.035, 0.24), Vector3(s * 0.19, 1.15, -d / 2 + 0.2), StyleKit.mat(PAD))
			StyleKit.box(n, Vector3(0.12, 0.07, 0.03), Vector3(0, 1.21, -d / 2 + 0.27), _screen())
		"air_bike":
			for z in [-d / 2 + 0.1, d / 2 - 0.1]:
				StyleKit.box(n, Vector3(w, 0.05, 0.1), Vector3(0, 0.03, z), frame)
			_strut(n, Vector3(0, 0.06, d / 2 - 0.1), Vector3(0, 0.8, d / 2 - 0.32), 0.07, frame)
			_strut(n, Vector3(0, 0.4, d / 2 - 0.25), Vector3(0, 0.45, -d / 2 + 0.38), 0.07, frame)
			# Den stora fläkten som ger motstånd, med galler.
			StyleKit.cylinder(n, 0.34, 0.34, 0.16, Vector3(0, 0.46, -d / 2 + 0.36), StyleKit.mat(StyleKit.METAL.darkened(0.25), 0.4), 28).rotation_degrees = Vector3(0, 0, 90)
			StyleKit.cylinder(n, 0.3, 0.3, 0.17, Vector3(0, 0.46, -d / 2 + 0.36), StyleKit.mat(IRON), 28).rotation_degrees = Vector3(0, 0, 90)
			StyleKit.cylinder(n, 0.08, 0.08, 0.18, Vector3(0, 0.46, -d / 2 + 0.36), StyleKit.mat(ACCENT), 16).rotation_degrees = Vector3(0, 0, 90)
			for s in [-1, 1]:
				_strut(n, Vector3(s * 0.15, 0.46, -d / 2 + 0.5), Vector3(s * 0.22, 1.22, -d / 2 + 0.56 - s * 0.06), 0.04, frame)
				StyleKit.box(n, Vector3(0.05, 0.18, 0.05), Vector3(s * 0.22, 1.24, -d / 2 + 0.56 - s * 0.06), StyleKit.mat(PAD))
				StyleKit.box(n, Vector3(0.1, 0.03, 0.12), Vector3(s * 0.17, 0.42 - s * 0.05, 0.0), StyleKit.mat(PAD))
			StyleKit.box(n, Vector3(0.05, 0.2, 0.05), Vector3(0, 0.88, d / 2 - 0.32), steel)
			StyleKit.box(n, Vector3(0.22, 0.07, 0.28), Vector3(0, 0.99, d / 2 - 0.3), StyleKit.mat(PAD), true, 0.025)
			StyleKit.box(n, Vector3(0.14, 0.09, 0.03), Vector3(0, 0.98, -d / 2 + 0.6), _screen())
		"rower":
			_strut(n, Vector3(0, 0.3, -d / 2 + 0.5), Vector3(0, 0.22, d / 2 - 0.1), 0.1, steel)
			StyleKit.box(n, Vector3(0.4, 0.2, 0.08), Vector3(0, 0.1, d / 2 - 0.1), frame)
			StyleKit.box(n, Vector3(w, 0.05, 0.1), Vector3(0, 0.025, -d / 2 + 0.2), frame)
			StyleKit.cylinder(n, 0.27, 0.27, 0.16, Vector3(0, 0.33, -d / 2 + 0.27), StyleKit.mat(StyleKit.DARK), 24).rotation_degrees = Vector3(0, 0, 90)
			StyleKit.cylinder(n, 0.2, 0.2, 0.17, Vector3(0, 0.33, -d / 2 + 0.27), StyleKit.mat(ACCENT, 0.3), 24).rotation_degrees = Vector3(0, 0, 90)
			_strut(n, Vector3(0, 0.5, -d / 2 + 0.35), Vector3(0, 0.92, -d / 2 + 0.55), 0.035, frame)
			StyleKit.box(n, Vector3(0.18, 0.14, 0.03), Vector3(0, 0.96, -d / 2 + 0.57), StyleKit.mat(StyleKit.DARK))
			StyleKit.box(n, Vector3(0.14, 0.1, 0.005), Vector3(0, 0.96, -d / 2 + 0.587), _screen(), false, 0.0)
			_pad(n, Vector3(0.3, 0.07, 0.28), Vector3(0, 0.38, 0.2))
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.14, 0.03, 0.26), Vector3(s * 0.12, 0.34, -d / 2 + 0.64), StyleKit.mat(PAD)).rotation_degrees = Vector3(-40, 0, 0)
			StyleKit.box(n, Vector3(0.44, 0.03, 0.03), Vector3(0, 0.45, -d / 2 + 0.46), StyleKit.mat(PAD))

		# --- Fria vikter -------------------------------------------------------
		"power_rack":
			# Lyftplattform (trä i mitten, gummi på sidorna) under en rack med stång på krokarna.
			StyleKit.box(n, Vector3(w, 0.05, d), Vector3(0, 0.025, 0), StyleKit.mat(IRON.lightened(0.1)), true, 0.0)
			StyleKit.box(n, Vector3(w * 0.5, 0.052, d - 0.04), Vector3(0, 0.026, 0), StyleKit.mat(StyleKit.OAK, 0.1, 3, 0.2), true, 0.0)
			var back := -d / 2 + 0.12
			var front := back + 0.95
			var x := w / 2 - 0.1
			for s in [-1, 1]:
				for z in [back, front]:
					_post(n, s * x, z, 2.3, frame, 0.08)
				StyleKit.box(n, Vector3(0.08, 0.08, front - back), Vector3(s * x, 2.3, (back + front) / 2), frame)
				StyleKit.box(n, Vector3(0.06, 0.06, front - back + 0.3), Vector3(s * (x - 0.07), 0.7, (back + front) / 2 + 0.15), steel)
				StyleKit.box(n, Vector3(0.06, 0.1, 0.08), Vector3(s * x, 1.32, front + 0.06), StyleKit.mat(IRON))
				# Skivförvaring på de bakre stolparna.
				StyleKit.cylinder(n, 0.025, 0.025, 0.26, Vector3(s * (x + 0.15), 0.45, back), steel, 8).rotation_degrees = Vector3(0, 0, 90)
				for i in 2:
					_plate(n, Vector3(s * (x + 0.12 + i * 0.055), 0.45, back), 0.24 - i * 0.05, WEIGHT_COLORS[i + (1 if s > 0 else 0)])
			StyleKit.box(n, Vector3(w - 0.12, 0.08, 0.08), Vector3(0, 2.3, back), frame)
			StyleKit.box(n, Vector3(w - 0.12, 0.12, 0.02), Vector3(0, 2.2, back - 0.05), StyleKit.mat(ACCENT))
			StyleKit.cylinder(n, 0.018, 0.018, w - 0.1, Vector3(0, 2.24, front + 0.02), steel, 10).rotation_degrees = Vector3(0, 0, 90)
			_barbell(n, Vector3(0, 1.39, front + 0.06), 1.9)
		"plate_tree":
			for turn in [0, 90]:
				StyleKit.box(n, Vector3(0.55, 0.05, 0.08), Vector3(0, 0.025, 0), frame).rotation_degrees = Vector3(0, turn, 0)
			_post(n, 0, 0, 1.2, frame, 0.07)
			for level in 3:
				var y := 0.3 + level * 0.35
				for s in [-1, 1]:
					StyleKit.cylinder(n, 0.022, 0.022, 0.22, Vector3(s * 0.13, y, 0), steel, 8).rotation_degrees = Vector3(0, 0, 90)
					for i in 3 - level:
						_plate(n, Vector3(s * (0.08 + i * 0.055), y, 0), 0.24 - level * 0.06, WEIGHT_COLORS[(level * 2 + i + (1 if s > 0 else 0)) % WEIGHT_COLORS.size()])
		"dumbbell_rack":
			# Två lutande hyllplan med hantlar i stigande vikt, de tyngsta längst ned.
			for support_x in [-w / 2 + 0.03, 0.0, w / 2 - 0.03]:
				StyleKit.box(n, Vector3(0.06, 0.85, d - 0.1), Vector3(support_x, 0.425, 0), frame)
			StyleKit.box(n, Vector3(w, 0.04, 0.32), Vector3(0, 0.5, 0.17), frame).rotation_degrees = Vector3(8, 0, 0)
			StyleKit.box(n, Vector3(w, 0.04, 0.32), Vector3(0, 0.82, -0.17), frame).rotation_degrees = Vector3(8, 0, 0)
			var count := int((w - 0.2) / 0.3)
			for tier in 2:
				var y := 0.52 if tier == 0 else 0.84
				var z := 0.17 if tier == 0 else -0.17
				for i in count:
					var x := -w / 2 + 0.2 + i * (w - 0.4) / maxf(count - 1, 1)
					var weight := (1 - tier) * count + i
					var r := 0.04 + weight * 0.0035
					StyleKit.cylinder(n, 0.014, 0.014, 0.3, Vector3(x, y + r, z), steel, 8).rotation_degrees = Vector3(90, 0, 0)
					for e in [-1, 1]:
						StyleKit.cylinder(n, r, r, 0.07, Vector3(x, y + r, z + e * 0.13), StyleKit.mat(IRON, 0.3), 6).rotation_degrees = Vector3(90, 0, 0)
		"adjustable_bench":
			StyleKit.box(n, Vector3(0.08, 0.07, d - 0.1), Vector3(0, 0.12, 0), frame)
			for z in [d / 2 - 0.1, -d / 2 + 0.1]:
				StyleKit.box(n, Vector3(0.42, 0.06, 0.08), Vector3(0, 0.03, z), frame)
			for s in [-1, 1]:
				StyleKit.cylinder(n, 0.04, 0.04, 0.04, Vector3(s * 0.19, 0.04, -d / 2 + 0.05), StyleKit.mat(StyleKit.DARK), 12).rotation_degrees = Vector3(0, 0, 90)
			_post(n, 0, d / 2 - 0.35, 0.42, frame, 0.06)
			_pad(n, Vector3(0.28, 0.08, 0.4), Vector3(0, 0.45, d / 2 - 0.3))
			# Ryggstödet uppfällt i lutning.
			_pad(n, Vector3(0.28, 0.08, 0.72), Vector3(0, 0.63, -0.2)).rotation_degrees = Vector3(30, 0, 0)
			_strut(n, Vector3(0, 0.14, -0.38), Vector3(0, 0.55, -0.28), 0.04, steel)
		"kettlebell_rack":
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.05, 0.6, d - 0.04), Vector3(s * (w / 2 - 0.025), 0.3, 0), frame)
			for y in [0.06, 0.42]:
				StyleKit.box(n, Vector3(w, 0.03, d), Vector3(0, y, 0), frame)
			var count := int(w / 0.26)
			for shelf in 2:
				for i in count:
					var x := -w / 2 + 0.16 + i * (w - 0.32) / maxf(count - 1, 1)
					var r := (0.095 if shelf == 0 else 0.07) + (i % 3) * 0.006
					_kettlebell(n, Vector3(x, 0.075 if shelf == 0 else 0.435, 0), r, WEIGHT_COLORS[(i + shelf * 2) % WEIGHT_COLORS.size()])
		"roman_chair":
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.06, 0.06, d), Vector3(s * 0.25, 0.03, 0), frame)
			for z in [-d / 2 + 0.05, d / 2 - 0.05]:
				StyleKit.box(n, Vector3(0.56, 0.06, 0.06), Vector3(0, 0.03, z), frame)
			_strut(n, Vector3(0, 0.06, -d / 2 + 0.1), Vector3(0, 0.9, d / 2 - 0.3), 0.08, frame)
			for s in [-1, 1]:
				_pad(n, Vector3(0.18, 0.09, 0.3), Vector3(s * 0.11, 0.95, d / 2 - 0.28)).rotation_degrees = Vector3(-35, 0, 0)
				StyleKit.cylinder(n, 0.055, 0.055, 0.16, Vector3(s * 0.1, 0.5, -d / 2 + 0.42), StyleKit.mat(PAD), 12).rotation_degrees = Vector3(0, 0, 90)
				_strut(n, Vector3(s * 0.26, 0.06, d / 2 - 0.15), Vector3(s * 0.27, 0.92, d / 2 - 0.12), 0.04, frame)
			StyleKit.box(n, Vector3(0.4, 0.03, 0.3), Vector3(0, 0.3, -d / 2 + 0.28), StyleKit.mat(IRON)).rotation_degrees = Vector3(40, 0, 0)
			_strut(n, Vector3(0, 0.3, -d / 2 + 0.3), Vector3(0, 0.5, -d / 2 + 0.42), 0.04, frame)

		# --- Maskiner ----------------------------------------------------------
		"lat_pulldown":
			var back := -d / 2 + 0.15
			StyleKit.box(n, Vector3(0.1, 0.06, d - 0.1), Vector3(0, 0.03, 0), frame)
			StyleKit.box(n, Vector3(w * 0.7, 0.06, 0.12), Vector3(0, 0.03, back), frame)
			for s in [-1, 1]:
				_post(n, s * 0.26, back, 2.15, frame, 0.08)
			StyleKit.box(n, Vector3(0.62, 0.08, 0.1), Vector3(0, 2.15, back), frame)
			_stack(n, 0, back, 2.0)
			# Armen fram med blocket, vajern och den breda stången.
			StyleKit.box(n, Vector3(0.08, 0.08, 0.8), Vector3(0, 2.1, back + 0.42), frame)
			StyleKit.cylinder(n, 0.005, 0.005, 0.4, Vector3(0, 1.86, back + 0.78), StyleKit.mat(StyleKit.DARK), 6)
			StyleKit.box(n, Vector3(w - 0.1, 0.03, 0.03), Vector3(0, 1.65, back + 0.78), steel)
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.16, 0.04, 0.04), Vector3(s * (w / 2 - 0.13), 1.62, back + 0.78), StyleKit.mat(PAD)).rotation_degrees = Vector3(0, 0, s * -20)
			StyleKit.box(n, Vector3(0.06, 0.45, 0.06), Vector3(0, 0.25, back + 0.9), frame)
			_pad(n, Vector3(0.42, 0.08, 0.38), Vector3(0, 0.5, back + 0.9))
			_post(n, 0, back + 0.72, 0.72, frame, 0.05)
			for s in [-1, 1]:
				StyleKit.cylinder(n, 0.06, 0.06, 0.2, Vector3(s * 0.13, 0.74, back + 0.72), StyleKit.mat(PAD), 12).rotation_degrees = Vector3(0, 0, 90)
		"seated_row":
			var back := -d / 2 + 0.15
			StyleKit.box(n, Vector3(0.12, 0.08, d - 0.1), Vector3(0, 0.04, 0), frame)
			for s in [-1, 1]:
				_post(n, s * 0.24, back, 1.7, frame, 0.08)
			StyleKit.box(n, Vector3(0.56, 0.08, 0.1), Vector3(0, 1.7, back), frame)
			_stack(n, 0, back, 1.6)
			StyleKit.box(n, Vector3(0.06, 0.6, 0.06), Vector3(0, 0.6, back + 0.45), frame)
			_pad(n, Vector3(0.36, 0.42, 0.08), Vector3(0, 0.95, back + 0.5))
			StyleKit.box(n, Vector3(0.06, 0.4, 0.06), Vector3(0, 0.22, d / 2 - 0.45), frame)
			_pad(n, Vector3(0.42, 0.08, 0.4), Vector3(0, 0.46, d / 2 - 0.45))
			StyleKit.cylinder(n, 0.005, 0.005, 0.5, Vector3(0, 0.98, back + 0.22), StyleKit.mat(StyleKit.DARK), 6).rotation_degrees = Vector3(90, 0, 0)
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.04, 0.14, 0.04), Vector3(s * 0.14, 0.98, back + 0.62), StyleKit.mat(PAD))
				StyleKit.box(n, Vector3(0.14, 0.03, 0.2), Vector3(s * 0.15, 0.2, back + 0.72), StyleKit.mat(IRON)).rotation_degrees = Vector3(-50, 0, 0)
		"chest_press", "shoulder_press":
			# Viktmagasinet vid sidan, ryggstödet framför tornet och pressarmar som går fram
			# (bröstpress) eller upp (axelpress).
			var shoulders := kind == "shoulder_press"
			var back := -d / 2 + 0.15
			StyleKit.box(n, Vector3(w, 0.06, 0.12), Vector3(0, 0.03, back), frame)
			StyleKit.box(n, Vector3(0.12, 0.06, d - 0.1), Vector3(0, 0.03, 0), frame)
			for post_x in [-w / 2 + 0.1, -w / 2 + 0.42, w / 2 - 0.08]:
				_post(n, post_x, back, 1.75, frame, 0.07)
			StyleKit.box(n, Vector3(w - 0.1, 0.08, 0.1), Vector3(0, 1.75, back), frame)
			_stack(n, -w / 2 + 0.26, back, 1.65)
			_pad(n, Vector3(0.42, 0.7 if shoulders else 0.62, 0.09), Vector3(0.1, 1.0 if shoulders else 0.92, back + 0.32)).rotation_degrees = Vector3(-8, 0, 0)
			StyleKit.box(n, Vector3(0.06, 0.42, 0.06), Vector3(0.1, 0.24, back + 0.6), frame)
			_pad(n, Vector3(0.42, 0.08, 0.4), Vector3(0.1, 0.49, back + 0.6))
			for s in [-1, 1]:
				var x: float = 0.1 + s * 0.32
				var grip := Vector3(x, 1.45, back + 0.55) if shoulders else Vector3(x, 1.05, back + 0.85)
				_strut(n, Vector3(x, 1.7 if not shoulders else 0.75, back + 0.08), grip, 0.05, frame)
				StyleKit.box(n, Vector3(0.05, 0.05, 0.16), grip + Vector3(0, 0.02, 0.06), StyleKit.mat(PAD))
		"leg_extension", "leg_curl":
			# Bensträck sittande med rullen framför smalbenen; lårcurl liggande på en
			# bänk med rullen över hälarna. Magasinet står vid sidan.
			var back := -d / 2 + 0.15
			var stack_x := -w / 2 + 0.17
			StyleKit.box(n, Vector3(0.12, 0.06, d - 0.1), Vector3(0.1, 0.03, 0), frame)
			StyleKit.box(n, Vector3(w - 0.1, 0.06, 0.12), Vector3(0, 0.03, back), frame)
			for s in [-1, 1]:
				_post(n, stack_x + s * 0.17, back, 1.5, frame, 0.07)
			StyleKit.box(n, Vector3(0.42, 0.08, 0.1), Vector3(stack_x, 1.5, back), frame)
			_stack(n, stack_x, back, 1.4)
			if kind == "leg_extension":
				StyleKit.box(n, Vector3(0.06, 0.48, 0.06), Vector3(0.15, 0.26, 0.05), frame)
				_pad(n, Vector3(0.42, 0.09, 0.45), Vector3(0.15, 0.55, 0.05))
				_pad(n, Vector3(0.42, 0.6, 0.09), Vector3(0.15, 0.92, -0.22)).rotation_degrees = Vector3(10, 0, 0)
				_strut(n, Vector3(0.15, 0.55, 0.3), Vector3(0.15, 0.3, 0.42), 0.05, frame)
				StyleKit.cylinder(n, 0.06, 0.06, 0.34, Vector3(0.15, 0.3, 0.45), StyleKit.mat(PAD), 12).rotation_degrees = Vector3(0, 0, 90)
				for s in [-1, 1]:
					StyleKit.box(n, Vector3(0.04, 0.04, 0.22), Vector3(0.15 + s * 0.26, 0.55, 0.0), StyleKit.mat(PAD))
			else:
				_strut(n, Vector3(0.12, 0.06, back + 0.2), Vector3(0.12, 0.62, back + 0.2), 0.06, frame)
				_strut(n, Vector3(0.12, 0.06, d / 2 - 0.25), Vector3(0.12, 0.62, d / 2 - 0.25), 0.06, frame)
				_pad(n, Vector3(0.36, 0.09, 0.62), Vector3(0.12, 0.7, back + 0.45)).rotation_degrees = Vector3(-8, 0, 0)
				_pad(n, Vector3(0.36, 0.1, 0.42), Vector3(0.12, 0.72, d / 2 - 0.42)).rotation_degrees = Vector3(8, 0, 0)
				StyleKit.cylinder(n, 0.06, 0.06, 0.34, Vector3(0.12, 0.88, d / 2 - 0.12), StyleKit.mat(PAD), 12).rotation_degrees = Vector3(0, 0, 90)
				for s in [-1, 1]:
					StyleKit.box(n, Vector3(0.04, 0.12, 0.04), Vector3(0.12 + s * 0.2, 0.7, back + 0.16), StyleKit.mat(PAD))
		"leg_press":
			# Benpress i 45 grader: släden med fotplattan och skivhorn glider uppför rälsen,
			# och man sitter tillbakalutad längst fram.
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.08, 0.08, d - 0.1), Vector3(s * 0.38, 0.04, 0), frame)
				_strut(n, Vector3(s * 0.28, 0.35, d / 2 - 0.8), Vector3(s * 0.28, 1.35, -d / 2 + 0.12), 0.07, steel)
				_post(n, s * 0.28, -d / 2 + 0.12, 1.35, frame, 0.08)
			StyleKit.box(n, Vector3(0.84, 0.08, 0.08), Vector3(0, 1.35, -d / 2 + 0.12), frame)
			var sled := Node3D.new()
			sled.position = Vector3(0, 0.95, -d / 2 + 0.6)
			sled.rotation_degrees = Vector3(-45, 0, 0)
			n.add_child(sled)
			StyleKit.box(sled, Vector3(0.66, 0.5, 0.05), Vector3(0, 0, 0.06), StyleKit.mat(IRON), true, 0.01)
			StyleKit.box(sled, Vector3(0.6, 0.06, 0.012), Vector3(0, -0.18, 0.09), StyleKit.mat(ACCENT), false, 0.0)
			for s in [-1, 1]:
				StyleKit.cylinder(sled, 0.025, 0.025, 0.24, Vector3(s * 0.46, 0, -0.06), steel, 8).rotation_degrees = Vector3(0, 0, 90)
				for i in 2:
					_plate(sled, Vector3(s * (0.43 + i * 0.055), 0, -0.06), 0.22 - i * 0.05, IRON)
			_pad(n, Vector3(0.48, 0.09, 0.42), Vector3(0, 0.45, d / 2 - 0.42))
			_pad(n, Vector3(0.48, 0.7, 0.09), Vector3(0, 0.75, d / 2 - 0.16)).rotation_degrees = Vector3(40, 0, 0)
			StyleKit.box(n, Vector3(0.1, 0.38, 0.3), Vector3(0, 0.2, d / 2 - 0.35), frame)
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.04, 0.04, 0.24), Vector3(s * 0.3, 0.52, d / 2 - 0.42), StyleKit.mat(PAD))
		"smith_machine":
			var x := w / 2 - 0.08
			for s in [-1, 1]:
				for z in [-0.38, 0.38]:
					_post(n, s * x, z, 2.25, frame, 0.08)
				StyleKit.box(n, Vector3(0.08, 0.08, 0.84), Vector3(s * x, 2.25, 0), frame)
				StyleKit.box(n, Vector3(0.08, 0.06, 0.84), Vector3(s * x, 0.03, 0), frame)
				# Styrskenan som stången löper i, och skivhorn på bakre stolparna.
				StyleKit.box(n, Vector3(0.03, 2.1, 0.03), Vector3(s * (x - 0.08), 1.1, 0.0), steel)
				StyleKit.cylinder(n, 0.025, 0.025, 0.24, Vector3(s * (x + 0.14), 0.5, -0.38), steel, 8).rotation_degrees = Vector3(0, 0, 90)
				_plate(n, Vector3(s * (x + 0.12), 0.5, -0.38), 0.22, WEIGHT_COLORS[1 if s < 0 else 3])
			for z in [-0.38, 0.38]:
				StyleKit.box(n, Vector3(w - 0.08, 0.08, 0.08), Vector3(0, 2.25, z), frame)
			StyleKit.box(n, Vector3(w - 0.1, 0.12, 0.02), Vector3(0, 2.15, -0.43), StyleKit.mat(ACCENT))
			_barbell(n, Vector3(0, 1.25, 0.0), w - 0.25)
			StyleKit.box(n, Vector3(0.06, 0.4, 0.06), Vector3(0, 0.2, 0.0), frame)
			_pad(n, Vector3(0.3, 0.08, 1.05), Vector3(0, 0.44, 0.08))
		"cable_station":
			# Funktionell kabelstation: två torn med magasin och flyttbara block, en ram
			# med räckhäng emellan och handtag som hänger i vajrarna.
			var tower := w / 2 - 0.25
			for s in [-1, 1]:
				var tx: float = s * tower
				StyleKit.box(n, Vector3(0.48, 0.06, d - 0.1), Vector3(tx, 0.03, 0), frame)
				for px in [-0.2, 0.2]:
					_post(n, tx + px, -d / 2 + 0.18, 2.2, frame, 0.08)
				StyleKit.box(n, Vector3(0.48, 0.08, 0.1), Vector3(tx, 2.2, -d / 2 + 0.18), frame)
				_stack(n, tx, -d / 2 + 0.18, 2.05)
				_post(n, tx - s * 0.12, -d / 2 + 0.4, 2.0, steel, 0.05)
				StyleKit.box(n, Vector3(0.1, 0.12, 0.1), Vector3(tx - s * 0.12, 1.3, -d / 2 + 0.45), StyleKit.mat(IRON))
				StyleKit.cylinder(n, 0.005, 0.005, 0.5, Vector3(tx - s * 0.12, 1.0, -d / 2 + 0.5), StyleKit.mat(StyleKit.DARK), 6)
				StyleKit.box(n, Vector3(0.12, 0.04, 0.04), Vector3(tx - s * 0.12, 0.73, -d / 2 + 0.5), StyleKit.mat(PAD))
			StyleKit.box(n, Vector3(w - 0.4, 0.08, 0.08), Vector3(0, 2.2, -d / 2 + 0.18), frame)
			StyleKit.cylinder(n, 0.018, 0.018, w * 0.55, Vector3(0, 2.15, -d / 2 + 0.45), steel, 10).rotation_degrees = Vector3(0, 0, 90)
			StyleKit.box(n, Vector3(w * 0.4, 0.14, 0.02), Vector3(0, 1.95, -d / 2 + 0.13), StyleKit.mat(ACCENT))

		# --- Funktionell träning -----------------------------------------------
		"heavy_bag":
			StyleKit.box(n, Vector3(0.2, 0.04, 0.2), Vector3(0, StyleKit.WALL_HEIGHT - 0.02, 0), frame)
			StyleKit.cylinder(n, 0.008, 0.008, 0.74, Vector3(0, 2.21, 0), steel, 6)
			for s in [-1, 1]:
				_strut(n, Vector3(0, 1.85, 0), Vector3(s * 0.12, 1.71, 0), 0.012, steel)
			StyleKit.cylinder(n, 0.19, 0.19, 1.05, Vector3(0, 1.17, 0), StyleKit.mat(Color(0.62, 0.2, 0.22), 0.25), 20)
			StyleKit.cylinder(n, 0.195, 0.195, 0.08, Vector3(0, 1.66, 0), StyleKit.mat(IRON), 20)
			StyleKit.cylinder(n, 0.195, 0.195, 0.06, Vector3(0, 0.67, 0), StyleKit.mat(IRON), 20)
			StyleKit.cylinder(n, 0.193, 0.193, 0.1, Vector3(0, 1.32, 0), StyleKit.mat(StyleKit.WHITE), 20)
		"sled":
			var yellow := StyleKit.mat(Color(0.95, 0.78, 0.3), 0.3)
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.06, 0.05, d), Vector3(s * 0.25, 0.025, 0), steel)
			StyleKit.box(n, Vector3(0.56, 0.04, 0.5), Vector3(0, 0.07, 0.1), yellow)
			_post(n, 0, 0.1, 0.38, steel, 0.05)
			for i in 2:
				_plate(n, Vector3(0, 0.12 + i * 0.055, 0.1), 0.22 - i * 0.03, IRON, Vector3.UP)
			for s in [-1, 1]:
				_strut(n, Vector3(s * 0.25, 0.08, -0.15), Vector3(s * 0.22, 1.05, -0.42), 0.05, yellow)
				StyleKit.box(n, Vector3(0.06, 0.18, 0.06), Vector3(s * 0.22, 1.06, -0.44), StyleKit.mat(PAD))
			StyleKit.box(n, Vector3(0.48, 0.04, 0.04), Vector3(0, 0.5, -0.26), steel)
		"battle_ropes":
			# Två rep från ett ankare längst in, utlagda i vågor på gräset.
			StyleKit.box(n, Vector3(0.24, 0.3, 0.24), Vector3(0, 0.15, -d / 2 + 0.12), StyleKit.mat(IRON), true, 0.03)
			StyleKit.cylinder(n, 0.03, 0.03, 0.28, Vector3(0, 0.24, -d / 2 + 0.25), steel, 8).rotation_degrees = Vector3(0, 0, 90)
			var rope := StyleKit.mat(Color(0.22, 0.22, 0.24), 0.1)
			for s in [-1, 1]:
				var prev := Vector3(s * 0.05, 0.04, -d / 2 + 0.28)
				var segments := 10
				for i in range(1, segments + 1):
					var t := float(i) / segments
					var p := Vector3(s * (0.08 + 0.3 * t) + sin(t * TAU * 1.5) * 0.09 * t, 0.04, -d / 2 + 0.28 + t * (d - 0.6))
					_strut(n, prev, p, 0.05, rope)
					prev = p
				StyleKit.box(n, Vector3(0.07, 0.07, 0.22), prev + Vector3(0, 0, 0.1), StyleKit.mat(ACCENT))
		"plyo_boxes":
			var foam := StyleKit.mat(PAD.lightened(0.06), 0.1)
			StyleKit.box(n, Vector3(0.76, 0.6, 0.62), Vector3(-0.3, 0.3, 0), foam, true, 0.04)
			StyleKit.box(n, Vector3(0.77, 0.06, 0.63), Vector3(-0.3, 0.5, 0), StyleKit.mat(ACCENT), true, 0.0)
			StyleKit.box(n, Vector3(0.6, 0.3, 0.5), Vector3(-0.3, 0.75, 0.02), foam, true, 0.04)
			StyleKit.box(n, Vector3(0.58, 0.45, 0.52), Vector3(0.38, 0.225, 0.05), StyleKit.mat(Color(0.32, 0.45, 0.6)), true, 0.04)
		"medball_rack":
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.05, 0.85, d), Vector3(s * (w / 2 - 0.025), 0.425, 0), frame)
			var balls := [IRON, ACCENT.darkened(0.2), WEIGHT_COLORS[0], WEIGHT_COLORS[1]]
			for tier in 3:
				var y := 0.1 + tier * 0.3
				for z in [-0.1, 0.1]:
					StyleKit.box(n, Vector3(w, 0.03, 0.03), Vector3(0, y, z), frame)
				var count := int((w - 0.1) / 0.27)
				for i in count:
					var r := 0.12 - tier * 0.015
					StyleKit.sphere(n, r, Vector3(-w / 2 + 0.16 + i * (w - 0.32) / maxf(count - 1, 1), y + r * 0.8, 0), StyleKit.mat(balls[(i + tier) % balls.size()], 0.2))
		"foam_rollers":
			StyleKit.box(n, Vector3(w, 0.45, d), Vector3(0, 0.225, 0), StyleKit.mat(FRAME, 0.2))
			var count := maxi(1, int((w - 0.1) / 0.16))
			for row in 2:
				for i in count:
					StyleKit.cylinder(n, 0.07, 0.07, 0.45, Vector3(-w / 2 + 0.11 + i * (w - 0.22) / maxf(count - 1, 1), 0.46 + (i % 2) * 0.03, (row - 0.5) * d * 0.45),
							StyleKit.mat(SOFT_COLORS[(i + row * 2) % SOFT_COLORS.size()]), 14)
		"exercise_balls":
			for z in [-0.12, 0.12]:
				StyleKit.box(n, Vector3(w, 0.04, 0.04), Vector3(0, 0.12, z), frame)
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.04, 0.12, 0.3), Vector3(s * (w / 2 - 0.02), 0.06, 0), frame)
			for i in 2:
				StyleKit.sphere(n, 0.3, Vector3((i - 0.5) * 0.64, 0.42, 0), StyleKit.mat([Color(0.45, 0.58, 0.8), Color(0.62, 0.52, 0.8)][i], 0.4))

		# --- Receptionen och omklädningsrummet ----------------------------------
		"front_desk":
			# Disken: en hög front mot besökarna med gymmets band, en ek-kant att luta sig
			# mot, och personalens sida med skärm, kortterminal och handdukar att dela ut.
			var white := StyleKit.mat(StyleKit.WHITE)
			StyleKit.box(n, Vector3(w, 0.08, d - 0.1), Vector3(0, 0.04, 0), StyleKit.mat(StyleKit.DARK))
			StyleKit.box(n, Vector3(w, 1.0, 0.06), Vector3(0, 0.56, d / 2 - 0.08), white)
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.06, 1.0, d - 0.1), Vector3(s * (w / 2 - 0.03), 0.56, 0), white)
			StyleKit.box(n, Vector3(w + 0.06, 0.05, 0.34), Vector3(0, 1.085, d / 2 - 0.13), StyleKit.mat(StyleKit.OAK, 0.2))
			StyleKit.box(n, Vector3(w - 0.12, 0.04, d - 0.3), Vector3(0, 0.76, -0.12), StyleKit.mat(StyleKit.OAK.lightened(0.05), 0.2))
			StyleKit.box(n, Vector3(w * 0.7, 0.16, 0.012), Vector3(0, 0.66, d / 2 - 0.044), StyleKit.mat(ACCENT), false, 0.0)
			StyleKit.box(n, Vector3(w * 0.22, 0.03, 0.006), Vector3(0, 0.66, d / 2 - 0.036), white, false, 0.0)
			StyleKit.box(n, Vector3(0.06, 0.2, 0.06), Vector3(-w * 0.2, 0.88, -0.05), StyleKit.mat(StyleKit.DARK))
			StyleKit.box(n, Vector3(0.48, 0.3, 0.03), Vector3(-w * 0.2, 1.08, -0.05), StyleKit.mat(StyleKit.DARK, 0.4))
			StyleKit.box(n, Vector3(0.44, 0.26, 0.005), Vector3(-w * 0.2, 1.08, -0.068), _screen(), false, 0.0)
			StyleKit.box(n, Vector3(0.08, 0.03, 0.14), Vector3(w * 0.25, 1.125, d / 2 - 0.12), StyleKit.mat(StyleKit.DARK))
			StyleKit.box(n, Vector3(0.06, 0.004, 0.05), Vector3(w * 0.25, 1.142, d / 2 - 0.15), _green(), false, 0.0)
			for i in 3:
				StyleKit.box(n, Vector3(0.24, 0.045, 0.18), Vector3(-w * 0.32, 1.135 + i * 0.047, d / 2 - 0.13), StyleKit.mat(StyleKit.WHITE if i != 1 else ACCENT.lightened(0.2)))
		"drinks_fridge":
			StyleKit.box(n, Vector3(w, 1.95, d), Vector3(0, 0.975, 0), StyleKit.mat(StyleKit.DARK, 0.3))
			StyleKit.box(n, Vector3(w, 0.22, 0.02), Vector3(0, 1.82, d / 2 + 0.01), StyleKit.mat(ACCENT), true, 0.0)
			var inside := StyleKit.own_mat(Color(0.88, 0.95, 0.98))
			inside.set_shader_parameter("emission", Color(0.8, 0.92, 1.0))
			inside.set_shader_parameter("emission_energy", 0.4)
			StyleKit.box(n, Vector3(w - 0.1, 1.5, 0.02), Vector3(0, 0.95, d / 2 - 0.3), inside, false, 0.0)
			var drinks := [Color(0.55, 0.78, 0.95), Color(0.98, 0.6, 0.25), Color(0.65, 0.88, 0.35), Color(0.9, 0.35, 0.4)]
			for row in 4:
				var y := 0.32 + row * 0.37
				StyleKit.box(n, Vector3(w - 0.1, 0.015, 0.26), Vector3(0, y, d / 2 - 0.15), StyleKit.mat(StyleKit.WHITE, 0.5), false, 0.0)
				for i in 4:
					StyleKit.cylinder(n, 0.035, 0.035, 0.2, Vector3(-w / 2 + 0.16 + i * (w - 0.32) / 3.0, y + 0.11, d / 2 - 0.12), StyleKit.mat(drinks[(i + row) % drinks.size()], 0.6), 10)
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.04, 1.6, 0.03), Vector3(s * (w / 2 - 0.03), 0.92, d / 2 + 0.005), StyleKit.mat(StyleKit.DARK.lightened(0.1)))
			StyleKit.box(n, Vector3(w, 0.06, 0.03), Vector3(0, 0.1, d / 2 + 0.005), StyleKit.mat(StyleKit.DARK.lightened(0.1)))
			StyleKit.box(n, Vector3(0.02, 0.4, 0.03), Vector3(w / 2 - 0.09, 0.95, d / 2 + 0.03), steel)
		"merch_shelf":
			var white := StyleKit.mat(StyleKit.WHITE)
			StyleKit.box(n, Vector3(w, 1.5, 0.03), Vector3(0, 0.75, -d / 2 + 0.015), white)
			for s in [-1, 1]:
				StyleKit.box(n, Vector3(0.03, 1.5, d), Vector3(s * (w / 2 - 0.015), 0.75, 0), white)
			for y in [0.1, 0.5, 0.9, 1.3]:
				StyleKit.box(n, Vector3(w, 0.03, d), Vector3(0, y, 0), StyleKit.mat(StyleKit.OAK))
			for i in 4:
				StyleKit.box(n, Vector3(0.3, 0.13, 0.26), Vector3(-w / 2 + 0.25 + i * 0.4, 0.18, 0), StyleKit.mat(StyleKit.WHITE if i % 2 == 0 else ACCENT.lightened(0.15)))
			var tubs := [IRON, StyleKit.WHITE, WEIGHT_COLORS[0]]
			for i in 7:
				StyleKit.cylinder(n, 0.07, 0.07, 0.18, Vector3(-w / 2 + 0.16 + i * (w - 0.32) / 6.0, 0.605, 0), StyleKit.mat(tubs[i % 3], 0.4), 14)
			var shakers := [ACCENT, IRON, Color(0.92, 0.55, 0.65)]
			for i in 9:
				StyleKit.cylinder(n, 0.04, 0.04, 0.16, Vector3(-w / 2 + 0.14 + i * (w - 0.28) / 8.0, 0.995, 0), StyleKit.mat(shakers[i % 3], 0.5), 10)
			for i in 4:
				StyleKit.box(n, Vector3(0.22, 0.06, 0.18), Vector3(-w / 2 + 0.3 + i * 0.37, 1.345, 0), StyleKit.mat([IRON, ACCENT, IRON, WEIGHT_COLORS[1]][i]))
		"access_gate":
			var xs := [-w / 2 + 0.11, 0.0, w / 2 - 0.11]
			for x in xs:
				StyleKit.box(n, Vector3(0.2, 1.0, d), Vector3(x, 0.5, 0), steel, true, 0.02)
				StyleKit.box(n, Vector3(0.21, 0.04, d + 0.01), Vector3(x, 1.0, 0), StyleKit.mat(StyleKit.DARK))
				StyleKit.box(n, Vector3(0.08, 0.012, 0.1), Vector3(x, 1.026, 0.06), _green(), false, 0.0)
			var glass := StyleKit.mat(Color(0.78, 0.9, 0.96), 0.9)
			for i in 2:
				var a: float = xs[i] + 0.1
				var b: float = xs[i + 1] - 0.1
				var half := (b - a - 0.06) / 2
				for side in [[a, 1.0], [b, -1.0]]:
					StyleKit.box(n, Vector3(half, 0.48, 0.015), Vector3(side[0] + side[1] * half / 2, 0.68, 0), glass, false, 0.0)
		"water_fountain":
			StyleKit.box(n, Vector3(w, 0.32, d), Vector3(0, 0.82, 0), steel, true, 0.03)
			StyleKit.box(n, Vector3(w - 0.08, 0.02, d - 0.1), Vector3(0, 0.985, 0.02), StyleKit.mat(StyleKit.METAL.darkened(0.3), 0.6), true, 0.0)
			StyleKit.box(n, Vector3(0.05, 0.66, 0.05), Vector3(0, 0.33, -d / 2 + 0.04), steel)
			StyleKit.box(n, Vector3(w * 0.85, 0.75, 0.1), Vector3(0, 1.45, -d / 2 + 0.05), steel)
			StyleKit.box(n, Vector3(w * 0.6, 0.4, 0.01), Vector3(0, 1.4, -d / 2 + 0.105), StyleKit.mat(StyleKit.DARK), false, 0.0)
			StyleKit.box(n, Vector3(0.1, 0.03, 0.005), Vector3(0, 1.72, -d / 2 + 0.108), _green(), false, 0.0)
		"spray_station":
			# Desinfektion och papper att torka av maskinerna med.
			StyleKit.cylinder(n, 0.15, 0.16, 0.03, Vector3(0, 0.015, 0), StyleKit.mat(StyleKit.DARK), 16)
			_post(n, 0, 0, 0.9, steel, 0.05)
			StyleKit.box(n, Vector3(0.3, 0.3, 0.18), Vector3(0, 1.05, 0), StyleKit.mat(StyleKit.WHITE), true, 0.02)
			StyleKit.box(n, Vector3(0.31, 0.05, 0.181), Vector3(0, 1.12, 0), StyleKit.mat(ACCENT), true, 0.0)
			StyleKit.cylinder(n, 0.035, 0.04, 0.18, Vector3(0.07, 1.29, 0), StyleKit.mat(ACCENT.lightened(0.2), 0.5), 10)
			StyleKit.box(n, Vector3(0.03, 0.05, 0.06), Vector3(0.07, 1.4, 0.02), StyleKit.mat(StyleKit.WHITE))
		"speaker":
			for i in 3:
				var angle := TAU * i / 3.0
				_strut(n, Vector3(0, 0.55, 0), Vector3(cos(angle) * 0.18, 0.0, sin(angle) * 0.18), 0.025, StyleKit.mat(StyleKit.DARK))
			_post(n, 0, 0, 1.38, StyleKit.mat(StyleKit.DARK), 0.035)
			StyleKit.box(n, Vector3(0.3, 0.48, 0.26), Vector3(0, 1.6, 0), StyleKit.mat(IRON, 0.2), true, 0.03)
			StyleKit.cylinder(n, 0.09, 0.09, 0.01, Vector3(0, 1.52, 0.131), StyleKit.mat(StyleKit.DARK.lightened(0.15)), 16).rotation_degrees = Vector3(90, 0, 0)
			StyleKit.cylinder(n, 0.035, 0.035, 0.01, Vector3(0, 1.75, 0.131), StyleKit.mat(StyleKit.DARK.lightened(0.15)), 12).rotation_degrees = Vector3(90, 0, 0)
		"yoga_shelf":
			# Fack med rullade mattor, block och bolster till passen.
			var oak := StyleKit.mat(StyleKit.OAK.lightened(0.05))
			StyleKit.box(n, Vector3(w, 1.1, 0.02), Vector3(0, 0.55, -d / 2 + 0.01), oak)
			for x in [-w / 2 + 0.015, -w / 6, w / 6, w / 2 - 0.015]:
				StyleKit.box(n, Vector3(0.03, 1.1, d), Vector3(x, 0.55, 0), oak)
			for y in [0.02, 0.38, 0.74, 1.09]:
				StyleKit.box(n, Vector3(w, 0.03, d), Vector3(0, y, 0), oak)
			for col in 3:
				var cx := (col - 1) * w / 3
				for i in 3:
					StyleKit.cylinder(n, 0.07, 0.07, d - 0.05, Vector3(cx + (i - 1) * 0.14, 0.105 + (0.13 if i == 1 else 0.0), 0), StyleKit.mat(SOFT_COLORS[(col * 3 + i) % SOFT_COLORS.size()]), 14).rotation_degrees = Vector3(90, 0, 0)
				for i in 2 + col % 2:
					StyleKit.box(n, Vector3(0.22, 0.1, 0.15), Vector3(cx, 0.445 + i * 0.1, 0), StyleKit.mat([Color(0.62, 0.52, 0.8), Color(0.82, 0.68, 0.5)][i % 2]))
				StyleKit.cylinder(n, 0.1, 0.1, d - 0.06, Vector3(cx, 0.855, 0), StyleKit.mat(SOFT_COLORS[(col + 3) % SOFT_COLORS.size()].darkened(0.1)), 16).rotation_degrees = Vector3(90, 0, 0)
		"lockers":
			var body := Color(0.55, 0.68, 0.7)
			StyleKit.box(n, Vector3(w, 0.1, d - 0.04), Vector3(0, 0.05, -0.02), StyleKit.mat(StyleKit.DARK))
			StyleKit.box(n, Vector3(w, 1.8, d), Vector3(0, 1.0, 0), StyleKit.mat(body, 0.15))
			StyleKit.box(n, Vector3(w + 0.01, 0.03, d + 0.02), Vector3(0, 1.915, 0), StyleKit.mat(body.darkened(0.2)))
			var cols := maxi(1, roundi(w / 0.4))
			var col_w := w / cols
			for i in cols:
				var x := -w / 2 + col_w * (i + 0.5)
				for row in 2:
					var y := 0.555 + row * 0.9
					# Luckorna ligger tätt; de fasade kanterna ritar skarvarna (se köksbänken).
					StyleKit.box(n, Vector3(col_w - 0.006, 0.86, 0.015), Vector3(x, y, d / 2 + 0.004), StyleKit.mat(body.lightened(0.08), 0.15), true, 0.008)
					for v in 3:
						StyleKit.box(n, Vector3(col_w * 0.5, 0.012, 0.006), Vector3(x, y + 0.3 - v * 0.04, d / 2 + 0.012), StyleKit.mat(body.darkened(0.3)), false, 0.0)
					StyleKit.box(n, Vector3(0.03, 0.08, 0.025), Vector3(x + col_w * 0.32, y, d / 2 + 0.02), steel)
					StyleKit.box(n, Vector3(0.06, 0.035, 0.004), Vector3(x, y + 0.37, d / 2 + 0.012), StyleKit.mat(StyleKit.WHITE), false, 0.0)
			# Någons träningsväska ovanpå skåpen.
			if w > 2.0:
				StyleKit.box(n, Vector3(0.5, 0.24, 0.28), Vector3(-w * 0.25, 2.05, 0), StyleKit.mat(Color(0.82, 0.42, 0.46)), true, 0.05)
				StyleKit.box(n, Vector3(0.3, 0.04, 0.03), Vector3(-w * 0.25, 2.2, 0), StyleKit.mat(StyleKit.DARK))
		"locker_bench":
			var oak := StyleKit.mat(StyleKit.OAK)
			for i in 3:
				StyleKit.box(n, Vector3(w, 0.03, 0.11), Vector3(0, 0.45, -d / 2 + 0.07 + i * 0.13), oak)
			for x in [-w / 2 + 0.15, w / 2 - 0.15]:
				StyleKit.box(n, Vector3(0.05, 0.44, d - 0.06), Vector3(x, 0.22, 0), steel)
			# En kvarglömd handduk eller vattenflaska på några av bänkarna.
			var pick := int(absf(n.position.x * 3.0 + n.position.z * 5.0)) % 3
			if pick == 0:
				StyleKit.box(n, Vector3(0.3, 0.05, 0.25), Vector3(w * 0.28, 0.49, 0), StyleKit.mat(Color(0.95, 0.95, 0.92)))
			elif pick == 1:
				StyleKit.cylinder(n, 0.035, 0.035, 0.22, Vector3(-w * 0.3, 0.575, 0), StyleKit.mat(ACCENT, 0.6), 10)

		# --- Golvytor ----------------------------------------------------------
		"entry_mat":
			StyleKit.box(n, Vector3(w, 0.014, d), Vector3(0, 0.007, 0), StyleKit.mat(StyleKit.DARK.lightened(0.06), 0.0, 1, 0.12), true, 0.0)
			StyleKit.box(n, Vector3(w - 0.12, 0.016, 0.07), Vector3(0, 0.008, d / 2 - 0.12), StyleKit.mat(ACCENT), true, 0.0)
		"rubber_floor":
			StyleKit.box(n, Vector3(w, 0.01, d), Vector3(0, 0.005, 0), StyleKit.mat(RUBBER, 0.0, 1, 1.0, RUBBER.darkened(0.25)), true, 0.0)
		"turf":
			StyleKit.box(n, Vector3(w, 0.016, d), Vector3(0, 0.008, 0), StyleKit.mat(TURF), true, 0.0)
			var lines := StyleKit.mat(StyleKit.WHITE)
			for z in [-d / 2 + 0.06, d / 2 - 0.06]:
				StyleKit.box(n, Vector3(w - 0.08, 0.018, 0.04), Vector3(0, 0.009, z), lines, false, 0.0)
			for i in range(1, int(w)):
				StyleKit.box(n, Vector3(0.04, 0.018, d - 0.12), Vector3(-w / 2 + i, 0.009, 0), lines, false, 0.0)


# --- Rummen -------------------------------------------------------------------

## Gymmets belysning och väggar: stora rum får ett rutnät av taklampor (som lysrörsrader
## i en riktig hall) i stället för bara en i mitten, och hallens långa västvägg vid de fria
## vikterna får ett band i accentfärg ovanför spegeln.
static func decorate(parent: Node3D, rig: TimeOfDayRig, room_id: String, o: Vector3, size: Vector2) -> void:
	var cells := Vector2i(maxi(1, roundi(size.x / 4.5)), maxi(1, roundi(size.y / 4.5)))
	if cells.x * cells.y > 1:
		for i in cells.x:
			for j in cells.y:
				var lamp := OmniLight3D.new()
				lamp.position = o + Vector3(size.x * (i + 0.5) / cells.x, 2.35, size.y * (j + 0.5) / cells.y)
				lamp.light_color = Color(1.0, 0.9, 0.75)
				lamp.omni_range = 5.5
				parent.add_child(lamp)
				if rig:
					rig.register_lamp(lamp, null, 0.45)
	if room_id == "gym":
		var mirror := FloorPlanArt.furniture_rect(room_id, "mirror_wall")
		var rubber := FloorPlanArt.furniture_rect(room_id, "rubber_floor")
		if rubber.size != Vector2.ZERO:
			var from := minf(rubber.position.y, mirror.position.y) if mirror.size != Vector2.ZERO else rubber.position.y
			var length := size.y - from - 0.05
			StyleKit.box(parent, Vector3(0.012, 0.22, length), o + Vector3(0.006, 2.18, from + length / 2), StyleKit.mat(ACCENT), false, 0.0)
			StyleKit.box(parent, Vector3(0.013, 0.04, length), o + Vector3(0.007, 2.02, from + length / 2), StyleKit.mat(IRON), false, 0.0)


# --- Delar --------------------------------------------------------------------

## En stolpe från golvet.
static func _post(n: Node3D, x: float, z: float, h: float, material: Material, size := 0.07) -> void:
	StyleKit.box(n, Vector3(size, h, size), Vector3(x, h / 2, z), material)


## En rak stång mellan två punkter i nodens egna koordinater (ramar, armar, rep).
## Vrids med basen i stället för look_at, som räknar i världens koordinater.
static func _strut(n: Node3D, a: Vector3, b: Vector3, thickness: float, material: Material) -> void:
	var mesh := StyleKit.box(n, Vector3(thickness, thickness, a.distance_to(b)), (a + b) / 2, material, true, 0.008)
	var direction := (b - a).normalized()
	mesh.basis = Basis.looking_at(direction, Vector3.UP if absf(direction.y) < 0.99 else Vector3.RIGHT)


## En stoppad dyna (sits, ryggstöd) i svart konstläder.
static func _pad(n: Node3D, size: Vector3, center: Vector3) -> MeshInstance3D:
	return StyleKit.box(n, size, center, StyleKit.mat(PAD, 0.2), true, 0.03)


## Ett viktmagasin: plattor mellan två styrstänger upp till `top`, och en skylt i
## accentfärg framför stängerna.
static func _stack(n: Node3D, x: float, z: float, top: float) -> void:
	StyleKit.box(n, Vector3(0.4, 0.06, 0.22), Vector3(x, 0.03, z), StyleKit.mat(FRAME, 0.3))
	StyleKit.box(n, Vector3(0.3, 0.5, 0.12), Vector3(x, 0.31, z), StyleKit.mat(IRON, 0.2))
	for i in 5:
		StyleKit.box(n, Vector3(0.302, 0.008, 0.122), Vector3(x, 0.12 + i * 0.1, z), StyleKit.mat(IRON.lightened(0.25)), false, 0.0)
	for s in [-1, 1]:
		StyleKit.cylinder(n, 0.012, 0.012, top - 0.06, Vector3(x + s * 0.1, (top + 0.06) / 2, z), StyleKit.mat(StyleKit.METAL, 0.8), 8)
	StyleKit.box(n, Vector3(0.36, top - 0.7, 0.02), Vector3(x, 0.65 + (top - 0.7) / 2, z + 0.09), StyleKit.mat(ACCENT, 0.3))


## En viktskiva som en skiva kring `axis` (stångens riktning).
static func _plate(n: Node3D, at: Vector3, radius: float, color: Color, axis := Vector3.RIGHT) -> void:
	var plate := StyleKit.cylinder(n, radius, radius, 0.05, at, StyleKit.mat(color, 0.3), 20)
	if axis == Vector3.RIGHT:
		plate.rotation_degrees = Vector3(0, 0, 90)
	elif axis == Vector3.BACK:
		plate.rotation_degrees = Vector3(90, 0, 0)


## En skivstång längs x med två skivor i varje ände.
static func _barbell(n: Node3D, at: Vector3, length: float) -> void:
	StyleKit.cylinder(n, 0.014, 0.014, length, at, StyleKit.mat(StyleKit.METAL, 0.8), 10).rotation_degrees = Vector3(0, 0, 90)
	for s in [-1, 1]:
		for i in 2:
			_plate(n, at + Vector3(s * (length / 2 - 0.22 + i * 0.055), 0, 0), 0.22 - i * 0.05, IRON)


## En kettlebell som står på `at`: klot och handtag.
static func _kettlebell(n: Node3D, at: Vector3, r: float, color: Color) -> void:
	StyleKit.sphere(n, r, at + Vector3(0, r, 0), StyleKit.mat(color, 0.3))
	for s in [-1, 1]:
		StyleKit.box(n, Vector3(0.022, r * 0.7, 0.022), at + Vector3(s * r * 0.55, r * 1.85, 0), StyleKit.mat(IRON))
	StyleKit.box(n, Vector3(r * 1.3, 0.024, 0.024), at + Vector3(0, r * 2.2, 0), StyleKit.mat(IRON))


## En lutande konsol med skärm, vänd mot den som tränar.
static func _console(n: Node3D, at: Vector3, width: float) -> void:
	var console := Node3D.new()
	console.position = at
	console.rotation_degrees = Vector3(-25, 0, 0)
	n.add_child(console)
	StyleKit.box(console, Vector3(width, 0.3, 0.08), Vector3.ZERO, StyleKit.mat(StyleKit.DARK, 0.4))
	StyleKit.box(console, Vector3(width * 0.55, 0.17, 0.01), Vector3(0, 0.02, 0.042), _screen(), false, 0.0)


## Skärmarna lyser svagt turkos hela dagen.
static func _screen() -> ShaderMaterial:
	if _screen_mat == null:
		_screen_mat = StyleKit.own_mat(Color(0.25, 0.55, 0.6))
		_screen_mat.set_shader_parameter("emission", Color(0.3, 0.75, 0.75))
		_screen_mat.set_shader_parameter("emission_energy", 0.6)
	return _screen_mat


## Gröna lampor på kortläsare och vattenautomaten.
static func _green() -> ShaderMaterial:
	if _green_mat == null:
		_green_mat = StyleKit.own_mat(Color(0.4, 0.9, 0.5))
		_green_mat.set_shader_parameter("emission", Color(0.4, 1.0, 0.5))
		_green_mat.set_shader_parameter("emission_energy", 0.8)
	return _green_mat


# --- Planritningen ------------------------------------------------------------

## Symbolen ovanifrån i planritningen (FloorPlanArt).
static func draw_symbol(canvas: CanvasItem, kind: String, r: Rect2) -> void:
	var frame := Color(0.42, 0.43, 0.47)
	var pad := Color(0.26, 0.26, 0.3)
	var accent := Color(0.45, 0.72, 0.65)
	match kind:
		"rubber_floor":
			canvas.draw_rect(r, Color(0.45, 0.46, 0.49))
			var step := minf(r.size.x, r.size.y) / 6.0
			FloorPlanArt._grid(canvas, r, step, Color(0.39, 0.4, 0.43))
		"turf":
			canvas.draw_rect(r, Color(0.52, 0.72, 0.5))
			var long := r.size.x >= r.size.y
			var count := 10
			for i in range(1, count):
				var t := float(i) / count
				if long:
					canvas.draw_line(Vector2(r.position.x + r.size.x * t, r.position.y + 2), Vector2(r.position.x + r.size.x * t, r.end.y - 2), Color(1, 1, 1, 0.8), 1.0)
				else:
					canvas.draw_line(Vector2(r.position.x + 2, r.position.y + r.size.y * t), Vector2(r.end.x - 2, r.position.y + r.size.y * t), Color(1, 1, 1, 0.8), 1.0)
		"entry_mat":
			FloorPlanArt._box(canvas, r, Color(0.36, 0.36, 0.38), 2.0)
			canvas.draw_rect(r.grow(-3), Color(accent, 0.8), false, 1.5)
		"front_desk", "merch_shelf", "yoga_shelf", "locker_bench":
			FloorPlanArt._box(canvas, r, FloorPlanArt.OAK, 2.0)
			FloorPlanArt._box(canvas, r.grow(-minf(r.size.x, r.size.y) * 0.25), FloorPlanArt.WHITE if kind == "front_desk" else FloorPlanArt.OAK.lightened(0.1), 2.0)
		"lockers":
			FloorPlanArt._box(canvas, r, Color(0.6, 0.72, 0.74), 1.0)
			var horizontal := r.size.x >= r.size.y
			var length := r.size.x if horizontal else r.size.y
			var cols := maxi(1, int(length / 14.0))
			for i in range(1, cols):
				var t := float(i) / cols
				if horizontal:
					canvas.draw_line(Vector2(r.position.x + r.size.x * t, r.position.y), Vector2(r.position.x + r.size.x * t, r.end.y), FloorPlanArt.LINE, 1.0)
				else:
					canvas.draw_line(Vector2(r.position.x, r.position.y + r.size.y * t), Vector2(r.end.x, r.position.y + r.size.y * t), FloorPlanArt.LINE, 1.0)
		"treadmill", "rower":
			FloorPlanArt._box(canvas, r, pad, 3.0)
			FloorPlanArt._box(canvas, r.grow(-minf(r.size.x, r.size.y) * 0.2), Color(0.15, 0.15, 0.18), 2.0)
		"heavy_bag", "exercise_balls", "medball_rack", "plate_tree":
			FloorPlanArt._box(canvas, r, Color(0, 0, 0, 0), 2.0)
			var balls := 1 if kind in ["heavy_bag", "plate_tree"] else 2
			for i in balls:
				var c := r.position + r.size * Vector2((i + 0.5) / balls, 0.5) if r.size.x >= r.size.y else r.position + r.size * Vector2(0.5, (i + 0.5) / balls)
				canvas.draw_circle(c, minf(r.size.x, r.size.y) * 0.38, Color(0.62, 0.2, 0.22) if kind == "heavy_bag" else accent)
		"drinks_fridge", "water_fountain", "spray_station", "speaker", "access_gate":
			FloorPlanArt._box(canvas, r, Color(0.78, 0.8, 0.84), 2.0)
			canvas.draw_rect(r.grow(-2), Color(accent, 0.7), false, 1.5)
		_:
			# Maskiner och ställningar: ram med en dyna och en rand i accentfärg.
			FloorPlanArt._box(canvas, r, frame, 3.0)
			FloorPlanArt._box(canvas, r.grow(-minf(r.size.x, r.size.y) * 0.22), pad, 2.0)
			canvas.draw_line(r.position + Vector2(3, 3), Vector2(r.end.x - 3, r.position.y + 3), accent, 2.0)
