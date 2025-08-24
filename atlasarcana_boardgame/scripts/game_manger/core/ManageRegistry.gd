# ManagerRegistry.gd
extends Node
class_name ManagerRegistry

signal managers_initialized()

var character: Character
var map_manager: MapManager3D
var turn_manager: TurnManager
var movement_manager: MovementManager
#var build_manager: BuildManager
#var interact_manager: InteractManager
#var attack_manager: AttackManager
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
	# Create 3D map manager instead of 2D
	map_manager = MapManager3D.new()
	map_manager.generate_map(32, 24)  # Width x Height for 3D map
	
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
	
	#Action managers - Create only if the classes exist
	movement_manager = MovementManager.new()
	
	## Create build manager
	#build_manager = BuildManager.new()
	#
	## Create interact manager
	#interact_manager = InteractManager.new()
	
	# Create attack manager if it exists
	#if ClassDB.class_exists("AttackManager"):
		#attack_manager = AttackManager.new()
	#else:
		#print("Warning: AttackManager class not found, creating stub")
		#attack_manager = _create_manager_stub("AttackManager")
	
	#Scene manager
	scene_manager = SceneManager.new()
	
	print("Core managers created with 3D compatibility")

func _create_manager_stub(manager_name: String) -> Node:
	"""Create a stub manager for missing manager classes"""
	var stub = Node.new()
	stub.name = manager_name + "_Stub"
	stub.set_script(preload("res://scripts/game_manger/core/ManagerStub.gd"))
	return stub

func _add_managers_to_scene():
	"""Add all managers to the scene tree"""
	add_child(turn_manager)
	add_child(map_manager)
	add_child(character)
	add_child(movement_manager)
	#add_child(build_manager)
	#add_child(interact_manager)
	#add_child(attack_manager)
	add_child(resource_manager)
	add_child(inventory_manager)
	add_child(warband_manager)
	add_child(scene_manager)

func _initialize_manager_dependencies():
	"""Initialize manager dependencies and cross-references"""
	# Action managers need character and map
	# Use safe initialization that checks if managers exist and handles 3D types
	if movement_manager and movement_manager.has_method("initialize"):
		# Try to initialize with 3D map manager
		movement_manager.initialize(character, map_manager)
		print("MovementManager initialized with 3D map")
	elif movement_manager:
		# Fallback: set properties directly
		print("Warning: MovementManager missing initialize method, setting properties directly")
		movement_manager.character = character
		movement_manager.map_manager = map_manager
	
	#if build_manager and build_manager.has_method("initialize"):
		##build_manager.initialize(character, map_manager)
		#print("BuildManager initialized with 3D map")
	#elif build_manager:
		#print("Warning: BuildManager missing initialize method")
		#if build_manager.has_method("set_character"):
			#build_manager.set_character(character)
		#if build_manager.has_method("set_map_manager"):
			#build_manager.set_map_manager(map_manager)
	
	#if interact_manager and interact_manager.has_method("initialize"):
		#interact_manager.initialize(character, map_manager)
		#print("InteractManager initialized with 3D map")
	#elif interact_manager:
		#print("Warning: InteractManager missing initialize method")
		#interact_manager.character = character
		#interact_manager.map_manager = map_manager
	
	#if attack_manager and attack_manager.has_method("initialize"):
		##attack_manager.initialize(character, map_manager)
		#print("AttackManager initialized with 3D map")
	#elif attack_manager:
		#print("Warning: AttackManager missing initialize method")
		#if attack_manager.has_method("set_character"):
			#attack_manager.set_character(character)
		#if attack_manager.has_method("set_map_manager"):
			#attack_manager.set_map_manager(map_manager)
	
	# Inventory manager needs character
	if character and inventory_manager:
		if inventory_manager.has_method("set_character"):
			inventory_manager.set_character(character)
			print("InventoryManager initialized with character")
		else:
			print("Warning: InventoryManager does not have set_character method")
	
	print("Manager dependencies initialized with 3D compatibility")

# ═══════════════════════════════════════════════════════════
# MANAGER ACCESS METHODS
# ═══════════════════════════════════════════════════════════

func get_character() -> Character:
	"""Get the character instance"""
	return character

func get_map_manager() -> MapManager3D:
	"""Get the 3D map manager instance"""
	return map_manager

func get_turn_manager() -> TurnManager:
	"""Get the turn manager instance"""
	return turn_manager

func get_movement_manager() -> MovementManager:
	"""Get the movement manager instance"""
	return movement_manager

#func get_build_manager() -> BuildManager:
	#"""Get the build manager instance"""
	#return build_manager

#func get_interact_manager() -> InteractManager:
	#"""Get the interact manager instance"""
	#return interact_manager

#func get_attack_manager() -> AttackManager:
	#"""Get the attack manager instance"""
	#return attack_manager

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
