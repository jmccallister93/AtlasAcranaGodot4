# MovementManager.gd
extends Node
class_name MovementManager

signal movement_attempted(from_pos: Vector2i, to_pos: Vector2i)
signal movement_completed(new_pos: Vector2i)
signal movement_failed(reason: String)
signal movement_mode_started
signal movement_mode_ended
signal movement_confirmation_requested(target_tile: BiomeTile)

enum MovementState {
	INACTIVE,
	SELECTING_TARGET,
	AWAITING_CONFIRMATION
}

var character: Character
var map_manager: MapManager
var tile_size: int = 32
var current_state: MovementState = MovementState.INACTIVE
var highlighted_tiles: Array = []
var pending_target_position: Vector2i

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
	pending_target_position = Vector2i.ZERO
	movement_mode_ended.emit()
	print("Movement mode ended")

func get_character_movement_range() -> int:
	"""Get the character's movement range from enhanced stats"""
	if character and character.stats:
		return character.stats.get_stat_value("Exploration", "Movement")
	return 3  # Default fallback

func highlight_movement_tiles():
	"""Highlight tiles within movement range"""
	clear_highlighted_tiles()
	
	var center_tile = map_manager.get_tile_at(character.grid_position)
	if not center_tile:
		return
		
	# Get tiles within movement range using enhanced stats
	var movement_range = get_character_movement_range()
	var tiles_in_range = map_manager.get_tiles_in_radius(center_tile, movement_range)
	
	for tile in tiles_in_range:
		# Don't highlight the current position
		if tile.grid_position != character.grid_position:
			tile.set_movement_highlighted(true)
			highlighted_tiles.append(tile)

func clear_highlighted_tiles():
	"""Clear all highlighted tiles"""
	for tile in highlighted_tiles:
		tile.set_movement_highlighted(false)
	highlighted_tiles.clear()

func is_tile_highlighted(target_pos: Vector2i) -> bool:
	"""Check if a tile is currently highlighted"""
	for tile in highlighted_tiles:
		if tile.grid_position == target_pos:
			return true
	return false

func attempt_move_to(target_pos: Vector2i):
	"""Attempt to move to target position - now requests confirmation first"""
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
	
	# Check if target is within movement range using enhanced stats
	var distance = abs(target_pos.x - current_pos.x) + abs(target_pos.y - current_pos.y)
	var max_movement = get_character_movement_range()
	
	if distance > max_movement:
		print("Target too far: ", distance, " max: ", max_movement)
		movement_failed.emit("Target is too far")
		return
	
	# Store the target and request confirmation
	pending_target_position = target_pos
	current_state = MovementState.AWAITING_CONFIRMATION
	
	var target_tile = map_manager.get_tile_at(target_pos)
	if target_tile:
		movement_confirmation_requested.emit(target_tile)
	else:
		movement_failed.emit("Invalid target tile")
		end_movement_mode()

func confirm_movement():
	"""Execute the confirmed movement"""
	if current_state != MovementState.AWAITING_CONFIRMATION:
		print("No movement awaiting confirmation")
		return
		
	var current_pos = character.grid_position
	var target_pos = pending_target_position
	
	# Final validation
	if character.current_action_points <= 0:
		movement_failed.emit("No action points remaining")
		end_movement_mode()
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

func cancel_movement():
	"""Cancel the pending movement and return to selection mode"""
	if current_state == MovementState.AWAITING_CONFIRMATION:
		current_state = MovementState.SELECTING_TARGET
		pending_target_position = Vector2i.ZERO
		print("Movement cancelled, returning to selection mode")

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

# Additional helper functions for enhanced stats integration
func get_character_action_points() -> int:
	"""Get current action points from character"""
	if character:
		return character.current_action_points
	return 0

func get_max_action_points() -> int:
	"""Get max action points from enhanced stats"""
	if character and character.stats:
		return character.stats.get_stat_value("Exploration", "Action_Points")
	return 5  # Default fallback

func can_character_move() -> bool:
	"""Check if character can move (has action points and movement range)"""
	return get_character_action_points() > 0 and get_character_movement_range() > 0

func get_movement_cost_to_tile(target_pos: Vector2i) -> int:
	"""Calculate movement cost to a specific tile (for future terrain-based costs)"""
	var current_pos = character.grid_position
	var distance = abs(target_pos.x - current_pos.x) + abs(target_pos.y - current_pos.y)
	
	# For now, movement cost is just the distance
	# In the future, you could add terrain modifiers here
	var target_tile = map_manager.get_tile_at(target_pos)
	#if target_tile:
		## Example: Different terrain types could have different costs
		#match target_tile.biome:
			#BiomeTile.Biome.MOUNTAIN:
				#return distance * 2  # Mountains cost double
			#BiomeTile.Biome.WATER:
				#return distance * 3  # Water costs triple (or could be impassable)
			#_:
				#return distance  # Normal cost
	
	return distance
