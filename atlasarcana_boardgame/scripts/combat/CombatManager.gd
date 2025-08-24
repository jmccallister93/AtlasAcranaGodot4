# Simple3DCombatManager.gd
extends Node
class_name CombatManager

signal combat_scene_finished()

# References
var game_manager: GameManager
var current_3d_scene: SimpleCombatScene3D
var expedition_camera: Camera3D
var map_manager_3d: MapManager3D

# Scene state
var is_in_combat: bool = false
var saved_expedition_camera_state: Dictionary = {}

func initialize(gm: GameManager):
	"""Initialize the combat manager"""
	game_manager = gm
	# Get reference to the 3D map manager
	map_manager_3d = game_manager.get_3d_map_manager()

func start_simple_combat():
	"""Start a simple 3D combat encounter"""
	if is_in_combat:
		return false
	
	is_in_combat = true
	
	# Save current camera state
	_save_3d_camera_state()
	
	# Create and add 3D combat scene
	current_3d_scene = SimpleCombatScene3D.new()
	current_3d_scene.name = "SimpleCombatScene3D"
	get_tree().current_scene.add_child(current_3d_scene)
	
	# Connect combat finished signal
	current_3d_scene.combat_finished.connect(_on_combat_finished)
	
	# Disable expedition systems and hide map
	disable_expedition_systems()
	
	return true

func _save_3d_camera_state():
	"""Save the current 3D camera state"""
	var cameras_2d = get_tree().get_nodes_in_group("Camera3D")
	for camera in cameras_2d:
		if camera.is_current():
			expedition_camera = camera
			saved_expedition_camera_state = {
				"position": camera.global_position,
				"zoom": camera.zoom,
				"enabled": camera.enabled
			}
			break

func disable_expedition_systems():
	"""Disable expedition camera, UI, and hide the map during combat"""
	# Disable expedition 3D camera
	if expedition_camera:
		expedition_camera.enabled = false
		expedition_camera.current = false
		print("CombatManager: Expedition camera disabled")
	
	# Hide the 3D map
	hide_expedition_map()
	
	# Hide expedition UI (keep it in the tree but hide it)
	var game_ui = get_tree().get_first_node_in_group("game_ui")
	if game_ui:
		game_ui.visible = false

func hide_expedition_map():
	"""Hide the expedition map during combat"""
	if map_manager_3d:
		# Method 1: Make the entire map invisible
		map_manager_3d.visible = false
	else:
		pass

func _on_combat_finished():
	"""Handle combat scene finishing"""
	restore_expedition_systems()
	cleanup_3d_scene()
	is_in_combat = false
	combat_scene_finished.emit()

func restore_expedition_systems():
	"""Restore expedition camera, UI, and map after combat"""
	# Show the expedition map first
	show_expedition_map()
	
	# Restore expedition camera
	if expedition_camera and saved_expedition_camera_state.size() > 0:
		expedition_camera.global_position = saved_expedition_camera_state.position
		expedition_camera.enabled = saved_expedition_camera_state.get("enabled", true)
		expedition_camera.current = saved_expedition_camera_state.get("current", true)
		
		# Restore target position if available
		if expedition_camera.has_method("set_target_position"):
			var target_pos = saved_expedition_camera_state.get("target_position", Vector3.ZERO)
			expedition_camera.call("set_target_position", target_pos)
		
	
	# Restore expedition UI
	var game_ui = get_tree().get_first_node_in_group("game_ui")
	if game_ui:
		game_ui.visible = true

func show_expedition_map():
	"""Show the expedition map after combat"""
	if map_manager_3d:
		# Restore visibility
		map_manager_3d.visible = true
	else:
		pass

func cleanup_3d_scene():
	"""Clean up the 3D combat scene"""
	if current_3d_scene:
		current_3d_scene.cleanup()
		current_3d_scene.queue_free()  # Use queue_free() instead of just setting to null
		current_3d_scene = null
	print("CombatManager: Combat scene cleaned up")

func is_combat_active() -> bool:
	"""Check if combat is currently active"""
	return is_in_combat

func get_current_scene() -> SimpleCombatScene3D:
	"""Get the current combat scene"""
	return current_3d_scene
