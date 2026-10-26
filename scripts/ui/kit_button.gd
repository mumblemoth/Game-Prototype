class_name KitButton
extends Button
## Knappen i UI-kitet: en sned platta med lutande versaler. Muspekaren eller fokus låter
## en gul platta svepa in från vänster medan texten blir svart och knuffas åt höger, med
## en röd hård skugga bakom; ett tryck ger en kort stöt. Tre utseenden:
##   "menu"   – stora listval (titelskärmen, pausmenyn, rummens menyer)
##   "tab"    – kompakta flikar och växlar; gula när de är valda (button_pressed/selected)
##   "action" – gula knappar för det viktigaste valet i en panel
## title är texten och note en mindre text till höger (taggar, antal, värde, eller varför
## valet inte går). Hela knappen ritas här; Buttons egna text och rutor används inte.

const PAD := 18.0
const SIZES := {"menu": UiKit.MENU, "tab": UiKit.SMALL + 1, "action": UiKit.BODY + 2}
## Höjden är textstorleken plus det här.
const EXTRA_HEIGHT := {"menu": 24, "tab": 20, "action": 26}

var title := "":
	set(value):
		title = value
		_fit()
		queue_redraw()
var note := "":
	set(value):
		note = value
		_fit()
		queue_redraw()
var variant := "menu"
var font_size := 0
## Lyser som det aktuella valet (t.ex. sidan som är öppen) även utan fokus.
var selected := false:
	set(value):
		selected = value
		_update_hot()
		queue_redraw()

var _hot := 0.0:
	set(value):
		_hot = value
		queue_redraw()
var _punch := 0.0:
	set(value):
		_punch = value
		queue_redraw()
var _enter := 1.0:
	set(value):
		_enter = value
		self_modulate.a = value
		queue_redraw()
var _hot_tween: Tween


func _init(p_title := "", p_note := "", p_variant := "menu", p_font_size := 0) -> void:
	variant = p_variant
	font_size = p_font_size if p_font_size > 0 else SIZES[variant]
	custom_minimum_size.y = font_size + EXTRA_HEIGHT[variant]
	title = p_title
	note = p_note
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_update_hot)
	focus_entered.connect(_update_hot)
	focus_exited.connect(_update_hot)
	toggled.connect(func(_on: bool) -> void:
		_update_hot()
		queue_redraw())
	pressed.connect(punch)


## Glider in från vänster efter delay (listor som byggs upp ett val i taget).
func appear(delay := 0.0) -> void:
	_enter = 0.0
	var tween := create_tween()
	tween.tween_property(self, "_enter", 1.0, UiKit.t(UiKit.MID)).set_delay(delay).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)


## Den korta stöten när knappen trycks.
func punch() -> void:
	if not is_inside_tree():
		return
	_punch = 1.0
	create_tween().tween_property(self, "_punch", 0.0, UiKit.t(0.24)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_mouse_entered() -> void:
	# Musen flyttar fokus, så att bara ett val lyser åt gången (som med tangenterna).
	if not disabled and focus_mode != Control.FOCUS_NONE:
		grab_focus()
	_update_hot()


func _is_on() -> bool:
	return selected or (toggle_mode and button_pressed)


func _is_lit() -> bool:
	if disabled:
		return false
	return has_focus() or is_hovered() or (variant != "tab" and _is_on())


func _update_hot() -> void:
	var target := 1.0 if _is_lit() else 0.0
	if _hot_tween:
		_hot_tween.kill()
	if not is_inside_tree():
		_hot = target
		return
	_hot_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hot_tween.tween_property(self, "_hot", target, UiKit.t(UiKit.FAST))


## Flikar och knappar är så breda som texten; listval så breda som sin kolumn.
func _fit() -> void:
	if variant == "menu" or font_size == 0:
		return
	var width := UiKit.display_font().get_string_size(title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if note != "":
		width += UiKit.body_font(true).get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, _note_size()).x + 14
	custom_minimum_size.x = ceilf(width + PAD * 2 + custom_minimum_size.y * UiKit.SLANT)


func _note_size() -> int:
	return maxi(UiKit.TINY, int(font_size * 0.55))


func _draw() -> void:
	var s := size
	var lean := s.y * UiKit.SLANT
	var grow := 1.0 + 0.05 * _punch
	var shift := UiKit.travel(Vector2(-60.0 * (1.0 - _enter), 0))
	draw_set_transform(shift + s / 2 * (1.0 - grow), 0.0, Vector2(grow, grow))
	var rect := Rect2(Vector2.ZERO, s)
	var on := _is_on()
	var title_color: Color
	var note_color: Color
	match variant:
		"menu":
			if _hot > 0.0:
				UiKit.draw_slant(self, Rect2(UiKit.SHADOW * _hot, s), Color(UiKit.RED, _hot))
			UiKit.draw_slant(self, rect, Color(UiKit.INK, 0.55 if disabled else 0.9))
			if _hot > 0.0:
				UiKit.draw_slant(self, Rect2(Vector2.ZERO, Vector2(lerpf(lean + 1.0, s.x, _hot), s.y)), UiKit.YELLOW)
			title_color = UiKit.MUTED if disabled else UiKit.PAPER.lerp(UiKit.INK, _hot)
			note_color = UiKit.RED.lightened(0.3) if disabled else UiKit.YELLOW.lerp(UiKit.INK, _hot)
		"tab":
			if _hot > 0.0 and not on:
				UiKit.draw_slant(self, Rect2(Vector2(4, 4) * _hot, s), Color(UiKit.RED, _hot))
			UiKit.draw_slant(self, rect, UiKit.YELLOW if on else Color(UiKit.INK, 0.5 if disabled else 0.9))
			if not on:
				UiKit.draw_slant_outline(self, rect, Color(UiKit.PAPER, 0.25).lerp(UiKit.YELLOW, _hot))
			title_color = UiKit.INK if on else (UiKit.MUTED if disabled else UiKit.PAPER.lerp(UiKit.YELLOW, _hot))
			note_color = Color(title_color, 0.75)
		_:
			if _hot > 0.0:
				UiKit.draw_slant(self, Rect2(UiKit.SHADOW * _hot, s), Color(UiKit.RED, _hot))
			UiKit.draw_slant(self, rect, UiKit.INK_2 if disabled else UiKit.YELLOW.lerp(UiKit.PAPER, _hot))
			title_color = UiKit.MUTED if disabled else UiKit.INK
			note_color = Color(title_color, 0.7)
	var font := UiKit.display_font()
	var text := title.to_upper()
	var y := UiKit.baseline(font, font_size, s.y)
	var note_width := 0.0
	if note != "":
		var note_font := UiKit.body_font(true)
		note_width = note_font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, _note_size()).x
		var right := s.x - lean * 0.5 - PAD
		draw_string(note_font, Vector2(right - note_width, UiKit.baseline(note_font, _note_size(), s.y)), note, HORIZONTAL_ALIGNMENT_LEFT, -1, _note_size(), note_color)
	if variant == "menu":
		draw_string(font, Vector2(lean + PAD + 10.0 * _hot, y), text, HORIZONTAL_ALIGNMENT_LEFT, s.x - lean - PAD * 2 - note_width - 10, font_size, title_color)
	else:
		var x := lean * 0.5 + PAD
		draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, title_color)
