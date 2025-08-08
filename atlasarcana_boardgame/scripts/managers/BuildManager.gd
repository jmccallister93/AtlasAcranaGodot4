# BuildManager.gd
extends Node
class_name BuildManager

# Signals similar to MovementManager
signal building_attempted(target_pos: Vector2i, building_type: String)
signal building_completed(new_building: Building, tile: BiomeTile)
signal building_placed
signal building_failed(reason: String)
signal build_mode_started
signal build_mode_ended
signal build_mode_failed
signal build_confirmation_requested(target_tile: BiomeTile, building_type: String)

# Build mode states
enum BuildState {
	INACTIVE,
	SELECTING_TARGET,
	AWAITING_CONFIRMATION
}

# References
var character: Character
var map_manager: MapManager
var current_state: BuildState = BuildState.INACTIVE
var highlighted_tiles: Array[BiomeTile] = []
var pending_target_position: Vector2i
var pending_building_type: String = "basic_structure"  # Default building type

# Building storage (your existing code)
var buildings_by_tile: Dictionary = {}  # Vector2i -> Array[Building]
var buildings_by_type: Dictionary = {}  # String -> Array[Building]

func initialize(char: Character, map: MapManager):
	"""Initialize the build manager with character and map references"""
	character = char
	map_manager = map

func start_build_mode():
	"""Start the building selection mode"""
	if current_state != BuildState.INACTIVE:
		return
		
	if character.current_action_points <= 0:
		build_mode_failed.emit("No action points remaining")
		return
		
	current_state = BuildState.SELECTING_TARGET
	highlight_adjacent_tiles()
	build_mode_started.emit()
	print("Build mode started")

func end_build_mode():
	"""End the building selection mode"""
	current_state = BuildState.INACTIVE
	clear_highlighted_tiles()
	pending_target_position = Vector2i.ZERO
	pending_building_type = "basic_structure"
	build_mode_ended.emit()
	print("Build mode ended")

func highlight_adjacent_tiles():
	"""Highlight tiles adjacent to the character for building"""
	clear_highlighted_tiles()
	
	var character_pos = character.grid_position
	
	# Get all 8 adjacent tiles (including diagonals)
	var adjacent_directions = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),  # Top row
		Vector2i(-1,  0),                  Vector2i(1,  0),  # Middle row (excluding center)
		Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1)   # Bottom row
	]
	
	for direction in adjacent_directions:
		var tile_pos = character_pos + direction
		var tile = map_manager.get_tile_at(tile_pos)
		
		if tile and can_build_on_tile(tile):
			tile.set_build_highlighted(true)  # Different highlight method for building
			highlighted_tiles.append(tile)

func clear_highlighted_tiles():
	"""Clear all highlighted tiles"""
	for tile in highlighted_tiles:
		tile.set_build_highlighted(false)
	highlighted_tiles.clear()

func can_build_on_tile(tile: BiomeTile) -> bool:
	"""Check if building is allowed on this tile"""
	# Don't allow building on character's current position
	if tile.grid_position == character.grid_position:
		return false
	
	# Don't allow building on occupied tiles
	if tile.is_occupied:
		return false
	
	# Don't allow building on water (unless it's a dock)
	if tile.biome_type == BiomeTile.BiomeType.WATER:
		return false
	
	# Add any other building restrictions here
	return true

func is_tile_highlighted(target_pos: Vector2i) -> bool:
	"""Check if a tile is currently highlighted for building"""
	for tile in highlighted_tiles:
		if tile.grid_position == target_pos:
			return true
	return false

func attempt_build_at(target_pos: Vector2i):
	"""Attempt to build at target position - requests confirmation first"""
	print("Attempting to build at: ", target_pos)
	
	# Only allow building if in selecting mode and tile is highlighted
	if current_state != BuildState.SELECTING_TARGET:
		print("Not in build selection mode")
		return
		
	if not is_tile_highlighted(target_pos):
		print("Target tile is not highlighted/buildable")
		building_failed.emit("Target tile is not buildable")
		return
	
	# Check if character has action points
	if character.current_action_points <= 0:
		print("No action points remaining")
		building_failed.emit("No action points remaining")
		end_build_mode()
		return
	
	# Store the target and request confirmation
	pending_target_position = target_pos
	current_state = BuildState.AWAITING_CONFIRMATION
	
	var target_tile = map_manager.get_tile_at(target_pos)
	if target_tile:
		build_confirmation_requested.emit(target_tile, pending_building_type)
	else:
		building_failed.emit("Invalid target tile")
		end_build_mode()

func confirm_building():
	"""Execute the confirmed building placement"""
	if current_state != BuildState.AWAITING_CONFIRMATION:
		print("No building awaiting confirmation")
		return
		
	var target_pos = pending_target_position
	var building_type = pending_building_type
	
	# Final validation
	if character.current_action_points <= 0:
		building_failed.emit("No action points remaining")
		end_build_mode()
		return
	
	var target_tile = map_manager.get_tile_at(target_pos)
	if not target_tile or not can_build_on_tile(target_tile):
		building_failed.emit("Cannot build on target tile")
		end_build_mode()
		return
	
	# Emit attempt signal
	building_attempted.emit(target_pos, building_type)
	
	# Create and place the building
	var success = place_building(building_type, target_tile)
	
	if success:
		# Spend action point
		character.spend_action_points()
		
		# End build mode
		end_build_mode()
		
		# Emit completion signal
		var placed_buildings = get_buildings_on_tile(target_tile)
		if placed_buildings.size() > 0:
			building_completed.emit(placed_buildings[-1], target_tile)
	else:
		building_failed.emit("Failed to place building")
		end_build_mode()

func cancel_building():
	"""Cancel the pending building and return to selection mode"""
	if current_state == BuildState.AWAITING_CONFIRMATION:
		current_state = BuildState.SELECTING_TARGET
		pending_target_position = Vector2i.ZERO
		print("Building cancelled, returning to selection mode")

# Your existing building placement code (enhanced)
func place_building(building_type: String, tile: BiomeTile) -> bool:
	"""Place a building on the specified tile"""
	if not tile.can_place_building(building_type):
		return false
	
	var building = create_building(building_type, tile)
	if building:
		add_building_to_tile(building, tile)
		building_placed.emit(building, tile)
		print("Building placed: ", building_type, " at ", tile.grid_position)
		return true
	
	return false

func create_building(building_type: String, tile: BiomeTile) -> Building:
	"""Create a building instance"""
	# For now, create a simple visual placeholder instead of full Building class
	var building = create_placeholder_building(building_type, tile)
	return building

func create_placeholder_building(building_type: String, tile: BiomeTile) -> Building:
	"""Create a placeholder building (purple square for now)"""
	var building = Building.new()
	building.building_type = building_type
	building.tile_position = tile.grid_position
	
	# Create visual representation (purple square)
	var visual = ColorRect.new()
	visual.color = Color.PURPLE
	visual.size = Vector2(32, 32)
	visual.position = Vector2(-16, -16)  # Center on building
	visual.z_index = 15
	building.add_child(visual)
	
	# FIX: Position building using same method as character movement
	var world_pos = Vector2(
		tile.grid_position.x * map_manager.tile_size + map_manager.tile_size/2,
		tile.grid_position.y * map_manager.tile_size + map_manager.tile_size/2
	)
	building.global_position = world_pos
	
	# FIX: Add to map_manager instead of tile
	map_manager.add_child(building)
	
	return building
	
func add_building_to_tile(building: Building, tile: BiomeTile):
	"""Add building to tracking dictionaries"""
	var grid_pos = tile.grid_position
	
	if grid_pos not in buildings_by_tile:
		buildings_by_tile[grid_pos] = []
	buildings_by_tile[grid_pos].append(building)
	
	if building.building_type not in buildings_by_type:
		buildings_by_type[building.building_type] = []
	buildings_by_type[building.building_type].append(building)
	
	tile.is_occupied = true

# Your existing getter methods
func get_buildings_on_tile(tile: BiomeTile) -> Array[Building]:
	var buildings = buildings_by_tile.get(tile.grid_position, [])
	var result: Array[Building] = []
	result.assign(buildings)
	return result

func get_buildings_of_type(building_type: String) -> Array[Building]:
	var buildings = buildings_by_type.get(building_type, [])
	var result: Array[Building] = []
	result.assign(buildings)
	return result

# Utility methods
func get_adjacent_positions(center_pos: Vector2i) -> Array[Vector2i]:
	"""Get all adjacent positions around a center position"""
	var adjacent_positions: Array[Vector2i] = []
	var directions = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1,  0),                  Vector2i(1,  0),
		Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1)
	]
	
	for direction in directions:
		adjacent_positions.append(center_pos + direction)
	
	return adjacent_positions

func set_building_type(building_type: String):
	"""Set the type of building to place"""
	pending_building_type = building_type
	print("Building type set to: ", building_type)

# Debug methods
func debug_print_state():
	"""Print current state for debugging"""
	print("=== BuildManager State ===")
	print("Current state: ", current_state)
	print("Highlighted tiles: ", highlighted_tiles.size())
	print("Pending building: ", pending_building_type)
	print("Buildings placed: ", buildings_by_tile.size())
	print("===========================")
