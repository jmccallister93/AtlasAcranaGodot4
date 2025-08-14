# UIBridge.gd
extends Node
class_name UIBridge

var game_ui: GameUI
var confirmation_controller: ConfirmationController
var managers: ManagerRegistry

func initialize(manager_registry: ManagerRegistry):
	"""Initialize the UI bridge with manager registry"""
	managers = manager_registry
	confirmation_controller = ConfirmationController.new()
	add_child(confirmation_controller)

# ═══════════════════════════════════════════════════════════
# GAME UI REGISTRATION
# ═══════════════════════════════════════════════════════════

func register_game_ui(ui: GameUI):
	"""Register the game UI instance"""
	game_ui = ui
	print("UIBridge: GameUI registered")

func unregister_game_ui():
	"""Unregister the game UI instance"""
	game_ui = null
	print("UIBridge: GameUI unregistered")

# ═══════════════════════════════════════════════════════════
# ACTION BUTTON STATE MANAGEMENT
# ═══════════════════════════════════════════════════════════

func update_action_button_states(current_action_mode):
	"""Update action button states in the UI"""
	if game_ui:
		game_ui.update_action_button_states(current_action_mode)

# ═══════════════════════════════════════════════════════════
# CONFIRMATION DIALOGS
# ═══════════════════════════════════════════════════════════

func show_movement_confirmation(target_tile: BiomeTile):
	"""Show movement confirmation dialog"""
	if game_ui:
		game_ui.show_movement_confirmation(target_tile)
		confirmation_controller.register_pending_confirmation("movement", {
			"tile": target_tile,
			"position": target_tile.grid_position
		})
	else:
		print("UIBridge: No GameUI - auto-confirming movement")
		_auto_confirm_movement()

func show_build_confirmation(target_tile: BiomeTile, building_type: String):
	"""Show build confirmation dialog"""
	if game_ui:
		game_ui.show_build_confirmation(target_tile, building_type)
		confirmation_controller.register_pending_confirmation("build", {
			"tile": target_tile,
			"position": target_tile.grid_position,
			"building_type": building_type
		})
	else:
		print("UIBridge: No GameUI - auto-confirming building")
		_auto_confirm_building()

func show_attack_confirmation(target_tile: BiomeTile):
	"""Show attack confirmation dialog"""
	if game_ui:
		game_ui.show_attack_confirmation(target_tile)
		confirmation_controller.register_pending_confirmation("attack", {
			"tile": target_tile,
			"position": target_tile.grid_position
		})
	else:
		print("UIBridge: No GameUI - auto-confirming attack")
		_auto_confirm_attack()

func show_interact_confirmation(target_tile: BiomeTile, interaction_name: String):
	"""Show interact confirmation dialog"""
	if game_ui:
		game_ui.show_interact_confirmation(target_tile, interaction_name)
		confirmation_controller.register_pending_confirmation("interact", {
			"tile": target_tile,
			"position": target_tile.grid_position,
			"interaction_name": interaction_name
		})
	else:
		print("UIBridge: No GameUI - auto-confirming interaction")
		_auto_confirm_interaction()

# ═══════════════════════════════════════════════════════════
# CONFIRMATION HANDLING - Called by GameUI
# ═══════════════════════════════════════════════════════════

func confirm_movement(target_position: Vector2i):
	"""Confirm and execute movement"""
	print("UIBridge: Movement confirmed to: ", target_position)
	if managers.movement_manager:
		managers.movement_manager.confirm_movement()
	confirmation_controller.clear_confirmation("movement")

func confirm_building(target_position: Vector2i, building_type: String):
	"""Confirm and execute building placement"""
	print("UIBridge: Building confirmed: ", building_type, " at ", target_position)
	if managers.build_manager:
		managers.build_manager.confirm_building()
	confirmation_controller.clear_confirmation("build")

func confirm_attack(target_position: Vector2i):
	"""Confirm and execute attack"""
	print("UIBridge: Attack confirmed at: ", target_position)
	if managers.attack_manager:
		managers.attack_manager.confirm_attack()
	confirmation_controller.clear_confirmation("attack")

func confirm_interaction(target_position: Vector2i, interaction_type: String):
	"""Confirm and execute interaction"""
	print("UIBridge: Interaction confirmed: ", interaction_type, " at ", target_position)
	if managers.interact_manager:
		managers.interact_manager.confirm_interaction()
	confirmation_controller.clear_confirmation("interact")

# ═══════════════════════════════════════════════════════════
# AUTO-CONFIRMATION FALLBACKS
# ═══════════════════════════════════════════════════════════

func _auto_confirm_movement():
	"""Auto-confirm movement when no UI is available"""
	if managers.movement_manager:
		managers.movement_manager.confirm_movement()

func _auto_confirm_building():
	"""Auto-confirm building when no UI is available"""
	if managers.build_manager:
		managers.build_manager.confirm_building()

func _auto_confirm_attack():
	"""Auto-confirm attack when no UI is available"""
	if managers.attack_manager:
		managers.attack_manager.confirm_attack()

func _auto_confirm_interaction():
	"""Auto-confirm interaction when no UI is available"""
	if managers.interact_manager:
		managers.interact_manager.confirm_interaction()

# ═══════════════════════════════════════════════════════════
# NOTIFICATION MESSAGES
# ═══════════════════════════════════════════════════════════

func show_error(message: String):
	"""Show error message to user"""
	if game_ui:
		game_ui.show_error(message)
	else:
		print("ERROR: " + message)

func show_success(message: String):
	"""Show success message to user"""
	if game_ui:
		game_ui.show_success(message)
	else:
		print("SUCCESS: " + message)

func show_info(message: String):
	"""Show info message to user"""
	if game_ui:
		game_ui.show_info(message)
	else:
		print("INFO: " + message)

# ═══════════════════════════════════════════════════════════
# RESOURCE DISPLAY UPDATES
# ═══════════════════════════════════════════════════════════

func update_resource(resource_name: String, new_amount: int):
	"""Update resource display in UI"""
	if game_ui:
		game_ui.update_resource(resource_name, new_amount)

# ═══════════════════════════════════════════════════════════
# BUILDING SYSTEM UI UPDATES
# ═══════════════════════════════════════════════════════════

func show_building_detail(building: Building):
	"""Show building detail view for a specific building"""
	if game_ui:
		game_ui.show_building_detail(building)
	else:
		print("UIBridge: GameUI not available for building detail")

func show_building_type_detail(building_type_name: String):
	"""Show building detail view for a building type"""
	if game_ui:
		game_ui.show_building_type_detail(building_type_name)
	else:
		print("UIBridge: GameUI not available for building type detail")

func on_building_data_changed():
	"""Handle building data changes"""
	if game_ui:
		game_ui._on_building_data_changed()

# ═══════════════════════════════════════════════════════════
# GAME STATE QUERIES FOR UI
# ═══════════════════════════════════════════════════════════

func get_current_action_points() -> int:
	"""Get current action points for UI display"""
	if managers.character:
		return managers.character.current_action_points
	return 0

func get_resource_amount(resource_name: String) -> int:
	"""Get resource amount for UI display"""
	if managers.resource_manager:
		return managers.resource_manager.get_resource(resource_name)
	return 0

func get_all_resources() -> Dictionary:
	"""Get all resources for UI display"""
	if managers.resource_manager:
		return managers.resource_manager.get_all_resources()
	return {}

# ═══════════════════════════════════════════════════════════
# UI STATE VALIDATION
# ═══════════════════════════════════════════════════════════

func is_ui_available() -> bool:
	"""Check if GameUI is available"""
	return game_ui != null

func can_show_confirmations() -> bool:
	"""Check if confirmation dialogs can be shown"""
	return game_ui != null

# ═══════════════════════════════════════════════════════════
# DEBUG METHODS
# ═══════════════════════════════════════════════════════════

func debug_ui_state():
	"""Debug current UI state"""
	print("UIBridge Debug:")
	print("  GameUI available: ", is_ui_available())
	print("  Confirmation controller: ", confirmation_controller != null)
	print("  Managers available: ", managers != null)
	
	if confirmation_controller:
		print("  Pending confirmations: ", confirmation_controller.get_pending_count())
