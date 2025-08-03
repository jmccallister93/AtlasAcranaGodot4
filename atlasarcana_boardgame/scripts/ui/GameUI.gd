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
@onready var inventory_menu_scene: PackedScene = preload("res://scenes/ui/menus/InventoryMenu.tscn")
var inventory_menu: InventoryMenu

@onready var character_menu_scene: PackedScene = preload("res://scenes/ui/menus/CharacterMenu.tscn")
var character_menu: CharacterMenu

@onready var building_menu_scene: PackedScene = preload("res://scenes/ui/menus/BuildingMenu.tscn")
var building_menu: BuildingMenu

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

signal character_opened
signal character_closed

signal building_opened
signal building_closed



func _ready():
	setup_ui()
	connect_menu_buttons()
	inventory_menu = inventory_menu_scene.instantiate()
	add_child(inventory_menu)
	inventory_menu.hide()
	character_menu = character_menu_scene.instantiate()
	add_child(character_menu)
	character_menu.hide()
	building_menu = building_menu_scene.instantiate()
	add_child(building_menu)
	building_menu.hide()

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
	var button_container_width = 300  # Adjust based on number of buttons
	menu_buttons.position = Vector2((bar_size.x - button_container_width) / 2, 5)
	#menu_buttons.size = Vector2(button_container_width, bar_size.y - 10)

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



func close_all_menus():
	if inventory_menu and inventory_menu.visible:
		inventory_menu.hide()
		inventory_closed.emit()

	if character_menu and character_menu.visible:
		character_menu.hide()
		character_closed.emit()
	
	if building_menu and building_menu.visible:
		building_menu.hide()
		building_closed.emit()

	# Add other menus here as needed (buildings_menu, etc.)
	
# Menu button callbacks
func _on_inventory_button_pressed():
	"""Handle inventory button press"""
	if inventory_menu:
		if inventory_menu.visible:
			inventory_menu.hide()
			inventory_closed.emit()
			print("Hiding inventory...")
		else:
			close_all_menus()
			inventory_menu.show()
			inventory_opened.emit()
			print("Showing inventory...")

func _on_character_button_pressed():
	"""Handle character sheet button press"""
	if character_menu:
		if character_menu.visible:
			character_menu.hide()
			character_closed.emit()
			print("Hiding character...")
		else:
			close_all_menus()
			character_menu.show()
			character_opened.emit()
			print("Showing character...")

func _on_buildings_button_pressed():
	"""Handle buildings menu button press"""
	if building_menu:
		if building_menu.visible:
			building_menu.hide()
			building_closed.emit()
			print("Hiding character...")
		else:
			close_all_menus()
			building_menu.show()
			building_opened.emit()
			print("Showing character...")
