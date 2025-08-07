# Character.gd
extends CharacterBody2D
class_name Character

signal stamina_spent(stamina: int)

@export var stats: CharacterStats
var current_stamina: int
var current_movement_points: int
var current_action_points: int
var grid_position: Vector2i
var sprite: Sprite2D

func _ready():
	if stats == null:
		push_error("Character: stats must be set before adding to scene tree")
		return
	
	initialize_from_stats()
	create_sprite()
	

func initialize_from_stats():
	current_stamina = stats.max_stamina
	current_movement_points = stats.max_movement_points
	current_action_points = stats.get_action_points()
	grid_position = Vector2i(0, 0)
	var tile_size = 64
	global_position = Vector2(
		grid_position.x * tile_size +tile_size /2,  # Center like tiles
		grid_position.y * tile_size +tile_size /2   # Center like tiles
	)

func refresh_turn_resources():
	if stats == null:
		return
	current_stamina = stats.max_stamina
	current_movement_points = stats.max_movement_points
	current_action_points = stats.get_action_points()
	
func can_perform_action(action_cost: int) -> bool:
	return current_action_points >= action_cost

func spend_action_points(cost: int) -> bool:
	if can_perform_action(cost):
		current_action_points -= cost
		return true
	return false

func spend_stamina():
	if current_stamina > 0:
		current_stamina -= 1
		stamina_spent.emit(current_stamina)
func create_sprite():
	var color_rect = ColorRect.new()
	color_rect.name = "CharacterSprite"
	color_rect.color = Color.RED
	color_rect.size = Vector2(32, 32)  
	color_rect.position = Vector2(-32, -32) 
	color_rect.z_index = 10
	
	add_child(color_rect)
	#sprite = color_rect  # If you need to reference it later
#func create_sprite():
	#sprite = Sprite2D.new()
	#sprite.name = "CharacterSprite"
	#sprite.centered = true
	#sprite.offset = Vector2.ZERO
	#sprite.position = Vector2.ZERO
	#sprite.scale = Vector2.ONE
	#sprite.z_index = 10  # Optional for rendering order
	
	#var texture_path = "res://assets/character/character_sprite.png"
	#if ResourceLoader.exists(texture_path):
		#sprite.texture = load(texture_path)
	#else:
		#push_warning("Character sprite texture not found at: " + texture_path)
	
	#add_child(sprite)
