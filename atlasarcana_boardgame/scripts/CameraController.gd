extends Camera2D
class_name CameraController

# Movement settings
@export var move_speed: float = 400.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0

# Mouse drag settings
@export var enable_mouse_drag: bool = true
@export var drag_sensitivity: float = 1.0

# Optional camera bounds (set these if you want to limit camera movement)
@export var use_bounds: bool = false
@export var bounds_rect: Rect2 = Rect2(-1000, -1000, 2000, 2000)

# Smooth movement settings
@export var smooth_movement: bool = true
@export var movement_smoothing: float = 10.0

# Internal variables
var target_position: Vector2
var movement_input: Vector2

# Mouse drag variables
var is_dragging: bool = false
var drag_start_position: Vector2
var last_mouse_position: Vector2

func _ready():
	# Initialize target position to current position
	target_position = global_position
	
	# Enable camera as current
	make_current()
	
	# Set initial zoom if needed
	zoom = Vector2(1.0, 1.0)

func _process(delta):
	handle_input()
	update_camera_movement(delta)

func handle_input():
	"""Handle WASD movement input"""
	movement_input = Vector2.ZERO
	
	# WASD movement input
	if Input.is_action_pressed("ui_left"):
		movement_input.x -= 1
	if Input.is_action_pressed("ui_right"):
		movement_input.x += 1
	if Input.is_action_pressed("ui_up"):
		movement_input.y -= 1
	if Input.is_action_pressed("ui_down"):
		movement_input.y += 1
	
	# Normalize diagonal movement so it's not faster
	movement_input = movement_input.normalized()

func handle_zoom_input():
	"""Handle camera zoom controls"""
	# Q/E key zoom (if you add these input actions)
	if Input.is_action_just_pressed("zoom_in"):
		zoom_in()
	elif Input.is_action_just_pressed("zoom_out"):
		zoom_out()

func _unhandled_input(event):
	"""Handle mouse wheel zoom and mouse drag"""
	if event is InputEventMouseButton:
		if event.pressed:
			# Handle zoom
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
	
	# Convert screen space movement to world space
	# Account for camera zoom - more zoom means less movement per pixel
	var world_delta = mouse_delta / zoom * drag_sensitivity
	
	# Update target position (inverted because we want to "drag" the world)
	target_position += world_delta
	
	# Apply bounds if enabled
	if use_bounds:
		target_position.x = clamp(target_position.x, bounds_rect.position.x, bounds_rect.position.x + bounds_rect.size.x)
		target_position.y = clamp(target_position.y, bounds_rect.position.y, bounds_rect.position.y + bounds_rect.size.y)
	
	# Update last mouse position
	last_mouse_position = mouse_pos

func zoom_in():
	"""Zoom the camera in"""
	var new_zoom = zoom + Vector2(zoom_speed, zoom_speed)
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	zoom = new_zoom

func zoom_out():
	"""Zoom the camera out"""
	var new_zoom = zoom - Vector2(zoom_speed, zoom_speed)
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	zoom = new_zoom

func update_camera_movement(delta):
	"""Update camera position based on input"""
	# Handle WASD movement (only if not dragging)
	if movement_input != Vector2.ZERO and not is_dragging:
		# Calculate movement speed adjusted for zoom (move faster when zoomed out)
		var adjusted_speed = move_speed / zoom.x
		
		# Update target position
		target_position += movement_input * adjusted_speed * delta
		
		# Apply bounds if enabled
		if use_bounds:
			target_position.x = clamp(target_position.x, bounds_rect.position.x, bounds_rect.position.x + bounds_rect.size.x)
			target_position.y = clamp(target_position.y, bounds_rect.position.y, bounds_rect.position.y + bounds_rect.size.y)
	
	# Apply movement (smooth or instant)
	# Mouse drag updates target_position directly, so this handles both WASD and drag
	if smooth_movement:
		global_position = global_position.lerp(target_position, movement_smoothing * delta)
	else:
		global_position = target_position

# Public methods for external control
func set_camera_position(new_position: Vector2):
	"""Set camera position directly"""
	target_position = new_position
	if not smooth_movement:
		global_position = new_position

func move_to_position(new_position: Vector2, instant: bool = false):
	"""Move camera to a specific position"""
	target_position = new_position
	if instant:
		global_position = new_position

func set_zoom_level(new_zoom: float):
	"""Set camera zoom level"""
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)

func get_camera_bounds() -> Rect2:
	"""Get the current camera viewport bounds in world coordinates"""
	var viewport_size = get_viewport().get_visible_rect().size
	var world_size = viewport_size / zoom
	var top_left = global_position - world_size / 2
	return Rect2(top_left, world_size)

func set_bounds(new_bounds: Rect2):
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
func focus_on_tile(tile_position: Vector2):
	"""Focus camera on a specific tile"""
	move_to_position(tile_position)

func focus_on_area(area_rect: Rect2, padding: float = 100.0):
	"""Focus camera to show a specific area"""
	var center = area_rect.get_center()
	var area_size = area_rect.size + Vector2(padding, padding)
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Calculate zoom to fit the area
	var zoom_x = viewport_size.x / area_size.x
	var zoom_y = viewport_size.y / area_size.y
	var optimal_zoom = min(zoom_x, zoom_y)
	optimal_zoom = clamp(optimal_zoom, min_zoom, max_zoom)
	
	# Apply zoom and position
	set_zoom_level(optimal_zoom)
	move_to_position(center)
