## BuildManager.gd - 3D Compatible Building System Manager
#extends Node
#class_name BuildManager
#
## Signals for building system events
#signal building_attempted(character: Character, building_type: String, position)
#signal building_completed(character: Character, building: Building, position)
#signal building_failed(reason: String)
#signal build_mode_started
#signal build_mode_ended
#signal build_confirmation_requested(target_tile, building_type: String)
#
## Building mode states
#enum BuildState {
	#INACTIVE,
	#SELECTING_LOCATION,
	#AWAITING_CONFIRMATION
#}
#
## References
#var character: Character
#var map_manager: MapManager3D  # Updated for 3D compatibility
#var current_state: BuildState = BuildState.INACTIVE
#var highlighted_tiles: Array = []
#var pending_target_position: Vector2i
#var pending_building_type: String
#
## Building system data
#var available_buildings: Dictionary = {}
#var placed_buildings: Dictionary = {}  # Vector2i -> Building
#var building_recipes: Dictionary = {}
#
#func _ready():
	#"""Initialize the build manager"""
	#setup_building_definitions()
	#print("BuildManager initialized with 3D compatibility")
#
#func initialize(char: Character, map):
	#"""Initialize the build manager with character and map references (3D compatible)"""
	#character = char
	#
	## Handle both MapManager and MapManager3D
	#if map is MapManager3D:
		#map_manager = map as MapManager3D
		#print("BuildManager: Initialized with 3D map manager")
	#elif map.has_method("get_tile_at"):
		#map_manager = map
		#print("BuildManager: Initialized with legacy map manager")
	#else:
		#print("ERROR: BuildManager received invalid map manager type")
#
#func setup_building_definitions():
	#"""Setup available building types and their requirements"""
	## Basic buildings
	#available_buildings["farm"] = {
		#"name": "Farm",
		#"description": "Produces food over time",
		#"cost": {"wood": 2, "stone": 1},
		#"size": Vector2i(1, 1),  # 1x1 building
		#"allowed_biomes": ["grassland", "plains"],
		#"production": {"food": 2},
		#"build_time": 3
	#}
	#
	#available_buildings["lumber_mill"] = {
		#"name": "Lumber Mill",
		#"description": "Processes wood more efficiently",
		#"cost": {"wood": 3, "stone": 2},
		#"size": Vector2i(2, 1),  # 2x1 building
		#"allowed_biomes": ["forest"],
		#"production": {"wood": 3},
		#"build_time": 4
	#}
	#
	#available_buildings["mine"] = {
		#"name": "Mine",
		#"description": "Extracts stone and metal from mountains",
		#"cost": {"wood": 2, "stone": 3},
		#"size": Vector2i(1, 1),
		#"allowed_biomes": ["mountain"],
		#"production": {"stone": 2, "metal": 1},
		#"build_time": 5
	#}
	#
	#available_buildings["watchtower"] = {
		#"name": "Watchtower",
		#"description": "Provides vision and early warning",
		#"cost": {"wood": 4, "stone": 4},
		#"size": Vector2i(1, 1),
		#"allowed_biomes": ["grassland", "plains", "forest", "mountain"],
		#"production": {},
		#"build_time": 6,
		#"special_effects": ["vision_range_increase"]
	#}
#
#func start_build_mode(building_type: String = ""):
	#"""Start the building placement mode"""
	#if current_state != BuildState.INACTIVE:
		#return
		#
	#if character.current_action_points <= 0:
		#building_failed.emit("No action points remaining")
		#return
		#
	## Set building type if provided, otherwise let UI handle selection
	#if building_type != "" and building_type in available_buildings:
		#pending_building_type = building_type
	#
	#current_state = BuildState.SELECTING_LOCATION
	#highlight_buildable_tiles()
	#build_mode_started.emit()
	#print("Build mode started for: ", pending_building_type if pending_building_type else "unspecified")
#
#func end_build_mode():
	#"""End the building placement mode"""
	#current_state = BuildState.INACTIVE
	#clear_highlighted_tiles()
	#pending_target_position = Vector2i.ZERO
	#pending_building_type = ""
	#build_mode_ended.emit()
	#print("Build mode ended")
#
#func set_building_type(building_type: String):
	#"""Set the type of building to place"""
	#if building_type in available_buildings:
		#pending_building_type = building_type
		#if current_state == BuildState.SELECTING_LOCATION:
			## Refresh highlights for new building type
			#highlight_buildable_tiles()
	#else:
		#print("BuildManager: Unknown building type: ", building_type)
#
#func get_character_grid_position_3d() -> Vector3i:
	#"""Get character position as 3D coordinates"""
	#if character.grid_position is Vector2i:
		#var pos_2d = character.grid_position as Vector2i
		#return Vector3i(pos_2d.x, 0, pos_2d.y)
	#else:
		#print("Warning: Character position is not Vector2i in BuildManager")
		#return Vector3i(0, 0, 0)  # Safe fallback
#
#func highlight_buildable_tiles():
	#"""Highlight tiles where buildings can be placed (3D compatible)"""
	#clear_highlighted_tiles()
	#
	#if pending_building_type == "":
		#print("BuildManager: No building type selected")
		#return
	#
	## Get character position in both formats - use safe conversion
	#var character_pos_2d: Vector2i
	#var character_pos_3d: Vector3i
	#
	#if character.grid_position is Vector2i:
		#character_pos_2d = character.grid_position as Vector2i
		#character_pos_3d = Vector3i(character_pos_2d.x, 0, character_pos_2d.y)
	#else:
		#print("Warning: Character position not Vector2i in highlight_buildable_tiles")
		#character_pos_2d = Vector2i(0, 0)
		#character_pos_3d = Vector3i(0, 0, 0)
	#
	## Get building info
	#var building_data = available_buildings[pending_building_type]
	#var build_range = get_character_build_range()
	#
	## Check tiles within build range
	#for x in range(character_pos_2d.x - build_range, character_pos_2d.x + build_range + 1):
		#for y in range(character_pos_2d.y - build_range, character_pos_2d.y + build_range + 1):
			#var tile_pos_2d = Vector2i(x, y)
			#var tile_pos_3d = Vector3i(x, 0, y)
			#
			## Skip character's current position
			#if tile_pos_2d == character_pos_2d:
				#continue
			#
			## Get tile using appropriate method
			#var tile = null
			#if map_manager.has_method("get_tile_at_position"):  # 3D version
				#tile = map_manager.get_tile_at_position(tile_pos_3d)
			#else:  # 2D fallback
				#tile = map_manager.get_tile_at(tile_pos_2d)
			#
			## Check if building can be placed here
			#if tile and can_place_building_at_tile(tile, building_data):
				#tile.set_build_highlighted(true)
				#highlighted_tiles.append(tile)
#
#func clear_highlighted_tiles():
	#"""Clear all highlighted tiles"""
	#for tile in highlighted_tiles:
		#if tile.has_method("set_build_highlighted"):
			#tile.set_build_highlighted(false)
	#highlighted_tiles.clear()
#
#func get_character_build_range() -> int:
	#"""Get the character's building range from enhanced stats"""
	#if character and character.stats:
		#return character.stats.get_stat_value("Building", "Range")
	#return 2  # Default fallback
#
#func can_place_building_at_tile(tile, building_data: Dictionary) -> bool:
	#"""Check if a building can be placed on the specified tile"""
	## Check if tile is already occupied
	#var tile_pos_2d = Vector2i(tile.grid_position.x, tile.grid_position.z) if tile.grid_position is Vector3i else tile.grid_position
	#if tile_pos_2d in placed_buildings:
		#return false
	#
	## Check if tile is occupied by other entities
	#if tile.is_occupied:
		#return false
	#
	## Check biome compatibility
	#var allowed_biomes = building_data.get("allowed_biomes", [])
	#if allowed_biomes.size() > 0:
		#var tile_biome_name = get_tile_biome_name(tile)
		#if not tile_biome_name in allowed_biomes:
			#return false
	#
	## Check building size (for multi-tile buildings)
	#var building_size = building_data.get("size", Vector2i(1, 1))
	#if building_size != Vector2i(1, 1):
		## For now, just check single tile - can expand later for multi-tile buildings
		#return true
	#
	#return true
#
#func get_tile_biome_name(tile) -> String:
	#"""Get biome name from tile for compatibility checking"""
	#if "biome_type" in tile:
		## Convert enum to string - this might need adjustment based on your BiomeTile3D implementation
		#match tile.biome_type:
			#0: return "grassland"  # BiomeTile3D.BiomeType.GRASSLAND
			#1: return "forest"     # BiomeTile3D.BiomeType.FOREST
			#2: return "mountain"   # BiomeTile3D.BiomeType.MOUNTAIN
			#3: return "water"      # BiomeTile3D.BiomeType.WATER
			#4: return "desert"     # BiomeTile3D.BiomeType.DESERT
			#5: return "swamp"      # BiomeTile3D.BiomeType.SWAMP
			#_: return "unknown"
	#return "unknown"
#
#func is_tile_highlighted(target_pos) -> bool:
	#"""Check if a tile is currently highlighted for building"""
	## Convert position for comparison
	#var check_pos: Vector2i
	#if target_pos is Vector2i:
		#check_pos = target_pos as Vector2i
	#elif target_pos is Vector3i:
		#var pos_3d = target_pos as Vector3i
		#check_pos = Vector2i(pos_3d.x, pos_3d.z)
	#else:
		#return false
	#
	#for tile in highlighted_tiles:
		#var tile_pos = Vector2i(tile.grid_position.x, tile.grid_position.z) if tile.grid_position is Vector3i else tile.grid_position
		#if tile_pos == check_pos:
			#return true
	#return false
#
#func attempt_build_at(target_pos, building_type: String = ""):
	#"""Attempt to build at target position - handles both Vector2i and Vector3i"""
	## Use provided building type or fall back to pending type
	#if building_type != "":
		#pending_building_type = building_type
	#
	#if pending_building_type == "":
		#building_failed.emit("No building type selected")
		#return
	#
	## Convert position to 2D for compatibility - use safe conversion
	#var target_pos_2d: Vector2i
	#var target_pos_3d: Vector3i
	#
	#if target_pos is Vector2i:
		#target_pos_2d = target_pos as Vector2i
		#target_pos_3d = Vector3i(target_pos_2d.x, 0, target_pos_2d.y)
	#elif target_pos is Vector3i:
		#var pos_3d = target_pos as Vector3i
		#target_pos_3d = pos_3d
		#target_pos_2d = Vector2i(pos_3d.x, pos_3d.z)
	#else:
		#print("BuildManager: Invalid target position type: ", typeof(target_pos))
		#return
	#
	#print("Attempting to build ", pending_building_type, " at: ", target_pos_2d, " (3D: ", target_pos_3d, ")")
	#
	## Only allow building if in selecting mode and tile is highlighted
	#if current_state != BuildState.SELECTING_LOCATION:
		#print("Not in build selection mode")
		#return
		#
	#if not is_tile_highlighted(target_pos_2d):
		#print("Target tile is not highlighted/buildable")
		#building_failed.emit("Cannot build at this location")
		#return
	#
	## Check if character has action points
	#if character.current_action_points <= 0:
		#print("No action points remaining")
		#building_failed.emit("No action points remaining")
		#end_build_mode()
		#return
	#
	## Check resource requirements
	#var building_data = available_buildings[pending_building_type]
	#var building_cost = building_data.get("cost", {})
	#
	#if not can_afford_building(building_cost):
		#building_failed.emit("Insufficient resources")
		#return
	#
	## Store the target and request confirmation
	#pending_target_position = target_pos_2d
	#current_state = BuildState.AWAITING_CONFIRMATION
	#
	## Get target tile using appropriate method
	#var target_tile = null
	#if map_manager.has_method("get_tile_at_position"):  # 3D version
		#target_tile = map_manager.get_tile_at_position(target_pos_3d)
	#else:  # 2D fallback
		#target_tile = map_manager.get_tile_at(target_pos_2d)
	#
	#if target_tile:
		#build_confirmation_requested.emit(target_tile, pending_building_type)
	#else:
		#building_failed.emit("Invalid target tile")
		#end_build_mode()
#
#func confirm_building():
	#"""Execute the confirmed building placement"""
	#if current_state != BuildState.AWAITING_CONFIRMATION:
		#print("No building awaiting confirmation")
		#return
		#
	#var target_pos = pending_target_position
	#var building_type = pending_building_type
	#
	## Final validation
	#if character.current_action_points <= 0:
		#building_failed.emit("No action points remaining")
		#end_build_mode()
		#return
	#
	#var building_data = available_buildings[building_type]
	#var building_cost = building_data.get("cost", {})
	#
	#if not can_afford_building(building_cost):
		#building_failed.emit("Insufficient resources")
		#end_build_mode()
		#return
	#
	## Emit attempt signal
	#building_attempted.emit(character, building_type, target_pos)
	#
	## Spend resources
	#spend_resources(building_cost)
	#
	## Create and place building
	#var building = create_building(building_type, target_pos)
	#place_building(building, target_pos)
	#
	## Spend action point
	#character.spend_action_points()
	#
	## End build mode
	#end_build_mode()
	#
	## Emit completion signal
	#building_completed.emit(character, building, target_pos)
	#print("Building completed: ", building_type, " at ", target_pos)
#
#func cancel_building():
	#"""Cancel the pending building and return to selection mode"""
	#if current_state == BuildState.AWAITING_CONFIRMATION:
		#current_state = BuildState.SELECTING_LOCATION
		#pending_target_position = Vector2i.ZERO
		#print("Building cancelled, returning to selection mode")
#
#func can_afford_building(cost: Dictionary) -> bool:
	#"""Check if character can afford the building cost"""
	## This would integrate with your resource system
	## For now, assume we can always afford it - you'll need to integrate with ResourceManager
	#return true
#
#func spend_resources(cost: Dictionary):
	#"""Spend resources for building construction"""
	## This would integrate with your resource system
	#print("Spending resources: ", cost)
	## Example integration:
	## for resource in cost:
	##     resource_manager.spend_resource(resource, cost[resource])
#
#func create_building(building_type: String, position: Vector2i) -> Building:
	#"""Create a new building instance"""
	## This would create an actual Building object based on your Building class
	## For now, create a simple dictionary representation
	#var building_data = available_buildings[building_type]
	#
	## This is a placeholder - you'll need to implement based on your Building class
	#var building = {
		#"type": building_type,
		#"name": building_data.name,
		#"position": position,
		#"production": building_data.get("production", {}),
		#"build_time": building_data.get("build_time", 1),
		#"health": 100,
		#"is_complete": false
	#}
	#
	#print("Created building: ", building_type, " at ", position)
	#return building
#
#func place_building(building, position: Vector2i):
	#"""Place building on the map"""
	#placed_buildings[position] = building
	#
	## Mark tile as occupied
	#var tile_pos_3d = Vector3i(position.x, 0, position.y)
	#var tile = null
	#if map_manager.has_method("get_tile_at_position"):
		#tile = map_manager.get_tile_at_position(tile_pos_3d)
	#else:
		#tile = map_manager.get_tile_at(position)
	#
	#if tile:
		#tile.is_occupied = true
		#print("Tile marked as occupied at ", position)
#
## Building management methods
#func get_building_at(position) -> Dictionary:
	#"""Get building at specified position"""
	#var pos_2d: Vector2i
	#if position is Vector2i:
		#pos_2d = position as Vector2i
	#elif position is Vector3i:
		#var pos_3d = position as Vector3i
		#pos_2d = Vector2i(pos_3d.x, pos_3d.z)
	#else:
		#return {}
	#
	#return placed_buildings.get(pos_2d, {})
#
#func remove_building_at(position):
	#"""Remove building at specified position"""
	#var pos_2d: Vector2i
	#if position is Vector2i:
		#pos_2d = position as Vector2i
	#elif position is Vector3i:
		#var pos_3d = position as Vector3i
		#pos_2d = Vector2i(pos_3d.x, pos_3d.z)
	#else:
		#return
	#
	#if pos_2d in placed_buildings:
		#placed_buildings.erase(pos_2d)
		#
		## Mark tile as unoccupied
		#var tile_pos_3d = Vector3i(pos_2d.x, 0, pos_2d.y)
		#var tile = null
		#if map_manager.has_method("get_tile_at_position"):
			#tile = map_manager.get_tile_at_position(tile_pos_3d)
		#else:
			#tile = map_manager.get_tile_at(pos_2d)
		#
		#if tile:
			#tile.is_occupied = false
		#
		#print("Building removed at ", pos_2d)
#
#func get_all_buildings() -> Dictionary:
	#"""Get all placed buildings"""
	#return placed_buildings
#
#func get_buildings_of_type(building_type: String) -> Array:
	#"""Get all buildings of a specific type"""
	#var buildings = []
	#for pos in placed_buildings:
		#var building = placed_buildings[pos]
		#if building.get("type", "") == building_type:
			#buildings.append(building)
	#return buildings
#
## Utility methods
#func get_available_buildings() -> Dictionary:
	#"""Get all available building types"""
	#return available_buildings
#
#func get_building_cost(building_type: String) -> Dictionary:
	#"""Get the cost of a specific building type"""
	#return available_buildings.get(building_type, {}).get("cost", {})
#
#func get_building_info(building_type: String) -> Dictionary:
	#"""Get complete information about a building type"""
	#return available_buildings.get(building_type, {})
#
## Debug methods
#func debug_print_state():
	#"""Print current state for debugging"""
	#print("=== BuildManager State ===")
	#print("Current state: ", current_state)
	#print("Pending building: ", pending_building_type)
	#print("Highlighted tiles: ", highlighted_tiles.size())
	#print("Placed buildings: ", placed_buildings.size())
	#print("==========================")
#
#func debug_list_buildings():
	#"""List all placed buildings"""
	#print("=== Placed Buildings ===")
	#for pos in placed_buildings:
		#var building = placed_buildings[pos]
		#print(building.get("name", "Unknown"), " at ", pos)
	#print("========================")
