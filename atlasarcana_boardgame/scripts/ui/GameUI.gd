extends Control
class_name GameUI

# UI References - Top Bar
@onready var turn_label: Label = $TopBar/LeftSection/TurnInfo/TurnLabel
@onready var resources_container: HBoxContainer = $TopBar/CenterSection/ResourcesContainer
@onready var character_info: VBoxContainer = $TopBar/RightSection/CharacterInfo

# UI References - Bottom Bar
@onready var menu_buttons_container: HBoxContainer = $BottomBar/MenuButtons

# UI References - Resource Labels
@onready var gold_label: Label = $TopBar/CenterSection/ResourcesContainer/GoldContainer/GoldLabel
@onready var food_label: Label = $TopBar/CenterSection/ResourcesContainer/FoodContainer/FoodLabel
@onready var wood_label: Label = $TopBar/CenterSection/ResourcesContainer/WoodContainer/WoodLabel
@onready var stone_label: Label = $TopBar/CenterSection/ResourcesContainer/StoneContainer/StoneLabel

# UI References - Character Stats
@onready var character_name_label: Label = $TopBar/RightSection/CharacterInfo/NameLabel
@onready var character_level_label: Label = $TopBar/RightSection/CharacterInfo/StatsContainer/LevelLabel
@onready var character_hp_label: Label = $TopBar/RightSection/CharacterInfo/StatsContainer/HPLabel

#Menus
@onready var inventory_menu = get_parent().get_node_or_null("InventoryMenu")

# Game Data (Placeholder values)
var current_turn: int = 1
var player_resources: Dictionary = {
	"gold": 1250,
	"food": 45,
	"wood": 78,
	"stone": 32
}
var character_data: Dictionary = {
	"name": "Hero",
	"level": 5,
	"current_hp": 85,
	"max_hp": 100,
	"experience": 2340,
	"next_level_exp": 3000
}

# Signals for menu interactions
signal inventory_opened
signal inventory_closed

signal character_sheet_opened
signal buildings_menu_opened
signal research_opened
signal diplomacy_opened
signal settings_opened

func _ready():
	setup_ui()
	connect_menu_buttons()
	update_all_displays()

func setup_ui():
	"""Initialize UI styling and properties"""
	# Get viewport size for positioning
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Set GameUI size manually
	size = viewport_size
	position = Vector2.ZERO
	
	# Position and size the TopBar
	var top_bar = $TopBar
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(viewport_size.x, 80)
	top_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Position and size the BottomBar  
	var bottom_bar = $BottomBar
	bottom_bar.position = Vector2(0, viewport_size.y - 60)
	bottom_bar.size = Vector2(viewport_size.x, 60)
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Position the sections within TopBar
	setup_top_bar_layout()
	
	# Position the buttons within BottomBar
	setup_bottom_bar_layout()
	
	# Make sure UI doesn't block mouse input to the game world (except for the bars)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup_top_bar_layout():
	"""Position elements within the top bar"""
	var top_bar = $TopBar
	var bar_size = top_bar.size
	
	# Left section (Turn info)
	var left_section = $TopBar/LeftSection
	left_section.position = Vector2(10, 10)
	left_section.size = Vector2(200, bar_size.y - 20)
	
	# Center section (Resources)
	var center_section = $TopBar/CenterSection  
	var center_width = 400
	center_section.position = Vector2((bar_size.x - center_width) / 2, 10)
	center_section.size = Vector2(center_width, bar_size.y - 20)
	
	# Right section (Character info)
	var right_section = $TopBar/RightSection
	var right_width = 250
	right_section.position = Vector2(bar_size.x - right_width - 10, 10)
	right_section.size = Vector2(right_width, bar_size.y - 20)

func setup_bottom_bar_layout():
	"""Position elements within the bottom bar"""
	var bottom_bar = $BottomBar
	var bar_size = bottom_bar.size
	
	# Center the menu buttons
	var menu_buttons = $BottomBar/MenuButtons
	var button_container_width = 600  # Adjust based on number of buttons
	menu_buttons.position = Vector2((bar_size.x - button_container_width) / 2, 5)
	menu_buttons.size = Vector2(button_container_width, bar_size.y - 10)

# Handle screen resize (with recursion protection)
var _is_resizing = false
func _notification(what):
	if what == NOTIFICATION_RESIZED and not _is_resizing:
		_is_resizing = true
		setup_ui()
		_is_resizing = false

func connect_menu_buttons():
	"""Connect all menu button signals"""
	var inventory_btn = $BottomBar/MenuButtons/InventoryButton
	var character_btn = $BottomBar/MenuButtons/CharacterButton
	var buildings_btn = $BottomBar/MenuButtons/BuildingsButton
	var research_btn = $BottomBar/MenuButtons/ResearchButton
	var diplomacy_btn = $BottomBar/MenuButtons/DiplomacyButton
	var settings_btn = $BottomBar/MenuButtons/SettingsButton
	
	inventory_btn.pressed.connect(_on_inventory_button_pressed)
	character_btn.pressed.connect(_on_character_button_pressed)
	buildings_btn.pressed.connect(_on_buildings_button_pressed)
	research_btn.pressed.connect(_on_research_button_pressed)
	diplomacy_btn.pressed.connect(_on_diplomacy_button_pressed)
	settings_btn.pressed.connect(_on_settings_button_pressed)

func update_all_displays():
	"""Update all UI elements with current data"""
	update_turn_display()
	update_resources_display()
	update_character_display()

func update_turn_display():
	"""Update the turn counter"""
	turn_label.text = "Turn: %d" % current_turn

func update_resources_display():
	"""Update all resource displays"""
	gold_label.text = str(player_resources.gold)
	food_label.text = str(player_resources.food)
	wood_label.text = str(player_resources.wood)
	stone_label.text = str(player_resources.stone)

func update_character_display():
	"""Update character information display"""
	character_name_label.text = character_data.name
	character_level_label.text = "Lv.%d" % character_data.level
	character_hp_label.text = "%d/%d HP" % [character_data.current_hp, character_data.max_hp]

# Public methods for updating game state
func advance_turn():
	"""Advance to the next turn"""
	current_turn += 1
	update_turn_display()

func add_resources(resource_type: String, amount: int):
	"""Add resources to the player's stockpile"""
	if resource_type in player_resources:
		player_resources[resource_type] += amount
		update_resources_display()

func spend_resources(resource_type: String, amount: int) -> bool:
	"""Spend resources if available"""
	if resource_type in player_resources and player_resources[resource_type] >= amount:
		player_resources[resource_type] -= amount
		update_resources_display()
		return true
	return false

func update_character_hp(new_hp: int):
	"""Update character's current HP"""
	character_data.current_hp = clamp(new_hp, 0, character_data.max_hp)
	update_character_display()

func level_up_character():
	"""Handle character leveling up"""
	character_data.level += 1
	character_data.max_hp += 10  # Example: +10 HP per level
	character_data.current_hp = character_data.max_hp  # Full heal on level up
	update_character_display()

# Menu button callbacks
func _on_inventory_button_pressed():
	"""Handle inventory button press"""
	if inventory_menu:
		if inventory_menu.visible:
			inventory_menu.hide()
			inventory_closed.emit()
			print("Hiding inventory...")
		else:
			inventory_menu.show()
			inventory_opened.emit()
			print("Showing inventory...")

func _on_character_button_pressed():
	"""Handle character sheet button press"""
	print("Opening Character Sheet...")
	character_sheet_opened.emit()

func _on_buildings_button_pressed():
	"""Handle buildings menu button press"""
	print("Opening Buildings Menu...")
	buildings_menu_opened.emit()

func _on_research_button_pressed():
	"""Handle research button press"""
	print("Opening Research Tree...")
	research_opened.emit()

func _on_diplomacy_button_pressed():
	"""Handle diplomacy button press"""
	print("Opening Diplomacy...")
	diplomacy_opened.emit()

func _on_settings_button_pressed():
	"""Handle settings button press"""
	print("Opening Settings...")
	settings_opened.emit()

# Utility methods for external access
func get_current_turn() -> int:
	return current_turn

func get_resource_amount(resource_type: String) -> int:
	return player_resources.get(resource_type, 0)

func can_afford(costs: Dictionary) -> bool:
	"""Check if player can afford something"""
	for resource in costs:
		if get_resource_amount(resource) < costs[resource]:
			return false
	return true

func get_character_data() -> Dictionary:
	return character_data.duplicate()

# Example method for testing - you can remove this later
func _input(event):
	"""Test input handling - remove in production"""
	if event.is_action_pressed("ui_accept"):  # Space bar
		advance_turn()
	elif event.is_action_pressed("ui_select"):  # Enter
		add_resources("gold", 100)
		add_resources("food", 10)
