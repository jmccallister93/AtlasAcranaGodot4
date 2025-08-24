# BiomeTile3D.gd - 3D Conversion of your BiomeTile
extends Area3D  # Changed from Area2D
class_name BiomeTile3D

# Tile properties
@export var grid_position: Vector3i  # Changed from Vector2i
@export var biome_type: BiomeType = BiomeType.GRASSLAND
var tile_size: float = 2.0  # Changed to float for 3D scaling
var elevation: float = 0.0  # New: tile elevation

# Reference to map manager for accessing map-wide functionality
var map_manager: MapManager3D  # Updated type

# Game logic data (unchanged)
var resources: Dictionary = {}
var is_occupied: bool = false
var movement_cost: float = 1.0

# 3D Visual components - created in code
var mesh_instance: MeshInstance3D  # Replaced Sprite2D
var collision_shape: CollisionShape3D  # Changed from CollisionShape2D
var material: StandardMaterial3D
var hover_indicator: MeshInstance3D  # Replaced Label with 3D indicator

# 3D Highlight overlays (replace 2D ColorRect overlays)
var movement_highlight: MeshInstance3D
var build_highlight: MeshInstance3D
var interact_highlight: MeshInstance3D
var attack_highlight: MeshInstance3D

# Highlight states (unchanged)
var is_movement_highlighted: bool = false
var is_build_highlighted: bool = false
var is_interact_highlighted: bool = false
var is_attack_highlighted: bool = false

# Signals for game events (unchanged)
signal tile_clicked(tile: BiomeTile3D)
signal tile_hovered(tile: BiomeTile3D)

enum BiomeType {
	GRASSLAND,
	FOREST,
	MOUNTAIN,
	WATER,
	DESERT,
	SWAMP
}

func _ready():
	"""Initialize the 3D tile"""
	create_3d_mesh()
	create_3d_collision_shape()
	create_3d_hover_indicator()
	
	# Initialize tile
	setup_tile_3d()
	setup_3d_highlight_overlays()
	connect_3d_signals()

func create_3d_mesh():
	"""Create and setup the 3D mesh component with no gaps"""
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TileMesh"
	
	# Create a plane mesh that exactly fills tile_size with no gaps
	#var plane_mesh = PlaneMesh.new()
	#plane_mesh.size = Vector2(tile_size, tile_size)
	#plane_mesh.subdivide_width = 1  # Reduce subdivisions for performance
	#plane_mesh.subdivide_depth = 1
	#mesh_instance.mesh = plane_mesh
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(tile_size, 0.2, tile_size) # give a bit of thickness
	mesh_instance.mesh = box_mesh
	
	add_child(mesh_instance)

func create_3d_collision_shape():
	"""Create and setup the 3D collision shape"""
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	
	# Create box shape for the tile (thin for flat tiles)
	var shape = BoxShape3D.new()
	shape.size = Vector3(tile_size, 0.1, tile_size)  # Thin box for flat tile
	collision_shape.shape = shape
	
	add_child(collision_shape)

func create_3d_hover_indicator():
	"""Create 3D hover indicator (replaces 2D label)"""
	hover_indicator = MeshInstance3D.new()
	hover_indicator.name = "HoverIndicator"
	
	# Create a small sphere or cylinder for hover indication
	var indicator_mesh = CylinderMesh.new()
	indicator_mesh.top_radius = 0.1
	indicator_mesh.bottom_radius = 0.1
	indicator_mesh.height = 0.2
	hover_indicator.mesh = indicator_mesh
	
	# Create glowing material for hover indicator
	var indicator_material = StandardMaterial3D.new()
	indicator_material.albedo_color = Color.YELLOW
	indicator_material.emission_enabled = true
	indicator_material.emission = Color.YELLOW
	indicator_material.emission_energy = 0.5
	hover_indicator.material_override = indicator_material
	
	# Position above tile surface
	hover_indicator.position = Vector3(0, 0.2, 0)
	hover_indicator.visible = false
	add_child(hover_indicator)

func setup_tile_3d():
	"""Initialize the 3D tile based on its biome type"""
	var biome_data = get_biome_data(biome_type)
	
	# Create and apply material based on biome
	create_biome_material(biome_data)
	
	# Set tile properties from biome
	movement_cost = biome_data.movement_cost
	resources = biome_data.base_resources.duplicate()
	
	# CRITICAL: Position tiles so they connect seamlessly
	global_position = Vector3(
		grid_position.x * tile_size,  # Don't add offset - tiles should touch exactly
		elevation,
		grid_position.z * tile_size
	)

func create_biome_material(biome_data: Dictionary):
	"""Create 3D material based on biome type with edge considerations"""
	material = StandardMaterial3D.new()
	
	# Set base color
	material.albedo_color = biome_data.color
	
	# Disable backface culling to prevent holes
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Ensure no gaps by disabling depth testing issues
	material.no_depth_test = false
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	
	# Load texture if available
	if biome_data.has("texture_path"):
		var texture = load(biome_data.texture_path) as Texture2D
		if texture:
			material.albedo_texture = texture
			# Ensure texture wrapping doesn't create gaps
			material.uv1_scale = Vector3(1, 1, 1)
	
	# Set material properties based on biome
	match biome_type:
		BiomeType.WATER:
			material.metallic = 0.0
			material.roughness = 0.0
		BiomeType.MOUNTAIN:
			material.metallic = 0.2
			material.roughness = 0.8
		BiomeType.FOREST:
			material.roughness = 0.9
		_:
			material.metallic = 0.0
			material.roughness = 0.7
	
	mesh_instance.material_override = material
func setup_3d_highlight_overlays():
	"""Setup 3D highlight overlays (replace 2D ColorRect overlays)"""
	# Movement highlight
	movement_highlight = create_highlight_overlay(Color(0, 0, 1, 0.3))  # Blue
	movement_highlight.name = "MovementHighlight"
	
	# Build highlight  
	build_highlight = create_highlight_overlay(Color(0.8, 0.4, 0.8, 0.3))  # Purple
	build_highlight.name = "BuildHighlight"
	
	# Interact highlight
	interact_highlight = create_highlight_overlay(Color(1.0, 1.0, 0.0, 0.4))  # Yellow
	interact_highlight.name = "InteractHighlight"
	
	# Attack highlight
	attack_highlight = create_highlight_overlay(Color(1.0, 0.0, 0.0, 0.4))  # Red
	attack_highlight.name = "AttackHighlight"

func create_highlight_overlay(color: Color) -> MeshInstance3D:
	"""Create a 3D highlight overlay mesh"""
	var highlight = MeshInstance3D.new()
	
	# Create a slightly larger plane above the tile
	var highlight_mesh = PlaneMesh.new()
	highlight_mesh.size = Vector2(tile_size * 1.1, tile_size * 1.1)
	highlight.mesh = highlight_mesh
	
	# Create transparent material with the specified color
	var highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = color
	highlight_material.flags_transparent = true
	highlight_material.no_depth_test = true
	highlight_material.flags_unshaded = true
	highlight.material_override = highlight_material
	
	# Position slightly above tile surface
	highlight.position = Vector3(0, 0.01, 0)
	highlight.visible = false
	
	add_child(highlight)
	return highlight

func connect_3d_signals():
	"""Connect 3D-specific signals"""
	# 3D input events work differently - handled by mouse raycasting in MapManager
	input_event.connect(_on_input_event_3d)
	mouse_entered.connect(_on_mouse_entered_3d)
	mouse_exited.connect(_on_mouse_exited_3d)

func _on_input_event_3d(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int):
	"""Handle 3D input events"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			tile_clicked.emit(self)
			show_tile_details_3d()

func _on_mouse_entered_3d():
	"""Handle 3D mouse hover"""
	tile_hovered.emit(self)
	# Show hover indicator
	if hover_indicator:
		hover_indicator.visible = true
	
	# Add subtle glow effect
	if material:
		create_tween().tween_property(material, "emission_energy", 0.2, 0.1)

func _on_mouse_exited_3d():
	"""Handle 3D mouse exit"""
	# Hide hover indicator
	if hover_indicator:
		hover_indicator.visible = false
	
	# Remove glow effect
	if material:
		create_tween().tween_property(material, "emission_energy", 0.0, 0.1)

# 3D Highlight methods (updated for 3D)
func set_movement_highlighted(highlighted: bool):
	"""Set the movement highlight state"""
	is_movement_highlighted = highlighted
	if movement_highlight:
		movement_highlight.visible = highlighted

func set_build_highlighted(highlighted: bool):
	"""Set the build highlight state"""
	is_build_highlighted = highlighted
	if build_highlight:
		build_highlight.visible = highlighted

func set_interact_highlighted(highlighted: bool):
	"""Set the interact highlight state"""
	is_interact_highlighted = highlighted
	if interact_highlight:
		interact_highlight.visible = highlighted
	
	# Add pulsing animation for interact mode
	if highlighted:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(self, "scale", Vector3(1.05, 1.0, 1.05), 0.5)
		tween.tween_property(self, "scale", Vector3.ONE, 0.5)
	else:
		var tweens = get_tree().get_processed_tweens()
		for tween in tweens:
			if tween.is_valid():
				tween.kill()
		scale = Vector3.ONE

func set_attack_highlighted(highlighted: bool):
	"""Set the attack highlight state"""
	is_attack_highlighted = highlighted
	if attack_highlight:
		attack_highlight.visible = highlighted
	
	# Add pulsing red glow for attack mode
	if highlighted and attack_highlight:
		var highlight_material = attack_highlight.material_override as StandardMaterial3D
		if highlight_material:
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(highlight_material, "albedo_color:a", 0.6, 0.5)
			tween.tween_property(highlight_material, "albedo_color:a", 0.3, 0.5)
	else:
		var tweens = get_tree().get_processed_tweens()
		for tween in tweens:
			if tween.is_valid():
				tween.kill()

func set_elevation(new_elevation: float):
	"""Set tile elevation (new 3D feature)"""
	elevation = new_elevation
	global_position.y = elevation
	
	# Update collision shape position if needed
	if collision_shape:
		collision_shape.position.y = 0

func get_biome_data(biome: BiomeType) -> Dictionary:
	"""Return 3D biome-specific data"""
	match biome:
		BiomeType.GRASSLAND:
			return {
				"color": Color(0.4, 0.8, 0.2),  # Green
				"texture_path": "res://assets/tiles/3d/grassland_texture.png",
				"movement_cost": 1.0,
				"base_resources": {"food": 2, "wood": 0},
				"building_bonus": {"farm": 1.5},
				"name": "Grassland"
			}
		BiomeType.FOREST:
			return {
				"color": Color(0.2, 0.6, 0.2),  # Dark Green
				"texture_path": "res://assets/tiles/3d/forest_texture.png",
				"movement_cost": 1.5,
				"base_resources": {"food": 1, "wood": 3},
				"building_bonus": {"lumber_mill": 2.0},
				"name": "Forest"
			}
		BiomeType.MOUNTAIN:
			return {
				"color": Color(0.6, 0.5, 0.4),  # Brown/Gray
				"texture_path": "res://assets/tiles/3d/mountain_texture.png",
				"movement_cost": 2.0,
				"base_resources": {"stone": 2, "metal": 1},
				"building_bonus": {"mine": 2.0},
				"name": "Mountain"
			}
		BiomeType.WATER:
			return {
				"color": Color(0.2, 0.4, 0.8),  # Blue
				"texture_path": "res://assets/tiles/3d/water_texture.png",
				"movement_cost": 999.0,  # Impassable
				"base_resources": {"fish": 2},
				"building_bonus": {"dock": 1.5},
				"name": "Water"
			}
		BiomeType.DESERT:
			return {
				"color": Color(0.8, 0.7, 0.4),  # Sand color
				"texture_path": "res://assets/tiles/3d/desert_texture.png",
				"movement_cost": 1.3,
				"base_resources": {"stone": 1},
				"building_bonus": {"mine": 1.2},
				"name": "Desert"
			}
		BiomeType.SWAMP:
			return {
				"color": Color(0.4, 0.5, 0.3),  # Muddy green
				"texture_path": "res://assets/tiles/3d/swamp_texture.png",
				"movement_cost": 2.5,
				"base_resources": {"wood": 1, "herbs": 2},
				"building_bonus": {"farm": 0.8},
				"name": "Swamp"
			}
		_:
			return {
				"color": Color.GRAY,
				"texture_path": "res://assets/tiles/3d/default_texture.png",
				"movement_cost": 1.0,
				"base_resources": {},
				"building_bonus": {},
				"name": "Unknown"
			}

func show_tile_details_3d():
	"""Show 3D tile details (you might want a 3D floating UI)"""
	var biome_data = get_biome_data(biome_type)
	print("=== 3D TILE DETAILS ===")
	print("Biome: ", biome_data.name)
	print("3D Position: ", grid_position)
	print("World Position: ", global_position)
	print("Elevation: ", elevation)
	print("Resources: ", resources)
	print("Movement Cost: ", movement_cost)
	print("=====================")

# Utility methods for 3D operations
func get_world_center() -> Vector3:
	"""Get the world center position of this tile"""
	return global_position

func get_distance_to_3d(other_tile: BiomeTile3D) -> float:
	"""Get 3D distance to another tile"""
	return global_position.distance_to(other_tile.global_position)

func get_grid_distance_to(other_tile: BiomeTile3D) -> int:
	"""Get grid-based distance (Manhattan distance in 3D)"""
	var diff = grid_position - other_tile.grid_position
	return abs(diff.x) + abs(diff.y) + abs(diff.z)

func get_neighbors_3d() -> Array[BiomeTile3D]:
	"""Get neighboring tiles using the 3D map manager"""
	if not map_manager:
		push_warning("BiomeTile3D has no map_manager reference")
		return []
	return map_manager.get_neighbors_3d(self)

# Legacy compatibility methods
func get_neighbors() -> Array[BiomeTile3D]:
	"""Legacy method - forwards to 3D version"""
	return get_neighbors_3d()

func get_distance_to(other_tile: BiomeTile3D) -> float:
	"""Legacy method - forwards to 3D version"""
	return get_distance_to_3d(other_tile)
