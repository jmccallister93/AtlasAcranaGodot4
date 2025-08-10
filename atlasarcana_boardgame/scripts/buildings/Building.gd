# Building.gd
extends Node2D
class_name Building

# Building properties
var building_type: BuildingData.BuildingType
var building_type_string: String = ""
var tile_position: Vector2i
var target_tile: BiomeTile
var tile: BiomeTile  
var is_active: bool = true
var health: int = 100
var max_health: int = 100
var building_data: Dictionary

# Building stats
var production_rate: float = 1.0
var maintenance_cost: int = 0
var construction_cost: Dictionary = {}

# Visual components
var sprite: ColorRect
var health_bar: ProgressBar

# Production data
var base_production: Dictionary = {}
var total_production: Dictionary = {}

# Store building data for delayed visual setup
var pending_building_data: Dictionary = {}

func _ready():
	create_visual_components()
	
	# Apply visual update if we have pending building data
	if not pending_building_data.is_empty():
		update_visual_representation(pending_building_data)
		pending_building_data = {}  # Clear after use
	
	# Connect to turn advancement for resource production
	if GameManager:
		GameManager.turn_advanced.connect(_on_turn_advanced)

func initialize(type: BuildingData.BuildingType, target_tile_ref: BiomeTile):
	"""Initialize the building with type and tile data"""
	building_type = type
	target_tile = target_tile_ref
	tile = target_tile_ref  # Set alias for BuildingMenu compatibility
	tile_position = target_tile_ref.grid_position
	
	# Get building data
	building_data = BuildingData.get_building_data(building_type)
	building_type_string = building_data.get("name", "Unknown")
	
	# Set production values
	base_production = building_data.get("base_production", {})
	total_production = BuildingData.get_total_production(building_type, target_tile_ref.biome_type)
	
	# Update visual based on building type
	if sprite:
		# If sprite already exists (unlikely), update immediately
		update_visual_representation(building_data)
	else:
		# Store building data for when sprite is created in _ready()
		pending_building_data = building_data
	
	print("Building initialized: %s at %s" % [building_type_string, tile_position])
	print("Total production: %s" % total_production)

func create_visual_components():
	"""Create basic visual representation"""
	# Create colored square placeholder
	sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)  # bottom corner
	sprite.z_index = 15
	
	# Set a default color first
	sprite.color = Color.WHITE
	
	add_child(sprite)
	
	print("Building visual components created with sprite at: ", sprite.position)

func update_visual_representation(building_data: Dictionary):
	"""Update the visual based on building type"""
	if not sprite:
		print("Warning: Sprite not available for visual update")
		return
		
	var color = building_data.get("sprite_color", Color.PURPLE)
	sprite.color = color
	
	print("Building visual updated - Type: %s, Color: %s" % [building_data.get("name", "Unknown"), color])

func _on_turn_advanced(turn_number: int):
	"""Handle turn advancement - produce resources"""
	if not is_active:
		return
	
	if total_production.is_empty():
		return
	
	# Produce resources
	for resource in total_production:
		var amount = total_production[resource]
		GameManager.add_resource(resource, amount)
		print("%s produced %d %s" % [building_type_string, amount, resource])
	
	# Show production notification
	if GameManager.game_ui:
		var production_text = ""
		for resource in total_production:
			if production_text != "":
				production_text += ", "
			production_text += "%d %s" % [total_production[resource], resource]
		
		GameManager.game_ui.show_info("%s produced: %s" % [building_type_string, production_text])

# REQUIRED METHODS FOR BUILDINGMENU INTEGRATION
func get_building_name() -> String:
	"""Get the display name of this building - REQUIRED for BuildingMenu"""
	return building_type_string

func get_production() -> Dictionary:
	"""Get what this building produces per turn - REQUIRED for BuildingMenu"""
	return total_production.duplicate()

func get_base_production() -> Dictionary:
	"""Get base production without biome bonuses - REQUIRED for BuildingMenu"""
	return base_production.duplicate()

func get_biome_bonus() -> Dictionary:
	"""Calculate the biome bonus for this building - REQUIRED for BuildingMenu"""
	var bonus = {}
	for resource in total_production:
		var total_amount = total_production[resource]
		var base_amount = base_production.get(resource, 0)
		if total_amount > base_amount:
			bonus[resource] = total_amount - base_amount
	return bonus

func get_building_info() -> Dictionary:
	"""Get comprehensive building information - REQUIRED for BuildingMenu"""
	return {
		"name": get_building_name(),
		"type": building_data.get("type", "unknown"),
		"position": tile_position,
		"biome": tile.biome_type if tile else "unknown",
		"base_production": get_base_production(),
		"total_production": get_production(),
		"biome_bonus": get_biome_bonus(),
		"description": building_data.get("description", ""),
		"cost": building_data.get("cost", {}),
		"health": health,
		"max_health": max_health,
		"is_active": is_active
	}

# UTILITY BUILDING METHODS
func is_utility_building() -> bool:
	"""Check if this is a utility building that needs special menus"""
	return building_data.has("utility_type")

func get_utility_type() -> String:
	"""Get the utility type for utility buildings"""
	return building_data.get("utility_type", "")

func open_utility_menu():
	"""Open the utility menu for this building"""
	if not is_utility_building():
		return
	
	var utility_type = get_utility_type()
	match utility_type:
		"weapon_crafting":
			open_forge_menu()
		"unit_training":
			open_barracks_menu()
		_:
			print("Unknown utility type: %s" % utility_type)

func open_forge_menu():
	"""Open forge crafting menu"""
	print("Opening forge menu for weapon crafting...")
	if GameManager.game_ui:
		GameManager.game_ui.show_info("Forge menu coming soon!")

func open_barracks_menu():
	"""Open barracks training menu"""
	print("Opening barracks menu for unit training...")
	if GameManager.game_ui:
		GameManager.game_ui.show_info("Barracks menu coming soon!")

# BUILDING HEALTH AND MAINTENANCE
func take_damage(amount: int):
	"""Damage the building"""
	health = max(0, health - amount)
	if health <= 0:
		destroy_building()

func repair(amount: int):
	"""Repair the building"""
	health = min(max_health, health + amount)

func destroy_building():
	"""Destroy this building"""
	print("Building destroyed at: ", tile_position)
	
	# Notify the tile that it's no longer occupied
	if target_tile:
		target_tile.is_occupied = false
	
	# Disconnect from turn signals
	if GameManager and GameManager.turn_advanced.is_connected(_on_turn_advanced):
		GameManager.turn_advanced.disconnect(_on_turn_advanced)
	
	queue_free()

# LEGACY COMPATIBILITY METHODS
func get_info() -> Dictionary:
	"""Get building information for UI display - LEGACY METHOD"""
	return {
		"type": building_type_string,
		"type_enum": building_type,
		"position": tile_position,
		"health": health,
		"max_health": max_health,
		"is_active": is_active,
		"base_production": base_production,
		"total_production": total_production,
		"biome_bonus": get_biome_bonus(),
		"is_utility": is_utility_building(),
		"utility_type": get_utility_type()
	}

# UPGRADE SYSTEM (Optional - for future use)
func can_be_upgraded() -> bool:
	"""Check if this building can be upgraded"""
	# Implement upgrade logic here
	return false

func get_upgrade_cost() -> Dictionary:
	"""Get the cost to upgrade this building"""
	# Implement upgrade cost logic here
	return {}

# INTERACTION METHODS
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	"""Handle building interaction"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			show_building_info()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if is_utility_building():
				open_utility_menu()

func show_building_info():
	"""Show building information"""
	var info = get_info()
	print("=== %s INFO ===" % info.type)
	print("Position: %s" % info.position)
	print("Health: %d/%d" % [info.health, info.max_health])
	print("Production: %s" % info.total_production)
	
	if not info.biome_bonus.is_empty():
		print("Biome bonus: %s" % info.biome_bonus)
	
	if info.is_utility:
		print("Utility type: %s" % info.utility_type)
		print("Right-click to open utility menu")

# Add collision detection for interaction
func _enter_tree():
	"""Setup collision when entering tree"""
	# Add collision shape for mouse interaction
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	
	# Connect input signal
	area.input_event.connect(_on_input_event)

# DEBUG METHODS
func debug_building_state():
	"""Debug method to print building state"""
	print("=== BUILDING DEBUG: %s ===" % get_building_name())
	print("Position: %s" % tile_position)
	print("Biome: %s" % (tile.biome_type if tile else "none"))
	print("Base Production: %s" % base_production)
	print("Total Production: %s" % total_production)
	print("Biome Bonus: %s" % get_biome_bonus())
	print("Health: %d/%d" % [health, max_health])
	print("Active: %s" % is_active)
	print("===========================")
