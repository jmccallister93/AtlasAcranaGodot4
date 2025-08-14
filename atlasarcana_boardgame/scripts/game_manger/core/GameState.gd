# GameState.gd
extends Resource
class_name GameState

signal state_changed(property_name: String, old_value, new_value)
signal game_phase_changed(old_phase: String, new_phase: String)

# ═══════════════════════════════════════════════════════════
# CORE GAME STATE
# ═══════════════════════════════════════════════════════════

@export var current_turn: int = 1 :
	set(value):
		var old_value = current_turn
		current_turn = value
		state_changed.emit("current_turn", old_value, value)

@export var game_phase: String = "exploration" :
	set(value):
		var old_value = game_phase
		game_phase = value
		game_phase_changed.emit(old_value, value)
		state_changed.emit("game_phase", old_value, value)

@export var game_started_at: String = ""
@export var total_play_time: float = 0.0
@export var last_save_time: String = ""

# ═══════════════════════════════════════════════════════════
# PLAYER STATE
# ═══════════════════════════════════════════════════════════

@export var player_data: Dictionary = {}
@export var character_position: Vector2i = Vector2i.ZERO
@export var character_stats: Dictionary = {}
@export var current_action_points: int = 3
@export var max_action_points: int = 3

# ═══════════════════════════════════════════════════════════
# RESOURCE STATE
# ═══════════════════════════════════════════════════════════

@export var resources: Dictionary = {
	"wood": 0,
	"stone": 0,
	"food": 0,
	"metal": 0
}

@export var resource_income: Dictionary = {}
@export var resource_storage_limits: Dictionary = {}

# ═══════════════════════════════════════════════════════════
# WORLD STATE
# ═══════════════════════════════════════════════════════════

@export var map_size: Vector2i = Vector2i(32, 32)
@export var explored_tiles: Array[Vector2i] = []
@export var discovered_locations: Array[String] = []
@export var completed_quests: Array[String] = []
@export var active_quests: Array[String] = []

# ═══════════════════════════════════════════════════════════
# BUILDING STATE
# ═══════════════════════════════════════════════════════════

@export var buildings: Array[Dictionary] = []
@export var building_count_by_type: Dictionary = {}

# ═══════════════════════════════════════════════════════════
# INVENTORY STATE
# ═══════════════════════════════════════════════════════════

@export var inventory_items: Array[Dictionary] = []
@export var inventory_capacity: int = 50

# ═══════════════════════════════════════════════════════════
# WARBAND STATE
# ═══════════════════════════════════════════════════════════

@export var warband_members: Array[Dictionary] = []
@export var warband_capacity: int = 10

# ═══════════════════════════════════════════════════════════
# GAME SETTINGS & PREFERENCES
# ═══════════════════════════════════════════════════════════

@export var difficulty_level: String = "normal"
@export var auto_save_enabled: bool = true
@export var auto_save_interval: int = 300  # 5 minutes
@export var game_speed: float = 1.0

func _init():
	"""Initialize default game state"""
	if game_started_at == "":
		game_started_at = Time.get_datetime_string_from_system()
	
	_initialize_default_resources()

# ═══════════════════════════════════════════════════════════
# RESOURCE MANAGEMENT
# ═══════════════════════════════════════════════════════════

func _initialize_default_resources():
	"""Initialize default resource amounts"""
	if resources.is_empty():
		resources = {
			"wood": 10,
			"stone": 5,
			"food": 15,
			"metal": 0
		}

func set_resource(resource_name: String, amount: int):
	"""Set a resource to a specific amount"""
	var old_amount = resources.get(resource_name, 0)
	resources[resource_name] = amount
	state_changed.emit("resource_" + resource_name, old_amount, amount)

func add_resource(resource_name: String, amount: int):
	"""Add to a resource amount"""
	var current = resources.get(resource_name, 0)
	set_resource(resource_name, current + amount)

func spend_resource(resource_name: String, amount: int) -> bool:
	"""Spend a resource if available"""
	var current = resources.get(resource_name, 0)
	if current >= amount:
		set_resource(resource_name, current - amount)
		return true
	return false

func get_resource(resource_name: String) -> int:
	"""Get current amount of a resource"""
	return resources.get(resource_name, 0)

func has_resource(resource_name: String, amount: int) -> bool:
	"""Check if we have enough of a resource"""
	return get_resource(resource_name) >= amount

# ═══════════════════════════════════════════════════════════
# CHARACTER STATE MANAGEMENT
# ═══════════════════════════════════════════════════════════

func set_character_position(new_position: Vector2i):
	"""Update character position"""
	var old_position = character_position
	character_position = new_position
	state_changed.emit("character_position", old_position, new_position)

func set_action_points(points: int):
	"""Set current action points"""
	var old_points = current_action_points
	current_action_points = clamp(points, 0, max_action_points)
	state_changed.emit("current_action_points", old_points, current_action_points)

func spend_action_points(amount: int = 1) -> bool:
	"""Spend action points"""
	if current_action_points >= amount:
		set_action_points(current_action_points - amount)
		return true
	return false

func refresh_action_points():
	"""Refresh action points to maximum"""
	set_action_points(max_action_points)

# ═══════════════════════════════════════════════════════════
# WORLD STATE MANAGEMENT
# ═══════════════════════════════════════════════════════════

func add_explored_tile(tile_position: Vector2i):
	"""Mark a tile as explored"""
	if tile_position not in explored_tiles:
		explored_tiles.append(tile_position)
		state_changed.emit("explored_tiles", null, tile_position)

func is_tile_explored(tile_position: Vector2i) -> bool:
	"""Check if a tile has been explored"""
	return tile_position in explored_tiles

func add_discovered_location(location_name: String):
	"""Add a discovered location"""
	if location_name not in discovered_locations:
		discovered_locations.append(location_name)
		state_changed.emit("discovered_locations", null, location_name)

func complete_quest(quest_id: String):
	"""Mark a quest as completed"""
	if quest_id in active_quests:
		active_quests.erase(quest_id)
	
	if quest_id not in completed_quests:
		completed_quests.append(quest_id)
		state_changed.emit("quest_completed", null, quest_id)

func start_quest(quest_id: String):
	"""Start a new quest"""
	if quest_id not in active_quests and quest_id not in completed_quests:
		active_quests.append(quest_id)
		state_changed.emit("quest_started", null, quest_id)

# ═══════════════════════════════════════════════════════════
# BUILDING STATE MANAGEMENT
# ═══════════════════════════════════════════════════════════

func add_building(building_data: Dictionary):
	"""Add a building to the state"""
	buildings.append(building_data)
	
	var building_type = building_data.get("type", "unknown")
	building_count_by_type[building_type] = building_count_by_type.get(building_type, 0) + 1
	
	state_changed.emit("buildings", null, building_data)

func remove_building(building_id: String):
	"""Remove a building from the state"""
	for i in range(buildings.size()):
		if buildings[i].get("id") == building_id:
			var building_data = buildings[i]
			buildings.remove_at(i)
			
			var building_type = building_data.get("type", "unknown")
			if building_count_by_type.has(building_type):
				building_count_by_type[building_type] -= 1
				if building_count_by_type[building_type] <= 0:
					building_count_by_type.erase(building_type)
			
			state_changed.emit("building_removed", building_data, null)
			break

func get_building_count(building_type: String) -> int:
	"""Get count of buildings of a specific type"""
	return building_count_by_type.get(building_type, 0)

# ═══════════════════════════════════════════════════════════
# SAVE/LOAD FUNCTIONALITY
# ═══════════════════════════════════════════════════════════

func save_to_file(file_path: String) -> bool:
	"""Save game state to file"""
	update_save_metadata()
	
	var save_file = FileAccess.open(file_path, FileAccess.WRITE)
	if save_file == null:
		print("GameState: Failed to open save file for writing: ", file_path)
		return false
	
	var save_data = get_save_data()
	save_file.store_string(JSON.stringify(save_data))
	save_file.close()
	
	print("GameState: Game saved successfully to: ", file_path)
	return true

func load_from_file(file_path: String) -> bool:
	"""Load game state from file"""
	if not FileAccess.file_exists(file_path):
		print("GameState: Save file does not exist: ", file_path)
		return false
	
	var save_file = FileAccess.open(file_path, FileAccess.READ)
	if save_file == null:
		print("GameState: Failed to open save file for reading: ", file_path)
		return false
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("GameState: Failed to parse save file JSON")
		return false
	
	apply_save_data(json.data)
	print("GameState: Game loaded successfully from: ", file_path)
	return true

func get_save_data() -> Dictionary:
	"""Get all state data for saving"""
	return {
		"version": "1.0",
		"current_turn": current_turn,
		"game_phase": game_phase,
		"game_started_at": game_started_at,
		"total_play_time": total_play_time,
		"last_save_time": last_save_time,
		"player_data": player_data,
		"character_position": {"x": character_position.x, "y": character_position.y},
		"character_stats": character_stats,
		"current_action_points": current_action_points,
		"max_action_points": max_action_points,
		"resources": resources,
		"resource_income": resource_income,
		"resource_storage_limits": resource_storage_limits,
		"map_size": {"x": map_size.x, "y": map_size.y},
		"explored_tiles": _vector2i_array_to_dict_array(explored_tiles),
		"discovered_locations": discovered_locations,
		"completed_quests": completed_quests,
		"active_quests": active_quests,
		"buildings": buildings,
		"building_count_by_type": building_count_by_type,
		"inventory_items": inventory_items,
		"inventory_capacity": inventory_capacity,
		"warband_members": warband_members,
		"warband_capacity": warband_capacity,
		"difficulty_level": difficulty_level,
		"auto_save_enabled": auto_save_enabled,
		"auto_save_interval": auto_save_interval,
		"game_speed": game_speed
	}

func apply_save_data(save_data: Dictionary):
	"""Apply loaded save data to current state"""
	current_turn = save_data.get("current_turn", 1)
	game_phase = save_data.get("game_phase", "exploration")
	game_started_at = save_data.get("game_started_at", "")
	total_play_time = save_data.get("total_play_time", 0.0)
	last_save_time = save_data.get("last_save_time", "")
	player_data = save_data.get("player_data", {})
	
	var char_pos = save_data.get("character_position", {"x": 0, "y": 0})
	character_position = Vector2i(char_pos.x, char_pos.y)
	
	character_stats = save_data.get("character_stats", {})
	current_action_points = save_data.get("current_action_points", 3)
	max_action_points = save_data.get("max_action_points", 3)
	resources = save_data.get("resources", {})
	resource_income = save_data.get("resource_income", {})
	resource_storage_limits = save_data.get("resource_storage_limits", {})
	
	var map_size_data = save_data.get("map_size", {"x": 32, "y": 32})
	map_size = Vector2i(map_size_data.x, map_size_data.y)
	
	explored_tiles = _dict_array_to_vector2i_array(save_data.get("explored_tiles", []))
	discovered_locations = save_data.get("discovered_locations", [])
	completed_quests = save_data.get("completed_quests", [])
	active_quests = save_data.get("active_quests", [])
	buildings = save_data.get("buildings", [])
	building_count_by_type = save_data.get("building_count_by_type", {})
	inventory_items = save_data.get("inventory_items", [])
	inventory_capacity = save_data.get("inventory_capacity", 50)
	warband_members = save_data.get("warband_members", [])
	warband_capacity = save_data.get("warband_capacity", 10)
	difficulty_level = save_data.get("difficulty_level", "normal")
	auto_save_enabled = save_data.get("auto_save_enabled", true)
	auto_save_interval = save_data.get("auto_save_interval", 300)
	game_speed = save_data.get("game_speed", 1.0)

func update_save_metadata():
	"""Update metadata before saving"""
	last_save_time = Time.get_datetime_string_from_system()
	#total_play_time += get_process_delta_time()

# ═══════════════════════════════════════════════════════════
# HELPER METHODS
# ═══════════════════════════════════════════════════════════

func _vector2i_array_to_dict_array(vec_array: Array[Vector2i]) -> Array:
	"""Convert Vector2i array to dictionary array for JSON serialization"""
	var dict_array = []
	for vec in vec_array:
		dict_array.append({"x": vec.x, "y": vec.y})
	return dict_array

func _dict_array_to_vector2i_array(dict_array: Array) -> Array[Vector2i]:
	"""Convert dictionary array back to Vector2i array"""
	var vec_array: Array[Vector2i] = []
	for dict_item in dict_array:
		vec_array.append(Vector2i(dict_item.x, dict_item.y))
	return vec_array

# ═══════════════════════════════════════════════════════════
# VALIDATION & DEBUG
# ═══════════════════════════════════════════════════════════

func validate_state() -> bool:
	"""Validate that the game state is consistent"""
	# Check basic constraints
	if current_action_points < 0 or current_action_points > max_action_points:
		print("GameState: Invalid action points: ", current_action_points, "/", max_action_points)
		return false
	
	if current_turn < 1:
		print("GameState: Invalid turn number: ", current_turn)
		return false
	
	# Check resource constraints
	for resource_name in resources:
		if resources[resource_name] < 0:
			print("GameState: Negative resource amount: ", resource_name, "=", resources[resource_name])
			return false
	
	return true

func debug_print_state():
	"""Debug print current game state"""
	print("=== GameState Debug ===")
	print("Turn: ", current_turn)
	print("Phase: ", game_phase)
	print("Character Position: ", character_position)
	print("Action Points: ", current_action_points, "/", max_action_points)
	print("Resources: ", resources)
	print("Buildings: ", buildings.size())
	print("Explored Tiles: ", explored_tiles.size())
	print("Active Quests: ", active_quests.size())
	print("Completed Quests: ", completed_quests.size())
	print("======================")
