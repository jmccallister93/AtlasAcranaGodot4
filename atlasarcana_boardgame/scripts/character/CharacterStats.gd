# EnhancedCharacterStats.gd
extends Resource
class_name CharacterStats

signal stats_changed(category_name: String, stat_name: String, old_value: int, new_value: int)
signal stats_recalculated()

@export var character_name: String = "Character"
@export var character_level: int = 1
@export var experience: int = 0

# Stat categories
var combat_stats: StatCategory
var warband_stats: StatCategory
var exploration_stats: StatCategory

# References
var equipment_manager: EquipmentManager
var skill_manager: SkillManager

func _init():
	initialize_stat_categories()

func initialize_stat_categories():
	"""Initialize all stat categories with their base stats"""
	# Combat Stats
	combat_stats = StatCategory.new()
	combat_stats.category_name = "Combat"
	combat_stats.description = "Stats that affect combat performance"
	combat_stats.category_color = Color.RED
	
	# Add combat stats
	combat_stats.add_stat("Health", 100, "Your life force. When it reaches 0, you die.")
	combat_stats.add_stat("Attack", 25, "Your physical damage output in combat.")
	combat_stats.add_stat("Defense", 18, "Your ability to resist and mitigate incoming damage.")
	combat_stats.add_stat("Accuracy", 75, "Your chance to hit enemies in combat.")
	combat_stats.add_stat("Critical_Chance", 5, "Your chance to deal critical damage.")
	combat_stats.add_stat("Critical_Damage", 150, "Percentage damage dealt on critical hits.")
	
	# Warband Stats
	warband_stats = StatCategory.new()
	warband_stats.category_name = "Warband"
	warband_stats.description = "Stats that affect warband management and leadership"
	warband_stats.category_color = Color.BLUE
	
	# Add warband stats
	warband_stats.add_stat("Leadership", 10, "Your ability to command and inspire troops.")
	warband_stats.add_stat("Recruitment", 5, "Your effectiveness at recruiting new units.")
	warband_stats.add_stat("Morale_Bonus", 0, "Bonus morale provided to your warband.")
	warband_stats.add_stat("Training_Efficiency", 100, "How quickly your units gain experience.")
	warband_stats.add_stat("Supply_Management", 10, "Your ability to manage warband resources.")
	
	# Exploration Stats
	exploration_stats = StatCategory.new()
	exploration_stats.category_name = "Exploration"
	exploration_stats.description = "Stats that affect world map movement and exploration"
	exploration_stats.category_color = Color.GREEN
	
	# Add exploration stats
	exploration_stats.add_stat("Movement", 3, "How far you can move on the world map.")
	exploration_stats.add_stat("Action_Points", 5, "Number of actions you can take per turn.")
	exploration_stats.add_stat("Stamina", 80, "Energy for special abilities and sustained actions.")
	exploration_stats.add_stat("Build", 12, "Your construction and crafting capabilities.")
	exploration_stats.add_stat("Interaction_Range", 1, "How far you can interact with objects.")
	exploration_stats.add_stat("Vision_Range", 3, "How far you can see on the world map.")

func set_equipment_manager(manager: EquipmentManager):
	"""Set the equipment manager reference"""
	equipment_manager = manager
	if equipment_manager:
		equipment_manager.equipment_changed.connect(_on_equipment_changed)

func set_skill_manager(manager: SkillManager):
	"""Set the skill manager reference"""
	skill_manager = manager
	if skill_manager:
		skill_manager.skill_learned.connect(_on_skill_learned)
		skill_manager.skill_unlearned.connect(_on_skill_unlearned)

func get_stat_categories() -> Array[StatCategory]:
	"""Get all stat categories"""
	return [combat_stats, warband_stats, exploration_stats]

func get_category(category_name: String) -> StatCategory:
	"""Get a specific stat category"""
	match category_name.to_lower():
		"combat":
			return combat_stats
		"warband":
			return warband_stats
		"exploration":
			return exploration_stats
		_:
			return null

func get_stat_value(category_name: String, stat_name: String) -> int:
	"""Get the total value of a specific stat"""
	var category = get_category(category_name)
	if category:
		var stat = category.get_stat(stat_name)
		if stat:
			return stat.get_total_value()
	return 0

func get_stat_data(category_name: String, stat_name: String) -> StatData:
	"""Get the full stat data for a specific stat"""
	var category = get_category(category_name)
	if category:
		return category.get_stat(stat_name)
	return null

func set_base_stat(category_name: String, stat_name: String, value: int):
	"""Set the base value of a specific stat"""
	var stat = get_stat_data(category_name, stat_name)
	if stat:
		var old_value = stat.get_total_value()
		stat.base_value = value
		var new_value = stat.get_total_value()
		stats_changed.emit(category_name, stat_name, old_value, new_value)

func recalculate_stats():
	"""Recalculate all stats based on equipment and skills"""
	recalculate_equipment_modifiers()
	recalculate_skill_modifiers()
	stats_recalculated.emit()

func recalculate_equipment_modifiers():
	"""Recalculate equipment modifiers for all stats"""
	if not equipment_manager:
		return
	
	# Clear all equipment modifiers
	clear_all_equipment_modifiers()
	
	# Get total equipment modifiers
	var equipment_mods = equipment_manager.get_total_stat_modifiers()
	
	# Apply equipment modifiers to appropriate stats
	for stat_name in equipment_mods:
		var modifier_value = equipment_mods[stat_name]
		apply_equipment_modifier_to_stat(stat_name, modifier_value)

func recalculate_skill_modifiers():
	"""Recalculate skill modifiers for all stats"""
	if not skill_manager:
		return
	
	# Clear all skill modifiers
	clear_all_skill_modifiers()
	
	# Get total skill modifiers
	var skill_mods = skill_manager.get_total_stat_modifiers()
	
	# Apply skill modifiers to appropriate stats
	for stat_name in skill_mods:
		var modifier_value = skill_mods[stat_name]
		apply_skill_modifier_to_stat(stat_name, modifier_value)

func clear_all_equipment_modifiers():
	"""Clear equipment modifiers from all stats"""
	for category in get_stat_categories():
		for stat_name in category.stats:
			var stat = category.stats[stat_name]
			stat.set_equipment_modifier(0)

func clear_all_skill_modifiers():
	"""Clear skill modifiers from all stats"""
	for category in get_stat_categories():
		for stat_name in category.stats:
			var stat = category.stats[stat_name]
			stat.set_skill_modifier(0)

func apply_equipment_modifier_to_stat(stat_name: String, modifier: int):
	"""Apply an equipment modifier to the appropriate stat"""
	var stat = find_stat_by_name(stat_name)
	if stat:
		stat.set_equipment_modifier(stat.equipment_modifier + modifier)

func apply_skill_modifier_to_stat(stat_name: String, modifier: int):
	"""Apply a skill modifier to the appropriate stat"""
	var stat = find_stat_by_name(stat_name)
	if stat:
		stat.set_skill_modifier(stat.skill_modifier + modifier)

func find_stat_by_name(stat_name: String) -> StatData:
	"""Find a stat by name across all categories"""
	for category in get_stat_categories():
		if category.stats.has(stat_name):
			return category.stats[stat_name]
	return null

func _on_equipment_changed(slot_type: EquipmentSlot.SlotType, old_item: EquipmentItem, new_item: EquipmentItem):
	"""Handle equipment changes"""
	recalculate_equipment_modifiers()

func _on_skill_learned(skill: SkillNode):
	"""Handle skill learning"""
	recalculate_skill_modifiers()

func _on_skill_unlearned(skill: SkillNode):
	"""Handle skill unlearning"""
	recalculate_skill_modifiers()

# Legacy compatibility methods
func get_action_points() -> int:
	return get_stat_value("Exploration", "Action_Points")

func get_max_health() -> int:
	return get_stat_value("Combat", "Health")

func get_movement() -> int:
	return get_stat_value("Exploration", "Movement")

func get_build() -> int:
	return get_stat_value("Exploration", "Build")

func get_attack() -> int:
	return get_stat_value("Combat", "Attack")

func get_defense() -> int:
	return get_stat_value("Combat", "Defense")
