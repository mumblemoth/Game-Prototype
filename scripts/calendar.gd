class_name Calendar
## Kalendern i telefonen. Den har ingen egen data: händelserna räknas fram ur de system
## som redan bestämmer vad som händer en viss dag, så att kalendern alltid stämmer med
## spelet:
##   StoryScenes – morgon- och nattscener (dag och tidszon)
##   Economy     – lönen, månadens räkningar och veckans räkningar
##   Schedules   – storyöverstyrningar och regler som tar någon någonstans ("practice")
##   Locations   – platser som öppnar en viss dag (min_day)
## Oväntade räkningar och regler med slump (chance) eller som beror på andra (if_at)
## visas inte: de ska komma som en överraskning. Personer man inte har träffat syns inte.
## Prognosen utgår från att storyn står still, som Schedules.next_time_at.
##
## En händelse: {"day": int, "period": String, "title": String, "detail": String,
## "kind": String}. period är "" för det som händer när dagen börjar (pengarna).
## kind är "story", "money", "people" eller "place" och bestämmer färgen.
## All text spelaren ser är på engelska.

## Ordningen inom en dag: det som händer när dagen börjar först, sedan tidszonerna.
const PERIOD_ORDER := ["", "morning", "afternoon", "evening", "night"]


## Alla händelser en dag, i den ordning de händer.
static func events_on(day: int) -> Array:
	var events := []
	_money_events(day, events)
	_story_events(day, events)
	_people_events(day, events)
	_place_events(day, events)
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return PERIOD_ORDER.find(a["period"]) < PERIOD_ORDER.find(b["period"]))
	return events


## Om en händelse redan har hänt. Pengarna dras när dagen börjar, så i dag har de hänt.
static func is_past(event: Dictionary) -> bool:
	if event["day"] != GameState.day:
		return event["day"] < GameState.day
	if GameState.is_day_over():
		return true
	return PERIOD_ORDER.find(event["period"]) < PERIOD_ORDER.find(GameState.get_time_of_day())


## Händelserna som inte har hänt än, från i dag och days dagar framåt, högst limit.
static func upcoming(days: int, limit: int) -> Array:
	var found := []
	for day in range(GameState.day, GameState.day + days):
		for event in events_on(day):
			if not is_past(event):
				found.append(event)
				if found.size() >= limit:
					return found
	return found


## Månadens räkningar med de abonnemang som är tecknade.
static func monthly_bills_due() -> int:
	var total := Economy.monthly_bills_total()
	for subscription in GameState.subscriptions:
		total += Economy.SUBSCRIPTIONS[subscription]["amount"]
	return total


static func _money_events(day: int, events: Array) -> void:
	var day_of_month := Economy.day_of_month(day)
	if day_of_month == Economy.PAYDAY:
		events.append(_event(day, "", "Payday", "+%s from %s" % [Economy.format(Economy.salary(GameState.flags)), Economy.SALARY["employer"]], "money"))
	# Samma villkor som GameState._money_new_day: den allra första månaden dras inget.
	if day_of_month == Economy.BILL_DAY and Economy.month_of(day) > 1:
		events.append(_event(day, "", "Monthly bills", "%s comes out of your account" % Economy.format(monthly_bills_due()), "money"))
	for id in Economy.WEEKLY_BILLS:
		var bill: Dictionary = Economy.WEEKLY_BILLS[id]
		if (day - 1) % GameState.WEEKDAYS.size() == bill["weekday"]:
			events.append(_event(day, "", bill["name"], Economy.format(-bill["amount"]), "money"))


static func _story_events(day: int, events: Array) -> void:
	for scene_id in StoryScenes.SCENES:
		var scene: Dictionary = StoryScenes.SCENES[scene_id]
		if scene["day"] == day:
			events.append(_event(day, scene["period"], scene.get("title", GameState.PERIOD_NAMES[scene["period"]]), "Story scene", "story"))


## Det som tar någon ur sin vanliga rutin. En överstyrning som gäller flera tidszoner
## blir en händelse, i den första tidszonen.
static func _people_events(day: int, events: Array) -> void:
	for character_id in GameState.CHARACTERS:
		if character_id == "mom" or not GameState.is_introduced(character_id):
			continue
		var seen := {}
		for period in GameState.TIME_PERIODS:
			var slot := Schedules.resolve(character_id, day, period)
			var source: String = slot["source"]
			if seen.has(source) or not _is_notable(character_id, source):
				continue
			seen[source] = true
			events.append(_event(day, period, GameState.character_name(character_id), Schedules.describe(slot), "people"))


## Om det som bestämde var personen är hör hemma i kalendern: storyns överstyrningar,
## och regler som går att förutse och tar personen hemifrån (borta, eller till en plats
## i Locations). Att hunden busar på gården är ingen kalenderhändelse.
static func _is_notable(character_id: String, source: String) -> bool:
	if source.begins_with("story:"):
		return true
	if not source.begins_with("rule:"):
		return false
	var rule_id := source.trim_prefix("rule:")
	for rule in Schedules.RULES.get(character_id, []):
		if rule["id"] == rule_id:
			if rule.has("chance") or rule.has("if_at"):
				return false
			return rule["room"] == "" or Locations.location_of_room(rule["room"]) != ""
	return false


static func _place_events(day: int, events: Array) -> void:
	for location_id in Locations.LOCATIONS:
		var location: Dictionary = Locations.LOCATIONS[location_id]
		if location.get("min_day", 1) == day and day > 1:
			events.append(_event(day, "", "%s opens" % location["name"], location.get("description", ""), "place"))


static func _event(day: int, period: String, title: String, detail: String, kind: String) -> Dictionary:
	return {"day": day, "period": period, "title": title, "detail": detail, "kind": kind}
