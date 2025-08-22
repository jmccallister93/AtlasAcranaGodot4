# BottomRightUI.gd - Bottom Right: Turn Control
extends Control
class_name BottomRightUI

# UI Components
var background_panel: Panel
var turn_container: VBoxContainer
var advance_turn_button: Button
var turn_info_label: Label

# Turn state
var current_turn: int = 1
var can_advance_turn: bool = true
var pulse_tween: Tween  # Store reference to pulse tween

# Signals
signal advance_turn_requested()

func _ready():
	create_ui_components()
	setup_styling()

func create_ui_components():
	"""Create all turn control components"""
	# Background panel
	background_panel = Panel.new()
	background_panel.name = "TurnControlBackground"
	add_child(background_panel)
	
	# Main container
	turn_container = VBoxContainer.new()
	turn_container.name = "TurnContainer"
	turn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	background_panel.add_child(turn_container)
	
	# Turn info label (optional)
	turn_info_label = Label.new()
	turn_info_label.text = "Turn " + str(current_turn)
	turn_info_label.name = "TurnInfoLabel"
	turn_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_container.add_child(turn_info_label)
	
	# Small spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(1, 5)
	turn_container.add_child(spacer)
	
	# Advance turn button
	advance_turn_button = create_styled_button()
	turn_container.add_child(advance_turn_button)
	
	connect_button_signals()

func create_styled_button() -> Button:
	"""Create the styled advance turn button"""
	var button = Button.new()
	button.text = "End Turn"
	button.name = "AdvanceTurnButton"
	button.custom_minimum_size = Vector2(100, 40)
	
	style_button_normal(button)
	return button

func style_button_normal(button: Button):
	"""Apply normal styling to the advance turn button"""
	var accent_color = Color(0.1, 0.7, 0.9)  # Cyan/blue color
	
	# Create normal style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
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
	
	# Turn info label styling
	turn_info_label.add_theme_font_size_override("font_size", 12)
	turn_info_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)

func connect_button_signals():
	"""Connect button signals"""
	advance_turn_button.pressed.connect(_on_advance_turn_pressed)

func _on_advance_turn_pressed():
	"""Handle advance turn button press"""
	if can_advance_turn:
		animate_button_press()
		advance_turn_requested.emit()
		# Connect to GameManager directly as fallback
		if GameManager.has_method("advance_turn"):
			GameManager.advance_turn()

func setup_layout(section_size: Vector2, margin: int = 10):
	"""Setup the layout of this section - auto-size to content"""
	# Calculate required width based on button size and margins
	var button_width = 100
	var required_width = button_width + (margin * 2)
	
	# Use calculated width instead of provided width
	size = Vector2(required_width, section_size.y)
	
	# Position background to fit content
	background_panel.position = Vector2.ZERO
	background_panel.size = size
	
	# Position container
	turn_container.position = Vector2(margin, margin)
	turn_container.size = Vector2(size.x - (margin * 2), size.y - (margin * 2))

# Public interface methods
func update_turn_info(turn_number: int):
	"""Update the turn information display"""
	current_turn = turn_number
	turn_info_label.text = "Turn " + str(turn_number)
	
	# Brief animation for turn changes
	animate_turn_change()

func set_can_advance_turn(can_advance: bool):
	"""Enable or disable turn advancement"""
	can_advance_turn = can_advance
	advance_turn_button.disabled = not can_advance
	
	if can_advance:
		advance_turn_button.modulate = Color.WHITE
		advance_turn_button.tooltip_text = ""
		advance_turn_button.text = "End Turn"
	else:
		advance_turn_button.modulate = Color(0.5, 0.5, 0.5, 0.8)
		advance_turn_button.tooltip_text = "Cannot advance turn"
		advance_turn_button.text = "End Turn"

func set_button_text(new_text: String):
	"""Update the button text"""
	advance_turn_button.text = new_text

func show_turn_processing():
	"""Show that turn is being processed"""
	advance_turn_button.disabled = true
	advance_turn_button.text = "Processing..."
	advance_turn_button.modulate = Color(0.7, 0.7, 0.7, 1.0)

func hide_turn_info():
	"""Hide the turn info label"""
	turn_info_label.visible = false

func show_turn_info():
	"""Show the turn info label"""
	turn_info_label.visible = true

func set_turn_info_text(text: String):
	"""Set custom turn info text"""
	turn_info_label.text = text

# Animation methods
func animate_button_press():
	"""Create a brief animation when the button is pressed"""
	var tween = create_tween()
	var original_scale = advance_turn_button.scale
	
	tween.tween_property(advance_turn_button, "scale", original_scale * 1.1, 0.1)
	tween.tween_property(advance_turn_button, "scale", original_scale, 0.1)

func animate_turn_change():
	"""Create an animation when the turn changes"""
	var tween = create_tween()
	var original_scale = turn_info_label.scale
	
	# Scale animation
	tween.tween_property(turn_info_label, "scale", original_scale * 1.2, 0.2)
	tween.tween_property(turn_info_label, "scale", original_scale, 0.2)
	
	# Color flash
	var original_color = Color.LIGHT_GRAY
	turn_info_label.add_theme_color_override("font_color", Color.YELLOW)
	tween.tween_callback(func(): turn_info_label.add_theme_color_override("font_color", original_color)).set_delay(0.5)

func pulse_button():
	"""Create a pulsing effect for the advance turn button"""
	# Stop any existing pulse first
	stop_pulse()
	
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	
	pulse_tween.tween_property(advance_turn_button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 1.0)
	pulse_tween.tween_property(advance_turn_button, "modulate", Color.WHITE, 1.0)

func stop_pulse():
	"""Stop the pulsing effect"""
	if pulse_tween:
		pulse_tween.kill()
		pulse_tween = null
	advance_turn_button.modulate = Color.WHITE

# Getters
func get_current_turn() -> int:
	"""Get the current turn number"""
	return current_turn

func get_can_advance_turn() -> bool:
	"""Get whether turn can be advanced"""
	return can_advance_turn

func get_advance_turn_button() -> Button:
	"""Get the advance turn button"""
	return advance_turn_button
