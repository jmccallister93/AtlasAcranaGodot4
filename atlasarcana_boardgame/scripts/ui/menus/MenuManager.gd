extends Node
class_name MenuManager

# Menu scene paths (will load these when scenes exist)
#const INVENTORY_SCENE_PATH = "res://ui/menus/InventoryMenu.tscn"
#const CHARACTER_SCENE_PATH = "res://ui/menus/CharacterMenu.tscn"
#const BUILDINGS_SCENE_PATH = "res://ui/menus/BuildingsMenu.tscn"
#const RESEARCH_SCENE_PATH = "res://ui/menus/ResearchMenu.tscn"
#const DIPLOMACY_SCENE_PATH = "res://ui/menus/DiplomacyMenu.tscn"
#const SETTINGS_SCENE_PATH = "res://ui/menus/SettingsMenu.tscn"

# Container for menus (should be a CanvasLayer for proper layering)
var menu_container: CanvasLayer 

# Currently open menus (track multiple if needed)
var open_menus: Dictionary = {}
var menu_stack: Array[Control] = []  # For tracking menu order

# Game data references (passed to menus)
var game_data: Dictionary = {}
var player_inventory: Array = []
var character_stats: Dictionary = {}

func _ready():
	# Create menu container if it doesn't exist
	if not menu_container:
		print("Creating MenuLayer...")
		menu_container = CanvasLayer.new()
		menu_container.name = "MenuLayer" 
		menu_container.layer = 100  # High layer to ensure it's above everything
		add_child(menu_container)
		print("MenuLayer created with layer: ", menu_container.layer)
	else:
		print("MenuLayer found, layer: ", menu_container.layer)

func _input(event):
	"""Handle global menu shortcuts"""
	if event.is_action_pressed("ui_cancel"):  # ESC key
		close_top_menu()
	# Add more hotkeys when you create input actions
	elif event.is_action_pressed("inventory_hotkey"):  # I key
		toggle_menu("inventory")


# Main menu control methods
func open_menu(menu_type: String, data: Dictionary = {}):
	
	"""Open a specific menu type"""
	# Close menu if already open (toggle behavior)
	if menu_type in open_menus:
		close_menu(menu_type)
		return
	
	var menu_instance: Control
	
	# Create the appropriate menu (try scene first, then fallback to code)
	menu_instance = create_menu_instance(menu_type)
	if not menu_instance:
		print("Failed to create menu instance for: ", menu_type)
		return
	
	menu_container.add_child(menu_instance)
	print("Menu added to container. Menu size: ", menu_instance.size, " Position: ", menu_instance.position)
	
	# Make sure the menu is visible
	menu_instance.visible = true
	menu_instance.z_index = 100  # Ensure it's on top
	
	# Initialize menu with data
	if menu_instance.has_method("initialize"):
		menu_instance.initialize(data)
	
	# Set up menu data based on type
	setup_menu_data(menu_instance, menu_type)
	
	# Connect close signal if menu has one
	if menu_instance.has_signal("menu_closed"):
		menu_instance.menu_closed.connect(_on_menu_closed.bind(menu_type))
	
	# Track the menu
	open_menus[menu_type] = menu_instance
	menu_stack.push_back(menu_instance)
	
	# Optional: Pause game
	# get_tree().paused = true
	
	print("Opened ", menu_type, " menu successfully")
	print("Menu container layer: ", menu_container.layer)
	print("Menu container children: ", menu_container.get_children().size())


func create_menu_instance(menu_type: String) -> Control:
	"""Create a menu instance, trying scene file first, then code fallback"""
	
	# For now, always use placeholder menus while testing
	print("Creating placeholder ", menu_type, " menu (scene files disabled)")
	return create_placeholder_menu(menu_type)
	
func create_placeholder_menu(menu_type: String) -> Control:
	"""Create a simple placeholder menu from code"""
	var menu = Control.new()
	menu.name = menu_type.capitalize() + "Menu"
	
	# Set up basic layout
	var viewport_size = get_viewport().get_visible_rect().size
	menu.size = Vector2(500, 400)
	menu.position = (viewport_size - menu.size) / 2
	
	print("Creating placeholder menu - Viewport: ", viewport_size, " Menu size: ", menu.size, " Menu pos: ", menu.position)
	
	# Add background panel
	var background = Panel.new()
	background.size = menu.size
	background.position = Vector2.ZERO
	background.mouse_filter = Control.MOUSE_FILTER_STOP  # Important: catch mouse events
	menu.add_child(background)
	
	# Style the background with a more visible color
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.3, 0.95)  # More opaque, slightly blue
	style_box.border_color = Color(0.8, 0.8, 0.8, 1.0)  # White border
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	background.add_theme_stylebox_override("panel", style_box)
	
	# Add title with bigger, more visible text
	var title = Label.new()
	title.text = menu_type.capitalize() + " Menu"
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	menu.add_child(title)
	
	# Add placeholder content
	var content = Label.new()
	content.text = "This is a placeholder " + menu_type + " menu.\n\nThis confirms the menu system is working!\n\nReplace with actual " + menu_type + " scene when ready."
	content.position = Vector2(20, 80)
	content.size = Vector2(460, 200)
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_theme_color_override("font_color", Color.WHITE)
	content.add_theme_font_size_override("font_size", 16)
	menu.add_child(content)
	
	# Add close button with better styling
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.size = Vector2(100, 50)
	close_button.position = Vector2(menu.size.x - 120, menu.size.y - 70)
	close_button.pressed.connect(_on_placeholder_close.bind(menu_type))
	
	# Style the button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.6, 0.3, 0.3, 1.0)  # Red-ish
	button_style.corner_radius_top_left = 4
	button_style.corner_radius_top_right = 4
	button_style.corner_radius_bottom_left = 4
	button_style.corner_radius_bottom_right = 4
	close_button.add_theme_stylebox_override("normal", button_style)
	close_button.add_theme_color_override("font_color", Color.WHITE)
	
	menu.add_child(close_button)
	
	# Add menu_closed signal
	menu.add_user_signal("menu_closed")
	
	# Make sure it's visible
	menu.visible = true
	menu.z_index = 1000
	
	print("Placeholder menu created successfully")
	return menu

func _on_placeholder_close(menu_type: String):
	"""Handle close button for placeholder menus"""
	close_menu(menu_type)

# TEMPORARY DEBUG FUNCTION
func create_test_menu():
	"""Create a simple test menu to verify the system works"""
	print("Creating test menu...")
	
	# Create a simple red panel
	var test_menu = Panel.new()
	test_menu.size = Vector2(300, 200)
	test_menu.position = Vector2(100, 100)
	
	# Make it very visible
	var style = StyleBoxFlat.new()
	style.bg_color = Color.RED
	test_menu.add_theme_stylebox_override("panel", style)
	
	# Add a label
	var label = Label.new()
	label.text = "TEST MENU - THIS SHOULD BE VISIBLE!"
	label.position = Vector2(20, 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 20)
	test_menu.add_child(label)
	
	# Add to menu container
	menu_container.add_child(test_menu)
	print("Test menu added to container")
	print("Menu container has ", menu_container.get_children().size(), " children")

func close_menu(menu_type: String):
	"""Close a specific menu"""
	if menu_type not in open_menus:
		return
	
	var menu_instance = open_menus[menu_type]
	
	# Remove from tracking
	open_menus.erase(menu_type)
	menu_stack.erase(menu_instance)
	
	# Clean up the menu
	menu_instance.queue_free()
	
	# Unpause if no menus are open
	if open_menus.is_empty():
		get_tree().paused = false
	
	print("Closed ", menu_type, " menu")

func close_all_menus():
	"""Close all open menus"""
	var menu_types = open_menus.keys()
	for menu_type in menu_types:
		close_menu(menu_type)

func close_top_menu():
	"""Close the most recently opened menu (ESC key behavior)"""
	if menu_stack.is_empty():
		return
	
	var top_menu = menu_stack.back()
	# Find which menu type this instance belongs to
	for menu_type in open_menus:
		if open_menus[menu_type] == top_menu:
			close_menu(menu_type)
			return

func toggle_menu(menu_type: String, data: Dictionary = {}):
	
	"""Toggle a menu open/closed"""
	if is_menu_open(menu_type):
		close_menu(menu_type)
	else:
		open_menu(menu_type, data)

func is_menu_open(menu_type: String) -> bool:
	"""Check if a specific menu is open"""
	return menu_type in open_menus

func is_any_menu_open() -> bool:
	"""Check if any menu is open"""
	return not open_menus.is_empty()

func setup_menu_data(menu_instance: Control, menu_type: String):
	"""Pass appropriate data to each menu type"""
	match menu_type:
		"inventory":
			if menu_instance.has_method("set_inventory_data"):
				menu_instance.set_inventory_data(player_inventory)
		"character":
			if menu_instance.has_method("set_character_data"):
				menu_instance.set_character_data(character_stats)
		"buildings":
			if menu_instance.has_method("set_building_data"):
				menu_instance.set_building_data(game_data.get("buildings", {}))
		# Add more menu-specific data setup as needed

# Data management methods
func update_inventory(new_inventory: Array):
	"""Update inventory data and refresh open inventory menu"""
	player_inventory = new_inventory
	if is_menu_open("inventory"):
		var inventory_menu = open_menus["inventory"]
		if inventory_menu.has_method("refresh_inventory"):
			inventory_menu.refresh_inventory(player_inventory)

func update_character_stats(new_stats: Dictionary):
	"""Update character data and refresh open character menu"""
	character_stats = new_stats
	if is_menu_open("character"):
		var character_menu = open_menus["character"]
		if character_menu.has_method("refresh_character"):
			character_menu.refresh_character(character_stats)

func set_game_data(data: Dictionary):
	"""Set reference to main game data"""
	game_data = data

# Signal callbacks
func _on_menu_closed(menu_type: String):
	"""Handle when a menu closes itself"""
	close_menu(menu_type)
