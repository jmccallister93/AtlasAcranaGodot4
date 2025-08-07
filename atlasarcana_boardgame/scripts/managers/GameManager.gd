extends Node

signal turn_advanced(turn_number: int)
signal initial_turn(turn_number: int)
signal action_points_spent(current_action_points: int)

var turn_manager: TurnManager
var map_manager: MapManager
var character: Character
var movement_manager: MovementManager

func _ready():
	start_new_game()

func start_new_game():
	turn_manager = TurnManager.new()
	map_manager = MapManager.new()
	map_manager.generate_map(32, 32)
	movement_manager = MovementManager.new()
	character = Character.new()
#	Initalize character stats
	var character_stats = CharacterStats.new()
	character.stats = character_stats
	character.initialize_from_stats()
	
	
	add_child(turn_manager)
	add_child(map_manager)
	add_child(character)
	add_child(movement_manager)
	
	movement_manager.initialize(character, map_manager) 
	
	connect_signals()

func connect_signals():
#	Turns
	turn_manager.initial_turn.connect(_on_turn_manager_initial_turn)
	turn_manager.turn_advanced.connect(_on_turn_manager_turn_advanced)
#	Character
	character.action_points_spent.connect(_on_character_action_points_spent)
	#Map
	map_manager.movement_requested.connect(_on_movement_requested)

func _on_turn_manager_initial_turn(turn_number: int):
	initial_turn.emit(turn_number)

func _on_turn_manager_turn_advanced(turn_number: int):
	turn_advanced.emit(turn_number)
	character.refresh_turn_resources()
	
func _on_character_action_points_spent(current_action_points: int):
	action_points_spent.emit(current_action_points)
	
func _on_movement_requested(target_grid_pos: Vector2i):
	movement_manager.attempt_move_to(target_grid_pos)

# Public methods to interact with managers
func advance_turn():
	turn_manager.advance_turn()

func spend_action_points():
	character.spend_action_points()
	
func get_current_action_points() -> int:
	return character.current_action_points
