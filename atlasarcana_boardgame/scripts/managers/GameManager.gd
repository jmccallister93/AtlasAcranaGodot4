#GameManager.gd
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
var attack_manager: AttackManager
var resource_manager: ResourceManager
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
	attack_manager = AttackManager.new()
	character = Character.new()
	resource_manager = ResourceManager.new()
	
	
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
	add_child(attack_manager)
	add_child(resource_manager)
	
	movement_manager.initialize(character, map_manager) 
	build_manager.initialize(character, map_manager)
	
	interact_manager.initialize(character, map_manager)
	attack_manager.initialize(character, map_manager)
	
	connect_signals()
	


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

func create_test_enemies():
	"""Create test enemies for combat"""
	# Create a goblin warrior at position (4, 6)
	var goblin = attack_manager.create_goblin_warrior(Vector2i(4, 6))
	attack_manager.add_enemy(goblin, Vector2i(4, 6))
	
	# Create an orc brute at position (8, 4)
	var orc = attack_manager.create_orc_brute(Vector2i(8, 4))
	attack_manager.add_enemy(orc, Vector2i(8, 4))
	
	# Create a skeleton archer at position (6, 8)
	var skeleton = attack_manager.create_skeleton_archer(Vector2i(6, 8))
	attack_manager.add_enemy(skeleton, Vector2i(6, 8))
	
	# Create a random enemy at position (10, 2)
	var random_enemy = attack_manager.create_random_enemy(Vector2i(10, 2))
	attack_manager.add_enemy(random_enemy, Vector2i(10, 2))
	
	print("Created test enemies at positions: (4,6), (8,4), (6,8), (10,2)")

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
			attack_manager.end_attack_mode()  
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
	attack_manager.start_attack_mode()  # Actually use the attack manager
	
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
	build_manager.building_data_changed.connect(_on_building_data_changed)
	# Interact Manager 
	interact_manager.interaction_completed.connect(_on_interaction_completed)
	interact_manager.interaction_failed.connect(_on_interaction_failed)
	interact_manager.interact_confirmation_requested.connect(_on_interact_confirmation_requested)
	# Attack Manager signals 
	attack_manager.attack_completed.connect(_on_attack_completed)
	attack_manager.attack_failed.connect(_on_attack_failed)
	attack_manager.attack_confirmation_requested.connect(_on_attack_confirmation_requested)
	attack_manager.enemy_died.connect(_on_enemy_died)
	# Resource Manager signals
	resource_manager.resource_changed.connect(_on_resource_changed)
	resource_manager.resources_spent.connect(_on_resources_spent)
	resource_manager.insufficient_resources.connect(_on_insufficient_resources)


func _on_turn_manager_initial_turn(turn_number: int):
	initial_turn.emit(turn_number)

func _on_turn_manager_turn_advanced(turn_number: int):
	turn_advanced.emit(turn_number)
	character.refresh_turn_resources()
	resource_manager.apply_turn_income()
	
func _on_character_action_points_spent(current_action_points: int):
	action_points_spent.emit(current_action_points)
	
func _on_movement_requested(target_grid_pos: Vector2i):
	"""Handle click requests from map - route to appropriate manager"""
	match current_action_mode:
		ActionMode.MOVEMENT:
			movement_manager.attempt_move_to(target_grid_pos)
		ActionMode.BUILD:
			build_manager.attempt_build_at(target_grid_pos)
		ActionMode.ATTACK:
			attack_manager.attempt_attack_at(target_grid_pos)
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
		
func _on_building_data_changed():
	if game_ui:
		game_ui._on_building_data_changed()

func _on_interact_confirmation_requested(target_tile: BiomeTile, entity: InteractableEntity):
	"""Handle interact confirmation request"""
	if game_ui:
		game_ui.show_interact_confirmation(target_tile, entity.interaction_name)
	else:
		print("Warning: No GameUI reference, auto-confirming interaction")
		interact_manager.confirm_interaction()

func _on_attack_confirmation_requested(target_tile: BiomeTile, enemy: Enemy):
	"""Handle attack confirmation request"""
	if game_ui:
		game_ui.show_attack_confirmation(target_tile)
	else:
		print("Warning: No GameUI reference, auto-confirming attack")
		attack_manager.confirm_attack()

func _on_resource_changed(resource_name: String, new_amount: int):
	"""Handle resource amount changes"""
	if game_ui:
		game_ui.update_resource(resource_name, new_amount)

func _on_resources_spent(spent_resources: Dictionary):
	"""Handle resources being spent"""
	print("Resources spent: ", spent_resources)

func _on_insufficient_resources(required: Dictionary, available: Dictionary):
	"""Handle insufficient resources"""
	var message = "Not enough resources! Need: "
	for resource in required:
		var need = required[resource]
		var have = available.get(resource, 0)
		message += "%d %s (have %d), " % [need, resource, have]
	
	if game_ui:
		game_ui.show_error(message.trim_suffix(", "))

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
	"""Confirm and execute attack"""
	print("Attack confirmed at: ", target_position)
	attack_manager.confirm_attack() 

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

func _on_attack_completed(character: Character, enemy: Enemy, result: Dictionary):
	"""Handle successful attack"""
	var damage = result.get("damage_dealt", 0)
	var enemy_died = result.get("enemy_died", false)
	
	if enemy_died:
		var exp_gained = result.get("experience", 0)
		print("Attack completed: %s defeated! Gained %d experience." % [enemy.enemy_name, exp_gained])
		if game_ui:
			game_ui.show_success("%s defeated! +%d EXP" % [enemy.enemy_name, exp_gained])
	else:
		print("Attack completed: %d damage dealt to %s" % [damage, enemy.enemy_name])
		if game_ui:
			game_ui.show_info("Hit %s for %d damage!" % [enemy.enemy_name, damage])

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

func _on_attack_failed(reason: String):
	"""Handle failed attack"""
	print("Attack failed: ", reason)
	if game_ui:
		game_ui.show_error(reason)

func _on_enemy_died(enemy: Enemy):
	"""Handle enemy death notification"""
	print("Enemy died: ", enemy.enemy_name)
	# Additional handling for enemy death (quest updates, etc.)


# Add end_attack_mode() method:
func end_attack_mode():
	"""Handle attack mode end"""
	print("Attack action END requested from UI")
	if current_action_mode == ActionMode.ATTACK:
		attack_manager.end_attack_mode()
		current_action_mode = ActionMode.NONE
		
		# Update UI
		if game_ui:
			game_ui.update_action_button_states(current_action_mode)

# Public methods to interact with managers
func advance_turn():
	turn_manager.advance_turn()
	# End all action modes when turn advances
	end_all_action_modes()

func spend_action_points():
	character.spend_action_points()
	
func get_current_action_points() -> int:
	return character.current_action_points

func add_resource(resource_name: String, amount: int):
	"""Add resources to the player"""
	resource_manager.add_resource(resource_name, amount)

func spend_resource(resource_name: String, amount: int) -> bool:
	"""Spend a single resource"""
	return resource_manager.spend_resource(resource_name, amount)

func spend_resources(cost: Dictionary) -> bool:
	"""Spend multiple resources"""
	return resource_manager.spend_resources(cost)

func has_resource(resource_name: String, amount: int) -> bool:
	"""Check if player has enough of a resource"""
	return resource_manager.has_resource(resource_name, amount)

func can_afford(cost: Dictionary) -> bool:
	"""Check if player can afford a cost"""
	return resource_manager.can_afford(cost)

func get_resource(resource_name: String) -> int:
	"""Get current amount of a resource"""
	return resource_manager.get_resource(resource_name)

func get_all_resources() -> Dictionary:
	"""Get all current resources"""
	return resource_manager.get_all_resources()

func set_resource(resource_name: String, amount: int):
	"""Set a resource to a specific amount"""
	resource_manager.set_resource(resource_name, amount)
	
func show_building_detail(building: Building):
	"""Show building detail view for a specific building"""
	if game_ui:
		game_ui.show_building_detail(building)
	else:
		print("GameUI not available for building detail")

func show_building_type_detail(building_type_name: String):
	"""Show building detail view for a building type"""
	if game_ui:
		game_ui.show_building_type_detail(building_type_name)
	else:
		print("GameUI not available for building type detail")
