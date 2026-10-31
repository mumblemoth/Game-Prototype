extends CanvasLayer
## Spelar morgon- och nattscener (StoryScenes) över allt annat: tonar ned bakgrunden,
## visar scenens rubrik och tidszon och en ljus textruta i Harem Heaven-stil med en
## replik i taget. Klick eller valfri tangent visar nästa replik; efter sista repliken
## får GameState veta att scenen är slut. Spelar också scenminnen från telefonen igen.

const INK := Color(0.15, 0.15, 0.2)

var _lines: Array = []
var _index := 0
## Om ett minne spelas igen (då ändras inget i spelet när det är slut).
var _replaying := false
var _title: Label
var _speaker: Label
var _text: Label


func _ready() -> void:
	layer = 6
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.06, 0.1, 0.82)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_next())
	add_child(shade)
	_title = Label.new()
	_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title.offset_top = 200
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", Color.WHITE)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.95, 0.92)
	style.border_color = INK
	style.set_border_width_all(2)
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(240, 520)
	panel.size = Vector2(800, 150)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", 20)
	_speaker.add_theme_color_override("font_color", Color(0.75, 0.3, 0.25))
	column.add_child(_speaker)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(730, 70)
	_text.add_theme_font_size_override("font_size", 22)
	_text.add_theme_color_override("font_color", INK)
	column.add_child(_text)
	var hint := Label.new()
	hint.text = "Click to continue"
	hint.position = Vector2(240, 676)
	hint.size = Vector2(800, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	GameState.scene_requested.connect(play)
	GameState.scene_finished.connect(func() -> void: visible = false)
	GameState.memory_replay_requested.connect(replay)


func play(scene_id: String) -> void:
	_replaying = false
	var title: String = StoryScenes.get_scene(scene_id).get("title", "")
	var period: String = GameState.PERIOD_NAMES[GameState.get_time_of_day()]
	_start(StoryScenes.lines_for(scene_id, GameState.flags), "%s\n%s · %s" % [title, GameState.get_weekday(), period])


## Upplever ett minne igen: samma repliker som då och dagen det hände i rubriken.
func replay(memory_id: String) -> void:
	_replaying = true
	var record: Dictionary = GameState.memories[memory_id]
	var replay_data: Dictionary = record["replay"]
	var title: String = PhoneData.MEMORIES[memory_id]["title"]
	var when := "%s · %s" % [GameState.weekday_of(record["day"]), GameState.PERIOD_NAMES[record["period"]]]
	_start(StoryScenes.lines_for(replay_data["scene"], replay_data["flags"]), "%s\nMemory · Day %d · %s" % [title, record["day"], when])


func _start(lines: Array, title: String) -> void:
	_lines = lines
	_index = 0
	_title.text = title
	visible = true
	_show_line()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo:
		_next()
		get_viewport().set_input_as_handled()


func _show_line() -> void:
	if _index >= _lines.size():
		visible = false
		if _replaying:
			_replaying = false
			GameState.finish_replay()
		else:
			GameState.finish_scene()
		return
	var line: Array = _lines[_index]
	_speaker.text = line[0]
	_speaker.visible = line[0] != ""
	_text.text = line[1]


func _next() -> void:
	_index += 1
	_show_line()
