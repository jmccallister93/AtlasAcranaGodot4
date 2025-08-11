# StatCategory.gd
extends Resource
class_name StatCategory

@export var category_name: String
@export var description: String
@export var stats: Dictionary = {}  # stat_name -> StatData
@export var category_color: Color = Color.WHITE

func add_stat(stat_name: String, base_value: int, description: String = ""):
	var stat_data = StatData.new()
	stat_data.stat_name = stat_name
	stat_data.base_value = base_value
	stat_data.description = description
	stats[stat_name] = stat_data

func get_stat(stat_name: String) -> StatData:
	return stats.get(stat_name)

func get_all_stats() -> Dictionary:
	return stats.duplicate()
