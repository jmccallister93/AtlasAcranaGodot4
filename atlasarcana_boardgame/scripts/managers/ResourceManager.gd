# ResourceManager.gd
extends Node
class_name ResourceManager

signal resource_changed(resource_name: String, new_amount: int)
signal resources_spent(spent_resources: Dictionary)
signal insufficient_resources(required: Dictionary, available: Dictionary)

# Player resources
var resources: Dictionary = {
	"essence": 100,
	"gold": 200,      # Starting gold for building
	"food": 10,
	"wood": 15,
	"stone": 5,
	"metal": 0
}

# Resource display names
var resource_display_names: Dictionary = {
	"essence": "Essence",
	"gold": "Gold",
	"food": "Food", 
	"wood": "Wood",
	"stone": "Stone",
	"metal": "Metal"
}

func _ready():
	print("ResourceManager initialized with starting resources: ", resources)

func add_resource(resource_name: String, amount: int):
	"""Add resources to the player's inventory"""
	if amount <= 0:
		return
		
	if resource_name in resources:
		resources[resource_name] += amount
	else:
		resources[resource_name] = amount
	
	resource_changed.emit(resource_name, resources[resource_name])
	print("Added %d %s (Total: %d)" % [amount, resource_name, resources[resource_name]])

func spend_resource(resource_name: String, amount: int) -> bool:
	"""Spend a single resource - returns true if successful"""
	if not has_resource(resource_name, amount):
		return false
	
	resources[resource_name] -= amount
	resource_changed.emit(resource_name, resources[resource_name])
	print("Spent %d %s (Remaining: %d)" % [amount, resource_name, resources[resource_name]])
	return true

func spend_resources(cost: Dictionary) -> bool:
	"""Spend multiple resources - returns true if successful"""
	# First check if we can afford everything
	if not can_afford(cost):
		insufficient_resources.emit(cost, resources.duplicate())
		return false
	
	# Spend all resources
	var spent = {}
	for resource_name in cost:
		var amount = cost[resource_name]
		if spend_resource(resource_name, amount):
			spent[resource_name] = amount
		else:
			# This shouldn't happen if can_afford worked correctly
			print("Error: Failed to spend %s after affordability check" % resource_name)
			return false
	
	resources_spent.emit(spent)
	return true

func has_resource(resource_name: String, amount: int) -> bool:
	"""Check if player has enough of a specific resource"""
	return resources.get(resource_name, 0) >= amount

func can_afford(cost: Dictionary) -> bool:
	"""Check if player can afford a cost dictionary"""
	for resource_name in cost:
		var required = cost[resource_name]
		if not has_resource(resource_name, required):
			return false
	return true

func get_resource(resource_name: String) -> int:
	"""Get the current amount of a resource"""
	return resources.get(resource_name, 0)

func get_all_resources() -> Dictionary:
	"""Get a copy of all current resources"""
	return resources.duplicate()

func set_resource(resource_name: String, amount: int):
	"""Set a resource to a specific amount"""
	var old_amount = resources.get(resource_name, 0)
	resources[resource_name] = max(0, amount)  # Prevent negative resources
	
	if old_amount != resources[resource_name]:
		resource_changed.emit(resource_name, resources[resource_name])

func get_resource_display_name(resource_name: String) -> String:
	"""Get the display name for a resource"""
	return resource_display_names.get(resource_name, resource_name.capitalize())

# Debug and utility methods
func debug_print_resources():
	"""Print all current resources for debugging"""
	print("=== CURRENT RESOURCES ===")
	for resource_name in resources:
		print("%s: %d" % [get_resource_display_name(resource_name), resources[resource_name]])
	print("=========================")

func debug_add_resources(amount: int = 100):
	"""Debug method to add resources"""
	for resource_name in resources:
		add_resource(resource_name, amount)
	print("Added %d to all resources" % amount)

func reset_resources():
	"""Reset resources to starting values"""
	resources = {
		"gold": 200,
		"food": 10,
		"wood": 10,
		"stone": 10,
		"metal": 10
	}
	
	# Emit signals for all resources
	for resource_name in resources:
		resource_changed.emit(resource_name, resources[resource_name])
	
	print("Resources reset to starting values")

# Resource income calculations
func calculate_total_income() -> Dictionary:
	"""Calculate total resource income per turn from all sources"""
	var total_income = {}
	
	# Get income from buildings
	if GameManager and GameManager.build_manager:
		var building_income = GameManager.build_manager.get_total_production_per_turn()
		for resource in building_income:
			total_income[resource] = total_income.get(resource, 0) + building_income[resource]
	
	# Add other income sources here (base income, etc.)
	# For example, base gold income:
	total_income["gold"] = total_income.get("gold", 0) + 5  # Base 5 gold per turn
	
	return total_income

func apply_turn_income():
	"""Apply per-turn resource income"""
	var income = calculate_total_income()
	
	if income.is_empty():
		return
	
	print("=== TURN INCOME ===")
	for resource_name in income:
		var amount = income[resource_name]
		add_resource(resource_name, amount)
		print("+%d %s" % [amount, get_resource_display_name(resource_name)])
	print("===================")

# Resource validation
func validate_resources():
	"""Ensure all resources are non-negative"""
	for resource_name in resources:
		if resources[resource_name] < 0:
			print("Warning: Negative resource detected: %s = %d" % [resource_name, resources[resource_name]])
			resources[resource_name] = 0
			resource_changed.emit(resource_name, 0)
