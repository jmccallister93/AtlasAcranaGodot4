# ManagerRegistry.gd
extends Node
class_name ManagerRegistry

signal managers_initialized()

var character: Character
var map_manager: MapManager
var turn_manager: TurnManager
var movement_manager: MovementManager
var build_manager: BuildManager
var interact_manager: InteractManager
var attack_manager: AttackManager
var resource_manager: ResourceManager
var inventory_manager: InventoryManager
var warband_manager: WarbandManager
var scene_manager: SceneManager

func initialize_all_managers():
	"""Initialize all game managers in the correct order"""
	
	# Create core managers 
	_create_core_managers()
	
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
	
	#Create system-level manager
	resource_manager = ResourceManager.new()
	inventory_manager = InventoryManager.new()
	warband_manager = WarbandManager.new()
	
	#Action managers
	movement_manager = MovementManager.new()
	build_manager = BuildManager.new()
	interact_manager = InteractManager.new()
	attack_manager = AttackManager.new()
	
	#Scene manager
	scene_manager = SceneManager.new()

func _add_managers_to_scene():
	"""Add all managers to the scene tree"""
	add_child(turn_manager)
	add_child(map_manager)
	add_child(character)
	add_child(movement_manager)
	add_child(build_manager)
	add_child(interact_manager)
	add_child(attack_manager)
	add_child(resource_manager)
	add_child(inventory_manager)
	add_child(warband_manager)
	add_child(scene_manager)

func _initialize_manager_dependencies():
	"""Initialize manager dependencies and cross-references"""
	# Action managers need character and map
	movement_manager.initialize(character, map_manager)
	build_manager.initialize(character, map_manager)
	interact_manager.initialize(character, map_manager)
	attack_manager.initialize(character, map_manager)
	
	# Inventory manager needs character
	if character:
		inventory_manager.set_character(character)

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
