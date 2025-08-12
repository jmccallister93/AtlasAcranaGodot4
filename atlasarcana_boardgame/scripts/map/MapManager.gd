extends Node2D
class_name MapManager

signal map_generated
signal tile_clicked(tile: BiomeTile)
signal movement_requested(target_grid_pos: Vector2i)

# Map configuration - single source of truth
var map_width: int = 32
var map_height: int = 24
var tile_size: int = 64

# Map data structures
var tiles: Array[Array] = []  # 2D array of BiomeTile
var tile_lookup: Dictionary = {}  # Vector2i -> BiomeTile for quick access

# Biome generation settings
var biome_weights = {
	BiomeTile.BiomeType.GRASSLAND: 0.4,
	BiomeTile.BiomeType.FOREST: 0.25,
	BiomeTile.BiomeType.MOUNTAIN: 0.15,
	BiomeTile.BiomeType.WATER: 0.1,
	BiomeTile.BiomeType.DESERT: 0.05,
	BiomeTile.BiomeType.SWAMP: 0.05
}

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_movement_click(event.position)
			
func handle_movement_click(screen_pos: Vector2):
	# Convert screen position to local position on the map
	var local_pos = to_local(get_global_mouse_position())
	
	# Convert to grid coordinates
	var grid_pos = Vector2i(int(local_pos.x / tile_size), int(local_pos.y / tile_size))
	
	print("Screen pos: ", screen_pos)
	print("Local pos: ", local_pos) 
	print("Grid pos: ", grid_pos)
	
	# Check if it's a valid grid position
	if is_valid_position(grid_pos):
		# Emit a signal that GameManager can listen to
		movement_requested.emit(grid_pos)
		
func generate_map(width: int, height: int):
	"""Generate a new map with the specified dimensions"""
	map_width = width
	map_height = height
	
	clear_existing_map()
	create_tile_grid()
	generate_biomes()
	connect_tile_signals()
	
	map_generated.emit()

func clear_existing_map():
	"""Clear existing tiles from the map"""
	# Clear existing tiles
	for child in get_children():
		if child is BiomeTile:
			child.queue_free()
	
	tiles.clear()
	tile_lookup.clear()

func create_tile_grid():
	"""Create the grid of tiles"""
	# Initialize 2D array
	tiles.resize(map_height)
	for y in range(map_height):
		tiles[y] = []
		tiles[y].resize(map_width)
		
		for x in range(map_width):
			var tile = create_tile(Vector2i(x, y))
			tiles[y][x] = tile
			tile_lookup[Vector2i(x, y)] = tile

func create_tile(grid_pos: Vector2i) -> BiomeTile:
	"""Create a single tile at the specified grid position"""
	var tile = BiomeTile.new()
	tile.grid_position = grid_pos
	tile.tile_size = tile_size  # Set from manager's tile_size
	tile.map_manager = self     # Give tile reference to this manager
	add_child(tile)
	return tile

func generate_biomes():
	"""Generate biomes for all tiles using noise"""
	# Simple noise-based biome generation
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.1
	
	for y in range(map_height):
		for x in range(map_width):
			var noise_value = noise.get_noise_2d(x, y)
			var biome_type = get_biome_from_noise(noise_value)
			tiles[y][x].biome_type = biome_type

func get_biome_from_noise(noise_value: float) -> BiomeTile.BiomeType:
	"""Convert noise value to biome type"""
	# Convert noise (-1 to 1) to biome type
	var normalized = (noise_value + 1.0) / 2.0  # 0 to 1
	
	if normalized < 0.1:
		return BiomeTile.BiomeType.WATER
	elif normalized < 0.25:
		return BiomeTile.BiomeType.SWAMP
	elif normalized < 0.45:
		return BiomeTile.BiomeType.FOREST
	elif normalized < 0.7:
		return BiomeTile.BiomeType.GRASSLAND
	elif normalized < 0.9:
		return BiomeTile.BiomeType.MOUNTAIN
	else:
		return BiomeTile.BiomeType.DESERT

func connect_tile_signals():
	"""Connect signals from all tiles"""
	for y in range(map_height):
		for x in range(map_width):
			var tile = tiles[y][x]
			tile.tile_clicked.connect(_on_tile_clicked)

func _on_tile_clicked(tile: BiomeTile):
	"""Handle tile click events"""
	tile_clicked.emit(tile)

func get_tile_at(grid_pos: Vector2i) -> BiomeTile:
	"""Get tile at specified grid position"""
	return tile_lookup.get(grid_pos)

func get_neighbors(tile: BiomeTile) -> Array[BiomeTile]:
	"""Get neighboring tiles for the specified tile"""
	var neighbors: Array[BiomeTile] = []
	var directions = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
	
	for direction in directions:
		var neighbor_pos = tile.grid_position + direction
		var neighbor = get_tile_at(neighbor_pos)
		if neighbor:
			neighbors.append(neighbor)
	
	return neighbors

func is_valid_position(grid_pos: Vector2i) -> bool:
	"""Check if a grid position is valid"""
	return grid_pos.x >= 0 and grid_pos.x < map_width and grid_pos.y >= 0 and grid_pos.y < map_height

func get_tiles_in_radius(center_tile: BiomeTile, radius: int) -> Array[BiomeTile]:
	"""Get all tiles within a specified radius of the center tile"""
	var tiles_in_radius: Array[BiomeTile] = []
	
	for y in range(center_tile.grid_position.y - radius, center_tile.grid_position.y + radius + 1):
		for x in range(center_tile.grid_position.x - radius, center_tile.grid_position.x + radius + 1):
			var pos = Vector2i(x, y)
			if is_valid_position(pos):
				var distance = abs(pos.x - center_tile.grid_position.x) + abs(pos.y - center_tile.grid_position.y)
				if distance <= radius:
					var tile = get_tile_at(pos)
					if tile:
						tiles_in_radius.append(tile)
	
	return tiles_in_radius

func get_tiles_of_biome(biome_type: BiomeTile.BiomeType) -> Array[BiomeTile]:
	"""Get all tiles of a specific biome type"""
	var biome_tiles: Array[BiomeTile] = []
	
	for y in range(map_height):
		for x in range(map_width):
			if tiles[y][x].biome_type == biome_type:
				biome_tiles.append(tiles[y][x])
	
	return biome_tiles

func update_tile_size(new_size: int):
	"""Update the tile size for all tiles"""
	tile_size = new_size
	
	# Update all existing tiles
	for y in range(map_height):
		for x in range(map_width):
			tiles[y][x].update_tile_size(new_size)

func get_map_bounds() -> Rect2i:
	"""Get the bounds of the map in grid coordinates"""
	return Rect2i(0, 0, map_width, map_height)

func get_world_bounds() -> Rect2:
	"""Get the bounds of the map in world coordinates"""
	return Rect2(0, 0, map_width * tile_size, map_height * tile_size)
