class_name PhoneIcons
## Telefonens ikoner, ritade i kod i en och samma stil: ett rutnät på 24×24 enheter,
## linjer som är 2 enheter breda med runda ändar och hörn, och samma rundning överallt.
## Appikonerna ritas vita på en rundad platta i appens färg (PhoneTheme.TILE) med en
## svag toning uppifrån. Finns res://Assets/ui/phone/icons/<id>.png används bilden
## i stället, så att ikonerna kan bytas mot målade när spelets stil är bestämd.
## Alla id:n och vad de används till står i docs/phone_ui_spec.md.

const OVERRIDE_DIR := "res://Assets/ui/phone/icons/"
const APP_ICONS := ["phone", "messages", "memories", "journal", "profile", "wallet", "settings"]
const SYSTEM_ICONS := ["signal", "wifi", "battery", "back", "chevron", "play", "lock", "heart", "check", "end_call", "image"]

static var _overrides := {}


## Bilden som ersätter en ikon, eller null.
static func override_texture(id: String) -> Texture2D:
	if not _overrides.has(id):
		var path := OVERRIDE_DIR + id + ".png"
		_overrides[id] = load(path) if ResourceLoader.exists(path) else null
	return _overrides[id]


## En appikon: rundad platta med toning, en tunn ljus kant och symbolen i mitten.
static func draw_tile(c: CanvasItem, app_id: String, rect: Rect2, pressed := false) -> void:
	var texture := override_texture(app_id)
	if texture != null:
		c.draw_texture_rect(texture, rect, false, Color(0.85, 0.85, 0.85) if pressed else Color.WHITE)
		return
	var base: Color = PhoneTheme.TILE.get(app_id, PhoneTheme.MUTED)
	if pressed:
		base = base.darkened(0.12)
	var radius := rect.size.x * PhoneTheme.TILE_RADIUS / PhoneTheme.TILE_SIZE
	var points := rounded_points(rect, radius)
	var colors := PackedColorArray()
	for point in points:
		var t := (point.y - rect.position.y) / rect.size.y
		colors.append(base.lightened(0.16).lerp(base.darkened(0.06), t))
	c.draw_polygon(points, colors)
	# Kantutjämning: polygonen saknar den, så kanten dras en gång till med en mjuk linje.
	var outline := points.duplicate()
	outline.append(points[0])
	c.draw_polyline(outline, base.darkened(0.04), 1.2, true)
	var shine := PackedVector2Array()
	for point in points:
		if point.y < rect.position.y + radius:
			shine.append(point + Vector2(0, 0.8))
	c.draw_polyline(shine, Color(1, 1, 1, 0.35), 1.0, true)
	var glyph := rect.size.x * 0.56
	draw(c, app_id, Rect2(rect.get_center() - Vector2(glyph, glyph) / 2, Vector2(glyph, glyph)), Color.WHITE)


## Ritar en symbol i rect (kvadratisk) i en färg. width är linjebredden i rutnätets
## enheter. fill används av batteriet (0–1).
static func draw(c: CanvasItem, id: String, rect: Rect2, color: Color, width := 2.0, fill := 1.0) -> void:
	var s := rect.size.x / 24.0
	var o := rect.position
	var w := width * s
	var p := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * s
	match id:
		"phone":
			_stroke(c, _handset(p, 0.0), color, w, true)
		"end_call":
			_stroke(c, _handset(p, PI * 0.75), color, w, true)
		"messages":
			var bubble := rounded_points(Rect2(p.call(3, 4), Vector2(18, 13) * s), 5 * s, 6)
			# Svansen läggs in i nederkanten, mellan det högra och det vänstra hörnet.
			var path := PackedVector2Array()
			for i in bubble.size():
				path.append(bubble[i])
				if i == bubble.size() * 3 / 4 - 1:
					path.append(p.call(11, 17))
					path.append(p.call(6.5, 20.8))
			_stroke(c, path, color, w, true)
		"memories", "image":
			if id == "memories":
				# En bild till bakom, så att det ser ut som en hög med foton.
				_stroke(c, PackedVector2Array([p.call(6.5, 2.5), p.call(17.5, 2.5)]), color, w)
			_stroke(c, rounded_points(Rect2(p.call(3, 5.5), Vector2(18, 14.5) * s), 3.5 * s, 4), color, w, true)
			_stroke(c, PackedVector2Array([p.call(4, 18), p.call(9, 12.5), p.call(13, 16.5), p.call(15.5, 14), p.call(20, 18.5)]), color, w)
			c.draw_circle(p.call(15.8, 10), 1.6 * s, color, false, w, true)
		"profile":
			c.draw_circle(p.call(12, 8), 4 * s, color, false, w, true)
			_stroke(c, _arc(p.call(12, 21.5), 7.5 * s, PI, TAU), color, w)
		"wallet":
			# Plånbok: kropp, en sedel som sticker upp bakom och knäppet på sidan.
			_stroke(c, PackedVector2Array([p.call(6, 7), p.call(16, 3.5), p.call(17.5, 7)]), color, w)
			_stroke(c, rounded_points(Rect2(p.call(3, 7), Vector2(18, 13) * s), 3 * s, 4), color, w, true)
			_stroke(c, rounded_points(Rect2(p.call(14, 11), Vector2(7, 5) * s), 2 * s, 3), color, w, true)
			c.draw_circle(p.call(17, 13.5), 1.1 * s, color, true, -1.0, true)
		"journal":
			_stroke(c, rounded_points(Rect2(p.call(5, 3), Vector2(14, 18) * s), 2.5 * s, 4), color, w, true)
			_stroke(c, PackedVector2Array([p.call(8.5, 3.5), p.call(8.5, 20.5)]), color, w)
			_stroke(c, PackedVector2Array([p.call(11.8, 8.5), p.call(15.5, 8.5)]), color, w)
			_stroke(c, PackedVector2Array([p.call(11.8, 12.5), p.call(15.5, 12.5)]), color, w)
		"settings":
			var gear := PackedVector2Array()
			for i in 8:
				var a := TAU * i / 8.0
				for step in [[-0.36, 7.2], [-0.2, 10.0], [0.2, 10.0], [0.36, 7.2]]:
					gear.append(p.call(12, 12) + Vector2.from_angle(a + step[0]) * step[1] * s)
			_stroke(c, gear, color, w * 0.9, true)
			c.draw_circle(p.call(12, 12), 3 * s, color, false, w * 0.9, true)
		"signal":
			for i in 4:
				var h := 4.0 + i * 3.0
				_bar(c, Rect2(p.call(2 + i * 5.5, 20 - h), Vector2(3.6, h) * s), color)
		"wifi":
			for r in [7.5, 12.5]:
				_stroke(c, _arc(p.call(12, 20), r * s, -PI * 0.78, -PI * 0.22), color, w)
			c.draw_circle(p.call(12, 19), 2 * s, color, true, -1.0, true)
		"battery":
			var body := Rect2(p.call(1.5, 7), Vector2(19, 10) * s)
			_stroke(c, rounded_points(body, 3.2 * s, 4), color, w * 0.6, true)
			_stroke(c, PackedVector2Array([p.call(22.5, 10.5), p.call(22.5, 13.5)]), color, w * 0.8)
			var inner := body.grow(-2.2 * s)
			inner.size.x = maxf(inner.size.x * fill, 1.5 * s)
			# Nästan tomt batteri blir rött.
			c.draw_style_box(PhoneTheme.rounded(PhoneTheme.DANGER if fill < 0.25 else color, int(1.5 * s)), inner)
		"back":
			_stroke(c, PackedVector2Array([p.call(15, 4), p.call(7.5, 12), p.call(15, 20)]), color, w)
		"chevron":
			_stroke(c, PackedVector2Array([p.call(9, 5), p.call(16, 12), p.call(9, 19)]), color, w)
		"play":
			var triangle := PackedVector2Array([p.call(8, 5), p.call(8, 19), p.call(19.5, 12)])
			c.draw_colored_polygon(triangle, color)
			_stroke(c, triangle, color, w * 0.8, true)
		"lock":
			_stroke(c, rounded_points(Rect2(p.call(5, 11), Vector2(14, 10) * s), 2.5 * s, 4), color, w, true)
			var shackle := PackedVector2Array([p.call(8, 11)])
			shackle.append_array(_arc(p.call(12, 7.5), 4 * s, PI, TAU))
			shackle.append(p.call(16, 11))
			_stroke(c, shackle, color, w)
		"heart":
			var heart := PackedVector2Array()
			for i in 40:
				var t := TAU * i / 40.0
				var x := 16 * pow(sin(t), 3)
				var y := 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)
				heart.append(p.call(12 + x * 0.55, 11.5 - y * 0.55))
			_stroke(c, heart, color, w, true)
		"check":
			_stroke(c, PackedVector2Array([p.call(5, 12.5), p.call(10, 17.5), p.call(19, 7)]), color, w)


## Punkterna runt en rundad rektangel, medurs från övre vänstra hörnet.
static func rounded_points(rect: Rect2, radius: float, segments := 8) -> PackedVector2Array:
	radius = minf(radius, minf(rect.size.x, rect.size.y) / 2)
	var points := PackedVector2Array()
	var corners := [
		[rect.position + Vector2(radius, radius), PI],
		[Vector2(rect.end.x - radius, rect.position.y + radius), PI * 1.5],
		[rect.end - Vector2(radius, radius), 0.0],
		[Vector2(rect.position.x + radius, rect.end.y - radius), PI * 0.5],
	]
	for corner in corners:
		for i in segments + 1:
			points.append(corner[0] + Vector2.from_angle(corner[1] + PI * 0.5 * i / segments) * radius)
	return points


## En linje med runda ändar och hörn (Godot ritar annars raka ändar).
static func _stroke(c: CanvasItem, points: PackedVector2Array, color: Color, width: float, closed := false) -> void:
	var path := points.duplicate()
	if closed:
		path.append(points[0])
	c.draw_polyline(path, color, width, true)
	for point in path:
		c.draw_circle(point, width / 2, color, true, -1.0, true)


static func _bar(c: CanvasItem, rect: Rect2, color: Color) -> void:
	c.draw_style_box(PhoneTheme.rounded(color, int(rect.size.x / 2)), rect)


static func _arc(center: Vector2, radius: float, from: float, to: float, segments := 14) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments + 1:
		points.append(center + Vector2.from_angle(lerpf(from, to, float(i) / segments)) * radius)
	return points


## Telefonluren som en sluten kontur, vriden angle radianer runt mitten.
static func _handset(p: Callable, angle: float) -> PackedVector2Array:
	var outline := [Vector2(5.5, 3), Vector2(9, 3), Vector2(10.5, 7.5), Vector2(8.3, 9.4), Vector2(14.6, 15.7), Vector2(16.5, 13.5), Vector2(21, 15), Vector2(21, 18.5), Vector2(18.5, 21)]
	# Lurens rygg: en mjuk båge tillbaka till början.
	for i in range(1, 9):
		var t := i / 9.0
		outline.append((Vector2(18.5, 21) * (1 - t) * (1 - t)) + Vector2(4.5, 19.5) * 2 * (1 - t) * t + Vector2(3, 5.5) * t * t)
	outline.append(Vector2(3, 5.5))
	var points := PackedVector2Array()
	for point in outline:
		var turned: Vector2 = Vector2(12, 12) + (point - Vector2(12, 12)).rotated(angle)
		points.append(p.call(turned.x, turned.y))
	return points
