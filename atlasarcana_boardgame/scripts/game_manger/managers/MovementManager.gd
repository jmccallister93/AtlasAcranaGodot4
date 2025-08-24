# MovementManager.gd
extends Node
class_name MovementManager

signal movement_attempted(from_pos: Vector2i, to_pos: Vector2i)
signal movement_completed(new_pos: Vector2i)
signal movement_failed(reason: String)
signal movement_mode_started
signal movement_mode_ended
signal movement_confirmation_requested(target_tile: BiomeTile3D)

enum MovementState {
	INACTIVE,
	SELECTING_TARGET,
	AWAITING_CONFIRMATION
}

var character: Character
var map_manager: MapManager3D  # Updated to use 3D map manager
var tile_size: int = 32
var current_state: MovementState = MovementState.INACTIVE
var highlighted_tiles: Array = []
var pending_target_position: Vector2i

func initialize(char: Character, map):
	"""Initialize with character and map manager (handles both 2D and 3D)"""
	character = char
	
	# Handle both MapManager and MapManager3D
	if map is MapManager3D:
		map_manager = map as MapManager3D
		tile_size = map_manager.tile_size
		print("MovementManager: Initialized with 3D map manager")
	elif map.has_method("get_tile_at"):
		# Fallback for any map manager with basic interface
		map_manager = map
		tile_size = map.tile_size if "tile_size" in map else 32
		print("MovementManager: Initialized with map manager (unknown type)")
	else:
		print("ERROR: MovementManager received invalid map manager type")

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

func get_character_tile_3d() -> BiomeTile3D:
	"""Get the current tile the character is on (3D version)"""
	if not map_manager:
		return null
	
	# Convert character's 2D position to 3D if needed
	var char_pos_3d: Vector3i
	if character.grid_position is Vector2i:
		var pos_2d = character.grid_position as Vector2i
		char_pos_3d = Vector3i(pos_2d.x, 0, pos_2d.y)
	else:
		# Assume it's already Vector3i or handle other cases
		print("Warning: Character position is not Vector2i, attempting conversion")
		char_pos_3d = Vector3i(0, 0, 0)  # Safe fallback
	
	return map_manager.get_tile_at_position(char_pos_3d)

func highlight_movement_tiles():
	"""Highlight tiles within movement range (updated for 3D)"""
	clear_highlighted_tiles()
	
	# Get current character tile
	var center_tile = null
	if map_manager.has_method("get_tile_at_position"):  # 3D version
		# Convert to 3D position if needed
		var char_pos_3d: Vector3i
		if character.grid_position is Vector2i:
			var pos_2d = character.grid_position as Vector2i
			char_pos_3d = Vector3i(pos_2d.x, 0, pos_2d.y)
		else:
			# Safe fallback if position is unexpected type
			print("Warning: Unexpected character position type in highlight_movement_tiles")
			char_pos_3d = Vector3i(0, 0, 0)
		center_tile = map_manager.get_tile_at_position(char_pos_3d)
	else:  # Fallback for 2D
		# Ensure we have Vector2i for 2D method
		var pos_2d: Vector2i
		if character.grid_position is Vector2i:
			pos_2d = character.grid_position as Vector2i
		else:
			print("Warning: Character position not Vector2i for 2D map")
			pos_2d = Vector2i(0, 0)
		center_tile = map_manager.get_tile_at(pos_2d)
	
	if not center_tile:
		print("MovementManager: Could not find character's current tile")
		return
		
	# Get tiles within movement range
	var movement_range = get_character_movement_range()
	var tiles_in_range = []
	
	# Use 3D method if available
	if map_manager.has_method("get_tiles_in_radius_3d"):
		tiles_in_range = map_manager.get_tiles_in_radius_3d(center_tile, movement_range)
	else:
		tiles_in_range = map_manager.get_tiles_in_radius(center_tile, movement_range)
	
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

func attempt_move_to(target_pos):
	"""Attempt to move to target position - handles both Vector2i and Vector3i"""
	# Convert position if needed - use safe type conversion
	var target_pos_2d: Vector2i
	var target_pos_3d: Vector3i
	
	if target_pos is Vector2i:
		target_pos_2d = target_pos as Vector2i
		target_pos_3d = Vector3i(target_pos_2d.x, 0, target_pos_2d.y)
	elif target_pos is Vector3i:
		var pos_3d = target_pos as Vector3i
		target_pos_3d = pos_3d
		target_pos_2d = Vector2i(pos_3d.x, pos_3d.z)
	else:
		print("MovementManager: Invalid target position type: ", typeof(target_pos))
		return
	
	print("Attempting to move to: ", target_pos_2d, " (3D: ", target_pos_3d, ")")
	
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
	
	# Store the target and request confirmation (use 2D for character compatibility)
	pending_target_position = target_pos_2d
	current_state = MovementState.AWAITING_CONFIRMATION
	
	# Get target tile using appropriate method
	var target_tile = null
	if map_manager.has_method("get_tile_at_position"):  # 3D version
		target_tile = map_manager.get_tile_at_position(target_pos_3d)
	else:  # 2D fallback
		target_tile = map_manager.get_tile_at(target_pos_2d)
	
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

func move_character_to(grid_pos):
	"""Move character to grid position - handles both 2D and 3D"""
	var old_pos = character.grid_position
	
	# Always store as Vector2i for character compatibility - use safe conversion
	var new_pos_2d: Vector2i
	if grid_pos is Vector2i:
		new_pos_2d = grid_pos as Vector2i
	elif grid_pos is Vector3i:
		var pos_3d = grid_pos as Vector3i
		new_pos_2d = Vector2i(pos_3d.x, pos_3d.z)
	else:
		print("MovementManager: Invalid grid position type for character movement: ", typeof(grid_pos))
		return
	
	print("Moving character from ", old_pos, " to ", new_pos_2d)
	character.grid_position = new_pos_2d
	
	# Set world position (use 2D method for compatibility)
	var world_pos = grid_to_world(new_pos_2d)
	character.global_position = world_pos
	print("Character world position set to: ", character.global_position)

# 3D-compatible coordinate conversion methods
func world_to_grid_3d(world_pos: Vector3) -> Vector3i:
	"""Convert 3D world position to 3D grid coordinates"""
	if map_manager and map_manager.has_method("world_to_grid"):
		return map_manager.world_to_grid(world_pos)
	else:
		# Fallback calculation
		return Vector3i(
			int(world_pos.x / tile_size),
			0,
			int(world_pos.z / tile_size)
		)

func grid_to_world_3d(grid_pos: Vector3i) -> Vector3:
	"""Convert 3D grid position to 3D world coordinates"""
	if map_manager and map_manager.has_method("grid_to_world"):
		return map_manager.grid_to_world(grid_pos)
	else:
		# Fallback calculation
		return Vector3(
			grid_pos.x * tile_size,
			0,
			grid_pos.z * tile_size
		)
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

func get_movement_cost_to_tile(target_pos) -> int:
	"""Calculate movement cost to a specific tile (handles both 2D and 3D)"""
	# Convert positions to common format - use safe conversion
	var current_pos_2d: Vector2i
	var target_pos_2d: Vector2i
	
	# Get current position safely
	if character.grid_position is Vector2i:
		current_pos_2d = character.grid_position as Vector2i
	else:
		print("MovementManager: Character position not Vector2i in get_movement_cost_to_tile")
		current_pos_2d = Vector2i(0, 0)
	
	# Convert target position safely
	if target_pos is Vector2i:
		target_pos_2d = target_pos as Vector2i
	elif target_pos is Vector3i:
		var pos_3d = target_pos as Vector3i
		target_pos_2d = Vector2i(pos_3d.x, pos_3d.z)
	else:
		print("MovementManager: Invalid target position type: ", typeof(target_pos))
		return 999  # High cost for invalid positions
	
	var distance = abs(target_pos_2d.x - current_pos_2d.x) + abs(target_pos_2d.y - current_pos_2d.y)
	
	# Get target tile for terrain cost calculation
	var target_tile = null
	if map_manager.has_method("get_tile_at_position"):  # 3D version
		var target_pos_3d = Vector3i(target_pos_2d.x, 0, target_pos_2d.y)
		target_tile = map_manager.get_tile_at_position(target_pos_3d)
	elif map_manager.has_method("get_tile_at"):  # 2D version
		target_tile = map_manager.get_tile_at(target_pos_2d)
	
	if target_tile and "movement_cost" in target_tile:
		return int(distance * target_tile.movement_cost)
	
	return distance
