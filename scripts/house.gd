extends Node
## Spelets huvudscen: huset i 3D (HouseView3D), en vÃƒÂ¥ning i taget, dÃƒÂ¤r man navigerar
## genom att klicka pÃƒÂ¥ rummen (ingen styrning av figuren). Klick pÃƒÂ¥ ett rum flyttar
## mamman dit, kameran glider in och rummets meny ÃƒÂ¶ppnas i Harem Heaven-stil: rummets
## aktiviteter, samtal med familjemedlemmarna som ÃƒÂ¤r dÃƒÂ¤r och att vÃƒÂ¤nta till nÃƒÂ¤sta
## tidszon. Familjen stÃƒÂ¥r i rummen enligt sina scheman.

## VÃƒÂ¥ningspanelen till vÃƒÂ¤nster, under HUD:ens plattor: lÃƒÂ¤ge och bredd pÃƒÂ¥ namnplattan.
const FLOOR_PANEL_POS := Vector2(16, 118)
const FLOOR_PLATE_SIZE := Vector2(250, 36)

var _view: HouseView3D
## Namnplattan visar vÃƒÂ¥ningen som syns (hemma) eller platsen (ute).
var _floor_plate: Control
var _floor_name := ""
## Q och E byter vÃƒÂ¥ning; knapparna gÃƒÂ¶r samma sak med musen.
var _floor_up_hint: KitButton
var _floor_down_hint: KitButton
var _menu_layer: CanvasLayer
var _menu_title: Label
var _menu_period: Label
var _menu_list: VBoxContainer
var _dialog: CanvasLayer
var _phone: CanvasLayer
var _appearance: CanvasLayer
var _map: CanvasLayer
var _pause: CanvasLayer
## VÃƒÂ¥ningsknapparna (hemma) och kartan och hemresan (ute), under namnplattan.
var _floor_column: HBoxContainer
var _location_panel: HBoxContainer
var _menu_room := ""
## Saken i planen som valet under musen hÃƒÂ¶r till (skÃƒÂ¤rmkoordinater), och lagret som
## ritar markeringen ovanpÃƒÂ¥ den nedtonade planen.
var _highlight_rect := Rect2()
var _highlight: Control
## TÃƒÂ¤cker planen en kort stund nÃƒÂ¤r man byter vÃƒÂ¥ning, sÃƒÂ¥ att bytet tonar in.
var _floor_fade: ColorRect
## Tonar mellan dagarna och mjukar upp bytet av tidszon.
var _transition: TimeTransition
## En aktivitet spelas upp i 3D-vyn; klick pÃƒÂ¥ rum vÃƒÂ¤ntar tills den ÃƒÂ¤r klar.
var _playing_fx := false

func _ready() -> void:
	_view = HouseView3D.new()
	add_child(_view)
	_view.room_hovered.connect(_set_hover)
	_view.room_clicked.connect(_on_room_clicked)
	_view.can_pan = _can_pan
	
	_floor_fade = ColorRect.new()
	_floor_fade.color = PlanDrawer.PAPER
	_floor_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_floor_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_floor_fade.modulate.a = 0.0
	add_child(_floor_fade)
	_build_floor_label()

	_transition = TimeTransition.new()
	add_child(load("res://scripts/hud.gd").new(_transition))
	
	_dialog = load("res://scripts/dialog_box.gd").new()
	add_child(_dialog)
	add_child(load("res://scripts/scene_player.gd").new())
	if GameState.period == 0 and GameState.playing_scene == "":
		GameState.begin_day.call_deferred()
	_phone = load("res://scripts/phone.gd").new()
	add_child(_phone)
	_appearance = load("res://scripts/appearance_panel.gd").new()
	add_child(_appearance)
	
	# Connect dialogue system signals
	var dialogue_system = Engine.get_singleton("DialogueSystem")
	if dialogue_system:
		dialogue_system.dialogue_started.connect(_on_dialogue_started)
		dialogue_system.dialogue_ended.connect(_on_dialogue_ended)
		dialogue_system.dialogue_line.connect(_on_dialogue_line)
		dialogue_system.dialogue_mutated.connect(_on_dialogue_mutated)
	
	_map = load("res://scripts/world_map.gd").new()
	add_child(_map)
	UiKit.load_settings()
	_pause = load("res://scripts/ui/pause_menu.gd").new()
	add_child(_pause)
	_build_pause_button()
	_build_map_button()
	add_child(_transition)

	GameState.room_changed.connect(func(room_id: String) -> void:
		_show_floor(PlanDrawer.floor_of(room_id))
		_view.set_current(room_id))
	GameState.time_of_day_changed.connect(_on_time_of_day_changed)
	GameState.day_ended.connect(_close_menu)
	GameState.scene_requested.connect(func(_scene_id: String) -> void:
		_close_menu()
		_transition.play_new_day(func() -> void: pass))
	GameState.dialogue_changed.connect(func(active: bool) -> void:
		_dialog.visible = active)
	
	# Set up the initial state
	_highlight = ColorRect.new()
	_highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight.color = Color(1, 1, 1, 0.12)
	_highlight.visible = false
	add_child(_highlight)
	_show_floor(PlanDrawer.floor_of(GameState.current_room))
	_view.set_current(GameState.current_room)
	_view.can_pan = _can_pan

func _can_pan() -> bool:
	return not _dialog.visible and not _phone.visible and not _appearance.visible and not _map.visible and not _pause.is_open and not _transition.is_playing() and not GameState.in_dialogue()

func _set_hover(room: String) -> void:
	_highlight_rect = PlanDrawer.highlight_rect_of(room)
	_highlight.visible = room != ""

func _on_room_clicked(room: String) -> void:
	print("click ", room, " trans=", _transition.is_playing(), " dlg=", GameState.in_dialogue(), " playable=", GameState.is_playable())
	if _transition.is_playing() or GameState.in_dialogue():
		return
	if not GameState.is_playable():
		return
	if _dialog.visible or _appearance.visible or _phone.visible or _map.visible or _pause.is_open:
		return
	_close_menu()
	_phone.close()
	_map.close_map()
	
	# Move the character to the clicked room
	_view.set_current(room)
	
	# Update the menu
	_menu_room = room
	_build_menu()

func _build_menu() -> void:
	_menu_list.clear()
	_menu_title.text = _floor_name
	_menu_period.text = GameState.time_of_day
	
	# Add the menu items
	var menu_items = [
		{"name": "Talk", "action": "talk"},
		{"name": "Wait", "action": "wait"},
		{"name": "Phone", "action": "phone"},
		{"name": "Appearance", "action": "appearance"}
	]
	
	for item in menu_items:
		var button = Button.new()
		button.text = item.name
		button.pressed.connect(func() -> void:
			match item.action:
				"talk":
					# Start a dialogue
					pass
				"wait":
					# Wait for a while
					pass
				"phone":
					_phone.open()
				"appearance":
					_appearance.open()
		)
		_menu_list.add_child(button)

func _build_floor_label() -> void:
	_floor_plate = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.5)
	style.set_content_margin_all(10)
	_floor_plate.add_theme_stylebox_override("panel", style)
	_floor_plate.offset_left = 16
	_floor_plate.offset_top = 12
	_floor_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var label := Label.new()
	label.name = "Label"
	label.text = "Floor"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_floor_plate.add_child(label)
	add_child(_floor_plate)

func _build_pause_button() -> void:
	var button = KitButton.new()
	button.text = "Pause"
	button.pressed.connect(_open_pause)
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.position = Vector2(10, 10)
	button.size = Vector2(80, 30)
	add_child(button)

func _build_map_button() -> void:
	var button = KitButton.new()
	button.text = "Map"
	button.pressed.connect(_toggle_map)
	button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	button.position = Vector2(-10, 10)
	button.size = Vector2(80, 30)
	add_child(button)

func _open_pause() -> void:
	_pause.open()

func _close_menu() -> void:
	_dialog.hide()
	_phone.close()
	_appearance.close()
	_map.close_map()

func _toggle_map() -> void:
	if _map.is_open:
		_map.close_map()
		return
	if _dialog.visible or _appearance.visible or _pause.is_open or _transition.is_playing() or GameState.in_dialogue():
		return
	if not GameState.is_playable():
		return
	_close_menu()
	_phone.close()
	_map.open()

func _on_dialogue_started() -> void:
	_close_menu()
	_dialog.show()

func _on_dialogue_ended() -> void:
	_dialog.hide()

func _on_dialogue_line(line: String) -> void:
	_dialog.show()
	_dialog.set_text(line)

func _on_dialogue_mutated() -> void:
	# Handle dialogue mutations
	pass

func _on_time_of_day_changed(_period: String) -> void:
	# Handle time of day changes
	pass

func _show_floor(floor: String) -> void:
	_floor_name = floor
	_floor_plate.get_node("Label").text = floor
	_view.show_floor(floor)

# --- Scene player ---
func _on_scene_requested(scene_id: String) -> void:
	_close_menu()
	_transition.play_new_day(func() -> void: pass)

# --- Phone ---
func _on_phone_open() -> void:
	_phone.open()

# --- Appearance ---
func _on_appearance_open() -> void:
	_appearance.open()

# --- Pause ---
func _on_pause_open() -> void:
	_pause.open()

# --- Game state ---
func _on_game_state_changed() -> void:
	# Handle game state changes
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		var here := GameState.get_characters_in(GameState.current_room).filter(func(c: String) -> bool: return c != "mom")
		print("F1 room=", GameState.current_room, " here=", here, " period=", GameState.get_time_of_day())
		if not here.is_empty():
			print("talk_to -> ", GameState.talk_to(here[0]))