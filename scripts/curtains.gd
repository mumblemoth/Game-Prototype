class_name Curtains
## Gardinerna i husets rum: vilket läge ("open", "half" eller "closed") de har just nu.
## Läget räknas fram i tre lager, och det första som ger ett svar vinner:
##   1. Mamman själv – hon har dragit för eller ifrån (valet i rummets meny, eller när
##      hon byter om). Det gäller resten av tidszonen; sedan tar reglerna över igen.
##   2. Regler (RULES) – sammanhanget i huset: vem som är i rummet, vad de gör och tiden
##      på dygnet. Son 1 drar för när han spelar, den som sover har mörkt, och så vidare.
##   3. Fönstrets eget läge ("default" i FloorPlanArt.WINDOWS, annars "open").
## Alla fönster i ett rum följer samma läge. HouseView3D frågar state_for() när tidszonen
## byts och när någon flyttar sig, och gardinerna glider dit (HouseWindow.set_curtains).
## All text spelaren ser är på engelska.

## Reglerna i ordning; den första som stämmer gäller. Villkoren är valfria:
##   rooms    – bara i dessa rum
##   periods  – bara under dessa tidszoner
##   who      – den här personen är i rummet
##   activity – någon i rummet gör det här (Schedules.ACTIVITIES)
##   nobody   – true: ingen är i rummet
##   flags    – händelser som måste ha hänt ("x") eller inte ("!x")
## state är läget, och text (valfri) förklarar det i rummets meny.
const RULES := [
	# Son 1 drar för när han spelar, annars bländar solen i skärmarna.
	{"id": "gaming_glare", "rooms": ["son_room_1"], "activity": "gaming", "periods": ["afternoon", "evening"], "state": "closed",
			"text": "Son 1 keeps them shut so the sun doesn't glare on his screens."},
	# Den som sover har mörkt.
	{"id": "sleeping", "activity": "sleeping", "state": "closed", "text": "Someone is asleep in here."},
	# Tv-kväll: halvt fördraget, så att kvällssolen inte speglar sig i tv:n.
	{"id": "tv_evening", "rooms": ["living_room"], "activity": "tv", "periods": ["evening"], "state": "half",
			"text": "Half drawn, so the evening sun doesn't reflect on the TV."},
	# Sovrummet och badrummen på kvällen: ingen insyn när lamporna är tända.
	{"id": "evening_privacy", "rooms": ["bedroom", "bathroom", "guest_wc"], "periods": ["evening"], "state": "closed"},
	# Natten: hela huset är fördraget.
	{"id": "night", "periods": ["night"], "state": "closed"},
]

## Mammans egna val: rum -> {"state", "day", "period"}.
static var _manual := {}


## Glömmer mammans val (nytt spel).
static func reset() -> void:
	_manual.clear()


## Läget i ett rum just nu. `default` är fönstrets eget läge när ingen regel gäller.
static func state_for(room_id: String, default := "open") -> String:
	var manual: Dictionary = _manual.get(room_id, {})
	if manual.get("day", -1) == GameState.day and manual.get("period", "") == GameState.get_time_of_day():
		return manual["state"]
	return active_rule(room_id).get("state", default)


## Regeln som bestämmer över ett rums gardiner just nu, eller {} om ingen gör det.
static func active_rule(room_id: String) -> Dictionary:
	var period := GameState.get_time_of_day()
	var present := GameState.get_characters_in(room_id)
	for rule in RULES:
		if not rule.get("rooms", []).is_empty() and not room_id in rule["rooms"]:
			continue
		if not rule.get("periods", []).is_empty() and not period in rule["periods"]:
			continue
		if rule.has("who") and not rule["who"] in present:
			continue
		if rule.has("activity") and not present.any(func(c: String) -> bool: return GameState.where_is(c).get("activity", "") == rule["activity"]):
			continue
		if rule.get("nobody", false) and not present.is_empty():
			continue
		if rule.get("flags", []).any(func(flag: String) -> bool: return flag.begins_with("!") == GameState.has_flag(flag.trim_prefix("!"))):
			continue
		return rule
	return {}


## Mamman drar för eller ifrån i ett rum (gäller resten av tidszonen).
static func set_for_now(room_id: String, state: String) -> void:
	_manual[room_id] = {"state": state, "day": GameState.day, "period": GameState.get_time_of_day()}


## Fönstren med gardiner eller rullgardin som syns i 3D (de södra väggarna är avskurna).
static func curtained_windows(room_id: String) -> Array[Dictionary]:
	return FloorPlanArt.windows(room_id).filter(func(w: Dictionary) -> bool: return w["curtains"] != "none" and w["side"] != "south")


## Valet i rummets meny hemma: dra för om de är ifrån (eller halvt), annars dra ifrån.
## "curtains" är läget valet sätter; house.gd utför det.
static func actions_for_room(room_id: String) -> Array:
	var windows := curtained_windows(room_id)
	if windows.is_empty() or Locations.location_of_room(room_id) != "":
		return []
	var closed := state_for(room_id, windows[0]["default"]) == "closed"
	var blind := windows.all(func(w: Dictionary) -> bool: return w["curtains"] == "blind")
	var what := "blind" if blind else "curtains"
	var label: String
	var text: String
	if closed:
		label = "Raise the blind" if blind else "Open the curtains"
		text = "You let the daylight back in." if GameState.get_time_of_day() in ["morning", "afternoon"] else "You open the %s and look out at the street." % what
	else:
		label = "Lower the blind" if blind else "Draw the curtains"
		text = "You draw the %s." % what
	var reason: String = active_rule(room_id).get("text", "")
	return [{"id": "curtains_" + room_id, "object": "window", "label": label, "text": text if reason == "" else "%s (%s)" % [text, reason],
			"curtains": "open" if closed else "closed"}]
