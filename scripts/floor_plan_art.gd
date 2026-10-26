class_name FloorPlanArt
## Golvmaterial och möbelsymboler för planritningen ovanifrån. Allt ritas i kod i
## spelets färger, och samma bild kan exporteras som underlag för AI-generering.

## Golv per rum. Rum som saknas här får trägolv.
const FLOOR_MATERIALS := {
	"kitchen": "tile_warm",
	"guest_wc": "tile",
	"bathroom": "tile",
	"laundry": "concrete",
	"storage": "concrete",
	"basement_hall": "concrete",
	"outside": "grass",
	"backyard": "grass",
	"attic": "wood_old",
	"park": "grass",
	"gym": "vinyl",
	"yoga_studio": "maple",
	"locker_room": "tile",
	"grocery": "tile_warm",
	"classroom": "tile_warm",
	"entrance": "terrazzo",
	"center_court": "terrazzo",
	"west_promenade": "terrazzo",
	"east_promenade": "terrazzo",
	"salon": "checker",
}

## Fönster i ytterväggar: [vägg, placering, bredd i meter] och valfritt en dictionary med
## alternativ. Väggen räknas från väst till öst (norr, söder) eller från norr till söder
## (väster, öster). Placeringen är:
##   ett tal ≥ 0 – meter från väggens början
##   ett tal < 0 – räknat från väggens slut (-0.5 = slutar en halvmeter före hörnet)
##   "center"    – mitt på väggen (en rad fönster centreras som helhet)
## Alternativen (se windows()):
##   style    – fönstrets typ i WINDOW_STYLES (annars "standard")
##   curtains – "drapes" (två gardiner, standard), "single_left"/"single_right" (en gardin
##              åt ena sidan sett inifrån), "blind" (rullgardin) eller "none"
##   default  – gardinernas läge när ingen regel i Curtains gäller: "open", "half", "closed"
##   frosted  – frostat glas (badrum)
##   sill/top – egen bröstningshöjd och överkant (meter över golvet)
##   repeat/gap – en rad med `repeat` likadana fönster och `gap` meter emellan
## Höga möbler och saker på väggen ska inte stå framför fönstren (bröstningen är
## stilens "sill"); tavlor som ändå hamnar på ett fönster hoppas över i 3D.
const WINDOWS := {
	# Köket: rullgardin över diskbänken mot gatan, gardiner vid matbordet i väster (sido-
	# dörren ut till trädgården sitter längre söderut på samma vägg).
	"kitchen": [["north", 1.0, 1.2, {"curtains": "blind"}], ["west", 1.6, 1.6]],
	# Hallen: ett småspröjsat fönster över trappans vilplan, bredvid ytterdörren.
	"hall": [["north", 1.9, 1.0, {"style": "cottage", "curtains": "none"}]],
	# Vardagsrummet: ett litet fönster mot gatan bredvid tv:n, ett fönster vid fåtöljen
	# och ett stort fönster vid läshörnan mot trädgårdssidan. Fönsterdörrarna ut till
	# uteplatsen sitter i södra väggen (PlanDrawer.GARDEN_DOORS).
	"living_room": [["north", 0.25, 0.9], ["east", 1.0, 1.8], ["east", 4.6, 2.4, {"style": "picture"}]],
	"guest_wc": [["south", 1.3, 0.8, {"style": "small", "frosted": true, "curtains": "blind"}]],
	# Kontoret: skrivbordet under västra fönstret och utsikt över trädgården i söder.
	"home_office": [["west", 1.3, 1.4], ["south", 2.8, 1.6]],
	# Son 1: fönstret över gamingskrivbordet (skärmarna står framför det) och ett högt
	# fönster vid sängen.
	"son_room_1": [["north", 1.8, 1.2], ["west", 0.4, 1.3, {"style": "high"}]],
	# Son 2: skrivbordet under västra fönstret och ett fönster mot trädgården.
	"son_room_2": [["west", 2.4, 1.2], ["south", 1.6, 1.2]],
	"upstairs_hall": [["north", 3.0, 1.0, {"style": "cottage", "curtains": "none"}]],
	"bathroom": [["south", 2.4, 0.8, {"style": "small", "frosted": true, "curtains": "blind"}]],
	# Sovrummet: ett fönsterband ovanför sängen, ett fönster vid läsfåtöljen och en fransk
	# balkong mellan sminkbordet och garderoben.
	"bedroom": [["north", 0.95, 1.9, {"style": "high"}], ["east", 2.4, 1.4], ["east", 5.9, 1.1, {"style": "tall"}]],
	# Vinden: gavelfönster i väster och öster (taket har nocken längs huset) och ett
	# takfönster i norr.
	"attic": [["north", 5.0, 1.0, {"style": "small", "curtains": "none"}], ["west", 2.5, 1.0, {"style": "cottage", "curtains": "none"}], ["east", 2.5, 1.0, {"style": "cottage", "curtains": "none"}]],
	# Källaren: höga fönster mot ljusgårdarna.
	"laundry": [["north", 2.6, 0.8, {"style": "high", "curtains": "none"}], ["west", 1.4, 0.8, {"style": "high", "curtains": "none"}]],
	"storage": [["west", 0.9, 0.7, {"style": "high", "curtains": "none"}]],
	"basement_hall": [["north", 0.3, 0.8, {"style": "high", "curtains": "none"}]],
	"hobby_room": [["north", 1.0, 1.2, {"style": "high", "curtains": "blind"}], ["east", 2.2, 1.2, {"style": "high", "curtains": "none"}]],
	"classroom": [["north", 0.6, 1.4, {"repeat": 2, "gap": 1.4, "curtains": "blind"}], ["west", 1.2, 1.6, {"curtains": "blind"}]],
	"teachers_lounge": [["north", 1.0, 1.4, {"curtains": "blind"}], ["east", 1.4, 1.4, {"curtains": "blind"}]],
	"neighbor_living": [["north", 1.6, 1.6], ["west", 1.4, 1.4], ["east", 1.4, 1.4]],
	# Gymmet: skyltfönster vid entrén (på var sida om dörren), ett högt fönsterband över
	# konditionsraden (löpbandens konsoler når inte upp till det) och ett fönster vid
	# soffan i väster. Salen har fönster mot öster (norra väggen är spegel), och
	# omklädningsrummet ett frostat band högt över duscharna.
	"gym": [["north", 0.2, 1.2, {"style": "picture", "curtains": "none"}], ["north", 2.7, 1.6, {"style": "picture", "curtains": "none"}],
			["north", 5.5, 1.9, {"style": "high", "repeat": 5, "gap": 0.3, "sill": 1.4, "top": 2.3, "curtains": "none"}],
			["west", 1.2, 1.8, {"curtains": "none"}]],
	"yoga_studio": [["east", 1.0, 1.8, {"curtains": "single_left"}], ["east", 5.0, 1.8, {"curtains": "single_right"}]],
	"locker_room": [["east", 4.1, 1.8, {"style": "high", "frosted": true, "curtains": "none"}]],
	# Köpcentret: skyltfönster mot parkeringen i norr, glasade dörrar i entrén och höga
	# fönsterband i ankarbutikernas gavlar. Butikerna mot gångarna har inga ytterväggar.
	"entrance": [["north", 0.3, 1.2, {"style": "tall", "curtains": "none"}], ["north", -0.3, 1.2, {"style": "tall", "curtains": "none"}]],
	"grocery": [["north", 0.8, 2.4, {"style": "picture", "curtains": "none", "repeat": 2, "gap": 1.6}], ["west", 1.6, 1.6, {"style": "high", "curtains": "none", "repeat": 3, "gap": 3.2}]],
	"restaurant": [["north", 0.6, 1.6, {"style": "picture", "curtains": "none", "repeat": 2, "gap": 0.6}]],
	"salon": [["north", 0.3, 1.5, {"style": "picture", "curtains": "blind"}]],
	"boutique": [["north", 0.6, 2.6, {"style": "picture", "curtains": "none", "repeat": 2, "gap": 1.6}], ["east", 1.0, 1.8, {"curtains": "none"}], ["east", -1.2, 1.8, {"style": "high", "curtains": "none"}]],
}

## Fönstrens typer: bröstning och överkant (meter över golvet), rutor i bredd (0 = efter
## bredden, ungefär en ruta per 0,7 m) och i höjd, en tvärpost för fönsterdörrar och om
## gardinerna går ned till golvet.
const WINDOW_STYLES := {
	"standard": {"sill": 0.95, "top": 2.1, "columns": 0, "rows": 1},
	# Stort fönster utan spröjs, lågt, för utsiktens skull.
	"picture": {"sill": 0.55, "top": 2.2, "columns": 1, "rows": 1, "floor_curtains": true},
	# Fönsterdörr ned till golvet med tvärpost (fransk balkong).
	"tall": {"sill": 0.06, "top": 2.25, "columns": 2, "rows": 1, "transom": 1.85, "floor_curtains": true},
	# Smalt band högt upp: ovanför en säng eller ett badkar, källarfönster.
	"high": {"sill": 1.55, "top": 2.15, "columns": 0, "rows": 1},
	"small": {"sill": 1.2, "top": 1.85, "columns": 1, "rows": 1},
	# Småspröjsat, som i en äldre villa.
	"cottage": {"sill": 0.95, "top": 2.1, "columns": 2, "rows": 3},
}


## Ett rums fönster med placeringen uträknad: [{room, index, side, start, width, sill, top,
## style, curtains, default, frosted}], i ordningen i WINDOWS (en rad blir flera).
static func windows(room_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var plan := PlanDrawer.plan_of(room_id)
	for entry in WINDOWS.get(room_id, []):
		var side: String = entry[0]
		var width: float = entry[2]
		var options: Dictionary = entry[3] if entry.size() > 3 else {}
		var style_id: String = options.get("style", "standard")
		var style: Dictionary = WINDOW_STYLES[style_id]
		var count: int = options.get("repeat", 1)
		var gap: float = options.get("gap", 0.6)
		var length := plan.size.x if side in ["north", "south"] else plan.size.y
		var row := width * count + gap * (count - 1)
		var start: float
		if entry[1] is String:
			start = (length - row) / 2.0
		elif entry[1] < 0.0:
			start = length + entry[1] - row
		else:
			start = entry[1]
		for i in count:
			result.append({"room": room_id, "index": result.size(), "side": side, "start": start + i * (width + gap), "width": width,
					"sill": options.get("sill", style["sill"]), "top": options.get("top", style["top"]), "style": style_id,
					"curtains": options.get("curtains", "drapes"), "default": options.get("default", "open"), "frosted": options.get("frosted", false)})
	return result


## Om en sträcka längs en vägg (meter från väggens början) går in i ett fönster.
static func overlaps_window(room_id: String, side: String, from: float, to: float) -> bool:
	for window in windows(room_id):
		if window["side"] == side and from < window["start"] + window["width"] and to > window["start"]:
			return true
	return false

## Möbler per rum: [typ, Rect2 i meter räknat från rummets nordvästra hörn] och valfritt
## ett väderstreck som möbelns framsida pekar mot ("north", "south", "west", "east").
## Utan det ("" eller utelämnat) vänds möbeln bort från närmaste vägg (sittplatser mot
## närmaste bord). Ett fjärde element väljer en stil (HomeKit), t.ex. ["rug", Rect2(...),
## "", "sage"] eller ["shelf", Rect2(...), "", "sideboard"], så att samma typ inte ser
## likadan ut i varje rum.
const FURNITURE := {
	# Köket (5,6 × 5,4), mallen för stilen: bänk längs norrväggen med diskho och spis,
	# kylskåp i hörnet, en låg skänk med kokböcker mot hallen, matbordet mitt i rummet och
	# hundens bädd vid sidodörren ut till trädgården. Dörren till hallen är mitt på östra
	# väggen.
	"kitchen": [
		["counter", Rect2(0, 0, 3.5, 0.6)],
		["sink", Rect2(1.15, 0.08, 0.75, 0.44)],
		["stove", Rect2(2.45, 0.08, 0.57, 0.44)],
		["fridge", Rect2(3.5, 0, 0.9, 0.62)],
		["shelf", Rect2(5.18, 0.45, 0.42, 1.3), "", "sideboard"],
		["table", Rect2(1.9, 2.3, 1.8, 1.05)],
		["chair", Rect2(2.25, 1.85, 0.4, 0.35)],
		["chair", Rect2(2.95, 1.85, 0.4, 0.35)],
		["chair", Rect2(2.25, 3.45, 0.4, 0.35)],
		["chair", Rect2(2.95, 3.45, 0.4, 0.35)],
		["dog_bed", Rect2(1.2, 4.7, 0.75, 0.55)],
	],
	# Hallen (3,4 × 6,6): ytterdörren i norr till vänster, U-trappan längs östra väggen
	# (upp till övervåningen, källardörren under andra loppets höga ände). Vid dörren en
	# skohylla, klädhängaren med familjens jackor och hundens koppel och en randig löpare
	# in i huset; mellan dörrarna till köket och kontoret byrån med nycklar och post.
	# Dörrar till vardagsrummet (öster, nedanför trappan) och gäst-wc:t (söder).
	"hall": [
		["stairs", Rect2(1.3, 0.15, 2.0, 2.8), "south"],
		["shoe_rack", Rect2(0.05, 0.35, 0.32, 1.1)],
		["coat_stand", Rect2(0.08, 1.6, 0.45, 0.45)],
		["rug", Rect2(0.45, 0.25, 0.7, 2.4), "", "runner"],
		["console", Rect2(0.05, 3.55, 0.36, 1.2)],
		["rug", Rect2(0.75, 4.05, 1.9, 1.3), "", "wool"],
	],
	# Vardagsrummet (3,8 × 8,8), genomgående från gatan till trädgården: tv-hörnan i norr
	# med soffan och pappans fåtölj, en läshörna vid det stora fönstret med bokhyllan
	# och en låg skänk, och fönsterdörrarna ut till uteplatsen i söder.
	"living_room": [
		["shelf", Rect2(3.4, 3.3, 0.38, 1.25)],
		["tv", Rect2(1.3, 0.05, 2.2, 0.42)],
		["rug", Rect2(0.45, 0.85, 2.9, 2.3), "", "sage"],
		["coffee_table", Rect2(1.5, 1.45, 1.2, 0.6)],
		["sofa", Rect2(0.45, 2.55, 2.6, 0.9), "north"],
		["armchair", Rect2(2.95, 0.95, 0.8, 0.85), "west", "rust"],
		["floor_lamp", Rect2(3.38, 2.1, 0.34, 0.34)],
		["armchair", Rect2(2.95, 5.3, 0.8, 0.85), "west", "cream"],
		["side_table", Rect2(3.25, 6.3, 0.45, 0.45)],
		["shelf", Rect2(0.05, 5.4, 0.42, 1.6), "", "sideboard"],
		["rug", Rect2(1.0, 5.1, 1.9, 1.5), "", "jute"],
		["plant", Rect2(0.1, 8.15, 0.55, 0.55), "", "tall"],
	],
	# Gäst-wc:t (3,4 × 2,2): duschhörna, handfat i en kommod och toaletten mot östra
	# väggen. Dörren från hallen är mitt på norra väggen.
	"guest_wc": [
		["shower", Rect2(0.05, 0.05, 1.0, 1.0)],
		["basin", Rect2(2.3, 0.05, 0.7, 0.45)],
		["toilet", Rect2(2.75, 1.4, 0.6, 0.5)],
	],
	# Kontoret (5,6 × 3,4) mot trädgården: mammans skrivbord under västra fönstret med
	# högarna av prov hon rättar, kontorsstolen, en bokhylla med lärarböcker, en läsfåtölj
	# med golvlampa och en matta. Dörren från hallen sitter i nordöstra hörnet.
	"home_office": [
		["desk", Rect2(0.05, 1.25, 0.75, 1.6), "", "teacher"],
		["chair", Rect2(0.92, 1.8, 0.45, 0.45), "", "office"],
		["shelf", Rect2(0.05, 0.05, 0.38, 1.1)],
		["rug", Rect2(1.7, 1.0, 2.4, 1.6), "", "navy"],
		["armchair", Rect2(3.2, 0.1, 0.85, 0.8), "south", "mustard"],
		["floor_lamp", Rect2(4.2, 0.15, 0.32, 0.32)],
	],
	# Son 1 (4,4 × 4,4): nördig gamer. Gamingskrivbord med två skärmar under fönstret, tv
	# och konsol mot västra väggen med en sittsäck framför, en hylla med samlarfigurer,
	# en smal garderob och affischen över sängen.
	"son_room_1": [
		["bed", Rect2(0.1, 0.15, 1.0, 2.0), "south", "gamer"],
		["poster", Rect2(0.25, 0.05, 0.6, 0.06)],
		["gaming_desk", Rect2(1.65, 0.05, 2.0, 0.65)],
		["gaming_chair", Rect2(2.4, 0.8, 0.55, 0.55)],
		["wardrobe", Rect2(3.72, 0.05, 0.65, 0.6)],
		["rug", Rect2(0.9, 2.5, 1.8, 1.4), "", "purple"],
		["media_stand", Rect2(0.05, 3.1, 0.45, 1.0)],
		["beanbag", Rect2(1.1, 3.3, 0.65, 0.6)],
		["collectible_shelf", Rect2(3.95, 3.1, 0.4, 1.0)],
	],
	# Son 2 (4,4 × 4,4): amerikansk fotboll. Pokalhylla, bänkpress, hantlar, en matta som
	# en fotbollsplan, en sportbag med hjälm och boll, skrivbord under fönstret och en
	# affisch över sängen.
	"son_room_2": [
		["bed", Rect2(0.1, 0.15, 1.0, 2.0), "south", "team"],
		["poster", Rect2(0.05, 0.7, 0.06, 0.7)],
		["trophy_shelf", Rect2(1.5, 0.05, 1.3, 0.4)],
		["dumbbells", Rect2(3.0, 0.15, 0.55, 0.28)],
		["weight_bench", Rect2(3.6, 1.5, 0.55, 1.2)],
		["field_rug", Rect2(1.5, 1.3, 1.6, 1.1)],
		["desk", Rect2(0.05, 2.45, 0.6, 1.2)],
		["chair", Rect2(0.75, 2.8, 0.45, 0.45)],
		["football_gear", Rect2(2.2, 3.7, 0.75, 0.45)],
	],
	# Trapphallen (4,6 × 5,6), familjens allrum: trapphålet rakt ovanför hallens trappa,
	# vindsstegen mot västra väggen mellan sönernas dörrar, fotoväggen med en låg hylla
	# med sällskapsspel under, en matta och tvättkorgen vid badrummet.
	"upstairs_hall": [
		["stairs", Rect2(2.5, 0.15, 2.0, 2.8), "south"],
		["attic_ladder", Rect2(0.05, 3.0, 1.0, 0.55)],
		["photo_wall", Rect2(0.5, 0.05, 1.6, 0.06)],
		["shelf", Rect2(0.5, 0.05, 1.6, 0.4), "", "games"],
		["rug", Rect2(1.4, 3.3, 1.8, 1.4), "", "jute"],
		["basket", Rect2(3.6, 4.9, 0.55, 0.45)],
	],
	# Badrummet (4,6 × 3,2): duschhörna, badkaret längs södra väggen, dubbla handfat mot
	# hallen och toaletten mot östra väggen.
	"bathroom": [
		["bathtub", Rect2(0.1, 2.25, 1.7, 0.85)],
		["shower", Rect2(0.05, 0.05, 1.0, 1.0)],
		["basin", Rect2(2.95, 0.05, 1.4, 0.48), "", "double"],
		["toilet", Rect2(3.95, 1.5, 0.6, 0.5)],
	],
	# Föräldrarnas sovrum (3,8 × 8,8): dubbelsäng mellan nattduksbord under fönsterbandet,
	# en läsfåtölj med golvlampa vid fönstret, sminkbordet med pall, garderoben i
	# klädhörnan i söder och ett vitt skrivbord med laptop mot hallen.
	"bedroom": [
		["bed", Rect2(0.9, 0.1, 2.0, 2.1), "south", "linen"],
		["nightstand", Rect2(0.45, 0.15, 0.4, 0.4)],
		["nightstand", Rect2(2.95, 0.15, 0.4, 0.4)],
		["rug", Rect2(0.7, 2.35, 2.4, 1.5), "", "blush"],
		["armchair", Rect2(2.95, 2.5, 0.8, 0.85), "west", "blush"],
		["floor_lamp", Rect2(3.4, 3.45, 0.32, 0.32)],
		["vanity", Rect2(3.3, 4.25, 0.5, 1.1)],
		["stool", Rect2(2.75, 4.6, 0.4, 0.4)],
		["wardrobe", Rect2(3.2, 7.1, 0.6, 1.6)],
		["desk", Rect2(0.05, 5.6, 0.55, 1.3), "", "white"],
		["chair", Rect2(0.7, 6.05, 0.45, 0.45), "", "white"],
	],
	# Vinden (10,8 × 6 innanför knäväggarna): luckan över vindsstegen, kistan med
	# bröllopsalbumet, kartonger med babykläder, vaggan sönerna sov i, en gammal fåtölj
	# under ett lakan och en blekt matta.
	"attic": [
		["stairs", Rect2(3.55, 1.32, 0.8, 1.1)],
		["trunk", Rect2(5.6, 0.3, 1.1, 0.6)],
		["boxes", Rect2(8.4, 0.3, 1.6, 0.9)],
		["boxes", Rect2(9.3, 1.6, 1.1, 1.2)],
		["boxes", Rect2(0.4, 4.6, 1.2, 1.0)],
		["armchair", Rect2(1.2, 0.5, 0.8, 0.85), "south", "sheet"],
		["cradle", Rect2(7.0, 3.6, 0.9, 0.5)],
		["rug", Rect2(5.0, 2.4, 2.6, 1.6), "", "faded"],
	],
	# Tvättstugan (5,6 × 4): tvättmaskin och torktumlare, en vit bänk att vika på,
	# torkställningen, strykbrädan, tvättkorgen och en stålhylla med tvättmedel.
	"laundry": [
		["washer", Rect2(0.1, 0.1, 0.65, 0.65)],
		["washer", Rect2(0.8, 0.1, 0.65, 0.65), "", "dryer"],
		["counter", Rect2(1.55, 0.05, 1.8, 0.6), "", "utility"],
		["shelf", Rect2(0.05, 2.5, 0.38, 1.3), "", "metal"],
		["rack", Rect2(1.8, 2.0, 1.6, 0.6)],
		["ironing_board", Rect2(3.6, 2.9, 1.3, 0.4)],
		["basket", Rect2(0.6, 1.4, 0.55, 0.45)],
	],
	# Källarhallen (3,4 × 6,6): trappan upp rakt under hallens trappa, stålhyllan med
	# glödlampor och batterier och familjens cyklar.
	"basement_hall": [
		["stairs", Rect2(1.3, 0.15, 2.0, 2.8), "south"],
		["shelf", Rect2(0.05, 2.75, 0.4, 1.6), "", "metal"],
		["bike", Rect2(1.9, 5.3, 1.3, 0.55), "south", "red"],
		["bike", Rect2(1.9, 6.0, 1.3, 0.55), "south", "blue"],
	],
	# Hobbyrummet (3,8 × 6,6): mammans träningshörna (matta, löpband, hantlar) och
	# målarhörnan vid östra fönstret med staffliet, ett bord med färger och en hylla.
	"hobby_room": [
		["gym_mat", Rect2(0.4, 0.5, 1.0, 2.0)],
		["treadmill", Rect2(2.85, 0.3, 0.8, 1.6), "south"],
		["dumbbells", Rect2(0.5, 2.8, 0.6, 0.3)],
		["easel", Rect2(2.6, 2.6, 0.8, 0.6), "south"],
		["side_table", Rect2(3.1, 3.5, 0.6, 0.6), "", "paints"],
		["shelf", Rect2(3.4, 4.6, 0.38, 1.4), "", "art"],
		["rug", Rect2(0.4, 4.4, 2.0, 1.5), "", "wool"],
	],
	# Förrådet (5,6 × 2,6): stålhylla, kartonger, julpyntet och en gammal koffert.
	"storage": [
		["shelf", Rect2(0.6, 0.05, 2.4, 0.45), "", "metal"],
		["boxes", Rect2(3.3, 0.15, 1.1, 0.8)],
		["boxes", Rect2(0.3, 1.5, 1.2, 0.85)],
		["boxes", Rect2(1.8, 1.6, 1.0, 0.75), "", "holiday"],
		["trunk", Rect2(4.3, 1.6, 1.1, 0.6)],
	],
	# Framsidan (20 × 7, tomten norr om huset ned till gatan): uppfarten med familjens
	# bil vid tomtens västra kant, stenplattor från grinden till ytterdörren med krukor
	# på var sida om trappan, rabatter längs fasaden och ett träd med en bänk.
	"outside": [
		["driveway", Rect2(0.3, 0, 3.0, 6.7)],
		["car", Rect2(1.15, 2.6, 1.3, 2.6), "north"],
		["path", Rect2(9.5, 0, 0.9, 5.9)],
		["plant", Rect2(8.6, 5.85, 0.55, 0.55), "", "planter"],
		["plant", Rect2(10.8, 5.85, 0.55, 0.55), "", "planter"],
		["flower_bed", Rect2(4.2, 6.2, 4.0, 0.6)],
		["flower_bed", Rect2(12.0, 6.2, 3.8, 0.6)],
		["tree", Rect2(15.8, 1.0, 2.2, 2.2)],
		["bench", Rect2(15.9, 3.9, 1.4, 0.5), "north"],
	],
	# Trädgården (20 × 7,6, söder om huset): uteplatsen utanför vardagsrummets fönster-
	# dörrar med bord, grill och en kruka, en stig av stenplattor längs huset från sido-
	# grinden, klädstrecket utanför kontoret, mammans pallkrage, förrådet vid stigen,
	# solstolar på gräsmattan och ett äppelträd i hörnet.
	"backyard": [
		["patio", Rect2(11.6, 0, 5.4, 3.4)],
		["picnic_table", Rect2(13.2, 1.0, 1.8, 1.2)],
		["grill", Rect2(16.1, 0.4, 0.7, 0.6)],
		["plant", Rect2(11.75, 2.7, 0.55, 0.55), "", "planter"],
		["path", Rect2(2.4, 0.4, 9.2, 0.55)],
		["clothesline", Rect2(4.3, 1.4, 2.6, 0.9)],
		["veg_bed", Rect2(0.6, 3.4, 1.2, 2.8)],
		["shed", Rect2(0.2, 0.5, 2.0, 1.8), "east"],
		["sun_lounger", Rect2(7.6, 3.8, 0.7, 1.9), "south", "stripe_blue"],
		["sun_lounger", Rect2(8.7, 3.8, 0.7, 1.9), "south", "stripe_coral"],
		["tree", Rect2(18.0, 5.2, 1.8, 1.8)],
	],
	# --- Platserna i grannskapet (platshållare tills riktiga miljöer finns) ---
	# Skolan: klassrum med tavla, katedern och elevbänkar, och lärarrummet.
	"classroom": [
		["whiteboard", Rect2(0.05, 1.2, 0.06, 2.0)],
		["desk", Rect2(0.7, 1.6, 0.6, 1.3)],
		["chair", Rect2(0.25, 2.05, 0.4, 0.4)],
		["desk", Rect2(2.4, 0.9, 0.9, 0.5)],
		["desk", Rect2(3.9, 0.9, 0.9, 0.5)],
		["desk", Rect2(2.4, 2.1, 0.9, 0.5)],
		["desk", Rect2(3.9, 2.1, 0.9, 0.5)],
		["desk", Rect2(2.4, 3.3, 0.9, 0.5)],
		["desk", Rect2(3.9, 3.3, 0.9, 0.5)],
		["shelf", Rect2(5.6, 0.1, 0.35, 1.4)],
		["plant", Rect2(5.4, 3.9, 0.45, 0.45)],
	],
	"teachers_lounge": [
		["counter", Rect2(0.05, 0.0, 1.8, 0.6)],
		["table", Rect2(0.6, 1.6, 1.4, 0.9)],
		["chair", Rect2(0.85, 1.15, 0.4, 0.4)],
		["chair", Rect2(1.4, 1.15, 0.4, 0.4)],
		["sofa", Rect2(2.6, 2.0, 0.85, 1.6)],
		["plant", Rect2(2.9, 0.15, 0.45, 0.45)],
	],
	# Grannens vardagsrum: soffgrupp, bokhylla och flyttkartonger (nyinflyttad).
	"neighbor_living": [
		["shelf", Rect2(0.1, 0.1, 1.0, 0.35)],
		["tv", Rect2(3.0, 0.05, 1.6, 0.35)],
		["rug", Rect2(1.4, 1.3, 2.6, 1.8)],
		["coffee_table", Rect2(2.1, 1.85, 1.2, 0.6)],
		["sofa", Rect2(1.5, 3.2, 2.4, 0.85)],
		["armchair", Rect2(4.5, 1.6, 0.75, 0.8)],
		["boxes", Rect2(0.2, 3.3, 1.0, 0.8)],
		["plant", Rect2(4.8, 3.6, 0.45, 0.45)],
	],
	# Gymmet (16,5 × 15), uppdelat i zoner som i en riktig träningsanläggning:
	#   entré och reception i nordväst: dörrmatta, disken med personalens hylla och
	#     dryckeskyl, en soffa att vänta i, vattenautomat och spärrarna in till hallen;
	#   kondition under fönsterbandet i norr: löpband, crosstrainers, trappmaskiner och
	#     liggcyklar mot väggen, spinningcyklar, roddmaskiner och airbikes i raden bakom;
	#   fria vikter i väster på gummigolv: två rack med lyftplattformar, bänkpressar,
	#     hantelställ med spegel och justerbara bänkar, kettlebells och ryggbänk;
	#   maskiner i mitten i två rader med gångar emellan, kabelstationen mot östra väggen
	#     och boxningssäckar i hörnet;
	#   stretchyta med mattor, foamrollers och pilatesbollar;
	#   en gräslinje längs södra väggen med släde, plyolådor, battle ropes och bollar.
	# En gång löper från spärrarna österut till salen, en till omklädningsrummet. Höga
	# saker står i norr och mot sidoväggarna; i söder (mot kameran) bara låga saker.
	"gym": [
		["entry_mat", Rect2(1.45, 0.1, 1.1, 0.8)],
		["rubber_floor", Rect2(0.0, 4.6, 6.7, 7.6)],
		["turf", Rect2(0.3, 12.6, 11.2, 2.0), "north"],
		["plant", Rect2(0.25, 0.25, 0.45, 0.45)],
		["sofa", Rect2(0.1, 1.3, 0.85, 1.9)],
		["front_desk", Rect2(3.0, 1.0, 0.8, 2.2), "west"],
		["stool", Rect2(3.95, 1.9, 0.4, 0.4)],
		["merch_shelf", Rect2(4.6, 1.2, 0.4, 1.7), "west"],
		["drinks_fridge", Rect2(4.45, 0.05, 0.75, 0.62)],
		["access_gate", Rect2(1.1, 3.55, 1.9, 0.35), "south"],
		["water_fountain", Rect2(0.05, 3.5, 0.35, 0.45)],
		["treadmill", Rect2(5.6, 0.3, 0.85, 2.0)],
		["treadmill", Rect2(6.65, 0.3, 0.85, 2.0)],
		["treadmill", Rect2(7.7, 0.3, 0.85, 2.0)],
		["treadmill", Rect2(8.75, 0.3, 0.85, 2.0)],
		["elliptical", Rect2(9.85, 0.35, 0.75, 1.8)],
		["elliptical", Rect2(10.8, 0.35, 0.75, 1.8)],
		["stair_climber", Rect2(11.85, 0.35, 0.8, 1.3)],
		["stair_climber", Rect2(12.85, 0.35, 0.8, 1.3)],
		["recumbent_bike", Rect2(14.0, 0.4, 0.7, 1.6)],
		["recumbent_bike", Rect2(15.0, 0.4, 0.7, 1.6)],
		["spin_bike", Rect2(5.7, 2.85, 0.55, 1.15), "south"],
		["spin_bike", Rect2(6.5, 2.85, 0.55, 1.15), "south"],
		["spin_bike", Rect2(7.3, 2.85, 0.55, 1.15), "south"],
		["spin_bike", Rect2(8.1, 2.85, 0.55, 1.15), "south"],
		["rower", Rect2(9.2, 2.75, 2.2, 0.6), "west"],
		["rower", Rect2(9.2, 3.5, 2.2, 0.6), "west"],
		["air_bike", Rect2(11.9, 2.85, 0.65, 1.25), "south"],
		["air_bike", Rect2(12.85, 2.85, 0.65, 1.25), "south"],
		["spray_station", Rect2(13.9, 2.9, 0.35, 0.35)],
		["plant", Rect2(15.85, 2.5, 0.45, 0.45)],
		["power_rack", Rect2(0.1, 4.9, 1.5, 1.5)],
		["power_rack", Rect2(0.1, 7.0, 1.5, 1.5)],
		["plate_tree", Rect2(1.95, 6.5, 0.5, 0.5)],
		["weight_bench", Rect2(2.95, 4.95, 0.6, 1.45), "south"],
		["weight_bench", Rect2(4.35, 4.95, 0.6, 1.45), "south"],
		["mirror_wall", Rect2(0.0, 8.8, 0.06, 3.4)],
		["dumbbell_rack", Rect2(0.05, 9.0, 0.75, 3.0)],
		["adjustable_bench", Rect2(1.55, 9.25, 1.2, 0.45), "west"],
		["adjustable_bench", Rect2(1.55, 10.2, 1.2, 0.45), "west"],
		["adjustable_bench", Rect2(1.55, 11.15, 1.2, 0.45), "west"],
		["dumbbells", Rect2(2.95, 9.3, 0.5, 0.3), "south"],
		["kettlebell_rack", Rect2(4.0, 8.9, 1.5, 0.5), "south"],
		["roman_chair", Rect2(4.6, 10.2, 0.7, 1.2), "south"],
		["spray_station", Rect2(5.9, 11.6, 0.35, 0.35)],
		["lat_pulldown", Rect2(7.2, 5.1, 1.2, 1.5), "south"],
		["seated_row", Rect2(8.8, 5.1, 1.1, 1.6), "south"],
		["chest_press", Rect2(10.3, 5.1, 1.1, 1.4), "south"],
		["shoulder_press", Rect2(11.8, 5.1, 1.1, 1.4), "south"],
		["leg_curl", Rect2(13.4, 5.1, 1.0, 1.5), "south"],
		["cable_station", Rect2(15.3, 5.6, 1.0, 2.6)],
		["leg_press", Rect2(7.25, 7.5, 1.2, 2.1), "south"],
		["leg_extension", Rect2(9.0, 7.8, 1.0, 1.3), "south"],
		["smith_machine", Rect2(10.6, 7.6, 2.1, 1.3), "south"],
		["heavy_bag", Rect2(13.4, 8.4, 0.55, 0.55)],
		["heavy_bag", Rect2(14.4, 8.4, 0.55, 0.55)],
		["gym_mat", Rect2(7.4, 10.3, 0.7, 1.7)],
		["gym_mat", Rect2(8.35, 10.3, 0.7, 1.7)],
		["gym_mat", Rect2(9.3, 10.3, 0.7, 1.7)],
		["gym_mat", Rect2(10.25, 10.3, 0.7, 1.7)],
		["foam_rollers", Rect2(11.4, 10.5, 0.55, 0.9), "west"],
		["exercise_balls", Rect2(12.3, 10.4, 1.3, 0.6), "south"],
		["sled", Rect2(1.0, 13.15, 0.9, 1.0), "east"],
		["plyo_boxes", Rect2(4.6, 13.0, 1.4, 0.8), "south"],
		["battle_ropes", Rect2(7.6, 12.9, 3.4, 1.0), "west"],
		["medball_rack", Rect2(11.8, 12.9, 0.45, 1.3), "west"],
		["plant", Rect2(15.7, 14.2, 0.5, 0.5)],
	],
	# Gruppträningssalen (7,5 × 8,5): spegelvägg i norr med instruktörens matta framför,
	# deltagarnas mattor i rader mot spegeln (fria vid dörrarna i väster och söder),
	# högtalare i hörnen, ett fack med block och bolster mellan fönstren och växter.
	"yoga_studio": [
		["mirror_wall", Rect2(0.6, 0.05, 6.3, 0.06)],
		["speaker", Rect2(0.15, 0.15, 0.4, 0.35)],
		["speaker", Rect2(6.95, 0.15, 0.4, 0.35)],
		["gym_mat", Rect2(3.4, 0.55, 0.7, 1.75)],
		["gym_mat", Rect2(1.35, 2.55, 0.65, 1.75)],
		["gym_mat", Rect2(3.43, 2.55, 0.65, 1.75)],
		["gym_mat", Rect2(5.5, 2.55, 0.65, 1.75)],
		["gym_mat", Rect2(1.35, 4.55, 0.65, 1.75)],
		["gym_mat", Rect2(3.43, 4.55, 0.65, 1.75)],
		["gym_mat", Rect2(5.5, 4.55, 0.65, 1.75)],
		["gym_mat", Rect2(1.35, 6.55, 0.65, 1.7)],
		["gym_mat", Rect2(5.5, 6.55, 0.65, 1.7)],
		["yoga_shelf", Rect2(7.05, 3.15, 0.4, 1.5)],
		["plant", Rect2(0.2, 7.9, 0.45, 0.45)],
		["plant", Rect2(6.85, 7.9, 0.45, 0.45)],
	],
	# Omklädningsrummet (7,5 × 6,5): skåp längs västra väggen (ovanför dörren från hallen)
	# och östra väggen, men inte mot norra väggen, där de skulle skymma salen bakom.
	# Bänkar framför skåpen, två duschar i sydöstra hörnet, en handduksbinge och en växt.
	"locker_room": [
		["lockers", Rect2(0.05, 0.2, 0.5, 2.2)],
		["lockers", Rect2(6.95, 0.2, 0.5, 3.4)],
		["locker_bench", Rect2(1.1, 0.6, 0.4, 1.6), "east"],
		["locker_bench", Rect2(5.9, 0.6, 0.4, 2.4), "west"],
		["locker_bench", Rect2(2.4, 4.3, 2.4, 0.4), "south"],
		["shower", Rect2(6.4, 4.0, 1.05, 1.05)],
		["shower", Rect2(6.4, 5.2, 1.05, 1.05)],
		["basket", Rect2(5.4, 5.6, 0.55, 0.5)],
		["plant", Rect2(0.25, 5.8, 0.45, 0.45)],
	],
	# Köpcentret. Gångarna: en dörrmatta och krukor i entrén, och i ljusgården planteringar
	# vid ingången, vägvisaren, fontänen med bänkar och en kiosk-vagn. Promenaderna har
	# en bänk var att vila fötterna på. Höga saker står inte mot södra väggarna.
	"entrance": [
		["rug", Rect2(1.9, 0.15, 2.2, 1.5)],
		["plant", Rect2(0.3, 1.75, 0.6, 0.6)],
		["plant", Rect2(5.1, 1.75, 0.6, 0.6)],
	],
	"center_court": [
		["planter", Rect2(0.3, 0.5, 1.2, 1.2)],
		["planter", Rect2(4.5, 0.5, 1.2, 1.2)],
		["directory", Rect2(4.7, 2.2, 0.9, 0.3), "south"],
		["bench", Rect2(2.2, 3.2, 1.6, 0.5), "north"],
		["fountain", Rect2(1.6, 4.1, 2.8, 2.8)],
		["bench", Rect2(2.2, 7.4, 1.6, 0.5), "south"],
		["kiosk", Rect2(2.3, 9.3, 1.4, 1.0), "south"],
	],
	"west_promenade": [
		["bench", Rect2(1.7, 3.35, 1.6, 0.5), "north"],
		["plant", Rect2(0.15, 3.3, 0.55, 0.55)],
	],
	"east_promenade": [
		["bench", Rect2(1.7, 3.35, 1.6, 0.5), "north"],
		["plant", Rect2(4.3, 3.3, 0.55, 0.55)],
	],
	# Livsmedelsbutiken (ankare i väster): frukt och grönt under skyltfönstren, frysdiskar
	# längs gaveln, hyllgångar i mitten och kassorna vid ingången från promenaden.
	"grocery": [
		["produce_stand", Rect2(0.9, 0.35, 2.2, 0.9)],
		["produce_stand", Rect2(4.9, 0.35, 2.2, 0.9)],
		["freezer", Rect2(0.05, 1.4, 0.8, 4.2)],
		["freezer", Rect2(0.05, 6.4, 0.8, 4.2)],
		["store_shelf", Rect2(1.9, 2.2, 0.6, 4.2), "east"],
		["store_shelf", Rect2(3.6, 2.2, 0.6, 4.2), "east"],
		["store_shelf", Rect2(1.9, 7.6, 0.6, 3.4), "east"],
		["store_shelf", Rect2(3.6, 7.6, 0.6, 3.4), "east"],
		["checkout", Rect2(5.6, 9.8, 0.7, 1.6), "east"],
		["checkout", Rect2(5.6, 12.0, 0.7, 1.6), "east"],
		["shopping_carts", Rect2(6.9, 10.0, 0.9, 1.5), "north"],
		["freezer", Rect2(1.4, 12.6, 2.8, 0.9), "north"],
	],
	# Restaurangen: bord för två vid fönstren mot parkeringen och en bar längs östra väggen.
	"restaurant": [
		["table", Rect2(0.6, 1.0, 0.9, 0.8)],
		["chair", Rect2(0.85, 0.45, 0.4, 0.4)],
		["chair", Rect2(0.85, 1.95, 0.4, 0.4)],
		["table", Rect2(2.4, 1.0, 0.9, 0.8)],
		["chair", Rect2(2.65, 0.45, 0.4, 0.4)],
		["chair", Rect2(2.65, 1.95, 0.4, 0.4)],
		["table", Rect2(0.6, 3.4, 0.9, 0.8)],
		["chair", Rect2(0.85, 2.85, 0.4, 0.4)],
		["chair", Rect2(0.85, 4.35, 0.4, 0.4)],
		["counter", Rect2(4.3, 0.4, 0.65, 2.6)],
		["plant", Rect2(4.35, 5.3, 0.5, 0.5)],
	],
	# Frisörsalongen: två arbetsplatser med speglar, tvättstolar, färgbaren med alla
	# nyanser, en torkhuv, väntfåtölj med tidningar under fönstret och kassan vid dörren.
	"salon": [
		["armchair", Rect2(0.4, 0.35, 0.8, 0.75)],
		["coffee_table", Rect2(0.5, 1.3, 0.6, 0.4)],
		["salon_station", Rect2(2.1, 0.05, 1.3, 1.4)],
		["salon_station", Rect2(3.6, 0.05, 1.3, 1.4)],
		["color_bar", Rect2(0.05, 2.1, 0.45, 1.8)],
		["wash_station", Rect2(3.9, 2.1, 1.05, 1.9)],
		["hood_dryer", Rect2(0.1, 4.2, 0.75, 0.75)],
		["reception_desk", Rect2(3.95, 4.7, 1.0, 0.6)],
	],
	# Klädbutiken (ankare i öster): skyltdockor i skyltfönstren, klädställningar, hylla
	# med skor och väskor mellan fönstren, glasdisk med smycken och klockor, provhytter
	# och spegelvägg längs gaveln, kassan och bord med vikta plagg.
	"boutique": [
		["mannequin", Rect2(1.6, 0.7, 0.5, 0.5)],
		["mannequin", Rect2(5.9, 0.7, 0.5, 0.5)],
		["display_shelf", Rect2(3.3, 0.05, 1.4, 0.4)],
		["clothes_rack", Rect2(1.0, 2.4, 1.8, 0.5)],
		["clothes_rack", Rect2(3.6, 2.4, 1.8, 0.5)],
		["clothes_rack", Rect2(1.0, 4.4, 1.8, 0.5)],
		["clothes_rack", Rect2(3.6, 4.4, 1.8, 0.5)],
		["display_table", Rect2(6.1, 3.6, 1.2, 0.8)],
		["mirror_wall", Rect2(7.88, 5.0, 0.06, 2.4)],
		["display_case", Rect2(2.4, 6.6, 1.8, 0.6), "south"],
		["fitting_room", Rect2(6.5, 8.6, 1.45, 3.0)],
		["reception_desk", Rect2(2.4, 10.4, 1.8, 0.7), "north"],
		["display_table", Rect2(1.2, 12.6, 1.6, 0.9)],
		["display_table", Rect2(3.8, 12.6, 1.6, 0.9)],
		["plant", Rect2(7.3, 14.3, 0.5, 0.5)],
	],
	# Kaféet mot ljusgården: espressobar med bakverk, småbord och en läshörna.
	"cafe": [
		["espresso_bar", Rect2(0.1, 0.05, 2.8, 0.7)],
		["table", Rect2(0.7, 1.9, 0.7, 0.7)],
		["chair", Rect2(0.2, 2.05, 0.4, 0.4)],
		["chair", Rect2(1.5, 2.05, 0.4, 0.4)],
		["table", Rect2(2.7, 2.6, 0.7, 0.7)],
		["chair", Rect2(2.2, 2.75, 0.4, 0.4)],
		["chair", Rect2(3.5, 2.75, 0.4, 0.4)],
		["armchair", Rect2(0.3, 3.9, 0.85, 0.8), "east"],
		["coffee_table", Rect2(1.35, 4.0, 0.6, 0.6)],
		["plant", Rect2(4.35, 4.3, 0.5, 0.5)],
	],
	# Bokhandeln mot ljusgården: bokhyllor, ett bord med nyheter, en läsfåtölj och kassan.
	"bookstore": [
		["shelf", Rect2(0.3, 0.05, 2.0, 0.4)],
		["shelf", Rect2(2.6, 0.05, 2.0, 0.4)],
		["shelf", Rect2(4.55, 0.9, 0.4, 2.6)],
		["display_table", Rect2(1.4, 1.8, 1.4, 0.8)],
		["armchair", Rect2(3.5, 3.7, 0.85, 0.8), "west"],
		["reception_desk", Rect2(0.5, 3.9, 1.3, 0.6), "north"],
		["plant", Rect2(4.4, 4.4, 0.5, 0.5)],
	],
	# Parken: gångväg, damm, träd, bänkar och ett picknickbord.
	"park": [
		["path", Rect2(0, 2.4, 9, 0.9)],
		["pond", Rect2(5.4, 0.5, 2.8, 1.6)],
		["tree", Rect2(0.5, 0.4, 1.2, 1.2)],
		["tree", Rect2(2.6, 0.6, 1.0, 1.0)],
		["tree", Rect2(7.6, 3.8, 1.1, 1.1)],
		["bench", Rect2(3.9, 1.7, 1.2, 0.45)],
		["picnic_table", Rect2(1.2, 3.8, 1.6, 1.0)],
		["plant", Rect2(4.6, 4.6, 0.6, 0.6)],
	],
}

const LINE := Color(0.38, 0.25, 0.16, 0.85)
const OAK := Color(0.86, 0.7, 0.52)
const TEAL := Color(0.4, 0.64, 0.62)
const STONE := Color(0.92, 0.9, 0.86)
const WHITE := Color(0.98, 0.97, 0.94)
const WOOD := Color(0.66, 0.46, 0.3)
const SAGE := Color(0.58, 0.67, 0.55)
const DARK := Color(0.32, 0.3, 0.29)
const RUG := Color(0.85, 0.72, 0.62)
const LEAF := Color(0.45, 0.62, 0.4)


## Ritar rummets golv med mönster efter material.
static func draw_floor(canvas: CanvasItem, room_id: String, rect: Rect2, meter: float) -> void:
	var material: String = FLOOR_MATERIALS.get(room_id, "wood")
	match material:
		"wood", "wood_old":
			var base := OAK if material == "wood" else OAK.darkened(0.12)
			canvas.draw_rect(rect, base)
			var plank := 0.22 * meter
			var row := 0
			var y := rect.position.y + plank
			while y < rect.end.y:
				canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), base.darkened(0.1), 1.0)
				# Förskjutna skarvar mellan plankorna.
				var x := rect.position.x + (row % 3) * 0.6 * meter + 0.4 * meter
				while x < rect.end.x:
					canvas.draw_line(Vector2(x, y - plank), Vector2(x, y), base.darkened(0.1), 1.0)
					x += 1.8 * meter
				y += plank
				row += 1
		"tile", "tile_warm":
			var base := Color(0.9, 0.9, 0.88) if material == "tile" else Color(0.93, 0.87, 0.8)
			canvas.draw_rect(rect, base)
			_grid(canvas, rect, 0.4 * meter, base.darkened(0.08))
		"concrete":
			canvas.draw_rect(rect, Color(0.84, 0.82, 0.78))
		"vinyl":
			canvas.draw_rect(rect, Color(0.83, 0.83, 0.82))
			_grid(canvas, rect, 1.0 * meter, Color(0.78, 0.78, 0.77))
		"maple":
			canvas.draw_rect(rect, OAK.lightened(0.2))
			var y := rect.position.y + 0.12 * meter
			while y < rect.end.y:
				canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), OAK.lightened(0.1), 1.0)
				y += 0.12 * meter
		"terrazzo", "checker":
			var base := Color(0.86, 0.82, 0.76) if material == "terrazzo" else Color(0.92, 0.84, 0.84)
			canvas.draw_rect(rect, base)
			_grid(canvas, rect, (1.2 if material == "terrazzo" else 0.5) * meter, base.darkened(0.1))
		"grass":
			canvas.draw_rect(rect, Color(0.68, 0.78, 0.55))


static func _grid(canvas: CanvasItem, rect: Rect2, step: float, color: Color) -> void:
	var x := rect.position.x + step
	while x < rect.end.x:
		canvas.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), color, 1.0)
		x += step
	var y := rect.position.y + step
	while y < rect.end.y:
		canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), color, 1.0)
		y += step


## Ritar rummets möbler. Rummets nordvästra hörn ligger på `origin` på skärmen.
static func draw_furniture(canvas: CanvasItem, room_id: String, origin: Vector2, meter: float) -> void:
	for item in FURNITURE.get(room_id, []):
		var plan: Rect2 = item[1]
		var rect := Rect2(origin + plan.position * meter, plan.size * meter)
		if not (item[0] in FLAT_ITEMS):
			_shadow(canvas, rect)
		_draw_item(canvas, item[0], rect)


## Saker som ligger platt mot golvet eller på en bänk och därför inte kastar skugga.
## Växter ritar sin egen runda skugga.
const FLAT_ITEMS := ["rug", "path", "stairs", "sink", "stove", "gym_mat", "plant", "field_rug", "poster", "pennant", "photo_wall", "pond", "whiteboard", "mirror_wall", "attic_ladder", "entry_mat", "rubber_floor", "turf", "driveway", "patio"]
## Saker som hänger på en vägg (ritas tunt längs väggen, och i 3D högt upp på väggen).
const WALL_ITEMS := ["poster", "pennant", "photo_wall", "whiteboard", "mirror_wall"]


## Mjuk skugga snett nedanför en möbel.
static func _shadow(canvas: CanvasItem, r: Rect2) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.16, 0.1, 0.16)
	style.set_corner_radius_all(4)
	canvas.draw_style_box(style, Rect2(r.position + Vector2(2, 4), r.size))


## Mörknar rummets kanter lite, som skuggan från väggarna.
static func draw_inner_shadow(canvas: CanvasItem, rect: Rect2) -> void:
	for i in 4:
		canvas.draw_rect(rect.grow(-1.5 - i * 3.0), Color(0.25, 0.16, 0.1, 0.07 - i * 0.015), false, 3.0)


## Rektangeln för rummets trappa i meter, eller en tom Rect2 om rummet saknar trappa.
static func stairs_rect(room_id: String) -> Rect2:
	return furniture_rect(room_id, "stairs")


## Möbelns stil (fjärde elementet i FURNITURE), eller "".
static func item_style(item: Array) -> String:
	return item[3] if item.size() > 3 else ""


## Gårdar med staket bara på vissa sidor (resten gränsar mot huset eller får häckar av
## Surroundings): framsidan mot gatan och trädgården mot grannen bakom.
const YARD_FENCES := {"outside": ["north"], "backyard": ["south"]}


## Öppningarna i en gårds staket: där en gång eller uppfart når sidan.
## [{start, width}] i meter längs sidan (från väster eller norr).
static func yard_gaps(room_id: String, side: String) -> Array:
	var plan := PlanDrawer.plan_of(room_id)
	var gaps := []
	for item in FURNITURE.get(room_id, []):
		if not item[0] in ["path", "driveway"]:
			continue
		var r: Rect2 = item[1]
		var touches: bool = {"north": r.position.y < 0.05, "south": r.end.y > plan.size.y - 0.05,
				"west": r.position.x < 0.05, "east": r.end.x > plan.size.x - 0.05}[side]
		if touches:
			gaps.append({"start": r.position.x if side in ["north", "south"] else r.position.y, "width": r.size.x if side in ["north", "south"] else r.size.y})
	return gaps


## Den första möbeln av en viss typ i rummet (meter, från rummets nordvästra hörn),
## eller en tom Rect2 om rummet inte har någon sådan.
static func furniture_rect(room_id: String, kind: String) -> Rect2:
	for item in FURNITURE.get(room_id, []):
		if item[0] == kind:
			return item[1]
	return Rect2()


static func _draw_item(canvas: CanvasItem, kind: String, r: Rect2) -> void:
	if kind in GymKit.KINDS:
		GymKit.draw_symbol(canvas, kind, r)
		return
	if kind in HomeKit.KINDS:
		HomeKit.draw_symbol(canvas, kind, r)
		return
	match kind:
		"counter":
			_box(canvas, r, STONE)
			canvas.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.12)), TEAL)
		"sink":
			_box(canvas, r, Color(0.85, 0.86, 0.86))
			_ellipse(canvas, r.get_center(), r.size * 0.32, Color(0.75, 0.78, 0.8))
		"stove":
			_box(canvas, r, DARK)
			for i in 4:
				var c := r.position + r.size * Vector2(0.3 + 0.4 * (i % 2), 0.3 + 0.4 * (i / 2))
				canvas.draw_arc(c, minf(r.size.x, r.size.y) * 0.14, 0, TAU, 16, Color(0.6, 0.58, 0.56), 1.5)
		"fridge":
			_box(canvas, r, TEAL)
			canvas.draw_line(r.position + Vector2(r.size.x * 0.5, 0), r.end - Vector2(r.size.x * 0.5, 0), TEAL.darkened(0.25), 1.5)
		"table", "coffee_table":
			var top := WOOD if kind == "table" else WOOD.lightened(0.15)
			_box(canvas, r, top, 4.0)
			# Ådring längs bordets långsida.
			var horizontal := r.size.x >= r.size.y
			for i in 3:
				var t := (i + 1) / 4.0
				if horizontal:
					canvas.draw_line(Vector2(r.position.x + 6, r.position.y + r.size.y * t),
							Vector2(r.end.x - 6, r.position.y + r.size.y * t), top.darkened(0.12), 1.0)
				else:
					canvas.draw_line(Vector2(r.position.x + r.size.x * t, r.position.y + 6),
							Vector2(r.position.x + r.size.x * t, r.end.y - 6), top.darkened(0.12), 1.0)
		"chair":
			_box(canvas, r, WOOD.darkened(0.1), 5.0)
			_box(canvas, r.grow(-3), WOOD.lightened(0.1), 4.0)
		"sofa", "armchair":
			_box(canvas, r, SAGE, 7.0)
			# Ryggstöd längs sydsidan (soffan vänd mot norr) och armstöd på sidorna.
			var back := r.size.y * 0.28
			var arm := minf(r.size.x * 0.1, 10.0)
			_box(canvas, Rect2(r.position + Vector2(0, r.size.y - back), Vector2(r.size.x, back)), SAGE.darkened(0.15), 5.0)
			_box(canvas, Rect2(r.position, Vector2(arm, r.size.y)), SAGE.darkened(0.1), 5.0)
			_box(canvas, Rect2(Vector2(r.end.x - arm, r.position.y), Vector2(arm, r.size.y)), SAGE.darkened(0.1), 5.0)
			# Sittdynor.
			var cushions := 3 if kind == "sofa" and r.size.x > r.size.y * 2 else 1
			var seat := Rect2(r.position + Vector2(arm, 0), Vector2(r.size.x - arm * 2, r.size.y - back))
			for i in cushions:
				var w := seat.size.x / cushions
				_box(canvas, Rect2(seat.position + Vector2(w * i + 2, 3), Vector2(w - 4, seat.size.y - 5)), SAGE.lightened(0.08), 5.0)
			if kind == "sofa":
				_box(canvas, Rect2(Vector2(seat.position.x + 6, seat.end.y - 16), Vector2(16, 13)), Color(0.93, 0.8, 0.62), 4.0)
				_box(canvas, Rect2(Vector2(seat.end.x - 22, seat.end.y - 16), Vector2(16, 13)), Color(0.85, 0.6, 0.55), 4.0)
		"tv":
			_box(canvas, r, DARK)
			canvas.draw_line(r.position + Vector2(4, r.size.y - 3), r.end - Vector2(4, 3), Color(0.55, 0.55, 0.58), 1.5)
		"rug":
			_box(canvas, r, RUG, 6.0)
			canvas.draw_rect(r.grow(-6), RUG.darkened(0.1), false, 1.5)
			canvas.draw_rect(r.grow(-11), RUG.darkened(0.06), false, 1.0)
			# Ett enkelt rutmönster i mitten.
			var c := r.get_center()
			var d := minf(r.size.x, r.size.y) * 0.22
			canvas.draw_polyline(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0), c + Vector2(0, d), c + Vector2(-d, 0), c + Vector2(0, -d)]),
					RUG.darkened(0.12), 1.5, true)
		"bed":
			_box(canvas, r, WHITE, 5.0)
			var pillow := Vector2(r.size.x * 0.4 if r.size.x > r.size.y * 0.7 else r.size.x * 0.8, r.size.y * 0.15)
			var count := 2 if r.size.x > r.size.y * 0.7 else 1
			for i in count:
				var px := r.position.x + (r.size.x - pillow.x * count) / (count + 1) * (i + 1) + pillow.x * i
				_box(canvas, Rect2(Vector2(px, r.position.y + r.size.y * 0.05), pillow), Color(0.95, 0.93, 0.9), 3.0)
			var blanket := Rect2(r.position + Vector2(0, r.size.y * 0.32), r.size * Vector2(1, 0.68))
			_box(canvas, blanket, TEAL.lightened(0.25), 4.0)
			# Det vikta täcket överst.
			_box(canvas, Rect2(blanket.position, Vector2(blanket.size.x, blanket.size.y * 0.16)), TEAL.lightened(0.4), 4.0)
			canvas.draw_line(blanket.position + Vector2(4, blanket.size.y * 0.6), Vector2(blanket.end.x - 4, blanket.position.y + blanket.size.y * 0.6),
					TEAL.lightened(0.1), 1.0)
		"nightstand", "shelf", "wardrobe", "shoe_rack":
			_box(canvas, r, WOOD.lightened(0.05))
			if kind == "wardrobe":
				canvas.draw_line(r.position + Vector2(r.size.x / 2, 0), Vector2(r.position.x + r.size.x / 2, r.end.y), LINE, 1.0)
		"desk":
			_box(canvas, r, WOOD.lightened(0.1))
			# En stängd laptop och en liten lampa.
			var laptop := Vector2(minf(r.size.x * 0.3, 26), minf(r.size.y * 0.5, 18))
			_box(canvas, Rect2(r.get_center() - laptop / 2, laptop), Color(0.62, 0.64, 0.68), 2.0)
			canvas.draw_circle(r.position + Vector2(r.size.x * 0.85, r.size.y * 0.5), minf(r.size.y * 0.22, 7), Color(0.98, 0.9, 0.62))
		"toilet":
			_box(canvas, Rect2(r.position + Vector2(0, r.size.y * 0.65), r.size * Vector2(1, 0.35)), WHITE)
			_ellipse(canvas, r.position + r.size * Vector2(0.5, 0.38), r.size * Vector2(0.45, 0.36), WHITE, true)
		"basin":
			_box(canvas, r, WHITE, 4.0)
			_ellipse(canvas, r.get_center(), r.size * 0.3, Color(0.85, 0.87, 0.88))
		"bathtub":
			_box(canvas, r, WHITE, 10.0)
			_box(canvas, r.grow(-6), Color(0.8, 0.88, 0.9), 8.0)
		"shower":
			# Duschhörna: kaklad platta med golvbrunn och en glasvägg mot rummet.
			_box(canvas, r, Color(0.86, 0.9, 0.9), 2.0)
			_grid(canvas, r.grow(-2), minf(r.size.x, r.size.y) / 4, Color(0.78, 0.84, 0.85))
			canvas.draw_circle(r.get_center(), minf(r.size.x, r.size.y) * 0.06, Color(0.55, 0.6, 0.62))
			canvas.draw_line(Vector2(r.position.x, r.end.y), r.end, Color(0.55, 0.75, 0.85), 2.5)
			canvas.draw_line(Vector2(r.end.x, r.position.y), r.end, Color(0.55, 0.75, 0.85), 2.5)
		"washer":
			_box(canvas, r, WHITE, 3.0)
			canvas.draw_arc(r.get_center(), minf(r.size.x, r.size.y) * 0.3, 0, TAU, 24, LINE, 1.5)
		"rack":
			_box(canvas, r, Color(0, 0, 0, 0))
			for i in 5:
				var y := r.position.y + r.size.y * (i + 0.5) / 5
				canvas.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), LINE, 1.0)
		"basket":
			_ellipse(canvas, r.get_center(), r.size / 2, Color(0.8, 0.68, 0.5), true)
		"dog_bed":
			_ellipse(canvas, r.get_center(), r.size / 2, Color(0.72, 0.55, 0.45), true)
			_ellipse(canvas, r.get_center(), r.size / 2 * 0.65, Color(0.85, 0.75, 0.65))
		"boxes", "trunk":
			_box(canvas, r, Color(0.78, 0.62, 0.42) if kind == "boxes" else WOOD)
			canvas.draw_line(r.position + Vector2(r.size.x / 2, 0), Vector2(r.position.x + r.size.x / 2, r.end.y), LINE, 1.0)
		"plant":
			var c := r.get_center()
			var radius := minf(r.size.x, r.size.y) / 2
			canvas.draw_circle(c + Vector2(1, 2), radius * 0.95, Color(0.25, 0.16, 0.1, 0.18))
			canvas.draw_circle(c, radius * 0.6, Color(0.76, 0.5, 0.36))
			for i in 7:
				var leaf := c + Vector2.from_angle(TAU * i / 7.0 + 0.3) * radius * 0.5
				canvas.draw_circle(leaf, radius * 0.42, LEAF.darkened(0.1 if i % 2 == 0 else 0.0))
			canvas.draw_circle(c, radius * 0.32, LEAF.lightened(0.18))
		"gym_mat":
			_box(canvas, r, Color(0.5, 0.62, 0.68), 4.0)
		"bike":
			canvas.draw_arc(r.position + Vector2(r.size.y / 2, r.size.y / 2), r.size.y * 0.45, 0, TAU, 20, DARK, 2.0)
			canvas.draw_arc(r.end - Vector2(r.size.y / 2, r.size.y / 2), r.size.y * 0.45, 0, TAU, 20, DARK, 2.0)
		"easel":
			_box(canvas, r, WHITE)
		"path":
			canvas.draw_rect(r, Color(0.85, 0.8, 0.7))
		"attic_ladder":
			for s in [0.15, 0.85]:
				canvas.draw_line(r.position + Vector2(r.size.x * s, 0), r.position + Vector2(r.size.x * s, r.size.y), WOOD, 2.0)
			for i in range(1, 5):
				canvas.draw_line(r.position + Vector2(r.size.x * 0.15, r.size.y * i / 5.0), r.position + Vector2(r.size.x * 0.85, r.size.y * i / 5.0), WOOD, 1.5)
		"stairs":
			pass  # Ritas av kartan, som också lägger till pilar upp och ned.
		"vanity":
			# Sminkbord mot väggen: spegel längs väggsidan, flaskor och en sminkväska.
			_box(canvas, r, Color(0.95, 0.9, 0.86), 3.0)
			var mirror := Rect2(r.position, Vector2(r.size.x * 0.22, r.size.y)) if r.size.y > r.size.x else Rect2(r.position, Vector2(r.size.x, r.size.y * 0.22))
			_box(canvas, mirror.grow(-1), Color(0.78, 0.88, 0.95), 2.0)
			var spots := [Vector2(0.55, 0.2), Vector2(0.7, 0.32), Vector2(0.6, 0.75), Vector2(0.75, 0.82)]
			var colors := [Color(0.95, 0.6, 0.7), Color(0.8, 0.7, 0.9), Color(0.95, 0.85, 0.6), Color(0.9, 0.45, 0.45)]
			for i in spots.size():
				canvas.draw_circle(r.position + r.size * spots[i], minf(r.size.x, r.size.y) * 0.09, colors[i])
			_box(canvas, Rect2(r.position + r.size * Vector2(0.45, 0.42), r.size * Vector2(0.4, 0.16)), Color(0.85, 0.55, 0.6), 2.0)
		"stool":
			_ellipse(canvas, r.get_center(), r.size / 2, WOOD.lightened(0.1), true)
			_ellipse(canvas, r.get_center(), r.size / 2 * 0.72, Color(0.93, 0.68, 0.72))
		"gaming_desk":
			# Mörkt skrivbord med två skärmar, tangentbord, mus, burk och en rgb-list.
			_box(canvas, r, Color(0.25, 0.25, 0.3), 3.0)
			var screen_w := r.size.x * 0.32
			for i in 2:
				var sx := r.position.x + r.size.x * (0.17 + i * 0.34)
				_box(canvas, Rect2(Vector2(sx, r.position.y + 3), Vector2(screen_w, r.size.y * 0.16)), Color(0.12, 0.12, 0.16), 2.0)
				canvas.draw_line(Vector2(sx + 3, r.position.y + 3 + r.size.y * 0.16), Vector2(sx + screen_w - 3, r.position.y + 3 + r.size.y * 0.16), Color(0.4, 0.75, 1.0), 2.0)
			_box(canvas, Rect2(r.position + r.size * Vector2(0.3, 0.52), r.size * Vector2(0.34, 0.16)), Color(0.18, 0.18, 0.22), 2.0)
			canvas.draw_circle(r.position + r.size * Vector2(0.72, 0.6), minf(r.size.y * 0.07, 4), Color(0.18, 0.18, 0.22))
			canvas.draw_circle(r.position + r.size * Vector2(0.9, 0.55), minf(r.size.y * 0.08, 5), Color(0.4, 0.85, 0.4))
			var stripe := [Color(1.0, 0.3, 0.5), Color(0.7, 0.4, 1.0), Color(0.3, 0.6, 1.0), Color(0.3, 0.95, 0.8)]
			for i in 4:
				canvas.draw_line(Vector2(r.position.x + r.size.x * i / 4.0 + 2, r.end.y - 2), Vector2(r.position.x + r.size.x * (i + 1) / 4.0 - 2, r.end.y - 2), stripe[i], 2.0)
		"gaming_chair":
			_box(canvas, r, Color(0.15, 0.15, 0.18), 8.0)
			_box(canvas, r.grow(-4), Color(0.22, 0.22, 0.26), 6.0)
			canvas.draw_line(r.position + Vector2(r.size.x * 0.32, 4), Vector2(r.position.x + r.size.x * 0.32, r.end.y - 4), Color(0.9, 0.25, 0.3), 2.0)
			canvas.draw_line(r.position + Vector2(r.size.x * 0.68, 4), Vector2(r.position.x + r.size.x * 0.68, r.end.y - 4), Color(0.9, 0.25, 0.3), 2.0)
		"beanbag":
			_ellipse(canvas, r.get_center(), r.size / 2, Color(0.5, 0.42, 0.75), true)
			_ellipse(canvas, r.get_center() + r.size * Vector2(-0.08, -0.08), r.size / 2 * 0.55, Color(0.6, 0.52, 0.85))
			# En handkontroll på sittsäcken.
			_box(canvas, Rect2(r.get_center() + r.size * Vector2(0.05, 0.05), r.size * Vector2(0.28, 0.16)), Color(0.2, 0.2, 0.24), 3.0)
		"media_stand":
			_box(canvas, r, WOOD.darkened(0.05))
			_box(canvas, Rect2(r.position + Vector2(r.size.x * 0.1, 2), Vector2(r.size.x * 0.8, r.size.y * 0.2)), DARK.darkened(0.3), 2.0)
			_box(canvas, Rect2(r.position + r.size * Vector2(0.15, 0.5), r.size * Vector2(0.3, 0.32)), WHITE, 2.0)
			_box(canvas, Rect2(r.position + r.size * Vector2(0.58, 0.5), r.size * Vector2(0.24, 0.28)), Color(0.2, 0.2, 0.24), 2.0)
		"collectible_shelf", "trophy_shelf":
			_box(canvas, r, WOOD.lightened(0.05))
			var count := maxi(1, int(r.size.x / 9))
			for i in count:
				var c := r.position + Vector2(r.size.x * (i + 0.5) / count, r.size.y * 0.5)
				if kind == "trophy_shelf":
					canvas.draw_circle(c, minf(r.size.y * 0.24, 6), Color(0.95, 0.78, 0.3) if i % 3 else Color(0.82, 0.82, 0.86))
					canvas.draw_circle(c, minf(r.size.y * 0.12, 3), Color(0.8, 0.6, 0.2))
				else:
					var figure: Color = [Color(0.9, 0.35, 0.35), Color(0.35, 0.6, 0.95), Color(0.95, 0.85, 0.35), Color(0.5, 0.85, 0.5), Color(0.8, 0.5, 0.9)][i % 5]
					_box(canvas, Rect2(c - Vector2(3, 4), Vector2(6, 8)), figure, 2.0)
		"poster", "pennant", "photo_wall":
			var poster_colors := {"poster": [Color(0.3, 0.45, 0.85), Color(0.9, 0.4, 0.3)], "pennant": [Color(0.15, 0.3, 0.6), Color(0.95, 0.75, 0.25)], "photo_wall": [Color(0.95, 0.92, 0.85), Color(0.6, 0.5, 0.4)]}
			var pick: Array = poster_colors[kind]
			var vertical := r.size.y > r.size.x
			var thick := Rect2(r.position, Vector2(maxf(r.size.x, 5), maxf(r.size.y, 5)))
			_box(canvas, thick, pick[0], 1.0)
			if kind == "photo_wall":
				for i in 3:
					var t := (i + 0.5) / 3.0
					var p := thick.position + (Vector2(2.5, thick.size.y * t) if vertical else Vector2(thick.size.x * t, 2.5))
					canvas.draw_circle(p, 1.5, pick[1])
			else:
				canvas.draw_line(thick.get_center() - (Vector2(0, thick.size.y * 0.3) if vertical else Vector2(thick.size.x * 0.3, 0)),
						thick.get_center() + (Vector2(0, thick.size.y * 0.3) if vertical else Vector2(thick.size.x * 0.3, 0)), pick[1], 2.0)
		"field_rug":
			# Matta som en fotbollsplan: grön med vita yardlinjer och färgade målområden.
			_box(canvas, r, Color(0.36, 0.62, 0.36), 3.0)
			var long := r.size.x >= r.size.y
			var zone := (r.size.x if long else r.size.y) * 0.12
			var ends := [Rect2(r.position, Vector2(zone, r.size.y)) if long else Rect2(r.position, Vector2(r.size.x, zone)),
					Rect2(Vector2(r.end.x - zone, r.position.y), Vector2(zone, r.size.y)) if long else Rect2(Vector2(r.position.x, r.end.y - zone), Vector2(r.size.x, zone))]
			_box(canvas, ends[0], Color(0.2, 0.32, 0.62), 2.0)
			_box(canvas, ends[1], Color(0.85, 0.3, 0.3), 2.0)
			for i in range(1, 6):
				var t := zone + ((r.size.x if long else r.size.y) - zone * 2) * i / 6.0
				if long:
					canvas.draw_line(Vector2(r.position.x + t, r.position.y + 3), Vector2(r.position.x + t, r.end.y - 3), Color(1, 1, 1, 0.85), 1.0)
				else:
					canvas.draw_line(Vector2(r.position.x + 3, r.position.y + t), Vector2(r.end.x - 3, r.position.y + t), Color(1, 1, 1, 0.85), 1.0)
		"dumbbells":
			for i in 2:
				var y := r.position.y + r.size.y * (0.3 + i * 0.4)
				canvas.draw_line(Vector2(r.position.x + r.size.x * 0.2, y), Vector2(r.end.x - r.size.x * 0.2, y), Color(0.6, 0.6, 0.64), 2.0)
				for x in [r.position.x + r.size.x * 0.15, r.end.x - r.size.x * 0.15]:
					canvas.draw_circle(Vector2(x, y), minf(r.size.y * 0.2, 5), Color(0.2, 0.2, 0.24))
		"weight_bench":
			var long := r.size.y >= r.size.x
			var pad := r.grow(-r.size.x * 0.22) if long else r.grow(-r.size.y * 0.22)
			_box(canvas, pad, Color(0.15, 0.15, 0.2), 4.0)
			_box(canvas, pad.grow(-2), Color(0.25, 0.25, 0.32), 3.0)
			# Skivstång över bänkens ena ände.
			var bar_y := r.position.y + r.size.y * 0.18
			canvas.draw_line(Vector2(r.position.x - 4, bar_y), Vector2(r.end.x + 4, bar_y), Color(0.65, 0.65, 0.7), 2.5)
			for x in [r.position.x - 2, r.end.x + 2]:
				_box(canvas, Rect2(Vector2(x - 3, bar_y - 7), Vector2(6, 14)), Color(0.2, 0.2, 0.24), 2.0)
		"football_gear":
			# Sportbag med hjälm och en boll.
			_box(canvas, Rect2(r.position, r.size * Vector2(0.62, 1.0)), Color(0.2, 0.3, 0.55), 6.0)
			canvas.draw_line(r.position + Vector2(4, r.size.y * 0.5), Vector2(r.position.x + r.size.x * 0.62 - 4, r.position.y + r.size.y * 0.5), Color(0.95, 0.75, 0.25), 1.5)
			canvas.draw_circle(r.position + r.size * Vector2(0.31, 0.45), minf(r.size.x, r.size.y) * 0.3, Color(0.85, 0.25, 0.25))
			canvas.draw_circle(r.position + r.size * Vector2(0.31, 0.45), minf(r.size.x, r.size.y) * 0.15, Color(0.95, 0.95, 0.95))
			_ellipse(canvas, r.position + r.size * Vector2(0.82, 0.5), r.size * Vector2(0.14, 0.24), Color(0.6, 0.35, 0.2), true)
			canvas.draw_line(r.position + r.size * Vector2(0.82, 0.38), r.position + r.size * Vector2(0.82, 0.62), WHITE, 1.0)
		# --- Köpcentret ---
		"store_shelf", "display_shelf", "freezer":
			var fill: Color = {"store_shelf": WHITE, "display_shelf": WOOD.lightened(0.2), "freezer": Color(0.82, 0.9, 0.95)}[kind]
			_box(canvas, r, fill)
			var long := r.size.x >= r.size.y
			canvas.draw_line(r.get_center() - (Vector2(r.size.x * 0.45, 0) if long else Vector2(0, r.size.y * 0.45)),
					r.get_center() + (Vector2(r.size.x * 0.45, 0) if long else Vector2(0, r.size.y * 0.45)), fill.darkened(0.25), 1.0)
		"produce_stand":
			_box(canvas, r, WOOD.lightened(0.15))
			var fruit := [Color(0.95, 0.45, 0.3), Color(0.6, 0.82, 0.35), Color(0.98, 0.8, 0.3), Color(0.55, 0.35, 0.6)]
			for i in 4:
				var crate := Rect2(r.position + Vector2(r.size.x * i / 4.0 + 2, 2), Vector2(r.size.x / 4.0 - 4, r.size.y - 4))
				_box(canvas, crate, fruit[i], 2.0)
		"checkout", "reception_desk", "espresso_bar", "display_case":
			var top: Color = {"checkout": DARK.lightened(0.3), "reception_desk": WHITE, "espresso_bar": WOOD, "display_case": Color(0.82, 0.9, 0.95)}[kind]
			_box(canvas, r, top, 3.0)
			if kind == "checkout":
				canvas.draw_rect(r.grow(-r.size.x * 0.25 if r.size.x < r.size.y else -r.size.y * 0.25), Color(0.2, 0.2, 0.24))
			elif kind == "espresso_bar":
				canvas.draw_circle(r.position + r.size * Vector2(0.2, 0.5), minf(r.size.x, r.size.y) * 0.25, DARK)
		"shopping_carts":
			for i in 3:
				canvas.draw_rect(r.grow(-2 - i * 3), Color(0.6, 0.62, 0.66), false, 1.5)
		"clothes_rack":
			var long := r.size.x >= r.size.y
			var count := int((r.size.x if long else r.size.y) / 6)
			for i in count:
				var t := (i + 0.5) / count
				var c: Color = [Color(0.95, 0.85, 0.75), Color(0.85, 0.4, 0.45), Color(0.4, 0.5, 0.7), Color(0.55, 0.7, 0.5)][i % 4]
				var p := r.position + (Vector2(r.size.x * t, 0) if long else Vector2(0, r.size.y * t))
				canvas.draw_line(p, p + (Vector2(0, r.size.y) if long else Vector2(r.size.x, 0)), c, 4.0)
		"display_table":
			_box(canvas, r, OAK, 3.0)
			for i in 3:
				_box(canvas, Rect2(r.position + r.size * Vector2(0.1 + i * 0.3, 0.25), r.size * Vector2(0.22, 0.5)), [Color(0.85, 0.4, 0.45), Color(0.4, 0.55, 0.8), WHITE][i], 2.0)
		"mannequin":
			_ellipse(canvas, r.get_center(), r.size * 0.4, Color(0.95, 0.92, 0.88), true)
		"fitting_room":
			# Två hytter med en vägg emellan.
			_box(canvas, r, WHITE)
			var long := r.size.x >= r.size.y
			var p := r.position + (Vector2(r.size.x / 2, 0) if long else Vector2(0, r.size.y / 2))
			canvas.draw_line(p, p + (Vector2(0, r.size.y) if long else Vector2(r.size.x, 0)), LINE, 1.0)
		"bench":
			_box(canvas, r, WOOD.lightened(0.05), 3.0)
		"mirror_wall":
			_box(canvas, Rect2(r.position, Vector2(maxf(r.size.x, 4), maxf(r.size.y, 4))), Color(0.78, 0.88, 0.95), 1.0)
		"planter":
			_box(canvas, r, STONE.darkened(0.08), 6.0)
			canvas.draw_circle(r.get_center(), minf(r.size.x, r.size.y) * 0.38, LEAF)
		"fountain":
			_ellipse(canvas, r.get_center(), r.size / 2, STONE.darkened(0.05), true)
			_ellipse(canvas, r.get_center(), r.size / 2 * 0.82, Color(0.55, 0.78, 0.9))
			_ellipse(canvas, r.get_center(), r.size / 2 * 0.22, STONE, true)
		"kiosk":
			_box(canvas, r, Color(0.95, 0.75, 0.55), 4.0)
			canvas.draw_rect(r.grow(-4), Color(0.86, 0.5, 0.48), false, 2.0)
		"directory":
			_box(canvas, Rect2(r.position, Vector2(maxf(r.size.x, 5), maxf(r.size.y, 5))), DARK.lightened(0.2), 2.0)
		"salon_station":
			_box(canvas, Rect2(r.position, Vector2(r.size.x, r.size.y * 0.3)), WHITE, 2.0)
			canvas.draw_line(r.position + Vector2(4, 2), Vector2(r.end.x - 4, r.position.y + 2), Color(0.55, 0.75, 0.85), 2.0)
			_ellipse(canvas, r.position + r.size * Vector2(0.5, 0.68), r.size * Vector2(0.26, 0.22), Color(0.3, 0.3, 0.34), true)
		"wash_station":
			var long := r.size.x >= r.size.y
			for i in 2:
				var seat := Rect2(r.position + (Vector2(r.size.x * i / 2.0, 0) if long else Vector2(0, r.size.y * i / 2.0)), r.size * (Vector2(0.5, 1) if long else Vector2(1, 0.5)))
				_box(canvas, seat.grow(-2), Color(0.3, 0.3, 0.34), 4.0)
		"hood_dryer":
			_ellipse(canvas, r.get_center(), r.size / 2, Color(0.3, 0.3, 0.34), true)
			_ellipse(canvas, r.get_center(), r.size / 2 * 0.6, Color(0.9, 0.88, 0.86))
		"color_bar":
			_box(canvas, r, WHITE)
			var long := r.size.x >= r.size.y
			var tubes := [Color(0.55, 0.22, 0.12), Color(0.78, 0.36, 0.16), Color(0.4, 0.24, 0.15), Color(0.12, 0.1, 0.1), Color(0.86, 0.68, 0.4)]
			for i in tubes.size():
				var t := (i + 0.5) / tubes.size()
				canvas.draw_circle(r.position + (Vector2(r.size.x * t, r.size.y / 2) if long else Vector2(r.size.x / 2, r.size.y * t)), minf(r.size.x, r.size.y) * 0.22, tubes[i])


## Fylld rektangel med tunn kontur och rundade hörn.
static func _box(canvas: CanvasItem, r: Rect2, fill: Color, corner := 2.0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(int(corner))
	style.anti_aliasing = true
	canvas.draw_style_box(style, r)


static func _ellipse(canvas: CanvasItem, center: Vector2, radii: Vector2, fill: Color, outline := false) -> void:
	var points := PackedVector2Array()
	for i in 24:
		points.append(center + Vector2.from_angle(TAU * i / 24.0) * radii)
	canvas.draw_colored_polygon(points, fill)
	if outline:
		points.append(points[0])
		canvas.draw_polyline(points, LINE, 1.0, true)
