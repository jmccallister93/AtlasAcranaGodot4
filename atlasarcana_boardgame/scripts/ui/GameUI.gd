extends Control
class_name GameUI

# UI References - Top Bar
@onready var turn_label: Label = $TopBar/LeftSection/TurnInfo/TurnLabel
@onready var turn_subtext = $TopBar/LeftSection/TurnInfo/TurnSubtext
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

#Action Control
@onready var turn_manager = GameManager.turn_manager
@onready var action_control = $BottomBar/ActionControl
@onready var advance_turn_button = $BottomBar/ActionControl/AdvanceTurn
var current_turn: int = 1

#Character 
@onready var character = GameManager.character
@onready var character_stamina = Label.new()
@onready var character_stamina_button = Button.new()

# Signals for menu interactions
signal inventory_opened
signal inventory_closed

signal character_opened
signal character_closed

signal building_opened
signal building_closed

signal advance_turn_clicked
signal use_stamina_clicked

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
	get_turn()
	get_stamina()

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
	turn_label.text = "Turn Number"

	
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

	
#	Advance turn button setup
	action_control.position = Vector2(5, 5)
	advance_turn_button.text = "Advance"
	advance_turn_button.pressed.connect(GameManager.advance_turn)
	
	#Show stamina
	character_stamina.text = "Stamina: " + str(GameManager.get_current_stamina())
	character_stamina.position = Vector2(5,40)
	bottom_bar.add_child(character_stamina)
#	Use Stamina
	character_stamina_button.text = "Use"
	character_stamina_button.position = Vector2(100,35)
	bottom_bar.add_child(character_stamina_button)
	character_stamina_button.pressed.connect(GameManager.spend_stamina)

# Handle screen resize 
var _is_resizing = false

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
		inventory_menu.hide_menu()
		inventory_closed.emit()

	if character_menu and character_menu.visible:
		character_menu.hide_menu()
		character_closed.emit()
	
	if building_menu and building_menu.visible:
		building_menu.hide_menu()
		building_closed.emit()

	# Add other menus here as needed (buildings_menu, etc.)
	
# Menu button callbacks
func _on_inventory_button_pressed():
	"""Handle inventory button press"""
	if inventory_menu:
		if inventory_menu.visible:
			inventory_menu.hide_menu()
			inventory_closed.emit()
			print("Hiding inventory...")
		else:
			close_all_menus()
			inventory_menu.show_menu()
			inventory_opened.emit()
			print("Showing inventory...")

func _on_character_button_pressed():
	"""Handle character sheet button press"""
	if character_menu:
		if character_menu.visible:
			character_menu.hide_menu()
			character_closed.emit()
			print("Hiding character...")
		else:
			close_all_menus()
			character_menu.show_menu()
			character_opened.emit()
			print("Showing character...")

func _on_buildings_button_pressed():
	"""Handle buildings menu button press"""
	if building_menu:
		if building_menu.visible:
			building_menu.hide_menu()
			building_closed.emit()
			print("Hiding character...")
		else:
			close_all_menus()
			building_menu.show_menu()
			building_opened.emit()
			print("Showing character...")

#Turn related
func get_turn():
	GameManager.initial_turn.connect(_on_game_manager_initial_turn)
	GameManager.turn_advanced.connect(_on_game_manager_turn_advanced)
	

func _on_game_manager_initial_turn(turn: int) -> void:
	turn_subtext.text = str(turn)

func _on_game_manager_turn_advanced(turn: int) -> void:
	turn_subtext.text = str(turn)

func _on_advance_click():
	advance_turn_clicked.emit()

func get_stamina():
	GameManager.stamina_spent.connect(_on_game_manager_stamina_spent)

func _on_game_manager_stamina_spent(current_stamina: int) -> void:
	# Actually update the stamina display instead of just emitting a signal
	character_stamina.text = "Stamina: " + str(current_stamina)
	use_stamina_clicked.emit()  
