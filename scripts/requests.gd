class_name Requests
## Mätare som växer med tiden och får personer att komma till mamman med en förfrågan.
## Gör hon det de ber om får hon något tillbaka: pengar, eller att personen tar en syssla
## åt henne (som då inte tar någon tid). Det är spelets sätt att köpa sig fri tid.
## Det här är bara data och uträkningar; mätarna, förfrågningarna och skulderna finns i
## GameState. All text spelaren ser är på engelska.
##
## Två skilda spår som delar samma motor:
##   desire – vuxna romantiska intressen (maken och vuxna NPC:er utanför familjen) och
##            mamman själv. Bara personer i DESIRE får finnas här.
##   wants  – sönerna. Vanliga tonårsönskemål (skjuts, pengar till ett spel, kompisar
##            över). Ingenting romantiskt eller sexuellt, och de är aldrig med i DESIRE.
##
## Kurvan: varje tidszon växer mätaren med
##     rate × multiplikatorer × (0,5 + värde / 100)
## så den börjar långsamt, tar fart när den har kommit en bit, och slår i taket vid 100.
## Från 0 till tröskeln 60 tar det ungefär 25 × ln(2,2) / rate tidszoner, t.ex. fem dagar
## med rate 4. När förfrågan är gjord sjunker mätaren till "after".
##
## Utlösningen (varje spelbar tidszon, efter att mätarna har vuxit):
##   1. Mätaren ≥ threshold, ingen öppen förfrågan, cooldown sedan förra är över,
##      personen är introducerad, inte upptagen och inte borta.
##   2. Chans = 0,25 + 0,75 × (värde − threshold) / (100 − threshold); säker vid 100.
##      Slås fast per dag och tidszon (som Schedules chance), så att det blir samma
##      efter att man har laddat ett spel.
##   3. En typ väljs bland dem personen har vars min_rank uppfylls, viktat med weight.
##   4. Är hon i samma rum säger personen det direkt, annars kommer ett sms.
## En förfrågan som inte görs inom expires dagar försvinner, och relationen tappar lite.

## Bara vuxna. Sönerna och hunden får aldrig stå här (se _validate).
const DESIRE := {
	# Mammans egen mätare ger inga förfrågningar, se MOM_EFFECTS.
	"mom": {"rate": 3.0, "threshold": 70, "after": 10},
	"husband": {"rate": 4.0, "threshold": 60, "after": 5, "cooldown": 1},
	"neighbor": {"rate": 3.0, "threshold": 60, "after": 10, "cooldown": 2},
	"principal": {"rate": 2.0, "threshold": 65, "after": 15, "cooldown": 3},
}
const WANTS := {
	"son_1": {"rate": 5.0, "threshold": 55, "after": 0, "cooldown": 1},
	"son_2": {"rate": 5.0, "threshold": 55, "after": 0, "cooldown": 1},
}
const NEVER_DESIRE := ["son_1", "son_2", "dog"]

## Vad som höjer de vuxnas desire-mätare: mammans Attractiveness, relationens rank,
## om hon har Date Night-klänningen på sig och om hennes egen mätare är hög.
const DESIRE_PER_ATTRACTIVENESS := 0.15
const DESIRE_PER_RANK := 0.05
const DATE_OUTFIT_BONUS := 1.2
const MOM_SIGNAL := {"min": 40, "bonus": 1.15}
## Sönerna vill mer på helgen, när de har tid att komma på saker.
const WEEKEND_WANTS_BONUS := 1.3

## Vad mammans egen mätare gör. Allt hon gör som har "relief" sänker mätaren med
## relief_scale × relief.
const MOM_EFFECTS := {"relief_scale": 2}

const LINK_PENALTY := {"declined": -1, "expired": -2}
## När hon säger nej sjunker mätaren bara så här mycket (andel av vägen ner till "after").
const DECLINE_RELIEF := 0.5

## Förfrågningarna: person -> [typ]. Varje typ har samma fält som en handling i
## RoomActions (label, text, time, effects, social, link_points, cost, earn, earn_scale,
## income, requires, periods), och dessutom:
##   id       – unik i hela listan
##   ask      – vad personen säger, direkt eller i ett sms
##   weight   – hur ofta den väljs jämfört med personens andra typer
##   min_rank – lägsta rank i relationen för att typen ska komma
##   room     – var den görs; utan room görs den där personen är
##   owes     – hur många sysslor personen tar åt henne efteråt (se CHORES)
##   expires  – dagar innan den försvinner (EXPIRES annars)
## Texterna är platshållare tills riktig story och dialog skrivs.
const EXPIRES := 2
const TYPES := {
	# --- Sönerna (wants) ---
	"son_1": [
		{"id": "son1_game_money", "weight": 3, "ask": "Mom… the new expansion dropped. Could you spot me $60? I'll do the dishes. For real.",
			"label": "Give him $60 for the expansion", "text": "He grabs your card, buys it in four seconds and swears on his headset that he'll pay you back in dishes.",
			"cost": 60, "owes": 2, "link_points": 2},
		{"id": "son1_ride", "weight": 2, "ask": "Can you drive me to Eli's? Their whole squad is doing a LAN night.",
			"label": "Drive him to his friend's", "text": "He talks about patch notes the whole way. At the curb he mumbles a thank-you and promises to walk the dog all week.",
			"time": true, "owes": 2, "link_points": 2},
		{"id": "son1_late", "weight": 2, "ask": "There's a tournament tonight. Can I stay up? Just this once. I'll take the laundry down tomorrow.",
			"label": "Let him stay up for the tournament", "text": "You hear him cheering at 1 a.m. His team wins. He'll be a zombie tomorrow, but a happy one.",
			"periods": ["evening"], "effects": {"home": -3}, "owes": 1, "link_points": 2},
	],
	"son_2": [
		{"id": "son2_gear", "weight": 3, "ask": "My gloves are falling apart, Coach says I need new ones before Saturday. $45?",
			"label": "Pay for his new gloves", "text": "He tries them on right there in the hallway and makes a one-handed catch with a sock. Deal: he takes the plants and the dog.",
			"cost": 45, "owes": 2, "link_points": 2},
		{"id": "son2_drills", "weight": 2, "ask": "Can you run drills with me? I need someone to throw. I'll do the boxes in the attic, promise.",
			"label": "Run drills with him", "text": "You throw until your arm aches. He catches everything and keeps saying 'one more'.",
			"time": true, "social": {"fitness": 2}, "owes": 2, "link_points": 3},
		{"id": "son2_friends", "weight": 1, "min_rank": 2, "ask": "Can the guys come over Saturday to watch the game? We'll clean up after. All of it.",
			"label": "Let his friends come over", "text": "Six teenagers, four pizzas and one very excited dog. They actually do clean up. Mostly.",
			"effects": {"home": -5}, "owes": 3, "link_points": 3},
	],
	# --- Vuxna (desire). Belöningen är pengar eller att maken tar sysslor. ---
	"husband": [
		{"id": "husband_date", "weight": 3, "ask": "Kids are out of our hair tonight. Let me take you out. Just us.",
			"label": "Go out with him tonight", "text": "He books a table and holds your hand across it all evening. On the way home he says the dishes are his for the week. (Placeholder scene.)",
			"time": true, "periods": ["evening"], "relief": 15, "owes": 3, "link_points": 3},
		{"id": "husband_early", "weight": 3, "ask": "Come to bed early tonight?",
			"label": "Go to bed early with him", "text": "You leave the rest of the evening for tomorrow. (Placeholder scene.)",
			"time": true, "periods": ["evening"], "room": "bedroom", "relief": 12, "owes": 2, "link_points": 3},
		{"id": "husband_dress", "weight": 1, "min_rank": 3, "requires": {"charm": 3}, "ask": "Wear that dress for me tonight? The one from the boutique.",
			"label": "Put on the dress for him", "text": "He forgets what he was saying halfway through the sentence. Then he offers to cook. Twice. (Placeholder scene.)",
			"periods": ["evening"], "relief": 10, "social": {"charm": 1}, "owes": 2, "link_points": 2},
	],
	"neighbor": [
		{"id": "neighbor_photos", "weight": 2, "requires": {"attractiveness": 3}, "ask": "I'm putting together a portfolio and I'd love you as a model. Paid, of course.",
			"label": "Model for the neighbor's portfolio", "text": "A few hours of lights and quiet direction. The neighbor pays in cash and says the camera loves you. (Placeholder scene.)",
			"time": true, "room": "neighbor_living", "relief": 5, "social": {"charm": 2},
			"earn": 80, "earn_scale": {"charm": 20}, "income": "modeling", "link_points": 3},
		{"id": "neighbor_art", "weight": 2, "min_rank": 2, "ask": "Could you help me hang the new art this afternoon? You have a better eye than me. I'll pay for your time.",
			"label": "Help the neighbor hang the art", "text": "You move every frame twice. Somewhere in there you end up standing very close. The neighbor insists you take the money. (Placeholder scene.)",
			"time": true, "periods": ["afternoon"], "room": "neighbor_living", "relief": 8, "social": {"charm": 1},
			"earn": 50, "earn_scale": {"knowledge": 10}, "link_points": 3},
	],
	"principal": [
		{"id": "principal_late", "weight": 3, "ask": "Could you stay late and help me with the board presentation? There's a stipend in it.",
			"label": "Stay late to help the principal", "text": "Slides, coffee and a lot of eye contact across the table. The stipend comes through the next morning. (Placeholder scene.)",
			"time": true, "room": "teachers_lounge", "effects": {"work": 10}, "social": {"knowledge": 2},
			"earn": 60, "earn_scale": {"knowledge": 15}, "link_points": 2},
		{"id": "principal_gala", "weight": 1, "min_rank": 3, "requires": {"attractiveness": 4}, "ask": "I need a plus-one for the donor gala. You'd make a better impression than anyone. I'll make it worth your while.",
			"label": "Be the principal's plus-one at the gala", "text": "You work the room on the principal's arm and two donors sign on the spot. An envelope finds its way into your purse. (Placeholder scene.)",
			"time": true, "periods": ["evening"], "room": "restaurant", "effects": {"work": 15}, "relief": 5, "social": {"charm": 3},
			"earn": 150, "earn_scale": {"charm": 25}, "link_points": 3},
	],
}

## Sysslor man kan be någon som är skyldig en tjänst att göra. chore: id i
## RoomActions.ACTIONS; helpers: vilka som kan göra den (och är hemma). Delegerat ger det
## samma effekter men tar ingen tid för mamman.
const CHORES := {
	"kitchen_dishes": {"helpers": ["son_1", "son_2", "husband"], "text": "%s does the dishes, complaining the whole time."},
	"kitchen_cook": {"helpers": ["husband"], "text": "%s makes his famous pasta. It's the only thing he makes."},
	"hall_walk_dog": {"helpers": ["son_1", "son_2"], "text": "%s grabs the leash. The dog is thrilled."},
	"laundry_wash": {"helpers": ["son_1", "husband"], "text": "%s starts a load. You decide not to check how he sorted it."},
	"attic_boxes": {"helpers": ["son_2", "husband"], "text": "%s hauls the boxes around until the attic looks sorted."},
	"upstairs_laundry": {"helpers": ["son_1", "son_2"], "text": "%s collects the laundry from the hamper."},
	"yard_plants": {"helpers": ["son_2"], "text": "%s waters the plants and the dog, too."},
	"garden_water": {"helpers": ["son_2", "husband"], "text": "%s takes the hose to the flower beds. Most of the water lands on the plants."},
}
## Mest skulder en person kan ha till mamman åt gången.
const MAX_OWED := 5


static func meter_info(character_id: String) -> Dictionary:
	return DESIRE.get(character_id, WANTS.get(character_id, {}))


static func is_desire(character_id: String) -> bool:
	return DESIRE.has(character_id)


## Personerna som kan komma med förfrågningar (alla utom mamman).
static func requesters() -> Array:
	return (DESIRE.keys() + WANTS.keys()).filter(func(id: String) -> bool: return id != "mom")


## Hur mycket en mätare växer på en tidszon. mult är multiplikatorerna som GameState
## räknar fram (Attractiveness, rank, kläder ...).
static func growth(character_id: String, value: float, mult: float) -> float:
	return meter_info(character_id).get("rate", 0.0) * mult * (0.5 + value / 100.0)


## Chansen att en förfrågan kommer, 0–1, eller 0 under tröskeln.
static func trigger_chance(character_id: String, value: float) -> float:
	var threshold: float = meter_info(character_id).get("threshold", 100)
	if value < threshold:
		return 0.0
	return clampf(0.25 + 0.75 * (value - threshold) / (100.0 - threshold), 0.0, 1.0)


## Ett tärningsslag 0–1 som är samma för samma person, dag, tidszon och syfte.
static func roll(character_id: String, day: int, period: String, purpose: String) -> float:
	return posmod(hash("%s|%s|%d|%s" % [character_id, purpose, day, period]), 1000) / 1000.0


## Väljer en typ bland dem personen kan få vid sin rank, eller {}. Typer vars krav
## (requires) mamman uppfyller går först; finns ingen sådan kan en låst komma ändå,
## så att spelaren ser vad som saknas.
static func pick_type(character_id: String, rank: int, roll_value: float) -> Dictionary:
	var options: Array = TYPES.get(character_id, []).filter(func(t: Dictionary) -> bool: return rank >= t.get("min_rank", 1))
	var doable := options.filter(func(t: Dictionary) -> bool: return GameState.requirement_block_reason(t.get("requires", {})) == "")
	if not doable.is_empty():
		options = doable
	var total := 0
	for t in options:
		total += t.get("weight", 1)
	var pick := roll_value * total
	for t in options:
		pick -= t.get("weight", 1)
		if pick < 0:
			return t
	return {} if options.is_empty() else options.back()


static func find_type(type_id: String) -> Dictionary:
	for character_id in TYPES:
		for t in TYPES[character_id]:
			if t["id"] == type_id:
				return t
	return {}


## Val som genereras för ett rum: öppna förfrågningar där de kan göras (och ett nej),
## och sysslor att be någon som är skyldig en tjänst om. Samma form som RoomActions.
static func actions_for_room(room_id: String) -> Array:
	var result := []
	for character_id in GameState.requests:
		var request: Dictionary = GameState.requests[character_id]
		var t := find_type(request["type"])
		var where: String = t.get("room", GameState.get_character_room(character_id))
		if where != room_id:
			continue
		var person := GameState.character_name(character_id)
		var action := t.duplicate()
		for key in ["ask", "weight", "min_rank", "room", "owes", "expires"]:
			action.erase(key)
		action.merge({"id": "request_" + t["id"], "object": "", "link": character_id, "fulfills": character_id,
			"ledger_label": t["label"]}, true)
		action["link_points"] = t.get("link_points", 1)
		if t.get("earn", 0) <= 0:
			action.erase("earn")
		if not t.has("room"):
			action["needs"] = character_id
		elif character_id == "husband":
			action["needs_home"] = character_id
		result.append(action)
		if GameState.get_character_room(character_id) == room_id:
			result.append({"id": "decline_" + t["id"], "object": "", "label": "Tell %s not now" % person,
				"text": "You tell %s maybe another time. It doesn't go down great." % person, "declines": character_id})
	for chore_id in CHORES:
		var chore := _chore_action(chore_id, room_id)
		if not chore.is_empty():
			result.append(chore)
	return result


## Ett val att låta någon som är skyldig en tjänst göra sysslan, eller {} om ingen kan.
static func _chore_action(chore_id: String, room_id: String) -> Dictionary:
	var original: Dictionary = {}
	for action in RoomActions.ACTIONS.get(room_id, []):
		if action["id"] == chore_id:
			original = action
	if original.is_empty():
		return {}
	for helper in CHORES[chore_id]["helpers"]:
		var owed: int = GameState.owed.get(helper, 0)
		if owed <= 0:
			continue
		var where := GameState.get_character_room(helper)
		if where == "" or not GameState.ROOMS[where]["floor"] in GameState.HOME_FLOORS or GameState.is_busy(helper):
			continue
		var person := GameState.character_name(helper)
		return {"id": "delegate_" + chore_id, "object": original.get("object", ""),
			"label": "Ask %s to %s (owes you %d)" % [person, original["label"].to_lower(), owed],
			"text": CHORES[chore_id]["text"] % person, "effects": original.get("effects", {}), "delegates": helper,
			"delegated_chore": chore_id}
	return {}


## Kollar att ingen familjemedlem under 18 har hamnat i desire-spåret. Anropas vid start.
static func validate() -> void:
	for character_id in NEVER_DESIRE:
		assert(not DESIRE.has(character_id) and not TYPES.get(character_id, []).any(
			func(t: Dictionary) -> bool: return t.has("relief")),
			"%s får aldrig ha desire eller romantiska förfrågningar" % character_id)
