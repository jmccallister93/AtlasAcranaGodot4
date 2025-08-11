# SkillManager.gd
extends Node
class_name SkillManager

signal skill_learned(skill: SkillNode)
signal skill_unlearned(skill: SkillNode)
signal skill_points_changed(current_points: int)

@export var available_skill_points: int = 0
var skill_trees: Dictionary = {}  # tree_name -> SkillTree
var learned_skills: Array = []  # Array of skill IDs
var character_stats: EnhancedCharacterStats

func _init():
	initialize_skill_trees()

func initialize_skill_trees():
	"""Initialize all skill trees"""
	create_combat_tree()
	create_leadership_tree()
	create_exploration_tree()

func create_combat_tree():
	"""Create the combat skill tree"""
	var combat_tree = SkillTree.new()
	combat_tree.tree_name = "Combat"
	combat_tree.tree_description = "Skills focused on combat prowess"
	combat_tree.tree_color = Color.RED
	
	# Weapon Mastery
	var weapon_mastery = SkillNode.new()
	weapon_mastery.skill_id = "weapon_mastery"
	weapon_mastery.skill_name = "Weapon Mastery"
	weapon_mastery.description = "Increases attack damage"
	weapon_mastery.max_level = 5
	weapon_mastery.stat_modifiers_per_level = {"Attack": 3}
	weapon_mastery.tree_position = Vector2(100, 100)
	combat_tree.add_skill(weapon_mastery)
	
	# Armor Training
	var armor_training = SkillNode.new()
	armor_training.skill_id = "armor_training"
	armor_training.skill_name = "Armor Training"
	armor_training.description = "Increases defense"
	armor_training.max_level = 5
	armor_training.stat_modifiers_per_level = {"Defense": 2}
	armor_training.tree_position = Vector2(200, 100)
	combat_tree.add_skill(armor_training)
	
	# Critical Strike
	var critical_strike = SkillNode.new()
	critical_strike.skill_id = "critical_strike"
	critical_strike.skill_name = "Critical Strike"
	critical_strike.description = "Increases critical chance and damage"
	critical_strike.max_level = 3
	critical_strike.required_skills = ["weapon_mastery"]
	critical_strike.stat_modifiers_per_level = {"Critical_Chance": 2, "Critical_Damage": 10}
	critical_strike.tree_position = Vector2(150, 200)
	combat_tree.add_skill(critical_strike)
	
	skill_trees["Combat"] = combat_tree

func create_leadership_tree():
	"""Create the leadership skill tree"""
	var leadership_tree = SkillTree.new()
	leadership_tree.tree_name = "Leadership"
	leadership_tree.tree_description = "Skills focused on warband management"
	leadership_tree.tree_color = Color.BLUE
	
	# Natural Leader
	var natural_leader = SkillNode.new()
	natural_leader.skill_id = "natural_leader"
	natural_leader.skill_name = "Natural Leader"
	natural_leader.description = "Improves leadership capability"
	natural_leader.max_level = 5
	natural_leader.stat_modifiers_per_level = {"Leadership": 2}
	natural_leader.tree_position = Vector2(100, 100)
	leadership_tree.add_skill(natural_leader)
	
	# Recruiter
	var recruiter = SkillNode.new()
	recruiter.skill_id = "recruiter"
	recruiter.skill_name = "Recruiter"
	recruiter.description = "Better at finding and recruiting units"
	recruiter.max_level = 3
	recruiter.stat_modifiers_per_level = {"Recruitment": 2}
	recruiter.tree_position = Vector2(200, 100)
	leadership_tree.add_skill(recruiter)
	
	# Inspiring Presence
	var inspiring_presence = SkillNode.new()
	inspiring_presence.skill_id = "inspiring_presence"
	inspiring_presence.skill_name = "Inspiring Presence"
	inspiring_presence.description = "Boosts warband morale"
	inspiring_presence.max_level = 3
	inspiring_presence.required_skills = ["natural_leader"]
	inspiring_presence.stat_modifiers_per_level = {"Morale_Bonus": 5}
	inspiring_presence.tree_position = Vector2(150, 200)
	leadership_tree.add_skill(inspiring_presence)
	
	skill_trees["Leadership"] = leadership_tree

func create_exploration_tree():
	"""Create the exploration skill tree"""
	var exploration_tree = SkillTree.new()
	exploration_tree.tree_name = "Exploration"
	exploration_tree.tree_description = "Skills focused on world exploration"
	exploration_tree.tree_color = Color.GREEN
	
	# Pathfinding
	var pathfinding = SkillNode.new()
	pathfinding.skill_id = "pathfinding"
	pathfinding.skill_name = "Pathfinding"
	pathfinding.description = "Increases movement range"
	pathfinding.max_level = 5
	pathfinding.stat_modifiers_per_level = {"Movement": 2}
	pathfinding.tree_position = Vector2(100, 100)
	exploration_tree.add_skill(pathfinding)
	
	# Engineering
	var engineering = SkillNode.new()
	engineering.skill_id = "engineering"
	engineering.skill_name = "Engineering"
	engineering.description = "Improves building capabilities"
	engineering.max_level = 5
	engineering.stat_modifiers_per_level = {"Build": 1}
	engineering.tree_position = Vector2(200, 100)
	exploration_tree.add_skill(engineering)
	
	# Eagle Eye
	var eagle_eye = SkillNode.new()
	eagle_eye.skill_id = "eagle_eye"
	eagle_eye.skill_name = "Eagle Eye"
	eagle_eye.description = "Increases vision range and interaction range"
	eagle_eye.max_level = 3
	eagle_eye.stat_modifiers_per_level = {"Vision_Range": 1, "Interaction_Range": 1}
	eagle_eye.tree_position = Vector2(150, 200)
	exploration_tree.add_skill(eagle_eye)
	
	skill_trees["Exploration"] = exploration_tree

func set_character_stats(stats: EnhancedCharacterStats):
	"""Set the character stats reference"""
	character_stats = stats

func learn_skill(skill_id: String) -> bool:
	"""Learn a skill"""
	var skill = find_skill_by_id(skill_id)
	if not skill:
		return false
	
	# Check if we can learn it
	var tree = skill_trees[skill.tree_category]
	if not tree.can_learn_skill(skill, character_stats, learned_skills):
		return false
	
	# Check skill points
	if available_skill_points < skill.skill_point_cost:
		return false
	
	# Learn the skill
	skill.level_up()
	available_skill_points -= skill.skill_point_cost
	
	if not skill.skill_id in learned_skills:
		learned_skills.append(skill.skill_id)
	
	skill_learned.emit(skill)
	skill_points_changed.emit(available_skill_points)
	return true

func unlearn_skill(skill_id: String) -> bool:
	"""Unlearn a skill (for respec)"""
	var skill = find_skill_by_id(skill_id)
	if not skill or not skill.is_learned():
		return false
	
	# Check if other skills depend on this one
	if has_dependent_skills(skill_id):
		return false
	
	skill.level_down()
	available_skill_points += skill.skill_point_cost
	
	if skill.current_level == 0:
		learned_skills.erase(skill.skill_id)
	
	skill_unlearned.emit(skill)
	skill_points_changed.emit(available_skill_points)
	return true

func has_dependent_skills(skill_id: String) -> bool:
	"""Check if any learned skills depend on this skill"""
	for tree in skill_trees.values():
		for skill in tree.get_learned_skills():
			if skill_id in skill.required_skills:
				return true
	return false

func find_skill_by_id(skill_id: String) -> SkillNode:
	"""Find a skill by ID across all trees"""
	for tree in skill_trees.values():
		var skill = tree.get_skill(skill_id)
		if skill:
			return skill
	return null

func get_skill_tree(tree_name: String) -> SkillTree:
	"""Get a skill tree by name"""
	return skill_trees.get(tree_name)

func get_all_skill_trees() -> Array:
	"""Get all skill trees"""
	var trees: Array = []
	for tree in skill_trees.values():
		trees.append(tree)
	return trees

func get_total_stat_modifiers() -> Dictionary:
	"""Get total stat modifiers from all learned skills"""
	var total_modifiers = {}
	
	for tree in skill_trees.values():
		for skill in tree.get_learned_skills():
			var skill_mods = skill.get_stat_modifiers()
			for stat_name in skill_mods:
				if not total_modifiers.has(stat_name):
					total_modifiers[stat_name] = 0
				total_modifiers[stat_name] += skill_mods[stat_name]
	
	return total_modifiers

func add_skill_points(points: int):
	"""Add skill points"""
	available_skill_points += points
	skill_points_changed.emit(available_skill_points)

func get_available_skill_points() -> int:
	"""Get current available skill points"""
	return available_skill_points
