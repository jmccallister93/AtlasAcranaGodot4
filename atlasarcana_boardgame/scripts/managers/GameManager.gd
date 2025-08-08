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
var game_ui: GameUI

func _ready():
	start_new_game()

func start_new_game():
	turn_manager = TurnManager.new()
	map_manager = MapManager.new()
	map_manager.generate_map(32, 32)
	movement_manager = MovementManager.new()
	build_manager = BuildManager.new()
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
	
	movement_manager.initialize(character, map_manager) 
	build_manager.initialize(character, map_manager)
	
	connect_signals()

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
			# TODO: Add interact manager when implemented
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
	print("Interact mode started (not implemented yet)")
	
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
	"""Confirm and execute interaction (placeholder)"""
	print("Interaction confirmed: ", interaction_type, " at ", target_position)
	# TODO: Implement interaction system

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

func _on_movement_failed(reason: String):
	"""Handle failed movement"""
	print("Movement failed: ", reason)

func _on_building_failed(reason: String):
	"""Handle failed building placement"""
	print("Building failed: ", reason)


# Public methods to interact with managers
func advance_turn():
	turn_manager.advance_turn()
	# End all action modes when turn advances
	end_all_action_modes()

func spend_action_points():
	character.spend_action_points()
	
func get_current_action_points() -> int:
	return character.current_action_points
