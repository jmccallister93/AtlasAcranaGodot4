# StatData.gd
extends Resource
class_name StatData

@export var stat_name: String
@export var base_value: int = 0
@export var equipment_modifier: int = 0
@export var skill_modifier: int = 0
@export var temporary_modifier: int = 0
@export var description: String = ""

func get_total_value() -> int:
	return base_value + equipment_modifier + skill_modifier + temporary_modifier

func set_equipment_modifier(value: int):
	equipment_modifier = value

func set_skill_modifier(value: int):
	skill_modifier = value

func add_temporary_modifier(value: int):
	temporary_modifier += value

func clear_temporary_modifiers():
	temporary_modifier = 0
