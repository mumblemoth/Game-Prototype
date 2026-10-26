class_name StoryStage extends CanvasLayer
## Scenens scen: figurerna bakom dialogrutan och rank-upp-kortet. GameState skapar den
## första gången en dialogfil anropar sprite() eller rank_card(), och tömmer den när
## dialogen är slut.
##
## Figurer läses från res://Assets/characters/<char>/<pose>.png. Saknas bilden ritas en
## platshållare: en ruta i personens färg (GameState.CHARACTERS) med initialerna på.

const SPRITE_PATH := "res://Assets/characters/%s/%s.png"
## Under dialogrutan (StoryBalloon har layer 100).
const LAYER := 90
const SPRITE_SIZE := Vector2(300, 520)
## Avståndet från skärmens nederkant upp till figurernas fötter.
const SPRITE_BOTTOM := 40.0
const INITIALS_FONT_SIZE := 96
const POSE_FONT_SIZE := 18
const CARD_SIZE := Vector2(420, 120)
const CARD_TOP := 80.0
const CARD_FONT_SIZE := 34
const CARD_FADE := 0.3
const CARD_HOLD := 2.0

## char_id -> figurens nod, i den ordning de kom in.
var _sprites := {}


func _ready() -> void:
	layer = LAYER


## Visar personen eller byter pose. Nya figurer ställer sig till höger om de som redan står.
func show_sprite(char_id: String, pose: String) -> void:
	if _sprites.has(char_id):
		_sprites[char_id].queue_free()
	var node := _make_sprite(char_id, pose)
	add_child(node)
	_sprites[char_id] = node
	_arrange()


## Rank-upp-kortet: tonar in överst, står en stund och tonar ut.
func show_rank_card(char_id: String, rank: int) -> void:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = GameState.CHARACTERS[char_id]["color"]
	style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = "%s\nRank %d" % [GameState.character_name(char_id), rank]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", CARD_FONT_SIZE)
	card.add_child(label)
	add_child(card)
	card.position = Vector2((_screen().x - CARD_SIZE.x) / 2.0, CARD_TOP)
	card.modulate.a = 0.0
	var tween := card.create_tween()
	tween.tween_property(card, "modulate:a", 1.0, CARD_FADE)
	tween.tween_interval(CARD_HOLD)
	tween.tween_property(card, "modulate:a", 0.0, CARD_FADE)
	tween.tween_callback(card.queue_free)


func clear() -> void:
	for node in _sprites.values():
		node.queue_free()
	_sprites.clear()


func _make_sprite(char_id: String, pose: String) -> Control:
	var path := SPRITE_PATH % [char_id, pose]
	if ResourceLoader.exists(path):
		var picture := TextureRect.new()
		picture.texture = load(path)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.size = SPRITE_SIZE
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return picture
	var box := ColorRect.new()
	box.color = GameState.CHARACTERS[char_id]["color"]
	box.size = SPRITE_SIZE
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var initials := Label.new()
	initials.text = GameState.CHARACTERS[char_id]["initials"]
	initials.set_anchors_preset(Control.PRESET_FULL_RECT)
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initials.add_theme_font_size_override("font_size", INITIALS_FONT_SIZE)
	box.add_child(initials)
	# Posen syns längst ned så att man ser att taggen kom fram.
	var pose_label := Label.new()
	pose_label.text = pose
	pose_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	pose_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pose_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pose_label.add_theme_font_size_override("font_size", POSE_FONT_SIZE)
	box.add_child(pose_label)
	return box


## Sprider figurerna jämnt över skärmens bredd.
func _arrange() -> void:
	var screen := _screen()
	var count := _sprites.size()
	var i := 0
	for node in _sprites.values():
		var center := screen.x * (i + 1) / (count + 1)
		node.position = Vector2(center - SPRITE_SIZE.x / 2.0, screen.y - SPRITE_BOTTOM - SPRITE_SIZE.y)
		i += 1


func _screen() -> Vector2:
	return get_viewport().get_visible_rect().size
