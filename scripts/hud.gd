extends CanvasLayer
## HUD i UI-kitets stil (UiKit): tidszonen, dagen, pengarna och platsen på sneda
## plattor uppe till vänster, mammans mätare nere till vänster, en ljus textruta nederst
## i mitten för det som händer, en tipsrad ovanför den och sammanfattningen när dagen
## är slut.

const PAD := 16

var _place: Control
var _meters: Control
var _text: Label
var _hint: Label
var _day_end_overlay: Control
var _day_end_backdrop: KitBackdrop
var _summary: VBoxContainer
var _transition: TimeTransition


func _init(transition: TimeTransition = null) -> void:
	_transition = transition


func _ready() -> void:
	layer = 2
	_build_place()
	_build_stats()
	_build_text_box()
	_build_day_end()
	GameState.stats_changed.connect(_refresh)
	GameState.money_changed.connect(_refresh)
	GameState.room_changed.connect(func(_room_id: String) -> void: _refresh())
	GameState.time_of_day_changed.connect(func(_period: String) -> void: _refresh())
	GameState.message_posted.connect(func(text: String) -> void: _text.text = text)
	GameState.action_performed.connect(func(text: String, changes: String) -> void:
		_text.text = text if changes == "" else "%s  (%s)" % [text, changes])
	GameState.hint_changed.connect(func(text: String) -> void: _hint.text = text)
	GameState.day_ended.connect(_show_day_end)
	_text.text = "Click a room to go there."
	_refresh()


## Tidszonen stor på en svart platta, dagen och pengarna på en ljus och platsen på en
## gul, förskjutna snett under varandra.
func _build_place() -> void:
	_place = Control.new()
	_place.position = Vector2(PAD, 14)
	_place.size = Vector2(320, 100)
	_place.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place.draw.connect(func() -> void:
		var font := UiKit.display_font()
		var body := UiKit.body_font(true)
		var period: String = GameState.PERIOD_NAMES[GameState.get_time_of_day()] if not GameState.is_day_over() else "Night"
		var room: Dictionary = GameState.ROOMS[GameState.current_room]
		UiKit.draw_slant(_place, Rect2(4, 4, 250, 44), UiKit.RED)
		UiKit.draw_slant(_place, Rect2(0, 0, 250, 44), UiKit.INK)
		_place.draw_string(font, Vector2(22, UiKit.baseline(font, 32, 44)), period.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, UiKit.YELLOW)
		var date_rect := Rect2(12, 48, 296, 26)
		UiKit.draw_slant(_place, date_rect, UiKit.PAPER)
		_place.draw_string(font, Vector2(28, 48 + UiKit.baseline(font, 17, 26)), ("%s · Day %d" % [GameState.get_weekday(), GameState.day]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, UiKit.INK)
		_place.draw_string(font, Vector2(0, 48 + UiKit.baseline(font, 17, 26)), Economy.format(GameState.money), HORIZONTAL_ALIGNMENT_RIGHT, date_rect.end.x - 14, 17, UiKit.RED if GameState.money < 0 else UiKit.INK)
		UiKit.draw_slant(_place, Rect2(24, 76, 284, 24), UiKit.YELLOW)
		_place.draw_string(body, Vector2(40, 76 + UiKit.baseline(body, 14, 24)), "%s  —  %s" % [room["name"], room["floor"]], HORIZONTAL_ALIGNMENT_LEFT, 262, 14, UiKit.INK))
	add_child(_place)


## Mätarna nere till vänster: namnet på en svart platta, en sned stapel och värdet.
func _build_stats() -> void:
	_meters = Control.new()
	_meters.size = Vector2(280, 96)
	_meters.position = Vector2(PAD, 720 - PAD - _meters.size.y)
	_meters.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meters.draw.connect(func() -> void:
		var font := UiKit.display_font()
		var y := 0.0
		for key in GameState.STAT_NAMES:
			var value: int = GameState.stats[key]
			var color: Color = UiKit.METERS[key]
			UiKit.draw_slant(_meters, Rect2(0, y, 98, 28), UiKit.INK)
			_meters.draw_string(font, Vector2(14, y + UiKit.baseline(font, 17, 28)), GameState.STAT_NAMES[key].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, UiKit.PAPER)
			UiKit.draw_meter(_meters, Rect2(104, y + 7, 128, 14), float(value) / GameState.STAT_MAX, color)
			UiKit.draw_display(_meters, Vector2(240, y + UiKit.baseline(font, 20, 28)), str(value), 20, color, Color(0, 0, 0, 0))
			y += 34)
	add_child(_meters)


## Ljus textruta nederst i mitten, där det som händer berättas.
func _build_text_box() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.plate(UiKit.PAPER, 0.0, UiKit.INK, 3, UiKit.INK, Vector2(30, 16)))
	panel.position = Vector2(300, 610)
	panel.size = Vector2(680, 96)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	_text = UiKit.label("", UiKit.BODY + 1, UiKit.INK, false, 620)
	_text.custom_minimum_size.y = 64
	panel.add_child(_text)
	_hint = UiKit.label("", UiKit.SMALL + 2, UiKit.PAPER, true)
	_hint.add_theme_color_override("font_outline_color", UiKit.INK)
	_hint.add_theme_constant_override("outline_size", 7)
	_hint.position = Vector2(300, 576)
	_hint.size = Vector2(680, 26)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)


## Dagens slut: kitets bakgrund över planen, en stor rubrik, mätarna, pengarna och
## omdömet, och knappen som startar nästa dag.
func _build_day_end() -> void:
	# Täcker hela skärmen så att man inte kan klicka på planen bakom.
	_day_end_overlay = Control.new()
	_day_end_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_day_end_overlay.theme = UiKit.theme()
	_day_end_overlay.visible = false
	add_child(_day_end_overlay)
	_day_end_backdrop = KitBackdrop.new(false, 0.04, 180.0)
	_day_end_overlay.add_child(_day_end_backdrop)
	_summary = VBoxContainer.new()
	_summary.add_theme_constant_override("separation", 10)
	_summary.position = Vector2(380, 90)
	_summary.size = Vector2(600, 0)
	_day_end_overlay.add_child(_summary)


func _refresh() -> void:
	_place.queue_redraw()
	_meters.queue_redraw()


func _show_day_end() -> void:
	for child in _summary.get_children():
		child.queue_free()
	_summary.add_child(UiKit.header("Day's End", "%s · Day %d" % [GameState.get_weekday(), GameState.day]))
	var struggling: Array[String] = []
	var meters := Control.new()
	meters.custom_minimum_size = Vector2(600, 3 * 46)
	meters.draw.connect(func() -> void:
		var font := UiKit.display_font()
		var y := 0.0
		for key in GameState.STAT_NAMES:
			var value: int = GameState.stats[key]
			var color: Color = UiKit.METERS[key]
			meters.draw_string(font, Vector2(4, y + 26), GameState.STAT_NAMES[key].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.HEADING, UiKit.PAPER)
			UiKit.draw_meter(meters, Rect2(150, y + 8, 360, 18), float(value) / GameState.STAT_MAX, color, true)
			UiKit.draw_display(meters, Vector2(530, y + 28), str(value), UiKit.HEADING + 4, color, Color(0, 0, 0, 0))
			y += 46)
	_summary.add_child(meters)
	for key in GameState.STAT_NAMES:
		if GameState.stats[key] < 25:
			struggling.append(GameState.STAT_NAMES[key].to_lower())
	# Pengarna och vad som väntar: lönen eller räkningarna, det som kommer först.
	var outlook := ""
	var to_payday := GameState.days_until_payday()
	var to_bills := GameState.days_until_bills()
	if to_payday <= to_bills:
		outlook = "Payday in %d day%s" % [to_payday, "" if to_payday == 1 else "s"] if to_payday > 0 else "Payday is today"
	else:
		outlook = "Bills (%s) due in %d day%s" % [Economy.format(Economy.monthly_bills_total()), to_bills, "" if to_bills == 1 else "s"]
	_summary.add_child(UiKit.label("%s   ·   %s" % [Economy.format(GameState.money), outlook], UiKit.BODY + 2, UiKit.PAPER, true))
	var verdict := "You kept it all together today. Well done!" if struggling.is_empty() else "Things are slipping: " + ", ".join(struggling) + "."
	var verdict_label := UiKit.display(verdict, UiKit.HEADING + 2, UiKit.YELLOW if struggling.is_empty() else UiKit.RED.lightened(0.25), Color(0, 0, 0, 0))
	verdict_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	verdict_label.custom_minimum_size.x = 600
	_summary.add_child(verdict_label)
	var button := KitButton.new("Start the next day", "", "action")
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.pressed.connect(_on_next_day_pressed)
	_summary.add_child(button)
	_day_end_overlay.visible = true
	_day_end_backdrop.sweep_in()
	UiKit.enter(_summary, 0.1, Vector2(80, 0), UiKit.SLOW)
	button.grab_focus.call_deferred()


## Nästa dag börjar bakom dagsövergången (TimeTransition), som döljer sammanfattningen
## när skärmen är mörk.
func _on_next_day_pressed() -> void:
	if _transition:
		_transition.play_new_day(func() -> void:
			_day_end_overlay.visible = false
			GameState.start_next_day())
	else:
		_day_end_overlay.visible = false
		GameState.start_next_day()
