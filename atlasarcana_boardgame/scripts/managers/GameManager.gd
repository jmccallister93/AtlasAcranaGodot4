extends Node

signal turn_advanced(turn_number: int)
signal initial_turn(turn_number: int)
signal action_points_spent(current_action_points: int)

# Add Action Mode Management
enum ActionMode {
	NONE,
	MOVEMENT,
	BUILD,
	ATTACK,
	INTERACT
}

var current_action_mode: ActionMode = ActionMode.NONE

var turn_manager: TurnManager
var map_manager: MapManager
var character: Character
var movement_manager: MovementManager
var build_manager: BuildManager
var interact_manager: InteractManager
var game_ui: GameUI

func _ready():
	start_new_game()

func start_new_game():
	turn_manager = TurnManager.new()
	map_manager = MapManager.new()
	map_manager.generate_map(32, 32)
	movement_manager = MovementManager.new()
	build_manager = BuildManager.new()
	interact_manager = InteractManager.new()
	character = Character.new()
	
	# Initialize character stats
	var character_stats = CharacterStats.new()
	character.stats = character_stats
	character.initialize_from_stats()
	
	add_child(turn_manager)
	add_child(map_manager)
	add_child(character)
	add_child(movement_manager)
	add_child(build_manager)
	add_child(interact_manager)
	
	movement_manager.initialize(character, map_manager) 
	build_manager.initialize(character, map_manager)
	interact_manager.initialize(character, map_manager)
	
	connect_signals()
	
	create_test_interactables()

func create_test_interactables():
	"""Create test interactable entities"""
	# Create a treasure chest at position (3,3)
	var treasure_chest = interact_manager.create_treasure_chest(Vector2i(3, 3))
	interact_manager.add_entity(treasure_chest, Vector2i(3, 3))
	
	# Create a magic crystal at position (5, 5)
	var magic_crystal = interact_manager.create_magic_crystal(Vector2i(5, 5))
	interact_manager.add_entity(magic_crystal, Vector2i(5, 5))
	
	# Create an herb patch at position (7, 2)
	var herb_patch = interact_manager.create_herb_patch(Vector2i(7, 2))
	interact_manager.add_entity(herb_patch, Vector2i(7, 2))
	
	# Create a simple test interactable at position (2, 6)
	var test_item = interact_manager.create_test_interactable(Vector2i(2, 6), "mysterious_box", Color.CYAN)
	interact_manager.add_entity(test_item, Vector2i(2, 6))
	
	print("Created test interactables at positions: (3,3), (5,5), (7,2), (2,6)")

func register_game_ui(ui: GameUI):
	"""Called by GameUI to register itself with GameManager"""
	game_ui = ui
	print("✅ GameUI registered with GameManager")

func unregister_game_ui():
	"""Called when GameUI is being removed"""
	game_ui = null
	print("GameUI unregistered from GameManager")

# ═══════════════════════════════════════════════════════════
# ACTION MODE MANAGEMENT SYSTEM
# ═══════════════════════════════════════════════════════════
func can_start_action_mode() -> bool:
	"""Check if player has enough action points to start an action"""
	return character.current_action_points > 0

func show_no_action_points_notification():
	"""Show notification when player tries to act without action points"""
	if game_ui:
		game_ui.show_error("No action points remaining! End your turn to refresh.")
		
func end_all_action_modes():
	"""End all active action modes"""
	match current_action_mode:
		ActionMode.MOVEMENT:
			movement_manager.end_movement_mode()
			print("Ended movement mode")
		ActionMode.BUILD:
			if build_manager:
				build_manager.end_build_mode()
			print("Ended build mode")
		ActionMode.ATTACK:
			# TODO: Add attack manager when implemented
			print("Ended attack mode")
		ActionMode.INTERACT:
			interact_manager.end_interact_mode()  
			print("Ended interact mode")
		ActionMode.NONE:
			pass  # No mode to end
	
	current_action_mode = ActionMode.NONE
	
	# Update UI button states if needed
	if game_ui:
		game_ui.update_action_button_states(current_action_mode)

func start_movement_mode():
	"""Handle move button press from UI"""
	print("Move action requested from UI")
	
	# Check action points first
	if not can_start_action_mode():
		show_no_action_points_notification()
		return
	
	# End any other active modes first
	if current_action_mode != ActionMode.MOVEMENT:
		end_all_action_modes()
	
	# Start movement mode
	current_action_mode = ActionMode.MOVEMENT
	movement_manager.start_movement_mode()
	
	# Update UI
	if game_ui:
		game_ui.update_action_button_states(current_action_mode)

func start_build_mode():
	"""Handle build button press from UI"""
	print("Build action requested from UI")
	
	# Check action points first
	if not can_start_action_mode():
		show_no_action_points_notification()
		return
	
	# End any other active modes first
	if current_action_mode != ActionMode.BUILD:
		end_all_action_modes()
	
	# Start build mode
	current_action_mode = ActionMode.BUILD
	build_manager.start_build_mode()
	
	# Update UI
	if game_ui:
		game_ui.update_action_button_states(current_action_mode)

func start_attack_mode():
	"""Handle attack button press from UI"""
	print("Attack action requested from UI")
	
	# Check action points first
	if not can_start_action_mode():
		show_no_action_points_notification()
		return
	
	# End any other active modes first
	if current_action_mode != ActionMode.ATTACK:
		end_all_action_modes()
	
	# Start attack mode
	current_action_mode = ActionMode.ATTACK
	print("Attack mode started (not implemented yet)")
	
	# Update UI
	if game_ui:
		game_ui.update_action_button_states(current_action_mode)

func start_interact_mode():
	"""Handle interact button press from UI"""
	print("Interact action requested from UI")
	
	# Check action points first
	if not can_start_action_mode():
		show_no_action_points_notification()
		return
	
	# End any other active modes first
	if current_action_mode != ActionMode.INTERACT:
		end_all_action_modes()
	
	# Start interact mode
	current_action_mode = ActionMode.INTERACT
	interact_manager.start_interact_mode()  # Update this line
	
	# Update UI
	if game_ui:
		game_ui.update_action_button_states(current_action_mode)
		
func end_movement_mode():
	"""Handle movement mode end"""
	print("Move action END requested from UI")
	if current_action_mode == ActionMode.MOVEMENT:
		movement_manager.end_movement_mode()
		current_action_mode = ActionMode.NONE
		print("current_action_mode", current_action_mode)
		# Update UI
		if game_ui:
			game_ui.update_action_button_states(current_action_mode)

func end_build_mode():
	"""Handle build mode end"""
	print("Build action END requested from UI")
	if current_action_mode == ActionMode.BUILD:
		build_manager.end_build_mode()  # Update this line
		current_action_mode = ActionMode.NONE
		
		# Update UI
		if game_ui:
			game_ui.update_action_button_states(current_action_mode)

func end_interact_mode():
	"""Handle interact mode end"""
	print("Interact action END requested from UI")
	if current_action_mode == ActionMode.INTERACT:
		interact_manager.end_interact_mode()
		current_action_mode = ActionMode.NONE
		
		# Update UI
		if game_ui:
			game_ui.update_action_button_states(current_action_mode)

func get_current_action_mode() -> ActionMode:
	"""Get the currently active action mode"""
	return current_action_mode

func is_mode_active(mode: ActionMode) -> bool:
	"""Check if a specific mode is currently active"""
	return current_action_mode == mode

# ═══════════════════════════════════════════════════════════
# REST OF YOUR EXISTING CODE (unchanged)
# ═══════════════════════════════════════════════════════════

func connect_signals():
	# Turns
	turn_manager.initial_turn.connect(_on_turn_manager_initial_turn)
	turn_manager.turn_advanced.connect(_on_turn_manager_turn_advanced)
	# Character
	character.action_points_spent.connect(_on_character_action_points_spent)
	character.action_points_refreshed.connect(_on_character_action_points_spent)
	# Map
	map_manager.movement_requested.connect(_on_movement_requested)
	# Movement Manager
	movement_manager.movement_completed.connect(_on_movement_completed)
	movement_manager.movement_failed.connect(_on_movement_failed)
	movement_manager.movement_confirmation_requested.connect(_on_movement_confirmation_requested)
	# Build Manager
	build_manager.building_completed.connect(_on_building_completed)
	build_manager.building_failed.connect(_on_building_failed)
	build_manager.build_confirmation_requested.connect(_on_build_confirmation_requested)
	# Interact Manager 
	interact_manager.interaction_completed.connect(_on_interaction_completed)
	interact_manager.interaction_failed.connect(_on_interaction_failed)
	interact_manager.interact_confirmation_requested.connect(_on_interact_confirmation_requested)


func _on_turn_manager_initial_turn(turn_number: int):
	initial_turn.emit(turn_number)

func _on_turn_manager_turn_advanced(turn_number: int):
	turn_advanced.emit(turn_number)
	character.refresh_turn_resources()
	
func _on_character_action_points_spent(current_action_points: int):
	action_points_spent.emit(current_action_points)
	
func _on_movement_requested(target_grid_pos: Vector2i):
	"""Handle click requests from map - route to appropriate manager"""
	match current_action_mode:
		ActionMode.MOVEMENT:
			movement_manager.attempt_move_to(target_grid_pos)
		ActionMode.BUILD:
			build_manager.attempt_build_at(target_grid_pos)
		ActionMode.INTERACT:
			interact_manager.attempt_interact_at(target_grid_pos)
		_:
			# No active mode, ignore click
			pass
	
func _on_movement_confirmation_requested(target_tile: BiomeTile):
	"""Handle movement confirmation request"""
	if game_ui:
		game_ui.show_movement_confirmation(target_tile)
	else:
		print("Warning: No GameUI reference, auto-confirming movement")
		movement_manager.confirm_movement()

func _on_build_confirmation_requested(target_tile: BiomeTile, building_type: String):
	"""Handle build confirmation request"""
	if game_ui:
		game_ui.show_build_confirmation(target_tile, building_type)
	else:
		print("Warning: No GameUI reference, auto-confirming building")
		build_manager.confirm_building()

func _on_interact_confirmation_requested(target_tile: BiomeTile, entity: InteractableEntity):
	"""Handle interact confirmation request"""
	if game_ui:
		game_ui.show_interact_confirmation(target_tile, entity.interaction_name)
	else:
		print("Warning: No GameUI reference, auto-confirming interaction")
		interact_manager.confirm_interaction()

# Confirmation methods that GameUI will call
func confirm_movement(target_position: Vector2i):
	"""Confirm and execute movement"""
	print("Movement confirmed to: ", target_position)
	movement_manager.confirm_movement()

func confirm_building(target_position: Vector2i, building_type: String):
	"""Confirm and execute building placement"""
	print("Building confirmed: ", building_type, " at ", target_position)
	build_manager.confirm_building()

func confirm_attack(target_position: Vector2i):
	"""Confirm and execute attack (placeholder)"""
	print("Attack confirmed at: ", target_position)
	# TODO: Implement attack system

func confirm_interaction(target_position: Vector2i, interaction_type: String):
	"""Confirm and execute interaction"""
	print("Interaction confirmed: ", interaction_type, " at ", target_position)
	interact_manager.confirm_interaction()
	
func _on_movement_completed(new_pos: Vector2i):
	"""Handle successful movement"""
	print("Movement completed to: ", new_pos)
	end_movement_mode()
	# Movement mode automatically ends after completion

func _on_building_completed(new_building: Building, tile: BiomeTile):
	"""Handle successful building placement"""
	print("Building completed at: ", tile.grid_position)
	# Building mode automatically ends after completion
	end_build_mode()

func _on_interaction_completed(character: Character, entity: InteractableEntity, result: Dictionary):
	"""Handle successful interaction"""
	print("Interaction completed: ", result.get("message", "Success"))
	# Show notification about the interaction result
	if game_ui and result.has("message"):
		game_ui.show_success(result.message)
	
	# Interaction mode automatically ends after completion
	end_interact_mode()

func _on_movement_failed(reason: String):
	"""Handle failed movement"""
	print("Movement failed: ", reason)

func _on_building_failed(reason: String):
	"""Handle failed building placement"""
	print("Building failed: ", reason)

func _on_interaction_failed(reason: String):
	"""Handle failed interaction"""
	print("Interaction failed: ", reason)
	if game_ui:
		game_ui.show_error(reason)


# Public methods to interact with managers
func advance_turn():
	turn_manager.advance_turn()
	# End all action modes when turn advances
	end_all_action_modes()

func spend_action_points():
	character.spend_action_points()
	
func get_current_action_points() -> int:
	return character.current_action_points
