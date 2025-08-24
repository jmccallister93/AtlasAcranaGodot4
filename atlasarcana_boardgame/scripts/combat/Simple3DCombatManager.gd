# ═══════════════════════════════════════════════════════════
# SIMPLE 3D COMBAT MANAGER
# ═══════════════════════════════════════════════════════════

# Simple3DCombatManager.gd - Create this as a new script
extends Node
class_name Simple3DCombatManager

signal combat_scene_finished()

# References
var game_manager: GameManager
var current_3d_scene: SimpleCombatScene3D
var original_camera: Camera2D

# Scene state
var is_in_combat: bool = false
var saved_2d_camera_state: Dictionary = {}

func initialize(gm: GameManager):
	"""Initialize the combat manager"""
	game_manager = gm
	print("Simple3DCombatManager: Initialized")

func start_simple_combat():
	"""Start a simple 3D combat encounter"""
	if is_in_combat:
		print("Simple3DCombatManager: Already in combat")
		return false
	
	print("Simple3DCombatManager: Starting 3D combat")
	is_in_combat = true
	
	# Save current 2D camera state
	_save_2d_camera_state()
	
	# Create and add 3D combat scene
	current_3d_scene = SimpleCombatScene3D.new()
	current_3d_scene.name = "SimpleCombatScene3D"
	get_tree().current_scene.add_child(current_3d_scene)
	
	# Connect combat finished signal
	current_3d_scene.combat_finished.connect(_on_combat_finished)
	
	# Disable 2D UI and camera
	_disable_2d_systems()
	
	return true

func _save_2d_camera_state():
	"""Save the current 2D camera state"""
	var cameras_2d = get_tree().get_nodes_in_group("Camera2D")
	for camera in cameras_2d:
		if camera.is_current():
			original_camera = camera
			saved_2d_camera_state = {
				"position": camera.global_position,
				"zoom": camera.zoom,
				"enabled": camera.enabled
			}
			print("Simple3DCombatManager: Saved 2D camera state")
			break

func _disable_2d_systems():
	"""Disable 2D camera and UI during combat"""
	# Disable 2D camera
	if original_camera:
		original_camera.enabled = false
		original_camera.current = false
	
	# Hide 2D UI (keep it in the tree but hide it)
	var game_ui = get_tree().get_first_node_in_group("game_ui")
	if game_ui:
		game_ui.visible = false
	
	print("Simple3DCombatManager: 2D systems disabled")

func _on_combat_finished():
	"""Handle combat scene finishing"""
	print("Simple3DCombatManager: Combat finished")
	_restore_2d_systems()
	_cleanup_3d_scene()
	is_in_combat = false
	combat_scene_finished.emit()

func _restore_2d_systems():
	"""Restore 2D camera and UI after combat"""
	# Restore 2D camera
	if original_camera and saved_2d_camera_state.has("enabled"):
		original_camera.global_position = saved_2d_camera_state.position
		original_camera.zoom = saved_2d_camera_state.zoom
		original_camera.enabled = saved_2d_camera_state.enabled
		original_camera.current = true
		print("Simple3DCombatManager: 2D camera restored")
	
	# Restore 2D UI
	var game_ui = get_tree().get_first_node_in_group("game_ui")
	if game_ui:
		game_ui.visible = true
	
	print("Simple3DCombatManager: 2D systems restored")

func _cleanup_3d_scene():
	"""Clean up the 3D combat scene"""
	if current_3d_scene:
		current_3d_scene.cleanup()
		current_3d_scene = null
	print("Simple3DCombatManager: 3D scene cleaned up")

func is_combat_active() -> bool:
	"""Check if combat is currently active"""
	return is_in_combat

func get_current_scene() -> SimpleCombatScene3D:
	"""Get the current combat scene"""
	return current_3d_scene
