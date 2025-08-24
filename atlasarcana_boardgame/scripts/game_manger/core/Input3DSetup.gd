# Input3DSetup.gd - Helper class to set up input actions for 3D systems
extends RefCounted
class_name Input3DSetup

static func setup_3d_input_actions():
	"""Setup all necessary input actions for 3D systems"""
	print("Setting up 3D input actions...")
	
	# Camera movement actions
	_add_action_if_missing("camera_up", [KEY_Q])
	_add_action_if_missing("camera_down", [KEY_E])
	
	# Camera control actions  
	_add_action_if_missing("camera_rotate", [MOUSE_BUTTON_RIGHT])
	_add_action_if_missing("camera_pan", [MOUSE_BUTTON_MIDDLE])
	
	# Camera preset views
	_add_action_if_missing("camera_overview", [KEY_1])
	_add_action_if_missing("camera_close", [KEY_2])
	_add_action_if_missing("camera_side", [KEY_3])
	_add_action_if_missing("camera_top_down", [KEY_4])
	
	# 3D interaction actions
	_add_action_if_missing("focus_on_selection", [KEY_F])
	_add_action_if_missing("reset_camera", [KEY_HOME])
	
	print("3D input actions setup complete!")

static func _add_action_if_missing(action_name: String, inputs: Array):
	"""Add an input action if it doesn't already exist"""
	if InputMap.has_action(action_name):
		print("Input action '", action_name, "' already exists")
		return
	
	InputMap.add_action(action_name)
	
	for input in inputs:
		var event = _create_input_event(input)
		if event:
			InputMap.action_add_event(action_name, event)
			print("Added input action '", action_name, "' with input: ", input)

static func _create_input_event(input) -> InputEvent:
	"""Create an InputEvent from various input types"""
	if input is int:
		# Handle key codes
		if input >= MOUSE_BUTTON_LEFT and input <= MOUSE_BUTTON_XBUTTON2:
			# Mouse button
			var mouse_event = InputEventMouseButton.new()
			mouse_event.button_index = input
			return mouse_event
		else:
			# Keyboard key
			var key_event = InputEventKey.new()
			key_event.keycode = input
			return key_event
	
	return null

static func setup_debug_input_actions():
	"""Setup debug input actions for 3D systems"""
	print("Setting up 3D debug input actions...")
	
	_add_action_if_missing("debug_3d_camera", [KEY_F9])
	_add_action_if_missing("debug_3d_map", [KEY_F10])
	_add_action_if_missing("debug_3d_tiles", [KEY_F11])
	_add_action_if_missing("toggle_3d_wireframe", [KEY_F12])
	
	print("3D debug input actions setup complete!")

static func remove_3d_input_actions():
	"""Remove all 3D input actions (for cleanup)"""
	var actions_to_remove = [
		"camera_up", "camera_down", "camera_rotate", "camera_pan",
		"camera_overview", "camera_close", "camera_side", "camera_top_down",
		"focus_on_selection", "reset_camera",
		"debug_3d_camera", "debug_3d_map", "debug_3d_tiles", "toggle_3d_wireframe"
	]
	
	for action in actions_to_remove:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
			print("Removed input action: ", action)

static func print_current_3d_actions():
	"""Print all current 3D-related input actions (for debugging)"""
	print("=== Current 3D Input Actions ===")
	var all_actions = InputMap.get_actions()
	
	for action in all_actions:
		if "camera" in action or "3d" in action:
			var events = InputMap.action_get_events(action)
			print(action, ": ", events)
	
	print("===============================")
