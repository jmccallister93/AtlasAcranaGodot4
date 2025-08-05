extends Node2D
class_name Building

@export var building_type: String = "farm"
@export var production_output: Dictionary = {}
@export var tile_position: Vector2i

var sprite: Sprite2D

func _ready():
	create_sprite()

func create_sprite():
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	# Load texture based on building_type
	add_child(sprite)

func get_production() -> Dictionary:
	return production_output.duplicate()
