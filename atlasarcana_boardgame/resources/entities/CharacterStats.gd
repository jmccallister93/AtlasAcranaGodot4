# CharacterStats.gd
extends Resource
class_name CharacterStats

@export var character_name: String = "Character"
@export var max_stamina: int = 5
@export var max_movement_points: int = 3
@export var max_health: int = 10
@export var max_build: int = 3
# Add other base stats here

# You can even add stat calculation methods
func get_action_points() -> int:
	return max_stamina
