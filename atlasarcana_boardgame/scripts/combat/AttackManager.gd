# AttackManager.gd
extends Node
class_name AttackManager

# Signals similar to other managers
signal attack_attempted(character: Character, enemy: Enemy)
signal attack_completed(character: Character, enemy: Enemy, result: Dictionary)
signal attack_failed(reason: String)
signal attack_mode_started
signal attack_mode_ended
signal attack_confirmation_requested(target_tile: BiomeTile, enemy: Enemy)
signal enemy_died(enemy: Enemy)

# Attack mode states
enum AttackState {
	INACTIVE,
	SELECTING_TARGET,
	AWAITING_CONFIRMATION
}

# References
var character: Character
var map_manager: MapManager
var current_state: AttackState = AttackState.INACTIVE
var highlighted_tiles: Array[BiomeTile] = []
var pending_target_position: Vector2i
var pending_target_enemy: Enemy

# Enemy storage
var enemies_by_tile: Dictionary = {}  # Vector2i -> Array[Enemy]
var all_enemies: Array[Enemy] = []

# Attack configuration
var base_attack_range: int = 1  # Base attack range for character
var base_attack_damage: int = 10  # Base attack damage

func initialize(char: Character, map: MapManager):
	"""Initialize the attack manager with character and map references"""
	character = char
	map_manager = map

func start_attack_mode():
	"""Start the attack selection mode"""
	if current_state != AttackState.INACTIVE:
		return
		
	if character.current_action_points <= 0:
		attack_failed.emit("No action points remaining")
		return
		
	current_state = AttackState.SELECTING_TARGET
	highlight_attackable_tiles()
	attack_mode_started.emit()
	print("Attack mode started")

func end_attack_mode():
	"""End the attack selection mode"""
	current_state = AttackState.INACTIVE
	clear_highlighted_tiles()
	pending_target_position = Vector2i.ZERO
	pending_target_enemy = null
	attack_mode_ended.emit()
	print("Attack mode ended")

func highlight_attackable_tiles():
	"""Highlight tiles within attack range that have attackable enemies"""
	clear_highlighted_tiles()
	
	var character_pos = character.grid_position
	
	# Get all tiles within attack range
	var attack_range_tiles = get_tiles_in_range(character_pos, base_attack_range)
	
	for tile_pos in attack_range_tiles:
		var tile = map_manager.get_tile_at(tile_pos)
		
		if tile and has_attackable_enemy(tile_pos):
			var enemies = get_enemies_at_position(tile_pos)
			# Only highlight if there's at least one enemy the character can attack
			var can_attack_any = false
			for enemy in enemies:
				if enemy.can_be_attacked_by(character):
					can_attack_any = true
					break
			
			if can_attack_any:
				tile.set_attack_highlighted(true)  # Use proper attack highlighting
				highlighted_tiles.append(tile)

func clear_highlighted_tiles():
	"""Clear all highlighted tiles"""
	for tile in highlighted_tiles:
		tile.set_attack_highlighted(false)  # Use proper attack highlighting
	highlighted_tiles.clear()

func get_tiles_in_range(center_pos: Vector2i, range: int) -> Array[Vector2i]:
	"""Get all tiles within attack range"""
	var tiles_in_range: Array[Vector2i] = []
	
	for x in range(-range, range + 1):
		for y in range(-range, range + 1):
			var distance = abs(x) + abs(y)  # Manhattan distance
			if distance <= range and distance > 0:  # Don't include center tile
				tiles_in_range.append(center_pos + Vector2i(x, y))
	
	return tiles_in_range

func has_attackable_enemy(position: Vector2i) -> bool:
	"""Check if there's an attackable enemy at the given position"""
	return position in enemies_by_tile and enemies_by_tile[position].size() > 0

func get_enemies_at_position(position: Vector2i) -> Array[Enemy]:
	"""Get all enemies at the given position"""
	var enemies = enemies_by_tile.get(position, [])
	var result: Array[Enemy] = []
	result.assign(enemies)
	return result

func is_tile_highlighted(target_pos: Vector2i) -> bool:
	"""Check if a tile is currently highlighted for attack"""
	for tile in highlighted_tiles:
		if tile.grid_position == target_pos:
			return true
	return false

func attempt_attack_at(target_pos: Vector2i):
	"""Attempt to attack at target position - requests confirmation first"""
	print("Attempting to attack at: ", target_pos)
	
	# Only allow attack if in selecting mode and tile is highlighted
	if current_state != AttackState.SELECTING_TARGET:
		print("Not in attack selection mode")
		return
		
	if not is_tile_highlighted(target_pos):
		print("Target tile is not highlighted/attackable")
		attack_failed.emit("No attackable enemies at this location")
		return
	
	# Check if character has action points
	if character.current_action_points <= 0:
		print("No action points remaining")
		attack_failed.emit("No action points remaining")
		end_attack_mode()
		return
	
	# Get the first attackable enemy at this position
	var enemies = get_enemies_at_position(target_pos)
	var target_enemy = null
	
	for enemy in enemies:
		if enemy.can_be_attacked_by(character):
			target_enemy = enemy
			break
	
	if not target_enemy:
		attack_failed.emit("No valid attackable enemies at this location")
		return
	
	# Store the target and request confirmation
	pending_target_position = target_pos
	pending_target_enemy = target_enemy
	current_state = AttackState.AWAITING_CONFIRMATION
	
	var target_tile = map_manager.get_tile_at(target_pos)
	if target_tile:
		attack_confirmation_requested.emit(target_tile, target_enemy)
	else:
		attack_failed.emit("Invalid target tile")
		end_attack_mode()

func confirm_attack():
	"""Execute the confirmed attack"""
	if current_state != AttackState.AWAITING_CONFIRMATION:
		print("No attack awaiting confirmation")
		return
		
	var target_enemy = pending_target_enemy
	
	# Final validation
	if character.current_action_points <= 0:
		attack_failed.emit("No action points remaining")
		end_attack_mode()
		return
	
	if not target_enemy or not target_enemy.can_be_attacked_by(character):
		attack_failed.emit("Cannot attack target enemy")
		end_attack_mode()
		return
	
	# Emit attempt signal
	attack_attempted.emit(character, target_enemy)
	
	# Calculate attack damage (could be made more complex)
	var attack_damage = calculate_attack_damage(character, target_enemy)
	
	# Perform the attack
	var result = target_enemy.take_damage(attack_damage, character)
	
	if result.get("success", false):
		# Spend action point
		character.spend_action_points()
		
		# Check if enemy died
		if result.get("enemy_died", false):
			handle_enemy_death(target_enemy, result)
		
		# End attack mode
		end_attack_mode()
		
		# Emit completion signal
		attack_completed.emit(character, target_enemy, result)
		print("Attack completed: ", result.get("damage_dealt", 0), " damage dealt")
	else:
		attack_failed.emit(result.get("message", "Attack failed"))
		end_attack_mode()

func calculate_attack_damage(attacker: Character, target: Enemy) -> int:
	"""Calculate attack damage - can be made more sophisticated"""
	var base_damage = base_attack_damage
	
	# Add character stats if available (strength, weapon damage, etc.)
	# For now, just use base damage with some randomness
	var damage_variance = randi() % 5  # 0-4 extra damage
	return base_damage + damage_variance

func handle_enemy_death(enemy: Enemy, attack_result: Dictionary):
	"""Handle what happens when an enemy dies"""
	# Award experience
	if attack_result.has("experience"):
		var exp = attack_result.experience
		print("Gained %d experience!" % exp)
		# TODO: Add experience to character when character system supports it
	
	# Handle loot
	if attack_result.has("loot"):
		var loot = attack_result.loot
		for item in loot:
			var amount = loot[item]
			print("Found loot: %d %s" % [amount, item])
			# TODO: Add loot to character inventory when inventory system supports it
	
	# Remove enemy from the world
	remove_enemy(enemy)
	
	# Emit death signal
	enemy_died.emit(enemy)

func cancel_attack():
	"""Cancel the pending attack and return to selection mode"""
	if current_state == AttackState.AWAITING_CONFIRMATION:
		current_state = AttackState.SELECTING_TARGET
		pending_target_position = Vector2i.ZERO
		pending_target_enemy = null
		print("Attack cancelled, returning to selection mode")

# Enemy management methods
func add_enemy(enemy: Enemy, position: Vector2i):
	"""Add an enemy to the world"""
	enemy.set_grid_position(position, map_manager.tile_size)
	
	# Add to tile lookup
	if position not in enemies_by_tile:
		enemies_by_tile[position] = []
	enemies_by_tile[position].append(enemy)
	
	# Add to global list
	all_enemies.append(enemy)
	
	# Connect enemy signals
	enemy.died.connect(_on_enemy_died)
	enemy.health_changed.connect(_on_enemy_health_changed)
	
	# Add to scene tree via map manager
	map_manager.add_child(enemy)
	
	print("Added enemy: ", enemy.enemy_name, " at ", position)

func remove_enemy(enemy: Enemy):
	"""Remove an enemy from the world"""
	var position = enemy.grid_position
	
	# Remove from tile lookup
	if position in enemies_by_tile:
		enemies_by_tile[position].erase(enemy)
		if enemies_by_tile[position].is_empty():
			enemies_by_tile.erase(position)
	
	# Remove from global list
	all_enemies.erase(enemy)
	
	# Disconnect signals
	if enemy.died.is_connected(_on_enemy_died):
		enemy.died.disconnect(_on_enemy_died)
	if enemy.health_changed.is_connected(_on_enemy_health_changed):
		enemy.health_changed.disconnect(_on_enemy_health_changed)
	
	# Remove from scene tree after a delay to allow death animations
	enemy.call_deferred("queue_free")
	
	print("Removed enemy: ", enemy.enemy_name, " at ", position)

func _on_enemy_died(enemy: Enemy):
	"""Handle enemy death signal"""
	print("%s has died!" % enemy.enemy_name)
	# Additional death handling can go here

func _on_enemy_health_changed(enemy: Enemy, current_health: int, max_health: int):
	"""Handle enemy health change"""
	print("%s health: %d/%d" % [enemy.enemy_name, current_health, max_health])

# Factory methods for creating enemies
func create_goblin_warrior(position: Vector2i) -> Enemy:
	"""Create a goblin warrior enemy"""
	var goblin = Enemy.create_goblin(position)
	return goblin

func create_orc_brute(position: Vector2i) -> Enemy:
	"""Create an orc brute enemy"""
	var orc = Enemy.create_orc(position)
	return orc

func create_skeleton_archer(position: Vector2i) -> Enemy:
	"""Create a skeleton archer enemy"""
	var skeleton = Enemy.create_skeleton(position)
	return skeleton

func create_ancient_dragon(position: Vector2i) -> Enemy:
	"""Create an ancient dragon enemy"""
	var dragon = Enemy.create_dragon(position)
	return dragon

func create_random_enemy(position: Vector2i) -> Enemy:
	"""Create a random enemy at the position"""
	var enemy_types = ["goblin", "orc", "skeleton"]
	var random_type = enemy_types[randi() % enemy_types.size()]
	
	match random_type:
		"goblin":
			return create_goblin_warrior(position)
		"orc":
			return create_orc_brute(position)
		"skeleton":
			return create_skeleton_archer(position)
		_:
			return create_goblin_warrior(position)

# Utility methods
func get_enemies_of_type(enemy_type: String) -> Array[Enemy]:
	"""Get all enemies of a specific type"""
	var result: Array[Enemy] = []
	for enemy in all_enemies:
		if enemy.enemy_type == enemy_type:
			result.append(enemy)
	return result

func get_enemies_in_range(center_pos: Vector2i, range: int) -> Array[Enemy]:
	"""Get all enemies within a certain range of a position"""
	var result: Array[Enemy] = []
	var tiles_in_range = get_tiles_in_range(center_pos, range)
	
	for tile_pos in tiles_in_range:
		var enemies = get_enemies_at_position(tile_pos)
		result.append_array(enemies)
	
	return result

func get_nearest_enemy(to_position: Vector2i) -> Enemy:
	"""Get the nearest enemy to a position"""
	var nearest_enemy: Enemy = null
	var nearest_distance: int = 999999
	
	for enemy in all_enemies:
		if enemy.is_dead:
			continue
			
		var distance = abs(enemy.grid_position.x - to_position.x) + abs(enemy.grid_position.y - to_position.y)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	
	return nearest_enemy

func count_living_enemies() -> int:
	"""Count how many enemies are still alive"""
	var count = 0
	for enemy in all_enemies:
		if not enemy.is_dead:
			count += 1
	return count

func heal_all_enemies(amount: int):
	"""Heal all living enemies (for testing)"""
	for enemy in all_enemies:
		if not enemy.is_dead:
			enemy.heal(amount)

func spawn_enemy_wave(wave_size: int = 3, spawn_range: int = 5):
	"""Spawn a wave of random enemies around the character"""
	var character_pos = character.grid_position
	var spawned = 0
	
	for i in range(100):  # Try up to 100 times to find valid spawn positions
		if spawned >= wave_size:
			break
			
		# Generate random position within spawn range
		var offset_x = randi() % (spawn_range * 2 + 1) - spawn_range
		var offset_y = randi() % (spawn_range * 2 + 1) - spawn_range
		var spawn_pos = character_pos + Vector2i(offset_x, offset_y)
		
		# Make sure position is valid and empty
		var tile = map_manager.get_tile_at(spawn_pos)
		if tile and not has_attackable_enemy(spawn_pos) and spawn_pos != character_pos:
			var enemy = create_random_enemy(spawn_pos)
			add_enemy(enemy, spawn_pos)
			spawned += 1
	
	print("Spawned %d enemies in wave" % spawned)

# Debug methods
func debug_print_state():
	"""Print current state for debugging"""
	print("=== AttackManager State ===")
	print("Current state: ", current_state)
	print("Highlighted tiles: ", highlighted_tiles.size())
	print("Total enemies: ", all_enemies.size())
	print("Living enemies: ", count_living_enemies())
	print("Enemies by tile: ", enemies_by_tile.keys())
	print("===========================")

func debug_spawn_test_enemies():
	"""Spawn test enemies for debugging"""
	var character_pos = character.grid_position
	
	# Spawn a goblin nearby
	var goblin_pos = character_pos + Vector2i(2, 1)
	var goblin = create_goblin_warrior(goblin_pos)
	add_enemy(goblin, goblin_pos)
	
	# Spawn an orc nearby
	var orc_pos = character_pos + Vector2i(-2, 2)
	var orc = create_orc_brute(orc_pos)
	add_enemy(orc, orc_pos)
	
	# Spawn a skeleton archer nearby
	var skeleton_pos = character_pos + Vector2i(1, -2)
	var skeleton = create_skeleton_archer(skeleton_pos)
	add_enemy(skeleton, skeleton_pos)
	
	print("Spawned test enemies around character")
