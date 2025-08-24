# GameManager.gd 
extends Node

# Core game components
var game_state: GameState
var manager_registry: ManagerRegistry
var action_controller: ActionModeController
var ui_bridge: UIBridge
var event_bus: GameEventBus

var camera_controller: ExpeditionCamera3D
var mouse_raycaster: MouseRaycaster3D

# Quick access to common components
var character: Character
var turn_manager: TurnManager

var combat_manager: CombatManager

var map_generator: ExpeditionMapGenerator


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
	
	# Setup 3D input actions first
	_setup_3d_input_system()
	
	# Initialize component systems
	_initialize_manager_registry()
	_initialize_camera_controller() 
	_initialize_action_controller()
	_initialize_ui_bridge()
	_initialize_event_bus()
	_initialize_map_generator()
	
	#Added
	_initialize_combat_manager()
	
	# Set up quick access references
	character = manager_registry.get_character()
	turn_manager = manager_registry.get_turn_manager()
	
	# Final 3D system validation
	_validate_3d_systems()
	

func _initialize_map_generator():
	"""Initialize the procedural 3D map generator"""
	map_generator = ExpeditionMapGenerator.new()
	add_child(map_generator)
	
	# Optional: Configure map parameters
	map_generator.map_size = 50  # Adjust as needed
	map_generator.tile_size = 2.0
	map_generator.height_scale = 8.0
	map_generator.noise_frequency = 0.08
	
	print("ExpeditionMapGenerator initialized and added to scene")

# Added this new initialization function
func _initialize_combat_manager():
	"""Initialize the simple 3D combat manager"""
	combat_manager = CombatManager.new()
	add_child(combat_manager)
	combat_manager.initialize(self)
	
	# Connect combat finished signal
	combat_manager.combat_scene_finished.connect(_on_combat_scene_finished)
	
#Added
func _on_combat_scene_finished():
	"""Handle combat scene finishing"""

#Added
func trigger_combat():
	"""Trigger simple 3D combat for testing"""
	if not combat_manager:
		return false
	
	if combat_manager.is_combat_active():
		return false
	
	return combat_manager.start_simple_combat()
#Added
func is_3d_combat_available() -> bool:
	"""Check if 3D combat can be started"""
	return combat_manager != null and not combat_manager.is_combat_active()

# Added this getter method
func get_combat_manager() -> CombatManager:
	"""Get the simple 3D combat manager"""
	return combat_manager

# Additional 3D combat integration methods
func can_start_3d_combat_at_tile(tile: BiomeTile3D) -> bool:
	"""Check if 3D combat can be started at a specific tile"""
	if not is_3d_combat_available():
		return false
	
	# Add your combat conditions here
	# For example: check if there are enemies on the tile
	return tile != null and tile.is_occupied

func start_3d_combat_at_position(grid_position: Vector3i) -> bool:
	"""Start 3D combat at a specific grid position"""
	var tile = get_tile_at_3d_position(grid_position)
	if tile and can_start_3d_combat_at_tile(tile):
		# Focus camera on combat location before starting
		focus_camera_on_tile(tile, true)
		return trigger_combat()
	return false

func _setup_3d_input_system():
	"""Setup all 3D input actions"""
	Input3DSetup.setup_3d_input_actions()
	
	# Setup debug actions in debug builds
	if OS.is_debug_build():
		Input3DSetup.setup_debug_input_actions()
	
	print("GameManager: 3D input system setup complete")

func _validate_3d_systems():
	"""Validate that all 3D systems are properly initialized"""
	var status = get_3d_system_status()
	
	print("=== 3D System Status ===")
	for key in status:
		print(key, ": ", status[key])
	print("========================")
	
	if not status.overall_ready:
		print("WARNING: 3D systems not fully ready!")
	else:
		print("SUCCESS: All 3D systems ready!")

func _initialize_manager_registry():
	"""Initialize the manager registry and all game managers"""
	manager_registry = ManagerRegistry.new()
	add_child(manager_registry)
	manager_registry.initialize_all_managers()

func _initialize_camera_controller():
	"""Initialize the 3D camera controller programmatically"""
	camera_controller = ExpeditionCamera3D.new()
	add_child(camera_controller)
	
	# Set camera bounds to match 3D map size
	var map_manager = manager_registry.get_map_manager()
	if map_manager:
		# Convert 2D bounds to 3D bounds
		var bounds_2d = map_manager.get_world_bounds()
		var bounds_3d = Vector3(bounds_2d.size.x, 20, bounds_2d.size.y)  # Add Y height
		camera_controller.set_bounds(bounds_3d)
		print("3D Camera bounds set to: ", bounds_3d)
		
		# Start at center of map in 3D space
		var center_3d = Vector3(
			map_manager.map_width * map_manager.tile_size / 2, 
			0,  # Ground level
			map_manager.map_height * map_manager.tile_size / 2
		)
		camera_controller.set_target_position(center_3d)
		camera_controller.set_distance(15.0)  # Good overview distance
		camera_controller.set_angles(0, -45)  # Nice viewing angle
		print("3D Camera focused on: ", center_3d)
	else:
		camera_controller.set_target_position(Vector3.ZERO)
	
	print("ExpeditionCamera3D initialized and configured")

func _initialize_action_controller():
	"""Initialize the action mode controller"""
	action_controller = ActionModeController.new()
	add_child(action_controller)
	# UI bridge must be created first before initializing action controller

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

func confirm_movement(target_position):
	"""Confirm movement action - handles both Vector2i and Vector3i"""
	if ui_bridge:
		# Convert Vector2i to Vector3i if needed for 3D compatibility
		var pos_3d = convert_to_3d_position(target_position)
		ui_bridge.confirm_movement(pos_3d)

func confirm_building(target_position, building_type: String):
	"""Confirm building placement - handles both Vector2i and Vector3i"""
	if ui_bridge:
		var pos_3d = convert_to_3d_position(target_position)
		ui_bridge.confirm_building(pos_3d, building_type)

func confirm_attack(target_position):
	"""Confirm attack action - handles both Vector2i and Vector3i"""
	if ui_bridge:
		var pos_3d = convert_to_3d_position(target_position)
		ui_bridge.confirm_attack(pos_3d)

func confirm_interaction(target_position, interaction_type: String):
	"""Confirm interaction action - handles both Vector2i and Vector3i"""
	if ui_bridge:
		var pos_3d = convert_to_3d_position(target_position)
		ui_bridge.confirm_interaction(pos_3d, interaction_type)

# Helper method for coordinate conversion
func convert_to_3d_position(position) -> Vector3i:
	"""Convert position to Vector3i for 3D compatibility"""
	if position is Vector2i:
		var pos_2d = position as Vector2i
		return Vector3i(pos_2d.x, 0, pos_2d.y)  # Y=0 for ground level
	elif position is Vector3i:
		return position as Vector3i
	else:
		print("Warning: Unknown position type in convert_to_3d_position: ", typeof(position))
		return Vector3i.ZERO

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
		manager_registry.resource_manager.add_resource(resource_name, amount)
		if game_state:
			game_state.add_resource(resource_name, amount)

func spend_resource(resource_name: String, amount: int) -> bool:
	"""Spend a single resource"""
	if manager_registry:
		var success = manager_registry.resource_manager.spend_resource(resource_name, amount)
		if success and game_state:
			game_state.spend_resource(resource_name, amount)
		return success
	return false

func spend_resources(cost: Dictionary) -> bool:
	"""Spend multiple resources"""
	if manager_registry:
		var success = manager_registry.resource_manager.spend_resources(cost)
		if success and game_state:
			for resource_name in cost:
				game_state.spend_resource(resource_name, cost[resource_name])
		return success
	return false

func has_resource(resource_name: String, amount: int) -> bool:
	"""Check if player has enough of a resource"""
	if manager_registry:
		return manager_registry.resource_manager.has_resource(resource_name, amount)
	return false

func can_afford(cost: Dictionary) -> bool:
	"""Check if player can afford a cost"""
	if manager_registry:
		return manager_registry.resource_manager.can_afford(cost)
	return false

func get_resource(resource_name: String) -> int:
	"""Get current amount of a resource"""
	if manager_registry:
		return manager_registry.resource_manager.get_resource(resource_name)
	return 0

func get_all_resources() -> Dictionary:
	"""Get all current resources"""
	if manager_registry:
		return manager_registry.resource_manager.get_all_resources()
	return {}

func set_resource(resource_name: String, amount: int):
	"""Set a resource to a specific amount"""
	if manager_registry:
		manager_registry.resource_manager.set_resource(resource_name, amount)
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
		return manager_registry.inventory_manager.add_item_to_inventory(item, amount)
	return false

func remove_item_from_inventory(item_id: String, amount: int = 1) -> int:
	"""Remove items from inventory"""
	if manager_registry:
		return manager_registry.inventory_manager.remove_item_from_inventory(item_id, amount)
	return 0

func has_item_in_inventory(item_id: String, amount: int = 1) -> bool:
	"""Check if player has an item in inventory"""
	if manager_registry:
		return manager_registry.inventory_manager.has_item_in_inventory(item_id, amount)
	return false

# ═══════════════════════════════════════════════════════════
# BUILDING SYSTEM (Public API)
# ═══════════════════════════════════════════════════════════

#func show_building_detail(building: Building):
	#"""Show building detail view"""
	#if ui_bridge:
		#ui_bridge.show_building_detail(building)
#
#func show_building_type_detail(building_type_name: String):
	#"""Show building type detail view"""
	#if ui_bridge:
		#ui_bridge.show_building_type_detail(building_type_name)

# ═══════════════════════════════════════════════════════════
# WARBAND MANAGEMENT (Public API)
# ═══════════════════════════════════════════════════════════

func get_warband_manager() -> WarbandManager:
	"""Get the warband manager"""
	if manager_registry:
		return manager_registry.warband_manager.get_warband_manager()
	return null

# ═══════════════════════════════════════════════════════════
# BUILDING SYSTEM (Public API)
# ═══════════════════════════════════════════════════════════

#func get_build_manager() -> BuildManager:
	#"""Get the build manager"""
	#if manager_registry:
		#return manager_registry.get_build_manager()
	#return null
#
#func start_building_mode(building_type: String = ""):
	#"""Start building placement mode"""
	#var build_manager = get_build_manager()
	#if build_manager:
		#build_manager.start_build_mode(building_type)
#
#func end_building_mode():
	#"""End building placement mode"""
	#var build_manager = get_build_manager()
	#if build_manager:
		#build_manager.end_build_mode()
#
#func can_place_building_at(position, building_type: String) -> bool:
	#"""Check if a building can be placed at position"""
	#var build_manager = get_build_manager()
	#if build_manager:
		## Convert position if needed
		#var pos_3d = convert_to_3d_position(position)
		#var tile = get_tile_at_3d_position(pos_3d)
		#if tile and build_manager.pending_building_type == building_type:
			#var building_data = build_manager.available_buildings.get(building_type, {})
			#return build_manager.can_place_building_at_tile(tile, building_data)
	#return false
#
#func place_building(position, building_type: String) -> bool:
	#"""Attempt to place a building at position"""
	#var build_manager = get_build_manager()
	#if build_manager:
		#build_manager.attempt_build_at(position, building_type)
		#return true
	#return false
#
#func get_building_at_position(position) -> Dictionary:
	#"""Get building at specified position"""
	#var build_manager = get_build_manager()
	#if build_manager:
		#return build_manager.get_building_at(position)
	#return {}
#
#func get_available_buildings() -> Dictionary:
	#"""Get all available building types"""
	#var build_manager = get_build_manager()
	#if build_manager:
		#return build_manager.get_available_buildings()
	#return {}
#
#func get_building_cost(building_type: String) -> Dictionary:
	#"""Get the resource cost of a building type"""
	#var build_manager = get_build_manager()
	#if build_manager:
		#return build_manager.get_building_cost(building_type)
	#return {}

# ═══════════════════════════════════════════════════════════
# 3D SYSTEM ACCESS METHODS 
# ═══════════════════════════════════════════════════════════

func get_3d_camera() -> ExpeditionCamera3D:
	"""Get the 3D camera controller"""
	return camera_controller

func get_3d_map_manager() -> MapManager3D:
	"""Get the 3D map manager"""
	if manager_registry:
		return manager_registry.get_map_manager() as MapManager3D
	return null

func focus_camera_on_tile(tile: BiomeTile3D, instant: bool = false):
	"""Focus the 3D camera on a specific tile"""
	if camera_controller and tile:
		camera_controller.focus_on_tile(tile, instant)

func focus_camera_on_position(world_position: Vector3, instant: bool = false):
	"""Focus the 3D camera on a world position"""
	if camera_controller:
		camera_controller.focus_on_position(world_position, instant)

func set_camera_view(preset_name: String):
	"""Set the 3D camera to a preset view"""
	if camera_controller:
		camera_controller.set_preset_view(preset_name)

func get_tile_at_3d_position(grid_position: Vector3i) -> BiomeTile3D:
	"""Get tile at 3D grid position"""
	var map_manager = get_3d_map_manager()
	if map_manager:
		return map_manager.get_tile_at_position(grid_position)
	return null

func get_tile_at_world_position(world_position: Vector3) -> BiomeTile3D:
	"""Get tile at world position"""
	var map_manager = get_3d_map_manager()
	if map_manager:
		return map_manager.get_tile_at_world(world_position)
	return null

# Legacy compatibility methods for gradual migration
func get_tile_at_position(position) -> BiomeTile3D:
	"""Get tile at position - handles both 2D and 3D coordinates"""
	var pos_3d = convert_to_3d_position(position)
	return get_tile_at_3d_position(pos_3d)

func convert_2d_to_3d_grid_position(pos_2d: Vector2i) -> Vector3i:
	"""Convert 2D grid position to 3D grid position"""
	return Vector3i(pos_2d.x, 0, pos_2d.y)

func convert_3d_to_2d_grid_position(pos_3d: Vector3i) -> Vector2i:
	"""Convert 3D grid position to 2D grid position (for legacy systems)"""
	return Vector2i(pos_3d.x, pos_3d.z)

# Debug methods for 3D systems
func debug_3d_camera_info():
	"""Print debug information about the 3D camera"""
	if camera_controller:
		camera_controller.debug_print_camera_info()

func debug_3d_map_info():
	"""Print debug information about the 3D map"""
	var map_manager = get_3d_map_manager()
	if map_manager:
		map_manager.debug_print_3d_info()

func is_3d_system_ready() -> bool:
	"""Check if all 3D systems are properly initialized"""
	return camera_controller != null and get_3d_map_manager() != null

func get_3d_system_status() -> Dictionary:
	"""Get status of all 3D systems"""
	return {
		"camera_ready": camera_controller != null,
		"map_manager_ready": get_3d_map_manager() != null,
		"combat_manager_ready": combat_manager != null,
		"mouse_raycaster_ready": get_3d_map_manager() != null and get_3d_map_manager().mouse_raycaster != null,
		"terrain_materials_ready": get_3d_map_manager() != null and get_3d_map_manager().terrain_material_library != null,
		"overall_ready": is_3d_system_ready()
	}

# Input handling for 3D camera presets
func _input(event):
	"""Handle global 3D input events"""
	if event.is_action_pressed("camera_overview"):
		set_camera_view("overview")
	elif event.is_action_pressed("camera_close"):
		set_camera_view("close")
	elif event.is_action_pressed("camera_side"):
		set_camera_view("side")
	elif event.is_action_pressed("camera_top_down"):
		set_camera_view("top_down")
	elif event.is_action_pressed("reset_camera"):
		reset_camera_to_default()
	elif event.is_action_pressed("debug_3d_camera"):
		debug_3d_camera_info()
	elif event.is_action_pressed("debug_3d_map"):
		debug_3d_map_info()

func reset_camera_to_default():
	"""Reset camera to default position and view"""
	if camera_controller:
		# Reset to map center
		var map_manager = get_3d_map_manager()
		if map_manager:
			var center_3d = Vector3(
				map_manager.map_width * map_manager.tile_size / 2,
				0,
				map_manager.map_height * map_manager.tile_size / 2
			)
			camera_controller.set_target_position(center_3d)
			camera_controller.set_distance(15.0)
			camera_controller.set_angles(0, -45)
			print("Camera reset to default position")
