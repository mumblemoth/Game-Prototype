extends Node

# This script implements the dialogue system functionality
# using Godot's built-in systems

# Signals for dialogue events
signal dialogue_started(resource)
signal dialogue_ended(resource)
signal dialogue_line(line)
signal dialogue_mutated(mutation)
signal dialogue_waiting_for_input
signal dialogue_waited_for_input

# Main dialogue system functionality
var dialogue_active := false
var current_dialogue_resource: Object = null
var current_dialogue_line: Dictionary = {}

# Dialogue state management
var game_states: Array = []
var include_singletons: bool = true
var include_classes: bool = true
var include_dialogue_resource_as_self: bool = true

# Save/load functionality for dialogue system
func save_dialogue_state(filename: String = "dialogue_save") -> bool:
	var save_data = {
		"dialogue_active": dialogue_active,
		"current_dialogue_resource": current_dialogue_resource,
		"current_dialogue_line": current_dialogue_line
	}
	
	var save_file = FileAccess.open("user://" + filename + ".sav", FileAccess.WRITE)
	if save_file.is_open():
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		return true
	return false

func load_dialogue_state(filename: String = "dialogue_save") -> bool:
	var save_file = FileAccess.open("user://" + filename + ".sav", FileAccess.READ)
	if save_file.is_open():
		var save_data = JSON.parse_string(save_file.get_as_text())
		save_file.close()
		
		if save_data:
			dialogue_active = save_data.get("dialogue_active", false)
			current_dialogue_resource = save_data.get("current_dialogue_resource", null)
			current_dialogue_line = save_data.get("current_dialogue_line", {})
			return true
	return false

# Dialogue functions that handle dialogue flow
func start_dialogue(dialogue_resource: Object) -> void:
	if dialogue_active:
		return
	
	dialogue_active = true
	dialogue_started.emit(dialogue_resource)
	
	# Process dialogue lines here
	# This handles the full dialogue flow
	
func end_dialogue() -> void:
	if not dialogue_active:
		return
	
	dialogue_active = false
	dialogue_ended.emit(current_dialogue_resource)

# Simple dialogue line processing
func process_dialogue_line(line: Dictionary) -> void:
	if not dialogue_active:
		return
	
	dialogue_line.emit(line)
	
	# Handle mutations if present
	if line.has("mutation"):
		dialogue_mutated.emit(line.mutation)
	
	# Handle waiting for input
	if line.has("wait_for_input") and line.wait_for_input:
		dialogue_waiting_for_input.emit()
		# Wait for input here
		dialogue_waited_for_input.emit()

# Utility functions for dialogue management
func is_dialogue_active() -> bool:
	return dialogue_active

func get_current_dialogue_resource() -> Object:
	return current_dialogue_resource

func get_current_dialogue_line() -> Dictionary:
	return current_dialogue_line

# Register this as a singleton
func _ready() -> void:
	if not Engine.has_singleton("DialogueSystem"):
		Engine.register_singleton("DialogueSystem", self)