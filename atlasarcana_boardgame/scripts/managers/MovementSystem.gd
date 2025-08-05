extends Node
class_name MovementSystem

signal path_calculated(path: Array[BiomeTile])

var current_character: Character = null
var highlighted_tiles: Array[BiomeTile] = []

func show_movement_range(character: Character, map_manager: MapManager):
	clear_highlights()
	current_character = character
	
	var reachable_tiles = calculate_reachable_tiles(character, map_manager)
	highlight_movement_tiles(reachable_tiles)

func calculate_reachable_tiles(character: Character, map_manager: MapManager) -> Dictionary:
	var reachable = {}
	var current_tile = get_character_tile(character, map_manager)
	if not current_tile:
		return reachable
	
	# Dijkstra's algorithm for movement range
	var queue: Array[Dictionary] = [{"tile": current_tile, "cost": 0.0}]
	var visited = {}
	
	while queue.size() > 0:
		# Sort by cost (simple priority queue)
		queue.sort_custom(func(a, b): return a.cost < b.cost)
		var current = queue.pop_front()
		var tile = current.tile
		var cost = current.cost
		
		if tile.grid_position in visited:
			continue
			
		visited[tile.grid_position] = cost
		
		if cost <= character.movement_points:
			reachable[tile.grid_position] = {"tile": tile, "cost": cost}
		
		# Add neighbors
		var neighbors = map_manager.get_neighbors(tile)
		for neighbor in neighbors:
			if neighbor.grid_position not in visited:
				var new_cost = cost + neighbor.movement_cost
				queue.append({"tile": neighbor, "cost": new_cost})
	
	return reachable

func highlight_movement_tiles(reachable_tiles: Dictionary):
	for data in reachable_tiles.values():
		var tile = data.tile
		var cost = data.cost
		
		# Color based on reachability
		if cost <= current_character.movement_points:
			tile.modulate = Color.YELLOW
		else:
			tile.modulate = Color.RED
		
		highlighted_tiles.append(tile)

func clear_highlights():
	for tile in highlighted_tiles:
		tile.modulate = Color.WHITE
	highlighted_tiles.clear()

func get_character_tile(character: Character, map_manager: MapManager) -> BiomeTile:
	# Convert character world position to grid position
	var grid_pos = Vector2i(
		int(character.global_position.x / map_manager.tile_size),
		int(character.global_position.y / map_manager.tile_size)
	)
	return map_manager.get_tile_at(grid_pos)
