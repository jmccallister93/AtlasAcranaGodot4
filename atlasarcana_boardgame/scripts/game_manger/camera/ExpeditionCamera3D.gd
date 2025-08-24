# ExpeditionCamera3D.gd - 3D Conversion of ExpeditionCamera
extends Camera3D  # Changed from Camera2D
class_name ExpeditionCamera3D

# Camera movement settings
@export var move_speed: float = 10.0
@export var orbit_speed: float = 2.0
@export var zoom_speed: float = 2.0

# Distance constraints (replaces zoom)
@export var min_distance: float = 5.0
@export var max_distance: float = 50.0
@export var default_distance: float = 15.0

# Angle constraints
@export var min_angle: float = -80.0  # How low camera can look (degrees)
@export var max_angle: float = -10.0  # How high camera can look (degrees)

# Mouse control settings
@export var enable_mouse_orbit: bool = true
@export var orbit_sensitivity: float = 2.0
@export var enable_mouse_pan: bool = true
@export var pan_sensitivity: float = 1.0

# Camera bounds (optional)
@export var use_bounds: bool = false
@export var bounds_size: Vector3 = Vector3(50, 10, 50)

# Camera modes
enum CameraMode {
	FREE,        # Free camera movement
	ORBIT,       # Orbit around a target
	FOLLOW       # Follow a target
}

# Internal state
var current_mode: CameraMode = CameraMode.ORBIT
var target_position: Vector3 = Vector3.ZERO
var current_distance: float
var current_yaw: float = 0.0      # Horizontal rotation (Y-axis)
var current_pitch: float = -45.0  # Vertical rotation (X-axis)

# Smooth movement
@export var smooth_movement: bool = true
@export var movement_smoothing: float = 8.0
@export var rotation_smoothing: float = 10.0

# Input state
var is_orbiting: bool = false
var is_panning: bool = false
var last_mouse_position: Vector2
var movement_input: Vector3

# Target following
var follow_target: Node3D = null

func _ready():
	"""Initialize the 3D camera"""
	current_distance = default_distance
	
	# Add to camera group for easy finding
	add_to_group("expedition_camera")
	
	# Set initial position based on orbit parameters
	update_camera_position()
	
	# Make this camera current
	make_current()
	
	print("ExpeditionCamera3D initialized")

func _process(delta):
	"""Update camera each frame"""
	handle_keyboard_input(delta)
	update_camera_movement(delta)

func handle_keyboard_input(delta):
	"""Handle WASD and other keyboard input"""
	movement_input = Vector3.ZERO
	
	# WASD movement (world-space)
	if Input.is_action_pressed("ui_left"):
		movement_input.x -= 1
	if Input.is_action_pressed("ui_right"):
		movement_input.x += 1
	if Input.is_action_pressed("ui_up"):
		movement_input.z -= 1  # Forward in 3D
	if Input.is_action_pressed("ui_down"):
		movement_input.z += 1  # Backward in 3D
	
	# Q/E for up/down movement
	if Input.is_action_pressed("camera_up"):
		movement_input.y += 1
	if Input.is_action_pressed("camera_down"):
		movement_input.y -= 1
	
	# Normalize movement
	movement_input = movement_input.normalized()

func _unhandled_input(event):
	"""Handle mouse input for camera control"""
	if event is InputEventMouseButton:
		handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)

func handle_mouse_button(event: InputEventMouseButton):
	"""Handle mouse button events for camera control"""
	if event.button_index == MOUSE_BUTTON_RIGHT:
		# Right mouse button for orbiting
		if event.pressed:
			start_orbit(event.position)
		else:
			end_orbit()
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		# Middle mouse button for panning
		if event.pressed:
			start_pan(event.position)
		else:
			end_pan()
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		# Zoom in (decrease distance)
		zoom_in()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		# Zoom out (increase distance)
		zoom_out()

func handle_mouse_motion(event: InputEventMouseMotion):
	"""Handle mouse motion for orbit and pan"""
	if is_orbiting and enable_mouse_orbit:
		update_orbit(event.relative)
	elif is_panning and enable_mouse_pan:
		update_pan(event.relative)

func start_orbit(mouse_pos: Vector2):
	"""Start orbiting with mouse"""
	is_orbiting = true
	last_mouse_position = mouse_pos
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)

func end_orbit():
	"""End orbiting"""
	is_orbiting = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func start_pan(mouse_pos: Vector2):
	"""Start panning with mouse"""
	is_panning = true
	last_mouse_position = mouse_pos
	Input.set_default_cursor_shape(Input.CURSOR_MOVE)

func end_pan():
	"""End panning"""
	is_panning = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func update_orbit(mouse_delta: Vector2):
	"""Update camera orbit based on mouse movement"""
	# Update yaw (horizontal rotation)
	current_yaw -= mouse_delta.x * orbit_sensitivity * get_process_delta_time()
	
	# Update pitch (vertical rotation) with constraints
	current_pitch -= mouse_delta.y * orbit_sensitivity * get_process_delta_time()
	current_pitch = clamp(current_pitch, min_angle, max_angle)

func update_pan(mouse_delta: Vector2):
	"""Update camera pan (move target position)"""
	var pan_delta = Vector3.ZERO
	
	# Calculate pan movement in camera space
	var right_vector = transform.basis.x
	var up_vector = Vector3.UP
	
	pan_delta += right_vector * mouse_delta.x * pan_sensitivity * get_process_delta_time()
	pan_delta += up_vector * mouse_delta.y * pan_sensitivity * get_process_delta_time()
	
	# Apply to target position
	target_position += pan_delta

func zoom_in():
	"""Zoom camera in (decrease distance from target)"""
	current_distance = clamp(current_distance - zoom_speed, min_distance, max_distance)

func zoom_out():
	"""Zoom camera out (increase distance from target)"""
	current_distance = clamp(current_distance + zoom_speed, min_distance, max_distance)

func update_camera_movement(delta):
	"""Update camera position and rotation"""
	# Handle WASD movement of target position
	if movement_input != Vector3.ZERO:
		var move_delta = movement_input * move_speed * delta
		
		# Move relative to camera orientation for intuitive controls
		var forward = -transform.basis.z
		var right = transform.basis.x
		
		target_position += right * move_delta.x
		target_position += Vector3.UP * move_delta.y
		target_position += forward * move_delta.z
	
	# Apply bounds if enabled
	if use_bounds:
		target_position.x = clamp(target_position.x, -bounds_size.x/2, bounds_size.x/2)
		target_position.y = clamp(target_position.y, 0, bounds_size.y)
		target_position.z = clamp(target_position.z, -bounds_size.z/2, bounds_size.z/2)
	
	# Update camera position based on current mode
	match current_mode:
		CameraMode.ORBIT:
			update_orbit_position(delta)
		CameraMode.FOLLOW:
			update_follow_position(delta)
		CameraMode.FREE:
			update_free_position(delta)

func update_orbit_position(delta):
	"""Update camera position in orbit mode"""
	# Calculate target camera position based on spherical coordinates
	var yaw_rad = deg_to_rad(current_yaw)
	var pitch_rad = deg_to_rad(current_pitch)
	
	var target_pos = Vector3(
		target_position.x + current_distance * sin(pitch_rad) * sin(yaw_rad),
		target_position.y + current_distance * cos(pitch_rad),
		target_position.z + current_distance * sin(pitch_rad) * cos(yaw_rad)
	)
	
	# Apply smooth movement or direct positioning
	if smooth_movement:
		global_position = global_position.lerp(target_pos, movement_smoothing * delta)
	else:
		global_position = target_pos
	
	# Always look at target
	look_at(target_position, Vector3.UP)

func update_follow_position(delta):
	"""Update camera position in follow mode"""
	if follow_target:
		target_position = follow_target.global_position
		update_orbit_position(delta)

func update_free_position(delta):
	"""Update camera position in free mode"""
	# Free camera movement (not implemented in this example)
	pass

# Public interface methods
func set_target_position(new_target: Vector3):
	"""Set the position the camera orbits around"""
	target_position = new_target

func focus_on_position(pos: Vector3, instant: bool = false):
	"""Focus camera on a specific position"""
	target_position = pos
	if instant:
		update_orbit_position(0.0)

func focus_on_tile(tile: BiomeTile3D, instant: bool = false):
	"""Focus camera on a specific tile"""
	focus_on_position(tile.global_position, instant)



#func focus_on_character(character: Character, instant: bool = false):
	#"""Focus camera on the player character"""
	#focus_on_position(character.global_position, instant)
	
func update_camera_position(delta: float = 0.0):
	"""Legacy method name for compatibility - forwards to orbit position update"""
	update_orbit_position(delta)

func set_follow_target(target: Node3D):
	"""Set target to follow"""
	follow_target = target
	current_mode = CameraMode.FOLLOW

func set_orbit_mode():
	"""Set camera to orbit mode"""
	current_mode = CameraMode.ORBIT
	follow_target = null

func set_distance(distance: float, instant: bool = false):
	"""Set camera distance from target"""
	current_distance = clamp(distance, min_distance, max_distance)
	if instant:
		update_orbit_position(0.0)

func set_angles(yaw: float, pitch: float, instant: bool = false):
	"""Set camera orbit angles"""
	current_yaw = yaw
	current_pitch = clamp(pitch, min_angle, max_angle)
	if instant:
		update_orbit_position(0.0)

func get_camera_info() -> Dictionary:
	"""Get current camera information"""
	return {
		"position": global_position,
		"target": target_position,
		"distance": current_distance,
		"yaw": current_yaw,
		"pitch": current_pitch,
		"mode": current_mode
	}

# Bounds management
func set_bounds(new_bounds: Vector3):
	"""Set camera movement bounds"""
	bounds_size = new_bounds
	use_bounds = true

func enable_bounds(enabled: bool):
	"""Enable or disable bounds"""
	use_bounds = enabled

# Camera mode switching
func set_camera_mode(mode: CameraMode):
	"""Set camera mode"""
	current_mode = mode
	
	match mode:
		CameraMode.FREE:
			print("Camera set to FREE mode")
		CameraMode.ORBIT:
			print("Camera set to ORBIT mode")
		CameraMode.FOLLOW:
			print("Camera set to FOLLOW mode")

# Preset camera positions
func set_preset_view(preset_name: String):
	"""Set camera to a preset view"""
	match preset_name:
		"overview":
			set_angles(0, -60)
			set_distance(30)
		"close":
			set_angles(0, -30)
			set_distance(10)
		"side":
			set_angles(90, -45)
			set_distance(20)
		"top_down":
			set_angles(0, -89)
			set_distance(25)
		_:
			print("Unknown preset: ", preset_name)

# Utility methods
func get_look_direction() -> Vector3:
	"""Get the direction the camera is looking"""
	return -transform.basis.z

func get_right_direction() -> Vector3:
	"""Get the camera's right direction"""
	return transform.basis.x

func get_up_direction() -> Vector3:
	"""Get the camera's up direction"""
	return transform.basis.y

func is_position_in_view(pos: Vector3) -> bool:
	"""Check if a position is visible in the camera's view"""
	var screen_pos = unproject_position(pos)
	var viewport_rect = get_viewport().get_visible_rect()
	return viewport_rect.has_point(screen_pos)

# Save/Load camera state (useful for save games)
func save_camera_state() -> Dictionary:
	"""Save current camera state"""
	return {
		"target_position": var_to_str(target_position),
		"distance": current_distance,
		"yaw": current_yaw,
		"pitch": current_pitch,
		"mode": current_mode
	}

func load_camera_state(state: Dictionary):
	"""Load camera state"""
	if state.has("target_position"):
		target_position = str_to_var(state.target_position)
	if state.has("distance"):
		current_distance = state.distance
	if state.has("yaw"):
		current_yaw = state.yaw
	if state.has("pitch"):
		current_pitch = state.pitch
	if state.has("mode"):
		current_mode = state.mode
	
	# Apply immediately
	update_orbit_position(0.0)

# Debug methods
func debug_print_camera_info():
	"""Print debug information about camera state"""
	print("=== ExpeditionCamera3D Debug ===")
	print("Position: ", global_position)
	print("Target: ", target_position)
	print("Distance: ", current_distance)
	print("Yaw: ", current_yaw)
	print("Pitch: ", current_pitch)
	print("Mode: ", CameraMode.keys()[current_mode])
	print("Orbiting: ", is_orbiting)
	print("Panning: ", is_panning)
	print("===============================")

func debug_visualize_target():
	"""Add a visual indicator at the target position (for debugging)"""
	var indicator = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	indicator.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.emission_enabled = true
	material.emission = Color.RED
	indicator.material_override = material
	
	get_tree().current_scene.add_child(indicator)
	indicator.global_position = target_position
	
	# Remove after 3 seconds
	get_tree().create_timer(3.0).timeout.connect(func(): indicator.queue_free())
