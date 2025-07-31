extends Camera2D
class_name CameraController

# Movement settings
@export var move_speed: float = 400.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0

# Optional camera bounds (set these if you want to limit camera movement)
@export var use_bounds: bool = false
@export var bounds_rect: Rect2 = Rect2(-1000, -1000, 2000, 2000)

# Smooth movement settings
@export var smooth_movement: bool = true
@export var movement_smoothing: float = 10.0

# Internal variables
var target_position: Vector2
var movement_input: Vector2

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
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
		movement_input.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		movement_input.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
		movement_input.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
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
	"""Handle mouse wheel zoom"""
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_in()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_out()

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
	if movement_input != Vector2.ZERO:
		# Calculate movement speed adjusted for zoom (move faster when zoomed out)
		var adjusted_speed = move_speed / zoom.x
		
		# Update target position
		target_position += movement_input * adjusted_speed * delta
		
		# Apply bounds if enabled
		if use_bounds:
			target_position.x = clamp(target_position.x, bounds_rect.position.x, bounds_rect.position.x + bounds_rect.size.x)
			target_position.y = clamp(target_position.y, bounds_rect.position.y, bounds_rect.position.y + bounds_rect.size.y)
	
	# Apply movement (smooth or instant)
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
