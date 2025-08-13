# BottomBarUI.gd - Fixed Version with Equipment Button
extends Control
class_name BottomBarUI

# UI Components
var background_panel: Panel
var menu_buttons_container: HBoxContainer
var action_buttons_container: HBoxContainer
var advance_turn_container: HBoxContainer

# Menu buttons
var inventory_button: Button
var character_button: Button
var buildings_button: Button
var equipment_button: Button  # NEW: Equipment button

# Action buttons
var move_button: Button
var build_button: Button
var attack_button: Button
var interact_button: Button

# Advance turn
var advance_turn_button: Button

# Signals
signal menu_button_pressed(menu_type: String)
signal action_button_pressed(action_type: String)
signal action_failed(message: String)

func _ready():
	print("BottomBarUI _ready() called")
	# Don't create UI components here - wait for setup_layout

func create_ui_components():
	"""Create all bottom bar UI components"""
	print("Creating BottomBarUI components")
	
	# Clear any existing children
	for child in get_children():
		child.queue_free()
	
	# Background panel
	background_panel = Panel.new()
	background_panel.name = "BottomBarBackground"
	background_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_panel)
	
	# Style the background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_color = Color(0.3, 0.3, 0.3)
	style.border_width_top = 2
	background_panel.add_theme_stylebox_override("panel", style)
	
	create_menu_buttons()
	create_action_buttons()
	create_advance_turn_button()
	
	connect_button_signals()
	
	print("✅ BottomBarUI components created")

func create_menu_buttons():
	"""Create menu buttons section"""
	menu_buttons_container = HBoxContainer.new()
	menu_buttons_container.name = "MenuButtonsContainer"
	menu_buttons_container.add_theme_constant_override("separation", 10)
	background_panel.add_child(menu_buttons_container)
	
	# Create menu buttons
	inventory_button = create_styled_button("Inventory", Color(0.6, 0.4, 0.2))
	character_button = create_styled_button("Character", Color(0.2, 0.6, 0.8))
	buildings_button = create_styled_button("Buildings", Color(0.5, 0.5, 0.5))
	equipment_button = create_styled_button("Equipment", Color(0.8, 0.2, 0.6))  # NEW: Equipment button with purple color
	
	menu_buttons_container.add_child(inventory_button)
	menu_buttons_container.add_child(character_button)
	menu_buttons_container.add_child(buildings_button)
	menu_buttons_container.add_child(equipment_button)  # NEW: Add equipment button

func create_action_buttons():
	"""Create action buttons section"""
	action_buttons_container = HBoxContainer.new()
	action_buttons_container.name = "ActionButtonsContainer"
	action_buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	action_buttons_container.add_theme_constant_override("separation", 10)
	background_panel.add_child(action_buttons_container)
	
	# Create action buttons
	move_button = create_styled_button("Move", Color(0.2, 0.8, 0.2))
	build_button = create_styled_button("Build", Color(0.8, 0.6, 0.2))
	attack_button = create_styled_button("Attack", Color(0.8, 0.2, 0.2))
	interact_button = create_styled_button("Interact", Color(0.6, 0.2, 0.8))
	
	action_buttons_container.add_child(move_button)
	action_buttons_container.add_child(build_button)
	action_buttons_container.add_child(attack_button)
	action_buttons_container.add_child(interact_button)

func create_advance_turn_button():
	"""Create advance turn button"""
	advance_turn_container = HBoxContainer.new()
	advance_turn_container.name = "AdvanceTurnContainer"
	advance_turn_container.alignment = BoxContainer.ALIGNMENT_END
	background_panel.add_child(advance_turn_container)
	
	advance_turn_button = create_styled_button("End Turn", Color(0.1, 0.7, 0.9))
	advance_turn_button.custom_minimum_size = Vector2(100, 40)
	advance_turn_container.add_child(advance_turn_button)

func create_styled_button(text: String, accent_color: Color) -> Button:
	"""Create a styled button with consistent appearance"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(80, 40)
	
	# Create normal style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.2)
	normal_style.border_color = accent_color
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	
	# Create hover style
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = accent_color * 0.3
	
	# Create pressed style
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = accent_color * 0.5
	
	# Apply styles
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", Color.WHITE)
	
	return button

func connect_button_signals():
	"""Connect all button signals"""
	print("Connecting BottomBarUI button signals")
	
	# Menu buttons
	inventory_button.pressed.connect(func(): menu_button_pressed.emit("inventory"))
	character_button.pressed.connect(func(): menu_button_pressed.emit("character"))
	buildings_button.pressed.connect(func(): menu_button_pressed.emit("buildings"))
	equipment_button.pressed.connect(func(): menu_button_pressed.emit("equipment"))  # NEW: Equipment button signal
	
	# Action buttons
	move_button.pressed.connect(func(): action_button_pressed.emit("move"))
	build_button.pressed.connect(func(): action_button_pressed.emit("build"))
	attack_button.pressed.connect(func(): action_button_pressed.emit("attack"))
	interact_button.pressed.connect(func(): action_button_pressed.emit("interact"))
	
	# Advance turn button
	advance_turn_button.pressed.connect(GameManager.advance_turn)
	
	print("✅ BottomBarUI signals connected")

func setup_layout(viewport_size: Vector2):
	"""Setup the layout of the bottom bar"""
	print("BottomBarUI setup_layout called with size: ", viewport_size)
	
	var bar_height = 80
	var margin = 10
	
	# Position and size the main control
	position = Vector2(0, viewport_size.y - bar_height)
	size = Vector2(viewport_size.x, bar_height)
	mouse_filter = Control.MOUSE_FILTER_PASS  # Allow mouse events
	visible = true
	
	print("BottomBarUI positioned at: ", position, " with size: ", size)
	
	# Create UI components now
	create_ui_components()
	
	# Wait a frame then layout sections
	call_deferred("layout_sections", viewport_size, bar_height, margin)

func layout_sections(viewport_size: Vector2, bar_height: int, margin: int):
	"""Layout the three main sections"""
	if not background_panel:
		print("❌ Background panel not ready for layout")
		return
		
	print("Laying out BottomBarUI sections")
	
	var usable_height = bar_height - (margin * 2)
	var y_pos = margin
	
	# Ensure background panel covers the full area
	background_panel.position = Vector2.ZERO
	background_panel.size = size
	
	# Menu buttons (left) - UPDATED: Increased width to accommodate 4 buttons
	if menu_buttons_container:
		menu_buttons_container.position = Vector2(margin, y_pos)
		menu_buttons_container.size = Vector2(400, usable_height)  # Increased from 300 to 400
		print("Menu buttons positioned at: ", menu_buttons_container.position)
	
	# Action buttons (center)
	if action_buttons_container:
		var action_buttons_width = 400
		action_buttons_container.position = Vector2((viewport_size.x - action_buttons_width) / 2, y_pos)
		action_buttons_container.size = Vector2(action_buttons_width, usable_height)
		print("Action buttons positioned at: ", action_buttons_container.position)
	
	# Advance turn (right)
	if advance_turn_container:
		var advance_turn_width = 120
		advance_turn_container.position = Vector2(viewport_size.x - advance_turn_width - margin, y_pos)
		advance_turn_container.size = Vector2(advance_turn_width, usable_height)
		print("Advance turn positioned at: ", advance_turn_container.position)
	
	print("✅ BottomBarUI layout complete")

# Public interface methods for mode management
func _on_mode_changed(active_mode):
	"""Update button appearance based on active mode"""
	reset_action_button_styles()
	
	match active_mode:
		GameManager.ActionMode.MOVEMENT:
			highlight_action_button(move_button, "Move (Active)")
		GameManager.ActionMode.BUILD:
			highlight_action_button(build_button, "Build (Active)")
		GameManager.ActionMode.ATTACK:
			highlight_action_button(attack_button, "Attack (Active)")
		GameManager.ActionMode.INTERACT:
			highlight_action_button(interact_button, "Interact (Active)")

func update_button_states(active_mode):
	"""Public method called by GameUI to update button states"""
	_on_mode_changed(active_mode)

func reset_action_button_styles():
	"""Reset all action buttons to normal appearance"""
	if not move_button or not build_button or not attack_button or not interact_button:
		return
		
	var buttons = [move_button, build_button, attack_button, interact_button]
	var texts = ["Move", "Build", "Attack", "Interact"]
	var colors = [Color(0.2, 0.8, 0.2), Color(0.8, 0.6, 0.2), Color(0.8, 0.2, 0.2), Color(0.6, 0.2, 0.8)]
	
	for i in range(buttons.size()):
		buttons[i].text = texts[i]
		style_button_normal(buttons[i], colors[i])

func highlight_action_button(button: Button, active_text: String):
	"""Highlight a button to show it's active"""
	if not button:
		return
		
	button.text = active_text
	
	# Create active style
	var active_style = StyleBoxFlat.new()
	active_style.bg_color = Color(0.2, 0.8, 0.2, 0.8)
	active_style.border_color = Color.WHITE
	active_style.border_width_left = 3
	active_style.border_width_right = 3
	active_style.border_width_top = 3
	active_style.border_width_bottom = 3
	active_style.corner_radius_top_left = 4
	active_style.corner_radius_top_right = 4
	active_style.corner_radius_bottom_left = 4
	active_style.corner_radius_bottom_right = 4
	
	# Create active hover style
	var hover_style = active_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.9, 0.3, 0.9)
	
	button.add_theme_stylebox_override("normal", active_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", active_style)
	button.add_theme_color_override("font_color", Color.WHITE)

func style_button_normal(button: Button, accent_color: Color):
	"""Apply normal styling to a button"""
	if not button:
		return
		
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.2)
	normal_style.border_color = accent_color
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = accent_color * 0.3
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = accent_color * 0.5
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", Color.WHITE)

func get_action_buttons() -> Array:
	"""Get all action buttons for external access"""
	return [move_button, build_button, attack_button, interact_button]

func update_action_buttons_availability(current_action_points: int):
	"""Update action button appearance based on available action points"""
	var has_action_points = current_action_points > 0
	
	var action_buttons = [move_button, build_button, attack_button, interact_button]
	
	for button in action_buttons:
		if not button:
			continue
			
		if has_action_points:
			# Enable button
			button.disabled = false
			button.modulate = Color.WHITE
			button.tooltip_text = ""
		else:
			# Disable button and make it look disabled
			button.disabled = true
			button.modulate = Color(0.5, 0.5, 0.5, 0.8)  # Grayed out
			button.tooltip_text = "No action points remaining"

# Debug method
func debug_print_state():
	"""Debug method to print current state"""
	print("=== BottomBarUI Debug State ===")
	print("Visible: ", visible)
	print("Size: ", size)
	print("Position: ", position)
	print("Parent: ", get_parent())
	print("Children count: ", get_children().size())
	if background_panel:
		print("Background panel size: ", background_panel.size)
		print("Background panel position: ", background_panel.position)
		print("Background panel children: ", background_panel.get_children().size())
	print("Move button exists: ", move_button != null)
	print("Inventory button exists: ", inventory_button != null)
	print("Equipment button exists: ", equipment_button != null)  # NEW: Debug equipment button
	if menu_buttons_container:
		print("Menu container position: ", menu_buttons_container.position)
		print("Menu container size: ", menu_buttons_container.size)
	if action_buttons_container:
		print("Action container position: ", action_buttons_container.position)
		print("Action container size: ", action_buttons_container.size)
	print("==============================")
