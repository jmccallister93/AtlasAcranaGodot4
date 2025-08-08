# Enemy.gd - Attackable Enemy Entity
extends Node2D
class_name Enemy

# Signals for attack events
signal attacked(enemy: Enemy, attacker: Character, damage: int)
signal died(enemy: Enemy)
signal health_changed(enemy: Enemy, current_health: int, max_health: int)

# Enemy properties
@export var enemy_type: String = "goblin"
@export var enemy_name: String = "Goblin"
@export var can_be_attacked: bool = true
@export var attack_range: int = 1  # How close attacker needs to be

# Combat stats
@export var max_health: int = 30
@export var current_health: int = 30
@export var armor: int = 2
@export var damage: int = 8
@export var experience_reward: int = 10
@export var loot_table: Dictionary = {"gold": 5}

# Visual configuration
@export var visual_color: Color = Color.RED
@export var visual_size: Vector2 = Vector2(24, 24)
@export var visual_shape: String = "rectangle"  # "rectangle", "circle", "custom"

# Status effects and states
var is_dead: bool = false
var status_effects: Array[String] = []

# Position and visual
var grid_position: Vector2i
var visual_component: Node2D
var health_bar_component: Node2D

func _ready():
	create_visual_component()
	create_health_bar()
	update_visual_state()

func create_visual_component():
	"""Create the visual representation based on configuration"""
	visual_component = Node2D.new()
	visual_component.name = "VisualComponent"
	add_child(visual_component)
	
	match visual_shape:
		"rectangle":
			create_rectangle_visual()
		"circle":
			create_circle_visual()
		"custom":
			create_custom_visual()
		_:
			create_rectangle_visual()

func create_rectangle_visual():
	"""Create a rectangular visual"""
	var visual = ColorRect.new()
	visual.size = visual_size
	visual.position = Vector2(-visual_size.x/2, -visual_size.y/2)
	visual.color = visual_color
	visual.z_index = 15  # Above tiles but below UI
	visual_component.add_child(visual)

func create_circle_visual():
	"""Create a circular visual"""
	var visual = ColorRect.new()
	var circle_size = min(visual_size.x, visual_size.y)
	visual.size = Vector2(circle_size, circle_size)
	visual.position = Vector2(-circle_size/2, -circle_size/2)
	visual.color = visual_color
	visual.z_index = 15
	visual_component.add_child(visual)

func create_custom_visual():
	"""Override this in subclasses for custom visuals"""
	create_rectangle_visual()  # Fallback to rectangle

func create_health_bar():
	"""Create a health bar above the enemy"""
	health_bar_component = Node2D.new()
	health_bar_component.name = "HealthBar"
	add_child(health_bar_component)
	
	# Background bar
	var bg_bar = ColorRect.new()
	bg_bar.size = Vector2(visual_size.x, 4)
	bg_bar.position = Vector2(-visual_size.x/2, -visual_size.y/2 - 8)
	bg_bar.color = Color.DARK_RED
	bg_bar.z_index = 16
	health_bar_component.add_child(bg_bar)
	
	# Health bar
	var health_bar = ColorRect.new()
	health_bar.name = "HealthBar"
	health_bar.size = Vector2(visual_size.x, 4)
	health_bar.position = Vector2(-visual_size.x/2, -visual_size.y/2 - 8)
	health_bar.color = Color.GREEN
	health_bar.z_index = 17
	health_bar_component.add_child(health_bar)

func update_health_bar():
	"""Update the health bar visual"""
	if not health_bar_component:
		return
		
	var health_bar = health_bar_component.get_node("HealthBar")
	if health_bar:
		var health_percentage = float(current_health) / float(max_health)
		health_bar.size.x = visual_size.x * health_percentage
		
		# Change color based on health
		if health_percentage > 0.6:
			health_bar.color = Color.GREEN
		elif health_percentage > 0.3:
			health_bar.color = Color.YELLOW
		else:
			health_bar.color = Color.RED

func can_be_attacked_by(attacker: Character) -> bool:
	"""Check if this enemy can be attacked by the character"""
	if not can_be_attacked or is_dead:
		return false
	
	# Check if attacker has enough action points (assuming 1 AP for attack)
	if attacker.current_action_points < 1:
		return false
	
	# Check attack range
	var distance = abs(grid_position.x - attacker.grid_position.x) + abs(grid_position.y - attacker.grid_position.y)
	if distance > attack_range:
		return false
	
	return true

func take_damage(damage_amount: int, attacker: Character) -> Dictionary:
	"""Take damage and return attack result"""
	if is_dead:
		return {"success": false, "message": "Enemy is already dead"}
	
	# Calculate actual damage (armor reduction)
	var actual_damage = max(1, damage_amount - armor)  # Minimum 1 damage
	current_health = max(0, current_health - actual_damage)
	
	# Emit health changed signal
	health_changed.emit(self, current_health, max_health)
	update_health_bar()
	
	# Emit attacked signal
	attacked.emit(self, attacker, actual_damage)
	
	var result = {
		"success": true,
		"damage_dealt": actual_damage,
		"damage_blocked": damage_amount - actual_damage,
		"enemy_health": current_health,
		"enemy_max_health": max_health
	}
	
	# Check if enemy died
	if current_health <= 0:
		result["enemy_died"] = true
		result["experience"] = experience_reward
		result["loot"] = loot_table.duplicate()
		die()
	else:
		result["enemy_died"] = false
		result["message"] = "%s takes %d damage! (%d/%d HP)" % [enemy_name, actual_damage, current_health, max_health]
	
	return result

func die():
	"""Handle enemy death"""
	if is_dead:
		return
		
	is_dead = true
	can_be_attacked = false
	
	# Visual death effect
	update_visual_for_death()
	
	# Emit death signal
	died.emit(self)
	
	print("%s has been defeated!" % enemy_name)

func update_visual_for_death():
	"""Update visual when enemy dies"""
	if visual_component:
		# Darken the enemy and maybe add an X or skull
		for child in visual_component.get_children():
			if child is ColorRect:
				child.color = child.color.darkened(0.7)
		
		# Hide health bar
		if health_bar_component:
			health_bar_component.visible = false
		
		# Optional: Add death marker
		var death_marker = Label.new()
		death_marker.text = "💀"
		death_marker.position = Vector2(-6, -12)
		death_marker.z_index = 20
		visual_component.add_child(death_marker)

func update_visual_state():
	"""Update visual based on current state"""
	update_health_bar()
	
	if is_dead:
		update_visual_for_death()

func get_attack_info() -> Dictionary:
	"""Get information about this enemy for UI display"""
	return {
		"name": enemy_name,
		"type": enemy_type,
		"health": current_health,
		"max_health": max_health,
		"armor": armor,
		"damage": damage,
		"can_attack": can_be_attacked,
		"is_dead": is_dead,
		"description": get_description()
	}

func get_description() -> String:
	"""Get description for this enemy"""
	if is_dead:
		return "A fallen " + enemy_type + "."
	else:
		return "A %s with %d/%d HP. Armor: %d, Damage: %d" % [enemy_type, current_health, max_health, armor, damage]

func set_grid_position(pos: Vector2i, tile_size: int):
	"""Set the grid position and update world position"""
	grid_position = pos
	global_position = Vector2(
		pos.x * tile_size + tile_size / 2,
		pos.y * tile_size + tile_size / 2
	)

func heal(amount: int):
	"""Heal the enemy (for testing or special abilities)"""
	if is_dead:
		return
		
	current_health = min(max_health, current_health + amount)
	health_changed.emit(self, current_health, max_health)
	update_health_bar()

func add_status_effect(effect: String):
	"""Add a status effect"""
	if effect not in status_effects:
		status_effects.append(effect)

func remove_status_effect(effect: String):
	"""Remove a status effect"""
	status_effects.erase(effect)

func has_status_effect(effect: String) -> bool:
	"""Check if enemy has a specific status effect"""
	return effect in status_effects

# Configuration methods for easy setup
func configure_visual(color: Color, size: Vector2 = Vector2(24, 24), shape: String = "rectangle"):
	"""Configure the visual appearance"""
	visual_color = color
	visual_size = size
	visual_shape = shape
	
	# Recreate visual if already created
	if visual_component:
		visual_component.queue_free()
		call_deferred("create_visual_component")
		call_deferred("create_health_bar")

func configure_stats(health: int, armor_value: int = 0, damage_value: int = 5, exp_reward: int = 10):
	"""Configure the combat stats"""
	max_health = health
	current_health = health
	armor = armor_value
	damage = damage_value
	experience_reward = exp_reward
	
	# Update health bar if it exists
	if health_bar_component:
		update_health_bar()

func configure_loot(loot: Dictionary):
	"""Configure the loot table"""
	loot_table = loot.duplicate()

# Factory methods for different enemy types
static func create_goblin(position: Vector2i) -> Enemy:
	"""Create a goblin enemy"""
	var goblin = Enemy.new()
	goblin.enemy_type = "goblin"
	goblin.enemy_name = "Goblin Warrior"
	goblin.configure_visual(Color.DARK_GREEN, Vector2(20, 20), "rectangle")
	goblin.configure_stats(25, 1, 6, 8)
	goblin.configure_loot({"gold": 3, "goblin_ear": 1})
	return goblin

static func create_orc(position: Vector2i) -> Enemy:
	"""Create an orc enemy"""
	var orc = Enemy.new()
	orc.enemy_type = "orc"
	orc.enemy_name = "Orc Brute"
	orc.configure_visual(Color.DARK_RED, Vector2(28, 28), "rectangle")
	orc.configure_stats(45, 3, 10, 15)
	orc.configure_loot({"gold": 8, "orc_tusk": 1})
	return orc

static func create_skeleton(position: Vector2i) -> Enemy:
	"""Create a skeleton enemy"""
	var skeleton = Enemy.new()
	skeleton.enemy_type = "skeleton"
	skeleton.enemy_name = "Skeleton Archer"
	skeleton.configure_visual(Color.WHITE, Vector2(22, 22), "rectangle")
	skeleton.configure_stats(20, 0, 8, 12)
	skeleton.configure_loot({"gold": 5, "bone": 2})
	skeleton.attack_range = 2  # Ranged attack
	return skeleton

static func create_dragon(position: Vector2i) -> Enemy:
	"""Create a dragon enemy (boss)"""
	var dragon = Enemy.new()
	dragon.enemy_type = "dragon"
	dragon.enemy_name = "Ancient Dragon"
	dragon.configure_visual(Color.PURPLE, Vector2(40, 40), "rectangle")
	dragon.configure_stats(150, 8, 25, 100)
	dragon.configure_loot({"gold": 50, "dragon_scale": 3, "magic_gem": 1})
	dragon.attack_range = 3  # Powerful breath attack
	return dragon
