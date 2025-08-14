# SceneManager.gd - Handles scene transitions for combat
extends Node
class_name SceneManager

signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_completed(scene_name: String)

# Scene paths
const OVERWORLD_SCENE = "res://scenes/OverworldScene.tscn"
const COMBAT_SCENE = "res://scenes/CombatScene.tscn"

# Current scene tracking
var current_scene_name: String = "overworld"
var previous_scene_name: String = ""
var is_transitioning: bool = false

# Reference to game manager for state preservation
var game_manager: GameManager

func initialize(gm: GameManager):
	"""Initialize the scene manager with game manager reference"""
	game_manager = gm
	print("SceneManager: Initialized")

# ═══════════════════════════════════════════════════════════
# COMBAT SCENE TRANSITIONS
# ═══════════════════════════════════════════════════════════

func start_combat_scene(combat_data: Dictionary = {}):
	"""Transition to combat scene"""
	if is_transitioning:
		print("SceneManager: Already transitioning, ignoring request")
		return
	
	print("SceneManager: Starting combat scene transition...")
	is_transitioning = true
	previous_scene_name = current_scene_name
	
	# Save current game state before transition
	_save_overworld_state()
	
	# Emit signal for any listeners
	scene_transition_started.emit(current_scene_name, "combat")
	
	# Load combat scene
	_load_combat_scene(combat_data)

func return_to_overworld(combat_results: Dictionary = {}):
	"""Return to overworld scene after combat"""
	if is_transitioning:
		print("SceneManager: Already transitioning, ignoring request")
		return
	
	print("SceneManager: Returning to overworld...")
	is_transitioning = true
	
	# Process combat results
	_process_combat_results(combat_results)
	
	# Emit signal
	scene_transition_started.emit("combat", "overworld")
	
	# Load overworld scene
	_load_overworld_scene()

# ═══════════════════════════════════════════════════════════
# PRIVATE SCENE LOADING
# ═══════════════════════════════════════════════════════════

func _load_combat_scene(combat_data: Dictionary):
	"""Load the combat scene with transition"""
	# Create loading screen or fade effect here if desired
	_show_transition_effect()
	
	# Change to combat scene
	var scene_load_result = get_tree().change_scene_to_file(COMBAT_SCENE)
	
	if scene_load_result == OK:
		current_scene_name = "combat"
		
		# Wait a frame for scene to load, then setup combat
		await get_tree().process_frame
		_setup_combat_scene(combat_data)
		
		scene_transition_completed.emit("combat")
		is_transitioning = false
		print("SceneManager: Combat scene loaded successfully")
	else:
		print("SceneManager: Failed to load combat scene")
		is_transitioning = false

func _load_overworld_scene():
	"""Load the overworld scene"""
	_show_transition_effect()
	
	var scene_load_result = get_tree().change_scene_to_file(OVERWORLD_SCENE)
	
	if scene_load_result == OK:
		current_scene_name = "overworld"
		
		# Wait a frame for scene to load, then restore state
		await get_tree().process_frame
		_restore_overworld_state()
		
		scene_transition_completed.emit("overworld")
		is_transitioning = false
		print("SceneManager: Overworld scene loaded successfully")
	else:
		print("SceneManager: Failed to load overworld scene")
		is_transitioning = false

# ═══════════════════════════════════════════════════════════
# SCENE SETUP & STATE MANAGEMENT
# ═══════════════════════════════════════════════════════════

func _setup_combat_scene(combat_data: Dictionary):
	"""Setup the combat scene with data from overworld"""
	var combat_manager = get_tree().current_scene.get_node_or_null("CombatManager")
	if combat_manager and combat_manager.has_method("initialize_combat"):
		# Pass relevant data to combat scene
		var combat_setup = {
			"player_character": game_manager.character,
			"player_resources": game_manager.get_all_resources(),
			"combat_participants": combat_data.get("enemies", []),
			"terrain": combat_data.get("terrain", "plains"),
			"initial_positions": combat_data.get("positions", {}),
			"combat_type": combat_data.get("type", "encounter")
		}
		
		combat_manager.initialize_combat(combat_setup)
		
		# Connect combat end signal
		if combat_manager.has_signal("combat_finished"):
			combat_manager.combat_finished.connect(_on_combat_finished)
	else:
		print("SceneManager: Warning - Combat scene doesn't have proper CombatManager")

func _save_overworld_state():
	"""Save overworld state before combat"""
	# The game manager already handles most state, but we might want to save
	# specific overworld data like player position, current action mode, etc.
	var overworld_data = {
		"player_position": _get_player_overworld_position(),
		"current_turn": game_manager.get_current_turn(),
		"action_mode": game_manager.get_current_action_mode(),
		"ui_state": _get_ui_state()
	}
	
	# Store in game state or a separate overworld state manager
	game_manager.game_state.set_data("overworld_state", overworld_data)
	print("SceneManager: Overworld state saved")

func _restore_overworld_state():
	"""Restore overworld state after combat"""
	var overworld_data = game_manager.game_state.get_data("overworld_state", {})
	
	if overworld_data.has("player_position"):
		_restore_player_overworld_position(overworld_data.player_position)
	
	if overworld_data.has("action_mode"):
		# Restore previous action mode if it wasn't NONE
		var action_mode = overworld_data.action_mode
		if action_mode != game_manager.action_controller.ActionMode.NONE:
			_restore_action_mode(action_mode)
	
	if overworld_data.has("ui_state"):
		_restore_ui_state(overworld_data.ui_state)
	
	print("SceneManager: Overworld state restored")

func _process_combat_results(results: Dictionary):
	"""Process results from combat and update game state"""
	print("SceneManager: Processing combat results...")
	
	# Apply experience/resource gains
	if results.has("resources_gained"):
		for resource in results.resources_gained:
			game_manager.add_resource(resource, results.resources_gained[resource])
	
	# Apply experience to character
	if results.has("experience_gained"):
		var character = game_manager.character
		if character and character.has_method("gain_experience"):
			character.gain_experience(results.experience_gained)
	
	# Handle any character state changes (health, status effects, etc.)
	if results.has("character_state"):
		_apply_character_state_changes(results.character_state)
	
	# Handle any story/quest progression
	if results.has("story_events"):
		_process_story_events(results.story_events)

# ═══════════════════════════════════════════════════════════
# SIGNAL HANDLERS
# ═══════════════════════════════════════════════════════════

func _on_combat_finished(combat_results: Dictionary):
	"""Handle combat finished signal from combat scene"""
	print("SceneManager: Combat finished, returning to overworld")
	return_to_overworld(combat_results)

# ═══════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════

func _show_transition_effect():
	"""Show loading/transition effect"""
	# You could implement a fade effect, loading screen, etc.
	# For now, just a simple print
	print("SceneManager: Transitioning...")

func _get_player_overworld_position() -> Vector2:
	"""Get player position in overworld"""
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player:
		return player.global_position
	return Vector2.ZERO

func _restore_player_overworld_position(position: Vector2):
	"""Restore player position in overworld"""
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player:
		player.global_position = position

func _get_ui_state() -> Dictionary:
	"""Get current UI state"""
	# This would depend on your UI implementation
	return {"placeholder": "ui_state"}

func _restore_ui_state(ui_state: Dictionary):
	"""Restore UI state"""
	# Restore UI panels, windows, etc.
	pass

func _restore_action_mode(action_mode):
	"""Restore the previous action mode"""
	match action_mode:
		game_manager.action_controller.ActionMode.MOVEMENT:
			game_manager.start_movement_mode()
		game_manager.action_controller.ActionMode.BUILD:
			game_manager.start_build_mode()
		game_manager.action_controller.ActionMode.ATTACK:
			game_manager.start_attack_mode()
		game_manager.action_controller.ActionMode.INTERACT:
			game_manager.start_interact_mode()

func _apply_character_state_changes(character_state: Dictionary):
	"""Apply changes to character state from combat"""
	var character = game_manager.character
	if character:
		if character_state.has("health"):
			character.current_health = character_state.health
		if character_state.has("action_points"):
			character.current_action_points = character_state.action_points
		# Add other character state properties as needed

func _process_story_events(story_events: Array):
	"""Process any story events triggered by combat"""
	for event in story_events:
		print("SceneManager: Processing story event: ", event)
		# Trigger quest updates, story progression, etc.
		game_manager.event_bus.emit_signal("story_event_triggered", event)

# ═══════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════

func get_current_scene_name() -> String:
	"""Get the current scene name"""
	return current_scene_name

func is_in_combat() -> bool:
	"""Check if currently in combat scene"""
	return current_scene_name == "combat"

func is_in_overworld() -> bool:
	"""Check if currently in overworld scene"""
	return current_scene_name == "overworld"
