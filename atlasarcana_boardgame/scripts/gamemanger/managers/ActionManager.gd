# ActionModeManager.gd (Fixed)
extends Node
class_name ActionModeManager

# Signals
signal mode_changed(new_mode)
signal action_validation_failed(message: String)

# Reference to UI components
var bottom_bar: BottomBarUI
var notification_manager: NotificationManager

func _ready():
	# Enable input processing for ESC key
	set_process_input(true)

func _input(event: InputEvent):
	"""Handle global input events"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			handle_escape_key()

func initialize(bottom_bar_ref: BottomBarUI, notification_ref: NotificationManager):
	"""Initialize with references to other UI components"""
	bottom_bar = bottom_bar_ref
	notification_manager = notification_ref
	
	print("✅ ActionModeManager initialized with BottomBarUI and NotificationManager")
	
	# The action_button_pressed signal connection is now handled in GameUI
	# Connect to GameManager if it has mode-related signals
	if GameManager.has_signal("mode_changed"):
		GameManager.mode_changed.connect(_on_gamemanager_mode_changed)

func _on_action_button_pressed(action_type: String):
	"""Handle action button presses"""
	print("Action button pressed: ", action_type)
	
	# Validate if action can be performed
	if not can_perform_action():
		var message = "No action points remaining! End your turn to refresh."
		action_validation_failed.emit(message)
		if notification_manager:
			notification_manager.show_error(message)
		return
	
	# Handle the specific action
	match action_type:
		"move":
			handle_move_action()
		"build":
			handle_build_action()
		"attack":
			handle_attack_action()
		"interact":
			handle_interact_action()
		_:
			print("Unknown action type: ", action_type)

func handle_move_action():
	"""Handle move button press with toggle functionality"""
	var current_mode = GameManager.get_current_action_mode()
	
	if current_mode == GameManager.action_controller.ActionMode.MOVEMENT:
		# Already in movement mode, toggle it off
		GameManager.action_controller.end_movement_mode()
		print("Movement mode ended (toggled off)")
	else:
		# Start movement mode
		GameManager.action_controller.start_movement_mode()
		print("Movement mode started")

func handle_build_action():
	"""Handle build button press with toggle functionality"""
	var current_mode = GameManager.get_current_action_mode()
	
	if current_mode == GameManager.action_controller.ActionMode.BUILD:
		# Already in build mode, toggle it off
		GameManager.end_build_mode()
		print("Build mode ended (toggled off)")
	else:
		# Start build mode
		GameManager.start_build_mode()
		print("Build mode started")

func handle_attack_action():
	"""Handle attack button press with toggle functionality"""
	var current_mode = GameManager.get_current_action_mode()
	
	if current_mode == GameManager.ActionMode.ATTACK:
		# Already in attack mode, toggle it off
		GameManager.end_all_action_modes()
		print("Attack mode ended (toggled off)")
	else:
		# Start attack mode
		GameManager.start_attack_mode()
		print("Attack mode started")

func handle_interact_action():
	"""Handle interact button press with toggle functionality"""
	var current_mode = GameManager.get_current_action_mode()
	
	if current_mode == GameManager.ActionMode.INTERACT:
		# Already in interact mode, toggle it off
		GameManager.end_all_action_modes()
		print("Interact mode ended (toggled off)")
	else:
		# Start interact mode
		GameManager.start_interact_mode()
		print("Interact mode started")

func handle_escape_key():
	"""Handle ESC key press to cancel current mode"""
	var current_mode = GameManager.get_current_action_mode()
	
	if current_mode != GameManager.ActionMode.NONE:
		GameManager.end_all_action_modes()
		print("All action modes cancelled via ESC key")
		
		if notification_manager:
			notification_manager.show_notification("Action cancelled", 2.0, Color.YELLOW)

func can_perform_action() -> bool:
	"""Check if the player can perform an action"""
	return GameManager.get_current_action_points() > 0

func update_button_states(active_mode):
	"""Update button visual states based on active mode"""
	if bottom_bar:
		bottom_bar.update_button_states(active_mode)
	
	# Emit signal for other components that might need to know
	mode_changed.emit(active_mode)

func _on_gamemanager_mode_changed(new_mode):
	"""Handle mode changes from GameManager"""
	update_button_states(new_mode)

# Public interface methods
func force_end_all_modes():
	"""Force end all action modes (for external use)"""
	GameManager.end_all_action_modes()

func get_current_mode():
	"""Get the current action mode"""
	return GameManager.get_current_action_mode()

func is_mode_active() -> bool:
	"""Check if any action mode is currently active"""
	return GameManager.get_current_action_mode() != GameManager.ActionMode.NONE

# Validation methods
func can_start_movement() -> bool:
	"""Check if movement can be started"""
	return can_perform_action() and not is_mode_active()

func can_start_build() -> bool:
	"""Check if building can be started"""
	return can_perform_action() and not is_mode_active()

func can_start_attack() -> bool:
	"""Check if attack can be started"""
	return can_perform_action() and not is_mode_active()

func can_start_interact() -> bool:
	"""Check if interact can be started"""
	return can_perform_action() and not is_mode_active()

# Event handlers for specific game events
func update_button_availability():
	"""Update button visual states based on action points"""
	if bottom_bar:
		bottom_bar.update_action_buttons_availability(GameManager.get_current_action_points())

# Connect this to action points changes
func _on_action_points_changed(new_amount: int):
	"""Handle action points changing"""
	update_button_availability()
	
	if new_amount <= 0:
		if notification_manager:
			notification_manager.show_info("No action points remaining. End your turn to refresh.")

func _on_turn_advanced():
	"""Handle turn advancement"""
	# All modes should be ended when turn advances
	# This is typically handled by GameManager, but we can add additional logic here if needed
	print("Turn advanced - action modes will be reset")

# Debug methods
func debug_print_state():
	"""Print current state for debugging"""
	print("=== ActionModeManager State ===")
	print("Current mode: ", GameManager.get_current_action_mode())
	print("Action points: ", GameManager.get_current_action_points())
	print("Can perform action: ", can_perform_action())
	print("==============================")
