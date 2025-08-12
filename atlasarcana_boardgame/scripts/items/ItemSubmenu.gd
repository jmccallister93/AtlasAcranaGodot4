# ItemSubmenu.gd - Context menu for inventory items
extends Control
class_name ItemSubmenu

signal item_action_selected(action: String, item_data: Dictionary)
signal submenu_closed

var item_data: Dictionary = {}
var action_buttons: VBoxContainer

func _ready():
	# Make sure submenu appears above everything
	z_index = 1000
	mouse_filter = Control.MOUSE_FILTER_STOP

func setup_item(data: Dictionary):
	"""Setup the submenu with item data"""
	item_data = data
	create_submenu_ui()

func create_submenu_ui():
	"""Create the submenu interface"""
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	# Create main panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 0)
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	panel_style.border_color = Color.WHITE
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Create button container
	action_buttons = VBoxContainer.new()
	action_buttons.add_theme_constant_override("separation", 4)
	
	# Add item name header
	var item_name_label = Label.new()
	item_name_label.text = item_data.get("name", "Unknown Item")
	item_name_label.add_theme_color_override("font_color", Color.YELLOW)
	item_name_label.add_theme_font_size_override("font_size", 12)
	item_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_buttons.add_child(item_name_label)
	
	# Add separator
	var separator = HSeparator.new()
	separator.add_theme_color_override("separator", Color(0.5, 0.5, 0.5))
	action_buttons.add_child(separator)
	
	# Create action buttons based on item type
	create_action_buttons()
	
	panel.add_child(action_buttons)
	add_child(panel)

func create_action_buttons():
	"""Create appropriate action buttons based on item type"""
	var item_type = item_data.get("type", "")
	
	# Details button (always available)
	if item_data.get("has_details", false):
		var details_button = create_submenu_button("📋 Details", "details")
		action_buttons.add_child(details_button)
	
	# Type-specific buttons
	match item_type:
		"equipment":
			var equip_button = create_submenu_button("⚔️ Equip", "equip")
			action_buttons.add_child(equip_button)
			
		"consumable":
			var use_button = create_submenu_button("🍺 Use", "use")
			action_buttons.add_child(use_button)
	
	# Common buttons
	var examine_button = create_submenu_button("🔍 Examine", "examine")
	action_buttons.add_child(examine_button)
	
	# Only show drop if item is droppable (you might need to pass this info)
	var drop_button = create_submenu_button("🗑️ Drop", "drop")
	action_buttons.add_child(drop_button)
	
	# Cancel button
	var cancel_button = create_submenu_button("❌ Cancel", "cancel")
	action_buttons.add_child(cancel_button)

func create_submenu_button(text: String, action: String) -> Button:
	"""Create a submenu action button"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(130, 25)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Style the button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color.TRANSPARENT
	button_style.content_margin_left = 5
	button.add_theme_stylebox_override("normal", button_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.3, 0.3, 0.8)
	hover_style.content_margin_left = 5
	button.add_theme_stylebox_override("hover", hover_style)
	
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 11)
	
	# Connect button
	button.pressed.connect(_on_action_button_pressed.bind(action))
	
	return button

func _on_action_button_pressed(action: String):
	"""Handle action button press"""
	if action == "cancel":
		close_submenu()
	else:
		item_action_selected.emit(action, item_data)
		close_submenu()

func close_submenu():
	"""Close the submenu"""
	submenu_closed.emit()
	queue_free()

# Close submenu if clicked outside
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		close_submenu()

# Handle escape key
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_submenu()
		get_viewport().set_input_as_handled()
