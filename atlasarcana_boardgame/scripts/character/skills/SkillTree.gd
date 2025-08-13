# SkillTree.gd
extends Resource
class_name SkillTree

@export var tree_name: String
@export var tree_description: String
@export var tree_color: Color = Color.WHITE
@export var skills: Dictionary = {}  # skill_id -> SkillNode

func add_skill(skill: SkillNode):
	"""Add a skill to this tree"""
	skills[skill.skill_id] = skill
	skill.tree_category = tree_name

func get_skill(skill_id: String) -> SkillNode:
	"""Get a skill by ID"""
	return skills.get(skill_id)

func get_all_skills() -> Array:
	"""Get all skills in this tree"""
	var skill_array: Array = []
	for skill in skills.values():
		skill_array.append(skill)
	return skill_array

func get_learned_skills() -> Array:
	"""Get all learned skills in this tree"""
	var learned: Array = []
	for skill in skills.values():
		if skill.is_learned():
			learned.append(skill)
	return learned

func get_available_skills(character_stats: CharacterStats, learned_skills: Array) -> Array:
	"""Get skills that can be learned based on requirements"""
	var available: Array = []
	
	for skill in skills.values():
		if can_learn_skill(skill, character_stats, learned_skills):
			available.append(skill)
	
	return available

func can_learn_skill(skill: SkillNode, character_stats: CharacterStats, learned_skills: Array) -> bool:
	"""Check if a skill can be learned"""
	# Already maxed
	if skill.is_maxed():
		return false
	
	# Check level requirement
	if character_stats.character_level < skill.level_requirement:
		return false
	
	# Check required skills
	for required_skill_id in skill.required_skills:
		if required_skill_id not in learned_skills:
			return false
	
	# Check required stats
	for stat_name in skill.required_stats:
		var required_value = skill.required_stats[stat_name]
		var current_value = get_stat_value_from_character(character_stats, stat_name)
		if current_value < required_value:
			return false
	
	return true

func get_stat_value_from_character(character_stats: CharacterStats, stat_name: String) -> int:
	"""Helper to get stat value from character stats"""
	# Try each category
	for category in character_stats.get_stat_categories():
		if category.stats.has(stat_name):
			return category.stats[stat_name].get_total_value()
	return 0
