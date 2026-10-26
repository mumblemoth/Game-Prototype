class_name Dispatcher
## Väljer vilken rankscen som spelas i en tidszon. Läser villkoren i Balance.GATES; en
## scen som har en rad där är registrerad. Dialogfilen hittas på
## res://dialogue/<char>/<scen_id>.dialogue om SCENES inte säger något annat.

## Var dialogfilerna ligger: mapp per person (id i GameState.CHARACTERS).
const DIALOGUE_PATH := "res://dialogue/%s/%s.dialogue"
## Cuen scenerna börjar på om SCENES inte säger något annat.
const DEFAULT_CUE := "start"
## Händelsen (GameState.flags) som sätts när en scen är spelad: prefix + scen_id.
const DONE_FLAG := "scene_done_"
## Suffixet för en scens bonusvariant (CONTRACT.md, avsnitt 3).
const BONUS_SUFFIX := "_bonus"

## Undantag från standardvägen: scen_id -> {"dialogue": sökväg, "cue": cue}.
const SCENES := {
}


## Scenen som ska spelas i tidszonen (index i GameState.TIME_PERIODS), eller "" om ingen.
## Med char_id väljs bara bland den personens scener. Finns flera klara scener vinner
## den med högst rank.
static func resolve_slot(period: int, char_id := "") -> String:
	var best := ""
	var best_rank := 0
	for scene_id in Balance.GATES:
		var gate: Dictionary = Balance.GATES[scene_id]
		if char_id != "" and gate["char"] != char_id:
			continue
		if gate["rank"] > best_rank and is_ready(scene_id, period):
			best = scene_id
			best_rank = gate["rank"]
	return best


## Om scenen kan spelas nu: rätt tidszon och rum, inte redan spelad, föregående rank
## spelad, och relationen och mamman når upp till villkoren.
static func is_ready(scene_id: String, period: int) -> bool:
	var gate: Dictionary = Balance.GATES[scene_id]
	var char_id: String = gate["char"]
	var rank: int = gate["rank"]
	if not GameState.links.has(char_id) or is_done(scene_id):
		return false
	if period < 0 or period >= GameState.TIME_PERIODS.size() or GameState.TIME_PERIODS[period] != gate["period"]:
		return false
	if gate.has("room") and GameState.current_room != gate["room"]:
		return false
	var previous := scene_for(char_id, rank - 1)
	if previous != "" and not is_done(previous):
		return false
	var link: Dictionary = GameState.links[char_id]
	return link["points"] >= GameState.LINK_THRESHOLDS[rank] \
		and link["lust"] >= gate["lust"] \
		and GameState.attractiveness_tier() >= gate["attr"]


## Personens scen för en rank, eller "".
static func scene_for(char_id: String, rank: int) -> String:
	for scene_id in Balance.GATES:
		var gate: Dictionary = Balance.GATES[scene_id]
		if gate["char"] == char_id and gate["rank"] == rank:
			return scene_id
	return ""


static func is_done(scene_id: String) -> bool:
	return GameState.has_flag(DONE_FLAG + base_id(scene_id))


## Grundscenen för en bonusvariant ("eric_r1_bonus" -> "eric_r1").
static func base_id(scene_id: String) -> String:
	return scene_id.trim_suffix(BONUS_SUFFIX)


static func dialogue_path(scene_id: String) -> String:
	var gate: Dictionary = Balance.GATES[base_id(scene_id)]
	return SCENES.get(scene_id, {}).get("dialogue", DIALOGUE_PATH % [gate["char"], scene_id])


static func cue(scene_id: String) -> String:
	return SCENES.get(scene_id, {}).get("cue", DEFAULT_CUE)
