extends Node
class_name TurnManager

signal turn_advanced(turn_number: int)
signal player_turn_started(player_id: int)

var current_turn: int = 1
var current_player: int = 1
var total_players: int = 2

func advance_turn():
	current_player += 1
	if current_player > total_players:
		current_player = 1
		current_turn += 1
		turn_advanced.emit(current_turn)
	
	player_turn_started.emit(current_player)

func end_current_turn():
	advance_turn()
