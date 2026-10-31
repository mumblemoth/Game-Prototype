class_name KitBackdrop
extends Control
## Bakgrunden bakom kitets skärmar: svart (eller genomskinligt svart över spelet) med
## fina diagonala ränder som glider långsamt, och ett brett gult snedband med en röd
## linje bredvid. reveal (0–1) låter bandet svepa in från vänster när skärmen öppnas.

## Helt svart (titelskärmen, dagens slut) eller genomskinligt över spelet (pausmenyn).
var solid := true
## Var bandets mitt ligger, som andel av bredden.
var band_center := 0.18
var band_width := 340.0
var reveal := 1.0:
	set(value):
		reveal = value
		queue_redraw()
var _time := 0.0


func _init(p_solid := true, p_band_center := 0.18, p_band_width := 340.0) -> void:
	solid = p_solid
	band_center = p_band_center
	band_width = p_band_width
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## Bandet sveper in (anropas när skärmen öppnas).
func sweep_in(duration := UiKit.SLOW) -> void:
	reveal = 0.0
	create_tween().tween_property(self, "reveal", 1.0, UiKit.t(duration)).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if not UiKit.reduced_motion:
		_time += delta
		queue_redraw()


func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), UiKit.INK if solid else Color(UiKit.INK, 0.9 * reveal))
	# Ränderna.
	var spacing := 22.0
	var lean := s.y * 0.5
	var stripe := Color(1, 1, 1, 0.035 * (1.0 if solid else reveal))
	var x := -lean - spacing + fmod(_time * 10.0, spacing)
	while x < s.x + spacing:
		draw_line(Vector2(x, s.y), Vector2(x + lean, 0), stripe, 7.0)
		x += spacing
	# Bandet glider in från vänster kant.
	var band_lean := s.y * 0.32
	var left := s.x * band_center - band_width / 2
	var off := (1.0 - reveal) * -(left + band_width + band_lean + 40)
	var thin := PackedVector2Array([
		Vector2(left - 46 + band_lean + off, 0), Vector2(left - 22 + band_lean + off, 0),
		Vector2(left - 22 + off, s.y), Vector2(left - 46 + off, s.y)])
	draw_colored_polygon(thin, UiKit.YELLOW_DARK)
	var band := PackedVector2Array([
		Vector2(left + band_lean + off, 0), Vector2(left + band_width + band_lean + off, 0),
		Vector2(left + band_width + off, s.y), Vector2(left + off, s.y)])
	draw_colored_polygon(band, UiKit.YELLOW)
	draw_line(band[1] + Vector2(16, 0), band[2] + Vector2(16, 0), UiKit.RED, 5.0, true)
