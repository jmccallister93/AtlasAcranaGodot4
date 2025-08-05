extends CharacterBody2D
class_name Character

@export var character_name: String = "Character"
@export var movement_points: int = 3
@export var current_movement_points: int = 3

var grid_position: Vector2i
var sprite: Sprite2D

func _ready():
	create_sprite()

func create_sprite():
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	# Set default texture or load from resource
	add_child(sprite)

func reset_movement():
	current_movement_points = movement_points
