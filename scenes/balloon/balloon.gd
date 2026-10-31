class_name StoryBalloon extends CanvasLayer
## Dialogrutan för storyn. Läser en StoryScript och spelar upp den, utan Dialogue Manager.

signal finished

const STORY := preload("res://scripts/story/story_script.gd")

const SFX_DIR := "res://audio/sfx/"
const SFX_EXTENSIONS := ["ogg", "wav", "mp3"]
const ACTION_COLOR := Color(1, 1, 1, 0.6)
const BOX_WIDTH := 680.0
const BOX_HEIGHT := 140.0
const BOX_BOTTOM := 14.0
const TEXT_SIZE := 19
const NAME_SIZE := 17
const RESPONSE_SIZE := 19
const TYPE_SPEED := 0.012

var locals := {}
var _story
var _block: Array = []
var _index := 0
var _typing := false
var _waiting := false
var _advance := false
var _skip := false

var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()

static var LOCALS_RE := RegEx.create_from_string("^locals\\.(\\w+)\\s*(\\+=|=)\\s*(.+)$")
static var LOCALS_REF_RE := RegEx.create_from_string("locals\\.(\\w+)")

@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var balloon: Control = %Balloon
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var dialogue_label: RichTextLabel = %DialogueLabel
@onready var responses_menu: VBoxContainer = %ResponsesMenu
@onready var progress: Polygon2D = %Progress


func _ready() -> void:
	balloon.hide()
	_apply_kit_style()
	add_child(sfx_player)


func _exit_tree() -> void:
	GameState.set_dialogue_open(self, false)


func _unhandled_input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	var mouse := event as InputEventMouseButton
	var clicked: bool = mouse != null and mouse.is_pressed() and mouse.button_index == MOUSE_BUTTON_LEFT
	if _typing:
		if clicked or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_skip = true
		return
	if _waiting and (clicked or event.is_action_pressed("ui_accept")):
		_advance = true


## Spelar upp scenen från cue.
func begin(path: String, cue: String) -> void:
	_story = STORY.load_file(path)
	if _story == null:
		_finish()
		return
	locals = {}
	_block = _story.ops
	_index = _story.cue_index(cue)
	GameState.set_dialogue_open(self, true)
	show()
	balloon.show()
	await _run()
	_finish()


func _finish() -> void:
	GameState.set_dialogue_open(self, false)
	finished.emit()
	queue_free()


func _run() -> void:
	while _index < _block.size():
		var op: Dictionary = _block[_index]
		match op["type"]:
			"end":
				return
			"code":
				_exec(op["src"])
				_index += 1
			"say":
				await _show_line(op)
				_index += 1
			"choice":
				var options: Array = []
				while _index < _block.size() and _block[_index]["type"] == "choice":
					options.append(_block[_index])
					_index += 1
				var picked: int = await _ask(options)
				await _run_block(options[picked]["body"])
			_:
				_index += 1


func _run_block(block: Array) -> void:
	var outer_block := _block
	var outer_index := _index
	_block = block
	_index = 0
	await _run()
	_block = outer_block
	_index = outer_index

func _show_line(op: Dictionary) -> void:
	var is_action: bool = op["who"].is_empty()
	character_label.visible = not is_action
	character_label.text = op["who"]
	_apply_tags(op)
	dialogue_label.modulate = ACTION_COLOR if is_action else Color.WHITE
	var text: String = op["text"]
	dialogue_label.text = ("[i]%s[/i]" % text) if is_action else text
	dialogue_label.visible_ratio = 0.0
	progress.visible = false
	await _type_out()
	progress.visible = true
	_waiting = true
	await _wait_for_input()
	_waiting = false


func _type_out() -> void:
	_typing = true
	_skip = false
	var duration := maxf(0.05, dialogue_label.get_total_character_count() * TYPE_SPEED)
	var tween := create_tween()
	tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	while tween.is_valid() and tween.is_running() and not _skip:
		await get_tree().process_frame
	if _skip and tween.is_valid():
		tween.kill()
		dialogue_label.visible_ratio = 1.0
	_typing = false


func _wait_for_input() -> void:
	_advance = false
	while not _advance:
		await get_tree().process_frame


func _ask(options: Array) -> int:
	progress.visible = false
	for child in responses_menu.get_children():
		child.queue_free()
	var picked := [0]
	for i in options.size():
		var button := Button.new()
		button.text = options[i]["text"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		responses_menu.add_child(button)
		button.pressed.connect(_on_option_pressed.bind(i, picked))
	responses_menu.show()
	_advance = false
	while not _advance:
		await get_tree().process_frame
	responses_menu.hide()
	for child in responses_menu.get_children():
		child.queue_free()
	return picked[0]


func _on_option_pressed(index: int, picked: Array) -> void:
	picked[0] = index
	_advance = true


func _apply_tags(op: Dictionary) -> void:
	var char_id := _character_id(op["who"])
	if op["mood"] != "" and char_id != "":
		GameState.mood(char_id, op["mood"])
	if op["pose"] != "" and char_id != "":
		GameState.sprite(char_id, op["pose"])
	if op["sfx"] != "":
		_play_sfx(op["sfx"])


func _character_id(speaker: String) -> String:
	for char_id in GameState.CHARACTERS:
		if GameState.CHARACTERS[char_id]["name"] == speaker:
			return char_id
	return ""


func _play_sfx(sfx_name: String) -> void:
	for extension in SFX_EXTENSIONS:
		var path := "%s%s.%s" % [SFX_DIR, sfx_name, extension]
		if ResourceLoader.exists(path):
			sfx_player.stream = load(path)
			sfx_player.play()
			return
	push_warning("Hittar ingen ljudeffekt: %s" % sfx_name)

## Kör en $>-rad. += skrivs om till en tilldelning för Expression.
func _exec(src: String) -> void:
	var code := src.strip_edges()
	var match := LOCALS_RE.search(code)
	if match != null:
		var key := match.get_string(1)
		if match.get_string(2) == "+=":
			locals[key] = int(locals.get(key, 0)) + int(_eval(match.get_string(3)))
		else:
			locals[key] = _eval(match.get_string(3))
		return
	_eval(code)


func _eval(code: String) -> Variant:
	code = LOCALS_REF_RE.sub(code, 'locals["$1"]', true)
	var expression := Expression.new()
	if expression.parse(code, ["GameState", "locals"]) != OK:
		push_error("Kodfel i dialog: %s" % code)
		return null
	var result: Variant = expression.execute([GameState, locals], self, false)
	if expression.has_execute_failed():
		push_error("Körfel i dialog: %s" % code)
		return null
	return result

func _apply_kit_style() -> void:
	var kit_theme := Theme.new()
	if balloon.theme != null:
		kit_theme = balloon.theme.duplicate() as Theme
	kit_theme.default_font = UiKit.body_font()
	kit_theme.default_font_size = TEXT_SIZE
	kit_theme.set_stylebox("panel", "PanelContainer", UiKit.plate(UiKit.PAPER, 0.0, UiKit.INK, 3, UiKit.INK, Vector2(26, 14)))
	for margin in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		kit_theme.set_constant(margin, "MarginContainer", 0)
	var idle := UiKit.plate(Color(UiKit.INK, 0.92), UiKit.SLANT, Color(UiKit.PAPER, 0.25), 2, Color(0, 0, 0, 0), Vector2(30, 9))
	var lit := UiKit.plate(UiKit.YELLOW, UiKit.SLANT, Color(0, 0, 0, 0), 0, UiKit.RED, Vector2(30, 9))
	kit_theme.set_stylebox("normal", "Button", idle)
	kit_theme.set_stylebox("disabled", "Button", idle)
	for state in ["hover", "focus", "pressed", "hover_pressed"]:
		kit_theme.set_stylebox(state, "Button", lit)
	kit_theme.set_font("font", "Button", UiKit.display_font())
	kit_theme.set_font_size("font_size", "Button", RESPONSE_SIZE)
	kit_theme.set_color("font_color", "Button", UiKit.PAPER)
	kit_theme.set_color("font_disabled_color", "Button", UiKit.MUTED)
	for state in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		kit_theme.set_color(state, "Button", UiKit.INK)
	balloon.theme = kit_theme
	responses_menu.add_theme_constant_override("separation", 8)
	
	var box := balloon.get_node("MarginContainer") as Control
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.offset_left = -BOX_WIDTH / 2.0
	box.offset_right = BOX_WIDTH / 2.0
	box.offset_top = -BOX_HEIGHT - BOX_BOTTOM
	box.offset_bottom = -BOX_BOTTOM
	
	character_label.modulate = Color.WHITE
	character_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	character_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	character_label.add_theme_stylebox_override("normal", UiKit.plate(UiKit.YELLOW, UiKit.SLANT, Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), Vector2(14, 1)))
	character_label.add_theme_font_override("normal_font", UiKit.display_font())
	character_label.add_theme_font_size_override("normal_font_size", NAME_SIZE)
	character_label.add_theme_color_override("default_color", UiKit.INK)
	dialogue_label.add_theme_color_override("default_color", UiKit.INK)
	dialogue_label.add_theme_font_override("normal_font", UiKit.body_font())
	dialogue_label.add_theme_font_override("italics_font", UiKit.display_font())
	dialogue_label.add_theme_font_override("bold_font", UiKit.body_font(true))
	for font_size in ["normal_font_size", "italics_font_size", "bold_font_size"]:
		dialogue_label.add_theme_font_size_override(font_size, TEXT_SIZE)
	progress.color = UiKit.INK