class_name Schedules
## Scheman för familjen och huvud-NPC:erna (de med en planerad social link). Allt här
## är data plus en ren uppslagsfunktion; resultatet för just nu cachas i
## GameState.whereabouts och frågas därifrån ("var är X nu?").
##
## Tiden går i GameState:s fyra tidszoner, inte i timmar, så ett schema säger var
## personen är under varje tidszon.
##
## Ett schema byggs av tre lager. Det första lagret som ger ett svar vinner:
##   1. Storyöverstyrning – GameState.schedule_overrides, sätts av scener och händelser
##      under spelet ("maken är på tjänsteresa dag 8–10"). Sparas med spelet.
##   2. Regler (RULES) – undantag med villkor, i den ordning de står.
##   3. Rutin (ROUTINES) – veckans vanliga upplägg.
## Hittas inget är personen borta från kartan.
##
## Framtida NPC:er: en person med "introduced_by" i GameState.CHARACTERS finns i datan
## från början, men är inte med i världen förrän händelsen har satts. Före det gäller
## bara storyöverstyrningar och regler med "before_intro" (personen syns då som
## främling, t.ex. "New Neighbor"). När händelsen sätts kliver personen in i sin rutin,
## får en social link och läggs till i telefonen.
## All text spelaren ser är på engelska.

## Vad personerna gör. label syns för spelaren. busy: det går inte att prata med
## personen eller göra något ihop just då. Är personen borta (rum "") är label
## svaret på "var är X?".
const ACTIVITIES := {
	"": {"label": "Away"},
	"breakfast": {"label": "Having breakfast"},
	"sleeping": {"label": "Asleep", "busy": true},
	"work": {"label": "At work"},
	"tv": {"label": "Watching TV"},
	"tinkering": {"label": "Tinkering"},
	"gaming": {"label": "Gaming"},
	"training": {"label": "Working out"},
	"football": {"label": "Throwing a football around"},
	"practice": {"label": "At football practice"},
	"homework": {"label": "Doing homework"},
	"napping": {"label": "Napping"},
	"playing": {"label": "Playing"},
	"at_home": {"label": "At home"},
	"unpacking": {"label": "Unpacking boxes"},
	"yoga": {"label": "At a yoga class"},
	"paperwork": {"label": "Buried in paperwork"},
	"shopping": {"label": "Shopping"},
	"walking": {"label": "Out for a walk"},
}

## Veckorutiner: person -> dagnyckel -> tidszon -> [rum, aktivitet]. Rum "" betyder
## borta från kartan. Dagnycklarna slås upp i ordningen veckodag ("saturday"),
## "weekday"/"weekend" och sist "default"; den första som har tidszonen gäller, så en
## dag behöver bara ange det som skiljer sig.
const ROUTINES := {
	"husband": {
		"default": {"morning": ["kitchen", "breakfast"], "afternoon": ["", "work"], "evening": ["living_room", "tv"], "night": ["bedroom", "sleeping"]},
		"weekend": {"afternoon": ["hobby_room", "tinkering"]},
	},
	"son_1": {
		"default": {"morning": ["kitchen", "breakfast"], "afternoon": ["son_room_1", "gaming"], "evening": ["son_room_1", "gaming"], "night": ["son_room_1", "sleeping"]},
	},
	"son_2": {
		"default": {"morning": ["kitchen", "breakfast"], "afternoon": ["outside", "football"], "evening": ["son_room_2", "training"], "night": ["son_room_2", "sleeping"]},
		"sunday": {"evening": ["son_room_2", "homework"]},
	},
	"dog": {
		"default": {"morning": ["kitchen", "breakfast"], "afternoon": ["living_room", "napping"], "evening": ["living_room", "napping"], "night": ["hall", "sleeping"]},
	},
	# Framtida NPC:er (platshållare tills storyn skrivs).
	"neighbor": {
		"default": {"afternoon": ["neighbor_living", "unpacking"], "evening": ["neighbor_living", "at_home"]},
		"weekend": {"afternoon": ["park", "walking"]},
	},
	"principal": {
		"weekday": {"afternoon": ["teachers_lounge", "paperwork"]},
	},
	"best_friend": {
		"weekend": {"afternoon": ["boutique", "shopping"]},
		"friday": {"evening": ["restaurant", "at_home"]},
	},
}

## Undantag: person -> [regel], den första regeln som stämmer gäller. En regel har id,
## rum och aktivitet ("room", "activity") och villkor, som alla är valfria:
##   periods      – bara under dessa tidszoner
##   weekdays     – bara dessa veckodagar (index 0 = måndag)
##   min_day      – från och med dag; max_day – till och med dag
##   flags        – händelser som måste ha hänt ("met_neighbor") eller inte ("!met_neighbor")
##   quests       – questers läge: {"practice": "active"} eller "completed"
##   link_rank    – lägsta rank i relationer: {"neighbor": 3}
##   if_at        – andra personer måste vara i ett visst rum: {"son_2": "outside"}
##   chance       – sannolikhet 0–1. Slås fast per dag och tidszon, så svaret är detsamma
##                  hur många gånger man frågar, och prognoser stämmer.
##   before_intro – regeln gäller (bara) innan en framtida NPC är introducerad
const RULES := {
	"son_2": [
		{"id": "practice", "weekdays": [1, 3], "periods": ["afternoon"], "room": "", "activity": "practice"},
	],
	"husband": [
		{"id": "late_shift", "weekdays": [0, 1, 2, 3], "periods": ["evening"], "chance": 0.2, "room": "", "activity": "work"},
	],
	"dog": [
		# Hunden följer med Son 2 ut på gården.
		{"id": "fetch", "periods": ["afternoon"], "if_at": {"son_2": "outside"}, "room": "outside", "activity": "playing"},
	],
	"neighbor": [
		{"id": "moving_in", "before_intro": true, "periods": ["afternoon", "evening"], "room": "", "activity": "unpacking"},
		{"id": "yoga", "weekdays": [1, 3], "periods": ["evening"], "room": "yoga_studio", "activity": "yoga"},
		{"id": "settled", "flags": ["neighbor_settled"], "periods": ["afternoon"], "weekdays": [0, 1, 2, 3, 4], "room": "neighbor_living", "activity": "at_home"},
	],
}

## Hur djupt if_at får följa andra personers scheman (skydd mot cirklar).
const MAX_DEPTH := 3


## Var en person är och vad den gör en viss dag och tidszon:
##   {"room": String, "activity": String, "source": String, "stranger": bool}
## room är ett id i GameState.ROOMS, eller "" om personen är borta. source säger vad som
## bestämde det: "story:<id>", "rule:<id>", "routine" eller "" (inget schema).
## stranger: en framtida NPC som syns innan spelaren har träffat personen.
static func resolve(character_id: String, day: int, period: String, depth := 0) -> Dictionary:
	var introduced := GameState.is_introduced(character_id)
	var result := _story_slot(character_id, day, period)
	if result.is_empty():
		result = _rule_slot(character_id, day, period, introduced, depth)
	if result.is_empty() and introduced:
		result = _routine_slot(character_id, day, period)
	if result.is_empty():
		result = {"room": "", "activity": "", "source": ""}
	result["stranger"] = not introduced and result["room"] != ""
	return result


## Text för "var är X?", t.ex. "Kitchen · Having breakfast" eller "At football practice".
static func describe(slot: Dictionary) -> String:
	var label: String = ACTIVITIES.get(slot.get("activity", ""), ACTIVITIES[""])["label"]
	var room: String = slot.get("room", "")
	if room == "":
		return label
	var room_name: String = GameState.ROOMS[room]["name"]
	return room_name if slot.get("activity", "") == "" else "%s · %s" % [room_name, label]


static func is_busy(slot: Dictionary) -> bool:
	return ACTIVITIES.get(slot.get("activity", ""), {}).get("busy", false)


## Nästa gång personen är i ett rum (eller på en plats i Locations), räknat från och med
## en dag och tidszon: {"day": int, "period": String}, eller {} om det inte händer inom
## horizon_days. Utgår från att storyn står still (dagens händelser och quests).
static func next_time_at(character_id: String, place: String, from_day: int, from_period: String, horizon_days := 7) -> Dictionary:
	var start := GameState.TIME_PERIODS.find(from_period)
	for offset in horizon_days * GameState.TIME_PERIODS.size():
		var index := start + offset
		var day := from_day + index / GameState.TIME_PERIODS.size()
		var period: String = GameState.TIME_PERIODS[index % GameState.TIME_PERIODS.size()]
		var room: String = resolve(character_id, day, period)["room"]
		if room != "" and (room == place or Locations.location_of_room(room) == place):
			return {"day": day, "period": period}
	return {}


static func _story_slot(character_id: String, day: int, period: String) -> Dictionary:
	for override_id in GameState.schedule_overrides:
		var o: Dictionary = GameState.schedule_overrides[override_id]
		if o["character"] != character_id or day < o["from_day"] or (o["to_day"] >= 0 and day > o["to_day"]):
			continue
		if not o["periods"].is_empty() and not period in o["periods"]:
			continue
		return {"room": o["room"], "activity": o["activity"], "source": "story:" + override_id}
	return {}


static func _rule_slot(character_id: String, day: int, period: String, introduced: bool, depth: int) -> Dictionary:
	for rule in RULES.get(character_id, []):
		if rule.get("before_intro", false) == introduced:
			continue
		if _rule_matches(character_id, rule, day, period, depth):
			return {"room": rule["room"], "activity": rule.get("activity", ""), "source": "rule:" + rule["id"]}
	return {}


static func _rule_matches(character_id: String, rule: Dictionary, day: int, period: String, depth: int) -> bool:
	if not rule.get("periods", []).is_empty() and not period in rule["periods"]:
		return false
	if not rule.get("weekdays", []).is_empty() and not ((day - 1) % GameState.WEEKDAYS.size()) in rule["weekdays"]:
		return false
	if day < rule.get("min_day", 1) or day > rule.get("max_day", day):
		return false
	for flag in rule.get("flags", []):
		if flag.begins_with("!") == GameState.has_flag(flag.trim_prefix("!")):
			return false
	for quest in rule.get("quests", {}):
		if GameState.quests.get(quest, "") != rule["quests"][quest]:
			return false
	for other in rule.get("link_rank", {}):
		if GameState.links.get(other, {}).get("rank", 0) < rule["link_rank"][other]:
			return false
	for other in rule.get("if_at", {}):
		if depth >= MAX_DEPTH or resolve(other, day, period, depth + 1)["room"] != rule["if_at"][other]:
			return false
	if rule.has("chance"):
		var roll := posmod(hash("%s|%s|%d|%s" % [character_id, rule["id"], day, period]), 1000)
		if roll >= int(rule["chance"] * 1000):
			return false
	return true


static func _routine_slot(character_id: String, day: int, period: String) -> Dictionary:
	var routine: Dictionary = ROUTINES.get(character_id, {})
	var weekday := (day - 1) % GameState.WEEKDAYS.size()
	var keys := [GameState.WEEKDAYS[weekday].to_lower(), "weekend" if weekday >= 5 else "weekday", "default"]
	for key in keys:
		if routine.has(key) and routine[key].has(period):
			var slot: Array = routine[key][period]
			return {"room": slot[0], "activity": slot[1], "source": "routine"}
	return {}
