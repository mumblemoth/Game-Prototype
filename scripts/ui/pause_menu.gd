extends CanvasLayer
## Pausmenyn i Persona 4-anda (Esc eller MENU uppe till höger). Spelet står still bakom
## ett genomskinligt svart lager med ett gult snedband; valen står snett under varandra
## till vänster och sidan som är öppen till höger:
##   översikten – dag, tidszon, plats, pengar och mätarna, med mamman i dagens kläder
##   Status     – mätarna, Attractiveness, egenskaperna och relationerna (bonds)
##   Items      – saker hon har (Economy.ITEMS), har köpt (PURCHASES) och nya utseenden (LOOKS)
##   Memories   – minnena i ett rutnät; scener kan upplevas igen och bilder visas stort
##   Settings   – samma inställningar som på titelskärmen
## Title Screen och Quit frågar först. Esc går ett steg tillbaka. Läggs till av house.gd.

const ITEMS := [
	["resume", "Resume"], ["status", "Status"], ["items", "Items"], ["memories", "Memories"],
	["settings", "Settings"], ["title", "Title Screen"], ["quit", "Quit Game"],
]
const MENU_ORIGIN := Vector2(56, 118)
const MENU_STEP := Vector2(8, 62)
const MENU_SIZE := Vector2(310, 52)
## Var sidorna står (skärmkoordinater).
const PAGE := Rect2(452, 34, 800, 640)
const CARD_SIZE := Vector2(184, 140)
const NO_SAVE := "There's no saving yet, so this playthrough will be lost."

var is_open := false
var _root: Control
var _backdrop: KitBackdrop
var _buttons := {}
var _page_holder: Control
var _page := ""
## Bekräftelserutan eller bildvisaren, om någon är öppen.
var _overlay: Control
var _closing := false
var _memory := ""
var _memories_tab := "all"
var _items_tab := "items"
## Minnet som spelas igen härifrån (dit kommer man tillbaka efteråt).
var _relived := ""
var _textures := {}


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiKit.theme()
	add_child(_root)
	_backdrop = KitBackdrop.new(false, 0.06, 250.0)
	_root.add_child(_backdrop)
	_page_holder = Control.new()
	_page_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_page_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_page_holder)
	for i in ITEMS.size():
		var id: String = ITEMS[i][0]
		var button := KitButton.new(ITEMS[i][1])
		button.position = MENU_ORIGIN + MENU_STEP * i
		button.size = MENU_SIZE
		button.pressed.connect(_choose.bind(id))
		_root.add_child(button)
		_buttons[id] = button
	var hints := UiKit.key_hints([["↑↓", "Select"], ["Enter", "Confirm"], ["Esc", "Back"]])
	hints.position = Vector2(56, 684)
	_root.add_child(hints)
	GameState.memory_replay_finished.connect(func(memory_id: String) -> void:
		if memory_id != _relived:
			return
		_relived = ""
		_memory = memory_id
		open("memories"))


func open(page := "home") -> void:
	if is_open or GameState.playing_scene != "" or GameState.replaying_memory != "":
		return
	is_open = true
	_closing = false
	get_tree().paused = true
	visible = true
	_root.modulate.a = 1.0
	_backdrop.sweep_in()
	var i := 0
	for id in _buttons:
		_buttons[id].appear(i * UiKit.STAGGER)
		i += 1
	_show(page)
	(_buttons[page] if _buttons.has(page) else _buttons["resume"]).grab_focus()


## Stänger menyn och släpper pausen; then anropas när den är borta.
func close(then := Callable()) -> void:
	if not is_open or _closing:
		return
	_closing = true
	_close_overlay()
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, UiKit.t(UiKit.FAST))
	tween.tween_callback(func() -> void:
		visible = false
		is_open = false
		_closing = false
		get_tree().paused = false
		for child in _page_holder.get_children():
			child.queue_free()
		if then.is_valid():
			then.call())


func _unhandled_input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()


## Esc: stänger rutan som är öppen, går från ett minne till rutnätet, från en sida till
## översikten och från översikten tillbaka till spelet.
func _back() -> void:
	if _overlay != null:
		_close_overlay()
		_buttons.get(_page, _buttons["resume"]).grab_focus()
	elif _page == "memories" and _memory != "":
		_memory = ""
		_show("memories")
	elif _page != "home":
		var from := _page
		_show("home")
		_buttons[from].grab_focus()
	else:
		close()


func _choose(id: String) -> void:
	match id:
		"resume":
			close()
		"title":
			_confirm("Return to the title screen?", NO_SAVE, "Yes", func() -> void:
				UiTransition.wipe(self, func() -> void:
					get_tree().paused = false
					get_tree().change_scene_to_file("res://scenes/main_menu.tscn")))
		"quit":
			_confirm("Quit the game?", NO_SAVE, "Quit", func() -> void: get_tree().quit())
		_:
			if id == "memories":
				_memory = ""
			_show(id)


func _confirm(question: String, detail: String, yes_text: String, on_yes: Callable) -> void:
	_close_overlay()
	_overlay = UiKit.confirm(question, detail, yes_text, on_yes, _back)
	_root.add_child(_overlay)


func _close_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null


func _show(page: String) -> void:
	_page = page
	for child in _page_holder.get_children():
		child.queue_free()
	for id in _buttons:
		_buttons[id].selected = id == page
	var content := Control.new()
	content.position = PAGE.position
	content.size = PAGE.size
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page_holder.add_child(content)
	match page:
		"home":
			_home(content)
		"status":
			_status(content)
		"items":
			_items(content)
		"memories":
			if _memory != "":
				_memory_detail(content)
			else:
				_memories(content)
		"settings":
			_settings(content)
	UiKit.enter(content, 0.0, Vector2(70, 0))


func _place(parent: Control, child: Control, at: Vector2, width := 0.0) -> Control:
	child.position = at
	if width > 0.0:
		child.custom_minimum_size.x = width
		child.size.x = width
	parent.add_child(child)
	return child


## En liten rubrik: svart text på en gul sned platta.
func _section(text: String) -> Control:
	var control := Control.new()
	control.custom_minimum_size.y = 38
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.draw.connect(func() -> void:
		var font := UiKit.display_font()
		var width := font.get_string_size(text.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.HEADING - 4).x
		UiKit.draw_slant(control, Rect2(0, 2, width + 40, 28), UiKit.YELLOW)
		control.draw_string(font, Vector2(16, 2 + UiKit.baseline(font, UiKit.HEADING - 4, 28)), text.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.HEADING - 4, UiKit.INK))
	return control


func _column(separation := 8) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", separation)
	return column


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path)
	return _textures[path]


# --- Översikten ---------------------------------------------------------------------

## Dagen, platsen och mätarna, med mamman i dagens kläder till höger.
func _home(content: Control) -> void:
	var portrait_box := Rect2(470, -34, 360, 740)
	var texture := AppearanceData.preview_image(GameState.appearance)
	# En hård svart siluett bakom bilden, som Personas porträtt.
	for part in [[Vector2(16, 10), UiKit.INK], [Vector2.ZERO, Color.WHITE]]:
		var rect := TextureRect.new()
		rect.texture = texture
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.position = portrait_box.position + part[0]
		rect.size = portrait_box.size
		rect.self_modulate = part[1]
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(rect)
	var period: String = GameState.PERIOD_NAMES[GameState.get_time_of_day()] if not GameState.is_day_over() else "Night"
	var room: Dictionary = GameState.ROOMS[GameState.current_room]
	var card := Control.new()
	card.size = Vector2(460, 220)
	card.position = Vector2(0, 30)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.draw.connect(func() -> void:
		var font := UiKit.display_font()
		var body := UiKit.body_font(true)
		UiKit.draw_display(card, Vector2(0, 66), period.to_upper(), UiKit.HERO - 16)
		var date := "%s · Day %d" % [GameState.get_weekday(), GameState.day]
		UiKit.draw_slant(card, Rect2(12, 94, 380, 40), UiKit.PAPER)
		card.draw_string(font, Vector2(34, 94 + UiKit.baseline(font, UiKit.HEADING + 2, 40)), date.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.HEADING + 2, UiKit.INK)
		UiKit.draw_slant(card, Rect2(24, 140, 360, 32), UiKit.YELLOW)
		card.draw_string(body, Vector2(44, 140 + UiKit.baseline(body, UiKit.BODY, 32)), "%s  —  %s" % [room["name"], room["floor"]], HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.BODY, UiKit.INK)
		UiKit.draw_slant(card, Rect2(36, 178, 200, 32), UiKit.INK_2)
		card.draw_string(font, Vector2(56, 178 + UiKit.baseline(font, UiKit.HEADING, 32)), Economy.format(GameState.money), HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.HEADING, UiKit.RED if GameState.money < 0 else UiKit.PAPER))
	content.add_child(card)
	var column := _column(6)
	_place(content, column, Vector2(0, 290), 430)
	column.add_child(_section("Balance"))
	for key in GameState.STAT_NAMES:
		column.add_child(_balance_row(key))
	var money_note := UiKit.label(_money_outlook(), UiKit.SMALL, Color(UiKit.PAPER, 0.75))
	column.add_child(money_note)


## Lönen eller räkningarna, det som kommer först.
func _money_outlook() -> String:
	var to_payday := GameState.days_until_payday()
	var to_bills := GameState.days_until_bills()
	if to_payday <= to_bills:
		return "Payday is today" if to_payday <= 0 else "Payday in %d day%s" % [to_payday, "" if to_payday == 1 else "s"]
	return "Bills (%s) due in %d day%s" % [Economy.format(Economy.monthly_bills_total()), to_bills, "" if to_bills == 1 else "s"]


## En av mammans mätare: namn, värde och en sned stapel med streck.
func _balance_row(key: String) -> Control:
	var row := Control.new()
	row.custom_minimum_size.y = 54
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.draw.connect(func() -> void:
		var font := UiKit.display_font()
		var value: int = GameState.stats[key]
		var color: Color = UiKit.METERS[key]
		row.draw_string(font, Vector2(4, 22), GameState.STAT_NAMES[key].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.HEADING - 2, UiKit.PAPER)
		row.draw_string(font, Vector2(0, 22), str(value), HORIZONTAL_ALIGNMENT_RIGHT, row.size.x - 8, UiKit.HEADING, color)
		UiKit.draw_meter(row, Rect2(4, 30, row.size.x - 12, 16), float(value) / GameState.STAT_MAX, color, true))
	return row


# --- Status -------------------------------------------------------------------------

func _status(content: Control) -> void:
	_place(content, UiKit.header("Status", "Day %d" % GameState.day), Vector2.ZERO, 800)
	var left := _column(6)
	_place(content, left, Vector2(0, 104), 370)
	left.add_child(_section("Balance"))
	for key in GameState.STAT_NAMES:
		left.add_child(_balance_row(key))
	left.add_child(_spacer(10))
	left.add_child(_section("Attractiveness"))
	left.add_child(_attractiveness_row())
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.position = Vector2(410, 104)
	scroll.size = Vector2(390, 530)
	content.add_child(scroll)
	var right := _column(6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(right)
	right.add_child(_section("Skills"))
	for stat in SocialStats.STATS:
		right.add_child(_skill_row(stat))
	right.add_child(_spacer(6))
	right.add_child(_section("Bonds"))
	for character_id in GameState.links:
		right.add_child(_bond_row(character_id))


func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


## Betyget stort, namnet, fem prickar och vad nästa nivå låser upp.
func _attractiveness_row() -> Control:
	var rating := GameState.attractiveness()
	var tier := GameState.attractiveness_tier()
	var row := Control.new()
	row.custom_minimum_size.y = 130
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var next := ""
	for needed in SocialStats.ATTRACTIVENESS_UNLOCKS:
		if needed > tier:
			next = "At %d: %s" % [needed, SocialStats.ATTRACTIVENESS_UNLOCKS[needed]]
			break
	row.draw.connect(func() -> void:
		UiKit.draw_display(row, Vector2(2, 62), "%.1f" % rating, UiKit.DISPLAY + 6)
		row.draw_string(UiKit.display_font(), Vector2(130, 34), SocialStats.attractiveness_title(rating).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.HEADING + 2, UiKit.PAPER)
		UiKit.draw_pips(row, Vector2(132, 46), 5, tier, UiKit.YELLOW, Vector2(30, 14), 6)
		if next != "":
			row.draw_multiline_string(UiKit.body_font(), Vector2(4, 96), next, HORIZONTAL_ALIGNMENT_LEFT, row.size.x - 8, UiKit.SMALL, 2, Color(UiKit.PAPER, 0.7)))
	return row


## En egenskap: namn och nivå, fem prickar i dess färg och XP mot nästa nivå.
func _skill_row(stat: String) -> Control:
	var data: Dictionary = SocialStats.STATS[stat]
	var level := GameState.social_level(stat)
	var row := Control.new()
	row.custom_minimum_size.y = 78
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.draw.connect(func() -> void:
		var font := UiKit.display_font()
		var body := UiKit.body_font(true)
		var w := row.size.x - 12
		row.draw_string(font, Vector2(4, 24), data["name"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.HEADING, UiKit.PAPER)
		row.draw_string(font, Vector2(0, 24), "LV %d" % level, HORIZONTAL_ALIGNMENT_RIGHT, w, UiKit.HEADING, data["color"])
		row.draw_string(body, Vector2(4, 46), SocialStats.level_name(stat, level), HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.SMALL, Color(UiKit.PAPER, 0.75))
		UiKit.draw_pips(row, Vector2(w - 5 * 26 + 6, 34), 5, level, data["color"], Vector2(22, 12))
		UiKit.draw_meter(row, Rect2(4, 58, w - 100, 8), GameState.social_progress(stat), data["color"])
		var xp := "MAX" if level >= SocialStats.MAX_LEVEL else "%d / %d XP" % [GameState.social[stat], SocialStats.LEVEL_XP[level]]
		row.draw_string(body, Vector2(0, 68), xp, HORIZONTAL_ALIGNMENT_RIGHT, w, UiKit.TINY, Color(UiKit.PAPER, 0.6)))
	return row


## En relation: namnet, ranken, tio prickar och vägen till nästa rank.
func _bond_row(character_id: String) -> Control:
	var link: Dictionary = GameState.links[character_id]
	var color: Color = GameState.CHARACTERS[character_id]["color"].lightened(0.25)
	var row := Control.new()
	row.custom_minimum_size.y = 62
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.draw.connect(func() -> void:
		var font := UiKit.display_font()
		var w := row.size.x - 12
		row.draw_string(font, Vector2(4, 22), GameState.character_name(character_id).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.HEADING - 2, UiKit.PAPER)
		row.draw_string(font, Vector2(0, 22), "RANK %d" % link["rank"], HORIZONTAL_ALIGNMENT_RIGHT, w, UiKit.HEADING - 4, UiKit.YELLOW)
		UiKit.draw_pips(row, Vector2(4, 32), GameState.LINK_MAX_RANK, link["rank"], color, Vector2(16, 10), 3)
		UiKit.draw_meter(row, Rect2(4, 50, w - 4, 5), GameState.link_progress(character_id), UiKit.YELLOW))
	return row


# --- Items --------------------------------------------------------------------------

const ITEM_TABS := [["items", "Items"], ["purchases", "Purchases"], ["wardrobe", "Wardrobe"]]
const ITEM_EMPTY := {
	"items": "Nothing to carry yet. Paintings from the easel end up here.",
	"purchases": "Nothing bought yet. Bigger purchases show up here.",
	"wardrobe": "No new looks yet. The boutique and the grocery store sell more.",
}


func _items(content: Control) -> void:
	_place(content, UiKit.header("Items", Economy.format(GameState.money)), Vector2.ZERO, 800)
	_place(content, _tabs(ITEM_TABS, _items_tab, func(tab: String) -> void:
		_items_tab = tab
		_show("items")), Vector2(0, 96))
	var entries := _item_entries(_items_tab)
	var detail := UiKit.card(24)
	detail.position = Vector2(424, 152)
	detail.custom_minimum_size = Vector2(376, 220)
	var detail_column := _column(10)
	detail.add_child(detail_column)
	if entries.is_empty():
		_place(content, UiKit.label(ITEM_EMPTY[_items_tab], UiKit.BODY, Color(UiKit.PAPER, 0.75), false, 400), Vector2(4, 160))
		return
	content.add_child(detail)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.position = Vector2(0, 152)
	scroll.size = Vector2(410, 480)
	content.add_child(scroll)
	var list := _column(8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for entry in entries:
		var button := KitButton.new(entry["name"], entry["note"], "menu", UiKit.HEADING - 2)
		button.focus_entered.connect(_item_detail.bind(detail_column, entry))
		list.add_child(button)
	_item_detail(detail_column, entries[0])


## Raderna i en flik: {name, note, kind, desc, facts}.
func _item_entries(tab: String) -> Array:
	var entries := []
	match tab:
		"items":
			for item in Economy.ITEMS:
				var count: int = GameState.inventory.get(item, 0)
				if count > 0:
					var info: Dictionary = Economy.ITEMS[item]
					entries.append({"name": info["name"], "note": "×%d" % count, "kind": "Item", "desc": info.get("desc", ""),
						"facts": ["Carrying %d of %d" % [count, info["max"]]]})
		"purchases":
			for id in GameState.owned:
				if not Economy.PURCHASES.has(id):
					continue
				var info: Dictionary = Economy.PURCHASES[id]
				var facts := ["Paid %s" % Economy.format(info["price"])]
				for stat in info.get("decay", {}):
					facts.append("%s slips %d less each night" % [GameState.STAT_NAMES[stat], info["decay"][stat]])
				for stat in info.get("effects", {}):
					facts.append("%s +%d when bought" % [GameState.STAT_NAMES[stat], info["effects"][stat]])
				if info.has("link"):
					facts.append("%s ♥ %+d" % [GameState.character_name(info["link"]), info["link_points"]])
				entries.append({"name": info.get("name", info["label"]), "note": "", "kind": "Purchase", "desc": info["text"], "facts": facts})
		"wardrobe":
			for key in GameState.owned:
				if not Economy.LOOKS.has(key):
					continue
				var parts: PackedStringArray = key.split(":")
				var option: Dictionary = AppearanceData.OPTIONS[parts[0]][parts[1]]
				var wearing: bool = GameState.appearance.get(parts[0], "") == parts[1]
				entries.append({"name": option["name"], "note": "Wearing" if wearing else "",
					"kind": AppearanceData.CATEGORIES[parts[0]]["title"], "desc": option["desc"],
					"facts": ["Paid %s" % Economy.format(Economy.LOOKS[key]["price"])]})
	return entries


func _item_detail(column: VBoxContainer, entry: Dictionary) -> void:
	for child in column.get_children():
		child.queue_free()
	column.add_child(UiKit.label(entry["kind"].to_upper(), UiKit.SMALL, UiKit.YELLOW, true))
	column.add_child(UiKit.display(entry["name"], UiKit.TITLE - 6, UiKit.PAPER, Color(0, 0, 0, 0)))
	if entry["desc"] != "":
		column.add_child(UiKit.label(entry["desc"], UiKit.BODY, Color(UiKit.PAPER, 0.85), false, 330))
	for fact in entry["facts"]:
		column.add_child(UiKit.label("▸ " + fact, UiKit.SMALL, UiKit.PAPER, true, 330))


## Flikar i rad; den valda är gul.
func _tabs(options: Array, current: String, on_select: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for option in options:
		var tab := KitButton.new(option[1], "", "tab")
		tab.selected = option[0] == current
		tab.pressed.connect(func() -> void:
			if option[0] != current:
				on_select.call(option[0]))
		row.add_child(tab)
	return row


# --- Memories -----------------------------------------------------------------------

func _memories(content: Control) -> void:
	_place(content, UiKit.header("Memories", "%d / %d collected" % [GameState.memories.size(), PhoneData.MEMORIES.size()]), Vector2.ZERO, 800)
	_place(content, _tabs([["all", "All"], ["scene", "Scenes"], ["picture", "Pictures"]], _memories_tab, func(tab: String) -> void:
		_memories_tab = tab
		_show("memories")), Vector2(0, 96))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.position = Vector2(0, 150)
	scroll.size = Vector2(800, 486)
	content.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)
	for memory_id in PhoneData.MEMORIES:
		if _memories_tab == "all" or PhoneData.MEMORIES[memory_id]["type"] == _memories_tab:
			grid.add_child(_memory_card(memory_id))


## Ett minne som ett inramat kort med hård skugga: bilden, namnet på en sned platta,
## NEW om det inte är sett och en uppspelningsknapp på scener. Låsta minnen är mörka
## med ett frågetecken.
func _memory_card(memory_id: String) -> Control:
	var memory: Dictionary = PhoneData.MEMORIES[memory_id]
	var collected: bool = GameState.memories.has(memory_id)
	var holder := Control.new()
	holder.custom_minimum_size = CARD_SIZE + Vector2(8, 8)
	var button := Button.new()
	button.size = CARD_SIZE
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.disabled = not collected
	holder.add_child(button)
	holder.draw.connect(func() -> void:
		var lit := button.has_focus()
		holder.draw_rect(Rect2(Vector2(8, 8), CARD_SIZE), UiKit.RED if lit else Color(0, 0, 0, 0.55)))
	if collected:
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_child(_memory_thumb(memory_id))
		button.pressed.connect(func() -> void:
			_memory = memory_id
			_show("memories"))
	var frame := Control.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(frame)
	frame.draw.connect(func() -> void:
		var s := frame.size
		var font := UiKit.display_font()
		if not collected:
			frame.draw_rect(Rect2(Vector2.ZERO, s), UiKit.INK_2)
			frame.draw_string(font, Vector2(0, s.y / 2 + 20), "?", HORIZONTAL_ALIGNMENT_CENTER, s.x, UiKit.DISPLAY, Color(UiKit.PAPER, 0.18))
			frame.draw_string(UiKit.body_font(true), Vector2(0, s.y - 14), "LOCKED", HORIZONTAL_ALIGNMENT_CENTER, s.x, UiKit.TINY, UiKit.MUTED)
		else:
			UiKit.draw_slant(frame, Rect2(-12, s.y - 34, s.x * 0.92, 28), Color(UiKit.INK, 0.92))
			frame.draw_string(font, Vector2(8, s.y - 34 + UiKit.baseline(font, UiKit.SMALL + 1, 28)), memory["title"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, s.x * 0.92 - 24, UiKit.SMALL + 1, UiKit.PAPER)
			if not GameState.memories[memory_id]["seen"]:
				UiKit.draw_slant(frame, Rect2(s.x - 62, 8, 54, 22), UiKit.YELLOW)
				frame.draw_string(font, Vector2(s.x - 52, 8 + UiKit.baseline(font, UiKit.TINY + 2, 22)), "NEW", HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.TINY + 2, UiKit.INK)
		frame.draw_rect(Rect2(Vector2(2, 2), s - Vector2(4, 4)), UiKit.YELLOW if button.has_focus() else Color(UiKit.PAPER, 0.85 if collected else 0.2), false, 4.0))
	# Kortet lyfter och ramen blir gul när det har fokus (mus eller tangenter).
	var light := func(lit: bool) -> void:
		holder.queue_redraw()
		frame.queue_redraw()
		button.create_tween().tween_property(button, "position", UiKit.travel(Vector2(-3, -3)) if lit else Vector2.ZERO, UiKit.t(UiKit.FAST))
	button.mouse_entered.connect(func() -> void:
		if collected:
			button.grab_focus())
	button.focus_entered.connect(light.bind(true))
	button.focus_exited.connect(light.bind(false))
	return holder


## Bilden för ett minne som fyller sin förälder. Scener utan bild får ett kort i
## tidszonens färg med sol eller måne; scener har en uppspelningsknapp.
func _memory_thumb(memory_id: String) -> Control:
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
			thumb.draw_rect(Rect2(Vector2.ZERO, s), UiKit.INK_2 if night else UiKit.YELLOW_DARK)
			var x := -s.y
			while x < s.x:
				thumb.draw_line(Vector2(x, s.y), Vector2(x + s.y, 0), Color(1, 1, 1, 0.06), 8.0)
				x += 24
			thumb.draw_circle(Vector2(26, 26), 12, UiKit.PAPER if night else UiKit.YELLOW, true, -1.0, true)
		var center := s / 2 - Vector2(0, 10)
		var radius := minf(s.x, s.y) * 0.16
		thumb.draw_circle(center, radius, Color(UiKit.INK, 0.7), true, -1.0, true)
		thumb.draw_colored_polygon(PackedVector2Array([
			center + Vector2(-radius * 0.35, -radius * 0.5), center + Vector2(radius * 0.55, 0), center + Vector2(-radius * 0.35, radius * 0.5)]), UiKit.YELLOW))
	return thumb


## Ett minne: stor bild, vad det är, varifrån, när och var, och knappar som spelar
## scenen igen eller visar bilden över hela skärmen.
func _memory_detail(content: Control) -> void:
	var memory_id := _memory
	var memory: Dictionary = PhoneData.MEMORIES[memory_id]
	var record: Dictionary = GameState.memories[memory_id]
	var is_scene: bool = memory["type"] == "scene"
	GameState.mark_memory_seen(memory_id)
	_place(content, UiKit.header(memory["title"], "Scene" if is_scene else "Picture"), Vector2.ZERO, 800)
	var picture := Control.new()
	picture.position = Vector2(0, 110)
	picture.size = Vector2(480, 380)
	picture.clip_contents = true
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow := ColorRect.new()
	shadow.color = UiKit.RED
	shadow.position = Vector2(10, 120)
	shadow.size = picture.size
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(shadow)
	content.add_child(picture)
	picture.add_child(_memory_thumb(memory_id))
	var frame := Control.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.draw.connect(func() -> void: frame.draw_rect(Rect2(Vector2(2, 2), frame.size - Vector2(4, 4)), UiKit.PAPER, false, 4.0))
	picture.add_child(frame)
	var info := _column(4)
	_place(content, info, Vector2(520, 110), 300)
	var source: String = record["source"] if record["source"] != "" else memory.get("source", "")
	var rows := []
	if source != "":
		rows.append(["From", source])
	rows.append(["When", "Day %d · %s %s" % [record["day"], GameState.weekday_of(record["day"]), GameState.PERIOD_NAMES[record["period"]]]])
	if not is_scene:
		rows.append(["Where", GameState.ROOMS[record["room"]]["name"]])
	for row in rows:
		info.add_child(UiKit.label(row[0].to_upper(), UiKit.SMALL, UiKit.YELLOW, true))
		info.add_child(UiKit.label(row[1], UiKit.BODY, UiKit.PAPER, false, 300))
		info.add_child(_spacer(8))
	var actions := _column(12)
	_place(content, actions, Vector2(520, 390), 300)
	var main: KitButton
	if is_scene:
		main = KitButton.new("Relive", "", "action")
		main.pressed.connect(func() -> void:
			_relived = memory_id
			close(func() -> void: GameState.replay_memory(memory_id)))
	else:
		main = KitButton.new("View Full Screen", "", "action")
		main.pressed.connect(func() -> void: _view_image(_texture(memory["image"]), memory["title"], source))
	actions.add_child(main)
	var back := KitButton.new("Back", "Esc", "tab")
	back.pressed.connect(_back)
	actions.add_child(back)
	main.grab_focus.call_deferred()


## Bilden över hela skärmen med namn och ursprung; klick eller Esc stänger.
func _view_image(texture: Texture2D, title: String, source: String) -> void:
	_close_overlay()
	var viewer := ColorRect.new()
	viewer.color = Color(UiKit.INK, 0.94)
	viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewer.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_back())
	var image := TextureRect.new()
	image.texture = texture
	image.set_anchors_preset(Control.PRESET_FULL_RECT)
	image.offset_top = 24
	image.offset_bottom = -72
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewer.add_child(image)
	var caption := UiKit.display(title if source == "" else "%s  ·  %s" % [title, source], UiKit.HEADING, UiKit.YELLOW, Color(0, 0, 0, 0))
	caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -60
	caption.offset_bottom = -20
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	viewer.add_child(caption)
	_overlay = viewer
	_root.add_child(viewer)
	viewer.modulate.a = 0.0
	viewer.create_tween().tween_property(viewer, "modulate:a", 1.0, UiKit.t(UiKit.FAST))


# --- Settings -----------------------------------------------------------------------

func _settings(content: Control) -> void:
	_place(content, UiKit.header("Settings"), Vector2.ZERO, 800)
	_place(content, UiKit.settings_list(), Vector2(0, 110), 440)
