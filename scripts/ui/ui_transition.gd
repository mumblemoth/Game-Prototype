class_name UiTransition
extends CanvasLayer
## Kitets övergångar, ovanpå allt annat och även när spelet är pausat:
##   wipe()   – sneda gula och svarta band sveper in från vänster och täcker skärmen,
##              något byts medan den är täckt (scen, dag), och banden sveper ut åt höger.
##              En rubrik (t.ex. "Tuesday") kan stå i mittbandet medan den är täckt.
##   banner() – en sned svart skylt med stor gul text glider genom skärmen (tidszonen).
## Båda lägger sig själva under trädets rot, så att de överlever ett scenbyte.

const BANDS := 7
## Hur mycket varje band väntar på det förra (andel av svepet).
const STAGGER := 0.09

var _canvas: Control
## 0 = inget, 1 = täckt, 2 = har svept ut.
var _progress := 0.0
var _caption := ""
## Skyltens svep (0 = utanför vänster, 1 = på plats, 2 = utanför höger).
var _banner_at := 0.0
var _title := ""
var _kicker := ""


## Täcker skärmen, anropar covered och visar skärmen igen.
static func wipe(from: Node, covered: Callable, caption := "") -> void:
	var transition := UiTransition.new()
	transition._caption = caption.to_upper()
	from.get_tree().root.add_child(transition)
	transition._run_wipe(covered)


## En skylt som glider genom skärmen: title stort, kicker i en liten ljus platta.
static func banner(from: Node, title: String, kicker := "") -> void:
	var transition := UiTransition.new()
	transition.layer = 90
	transition._title = title.to_upper()
	transition._kicker = kicker.to_upper()
	from.get_tree().root.add_child(transition)
	transition._run_banner()


func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_canvas)


func _run_wipe(covered: Callable) -> void:
	# Klick når inte spelet medan banden rör sig.
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_draw_wipe)
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, UiKit.t(0.34)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(covered)
	tween.tween_interval(UiKit.t(0.55 if _caption != "" else 0.12))
	tween.tween_method(_set_progress, 1.0, 2.0, UiKit.t(0.36)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func _run_banner() -> void:
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_banner)
	var tween := create_tween()
	tween.tween_method(_set_banner, 0.0, 1.0, UiKit.t(0.28)).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.1)
	tween.tween_method(_set_banner, 1.0, 2.0, UiKit.t(0.3)).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func _set_progress(value: float) -> void:
	_progress = value
	_canvas.queue_redraw()


func _set_banner(value: float) -> void:
	_banner_at = value
	_canvas.queue_redraw()


func _draw_wipe() -> void:
	var s := _canvas.size
	var height := s.y / BANDS
	var lean := height * 0.7
	var spread := 1.0 + STAGGER * (BANDS - 1)
	for i in BANDS:
		# Varje band har sin egen del av svepet, lite efter bandet ovanför.
		var local := _progress if _progress <= 1.0 else _progress - 1.0
		var phase := clampf(local * spread - STAGGER * i, 0.0, 1.0)
		var left := -lean
		var right := s.x + lean
		if _progress <= 1.0:
			right = lerpf(-lean, s.x + lean, phase)
		else:
			left = lerpf(-lean, s.x + lean, phase)
		if right - left <= 1.0:
			continue
		var top := i * height - 1
		var bottom := (i + 1) * height + 1
		var points := PackedVector2Array([Vector2(left + lean, top), Vector2(right, top), Vector2(right - lean, bottom), Vector2(left, bottom)])
		_canvas.draw_colored_polygon(points, UiKit.INK if i % 2 == 1 else UiKit.YELLOW)
		# En röd kant leder svepet.
		var edge := Vector2(right, top) if _progress <= 1.0 else Vector2(left + lean, top)
		_canvas.draw_line(edge, edge + Vector2(-lean, bottom - top), UiKit.RED, 4.0, true)
	if _caption != "":
		var alpha := clampf(1.0 - absf(_progress - 1.0) * 5.0, 0.0, 1.0)
		if alpha > 0.0:
			var font := UiKit.display_font()
			var middle := BANDS / 2
			var y := middle * height + UiKit.baseline(font, UiKit.DISPLAY, height)
			UiKit.draw_display(_canvas, Vector2(0, y), _caption, UiKit.DISPLAY, Color(UiKit.YELLOW, alpha), Color(UiKit.RED, alpha), HORIZONTAL_ALIGNMENT_CENTER, s.x)


func _draw_banner() -> void:
	var s := _canvas.size
	var rect := Rect2(0, 250, s.x, 120)
	var lean := rect.size.y * 0.5
	# Skylten glider in från vänster och vidare ut åt höger.
	var shift := (_banner_at - 1.0) * (s.x + lean * 2)
	var plate := PackedVector2Array([
		Vector2(rect.position.x - lean + shift, rect.position.y), Vector2(rect.end.x + lean + shift, rect.position.y),
		Vector2(rect.end.x + shift, rect.end.y), Vector2(rect.position.x - lean * 2 + shift, rect.end.y)])
	var shadow := plate.duplicate()
	for i in shadow.size():
		shadow[i] += Vector2(0, 10)
	_canvas.draw_colored_polygon(shadow, UiKit.YELLOW)
	_canvas.draw_colored_polygon(plate, Color(UiKit.INK, 0.95))
	# Texten släpar efter skylten lite, så att den känns snabb.
	var text_shift := (_banner_at - 1.0) * s.x * 0.6
	var font := UiKit.display_font()
	UiKit.draw_display(_canvas, Vector2(text_shift, rect.position.y + UiKit.baseline(font, UiKit.DISPLAY + 12, rect.size.y)), _title, UiKit.DISPLAY + 12, UiKit.YELLOW, UiKit.RED, HORIZONTAL_ALIGNMENT_CENTER, s.x)
	if _kicker != "":
		var body := UiKit.body_font(true)
		var width := body.get_string_size(_kicker, HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.SMALL).x + 36
		var kicker_rect := Rect2(s.x / 2 - width / 2 - text_shift * 0.4, rect.position.y - 18, width, 30)
		UiKit.draw_slant(_canvas, kicker_rect, UiKit.PAPER)
		_canvas.draw_string(body, kicker_rect.position + Vector2(18, UiKit.baseline(body, UiKit.SMALL, 30)), _kicker, HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.SMALL, UiKit.INK)
