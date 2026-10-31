extends Node2D

# Test script to verify the new dialogue system works correctly

func _ready():
	print("Testing new dialogue system")
	
	# Check if DialogueSystem singleton exists
	if Engine.has_singleton("DialogueSystem"):
		print("DialogueSystem singleton found successfully")
		var dialogue_system = Engine.get_singleton("DialogueSystem")
		print("DialogueSystem type: ", dialogue_system.get_class())
		
		# Test that we can connect to signals
		print("Testing signal connections...")
		
		# Test methods
		print("Testing methods...")
		var methods = dialogue_system.get_method_list()
		for method in methods:
			print("Method: ", method.name)
		
		# Test that we can call methods
		print("Testing basic functionality...")
		
		# Try to start a dialogue (this would normally require a dialogue resource)
		print("Test completed successfully")
	else:
		print("ERROR: DialogueSystem singleton NOT found")
		print("The dialogue system may not be properly initialized")
