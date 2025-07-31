# Add this to your Main.gd script

extends Node2D  # or whatever your Main node type is

# Reference to the UI
@onready var game_ui: GameUI = $GameUI

func _ready():
	# Connect UI signals to your game logic
	if game_ui:
		game_ui.inventory_opened.connect(_on_inventory_opened)
		game_ui.character_sheet_opened.connect(_on_character_sheet_opened)
		game_ui.buildings_menu_opened.connect(_on_buildings_menu_opened)
		game_ui.research_opened.connect(_on_research_opened)
		game_ui.diplomacy_opened.connect(_on_diplomacy_opened)
		game_ui.settings_opened.connect(_on_settings_opened)

# Example: When a tile produces resources
func _on_tile_resource_harvested(resources_gained: Dictionary):
	for resource_type in resources_gained:
		game_ui.add_resources(resource_type, resources_gained[resource_type])

# Example: When player builds something
func try_build_structure(cost: Dictionary) -> bool:
	if game_ui.can_afford(cost):
		# Spend the resources
		for resource_type in cost:
			game_ui.spend_resources(resource_type, cost[resource_type])
		return true
	else:
		print("Not enough resources!")
		return false

# Example: End turn button pressed
func end_turn():
	game_ui.advance_turn()
	# Add your turn logic here
	process_end_of_turn()

func process_end_of_turn():
	# Example turn processing
	var resources_per_turn = {"food": 5, "gold": 10}
	for resource in resources_per_turn:
		game_ui.add_resources(resource, resources_per_turn[resource])

# UI Menu Callbacks
func _on_inventory_opened():
	print("Opening inventory system...")
	# Create and show inventory UI

func _on_character_sheet_opened():
	print("Opening character sheet...")
	# Create and show character UI

func _on_buildings_menu_opened():
	print("Opening building menu...")
	# Create and show building selection UI

func _on_research_opened():
	print("Opening research tree...")
	# Create and show research UI

func _on_diplomacy_opened():
	print("Opening diplomacy...")
	# Create and show diplomacy UI

func _on_settings_opened():
	print("Opening settings...")
	# Create and show settings UI

# Example: Connect to your tile system
func _on_tile_clicked(tile):
	# Example building cost
	var farm_cost = {"gold": 50, "wood": 20}
	
	if Input.is_action_pressed("build_farm"):  # Example action
		if try_build_structure(farm_cost):
			# Build the farm
			print("Farm built!")
		else:
			print("Cannot afford farm")
