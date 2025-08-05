extends Node2D
class_name MapManager

signal map_generated
signal tile_clicked(tile: BiomeTile)

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

func generate_map(width: int, height: int):
	map_width = width
	map_height = height
	
	clear_existing_map()
	create_tile_grid()
	generate_biomes()
	connect_tile_signals()
	
	map_generated.emit()

func clear_existing_map():
	# Clear existing tiles
	for child in get_children():
		if child is BiomeTile:
			child.queue_free()
	
	tiles.clear()
	tile_lookup.clear()

func create_tile_grid():
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
	var tile = BiomeTile.new()
	tile.grid_position = grid_pos
	tile.tile_size = tile_size
	add_child(tile)
	return tile

func generate_biomes():
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
	for y in range(map_height):
		for x in range(map_width):
			var tile = tiles[y][x]
			tile.tile_clicked.connect(_on_tile_clicked)

func _on_tile_clicked(tile: BiomeTile):
	tile_clicked.emit(tile)

func get_tile_at(grid_pos: Vector2i) -> BiomeTile:
	return tile_lookup.get(grid_pos)

func get_neighbors(tile: BiomeTile) -> Array[BiomeTile]:
	var neighbors: Array[BiomeTile] = []
	var directions = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
	
	for direction in directions:
		var neighbor_pos = tile.grid_position + direction
		var neighbor = get_tile_at(neighbor_pos)
		if neighbor:
			neighbors.append(neighbor)
	
	return neighbors
