# MovementManager.gd
extends Node
class_name MovementManager

signal movement_attempted(from_pos: Vector2i, to_pos: Vector2i)
signal movement_completed(new_pos: Vector2i)
signal movement_failed(reason: String)

var character: Character
var map_manager: MapManager
var tile_size: int = 32

func initialize(char: Character, map: MapManager):
	character = char
	map_manager = map
	tile_size = map_manager.tile_size  # Get the correct tile size from MapManager

#func _input(event):
	#if not character:
		#return
		#
	## Handle left mouse click
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#print("CLICKED")
			#handle_mouse_click(event.position)



func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / tile_size), int(world_pos.y / tile_size))
	
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * tile_size + tile_size/2, grid_pos.y * tile_size + tile_size/2)

func attempt_move_to(target_pos: Vector2i):
	print("Attempting to move to: ", target_pos)
	
	# Check if character has stamina
	if character.current_stamina <= 0:
		print("No stamina remaining")
		movement_failed.emit("No stamina remaining")
		return
	
	var current_pos = character.grid_position
	
	# Calculate distance for stamina cost
	var distance = current_pos.distance_to(Vector2(target_pos))
	var stamina_cost = int(ceil(distance))
	
	print("Distance: ", distance, " Stamina cost: ", stamina_cost)
	
	# Check if character has enough stamina for the move
	if character.current_stamina < stamina_cost:
		print("Not enough stamina: ", character.current_stamina, " needed: ", stamina_cost)
		movement_failed.emit("Not enough stamina for this move")
		return
	
	# Emit attempt signal
	movement_attempted.emit(current_pos, target_pos)
	
	# Move character
	move_character_to(target_pos)
	
	# Spend stamina based on distance
	for i in stamina_cost:
		if character.current_stamina > 0:
			character.spend_stamina()
	
	# Emit completion signal
	movement_completed.emit(target_pos)

func attempt_move(direction: Vector2i):
	var target_pos = character.grid_position + direction
	attempt_move_to(target_pos)

func is_valid_position(pos: Vector2i) -> bool:
	# Basic bounds checking - expand this later for terrain/obstacles
	return pos.x >= 0 and pos.x < map_manager.map_width and pos.y >= 0 and pos.y < map_manager.map_height

func move_character_to(grid_pos: Vector2i):
	print("Moving character from ", character.grid_position, " to ", grid_pos)
	character.grid_position = grid_pos
	var world_pos = grid_to_world(grid_pos)
	character.position = world_pos
	print("Character world position set to: ", character.position)
