# BottomCenterUI.gd - Bottom Center: Action Buttons
extends Control
class_name BottomCenterUI

# UI Components
var background_panel: Panel
var action_buttons_container: HBoxContainer

# Action buttons
var move_button: Button
var build_button: Button
var attack_button: Button
var interact_button: Button

# Button configuration
var button_config = {
	"move": {"text": "Move", "color": Color(0.2, 0.8, 0.2)},
	"build": {"text": "Build", "color": Color(0.8, 0.6, 0.2)},
	"attack": {"text": "Attack", "color": Color(0.8, 0.2, 0.2)},
	"interact": {"text": "Interact", "color": Color(0.6, 0.2, 0.8)}
}

# Signals
signal action_button_pressed(action_type: String)

func _ready():
	create_ui_components()
	setup_styling()

func create_ui_components():
	"""Create all action button components"""
	# Background panel
	background_panel = Panel.new()
	background_panel.name = "ActionButtonsBackground"
	add_child(background_panel)
	
	# Main container
	action_buttons_container = HBoxContainer.new()
	action_buttons_container.name = "ActionButtonsContainer"
	action_buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	action_buttons_container.add_theme_constant_override("separation", 12)
	background_panel.add_child(action_buttons_container)
	
	# Create action buttons
	create_action_buttons()
	connect_button_signals()

func create_action_buttons():
	"""Create all action buttons"""
	move_button = create_styled_button("move")
	build_button = create_styled_button("build")
	attack_button = create_styled_button("attack")
	interact_button = create_styled_button("interact")
	
	# Add buttons to container
	action_buttons_container.add_child(move_button)
	action_buttons_container.add_child(build_button)
	action_buttons_container.add_child(attack_button)
	action_buttons_container.add_child(interact_button)

func create_styled_button(button_type: String) -> Button:
	"""Create a styled button with consistent appearance"""
	var config = button_config[button_type]
	var button = Button.new()
	button.text = config.text
	button.name = config.text + "Button"
	button.custom_minimum_size = Vector2(90, 45)
	
	style_button_normal(button, config.color)
	return button

func style_button_normal(button: Button, accent_color: Color):
	"""Apply normal styling to a button"""
	# Create normal style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	normal_style.border_color = accent_color
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	
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
	button.add_theme_font_size_override("font_size", 14)

func setup_styling():
	"""Apply styling to the background"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.08, 0.9)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.4, 0.8)
	background_panel.add_theme_stylebox_override("panel", style)

func connect_button_signals():
	"""Connect all button signals"""
	move_button.pressed.connect(func(): action_button_pressed.emit("move"))
	build_button.pressed.connect(func(): action_button_pressed.emit("build"))
	attack_button.pressed.connect(func(): action_button_pressed.emit("attack"))
	interact_button.pressed.connect(func(): action_button_pressed.emit("interact"))

func setup_layout(section_size: Vector2, margin: int = 10):
	"""Setup the layout of this section"""
	size = section_size
	
	# Position background
	background_panel.position = Vector2.ZERO
	background_panel.size = section_size
	
	# Position container
	action_buttons_container.position = Vector2(margin, margin)
	action_buttons_container.size = Vector2(section_size.x - (margin * 2), section_size.y - (margin * 2))

# Public interface methods
func highlight_action_button(action_type: String, active_text: String = ""):
	"""Highlight a specific action button to show it's active"""
	reset_all_button_styles()
	
	var button = get_button_by_type(action_type)
	if button:
		var config = button_config[action_type]
		highlight_button(button, config.color)
		
		# Update text if provided
		if active_text != "":
			button.text = active_text
		else:
			button.text = config.text + " (Active)"

func reset_all_button_styles():
	"""Reset all buttons to normal appearance"""
	var buttons = [move_button, build_button, attack_button, interact_button]
	var types = ["move", "build", "attack", "interact"]
	
	for i in range(buttons.size()):
		if buttons[i]:
			var config = button_config[types[i]]
			style_button_normal(buttons[i], config.color)
			buttons[i].text = config.text

func highlight_button(button: Button, accent_color: Color):
	"""Highlight a button to show it's active"""
	var active_style = StyleBoxFlat.new()
	active_style.bg_color = accent_color * 0.7
	active_style.border_color = Color.WHITE
	active_style.border_width_left = 3
	active_style.border_width_right = 3
	active_style.border_width_top = 3
	active_style.border_width_bottom = 3
	active_style.corner_radius_top_left = 8
	active_style.corner_radius_top_right = 8
	active_style.corner_radius_bottom_left = 8
	active_style.corner_radius_bottom_right = 8
	
	var hover_style = active_style.duplicate()
	hover_style.bg_color = accent_color * 0.9
	
	button.add_theme_stylebox_override("normal", active_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", active_style)
	button.add_theme_color_override("font_color", Color.WHITE)

func get_button_by_type(action_type: String) -> Button:
	"""Get a button by its action type"""
	match action_type:
		"move":
			return move_button
		"build":
			return build_button
		"attack":
			return attack_button
		"interact":
			return interact_button
		_:
			return null

func set_button_enabled(action_type: String, enabled: bool):
	"""Enable or disable a specific action button"""
	var button = get_button_by_type(action_type)
	if button:
		button.disabled = not enabled
		button.modulate = Color.WHITE if enabled else Color(0.5, 0.5, 0.5, 0.8)

func set_all_buttons_enabled(enabled: bool):
	"""Enable or disable all action buttons"""
	var buttons = [move_button, build_button, attack_button, interact_button]
	
	for button in buttons:
		if button:
			button.disabled = not enabled
			button.modulate = Color.WHITE if enabled else Color(0.5, 0.5, 0.5, 0.8)
			
			if not enabled:
				button.tooltip_text = "No action points remaining"
			else:
				button.tooltip_text = ""

func update_buttons_availability(current_action_points: int):
	"""Update action button appearance based on available action points"""
	var has_action_points = current_action_points > 0
	set_all_buttons_enabled(has_action_points)

func set_button_text(action_type: String, new_text: String):
	"""Update button text"""
	var button = get_button_by_type(action_type)
	if button:
		button.text = new_text

func get_all_buttons() -> Array:
	"""Get all action buttons"""
	return [move_button, build_button, attack_button, interact_button]

func animate_button_press(action_type: String):
	"""Create a brief animation when a button is pressed"""
	var button = get_button_by_type(action_type)
	if button:
		var tween = create_tween()
		var original_scale = button.scale
		
		tween.tween_property(button, "scale", original_scale * 1.15, 0.1)
		tween.tween_property(button, "scale", original_scale, 0.1)

func pulse_active_button(action_type: String):
	"""Create a pulsing effect for an active button"""
	var button = get_button_by_type(action_type)
	if button:
		var tween = create_tween()
		tween.set_loops()
		
		tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.8)
		tween.tween_property(button, "modulate", Color.WHITE, 0.8)
