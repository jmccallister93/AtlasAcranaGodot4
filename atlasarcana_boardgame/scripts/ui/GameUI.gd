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

# Menus
@onready var inventory_menu_scene: PackedScene = preload("res://scenes/ui/menus/InventoryMenu.tscn")
var inventory_menu: InventoryMenu

@onready var character_menu_scene: PackedScene = preload("res://scenes/ui/menus/CharacterMenu.tscn")
var character_menu: CharacterMenu

@onready var building_menu_scene: PackedScene = preload("res://scenes/ui/menus/BuildingMenu.tscn")
var building_menu: BuildingMenu

# Top Bar
@onready var top_bar = $TopBar

# Bottom Bar
@onready var bottom_bar = $BottomBar

# Menu buttons
@onready var menu_buttons = $BottomBar/MenuButtons

# Advance Turn Control
@onready var advance_turn_control = $BottomBar/AdvanceTurnControl
@onready var advance_turn_button = $BottomBar/AdvanceTurnControl/AdvanceTurn

# Action Controls
@onready var action_buttons = $BottomBar/ActionButtons
@onready var move_button = $BottomBar/ActionButtons/MoveButton
@onready var build_button = $BottomBar/ActionButtons/BuildButton
@onready var attack_button = $BottomBar/ActionButtons/AttackButton
@onready var interact_button = $BottomBar/ActionButtons/InteractButton
@onready var action_confirmation_dialog: ActionConfirmationDialog

# Character UI
@onready var character_action_points = Label.new()

# Signals for menu interactions
signal inventory_opened
signal inventory_closed
signal character_opened
signal character_closed
signal building_opened
signal building_closed

# Signals for actions
signal move_action_requested

func _ready():
	setup_ui()
	connect_menu_buttons()
	connect_action_buttons()
	setup_menus()
	connect_game_signals()
	GameManager.register_game_ui(self)
	
	# Enable input processing for ESC key
	set_process_input(true)

func _exit_tree():
	# Unregister when GameUI is being removed
	if GameManager:
		GameManager.unregister_game_ui()

func _input(event: InputEvent):
	"""Handle global input events"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			# Cancel current action mode
			GameManager.end_all_action_modes()

func setup_ui():
	"""Initialize UI styling and properties"""
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Set GameUI size
	size = viewport_size
	position = Vector2.ZERO
	
	# Position and size the bars
	setup_top_bar(viewport_size)
	setup_bottom_bar(viewport_size)
	
	# Position sections within bars
	setup_top_bar_layout()
	setup_bottom_bar_layout()
	
	# Make sure UI doesn't block mouse input to the game world (except for the bars)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup_top_bar(viewport_size: Vector2):
	"""Setup top bar positioning and size"""
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(viewport_size.x, 80)
	top_bar.mouse_filter = Control.MOUSE_FILTER_STOP

func setup_bottom_bar(viewport_size: Vector2):
	"""Setup bottom bar positioning and size"""
	bottom_bar.position = Vector2(0, viewport_size.y - 60)
	bottom_bar.size = Vector2(viewport_size.x, 60)
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_STOP

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
	# Set Action buttons
	move_button.text = "Move"
	build_button.text = "Build"
	attack_button.text = "Attack"
	interact_button.text = "Interact"
	advance_turn_button.text = "Advance"
	
	# Connect advance button signal
	if not advance_turn_button.pressed.is_connected(GameManager.advance_turn):
		advance_turn_button.pressed.connect(GameManager.advance_turn)
	
	# Setup action_points display
	setup_action_points_display(bottom_bar)
	
	# Position elements after UI layout is complete
	call_deferred("_position_bottom_bar_elements")
	
func _position_bottom_bar_elements():
	"""Position elements after the UI has finished its layout pass"""
	var bar_size = bottom_bar.size
	var margin = 10  # Standard margin from edges
	
	# Menu buttons - Left side
	menu_buttons.position = Vector2(margin, 5)
	
	# Action buttons - Center (use actual container size)
	var action_button_width = action_buttons.size.x
	action_buttons.position = Vector2((bar_size.x - action_button_width) / 2, 5)
	
	# Advance turn button - Right side  
	var advance_turn_width = advance_turn_control.size.x
	advance_turn_control.position = Vector2(bar_size.x - advance_turn_width - 40, 5)
	
func setup_action_points_display(bottom_bar: Control):
	"""Setup the action_points display label"""
	character_action_points.text = "action_points: " + str(GameManager.get_current_action_points())
	character_action_points.position = Vector2(5, 40)
	bottom_bar.add_child(character_action_points)

func setup_menus():
	"""Initialize and setup all menus"""
	# Inventory Menu
	inventory_menu = inventory_menu_scene.instantiate()
	add_child(inventory_menu)
	inventory_menu.hide()
	
	# Character Menu
	character_menu = character_menu_scene.instantiate()
	add_child(character_menu)
	character_menu.hide()
	
	# Building Menu
	building_menu = building_menu_scene.instantiate()
	add_child(building_menu)
	building_menu.hide()
	
	# Confirmation Dialog
	action_confirmation_dialog = ActionConfirmationDialog.new()
	add_child(action_confirmation_dialog)
	action_confirmation_dialog.hide_dialog()
	
	# Connect confirmation dialog signals
	action_confirmation_dialog.confirmed.connect(_on_action_confirmation_dialog_confirmed)
	action_confirmation_dialog.cancelled.connect(_on_action_confirmation_dialog_cancelled)

# ═══════════════════════════════════════════════════════════
# ACTION BUTTON SYSTEM WITH ENHANCED FEATURES
# ═══════════════════════════════════════════════════════════

func connect_action_buttons():
	"""Connect all action button signals"""
	move_button.pressed.connect(_on_move_button_pressed)
	build_button.pressed.connect(_on_build_button_pressed)
	attack_button.pressed.connect(_on_attack_button_pressed)
	interact_button.pressed.connect(_on_interact_button_pressed)

func _on_move_button_pressed():
	"""Handle move button press"""
	print("Move button pressed")
	
	# If already in movement mode, toggle it off
	if GameManager.get_current_action_mode() == GameManager.ActionMode.MOVEMENT:
		GameManager.end_movement_mode()
	else:
		GameManager.start_movement_mode()

func _on_build_button_pressed():
	"""Handle build button press"""
	print("Build button pressed")
	
	# If already in build mode, toggle it off
	if GameManager.get_current_action_mode() == GameManager.ActionMode.BUILD:
		GameManager.end_build_mode()
	else:
		GameManager.start_build_mode()

func _on_attack_button_pressed():
	"""Handle attack button press"""
	print("Attack button pressed")
	
	# If already in attack mode, toggle it off
	if GameManager.get_current_action_mode() == GameManager.ActionMode.ATTACK:
		GameManager.end_all_action_modes()
	else:
		GameManager.start_attack_mode()

func _on_interact_button_pressed():
	"""Handle interact button press"""
	print("Interact button pressed")
	
	# If already in interact mode, toggle it off
	if GameManager.get_current_action_mode() == GameManager.ActionMode.INTERACT:
		GameManager.end_all_action_modes()
	else:
		GameManager.start_interact_mode()

# ═══════════════════════════════════════════════════════════
# VISUAL FEEDBACK SYSTEM
# ═══════════════════════════════════════════════════════════

func update_action_button_states(active_mode):
	"""Update button appearance based on active mode"""
	# Reset all buttons to normal state
	reset_action_button_styles()
	
	# Highlight the active button
	match active_mode:
		GameManager.ActionMode.MOVEMENT:
			highlight_button(move_button, "Move (Active)")
		GameManager.ActionMode.BUILD:
			highlight_button(build_button, "Build (Active)")
		GameManager.ActionMode.ATTACK:
			highlight_button(attack_button, "Attack (Active)")
		GameManager.ActionMode.INTERACT:
			highlight_button(interact_button, "Interact (Active)")
		GameManager.ActionMode.NONE:
			# All buttons back to normal
			pass

func reset_action_button_styles():
	"""Reset all action buttons to normal appearance"""
	var buttons = [move_button, build_button, attack_button, interact_button]
	var texts = ["Move", "Build", "Attack", "Interact"]
	
	for i in range(buttons.size()):
		buttons[i].text = texts[i]
		# Remove custom styling to return to theme default
		buttons[i].remove_theme_stylebox_override("normal")
		buttons[i].remove_theme_stylebox_override("hover")
		buttons[i].remove_theme_stylebox_override("pressed")
		buttons[i].remove_theme_color_override("font_color")

func highlight_button(button: Button, active_text: String):
	"""Highlight a button to show it's active with enhanced styling"""
	button.text = active_text
	
	# Create active button style
	var active_style = StyleBoxFlat.new()
	active_style.bg_color = Color(0.2, 0.8, 0.2, 0.8)  # Semi-transparent green
	active_style.border_color = Color.WHITE
	active_style.border_width_left = 2
	active_style.border_width_right = 2
	active_style.border_width_top = 2
	active_style.border_width_bottom = 2
	active_style.corner_radius_top_left = 4
	active_style.corner_radius_top_right = 4
	active_style.corner_radius_bottom_left = 4
	active_style.corner_radius_bottom_right = 4
	
	# Create hover style (slightly different for feedback)
	var hover_style = active_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.9, 0.3, 0.9)
	
	button.add_theme_stylebox_override("normal", active_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", active_style)
	button.add_theme_color_override("font_color", Color.WHITE)

# ═══════════════════════════════════════════════════════════
# NOTIFICATION SYSTEM
# ═══════════════════════════════════════════════════════════

func show_notification(message: String, duration: float = 3.0, color: Color = Color.RED):
	"""Show a temporary notification to the player"""
	var notification = Label.new()
	notification.text = message
	notification.add_theme_font_size_override("font_size", 16)
	notification.add_theme_color_override("font_color", color)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Position in center of screen
	var viewport_size = get_viewport().get_visible_rect().size
	notification.position = Vector2(
		viewport_size.x / 2 - 150,
		viewport_size.y / 2 - 50
	)
	notification.size = Vector2(300, 100)
	
	# Add background for better readability
	var background = StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.8)
	background.corner_radius_top_left = 8
	background.corner_radius_top_right = 8
	background.corner_radius_bottom_left = 8
	background.corner_radius_bottom_right = 8
	background.content_margin_top = 10
	background.content_margin_bottom = 10
	background.content_margin_left = 20
	background.content_margin_right = 20
	notification.add_theme_stylebox_override("normal", background)
	
	notification.z_index = 1000  # Ensure it appears above everything
	add_child(notification)
	
	# Fade in animation
	notification.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 1.0, 0.3)
	tween.tween_delay(duration - 0.6)  # Show for most of duration
	tween.tween_property(notification, "modulate:a", 0.0, 0.3)
	tween.tween_callback(notification.queue_free)

# ═══════════════════════════════════════════════════════════
# CONFIRMATION DIALOG SYSTEM
# ═══════════════════════════════════════════════════════════

func _on_action_confirmation_dialog_confirmed(action_data: Dictionary):
	"""Handle confirmation dialog confirmed"""
	match action_data.get("action_type", ""):
		"movement":
			GameManager.confirm_movement(action_data.target_position)
		"building":
			GameManager.confirm_building(action_data.target_position, action_data.building_type)
		"attack":
			GameManager.confirm_attack(action_data.target_position)
		"interaction":
			GameManager.confirm_interaction(action_data.target_position, action_data.interaction_type)

func _on_action_confirmation_dialog_cancelled():
	"""Handle confirmation dialog cancelled"""
	print("Action cancelled by user")
	# End the current mode when user cancels
	match GameManager.get_current_action_mode():
		GameManager.ActionMode.MOVEMENT:
			GameManager.end_movement_mode()
		GameManager.ActionMode.BUILD:
			GameManager.end_build_mode()
		GameManager.ActionMode.ATTACK:
			GameManager.end_all_action_modes()
		GameManager.ActionMode.INTERACT:
			GameManager.end_all_action_modes()

# Public methods for other systems to show confirmations
func show_movement_confirmation(target_tile: BiomeTile):
	"""Show movement confirmation dialog"""
	action_confirmation_dialog.show_movement_confirmation(target_tile)

func show_build_confirmation(target_tile: BiomeTile, building_type: String):
	"""Show building confirmation dialog"""
	action_confirmation_dialog.show_build_confirmation(target_tile, building_type)

func show_attack_confirmation(target_tile: BiomeTile):
	"""Show attack confirmation dialog"""
	action_confirmation_dialog.show_attack_confirmation(target_tile)

func show_interact_confirmation(target_tile: BiomeTile, interaction_type: String):
	"""Show interaction confirmation dialog"""
	action_confirmation_dialog.show_interact_confirmation(target_tile, interaction_type)

# ═══════════════════════════════════════════════════════════
# GAME SIGNAL CONNECTIONS
# ═══════════════════════════════════════════════════════════

func connect_game_signals():
	"""Connect to GameManager signals"""
	# Turn signals
	GameManager.initial_turn.connect(_on_game_manager_initial_turn)
	GameManager.turn_advanced.connect(_on_game_manager_turn_advanced)
	
	# Character signals
	GameManager.action_points_spent.connect(_on_game_manager_action_points_spent)

# ═══════════════════════════════════════════════════════════
# MENU SYSTEM (EXISTING FUNCTIONALITY)
# ═══════════════════════════════════════════════════════════

func connect_menu_buttons():
	"""Connect all menu button signals"""
	var inventory_btn = $BottomBar/MenuButtons/InventoryButton
	var character_btn = $BottomBar/MenuButtons/CharacterButton
	var buildings_btn = $BottomBar/MenuButtons/BuildingsButton
	
	inventory_btn.pressed.connect(_on_inventory_button_pressed)
	character_btn.pressed.connect(_on_character_button_pressed)
	buildings_btn.pressed.connect(_on_buildings_button_pressed)

func close_all_menus():
	"""Close all open menus"""
	if inventory_menu and inventory_menu.visible:
		inventory_menu.hide_menu()
		inventory_closed.emit()

	if character_menu and character_menu.visible:
		character_menu.hide_menu()
		character_closed.emit()
	
	if building_menu and building_menu.visible:
		building_menu.hide_menu()
		building_closed.emit()

# Menu button callbacks
func _on_inventory_button_pressed():
	"""Handle inventory button press"""
	if inventory_menu:
		if inventory_menu.visible:
			inventory_menu.hide_menu()
			inventory_closed.emit()
		else:
			close_all_menus()
			inventory_menu.show_menu()
			inventory_opened.emit()

func _on_character_button_pressed():
	"""Handle character sheet button press"""
	if character_menu:
		if character_menu.visible:
			character_menu.hide_menu()
			character_closed.emit()
		else:
			close_all_menus()
			character_menu.show_menu()
			character_opened.emit()

func _on_buildings_button_pressed():
	"""Handle buildings menu button press"""
	if building_menu:
		if building_menu.visible:
			building_menu.hide_menu()
			building_closed.emit()
		else:
			close_all_menus()
			building_menu.show_menu()
			building_opened.emit()

# ═══════════════════════════════════════════════════════════
# GAME EVENT HANDLERS
# ═══════════════════════════════════════════════════════════

func _on_game_manager_initial_turn(turn: int) -> void:
	turn_subtext.text = str(turn)

func _on_game_manager_turn_advanced(turn: int) -> void:
	turn_subtext.text = str(turn)

func _on_game_manager_action_points_spent(current_action_points: int) -> void:
	character_action_points.text = "action_points: " + str(current_action_points)
