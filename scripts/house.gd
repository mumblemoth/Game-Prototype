extends Node
## Spelets huvudscen: huset i 3D (HouseView3D), en vÃ¥ning i taget, dÃ¤r man navigerar
## genom att klicka pÃ¥ rummen (ingen styrning av figuren). Klick pÃ¥ ett rum flyttar
## mamman dit, kameran glider in och rummets meny Ã¶ppnas i Harem Heaven-stil: rummets
## aktiviteter, samtal med familjemedlemmarna som Ã¤r dÃ¤r och att vÃ¤nta till nÃ¤sta
## tidszon. Familjen stÃ¥r i rummen enligt sina scheman.

## VÃ¥ningspanelen till vÃ¤nster, under HUD:ens plattor: lÃ¤ge och bredd pÃ¥ namnplattan.
const FLOOR_PANEL_POS := Vector2(16, 118)
const FLOOR_PLATE_SIZE := Vector2(250, 36)

var _view: HouseView3D
## Namnplattan visar vÃ¥ningen som syns (hemma) eller platsen (ute).
var _floor_plate: Control
var _floor_name := ""
## Q och E byter vÃ¥ning; knapparna gÃ¶r samma sak med musen.
var _floor_up_hint: KitButton
var _floor_down_hint: KitButton
var _menu_layer: CanvasLayer
var _menu_title: Label
## Tidszonen pÃ¥ en liten gul platta ovanfÃ¶r rummets namn.
var _menu_period: Label
var _menu_list: VBoxContainer
var _dialog: CanvasLayer
var _phone: CanvasLayer
var _appearance: CanvasLayer
var _map: CanvasLayer
var _pause: CanvasLayer
## VÃ¥ningsknapparna (hemma) och kartan och hemresan (ute), under namnplattan.
var _floor_column: HBoxContainer
var _location_panel: HBoxContainer
var _menu_room := ""
## Saken i planen som valet under musen hÃ¶r till (skÃ¤rmkoordinater), och lagret som
## ritar markeringen ovanpÃ¥ den nedtonade planen.
var _highlight_rect := Rect2()
var _highlight: Control
## TÃ¤cker planen en kort stund nÃ¤r man byter vÃ¥ning, sÃ¥ att bytet tonar in.
var _floor_fade: ColorRect
## Tonar mellan dagarna och mjukar upp bytet av tidszon.
var _transition: TimeTransition
## En aktivitet spelas upp i 3D-vyn; klick pÃ¥ rum vÃ¤ntar tills den Ã¤r klar.
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
	_build_map_button()
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
	# Dagen bÃ¶rjar pÃ¥ morgonen (med scen om dagen har en) nÃ¤r allt Ã¤r uppbyggt.
	GameState.begin_day.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	# Esc stÃ¤nger rummets meny; annars Ã¶ppnar den pausmenyn (telefonen, kartan och de
	# andra panelerna tar Esc sjÃ¤lva nÃ¤r de Ã¤r Ã¶ppna). M Ã¶ppnar och stÃ¤nger kartan.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _menu_layer.visible:
			_close_menu()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		_toggle_map()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("floor_up") or event.is_action_pressed("floor_down"):
		_step_floor(-1 if event.is_action_pressed("floor_up") else 1)
		get_viewport().set_input_as_handled()


## WASD panorerar bara nÃ¤r ingen meny, panel eller scen har spelarens uppmÃ¤rksamhet.
func _can_pan() -> bool:
	if _menu_layer.visible or _dialog.visible or _appearance.visible or _transition.is_playing():
		return false
	if _phone.is_open or _pause.is_open or _map.is_open:
		return false
	return GameState.is_playable()


## MENU uppe till hÃ¶ger Ã¶ppnar pausmenyn med musen.
func _build_pause_button() -> void:
	var button := KitButton.new("Menu", "Esc", "tab")
	button.focus_mode = Control.FOCUS_NONE
	button.position = Vector2(1280 - 16 - button.custom_minimum_size.x, 16)
	button.pressed.connect(_open_pause)
	add_child(button)


func _open_pause() -> void:
	if _dialog.visible or _transition.is_playing() or _playing_fx:
		return
	_pause.open()


## Kartknappen nere till hÃ¶ger, under telefonens knapp och i samma stil, med kartans
## symbol. Den gÃ¶ms under en dialog, som telefonens.
func _build_map_button() -> void:
	var button := PhoneTheme.hud_button("      Map  (M)", 0)
	button.draw.connect(func() -> void: PhoneIcons.draw(button, "map", Rect2(14, 10, 24, 24), Color.WHITE))
	button.pressed.connect(_toggle_map)
	button.visible = not GameState.in_dialogue()
	GameState.dialogue_changed.connect(func(active: bool) -> void: button.visible = not active)
	add_child(button)


## M och kartknappen: stÃ¤nger kartan om den Ã¤r Ã¶ppen, annars Ã¶ppnas den (och rummets
## meny och telefonen stÃ¤ngs) nÃ¤r inget annat har spelarens uppmÃ¤rksamhet.
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


# --- Planen -------------------------------------------------------------------

## VÃ¥ningspanelen: en svart sned platta med namnet pÃ¥ det som syns, och under den
## knappar i kitets stil. Hemma byter de vÃ¥ning (som Q och E, och den som inte leder
## nÃ¥gonstans Ã¤r avstÃ¤ngd); ute Ã¶ppnar de kartan eller gÃ¥r hem.
func _build_floor_label() -> void:
	var panel := VBoxContainer.new()
	panel.position = FLOOR_PANEL_POS
	panel.add_theme_constant_override("separation", 8)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	_floor_plate = Control.new()
	_floor_plate.custom_minimum_size = FLOOR_PLATE_SIZE + UiKit.SHADOW * 0.5
	_floor_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_floor_plate.draw.connect(func() -> void:
		var font := UiKit.display_font()
		var rect := Rect2(Vector2.ZERO, FLOOR_PLATE_SIZE)
		UiKit.draw_slant(_floor_plate, Rect2(UiKit.SHADOW * 0.5, rect.size), UiKit.RED)
		UiKit.draw_slant(_floor_plate, rect, UiKit.INK)
		_floor_plate.draw_string(font, Vector2(20, UiKit.baseline(font, UiKit.HEADING - 4, rect.size.y)), _floor_name.to_upper(),
				HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36, UiKit.HEADING - 4, UiKit.PAPER))
	panel.add_child(_floor_plate)
	_floor_column = HBoxContainer.new()
	_floor_column.add_theme_constant_override("separation", 8)
	panel.add_child(_floor_column)
	_floor_up_hint = _floor_button("Up", "Q", func() -> void: _step_floor(-1), _floor_column)
	_floor_down_hint = _floor_button("Down", "E", func() -> void: _step_floor(1), _floor_column)
	_build_location_panel(panel)


func _floor_button(text: String, key: String, on_pressed: Callable, row: HBoxContainer) -> KitButton:
	var button := KitButton.new(text, key, "tab")
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_pressed)
	row.add_child(button)
	return button


## Q gÃ¥r uppÃ¥t (mot vinden), E nedÃ¥t (mot utanfÃ¶r) i GameState.HOME_FLOORS; stannar
## vid Ã¤ndarna. Bara nÃ¤r huset syns och ingen dialog eller panel har uppmÃ¤rksamheten.
func _step_floor(step: int) -> void:
	if not _can_pan() or GameState.in_dialogue() or _playing_fx:
		return
	var index := GameState.HOME_FLOORS.find(PlanDrawer.FLOOR_LABELS.get(_view.floor_name, ""))
	if index == -1:
		return
	var target: int = clampi(index + step, 0, GameState.HOME_FLOORS.size() - 1)
	if target == index:
		return
	_show_floor(PlanDrawer.FLOOR_LABELS.find_key(GameState.HOME_FLOORS[target]))


## Ute pÃ¥ en plats ersÃ¤tts vÃ¥ningsknapparna av kartan och vÃ¤gen hem.
func _build_location_panel(panel: VBoxContainer) -> void:
	_location_panel = HBoxContainer.new()
	_location_panel.add_theme_constant_override("separation", 8)
	_location_panel.visible = false
	panel.add_child(_location_panel)
	for item in [["Map", "M", func() -> void: _map.open()], ["Go Home", "", func() -> void: GameState.return_home()]]:
		_floor_button(item[0], item[1], func() -> void:
			if GameState.is_playable():
				_close_menu()
				item[2].call(), _location_panel)


func _show_floor(floor_name: String) -> void:
	if floor_name == "":
		floor_name = "EntrÃ©plan"
	var away := not floor_name in PlanDrawer.FLOORS
	_floor_column.visible = not away
	_location_panel.visible = away
	_floor_name = PlanDrawer.FLOOR_LABELS.get(floor_name, floor_name)
	_floor_plate.queue_redraw()
	if floor_name != _view.floor_name:
		if is_inside_tree():
			# Den nya vÃ¥ningen tonar fram.
			_floor_fade.modulate.a = 1.0
			create_tween().tween_property(_floor_fade, "modulate:a", 0.0, 0.35)
		_view.show_floor(floor_name)
	if not away:
		var index := GameState.HOME_FLOORS.find(PlanDrawer.FLOOR_LABELS[floor_name])
		_floor_up_hint.disabled = index <= 0
		_floor_down_hint.disabled = index >= GameState.HOME_FLOORS.size() - 1
	_set_hover("")


## Klick pÃ¥ ett rum i 3D-vyn: mamman gÃ¥r dit, kameran glider in och rummets meny Ã¶ppnas.
func _on_room_clicked(room_id: String) -> void:
	if not GameState.is_playable() or _playing_fx:
		return
	if room_id != GameState.current_room:
		var from_floor := PlanDrawer.floor_of(GameState.current_room)
		var to_floor := PlanDrawer.floor_of(room_id)
		if from_floor != to_floor:
			GameState.message_posted.emit(_floor_change_text(from_floor, to_floor, room_id))
		GameState.go_to_room(room_id)
	_view.focus_room(room_id)
	_open_menu(room_id)


## "You head upstairs to the Bedroom." och liknande nÃ¤r man byter vÃ¥ning.
func _floor_change_text(from_floor: String, to_floor: String, room_id: String) -> String:
	var room_name: String = GameState.ROOMS[room_id]["name"]
	if "UtanfÃ¶r" in [from_floor, to_floor]:
		return "You step %s to the %s." % ["outside" if to_floor == "UtanfÃ¶r" else "back inside", room_name]
	var up := PlanDrawer.FLOORS.find(to_floor) < PlanDrawer.FLOORS.find(from_floor)
	return "You head %s to the %s." % ["upstairs" if up else "downstairs", room_name]


func _set_hover(room_id: String) -> void:
	if _menu_layer.visible:
		return
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if room_id != "" else Input.CURSOR_ARROW)
	var hint := ""
	if room_id != "":
		var room_name: String = GameState.ROOMS[room_id]["name"]
		hint = "%s  â€“  you are here" % room_name if room_id == GameState.current_room else "Go to %s" % room_name
	GameState.show_hint(hint)


# --- Rummets meny -------------------------------------------------------------

## Menyn i Harem Heaven-stil: rummets namn och en kolumn av breda knappar mitt pÃ¥
## skÃ¤rmen, Ã¶ver en nedtonad plan.
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
	# Samtal med dem som Ã¤r i rummet; det stÃ¤rker relationen en gÃ¥ng per dag.
	for character_id in GameState.get_characters_in(room_id):
		if character_id == "mom":
			continue
		var character_name := GameState.character_name(character_id)
		var reason := Dispatcher.block_reason(character_id)
		var ready := Dispatcher.resolve_slot(GameState.period, character_id) != ""
		var talk := {"id": "talk_" + character_id, "object": "", "label": ("Spend time with %s" if ready else "Talk to %s") % character_name,
				"text": ("You chat with %s." % character_name) if ready or reason == "" else reason}
		if character_id == "dog":
			var bed := "dog_bed" if FloorPlanArt.furniture_rect(room_id, "dog_bed").size != Vector2.ZERO else "dog_house"
			talk = {"id": "pet_dog", "object": bed, "label": "Pet the dog", "text": "You scratch the dog behind the ears. Its tail thumps happily."}
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
				{"speaker": character_id, "text": "Hi! (Placeholder â€“ the real dialogue comes later.)"},
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


## Ett val fÃ¶r en handling i rummet. GÃ¥r den inte att gÃ¶ra just nu visas varfÃ¶r, i
## stÃ¤llet fÃ¶r taggarna. `after` kÃ¶rs efter handlingen (t.ex. Ã¶ppna en dialog).
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
			# Hon drar fÃ¶r innan hon byter om.
			Curtains.set_for_now(room_id, "closed")
			_view.refresh_curtains()
			GameState.message_posted.emit("You draw the curtains before you change.")
		if panel != "":
			_appearance.open(panel)
			return
		if action.get("fx", "") != "":
			# TrÃ¤dgÃ¥rdens aktiviteter spelas upp i 3D-vyn fÃ¶rst (simma, sola, vattna, apport).
			_playing_fx = true
			await _view.play_activity(room_id, action.get("object", ""), action["fx"])
			_playing_fx = false
		GameState.do_room_action(action)
		_view.refresh_people()
		Backyard.refresh_plants(get_tree())
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


## En knapp i menyn (KitButton): texten till vÃ¤nster och taggarna (eller varfÃ¶r det inte
## gÃ¥r) mindre till hÃ¶ger.
func _add_choice(text: String, tags: String, on_pressed: Callable, disabled := false) -> Button:
	var button := KitButton.new(text, tags, "menu", UiKit.HEADING - 2)
	button.custom_minimum_size.x = 600
	button.disabled = disabled
	button.pressed.connect(on_pressed)
	_menu_list.add_child(button)
	return button


## Markerar saken i planen som ett val hÃ¶r till (eller tar bort markeringen).
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
	# Skylten visas bara nÃ¤r spelaren fÃ¥r kontroll (morgon och natt har egna scener).
	if not period in GameState.PLAYABLE_PERIODS:
		return
	# En ny dag visar dagens namn i Ã¶vergÃ¥ngen; skylten kommer nÃ¤r den Ã¤r klar.
	if _transition.is_playing():
		await _transition.finished
		if GameState.get_time_of_day() != period:
			return
	UiTransition.banner(self, GameState.PERIOD_NAMES[period], GameState.get_weekday())


