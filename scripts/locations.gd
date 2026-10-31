class_name Locations
## Platserna i grannskapet som man reser till via kartan (WorldMap). Varje plats är en
## egen "våning" i PlanDrawer.FLOOR_PLANS med egna rum, så den visas med samma 3D-vy,
## menyer och tidssystem som huset. En ny plats läggs till genom att:
##   1. lägga till den här (namn, våning, ingång, plats på kartan, krav),
##   2. lägga till dess rum i PlanDrawer.FLOOR_PLANS, GameState.ROOMS och
##      FloorPlanArt.FURNITURE, och dess handlingar i RoomActions.
## Krav som kan låsa en plats (alla är valfria):
##   periods    – öppet bara under dessa tidszoner, t.ex. ["afternoon"]
##   weekdays   – öppet bara dessa veckodagar (index 0 = måndag)
##   min_day    – öppnar först en viss dag
##   flag       – en händelse i storyn måste ha hänt (GameState.flags), med flag_hint
##                som text så länge den inte har det
##   quest      – en quest måste vara startad (eller "quest_done": avklarad)
## All text spelaren ser är på engelska.

## Hemmet: dit "Go Home" leder, och huset på kartan.
const HOME := {
	"name": "Home",
	"room": "hall",
	"map_pos": Vector2(0.5, 0.56),
	"description": "Your house. Kids, dog, husband and a pile of laundry.",
}

const LOCATIONS := {
	"school": {
		"name": "School",
		"floor": "Skolan",
		"room": "classroom",
		"map_pos": Vector2(0.2, 0.25),
		"icon": "school",
		"color": Color(0.85, 0.45, 0.35),
		"description": "Where you teach and where both boys go. Grade papers, prepare lessons and meet colleagues.",
		"arrive": "You drive over to the school.",
		"periods": ["afternoon"],
		"weekdays": [0, 1, 2, 3, 4],
		"closed_text": "The school closes for the day. You head home.",
	},
	"neighbor": {
		"name": "Neighbor's House",
		"floor": "Grannen",
		"room": "neighbor_living",
		"map_pos": Vector2(0.71, 0.66),
		"icon": "house",
		"color": Color(0.55, 0.6, 0.85),
		"description": "The house next door. Someone new seems to have moved in.",
		"arrive": "You walk over and knock on the neighbor's door.",
		"periods": ["afternoon", "evening"],
		"flag": "met_neighbor",
		"flag_hint": "Introduce yourself to the neighbor first",
		"closed_text": "It's getting late. You say goodnight and walk home.",
	},
	"fitness": {
		"name": "Fitness Center",
		"floor": "Gymmet",
		"room": "gym",
		"map_pos": Vector2(0.82, 0.22),
		"icon": "fitness",
		"color": Color(0.35, 0.7, 0.6),
		"description": "Cardio, free weights, machines, a turf lane, a yoga studio and locker rooms. Open until late.",
		"arrive": "You grab your gym bag and drive to the fitness center.",
		"periods": ["afternoon", "evening"],
	},
	"shopping": {
		"name": "Shopping Center",
		"floor": "Köpcentret",
		"room": "entrance",
		"map_pos": Vector2(0.52, 0.16),
		"icon": "shopping",
		"color": Color(0.9, 0.6, 0.3),
		"description": "An indoor mall around a fountain court: groceries, fashion, a hair salon, a café, a bookstore and a restaurant.",
		"arrive": "You drive to the shopping center.",
		"periods": ["afternoon", "evening"],
	},
	"park": {
		"name": "Park",
		"floor": "Parken",
		"room": "park",
		"map_pos": Vector2(0.24, 0.72),
		"icon": "park",
		"color": Color(0.45, 0.7, 0.4),
		"description": "A green park with a pond, walking paths and picnic tables.",
		"arrive": "You stroll down the street to the park.",
		"periods": ["afternoon", "evening"],
	},
}

## Vägar på platshållarkartan: linjer mellan punkter (andelar av kartan).
const ROADS := [
	[Vector2(0.0, 0.42), Vector2(0.3, 0.44), Vector2(0.62, 0.4), Vector2(1.0, 0.44)],
	[Vector2(0.5, 0.0), Vector2(0.5, 0.42), Vector2(0.52, 1.0)],
	[Vector2(0.2, 0.42), Vector2(0.2, 0.3)],
	[Vector2(0.82, 0.43), Vector2(0.82, 0.28)],
	[Vector2(0.5, 0.62), Vector2(0.66, 0.66)],
	[Vector2(0.5, 0.74), Vector2(0.3, 0.74)],
]


## Platsen ett rum hör till, eller tom sträng om rummet är hemma.
static func location_of_room(room_id: String) -> String:
	var floor_name := PlanDrawer.floor_of(room_id)
	for location_id in LOCATIONS:
		if LOCATIONS[location_id]["floor"] == floor_name:
			return location_id
	return ""


static func location_name(location_id: String) -> String:
	return HOME["name"] if location_id == "" else LOCATIONS[location_id]["name"]
