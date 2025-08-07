# MovementManager.gd
extends Node
class_name MovementManager

signal movement_attempted(from_pos: Vector2i, to_pos: Vector2i)
signal movement_completed(new_pos: Vector2i)
signal movement_failed(reason: String)

var character: Character
var map_manager: MapManager

func initialize(char: Character, map: MapManager):
	character = char
	map_manager = map

func _input(event):
	if not character:
		return
		
	var direction = Vector2i.ZERO
	
	# Handle movement input
	if event.is_action_pressed("ui_up"):
		direction = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down"):
		direction = Vector2i(0, 1)
	elif event.is_action_pressed("ui_left"):
		direction = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right"):
		direction = Vector2i(1, 0)
	
	if direction != Vector2i.ZERO:
		attempt_move(direction)

func attempt_move(direction: Vector2i):
	# Check if character has stamina
	if character.current_stamina <= 0:
		movement_failed.emit("No stamina remaining")
		return
	
	var current_pos = character.grid_position
	var target_pos = current_pos + direction
	
	# Check if target position is valid
	if not is_valid_position(target_pos):
		movement_failed.emit("Invalid position")
		return
	
	# Emit attempt signal
	movement_attempted.emit(current_pos, target_pos)
	
	# Move character
	move_character_to(target_pos)
	
	# Spend stamina
	character.spend_stamina()
	
	# Emit completion signal
	movement_completed.emit(target_pos)

func is_valid_position(pos: Vector2i) -> bool:
	# Basic bounds checking - expand this later for terrain/obstacles
	return pos.x >= 0 and pos.x < map_manager.map_width and pos.y >= 0 and pos.y < map_manager.map_height

func move_character_to(grid_pos: Vector2i):
	character.grid_position = grid_pos
	# Convert grid position to world position (adjust tile size as needed)
	var tile_size = 32  # Adjust based on your tile size
	character.position = Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)
