class_name StoryScenes
## Spelets scener på morgonen och natten, som inte är spelbara. Varje scen har:
##   day     – vilken dag den spelas (1 = första dagen)
##   period  – "morning" eller "night"
##   title   – rubrik som visas överst (valfri)
##   lines   – repliker i ordning: [talare, text]. Tom talare betyder berättartext.
##             Ett tredje värde gör repliken villkorad: en händelse (GameState.flags)
##             som måste ha hänt ("met_neighbor") eller inte ("!met_neighbor").
## Saknar en dag morgonscen börjar spelaren direkt på eftermiddagen; saknar den nattscen
## går spelet direkt till nästa dag. Platshållare tills riktig story skrivs.

const SCENES := {
	"day1_morning": {
		"day": 1,
		"period": "morning",
		"title": "The First Day",
		"lines": [
			["", "The alarm goes off. Another week begins. (Placeholder morning scene.)"],
			["Mom", "Okay. Coffee, classes, dinner. I can do this."],
			["", "The school day flies by. By the time she gets home, it's afternoon."],
		],
	},
	"day1_night": {
		"day": 1,
		"period": "night",
		"title": "Night",
		"lines": [
			["", "The house goes quiet. (Placeholder night scene.)"],
			["Mom", "One day at a time."],
		],
	},
}


## Scenen för en dag och tidszon, eller tom sträng om ingen finns.
static func find(day: int, period: String) -> String:
	for scene_id in SCENES:
		var scene: Dictionary = SCENES[scene_id]
		if scene["day"] == day and scene["period"] == period:
			return scene_id
	return ""


static func get_scene(scene_id: String) -> Dictionary:
	return SCENES.get(scene_id, {})


## Scenens repliker som visas med de här händelserna. Ett minne sparar händelserna
## från när scenen spelades, så att den blir likadan när den upplevs igen.
static func lines_for(scene_id: String, flags: Dictionary) -> Array:
	var shown := []
	for line in get_scene(scene_id).get("lines", []):
		if line.size() > 2:
			var flag: String = line[2]
			if flags.get(flag.trim_prefix("!"), false) == flag.begins_with("!"):
				continue
		shown.append(line)
	return shown
