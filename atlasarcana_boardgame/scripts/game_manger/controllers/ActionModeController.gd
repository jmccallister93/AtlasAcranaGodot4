# ActionModeController.gd
extends Node
class_name ActionModeController

signal action_mode_changed(new_mode: ActionMode)

enum ActionMode {
	NONE,
	MOVEMENT,
	BUILD,
	ATTACK,
	INTERACT
}

var current_action_mode: ActionMode = ActionMode.NONE
var managers: ManagerRegistry
var ui_bridge: UIBridge
var character: Character

func initialize(manager_registry: ManagerRegistry, ui_bridge_ref: UIBridge):
	"""Initialize the action mode controller with dependencies"""
	managers = manager_registry
	ui_bridge = ui_bridge_ref
	character = managers.get_character()

# ═══════════════════════════════════════════════════════════
# ACTION MODE VALIDATION
# ═══════════════════════════════════════════════════════════

func can_start_action_mode() -> bool:
	"""Check if player has enough action points to start an action"""
	return character and character.current_action_points > 0

func show_no_action_points_notification():
	"""Show notification when player tries to act without action points"""
	if ui_bridge:
		ui_bridge.show_error("No action points remaining! End your turn to refresh.")

# ═══════════════════════════════════════════════════════════
# ACTION MODE MANAGEMENT
# ═══════════════════════════════════════════════════════════

func end_all_action_modes():
	"""End all active action modes"""
	match current_action_mode:
		ActionMode.MOVEMENT:
			managers.movement_manager.end_movement_mode()
			print("Ended movement mode")
		ActionMode.BUILD:
			managers.build_manager.end_build_mode()
			print("Ended build mode")
		ActionMode.ATTACK:
			managers.attack_manager.end_attack_mode()
			print("Ended attack mode")
		ActionMode.INTERACT:
			managers.interact_manager.end_interact_mode()
			print("Ended interact mode")
		ActionMode.NONE:
			pass  # No mode to end
	
	_set_action_mode(ActionMode.NONE)

func start_movement_mode():
	"""Handle move button press from UI"""
	print("Move action requested from UI")
	
	if not _validate_action_start():
		return
	
	_end_other_modes_if_needed(ActionMode.MOVEMENT)
	_set_action_mode(ActionMode.MOVEMENT)
	managers.movement_manager.start_movement_mode()

func start_build_mode():
	"""Handle build button press from UI"""
	print("Build action requested from UI")
	
	if not _validate_action_start():
		return
	
	_end_other_modes_if_needed(ActionMode.BUILD)
	_set_action_mode(ActionMode.BUILD)
	managers.build_manager.start_build_mode()

func start_attack_mode():
	"""Handle attack button press from UI"""
	print("Attack action requested from UI")
	
	if not _validate_action_start():
		return
	
	_end_other_modes_if_needed(ActionMode.ATTACK)
	_set_action_mode(ActionMode.ATTACK)
	managers.attack_manager.start_attack_mode()

func start_interact_mode():
	"""Handle interact button press from UI"""
	print("Interact action requested from UI")
	
	if not _validate_action_start():
		return
	
	_end_other_modes_if_needed(ActionMode.INTERACT)
	_set_action_mode(ActionMode.INTERACT)
	managers.interact_manager.start_interact_mode()

# ═══════════════════════════════════════════════════════════
# INDIVIDUAL MODE ENDING
# ═══════════════════════════════════════════════════════════

func end_movement_mode():
	"""Handle movement mode end"""
	if current_action_mode == ActionMode.MOVEMENT:
		managers.movement_manager.end_movement_mode()
		_set_action_mode(ActionMode.NONE)

func end_build_mode():
	"""Handle build mode end"""
	if current_action_mode == ActionMode.BUILD:
		managers.build_manager.end_build_mode()
		_set_action_mode(ActionMode.NONE)

func end_attack_mode():
	"""Handle attack mode end"""
	if current_action_mode == ActionMode.ATTACK:
		managers.attack_manager.end_attack_mode()
		_set_action_mode(ActionMode.NONE)

func end_interact_mode():
	"""Handle interact mode end"""
	if current_action_mode == ActionMode.INTERACT:
		managers.interact_manager.end_interact_mode()
		_set_action_mode(ActionMode.NONE)

# ═══════════════════════════════════════════════════════════
# CLICK ROUTING
# ═══════════════════════════════════════════════════════════

func handle_map_click(target_grid_pos: Vector2i):
	"""Route map clicks to appropriate manager based on current mode"""
	match current_action_mode:
		ActionMode.MOVEMENT:
			managers.movement_manager.attempt_move_to(target_grid_pos)
		ActionMode.BUILD:
			managers.build_manager.attempt_build_at(target_grid_pos)
		ActionMode.ATTACK:
			managers.attack_manager.attempt_attack_at(target_grid_pos)
		ActionMode.INTERACT:
			managers.interact_manager.attempt_interact_at(target_grid_pos)
		_:
			# No active mode, ignore click
			print("Map clicked but no action mode active")

# ═══════════════════════════════════════════════════════════
# ACTION COMPLETION HANDLING
# ═══════════════════════════════════════════════════════════

func on_action_completed(action_type: ActionMode):
	"""Handle when an action completes successfully"""
	match action_type:
		ActionMode.MOVEMENT:
			end_movement_mode()
		ActionMode.BUILD:
			end_build_mode()
		ActionMode.ATTACK:
			end_attack_mode()
		ActionMode.INTERACT:
			end_interact_mode()

# ═══════════════════════════════════════════════════════════
# GETTERS & STATE QUERIES
# ═══════════════════════════════════════════════════════════

func get_current_action_mode() -> ActionMode:
	"""Get the currently active action mode"""
	return current_action_mode

func is_mode_active(mode: ActionMode) -> bool:
	"""Check if a specific mode is currently active"""
	return current_action_mode == mode

func is_any_mode_active() -> bool:
	"""Check if any action mode is currently active"""
	return current_action_mode != ActionMode.NONE

# ═══════════════════════════════════════════════════════════
# PRIVATE HELPER METHODS
# ═══════════════════════════════════════════════════════════

func _validate_action_start() -> bool:
	"""Validate that an action can be started"""
	if not can_start_action_mode():
		show_no_action_points_notification()
		return false
	return true

func _end_other_modes_if_needed(new_mode: ActionMode):
	"""End other action modes if switching to a different one"""
	if current_action_mode != new_mode and current_action_mode != ActionMode.NONE:
		end_all_action_modes()

func _set_action_mode(new_mode: ActionMode):
	"""Set the action mode and update UI"""
	current_action_mode = new_mode
	action_mode_changed.emit(new_mode)
	
	# Update UI button states
	if ui_bridge:
		ui_bridge.update_action_button_states(current_action_mode)

func _on_turn_advanced():
	"""Handle turn advancement - end all action modes"""
	end_all_action_modes()
