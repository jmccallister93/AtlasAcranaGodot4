# GameEventBus.gd
extends Node
class_name GameEventBus

# ═══════════════════════════════════════════════════════════
# CENTRAL GAME EVENTS
# ═══════════════════════════════════════════════════════════

# Turn events
signal turn_advanced(turn_number: int)
signal initial_turn(turn_number: int)

# Action point events
signal action_points_spent(current_action_points: int)
signal action_points_refreshed(current_action_points: int)

# Resource events
signal resource_changed(resource_name: String, new_amount: int)
signal resources_spent(spent_resources: Dictionary)
signal insufficient_resources(required: Dictionary, available: Dictionary)

# Action completion events
signal movement_completed(new_pos: Vector2i)
signal movement_failed(reason: String)
signal building_completed(new_building: Building, tile: BiomeTile)
signal building_failed(reason: String)
signal interaction_completed(character: Character, entity: InteractableEntity, result: Dictionary)
signal interaction_failed(reason: String)
signal attack_completed(character: Character, enemy: Enemy, result: Dictionary)
signal attack_failed(reason: String)
signal enemy_died(enemy: Enemy)

# Confirmation request events
signal movement_confirmation_requested(target_tile: BiomeTile)
signal build_confirmation_requested(target_tile: BiomeTile, building_type: String)
signal interact_confirmation_requested(target_tile: BiomeTile, entity: InteractableEntity)
signal attack_confirmation_requested(target_tile: BiomeTile, enemy: Enemy)

# Map events
signal movement_requested(target_grid_pos: Vector2i)

# Building events
signal building_data_changed()

# Warband events
signal member_added()
signal member_removed()
signal member_status_changed()

# UI Events
signal ui_error_message(message: String)
signal ui_success_message(message: String)
signal ui_info_message(message: String)

var managers: ManagerRegistry
var action_controller: ActionModeController
var ui_bridge: UIBridge

func initialize(manager_registry: ManagerRegistry, action_mode_controller: ActionModeController, ui_bridge_ref: UIBridge):
	"""Initialize the event bus with all necessary components"""
	managers = manager_registry
	action_controller = action_mode_controller
	ui_bridge = ui_bridge_ref
	
	# Wait for managers to be initialized before connecting signals
	if managers.are_all_managers_initialized():
		_connect_all_signals()
	else:
		managers.managers_initialized.connect(_connect_all_signals)

# ═══════════════════════════════════════════════════════════
# SIGNAL CONNECTION MANAGEMENT
# ═══════════════════════════════════════════════════════════

func _connect_all_signals():
	"""Connect all signals from managers to event bus and route to appropriate handlers"""
	print("GameEventBus: Connecting all signals...")
	
	_connect_turn_signals()
	_connect_character_signals()
	_connect_map_signals()
	_connect_movement_signals()
	_connect_build_signals()
	_connect_interact_signals()
	_connect_attack_signals()
	_connect_resource_signals()
	_connect_warband_signals()
	_connect_action_controller_signals()
	
	print("GameEventBus: All signals connected successfully")

func _connect_turn_signals():
	"""Connect turn manager signals"""
	if managers.turn_manager:
		managers.turn_manager.initial_turn.connect(_on_initial_turn)
		managers.turn_manager.turn_advanced.connect(_on_turn_advanced)

func _connect_character_signals():
	"""Connect character signals"""
	if managers.character:
		managers.character.action_points_spent.connect(_on_action_points_spent)
		managers.character.action_points_refreshed.connect(_on_action_points_refreshed)

func _connect_map_signals():
	"""Connect map manager signals"""
	if managers.map_manager:
		managers.map_manager.movement_requested.connect(_on_movement_requested)

func _connect_movement_signals():
	"""Connect movement manager signals"""
	if managers.movement_manager:
		managers.movement_manager.movement_completed.connect(_on_movement_completed)
		managers.movement_manager.movement_failed.connect(_on_movement_failed)
		managers.movement_manager.movement_confirmation_requested.connect(_on_movement_confirmation_requested)

func _connect_build_signals():
	"""Connect build manager signals"""
	if managers.build_manager:
		managers.build_manager.building_completed.connect(_on_building_completed)
		managers.build_manager.building_failed.connect(_on_building_failed)
		managers.build_manager.build_confirmation_requested.connect(_on_build_confirmation_requested)
		managers.build_manager.building_data_changed.connect(_on_building_data_changed)

func _connect_interact_signals():
	"""Connect interact manager signals"""
	if managers.interact_manager:
		managers.interact_manager.interaction_completed.connect(_on_interaction_completed)
		managers.interact_manager.interaction_failed.connect(_on_interaction_failed)
		managers.interact_manager.interact_confirmation_requested.connect(_on_interact_confirmation_requested)

func _connect_attack_signals():
	"""Connect attack manager signals"""
	if managers.attack_manager:
		managers.attack_manager.attack_completed.connect(_on_attack_completed)
		managers.attack_manager.attack_failed.connect(_on_attack_failed)
		managers.attack_manager.attack_confirmation_requested.connect(_on_attack_confirmation_requested)
		managers.attack_manager.enemy_died.connect(_on_enemy_died)

func _connect_resource_signals():
	"""Connect resource manager signals"""
	if managers.resource_manager:
		managers.resource_manager.resource_changed.connect(_on_resource_changed)
		managers.resource_manager.resources_spent.connect(_on_resources_spent)
		managers.resource_manager.insufficient_resources.connect(_on_insufficient_resources)

func _connect_warband_signals():
	"""Connect warband manager signals"""
	if managers.warband_manager:
		managers.warband_manager.member_added.connect(_on_warband_member_added)
		managers.warband_manager.member_removed.connect(_on_warband_member_removed)
		managers.warband_manager.member_status_changed.connect(_on_warband_member_status_changed)

func _connect_action_controller_signals():
	"""Connect action controller signals"""
	if action_controller:
		turn_advanced.connect(action_controller._on_turn_advanced)

# ═══════════════════════════════════════════════════════════
# EVENT HANDLERS - TURN SYSTEM
# ═══════════════════════════════════════════════════════════

func _on_initial_turn(turn_number: int):
	"""Handle initial turn signal"""
	initial_turn.emit(turn_number)

func _on_turn_advanced(turn_number: int):
	"""Handle turn advanced signal"""
	turn_advanced.emit(turn_number)
	
	# Apply turn-based updates
	if managers.character:
		managers.character.refresh_turn_resources()
	if managers.resource_manager:
		managers.resource_manager.apply_turn_income()

func _on_action_points_spent(current_action_points: int):
	"""Handle action points spent signal"""
	action_points_spent.emit(current_action_points)

func _on_action_points_refreshed(current_action_points: int):
	"""Handle action points refreshed signal"""
	action_points_refreshed.emit(current_action_points)

# ═══════════════════════════════════════════════════════════
# EVENT HANDLERS - MAP INTERACTIONS
# ═══════════════════════════════════════════════════════════

func _on_movement_requested(target_grid_pos: Vector2i):
	"""Handle movement request from map - route to action controller"""
	if action_controller:
		action_controller.handle_map_click(target_grid_pos)

# ═══════════════════════════════════════════════════════════
# EVENT HANDLERS - MOVEMENT
# ═══════════════════════════════════════════════════════════

func _on_movement_completed(new_pos: Vector2i):
	"""Handle movement completion"""
	movement_completed.emit(new_pos)
	if action_controller:
		action_controller.on_action_completed(ActionModeController.ActionMode.MOVEMENT)

func _on_movement_failed(reason: String):
	"""Handle movement failure"""
	movement_failed.emit(reason)
	if ui_bridge:
		ui_bridge.show_error("Movement failed: " + reason)

func _on_movement_confirmation_requested(target_tile: BiomeTile):
	"""Handle movement confirmation request"""
	movement_confirmation_requested.emit(target_tile)
	if ui_bridge:
		ui_bridge.show_movement_confirmation(target_tile)

# ═══════════════════════════════════════════════════════════
# EVENT HANDLERS - BUILDING
# ═══════════════════════════════════════════════════════════

func _on_building_completed(new_building: Building, tile: BiomeTile):
	"""Handle building completion"""
	building_completed.emit(new_building, tile)
	if action_controller:
		action_controller.on_action_completed(ActionModeController.ActionMode.BUILD)

func _on_building_failed(reason: String):
	"""Handle building failure"""
	building_failed.emit(reason)
	if ui_bridge:
		ui_bridge.show_error("Building failed: " + reason)

func _on_build_confirmation_requested(target_tile: BiomeTile, building_type: String):
	"""Handle build confirmation request"""
	build_confirmation_requested.emit(target_tile, building_type)
	if ui_bridge:
		ui_bridge.show_build_confirmation(target_tile, building_type)

func _on_building_data_changed():
	"""Handle building data changes"""
	building_data_changed.emit()
	if ui_bridge:
		ui_bridge.on_building_data_changed()

# ═══════════════════════════════════════════════════════════
# EVENT HANDLERS - INTERACTIONS
# ═══════════════════════════════════════════════════════════

func _on_interaction_completed(character: Character, entity: InteractableEntity, result: Dictionary):
	"""Handle interaction completion"""
	interaction_completed.emit(character, entity, result)
	
	# Show success message if available
	if result.has("message") and ui_bridge:
		ui_bridge.show_success(result.message)
	
	if action_controller:
		action_controller.on_action_completed(ActionModeController.ActionMode.INTERACT)

func _on_interaction_failed(reason: String):
	"""Handle interaction failure"""
	interaction_failed.emit(reason)
	if ui_bridge:
		ui_bridge.show_error("Interaction failed: " + reason)

func _on_interact_confirmation_requested(target_tile: BiomeTile, entity: InteractableEntity):
	"""Handle interact confirmation request"""
	interact_confirmation_requested.emit(target_tile, entity)
	if ui_bridge:
		ui_bridge.show_interact_confirmation(target_tile, entity.interaction_name)

# ═══════════════════════════════════════════════════════════
# EVENT HANDLERS - COMBAT
# ═══════════════════════════════════════════════════════════

func _on_attack_completed(character: Character, enemy: Enemy, result: Dictionary):
	"""Handle attack completion"""
	attack_completed.emit(character, enemy, result)
	
	# Show appropriate message based on result
	if ui_bridge:
		var damage = result.get("damage_dealt", 0)
		var enemy_died = result.get("enemy_died", false)
		
		if enemy_died:
			var exp_gained = result.get("experience", 0)
			ui_bridge.show_success("%s defeated! +%d EXP" % [enemy.enemy_name, exp_gained])
		else:
			ui_bridge.show_info("Hit %s for %d damage!" % [enemy.enemy_name, damage])
	
	if action_controller:
		action_controller.on_action_completed(ActionModeController.ActionMode.ATTACK)

func _on_attack_failed(reason: String):
	"""Handle attack failure"""
	attack_failed.emit(reason)
	if ui_bridge:
		ui_bridge.show_error("Attack failed: " + reason)

func _on_attack_confirmation_requested(target_tile: BiomeTile, enemy: Enemy):
	"""Handle attack confirmation request"""
	attack_confirmation_requested.emit(target_tile, enemy)
	if ui_bridge:
		ui_bridge.show_attack_confirmation(target_tile)

func _on_enemy_died(enemy: Enemy):
	"""Handle enemy death"""
	enemy_died.emit(enemy)

# ═══════════════════════════════════════════════════════════
# EVENT HANDLERS - RESOURCES
# ═══════════════════════════════════════════════════════════

func _on_resource_changed(resource_name: String, new_amount: int):
	"""Handle resource amount changes"""
	resource_changed.emit(resource_name, new_amount)
	if ui_bridge:
		ui_bridge.update_resource(resource_name, new_amount)

func _on_resources_spent(spent_resources: Dictionary):
	"""Handle resources being spent"""
	resources_spent.emit(spent_resources)

func _on_insufficient_resources(required: Dictionary, available: Dictionary):
	"""Handle insufficient resources"""
	insufficient_resources.emit(required, available)
	
	if ui_bridge:
		var message = "Not enough resources! Need: "
		for resource in required:
			var need = required[resource]
			var have = available.get(resource, 0)
			message += "%d %s (have %d), " % [need, resource, have]
		ui_bridge.show_error(message.trim_suffix(", "))

# ═══════════════════════════════════════════════════════════
# EVENT HANDLERS - WARBAND
# ═══════════════════════════════════════════════════════════

func _on_warband_member_added():
	"""Handle warband member added"""
	member_added.emit()

func _on_warband_member_removed():
	"""Handle warband member removed"""
	member_removed.emit()

func _on_warband_member_status_changed():
	"""Handle warband member status change"""
	member_status_changed.emit()

# ═══════════════════════════════════════════════════════════
# PUBLIC EVENT EMITTERS
# ═══════════════════════════════════════════════════════════

func emit_ui_error(message: String):
	"""Emit UI error message"""
	ui_error_message.emit(message)

func emit_ui_success(message: String):
	"""Emit UI success message"""
	ui_success_message.emit(message)

func emit_ui_info(message: String):
	"""Emit UI info message"""
	ui_info_message.emit(message)
