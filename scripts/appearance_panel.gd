extends CanvasLayer
## Garderoben och sminkbordet i sovrummet och frisörsalongen i köpcentret: en panel i
## samma stil som rummens meny, med mammans bild till vänster och valen till höger.
## Garderoben har kläder; sminkbordet har flikar för smink, accessoarer och håret
## uppsatt eller utsläppt. Där gäller ett val direkt (GameState.set_appearance) och tar
## ingen tid, och när panelen stängs står det i textrutan vad hon ändrade.
## I salongen (frisyr och hårfärg) syns valen direkt som en förhandsvisning med pris.
## "Book" betalar (Economy.SALON) och tar tid via GameState.do_room_action; "Cancel"
## eller Esc lämnar håret som det var.

const INK := Color(0.15, 0.15, 0.2)
const PANEL := Color(0.2, 0.24, 0.28, 0.97)
const BUTTON := Color(0.33, 0.44, 0.5, 0.92)
const SELECTED := Color(0.85, 0.55, 0.45)
const BORDER := Color(0.62, 0.78, 0.84)
const TITLES := {"wardrobe": "Wardrobe", "vanity": "Vanity", "salon": "Hair Salon"}

var _station := ""
var _category := ""
var _before := {}
var _title: Label
var _tabs: HBoxContainer
var _options: GridContainer
var _description: Label
var _preview: TextureRect
var _summary: Label
## Salongens pris och om det går att boka, och knapparna längst ned.
var _footer: Label
var _cancel: Button
var _done: Button


func _ready() -> void:
	layer = 5
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.05, 0.08, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var frame := PanelContainer.new()
	frame.position = Vector2(150, 70)
	frame.size = Vector2(980, 560)
	frame.add_theme_stylebox_override("panel", _rounded(PANEL, 14, BORDER, 2, 18))
	add_child(frame)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	frame.add_child(row)
	# Mammans bild och en sammanfattning av hur hon ser ut.
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(260, 0)
	row.add_child(left)
	var preview_bg := PanelContainer.new()
	preview_bg.custom_minimum_size = Vector2(260, 420)
	preview_bg.add_theme_stylebox_override("panel", _rounded(Color(0.96, 0.93, 0.88), 10))
	left.add_child(preview_bg)
	_preview = TextureRect.new()
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_bg.add_child(_preview)
	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.custom_minimum_size = Vector2(260, 0)
	_summary.add_theme_font_size_override("font_size", 14)
	_summary.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	left.add_child(_summary)
	# Valen.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 14)
	row.add_child(right)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color.WHITE)
	right.add_child(_title)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	right.add_child(_tabs)
	_options = GridContainer.new()
	_options.columns = 2
	_options.add_theme_constant_override("h_separation", 10)
	_options.add_theme_constant_override("v_separation", 10)
	right.add_child(_options)
	_description = Label.new()
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size = Vector2(600, 48)
	_description.add_theme_font_size_override("font_size", 16)
	_description.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	right.add_child(_description)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	right.add_child(footer)
	_footer = Label.new()
	_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footer.add_theme_font_size_override("font_size", 17)
	_footer.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	footer.add_child(_footer)
	_cancel = _button("Cancel", BUTTON)
	_cancel.custom_minimum_size = Vector2(150, 46)
	_cancel.pressed.connect(cancel)
	footer.add_child(_cancel)
	_done = _button("Done", Color(0.45, 0.62, 0.5))
	_done.custom_minimum_size = Vector2(200, 46)
	_done.pressed.connect(close)
	footer.add_child(_done)
	GameState.appearance_changed.connect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel()
		get_viewport().set_input_as_handled()


## Öppnar garderoben ("wardrobe"), sminkbordet ("vanity") eller salongen ("salon").
func open(station: String) -> void:
	_station = station
	_before = GameState.appearance.duplicate()
	var categories := AppearanceData.categories_for(station)
	_category = categories[0]
	_title.text = TITLES[station]
	_cancel.visible = station == "salon"
	for child in _tabs.get_children():
		child.queue_free()
	if categories.size() > 1:
		for category in categories:
			var tab := _button(AppearanceData.CATEGORIES[category]["title"], BUTTON)
			tab.custom_minimum_size = Vector2(140, 38)
			tab.pressed.connect(func() -> void:
				_category = category
				_refresh())
			tab.set_meta("category", category)
			_tabs.add_child(tab)
	visible = true
	_refresh()


func close() -> void:
	if not visible:
		return
	if _station == "salon":
		_book()
		return
	visible = false
	var changes: Array[String] = []
	for category in AppearanceData.categories_for(_station):
		if GameState.appearance[category] != _before.get(category, ""):
			changes.append("%s: %s" % [AppearanceData.CATEGORIES[category]["title"].to_lower(), AppearanceData.option_name(category, GameState.appearance[category])])
	if changes.is_empty():
		GameState.message_posted.emit("You decide to keep your look as it is.")
	elif _station == "wardrobe":
		GameState.message_posted.emit("You change into your %s outfit." % AppearanceData.option_name("outfit", GameState.appearance["outfit"]))
	else:
		GameState.message_posted.emit("You freshen up your look (%s)." % ", ".join(changes))


## Stänger utan att ändra något i salongen (garderoben och sminkbordet stängs som vanligt).
func cancel() -> void:
	if not visible:
		return
	if _station != "salon":
		close()
		return
	visible = false
	for category in AppearanceData.categories_for(_station):
		GameState.set_appearance(category, _before[category])
	GameState.message_posted.emit("You thank the stylist and keep your hair as it is.")


## Salongens kategorier som skiljer sig från när hon kom in.
func _salon_changes() -> Array[String]:
	var changed: Array[String] = []
	for category in AppearanceData.categories_for("salon"):
		if GameState.appearance[category] != _before[category]:
			changed.append(category)
	return changed


func _salon_total() -> int:
	var total := 0
	for category in _salon_changes():
		total += Economy.salon_price(category, GameState.appearance[category])
	return total


## Bokar besöket: betalar, tar tid och ger lite Charm. En ny frisyr bärs utsläppt när
## hon går därifrån (knuten sätts upp hemma vid sminkbordet).
func _book() -> void:
	var changed := _salon_changes()
	if changed.is_empty():
		visible = false
		GameState.message_posted.emit("You decide to keep your hair as it is.")
		return
	var total := _salon_total()
	if total > GameState.money:
		return
	visible = false
	if "hairstyle" in changed:
		GameState.set_appearance("hair_up", "down")
	var services: Array[String] = []
	var results: Array[String] = []
	for category in changed:
		services.append(Economy.SALON[category]["service"].to_lower())
		var option_name := AppearanceData.option_name(category, GameState.appearance[category])
		results.append(option_name if category == "hairstyle" else "%s color" % option_name.to_lower())
	GameState.do_room_action({"id": "salon_visit", "label": "Hair salon", "ledger_label": "Hair salon – %s" % " & ".join(services),
			"text": "Your stylist gets to work. An hour later: %s. You can't stop looking in the mirror." % ", ".join(results),
			"time": true, "cost": total, "social": {"charm": Economy.SALON_CHARM}})


func _refresh() -> void:
	if not visible:
		return
	for tab in _tabs.get_children():
		if tab.is_queued_for_deletion():
			continue
		var active: bool = tab.get_meta("category") == _category
		tab.add_theme_stylebox_override("normal", _rounded(SELECTED if active else BUTTON, 10, BORDER, 2))
	for child in _options.get_children():
		child.queue_free()
	var current: String = GameState.appearance[_category]
	for option_id in AppearanceData.OPTIONS[_category]:
		var option: Dictionary = AppearanceData.OPTIONS[_category][option_id]
		var chosen: bool = option_id == current
		# Det som är till salu och inte köpt syns, med pris och var det finns.
		var look_key := "%s:%s" % [_category, option_id]
		var locked := not GameState.owns_look(_category, option_id)
		var label: String = option["name"]
		if locked:
			var look: Dictionary = Economy.LOOKS[look_key]
			label = "%s – %s at the %s" % [option["name"], Economy.format(look["price"]), GameState.ROOMS[look["room"]]["name"].to_lower()]
		elif _station == "salon":
			# Salongen visar vad varje ändring kostar; det hon redan har är gratis.
			label = "%s (yours)" % option["name"] if option_id == _before[_category] else "%s  ·  %s" % [option["name"], Economy.format(Economy.salon_price(_category, option_id))]
		var button := _button(label, SELECTED if chosen else BUTTON)
		button.disabled = locked
		button.custom_minimum_size = Vector2(300, 52)
		if option.has("swatch"):
			# Hårfärg: en färgprick framför namnet.
			var swatch: Color = option["swatch"]
			button.draw.connect(func() -> void:
				button.draw_circle(Vector2(26, button.size.y / 2), 11, Color.WHITE)
				button.draw_circle(Vector2(26, button.size.y / 2), 9, swatch))
		button.mouse_entered.connect(func() -> void: _description.text = option["desc"])
		button.pressed.connect(func() -> void: GameState.set_appearance(_category, option_id))
		_options.add_child(button)
	_description.text = AppearanceData.OPTIONS[_category][current]["desc"]
	_preview.texture = AppearanceData.preview_image(GameState.appearance)
	var lines: Array[String] = []
	for category in AppearanceData.CATEGORIES:
		lines.append("%s: %s" % [AppearanceData.CATEGORIES[category]["title"], AppearanceData.option_name(category, GameState.appearance[category])])
	_summary.text = "\n".join(lines)
	_refresh_footer()


## Salongens summa och bokningsknapp; garderoben och sminkbordet har bara "Done".
func _refresh_footer() -> void:
	_done.disabled = false
	_footer.text = ""
	_done.text = "Done"
	if _station != "salon":
		return
	var total := _salon_total()
	if total == 0:
		_footer.text = "Pick a new style or color to see the price."
		_done.text = "Leave"
	elif total > GameState.money:
		_footer.text = "Costs %s – you have %s" % [Economy.format(total), Economy.format(GameState.money)]
		_done.text = "Book"
		_done.disabled = true
	else:
		_footer.text = "Total %s  ·  takes time" % Economy.format(total)
		_done.text = "Book – %s" % Economy.format(total)


func _button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, Color.WHITE)
	button.add_theme_stylebox_override("normal", _rounded(color, 10, BORDER, 2))
	button.add_theme_stylebox_override("hover", _rounded(color.lightened(0.15), 10, BORDER, 2))
	button.add_theme_stylebox_override("pressed", _rounded(color.darkened(0.15), 10, BORDER, 2))
	return button


func _rounded(color: Color, radius: int, border := Color(0, 0, 0, 0), border_width := 0, padding := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	if border_width > 0:
		style.border_color = border
		style.set_border_width_all(border_width)
	if padding > 0:
		style.set_content_margin_all(padding)
	return style
