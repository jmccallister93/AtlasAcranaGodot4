extends Node
class_name TurnManager

signal initial_turn(turn_number: int)
signal turn_advanced(turn_number: int)
signal player_turn_started(player_id: int)

var current_turn: int = 1
var current_player: int = 1

func advance_turn():
	current_turn += 1
	turn_advanced.emit(current_turn)
	
func emit_initial_turn():
	initial_turn.emit(current_turn)

func _ready():
	call_deferred("emit_initial_turn")
	
