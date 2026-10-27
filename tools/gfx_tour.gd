extends Node
## Rundtur för grafikgranskning: det som ui_preview inte visar. Varje våning, kvällen
## och natten, en plats ute, kartan, telefonen och dialogrutan i en scen. Körs med:
##   Godot --path . res://tools/gfx_tour.tscn -- <mapp för bilderna>

var _out := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("gfx_tour")
	DirAccess.make_dir_recursive_absolute(_out)
	var house: Node = load("res://scenes/main.tscn").instantiate()
	add_child(house)
	await get_tree().create_timer(1.0).timeout
	for i in 4:
		if GameState.playing_scene != "":
			GameState.finish_scene()
		await get_tree().create_timer(0.5).timeout
	await _snap("t01_ground", 2.0)
	for floor_name in ["Övervåning", "Vind", "Källare", "Utanför"]:
		house._show_floor(floor_name)
		await _snap("t02_floor_" + PlanDrawer.FLOOR_LABELS[floor_name].to_snake_case(), 1.5)
	house._show_floor("Entréplan")
	house._map.open()
	await _snap("t03_map", 1.2)
	house._map.close_map()
	await get_tree().create_timer(0.6).timeout
	house._phone.open()
	await _snap("t04_phone", 1.2)
	house._phone.close()
	await get_tree().create_timer(0.6).timeout
	var manager: Node = Engine.get_singleton("DialogueManager")
	manager.show_dialogue_balloon_scene(GameState.STORY_BALLOON, load("res://dialogue/husband/eric_r1.dialogue"), "start")
	await _snap("t05_dialogue", 2.0)
	GameState.rank_card("husband", 2)
	await _snap("t05b_rank_card", 0.6)
	for node in get_tree().root.find_children("*", "StoryBalloon", true, false):
		node.queue_free()
	GameState._stage().clear()
	await get_tree().create_timer(0.5).timeout
	house._dialog.play([{"speaker": "mom", "text": "Hey, Miles. Got a minute?"}, {"speaker": "son_1", "text": "Hi!"}])
	await _snap("t05c_dialog_box", 1.0)
	house._dialog.hide()
	GameState._set_period(2)
	await _snap("t06_evening", 3.0)
	GameState._set_period(3)
	await _snap("t07_night", 3.0)
	GameState._set_period(1)
	await get_tree().create_timer(2.0).timeout
	GameState.travel_to_location("fitness")
	await _snap("t08_gym", 3.0)
	print("gfx_tour: done -> ", _out)
	get_tree().quit()


func _snap(file_name: String, wait: float) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join("%s.png" % file_name))
