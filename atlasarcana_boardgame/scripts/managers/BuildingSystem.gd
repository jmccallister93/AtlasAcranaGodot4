extends Node
class_name BuildingSystem

signal building_placed(building: Building, tile: BiomeTile)
signal building_removed(building: Building, tile: BiomeTile)

var buildings_by_tile: Dictionary = {}  # Vector2i -> Array[Building]
var buildings_by_type: Dictionary = {}  # String -> Array[Building]

func place_building(building_type: String, tile: BiomeTile) -> bool:
	if not tile.can_place_building(building_type):
		return false
	
	var building = create_building(building_type, tile)
	if building:
		add_building_to_tile(building, tile)
		building_placed.emit(building, tile)
		return true
	
	return false

func create_building(building_type: String, tile: BiomeTile) -> Building:
	var building = Building.new()
	building.building_type = building_type
	building.tile_position = tile.grid_position
	
	# Position building on tile
	building.global_position = tile.global_position
	tile.add_child(building)
	
	return building

func add_building_to_tile(building: Building, tile: BiomeTile):
	var grid_pos = tile.grid_position
	
	if grid_pos not in buildings_by_tile:
		buildings_by_tile[grid_pos] = []
	buildings_by_tile[grid_pos].append(building)
	
	if building.building_type not in buildings_by_type:
		buildings_by_type[building.building_type] = []
	buildings_by_type[building.building_type].append(building)
	
	tile.is_occupied = true

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
