class_name PhoneTheme
## Telefonens utseende på ett ställe: färger, typsnitt, textstorlekar, rundningar och
## mått. phone.gd och PhoneIcons läser allt härifrån, så att telefonen kan målas om
## när spelets slutliga stil är bestämd utan att sidorna behöver ändras.
## Måtten och vad de används till står i docs/phone_ui_spec.md.

# --- Färger (warm minimalism: krämvitt, varm brun text, salvia och teal) ----------
const INK := Color("2b2420")
const PAPER := Color("fbf7f1")
const CARD := Color("ffffff")
const MUTED := Color("8a7f76")
const LINE := Color("e8e0d6")
const ACCENT := Color("2f8f8a")
const THEM_BUBBLE := Color("efe8df")
const DANGER := Color("d0533f")
const BADGE := Color("e0503c")
const BEZEL := Color("1d1916")
const BEZEL_EDGE := Color("6d635b")

## Appikonernas färger.
const TILE := {
	"phone": Color("6fa67a"),
	"messages": Color("3e9c95"),
	"memories": Color("e07a5f"),
	"journal": Color("d4a04c"),
	"calendar": Color("c8554b"),
	"profile": Color("c9677f"),
	"wallet": Color("4f7cac"),
	"settings": Color("8c8379"),
}

# --- Textstorlekar ---------------------------------------------------------------
const CAPTION := 11
const FOOTNOTE := 12
const SUBHEAD := 13
const BODY := 14
const CALLOUT := 15
const HEADLINE := 17
const TITLE := 28
const CLOCK := 54

# --- Mått (i pixlar, skärmens koordinater där inget annat sägs) -------------------
const BODY_SIZE := Vector2(320, 640)
const BEZEL_WIDTH := 10
const BODY_RADIUS := 46
## Skärmens rundning är kroppens minus ramen, så att hörnen blir koncentriska.
const SCREEN_RADIUS := BODY_RADIUS - BEZEL_WIDTH
const SCREEN_SIZE := BODY_SIZE - Vector2(BEZEL_WIDTH, BEZEL_WIDTH) * 2
const STATUS_HEIGHT := 44
const ISLAND_SIZE := Vector2(96, 28)
const HOME_INDICATOR := Vector2(120, 5)
const SIDE := 16
const TILE_SIZE := 56
const TILE_RADIUS := 15
const CARD_RADIUS := 14
const BUTTON_RADIUS := 22
const DOCK_HEIGHT := 84
const DOCK_RADIUS := 30

## Egna typsnittsfiler som ersätter systemtypsnittet om de finns.
const FONT_FILES := {
	400: "res://Assets/fonts/phone_ui_regular.ttf",
	600: "res://Assets/fonts/phone_ui_semibold.ttf",
	700: "res://Assets/fonts/phone_ui_bold.ttf",
}
const SYSTEM_FONTS := ["Nunito", "Quicksand", "Segoe UI Variable Text", "Segoe UI", "Arial"]

static var _fonts := {}
static var _theme: Theme


## Typsnittet i en vikt (400 vanlig, 600 halvfet, 700 fet).
static func font(weight := 400) -> Font:
	if not _fonts.has(weight):
		var path: String = FONT_FILES.get(weight, FONT_FILES[400])
		if ResourceLoader.exists(path):
			_fonts[weight] = load(path)
		else:
			var system := SystemFont.new()
			system.font_names = PackedStringArray(SYSTEM_FONTS)
			system.font_weight = weight
			system.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
			system.hinting = TextServer.HINTING_LIGHT
			system.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
			_fonts[weight] = system
	return _fonts[weight]


## Temat som läggs på telefonens rot, så att alla etiketter och knappar får typsnittet.
static func theme() -> Theme:
	if _theme == null:
		_theme = Theme.new()
		_theme.default_font = font(400)
		_theme.default_font_size = BODY
		for type in ["Label", "Button"]:
			_theme.set_color("font_color", type, INK)
		_theme.set_font("font", "Button", font(600))
	return _theme


## En rundad StyleBoxFlat med mjuka hörn (många hörnsegment och kantutjämning).
static func rounded(color: Color, radius: int, border := Color(0, 0, 0, 0), border_width := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.corner_detail = 16
	style.anti_aliasing = true
	if border_width > 0:
		style.border_color = border
		style.set_border_width_all(border_width)
	return style


## Samma ruta för knappens alla lägen, med en mörkare ton när den trycks ned.
## padding är marginalen runt texten (x på sidorna, y över och under).
static func style_button(button: Button, color: Color, radius: int, text_color := Color.WHITE, border := Color(0, 0, 0, 0), padding := Vector2.ZERO) -> void:
	var border_width := 1 if border.a > 0 else 0
	var states := {
		"normal": color,
		"hover": color.lightened(0.06) if color.a > 0 else Color(INK, 0.05),
		"pressed": color.darkened(0.1) if color.a > 0 else Color(INK, 0.1),
		"disabled": color,
	}
	for state in states:
		var style := rounded(states[state], radius, border, border_width)
		if padding != Vector2.ZERO:
			style.content_margin_left = padding.x
			style.content_margin_right = padding.x
			style.content_margin_top = padding.y
			style.content_margin_bottom = padding.y
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, text_color)


## Knapparna nere till höger på skärmen (telefonen och kartan), staplade med HUD_GAP
## emellan. De hör till HUD:en och följer därför UI-kitet (UiKit), inte telefonens
## egen stil: en svart sned platta med röd hård skugga, kitets typsnitt och plats för
## en symbol till vänster. Under musen lyser kanten och texten gult.
const HUD_BUTTON_SIZE := Vector2(150, 44)
const HUD_GAP := 10
const HUD_MARGIN := 16


## En HUD-knapp. slot räknas nerifrån: 0 är den nedersta.
static func hud_button(text: String, slot: int) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size = HUD_BUTTON_SIZE
	button.position = Vector2(1280 - HUD_MARGIN - HUD_BUTTON_SIZE.x, 720 - HUD_MARGIN - HUD_BUTTON_SIZE.y - slot * (HUD_BUTTON_SIZE.y + HUD_GAP))
	button.add_theme_font_override("font", UiKit.display_font())
	button.add_theme_font_size_override("font_size", UiKit.BODY)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var edge := Color(UiKit.PAPER, 0.25)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var lit: bool = state != "normal"
		var style := UiKit.plate(Color(UiKit.INK, 0.94), UiKit.SLANT, UiKit.YELLOW if lit else edge, 2, UiKit.RED, Vector2(12, 0))
		style.shadow_offset = UiKit.SHADOW * 0.6
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", UiKit.PAPER)
	for state in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, UiKit.YELLOW)
	return button


## Rundar hörnen på allt kontrollen själv ritar (inte dess barn). Används för bilder
## och bakgrunder inne i telefonen, där nästlad clip_children inte ritar rätt.
static func round_corners(control: Control, radius: float) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/rounded_mask.gdshader")
	material.set_shader_parameter("radius", radius)
	control.material = material
	var update := func() -> void: material.set_shader_parameter("size", control.size)
	control.resized.connect(update)
	update.call()


## Batteriets nivå följer dagen: fullt på morgonen, nästan slut på natten.
static func battery_level(period: String) -> float:
	return {"morning": 1.0, "afternoon": 0.72, "evening": 0.41, "night": 0.18}.get(period, 1.0)
