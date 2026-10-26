class_name TimeTransition
extends CanvasLayer
## Övergångarna när tiden går, ovanpå spelet. En ny dag: skärmen tonar ned i kitets
## svarta (natten), dygnet byts medan den är mörk (våningen byggs om och ljuset hoppar
## till morgonen utan att synas), gryningen färgar skärmen medan veckodagen står i
## kitets stora gula text med dagens nummer på en ljus platta, och sedan tonar den nya
## dagen fram. Under dagen: ett kort, mjukt dis i den nya tidszonens färg medan ljuset i
## huset glider över (TimeOfDayRig). Själva spelläget byts direkt; det här är bara bilden.
## Tiderna följer inställningen Motion (UiKit.t).

signal finished

const NIGHT := UiKit.INK
const DAWN := Color("4a2a33")
const FADE_OUT := 0.9
const FADE_IN := 1.1
const CARD_HOLD := 1.4
## Hur mörkt diset blir när tidszonen byts under dagen.
const WASH_ALPHA := 0.32

var _shade: ColorRect
## Dagens kort (veckodag och nummer), ritat med kitets satser.
var _card: Control
var _weekday := ""
var _kicker := ""
## Kortet glider upp en bit när det tonar fram (0 = på plats).
var _rise := 0.0
var _tween: Tween
var _wash: Tween
var _playing := false


func _ready() -> void:
	layer = 7
	_shade = ColorRect.new()
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.color = NIGHT
	_shade.modulate.a = 0.0
	# Klick under kortet snabbar på övergången.
	_shade.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and _tween and _tween.is_running():
			_tween.set_speed_scale(3.0))
	add_child(_shade)
	_card = Control.new()
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.modulate.a = 0.0
	_card.draw.connect(_draw_card)
	add_child(_card)
	GameState.time_of_day_changed.connect(_on_time_of_day_changed)


func _draw_card() -> void:
	var s := _card.size
	var y := s.y * 0.42 + _rise
	UiKit.draw_display(_card, Vector2(0, y), _weekday, UiKit.HERO, UiKit.YELLOW, UiKit.RED, HORIZONTAL_ALIGNMENT_CENTER, s.x)
	var body := UiKit.body_font(true)
	var width := body.get_string_size(_kicker, HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.HEADING).x + 44
	var plate := Rect2(s.x / 2 - width / 2, y + 30, width, 38)
	UiKit.draw_slant(_card, Rect2(plate.position + UiKit.SHADOW * 0.6, plate.size), UiKit.RED)
	UiKit.draw_slant(_card, plate, UiKit.PAPER)
	_card.draw_string(body, plate.position + Vector2(22, UiKit.baseline(body, UiKit.HEADING, plate.size.y)), _kicker, HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.HEADING, UiKit.INK)


func _set_rise(value: float) -> void:
	_rise = value
	_card.queue_redraw()


## Om en dagsövergång pågår (då väntar tidszonens skylt och pausmenyn).
func is_playing() -> bool:
	return _playing


## Övergången till en ny dag. `change` körs när skärmen är helt mörk och ska byta dygnet
## (GameState.start_next_day och det som hör till).
func play_new_day(change: Callable) -> void:
	if _playing:
		return
	_playing = true
	if _wash:
		_wash.kill()
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_shade.color = NIGHT
	_card.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_shade, "modulate:a", 1.0, UiKit.t(FADE_OUT)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func() -> void:
		change.call()
		_weekday = GameState.get_weekday().to_upper()
		_kicker = ("Day %d" % GameState.day).to_upper())
	# Gryningen: natten ljusnar och dagens namn stiger fram.
	_tween.tween_property(_shade, "color", DAWN, UiKit.t(CARD_HOLD + 0.5)).set_trans(Tween.TRANS_SINE)
	_tween.parallel().tween_property(_card, "modulate:a", 1.0, UiKit.t(0.5)).set_trans(Tween.TRANS_SINE)
	_tween.parallel().tween_method(_set_rise, UiKit.travel(Vector2(0, 18)).y, 0.0, UiKit.t(0.7)).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_card, "modulate:a", 0.0, UiKit.t(0.4))
	_tween.tween_property(_shade, "modulate:a", 0.0, UiKit.t(FADE_IN)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func() -> void:
		_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_playing = false
		finished.emit())


## Tangenter (t.ex. nästa replik i en morgonscen) väntar tills den nya dagen syns.
func _input(event: InputEvent) -> void:
	if _playing and event is InputEventKey:
		get_viewport().set_input_as_handled()


## Under dagen: ett kort dis i den nya tidszonens färg, i takt med att ljuset glider över.
func _on_time_of_day_changed(period: String) -> void:
	if _playing or not period in GameState.PLAYABLE_PERIODS:
		return
	if _wash:
		_wash.kill()
	_shade.color = (TimeOfDayRig.PERIODS[period]["background"] as Color).darkened(0.55)
	_wash = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_wash.tween_property(_shade, "modulate:a", WASH_ALPHA, TimeOfDayRig.BLEND_SECONDS * 0.4)
	_wash.tween_property(_shade, "modulate:a", 0.0, TimeOfDayRig.BLEND_SECONDS * 0.6)
