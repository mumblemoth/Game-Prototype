class_name StoryScript
extends RefCounted
## Tolkar en .dialogue-fil till operations och spelar upp dem. Ersätter Dialogue Manager,
## så att dialogfilerna läses som vanlig text utan importeringssteg.

var ops: Array = []
var _lines: PackedStringArray
var _at := 0
var _cues := {}


## Läser och tolkar en fil. Null om filen inte går att öppna.
static func load_file(path: String) -> StoryScript:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Kan inte läsa dialogfilen: %s" % path)
		return null
	var story = new()
	story.parse(file.get_as_text())
	return story


func parse(text: String) -> void:
	_lines = text.split("\n")
	_at = 0
	ops = _parse_block(0)


## Var en cue börjar i ops, eller 0.
func cue_index(cue: String) -> int:
	return _cues.get(cue, 0)


func _indent_of(raw: String) -> int:
	var n := 0
	for character in raw:
		if character == "\t" or character == " ":
			n += 1
		else:
			break
	return n


func _parse_block(depth: int) -> Array:
	var out: Array = []
	while _at < _lines.size():
		var raw: String = _lines[_at]
		var trimmed := raw.strip_edges()
		if trimmed == "" or trimmed.begins_with("#"):
			_at += 1
			continue
		if _indent_of(raw) < depth:
			break
		if trimmed.begins_with("~ "):
			_cues[trimmed.substr(2).strip_edges()] = out.size()
			_at += 1
			continue
		if trimmed == "=> END":
			out.append({"type": "end"})
			_at += 1
			continue
		if trimmed.begins_with("- "):
			var option := {"type": "choice", "text": trimmed.substr(2).strip_edges(), "body": []}
			_at += 1
			option["body"] = _parse_block(depth + 1)
			out.append(option)
			continue
		if trimmed.begins_with("$> "):
			out.append({"type": "code", "src": trimmed.substr(3)})
			_at += 1
			continue
		out.append(_say_op(trimmed))
		_at += 1
	return out


## En replik: talare, taggar och text. Utan talare blir det en action-rad.
func _say_op(trimmed: String) -> Dictionary:
	var op := {"type": "say", "who": "", "text": trimmed, "mood": "", "pose": "", "sfx": ""}
	var colon := trimmed.find(":")
	if colon > 0 and colon < 24:
		op["who"] = trimmed.substr(0, colon).strip_edges()
		op["text"] = trimmed.substr(colon + 1).strip_edges()
	var text: String = op["text"]
	while text.begins_with("["):
		var close := text.find("]")
		if close < 0:
			break
		for pair in text.substr(1, close - 1).split(","):
			var entry := pair.strip_edges()
			if not entry.contains("="):
				continue
			var key := entry.get_slice("=", 0).strip_edges().trim_prefix("#")
			if op.has(key):
				op[key] = entry.get_slice("=", 1).strip_edges()
		text = text.substr(close + 1).strip_edges()
	op["text"] = text
	return op