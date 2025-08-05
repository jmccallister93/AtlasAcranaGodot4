extends Node
class_name GameManager

signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal game_state_changed(new_state: GameState)

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	CHARACTER_SELECTION,
	BUILDING_PLACEMENT
}

var current_state: GameState = GameState.MENU
var current_turn: int = 1
var current_player: int = 1
var total_players: int = 2

# System references
var map_manager: MapManager
var turn_manager: TurnManager
var movement_system: MovementSystem
var building_system: BuildingSystem
#var economy_system: EconomySystem

func _ready():
	# Get system references
	map_manager = get_node("../MapManager")
	turn_manager = get_node("../TurnManager")
	
	# Create subsystems
	create_game_systems()
	
	# Connect signals
	connect_game_signals()

func create_game_systems():
	movement_system = MovementSystem.new()
	movement_system.name = "MovementSystem"
	add_child(movement_system)
	
	building_system = BuildingSystem.new()
	building_system.name = "BuildingSystem"
	add_child(building_system)
	
	#economy_system = EconomySystem.new()
	#economy_system.name = "EconomySystem"
	#add_child(economy_system)

func connect_game_signals():
	if turn_manager:
		turn_manager.turn_advanced.connect(_on_turn_advanced)
	if map_manager:
		map_manager.map_generated.connect(_on_map_generated)

func start_new_game():
	change_state(GameState.PLAYING)
	map_manager.generate_map(32, 24)  # 32x24 tile map
	current_turn = 1
	turn_started.emit(current_turn)

func change_state(new_state: GameState):
	current_state = new_state
	game_state_changed.emit(new_state)

func _on_turn_advanced(turn_number: int):
	current_turn = turn_number
	turn_started.emit(current_turn)

func _on_map_generated():
	print("Map generation complete!")
