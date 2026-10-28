extends SceneTree
# Tillfälligt test av rankkedjan. Tas bort efteråt.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var dm: Node = Engine.get_singleton("DialogueManager")
	gs.current_room = "living_room"
	print("afternoon: '%s'" % Dispatcher.resolve_slot(1, "husband"))
	print("evening husband: '%s'" % Dispatcher.resolve_slot(2, "husband"))
	print("evening son_1: '%s'" % Dispatcher.resolve_slot(2, "son_1"))
	gs.current_room = "kitchen"
	print("evening wrong room: '%s'" % Dispatcher.resolve_slot(2, "husband"))
	gs.current_room = "living_room"
	gs.period = 2
	var before: Dictionary = gs.links["husband"].duplicate()
	var mom_before: float = gs.meters["mom"]

	# Gå igenom dialogfilen som balloonen gör, och välj första svaret.
	var res: Resource = load(Dispatcher.dialogue_path("eric_r1"))
	var line = await dm.get_next_dialogue_line(res, Dispatcher.cue("eric_r1"), [gs])
	var steps := 0
	while line != null and steps < 50:
		print("  [%s] %s  tags=%s" % [line.character, line.text, line.tags])
		if line.tags.has("pose=couch") or line.get_tag_value("pose") != "":
			gs.sprite(gs.get("CHARACTERS").keys()[1] if line.character == "Eric" else "mom", line.get_tag_value("pose"))
		var next_id: String = line.responses[0].next_id if line.responses.size() > 0 else line.next_id
		line = await dm.get_next_dialogue_line(res, next_id, [gs])
		steps += 1

	print("links before %s after %s" % [before, gs.links["husband"]])
	print("mom meter %.1f -> %.1f" % [mom_before, gs.meters["mom"]])
	print("done flag: %s" % gs.has_flag("scene_done_eric_r1"))
	print("replay blocked: '%s'" % Dispatcher.resolve_slot(2, "husband"))
	var stage: Node = gs.get_node_or_null("StoryStage")
	print("stage children: %s" % (stage.get_children().map(func(c): return c.get_class()) if stage else "none"))
	quit()
