# GameManager.gd - Simplified and Modular
extends Node

# Core game components
var game_state: GameState
var manager_registry: ManagerRegistry
var action_controller: ActionModeController
var ui_bridge: UIBridge
var event_bus: GameEventBus

var camera_controller: ExpeditionCamera


# Quick access to common components
var character: Character
var turn_manager: TurnManager

func _ready():
	"""Initialize the game"""
	start_new_game()

# ═══════════════════════════════════════════════════════════
# GAME LIFECYCLE
# ═══════════════════════════════════════════════════════════

func start_new_game():
	"""Initialize a new game with all components"""
	# Create core game state
	game_state = GameState.new()
	
	# Initialize component systems
	_initialize_manager_registry()
	_initialize_camera_controller() 
	_initialize_action_controller()
	_initialize_ui_bridge()
	_initialize_event_bus()
	
	# Set up quick access references
	character = manager_registry.get_character()
	turn_manager = manager_registry.get_turn_manager()
	
func _initialize_manager_registry():
	"""Initialize the manager registry and all game managers"""
	manager_registry = ManagerRegistry.new()
	add_child(manager_registry)
	manager_registry.initialize_all_managers()

func _initialize_camera_controller():
	"""Initialize the camera controller programmatically"""
	camera_controller = ExpeditionCamera.new()
	add_child(camera_controller)
	
	# Set camera bounds to match map size
	var map_manager = manager_registry.get_map_manager()
	if map_manager:
		var map_bounds = map_manager.get_world_bounds()
		camera_controller.set_bounds(map_bounds)
		print("Camera bounds set to: ", map_bounds)
	
	# Start at center of map instead of origin
	if map_manager:
		var center = Vector2(map_manager.map_width * map_manager.tile_size / 2, 
							map_manager.map_height * map_manager.tile_size / 2)
		camera_controller.set_camera_position(center)
	else:
		camera_controller.set_camera_position(Vector2.ZERO)

func _initialize_action_controller():
	"""Initialize the action mode controller"""
	action_controller = ActionModeController.new()
	add_child(action_controller)
	

func _initialize_ui_bridge():
	"""Initialize the UI bridge"""
	ui_bridge = UIBridge.new()
	add_child(ui_bridge)
	ui_bridge.initialize(manager_registry)
	
	# Now we can initialize action controller with UI bridge
	action_controller.initialize(manager_registry, ui_bridge)

func _initialize_event_bus():
	"""Initialize the event bus to handle all game events"""
	event_bus = GameEventBus.new()
	add_child(event_bus)
	event_bus.initialize(manager_registry, action_controller, ui_bridge)

# ═══════════════════════════════════════════════════════════
# UI REGISTRATION (Called by GameUI)
# ═══════════════════════════════════════════════════════════

func register_game_ui(ui: GameUI):
	"""Register the game UI with the system"""
	if ui_bridge:
		ui_bridge.register_game_ui(ui)
		print("GameManager: GameUI registered successfully")
	else:
		print("GameManager: Warning - UIBridge not available for UI registration")

func unregister_game_ui():
	"""Unregister the game UI"""
	if ui_bridge:
		ui_bridge.unregister_game_ui()
		print("GameManager: GameUI unregistered")

# ═══════════════════════════════════════════════════════════
# ACTION MODE MANAGEMENT (UI Interface)
# ═══════════════════════════════════════════════════════════

func start_movement_mode():
	"""Start movement action mode"""
	if action_controller:
		action_controller.start_movement_mode()

func start_build_mode():
	"""Start build action mode"""
	if action_controller:
		action_controller.start_build_mode()

func start_attack_mode():
	"""Start attack action mode"""
	if action_controller:
		action_controller.start_attack_mode()

func start_interact_mode():
	"""Start interact action mode"""
	if action_controller:
		action_controller.start_interact_mode()

func end_all_action_modes():
	"""End all active action modes"""
	if action_controller:
		action_controller.end_all_action_modes()

func get_current_action_mode():
	"""Get the current action mode"""
	if action_controller:
		return action_controller.get_current_action_mode()
	return ActionModeController.ActionMode.NONE

# ═══════════════════════════════════════════════════════════
# CONFIRMATION HANDLING (Called by GameUI)
# ═══════════════════════════════════════════════════════════

func confirm_movement(target_position: Vector2i):
	"""Confirm movement action"""
	if ui_bridge:
		ui_bridge.confirm_movement(target_position)

func confirm_building(target_position: Vector2i, building_type: String):
	"""Confirm building placement"""
	if ui_bridge:
		ui_bridge.confirm_building(target_position, building_type)

func confirm_attack(target_position: Vector2i):
	"""Confirm attack action"""
	if ui_bridge:
		ui_bridge.confirm_attack(target_position)

func confirm_interaction(target_position: Vector2i, interaction_type: String):
	"""Confirm interaction action"""
	if ui_bridge:
		ui_bridge.confirm_interaction(target_position, interaction_type)

# ═══════════════════════════════════════════════════════════
# TURN MANAGEMENT
# ═══════════════════════════════════════════════════════════

func advance_turn():
	"""Advance to the next turn"""
	if turn_manager:
		turn_manager.advance_turn()
		game_state.current_turn += 1
		print("GameManager: Advanced to turn ", game_state.current_turn)

func get_current_turn() -> int:
	"""Get the current turn number"""
	return game_state.current_turn if game_state else 1

# ═══════════════════════════════════════════════════════════
# RESOURCE MANAGEMENT (Public API)
# ═══════════════════════════════════════════════════════════

func add_resource(resource_name: String, amount: int):
	"""Add resources"""
	if manager_registry:
		manager_registry.add_resource(resource_name, amount)
		if game_state:
			game_state.add_resource(resource_name, amount)

func spend_resource(resource_name: String, amount: int) -> bool:
	"""Spend a single resource"""
	if manager_registry:
		var success = manager_registry.spend_resource(resource_name, amount)
		if success and game_state:
			game_state.spend_resource(resource_name, amount)
		return success
	return false

func spend_resources(cost: Dictionary) -> bool:
	"""Spend multiple resources"""
	if manager_registry:
		var success = manager_registry.spend_resources(cost)
		if success and game_state:
			for resource_name in cost:
				game_state.spend_resource(resource_name, cost[resource_name])
		return success
	return false

func has_resource(resource_name: String, amount: int) -> bool:
	"""Check if player has enough of a resource"""
	if manager_registry:
		return manager_registry.has_resource(resource_name, amount)
	return false

func can_afford(cost: Dictionary) -> bool:
	"""Check if player can afford a cost"""
	if manager_registry:
		return manager_registry.can_afford(cost)
	return false

func get_resource(resource_name: String) -> int:
	"""Get current amount of a resource"""
	if manager_registry:
		return manager_registry.get_resource(resource_name)
	return 0

func get_all_resources() -> Dictionary:
	"""Get all current resources"""
	if manager_registry:
		return manager_registry.get_all_resources()
	return {}

func set_resource(resource_name: String, amount: int):
	"""Set a resource to a specific amount"""
	if manager_registry:
		manager_registry.set_resource(resource_name, amount)
		if game_state:
			game_state.set_resource(resource_name, amount)

# ═══════════════════════════════════════════════════════════
# ACTION POINTS MANAGEMENT
# ═══════════════════════════════════════════════════════════

func spend_action_points(amount: int = 1) -> bool:
	"""Spend action points"""
	if character:
		var success = character.spend_action_points(amount)
		if success and game_state:
			game_state.spend_action_points(amount)
		return success
	return false

func get_current_action_points() -> int:
	"""Get current action points"""
	if character:
		return character.current_action_points
	return 0

# ═══════════════════════════════════════════════════════════
# INVENTORY MANAGEMENT (Public API)
# ═══════════════════════════════════════════════════════════

func add_item_to_inventory(item: BaseItem, amount: int = 1) -> bool:
	"""Add items to inventory"""
	if manager_registry:
		return manager_registry.add_item_to_inventory(item, amount)
	return false

func remove_item_from_inventory(item_id: String, amount: int = 1) -> int:
	"""Remove items from inventory"""
	if manager_registry:
		return manager_registry.remove_item_from_inventory(item_id, amount)
	return 0

func has_item_in_inventory(item_id: String, amount: int = 1) -> bool:
	"""Check if player has an item in inventory"""
	if manager_registry:
		return manager_registry.has_item_in_inventory(item_id, amount)
	return false

# ═══════════════════════════════════════════════════════════
# BUILDING SYSTEM (Public API)
# ═══════════════════════════════════════════════════════════

func show_building_detail(building: Building):
	"""Show building detail view"""
	if ui_bridge:
		ui_bridge.show_building_detail(building)

func show_building_type_detail(building_type_name: String):
	"""Show building type detail view"""
	if ui_bridge:
		ui_bridge.show_building_type_detail(building_type_name)

# ═══════════════════════════════════════════════════════════
# WARBAND MANAGEMENT (Public API)
# ═══════════════════════════════════════════════════════════

func get_warband_manager() -> WarbandManager:
	"""Get the warband manager"""
	if manager_registry:
		return manager_registry.get_warband_manager()
	return null

# ═══════════════════════════════════════════════════════════
# SAVE/LOAD SYSTEM
# ═══════════════════════════════════════════════════════════

func save_game(file_path: String) -> bool:
	"""Save the current game state"""
	if game_state:
		return game_state.save_to_file(file_path)
	return false

func load_game(file_path: String) -> bool:
	"""Load a game state from file"""
	if game_state:
		var success = game_state.load_from_file(file_path)
		if success:
			_sync_managers_with_game_state()
		return success
	return false

func _sync_managers_with_game_state():
	"""Synchronize manager states with loaded game state"""
	# This would involve updating managers with loaded state data
	# Implementation depends on how managers handle state restoration
	pass
