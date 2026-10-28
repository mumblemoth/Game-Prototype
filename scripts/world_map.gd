extends CanvasLayer
## Kartan över grannskapet. Den öppnas när man lämnar huset (eller via "Neighborhood
## Map" ute på en plats) och visar platserna i Locations som klickbara nålar och hemmet.
## Nålen under musen lyfts upp och får ett kort med namn, beskrivning och om platsen är
## öppen eller varför den är stängd. Klick på en öppen plats tonar ut, reser dit
## (GameState.travel_to_location) och tonar in. Klick på hemmet åker hem.
## M och kartknappen nere till höger (house.gd) öppnar och stänger den också. Om kartan
## är öppen står i GameState.map_open; stänger något annat den där (dagens slut) stängs
## den här också.
##
## Kartbilden är en platshållare ritad i kod (gräs, vägar, kvarter, damm och träd).
## Finns res://Assets/map/neighborhood.png (eller .webp/.jpg) visas den i stället, och
## nålarna placeras efter `map_pos` (andelar av bilden) i Locations.

signal closed

const MAP_RECT := Rect2(150, 70, 980, 560)
const ART_PATHS := ["res://Assets/map/neighborhood.png", "res://Assets/map/neighborhood.webp", "res://Assets/map/neighborhood.jpg"]
const PIN_RADIUS := 30.0
const INK := Color(0.2, 0.17, 0.15)
const GRASS := Color(0.68, 0.8, 0.55)
const ROAD := Color(0.86, 0.83, 0.78)
const BLOCK := Color(0.93, 0.88, 0.8)
const HOME_COLOR := Color(0.92, 0.45, 0.5)
const LOCKED := Color(0.62, 0.62, 0.64)

var is_open := false
var _map: Control
var _card: PanelContainer
var _card_title: Label
var _card_text: Label
var _card_status: Label
var _fade: ColorRect
var _hover := ""
var _hover_scale := {}
var _art: Texture2D
var _traveling := false
var _shake := {}


func _ready() -> void:
	layer = 5
	visible = false
	for path in ART_PATHS:
		if ResourceLoader.exists(path):
			_art = load(path)
			break
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.05, 0.08, 0.65)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Klick utanför kartan stänger den, som telefonen (kartknappen ligger under skuggan).
	shade.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close_map())
	add_child(shade)
	var frame := Control.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.draw.connect(func() -> void:
		frame.draw_rect(Rect2(MAP_RECT.position + UiKit.SHADOW, MAP_RECT.size), UiKit.RED)
		frame.draw_rect(MAP_RECT.grow(3), UiKit.INK))
	add_child(frame)
	_map = Control.new()
	_map.position = MAP_RECT.position
	_map.size = MAP_RECT.size
	_map.clip_contents = true
	_map.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.draw.connect(_draw_map)
	_map.gui_input.connect(_on_map_input)
	_map.mouse_exited.connect(func() -> void: _set_hover(""))
	add_child(_map)
	# Rubriken och knappen följer UI-kitet; själva kartan är målad i världens stil.
	# Rubriken står i kartans övre vänstra hörn, så att den inte krockar med HUD:en.
	var title := UiKit.header("Neighborhood", "", UiKit.HEADING + 8)
	title.position = MAP_RECT.position + Vector2(14, 8)
	title.size = Vector2(MAP_RECT.size.x / 2.0, UiKit.HEADING + 30)
	add_child(title)
	var close := KitButton.new("Stay here", "Esc", "action")
	close.focus_mode = Control.FOCUS_NONE
	close.reset_size()
	close.position = Vector2(MAP_RECT.get_center().x - close.get_combined_minimum_size().x / 2.0, MAP_RECT.end.y + 14)
	close.pressed.connect(close_map)
	add_child(close)
	_build_card()
	_fade = ColorRect.new()
	_fade.color = Color(0.05, 0.05, 0.08)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)
	GameState.locations_changed.connect(func() -> void: _map.queue_redraw())
	GameState.time_of_day_changed.connect(func(_period: String) -> void: _map.queue_redraw())
	GameState.map_toggled.connect(func(map_is_open: bool) -> void:
		if not map_is_open:
			close_map())


func _process(delta: float) -> void:
	if not visible:
		return
	var changed := false
	for id in _pins():
		var goal := 1.18 if id == _hover else 1.0
		var current: float = _hover_scale.get(id, 1.0)
		if absf(current - goal) > 0.001:
			_hover_scale[id] = move_toward(current, goal, delta * 1.6)
			changed = true
	for id in _shake.keys():
		_shake[id] -= delta
		changed = true
		if _shake[id] <= 0:
			_shake.erase(id)
	if changed:
		_map.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_map()
		get_viewport().set_input_as_handled()


func open() -> void:
	if not GameState.is_playable():
		return
	is_open = true
	visible = true
	_traveling = false
	_set_hover("")
	_map.queue_redraw()
	GameState.set_map_open(true)


func close_map() -> void:
	if not visible or _traveling:
		return
	is_open = false
	visible = false
	GameState.set_map_open(false)
	closed.emit()


# --- Nålarna ------------------------------------------------------------------

## Alla nålar på kartan: hemmet ("home") och platserna.
func _pins() -> Array:
	return ["home"] + Locations.LOCATIONS.keys()


func _pin_position(id: String) -> Vector2:
	var at: Vector2 = Locations.HOME["map_pos"] if id == "home" else Locations.LOCATIONS[id]["map_pos"]
	return at * MAP_RECT.size


## Varför en nål inte går att välja, eller tom sträng om den går.
func _block_reason(id: String) -> String:
	# Hemmet och platsen man redan är på är alltid öppna.
	if id == "home" or GameState.current_location() == id:
		return ""
	return GameState.location_block_reason(id)


func _pin_at(point: Vector2) -> String:
	for id in _pins():
		if point.distance_to(_pin_position(id)) <= PIN_RADIUS * 1.25:
			return id
	return ""


func _on_map_input(event: InputEvent) -> void:
	if _traveling:
		return
	if event is InputEventMouseMotion:
		_set_hover(_pin_at(event.position))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id := _pin_at(event.position)
		if id != "":
			_choose(id)


func _set_hover(id: String) -> void:
	if id == _hover:
		return
	_hover = id
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if id != "" else Input.CURSOR_ARROW)
	_update_card()
	_map.queue_redraw()


## Ett val på kartan: hemmet, platsen man redan är på, en stängd plats eller en resa.
func _choose(id: String) -> void:
	var here := GameState.current_location()
	if id == "home":
		if here == "":
			close_map()
			GameState.message_posted.emit("You decide to stay home.")
			return
		_travel(func() -> void: GameState.return_home())
		return
	if id == here:
		close_map()
		return
	var reason := _block_reason(id)
	if reason != "":
		_shake[id] = 0.35
		_card_status.text = reason
		GameState.show_hint(reason)
		return
	_travel(func() -> void: GameState.travel_to_location(id))


## Tona ut, res och tona in över platsen man kommer till.
func _travel(go: Callable) -> void:
	_traveling = true
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, 0.3)
	tween.tween_callback(func() -> void:
		visible = false
		is_open = false
		GameState.set_map_open(false)
		go.call()
		closed.emit())
	tween.tween_property(_fade, "modulate:a", 0.0, 0.01)
	tween.tween_callback(func() -> void: _traveling = false)


# --- Kortet -------------------------------------------------------------------

func _build_card() -> void:
	_card = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.96, 0.92, 0.97)
	style.border_color = INK
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 6
	_card.add_theme_stylebox_override("panel", style)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	_card.add_child(column)
	_card_title = Label.new()
	_card_title.add_theme_font_size_override("font_size", 20)
	_card_title.add_theme_color_override("font_color", INK)
	column.add_child(_card_title)
	_card_text = Label.new()
	_card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_text.custom_minimum_size = Vector2(260, 0)
	_card_text.add_theme_font_size_override("font_size", 14)
	_card_text.add_theme_color_override("font_color", INK.lightened(0.25))
	column.add_child(_card_text)
	_card_status = Label.new()
	_card_status.add_theme_font_size_override("font_size", 14)
	column.add_child(_card_status)
	add_child(_card)


func _update_card() -> void:
	if _hover == "":
		_card.visible = false
		return
	var here := GameState.current_location()
	var reason := _block_reason(_hover)
	if _hover == "home":
		_card_title.text = Locations.HOME["name"]
		_card_text.text = Locations.HOME["description"]
		_card_status.text = "You are here" if here == "" else "Click to go home"
	else:
		var location: Dictionary = Locations.LOCATIONS[_hover]
		_card_title.text = location["name"]
		_card_text.text = location["description"]
		if _hover == here:
			_card_status.text = "You are here"
		elif reason != "":
			_card_status.text = "Locked – " + reason
		else:
			_card_status.text = "Open now  ·  click to travel"
	var good := reason == ""
	_card_status.add_theme_color_override("font_color", Color(0.25, 0.55, 0.3) if good else Color(0.75, 0.35, 0.2))
	_card.reset_size()
	var pin := MAP_RECT.position + _pin_position(_hover)
	var at := pin + Vector2(PIN_RADIUS + 14, -_card.size.y / 2)
	if at.x + _card.size.x > 1270:
		at.x = pin.x - PIN_RADIUS - 14 - _card.size.x
	at.y = clampf(at.y, 10, 710 - _card.size.y)
	_card.position = at
	_card.visible = true


# --- Ritningen ----------------------------------------------------------------

func _draw_map() -> void:
	var size := MAP_RECT.size
	if _art:
		_map.draw_texture_rect(_art, Rect2(Vector2.ZERO, size), false)
	else:
		_draw_placeholder(size)
	# Nålarna: stängda platser gråa med ett lås, den under musen större med en ring.
	var here := GameState.current_location()
	for id in _pins():
		var center := _pin_position(id)
		if _shake.has(id):
			center.x += sin(_shake[id] * 60.0) * 5.0
		var scale: float = _hover_scale.get(id, 1.0)
		var radius := PIN_RADIUS * scale
		var locked := _block_reason(id) != ""
		var color: Color = HOME_COLOR if id == "home" else Locations.LOCATIONS[id]["color"]
		if locked:
			color = LOCKED
		var current: bool = (id == "home" and here == "") or id == here
		# Skugga, glöd, cirkel och vit kant.
		_map.draw_circle(center + Vector2(2, 4), radius, Color(0, 0, 0, 0.2))
		if id == _hover and not locked:
			_map.draw_circle(center, radius + 9, Color(1.0, 0.95, 0.7, 0.45))
		if current:
			_map.draw_arc(center, radius + 7, 0, TAU, 40, Color(1.0, 0.85, 0.35), 4.0, true)
		_map.draw_circle(center, radius, color)
		_map.draw_arc(center, radius - 1.5, 0, TAU, 40, Color.WHITE, 3.0, true)
		_draw_icon(center, radius, "home" if id == "home" else Locations.LOCATIONS[id]["icon"], Color(1, 1, 1, 0.55) if locked else Color.WHITE)
		if locked:
			_draw_lock(center + Vector2(radius * 0.7, radius * 0.7))
		# Namnskylt under nålen.
		var name := Locations.location_name("" if id == "home" else id)
		var font := ThemeDB.fallback_font
		var font_size := 17 if id == _hover else 15
		var width := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var plate := Rect2(center + Vector2(-width / 2 - 9, radius + 6), Vector2(width + 18, font_size + 10))
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.98, 0.96, 0.92, 0.95) if not locked else Color(0.88, 0.88, 0.88, 0.95)
		style.border_color = INK.lightened(0.2)
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		_map.draw_style_box(style, plate)
		_map.draw_string(font, plate.position + Vector2(9, font_size + 2), name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK if not locked else INK.lightened(0.4))


## Platshållarkartan: gräs, kvarter, vägar med mittlinje, en damm i parken och träd.
func _draw_placeholder(size: Vector2) -> void:
	_map.draw_rect(Rect2(Vector2.ZERO, size), GRASS)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 140:
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		_map.draw_circle(p, rng.randf_range(2, 5), GRASS.darkened(0.05) if i % 2 else GRASS.lightened(0.05))
	# Kvarter runt platserna.
	for id in Locations.LOCATIONS:
		var center: Vector2 = Locations.LOCATIONS[id]["map_pos"] * size
		var block := Rect2(center - Vector2(95, 62), Vector2(190, 124))
		var style := StyleBoxFlat.new()
		style.bg_color = BLOCK if id != "park" else GRASS.lightened(0.12)
		style.set_corner_radius_all(14)
		_map.draw_style_box(style, block)
	# Hemmets kvarter med grannhuset bredvid.
	var home := (Locations.HOME["map_pos"] as Vector2) * size
	var home_style := StyleBoxFlat.new()
	home_style.bg_color = BLOCK
	home_style.set_corner_radius_all(14)
	_map.draw_style_box(home_style, Rect2(home - Vector2(110, 62), Vector2(330, 124)))
	# Vägar: mörk kant, ljus yta och streckad mittlinje.
	for road in Locations.ROADS:
		var points := PackedVector2Array()
		for p in road:
			points.append((p as Vector2) * size)
		_map.draw_polyline(points, ROAD.darkened(0.25), 30.0, true)
		_map.draw_polyline(points, ROAD, 26.0, true)
		for i in points.size() - 1:
			var a := points[i]
			var b := points[i + 1]
			var length := a.distance_to(b)
			var t := 0.0
			while t < length:
				_map.draw_line(a.lerp(b, t / length), a.lerp(b, minf(t + 12, length) / length), Color(1, 1, 1, 0.8), 2.0)
				t += 26
	# Dammen i parken och träd runt omkring.
	var park: Vector2 = Locations.LOCATIONS["park"]["map_pos"] * size
	var pond := PackedVector2Array()
	for i in 24:
		pond.append(park + Vector2(-52, -32) + Vector2.from_angle(TAU * i / 24.0) * Vector2(34, 20))
	_map.draw_colored_polygon(pond, Color(0.55, 0.78, 0.9))
	for i in 34:
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var near_road := false
		for id in _pins():
			if p.distance_to(_pin_position(id)) < 70:
				near_road = true
		if near_road:
			continue
		_map.draw_circle(p + Vector2(2, 3), 11, Color(0, 0, 0, 0.12))
		_map.draw_circle(p, 11, Color(0.42, 0.62, 0.38))
		_map.draw_circle(p + Vector2(-3, -3), 6, Color(0.5, 0.7, 0.45))
	# Ram och en liten kompass.
	_map.draw_rect(Rect2(Vector2.ZERO, size), INK, false, 3.0)
	var compass := Vector2(size.x - 42, 42)
	_map.draw_circle(compass, 20, Color(0.98, 0.96, 0.92, 0.9))
	_map.draw_colored_polygon(PackedVector2Array([compass + Vector2(0, -16), compass + Vector2(6, 2), compass + Vector2(-6, 2)]), Color(0.85, 0.3, 0.3))
	_map.draw_string(ThemeDB.fallback_font, compass + Vector2(-5, 17), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK)


## Enkla symboler i vitt för varje sorts plats.
func _draw_icon(c: Vector2, r: float, icon: String, color: Color) -> void:
	var s := r / 30.0
	match icon:
		"home", "house":
			_map.draw_colored_polygon(PackedVector2Array([c + Vector2(-13, -1) * s, c + Vector2(0, -13) * s, c + Vector2(13, -1) * s]), color)
			_map.draw_rect(Rect2(c + Vector2(-9, -1) * s, Vector2(18, 13) * s), color)
			_map.draw_rect(Rect2(c + Vector2(-3, 4) * s, Vector2(6, 8) * s), Color(0, 0, 0, 0.25))
			if icon == "home":
				_map.draw_circle(c + Vector2(-2, 1) * s, 2.5 * s, HOME_COLOR)
				_map.draw_circle(c + Vector2(2, 1) * s, 2.5 * s, HOME_COLOR)
		"school":
			_map.draw_rect(Rect2(c + Vector2(-13, -5) * s, Vector2(26, 17) * s), color)
			_map.draw_colored_polygon(PackedVector2Array([c + Vector2(-15, -4) * s, c + Vector2(0, -14) * s, c + Vector2(15, -4) * s]), color)
			_map.draw_line(c + Vector2(0, -14) * s, c + Vector2(0, -20) * s, color, 2.0)
			_map.draw_rect(Rect2(c + Vector2(0, -20) * s, Vector2(7, 4) * s), color)
			for x in [-8, 4]:
				_map.draw_rect(Rect2(c + Vector2(x, 0) * s, Vector2(4, 4) * s), Color(0, 0, 0, 0.25))
		"fitness":
			_map.draw_line(c + Vector2(-12, 0) * s, c + Vector2(12, 0) * s, color, 4.0 * s)
			for x in [-12, 12]:
				_map.draw_rect(Rect2(c + Vector2(x - 3, -8) * s, Vector2(6, 16) * s), color)
		"shopping":
			_map.draw_rect(Rect2(c + Vector2(-11, -5) * s, Vector2(22, 17) * s), color)
			_map.draw_arc(c + Vector2(0, -5) * s, 6 * s, PI, TAU, 12, color, 2.5)
		"park":
			_map.draw_rect(Rect2(c + Vector2(-2, 2) * s, Vector2(4, 11) * s), color)
			_map.draw_circle(c + Vector2(0, -4) * s, 10 * s, color)


## Ett litet hänglås nere till höger på en stängd nål.
func _draw_lock(c: Vector2) -> void:
	_map.draw_circle(c, 11, INK)
	_map.draw_arc(c + Vector2(0, -2), 4.5, PI, TAU, 10, Color.WHITE, 2.0)
	_map.draw_rect(Rect2(c + Vector2(-5, -2), Vector2(10, 7)), Color.WHITE)
