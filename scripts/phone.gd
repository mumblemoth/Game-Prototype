extends CanvasLayer
## Mammans iPhone, spelets meny. Den glider upp nere till höger och fungerar som en
## riktig telefon: statusrad med tidszon, ö, signal och batteri (som laddas ur under
## dagen), en låsskärm med notiser första gången den öppnas i en ny tidszon, och en
## hemskärm med datumwidget, appar och docka. Apparna: Phone (ring kontakter),
## Messages (sms-trådar där man väljer vad man skriver), Memories (scener man kan
## uppleva igen och bilder man har hittat), Profile (mammans egenskaper och
## Attractiveness), Wallet (saldo, vad som väntar, sätt att tjäna och kontoutdrag), Journal (startade och avklarade quests) och Settings (bakgrunder,
## stäng, avsluta). Lås- och hemskärmen har var sin bakgrund: en färdig toning eller
## en bild bland minnena.
## Utseendet (färger, typsnitt, mått) kommer från PhoneTheme och ikonerna från
## PhoneIcons; måtten står i docs/phone_ui_spec.md. Innehållet kommer från PhoneData
## och vad spelaren har hittat från GameState. Öppnas med P eller telefonknappen; Esc
## eller klick utanför stänger.

const OPEN_POSITION := Vector2(930, 40)
const CLOSED_Y := 760.0
const APP_NAMES := {"phone": "Phone", "messages": "Messages", "memories": "Memories", "journal": "Journal", "profile": "Profile", "wallet": "Wallet", "settings": "Settings"}
## Apparna i hemskärmens rutnät och i dockan.
const GRID_APPS := ["journal", "profile", "wallet", "settings"]
## Hur många rader kontoutdraget i Wallet visar.
const WALLET_LEDGER_ROWS := 12
const DOCK_APPS := ["phone", "messages", "memories"]
## Vad bakåtknappen heter när den leder till en sida.
const PAGE_TITLES := {"home": "Home", "phone": "Contacts", "messages": "Messages", "memories": "Memories", "settings": "Settings"}
## Låsskärmen låser upp sig själv efter så här många sekunder när det inte finns notiser.
const AUTO_UNLOCK := 1.4

var is_open := false
var _shade: ColorRect
var _phone: Control
var _screen: Panel
var _wallpaper: Control
var _status_bar: Control
var _scroll: ScrollContainer
var _content: VBoxContainer
## Sidans fasta delar som inte rullar (låsskärm, hemskärm), i skärmens koordinater.
var _fixed: Control
var _home_bar: Button
var _sheet: Control
var _page := "home"
var _thread_contact := ""
var _call_contact := ""
var _journal_tab := "active"
var _memories_tab := "all"
var _memory := ""
## Minnet som spelas igen från telefonen (dit kommer man tillbaka efteråt).
var _relived := ""
## Platsen som väljs på bakgrundssidan ("lock" eller "home").
var _wallpaper_slot := "lock"
## Dag och tidszon när telefonen senast låstes upp; låsskärmen visas igen i nästa.
var _unlocked_period := ""
var _lock_token := 0
var _light_status := false
var _viewer: Control
var _viewer_image: TextureRect
var _viewer_caption: Label
var _refresh_queued := false
var _textures := {}


func _ready() -> void:
	layer = 5
	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, 0.35)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.visible = false
	_shade.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			close())
	add_child(_shade)
	_build_phone()
	_build_viewer()
	_build_phone_button()
	GameState.phone_changed.connect(_queue_refresh)
	GameState.social_changed.connect(_queue_refresh)
	GameState.money_changed.connect(_queue_refresh)
	GameState.time_of_day_changed.connect(func(_period: String) -> void:
		_status_bar.queue_redraw()
		_queue_refresh())
	# Efter ett minne man upplevt igen kommer man tillbaka till det i telefonen.
	# (Bara om det spelades härifrån; pausmenyns Memories tar hand om sina egna.)
	GameState.memory_replay_finished.connect(func(memory_id: String) -> void:
		if memory_id != _relived:
			return
		_relived = ""
		_memory = memory_id
		open("memory"))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_P:
		toggle()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and is_open:
		if _viewer.visible:
			_viewer.visible = false
		elif _sheet != null:
			_close_sheet()
		else:
			close()
		get_viewport().set_input_as_handled()


## Bygger om sidan en gång i slutet av bildrutan när något i telefonen ändrats (flera
## ändringar i rad, eller en ändring medan sidan byggs, ger bara en ombyggnad).
func _queue_refresh() -> void:
	if is_open and not _refresh_queued:
		_refresh_queued = true
		_refresh.call_deferred()


func _refresh() -> void:
	_refresh_queued = false
	if not is_open or _page in ["call", "lock", "unlocking"]:
		return
	var scrolled := _scroll.scroll_vertical
	_show(_page, false)
	# Sidan byggs om men stannar där man var (sms-tråden rullar själv till slutet).
	if _page != "thread":
		await get_tree().process_frame
		_scroll.scroll_vertical = scrolled


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open(page := "home") -> void:
	if is_open or GameState.playing_scene != "" or GameState.replaying_memory != "":
		return
	is_open = true
	_shade.visible = true
	_phone.visible = true
	if page == "home" and _unlocked_period != _period_key():
		page = "lock"
	_show(page)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_phone, "position", OPEN_POSITION, 0.3)


func close() -> void:
	if not is_open:
		return
	is_open = false
	_shade.visible = false
	_viewer.visible = false
	_close_sheet()
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_phone, "position", Vector2(OPEN_POSITION.x, CLOSED_Y), 0.22)
	tween.tween_callback(func() -> void: _phone.visible = is_open)


func _period_key() -> String:
	return "%d:%s" % [GameState.day, GameState.get_time_of_day()]


## Knappen nere till höger som öppnar telefonen, med en liten ritad telefon och ett
## rött märke när det finns olästa sms.
func _build_phone_button() -> void:
	var button := Button.new()
	button.text = "      Phone  (P)"
	button.focus_mode = Control.FOCUS_NONE
	button.size = Vector2(150, 44)
	button.position = Vector2(1280 - 16 - 150, 720 - 16 - 44)
	button.add_theme_font_override("font", PhoneTheme.font(600))
	button.add_theme_font_size_override("font_size", 16)
	PhoneTheme.style_button(button, Color(PhoneTheme.BEZEL, 0.92), 22, Color.WHITE, PhoneTheme.BEZEL_EDGE)
	button.draw.connect(func() -> void:
		button.draw_style_box(PhoneTheme.rounded(Color(0, 0, 0, 0), 4, Color.WHITE, 2), Rect2(18, 10, 15, 24))
		button.draw_line(Vector2(23, 13.5), Vector2(28, 13.5), Color.WHITE, 2.0, true)
		if not GameState.unread.is_empty():
			button.draw_circle(Vector2(33, 10), 7, PhoneTheme.BEZEL, true, -1.0, true)
			button.draw_circle(Vector2(33, 10), 5.5, PhoneTheme.BADGE, true, -1.0, true))
	button.pressed.connect(toggle)
	GameState.phone_changed.connect(button.queue_redraw)
	add_child(button)
	move_child(button, 0)


# --- Telefonens kropp ---------------------------------------------------------

func _build_phone() -> void:
	var screen_size := PhoneTheme.SCREEN_SIZE
	_phone = Control.new()
	_phone.size = PhoneTheme.BODY_SIZE
	_phone.position = Vector2(OPEN_POSITION.x, CLOSED_Y)
	_phone.visible = false
	_phone.theme = PhoneTheme.theme()
	_phone.draw.connect(_draw_side_buttons)
	add_child(_phone)
	# Ramen, med en mjuk skugga under telefonen.
	var body := Panel.new()
	body.size = PhoneTheme.BODY_SIZE
	var body_style := PhoneTheme.rounded(PhoneTheme.BEZEL, PhoneTheme.BODY_RADIUS, PhoneTheme.BEZEL_EDGE, 2)
	body_style.shadow_color = Color(0, 0, 0, 0.35)
	body_style.shadow_size = 18
	body_style.shadow_offset = Vector2(0, 6)
	body.add_theme_stylebox_override("panel", body_style)
	_phone.add_child(body)
	# Skärmen: allt på den klipps mot de rundade hörnen.
	_screen = Panel.new()
	_screen.position = Vector2.ONE * PhoneTheme.BEZEL_WIDTH
	_screen.size = screen_size
	_screen.clip_contents = true
	_screen.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_set_screen_color(PhoneTheme.PAPER)
	_phone.add_child(_screen)
	_wallpaper = Control.new()
	_wallpaper.size = screen_size
	_wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wallpaper.draw.connect(func() -> void:
		_draw_wallpaper(_wallpaper, _current_wallpaper(), Rect2(Vector2.ZERO, _wallpaper.size), true))
	_screen.add_child(_wallpaper)
	# Innehållet (byts per app) rullar mellan statusraden och hemindikatorn.
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(0, PhoneTheme.STATUS_HEIGHT)
	_scroll.size = Vector2(screen_size.x, screen_size.y - PhoneTheme.STATUS_HEIGHT - 22)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var bar := _scroll.get_v_scroll_bar()
	var grabber := PhoneTheme.rounded(Color(PhoneTheme.INK, 0.25), 2)
	grabber.content_margin_left = 2
	grabber.content_margin_right = 2
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		bar.add_theme_stylebox_override(state, grabber)
	bar.add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	_screen.add_child(_scroll)
	_content = VBoxContainer.new()
	_content.custom_minimum_size.x = screen_size.x
	_content.add_theme_constant_override("separation", 10)
	_scroll.add_child(_content)
	_fixed = Control.new()
	_fixed.size = screen_size
	_fixed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_fixed)
	_status_bar = Control.new()
	_status_bar.size = Vector2(screen_size.x, PhoneTheme.STATUS_HEIGHT)
	_status_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_bar.draw.connect(_draw_status_bar)
	_screen.add_child(_status_bar)
	# Hemindikatorn längst ned: klick går till hemskärmen (eller låser upp).
	_home_bar = Button.new()
	_home_bar.focus_mode = Control.FOCUS_NONE
	_home_bar.size = Vector2(150, 22)
	_home_bar.position = Vector2((screen_size.x - 150) / 2, screen_size.y - 22)
	for state in ["normal", "hover", "pressed", "focus"]:
		_home_bar.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_home_bar.draw.connect(func() -> void:
		var bar_size := PhoneTheme.HOME_INDICATOR
		var color := Color.WHITE if _light_status else PhoneTheme.INK
		_home_bar.draw_style_box(PhoneTheme.rounded(Color(color, 0.9), 3), Rect2((_home_bar.size - bar_size) / 2 + Vector2(0, 1), bar_size)))
	_home_bar.pressed.connect(func() -> void:
		if _page == "lock":
			_unlock()
		else:
			_show("home"))
	_screen.add_child(_home_bar)


## Knapparna på sidorna: ljud av, volym upp och ned till vänster, låsknappen till höger.
func _draw_side_buttons() -> void:
	var right := PhoneTheme.BODY_SIZE.x - 1
	for rect in [Rect2(-3, 112, 4, 24), Rect2(-3, 152, 4, 44), Rect2(-3, 204, 4, 44), Rect2(right, 168, 4, 70)]:
		_phone.draw_style_box(PhoneTheme.rounded(PhoneTheme.BEZEL_EDGE, 2), rect)


func _set_screen_color(color: Color) -> void:
	_screen.add_theme_stylebox_override("panel", PhoneTheme.rounded(color, PhoneTheme.SCREEN_RADIUS))


## Statusraden: tidszonen till vänster, ön i mitten, signal, wifi och batteri till höger.
func _draw_status_bar() -> void:
	var c := _status_bar
	var w := c.size.x
	var color := Color.WHITE if _light_status else PhoneTheme.INK
	var period := GameState.get_time_of_day()
	c.draw_string(PhoneTheme.font(600), Vector2(26, 29), GameState.PERIOD_NAMES[period], HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.BODY, color)
	var island := Rect2(Vector2((w - PhoneTheme.ISLAND_SIZE.x) / 2, 10), PhoneTheme.ISLAND_SIZE)
	c.draw_style_box(PhoneTheme.rounded(Color.BLACK, int(PhoneTheme.ISLAND_SIZE.y / 2)), island)
	c.draw_circle(Vector2(island.end.x - 14, island.get_center().y), 4, Color(0.13, 0.13, 0.18), true, -1.0, true)
	PhoneIcons.draw(c, "signal", Rect2(w - 90, 16, 16, 16), color)
	PhoneIcons.draw(c, "wifi", Rect2(w - 70, 15, 17, 17), color, 2.4)
	PhoneIcons.draw(c, "battery", Rect2(w - 49, 12, 24, 24), color, 2.0, PhoneTheme.battery_level(period))


# --- Bakgrunder ---------------------------------------------------------------

## Bakgrunden för sidan som visas: låsskärmens eller hemskärmens.
func _current_wallpaper() -> String:
	var slot := "lock" if _page in ["lock", "unlocking"] else "home"
	return _valid_wallpaper(GameState.phone_wallpapers.get(slot, ""))


## Värdet om det går att visa, annars den första färdiga bakgrunden.
func _valid_wallpaper(value: String) -> String:
	var parts := value.split(":")
	if parts.size() == 2:
		if parts[0] == "preset" and PhoneData.WALLPAPER_PRESETS.has(parts[1]):
			return value
		if parts[0] == "memory" and GameState.memories.has(parts[1]) and PhoneData.memory_image(parts[1]) != "":
			return value
	return "preset:" + PhoneData.WALLPAPER_PRESETS.keys()[0]


## Ritar en bakgrund som fyller rect. Bilder beskärs så att de täcker (på höjden där
## minnets wallpaper_focus säger). scrims mörkar upp- och nederkanten lite så att
## statusraden och dockan syns på ljusa bilder.
func _draw_wallpaper(c: CanvasItem, value: String, rect: Rect2, scrims := false) -> void:
	var parts := value.split(":")
	var texture: Texture2D
	var focus := 0.5
	if parts[0] == "memory":
		texture = _texture(PhoneData.memory_image(parts[1]))
		focus = PhoneData.MEMORIES[parts[1]].get("wallpaper_focus", 0.5)
	else:
		texture = _texture("res://Assets/ui/phone/wallpapers/%s.png" % parts[1])
	if texture != null:
		var texture_size := texture.get_size()
		var zoom := maxf(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
		var source := rect.size / zoom
		c.draw_texture_rect_region(texture, rect, Rect2(Vector2((texture_size.x - source.x) / 2, (texture_size.y - source.y) * focus), source))
	else:
		var colors: Array = PhoneData.WALLPAPER_PRESETS[parts[1]]["colors"]
		_vertical_gradient(c, rect, colors[0], colors[1])
		# Två mjuka ljusfläckar ger djup.
		c.draw_circle(rect.position + rect.size * Vector2(0.85, 0.18), rect.size.x * 0.55, Color(1, 1, 1, 0.1), true, -1.0, true)
		c.draw_circle(rect.position + rect.size * Vector2(0.1, 0.8), rect.size.x * 0.7, Color(colors[1].darkened(0.2), 0.18), true, -1.0, true)
	if scrims:
		var top := rect.size.y * 0.15
		var bottom := rect.size.y * 0.28
		_vertical_gradient(c, Rect2(rect.position, Vector2(rect.size.x, top)), Color(0, 0, 0, 0.3), Color(0, 0, 0, 0))
		_vertical_gradient(c, Rect2(rect.position.x, rect.end.y - bottom, rect.size.x, bottom), Color(0, 0, 0, 0), Color(0, 0, 0, 0.3))


func _vertical_gradient(c: CanvasItem, rect: Rect2, top: Color, bottom: Color) -> void:
	c.draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), PackedColorArray([top, top, bottom, bottom]))


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if path != "" and ResourceLoader.exists(path) else null
	return _textures[path]


# --- Sidor --------------------------------------------------------------------

func _show(page: String, animate := true) -> void:
	_page = page
	_close_sheet()
	for layer_node in [_content, _fixed]:
		for child in layer_node.get_children():
			child.queue_free()
	_scroll.scroll_vertical = 0
	var on_wallpaper := page in ["lock", "home"]
	_wallpaper.visible = on_wallpaper
	_scroll.visible = not on_wallpaper
	_light_status = on_wallpaper or page == "call"
	_set_screen_color(PhoneTheme.INK if page == "call" else PhoneTheme.PAPER)
	for node in [_wallpaper, _status_bar, _home_bar]:
		node.queue_redraw()
	match page:
		"lock":
			_lock()
		"home":
			_home()
		"phone":
			_contacts()
		"call":
			_call_screen()
		"messages":
			_threads()
		"thread":
			_thread()
		"memories":
			_memories()
		"memory":
			_memory_detail()
		"profile":
			_profile()
		"wallet":
			_wallet()
		"journal":
			_journal()
		"settings":
			_settings()
		"wallpaper":
			_wallpaper_page()
	if animate:
		for layer_node in [_content, _fixed]:
			layer_node.modulate.a = 0.0
			create_tween().tween_property(layer_node, "modulate:a", 1.0, 0.14)


# --- Låsskärmen ---------------------------------------------------------------

## Låsskärmen: hänglås, veckodag och dag, tidszonen i stort, och notiser om olästa sms
## och nya minnen. Klick låser upp; en notis låser upp direkt till sin app.
func _lock() -> void:
	var w := PhoneTheme.SCREEN_SIZE.x
	var unlock_area := Button.new()
	unlock_area.size = PhoneTheme.SCREEN_SIZE
	unlock_area.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus"]:
		unlock_area.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	unlock_area.pressed.connect(_unlock)
	_fixed.add_child(unlock_area)
	var head := Control.new()
	head.position = Vector2(0, 50)
	head.size = Vector2(w, 130)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.draw.connect(func() -> void:
		PhoneIcons.draw(head, "lock", Rect2(w / 2 - 9, 0, 18, 18), Color.WHITE)
		_shadow_string(head, PhoneTheme.font(600), Vector2(0, 46), "%s, Day %d" % [GameState.get_weekday(), GameState.day], w, PhoneTheme.CALLOUT, Color(1, 1, 1, 0.9))
		_shadow_string(head, PhoneTheme.font(700), Vector2(0, 104), GameState.PERIOD_NAMES[GameState.get_time_of_day()], w, PhoneTheme.CLOCK - 8, Color.WHITE))
	_fixed.add_child(head)
	var notes := _notifications()
	var y := 196.0
	for note in notes.slice(0, 3):
		var card := _notification_card(note)
		card.position = Vector2(12, y)
		_fixed.add_child(card)
		y += card.size.y + 8
	var hint := Control.new()
	hint.position = Vector2(0, PhoneTheme.SCREEN_SIZE.y - 52)
	hint.size = Vector2(w, 20)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.draw.connect(func() -> void:
		_shadow_string(hint, PhoneTheme.font(600), Vector2(0, 14), "Click to unlock", w, PhoneTheme.FOOTNOTE, Color(1, 1, 1, 0.8)))
	_fixed.add_child(hint)
	if notes.is_empty():
		_lock_token += 1
		var token := _lock_token
		get_tree().create_timer(AUTO_UNLOCK).timeout.connect(func() -> void:
			if is_open and _page == "lock" and token == _lock_token:
				_unlock())


## Notiserna på låsskärmen: {app, title, text, page, contact}.
func _notifications() -> Array:
	var notes := []
	for contact_id in GameState.unread:
		var thread: Array = GameState.messages.get(contact_id, [])
		notes.append({"app": "messages", "title": PhoneData.CONTACTS[contact_id]["name"], "text": str(thread[-1][1]) if not thread.is_empty() else "", "page": "thread", "contact": contact_id})
	var unseen := GameState.memories.keys().filter(func(memory_id: String) -> bool: return not GameState.memories[memory_id]["seen"])
	if not unseen.is_empty():
		var titles := ", ".join(unseen.map(func(memory_id: String) -> String: return PhoneData.MEMORIES[memory_id]["title"]))
		notes.append({"app": "memories", "title": "New memory" if unseen.size() == 1 else "%d new memories" % unseen.size(), "text": titles, "page": "memories", "contact": ""})
	return notes


func _notification_card(note: Dictionary) -> Button:
	var card := Button.new()
	card.size = Vector2(PhoneTheme.SCREEN_SIZE.x - 24, 72)
	card.focus_mode = Control.FOCUS_NONE
	PhoneTheme.style_button(card, Color(1, 1, 1, 0.8), 18, PhoneTheme.INK)
	card.draw.connect(func() -> void:
		var width := card.size.x - 24
		PhoneIcons.draw_tile(card, note["app"], Rect2(12, 11, 20, 20))
		card.draw_string(PhoneTheme.font(600), Vector2(40, 25), APP_NAMES[note["app"]].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.CAPTION, PhoneTheme.MUTED)
		card.draw_string(PhoneTheme.font(400), Vector2(12, 25), "now", HORIZONTAL_ALIGNMENT_RIGHT, width, PhoneTheme.CAPTION, PhoneTheme.MUTED)
		card.draw_string(PhoneTheme.font(600), Vector2(12, 47), note["title"], HORIZONTAL_ALIGNMENT_LEFT, width, PhoneTheme.BODY, PhoneTheme.INK)
		card.draw_string(PhoneTheme.font(400), Vector2(12, 63), _ellipsize(note["text"], PhoneTheme.font(400), PhoneTheme.SUBHEAD, width), HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.SUBHEAD, PhoneTheme.INK))
	card.pressed.connect(func() -> void:
		_thread_contact = note["contact"]
		_unlock(note["page"]))
	return card


## Låser upp: låsskärmen glider uppåt och tonar bort, sedan visas target.
func _unlock(target := "home") -> void:
	if _page != "lock":
		return
	_page = "unlocking"
	_unlocked_period = _period_key()
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_fixed, "position:y", -60.0, 0.2)
	tween.tween_property(_fixed, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(func() -> void:
		_fixed.position.y = 0
		if is_open:
			_show(target))


# --- Hemskärmen ---------------------------------------------------------------

## Hemskärmen: datumwidget överst, apparna i ett rutnät med fyra kolumner och dockan
## längst ned.
func _home() -> void:
	var screen_size := PhoneTheme.SCREEN_SIZE
	_fixed.add_child(_date_widget())
	var column_width := (screen_size.x - 40) / 4.0
	for i in GRID_APPS.size():
		var cell := _app_icon(GRID_APPS[i], true)
		cell.position = Vector2(20 + (i % 4) * column_width + (column_width - PhoneTheme.TILE_SIZE) / 2, 172 + (i / 4) * 90)
		_fixed.add_child(cell)
	var dock := Panel.new()
	dock.position = Vector2(12, screen_size.y - 22 - PhoneTheme.DOCK_HEIGHT)
	dock.size = Vector2(screen_size.x - 24, PhoneTheme.DOCK_HEIGHT)
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.add_theme_stylebox_override("panel", PhoneTheme.rounded(Color(1, 1, 1, 0.26), PhoneTheme.DOCK_RADIUS, Color(1, 1, 1, 0.32), 1))
	_fixed.add_child(dock)
	var cell_width := dock.size.x / DOCK_APPS.size()
	for i in DOCK_APPS.size():
		var icon := _app_icon(DOCK_APPS[i], false)
		icon.position = dock.position + Vector2(cell_width * (i + 0.5) - PhoneTheme.TILE_SIZE / 2.0, (PhoneTheme.DOCK_HEIGHT - PhoneTheme.TILE_SIZE) / 2.0)
		_fixed.add_child(icon)


## Widgeten med veckodag, tidszon och dag, och hur många quests som pågår.
func _date_widget() -> Control:
	var widget := Control.new()
	widget.position = Vector2(20, 58)
	widget.size = Vector2(PhoneTheme.SCREEN_SIZE.x - 40, 96)
	widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	widget.draw.connect(func() -> void:
		var right := widget.size.x - 18
		var faint := Color(1, 1, 1, 0.75)
		var active := GameState.quests.values().count("active")
		widget.draw_style_box(PhoneTheme.rounded(Color(0.12, 0.09, 0.07, 0.3), 22, Color(1, 1, 1, 0.18), 1), Rect2(Vector2.ZERO, widget.size))
		widget.draw_string(PhoneTheme.font(600), Vector2(18, 30), GameState.get_weekday().to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.CAPTION, faint)
		widget.draw_string(PhoneTheme.font(700), Vector2(18, 62), GameState.PERIOD_NAMES[GameState.get_time_of_day()], HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.TITLE, Color.WHITE)
		widget.draw_string(PhoneTheme.font(400), Vector2(18, 82), "Day %d" % GameState.day, HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.FOOTNOTE, faint)
		PhoneIcons.draw(widget, "journal", Rect2(right - 20, 14, 20, 20), faint)
		widget.draw_string(PhoneTheme.font(700), Vector2(0, 62), str(active), HORIZONTAL_ALIGNMENT_RIGHT, right, PhoneTheme.TITLE, Color.WHITE)
		widget.draw_string(PhoneTheme.font(400), Vector2(0, 82), "active quest" if active == 1 else "active quests", HORIZONTAL_ALIGNMENT_RIGHT, right, PhoneTheme.FOOTNOTE, faint))
	return widget


## En appikon med ett rött märke (olästa sms på Messages, nya minnen på Memories) och
## appens namn under om with_label.
func _app_icon(app_id: String, with_label: bool) -> Control:
	var tile := PhoneTheme.TILE_SIZE
	var cell := Control.new()
	cell.size = Vector2(tile, tile + 20 if with_label else tile)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var button := Button.new()
	button.size = Vector2(tile, tile)
	button.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.draw.connect(func() -> void:
		var pressed := button.get_draw_mode() in [BaseButton.DRAW_PRESSED, BaseButton.DRAW_HOVER_PRESSED]
		PhoneIcons.draw_tile(button, app_id, Rect2(Vector2.ZERO, button.size), pressed))
	button.pressed.connect(func() -> void: _show(app_id))
	cell.add_child(button)
	var badge_count := {"messages": GameState.unread.size(), "memories": GameState.unseen_memory_count()}.get(app_id, 0) as int
	if badge_count > 0:
		var badge := Label.new()
		badge.text = str(badge_count)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.custom_minimum_size = Vector2(20, 20)
		badge.position = Vector2(tile - 13, -7)
		badge.add_theme_font_override("font", PhoneTheme.font(600))
		badge.add_theme_font_size_override("font_size", PhoneTheme.FOOTNOTE)
		badge.add_theme_color_override("font_color", Color.WHITE)
		badge.add_theme_stylebox_override("normal", PhoneTheme.rounded(PhoneTheme.BADGE, 10))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(badge)
	if with_label:
		var label := Label.new()
		label.text = APP_NAMES[app_id]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(-10, tile + 3)
		label.size = Vector2(tile + 20, 16)
		label.add_theme_font_override("font", PhoneTheme.font(600))
		label.add_theme_font_size_override("font_size", PhoneTheme.CAPTION)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		label.add_theme_constant_override("shadow_offset_x", 0)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(label)
	return cell


# --- Byggstenar för apparnas sidor --------------------------------------------

func _label(text: String, size: int, color := PhoneTheme.INK, weight := 400, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", PhoneTheme.font(weight))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


## Lägger till en kontroll i sidan med marginal på sidorna.
func _padded(control: Control, side := PhoneTheme.SIDE) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", side)
	margin.add_theme_constant_override("margin_right", side)
	margin.add_child(control)
	_content.add_child(margin)


func _spacer(height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	_content.add_child(spacer)


## Bakåtknappen: en pil och namnet på sidan den leder till.
func _back_row(back_to: String) -> void:
	var title: String = PAGE_TITLES.get(back_to, "Back")
	var back := Button.new()
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size = Vector2(PhoneTheme.font(400).get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.CALLOUT).x + 34, 32)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for state in ["normal", "hover", "pressed", "focus"]:
		back.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	back.draw.connect(func() -> void:
		var color := PhoneTheme.ACCENT if back.get_draw_mode() == BaseButton.DRAW_NORMAL else PhoneTheme.ACCENT.darkened(0.25)
		PhoneIcons.draw(back, "back", Rect2(4, 7, 18, 18), color, 2.6)
		back.draw_string(PhoneTheme.font(400), Vector2(24, 21), title, HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.CALLOUT, color))
	back.pressed.connect(func() -> void: _show(back_to))
	_padded(back, 8)


## Sidhuvud: bakåtknapp och stor rubrik.
func _header(title: String, back_to := "home") -> void:
	_back_row(back_to)
	_padded(_label(title, PhoneTheme.TITLE, PhoneTheme.INK, 700))


## Rubrik över en grupp, i versaler.
func _section(text: String) -> void:
	var label := _label(text.to_upper(), PhoneTheme.FOOTNOTE, PhoneTheme.MUTED, 600)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", PhoneTheme.SIDE * 2)
	margin.add_theme_constant_override("margin_right", PhoneTheme.SIDE * 2)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_child(label)
	_content.add_child(margin)


## Rader i ett vitt rundat kort med tunna linjer emellan, indragna inset pixlar.
func _group(rows: Array, inset := PhoneTheme.SIDE) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", PhoneTheme.rounded(PhoneTheme.CARD, PhoneTheme.CARD_RADIUS, PhoneTheme.LINE, 1))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	for i in rows.size():
		if i > 0:
			var line := Control.new()
			line.custom_minimum_size.y = 1
			line.draw.connect(func() -> void: line.draw_line(Vector2(inset, 0.5), Vector2(line.size.x, 0.5), PhoneTheme.LINE, 1.0))
			column.add_child(line)
		# Den första och sista radens markering följer kortets rundade hörn.
		if rows[i] is Button:
			for state in ["hover", "pressed"]:
				var style := (rows[i] as Button).get_theme_stylebox(state).duplicate() as StyleBoxFlat
				if i == 0:
					style.corner_radius_top_left = PhoneTheme.CARD_RADIUS
					style.corner_radius_top_right = PhoneTheme.CARD_RADIUS
				if i == rows.size() - 1:
					style.corner_radius_bottom_left = PhoneTheme.CARD_RADIUS
					style.corner_radius_bottom_right = PhoneTheme.CARD_RADIUS
				style.corner_detail = 16
				rows[i].add_theme_stylebox_override(state, style)
		column.add_child(rows[i])
	card.add_child(column)
	_padded(card)


func _row_button(height: float) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, height)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in [["hover", 0.04], ["pressed", 0.08]]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(PhoneTheme.INK, state[1])
		button.add_theme_stylebox_override(state[0], style)
	return button


## En rad med rund avatar och initialer, namn, en undertext och en pil.
func _list_row(title: String, subtitle: String, color: Color, on_pressed: Callable, unread := false) -> Button:
	var button := _row_button(58)
	button.pressed.connect(on_pressed)
	var initials := _initials(title)
	button.draw.connect(func() -> void:
		var width := button.size.x - 62 - 44
		_draw_avatar(button, Vector2(31, 29), 19, color, initials)
		button.draw_string(PhoneTheme.font(600), Vector2(62, 26), _ellipsize(title, PhoneTheme.font(600), PhoneTheme.CALLOUT, width), HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.CALLOUT, PhoneTheme.INK)
		button.draw_string(PhoneTheme.font(400), Vector2(62, 44), _ellipsize(subtitle, PhoneTheme.font(400), PhoneTheme.SUBHEAD, width), HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.SUBHEAD, PhoneTheme.MUTED)
		if unread:
			button.draw_circle(Vector2(button.size.x - 36, 29), 4.5, PhoneTheme.ACCENT, true, -1.0, true)
		PhoneIcons.draw(button, "chevron", Rect2(button.size.x - 24, 22, 14, 14), Color(PhoneTheme.MUTED, 0.6), 2.4))
	return button


## En rad med ett namn till vänster och ett värde till höger.
func _value_row(key: String, value: String) -> Control:
	var row := Control.new()
	row.custom_minimum_size.y = 44
	row.draw.connect(func() -> void:
		var right := row.size.x - PhoneTheme.SIDE
		row.draw_string(PhoneTheme.font(400), Vector2(PhoneTheme.SIDE, 27), key, HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.BODY, PhoneTheme.INK)
		var text := _ellipsize(value, PhoneTheme.font(400), PhoneTheme.BODY, right - 90)
		row.draw_string(PhoneTheme.font(400), Vector2(0, 27), text, HORIZONTAL_ALIGNMENT_RIGHT, right, PhoneTheme.BODY, PhoneTheme.MUTED))
	return row


## En stor rundad knapp, ifylld (huvudval) eller med kant, med en symbol före texten.
func _action_button(text: String, glyph: String, on_pressed: Callable, filled := true) -> void:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 46
	button.add_theme_font_override("font", PhoneTheme.font(600))
	button.add_theme_font_size_override("font_size", PhoneTheme.CALLOUT)
	var text_color := Color.WHITE if filled else PhoneTheme.ACCENT
	if filled:
		PhoneTheme.style_button(button, PhoneTheme.ACCENT, PhoneTheme.BUTTON_RADIUS, text_color)
	else:
		PhoneTheme.style_button(button, PhoneTheme.CARD, PhoneTheme.BUTTON_RADIUS, text_color, Color(PhoneTheme.ACCENT, 0.5))
	if glyph != "":
		button.draw.connect(func() -> void:
			var text_width := PhoneTheme.font(600).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.CALLOUT).x
			PhoneIcons.draw(button, glyph, Rect2((button.size.x - text_width) / 2 - 24, (button.size.y - 16) / 2, 16, 16), text_color, 2.4))
	button.pressed.connect(on_pressed)
	_padded(button)


## Flikar som ett segmenterat reglage: [[id, text]]. on_select får flikens id.
func _segmented(options: Array, selected: String, on_select: Callable) -> void:
	var bar := PanelContainer.new()
	var bar_style := PhoneTheme.rounded(Color(PhoneTheme.INK, 0.07), 10)
	bar_style.set_content_margin_all(2)
	bar.add_theme_stylebox_override("panel", bar_style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	for tab in options:
		var button := Button.new()
		button.text = tab[1]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size.y = 30
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_override("font", PhoneTheme.font(600))
		button.add_theme_font_size_override("font_size", PhoneTheme.SUBHEAD)
		if selected == tab[0]:
			PhoneTheme.style_button(button, PhoneTheme.CARD, 8, PhoneTheme.INK)
		else:
			PhoneTheme.style_button(button, Color(0, 0, 0, 0), 8, PhoneTheme.MUTED)
		button.pressed.connect(on_select.bind(tab[0]))
		row.add_child(button)
	bar.add_child(row)
	_padded(bar)


func _draw_avatar(c: CanvasItem, center: Vector2, radius: float, color: Color, initials: String) -> void:
	c.draw_circle(center, radius, color, true, -1.0, true)
	var size := int(radius * 0.75)
	var font := PhoneTheme.font(600)
	var width := font.get_string_size(initials, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	c.draw_string(font, center + Vector2(-width / 2, size * 0.36), initials, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE)


func _initials(full_name: String) -> String:
	var initials := ""
	for word in full_name.split(" ", false):
		initials += word.substr(0, 1)
	return initials


## Texten förkortad med … så att den ryms i width pixlar.
func _ellipsize(text: String, font: Font, size: int, width: float) -> String:
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width:
		return text
	while text.length() > 1 and font.get_string_size(text + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		text = text.left(-1)
	return text + "…"


## Centrerad text med en svag skugga, för text direkt på en bakgrundsbild.
func _shadow_string(c: CanvasItem, font: Font, at: Vector2, text: String, width: float, size: int, color: Color) -> void:
	c.draw_string(font, at + Vector2(0, 1), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color(0, 0, 0, 0.25))
	c.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)


## Ett kort meddelande nederst på skärmen som tonar bort.
func _toast(text: String) -> void:
	var toast := Label.new()
	toast.text = text
	toast.add_theme_font_override("font", PhoneTheme.font(600))
	toast.add_theme_font_size_override("font_size", PhoneTheme.SUBHEAD)
	toast.add_theme_color_override("font_color", Color.WHITE)
	var style := PhoneTheme.rounded(Color(PhoneTheme.INK, 0.88), 16)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	toast.add_theme_stylebox_override("normal", style)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(toast)
	toast.size = toast.get_minimum_size()
	toast.position = Vector2((PhoneTheme.SCREEN_SIZE.x - toast.size.x) / 2, PhoneTheme.SCREEN_SIZE.y - 84)
	toast.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.15)
	tween.tween_interval(1.2)
	tween.tween_property(toast, "modulate:a", 0.0, 0.25)
	tween.tween_callback(toast.queue_free)


## Ett ark som glider upp nederst med val: [[text, Callable]] och Cancel sist.
func _open_sheet(title: String, options: Array) -> void:
	_close_sheet()
	_sheet = Control.new()
	_sheet.size = PhoneTheme.SCREEN_SIZE
	_screen.add_child(_sheet)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close_sheet())
	_sheet.add_child(dim)
	var panel := PanelContainer.new()
	var style := PhoneTheme.rounded(PhoneTheme.PAPER, PhoneTheme.SCREEN_RADIUS - 8)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 8
	panel.offset_right = -8
	panel.offset_bottom = -8
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.add_child(_label(title, PhoneTheme.FOOTNOTE, PhoneTheme.MUTED, 600, HORIZONTAL_ALIGNMENT_CENTER))
	for option in options + [["Cancel", _close_sheet]]:
		var button := Button.new()
		button.text = option[0]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size.y = 44
		button.add_theme_font_override("font", PhoneTheme.font(600 if option[0] == "Cancel" else 400))
		button.add_theme_font_size_override("font_size", PhoneTheme.CALLOUT)
		PhoneTheme.style_button(button, PhoneTheme.CARD, PhoneTheme.CARD_RADIUS, PhoneTheme.ACCENT, PhoneTheme.LINE)
		button.pressed.connect(option[1])
		column.add_child(button)
	panel.add_child(column)
	_sheet.add_child(panel)
	_sheet.modulate.a = 0.0
	create_tween().tween_property(_sheet, "modulate:a", 1.0, 0.12)


func _close_sheet() -> void:
	if _sheet != null:
		_sheet.queue_free()
		_sheet = null


# --- Phone --------------------------------------------------------------------

func _contacts() -> void:
	_header("Contacts")
	var rows := []
	for contact_id in GameState.known_contacts:
		var contact: Dictionary = PhoneData.CONTACTS[contact_id]
		var subtitle := "mobile"
		if GameState.links.has(contact_id):
			var link: Dictionary = GameState.links[contact_id]
			subtitle = "♥ Rank %d  ·  %d%% to next" % [link["rank"], roundi(GameState.link_progress(contact_id) * 100)]
		rows.append(_list_row(contact["name"], subtitle, contact["color"], func() -> void:
			_call_contact = contact_id
			_show("call")))
	_group(rows, 62)


## Ett samtal på mörk skärm: stor avatar, namn, samtalets repliker och en röd knapp
## som lägger på.
func _call_screen() -> void:
	var contact: Dictionary = PhoneData.CONTACTS[_call_contact]
	_spacer(30)
	var avatar := Control.new()
	avatar.custom_minimum_size.y = 112
	avatar.draw.connect(func() -> void:
		_draw_avatar(avatar, Vector2(avatar.size.x / 2, 54), 52, contact["color"], _initials(contact["name"])))
	_content.add_child(avatar)
	_content.add_child(_label(contact["name"], PhoneTheme.TITLE, Color.WHITE, 700, HORIZONTAL_ALIGNMENT_CENTER))
	_content.add_child(_label("calling…", PhoneTheme.CALLOUT, Color(1, 1, 1, 0.65), 400, HORIZONTAL_ALIGNMENT_CENTER))
	var transcript := PanelContainer.new()
	var style := PhoneTheme.rounded(Color(1, 1, 1, 0.08), PhoneTheme.CARD_RADIUS)
	style.set_content_margin_all(14)
	transcript.add_theme_stylebox_override("panel", style)
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 8)
	for line in PhoneData.CALLS.get(_call_contact, PhoneData.CALLS["default"]):
		lines.add_child(_label(("%s: %s" % [line[0], line[1]]) if line[0] != "" else line[1], PhoneTheme.BODY, Color(1, 1, 1, 0.85), 400, HORIZONTAL_ALIGNMENT_CENTER))
	transcript.add_child(lines)
	_spacer(4)
	_padded(transcript, 20)
	_spacer(14)
	var hang_up := Button.new()
	hang_up.custom_minimum_size = Vector2(64, 64)
	hang_up.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hang_up.focus_mode = Control.FOCUS_NONE
	PhoneTheme.style_button(hang_up, PhoneTheme.DANGER, 32)
	hang_up.draw.connect(func() -> void:
		PhoneIcons.draw(hang_up, "end_call", Rect2(17, 17, 30, 30), Color.WHITE))
	hang_up.pressed.connect(func() -> void: _show("phone"))
	_content.add_child(hang_up)
	_content.add_child(_label("End", PhoneTheme.FOOTNOTE, Color(1, 1, 1, 0.7), 600, HORIZONTAL_ALIGNMENT_CENTER))


# --- Messages -----------------------------------------------------------------

func _threads() -> void:
	_header("Messages")
	var rows := []
	for contact_id in GameState.known_contacts:
		var thread: Array = GameState.messages.get(contact_id, [])
		var contact: Dictionary = PhoneData.CONTACTS[contact_id]
		var preview := "No messages yet"
		if not thread.is_empty():
			preview = ("You: " if thread[-1][0] == "me" else "") + str(thread[-1][1])
		var open_thread := func() -> void:
			_thread_contact = contact_id
			_show("thread")
		rows.append(_list_row(contact["name"], preview, contact["color"], open_thread, contact_id in GameState.unread))
	_group(rows, 62)


## En sms-tråd: kontakten överst, mammans sms i teal till höger, svaren till vänster,
## och valen för vad hon kan skriva nederst.
func _thread() -> void:
	var contact_id := _thread_contact
	var contact: Dictionary = PhoneData.CONTACTS[contact_id]
	GameState.mark_read(contact_id)
	_back_row("messages")
	var avatar := Control.new()
	avatar.custom_minimum_size.y = 66
	avatar.draw.connect(func() -> void:
		_draw_avatar(avatar, Vector2(avatar.size.x / 2, 22), 22, contact["color"], _initials(contact["name"]))
		avatar.draw_string(PhoneTheme.font(600), Vector2(0, 62), contact["name"], HORIZONTAL_ALIGNMENT_CENTER, avatar.size.x, PhoneTheme.SUBHEAD, PhoneTheme.INK))
	_content.add_child(avatar)
	for message in GameState.messages.get(contact_id, []):
		_bubble(message[1], message[0] == "me")
	_section("Reply")
	for option in PhoneData.REPLIES.get(contact_id, PhoneData.REPLIES["default"]):
		var button := Button.new()
		button.text = option[0]
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", PhoneTheme.BODY)
		PhoneTheme.style_button(button, PhoneTheme.CARD, 18, PhoneTheme.ACCENT, Color(PhoneTheme.ACCENT, 0.45), Vector2(14, 9))
		button.pressed.connect(func() -> void:
			GameState.send_message(contact_id, option[0])
			# Svaret kommer en liten stund senare.
			get_tree().create_timer(1.2).timeout.connect(func() -> void:
				GameState.receive_message(contact_id, option[1])
				if _page == "thread" and _thread_contact == contact_id:
					GameState.mark_read(contact_id)))
		_padded(button)
	_spacer(6)
	_scroll_to_end()


func _bubble(text: String, from_me: bool) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END if from_me else BoxContainer.ALIGNMENT_BEGIN
	var bubble := PanelContainer.new()
	var style := PhoneTheme.rounded(PhoneTheme.ACCENT if from_me else PhoneTheme.THEM_BUBBLE, 18)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	bubble.add_theme_stylebox_override("panel", style)
	var label := _label(text, PhoneTheme.BODY, Color.WHITE if from_me else PhoneTheme.INK)
	label.custom_minimum_size.x = minf(210, PhoneTheme.font(400).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.BODY).x + 2)
	bubble.add_child(label)
	row.add_child(bubble)
	_padded(row, 14)


func _scroll_to_end() -> void:
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


# --- Memories -----------------------------------------------------------------

## Minnena i ett rutnät med flikar för alla, scener och bilder. Scener har en
## uppspelningsknapp, nya minnen en prick och låsta visas som tomma rutor med ett lås.
func _memories() -> void:
	_header("Memories")
	_padded(_label("%d of %d collected" % [GameState.memories.size(), PhoneData.MEMORIES.size()], PhoneTheme.SUBHEAD, PhoneTheme.MUTED))
	_segmented([["all", "All"], ["scene", "Scenes"], ["picture", "Pictures"]], _memories_tab, func(tab: String) -> void:
		_memories_tab = tab
		_show("memories", false))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	var tile_width := floorf((PhoneTheme.SCREEN_SIZE.x - PhoneTheme.SIDE * 2 - 10) / 3)
	for memory_id in PhoneData.MEMORIES:
		var memory: Dictionary = PhoneData.MEMORIES[memory_id]
		if _memories_tab != "all" and memory["type"] != _memories_tab:
			continue
		var collected: bool = GameState.memories.has(memory_id)
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(tile_width, 112)
		tile.focus_mode = Control.FOCUS_NONE
		PhoneTheme.style_button(tile, PhoneTheme.THEM_BUBBLE if collected else Color(PhoneTheme.INK, 0.07), 10)
		if collected:
			var thumb := _memory_thumb(memory_id, 12)
			PhoneTheme.round_corners(thumb, 10)
			tile.add_child(thumb)
			if not GameState.memories[memory_id]["seen"]:
				var dot := Panel.new()
				dot.add_theme_stylebox_override("panel", PhoneTheme.rounded(PhoneTheme.ACCENT, 7, Color.WHITE, 2))
				dot.position = Vector2(tile_width - 20, 8)
				dot.size = Vector2(13, 13)
				dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
				tile.add_child(dot)
			tile.pressed.connect(func() -> void:
				_memory = memory_id
				_show("memory"))
		else:
			tile.disabled = true
			tile.draw.connect(func() -> void:
				PhoneIcons.draw(tile, "lock", Rect2(tile.size / 2 - Vector2(11, 11), Vector2(22, 22)), Color(PhoneTheme.MUTED, 0.6)))
		grid.add_child(tile)
	_padded(grid)
	_spacer(6)


## Ett minne: stor bild, vad det är, varifrån, när och var, och knappar som spelar
## scenen igen, eller visar bilden över hela skärmen och gör den till bakgrund.
func _memory_detail() -> void:
	var memory_id := _memory
	var memory: Dictionary = PhoneData.MEMORIES[memory_id]
	var record: Dictionary = GameState.memories[memory_id]
	var is_scene: bool = memory["type"] == "scene"
	GameState.mark_memory_seen(memory_id)
	_header(memory["title"], "memories")
	var preview := Panel.new()
	preview.custom_minimum_size.y = 300
	preview.add_theme_stylebox_override("panel", PhoneTheme.rounded(PhoneTheme.THEM_BUBBLE, PhoneTheme.CARD_RADIUS))
	var thumb := _memory_thumb(memory_id, 22, false)
	PhoneTheme.round_corners(thumb, PhoneTheme.CARD_RADIUS)
	preview.add_child(thumb)
	_padded(preview)
	var rows := [_value_row("Type", "Scene" if is_scene else "Picture")]
	var source := _memory_source(memory_id)
	if source != "":
		rows.append(_value_row("From", source))
	rows.append(_value_row("When", "Day %d · %s %s" % [record["day"], GameState.weekday_of(record["day"]), GameState.PERIOD_NAMES[record["period"]]]))
	# Var en scen hände står i scenen; för bilder berättar platsen var man fick dem.
	if not is_scene:
		rows.append(_value_row("Where", GameState.ROOMS[record["room"]]["name"]))
	_group(rows)
	if is_scene:
		_action_button("Relive", "play", func() -> void:
			_relived = memory_id
			close()
			GameState.replay_memory(memory_id))
	else:
		_action_button("View Full Screen", "image", func() -> void:
			_view_image(load(memory["image"]), "%s  ·  %s" % [memory["title"], source] if source != "" else memory["title"]))
	if PhoneData.memory_image(memory_id) != "":
		var set_on := func(slots: Array) -> void:
			for slot in slots:
				GameState.set_wallpaper(slot, "memory:" + memory_id)
			_close_sheet()
			_toast("Wallpaper set")
		var choose := func() -> void:
			_open_sheet("Use “%s” as wallpaper" % memory["title"], [
				["Lock Screen", set_on.bind(["lock"])],
				["Home Screen", set_on.bind(["home"])],
				["Both", set_on.bind(["lock", "home"])],
			])
		_action_button("Set as Wallpaper", "", choose, false)
	_spacer(6)


## Varifrån ett minne kom: texten som gavs när det lades till, annars PhoneData:s.
func _memory_source(memory_id: String) -> String:
	var source: String = GameState.memories[memory_id]["source"]
	return source if source != "" else PhoneData.MEMORIES[memory_id].get("source", "")


## Bilden för ett minne som fyller sin förälder: bilden själv, eller för scener utan
## bild ett kort i tidszonens färg med scenens namn. Scener får en uppspelningsknapp
## (play_size är dess radie). with_title ritar scenens namn på kortet.
func _memory_thumb(memory_id: String, play_size: float, with_title := true) -> Control:
	var memory: Dictionary = PhoneData.MEMORIES[memory_id]
	var image := PhoneData.memory_image(memory_id)
	var thumb: Control
	if image != "":
		var rect := TextureRect.new()
		rect.texture = _texture(image)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb = rect
	else:
		thumb = Control.new()
	thumb.set_anchors_preset(Control.PRESET_FULL_RECT)
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if memory["type"] != "scene":
		return thumb
	var night: bool = GameState.memories[memory_id]["period"] == "night"
	thumb.draw.connect(func() -> void:
		var s := thumb.size
		if image == "":
			_vertical_gradient(thumb, Rect2(Vector2.ZERO, s), Color("4a4a7a") if night else Color("f2b48f"), Color("1c1b2e") if night else Color("c96f55"))
			# Månen eller solen i hörnet.
			thumb.draw_circle(Vector2(s.x - 16, 16), 6, Color(0.95, 0.95, 0.85) if night else Color(1.0, 0.88, 0.5), true, -1.0, true)
			if with_title:
				thumb.draw_multiline_string(PhoneTheme.font(600), Vector2(8, s.y - 26), memory["title"], HORIZONTAL_ALIGNMENT_LEFT, s.x - 16, PhoneTheme.FOOTNOTE, 2, Color.WHITE)
		var center := s / 2 - Vector2(0, 8 if with_title else 0)
		thumb.draw_circle(center, play_size, Color(0, 0, 0, 0.35), true, -1.0, true)
		PhoneIcons.draw(thumb, "play", Rect2(center - Vector2.ONE * play_size * 0.6 + Vector2(play_size * 0.08, 0), Vector2.ONE * play_size * 1.2), Color.WHITE))
	return thumb


## Visar en bild över hela skärmen med namn och ursprung under; klick stänger.
func _build_viewer() -> void:
	_viewer = ColorRect.new()
	(_viewer as ColorRect).color = Color(0, 0, 0, 0.88)
	_viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewer.visible = false
	_viewer.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_viewer.visible = false)
	add_child(_viewer)
	_viewer_image = TextureRect.new()
	_viewer_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewer_image.offset_top = 20
	_viewer_image.offset_bottom = -56
	_viewer_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_viewer_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_viewer_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewer.add_child(_viewer_image)
	_viewer_caption = Label.new()
	_viewer_caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_viewer_caption.offset_top = -46
	_viewer_caption.offset_bottom = -16
	_viewer_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_viewer_caption.add_theme_font_override("font", PhoneTheme.font(600))
	_viewer_caption.add_theme_font_size_override("font_size", 18)
	_viewer_caption.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_viewer_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewer.add_child(_viewer_caption)


func _view_image(texture: Texture2D, caption := "") -> void:
	_viewer_image.texture = texture
	_viewer_caption.text = caption
	_viewer.visible = true


# --- Profile ------------------------------------------------------------------

## Mammans Attractiveness överst, sedan egenskaperna med nivå och hur långt det är
## till nästa, och sist vad Attractiveness låser upp.
func _profile() -> void:
	_header("Profile")
	var rating := GameState.attractiveness()
	var tier := GameState.attractiveness_tier()
	var card := PanelContainer.new()
	var card_style := PhoneTheme.rounded(PhoneTheme.INK, 18)
	card_style.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel", card_style)
	var card_column := VBoxContainer.new()
	card_column.add_theme_constant_override("separation", 2)
	card.add_child(card_column)
	card_column.add_child(_label("ATTRACTIVENESS", PhoneTheme.CAPTION, Color(1, 1, 1, 0.6), 600))
	card_column.add_child(_label("%.1f  %s" % [rating, SocialStats.attractiveness_title(rating)], PhoneTheme.TITLE - 4, Color.WHITE, 700))
	# Skalan 1–5 med markören där betyget ligger.
	var meter := Control.new()
	meter.custom_minimum_size = Vector2(0, 18)
	meter.draw.connect(func() -> void:
		var w := meter.size.x
		meter.draw_style_box(PhoneTheme.rounded(Color(1, 1, 1, 0.15), 4), Rect2(0, 6, w, 8))
		meter.draw_style_box(PhoneTheme.rounded(PhoneTheme.TILE["profile"], 4), Rect2(0, 6, maxf(8, w * (rating - 1.0) / 4.0), 8))
		for i in 5:
			meter.draw_circle(Vector2(clampf(w * i / 4.0, 4, w - 4), 10), 3, Color.WHITE if i + 1 <= tier else Color(1, 1, 1, 0.3), true, -1.0, true))
	card_column.add_child(meter)
	_padded(card)
	_section("Skills")
	var stats := []
	for stat in SocialStats.STATS:
		stats.append(_stat_row(stat))
	_group(stats)
	_section("What Attractiveness unlocks")
	var unlocks := []
	for needed in SocialStats.ATTRACTIVENESS_UNLOCKS:
		var unlocked: bool = tier >= needed
		var row := MarginContainer.new()
		row.add_theme_constant_override("margin_left", 44)
		row.add_theme_constant_override("margin_right", PhoneTheme.SIDE)
		row.add_theme_constant_override("margin_top", 10)
		row.add_theme_constant_override("margin_bottom", 10)
		row.add_child(_label("%d · %s — %s" % [needed, SocialStats.ATTRACTIVENESS_TITLES[needed - 1], SocialStats.ATTRACTIVENESS_UNLOCKS[needed]], PhoneTheme.SUBHEAD, PhoneTheme.INK if unlocked else PhoneTheme.MUTED))
		row.draw.connect(func() -> void:
			if unlocked:
				row.draw_circle(Vector2(24, 19), 9, PhoneTheme.ACCENT, true, -1.0, true)
				PhoneIcons.draw(row, "check", Rect2(18, 13, 12, 12), Color.WHITE, 3.0)
			else:
				row.draw_circle(Vector2(24, 19), 8.5, PhoneTheme.LINE, false, 1.5, true))
		unlocks.append(row)
	_group(unlocks, 44)
	_spacer(6)


## En egenskap: namn, nivå och nivåns namn, en stapel mot nästa nivå och XP.
func _stat_row(stat: String) -> Control:
	var data: Dictionary = SocialStats.STATS[stat]
	var level := GameState.social_level(stat)
	var xp: int = GameState.social[stat]
	var next := "max" if level >= SocialStats.MAX_LEVEL else "%d / %d XP" % [xp, SocialStats.LEVEL_XP[level]]
	var progress := GameState.social_progress(stat)
	var row := Control.new()
	row.custom_minimum_size.y = 64
	row.draw.connect(func() -> void:
		var left := float(PhoneTheme.SIDE)
		var w := row.size.x - left * 2
		row.draw_string(PhoneTheme.font(600), Vector2(left, 24), data["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.CALLOUT, PhoneTheme.INK)
		row.draw_string(PhoneTheme.font(600), Vector2(left, 24), "Lv %d · %s" % [level, SocialStats.level_name(stat, level)], HORIZONTAL_ALIGNMENT_RIGHT, w, PhoneTheme.SUBHEAD, data["color"].darkened(0.15))
		row.draw_style_box(PhoneTheme.rounded(PhoneTheme.LINE, 4), Rect2(left, 33, w, 8))
		if progress > 0:
			row.draw_style_box(PhoneTheme.rounded(data["color"], 4), Rect2(left, 33, maxf(8, w * progress), 8))
		row.draw_string(PhoneTheme.font(400), Vector2(left, 56), next, HORIZONTAL_ALIGNMENT_RIGHT, w, PhoneTheme.CAPTION, PhoneTheme.MUTED))
	return row


# --- Wallet -------------------------------------------------------------------

## Saldot överst, sedan vad som väntar (lön, räkningar, fickpengar, handling och
## abonnemang), sätten att tjäna (de som inte är hittade visas som ??? med en vag
## ledtråd) och sist kontoutdraget, nyast först.
func _wallet() -> void:
	_header("Wallet")
	var balance := GameState.money
	var card := PanelContainer.new()
	var card_style := PhoneTheme.rounded(PhoneTheme.INK, 18)
	card_style.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel", card_style)
	var card_column := VBoxContainer.new()
	card_column.add_theme_constant_override("separation", 2)
	card.add_child(card_column)
	card_column.add_child(_label("BALANCE", PhoneTheme.CAPTION, Color(1, 1, 1, 0.6), 600))
	card_column.add_child(_label(Economy.format(balance), PhoneTheme.TITLE + 4, PhoneTheme.DANGER.lightened(0.25) if balance < 0 else Color.WHITE, 700))
	var status := "In the red – money worries every night" if balance < 0 else "Salary %s on the 25th" % Economy.format(Economy.salary(GameState.flags))
	card_column.add_child(_label(status, PhoneTheme.FOOTNOTE, Color(1, 1, 1, 0.6)))
	_padded(card)

	_section("Coming up")
	var upcoming := []
	var to_payday := GameState.days_until_payday()
	upcoming.append(_money_row("Payday", "Today" if to_payday == 0 else "In %d day%s" % [to_payday, _plural(to_payday)],
			"+" + Economy.format(Economy.salary(GameState.flags)), PhoneTheme.TILE["phone"].darkened(0.2)))
	var bills := Economy.monthly_bills_total()
	for subscription in GameState.subscriptions:
		bills += Economy.SUBSCRIPTIONS[subscription]["amount"]
	var to_bills := GameState.days_until_bills()
	upcoming.append(_money_row("Monthly bills", "Today" if to_bills == 0 else "In %d day%s" % [to_bills, _plural(to_bills)],
			Economy.format(-bills), PhoneTheme.INK))
	for id in Economy.WEEKLY_BILLS:
		var bill: Dictionary = Economy.WEEKLY_BILLS[id]
		upcoming.append(_money_row(bill["name"], "Every %s" % GameState.WEEKDAYS[bill["weekday"]], Economy.format(-bill["amount"]), PhoneTheme.INK))
	var since_shopping := GameState.day - GameState.last_groceries
	var left := Economy.GROCERY_GRACE_DAYS - since_shopping
	var grocery_note := "Shopped today" if since_shopping <= 0 else "Last shopped %d day%s ago" % [since_shopping, _plural(since_shopping)]
	if left < 3:
		grocery_note = "Fridge is empty – takeout tonight" if left <= 0 else "Fridge almost empty – shop soon"
	upcoming.append(_money_row("Groceries", grocery_note, "", PhoneTheme.INK, left < 3))
	for subscription in GameState.subscriptions:
		var info: Dictionary = Economy.SUBSCRIPTIONS[subscription]
		upcoming.append(_money_row(info["name"], "With the monthly bills", "%s/mo" % Economy.format(-info["amount"]), PhoneTheme.INK))
	_group(upcoming)

	var found := 0
	var ways := []
	for income_id in Economy.SIDE_INCOME:
		var income: Dictionary = Economy.SIDE_INCOME[income_id]
		if GameState.has_flag(income["flag"]):
			found += 1
			var earned: int = GameState.income_earned.get(income_id, 0)
			ways.append(_money_row(income["name"], "Earned %s so far" % Economy.format(earned) if earned > 0 else "Not tried yet",
					"", PhoneTheme.INK))
		else:
			ways.append(_money_row("???", income["hint"], "", PhoneTheme.MUTED))
	_section("Ways to earn · %d of %d found" % [found, Economy.SIDE_INCOME.size()])
	_group(ways)

	_section("Recent activity")
	if GameState.ledger.is_empty():
		_content.add_child(_label("No transactions yet.", PhoneTheme.SUBHEAD, PhoneTheme.MUTED, 400, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		var rows := []
		for i in range(GameState.ledger.size() - 1, maxi(GameState.ledger.size() - WALLET_LEDGER_ROWS, 0) - 1, -1):
			var entry: Dictionary = GameState.ledger[i]
			var amount: int = entry["amount"]
			rows.append(_money_row(entry["label"], "Day %d · %s" % [entry["day"], GameState.weekday_of(entry["day"])],
					("+" if amount > 0 else "") + Economy.format(amount), PhoneTheme.TILE["phone"].darkened(0.2) if amount > 0 else PhoneTheme.INK))
		_group(rows)
	_spacer(6)


## En rad i Wallet: namn och undertext till vänster, ett belopp till höger. warn
## färgar undertexten röd.
func _money_row(title: String, subtitle: String, amount: String, amount_color: Color, warn := false) -> Control:
	var row := Control.new()
	row.custom_minimum_size.y = 52
	var muted := title == "???"
	row.draw.connect(func() -> void:
		var left := float(PhoneTheme.SIDE)
		var right := row.size.x - left
		var amount_width := PhoneTheme.font(600).get_string_size(amount, HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.CALLOUT).x
		var width := right - left - amount_width - 10
		row.draw_string(PhoneTheme.font(600), Vector2(left, 23), _ellipsize(title, PhoneTheme.font(600), PhoneTheme.CALLOUT, width), HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.CALLOUT, PhoneTheme.MUTED if muted else PhoneTheme.INK)
		row.draw_string(PhoneTheme.font(400), Vector2(left, 41), _ellipsize(subtitle, PhoneTheme.font(400), PhoneTheme.FOOTNOTE, width), HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.FOOTNOTE, PhoneTheme.DANGER if warn else PhoneTheme.MUTED)
		if amount != "":
			row.draw_string(PhoneTheme.font(600), Vector2(0, 32), amount, HORIZONTAL_ALIGNMENT_RIGHT, right, PhoneTheme.CALLOUT, amount_color))
	return row


func _plural(count: int) -> String:
	return "" if count == 1 else "s"


# --- Journal ------------------------------------------------------------------

## Startade quests med flikar för pågående och avklarade.
func _journal() -> void:
	_header("Journal")
	_segmented([["active", "Active"], ["completed", "Completed"]], _journal_tab, func(tab: String) -> void:
		_journal_tab = tab
		_show("journal", false))
	var any := false
	for quest_id in GameState.quests:
		if GameState.quests[quest_id] != _journal_tab:
			continue
		any = true
		var quest: Dictionary = PhoneData.QUESTS[quest_id]
		var done := _journal_tab == "completed"
		var card := PanelContainer.new()
		var style := PhoneTheme.rounded(PhoneTheme.CARD, PhoneTheme.CARD_RADIUS, PhoneTheme.LINE, 1)
		style.set_content_margin_all(14)
		style.content_margin_left = 22
		style.content_margin_right = 40 if done else 14
		card.add_theme_stylebox_override("panel", style)
		var color: Color = PhoneTheme.TILE["phone"] if done else PhoneTheme.TILE["journal"]
		card.draw.connect(func() -> void:
			card.draw_style_box(PhoneTheme.rounded(color, 2), Rect2(8, 14, 4, card.size.y - 28))
			if done:
				card.draw_circle(Vector2(card.size.x - 22, 24), 9, color, true, -1.0, true)
				PhoneIcons.draw(card, "check", Rect2(card.size.x - 28, 18, 12, 12), Color.WHITE, 3.0))
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 4)
		column.add_child(_label(quest["title"], PhoneTheme.CALLOUT, PhoneTheme.INK, 600))
		column.add_child(_label(quest["description"], PhoneTheme.SUBHEAD, PhoneTheme.MUTED))
		card.add_child(column)
		_padded(card)
	if not any:
		var empty := Control.new()
		empty.custom_minimum_size.y = 120
		empty.draw.connect(func() -> void:
			PhoneIcons.draw(empty, "journal", Rect2(empty.size.x / 2 - 18, 30, 36, 36), Color(PhoneTheme.MUTED, 0.5))
			empty.draw_string(PhoneTheme.font(400), Vector2(0, 96), "Nothing here yet.", HORIZONTAL_ALIGNMENT_CENTER, empty.size.x, PhoneTheme.CALLOUT, PhoneTheme.MUTED))
		_content.add_child(empty)
	if _journal_tab == "active":
		_requests_section()


## Öppna förfrågningar, vilka som är skyldiga sysslor, och allas mätare (Requests).
func _requests_section() -> void:
	var open := []
	for character_id in GameState.requests:
		var t := Requests.find_type(GameState.requests[character_id]["type"])
		open.append(_money_row(GameState.character_name(character_id), t["label"], "", PhoneTheme.INK))
	for character_id in GameState.owed:
		if GameState.owed[character_id] > 0:
			open.append(_money_row(GameState.character_name(character_id), "Owes you %d chore%s" % [GameState.owed[character_id], _plural(GameState.owed[character_id])], "", PhoneTheme.INK))
	if not open.is_empty():
		_section("Requests & favors")
		_group(open)
	var rows := []
	for character_id in GameState.meters:
		if GameState.is_introduced(character_id):
			rows.append(_meter_row(character_id))
	_section("Moods")
	_group(rows)
	_spacer(6)


## En mätare: namn, vad den heter för personen, och en stapel med tröskeln markerad.
func _meter_row(character_id: String) -> Control:
	var value: float = GameState.meters[character_id]
	var threshold: float = Requests.meter_info(character_id).get("threshold", 100)
	var title := "You" if character_id == "mom" else GameState.character_name(character_id)
	var kind := "Desire" if Requests.is_desire(character_id) else "Wants something"
	var color: Color = PhoneTheme.TILE["phone"] if Requests.is_desire(character_id) else PhoneTheme.TILE["journal"]
	var row := Control.new()
	row.custom_minimum_size.y = 52
	row.draw.connect(func() -> void:
		var left := float(PhoneTheme.SIDE)
		var w := row.size.x - left * 2
		row.draw_string(PhoneTheme.font(600), Vector2(left, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.CALLOUT, PhoneTheme.INK)
		row.draw_string(PhoneTheme.font(400), Vector2(left, 22), "%s · %d" % [kind, roundi(value)], HORIZONTAL_ALIGNMENT_RIGHT, w, PhoneTheme.FOOTNOTE, PhoneTheme.MUTED)
		row.draw_style_box(PhoneTheme.rounded(PhoneTheme.LINE, 4), Rect2(left, 32, w, 8))
		if value > 0:
			row.draw_style_box(PhoneTheme.rounded(color, 4), Rect2(left, 32, maxf(8, w * value / 100.0), 8))
		row.draw_line(Vector2(left + w * threshold / 100.0, 29), Vector2(left + w * threshold / 100.0, 43), PhoneTheme.INK, 1.5))
	return row


# --- Settings -----------------------------------------------------------------

func _settings() -> void:
	_header("Settings")
	_group([
		_settings_row("Wallpaper", "image", PhoneTheme.TILE["memories"], func() -> void: _show("wallpaper"), PhoneData.wallpaper_name(_valid_wallpaper(GameState.phone_wallpapers["home"]))),
		_settings_row("Close Phone", "lock", PhoneTheme.TILE["settings"], close),
	], 56)
	_group([_settings_row("Quit Game", "", PhoneTheme.DANGER, func() -> void: get_tree().quit())])
	_content.add_child(_label("Saving comes later.", PhoneTheme.FOOTNOTE, PhoneTheme.MUTED, 400, HORIZONTAL_ALIGNMENT_CENTER))


## En inställningsrad: liten färgad ikon, namn, ett värde till höger och en pil. Utan
## ikon blir raden en röd varningsrad.
func _settings_row(title: String, glyph: String, color: Color, on_pressed: Callable, detail := "") -> Button:
	var button := _row_button(48)
	button.pressed.connect(on_pressed)
	button.draw.connect(func() -> void:
		var x := 16.0
		if glyph != "":
			button.draw_style_box(PhoneTheme.rounded(color, 8), Rect2(14, 9, 30, 30))
			PhoneIcons.draw(button, glyph, Rect2(19, 14, 20, 20), Color.WHITE)
			x = 56.0
		button.draw_string(PhoneTheme.font(400), Vector2(x, 30), title, HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.BODY, PhoneTheme.INK if glyph != "" else PhoneTheme.DANGER)
		if glyph != "":
			button.draw_string(PhoneTheme.font(400), Vector2(0, 30), detail, HORIZONTAL_ALIGNMENT_RIGHT, button.size.x - 34, PhoneTheme.BODY, PhoneTheme.MUTED)
			PhoneIcons.draw(button, "chevron", Rect2(button.size.x - 24, 17, 14, 14), Color(PhoneTheme.MUTED, 0.6), 2.4))
	return button


## Bakgrunder: lås- och hemskärmen bredvid varandra (klick väljer vilken som ändras)
## och under dem alla bakgrunder man kan välja: de färdiga och bilderna bland minnena
## (de man inte har hittat än är låsta).
func _wallpaper_page() -> void:
	_header("Wallpaper", "settings")
	var previews := HBoxContainer.new()
	previews.alignment = BoxContainer.ALIGNMENT_CENTER
	previews.add_theme_constant_override("separation", 22)
	for slot in PhoneData.WALLPAPER_SLOTS:
		previews.add_child(_slot_preview(slot))
	_padded(previews)
	_section("Choose for %s" % PhoneData.WALLPAPER_SLOTS[_wallpaper_slot])
	var options: Array = PhoneData.WALLPAPER_PRESETS.keys().map(func(preset_id: String) -> String: return "preset:" + preset_id)
	for memory_id in PhoneData.MEMORIES:
		if PhoneData.memory_image(memory_id) != "":
			options.append("memory:" + memory_id)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	var tile_width := floorf((PhoneTheme.SCREEN_SIZE.x - PhoneTheme.SIDE * 2 - 10) / 3)
	for value in options:
		grid.add_child(_wallpaper_option(value, tile_width))
	_padded(grid)
	_spacer(6)


## En liten telefonskärm som visar platsens bakgrund, med namn och vald bakgrund under.
func _slot_preview(slot: String) -> Control:
	var value := _valid_wallpaper(GameState.phone_wallpapers[slot])
	var selected := slot == _wallpaper_slot
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	var button := Button.new()
	button.custom_minimum_size = Vector2(104, 215)
	button.focus_mode = Control.FOCUS_NONE
	PhoneTheme.style_button(button, PhoneTheme.INK, 16)
	PhoneTheme.round_corners(button, 16)
	button.draw.connect(func() -> void:
		var rect := Rect2(Vector2.ZERO, button.size)
		_draw_wallpaper(button, value, rect, true)
		var w := rect.size.x
		if slot == "lock":
			_shadow_string(button, PhoneTheme.font(600), Vector2(0, 34), GameState.get_weekday(), w, PhoneTheme.CAPTION - 2, Color(1, 1, 1, 0.9))
			_shadow_string(button, PhoneTheme.font(700), Vector2(0, 56), GameState.PERIOD_NAMES[GameState.get_time_of_day()], w, PhoneTheme.HEADLINE - 1, Color.WHITE)
		else:
			for i in GRID_APPS.size():
				PhoneIcons.draw_tile(button, GRID_APPS[i], Rect2(10 + i * 22, 40, 17, 17))
			button.draw_style_box(PhoneTheme.rounded(Color(1, 1, 1, 0.26), 10), Rect2(5, rect.size.y - 34, w - 10, 26))
			for i in DOCK_APPS.size():
				PhoneIcons.draw_tile(button, DOCK_APPS[i], Rect2(w / 2 - 30 + i * 22, rect.size.y - 29, 16, 16))
		if selected:
			button.draw_style_box(PhoneTheme.rounded(Color(0, 0, 0, 0), 16, PhoneTheme.ACCENT, 3), rect))
	button.pressed.connect(func() -> void:
		_wallpaper_slot = slot
		_show("wallpaper", false))
	column.add_child(button)
	column.add_child(_label(PhoneData.WALLPAPER_SLOTS[slot], PhoneTheme.SUBHEAD, PhoneTheme.ACCENT if selected else PhoneTheme.INK, 600, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_label(PhoneData.wallpaper_name(value), PhoneTheme.CAPTION, PhoneTheme.MUTED, 400, HORIZONTAL_ALIGNMENT_CENTER))
	return column


## En bakgrund att välja: bilden med namnet nederst och en bock om den är vald.
func _wallpaper_option(value: String, width: float) -> Button:
	var memory_id := value.trim_prefix("memory:") if value.begins_with("memory:") else ""
	var locked := memory_id != "" and not GameState.memories.has(memory_id)
	var chosen: bool = GameState.phone_wallpapers[_wallpaper_slot] == value
	var tile := Button.new()
	tile.custom_minimum_size = Vector2(width, 132)
	tile.focus_mode = Control.FOCUS_NONE
	PhoneTheme.style_button(tile, Color(PhoneTheme.INK, 0.07) if locked else PhoneTheme.INK, 12)
	PhoneTheme.round_corners(tile, 12)
	tile.disabled = locked
	tile.draw.connect(func() -> void:
		var rect := Rect2(Vector2.ZERO, tile.size)
		if locked:
			PhoneIcons.draw(tile, "lock", Rect2(rect.get_center() - Vector2(11, 11), Vector2(22, 22)), Color(PhoneTheme.MUTED, 0.6))
			return
		_draw_wallpaper(tile, value, rect)
		_vertical_gradient(tile, Rect2(0, rect.size.y - 36, rect.size.x, 36), Color(0, 0, 0, 0), Color(0, 0, 0, 0.45))
		tile.draw_string(PhoneTheme.font(600), Vector2(8, rect.size.y - 10), _ellipsize(PhoneData.wallpaper_name(value), PhoneTheme.font(600), PhoneTheme.CAPTION, rect.size.x - 16), HORIZONTAL_ALIGNMENT_LEFT, -1, PhoneTheme.CAPTION, Color.WHITE)
		if chosen:
			tile.draw_style_box(PhoneTheme.rounded(Color(0, 0, 0, 0), 12, PhoneTheme.ACCENT, 3), rect)
			tile.draw_circle(Vector2(rect.size.x - 15, 15), 9, PhoneTheme.ACCENT, true, -1.0, true)
			PhoneIcons.draw(tile, "check", Rect2(rect.size.x - 21, 9, 12, 12), Color.WHITE, 3.0))
	tile.pressed.connect(func() -> void:
		GameState.set_wallpaper(_wallpaper_slot, value)
		_toast("Set as %s" % PhoneData.WALLPAPER_SLOTS[_wallpaper_slot]))
	return tile
