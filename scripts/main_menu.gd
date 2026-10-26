extends Control
## Titelskärmen i Persona 4-anda: svart bakgrund med gult snedband, mamman i sina två
## roller (hemma och på jobbet) till höger, spelets namn stort och lutande och en
## diagonal lista med val. New Game sveper över till huset med UiTransition.

const MENU_ORIGIN := Vector2(70, 380)
const MENU_STEP := Vector2(16, 66)
const MENU_SIZE := Vector2(360, 54)
const PORTRAITS := [
	["res://Assets/portraits/mom_work_full.png", Vector2(690, 40), 760.0, 0.55],
	["res://Assets/portraits/mom_casual_full.png", Vector2(930, 20), 820.0, 1.0],
]

var _buttons: Array[KitButton] = []
var _settings: Control
var _busy := false


func _ready() -> void:
	UiKit.load_settings()
	theme = UiKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := KitBackdrop.new(true, 0.76, 300.0)
	add_child(backdrop)
	backdrop.sweep_in(0.6)
	_build_portraits()
	_build_title()
	_build_menu()
	var hints := UiKit.key_hints([["↑↓", "Select"], ["Enter", "Confirm"], ["Esc", "Back"]])
	hints.position = Vector2(70, 680)
	add_child(hints)
	_buttons[0].grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _settings != null:
		_close_settings()
		get_viewport().set_input_as_handled()


## Mamman hemma och på jobbet, med en hård svart siluett bakom, som Personas porträtt.
func _build_portraits() -> void:
	var delay := 0.1
	for portrait in PORTRAITS:
		var texture: Texture2D = load(portrait[0])
		var height: float = portrait[2]
		var factor := height / texture.get_height()
		var holder := Control.new()
		holder.position = portrait[1]
		holder.size = Vector2(texture.get_width() * factor, height)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for part in [[Vector2(14, 8), UiKit.INK], [Vector2.ZERO, Color(1, 1, 1).darkened(1.0 - portrait[3])]]:
			var rect := TextureRect.new()
			rect.texture = texture
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			rect.size = holder.size
			rect.position = part[0]
			rect.self_modulate = part[1]
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(rect)
		add_child(holder)
		UiKit.enter(holder, delay, Vector2(90, 0), UiKit.SLOW)
		delay += 0.12


func _build_title() -> void:
	var title := UiKit.display(str(ProjectSettings.get_setting("application/config/name", "")).to_upper(), UiKit.HERO, UiKit.YELLOW, UiKit.RED)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size = Vector2(620, 0)
	title.position = Vector2(64, 70)
	title.rotation = deg_to_rad(-4.0)
	add_child(title)
	UiKit.enter(title, 0.15, Vector2(-80, 0), UiKit.SLOW)
	# Spelets tre mätare är vad det handlar om.
	var kicker := UiKit.label("HOME  ·  WORK  ·  ROMANCE", UiKit.SMALL + 1, UiKit.INK, true)
	kicker.add_theme_stylebox_override("normal", UiKit.plate(UiKit.PAPER, UiKit.SLANT, Color(0, 0, 0, 0), 0, UiKit.RED, Vector2(18, 5)))
	kicker.position = Vector2(84, 300)
	add_child(kicker)
	UiKit.enter(kicker, 0.3)


## Valen står snett under varandra, som i Personas menyer.
func _build_menu() -> void:
	var items := [
		["New Game", _new_game],
		["Settings", _open_settings],
		["Quit", func() -> void: get_tree().quit()],
	]
	for i in items.size():
		var button := KitButton.new(items[i][0])
		button.position = MENU_ORIGIN + MENU_STEP * i
		button.size = MENU_SIZE
		button.pressed.connect(items[i][1])
		add_child(button)
		button.appear(0.35 + i * UiKit.STAGGER * 2)
		_buttons.append(button)


func _new_game() -> void:
	if _busy:
		return
	_busy = true
	UiTransition.wipe(self, func() -> void:
		GameState.reset()
		get_tree().change_scene_to_file("res://scenes/main.tscn"), "Day 1 · %s" % GameState.weekday_of(1))


func _open_settings() -> void:
	if _settings != null:
		return
	_settings = UiKit.card(26)
	_settings.position = Vector2(470, 380)
	_settings.custom_minimum_size = Vector2(420, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_settings.add_child(column)
	column.add_child(UiKit.display("Settings", UiKit.HEADING + 6))
	var list := UiKit.settings_list()
	column.add_child(list)
	var back := KitButton.new("Back", "Esc", "tab")
	back.pressed.connect(_close_settings)
	column.add_child(back)
	add_child(_settings)
	UiKit.enter(_settings, 0.0, Vector2(60, 0))
	for button in _buttons:
		button.focus_mode = Control.FOCUS_NONE
	_buttons[1].selected = true
	(list.get_child(0) as Control).grab_focus()


func _close_settings() -> void:
	_settings.queue_free()
	_settings = null
	for button in _buttons:
		button.focus_mode = Control.FOCUS_ALL
	_buttons[1].selected = false
	_buttons[1].grab_focus()
