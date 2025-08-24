# MapManager3D.gd - 3D Conversion of your MapManager
extends Node3D  # Changed from Node2D
class_name MapManager3D

signal map_generated
signal tile_clicked(tile: BiomeTile3D)  # Updated signal type
signal movement_requested(target_grid_pos: Vector3i)  # Vector2i → Vector3i

# Map configuration - single source of truth  
var map_width: int = 32
var map_height: int = 24
var tile_size: float = 2.0  # Changed to float for 3D scaling
var map_elevation: float = 0.0  # New: Base elevation for the map

# Map data structures
var tiles: Array[Array] = []  # 2D array of BiomeTile3D
var tile_lookup: Dictionary = {}  # Vector3i -> BiomeTile3D for quick access

# 3D-specific components
var mouse_raycaster: MouseRaycaster3D
var terrain_material_library: TerrainMaterialLibrary

# Lighting for the 3D map
var directional_light: DirectionalLight3D
var environment: Environment

# Biome generation settings (unchanged)
var biome_weights = {
	BiomeTile3D.BiomeType.GRASSLAND: 0.4,
	BiomeTile3D.BiomeType.FOREST: 0.25,
	BiomeTile3D.BiomeType.MOUNTAIN: 0.15,
	BiomeTile3D.BiomeType.WATER: 0.1,
	BiomeTile3D.BiomeType.DESERT: 0.05,
	BiomeTile3D.BiomeType.SWAMP: 0.05
}

func _ready():
	"""Initialize 3D map components"""
	setup_3d_environment()
	setup_mouse_interaction()
	setup_materials()

func setup_3d_environment():
	"""Setup 3D lighting and environment"""
	# Add directional light
	directional_light = DirectionalLight3D.new()
	directional_light.name = "MapLight"
	directional_light.position = Vector3(0, 10, 5)
	directional_light.rotation_degrees = Vector3(-45, -30, 0)
	directional_light.light_energy = 1.0
	add_child(directional_light)
	
	# Add environment
	var world_env = WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	environment.sky.sky_material = sky_material
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.3
	world_env.environment = environment
	add_child(world_env)


func setup_mouse_interaction():
	"""Setup 3D mouse interaction system"""
	mouse_raycaster = MouseRaycaster3D.new()
	add_child(mouse_raycaster)
	mouse_raycaster.tile_clicked.connect(_on_tile_clicked_3d)

func setup_materials():
	"""Setup material library for different biomes"""
	terrain_material_library = TerrainMaterialLibrary.new()
	add_child(terrain_material_library)

func _on_tile_clicked_3d(tile: BiomeTile3D, click_position: Vector3):
	"""Handle 3D tile click events"""
	tile_clicked.emit(tile)
	
	# Convert world position to grid position and emit movement request
	var grid_pos = world_to_grid(click_position)
	movement_requested.emit(grid_pos)

func generate_map(width: int, height: int):
	"""Generate a new 3D map with the specified dimensions"""
	map_width = width
	map_height = height
	
	clear_existing_map()
	create_tile_grid_3d()
	generate_biomes_3d()
	connect_tile_signals()
	
	map_generated.emit()

func clear_existing_map():
	"""Clear existing 3D tiles from the map"""
	# Clear existing tiles
	for child in get_children():
		if child is BiomeTile3D:
			child.queue_free()
	
	tiles.clear()
	tile_lookup.clear()

func create_tile_grid_3d():
	"""Create the 3D grid of tiles"""
	# Initialize 2D array
	tiles.resize(map_height)
	for z in range(map_height):  # Z-axis is "forward/back" in 3D
		tiles[z] = []
		tiles[z].resize(map_width)
		
		for x in range(map_width):  # X-axis is "left/right"
			var tile = create_tile_3d(Vector3i(x, 0, z))  # Y=0 for flat terrain
			tiles[z][x] = tile
			tile_lookup[Vector3i(x, 0, z)] = tile

func create_tile_3d(grid_pos: Vector3i) -> BiomeTile3D:
	"""Create a single 3D tile at the specified grid position"""
	var tile = BiomeTile3D.new()
	tile.grid_position = grid_pos
	tile.tile_size = tile_size
	tile.map_manager = self
	add_child(tile)
	return tile



func get_biome_from_noise(noise_value: float) -> BiomeTile3D.BiomeType:
	"""Convert noise value (-1 to 1) to biome type based on weights"""
	# Normalize noise from [-1, 1] to [0, 1]
	var normalized_noise = (noise_value + 1.0) / 2.0
	
	# Create cumulative weight thresholds
	var cumulative_weight = 0.0
	var thresholds = []
	
	# Sort biomes by weight (descending) for better distribution
	var sorted_biomes = biome_weights.keys()
	sorted_biomes.sort_custom(func(a, b): return biome_weights[a] > biome_weights[b])
	
	# Build cumulative thresholds
	for biome_type in sorted_biomes:
		cumulative_weight += biome_weights[biome_type]
		thresholds.append({
			"threshold": cumulative_weight,
			"biome": biome_type
		})
	
	# Map noise value to biome based on thresholds
	for threshold_data in thresholds:
		if normalized_noise <= threshold_data.threshold:
			return threshold_data.biome
	
	# Fallback (should never reach here if weights sum to 1.0)
	return BiomeTile3D.BiomeType.GRASSLAND

func get_biome_from_noise_zones(noise_value: float) -> BiomeTile3D.BiomeType:
	"""Alternative: Map noise to specific zones for more predictable terrain"""
	# This creates more distinct biome zones
	if noise_value < -0.6:
		return BiomeTile3D.BiomeType.WATER
	elif noise_value < -0.3:
		return BiomeTile3D.BiomeType.SWAMP
	elif noise_value < -0.1:
		return BiomeTile3D.BiomeType.GRASSLAND
	elif noise_value < 0.2:
		return BiomeTile3D.BiomeType.FOREST
	elif noise_value < 0.5:
		return BiomeTile3D.BiomeType.DESERT
	else:
		return BiomeTile3D.BiomeType.MOUNTAIN

func generate_biomes_3d():
	"""Generate biomes for all 3D tiles using noise"""
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.1
	noise.noise_type = FastNoiseLite.TYPE_PERLIN  # Try different noise types
	
	for z in range(map_height):
		for x in range(map_width):
			var noise_value = noise.get_noise_2d(x, z)
			
			# Choose your preferred method:
			# Method 1: Weight-based distribution (more random/scattered)
			var biome_type = get_biome_from_noise(noise_value)
			
			# Method 2: Zone-based distribution (more organized regions)
			# var biome_type = get_biome_from_noise_zones(noise_value)
			
			tiles[z][x].biome_type = biome_type
			
			# Optional: Add elevation variation
			var elevation = get_elevation_from_noise(noise_value)
			tiles[z][x].set_elevation(elevation)

func get_elevation_from_noise(noise_value: float) -> float:
	"""Convert noise to elevation (enhanced version)"""
	# Scale noise to elevation range
	var base_elevation = 0.0
	var elevation_range = 2.0  # Max elevation difference
	
	# You can make elevation follow the noise or use different noise
	var elevation = base_elevation + (noise_value * elevation_range)
	
	# Clamp to reasonable values
	return clamp(elevation, -1.0, 3.0)

# Alternative: Multi-octave noise for more complex terrain
func generate_biomes_3d_advanced():
	"""Advanced biome generation with multiple noise layers"""
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.08
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Secondary noise for variation
	var detail_noise = FastNoiseLite.new()
	detail_noise.seed = randi() + 1000
	detail_noise.frequency = 0.3
	
	# Temperature-like noise
	var temp_noise = FastNoiseLite.new()
	temp_noise.seed = randi() + 2000
	temp_noise.frequency = 0.05
	
	for z in range(map_height):
		for x in range(map_width):
			# Combine multiple noise values
			var height_noise = noise.get_noise_2d(x, z)
			var detail = detail_noise.get_noise_2d(x, z) * 0.3
			var temperature = temp_noise.get_noise_2d(x, z)
			
			var combined_noise = height_noise + detail
			var biome_type = get_biome_from_climate(combined_noise, temperature)
			
			tiles[z][x].biome_type = biome_type
			tiles[z][x].set_elevation(get_elevation_from_noise(height_noise))

func get_biome_from_climate(height_noise: float, temperature: float) -> BiomeTile3D.BiomeType:
	"""Determine biome based on height and temperature"""
	# Water in low areas
	if height_noise < -0.4:
		return BiomeTile3D.BiomeType.WATER
	
	# Swamps in low, warm areas
	if height_noise < -0.2 and temperature > 0.0:
		return BiomeTile3D.BiomeType.SWAMP
	
	# Mountains in high areas
	if height_noise > 0.4:
		return BiomeTile3D.BiomeType.MOUNTAIN
	
	# Temperature-based biomes for mid-elevation
	if temperature < -0.3:
		return BiomeTile3D.BiomeType.MOUNTAIN  # Cold = mountain
	elif temperature > 0.3:
		return BiomeTile3D.BiomeType.DESERT    # Hot = desert
	elif height_noise > 0.0:
		return BiomeTile3D.BiomeType.FOREST    # Mid temp, higher = forest
	else:
		return BiomeTile3D.BiomeType.GRASSLAND # Mid temp, lower = grassland


func connect_tile_signals():
	"""Connect signals from all 3D tiles"""
	for z in range(map_height):
		for x in range(map_width):
			var tile = tiles[z][x]
			# BiomeTile3D will handle its own click detection
			# tile.tile_clicked.connect(_on_tile_clicked)

# Updated coordinate conversion functions
func world_to_grid(world_pos: Vector3) -> Vector3i:
	"""Convert world position to grid coordinates"""
	var x = int(round(world_pos.x / tile_size))
	var z = int(round(world_pos.z / tile_size))
	return Vector3i(x, 0, z)  # Y=0 for flat terrain

func grid_to_world(grid_pos: Vector3i) -> Vector3:
	"""Convert grid position to world coordinates"""
	var x = grid_pos.x * tile_size
	var z = grid_pos.z * tile_size
	var y = map_elevation + (grid_pos.y * tile_size)  # Handle elevation
	return Vector3(x, y, z)

func get_tile_at_position(grid_pos: Vector3i) -> BiomeTile3D:
	"""Get tile at specified 3D grid position"""
	return tile_lookup.get(grid_pos)

func get_tile_at_world(world_pos: Vector3) -> BiomeTile3D:
	"""Get tile at world position"""
	var grid_pos = world_to_grid(world_pos)
	return get_tile_at_position(grid_pos)

func get_neighbors_3d(tile: BiomeTile3D) -> Array[BiomeTile3D]:
	"""Get neighboring tiles in 3D (4-directional for flat terrain)"""
	var neighbors: Array[BiomeTile3D] = []
	# 4-directional neighbors (North, East, South, West)
	var directions = [
		Vector3i(0, 0, 1),   # North (+Z)
		Vector3i(1, 0, 0),   # East (+X)
		Vector3i(0, 0, -1),  # South (-Z)
		Vector3i(-1, 0, 0)   # West (-X)
	]
	
	for direction in directions:
		var neighbor_pos = tile.grid_position + direction
		var neighbor = get_tile_at_position(neighbor_pos)
		if neighbor:
			neighbors.append(neighbor)
	
	return neighbors



func get_map_bounds_3d() -> AABB:
	"""Get the bounds of the 3D map"""
	var min_pos = Vector3(0, map_elevation, 0)
	var max_pos = Vector3(map_width * tile_size, map_elevation + tile_size, map_height * tile_size)
	return AABB(min_pos, max_pos - min_pos)


func get_world_bounds() -> AABB:
	"""Updated to return 3D bounds"""
	return get_map_bounds_3d()

# Helper method for other systems
func convert_2d_to_3d_position(pos_2d: Vector2i) -> Vector3i:
	"""Convert old 2D positions to 3D positions"""
	return Vector3i(pos_2d.x, 0, pos_2d.y)
