class_name PlanDrawer
extends RefCounted
## Ritar husets planritning ovanifrån på en CanvasItem: golv (målade bilder eller
## kodritade), möbler, väggar, fönster, dörrar och trappor. Samma ritning används av
## kartan och av rumsvyn, så att rummen alltid stämmer med planen.
##
## Målade rum läses från res://Assets/plan_rooms/<room_id>.(png|webp|jpg). Bilden ska
## täcka rummet plus PAINT_MARGIN meter runt om (det tools/room_crops.gd klipper ut).

const FLOORS := ["Vind", "Övervåning", "Entréplan", "Källare", "Utanför"]
## Rummens planlösning per våning: Rect2(x österut, y söderut, bredd, djup) i meter.
const FLOOR_PLANS := {
	# Omgjort igen 2026-10-26 efter verkliga villaritningar: huset är 12,8 × 8,8 m (113 m²
	# per plan, som en rymlig tvåplansvilla) i stället för 15,6 × 10, där fem rum inte kunde
	# fylla ytan utan att bli orimligt stora. Gatan ligger i norr och trädgården i söder.
	#   Entréplanet: köket mot gatan (som i klassiska svenska villor), kontoret mot
	#     trädgården, hallen i mitten med trappan och gäst-wc:t längst in, och ett
	#     genomgående vardagsrum i öster med fönsterdörrar ut till uteplatsen.
	#   Övervåningen: sönernas rum över köket och kontoret, trapphallen som allrum,
	#     badrummet över gäst-wc:t (våtrummen staplade) och sovrummet över vardagsrummet.
	#   Källaren: bara under den norra delen (6,6 m djup), södra delen står på platta.
	# Hallarna ligger rakt ovanför varandra (x 5,6–9,0), så att trappan (samma ruta på alla
	# plan, längs hallens östra vägg) går rakt upp och ned.
	"Vind": {
		"attic": Rect2(1.0, 1.4, 10.8, 6.0),
	},
	"Övervåning": {
		"son_room_1": Rect2(0, 0, 4.4, 4.4),
		"son_room_2": Rect2(0, 4.4, 4.4, 4.4),
		"upstairs_hall": Rect2(4.4, 0, 4.6, 5.6),
		"bathroom": Rect2(4.4, 5.6, 4.6, 3.2),
		"bedroom": Rect2(9.0, 0, 3.8, 8.8),
	},
	"Entréplan": {
		"kitchen": Rect2(0, 0, 5.6, 5.4),
		"home_office": Rect2(0, 5.4, 5.6, 3.4),
		"hall": Rect2(5.6, 0, 3.4, 6.6),
		"guest_wc": Rect2(5.6, 6.6, 3.4, 2.2),
		"living_room": Rect2(9.0, 0, 3.8, 8.8),
	},
	"Källare": {
		"laundry": Rect2(0, 0, 5.6, 4.0),
		"storage": Rect2(0, 4.0, 5.6, 2.6),
		"basement_hall": Rect2(5.6, 0, 3.4, 6.6),
		"hobby_room": Rect2(9.0, 0, 3.8, 6.6),
	},
	# Tomten runt huset, i husets koordinater (tomten är 20 m bred, huset står mitt på):
	# framsidan mot gatan i norr och trädgården i söder. Sidorna (3,6 m) hör inte till
	# något rum; där går uppfarten och stigen runt huset (Surroundings).
	"Utanför": {
		"outside": Rect2(-3.6, -7.0, 20.0, 7.0),
		"backyard": Rect2(-3.6, 8.8, 20.0, 7.6),
	},
	# Platserna i grannskapet (Locations). De visas inte bland husets våningsknappar.
	"Skolan": {
		"classroom": Rect2(0, 0, 6, 4.5),
		"teachers_lounge": Rect2(6, 0, 3.5, 4.5),
	},
	"Grannen": {
		"neighbor_living": Rect2(0, 0, 5.5, 4.5),
	},
	# Gymmet (24 × 15 m): en öppen träningshall med entré och reception i nordväst (dörren
	# mot parkeringen), konditionsmaskiner under fönsterbandet i norr, fria vikter i väster,
	# maskiner i mitten, stretchyta och en gräslinje i söder. I öster gruppträningssalen
	# och omklädningsrummet, med dörrar från hallen och mellan varandra.
	"Gymmet": {
		"gym": Rect2(0, 0, 16.5, 15.0),
		"yoga_studio": Rect2(16.5, 0, 7.5, 8.5),
		"locker_room": Rect2(16.5, 8.5, 7.5, 6.5),
	},
	# Köpcentret (omgjort 2026-10-26), 32 × 15 m som ett riktigt "dumbbell"-köpcentrum:
	# ankarbutiker i båda ändar (livsmedel i väster, kläder i öster) som drar folk längs
	# en gång med mindre butiker emellan. Mitt på ligger en ljusgård med fontän, rakt
	# innanför huvudingången från parkeringen i norr. Butikerna har en bred front var mot
	# gången; inga butiker har dörrar till varandra.
	"Köpcentret": {
		"grocery": Rect2(0, 0, 8.0, 15.0),
		"restaurant": Rect2(8.0, 0, 5.0, 6.0),
		"entrance": Rect2(13.0, 0, 6.0, 2.5),
		"salon": Rect2(19.0, 0, 5.0, 6.0),
		"boutique": Rect2(24.0, 0, 8.0, 15.0),
		"west_promenade": Rect2(8.0, 6.0, 5.0, 4.0),
		"center_court": Rect2(13.0, 2.5, 6.0, 12.5),
		"east_promenade": Rect2(19.0, 6.0, 5.0, 4.0),
		"cafe": Rect2(8.0, 10.0, 5.0, 5.0),
		"bookstore": Rect2(19.0, 10.0, 5.0, 5.0),
	},
	"Parken": {
		"park": Rect2(0, 0, 9, 5.5),
	},
}
## Våningarnas namn som spelaren ser (nycklarna ovan är interna).
const FLOOR_LABELS := {"Vind": "Attic", "Övervåning": "Upstairs", "Entréplan": "Ground Floor", "Källare": "Basement", "Utanför": "Outside",
		"Skolan": "School", "Grannen": "Neighbor's House", "Gymmet": "Fitness Center", "Köpcentret": "Shopping Center", "Parken": "Park"}
## Ytterdörrar: rum -> vilken yttervägg dörren sitter i.
const FRONT_DOORS := {"hall": "north", "entrance": "north", "gym": "north"}
## Gångar i en plats (köpcentrets gångar och entré). Mellan två gångar är väggen nästan
## helt öppen, och en butik har en bred butiksfront (STOREFRONT_WIDTH) mot gången i
## stället för en vanlig dörr. Ytterdörren från en gång är lika bred.
const CONCOURSE := ["entrance", "center_court", "west_promenade", "east_promenade"]
const STOREFRONT_WIDTH := 2.4
## Var ytterdörrens mitt sitter längs väggen (meter från väggens början). Saknas rummet
## här sitter dörren mitt på väggen. Hallens dörr sitter till vänster om trappan, gymmets
## vid receptionen.
const FRONT_DOOR_OFFSETS := {"hall": 0.75, "gym": 2.0}
## Dörrar ut till trädgården (utöver ytterdörrarna): rum -> [vägg, dörrens mitt längs
## väggen (meter från väggens början), bredd, rummet ute]. Köket har en sidodörr vid
## hundens bädd ut till stigen längs huset, vardagsrummet fönsterdörrar mot uteplatsen.
const GARDEN_DOORS := {
	"kitchen": ["west", 4.4, 0.9, "backyard"],
	"living_room": ["south", 1.5, 1.6, "backyard"],
}
## Dörrar som inte sitter mitt på den gemensamma väggen, för att en trappa står i vägen:
## "rum_a/rum_b" (i bokstavsordning) -> dörrens mitt i meter från väggbitens västra eller
## norra ände.
const DOOR_POSITIONS := {
	"hall/living_room": 4.4,
	"bedroom/upstairs_hall": 4.3,
	"basement_hall/hobby_room": 4.4,
}
## Trappor med en vilplan (U-trappa): bredare än så här i meter ritas som två lopp.
const U_STAIR_MIN_WIDTH := 1.6
## Vilplanets djup i en U-trappa (meter), längst in mot norr.
const STAIR_LANDING := 1.0
const PAINTED_DIR := "res://Assets/plan_rooms/"
const IMAGE_EXTENSIONS := ["png", "webp", "jpg"]
## Marginalen runt rummet i en målad rumsbild, i meter.
const PAINT_MARGIN := 0.126
const DOOR_WIDTH := 0.9
const MARKER_RADIUS := 13.0

const PAPER := Color(0.96, 0.93, 0.88)
const GRID := Color(0.9, 0.85, 0.78)
const CURRENT_FILL := Color(0.97, 0.84, 0.55)
const WALL := Color(0.38, 0.25, 0.16)
const TEXT := Color(0.33, 0.22, 0.14)

var canvas: CanvasItem
var floor_name := "Entréplan"
## Pixlar per meter och var planens nollpunkt hamnar på skärmen.
var meter := 60.0
var origin := Vector2.ZERO
## Bara själva planen, utan målade rum och utan markeringar: underlag för bildgenerering.
var export_mode := false
var show_grid := true
var show_labels := true
var show_markers := true
var current_room := ""
var hover_room := ""
## Om satt tonas allt utanför det här rummet ned (rumsvyn).
var focus_room := ""

static var _label_font: Font
static var _paper_texture: Texture2D
static var _painted := {}


func _init(target: CanvasItem) -> void:
	canvas = target
	if _label_font == null:
		var font := SystemFont.new()
		font.font_names = PackedStringArray(["Nunito", "Quicksand", "Segoe UI Semibold", "Segoe UI"])
		font.font_weight = 600
		_label_font = font
		# Diskret papperstextur av brus.
		var noise := FastNoiseLite.new()
		noise.frequency = 0.06
		noise.fractal_octaves = 4
		_paper_texture = ImageTexture.create_from_image(noise.get_seamless_image(256, 256))


static func floor_of(room_id: String) -> String:
	for name in FLOOR_PLANS:
		if FLOOR_PLANS[name].has(room_id):
			return name
	return ""


static func plan_of(room_id: String) -> Rect2:
	var name := floor_of(room_id)
	return FLOOR_PLANS[name][room_id] if name != "" else Rect2()


## Den målade bilden av ett rum, eller null om det inte finns någon.
static func painted(room_id: String) -> Texture2D:
	if not _painted.has(room_id):
		_painted[room_id] = null
		for extension in IMAGE_EXTENSIONS:
			var path := "%s%s.%s" % [PAINTED_DIR, room_id, extension]
			if ResourceLoader.exists(path):
				_painted[room_id] = load(path)
				break
	return _painted[room_id]


## Skalar och placerar planen så att `plan_rect` (meter) får plats mitt i `area`.
func fit(area: Rect2, plan_rect: Rect2, max_meter := INF) -> void:
	meter = minf(max_meter, minf(area.size.x / plan_rect.size.x, area.size.y / plan_rect.size.y))
	origin = area.get_center() - plan_rect.get_center() * meter


func plans() -> Dictionary:
	return FLOOR_PLANS[floor_name]


func screen(point: Vector2) -> Vector2:
	return origin + point * meter


func screen_rect(plan: Rect2) -> Rect2:
	return Rect2(screen(plan.position), plan.size * meter)


func outer_plan() -> Rect2:
	var outer := Rect2()
	var first := true
	for room_id in plans():
		outer = plans()[room_id] if first else outer.merge(plans()[room_id])
		first = false
	return outer


func room_at(point: Vector2) -> String:
	for room_id in plans():
		if screen_rect(plans()[room_id]).has_point(point):
			return room_id
	return ""


# --- Ritning ------------------------------------------------------------------

func draw(area: Rect2) -> void:
	canvas.draw_rect(area, PAPER)
	canvas.draw_texture_rect(_paper_texture, area, true, Color(0.55, 0.42, 0.3, 0.07))
	if show_grid and not export_mode:
		_draw_grid(area)
	# Mjuk skugga under huset, så att det lyfter från papperet.
	for room_id in plans():
		var rect := screen_rect(plans()[room_id])
		for i in 3:
			canvas.draw_rect(Rect2(rect.position + Vector2(4 + i * 3, 6 + i * 3), rect.size), Color(0.3, 0.2, 0.12, 0.06))
	for room_id in plans():
		var plan: Rect2 = plans()[room_id]
		var rect := screen_rect(plan)
		var texture: Texture2D = null
		if not export_mode:
			texture = painted(room_id)
		if texture != null and not _painting_fits(texture, plan):
			texture = null  # Målad för en äldre planlösning; ritas i kod tills den målas om.
		if texture != null:
			_draw_painted(texture, plan)
		else:
			FloorPlanArt.draw_floor(canvas, room_id, rect, meter)
			FloorPlanArt.draw_furniture(canvas, room_id, rect.position, meter)
		FloorPlanArt.draw_inner_shadow(canvas, rect)
		if export_mode:
			continue
		if room_id == current_room:
			canvas.draw_rect(rect, Color(CURRENT_FILL, 0.22))
			canvas.draw_rect(rect.grow(-6), Color(CURRENT_FILL.darkened(0.15), 0.9), false, 3.0)
		elif room_id == hover_room:
			canvas.draw_rect(rect, Color(1, 1, 1, 0.28))
	for room_id in plans():
		_draw_walls(room_id)
	for room_id in plans():
		_draw_windows(room_id)
		_draw_doors(room_id)
		_draw_stairs(room_id)
	if focus_room != "":
		_dim_outside(area, screen_rect(plans()[focus_room]).grow(6))
	if export_mode:
		return
	for room_id in plans():
		if show_labels:
			_draw_room_name(room_id)
		if show_markers:
			_draw_room_markers(room_id)


## Den målade bilden täcker rummet plus marginalen; bara själva rummet visas.
func _draw_painted(texture: Texture2D, plan: Rect2) -> void:
	var crop := plan.grow(PAINT_MARGIN)
	var size := texture.get_size()
	var source := Rect2((plan.position - crop.position) / crop.size * size, plan.size / crop.size * size)
	canvas.draw_texture_rect_region(texture, screen_rect(plan), source)


## Om en målad bild har samma proportioner som rummet (plus marginalen).
func _painting_fits(texture: Texture2D, plan: Rect2) -> bool:
	var crop := plan.grow(PAINT_MARGIN)
	var size := texture.get_size()
	return absf(size.x / size.y - crop.size.x / crop.size.y) < 0.05 * crop.size.x / crop.size.y


func _dim_outside(area: Rect2, keep: Rect2) -> void:
	keep = keep.intersection(area)
	var veil := Color(PAPER, 0.6)
	for part in [
		Rect2(area.position, Vector2(area.size.x, keep.position.y - area.position.y)),
		Rect2(Vector2(area.position.x, keep.end.y), Vector2(area.size.x, area.end.y - keep.end.y)),
		Rect2(Vector2(area.position.x, keep.position.y), Vector2(keep.position.x - area.position.x, keep.size.y)),
		Rect2(Vector2(keep.end.x, keep.position.y), Vector2(area.end.x - keep.end.x, keep.size.y)),
	]:
		if part.size.x > 0 and part.size.y > 0:
			canvas.draw_rect(part, veil)


## Svagt rutnät på en meter, som på millimeterpapper.
func _draw_grid(area: Rect2) -> void:
	var start := origin - Vector2(30, 30) * meter
	for i in 60:
		var x := start.x + i * meter
		if x >= area.position.x and x <= area.end.x:
			canvas.draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), GRID, 1.0)
		var y := start.y + i * meter
		if y >= area.position.y and y <= area.end.y:
			canvas.draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), GRID, 1.0)


## Innerväggar tunt, ytterväggar (där det inte finns något rum på andra sidan) tjockt.
func _draw_walls(room_id: String) -> void:
	var plan: Rect2 = plans()[room_id]
	var corners := [plan.position, Vector2(plan.end.x, plan.position.y), plan.end, Vector2(plan.position.x, plan.end.y)]
	var thickness := clampf(meter / 7.0, 5.0, 16.0)
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var outward := (b - a).normalized().orthogonal() * 0.05
		var steps := maxi(1, int(a.distance_to(b) / 0.1))
		for s in steps:
			var p0 := a.lerp(b, float(s) / steps)
			var p1 := a.lerp(b, float(s + 1) / steps)
			var outside := not _plan_has_point((p0 + p1) / 2 + outward)
			canvas.draw_line(screen(p0), screen(p1), WALL, thickness if outside else thickness / 2)
			# Ljusare mittlinje i ytterväggarna, som på en arkitektritning.
			if outside:
				canvas.draw_line(screen(p0), screen(p1), WALL.lightened(0.35), thickness / 5)


## Fönster i ytterväggarna: en ljus öppning med två tunna glaslinjer.
func _draw_windows(room_id: String) -> void:
	var plan: Rect2 = plans()[room_id]
	var thickness := clampf(meter / 7.0, 5.0, 16.0)
	for window in FloorPlanArt.windows(room_id):
		var a := _wall_point(plan, window["side"], window["start"])
		var along := _wall_direction(window["side"])
		var p0 := screen(a)
		var p1 := screen(a + along * float(window["width"]))
		var normal := along.orthogonal()
		canvas.draw_line(p0, p1, Color(0.97, 0.98, 1.0), thickness)
		for offset in [-thickness / 4, thickness / 4]:
			canvas.draw_line(p0 + normal * offset, p1 + normal * offset, Color(0.55, 0.72, 0.85), 1.5)
		for end in [p0, p1]:
			canvas.draw_line(end - normal * thickness / 2, end + normal * thickness / 2, WALL, 2.0)


## Dörröppningar mot grannrum som rummet har en dörr till, och eventuell ytterdörr.
func _draw_doors(room_id: String) -> void:
	var plan: Rect2 = plans()[room_id]
	for target in _exits_of(room_id):
		if not plans().has(target) or target < room_id:
			continue  # Bara på samma våning, och varje dörr ritas en gång.
		var shared := shared_edge(plan, plans()[target])
		if not shared.is_empty():
			_draw_door_gap(shared[0], shared[1], door_width(room_id, target, shared[0].distance_to(shared[1])), door_middle(room_id, target, shared[0], shared[1]))
	for door in exterior_doors(room_id):
		var edge := exterior_door_edge(room_id, door)
		_draw_door_gap(edge[0], edge[1], door["width"], (edge[0] + edge[1]) / 2, "Out" if door["front"] else "Garden")


## En öppning kring `middle` på väggbiten a-b. Vanliga dörrar får en dörrbåge som visar
## åt vilket håll de slår; breda öppningar (butiksfronter, gångar) är bara öppna.
## Ytterdörrar får en etikett (`label`) utanför.
func _draw_door_gap(a: Vector2, b: Vector2, width: float, middle: Vector2, label := "") -> void:
	var is_front_door := label != ""
	var along := (b - a).normalized()
	var d0 := middle - along * width / 2
	var d1 := middle + along * width / 2
	var thickness := clampf(meter / 7.0, 5.0, 16.0)
	canvas.draw_line(screen(d0), screen(d1), FloorPlanArt.OAK if not is_front_door else PAPER, thickness + 1)
	if width <= DOOR_WIDTH + 0.01:
		var hinge := screen(d0)
		var radius := width * meter
		var start_angle := along.angle()
		canvas.draw_arc(hinge, radius, start_angle, start_angle + PI / 2, 24, Color(WALL, 0.6), 1.5, true)
		canvas.draw_line(hinge, hinge + Vector2.from_angle(start_angle + PI / 2) * radius, Color(WALL, 0.8), 2.0)
	if is_front_door and not export_mode:
		var label_pos := screen(middle) + along.orthogonal() * (thickness + 14) + Vector2(-10, 5)
		canvas.draw_string(_label_font, label_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, TEXT)


## Trappsymbol med pilar i rum som har trappor upp eller ned.
func _draw_stairs(room_id: String) -> void:
	var directions := stair_directions(room_id)
	if directions.is_empty():
		return
	if stairs_plan(room_id).size.x >= U_STAIR_MIN_WIDTH:
		_draw_u_stairs(room_id, directions)
		return
	var stair := screen_rect(stairs_plan(room_id))
	canvas.draw_rect(stair, FloorPlanArt.WOOD.lightened(0.25))
	for i in 9:
		var y := stair.position.y + stair.size.y * i / 8.0
		canvas.draw_line(Vector2(stair.position.x, y), Vector2(stair.end.x, y), Color(WALL, 0.6), 1.5)
	canvas.draw_rect(stair, Color(WALL, 0.8), false, 1.5)
	if export_mode:
		return
	# Pilar upp och/eller ned, i små brickor ovanpå trappan (upp överst).
	for i in directions.size():
		var up: bool = directions[i]
		var center := stair.get_center() + Vector2(0, (i - (directions.size() - 1) / 2.0) * 28)
		canvas.draw_circle(center + Vector2(0, 1.5), 12, Color(0, 0, 0, 0.15))
		canvas.draw_circle(center, 12, Color(PAPER, 0.95))
		canvas.draw_arc(center, 12, 0, TAU, 24, Color(WALL, 0.6), 1.5, true)
		var dir := -1.0 if up else 1.0
		canvas.draw_colored_polygon(PackedVector2Array([
			center + Vector2(0, 6 * dir), center + Vector2(-6, -4 * dir), center + Vector2(6, -4 * dir)]), WALL)


## En U-trappa som på en arkitektritning: första loppet på den öppna sidan stiger mot
## norr till vilplanet längst in, andra loppet vänder tillbaka mot söder. Steglinjer,
## en mittvägg och en gånglinje med pil åt det håll trappan leder upp (eller ned på
## våningen ovanför, där man kommer upp ur andra loppet). Leder trappan också ned
## (entréplanet) står "DN" vid källardörren under andra loppets höga ände.
func _draw_u_stairs(room_id: String, directions: Array) -> void:
	var halves := stair_halves(room_id)
	var first := screen_rect(halves[0])
	var second := screen_rect(halves[1])
	var stair := first.merge(second)
	var landing := STAIR_LANDING * meter
	var steps := 6
	var run := (stair.size.y - landing) / steps
	canvas.draw_rect(stair, FloorPlanArt.WOOD.lightened(0.25))
	canvas.draw_rect(Rect2(stair.position, Vector2(stair.size.x, landing)), FloorPlanArt.WOOD.lightened(0.18))
	for flight in [first, second]:
		for i in steps:
			var y: float = flight.end.y - run * i
			canvas.draw_line(Vector2(flight.position.x, y), Vector2(flight.end.x, y), Color(WALL, 0.6), 1.5)
	canvas.draw_line(Vector2(stair.position.x, stair.position.y + landing), Vector2(stair.end.x, stair.position.y + landing), Color(WALL, 0.6), 1.5)
	# Mittväggen mellan loppen.
	var middle := (first.get_center().x + second.get_center().x) / 2
	canvas.draw_line(Vector2(middle, stair.position.y + landing), Vector2(middle, stair.end.y), WALL, 3.0)
	canvas.draw_rect(stair, Color(WALL, 0.8), false, 1.5)
	if export_mode:
		return
	# Finns en vindsstege i rummet går vägen upp via den, och trappan leder bara ned.
	var has_ladder := FloorPlanArt.furniture_rect(room_id, "attic_ladder").size != Vector2.ZERO
	var up: bool = directions[0] and not has_ladder
	var path := PackedVector2Array([
		Vector2(first.get_center().x, first.end.y - run * 0.4),
		Vector2(first.get_center().x, stair.position.y + landing * 0.5),
		Vector2(second.get_center().x, stair.position.y + landing * 0.5),
		Vector2(second.get_center().x, second.end.y - run * 0.4)])
	if not up:
		path.reverse()
	canvas.draw_polyline(path, WALL, 2.0, true)
	canvas.draw_circle(path[0], 4, WALL)
	var tip := path[path.size() - 1]
	var dir := (tip - path[path.size() - 2]).normalized()
	canvas.draw_colored_polygon(PackedVector2Array([tip + dir * 8, tip - dir * 4 + dir.orthogonal() * 6, tip - dir * 4 - dir.orthogonal() * 6]), WALL)
	var label_at := path[0] + Vector2(-12, 22) if up else tip + Vector2(-12, 26)
	canvas.draw_string(_label_font, label_at, "UP" if up else "DN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, TEXT)
	if up and directions.size() > 1:
		canvas.draw_string(_label_font, Vector2(second.get_center().x - 12, second.end.y + 18), "DN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, TEXT)


## Rummets namn på en ljus etikett, så att det syns ovanpå golv och möbler.
func _draw_room_name(room_id: String) -> void:
	var font := _label_font
	var rect := screen_rect(plans()[room_id])
	var text: String = GameState.ROOMS[room_id]["name"]
	var is_current := room_id == current_room
	var font_size := 17
	while font_size > 11 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > rect.size.x - 28:
		font_size -= 1
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var height := font.get_height(font_size) + (14 if is_current else 0)
	var label := Rect2(rect.get_center() - Vector2(width / 2 + 12, height / 2 + 14), Vector2(width + 24, height + 8))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PAPER, 0.88) if not is_current else Color(CURRENT_FILL.lightened(0.35), 0.95)
	style.border_color = Color(WALL, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.12)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	canvas.draw_style_box(style, label)
	canvas.draw_string(font, label.position + Vector2(12, 4 + font.get_ascent(font_size)), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT)
	if is_current:
		var here := "You are here"
		var here_width := font.get_string_size(here, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		canvas.draw_string(font, Vector2(label.get_center().x - here_width / 2, label.end.y - 7), here,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(TEXT, 0.75))


func _draw_room_markers(room_id: String) -> void:
	var font := ThemeDB.fallback_font
	var present := GameState.get_characters_in(room_id)
	var rect := screen_rect(plans()[room_id])
	var start := rect.get_center() + Vector2(-(present.size() - 1) * 15.0, 34)
	for i in present.size():
		var info: Dictionary = GameState.CHARACTERS[present[i]]
		var center := start + Vector2(i * 30, 0)
		canvas.draw_circle(center + Vector2(0, 2), MARKER_RADIUS, Color(0, 0, 0, 0.2))
		canvas.draw_circle(center, MARKER_RADIUS, info["color"])
		canvas.draw_arc(center, MARKER_RADIUS - 1, 0, TAU, 32, Color.WHITE, 2.0, true)
		var initials := GameState.character_initials(present[i])
		var text_width := font.get_string_size(initials, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		canvas.draw_string(font, center + Vector2(-text_width / 2, 4), initials,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)


# --- Dörrar, trappor och ytor i planen (meter) --------------------------------

## Var en utgång från rummet sitter i planen: dörröppningen mot ett grannrum, trappan
## för andra våningar eller ytterdörren. Tom Rect2 om utgången inte finns i planen.
func exit_rect(room_id: String, target: String) -> Rect2:
	var plan: Rect2 = plans()[room_id]
	if plans().has(target):
		var shared := shared_edge(plan, plans()[target])
		if not shared.is_empty():
			return _door_area(door_middle(room_id, target, shared[0], shared[1]), (shared[1] - shared[0]).normalized(), door_width(room_id, target, shared[0].distance_to(shared[1])))
		return Rect2()
	var target_floor := floor_of(target)
	if target_floor == "Utanför":
		# Dörren som leder till just det rummet ute, annars ytterdörren.
		var doors := exterior_doors(room_id).filter(func(door: Dictionary) -> bool: return door["to"] == target)
		if doors.is_empty():
			doors = exterior_doors(room_id).filter(func(door: Dictionary) -> bool: return door["front"])
		if not doors.is_empty():
			var edge := exterior_door_edge(room_id, doors[0])
			return _door_area((edge[0] + edge[1]) / 2, (edge[1] - edge[0]).normalized(), doors[0]["width"])
	var directions := stair_directions(room_id)
	if directions.is_empty() or target_floor == "Utanför" or floor_name == "Utanför":
		return Rect2()
	# Trappan delas mellan upp och ned om den går åt båda håll: i en U-trappa är första
	# loppet upp och andra loppet (med källardörren under) ned, annars övre och nedre halvan.
	var stair := stairs_plan(room_id)
	var up := FLOORS.find(target_floor) < FLOORS.find(floor_name)
	var ladder := FloorPlanArt.furniture_rect(room_id, "attic_ladder")
	if up and ladder.size != Vector2.ZERO:
		return Rect2(plan.position + ladder.position, ladder.size)
	if not (true in directions and false in directions) or ladder.size != Vector2.ZERO:
		return stair
	if stair.size.x >= U_STAIR_MIN_WIDTH:
		return stair_halves(room_id)[0 if up else 1]
	var half := Vector2(stair.size.x, stair.size.y / 2)
	return Rect2(stair.position if up else stair.position + Vector2(0, half.y), half)


## Riktningarna (sant = upp) för rummets trappor, med upp först.
func stair_directions(room_id: String) -> Array:
	var directions := []
	for target in _exits_of(room_id):
		var target_floor := floor_of(target)
		if target_floor == floor_name or target_floor == "Utanför" or floor_name == "Utanför":
			continue
		directions.append(FLOORS.find(target_floor) < FLOORS.find(floor_name))
	directions.sort_custom(func(a, b): return a and not b)
	return directions


## Trappans yta i planen: från möbleringen, annars uppe till vänster i rummet.
func stairs_plan(room_id: String) -> Rect2:
	var plan: Rect2 = plans()[room_id]
	var stair := FloorPlanArt.stairs_rect(room_id)
	if stair.size == Vector2.ZERO:
		stair = Rect2(0.2, 0.4, 0.85, plan.size.y * 0.32)
	return Rect2(plan.position + stair.position, stair.size)


## En U-trappas två lopp i planen: [första loppet (på den öppna sidan, med mest plats i
## rummet), andra loppet (mot väggen)]. Båda går hela trappans djup; vilplanet är den
## norra biten av båda.
func stair_halves(room_id: String) -> Array:
	var stair := stairs_plan(room_id)
	var half := Vector2(stair.size.x / 2, stair.size.y)
	var west := Rect2(stair.position, half)
	var east := Rect2(stair.position + Vector2(half.x, 0), half)
	return [west, east] if stair_open_side(room_id) < 0 else [east, west]


## Vilken sida av trappan som vetter mot rummet: -1 väster, 1 öster (där det är mest plats).
static func stair_open_side(room_id: String) -> float:
	var room := plan_of(room_id).size
	var rect := FloorPlanArt.stairs_rect(room_id)
	return -1.0 if rect.position.x > room.x - rect.end.x else 1.0


## Ytterdörrens öppning i planen: [a, b] längs väggen, så bred att dörren får plats.
static func front_door_edge(room_id: String) -> Array:
	var plan := plan_of(room_id)
	var side: String = FRONT_DOORS[room_id]
	var horizontal := side in ["north", "south"]
	var length := plan.size.x if horizontal else plan.size.y
	var along := Vector2.RIGHT if horizontal else Vector2.DOWN
	var start := plan.position
	if side == "south":
		start.y = plan.end.y
	elif side == "east":
		start.x = plan.end.x
	var center := start + along * front_door_offset(room_id, length)
	var width := door_width(room_id, "", length)
	return [center - along * (width / 2 + 0.1), center + along * (width / 2 + 0.1)]


## Ytterdörrens mitt längs väggen (meter från väggens början).
static func front_door_offset(room_id: String, wall_length: float) -> float:
	return FRONT_DOOR_OFFSETS.get(room_id, wall_length / 2)


## Rummets ytterdörrar (ytterdörren och dörrar ut till trädgården):
## [{side, at (mitten, meter längs väggen), width, to (rummet ute, "" = gatan/kartan), front}].
static func exterior_doors(room_id: String) -> Array[Dictionary]:
	var doors: Array[Dictionary] = []
	if FRONT_DOORS.has(room_id):
		var side: String = FRONT_DOORS[room_id]
		var plan := plan_of(room_id)
		var length := plan.size.x if side in ["north", "south"] else plan.size.y
		doors.append({"side": side, "at": front_door_offset(room_id, length), "width": door_width(room_id, "", length), "to": "", "front": true})
	if GARDEN_DOORS.has(room_id):
		var entry: Array = GARDEN_DOORS[room_id]
		doors.append({"side": entry[0], "at": entry[1], "width": entry[2], "to": entry[3], "front": false})
	return doors


## En ytterdörrs öppning i planen: [a, b] längs väggen, lite bredare än dörren.
static func exterior_door_edge(room_id: String, door: Dictionary) -> Array:
	var plan := plan_of(room_id)
	var side: String = door["side"]
	var along := Vector2.RIGHT if side in ["north", "south"] else Vector2.DOWN
	var start := plan.position
	if side == "south":
		start.y = plan.end.y
	elif side == "east":
		start.x = plan.end.x
	var center: Vector2 = start + along * float(door["at"])
	return [center - along * (door["width"] / 2 + 0.1), center + along * (door["width"] / 2 + 0.1)]


## Var dörren mellan två rum sitter på deras gemensamma väggbit a-b: mitt på, eller där
## DOOR_POSITIONS säger.
static func door_middle(room_a: String, room_b: String, a: Vector2, b: Vector2) -> Vector2:
	var key := "%s/%s" % ([room_a, room_b] if room_a < room_b else [room_b, room_a])
	if DOOR_POSITIONS.has(key):
		var start := a if (a.x < b.x or a.y < b.y) else b
		var end := b if start == a else a
		return start + (end - start).normalized() * float(DOOR_POSITIONS[key])
	return (a + b) / 2


## Hur bred öppningen mellan två rum är (room_b "" = ytterdörren), med väggbitens längd:
## en vanlig dörr, en butiksfront mot en gång eller nästan hela väggen mellan två gångar.
static func door_width(room_a: String, room_b: String, edge_length: float) -> float:
	var width := DOOR_WIDTH
	if room_a in CONCOURSE and room_b in CONCOURSE:
		width = edge_length - 0.4
	elif room_a in CONCOURSE or room_b in CONCOURSE:
		width = STOREFRONT_WIDTH
	return clampf(width, 0.3, edge_length - 0.2)


## Den gemensamma väggbiten mellan två rum som ligger kant i kant, eller [] om de inte gör det.
static func shared_edge(a: Rect2, b: Rect2) -> Array:
	const EPS := 0.01
	for pair in [[a.end.x, b.position.x], [b.end.x, a.position.x]]:
		if absf(pair[0] - pair[1]) < EPS:
			var y0 := maxf(a.position.y, b.position.y)
			var y1 := minf(a.end.y, b.end.y)
			if y1 - y0 > 0.5:
				return [Vector2(pair[0], y0), Vector2(pair[0], y1)]
	for pair in [[a.end.y, b.position.y], [b.end.y, a.position.y]]:
		if absf(pair[0] - pair[1]) < EPS:
			var x0 := maxf(a.position.x, b.position.x)
			var x1 := minf(a.end.x, b.end.x)
			if x1 - x0 > 0.5:
				return [Vector2(x0, pair[0]), Vector2(x1, pair[0])]
	return []


## En klickbar yta kring en dörr: dörrens bredd längs väggen och en dörrbredd djup över väggen.
func _door_area(middle: Vector2, along: Vector2, width := DOOR_WIDTH) -> Rect2:
	var across := along.orthogonal().abs()
	var size := along.abs() * width + across * DOOR_WIDTH
	return Rect2(middle - size / 2, size)


func _wall_edge(plan: Rect2, side: String) -> Array:
	return [_wall_point(plan, side, 0.0), _wall_point(plan, side, 0.0) + _wall_direction(side) * (
			plan.size.x if side in ["north", "south"] else plan.size.y)]


func _wall_point(plan: Rect2, side: String, offset: float) -> Vector2:
	match side:
		"north":
			return plan.position + Vector2(offset, 0)
		"south":
			return Vector2(plan.position.x + offset, plan.end.y)
		"west":
			return plan.position + Vector2(0, offset)
		_:
			return Vector2(plan.end.x, plan.position.y + offset)


func _wall_direction(side: String) -> Vector2:
	return Vector2.RIGHT if side in ["north", "south"] else Vector2.DOWN


func _plan_has_point(point: Vector2) -> bool:
	for room_id in plans():
		if plans()[room_id].has_point(point):
			return true
	return false


## Rummets dörrar. I editorn finns inget speltillstånd, så då ritas inga dörrar.
func _exits_of(room_id: String) -> Dictionary:
	if Engine.is_editor_hint():
		return {}
	return GameState.get_exits(room_id)
