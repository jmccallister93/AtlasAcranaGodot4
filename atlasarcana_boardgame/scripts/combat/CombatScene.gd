# SimpleCombatScene3D.gd - Create this as a new script
extends Node3D
class_name CombatScene

signal combat_finished()

# 3D Components
var combat_camera: Camera3D
var test_cube: MeshInstance3D
var ground_plane: MeshInstance3D
var light: DirectionalLight3D
var environment: Environment

# UI for 3D scene
var combat_ui: Control
var return_button: Button
var pause_button: Button

# Combat state
var is_paused: bool = false

func _ready():
	"""Initialize the 3D combat scene"""
	print("SimpleCombatScene3D: Creating 3D combat scene")
	create_3d_environment()
	create_combat_ui()
	setup_camera_controls()

func create_3d_environment():
	"""Create the basic 3D environment"""
	print("Creating 3D environment...")
	
	# Create camera
	combat_camera = Camera3D.new()
	combat_camera.name = "CombatCamera"
	combat_camera.position = Vector3(5, 8, 10)
	combat_camera.look_at(Vector3.ZERO, Vector3.UP)
	add_child(combat_camera)
	combat_camera.current = true
	
	# Create lighting
	light = DirectionalLight3D.new()
	light.name = "DirectionalLight"
	light.position = Vector3(0, 10, 5)
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.0
	add_child(light)
	
	# Create ground plane
	ground_plane = MeshInstance3D.new()
	ground_plane.name = "Ground"
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(20, 20)
	ground_plane.mesh = plane_mesh
	
	# Create ground material
	var ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.3, 0.6, 0.3)  # Green
	ground_plane.material_override = ground_material
	add_child(ground_plane)
	
	# Create test cube
	test_cube = MeshInstance3D.new()
	test_cube.name = "TestCube"
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(2, 2, 2)
	test_cube.mesh = cube_mesh
	test_cube.position = Vector3(0, 1, 0)
	
	# Create cube material
	var cube_material = StandardMaterial3D.new()
	cube_material.albedo_color = Color(0.8, 0.2, 0.2)  # Red
	cube_material.metallic = 0.3
	cube_material.roughness = 0.7
	test_cube.material_override = cube_material
	add_child(test_cube)
	
	# Create environment
	var world_env = WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_horizon_color = Color(0.64625, 0.65575, 0.67075)
	sky_material.ground_horizon_color = Color(0.64625, 0.65575, 0.67075)
	environment.sky.sky_material = sky_material
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.3
	world_env.environment = environment
	add_child(world_env)
	
	print("✅ 3D environment created")

func create_combat_ui():
	"""Create UI overlay for the 3D combat scene"""
	print("Creating combat UI...")
	
	# Create UI layer
	combat_ui = Control.new()
	combat_ui.name = "CombatUI"
	combat_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	combat_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(combat_ui)
	
	# Create return button
	return_button = Button.new()
	return_button.text = "Return to Expedition"
	return_button.size = Vector2(200, 50)
	return_button.position = Vector2(50, 50)
	return_button.pressed.connect(_on_return_button_pressed)
	
	# Style the return button
	var return_style = StyleBoxFlat.new()
	return_style.bg_color = Color(0.2, 0.2, 0.8, 0.9)
	return_style.border_color = Color(0.4, 0.4, 1.0)
	return_style.border_width_left = 2
	return_style.border_width_right = 2
	return_style.border_width_top = 2
	return_style.border_width_bottom = 2
	return_style.corner_radius_top_left = 8
	return_style.corner_radius_top_right = 8
	return_style.corner_radius_bottom_left = 8
	return_style.corner_radius_bottom_right = 8
	return_button.add_theme_stylebox_override("normal", return_style)
	return_button.add_theme_color_override("font_color", Color.WHITE)
	
	combat_ui.add_child(return_button)
	
	# Create pause button
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.size = Vector2(100, 50)
	pause_button.position = Vector2(270, 50)
	pause_button.pressed.connect(_on_pause_button_pressed)
	
	# Style the pause button
	var pause_style = StyleBoxFlat.new()
	pause_style.bg_color = Color(0.8, 0.6, 0.2, 0.9)
	pause_style.border_color = Color(1.0, 0.8, 0.4)
	pause_style.border_width_left = 2
	pause_style.border_width_right = 2
	pause_style.border_width_top = 2
	pause_style.border_width_bottom = 2
	pause_style.corner_radius_top_left = 8
	pause_style.corner_radius_top_right = 8
	pause_style.corner_radius_bottom_left = 8
	pause_style.corner_radius_bottom_right = 8
	pause_button.add_theme_stylebox_override("normal", pause_style)
	pause_button.add_theme_color_override("font_color", Color.WHITE)
	
	combat_ui.add_child(pause_button)
	
	# Create instructions label
	var instructions = Label.new()
	instructions.text = "3D Combat Test Scene\nUse mouse to rotate camera\nWASD to move camera"
	instructions.position = Vector2(50, 120)
	instructions.add_theme_color_override("font_color", Color.WHITE)
	instructions.add_theme_font_size_override("font_size", 16)
	combat_ui.add_child(instructions)
	
	print("✅ Combat UI created")

func setup_camera_controls():
	"""Setup basic camera controls"""
	print("Setting up camera controls...")
	# Camera controls will be handled in _input()
	set_process_input(true)

func _input(event):
	"""Handle camera controls and other input"""
	if not combat_camera:
		return
	
	# Mouse look
	if event is InputEventMouseMotion and Input.is_action_pressed("camera_rotate"):
		var sensitivity = 0.002
		
		# Rotate camera around the origin
		var current_pos = combat_camera.position
		var distance = current_pos.length()
		
		# Convert to spherical coordinates
		var theta = atan2(current_pos.x, current_pos.z)
		var phi = acos(current_pos.y / distance)
		
		# Apply rotation
		theta -= event.relative.x * sensitivity
		phi -= event.relative.y * sensitivity
		phi = clamp(phi, 0.1, PI - 0.1)  # Prevent flipping
		
		# Convert back to cartesian
		combat_camera.position = Vector3(
			distance * sin(phi) * sin(theta),
			distance * cos(phi),
			distance * sin(phi) * cos(theta)
		)
		
		combat_camera.look_at(Vector3.ZERO, Vector3.UP)
	
	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(-1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1.0)
	
	# WASD camera movement (alternative to mouse)
	var camera_speed = 0.5
	if Input.is_action_pressed("ui_up"):
		combat_camera.position += combat_camera.transform.basis.z * -camera_speed
	if Input.is_action_pressed("ui_down"):
		combat_camera.position += combat_camera.transform.basis.z * camera_speed
	if Input.is_action_pressed("ui_left"):
		combat_camera.position += combat_camera.transform.basis.x * -camera_speed
	if Input.is_action_pressed("ui_right"):
		combat_camera.position += combat_camera.transform.basis.x * camera_speed

func _zoom_camera(zoom_delta: float):
	"""Zoom camera in/out"""
	if not combat_camera:
		return
	
	var zoom_speed = 2.0
	var current_pos = combat_camera.position
	var distance = current_pos.length()
	var new_distance = clamp(distance + zoom_delta * zoom_speed, 3.0, 30.0)
	
	combat_camera.position = current_pos.normalized() * new_distance
	combat_camera.look_at(Vector3.ZERO, Vector3.UP)

func _process(delta):
	"""Update the combat scene"""
	if is_paused:
		return
	
	# Rotate the test cube for visual interest
	if test_cube:
		test_cube.rotation_degrees.y += 30.0 * delta
		test_cube.rotation_degrees.x += 15.0 * delta

func _on_return_button_pressed():
	"""Handle return button press"""
	print("SimpleCombatScene3D: Return button pressed")
	combat_finished.emit()

func _on_pause_button_pressed():
	"""Handle pause button press"""
	is_paused = !is_paused
	pause_button.text = "Resume" if is_paused else "Pause"
	print("SimpleCombatScene3D: Combat ", "paused" if is_paused else "resumed")

func cleanup():
	"""Clean up the combat scene"""
	print("SimpleCombatScene3D: Cleaning up 3D combat scene")
	queue_free()
