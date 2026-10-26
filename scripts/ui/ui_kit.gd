class_name UiKit
## Spelets UI-kit i Persona 4-anda: svart och gult, tung lutande typografi, sneda
## plattor med hårda skuggor och snabba, kraftiga övergångar. Titelskärmen, pausmenyn,
## HUD:en och rummens menyer bygger av det här, så att stilen ändras på ett ställe.
## Komponenterna är KitButton (knappar och flikar), KitBackdrop (bakgrunder) och
## UiTransition (övergångar och skyltar). Telefonen har sin egen stil (PhoneTheme),
## eftersom den är en sak i världen. Beskrivning av kitet: docs/ui_kit.md.

# --- Färger ------------------------------------------------------------------------
const INK := Color("16131a")
## Ytor som ligger på den svarta bakgrunden (kort, spår i mätare).
const INK_2 := Color("2a2430")
const YELLOW := Color("ffd319")
const YELLOW_DARK := Color("d99a00")
const PAPER := Color("f7f2e7")
const RED := Color("e5412f")
const MUTED := Color("958d9c")
const SCRIM := Color(0.05, 0.04, 0.07, 0.72)
## Mammans mätare (GameState.STAT_NAMES).
const METERS := {"home": Color("ff9f2e"), "work": Color("4ea8ff"), "romance": Color("ff5c9a")}

# --- Textstorlekar -----------------------------------------------------------------
const HERO := 88
const DISPLAY := 60
const TITLE := 40
const MENU := 30
const HEADING := 24
const BODY := 18
const SMALL := 15
const TINY := 12

# --- Form ----------------------------------------------------------------------------
## Hur mycket plattorna lutar: förskjutning i x per pixel i höjd.
const SLANT := 0.25
## Den hårda skuggan under plattor och knappar.
const SHADOW := Vector2(6, 6)

# --- Rörelse (sekunder) ------------------------------------------------------------
const FAST := 0.12
const MID := 0.24
const SLOW := 0.42
## Fördröjningen mellan listval som glider in efter varandra.
const STAGGER := 0.045

# --- Typsnitt ------------------------------------------------------------------------
## Egna typsnittsfiler som ersätter systemtypsnitten om de finns. Display ska vara ett
## fett, smalt och kursivt typsnitt; systemets får lutning och fetma här.
const FONT_FILES := {
	"display": "res://Assets/fonts/ui_display.ttf",
	"body": "res://Assets/fonts/ui_body.ttf",
	"body_bold": "res://Assets/fonts/ui_body_bold.ttf",
}
const DISPLAY_FONTS := ["Bahnschrift", "Impact", "Arial Black", "Arial"]
const BODY_FONTS := ["Bahnschrift", "Segoe UI", "Arial"]
const ITALIC := 0.2

# --- Inställningar -----------------------------------------------------------------
const SETTINGS_PATH := "user://settings.cfg"
## Kortare och stillsammare animationer (inställningen Motion).
static var reduced_motion := false
static var _settings_loaded := false

static var _fonts := {}
static var _theme: Theme


## Rubriktypsnittet: fett, smalt och lutande.
static func display_font() -> Font:
	return _font("display", DISPLAY_FONTS, 700, 75, ITALIC, 0.35)


## Brödtexten (bold för etiketter, antal och taggar).
static func body_font(bold := false) -> Font:
	return _font("body_bold" if bold else "body", BODY_FONTS, 600 if bold else 400, 87 if bold else 100, 0.0, 0.0)


static func _font(key: String, names: Array, weight: int, stretch: int, slant: float, embolden: float) -> Font:
	if _fonts.has(key):
		return _fonts[key]
	var font: Font
	if ResourceLoader.exists(FONT_FILES[key]):
		font = load(FONT_FILES[key])
	else:
		var system := SystemFont.new()
		system.font_names = PackedStringArray(names)
		system.font_weight = weight
		system.font_stretch = stretch
		system.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		system.hinting = TextServer.HINTING_LIGHT
		# Bahnschrift är ett variabelt typsnitt: vikt och bredd väljs med axlarna.
		var variation := FontVariation.new()
		variation.base_font = system
		variation.variation_opentype = {"wght": weight, "wdth": stretch}
		variation.variation_transform = Transform2D(Vector2(1.0, slant), Vector2(0.0, 1.0), Vector2.ZERO)
		variation.variation_embolden = embolden
		font = variation
	_fonts[key] = font
	return font


## Temat för kitets skärmar, så att vanliga etiketter och rullister får stilen.
static func theme() -> Theme:
	if _theme == null:
		_theme = Theme.new()
		_theme.default_font = body_font()
		_theme.default_font_size = BODY
		_theme.set_color("font_color", "Label", PAPER)
		for bar in ["VScrollBar", "HScrollBar"]:
			var track := StyleBoxFlat.new()
			track.bg_color = Color(PAPER, 0.08)
			track.content_margin_left = 3
			track.content_margin_right = 3
			var grabber := StyleBoxFlat.new()
			grabber.bg_color = YELLOW
			_theme.set_stylebox("scroll", bar, track)
			_theme.set_stylebox("grabber", bar, grabber)
			_theme.set_stylebox("grabber_highlight", bar, grabber)
			_theme.set_stylebox("grabber_pressed", bar, grabber)
		_theme.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	return _theme


# --- Inställningar -----------------------------------------------------------------

## Läser inställningarna en gång (titelskärmen och huset anropar den).
static func load_settings() -> void:
	if _settings_loaded:
		return
	_settings_loaded = true
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	reduced_motion = config.get_value("ui", "reduced_motion", false)
	if config.get_value("display", "fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


static func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("ui", "reduced_motion", reduced_motion)
	config.set_value("display", "fullscreen", is_fullscreen())
	config.save(SETTINGS_PATH)


static func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]


## Inställningarna som en lista med val; trycket växlar och värdet står till höger.
## Samma lista finns på titelskärmen och i pausmenyn.
static func settings_list(font_size := 26) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	var rows := [
		["Fullscreen", func() -> String: return "On" if UiKit.is_fullscreen() else "Off",
			func() -> void: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if UiKit.is_fullscreen() else DisplayServer.WINDOW_MODE_FULLSCREEN)],
		["Motion", func() -> String: return "Reduced" if UiKit.reduced_motion else "Full",
			func() -> void: UiKit.reduced_motion = not UiKit.reduced_motion],
	]
	for row in rows:
		var button := KitButton.new(row[0], row[1].call(), "menu", font_size)
		button.pressed.connect(func() -> void:
			row[2].call()
			UiKit.save_settings()
			button.note = row[1].call())
		column.add_child(button)
	return column


# --- Rörelse -------------------------------------------------------------------------

## En tid som följer inställningen Motion (Reduced gör allt nästan direkt).
static func t(seconds: float) -> float:
	return seconds * (0.35 if reduced_motion else 1.0)


## Hur långt något glider in (inte alls med Reduced).
static func travel(offset: Vector2) -> Vector2:
	return Vector2.ZERO if reduced_motion else offset


## Tonar fram och glider in något till där det står. Bara för kontroller som inte
## ligger i en container (containern flyttar tillbaka dem); KitButton har appear().
static func enter(item: CanvasItem, delay := 0.0, from := Vector2(-48, 0), duration := MID) -> Tween:
	var target: Vector2 = item.position
	item.position = target + travel(from)
	item.modulate.a = 0.0
	var tween := item.create_tween().set_parallel().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(item, "position", target, t(duration)).set_delay(delay)
	tween.tween_property(item, "modulate:a", 1.0, t(duration * 0.6)).set_delay(delay)
	return tween


# --- Ritning -------------------------------------------------------------------------

## Hörnen på en platta som lutar åt höger och fyller rect (överkanten är förskjuten).
static func slant_points(rect: Rect2, slant := SLANT) -> PackedVector2Array:
	var lean := minf(rect.size.y * slant, rect.size.x)
	return PackedVector2Array([
		rect.position + Vector2(lean, 0),
		rect.position + Vector2(rect.size.x, 0),
		rect.position + Vector2(rect.size.x - lean, rect.size.y),
		rect.position + Vector2(0, rect.size.y),
	])


## En sned platta, med en tunn kantutjämnad kant så att diagonalerna inte blir taggiga.
static func draw_slant(item: CanvasItem, rect: Rect2, color: Color, slant := SLANT) -> void:
	if rect.size.x <= 0.5 or rect.size.y <= 0.5:
		return
	var points := slant_points(rect, slant)
	item.draw_colored_polygon(points, color)
	points.append(points[0])
	item.draw_polyline(points, color, 1.0, true)


static func draw_slant_outline(item: CanvasItem, rect: Rect2, color: Color, width := 2.0, slant := SLANT) -> void:
	var points := slant_points(rect, slant)
	points.append(points[0])
	item.draw_polyline(points, color, width, true)


## En mätare: svart kant, mörkt spår och fyllning till ratio, med streck var tionde del
## om ticks är sant.
static func draw_meter(item: CanvasItem, rect: Rect2, ratio: float, color: Color, ticks := false) -> void:
	draw_slant(item, rect.grow(3), INK)
	draw_slant(item, rect, INK_2)
	var lean := rect.size.y * SLANT
	if ratio > 0.0:
		draw_slant(item, Rect2(rect.position, Vector2(lean + (rect.size.x - lean) * clampf(ratio, 0.0, 1.0), rect.size.y)), color)
	if ticks:
		for i in range(1, 10):
			var x := rect.position.x + lean + (rect.size.x - lean) * i / 10.0
			item.draw_line(Vector2(x, rect.position.y), Vector2(x - lean, rect.end.y), Color(INK, 0.45), 2.0, true)


## En rad sneda prickar för nivåer och ranker: filled av count är ifyllda.
static func draw_pips(item: CanvasItem, origin: Vector2, count: int, filled: int, color: Color, pip := Vector2(18, 12), gap := 4.0) -> void:
	for i in count:
		var rect := Rect2(origin + Vector2(i * (pip.x + gap), 0), pip)
		draw_slant(item, rect, color if i < filled else Color(PAPER, 0.14))


## Stor rubriktext med svart kontur och röd hård skugga.
static func draw_display(item: CanvasItem, at: Vector2, text: String, size: int, color := YELLOW, shadow := RED, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var font := display_font()
	var outline := maxi(4, size / 7)
	if shadow.a > 0.0:
		var offset := Vector2(maxf(3, size / 14.0), maxf(3, size / 14.0))
		item.draw_string_outline(font, at + offset, text, align, width, size, outline, shadow)
		item.draw_string(font, at + offset, text, align, width, size, shadow)
	item.draw_string_outline(font, at, text, align, width, size, outline, INK)
	item.draw_string(font, at, text, align, width, size, color)


## Var baslinjen hamnar för att text ska stå mitt i en höjd.
static func baseline(font: Font, size: int, height: float) -> float:
	return (height + font.get_ascent(size) - font.get_descent(size)) / 2.0


# --- Byggstenar ----------------------------------------------------------------------

## En sned StyleBox (platta) för paneler och etiketter. margin är luften runt innehållet.
static func plate(color: Color, slant := 0.0, border := Color(0, 0, 0, 0), border_width := 0, shadow := Color(0, 0, 0, 0), margin := Vector2(20, 14)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.skew = Vector2(slant, 0)
	style.anti_aliasing = true
	if border_width > 0:
		style.border_color = border
		style.set_border_width_all(border_width)
	if shadow.a > 0.0:
		style.shadow_color = shadow
		style.shadow_size = 1
		style.shadow_offset = SHADOW
	style.content_margin_left = margin.x
	style.content_margin_right = margin.x
	style.content_margin_top = margin.y
	style.content_margin_bottom = margin.y
	return style


## Ett kort: mörk platta med tunn ljus kant och hård skugga.
static func card(margin := 20) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", plate(INK_2, 0.0, Color(PAPER, 0.18), 2, Color(INK, 0.9), Vector2(margin, margin)))
	return panel


static func label(text: String, size := BODY, color := PAPER, bold := false, wrap_width := 0.0) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_override("font", body_font(bold))
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap_width > 0.0:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result.custom_minimum_size.x = wrap_width
	return result


## Text i rubriktypsnittet, med kontur och (valfri) hård skugga.
static func display(text: String, size := TITLE, color := YELLOW, shadow := RED) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_override("font", display_font())
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.add_theme_color_override("font_outline_color", INK)
	result.add_theme_constant_override("outline_size", maxi(4, size / 7))
	if shadow.a > 0.0:
		result.add_theme_color_override("font_shadow_color", shadow)
		result.add_theme_constant_override("shadow_offset_x", maxi(3, size / 14))
		result.add_theme_constant_override("shadow_offset_y", maxi(3, size / 14))
		result.add_theme_constant_override("shadow_outline_size", maxi(4, size / 7))
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


## En skärms stora rubrik, lätt vriden som i Persona, med en ljus etikett efter
## (t.ex. "3 / 8 collected").
static func header(title: String, kicker := "", size := DISPLAY) -> Control:
	var control := Control.new()
	control.custom_minimum_size = Vector2(0, size + 22)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text := title.to_upper()
	control.draw.connect(func() -> void:
		control.draw_set_transform(Vector2(4, size * 0.92), deg_to_rad(-3.0))
		draw_display(control, Vector2.ZERO, text, size)
		if kicker != "":
			var width := display_font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			var font := body_font(true)
			var kicker_width := font.get_string_size(kicker, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL).x
			var rect := Rect2(width + 30, -30, kicker_width + 34, 28)
			draw_slant(control, rect, PAPER)
			control.draw_string(font, rect.position + Vector2(17, baseline(font, SMALL, rect.size.y)), kicker, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL, INK))
	return control


## Tangenter och vad de gör, nederst på skärmarna: [["Esc", "Back"], …].
static func key_hints(pairs: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for pair in pairs:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 8)
		var key := label(pair[0], TINY + 1, INK, true)
		key.add_theme_stylebox_override("normal", plate(PAPER, SLANT, Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), Vector2(9, 2)))
		item.add_child(key)
		item.add_child(label(pair[1], SMALL - 1, Color(PAPER, 0.7)))
		row.add_child(item)
	return row


## En bekräftelseruta över allt: fråga, förklaring och Yes/No. "No" har fokus från
## början; on_no anropas också av den som stänger rutan med Esc.
static func confirm(question: String, detail: String, yes_text: String, on_yes: Callable, on_no: Callable) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.theme = theme()
	var scrim := ColorRect.new()
	scrim.color = SCRIM
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", plate(INK, 0.0, YELLOW, 3, RED, Vector2(34, 28)))
	center.add_child(box)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	box.add_child(column)
	column.add_child(display(question, HEADING + 6))
	if detail != "":
		column.add_child(label(detail, BODY, Color(PAPER, 0.85), false, 520))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	column.add_child(buttons)
	var yes := KitButton.new(yes_text, "", "action")
	yes.pressed.connect(on_yes)
	var no := KitButton.new("No", "", "action")
	no.pressed.connect(on_no)
	buttons.add_child(yes)
	buttons.add_child(no)
	no.grab_focus.call_deferred()
	overlay.modulate.a = 0.0
	overlay.create_tween().tween_property(overlay, "modulate:a", 1.0, t(FAST))
	return overlay
