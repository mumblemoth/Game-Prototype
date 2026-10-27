extends Node
## Spelets huvudscen: huset i 3D (HouseView3D), en våning i taget, där man navigerar
## genom att klicka på rummen (ingen styrning av figuren). Klick på ett rum flyttar
## mamman dit, kameran glider in och rummets meny öppnas i Harem Heaven-stil: rummets
## aktiviteter, samtal med familjemedlemmarna som är där och att vänta till nästa
## tidszon. Familjen står i rummen enligt sina scheman.

var _view: HouseView3D
var _floor_buttons := {}
var _menu_layer: CanvasLayer
var _menu_title: Label
## Tidszonen på en liten gul platta ovanför rummets namn.
var _menu_period: Label
var _menu_list: VBoxContainer
var _dialog: CanvasLayer
var _phone: CanvasLayer
var _appearance: CanvasLayer
var _map: CanvasLayer
var _pause: CanvasLayer
## Våningsknapparna (hemma) och platsens panel med karta och hemresa (ute).
var _floor_column: VBoxContainer
var _location_panel: VBoxContainer
var _location_title: Label
var _menu_room := ""
## Saken i planen som valet under musen hör till (skärmkoordinater), och lagret som
## ritar markeringen ovanpå den nedtonade planen.
var _highlight_rect := Rect2()
var _highlight: Control
## Täcker planen en kort stund när man byter våning, så att bytet tonar in.
var _floor_fade: ColorRect
## Tonar mellan dagarna och mjukar upp bytet av tidszon.
var _transition: TimeTransition


func _ready() -> void:
	_view = HouseView3D.new()
	add_child(_view)
	_view.room_hovered.connect(_set_hover)
	_view.room_clicked.connect(_on_room_clicked)
	_floor_fade = ColorRect.new()
	_floor_fade.color = PlanDrawer.PAPER
	_floor_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_floor_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_floor_fade.modulate.a = 0.0
	add_child(_floor_fade)
	_build_floor_buttons()

	_transition = TimeTransition.new()
	add_child(load("res://scripts/hud.gd").new(_transition))
	_build_menu()
	_dialog = load("res://scripts/dialog_box.gd").new()
	add_child(_dialog)
	add_child(load("res://scripts/scene_player.gd").new())
	_phone = load("res://scripts/phone.gd").new()
	add_child(_phone)
	_appearance = load("res://scripts/appearance_panel.gd").new()
	add_child(_appearance)
	_map = load("res://scripts/world_map.gd").new()
	add_child(_map)
	UiKit.load_settings()
	_pause = load("res://scripts/ui/pause_menu.gd").new()
	add_child(_pause)
	_build_pause_button()
	add_child(_transition)

	GameState.room_changed.connect(func(room_id: String) -> void:
		_show_floor(PlanDrawer.floor_of(room_id))
		_view.set_current(room_id))
	GameState.time_of_day_changed.connect(_on_time_of_day_changed)
	GameState.day_ended.connect(_close_menu)
	GameState.scene_requested.connect(func(_scene_id: String) -> void:
		_close_menu()
		_map.close_map())
	_show_floor(PlanDrawer.floor_of(GameState.current_room))
	_view.set_current(GameState.current_room)
	# Dagen börjar på morgonen (med scen om dagen har en) när allt är uppbyggt.
	GameState.begin_day.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	# Esc stänger rummets meny; annars öppnar den pausmenyn (telefonen, kartan och de
	# andra panelerna tar Esc själva när de är öppna).
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _menu_layer.visible:
			_close_menu()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()


## MENU uppe till höger öppnar pausmenyn med musen.
func _build_pause_button() -> void:
	var button := KitButton.new("Menu", "Esc", "tab")
	button.focus_mode = Control.FOCUS_NONE
	button.position = Vector2(1280 - 16 - button.custom_minimum_size.x, 16)
	button.pressed.connect(_open_pause)
	add_child(button)


func _open_pause() -> void:
	if _dialog.visible or _transition.is_playing():
		return
	_pause.open()


# --- Planen -------------------------------------------------------------------

## Våningsknapparna står i husets ordning uppifrån och ned, som i en hiss.
func _build_floor_buttons() -> void:
	var column := VBoxContainer.new()
	column.position = Vector2(36, 120)
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	_floor_column = column
	_build_location_panel()
	var group := ButtonGroup.new()
	for floor_name in PlanDrawer.FLOORS:
		var button := KitButton.new(PlanDrawer.FLOOR_LABELS[floor_name], "", "tab", UiKit.BODY)
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(170, 40)
		button.pressed.connect(_show_floor.bind(floor_name))
		column.add_child(button)
		_floor_buttons[floor_name] = button


## Ute på en plats ersätts våningsknapparna av platsens namn, kartan och vägen hem.
func _build_location_panel() -> void:
	_location_panel = VBoxContainer.new()
	_location_panel.position = Vector2(36, 120)
	_location_panel.add_theme_constant_override("separation", 10)
	_location_panel.visible = false
	add_child(_location_panel)
	_location_title = UiKit.display("", UiKit.HEADING + 2)
	_location_title.custom_minimum_size = Vector2(200, 0)
	_location_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_location_panel.add_child(_location_title)
	for item in [["Neighborhood Map", func() -> void: _map.open()], ["Go Home", func() -> void: GameState.return_home()]]:
		var button := KitButton.new(item[0], "", "tab", UiKit.BODY)
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(200, 40)
		button.pressed.connect(func() -> void:
			if GameState.is_playable():
				_close_menu()
				item[1].call())
		_location_panel.add_child(button)


func _show_floor(floor_name: String) -> void:
	if floor_name == "":
		floor_name = "Entréplan"
	var away := not floor_name in PlanDrawer.FLOORS
	_floor_column.visible = not away
	_location_panel.visible = away
	if away:
		_location_title.text = PlanDrawer.FLOOR_LABELS.get(floor_name, floor_name)
	if floor_name != _view.floor_name:
		if is_inside_tree():
			# Den nya våningen tonar fram.
			_floor_fade.modulate.a = 1.0
			create_tween().tween_property(_floor_fade, "modulate:a", 0.0, 0.35)
		_view.show_floor(floor_name)
	if _floor_buttons.has(floor_name):
		_floor_buttons[floor_name].button_pressed = true
	_set_hover("")


## Klick på ett rum i 3D-vyn: mamman går dit, kameran glider in och rummets meny öppnas.
func _on_room_clicked(room_id: String) -> void:
	if not GameState.is_playable():
		return
	if room_id != GameState.current_room:
		var from_floor := PlanDrawer.floor_of(GameState.current_room)
		var to_floor := PlanDrawer.floor_of(room_id)
		if from_floor != to_floor:
			GameState.message_posted.emit(_floor_change_text(from_floor, to_floor, room_id))
		GameState.go_to_room(room_id)
	_view.focus_room(room_id)
	_open_menu(room_id)


## "You head upstairs to the Bedroom." och liknande när man byter våning.
func _floor_change_text(from_floor: String, to_floor: String, room_id: String) -> String:
	var room_name: String = GameState.ROOMS[room_id]["name"]
	if "Utanför" in [from_floor, to_floor]:
		return "You step %s to the %s." % ["outside" if to_floor == "Utanför" else "back inside", room_name]
	var up := PlanDrawer.FLOORS.find(to_floor) < PlanDrawer.FLOORS.find(from_floor)
	return "You head %s to the %s." % ["upstairs" if up else "downstairs", room_name]


func _set_hover(room_id: String) -> void:
	if _menu_layer.visible:
		return
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if room_id != "" else Input.CURSOR_ARROW)
	var hint := ""
	if room_id != "":
		var room_name: String = GameState.ROOMS[room_id]["name"]
		hint = "%s  –  you are here" % room_name if room_id == GameState.current_room else "Go to %s" % room_name
	GameState.show_hint(hint)


# --- Rummets meny -------------------------------------------------------------

## Menyn i Harem Heaven-stil: rummets namn och en kolumn av breda knappar mitt på
## skärmen, över en nedtonad plan.
func _build_menu() -> void:
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 3
	_menu_layer.visible = false
	add_child(_menu_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.1, 0.1, 0.14, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close_menu())
	_menu_layer.add_child(shade)
	_highlight = Control.new()
	_highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight.draw.connect(func() -> void:
		if _highlight_rect.size == Vector2.ZERO:
			return
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color(1.0, 0.95, 0.7, 0.28)
		fill.border_color = Color(1.0, 0.85, 0.4)
		fill.set_border_width_all(3)
		fill.set_corner_radius_all(6)
		fill.shadow_color = Color(1.0, 0.85, 0.4, 0.5)
		fill.shadow_size = 8
		_highlight.draw_style_box(fill, _highlight_rect))
	_menu_layer.add_child(_highlight)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -110
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_layer.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	center.add_child(column)
	_menu_title = UiKit.display("", UiKit.TITLE)
	_menu_title.uppercase = true
	column.add_child(_menu_title)
	_menu_period = UiKit.label("", UiKit.SMALL, UiKit.INK, true)
	_menu_period.uppercase = true
	_menu_period.add_theme_stylebox_override("normal", UiKit.plate(UiKit.YELLOW, UiKit.SLANT, Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), Vector2(14, 3)))
	_menu_period.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(_menu_period)
	column.move_child(_menu_period, 0)
	_menu_list = VBoxContainer.new()
	_menu_list.add_theme_constant_override("separation", 10)
	column.add_child(_menu_list)


func _open_menu(room_id: String) -> void:
	if not GameState.is_playable():
		return
	for child in _menu_list.get_children():
		child.queue_free()
	_menu_room = room_id
	_menu_title.text = GameState.ROOMS[room_id]["name"]
	_menu_period.text = GameState.PERIOD_NAMES[GameState.get_time_of_day()]
	for action in RoomActions.for_room(room_id):
		_add_action(action, room_id)
	# Samtal med dem som är i rummet; det stärker relationen en gång per dag.
	for character_id in GameState.get_characters_in(room_id):
		if character_id == "mom":
			continue
		var character_name := GameState.character_name(character_id)
		var talk := {"id": "talk_" + character_id, "object": "", "label": "Talk to %s" % character_name,
				"text": "You chat with %s." % character_name}
		if character_id == "dog":
			talk = {"id": "pet_dog", "object": "dog_bed", "label": "Pet the dog", "text": "You scratch the dog behind the ears. Its tail thumps happily."}
		if GameState.links.has(character_id):
			talk["link"] = character_id
			talk["link_points"] = 1
		if character_id == "dog":
			_add_action(talk, room_id)
			continue
		_add_action(talk, room_id, func() -> void:
			if GameState.talk_to(character_id):
				return
			_dialog.play([
				{"speaker": "mom", "text": "Hey, %s. Got a minute?" % character_name},
				{"speaker": character_id, "text": "Hi! (Placeholder – the real dialogue comes later.)"},
			]))
	_add_choice("Wait here", "takes time", func() -> void:
		_close_menu()
		GameState.message_posted.emit("You wait for a while.")
		GameState.advance_period())
	_add_choice("Close", "Esc", _close_menu)
	_menu_layer.visible = true
	# Valen glider in ett i taget.
	var index := 0
	for child in _menu_list.get_children():
		if not child.is_queued_for_deletion():
			(child as KitButton).appear(index * UiKit.STAGGER)
			index += 1


## Ett val för en handling i rummet. Går den inte att göra just nu visas varför, i
## stället för taggarna. `after` körs efter handlingen (t.ex. öppna en dialog).
func _add_action(action: Dictionary, room_id: String, after := Callable()) -> void:
	var reason := GameState.action_block_reason(action, room_id)
	var run := func() -> void:
		_close_menu()
		_highlight_object("", "")
		var panel: String = action.get("panel", "")
		if panel == "map":
			_map.open()
			return
		if action.has("curtains"):
			Curtains.set_for_now(room_id, action["curtains"])
			_view.refresh_curtains()
			GameState.message_posted.emit(action["text"])
			return
		if panel == "wardrobe" and Curtains.state_for(room_id) != "closed" and not Curtains.curtained_windows(room_id).is_empty():
			# Hon drar för innan hon byter om.
			Curtains.set_for_now(room_id, "closed")
			_view.refresh_curtains()
			GameState.message_posted.emit("You draw the curtains before you change.")
		if panel != "":
			_appearance.open(panel)
			return
		GameState.do_room_action(action)
		if after.is_valid():
			after.call()
	var button := _add_choice(action["label"], reason if reason != "" else RoomActions.tags(action), run, reason != "")
	var object: String = action.get("object", "")
	button.mouse_entered.connect(func() -> void:
		_highlight_object(room_id, object)
		GameState.show_hint(reason if reason != "" else action.get("text", "")))
	button.mouse_exited.connect(func() -> void:
		_highlight_object("", "")
		GameState.show_hint(""))


## En knapp i menyn (KitButton): texten till vänster och taggarna (eller varför det inte
## går) mindre till höger.
func _add_choice(text: String, tags: String, on_pressed: Callable, disabled := false) -> Button:
	var button := KitButton.new(text, tags, "menu", UiKit.HEADING - 2)
	button.custom_minimum_size.x = 600
	button.disabled = disabled
	button.pressed.connect(on_pressed)
	_menu_list.add_child(button)
	return button


## Markerar saken i planen som ett val hör till (eller tar bort markeringen).
func _highlight_object(room_id: String, object: String) -> void:
	_highlight_rect = Rect2()
	if room_id != "" and object != "":
		var rect := _view.object_screen_rect(room_id, object)
		if rect.size != Vector2.ZERO:
			_highlight_rect = rect.grow(6)
	_highlight.queue_redraw()


func _close_menu() -> void:
	if _menu_layer.visible:
		_view.focus_overview()
	_menu_layer.visible = false


# --- Tiden --------------------------------------------------------------------

func _on_time_of_day_changed(period: String) -> void:
	_close_menu()
	# Skylten visas bara när spelaren får kontroll (morgon och natt har egna scener).
	if not period in GameState.PLAYABLE_PERIODS:
		return
	# En ny dag visar dagens namn i övergången; skylten kommer när den är klar.
	if _transition.is_playing():
		await _transition.finished
		if GameState.get_time_of_day() != period:
			return
	UiTransition.banner(self, GameState.PERIOD_NAMES[period], "%s · Day %d" % [GameState.get_weekday(), GameState.day])
