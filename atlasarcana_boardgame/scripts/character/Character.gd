# Character.gd - Updated to use  stats system
extends CharacterBody2D
class_name Character

signal action_points_spent(action_points: int)
signal action_points_refreshed(action_points: int)
signal stats_changed()

@export var stats: CharacterStats
var equipment_manager: EquipmentManager
var skill_manager: SkillManager

# Current values that change during gameplay
var current_health: int
var current_stamina: int
var current_movement_points: int
var current_action_points: int
var current_build_points: int

var grid_position: Vector2i
var sprite: Sprite2D

func _ready():
	if stats == null:
		push_error("Character: stats must be set before adding to scene tree")
		return
	
	initialize_managers()
	initialize_from_stats()
	create_sprite()
	connect_character_signals()

func initialize_managers():
	"""Initialize equipment and skill managers"""
	# Create equipment manager
	equipment_manager = EquipmentManager.new()
	add_child(equipment_manager)
	equipment_manager.set_character_stats(stats)
	stats.set_equipment_manager(equipment_manager)
	
	# Create skill manager
	skill_manager = SkillManager.new()
	add_child(skill_manager)
	skill_manager.set_character_stats(stats)
	stats.set_skill_manager(skill_manager)
	
	# Give some starting skill points for testing
	skill_manager.add_skill_points(5)
	
	print("✅ Character managers initialized")

func connect_character_signals():
	"""Connect internal signals"""
	if stats:
		stats.stats_recalculated.connect(_on_stats_recalculated)
	
	if equipment_manager:
		equipment_manager.equipment_changed.connect(_on_equipment_changed)
	
	if skill_manager:
		skill_manager.skill_learned.connect(_on_skill_learned)

func initialize_from_stats():
	"""Initialize character values from stats"""
	if not stats:
		return
	
	# Initialize current values from stats
	current_health = stats.get_stat_value("Combat", "Health")
	current_stamina = stats.get_stat_value("Exploration", "Stamina")
	current_action_points = stats.get_stat_value("Exploration", "Action_Points")
	current_movement_points = stats.get_stat_value("Exploration", "Movement")
	current_build_points = stats.get_stat_value("Exploration", "Build")
	
	# Set grid position
	grid_position = Vector2i(16, 16)
	var tile_size = 64
	global_position = Vector2(
		grid_position.x * tile_size + tile_size / 2,
		grid_position.y * tile_size + tile_size / 2
	)

func refresh_turn_resources():
	"""Refresh resources at turn start"""
	if not stats:
		return
	
	# Refresh action points from stats
	current_action_points = stats.get_stat_value("Exploration", "Action_Points")
	action_points_refreshed.emit(current_action_points)
	
	# Refresh other turn-based resources as needed
	current_movement_points = stats.get_stat_value("Exploration", "Movement")

func can_perform_action(action_cost: int) -> bool:
	"""Check if character can perform an action"""
	return current_action_points >= action_cost

func spend_action_points(amount: int = 1):
	"""Spend action points"""
	if current_action_points >= amount:
		current_action_points -= amount
		action_points_spent.emit(current_action_points)

func get_attack_value() -> int:
	"""Get current attack value"""
	return stats.get_stat_value("Combat", "Attack")

func get_defense_value() -> int:
	"""Get current defense value"""
	return stats.get_stat_value("Combat", "Defense")

func get_current_health() -> int:
	"""Get current health"""
	return current_health

func get_max_health() -> int:
	"""Get maximum health"""
	return stats.get_stat_value("Combat", "Health")

func get_current_action_points() -> int:
	"""Get current action points"""
	return current_action_points

func get_max_action_points() -> int:
	"""Get maximum action points"""
	return stats.get_stat_value("Exploration", "Action_Points")

# Equipment methods
func equip_item(item: EquipmentItem, slot_type: EquipmentSlot.SlotType) -> bool:
	"""Equip an item"""
	if equipment_manager:
		return equipment_manager.equip_item(item, slot_type)
	return false

func unequip_item(slot_type: EquipmentSlot.SlotType) -> EquipmentItem:
	"""Unequip an item"""
	if equipment_manager:
		return equipment_manager.unequip_item(slot_type)
	return null

func get_equipped_item(slot_type: EquipmentSlot.SlotType) -> EquipmentItem:
	"""Get equipped item in a slot"""
	if equipment_manager:
		return equipment_manager.get_equipped_item(slot_type)
	return null

# Skill methods
func learn_skill(skill_id: String) -> bool:
	"""Learn a skill"""
	if skill_manager:
		return skill_manager.learn_skill(skill_id)
	return false

func get_skill_points() -> int:
	"""Get available skill points"""
	if skill_manager:
		return skill_manager.get_available_skill_points()
	return 0

func add_skill_points(amount: int):
	"""Add skill points"""
	if skill_manager:
		skill_manager.add_skill_points(amount)

# Legacy compatibility methods for existing game systems
func get_action_points() -> int:
	"""Legacy method for action points"""
	return get_current_action_points()

func create_sprite():
	"""Create character sprite"""
	#var color_rect = ColorRect.new()
	#color_rect.name = "CharacterSprite"
	#color_rect.color = Color.RED
	#color_rect.size = Vector2(32, 32)
	#color_rect.position = Vector2(-16, -16)  # Center the sprite
	#color_rect.z_index = 10
	#
	#add_child(color_rect)
	
	var sprite = Sprite2D.new()
	sprite.name="CharacterSprite"
	sprite.texture = preload("res://assets/character/character_sprite2.png")
	#sprite.size = Vector2i(32, 32)
	sprite.position = Vector2(-16, -16)  # Center the sprite
	sprite.z_index = 10
	add_child(sprite)
	var collision_box = CollisionShape2D.new()
	sprite.position = Vector2(-16, -16)  # Center the sprite
	sprite.z_index = 10
	add_child(collision_box)
	
	

# Signal handlers
func _on_stats_recalculated():
	"""Handle stats recalculation"""
	stats_changed.emit()
	print("Character stats recalculated")

func _on_equipment_changed(slot_type: EquipmentSlot.SlotType, old_item: EquipmentItem, new_item: EquipmentItem):
	"""Handle equipment changes"""
	if new_item:
		print("Equipped ", new_item.item_name, " in ", EquipmentSlot.SlotType.keys()[slot_type])
	elif old_item:
		print("Unequipped ", old_item.item_name, " from ", EquipmentSlot.SlotType.keys()[slot_type])

func _on_skill_learned(skill: SkillNode):
	"""Handle skill learned"""
	print("Learned skill: ", skill.skill_name)

func get_inventory_manager() -> InventoryManager:
	"""Get the character's inventory manager from GameManager"""
	if GameManager and GameManager.inventory_manager:
		return GameManager.inventory_manager
	return null

func add_item_to_inventory(item: BaseItem, amount: int = 1) -> bool:
	"""Helper method to add items to character inventory"""
	var inv_manager = get_inventory_manager()
	if inv_manager:
		return inv_manager.add_item(item, amount)
	return false
