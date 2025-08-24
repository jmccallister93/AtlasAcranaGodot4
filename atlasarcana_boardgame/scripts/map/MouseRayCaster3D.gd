# MouseRaycaster3D.gd - Updated with corner highlight system
extends Node3D
class_name MouseRaycaster3D

signal tile_clicked(tile: BiomeTile3D, click_position: Vector3)
signal tile_hovered(tile: BiomeTile3D, hover_position: Vector3)
signal tile_hover_ended(tile: BiomeTile3D)

# Raycast settings
var raycast_length: float = 1000.0
var collision_mask: int = 1  # Layer 1 for tiles

# Current state
var current_hovered_tile: BiomeTile3D = null
var camera: Camera3D = null

# Ray visualization (for debugging)
var debug_ray_visual: bool = false
var ray_mesh: MeshInstance3D
var ray_material: StandardMaterial3D

# Tile highlight system
var tile_highlight_node: Node3D
var corner_lines: Array[MeshInstance3D] = []
var highlight_material: StandardMaterial3D
var highlight_height: float = 0.1  # Height above tile surface
var corner_length_percent: float = 0.25  # 25% of tile edge length

func _ready():
	"""Initialize the mouse raycaster"""
	setup_debug_visualization()
	setup_tile_highlight_system()
	find_camera()

func find_camera():
	"""Find the active 3D camera"""
	# Wait a frame to ensure everything is loaded
	await get_tree().process_frame
	
	camera = get_viewport().get_camera_3d()
	if not camera:
		# Try to find any Camera3D node
		camera = get_tree().get_first_node_in_group("expedition_camera")
	
	if camera:
		print("MouseRaycaster3D: Found camera - ", camera.name)
	else:
		print("MouseRaycaster3D: WARNING - No Camera3D found!")

func setup_debug_visualization():
	"""Setup debug ray visualization"""
	if debug_ray_visual:
		ray_mesh = MeshInstance3D.new()
		ray_mesh.name = "DebugRay"
		
		# Create a thin cylinder for the ray
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = 0.01
		cylinder.bottom_radius = 0.01
		cylinder.height = raycast_length
		ray_mesh.mesh = cylinder
		
		# Create bright material
		ray_material = StandardMaterial3D.new()
		ray_material.albedo_color = Color.RED
		ray_material.emission_enabled = true
		ray_material.emission = Color.RED
		ray_material.emission_energy = 1.0
		ray_material.flags_unshaded = true
		ray_mesh.material_override = ray_material
		
		ray_mesh.visible = false
		add_child(ray_mesh)

func setup_tile_highlight_system():
	"""Setup the tile corner highlight system"""
	# Create container node for highlights
	tile_highlight_node = Node3D.new()
	tile_highlight_node.name = "TileHighlight"
	add_child(tile_highlight_node)
	
	# Create material for corner highlights
	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color.WHITE
	highlight_material.emission_enabled = true
	highlight_material.emission = Color.WHITE
	highlight_material.emission_energy = 1.0
	highlight_material.flags_unshaded = true
	highlight_material.no_depth_test = true  # Always visible on top
	highlight_material.flags_transparent = false  # Changed to false for better visibility
	highlight_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Visible from all angles
	
	# Create 8 corner line segments (2 per corner, 4 corners)
	create_corner_line_meshes()
	
	print("MouseRaycaster3D: Tile highlight system initialized")

func create_corner_line_meshes():
	"""Create the mesh instances for corner highlights"""
	corner_lines.clear()
	
	# Create 8 line segments (2 per corner)
	for i in range(8):
		var line_mesh = MeshInstance3D.new()
		line_mesh.name = "CornerLine" + str(i)
		
		# Create a thin box mesh for the line
		var box = BoxMesh.new()
		box.size = Vector3(1.0, 0.02, 0.02)  # Will be scaled per line
		line_mesh.mesh = box
		line_mesh.material_override = highlight_material
		
		tile_highlight_node.add_child(line_mesh)
		corner_lines.append(line_mesh)
	
	# Initially hide all corner lines
	hide_tile_highlight()

func show_tile_highlight(tile: BiomeTile3D):
	"""Show corner highlights for the specified tile"""
	if not tile:
		return
	
	var tile_size = tile.tile_size
	var tile_pos = tile.global_position
	var corner_length = tile_size * corner_length_percent
	
	# Position the highlight container
	tile_highlight_node.global_position = Vector3(tile_pos.x, tile_pos.y + highlight_height, tile_pos.z)
	
	# Calculate corner positions (assuming tile is centered)
	var half_size = tile_size * 0.5
	var corners = [
		Vector3(-half_size, 0, -half_size),  # Top-left
		Vector3(half_size, 0, -half_size),   # Top-right  
		Vector3(half_size, 0, half_size),    # Bottom-right
		Vector3(-half_size, 0, half_size)    # Bottom-left
	]
	
	# Set up each corner's two line segments
	for corner_idx in range(4):
		var corner_pos = corners[corner_idx]
		var line1_idx = corner_idx * 2      # Horizontal line
		var line2_idx = corner_idx * 2 + 1  # Vertical line
		
		# Calculate line directions based on corner
		var horizontal_dir: Vector3
		var vertical_dir: Vector3
		
		match corner_idx:
			0: # Top-left corner
				horizontal_dir = Vector3(1, 0, 0)   # Right
				vertical_dir = Vector3(0, 0, 1)     # Down
			1: # Top-right corner  
				horizontal_dir = Vector3(-1, 0, 0)  # Left
				vertical_dir = Vector3(0, 0, 1)     # Down
			2: # Bottom-right corner
				horizontal_dir = Vector3(-1, 0, 0)  # Left  
				vertical_dir = Vector3(0, 0, -1)    # Up
			3: # Bottom-left corner
				horizontal_dir = Vector3(1, 0, 0)   # Right
				vertical_dir = Vector3(0, 0, -1)    # Up
		
		# Position and scale horizontal line
		var h_line = corner_lines[line1_idx]
		h_line.position = corner_pos + horizontal_dir * (corner_length * 0.5)
		h_line.scale = Vector3(corner_length, 1, 1)
		h_line.visible = true
		
		# Position and scale vertical line  
		var v_line = corner_lines[line2_idx]
		v_line.position = corner_pos + vertical_dir * (corner_length * 0.5)
		v_line.scale = Vector3(corner_length, 1, 1)
		v_line.rotation_degrees = Vector3(0, 90, 0)  # Rotate to be perpendicular
		v_line.visible = true

func hide_tile_highlight():
	"""Hide all corner highlights"""
	for line in corner_lines:
		line.visible = false

func _input(event):
	"""Handle mouse input events"""
	if not camera:
		return
	
	if event is InputEventMouseMotion:
		handle_mouse_hover(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_mouse_click(event.position)

func handle_mouse_hover(mouse_pos: Vector2):
	"""Handle mouse hover for 3D tile selection"""
	var raycast_result = raycast_from_mouse(mouse_pos)
	
	if raycast_result and raycast_result.has("collider"):
		var collider = raycast_result.collider
		
		# Debug: Print what we hit
		print("Hit object: ", collider, " Type: ", collider.get_class())
		
		# Check if we hit a BiomeTile3D
		if collider is BiomeTile3D:
			var tile = collider as BiomeTile3D
			var hit_position = raycast_result.position
			
			print("Hit tile at grid position: ", tile.grid_position)
			print("Tile size: ", tile.tile_size if tile.has_method("get") and "tile_size" in tile else "NO TILE_SIZE")
			
			# If this is a new tile, handle hover change
			if tile != current_hovered_tile:
				# End hover on previous tile
				if current_hovered_tile:
					tile_hover_ended.emit(current_hovered_tile)
				
				# Start hover on new tile
				current_hovered_tile = tile
				tile_hovered.emit(tile, hit_position)
				
				# Show corner highlights for new tile
				print("Showing highlights for tile...")
				show_tile_highlight(tile)
		else:
			# Hit something else, end current hover
			if current_hovered_tile:
				tile_hover_ended.emit(current_hovered_tile)
				current_hovered_tile = null
				hide_tile_highlight()
	else:
		# Hit nothing, end current hover
		if current_hovered_tile:
			tile_hover_ended.emit(current_hovered_tile)
			current_hovered_tile = null
			hide_tile_highlight()

func handle_mouse_click(mouse_pos: Vector2):
	"""Handle mouse click for 3D tile interaction"""
	var raycast_result = raycast_from_mouse(mouse_pos)
	
	if raycast_result and raycast_result.has("collider"):
		var collider = raycast_result.collider
		
		# Check if we clicked on a BiomeTile3D (or its parent)
		var tile = find_tile_from_collider(collider)
		if tile:
			var click_position = raycast_result.position
			
			# Emit signal for game systems
			tile_clicked.emit(tile, click_position)
			
			# Call tile's click handler directly
			tile.handle_tile_clicked()
			
			print("Clicked tile at grid position: ", tile.grid_position)

func find_tile_from_collider(collider: Node) -> BiomeTile3D:
	"""Find BiomeTile3D from collider (may be child collision shape)"""
	var current = collider
	while current:
		if current is BiomeTile3D:
			return current as BiomeTile3D
		current = current.get_parent()
	return null

func raycast_from_mouse(mouse_pos: Vector2) -> Dictionary:
	"""Perform raycast from mouse position into 3D space"""
	if not camera:
		return {}
	
	# Create ray from camera through mouse position
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	var ray_end = ray_origin + ray_direction * raycast_length
	
	# Update debug visualization
	if debug_ray_visual and ray_mesh:
		ray_mesh.visible = true
		ray_mesh.position = ray_origin + ray_direction * (raycast_length / 2)
		ray_mesh.look_at(ray_origin + ray_direction, Vector3.UP)
		
		# Hide after a short time
		get_tree().create_timer(0.1).timeout.connect(func(): ray_mesh.visible = false)
	
	# Perform the raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = collision_mask
	
	var result = space_state.intersect_ray(query)
	
	return result

# Highlight customization methods
func set_highlight_color(color: Color):
	"""Change the color of tile highlights"""
	highlight_material.albedo_color = color
	highlight_material.emission = color

func set_highlight_height(height: float):
	"""Set how high above tiles the highlights appear"""
	highlight_height = height

func set_corner_length_percent(percent: float):
	"""Set what percentage of tile edge the corner lines cover"""
	corner_length_percent = clamp(percent, 0.1, 0.5)  # Reasonable limits

func set_highlight_thickness(thickness: float):
	"""Set the thickness of highlight lines"""
	for line in corner_lines:
		var mesh = line.mesh as BoxMesh
		if mesh:
			mesh.size.y = thickness
			mesh.size.z = thickness

# Existing methods continue unchanged...
func get_tile_at_mouse_position(mouse_pos: Vector2) -> BiomeTile3D:
	"""Get the tile under the mouse cursor"""
	var raycast_result = raycast_from_mouse(mouse_pos)
	
	if raycast_result and raycast_result.has("collider"):
		var collider = raycast_result.collider
		if collider is BiomeTile3D:
			return collider as BiomeTile3D
	
	return null

func get_world_position_at_mouse(mouse_pos: Vector2, y_plane: float = 0.0) -> Vector3:
	"""Get world position at mouse cursor (useful for non-tile placement)"""
	if not camera:
		return Vector3.ZERO
	
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	
	# Calculate intersection with Y plane
	if ray_direction.y != 0:
		var t = (y_plane - ray_origin.y) / ray_direction.y
		if t >= 0:  # Only forward intersections
			return ray_origin + ray_direction * t
	
	return Vector3.ZERO

# Configuration methods
func set_camera(new_camera: Camera3D):
	"""Set the camera to use for raycasting"""
	camera = new_camera

func set_collision_mask(mask: int):
	"""Set collision mask for raycast"""
	collision_mask = mask

func set_raycast_length(length: float):
	"""Set maximum raycast distance"""
	raycast_length = length

func enable_debug_visualization(enabled: bool):
	"""Enable/disable debug ray visualization"""
	debug_ray_visual = enabled
	if not enabled and ray_mesh:
		ray_mesh.visible = false

# Utility methods
func is_mouse_over_tile() -> bool:
	"""Check if mouse is currently over a tile"""
	return current_hovered_tile != null

func get_hovered_tile() -> BiomeTile3D:
	"""Get the currently hovered tile"""
	return current_hovered_tile

func clear_hover():
	"""Clear current hover state"""
	if current_hovered_tile:
		tile_hover_ended.emit(current_hovered_tile)
		current_hovered_tile = null
		hide_tile_highlight()

func _exit_tree():
	"""Cleanup when removed from tree"""
	if current_hovered_tile:
		tile_hover_ended.emit(current_hovered_tile)
		current_hovered_tile = null
	hide_tile_highlight()
