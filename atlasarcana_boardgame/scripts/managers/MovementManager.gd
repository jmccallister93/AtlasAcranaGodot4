# MovementManager.gd
extends Node
class_name MovementManager

signal movement_attempted(from_pos: Vector2i, to_pos: Vector2i)
signal movement_completed(new_pos: Vector2i)
signal movement_failed(reason: String)
signal movement_mode_started
signal movement_mode_ended

enum MovementState {
	INACTIVE,
	SELECTING_TARGET
}

var character: Character
var map_manager: MapManager
var tile_size: int = 32
var current_state: MovementState = MovementState.INACTIVE
var highlighted_tiles: Array[BiomeTile] = []

func initialize(char: Character, map: MapManager):
	character = char
	map_manager = map
	tile_size = map_manager.tile_size

func start_movement_mode():
	"""Start the movement selection mode"""
	if current_state != MovementState.INACTIVE:
		return
		
	if character.current_action_points <= 0:
		movement_failed.emit("No action points remaining")
		return
		
	current_state = MovementState.SELECTING_TARGET
	highlight_movement_tiles()
	movement_mode_started.emit()
	print("Movement mode started")

func end_movement_mode():
	"""End the movement selection mode"""
	current_state = MovementState.INACTIVE
	clear_highlighted_tiles()
	movement_mode_ended.emit()
	print("Movement mode ended")

func highlight_movement_tiles():
	"""Highlight tiles within movement range"""
	clear_highlighted_tiles()
	
	var center_tile = map_manager.get_tile_at(character.grid_position)
	if not center_tile:
		return
		
	# Get tiles within movement range
	var tiles_in_range = map_manager.get_tiles_in_radius(center_tile, character.stats.max_movement_points)
	
	for tile in tiles_in_range:
		# Don't highlight the current position
		if tile.grid_position != character.grid_position:
			tile.set_highlighted(true)
			highlighted_tiles.append(tile)

func clear_highlighted_tiles():
	"""Clear all highlighted tiles"""
	for tile in highlighted_tiles:
		tile.set_highlighted(false)
	highlighted_tiles.clear()

func is_tile_highlighted(target_pos: Vector2i) -> bool:
	"""Check if a tile is currently highlighted"""
	for tile in highlighted_tiles:
		if tile.grid_position == target_pos:
			return true
	return false

func attempt_move_to(target_pos: Vector2i):
	"""Attempt to move to target position"""
	print("Attempting to move to: ", target_pos)
	
	# Only allow movement if in selecting mode and tile is highlighted
	if current_state != MovementState.SELECTING_TARGET:
		print("Not in movement selection mode")
		return
		
	if not is_tile_highlighted(target_pos):
		print("Target tile is not highlighted/reachable")
		movement_failed.emit("Target tile is not reachable")
		return
	
	# Check if character has action points
	if character.current_action_points <= 0:
		print("No action points remaining")
		movement_failed.emit("No action points remaining")
		end_movement_mode()
		return
	
	var current_pos = character.grid_position
	
	# Check if target is within movement range
	var distance = abs(target_pos.x - current_pos.x) + abs(target_pos.y - current_pos.y)
	if distance > character.stats.max_movement_points:
		print("Target too far: ", distance, " max: ", character.max_movement_points)
		movement_failed.emit("Target is too far")
		return
	
	# Emit attempt signal
	movement_attempted.emit(current_pos, target_pos)
	
	# Move character
	move_character_to(target_pos)
	
	# Spend only 1 action point per move action (not per tile)
	character.spend_action_points()
	
	# End movement mode
	end_movement_mode()
	
	# Emit completion signal
	movement_completed.emit(target_pos)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / tile_size), int(world_pos.y / tile_size))
	
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * tile_size + tile_size/2, grid_pos.y * tile_size + tile_size/2)

func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < map_manager.map_width and pos.y >= 0 and pos.y < map_manager.map_height

func move_character_to(grid_pos: Vector2i):
	print("Moving character from ", character.grid_position, " to ", grid_pos)
	character.grid_position = grid_pos
	var world_pos = grid_to_world(grid_pos)
	character.global_position = world_pos
	print("Character world position set to: ", character.global_position)
