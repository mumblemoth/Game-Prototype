class_name HomeKit
## Hemmets egna saker i husets 3D-stil och som symboler i planritningen, och varianter av
## de vanliga möblerna, så att samma möbel inte står likadan i varje rum. FurnitureKit
## lämnar hit:
##   - nya typer (KINDS): hallens klädhängare och byrå, golvlampor, gårdens saker ...
##   - möbler med en stil (fjärde elementet i FloorPlanArt.FURNITURE), t.ex. en låg
##     skänk i stället för en bokhylla eller en mattas färg.
## Varje sak ska berätta något om familjen (se minnet om meningsfulla detaljer).

const KINDS := ["coat_stand", "console", "floor_lamp", "side_table", "ironing_board", "cradle",
		"driveway", "patio", "flower_bed", "grill", "veg_bed", "clothesline", "sun_lounger", "shed"]

## Tygets eller färgens ton per stil, för möbler som bara byter färg (soffor, fåtöljer,
## sängkläder, cyklar, bänkskåp).
const TINTS := {
	"rust": Color(0.82, 0.5, 0.38),
	"cream": Color(0.93, 0.88, 0.78),
	"mustard": Color(0.9, 0.72, 0.36),
	"blush": Color(0.92, 0.7, 0.68),
	"grey": Color(0.66, 0.68, 0.72),
	"sheet": Color(0.94, 0.94, 0.92),
	"gamer": Color(0.36, 0.32, 0.58),
	"team": Color(0.78, 0.3, 0.3),
	"linen": Color(0.9, 0.8, 0.66),
	"red": Color(0.9, 0.3, 0.3),
	"blue": Color(0.3, 0.5, 0.85),
	"utility": Color(0.95, 0.95, 0.93),
	"stripe_blue": Color(0.45, 0.65, 0.85),
	"stripe_coral": Color(0.95, 0.6, 0.5),
}

## Mattornas färger: [kant, mitt, mönster (StyleKit.mat), mönstrets storlek].
const RUGS := {
	"sage": [Color(0.55, 0.66, 0.52), Color(0.7, 0.78, 0.64), 1, 0.45],
	"navy": [Color(0.26, 0.32, 0.5), Color(0.34, 0.42, 0.62), 0, 0.4],
	"runner": [Color(0.62, 0.36, 0.32), Color(0.88, 0.8, 0.68), 0, 0.4],
	"jute": [Color(0.72, 0.6, 0.44), Color(0.82, 0.72, 0.56), 7, 0.15],
	"wool": [Color(0.85, 0.8, 0.72), Color(0.95, 0.92, 0.86), 1, 0.3],
	"purple": [Color(0.42, 0.36, 0.62), Color(0.52, 0.46, 0.72), 7, 0.08],
	"blush": [Color(0.86, 0.66, 0.64), Color(0.96, 0.84, 0.8), 0, 0.4],
	"faded": [Color(0.66, 0.48, 0.42), Color(0.76, 0.62, 0.54), 1, 0.5],
}

## Ungefärlig höjd (meter) för saker som kan stå ute; allt annat räknas som lågt (1 m).
## Surroundings hoppar över höga saker framför kameran (dockhusregeln).
const HEIGHTS := {"tree": 3.4, "shed": 2.6, "clothesline": 1.9, "car": 1.25, "bench": 0.8, "grill": 1.05}


static func tint(style: String, fallback: Color) -> Color:
	return TINTS.get(style, fallback)


static func height(kind: String) -> float:
	return HEIGHTS.get(kind, 1.0)


# --- Varianter av vanliga möbler ------------------------------------------------

## Bygger en stilvariant av en vanlig möbel, eller lämnar false om FurnitureKit ska bygga
## den som vanligt (färgvarianter sköts där med tint()).
static func build_variant(n: Node3D, rig: TimeOfDayRig, kind: String, w: float, d: float, style: String) -> bool:
	match [kind, style]:
		["rug", _]:
			if not RUGS.has(style):
				return false
			_rug(n, w, d, style)
		["shelf", "sideboard"]:
			_sideboard(n, w, d)
		["shelf", "metal"]:
			_metal_shelf(n, w, d)
		["shelf", "games"]:
			_games_shelf(n, w, d)
		["shelf", "art"]:
			_art_shelf(n, w, d)
		["plant", "tall"]:
			_tall_plant(n, w, d)
		["plant", "planter"]:
			_planter(n, w, d)
		["desk", "teacher"]:
			FurnitureKit.build(n, rig, "desk", w, d)
			_graded_tests(n, w, d)
		["desk", "white"]:
			_white_desk(n, w, d)
		["chair", "office"]:
			_office_chair(n)
		["chair", "white"]:
			_white_chair(n)
		["basin", "double"], ["basin", "no_mirror"]:
			_basin(n, w, d, style == "double")
		["washer", "dryer"]:
			_dryer(n, w, d)
		_:
			return false
	return true


static func _rug(n: Node3D, w: float, d: float, style: String) -> void:
	var spec: Array = RUGS[style]
	var edge: Color = spec[0]
	var middle: Color = spec[1]
	StyleKit.box(n, Vector3(w, 0.012, d), Vector3(0, 0.006, 0), StyleKit.mat(edge, 0.0, spec[2], spec[3], edge.darkened(0.15)), true, 0.0)
	StyleKit.box(n, Vector3(w - 0.18, 0.014, d - 0.18), Vector3(0, 0.007, 0), StyleKit.mat(middle, 0.0, spec[2], spec[3], middle.darkened(0.1)), true, 0.0)
	if style in ["navy", "runner", "blush"]:
		# Ränder tvärs över mattan (längs den kortare sidan).
		var across_x := w < d
		var length := d if across_x else w
		var count := maxi(2, int(length / 0.45))
		for i in count:
			var t := -length / 2 + 0.25 + (length - 0.5) * (i + 0.5) / count
			var size := Vector3(w - 0.3, 0.016, 0.06) if across_x else Vector3(0.06, 0.016, d - 0.3)
			StyleKit.box(n, size, Vector3(0, 0.008, t) if across_x else Vector3(t, 0.008, 0), StyleKit.mat(edge.lerp(Color.WHITE, 0.55)), true, 0.0)


## Låg skänk mot en innervägg: luckor, kokböcker eller fotoramar och en liten lampa.
static func _sideboard(n: Node3D, w: float, d: float) -> void:
	var wood := StyleKit.WALNUT.lightened(0.12)
	StyleKit.box(n, Vector3(w, 0.72, d), Vector3(0, 0.42, 0), StyleKit.mat(wood))
	for s in [-1, 1]:
		StyleKit.box(n, Vector3(0.04, 0.06, 0.04), Vector3(s * (w / 2 - 0.08), 0.03, d / 2 - 0.08), StyleKit.mat(StyleKit.DARK))
	var doors := maxi(2, roundi(w / 0.45))
	for i in doors:
		var x := -w / 2 + w * (i + 0.5) / doors
		StyleKit.box(n, Vector3(w / doors - 0.01, 0.6, 0.02), Vector3(x, 0.42, d / 2), StyleKit.mat(wood.lightened(0.05)), true, 0.006)
		StyleKit.sphere(n, 0.016, Vector3(x + (0.1 if i % 2 == 0 else -0.1), 0.45, d / 2 + 0.02), StyleKit.mat(StyleKit.BRASS, 0.8))
	# Kokböcker liggande i en trave, och en inramad bild av familjen.
	var colors := [Color(0.9, 0.45, 0.35), Color(0.4, 0.6, 0.45), Color(0.95, 0.85, 0.55)]
	for i in 3:
		StyleKit.box(n, Vector3(0.24, 0.035, 0.18), Vector3(-w / 2 + 0.22, 0.8 + i * 0.036, 0), StyleKit.mat(colors[i])).rotation_degrees.y = -6 + i * 5
	var frame := StyleKit.box(n, Vector3(0.2, 0.26, 0.025), Vector3(w * 0.1, 0.92, -d * 0.2), StyleKit.mat(StyleKit.WALNUT))
	frame.rotation_degrees.x = -10
	var photo := StyleKit.box(n, Vector3(0.15, 0.2, 0.005), Vector3(w * 0.1, 0.92, -d * 0.2 + 0.016), StyleKit.mat(Color(0.85, 0.78, 0.66)), true, 0.0)
	photo.rotation_degrees.x = -10
	StyleKit.cylinder(n, 0.06, 0.08, 0.06, Vector3(w / 2 - 0.2, 0.81, 0), StyleKit.mat(StyleKit.TERRACOTTA))
	StyleKit.sphere(n, 0.08, Vector3(w / 2 - 0.2, 0.9, 0), StyleKit.mat(StyleKit.LEAF))


## Stålhylla i källaren: fyra plan med backar, burkar och kartonger.
static func _metal_shelf(n: Node3D, w: float, d: float) -> void:
	var steel := StyleKit.mat(StyleKit.METAL.darkened(0.15), 0.4)
	for x in [-w / 2 + 0.02, w / 2 - 0.02]:
		for z in [-d / 2 + 0.02, d / 2 - 0.02]:
			StyleKit.box(n, Vector3(0.03, 1.8, 0.03), Vector3(x, 0.9, z), steel)
	var bins := [Color(0.35, 0.55, 0.85), Color(0.95, 0.75, 0.3), Color(0.5, 0.75, 0.5), Color(0.85, 0.65, 0.42)]
	for row in 4:
		var y := 0.15 + row * 0.5
		StyleKit.box(n, Vector3(w, 0.025, d), Vector3(0, y, 0), StyleKit.mat(StyleKit.METAL, 0.4))
		var count := maxi(1, int(w / 0.42))
		for i in count:
			var x := -w / 2 + w * (i + 0.5) / count
			if (row + i) % 3 == 2:
				# Färgburkar och flaskor i stället för en back.
				for k in 2:
					StyleKit.cylinder(n, 0.06, 0.06, 0.14, Vector3(x - 0.07 + k * 0.14, y + 0.08, 0), StyleKit.mat(bins[(row + k) % bins.size()].lightened(0.2), 0.4))
				continue
			StyleKit.box(n, Vector3(w / count - 0.06, 0.24, d * 0.8), Vector3(x, y + 0.135, 0), StyleKit.mat(bins[(row * 2 + i) % bins.size()]))


## Låg hylla i allrummet med sällskapsspel och fotoramar ovanpå.
static func _games_shelf(n: Node3D, w: float, d: float) -> void:
	StyleKit.box(n, Vector3(w, 0.85, d), Vector3(0, 0.425, 0), StyleKit.mat(StyleKit.WHITE))
	StyleKit.box(n, Vector3(w - 0.06, 0.34, 0.02), Vector3(0, 0.25, d / 2 - 0.01), StyleKit.mat(StyleKit.WHITE.darkened(0.2)), true, 0.0)
	StyleKit.box(n, Vector3(w - 0.06, 0.34, 0.02), Vector3(0, 0.63, d / 2 - 0.01), StyleKit.mat(StyleKit.WHITE.darkened(0.2)), true, 0.0)
	var boxes := [Color(0.9, 0.35, 0.35), Color(0.3, 0.55, 0.85), Color(0.95, 0.8, 0.3), Color(0.45, 0.7, 0.45), Color(0.6, 0.45, 0.75)]
	for row in 2:
		var y := 0.1 + row * 0.38
		for i in 4:
			var h := 0.06 + (i % 2) * 0.03
			StyleKit.box(n, Vector3(0.3, h, d * 0.8), Vector3(-w / 2 + 0.25 + i * 0.32, y + h / 2 + (i % 3) * 0.07, 0.0), StyleKit.mat(boxes[(i + row * 2) % boxes.size()]))
	for i in 3:
		var x := -w / 2 + 0.3 + i * (w - 0.6) / 2
		var frame := StyleKit.box(n, Vector3(0.18, 0.22, 0.025), Vector3(x, 0.97, -d * 0.15), StyleKit.mat(StyleKit.WALNUT if i != 1 else StyleKit.WHITE.darkened(0.1)))
		frame.rotation_degrees.x = -10


## Mammans hylla med målargrejer: burkar med penslar, färgtuber, rullat papper och dukar.
static func _art_shelf(n: Node3D, w: float, d: float) -> void:
	var h := 1.5
	StyleKit.box(n, Vector3(w, h, d), Vector3(0, h / 2, 0), StyleKit.mat(StyleKit.WHITE.darkened(0.04)))
	var paints := [Color(0.9, 0.35, 0.35), Color(0.35, 0.55, 0.9), Color(0.95, 0.8, 0.3), Color(0.45, 0.75, 0.45)]
	for row in 3:
		var y := 0.2 + row * 0.45
		StyleKit.box(n, Vector3(w - 0.06, 0.36, 0.02), Vector3(0, y + 0.18, d / 2 - 0.01), StyleKit.mat(StyleKit.WHITE.darkened(0.18)), true, 0.0)
		for i in 3:
			var x := -w / 2 + 0.15 + i * (w - 0.3) / 2
			match (row + i) % 3:
				0:
					StyleKit.cylinder(n, 0.05, 0.05, 0.12, Vector3(x, y + 0.08, 0), StyleKit.mat(Color(0.85, 0.9, 0.92), 0.6))
					for k in 3:
						StyleKit.cylinder(n, 0.006, 0.006, 0.2, Vector3(x - 0.02 + k * 0.02, y + 0.18, 0), StyleKit.mat(StyleKit.OAK)).rotation_degrees.z = -10 + k * 10
				1:
					for k in 3:
						StyleKit.box(n, Vector3(0.12, 0.025, 0.03), Vector3(x, y + 0.015 + k * 0.026, -0.04 + k * 0.04), StyleKit.mat(paints[(row + k) % paints.size()], 0.5))
				_:
					StyleKit.cylinder(n, 0.035, 0.035, d * 0.8, Vector3(x, y + 0.04, 0), StyleKit.mat(Color(0.97, 0.95, 0.9))).rotation_degrees.x = 90
	# Två dukar lutade mot hyllans sida.
	for i in 2:
		var canvas := StyleKit.box(n, Vector3(0.03, 0.5 - i * 0.1, 0.4 - i * 0.08), Vector3(w / 2 + 0.04 + i * 0.03, 0.25 - i * 0.05, 0.05), StyleKit.mat(StyleKit.WHITE))
		canvas.rotation_degrees.z = -8


## Hög krukväxt (fikonlyra) i vit kruka.
static func _tall_plant(n: Node3D, w: float, d: float) -> void:
	var r := minf(w, d) * 0.32
	StyleKit.cylinder(n, r, r * 0.8, r * 1.8, Vector3(0, r * 0.9, 0), StyleKit.mat(StyleKit.WHITE, 0.3))
	StyleKit.cylinder(n, 0.02, 0.03, 1.2, Vector3(0, r * 1.8 + 0.6, 0), StyleKit.mat(StyleKit.WALNUT))
	for i in 9:
		var angle := TAU * i / 9.0 + i * 0.4
		var leaf := StyleKit.sphere(n, 0.14, Vector3(cos(angle) * 0.15, r * 1.8 + 0.5 + i * 0.1, sin(angle) * 0.15), StyleKit.mat(StyleKit.LEAF.darkened(0.08 * (i % 2))))
		leaf.scale = Vector3(1.0, 0.45, 0.75)
		leaf.rotation = Vector3(0.3, angle, 0)


## Bred kruka med sommarblommor (vid trappan ute och på uteplatsen).
static func _planter(n: Node3D, w: float, d: float) -> void:
	var r := minf(w, d) * 0.45
	StyleKit.cylinder(n, r, r * 0.8, 0.4, Vector3(0, 0.2, 0), StyleKit.mat(StyleKit.TERRACOTTA, 0.0, 7, 0.1))
	StyleKit.cylinder(n, r * 0.92, r * 0.92, 0.02, Vector3(0, 0.39, 0), StyleKit.mat(Color(0.4, 0.3, 0.22)))
	var flowers := [Color(0.95, 0.55, 0.6), Color(0.98, 0.88, 0.45), Color(0.78, 0.66, 0.92), Color(0.98, 0.97, 0.95)]
	for i in 7:
		var angle := TAU * i / 7.0
		var at := Vector3(cos(angle) * r * 0.55, 0.5 + (i % 2) * 0.06, sin(angle) * r * 0.55)
		StyleKit.sphere(n, r * 0.35, at, StyleKit.mat(StyleKit.LEAF.lightened(0.05 * (i % 3))))
		StyleKit.sphere(n, r * 0.16, at + Vector3(0, r * 0.3, 0), StyleKit.mat(flowers[i % flowers.size()]))
	StyleKit.sphere(n, r * 0.4, Vector3(0, 0.62, 0), StyleKit.mat(StyleKit.LEAF.lightened(0.1)))


## Mammans rättningshögar på skrivbordet: prov i två högar, röd penna och ett äpple.
static func _graded_tests(n: Node3D, w: float, d: float) -> void:
	for pile in 2:
		var x := -w / 2 + 0.22 + pile * 0.3
		for i in 5 - pile * 2:
			var paper := StyleKit.box(n, Vector3(0.21, 0.01, 0.28), Vector3(x, 0.79 + i * 0.011, 0.08), StyleKit.mat(StyleKit.WHITE), true, 0.0)
			paper.rotation_degrees.y = -5 + i * 4 + pile * 8
	StyleKit.box(n, Vector3(0.13, 0.012, 0.012), Vector3(-w / 2 + 0.55, 0.83, 0.2), StyleKit.mat(Color(0.9, 0.2, 0.2), 0.5)).rotation_degrees.y = 35
	StyleKit.sphere(n, 0.045, Vector3(w / 2 - 0.45, 0.82, 0.18), StyleKit.mat(Color(0.85, 0.25, 0.25), 0.6))


## Vitt skrivbord med uppfälld laptop och en mugg (sovrummet).
static func _white_desk(n: Node3D, w: float, d: float) -> void:
	var white := StyleKit.mat(StyleKit.WHITE)
	StyleKit.box(n, Vector3(w, 0.04, d), Vector3(0, 0.74, 0), white)
	for s in [-1, 1]:
		for z in [-1, 1]:
			StyleKit.cylinder(n, 0.018, 0.015, 0.72, Vector3(s * (w / 2 - 0.06), 0.36, z * (d / 2 - 0.06)), StyleKit.mat(StyleKit.BRASS, 0.6), 10)
	StyleKit.box(n, Vector3(0.34, 0.015, 0.24), Vector3(0, 0.77, 0.06), StyleKit.mat(Color(0.82, 0.8, 0.86), 0.4))
	var screen := StyleKit.box(n, Vector3(0.34, 0.22, 0.012), Vector3(0, 0.88, -0.07), StyleKit.mat(Color(0.82, 0.8, 0.86), 0.4))
	screen.rotation_degrees.x = -12
	StyleKit.cylinder(n, 0.04, 0.035, 0.09, Vector3(w / 2 - 0.15, 0.81, 0.08), StyleKit.mat(Color(0.95, 0.75, 0.7), 0.5))


## Kontorsstol med fem ben och hjul.
static func _office_chair(n: Node3D) -> void:
	var black := StyleKit.mat(Color(0.22, 0.22, 0.26), 0.3)
	for i in 5:
		var angle := TAU * i / 5.0
		var leg := StyleKit.box(n, Vector3(0.04, 0.03, 0.26), Vector3(cos(angle) * 0.12, 0.05, sin(angle) * 0.12), black)
		leg.rotation.y = -angle + PI / 2
	StyleKit.cylinder(n, 0.025, 0.025, 0.35, Vector3(0, 0.23, 0), StyleKit.mat(StyleKit.METAL, 0.7), 10)
	StyleKit.box(n, Vector3(0.46, 0.08, 0.44), Vector3(0, 0.45, 0.02), StyleKit.mat(Color(0.35, 0.42, 0.5)), true, 0.03)
	StyleKit.box(n, Vector3(0.44, 0.5, 0.07), Vector3(0, 0.78, -0.2), StyleKit.mat(Color(0.35, 0.42, 0.5)), true, 0.03)


## Vit stol med grå dyna (sovrummets skrivbord).
static func _white_chair(n: Node3D) -> void:
	var white := StyleKit.mat(StyleKit.WHITE)
	StyleKit.box(n, Vector3(0.42, 0.04, 0.42), Vector3(0, 0.45, 0), white)
	StyleKit.box(n, Vector3(0.36, 0.04, 0.36), Vector3(0, 0.49, 0), StyleKit.mat(Color(0.78, 0.78, 0.8)))
	for corner in [Vector2(-0.18, -0.18), Vector2(0.18, -0.18), Vector2(-0.18, 0.18), Vector2(0.18, 0.18)]:
		StyleKit.cylinder(n, 0.018, 0.015, 0.45, Vector3(corner.x, 0.225, corner.y), StyleKit.mat(StyleKit.BRASS, 0.6), 8)
	StyleKit.box(n, Vector3(0.42, 0.18, 0.04), Vector3(0, 0.82, -0.19), white)


## Handfat i en kommod. Mot en låg innervägg finns ingen spegel (den skulle sväva);
## `double` ger två handfat.
static func _basin(n: Node3D, w: float, d: float, double: bool) -> void:
	StyleKit.box(n, Vector3(w, 0.8, d), Vector3(0, 0.4, 0), StyleKit.mat(StyleKit.OAK))
	var drawers := 2 if double else 1
	for i in drawers:
		var x := -w / 2 + w * (i + 0.5) / drawers
		StyleKit.box(n, Vector3(w / drawers - 0.04, 0.6, 0.02), Vector3(x, 0.4, d / 2), StyleKit.mat(StyleKit.OAK.lightened(0.06)), true, 0.006)
	StyleKit.box(n, Vector3(w + 0.04, 0.05, d + 0.02), Vector3(0, 0.825, 0), StyleKit.mat(StyleKit.WHITE, 0.4))
	var bowls := 2 if double else 1
	for i in bowls:
		var x := 0.0 if bowls == 1 else (-w / 4 if i == 0 else w / 4)
		StyleKit.cylinder(n, minf(w / bowls, d) * 0.32, minf(w / bowls, d) * 0.28, 0.02, Vector3(x, 0.855, 0.02), StyleKit.mat(Color(0.82, 0.88, 0.92), 0.6))
		StyleKit.cylinder(n, 0.015, 0.015, 0.2, Vector3(x, 0.95, -d / 2 + 0.05), StyleKit.mat(StyleKit.METAL, 0.9))
	# Tandborstmugg och tvål.
	StyleKit.cylinder(n, 0.035, 0.03, 0.1, Vector3(0.0 if double else w / 2 - 0.1, 0.9, -d / 2 + 0.1), StyleKit.mat(Color(0.55, 0.8, 0.85), 0.5))
	StyleKit.box(n, Vector3(0.08, 0.03, 0.05), Vector3(-w / 2 + 0.1, 0.865, -d / 2 + 0.1), StyleKit.mat(Color(0.95, 0.85, 0.7)))


## Torktumlare bredvid tvättmaskinen: samma låda, mörkare lucka och ett luddfilter.
static func _dryer(n: Node3D, w: float, d: float) -> void:
	StyleKit.box(n, Vector3(w - 0.02, 0.85, d - 0.02), Vector3(0, 0.425, 0), StyleKit.mat(StyleKit.WHITE, 0.4))
	StyleKit.cylinder(n, 0.21, 0.21, 0.03, Vector3(0, 0.42, d / 2), StyleKit.mat(StyleKit.DARK.lightened(0.15), 0.6)).rotation_degrees = Vector3(90, 0, 0)
	StyleKit.cylinder(n, 0.16, 0.16, 0.035, Vector3(0, 0.42, d / 2 + 0.005), StyleKit.mat(Color(0.3, 0.32, 0.36), 0.8)).rotation_degrees = Vector3(90, 0, 0)
	StyleKit.box(n, Vector3(w - 0.08, 0.08, 0.02), Vector3(0, 0.77, d / 2 - 0.005), StyleKit.mat(StyleKit.WHITE.darkened(0.08)))
	StyleKit.cylinder(n, 0.025, 0.025, 0.02, Vector3(w * 0.3, 0.77, d / 2 + 0.01), StyleKit.mat(Color(0.95, 0.5, 0.3), 0.6)).rotation_degrees = Vector3(90, 0, 0)


# --- Nya saker ------------------------------------------------------------------

## Bygger en av hemmets egna typer lokalt (bredd w längs x, djup d längs z, framsidan mot +z).
static func build(n: Node3D, rig: TimeOfDayRig, kind: String, w: float, d: float, style := "") -> void:
	match kind:
		"coat_stand":
			_coat_stand(n)
		"console":
			_console(n, w, d)
		"floor_lamp":
			_floor_lamp(n, rig)
		"side_table":
			_side_table(n, w, d, style)
		"ironing_board":
			_ironing_board(n, w, d)
		"cradle":
			_cradle(n, w, d)
		"driveway":
			StyleKit.box(n, Vector3(w, 0.03, d), Vector3(0, 0.015, 0), StyleKit.mat(Color(0.58, 0.57, 0.56), 0.0, 1, 0.5, Color(0.48, 0.47, 0.46)), true, 0.0)
		"patio":
			StyleKit.box(n, Vector3(w, 0.05, d), Vector3(0, 0.025, 0), StyleKit.mat(Color(0.8, 0.76, 0.7), 0.0, 1, 0.6, Color(0.68, 0.64, 0.58)), true, 0.0)
		"flower_bed":
			_flower_bed(n, w, d)
		"grill":
			_grill(n)
		"veg_bed":
			_veg_bed(n, w, d)
		"clothesline":
			_clothesline(n, w, d)
		"sun_lounger":
			_sun_lounger(n, w, d, tint(style, Color(0.45, 0.65, 0.85)))
		"shed":
			_shed(n, w, d)


## Hallens klädhängare: familjens jackor i deras färger och hundens koppel på en krok.
static func _coat_stand(n: Node3D) -> void:
	var wood := StyleKit.mat(StyleKit.WALNUT, 0.2)
	StyleKit.cylinder(n, 0.2, 0.22, 0.04, Vector3(0, 0.02, 0), wood)
	StyleKit.cylinder(n, 0.025, 0.03, 1.8, Vector3(0, 0.92, 0), wood, 10)
	StyleKit.sphere(n, 0.04, Vector3(0, 1.84, 0), wood)
	# Mammans kappa, pappans jacka och sönernas huvtröja och collegejacka.
	var coats := [[0.0, Color(0.82, 0.5, 0.38)], [PI / 2, Color(0.25, 0.32, 0.5)], [PI, Color(0.42, 0.36, 0.62)], [PI * 1.5, Color(0.8, 0.28, 0.3)]]
	for coat in coats:
		var angle: float = coat[0]
		var dir := Vector3(cos(angle), 0, sin(angle))
		StyleKit.box(n, Vector3(0.12, 0.02, 0.02), dir * 0.06 + Vector3(0, 1.7, 0), wood).rotation.y = -angle
		var body := StyleKit.box(n, Vector3(0.3, 0.7, 0.1), dir * 0.13 + Vector3(0, 1.33, 0), StyleKit.mat(coat[1]), true, 0.03)
		body.rotation.y = -angle + PI / 2
		body.rotation.z = 0.05
	# Kopplet: en röd rem som hänger ned och en hoprullad bit.
	StyleKit.box(n, Vector3(0.02, 0.5, 0.012), Vector3(0.0, 1.38, -0.05), StyleKit.mat(Color(0.88, 0.25, 0.28)))
	StyleKit.cylinder(n, 0.05, 0.05, 0.02, Vector3(0.0, 1.12, -0.05), StyleKit.mat(Color(0.88, 0.25, 0.28))).rotation_degrees.x = 90


## Smal byrå i hallen: skål med nycklar, posten (en räkning i rött kuvert) och mammans
## skolväska lutad mot benet.
static func _console(n: Node3D, w: float, d: float) -> void:
	var wood := StyleKit.WALNUT.lightened(0.18)
	StyleKit.box(n, Vector3(w, 0.04, d), Vector3(0, 0.8, 0), StyleKit.mat(wood, 0.2))
	StyleKit.box(n, Vector3(w - 0.08, 0.14, d - 0.04), Vector3(0, 0.71, 0), StyleKit.mat(wood.darkened(0.06)))
	StyleKit.box(n, Vector3(w - 0.12, 0.02, d - 0.06), Vector3(0, 0.15, 0), StyleKit.mat(wood.darkened(0.06)))
	for s in [-1, 1]:
		for z in [-1, 1]:
			StyleKit.box(n, Vector3(0.035, 0.78, 0.035), Vector3(s * (w / 2 - 0.04), 0.39, z * (d / 2 - 0.04)), StyleKit.mat(wood.darkened(0.12)))
	StyleKit.cylinder(n, 0.1, 0.06, 0.05, Vector3(-w * 0.25, 0.845, 0), StyleKit.mat(Color(0.55, 0.72, 0.75), 0.5))
	for i in 2:
		StyleKit.box(n, Vector3(0.06, 0.008, 0.02), Vector3(-w * 0.25 - 0.02 + i * 0.04, 0.87, -0.01 + i * 0.02), StyleKit.mat(StyleKit.BRASS, 0.8)).rotation_degrees.y = 30 + i * 50
	for i in 3:
		var letter := StyleKit.box(n, Vector3(0.22, 0.006, 0.12), Vector3(w * 0.18, 0.825 + i * 0.007, 0), StyleKit.mat(Color(0.95, 0.4, 0.38) if i == 2 else StyleKit.WHITE), true, 0.0)
		letter.rotation_degrees.y = -8 + i * 7
	var bag := StyleKit.box(n, Vector3(0.36, 0.3, 0.12), Vector3(w / 2 - 0.25, 0.15, d / 2 + 0.05), StyleKit.mat(Color(0.62, 0.45, 0.35)))
	bag.rotation_degrees = Vector3(-10, 15, 0)
	StyleKit.box(n, Vector3(0.3, 0.05, 0.13), Vector3(w / 2 - 0.25, 0.32, d / 2 + 0.03), StyleKit.mat(Color(0.95, 0.95, 0.92))).rotation_degrees = Vector3(-10, 15, 0)


## Golvlampa med tygskärm som tänds på kvällen (läsplatserna).
static func _floor_lamp(n: Node3D, rig: TimeOfDayRig) -> void:
	var brass := StyleKit.mat(StyleKit.BRASS, 0.6)
	StyleKit.cylinder(n, 0.14, 0.15, 0.03, Vector3(0, 0.015, 0), brass)
	StyleKit.cylinder(n, 0.012, 0.012, 1.4, Vector3(0, 0.72, 0), brass, 8)
	var shade := StyleKit.own_mat(Color(0.97, 0.92, 0.8))
	shade.set_shader_parameter("emission", Color(1.0, 0.82, 0.55))
	StyleKit.cylinder(n, 0.13, 0.19, 0.24, Vector3(0, 1.5, 0), shade).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	FurnitureKit._lamp_light(n, rig, Vector3(0, 1.3, 0.1), 2.6, 0.7, shade)


## Litet sidobord: med en bok och en mugg, eller (stil "paints") mammans färger och palett.
static func _side_table(n: Node3D, w: float, d: float, style: String) -> void:
	var wood := StyleKit.mat(StyleKit.OAK.lightened(0.05), 0.2)
	if style == "paints":
		FurnitureKit._table(n, w, d, 0.7, StyleKit.WHITE.darkened(0.05))
		var palette := StyleKit.cylinder(n, 0.13, 0.13, 0.012, Vector3(-w * 0.15, 0.735, 0.02), StyleKit.mat(StyleKit.OAK.lightened(0.15)))
		palette.scale = Vector3(1.3, 1, 1)
		var paints := [Color(0.9, 0.35, 0.35), Color(0.35, 0.55, 0.9), Color(0.95, 0.8, 0.3), Color(0.45, 0.75, 0.45), StyleKit.WHITE]
		for i in paints.size():
			StyleKit.sphere(n, 0.022, Vector3(-w * 0.15 + cos(i * 1.2) * 0.09, 0.745, 0.02 + sin(i * 1.2) * 0.07), StyleKit.mat(paints[i], 0.4)).scale = Vector3(1, 0.4, 1)
		StyleKit.cylinder(n, 0.045, 0.045, 0.12, Vector3(w * 0.25, 0.78, -d * 0.2), StyleKit.mat(Color(0.8, 0.88, 0.92), 0.7))
		for k in 3:
			StyleKit.cylinder(n, 0.006, 0.006, 0.22, Vector3(w * 0.25 - 0.015 + k * 0.015, 0.88, -d * 0.2), StyleKit.mat(StyleKit.OAK)).rotation_degrees.z = -12 + k * 12
		return
	var r := minf(w, d) / 2
	StyleKit.cylinder(n, r, r, 0.03, Vector3(0, 0.55, 0), wood)
	StyleKit.cylinder(n, 0.025, 0.03, 0.54, Vector3(0, 0.27, 0), wood, 10)
	StyleKit.cylinder(n, r * 0.6, r * 0.7, 0.03, Vector3(0, 0.015, 0), wood)
	StyleKit.box(n, Vector3(0.16, 0.03, 0.22), Vector3(-r * 0.25, 0.58, 0), StyleKit.mat(Color(0.35, 0.5, 0.7))).rotation_degrees.y = 15
	FurnitureKit._mug(n, Vector3(r * 0.4, 0.565, 0.05), Color(0.95, 0.85, 0.4))


## Strykbräda med strykjärn och en hög vikta kläder.
static func _ironing_board(n: Node3D, w: float, d: float) -> void:
	var top := StyleKit.box(n, Vector3(w, 0.03, d * 0.9), Vector3(0, 0.88, 0), StyleKit.mat(Color(0.75, 0.85, 0.92), 0.0, 1, 0.08, Color(0.62, 0.75, 0.85)), true, 0.04)
	top.scale = Vector3(1, 1, 1)
	for s in [-1, 1]:
		var leg := StyleKit.box(n, Vector3(0.025, 1.0, 0.025), Vector3(s * 0.1, 0.44, 0), StyleKit.mat(StyleKit.METAL, 0.6))
		leg.rotation_degrees.z = s * 22
	StyleKit.box(n, Vector3(0.22, 0.08, 0.11), Vector3(w * 0.3, 0.94, 0), StyleKit.mat(Color(0.95, 0.95, 0.96), 0.6), true, 0.03)
	StyleKit.box(n, Vector3(0.1, 0.04, 0.03), Vector3(w * 0.3, 1.0, 0), StyleKit.mat(Color(0.35, 0.65, 0.85), 0.5))
	var clothes := [Color(0.95, 0.95, 0.92), Color(0.4, 0.5, 0.7), Color(0.85, 0.4, 0.4)]
	for i in 3:
		StyleKit.box(n, Vector3(0.3, 0.04, 0.24), Vector3(-w * 0.25, 0.92 + i * 0.04, 0), StyleKit.mat(clothes[i]), true, 0.015)


## Vaggan sönerna sov i som bebisar, med en filt och en nalle.
static func _cradle(n: Node3D, w: float, d: float) -> void:
	var wood := StyleKit.mat(StyleKit.OAK.lightened(0.08), 0.2)
	StyleKit.box(n, Vector3(w, 0.32, d), Vector3(0, 0.36, 0), wood, true, 0.03)
	StyleKit.box(n, Vector3(w - 0.06, 0.3, d - 0.06), Vector3(0, 0.39, 0), StyleKit.mat(Color(0.95, 0.92, 0.85)))
	for s in [-1, 1]:
		var rocker := StyleKit.cylinder(n, d * 0.6, d * 0.6, 0.04, Vector3(s * (w / 2 - 0.08), 0.18, 0), wood, 24)
		rocker.rotation_degrees.z = 90
		rocker.scale = Vector3(1, 1, 0.5)
	StyleKit.box(n, Vector3(w * 0.5, 0.05, d * 0.7), Vector3(w * 0.1, 0.56, 0), StyleKit.mat(Color(0.7, 0.82, 0.92)), true, 0.02)
	var bear := Color(0.72, 0.52, 0.36)
	StyleKit.sphere(n, 0.07, Vector3(-w * 0.25, 0.6, 0), StyleKit.mat(bear))
	StyleKit.sphere(n, 0.05, Vector3(-w * 0.25, 0.7, 0), StyleKit.mat(bear))
	for s in [-1, 1]:
		StyleKit.sphere(n, 0.018, Vector3(-w * 0.25 + s * 0.035, 0.75, 0), StyleKit.mat(bear.darkened(0.15)))


## Rabatt längs fasaden: jordkant med tuvor och blommor i några färger.
static func _flower_bed(n: Node3D, w: float, d: float) -> void:
	StyleKit.box(n, Vector3(w, 0.1, d), Vector3(0, 0.05, 0), StyleKit.mat(Color(0.5, 0.38, 0.3), 0.0, 7, 0.2), true, 0.0)
	var flowers := [Color(0.9, 0.56, 0.6), Color(0.98, 0.86, 0.48), Color(0.76, 0.66, 0.9), Color(0.98, 0.96, 0.94)]
	var count := maxi(2, int(w / 0.3))
	for i in count:
		var x := -w / 2 + w * (i + 0.5) / count
		var z := sin(i * 2.3) * d * 0.2
		StyleKit.sphere(n, 0.13, Vector3(x, 0.18, z), StyleKit.mat(StyleKit.LEAF.lightened(0.05 * (i % 3))))
		StyleKit.sphere(n, 0.065, Vector3(x + 0.03, 0.3, z), StyleKit.mat(flowers[i % flowers.size()]))


## Klotgrill på tre ben, med en tång på sidobordet (pappans sommargrill).
static func _grill(n: Node3D) -> void:
	var black := StyleKit.mat(Color(0.18, 0.18, 0.2), 0.5)
	for i in 3:
		var angle := TAU * i / 3.0
		var leg := StyleKit.box(n, Vector3(0.03, 0.75, 0.03), Vector3(cos(angle) * 0.16, 0.37, sin(angle) * 0.16), StyleKit.mat(StyleKit.METAL, 0.6))
		leg.rotation = Vector3(sin(angle) * 0.2, 0, -cos(angle) * 0.2)
	var bowl := StyleKit.sphere(n, 0.28, Vector3(0, 0.78, 0), black)
	bowl.scale = Vector3(1, 0.8, 1)
	StyleKit.cylinder(n, 0.03, 0.03, 0.05, Vector3(0, 1.02, 0), StyleKit.mat(StyleKit.METAL, 0.8), 10)
	StyleKit.box(n, Vector3(0.3, 0.02, 0.22), Vector3(0.38, 0.72, 0), StyleKit.mat(StyleKit.OAK))
	StyleKit.box(n, Vector3(0.24, 0.015, 0.025), Vector3(0.38, 0.74, 0.03), StyleKit.mat(StyleKit.METAL, 0.8)).rotation_degrees.y = 10


## Pallkrage med grönsaker: salladshuvuden och tomatplantor vid käppar med röda tomater.
static func _veg_bed(n: Node3D, w: float, d: float) -> void:
	var wood := StyleKit.mat(StyleKit.OAK.darkened(0.15), 0.0, 6, 0.12)
	StyleKit.box(n, Vector3(w, 0.35, d), Vector3(0, 0.175, 0), wood, true, 0.0)
	StyleKit.box(n, Vector3(w - 0.08, 0.02, d - 0.08), Vector3(0, 0.34, 0), StyleKit.mat(Color(0.42, 0.32, 0.25), 0.0, 7, 0.1), true, 0.0)
	var long_x := w >= d
	var length := w if long_x else d
	var count := maxi(2, int(length / 0.35))
	for i in count:
		var t := -length / 2 + length * (i + 0.5) / count
		for row in [-1, 1]:
			var at := Vector3(t, 0.4, row * minf(w, d) * 0.22) if long_x else Vector3(row * minf(w, d) * 0.22, 0.4, t)
			if row < 0:
				StyleKit.sphere(n, 0.09, at, StyleKit.mat(Color(0.55, 0.78, 0.4)))
			elif i % 2 == 0:
				StyleKit.cylinder(n, 0.008, 0.008, 0.6, at + Vector3(0, 0.25, 0), StyleKit.mat(StyleKit.OAK), 6)
				StyleKit.sphere(n, 0.1, at + Vector3(0, 0.15, 0), StyleKit.mat(StyleKit.LEAF))
				StyleKit.sphere(n, 0.035, at + Vector3(0.06, 0.18, 0.04), StyleKit.mat(Color(0.9, 0.25, 0.2), 0.5))


## Klädstreck mellan två stolpar med tvätt på, och en korg med klädnypor.
static func _clothesline(n: Node3D, w: float, d: float) -> void:
	var post := StyleKit.mat(StyleKit.WHITE.darkened(0.08))
	var span := maxf(w, d) - 0.2
	var long_x := w >= d
	for s in [-1, 1]:
		var at := Vector3(s * span / 2, 0, 0) if long_x else Vector3(0, 0, s * span / 2)
		StyleKit.box(n, Vector3(0.06, 1.8, 0.06), at + Vector3(0, 0.9, 0), post)
		StyleKit.box(n, Vector3(0.05, 0.05, 0.6) if long_x else Vector3(0.6, 0.05, 0.05), at + Vector3(0, 1.75, 0), post)
	var clothes := [Color(0.95, 0.95, 0.92), Color(0.45, 0.6, 0.85), Color(0.95, 0.6, 0.55), Color(0.42, 0.36, 0.62), Color(0.8, 0.28, 0.3)]
	for line in [-0.22, 0.22]:
		var offset := Vector3(0, 0, line) if long_x else Vector3(line, 0, 0)
		StyleKit.box(n, (Vector3(span, 0.01, 0.01) if long_x else Vector3(0.01, 0.01, span)), offset + Vector3(0, 1.73, 0), StyleKit.mat(StyleKit.WHITE), false, 0.0)
		var count := int(span / 0.5)
		for i in count:
			if (i + int(line * 10)) % 3 == 2:
				continue
			var t := -span / 2 + span * (i + 0.5) / count
			var along := Vector3(t, 0, 0) if long_x else Vector3(0, 0, t)
			var size := Vector3(0.36, 0.45 - (i % 2) * 0.12, 0.015) if long_x else Vector3(0.015, 0.45 - (i % 2) * 0.12, 0.36)
			StyleKit.box(n, size, along + offset + Vector3(0, 1.72 - size.y / 2, 0), StyleKit.mat(clothes[(i * 2 + int(line * 10)) % clothes.size()]), true, 0.0)
	StyleKit.cylinder(n, 0.16, 0.13, 0.22, Vector3(span * 0.25 if long_x else 0.3, 0.11, 0.35 if long_x else span * 0.25), StyleKit.mat(Color(0.85, 0.65, 0.4)))


## Solstol med dyna och uppfällt ryggstöd mot -z.
static func _sun_lounger(n: Node3D, w: float, d: float, cushion: Color) -> void:
	var wood := StyleKit.mat(StyleKit.OAK.darkened(0.05), 0.2)
	StyleKit.box(n, Vector3(w, 0.06, d), Vector3(0, 0.28, 0), wood)
	for s in [-1, 1]:
		for z in [-1, 1]:
			StyleKit.box(n, Vector3(0.05, 0.26, 0.05), Vector3(s * (w / 2 - 0.05), 0.13, z * (d / 2 - 0.08)), wood)
	StyleKit.box(n, Vector3(w - 0.06, 0.06, d * 0.62), Vector3(0, 0.34, d * 0.17), StyleKit.mat(cushion, 0.0, 5, 0.12, cushion.lightened(0.3)), true, 0.02)
	var back := StyleKit.box(n, Vector3(w - 0.06, 0.06, d * 0.4), Vector3(0, 0.5, -d * 0.28), StyleKit.mat(cushion, 0.0, 5, 0.12, cushion.lightened(0.3)), true, 0.02)
	back.rotation_degrees.x = 38
	StyleKit.box(n, Vector3(w * 0.6, 0.08, 0.16), Vector3(0, 0.6, -d * 0.36), StyleKit.mat(StyleKit.WHITE), true, 0.03).rotation_degrees.x = 38


## Ett litet trädgårdsförråd med panel, sadeltak, dörr och fönster (trädgårdsredskap).
static func _shed(n: Node3D, w: float, d: float) -> void:
	var walls := StyleKit.mat(Color(0.6, 0.72, 0.62), 0.0, 6, 0.15, Color(0.5, 0.62, 0.52))
	var h := 1.9
	StyleKit.box(n, Vector3(w, h, d), Vector3(0, h / 2, 0), walls, true, 0.0)
	Surroundings._gable(n, Rect2(-w / 2, -d / 2, w, d), h, Surroundings.ROOF, walls)
	StyleKit.box(n, Vector3(0.8, 1.7, 0.04), Vector3(-w * 0.15, 0.85, d / 2 + 0.01), StyleKit.mat(Color(0.95, 0.94, 0.9)), true, 0.0)
	StyleKit.box(n, Vector3(0.66, 1.56, 0.04), Vector3(-w * 0.15, 0.82, d / 2 + 0.02), StyleKit.mat(Color(0.45, 0.58, 0.48)), true, 0.0)
	StyleKit.sphere(n, 0.03, Vector3(-w * 0.15 + 0.24, 0.85, d / 2 + 0.05), StyleKit.mat(StyleKit.BRASS, 0.8))
	StyleKit.box(n, Vector3(0.5, 0.4, 0.04), Vector3(w * 0.28, 1.3, d / 2 + 0.01), StyleKit.mat(StyleKit.WHITE), true, 0.0)
	StyleKit.box(n, Vector3(0.42, 0.32, 0.04), Vector3(w * 0.28, 1.3, d / 2 + 0.02), StyleKit.mat(Surroundings.GLASS, 0.6), true, 0.0)
	# En kratta lutad mot väggen.
	StyleKit.box(n, Vector3(0.03, 1.4, 0.03), Vector3(w / 2 - 0.12, 0.7, d / 2 + 0.08), StyleKit.mat(StyleKit.OAK)).rotation_degrees.z = 8
	StyleKit.box(n, Vector3(0.3, 0.04, 0.04), Vector3(w / 2 - 0.02, 1.4, d / 2 + 0.08), StyleKit.mat(StyleKit.DARK))


# --- Planritningen ----------------------------------------------------------------

## Symbol ovanifrån för en av hemmets egna typer.
static func draw_symbol(canvas: CanvasItem, kind: String, r: Rect2) -> void:
	var line := FloorPlanArt.LINE
	match kind:
		"coat_stand":
			canvas.draw_circle(r.get_center(), minf(r.size.x, r.size.y) * 0.45, Color(0.62, 0.45, 0.4))
			canvas.draw_circle(r.get_center(), minf(r.size.x, r.size.y) * 0.12, FloorPlanArt.WOOD.darkened(0.3))
		"console":
			FloorPlanArt._box(canvas, r, FloorPlanArt.WOOD.lightened(0.15))
			canvas.draw_circle(r.position + r.size * Vector2(0.5, 0.3), minf(r.size.x, r.size.y) * 0.2, Color(0.55, 0.72, 0.75))
		"floor_lamp":
			canvas.draw_circle(r.get_center(), minf(r.size.x, r.size.y) * 0.45, Color(0.98, 0.9, 0.62))
			canvas.draw_arc(r.get_center(), minf(r.size.x, r.size.y) * 0.45, 0, TAU, 20, line, 1.0)
		"side_table":
			canvas.draw_circle(r.get_center(), minf(r.size.x, r.size.y) * 0.45, FloorPlanArt.WOOD.lightened(0.2))
			canvas.draw_arc(r.get_center(), minf(r.size.x, r.size.y) * 0.45, 0, TAU, 20, line, 1.0)
		"ironing_board":
			FloorPlanArt._ellipse(canvas, r.get_center(), r.size / 2, Color(0.75, 0.85, 0.92), true)
		"cradle":
			FloorPlanArt._box(canvas, r, FloorPlanArt.OAK, 6.0)
			FloorPlanArt._box(canvas, r.grow(-3), Color(0.7, 0.82, 0.92), 4.0)
		"driveway":
			canvas.draw_rect(r, Color(0.72, 0.71, 0.7))
		"patio":
			canvas.draw_rect(r, Color(0.86, 0.82, 0.76))
			FloorPlanArt._grid(canvas, r, 12.0, Color(0.76, 0.72, 0.66))
		"flower_bed":
			FloorPlanArt._box(canvas, r, Color(0.6, 0.45, 0.35))
			for i in int(r.size.x / 10):
				canvas.draw_circle(r.position + Vector2(5 + i * 10, r.size.y / 2), 3, [Color(0.9, 0.56, 0.6), Color(0.98, 0.86, 0.48)][i % 2])
		"grill":
			canvas.draw_circle(r.get_center(), minf(r.size.x, r.size.y) * 0.4, Color(0.25, 0.25, 0.28))
		"veg_bed":
			FloorPlanArt._box(canvas, r, Color(0.55, 0.42, 0.3))
			FloorPlanArt._box(canvas, r.grow(-3), Color(0.5, 0.65, 0.38))
		"clothesline":
			canvas.draw_line(r.position + Vector2(0, r.size.y / 2), r.end - Vector2(0, r.size.y / 2), line, 1.5)
			canvas.draw_line(r.position + Vector2(r.size.x / 2, 0), r.end - Vector2(r.size.x / 2, 0), line, 1.5)
		"sun_lounger":
			FloorPlanArt._box(canvas, r, Color(0.45, 0.65, 0.85), 4.0)
		"shed":
			FloorPlanArt._box(canvas, r, Color(0.6, 0.72, 0.62))
			canvas.draw_line(r.position + Vector2(0, r.size.y / 2), r.end - Vector2(0, r.size.y / 2), line, 1.0)
