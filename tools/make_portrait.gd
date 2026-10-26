extends SceneTree
## Gör ett frilagt dialogporträtt av en karaktärsbild med ljus, jämn bakgrund (som
## Anima-bilderna): tar bort bakgrunden genom flödesfyllning från kanterna och beskär
## till överkroppen.
##
##   godot --headless --path . -s res://tools/make_portrait.gd -- <källbild> <utfil> [andel av höjden] [x,y ...]
## x,y är extra startpunkter för bakgrund som inte når kanten, i andelar av bilden.
## Exempel:
##   ... -- res://Assets/2026-10-24_21-17-30-anima-base-v1.0-1490281203.png res://Assets/portraits/mom.png 0.62

## Porträttens höjd i pixlar efter nedskalning.
const HEIGHT := 1100


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var source := Image.load_from_file(ProjectSettings.globalize_path(args[0]))
	var keep := float(args[2]) if args.size() > 2 else 0.6
	source.convert(Image.FORMAT_RGBA8)
	var scale_factor := HEIGHT / (source.get_height() * keep)
	source.resize(roundi(source.get_width() * scale_factor), roundi(source.get_height() * scale_factor), Image.INTERPOLATE_LANCZOS)
	# Extra startpunkter för bakgrund som kanterna inte når (t.ex. mellan benen eller
	# en skugga på golvet), som "x,y" i andelar av bilden.
	var seeds: Array[Vector2i] = []
	for i in range(3, args.size()):
		var parts := args[i].split(",")
		seeds.append(Vector2i(int(float(parts[0]) * source.get_width()), int(float(parts[1]) * source.get_height())))
	_remove_background(source, seeds)
	var crop := source.get_region(Rect2i(0, 0, source.get_width(), mini(HEIGHT, source.get_height())))
	var used := crop.get_used_rect()
	crop = crop.get_region(Rect2i(used.position.x, used.position.y, used.size.x, crop.get_height() - used.position.y))
	var out := ProjectSettings.globalize_path(args[1])
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	crop.save_png(out)
	print("sparad ", out, " ", crop.get_size())
	quit()


func _remove_background(img: Image, seeds: Array[Vector2i] = []) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var reference := img.get_pixel(2, 2)
	var visited := PackedByteArray()
	visited.resize(w * h)
	var queue: Array[Vector2i] = []
	for x in w:
		queue.append(Vector2i(x, 0))
	for y in h:
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(w - 1, y))
	# Nederkanten bara där det är bakgrund (figuren fortsätter ofta ut genom botten).
	for x in w:
		if _dist(img.get_pixel(x, h - 1), reference) < 0.4:
			queue.append(Vector2i(x, h - 1))
	queue.append_array(seeds)
	for p in queue:
		visited[p.y * w + p.x] = 1
	var i := 0
	while i < queue.size():
		var p := queue[i]
		i += 1
		var c := img.get_pixelv(p)
		img.set_pixelv(p, Color(0, 0, 0, 0))
		for n in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = p + n
			if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or visited[q.y * w + q.x]:
				continue
			var qc := img.get_pixelv(q)
			# Bakgrunden kan ha ett ljust sken bakom figuren, därför den generösa gränsen
			# mot referensfärgen; konturerna runt figuren stoppar fyllningen.
			if _dist(qc, c) < 0.06 and _dist(qc, reference) < 0.9:
				visited[q.y * w + q.x] = 1
				queue.append(q)
	# Mjuka upp kanten: halvgenomskinliga pixlar där figuren möter bakgrunden.
	var copy: Image = img.duplicate()
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if copy.get_pixel(x, y).a == 0:
				continue
			var empty := 0
			for n in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if copy.get_pixel(x + n.x, y + n.y).a == 0:
					empty += 1
			if empty > 0:
				var c := copy.get_pixel(x, y)
				c.a = 1.0 - empty * 0.2
				img.set_pixel(x, y, c)


func _dist(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
