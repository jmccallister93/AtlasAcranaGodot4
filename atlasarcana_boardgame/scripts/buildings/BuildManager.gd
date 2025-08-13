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
signal building_data_changed


# Build mode states
enum BuildState {
	INACTIVE,
	SELECTING_TARGET,
	SELECTING_BUILDING,
	AWAITING_CONFIRMATION
}

# References
var character: Character
var map_manager: MapManager
var current_state: BuildState = BuildState.INACTIVE
var highlighted_tiles: Array[BiomeTile] = []
var pending_target_position: Vector2i
var pending_building_type: BuildingData.BuildingType = BuildingData.BuildingType.BASIC_STRUCTURE

# Building selection menu
var building_selection_menu: BuildingSelectionMenu

# Building storage
var buildings_by_tile: Dictionary = {}  # Vector2i -> Array[Building]
var buildings_by_type: Dictionary = {}  # String -> Array[Building]
#UI Layering
var ui_layer: CanvasLayer

func initialize(char: Character, map: MapManager):
	"""Initialize the build manager with character and map references"""
	character = char
	map_manager = map
	
	# Connect to movement manager for position updates
	#if GameManager and GameManager.movement_manager:
	GameManager.manager_registry.movement_manager.movement_completed.connect(_on_character_moved)
	
	
	# Create building selection menu
	create_building_selection_menu()
	

func _on_character_moved(new_position: Vector2i):
	"""Handle character movement - update highlighted tiles if in build mode"""
	if current_state == BuildState.SELECTING_TARGET:
		print("Character moved to ", new_position, " - updating build highlights")
		update_highlighted_tiles()

func create_building_selection_menu():
	"""Create the building selection menu"""
	building_selection_menu = BuildingSelectionMenu.new()
	building_selection_menu.building_selected.connect(_on_building_selected)
	building_selection_menu.menu_closed.connect(_on_building_menu_closed)
	
	# Create a CanvasLayer for UI to ensure proper positioning
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 100  # High layer to ensure it's on top
	ui_layer.name = "BuildingMenuUILayer"
	
	# Add both to scene tree
	get_tree().current_scene.add_child(ui_layer)
	ui_layer.add_child(building_selection_menu)
	
	print("Building selection menu added to UI layer for proper positioning")

func start_build_mode():
	"""Start the building selection mode"""
	if current_state != BuildState.INACTIVE:
		return
		
	if character.current_action_points <= 0:
		build_mode_failed.emit("No action points remaining")
		return
		
	current_state = BuildState.SELECTING_TARGET
	update_highlighted_tiles()
	build_mode_started.emit()
	print("Build mode started - select a tile to build on")

func end_build_mode():
	"""End the building selection mode"""
	current_state = BuildState.INACTIVE
	clear_highlighted_tiles()
	pending_target_position = Vector2i.ZERO
	pending_building_type = BuildingData.BuildingType.BASIC_STRUCTURE
	
	# Hide building selection menu if open
	if building_selection_menu and building_selection_menu.visible:
		building_selection_menu.hide_menu()
	
	build_mode_ended.emit()
	print("Build mode ended")

func update_highlighted_tiles():
	"""Update highlighted tiles (used when build mode starts or character moves)"""
	clear_highlighted_tiles()
	highlight_adjacent_tiles()

func highlight_adjacent_tiles():
	"""Highlight tiles adjacent to the character for building"""
	var character_pos = character.grid_position
	print("Highlighting tiles adjacent to character at: ", character_pos)
	
	# Get all 8 adjacent tiles (including diagonals)
	var adjacent_directions = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),  # Top row
		Vector2i(-1,  0),                  Vector2i(1,  0),  # Middle row (excluding center)
		Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1)   # Bottom row
	]
	
	var tiles_highlighted = 0
	for direction in adjacent_directions:
		var tile_pos = character_pos + direction
		var tile = map_manager.get_tile_at(tile_pos)
		
		if tile and can_build_on_tile(tile):
			tile.set_build_highlighted(true)
			highlighted_tiles.append(tile)
			tiles_highlighted += 1
			print("Highlighted tile at: ", tile_pos, " (", tile.biome_type, ")")
	
	print("Total tiles highlighted: ", tiles_highlighted)

func clear_highlighted_tiles():
	"""Clear all highlighted tiles"""
	print("Clearing ", highlighted_tiles.size(), " highlighted tiles")
	for tile in highlighted_tiles:
		tile.set_build_highlighted(false)
	highlighted_tiles.clear()

func can_build_on_tile(tile: BiomeTile) -> bool:
	
	# Don't allow building on occupied tiles
	if tile.is_occupied:
		return false
	
	# Check if any buildings can be built on this biome type
	var building_definitions = BuildingData.get_building_definitions()
	for building_type in building_definitions:
		if BuildingData.can_build_on_biome(building_type, tile.biome_type):
			return true
	
	return false

func is_tile_highlighted(target_pos: Vector2i) -> bool:
	"""Check if a tile is currently highlighted for building"""
	for tile in highlighted_tiles:
		if tile.grid_position == target_pos:
			return true
	return false

func attempt_build_at(target_pos: Vector2i):
	"""Attempt to build at target position - show building selection menu"""
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
	
	# Store the target and show building selection menu
	pending_target_position = target_pos
	current_state = BuildState.SELECTING_BUILDING
	
	var target_tile = map_manager.get_tile_at(target_pos)
	if target_tile:
		# Get player resources from GameManager
		var player_resources = GameManager.get_all_resources()
		building_selection_menu.show_menu_with_data(target_tile, player_resources)
	else:
		building_failed.emit("Invalid target tile")
		end_build_mode()

func _on_building_selected(building_type: BuildingData.BuildingType):
	"""Handle building selection from menu"""
	print("Building selected: ", building_type)
	pending_building_type = building_type
	
	# Move to confirmation state
	current_state = BuildState.AWAITING_CONFIRMATION
	
	var target_tile = map_manager.get_tile_at(pending_target_position)
	if target_tile:
		var building_data = BuildingData.get_building_data(building_type)
		var building_name = building_data.get("name", "Unknown")
		build_confirmation_requested.emit(target_tile, building_name)
	else:
		building_failed.emit("Invalid target tile")
		end_build_mode()

func _on_building_menu_closed():
	"""Handle building menu being closed"""
	if current_state == BuildState.SELECTING_BUILDING:
		# Return to target selection
		current_state = BuildState.SELECTING_TARGET
		print("Building selection cancelled, returning to target selection")

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
	
	# Check if player can afford the building
	var building_cost = BuildingData.get_building_cost(building_type)
	if not GameManager.can_afford(building_cost):
		building_failed.emit("Not enough resources to build")
		end_build_mode()
		return
	
	# Emit attempt signal
	var building_data = BuildingData.get_building_data(building_type)
	var building_name = building_data.get("name", "Unknown")
	building_attempted.emit(target_pos, building_name)
	
	# Create and place the building
	var success = place_building(building_type, target_tile)
	
	if success:
		# Spend resources
		GameManager.spend_resources(building_cost)
		
		# Spend action point
		character.spend_action_points()
		
		# Get the placed building
		var placed_buildings = get_buildings_on_tile(target_tile)
		var new_building = placed_buildings[-1] if placed_buildings.size() > 0 else null
		
		# Emit completion signals
		if new_building:
			building_completed.emit(new_building, target_tile)
			building_data_changed.emit()  # New signal for menu updates
		
		# End build mode
		end_build_mode()
	else:
		building_failed.emit("Failed to place building")
		end_build_mode()
func cancel_building():
	"""Cancel the pending building and return to selection mode"""
	if current_state == BuildState.AWAITING_CONFIRMATION:
		current_state = BuildState.SELECTING_TARGET
		pending_target_position = Vector2i.ZERO
		print("Building cancelled, returning to target selection mode")

# Enhanced building placement
func place_building(building_type: BuildingData.BuildingType, tile: BiomeTile) -> bool:
	"""Place a building on the specified tile"""
	var building_data = BuildingData.get_building_data(building_type)
	
	# Check if building can be placed on this biome
	if not BuildingData.can_build_on_biome(building_type, tile.biome_type):
		print("Cannot build %s on %s biome" % [building_data.get("name", "Unknown"), tile.biome_type])
		return false
	
	var building = create_building(building_type, tile)
	if building:
		add_building_to_tile(building, tile)
		building_placed.emit(building, tile)
		print("Building placed: ", building_data.get("name", "Unknown"), " at ", tile.grid_position)
		return true
	
	return false

func create_building(building_type: BuildingData.BuildingType, tile: BiomeTile) -> Building:
	"""Create a building instance"""
	var building = Building.new()
	building.initialize(building_type, tile)
	
	# Position building using same method as character movement
	var world_pos = Vector2(
		tile.grid_position.x * map_manager.tile_size + map_manager.tile_size/2,
		tile.grid_position.y * map_manager.tile_size + map_manager.tile_size/2
	)
	building.global_position = world_pos
	
	# Add to map_manager
	map_manager.add_child(building)
	
	return building
	
func add_building_to_tile(building: Building, tile: BiomeTile):
	"""Add building to tracking dictionaries"""
	var grid_pos = tile.grid_position
	
	if grid_pos not in buildings_by_tile:
		buildings_by_tile[grid_pos] = []
	buildings_by_tile[grid_pos].append(building)
	
	# Use the building's actual name for consistent tracking
	var building_name = building.get_building_name()
	if building_name not in buildings_by_type:
		buildings_by_type[building_name] = []
	buildings_by_type[building_name].append(building)
	
	tile.is_occupied = true
	
	print("Building added to tracking: %s at %s" % [building_name, grid_pos])
# Building query methods
func get_buildings_on_tile(tile: BiomeTile) -> Array[Building]:
	var buildings = buildings_by_tile.get(tile.grid_position, [])
	var result: Array[Building] = []
	result.assign(buildings)
	return result

func get_buildings_of_type(building_type: String) -> Array[Building]:
	"""Get buildings by their display name (string) rather than enum"""
	var buildings = buildings_by_type.get(building_type, [])  # ✅ Fixed
	var result: Array[Building] = []
	result.assign(buildings)
	return result

func get_total_production_per_turn() -> Dictionary:
	"""Get total resource production from all buildings"""
	var total_production = {}
	
	for tile_pos in buildings_by_tile:
		var buildings = buildings_by_tile[tile_pos]
		for building in buildings:
			var production = building.get_production()
			for resource in production:
				if resource in total_production:
					total_production[resource] += production[resource]
				else:
					total_production[resource] = production[resource]
	
	return total_production

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

func set_building_type(building_type: BuildingData.BuildingType):
	"""Set the type of building to place"""
	pending_building_type = building_type
	var building_data = BuildingData.get_building_data(building_type)
	print("Building type set to: ", building_data.get("name", "Unknown"))

func get_buildings_of_type_by_name(building_name: String) -> Array[Building]:
	"""Get buildings by their display name (string) rather than enum"""
	var buildings = buildings_by_type.get(building_name, [])
	var result: Array[Building] = []
	result.assign(buildings)
	return result
# Add method to get all building type names
func get_all_building_type_names() -> Array[String]:
	"""Get all building type names that have been placed"""
	var names: Array[String] = []
	names.assign(buildings_by_type.keys())
	return names

# Add method to get total count of all buildings
func get_total_building_count() -> int:
	"""Get total number of buildings placed"""
	var total = 0
	for building_list in buildings_by_tile.values():
		total += building_list.size()
	return total
# Debug methods
func debug_print_state():
	"""Print current state for debugging"""
	print("=== BuildManager State ===")
	print("Current state: ", current_state)
	print("Highlighted tiles: ", highlighted_tiles.size())
	var building_data = BuildingData.get_building_data(pending_building_type)
	print("Pending building: ", building_data.get("name", "Unknown"))
	print("Buildings placed: ", buildings_by_tile.size())
	
	# Show total production
	var total_production = get_total_production_per_turn()
	print("Total production per turn: ", total_production)
	print("===========================")

# Update debug method to show more info
func debug_list_all_buildings():
	"""Debug method to list all placed buildings"""
	print("=== ALL BUILDINGS ===")
	print("Total buildings: ", get_total_building_count())
	print("Building types: ", get_all_building_type_names())
	
	for tile_pos in buildings_by_tile:
		var buildings = buildings_by_tile[tile_pos]
		for building in buildings:
			var building_name = building.get_building_name()
			var production = building.get_production()
			print("- %s at %s (Production: %s)" % [building_name, tile_pos, production])
	print("====================")


func _exit_tree():
	if ui_layer and is_instance_valid(ui_layer):
		ui_layer.queue_free()
