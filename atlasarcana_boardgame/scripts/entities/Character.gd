# Character.gd
extends CharacterBody2D
class_name Character

@export var stats: CharacterStats
var current_stamina: int
var current_movement_points: int
var current_action_points: int
var grid_position: Vector2i
var sprite: Sprite2D

func _ready():
	if stats:
		initialize_from_stats()
	create_sprite()

func initialize_from_stats():
	current_stamina = stats.max_stamina
	current_movement_points = stats.max_movement_points
	current_action_points = stats.get_action_points()

func refresh_turn_resources():
	current_movement_points = stats.max_movement_points
	current_action_points = stats.get_action_points()

func can_perform_action(action_cost: int) -> bool:
	return current_action_points >= action_cost

func spend_action_points(cost: int) -> bool:
	if can_perform_action(cost):
		current_action_points -= cost
		return true
	return false

func create_sprite():
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	add_child(sprite)
