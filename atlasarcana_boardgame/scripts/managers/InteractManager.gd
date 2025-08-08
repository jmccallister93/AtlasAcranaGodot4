# InteractManager.gd
extends Node
class_name InteractManager

# Signals similar to other managers
signal interaction_attempted(character: Character, entity: InteractableEntity)
signal interaction_completed(character: Character, entity: InteractableEntity, result: Dictionary)
signal interaction_failed(reason: String)
signal interact_mode_started
signal interact_mode_ended
signal interact_confirmation_requested(target_tile: BiomeTile, entity: InteractableEntity)

# Interaction mode states
enum InteractState {
	INACTIVE,
	SELECTING_TARGET,
	AWAITING_CONFIRMATION
}

# References
var character: Character
var map_manager: MapManager
var current_state: InteractState = InteractState.INACTIVE
var highlighted_tiles: Array[BiomeTile] = []
var pending_target_position: Vector2i
var pending_interaction_entity: InteractableEntity

# Interactable entities storage
var entities_by_tile: Dictionary = {}  # Vector2i -> Array[InteractableEntity]
var all_entities: Array[InteractableEntity] = []

func initialize(char: Character, map: MapManager):
	"""Initialize the interact manager with character and map references"""
	character = char
	map_manager = map

func start_interact_mode():
	"""Start the interaction selection mode"""
	if current_state != InteractState.INACTIVE:
		return
		
	if character.current_action_points <= 0:
		interaction_failed.emit("No action points remaining")
		return
		
	current_state = InteractState.SELECTING_TARGET
	highlight_interactable_tiles()
	interact_mode_started.emit()
	print("Interact mode started")

func end_interact_mode():
	"""End the interaction selection mode"""
	current_state = InteractState.INACTIVE
	clear_highlighted_tiles()
	pending_target_position = Vector2i.ZERO
	pending_interaction_entity = null
	interact_mode_ended.emit()
	print("Interact mode ended")

func highlight_interactable_tiles():
	"""Highlight tiles adjacent to the character that have interactable entities"""
	clear_highlighted_tiles()
	
	var character_pos = character.grid_position
	
	# Get all 8 adjacent tiles (including diagonals)
	var adjacent_directions = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),  # Top row
		Vector2i(-1,  0),                  Vector2i(1,  0),  # Middle row (excluding center)
		Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1)   # Bottom row
	]
	
	for direction in adjacent_directions:
		var tile_pos = character_pos + direction
		var tile = map_manager.get_tile_at(tile_pos)
		
		if tile and has_interactable_entity(tile_pos):
			var entities = get_entities_at_position(tile_pos)
			# Only highlight if there's at least one entity the character can interact with
			var can_interact_with_any = false
			for entity in entities:
				if entity.can_interact(character):
					can_interact_with_any = true
					break
			
			if can_interact_with_any:
				tile.set_interact_highlighted(true)
				highlighted_tiles.append(tile)

func clear_highlighted_tiles():
	"""Clear all highlighted tiles"""
	for tile in highlighted_tiles:
		tile.set_interact_highlighted(false)
	highlighted_tiles.clear()

func has_interactable_entity(position: Vector2i) -> bool:
	"""Check if there's an interactable entity at the given position"""
	return position in entities_by_tile and entities_by_tile[position].size() > 0

func get_entities_at_position(position: Vector2i) -> Array[InteractableEntity]:
	"""Get all interactable entities at the given position"""
	var entities = entities_by_tile.get(position, [])
	var result: Array[InteractableEntity] = []
	result.assign(entities)
	return result

func is_tile_highlighted(target_pos: Vector2i) -> bool:
	"""Check if a tile is currently highlighted for interaction"""
	for tile in highlighted_tiles:
		if tile.grid_position == target_pos:
			return true
	return false

func attempt_interact_at(target_pos: Vector2i):
	"""Attempt to interact at target position - requests confirmation first"""
	print("Attempting to interact at: ", target_pos)
	
	# Only allow interaction if in selecting mode and tile is highlighted
	if current_state != InteractState.SELECTING_TARGET:
		print("Not in interact selection mode")
		return
		
	if not is_tile_highlighted(target_pos):
		print("Target tile is not highlighted/interactable")
		interaction_failed.emit("No interactable entities at this location")
		return
	
	# Check if character has action points
	if character.current_action_points <= 0:
		print("No action points remaining")
		interaction_failed.emit("No action points remaining")
		end_interact_mode()
		return
	
	# Get the first interactable entity at this position
	var entities = get_entities_at_position(target_pos)
	var target_entity = null
	
	for entity in entities:
		if entity.can_interact(character):
			target_entity = entity
			break
	
	if not target_entity:
		interaction_failed.emit("No valid interactable entities at this location")
		return
	
	# Store the target and request confirmation
	pending_target_position = target_pos
	pending_interaction_entity = target_entity
	current_state = InteractState.AWAITING_CONFIRMATION
	
	var target_tile = map_manager.get_tile_at(target_pos)
	if target_tile:
		interact_confirmation_requested.emit(target_tile, target_entity)
	else:
		interaction_failed.emit("Invalid target tile")
		end_interact_mode()

func confirm_interaction():
	"""Execute the confirmed interaction"""
	if current_state != InteractState.AWAITING_CONFIRMATION:
		print("No interaction awaiting confirmation")
		return
		
	var target_entity = pending_interaction_entity
	
	# Final validation
	if character.current_action_points <= 0:
		interaction_failed.emit("No action points remaining")
		end_interact_mode()
		return
	
	if not target_entity or not target_entity.can_interact(character):
		interaction_failed.emit("Cannot interact with target entity")
		end_interact_mode()
		return
	
	# Emit attempt signal
	interaction_attempted.emit(character, target_entity)
	
	# Perform the interaction
	var result = target_entity.interact(character)
	
	if result.get("success", false):
		# Spend action point
		character.spend_action_points()
		
		# End interact mode
		end_interact_mode()
		
		# Emit completion signal
		interaction_completed.emit(character, target_entity, result)
		print("Interaction completed: ", result.get("message", "Success"))
	else:
		interaction_failed.emit(result.get("message", "Interaction failed"))
		end_interact_mode()

func cancel_interaction():
	"""Cancel the pending interaction and return to selection mode"""
	if current_state == InteractState.AWAITING_CONFIRMATION:
		current_state = InteractState.SELECTING_TARGET
		pending_target_position = Vector2i.ZERO
		pending_interaction_entity = null
		print("Interaction cancelled, returning to selection mode")

# Entity management methods
func add_entity(entity: InteractableEntity, position: Vector2i):
	"""Add an interactable entity to the world"""
	entity.set_grid_position(position, map_manager.tile_size)
	
	# Add to tile lookup
	if position not in entities_by_tile:
		entities_by_tile[position] = []
	entities_by_tile[position].append(entity)
	
	# Add to global list
	all_entities.append(entity)
	
	# Add to scene tree via map manager
	map_manager.add_child(entity)
	
	print("Added interactable entity: ", entity.entity_type, " at ", position)

func remove_entity(entity: InteractableEntity):
	"""Remove an interactable entity from the world"""
	var position = entity.grid_position
	
	# Remove from tile lookup
	if position in entities_by_tile:
		entities_by_tile[position].erase(entity)
		if entities_by_tile[position].is_empty():
			entities_by_tile.erase(position)
	
	# Remove from global list
	all_entities.erase(entity)
	
	# Remove from scene tree
	entity.queue_free()
	
	print("Removed interactable entity: ", entity.entity_type, " at ", position)

func get_adjacent_positions(center_pos: Vector2i) -> Array[Vector2i]:
	"""Get all adjacent positions around a center position"""
	var adjacent_positions: Array[Vector2i] = []
	var directions = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1,  0),                  Vector2i(1,  0),
		Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1)
	]
	
	for direction in directions:
		adjacent_positions.append(center_pos + direction)
	
	return adjacent_positions

# Utility methods
func get_entities_of_type(entity_type: String) -> Array[InteractableEntity]:
	"""Get all entities of a specific type"""
	var result: Array[InteractableEntity] = []
	for entity in all_entities:
		if entity.entity_type == entity_type:
			result.append(entity)
	return result

func create_test_interactable(position: Vector2i, type: String = "test_chest", color: Color = Color.YELLOW) -> InteractableEntity:
	"""Create a test interactable entity using the configurable approach"""
	var entity = InteractableEntity.new()
	
	# Configure basic properties
	entity.entity_type = type
	entity.interaction_name = "Open " + type.capitalize().replace("_", " ")
	entity.interaction_cost = 1
	entity.max_uses = 3  # Can be used 3 times
	
	# Configure visual appearance
	entity.configure_visual(color, Vector2(24, 24), "rectangle")
	
	# Configure interaction behavior
	var interaction_message = "You opened the " + type + "! Found some gold."
	var interaction_effects = {"gold": 10}
	entity.configure_interaction(
		"Open " + type.capitalize().replace("_", " "),
		interaction_message,
		interaction_effects,
		1,  # cost
		3   # max uses
	)
	
	return entity

# Alternative: Create specific entity types
func create_treasure_chest(position: Vector2i) -> InteractableEntity:
	"""Create a treasure chest entity"""
	var chest = InteractableEntity.new()
	chest.entity_type = "treasure_chest"
	chest.configure_visual(Color.GOLD, Vector2(28, 20), "rectangle")
	chest.configure_interaction(
		"Open Treasure Chest",
		"You opened the treasure chest and found gold!",
		{"gold": 15},
		1,  # cost
		1   # single use
	)
	return chest

func create_magic_crystal(position: Vector2i) -> InteractableEntity:
	"""Create a magic crystal entity"""
	var crystal = InteractableEntity.new()
	crystal.entity_type = "magic_crystal"
	crystal.configure_visual(Color.PURPLE, Vector2(16, 16), "circle")
	crystal.configure_interaction(
		"Touch Crystal",
		"The crystal glows and restores your energy!",
		{"mana": 5},
		1,  # cost
		-1  # infinite uses
	)
	return crystal

func create_herb_patch(position: Vector2i) -> InteractableEntity:
	"""Create a harvestable herb patch"""
	var herbs = InteractableEntity.new()
	herbs.entity_type = "herb_patch"
	herbs.configure_visual(Color.GREEN, Vector2(20, 12), "rectangle")
	herbs.configure_interaction(
		"Harvest Herbs",
		"You gathered some healing herbs.",
		{"herbs": 3},
		1,  # cost
		2   # can harvest twice
	)
	return herbs
# Debug methods
func debug_print_state():
	"""Print current state for debugging"""
	print("=== InteractManager State ===")
	print("Current state: ", current_state)
	print("Highlighted tiles: ", highlighted_tiles.size())
	print("Total entities: ", all_entities.size())
	print("Entities by tile: ", entities_by_tile.keys())
	print("=============================")
