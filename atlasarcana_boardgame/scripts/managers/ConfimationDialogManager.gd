# ConfirmationDialogManager.gd
extends Control
class_name ConfirmationDialogManager

signal confirmed(action_data: Dictionary)
signal cancelled

# UI Components
var background: ColorRect
var dialog_panel: Panel
var title_label: Label
var message_label: Label
var confirm_button: Button
var cancel_button: Button
var button_container: HBoxContainer

# Dialog configuration
var current_action_data: Dictionary = {}
var dialog_size: Vector2 = Vector2(400, 200)

func _ready():
	create_dialog_ui()
	setup_dialog_styling()
	connect_signals()
	hide_dialog()
	
	# Set high z-index to appear above everything
	z_index = 1000
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func create_dialog_ui():
	"""Create all UI components for the dialog"""
	# Semi-transparent background overlay
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0, 0, 0, 0.5)
	background.mouse_filter = Control.MOUSE_FILTER_STOP  # Block clicks behind dialog
	add_child(background)
	
	# Main dialog panel
	dialog_panel = Panel.new()
	dialog_panel.name = "DialogPanel"
	dialog_panel.size = dialog_size
	background.add_child(dialog_panel)
	
	# Title label
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Confirm Action"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_panel.add_child(title_label)
	
	# Message label
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.text = "Are you sure?"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_panel.add_child(message_label)
	
	# Button container
	button_container = HBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	dialog_panel.add_child(button_container)
	
	# Confirm button
	confirm_button = Button.new()
	confirm_button.name = "ConfirmButton"
	confirm_button.text = "Confirm"
	confirm_button.custom_minimum_size = Vector2(100, 40)
	button_container.add_child(confirm_button)
	
	# Cancel button
	cancel_button = Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(100, 40)
	button_container.add_child(cancel_button)

func setup_dialog_styling():
	"""Style the dialog components"""
	# Style the dialog panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.2, 0.2, 0.95)
	panel_style.border_color = Color(0.4, 0.4, 0.4)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	dialog_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Style title label
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Style message label
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	
	# Style confirm button (green)
	var confirm_style = StyleBoxFlat.new()
	confirm_style.bg_color = Color(0.2, 0.8, 0.2)
	confirm_style.corner_radius_top_left = 4
	confirm_style.corner_radius_top_right = 4
	confirm_style.corner_radius_bottom_left = 4
	confirm_style.corner_radius_bottom_right = 4
	confirm_button.add_theme_stylebox_override("normal", confirm_style)
	confirm_button.add_theme_color_override("font_color", Color.WHITE)
	
	# Style cancel button (red)
	var cancel_style = StyleBoxFlat.new()
	cancel_style.bg_color = Color(0.8, 0.2, 0.2)
	cancel_style.corner_radius_top_left = 4
	cancel_style.corner_radius_top_right = 4
	cancel_style.corner_radius_bottom_left = 4
	cancel_style.corner_radius_bottom_right = 4
	cancel_button.add_theme_stylebox_override("normal", cancel_style)
	cancel_button.add_theme_color_override("font_color", Color.WHITE)

func connect_signals():
	"""Connect button signals"""
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Allow ESC key to cancel
	set_process_input(true)

func _input(event: InputEvent):
	"""Handle ESC key to cancel dialog"""
	if visible and event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			_on_cancel_pressed()

func position_dialog():
	"""Position dialog in center of screen"""
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Fill the entire viewport with background
	background.size = viewport_size
	background.position = Vector2.ZERO
	
	# Center the dialog panel
	dialog_panel.position = Vector2(
		(viewport_size.x - dialog_size.x) / 2,
		(viewport_size.y - dialog_size.y) / 2
	)

func layout_dialog_contents():
	"""Layout the contents within the dialog panel"""
	var margin = 20
	
	# Position title
	title_label.position = Vector2(margin, margin)
	title_label.size = Vector2(dialog_size.x - margin * 2, 30)
	
	# Position message
	message_label.position = Vector2(margin, margin + 40)
	message_label.size = Vector2(dialog_size.x - margin * 2, 80)
	
	# Position button container
	button_container.position = Vector2(margin, dialog_size.y - 60)
	button_container.size = Vector2(dialog_size.x - margin * 2, 40)

func show_dialog(title: String, message: String, action_data: Dictionary = {}):
	"""Show the confirmation dialog with custom title and message"""
	title_label.text = title
	message_label.text = message
	current_action_data = action_data
	
	position_dialog()
	layout_dialog_contents()
	
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Focus the confirm button for keyboard navigation
	confirm_button.grab_focus()
	
	# Animate the dialog in
	animate_dialog_in()

func hide_dialog():
	"""Hide the confirmation dialog"""
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_action_data.clear()

func animate_dialog_in():
	"""Animate dialog appearing"""
	# Start with dialog scaled down and fade in
	dialog_panel.scale = Vector2(0.8, 0.8)
	dialog_panel.modulate.a = 0.0
	
	var tween = create_tween()
	tween.parallel().tween_property(dialog_panel, "scale", Vector2(1.0, 1.0), 0.2)
	tween.parallel().tween_property(dialog_panel, "modulate:a", 1.0, 0.2)

func animate_dialog_out():
	"""Animate dialog disappearing"""
	var tween = create_tween()
	tween.parallel().tween_property(dialog_panel, "scale", Vector2(0.8, 0.8), 0.15)
	tween.parallel().tween_property(dialog_panel, "modulate:a", 0.0, 0.15)
	tween.tween_callback(hide_dialog)

func _on_confirm_pressed():
	"""Handle confirm button press"""
	confirmed.emit(current_action_data)
	animate_dialog_out()

func _on_cancel_pressed():
	"""Handle cancel button press"""
	cancelled.emit()
	animate_dialog_out()

# Convenience methods for common dialog types
func show_movement_confirmation(target_tile: BiomeTile):
	"""Show movement confirmation dialog"""
	var biome_name = target_tile.get_biome_data(target_tile.biome_type).name
	var title = "Confirm Movement"
	var message = "Move to %s at (%d, %d)?" % [biome_name, target_tile.grid_position.x, target_tile.grid_position.y]
	var action_data = {
		"action_type": "movement",
		"target_position": target_tile.grid_position,
		"target_tile": target_tile
	}
	show_dialog(title, message, action_data)

func show_build_confirmation(target_tile: BiomeTile, building_type: String):
	"""Show building confirmation dialog"""
	var biome_name = target_tile.get_biome_data(target_tile.biome_type).name
	var title = "Confirm Building"
	var message = "Build %s on %s at (%d, %d)?" % [building_type.capitalize().replace("_", " "), biome_name, target_tile.grid_position.x, target_tile.grid_position.y]
	var action_data = {
		"action_type": "building",
		"target_position": target_tile.grid_position,
		"target_tile": target_tile,
		"building_type": building_type
	}
	show_dialog(title, message, action_data)

func show_attack_confirmation(target_tile: BiomeTile):
	"""Show attack confirmation dialog"""
	var biome_name = target_tile.get_biome_data(target_tile.biome_type).name
	var title = "Confirm Attack"
	var message = "Attack target at %s (%d, %d)?" % [biome_name, target_tile.grid_position.x, target_tile.grid_position.y]
	var action_data = {
		"action_type": "attack",
		"target_position": target_tile.grid_position,
		"target_tile": target_tile
	}
	show_dialog(title, message, action_data)

func show_interact_confirmation(target_tile: BiomeTile, interaction_type: String):
	"""Show interaction confirmation dialog"""
	var biome_name = target_tile.get_biome_data(target_tile.biome_type).name
	var title = "Confirm Interaction"
	var message = "%s with %s at (%d, %d)?" % [interaction_type, biome_name, target_tile.grid_position.x, target_tile.grid_position.y]
	var action_data = {
		"action_type": "interaction",
		"target_position": target_tile.grid_position,
		"target_tile": target_tile,
		"interaction_type": interaction_type
	}
	show_dialog(title, message, action_data)

func show_custom_confirmation(title: String, message: String, confirm_text: String = "Confirm", cancel_text: String = "Cancel", custom_data: Dictionary = {}):
	"""Show a custom confirmation dialog"""
	confirm_button.text = confirm_text
	cancel_button.text = cancel_text
	show_dialog(title, message, custom_data)
