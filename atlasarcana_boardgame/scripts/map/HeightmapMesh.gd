# HeightmapMesh.gd - Enhanced for BiomeTile Integration
extends MeshInstance3D
class_name HeightmapMesh

@export var width: int = 64
@export var height: int = 64
@export var tile_size: float = 2.0
@export var elevation_scale: float = 2.0
@export var noise: FastNoiseLite

# Material for the heightmap terrain
var terrain_material: StandardMaterial3D

# Heightmap data for quick access
var height_data: Array[Array] = []

func _ready():
	if noise == null:
		noise = FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.frequency = 0.08
		noise.seed = randi()
	
	generate_mesh()
	create_terrain_material()

func generate_mesh():
	"""Generate the heightmap mesh with improved normals"""
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Pre-calculate height data for normal computation
	calculate_height_data()
	
	# Generate vertices with proper normals
	for z in range(height):
		for x in range(width):
			var y = height_data[z][x]
			var vertex = Vector3(x * tile_size, y, z * tile_size)
			var normal = calculate_normal(x, z)
			var uv = Vector2(float(x) / (width - 1), float(z) / (height - 1))
			
			st.add_vertex(vertex)
			st.add_normal(normal)
			st.add_uv(uv)
	
	# Build triangles (grid → 2 triangles per quad)
	for z in range(height - 1):
		for x in range(width - 1):
			var i = z * width + x
			var i_right = i + 1
			var i_down = i + width
			var i_diag = i + width + 1
			
			# Triangle 1: top-left, bottom-left, top-right
			st.add_index(i)
			st.add_index(i_down)
			st.add_index(i_right)
			
			# Triangle 2: top-right, bottom-left, bottom-right
			st.add_index(i_right)
			st.add_index(i_down)
			st.add_index(i_diag)
	
	var mesh = st.commit()
	self.mesh = mesh

func calculate_height_data():
	"""Pre-calculate height data for all vertices"""
	height_data.clear()
	height_data.resize(height)
	
	for z in range(height):
		height_data[z] = []
		height_data[z].resize(width)
		for x in range(width):
			height_data[z][x] = noise.get_noise_2d(x, z) * elevation_scale

func calculate_normal(x: int, z: int) -> Vector3:
	"""Calculate proper normal vector for a vertex"""
	# Get height values for surrounding vertices
	var h_center = height_data[z][x]
	
	# Sample neighboring heights (with boundary checks)
	var h_left = h_center
	var h_right = h_center
	var h_up = h_center
	var h_down = h_center
	
	if x > 0:
		h_left = height_data[z][x - 1]
	if x < width - 1:
		h_right = height_data[z][x + 1]
	if z > 0:
		h_up = height_data[z - 1][x]
	if z < height - 1:
		h_down = height_data[z + 1][x]
	
	# Calculate normal using cross product of surface tangents
	var dx = Vector3(tile_size * 2, h_right - h_left, 0)  # tangent in X direction
	var dz = Vector3(0, h_down - h_up, tile_size * 2)     # tangent in Z direction
	
	var normal = dx.cross(dz).normalized()
	return normal

func create_terrain_material():
	"""Create a material for the terrain"""
	terrain_material = StandardMaterial3D.new()
	
	# Basic terrain coloring
	terrain_material.albedo_color = Color(0.6, 0.7, 0.4)  # Earthy color
	terrain_material.roughness = 0.8
	terrain_material.metallic = 0.0
	
	# Enable vertex colors if you want to paint biomes on the mesh later
	terrain_material.vertex_color_use_as_albedo = true
	terrain_material.vertex_color_is_srgb = false
	
	# Optional: Add a texture
	# var texture = load("res://path/to/terrain_texture.png") as Texture2D
	# if texture:
	#     terrain_material.albedo_texture = texture
	#     terrain_material.uv1_scale = Vector3(4, 4, 4)  # Tile the texture
	
	material_override = terrain_material

func get_height_at_position(world_pos: Vector3) -> float:
	"""Get the height at a specific world position using interpolation"""
	# Convert world position to grid coordinates (as floats for interpolation)
	var grid_x = world_pos.x / tile_size
	var grid_z = world_pos.z / tile_size
	
	# Clamp to valid range
	grid_x = clamp(grid_x, 0, width - 1)
	grid_z = clamp(grid_z, 0, height - 1)
	
	# Get integer and fractional parts
	var x0 = int(floor(grid_x))
	var z0 = int(floor(grid_z))
	var x1 = mini(x0 + 1, width - 1)
	var z1 = mini(z0 + 1, height - 1)
	
	var fx = grid_x - x0
	var fz = grid_z - z0
	
	# Bilinear interpolation
	var h00 = height_data[z0][x0]  # top-left
	var h10 = height_data[z0][x1]  # top-right
	var h01 = height_data[z1][x0]  # bottom-left
	var h11 = height_data[z1][x1]  # bottom-right
	
	var h0 = lerp(h00, h10, fx)  # top edge
	var h1 = lerp(h01, h11, fx)  # bottom edge
	var height = lerp(h0, h1, fz)   # final interpolated height
	
	return height

func get_height_at_grid(grid_x: int, grid_z: int) -> float:
	"""Get height at exact grid coordinates"""
	if grid_x < 0 or grid_x >= width or grid_z < 0 or grid_z >= height:
		return 0.0
	
	return height_data[grid_z][grid_x]

func update_material_for_biome_region(grid_pos: Vector3i, biome_color: Color, radius: float = 1.0):
	"""Update material to show biome coloring in a region (optional feature)"""
	# This is a placeholder for more advanced biome visualization
	# You could implement texture blending or vertex color painting here
	pass

func regenerate_with_new_settings():
	"""Regenerate the mesh with current settings"""
	generate_mesh()

# Debug function to visualize the heightmap bounds
func _get_configuration_warnings():
	var warnings = []
	
	if width <= 1 or height <= 1:
		warnings.append("Width and height should be greater than 1")
	
	if tile_size <= 0:
		warnings.append("Tile size should be greater than 0")
	
	return warnings
