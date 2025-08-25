# ManagerRegistry.gd - Enhanced with proper SceneManager initialization
extends Node
class_name ManagerRegistry

signal managers_initialized()

# Core managers
var character: Character
var map_manager: MapManager
var turn_manager: TurnManager

# Action managers
var movement_manager: MovementManager
var build_manager: BuildManager
var interact_manager: InteractManager
var attack_manager: AttackManager

# System managers
var resource_manager: ResourceManager
var inventory_manager: InventoryManager
var warband_manager: WarbandManager

# Scene manager (needs GameManager reference)
var scene_manager: SceneManager

func initialize_all_managers(game_manager: GameManager):
	"""Initialize all game managers in the correct order"""
	
	# Create core managers 
	_create_core_managers()
	
	# Create scene manager with game manager reference
	_create_scene_manager(game_manager)
	
	# Add all to scene tree
	_add_managers_to_scene()
	
	# Initialize manager dependencies
	_initialize_manager_dependencies()
	
	managers_initialized.emit()

# ═══════════════════════════════════════════════════════════
# MANAGER CREATION
# ═══════════════════════════════════════════════════════════

func _create_core_managers():
	"""Create the core game managers"""
	turn_manager = TurnManager.new()
	map_manager = MapManager.new()
	map_manager.generate_map(32, 32)
	
	# Create character with stats
	character = Character.new()
	var stats = CharacterStats.new()
	stats.character_name = "Hero"
	stats.character_level = 1
	character.stats = stats
	character.initialize_from_stats()
	
	# Create system-level managers
	resource_manager = ResourceManager.new()
	inventory_manager = InventoryManager.new()
	warband_manager = WarbandManager.new()
	
	# Action managers
	movement_manager = MovementManager.new()
	build_manager = BuildManager.new()
	interact_manager = InteractManager.new()
	attack_manager = AttackManager.new()

func _create_scene_manager(game_manager: GameManager):
	"""Create scene manager with proper GameManager reference"""
	scene_manager = SceneManager.new()
	# Initialize it immediately with the GameManager reference
	scene_manager.initialize(game_manager)

func _add_managers_to_scene():
	"""Add all managers to the scene tree"""
	# Add scene manager first so it can set up containers
	add_child(scene_manager)
	
	# Core managers
	add_child(turn_manager)
	add_child(resource_manager)
	add_child(inventory_manager)
	add_child(warband_manager)
	
	# Action managers
	add_child(movement_manager)
	add_child(build_manager)
	add_child(interact_manager)
	add_child(attack_manager)
	
	# Map and character are now managed by SceneManager
	# They'll be added to the appropriate scene containers

func _initialize_manager_dependencies():
	"""Initialize manager dependencies and cross-references"""
	# Wait for scene manager to be ready
	await scene_manager.scene_transition_completed
	
	# Get the expedition container from scene manager for map and character
	var expedition_container = scene_manager.get_expedition_container()
	
	# Add map manager to expedition container if not already there
	if map_manager and map_manager.get_parent() != expedition_container:
		if map_manager.get_parent():
			map_manager.get_parent().remove_child(map_manager)
		expedition_container.add_child(map_manager)
	
	# Add character to expedition container if not already there
	if character and character.get_parent() != expedition_container:
		if character.get_parent():
			character.get_parent().remove_child(character)
		expedition_container.add_child(character)
	
	# Action managers need character and map
	movement_manager.initialize(character, map_manager)
	build_manager.initialize(character, map_manager)
	interact_manager.initialize(character, map_manager)
	attack_manager.initialize(character, map_manager)
	
	# Inventory manager needs character
	if character:
		inventory_manager.set_character(character)
	
	print("ManagerRegistry: All manager dependencies initialized")

# ═══════════════════════════════════════════════════════════
# MANAGER ACCESS METHODS
# ═══════════════════════════════════════════════════════════

func get_character() -> Character:
	"""Get the character instance"""
	return character

func get_map_manager() -> MapManager:
	"""Get the map manager instance"""
	return map_manager

func get_turn_manager() -> TurnManager:
	"""Get the turn manager instance"""
	return turn_manager

func get_movement_manager() -> MovementManager:
	"""Get the movement manager instance"""
	return movement_manager

func get_build_manager() -> BuildManager:
	"""Get the build manager instance"""
	return build_manager

func get_interact_manager() -> InteractManager:
	"""Get the interact manager instance"""
	return interact_manager

func get_attack_manager() -> AttackManager:
	"""Get the attack manager instance"""
	return attack_manager

func get_resource_manager() -> ResourceManager:
	"""Get the resource manager instance"""
	return resource_manager

func get_inventory_manager() -> InventoryManager:
	"""Get the inventory manager instance"""
	return inventory_manager

func get_warband_manager() -> WarbandManager:
	"""Get the warband manager instance"""
	return warband_manager

func get_scene_manager() -> SceneManager:
	"""Get the scene manager instance"""
	return scene_manager

# ═══════════════════════════════════════════════════════════
# SCENE MANAGEMENT HELPERS
# ═══════════════════════════════════════════════════════════

func get_current_scene_container() -> Node:
	"""Get the currently active scene container"""
	if not scene_manager:
		return null
	
	if scene_manager.is_in_combat():
		return scene_manager.get_combat_container()
	else:
		return scene_manager.get_expedition_container()

func move_manager_to_scene(manager: Node, target_scene_type):
	"""Move a manager to a specific scene container"""
	if not scene_manager:
		return false
	
	var target_container: Node
	match target_scene_type:
		SceneManager.SceneType.EXPEDITION:
			target_container = scene_manager.get_expedition_container()
		SceneManager.SceneType.COMBAT:
			target_container = scene_manager.get_combat_container()
		_:
			return false
	
	if manager.get_parent():
		manager.get_parent().remove_child(manager)
	
	target_container.add_child(manager)
	return true

# ═══════════════════════════════════════════════════════════
# DEBUG AND UTILITY
# ═══════════════════════════════════════════════════════════

func get_manager_status() -> Dictionary:
	"""Get status of all managers for debugging"""
	return {
		"character": character != null,
		"map_manager": map_manager != null,
		"turn_manager": turn_manager != null,
		"movement_manager": movement_manager != null,
		"build_manager": build_manager != null,
		"interact_manager": interact_manager != null,
		"attack_manager": attack_manager != null,
		"resource_manager": resource_manager != null,
		"inventory_manager": inventory_manager != null,
		"warband_manager": warband_manager != null,
		"scene_manager": scene_manager != null,
		"current_scene": scene_manager.get_current_scene_type() if scene_manager else "unknown"
	}

func print_manager_hierarchy():
	"""Print the current manager hierarchy for debugging"""
	print("=== Manager Registry Hierarchy ===")
	print("ManagerRegistry children:")
	for child in get_children():
		print("  - ", child.name, " (", child.get_class(), ")")
	
	if scene_manager:
		print("SceneManager containers:")
		var expedition = scene_manager.get_expedition_container()
		var combat = scene_manager.get_combat_container()
		
		if expedition:
			print("  Expedition container children:")
			for child in expedition.get_children():
				print("    - ", child.name, " (", child.get_class(), ")")
		
		if combat:
			print("  Combat container children:")
			for child in combat.get_children():
				print("    - ", child.name, " (", child.get_class(), ")")
	
	print("=== End Hierarchy ===")

# ═══════════════════════════════════════════════════════════
# CLEANUP
# ═══════════════════════════════════════════════════════════

func _exit_tree():
	"""Clean up when the registry is destroyed"""
	# Disconnect any remaining signals
	if managers_initialized.get_connections().size() > 0:
		for connection in managers_initialized.get_connections():
			managers_initialized.disconnect(connection.callable)
	
	print("ManagerRegistry: Cleanup complete")
