# ManagerRegistry.gd
extends Node
class_name ManagerRegistry

signal managers_initialized()

# Core game objects
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

# Manager lookup dictionary
var _managers: Dictionary = {}

func initialize_all_managers():
	"""Initialize all game managers in the correct order"""
	print("ManagerRegistry: Initializing all managers...")
	
	# Create core managers first
	_create_core_managers()
	
	# Create system managers
	_create_system_managers()
	
	# Create action managers
	_create_action_managers()
	
	# Add all to scene tree
	_add_managers_to_scene()
	
	# Initialize manager dependencies
	_initialize_manager_dependencies()
	
	# Populate lookup dictionary
	_populate_manager_lookup()
	
	print("ManagerRegistry: All managers initialized successfully")
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

func _create_system_managers():
	"""Create system-level managers"""
	resource_manager = ResourceManager.new()
	inventory_manager = InventoryManager.new()
	warband_manager = WarbandManager.new()

func _create_action_managers():
	"""Create action-specific managers"""
	movement_manager = MovementManager.new()
	build_manager = BuildManager.new()
	interact_manager = InteractManager.new()
	attack_manager = AttackManager.new()

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

func _populate_manager_lookup():
	"""Populate the manager lookup dictionary for easy access"""
	_managers = {
		"turn": turn_manager,
		"map": map_manager,
		"character": character,
		"movement": movement_manager,
		"build": build_manager,
		"interact": interact_manager,
		"attack": attack_manager,
		"resource": resource_manager,
		"inventory": inventory_manager,
		"warband": warband_manager
	}

# ═══════════════════════════════════════════════════════════
# MANAGER ACCESS METHODS
# ═══════════════════════════════════════════════════════════

func get_manager(manager_name: String) -> Node:
	"""Get a manager by name"""
	if _managers.has(manager_name):
		return _managers[manager_name]
	
	print("ManagerRegistry: Warning - Manager '%s' not found" % manager_name)
	return null

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

# ═══════════════════════════════════════════════════════════
# UTILITY METHODS
# ═══════════════════════════════════════════════════════════

func get_all_managers() -> Array:
	"""Get all managers as an array"""
	return _managers.values()

func get_manager_names() -> Array:
	"""Get all manager names"""
	return _managers.keys()

func is_manager_initialized(manager_name: String) -> bool:
	"""Check if a specific manager is initialized"""
	return _managers.has(manager_name) and _managers[manager_name] != null

func are_all_managers_initialized() -> bool:
	"""Check if all managers are initialized"""
	for manager in _managers.values():
		if manager == null:
			return false
	return true

# ═══════════════════════════════════════════════════════════
# RESOURCE MANAGEMENT SHORTCUTS
# ═══════════════════════════════════════════════════════════

func add_resource(resource_name: String, amount: int):
	"""Shortcut to add resources"""
	if resource_manager:
		resource_manager.add_resource(resource_name, amount)

func spend_resource(resource_name: String, amount: int) -> bool:
	"""Shortcut to spend a single resource"""
	if resource_manager:
		return resource_manager.spend_resource(resource_name, amount)
	return false

func spend_resources(cost: Dictionary) -> bool:
	"""Shortcut to spend multiple resources"""
	if resource_manager:
		return resource_manager.spend_resources(cost)
	return false

func has_resource(resource_name: String, amount: int) -> bool:
	"""Shortcut to check if player has enough of a resource"""
	if resource_manager:
		return resource_manager.has_resource(resource_name, amount)
	return false

func can_afford(cost: Dictionary) -> bool:
	"""Shortcut to check if player can afford a cost"""
	if resource_manager:
		return resource_manager.can_afford(cost)
	return false

func get_resource(resource_name: String) -> int:
	"""Shortcut to get current amount of a resource"""
	if resource_manager:
		return resource_manager.get_resource(resource_name)
	return 0

func get_all_resources() -> Dictionary:
	"""Shortcut to get all current resources"""
	if resource_manager:
		return resource_manager.get_all_resources()
	return {}

func set_resource(resource_name: String, amount: int):
	"""Shortcut to set a resource to a specific amount"""
	if resource_manager:
		resource_manager.set_resource(resource_name, amount)

# ═══════════════════════════════════════════════════════════
# INVENTORY MANAGEMENT SHORTCUTS
# ═══════════════════════════════════════════════════════════

func add_item_to_inventory(item: BaseItem, amount: int = 1) -> bool:
	"""Shortcut to add items to inventory"""
	if inventory_manager:
		return inventory_manager.add_item(item, amount)
	return false

func remove_item_from_inventory(item_id: String, amount: int = 1) -> int:
	"""Shortcut to remove items from inventory"""
	if inventory_manager:
		return inventory_manager.remove_item(item_id, amount)
	return 0

func has_item_in_inventory(item_id: String, amount: int = 1) -> bool:
	"""Shortcut to check if player has an item in inventory"""
	if inventory_manager:
		return inventory_manager.has_item(item_id, amount)
	return false

# ═══════════════════════════════════════════════════════════
# CLEANUP
# ═══════════════════════════════════════════════════════════

func cleanup_managers():
	"""Clean up all managers when game ends"""
	print("ManagerRegistry: Cleaning up managers...")
	
	for manager in _managers.values():
		if manager and is_instance_valid(manager):
			manager.queue_free()
	
	_managers.clear()
	print("ManagerRegistry: Manager cleanup complete")
