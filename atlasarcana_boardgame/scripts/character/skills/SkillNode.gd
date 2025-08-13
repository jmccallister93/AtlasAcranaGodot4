# SkillNode.gd
extends Resource
class_name SkillNode

@export var skill_id: String
@export var skill_name: String
@export var description: String
@export var icon_path: String
@export var max_level: int = 1
@export var current_level: int = 0
@export var skill_point_cost: int = 1
@export var level_requirement: int = 1

# Prerequisites
@export var required_skills: Array = []  # Array of skill IDs
@export var required_stats: Dictionary = {}  # stat_name -> minimum_value

# Effects
@export var stat_modifiers_per_level: Dictionary = {}  # stat_name -> modifier_per_level
@export var special_abilities: Array = []  # Array of ability IDs

# Tree positioning (for UI)
@export var tree_position: Vector2 = Vector2.ZERO
@export var tree_category: String = ""

signal skill_level_changed(skill: SkillNode, old_level: int, new_level: int)

func can_learn() -> bool:
	"""Check if this skill can be learned (next level)"""
	return current_level < max_level

func is_maxed() -> bool:
	"""Check if this skill is at maximum level"""
	return current_level >= max_level

func is_learned() -> bool:
	"""Check if this skill has been learned (level > 0)"""
	return current_level > 0

func get_stat_modifiers() -> Dictionary:
	"""Get current stat modifiers based on level"""
	var modifiers = {}
	for stat_name in stat_modifiers_per_level:
		var modifier_per_level = stat_modifiers_per_level[stat_name]
		modifiers[stat_name] = modifier_per_level * current_level
	return modifiers

func get_next_level_stat_modifiers() -> Dictionary:
	"""Get stat modifiers if leveled up once more"""
	var modifiers = {}
	for stat_name in stat_modifiers_per_level:
		var modifier_per_level = stat_modifiers_per_level[stat_name]
		modifiers[stat_name] = modifier_per_level * (current_level + 1)
	return modifiers

func level_up() -> bool:
	"""Level up the skill if possible"""
	if can_learn():
		var old_level = current_level
		current_level += 1
		skill_level_changed.emit(self, old_level, current_level)
		return true
	return false

func level_down() -> bool:
	"""Level down the skill if possible (for respec)"""
	if current_level > 0:
		var old_level = current_level
		current_level -= 1
		skill_level_changed.emit(self, old_level, current_level)
		return true
	return false

func reset_skill():
	"""Reset skill to level 0"""
	if current_level > 0:
		var old_level = current_level
		current_level = 0
		skill_level_changed.emit(self, old_level, current_level)
