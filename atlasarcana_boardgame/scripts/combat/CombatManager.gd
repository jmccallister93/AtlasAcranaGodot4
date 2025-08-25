# CombatManager.gd - Updated to work with SceneManager architecture
extends Node
class_name CombatManager

signal combat_scene_finished(combat_results: Dictionary)

# References
var game_manager: GameManager
var scene_manager: SceneManager
var current_combat_scene: CombatScene

# Combat state
var is_in_combat: bool = false
var combat_data: Dictionary = {}
var combat_results: Dictionary = {}

func initialize(gm: GameManager):
	"""Initialize the combat manager"""
	game_manager = gm
	
	# Get scene manager reference from manager registry
	if game_manager.manager_registry:
		scene_manager = game_manager.manager_registry.get_scene_manager()
	
	print("CombatManager: Initialized with SceneManager integration")

# ═══════════════════════════════════════════════════════════
# COMBAT INITIALIZATION
# ═══════════════════════════════════════════════════════════

func start_simple_combat(combat_setup: Dictionary = {}):
	"""Start a simple 3D combat encounter"""
	if is_in_combat:
		print("CombatManager: Already in combat")
		return false
	
	print("CombatManager: Starting 3D combat")
	is_in_combat = true
	combat_data = combat_setup
	
	# Create the 3D combat scene
	_create_combat_scene()
	
	return true

func initialize_combat(combat_setup: Dictionary):
	"""Initialize combat with full setup data"""
	if is_in_combat:
		print("CombatManager: Combat already active")
		return false
	
	print("CombatManager: Initializing combat with setup data")
	combat_data = combat_setup
	is_in_combat = true
	
	# Create combat scene with setup data
	_create_combat_scene()
	_setup_combat_participants()
	_setup_combat_terrain()
	
	return true

func _create_combat_scene():
	"""Create the 3D combat scene"""
	if current_combat_scene:
		print("CombatManager: Combat scene already exists")
		return
	
	# Create the combat scene
	current_combat_scene = CombatScene.new()
	current_combat_scene.name = "CombatScene_" + str(Time.get_unix_time_from_system())
	
	# Connect signals
	current_combat_scene.combat_finished.connect(_on_combat_scene_finished)
	
	# Add to combat container (SceneManager handles this)
	if scene_manager:
		var combat_container = scene_manager.get_combat_container()
		if combat_container:
			combat_container.add_child(current_combat_scene)
			print("CombatManager: Combat scene added to combat container")
	else:
		# Fallback if scene manager not available
		add_child(current_combat_scene)
		print("CombatManager: Combat scene added as child (fallback)")

func _setup_combat_participants():
	"""Setup combat participants based on combat data"""
	if not current_combat_scene or not combat_data.has("combat_participants"):
		return
	
	var participants = combat_data.combat_participants
	print("CombatManager: Setting up ", participants.size(), " combat participants")
	
	# Add player character representation
	if combat_data.has("player_character"):
		_add_player_to_scene(combat_data.player_character)
	
	# Add enemies
	for enemy_data in participants:
		_add_enemy_to_scene(enemy_data)

func _setup_combat_terrain():
	"""Setup terrain based on combat data"""
	if not current_combat_scene or not combat_data.has("terrain"):
		return
	
	var terrain_type = combat_data.terrain
	print("CombatManager: Setting up terrain: ", terrain_type)
	
	# Customize the combat scene based on terrain
	match terrain_type:
		"forest":
			_setup_forest_terrain()
		"plains":
			_setup_plains_terrain()
		"mountain":
			_setup_mountain_terrain()
		_:
			print("CombatManager: Unknown terrain type, using default")

# ═══════════════════════════════════════════════════════════
# COMBAT PARTICIPANTS SETUP
# ═══════════════════════════════════════════════════════════

func _add_player_to_scene(character_data):
	"""Add player character to combat scene"""
	if not current_combat_scene:
		return
	
	# Create a simple player representation
	var player_node = MeshInstance3D.new()
	player_node.name = "Player"
	
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.height = 2.0
	capsule_mesh.top_radius = 0.5
	capsule_mesh.bottom_radius = 0.5
	player_node.mesh = capsule_mesh
	
	# Player material (blue)
	var player_material = StandardMaterial3D.new()
	player_material.albedo_color = Color(0.2, 0.4, 0.8)
	player_node.material_override = player_material
	
	# Position player
	player_node.position = Vector3(-3, 1, 0)
	
	current_combat_scene.add_child(player_node)
	print("CombatManager: Added player to combat scene")

func _add_enemy_to_scene(enemy_data):
	"""Add enemy to combat scene"""
	if not current_combat_scene:
		return
	
	# Create enemy representation
	var enemy_node = MeshInstance3D.new()
	enemy_node.name = "Enemy_" + str(enemy_data)
	
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(1.5, 1.5, 1.5)
	enemy_node.mesh = cube_mesh
	
	# Enemy material (red)
	var enemy_material = StandardMaterial3D.new()
	enemy_material.albedo_color = Color(0.8, 0.2, 0.2)
	enemy_node.material_override = enemy_material
	
	# Position enemy randomly
	var random_pos = Vector3(
		randf_range(2, 5),
		0.75,
		randf_range(-2, 2)
	)
	enemy_node.position = random_pos
	
	current_combat_scene.add_child(enemy_node)
	print("CombatManager: Added enemy to combat scene")

# ═══════════════════════════════════════════════════════════
# TERRAIN SETUP
# ═══════════════════════════════════════════════════════════

func _setup_forest_terrain():
	"""Setup forest terrain"""
	if not current_combat_scene:
		return
	
	# Change ground color to forest green
	var ground = current_combat_scene.get_node_or_null("Ground")
	if ground and ground is MeshInstance3D:
		var forest_material = StandardMaterial3D.new()
		forest_material.albedo_color = Color(0.2, 0.4, 0.2)
		ground.material_override = forest_material
	
	# Add some "trees" (cylinders)
	for i in range(5):
		var tree = MeshInstance3D.new()
		tree.name = "Tree_" + str(i)
		
		var cylinder_mesh = CylinderMesh.new()
		cylinder_mesh.height = 4.0
		cylinder_mesh.top_radius = 0.3
		cylinder_mesh.bottom_radius = 0.3
		tree.mesh = cylinder_mesh
		
		var tree_material = StandardMaterial3D.new()
		tree_material.albedo_color = Color(0.4, 0.2, 0.1)  # Brown
		tree.material_override = tree_material
		
		tree.position = Vector3(
			randf_range(-8, 8),
			2.0,
			randf_range(-8, 8)
		)
		
		current_combat_scene.add_child(tree)

func _setup_plains_terrain():
	"""Setup plains terrain (default)"""
	# Plains is the default terrain in CombatScene
	print("CombatManager: Using default plains terrain")

func _setup_mountain_terrain():
	"""Setup mountain terrain"""
	if not current_combat_scene:
		return
	
	# Change ground color to rocky gray
	var ground = current_combat_scene.get_node_or_null("Ground")
	if ground and ground is MeshInstance3D:
		var mountain_material = StandardMaterial3D.new()
		mountain_material.albedo_color = Color(0.4, 0.4, 0.4)
		ground.material_override = mountain_material
	
	# Add some "rocks" (irregular boxes)
	for i in range(3):
		var rock = MeshInstance3D.new()
		rock.name = "Rock_" + str(i)
		
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(
			randf_range(1, 3),
			randf_range(1, 2),
			randf_range(1, 3)
		)
		rock.mesh = box_mesh
		
		var rock_material = StandardMaterial3D.new()
		rock_material.albedo_color = Color(0.3, 0.3, 0.3)
		rock.material_override = rock_material
		
		rock.position = Vector3(
			randf_range(-6, 6),
			0.5,
			randf_range(-6, 6)
		)
		
		current_combat_scene.add_child(rock)

# ═══════════════════════════════════════════════════════════
# COMBAT FLOW MANAGEMENT
# ═══════════════════════════════════════════════════════════

func _on_combat_scene_finished():
	"""Handle combat scene finishing"""
	print("CombatManager: Combat scene finished")
	
	# Prepare combat results
	_prepare_combat_results()
	
	# Clean up combat scene
	cleanup_combat()
	
	# Emit finished signal with results
	combat_scene_finished.emit(combat_results)

func _prepare_combat_results():
	"""Prepare results from combat"""
	combat_results = {
		"victory": true,  # For now, always victory
		"resources_gained": {
			"gold": randi_range(10, 50),
			"experience": randi_range(25, 100)
		},
		"experience_gained": randi_range(25, 100),
		"character_state": {
			"health": game_manager.character.current_health if game_manager.character else 100,
			"action_points": game_manager.character.current_action_points if game_manager.character else 3
		},
		"combat_duration": Time.get_unix_time_from_system(),
		"terrain": combat_data.get("terrain", "unknown")
	}
	
	print("CombatManager: Combat results prepared")

func cleanup_combat():
	"""Clean up combat state and scene"""
	print("CombatManager: Cleaning up combat")
	
	# Remove combat scene
	if current_combat_scene:
		current_combat_scene.queue_free()
		current_combat_scene = null
	
	# Reset state
	is_in_combat = false
	combat_data.clear()
	combat_results.clear()

# ═══════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════

func is_combat_active() -> bool:
	"""Check if combat is currently active"""
	return is_in_combat

func get_current_combat_scene() -> CombatScene:
	"""Get the current combat scene"""
	return current_combat_scene

func get_combat_data() -> Dictionary:
	"""Get current combat setup data"""
	return combat_data.duplicate()

func can_start_combat() -> bool:
	"""Check if combat can be started"""
	return not is_in_combat and scene_manager != null

func force_end_combat():
	"""Force end combat (for debugging/emergency)"""
	if is_in_combat:
		_prepare_combat_results()
		cleanup_combat()
		combat_scene_finished.emit(combat_results)
