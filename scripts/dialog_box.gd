extends CanvasLayer
## Dialogruta i Persona 4-anda: svart sned textruta med gul kant, en fet gul namnskylt på
## talarens sida och porträtt av de två som pratar. Mamman står alltid till vänster och
## den hon pratar med till höger. Talaren är framme och upplyst och hoppar fram när ordet
## går över; den andra tonas ned och sjunker lite.
##
## Texten skrivs fram tecken för tecken med korta pauser efter skiljetecken. Klick,
## mellanslag, Enter eller Z visar resten av repliken direkt, eller nästa replik om hela
## redan syns. Håll Ctrl för att spola (allt syns direkt och nästa replik kommer av sig själv).
##
## Repliker: [{"speaker": "son_1", "text": "...", "expression": "happy"}, ...]
## Tom speaker är berättartext: ingen skylt, båda porträtten nedtonade.
## "expression" väljer PORTRAITS["son_1_happy"] om den finns, annars vanliga porträttet.

signal line_started(index: int)
signal closed

## Porträtt per karaktär (Anima-bilder). Saknas en bild visas en siluett.
## Porträtten är frilagda (tools/make_portrait.gd).
const PORTRAITS := {
	"mom": "res://Assets/portraits/mom.png",
}
## Vilken del av bilden som visas (överkroppen), som andel av bilden.
const PORTRAIT_REGION := Rect2(0.0, 0.0, 1.0, 0.75)

# --- Utseende -------------------------------------------------------------------
const YELLOW := Color("ffe14d")
const BOX_FILL := Color(0.05, 0.05, 0.07, 0.94)
const INK := Color("111014")
const TEXT_COLOR := Color("f4f1ea")
const NARRATION_COLOR := Color("c9d0e6")
const DIM := Color(0.4, 0.4, 0.48)
const TEXT_SIZE := 18
const NAME_SIZE := 20

# --- Layout, i viewportens koordinater (1280×720) -----------------------------------
## Textrutans hörn: lite sned, som i Persona. Halva bredden mot förr och centrerad, så
## att mer av rummet syns; texten har ändå plats för tre rader.
const BOX := [Vector2(346, 590), Vector2(946, 582), Vector2(934, 698), Vector2(334, 702)]
## Kantens tjocklek, skuggans förskjutning och var den tunna inre linjen går.
const BOX_EDGE := 4.0
const BOX_SHADOW := Vector2(6, 6)
const BOX_INNER := 6.0
## Det gula hörnet nere till höger, där pilen för "nästa" sitter.
const CORNER_ALONG_BOTTOM := 0.12
const CORNER_ALONG_RIGHT := 0.3
const ARROW_AT := Vector2(912, 686)
const TEXT_RECT := Rect2(370, 604, 548, 82)
## Porträttens överkant ligger utanför bild även nedtonad (bilderna är rakt avskurna där).
## Underkanten tonas ut från PORTRAIT_FADE (andel av höjden), eftersom den smala
## textrutan inte längre täcker den.
const PORTRAIT_SIZE := Vector2(336, 480)
const PORTRAIT_FADE := 0.68
const PORTRAIT_SHADER := "res://shaders/portrait_fade.gdshader"
const LEFT_SLOT := Vector2(110, -40)
const RIGHT_SLOT := Vector2(834, -40)
## Hur den som lyssnar sjunker och krymper.
const LISTENER_DROP := 14.0
const LISTENER_SCALE := 0.96
## Namnskylten: höjd, var den sitter över textrutan och luft runt namnet.
const PLATE_HEIGHT := 36.0
const PLATE_Y := 556.0
const PLATE_LEFT_X := 366.0
const PLATE_RIGHT_END := 926.0
const PLATE_PADDING := 46.0

# --- Fram-skrivning ---------------------------------------------------------------
const CHARS_PER_SECOND := 48.0
## Extra paus efter ett tecken, om det följs av mellanslag eller är sist.
const PAUSES := {".": 0.22, "!": 0.22, "?": 0.22, "…": 0.3, ",": 0.08, ";": 0.1, ":": 0.1, "—": 0.12}
## Tid mellan repliker när man spolar med Ctrl.
const SKIP_DELAY := 0.08
## Klick direkt efter att en replik börjat ignoreras, så att ett dubbelklick inte hoppar över den.
const INPUT_GRACE := 0.12
const ADVANCE_KEYS := [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_Z]

enum Side { NONE, LEFT, RIGHT }

var _root: Control
var _left: TextureRect
var _right: TextureRect
var _text: Label
var _plate: Control
var _arrow: Control
var _plate_font: Font
var _text_font: Font

var _lines: Array = []
var _index := 0
var _right_id := ""
var _side := Side.NONE
var _plate_name := ""
var _plate_color := Color.WHITE
var _typing := false
var _wait := 0.0
var _line_age := 0.0
var _done_age := 0.0
var _stage_tween: Tween


func _ready() -> void:
	layer = 4
	visible = false
	_plate_font = UiKit.display_font()
	_text_font = UiKit.body_font()

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_press())
	_root.draw.connect(_draw_shade)
	add_child(_root)

	# Ritordning: porträtt, textruta, text, namnskylt, pil.
	_left = _portrait_rect(LEFT_SLOT)
	_right = _portrait_rect(RIGHT_SLOT)
	_right.flip_h = true
	var box := Control.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.draw.connect(_draw_box.bind(box))
	_root.add_child(box)

	_text = Label.new()
	_text.position = TEXT_RECT.position
	_text.size = TEXT_RECT.size
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_override("font", _text_font)
	_text.add_theme_font_size_override("font_size", TEXT_SIZE)
	_text.add_theme_constant_override("line_spacing", 2)
	_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_text.add_theme_constant_override("shadow_offset_x", 1)
	_text.add_theme_constant_override("shadow_offset_y", 1)
	_root.add_child(_text)

	_plate = Control.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.draw.connect(_draw_plate)
	_root.add_child(_plate)

	_arrow = Control.new()
	_arrow.position = ARROW_AT
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.draw.connect(func() -> void:
		_arrow.draw_colored_polygon(PackedVector2Array([Vector2(-7, -5), Vector2(7, -5), Vector2(0, 5)]), INK))
	_root.add_child(_arrow)


## Visar en replik. Finns kvar för enkla anrop; play() tar en hel konversation.
func open(speaker_id: String, text: String) -> void:
	play([{"speaker": speaker_id, "text": text}])


## Spelar repliker i ordning och skickar closed efter sista. `partner` är den som står
## till höger från början; utan den blir det första som inte är mamman.
func play(lines: Array, partner := "") -> void:
	if lines.is_empty():
		return
	_lines = lines
	_index = 0
	_right_id = partner
	if _right_id == "":
		for line: Dictionary in lines:
			var speaker: String = line.get("speaker", "")
			if speaker != "" and speaker != "mom":
				_right_id = speaker
				break
	_left.texture = _portrait("mom")
	_right.texture = _portrait(_right_id) if _right_id != "" else null
	_right.visible = _right_id != ""
	_side = Side.NONE
	visible = true
	GameState.set_dialogue_open(self, true)
	_show_line()


func close() -> void:
	if visible:
		visible = false
		_lines = []
		GameState.set_dialogue_open(self, false)
		closed.emit()


func _exit_tree() -> void:
	GameState.set_dialogue_open(self, false)


func _process(delta: float) -> void:
	if not visible:
		return
	_line_age += delta
	var skipping := Input.is_key_pressed(KEY_CTRL)
	if _typing:
		if skipping:
			_finish_line()
		else:
			_wait -= delta
			while _typing and _wait <= 0.0:
				_reveal_next()
	else:
		_done_age += delta
		_arrow.position.y = ARROW_AT.y + sin(_done_age * 7.0) * 3.0
		if skipping and _done_age >= SKIP_DELAY:
			_advance()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	# Alla tangenter fångas medan rutan är öppen, så att spelet bakom inte reagerar.
	get_viewport().set_input_as_handled()
	if event.pressed and not event.echo and event.keycode in ADVANCE_KEYS:
		_press()


func _press() -> void:
	if _line_age < INPUT_GRACE:
		return
	if _typing:
		_finish_line()
	else:
		_advance()


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		close()
	else:
		_show_line()


func _show_line() -> void:
	var line: Dictionary = _lines[_index]
	var speaker: String = line.get("speaker", "")
	var expression: String = line.get("expression", "")
	# En tredje person som tar ordet kliver in på högra platsen.
	if speaker != "" and speaker != "mom" and speaker != _right_id:
		_right_id = speaker
		_right.visible = true
	if speaker == "mom":
		_left.texture = _portrait("mom", expression)
	elif speaker != "":
		_right.texture = _portrait(speaker, expression)

	_text.text = line.get("text", "")
	_text.visible_characters = 0
	_text.add_theme_color_override("font_color", TEXT_COLOR if speaker != "" else NARRATION_COLOR)
	_typing = _text.text != ""
	_wait = 0.0
	_line_age = 0.0
	_done_age = 0.0
	_arrow.visible = not _typing
	_stage(speaker)
	line_started.emit(_index)


func _reveal_next() -> void:
	var shown := _text.visible_characters + 1
	_text.visible_characters = shown
	if shown >= _text.text.length():
		_finish_line()
		return
	var character := _text.text[shown - 1]
	var pause: float = PAUSES.get(character, 0.0) if _text.text[shown] == " " else 0.0
	_wait += 1.0 / CHARS_PER_SECOND + pause


func _finish_line() -> void:
	_typing = false
	_text.visible_characters = -1
	_done_age = 0.0
	_arrow.visible = true


# --- Vem som pratar -------------------------------------------------------------

## Ställer upp scenen för talaren: porträtten byter ljus, storlek och höjd, och
## skylten glider in på talarens sida. En ny talare hoppar lite inåt mot mitten.
func _stage(speaker: String) -> void:
	var side := Side.NONE
	if speaker == "mom":
		side = Side.LEFT
	elif speaker != "":
		side = Side.RIGHT
	var changed := side != _side
	_side = side

	if _stage_tween:
		_stage_tween.kill()
	_stage_tween = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_stage_portrait(_left, LEFT_SLOT, side == Side.LEFT, changed, -1.0)
	_stage_portrait(_right, RIGHT_SLOT, side == Side.RIGHT, changed, 1.0)

	_plate.visible = side != Side.NONE
	if side == Side.NONE:
		return
	_plate_name = GameState.character_name(speaker)
	_plate_color = GameState.CHARACTERS[speaker]["color"]
	var width := _plate_font.get_string_size(_plate_name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x + PLATE_PADDING
	_plate.size = Vector2(width, PLATE_HEIGHT)
	var target := Vector2(PLATE_LEFT_X if side == Side.LEFT else PLATE_RIGHT_END - width, PLATE_Y)
	_plate.queue_redraw()
	if changed:
		_plate.position = target + Vector2(-28.0 if side == Side.LEFT else 28.0, 0)
		_plate.modulate.a = 0.0
		_stage_tween.tween_property(_plate, "position", target, 0.18)
		_stage_tween.tween_property(_plate, "modulate:a", 1.0, 0.12)
	else:
		_plate.position = target


func _stage_portrait(rect: TextureRect, slot: Vector2, active: bool, changed: bool, outward: float) -> void:
	var target := slot if active else slot + Vector2(0, LISTENER_DROP)
	if active and changed:
		rect.position = slot + Vector2(outward * 28.0, 0)
	_stage_tween.tween_property(rect, "position", target, 0.22)
	_stage_tween.tween_property(rect, "scale", Vector2.ONE if active else Vector2.ONE * LISTENER_SCALE, 0.22)
	_stage_tween.tween_property(rect, "modulate", Color.WHITE if active else DIM, 0.15)


# --- Porträtt -------------------------------------------------------------------

func _portrait_rect(slot: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.position = slot
	rect.size = PORTRAIT_SIZE
	rect.pivot_offset = Vector2(PORTRAIT_SIZE.x / 2.0, PORTRAIT_SIZE.y)  # Krymper mot fötterna.
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # Porträtten är målade, inte pixlar.
	var fade := ShaderMaterial.new()
	fade.shader = load(PORTRAIT_SHADER)
	fade.set_shader_parameter("fade_from", PORTRAIT_SIZE.y * PORTRAIT_FADE)
	fade.set_shader_parameter("fade_to", PORTRAIT_SIZE.y)
	rect.material = fade
	_root.add_child(rect)
	return rect


func _portrait(character_id: String, expression := "") -> Texture2D:
	var key := character_id
	if expression != "" and PORTRAITS.has(character_id + "_" + expression):
		key = character_id + "_" + expression
	if PORTRAITS.has(key) and ResourceLoader.exists(PORTRAITS[key]):
		var full: Texture2D = load(PORTRAITS[key])
		var atlas := AtlasTexture.new()
		atlas.atlas = full
		var size := full.get_size()
		atlas.region = Rect2(PORTRAIT_REGION.position * size, PORTRAIT_REGION.size * size)
		return atlas
	return _silhouette(GameState.CHARACTERS[character_id]["color"])


## En enkel siluett (huvud och axlar) för karaktärer som saknar porträtt.
func _silhouette(color: Color) -> Texture2D:
	var image := Image.create(210, 280, false, Image.FORMAT_RGBA8)
	var fill := color.darkened(0.35)
	for y in 280:
		for x in 210:
			var head := Vector2((x - 105) / 55.0, (y - 95) / 65.0).length_squared() <= 1.0
			var shoulders := y > 160 and Vector2((x - 105) / 100.0, (y - 300) / 140.0).length_squared() <= 1.0
			if head or shoulders:
				image.set_pixel(x, y, fill)
	return ImageTexture.create_from_image(image)


# --- Ritning --------------------------------------------------------------------

## Tonar ned spelet lätt, och mer mot botten där texten är.
func _draw_shade() -> void:
	var size := _root.size
	_root.draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.25))
	var clear := Color(0, 0, 0, 0)
	var dark := Color(0, 0, 0, 0.45)
	_root.draw_polygon(PackedVector2Array([Vector2(0, 360), Vector2(size.x, 360), Vector2(size.x, size.y), Vector2(0, size.y)]),
			PackedColorArray([clear, clear, dark, dark]))


func _draw_box(canvas: Control) -> void:
	var box := PackedVector2Array(BOX)
	var edge: PackedVector2Array = Geometry2D.offset_polygon(box, BOX_EDGE, Geometry2D.JOIN_MITER)[0]
	var shadow := PackedVector2Array()
	for point in edge:
		shadow.append(point + BOX_SHADOW)
	canvas.draw_colored_polygon(shadow, Color(0, 0, 0, 0.5))
	canvas.draw_colored_polygon(edge, YELLOW)
	canvas.draw_colored_polygon(box, BOX_FILL)
	# Tunn inre linje och det gula hörnet där pilen sitter.
	var inner: PackedVector2Array = Geometry2D.offset_polygon(box, -BOX_INNER, Geometry2D.JOIN_MITER)[0]
	inner.append(inner[0])
	canvas.draw_polyline(inner, Color(YELLOW, 0.22), 1.5, true)
	var bottom_right: Vector2 = BOX[2]
	canvas.draw_colored_polygon(PackedVector2Array([
		bottom_right,
		bottom_right.lerp(BOX[3], CORNER_ALONG_BOTTOM),
		bottom_right.lerp(BOX[1], CORNER_ALONG_RIGHT),
	]), YELLOW)


## Namnskylten: sned gul skylt med skugga, en rand i talarens färg och svart fet text.
## Formen är ritad för en 54 px hög skylt och skalas till PLATE_HEIGHT.
func _draw_plate() -> void:
	var w := _plate.size.x
	var k := PLATE_HEIGHT / 54.0
	var shape := PackedVector2Array([Vector2(0, 4) * k, Vector2(w, -2 * k), Vector2(w - 16 * k, 48 * k), Vector2(-14, 54) * k])
	var shadow := PackedVector2Array()
	for point in shape:
		shadow.append(point + Vector2(6, 6) * k)
	_plate.draw_colored_polygon(shadow, INK)
	_plate.draw_colored_polygon(shape, YELLOW)
	_plate.draw_colored_polygon(PackedVector2Array([Vector2(6, 8) * k, Vector2(20, 7) * k, Vector2(6, 48) * k, Vector2(-8, 49) * k]), _plate_color)
	_plate.draw_string(_plate_font, Vector2(30, 40) * k, _plate_name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, INK)

