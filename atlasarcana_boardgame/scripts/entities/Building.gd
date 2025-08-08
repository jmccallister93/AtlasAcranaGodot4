# Building.gd
extends Node2D
class_name Building

# Building properties
var building_type: String = ""
var tile_position: Vector2i
var is_active: bool = true
var health: int = 100
var max_health: int = 100

# Building stats (can be expanded later)
var production_rate: float = 1.0
var maintenance_cost: int = 0
var construction_cost: Dictionary = {}

# Visual components
var sprite: Sprite2D
var health_bar: ProgressBar

func _ready():
	create_visual_components()

func create_visual_components():
	"""Create basic visual representation"""
	# This is handled by BuildManager for now with the purple square
	# Later you can expand this to have proper sprites, animations, etc.
	pass

func get_production() -> Dictionary:
	"""Get what this building produces per turn"""
	# Placeholder - expand based on building type
	match building_type:
		"basic_structure":
			return {"test_resource": 1}
		_:
			return {}

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
	queue_free()

func get_info() -> Dictionary:
	"""Get building information for UI display"""
	return {
		"type": building_type,
		"position": tile_position,
		"health": health,
		"max_health": max_health,
		"is_active": is_active
	}
