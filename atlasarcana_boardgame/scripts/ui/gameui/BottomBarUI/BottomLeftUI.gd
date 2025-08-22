# BottomLeftUI.gd - Bottom Left: Menu Buttons
extends Control
class_name BottomLeftUI

# UI Components
var background_panel: Panel
var menu_buttons_container: HBoxContainer

# Menu buttons
var inventory_button: Button
var character_button: Button
var buildings_button: Button
var equipment_button: Button
var warband_button: Button

# Button configuration
var button_config = {
	"inventory": {"text": "Inventory", "color": Color(0.6, 0.4, 0.2)},
	"character": {"text": "Character", "color": Color(0.2, 0.6, 0.8)},
	"buildings": {"text": "Buildings", "color": Color(0.5, 0.5, 0.5)},
	"equipment": {"text": "Equipment", "color": Color(0.8, 0.2, 0.6)},
	"warband": {"text": "Warband", "color": Color(0.2, 0.8, 0.4)}
}

# Signals
signal menu_button_pressed(menu_type: String)

func _ready():
	create_ui_components()
	setup_styling()

func create_ui_components():
	"""Create all menu button components"""
	# Background panel
	background_panel = Panel.new()
	background_panel.name = "MenuButtonsBackground"
	add_child(background_panel)
	
	# Main container
	menu_buttons_container = HBoxContainer.new()
	menu_buttons_container.name = "MenuButtonsContainer"
	menu_buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_buttons_container.add_theme_constant_override("separation", 8)
	background_panel.add_child(menu_buttons_container)
	
	# Create menu buttons
	create_menu_buttons()
	connect_button_signals()

func create_menu_buttons():
	"""Create all menu buttons"""
	inventory_button = create_styled_button("inventory")
	character_button = create_styled_button("character")
	buildings_button = create_styled_button("buildings")
	equipment_button = create_styled_button("equipment")
	warband_button = create_styled_button("warband")
	
	# Add buttons to container
	menu_buttons_container.add_child(inventory_button)
	menu_buttons_container.add_child(character_button)
	menu_buttons_container.add_child(buildings_button)
	menu_buttons_container.add_child(equipment_button)
	menu_buttons_container.add_child(warband_button)

func create_styled_button(button_type: String) -> Button:
	"""Create a styled button with consistent appearance"""
	var config = button_config[button_type]
	var button = Button.new()
	button.text = config.text
	button.name = config.text + "Button"
	button.custom_minimum_size = Vector2(85, 40)
	
	style_button_normal(button, config.color)
	return button

func style_button_normal(button: Button, accent_color: Color):
	"""Apply normal styling to a button"""
	# Create normal style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	normal_style.border_color = accent_color
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6
	
	# Create hover style
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = accent_color * 0.4
	hover_style.border_color = accent_color * 1.2
	
	# Create pressed style
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = accent_color * 0.6
	
	# Apply styles
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", Color.WHITE)

func setup_styling():
	"""Apply styling to the background"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.3, 0.8)
	background_panel.add_theme_stylebox_override("panel", style)

func connect_button_signals():
	"""Connect all button signals"""
	inventory_button.pressed.connect(func(): menu_button_pressed.emit("inventory"))
	character_button.pressed.connect(func(): menu_button_pressed.emit("character"))
	buildings_button.pressed.connect(func(): menu_button_pressed.emit("buildings"))
	equipment_button.pressed.connect(func(): menu_button_pressed.emit("equipment"))
	warband_button.pressed.connect(func(): menu_button_pressed.emit("warband"))

func setup_layout(section_size: Vector2, margin: int = 10):
	"""Setup the layout of this section"""
	size = section_size
	
	# Position background
	background_panel.position = Vector2.ZERO
	background_panel.size = section_size
	
	# Position container
	menu_buttons_container.position = Vector2(margin, margin)
	menu_buttons_container.size = Vector2(section_size.x - (margin * 2), section_size.y - (margin * 2))

# Public interface methods
func highlight_menu_button(menu_type: String):
	"""Highlight a specific menu button to show it's active"""
	reset_all_button_styles()
	
	var button = get_button_by_type(menu_type)
	if button:
		var config = button_config[menu_type]
		highlight_button(button, config.color)

func reset_all_button_styles():
	"""Reset all buttons to normal appearance"""
	var buttons = [inventory_button, character_button, buildings_button, equipment_button, warband_button]
	var types = ["inventory", "character", "buildings", "equipment", "warband"]
	
	for i in range(buttons.size()):
		if buttons[i]:
			var config = button_config[types[i]]
			style_button_normal(buttons[i], config.color)

func highlight_button(button: Button, accent_color: Color):
	"""Highlight a button to show it's active"""
	var active_style = StyleBoxFlat.new()
	active_style.bg_color = accent_color * 0.8
	active_style.border_color = Color.WHITE
	active_style.border_width_left = 3
	active_style.border_width_right = 3
	active_style.border_width_top = 3
	active_style.border_width_bottom = 3
	active_style.corner_radius_top_left = 6
	active_style.corner_radius_top_right = 6
	active_style.corner_radius_bottom_left = 6
	active_style.corner_radius_bottom_right = 6
	
	var hover_style = active_style.duplicate()
	hover_style.bg_color = accent_color * 0.9
	
	button.add_theme_stylebox_override("normal", active_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", active_style)
	button.add_theme_color_override("font_color", Color.WHITE)

func get_button_by_type(menu_type: String) -> Button:
	"""Get a button by its menu type"""
	match menu_type:
		"inventory":
			return inventory_button
		"character":
			return character_button
		"buildings":
			return buildings_button
		"equipment":
			return equipment_button
		"warband":
			return warband_button
		_:
			return null

func set_button_enabled(menu_type: String, enabled: bool):
	"""Enable or disable a specific menu button"""
	var button = get_button_by_type(menu_type)
	if button:
		button.disabled = not enabled
		button.modulate = Color.WHITE if enabled else Color(0.5, 0.5, 0.5, 0.8)

func set_button_text(menu_type: String, new_text: String):
	"""Update button text"""
	var button = get_button_by_type(menu_type)
	if button:
		button.text = new_text

func get_all_buttons() -> Array:
	"""Get all menu buttons"""
	return [inventory_button, character_button, buildings_button, equipment_button, warband_button]

func animate_button_press(menu_type: String):
	"""Create a brief animation when a button is pressed"""
	var button = get_button_by_type(menu_type)
	if button:
		var tween = create_tween()
		var original_scale = button.scale
		
		tween.tween_property(button, "scale", original_scale * 1.1, 0.1)
		tween.tween_property(button, "scale", original_scale, 0.1)
