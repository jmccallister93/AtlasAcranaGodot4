extends Node

signal turn_advanced(turn_number: int)
signal initial_turn(turn_number: int)

var turn_manager: TurnManager
var map_manager: MapManager

var current_state
func _ready():
	#Start game
	start_new_game()

func start_new_game():
	turn_manager = TurnManager.new()
	map_manager = MapManager.new()
	map_manager.generate_map(32, 32)
	add_child(turn_manager)
	add_child(map_manager)
