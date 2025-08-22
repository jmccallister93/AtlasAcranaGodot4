extends Camera3D
class_name ExpeditionCamera3D

# Movement settings
@export var move_speed: float = 400.0
@export var fov_speed: float = 5.0
@export var min_fov: float = 20.0
@export var max_fov: float = 120.0

# Mouse drag settings
@export var enable_mouse_drag: bool = true
@export var drag_sensitivity: float = 1.0

# Optional camera bounds (set these if you want to limit camera movement)
@export var use_bounds: bool = false
@export var bounds_rect: AABB = AABB(Vector3(-1000, -1000, -1000), Vector3(2000, 2000, 2000))

# Smooth movement settings
@export var smooth_movement: bool = true
@export var movement_smoothing: float = 10.0

# Internal variables
var target_position: Vector3
var movement_input: Vector3

# Mouse drag variables
var is_dragging: bool = false
var drag_start_position: Vector2
var last_mouse_position: Vector2

func _ready():
	# Initialize target position to current position
	target_position = global_position
	
	# Enable camera as current
	make_current()
	
	# Set initial FOV if needed
	fov = 75.0

func _process(delta):
	handle_input()
	update_camera_movement(delta)

func handle_input():
	"""Handle WASD movement input"""
	movement_input = Vector3.ZERO
	
	# WASD movement input (X and Z axes for horizontal movement)
	if Input.is_action_pressed("ui_left"):
		movement_input.x -= 1
	if Input.is_action_pressed("ui_right"):
		movement_input.x += 1
	if Input.is_action_pressed("ui_up"):
		movement_input.z -= 1
	if Input.is_action_pressed("ui_down"):
		movement_input.z += 1
	
	# Optional: Add Q/E for Y-axis movement (up/down)
	#if Input.is_action_pressed("move_up"):
		#movement_input.y += 1
	#if Input.is_action_pressed("move_down"):
		#movement_input.y -= 1
	
	# Normalize diagonal movement so it's not faster
	movement_input = movement_input.normalized()

func handle_fov_input():
	"""Handle camera FOV controls"""
	# Q/E key FOV (if you add these input actions)
	if Input.is_action_just_pressed("zoom_in"):
		zoom_in()
	elif Input.is_action_just_pressed("zoom_out"):
		zoom_out()

func _unhandled_input(event):
	"""Handle mouse wheel FOV and mouse drag"""
	if event is InputEventMouseButton:
		if event.pressed:
			# Handle FOV
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_in()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_out()
			# Handle drag start
			elif event.button_index == MOUSE_BUTTON_LEFT and enable_mouse_drag:
				start_mouse_drag(event.position)
		else:
			# Handle drag end
			if event.button_index == MOUSE_BUTTON_LEFT and is_dragging:
				stop_mouse_drag()
	
	elif event is InputEventMouseMotion:
		# Handle mouse drag movement
		if is_dragging:
			update_mouse_drag(event.position)

func start_mouse_drag(mouse_pos: Vector2):
	"""Start mouse drag camera movement"""
	is_dragging = true
	drag_start_position = mouse_pos
	last_mouse_position = mouse_pos
	
	# Optional: Change cursor to indicate dragging
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)

func stop_mouse_drag():
	"""Stop mouse drag camera movement"""
	is_dragging = false
	
	# Reset cursor
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func update_mouse_drag(mouse_pos: Vector2):
	"""Update camera position based on mouse drag"""
	if not is_dragging:
		return
	
	# Calculate mouse movement delta
	var mouse_delta = last_mouse_position - mouse_pos
	
	# Convert screen movement to 3D world movement
	var camera_transform = global_transform
	var right = camera_transform.basis.x
	var up = camera_transform.basis.y
	
	# Scale movement based on distance and FOV
	var distance_factor = global_position.length() * 0.001
	var fov_factor = fov / 75.0  # Normalize to default FOV
	var world_delta = (right * mouse_delta.x + up * mouse_delta.y) * distance_factor * fov_factor * drag_sensitivity
	
	# Update target position
	target_position += world_delta
	
	# Apply bounds if enabled
	if use_bounds:
		target_position = target_position.clamp(bounds_rect.position, bounds_rect.position + bounds_rect.size)
	
	# Update last mouse position
	last_mouse_position = mouse_pos

func zoom_in():
	"""Decrease FOV (zoom in)"""
	var new_fov = fov - fov_speed
	fov = clamp(new_fov, min_fov, max_fov)

func zoom_out():
	"""Increase FOV (zoom out)"""
	var new_fov = fov + fov_speed
	fov = clamp(new_fov, min_fov, max_fov)

func update_camera_movement(delta):
	"""Update camera position based on input"""
	# Handle WASD movement (only if not dragging)
	if movement_input != Vector3.ZERO and not is_dragging:
		# Calculate movement speed (no FOV adjustment needed in 3D)
		var adjusted_speed = move_speed
		
		# Update target position
		target_position += movement_input * adjusted_speed * delta
		
		# Apply bounds if enabled
		if use_bounds:
			target_position = target_position.clamp(bounds_rect.position, bounds_rect.position + bounds_rect.size)
	
	# Apply movement (smooth or instant)
	# Mouse drag updates target_position directly, so this handles both WASD and drag
	if smooth_movement:
		global_position = global_position.lerp(target_position, movement_smoothing * delta)
	else:
		global_position = target_position

# Public methods for external control
func set_camera_position(new_position: Vector3):
	"""Set camera position directly"""
	target_position = new_position
	if not smooth_movement:
		global_position = new_position

func move_to_position(new_position: Vector3, instant: bool = false):
	"""Move camera to a specific position"""
	target_position = new_position
	if instant:
		global_position = new_position

func set_fov_level(new_fov: float):
	"""Set camera FOV level"""
	fov = clamp(new_fov, min_fov, max_fov)

func get_camera_bounds() -> AABB:
	"""Get the current camera viewport bounds in world coordinates"""
	# This is approximate - 3D camera bounds are more complex
	var viewport_size = get_viewport().get_visible_rect().size
	var distance = global_position.length()
	var fov_factor = tan(deg_to_rad(fov * 0.5))
	var world_height = 2.0 * distance * fov_factor
	var world_width = world_height * (viewport_size.x / viewport_size.y)
	
	var half_size = Vector3(world_width * 0.5, world_height * 0.5, distance)
	return AABB(global_position - half_size, half_size * 2)

func set_bounds(new_bounds: AABB):
	"""Set camera movement bounds"""
	bounds_rect = new_bounds
	use_bounds = true

func disable_bounds():
	"""Disable camera bounds"""
	use_bounds = false

func set_drag_enabled(enabled: bool):
	"""Enable or disable mouse drag functionality"""
	enable_mouse_drag = enabled
	if not enabled and is_dragging:
		stop_mouse_drag()

func is_mouse_dragging() -> bool:
	"""Check if currently dragging with mouse"""
	return is_dragging

# Utility methods
func focus_on_tile(tile_position: Vector3):
	"""Focus camera on a specific tile"""
	move_to_position(tile_position)

func focus_on_area(area_bounds: AABB, padding: float = 100.0):
	"""Focus camera to show a specific area"""
	var center = area_bounds.get_center()
	var area_size = area_bounds.size + Vector3(padding, padding, padding)
	
	# Calculate optimal distance and FOV to fit the area
	var max_dimension = max(area_size.x, max(area_size.y, area_size.z))
	var optimal_distance = max_dimension / (2.0 * tan(deg_to_rad(45.0)))  # Assume 45° FOV for calculation
	
	# Move camera back from center
	var direction = (global_position - center).normalized()
	if direction == Vector3.ZERO:
		direction = Vector3(0, 0, 1)  # Default direction if at center
	
	var optimal_position = center + direction * optimal_distance
	move_to_position(optimal_position)

# Additional 3D-specific methods
func look_at_position(target: Vector3, up_vector: Vector3 = Vector3.UP):
	"""Make camera look at a specific position"""
	look_at(target, up_vector)

func orbit_around_point(center: Vector3, radius: float, angle_y: float, angle_x: float = 0.0):
	"""Position camera in orbit around a point"""
	var orbit_position = Vector3(
		center.x + radius * cos(angle_y) * cos(angle_x),
		center.y + radius * sin(angle_x),
		center.z + radius * sin(angle_y) * cos(angle_x)
	)
	
	set_camera_position(orbit_position)
	look_at_position(center)

func set_projection_mode(use_orthogonal: bool, ortho_size: float = 10.0):
	"""Switch between perspective and orthogonal projection"""
	if use_orthogonal:
		projection = PROJECTION_ORTHOGONAL
		size = ortho_size
	else:
		projection = PROJECTION_PERSPECTIVE
