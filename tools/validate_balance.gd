@tool
extends EditorScript
## Kontrollerar Balance.GATES och Balance.EFFECTS mot GameState och Dispatcher.
## Kör från editorn: öppna skriptet och välj File > Run. Kräver inte att spelet körs –
## skripten laddas direkt i stället för att gå via GameState-autoloaden.
## Ändrar ingenting, skriver bara ut en rapport.

const GS := preload("res://scripts/game_state.gd")
const BAL := preload("res://scripts/balance.gd")
const DISP := preload("res://scripts/story/dispatcher.gd")

## De enda nycklar en EFFECTS-rad får ha (de som GameState.apply() läser).
const EFFECT_KEYS := ["link_points", "lust", "stats", "relief", "flags"]
## Mappen med en undermapp per person; varje .dialogue-fil heter som sitt scen_id.
const DIALOGUE_ROOT := "res://dialogue"


func _run() -> void:
	validate()


## Kör alla kontroller, skriver ut rapporten och returnerar [fel, varningar].
static func validate() -> Array[int]:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var gates: Dictionary = BAL.GATES
	var effects: Dictionary = BAL.EFFECTS

	# (char, rank) -> första scen_id med det paret.
	var seen := {}
	# char -> ranker som finns.
	var ranks_by_char := {}

	for scene_id in gates:
		var gate = gates[scene_id]
		if not gate is Dictionary:
			errors.append("%s: GATES row is not a Dictionary" % scene_id)
			continue

		var char_id = gate.get("char")
		var char_ok: bool = char_id is String and GS.CHARACTERS.has(char_id)
		if not char_ok:
			errors.append("%s: char %s is not a key in GameState.CHARACTERS" % [scene_id, _show(char_id)])

		var rank = gate.get("rank")
		var rank_ok: bool = rank is int and rank >= 1 and rank <= GS.LINK_MAX_RANK
		if not rank_ok:
			errors.append("%s: rank %s must be an int in 1..%d" % [scene_id, _show(rank), GS.LINK_MAX_RANK])

		var period = gate.get("period")
		if not (period is String and period in GS.TIME_PERIODS):
			errors.append("%s: period %s is not in GameState.TIME_PERIODS" % [scene_id, _show(period)])

		# Rummet är valfritt, men finns nyckeln måste den peka på ett riktigt rum.
		# "" kan aldrig vara lika med current_room, så då kan scenen aldrig spelas.
		if gate.has("room"):
			var room = gate["room"]
			if room is String and room == "":
				warnings.append("%s: room is \"\" – the dispatcher checks gate.has(\"room\"), so this gate can never open" % scene_id)
			elif not (room is String and GS.ROOMS.has(room)):
				errors.append("%s: room %s is not a key in GameState.ROOMS" % [scene_id, _show(room)])

		var lust = gate.get("lust")
		if not (lust is float and lust >= 0.0):
			errors.append("%s: lust %s must be a float >= 0" % [scene_id, _show(lust)])

		var attr = gate.get("attr")
		if not (attr is int and attr >= 1):
			errors.append("%s: attr %s must be an int >= 1" % [scene_id, _show(attr)])

		# Dialogfilen, med samma upplösning som Dispatcher.dialogue_path().
		if char_ok:
			var path: String = DISP.SCENES.get(scene_id, {}).get("dialogue", DISP.DIALOGUE_PATH % [char_id, scene_id])
			if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
				errors.append("%s: dialogue file missing at %s" % [scene_id, path])

		# Grundscener faller inte tillbaka på något – de måste ha en egen rad.
		if not effects.has(scene_id):
			errors.append("%s: no EFFECTS row for this scene" % scene_id)

		if char_ok and rank_ok:
			var pair := "%s/%d" % [char_id, rank]
			if seen.has(pair):
				errors.append("%s: same (char, rank) = (%s, %d) as %s" % [scene_id, char_id, rank, seen[pair]])
			else:
				seen[pair] = scene_id
			if not ranks_by_char.has(char_id):
				ranks_by_char[char_id] = []
			if not rank in ranks_by_char[char_id]:
				ranks_by_char[char_id].append(rank)

	# Rankerna per person börjar på 1 och har inga hål.
	for char_id in ranks_by_char:
		var ranks: Array = ranks_by_char[char_id]
		ranks.sort()
		var missing: Array[int] = []
		for r in range(1, ranks.back() + 1):
			if not r in ranks:
				missing.append(r)
		if not missing.is_empty():
			errors.append("%s: ranks %s present but %s missing – the chain stops before the gap" % [char_id, ranks, missing])

	var suffix: String = DISP.BONUS_SUFFIX
	for scene_id in effects:
		var row = effects[scene_id]
		var is_bonus: bool = scene_id.ends_with(suffix)
		var base: String = scene_id.trim_suffix(suffix)
		if is_bonus:
			# Bonusraden hör till en grundscen i GATES.
			if not gates.has(base):
				warnings.append("%s: bonus row has no base scene %s in GATES" % [scene_id, base])
		elif not gates.has(scene_id):
			errors.append("%s: EFFECTS row has no GATES row (not a base scene)" % scene_id)

		if not row is Dictionary:
			errors.append("%s: EFFECTS row is not a Dictionary" % scene_id)
			continue
		for key in row:
			if not key in EFFECT_KEYS:
				errors.append("%s: unknown EFFECTS key %s (allowed: %s)" % [scene_id, _show(key), ", ".join(EFFECT_KEYS)])
		if row.has("flags") and not row["flags"] is Array:
			errors.append("%s: flags must be an Array, got %s" % [scene_id, type_string(typeof(row["flags"]))])

	# Dialogfiler utan GATES-rad kan dispatchern aldrig spela.
	for path in _dialogue_files():
		var scene_id := path.get_file().get_basename()
		# En _bonus-fil hör till sin grundscens rad.
		if not gates.has(scene_id.trim_suffix(suffix)) and not _is_override(path):
			warnings.append("%s: dialogue file %s has no GATES row – the dispatcher can never play it" % [scene_id, path])

	for line in errors:
		push_error("ERROR " + line)
		print("ERROR " + line)
	for line in warnings:
		push_warning("WARN " + line)
		print("WARN " + line)
	if errors.is_empty() and warnings.is_empty():
		print("balance OK")
	print("%d errors, %d warnings, %d scenes checked" % [errors.size(), warnings.size(), gates.size()])
	return [errors.size(), warnings.size()]


## Alla res://dialogue/<char>/<fil>.dialogue, utom filer som börjar med "_".
static func _dialogue_files() -> Array[String]:
	var files: Array[String] = []
	for dir_name in DirAccess.get_directories_at(DIALOGUE_ROOT):
		var dir := DIALOGUE_ROOT.path_join(dir_name)
		for file in DirAccess.get_files_at(dir):
			if file.begins_with("_") or file.get_extension() != "dialogue":
				continue
			files.append(dir.path_join(file))
	return files


## Om filen är en scens dialog via ett undantag i Dispatcher.SCENES.
static func _is_override(path: String) -> bool:
	for scene_id in DISP.SCENES:
		if DISP.SCENES[scene_id].get("dialogue", "") == path:
			return true
	return false


static func _show(value) -> String:
	if value == null:
		return "<missing>"
	return var_to_str(value)
