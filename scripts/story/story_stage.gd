class_name StoryStage extends CanvasLayer
## Scenens scen: figurerna bakom dialogrutan och rank-upp-kortet. GameState skapar den
## första gången en dialogfil anropar sprite() eller rank_card(), och tömmer den när
## dialogen är slut.
##
## Figurer läses från res://Assets/characters/<char>/<pose>_<mood>.png, och annars
## <pose>.png. Saknas båda ritas en platshållare: en ruta i personens färg
## (GameState.CHARACTERS) med initialerna på.

const SPRITE_PATH := "res://Assets/characters/%s/%s.png"
const MOOD_SPRITE_PATH := "res://Assets/characters/%s/%s_%s.png"
## Uttrycket en figur har innan dialogen sagt något annat.
const DEFAULT_MOOD := "neutral"
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
## Platskortets överkant; det står mitt på skärmen så att det inte täcker HUD:ens plattor.
const LOCATION_TOP := 20.0
const LOCATION_PADDING := 14
const LOCATION_FONT_SIZE := 22
const LOCATION_HOLD := 2.5
## Platshållarens ram och skugga, i UI-kitets stil (inramad vinjett).
const FRAME_WIDTH := 4
const FRAME_SHADOW := Vector2(8, 8)

## char_id -> figurens nod, i den ordning de kom in.
var _sprites := {}
## char_id -> posen figuren står i.
var _poses := {}
## char_id -> uttrycket. Kan finnas för en figur som inte står på scenen än.
var _moods := {}
## Platskortet som visas just nu, så att ett nytt ersätter det.
var _location_card: Control


func _ready() -> void:
	layer = LAYER


## Visar personen eller byter pose. Nya figurer ställer sig till höger om de som redan står.
func show_sprite(char_id: String, pose: String) -> void:
	_poses[char_id] = pose
	if _sprites.has(char_id):
		_sprites[char_id].queue_free()
	var node := _make_sprite(char_id, pose, _moods.get(char_id, DEFAULT_MOOD))
	add_child(node)
	_sprites[char_id] = node
	_arrange()


## Byter uttryck. Står figuren på scenen ritas den om i samma pose och på samma plats.
func show_mood(char_id: String, mood_id: String) -> void:
	_moods[char_id] = mood_id
	if _sprites.has(char_id):
		show_sprite(char_id, _poses[char_id])


## Platskortet: tonar in överst i mitten, står en stund och tonar ut.
func show_location(text: String) -> void:
	if is_instance_valid(_location_card):
		_location_card.queue_free()
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.plate(UiKit.INK, UiKit.SLANT, Color(0, 0, 0, 0), 0, UiKit.RED, Vector2(LOCATION_PADDING * 2, LOCATION_PADDING * 0.5)))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UiKit.display(text.to_upper(), LOCATION_FONT_SIZE, UiKit.YELLOW, Color(0, 0, 0, 0))
	card.add_child(label)
	add_child(card)
	card.reset_size()
	card.position = Vector2(roundf((_screen().x - card.size.x) / 2.0), LOCATION_TOP)
	card.modulate.a = 0.0
	_location_card = card
	var tween := card.create_tween()
	tween.tween_property(card, "modulate:a", 1.0, CARD_FADE)
	tween.tween_interval(LOCATION_HOLD)
	tween.tween_property(card, "modulate:a", 0.0, CARD_FADE)
	tween.tween_callback(card.queue_free)


## Rank-upp-kortet: tonar in överst, står en stund och tonar ut.
func show_rank_card(char_id: String, rank: int) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.plate(UiKit.INK, UiKit.SLANT, UiKit.YELLOW, 3, UiKit.RED))
	card.custom_minimum_size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 0)
	card.add_child(column)
	var person := UiKit.label(GameState.character_name(char_id).to_upper(), UiKit.SMALL, (GameState.CHARACTERS[char_id]["color"] as Color).lightened(0.35), true)
	person.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(person)
	var label := UiKit.display("Rank %d" % rank, CARD_FONT_SIZE)
	label.uppercase = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)
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
	_poses.clear()
	_moods.clear()
	if is_instance_valid(_location_card):
		_location_card.queue_free()


func _make_sprite(char_id: String, pose: String, mood_id: String) -> Control:
	var path := MOOD_SPRITE_PATH % [char_id, pose, mood_id]
	if not ResourceLoader.exists(path):
		path = SPRITE_PATH % [char_id, pose]
	if ResourceLoader.exists(path):
		var picture := TextureRect.new()
		picture.texture = load(path)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.size = SPRITE_SIZE
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return picture
	# Platshållaren är en inramad vinjett: personens färg i en ljus ram med svart kant och
	# hård skugga, initialerna i kitets rubriktypsnitt och namnet på en platta.
	var color: Color = GameState.CHARACTERS[char_id]["color"]
	var box := PanelContainer.new()
	var style := UiKit.plate(color.darkened(0.25), 0.0, UiKit.PAPER, FRAME_WIDTH, Color(UiKit.INK, 0.85), Vector2.ZERO)
	style.shadow_offset = FRAME_SHADOW
	box.add_theme_stylebox_override("panel", style)
	box.size = SPRITE_SIZE
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(column)
	var initials := UiKit.display(GameState.character_initials(char_id), INITIALS_FONT_SIZE, color.lightened(0.6), UiKit.INK)
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(initials)
	var name_plate := UiKit.label(GameState.character_name(char_id).to_upper(), UiKit.BODY, UiKit.INK, true)
	name_plate.add_theme_stylebox_override("normal", UiKit.plate(UiKit.PAPER, UiKit.SLANT, Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), Vector2(16, 2)))
	name_plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(name_plate)
	# Pose och uttryck syns under namnet så att man ser att taggarna kom fram.
	var pose_label := UiKit.label("%s · %s" % [pose, mood_id], POSE_FONT_SIZE - 4, Color(UiKit.PAPER, 0.75))
	pose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(pose_label)
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
