extends Node3D
class_name ExpeditionMapGenerator
# Map generation settings
@export var map_size: int = 100  # Grid size (100x100)
@export var tile_size: float = 2.0  # Size of each grid cell in world units
@export var height_scale: float = 10.0  # Maximum height variation
@export var noise_frequency: float = 0.1  # Noise frequency for terrain

# Terrain colors (customizable in inspector)
@export_group("Terrain Colors")
@export var deep_water_color: Color = Color(0.0, 0.2, 0.6)
@export var shallow_water_color: Color = Color(0.2, 0.4, 0.8)
@export var beach_color: Color = Color(0.9, 0.8, 0.6)
@export var grass_color: Color = Color(0.2, 0.6, 0.2)
@export var hill_color: Color = Color(0.4, 0.5, 0.2)
@export var mountain_color: Color = Color(0.5, 0.4, 0.3)
@export var snow_color: Color = Color(0.9, 0.9, 0.9)

# Grid system
var grid_map: Array[Array] = []
var terrain_mesh: MeshInstance3D
var noise: FastNoiseLite

# Grid cell data structure
class GridCell:
	var world_position: Vector3
	var grid_position: Vector2i
	var height: float
	var is_walkable: bool = true
	var movement_cost: int = 1
	
	func _init(grid_pos: Vector2i, world_pos: Vector3, h: float):
		grid_position = grid_pos
		world_position = world_pos
		height = h

func _ready():
	setup_noise()
	generate_map()
	create_terrain_mesh()

func setup_noise():
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = noise_frequency
	noise.noise_type = FastNoiseLite.TYPE_PERLIN

func generate_map():
	# Initialize grid
	grid_map = []
	for x in range(map_size):
		grid_map.append([])
		for z in range(map_size):
			grid_map[x].append(null)
	
	# Generate terrain data
	for x in range(map_size):
		for z in range(map_size):
			# Calculate world position
			var world_x = x * tile_size - (map_size * tile_size) / 2.0
			var world_z = z * tile_size - (map_size * tile_size) / 2.0
			
			# Generate height using noise
			var height = noise.get_noise_2d(x, z) * height_scale
			
			# Create world position
			var world_pos = Vector3(world_x, height, world_z)
			
			# Create grid cell
			var cell = GridCell.new(Vector2i(x, z), world_pos, height)
			
			# Set walkability based on slope (optional)
			if abs(height) > height_scale * 0.7:
				cell.is_walkable = false
				cell.movement_cost = 999  # Impassable
			
			grid_map[x][z] = cell

func create_terrain_mesh():
	# Create a simple terrain mesh using the grid data
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var colors = PackedColorArray()  # Add colors array
	var indices = PackedInt32Array()
	
	# Generate vertices
	for x in range(map_size):
		for z in range(map_size):
			var cell = grid_map[x][z] as GridCell
			vertices.push_back(cell.world_position)
			
			# Calculate normal (simplified)
			var normal = Vector3.UP  # You can calculate proper normals here
			normals.push_back(normal)
			
			# UV coordinates
			uvs.push_back(Vector2(float(x) / map_size, float(z) / map_size))
			
			# Calculate color based on height
			var color = get_height_color(cell.height)
			colors.push_back(color)
	
	# Generate triangles
	for x in range(map_size - 1):
		for z in range(map_size - 1):
			var i = x * map_size + z
			var i1 = i + 1
			var i2 = i + map_size
			var i3 = i + map_size + 1
			
			# First triangle
			indices.push_back(i)
			indices.push_back(i2)
			indices.push_back(i1)
			
			# Second triangle
			indices.push_back(i1)
			indices.push_back(i2)
			indices.push_back(i3)
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors  # Add colors to mesh
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Add mesh to scene
	terrain_mesh = MeshInstance3D.new()
	terrain_mesh.mesh = array_mesh
	add_child(terrain_mesh)
	
	# Create material that uses vertex colors
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.metallic = 0.0  # Make it non-metallic for better color visibility
	material.roughness = 0.8  # Slightly rough surface
	terrain_mesh.material_override = material

# Grid coordinate conversion functions
func world_to_grid(world_pos: Vector3) -> Vector2i:
	var x = int((world_pos.x + (map_size * tile_size) / 2.0) / tile_size)
	var z = int((world_pos.z + (map_size * tile_size) / 2.0) / tile_size)
	return Vector2i(x, z)

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	if not is_valid_grid_position(grid_pos):
		return Vector3.ZERO
	
	var cell = grid_map[grid_pos.x][grid_pos.y] as GridCell
	return cell.world_position

func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < map_size and grid_pos.y >= 0 and grid_pos.y < map_size

func get_cell_at_grid(grid_pos: Vector2i) -> GridCell:
	if not is_valid_grid_position(grid_pos):
		return null
	return grid_map[grid_pos.x][grid_pos.y] as GridCell

func get_cell_at_world(world_pos: Vector3) -> GridCell:
	var grid_pos = world_to_grid(world_pos)
	return get_cell_at_grid(grid_pos)

# Distance calculation functions
func calculate_grid_distance(from_grid: Vector2i, to_grid: Vector2i) -> int:
	# Manhattan distance
	return abs(to_grid.x - from_grid.x) + abs(to_grid.y - from_grid.y)

func calculate_world_distance(from_world: Vector3, to_world: Vector3) -> float:
	return from_world.distance_to(to_world)

func calculate_movement_cost(from_grid: Vector2i, to_grid: Vector2i) -> int:
	var from_cell = get_cell_at_grid(from_grid)
	var to_cell = get_cell_at_grid(to_grid)
	
	if not from_cell or not to_cell:
		return -1  # Invalid movement
	
	if not to_cell.is_walkable:
		return -1  # Cannot move to unwalkable cell
	
	# Base cost is the target cell's movement cost
	var cost = to_cell.movement_cost
	
	# Add extra cost for height differences
	var height_diff = abs(to_cell.height - from_cell.height)
	if height_diff > 2.0:  # Steep terrain
		cost += int(height_diff)
	
	return cost

# Pathfinding helper - get neighboring cells
func get_neighbors(grid_pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions = [
		Vector2i(0, 1),   # North
		Vector2i(1, 0),   # East
		Vector2i(0, -1),  # South
		Vector2i(-1, 0),  # West
		# Diagonal movement (optional)
		Vector2i(1, 1),   # Northeast
		Vector2i(1, -1),  # Southeast
		Vector2i(-1, -1), # Southwest
		Vector2i(-1, 1)   # Northwest
	]
	
	for dir in directions:
		var neighbor_pos = grid_pos + dir
		if is_valid_grid_position(neighbor_pos):
			var cell = get_cell_at_grid(neighbor_pos)
			if cell and cell.is_walkable:
				neighbors.push_back(neighbor_pos)
	
	return neighbors

# Debug functions
func show_grid_debug():
	# Create debug markers for grid positions (optional)
	for x in range(0, map_size, 5):  # Show every 5th grid line
		for z in range(0, map_size, 5):
			var cell = grid_map[x][z] as GridCell
			var marker = CSGSphere3D.new()
			marker.radius = 0.2
			marker.position = cell.world_position + Vector3.UP * 0.5
			add_child(marker)

# Example usage functions
func find_path_simple(from_world: Vector3, to_world: Vector3) -> Array[Vector2i]:
	# This is a simple example - you'd want to implement A* for real pathfinding
	var from_grid = world_to_grid(from_world)
	var to_grid = world_to_grid(to_world)
	
	var path: Array[Vector2i] = []
	var current = from_grid
	
	# Simple pathfinding - just move towards target (not optimal)
	while current != to_grid:
		var diff = to_grid - current
		var next_step = Vector2i(
			current.x + sign(diff.x),
			current.y + sign(diff.y)
		)
		
		if is_valid_grid_position(next_step) and get_cell_at_grid(next_step).is_walkable:
			current = next_step
			path.push_back(current)
		else:
			break  # Can't reach target
	
	return path

# Regenerate map with new parameters
func regenerate_map():
	# Clear existing terrain
	if terrain_mesh:
		terrain_mesh.queue_free()
	
	# Generate new map
	setup_noise()
	generate_map()
	create_terrain_mesh()

# Height-based color calculation
func get_height_color(height: float) -> Color:
	"""Calculate color based on terrain height"""
	# Calculate color based on height thresholds
	if height < -height_scale * 0.3:  # Deep water
		return deep_water_color
	elif height < -height_scale * 0.1:  # Shallow water
		var t = (height + height_scale * 0.3) / (height_scale * 0.2)
		return deep_water_color.lerp(shallow_water_color, t)
	elif height < 0.0:  # Beach/shore
		var t = (height + height_scale * 0.1) / (height_scale * 0.1)
		return shallow_water_color.lerp(beach_color, t)
	elif height < height_scale * 0.1:  # Grass level
		var t = height / (height_scale * 0.1)
		return beach_color.lerp(grass_color, t)
	elif height < height_scale * 0.3:  # Hills
		var t = (height - height_scale * 0.1) / (height_scale * 0.2)
		return grass_color.lerp(hill_color, t)
	elif height < height_scale * 0.6:  # Mountains
		var t = (height - height_scale * 0.3) / (height_scale * 0.3)
		return hill_color.lerp(mountain_color, t)
	else:  # Snow peaks
		var t = (height - height_scale * 0.6) / (height_scale * 0.4)
		return mountain_color.lerp(snow_color, clamp(t, 0.0, 1.0))
	
	return grass_color  # Fallback
