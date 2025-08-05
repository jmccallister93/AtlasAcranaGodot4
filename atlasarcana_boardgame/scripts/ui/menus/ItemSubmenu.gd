extends Control
class_name ItemSubmenu

signal item_action_selected(action: String, item_data: Dictionary)
signal submenu_closed()

var item_icon: TextureRect
var item_name: Label
var item_description: Label
var action_buttons_container: VBoxContainer


var current_item_data: Dictionary

func setup_item(item_data: Dictionary):
	current_item_data = item_data
	
	# Clear previous children if reused (defensive)
	for child in get_children():
		child.queue_free()

	# Root VBox for layout
	var root = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(root)

	# Icon
	item_icon = TextureRect.new()
	item_icon.texture = item_data.get("texture")
	item_icon.custom_minimum_size = Vector2(64, 64)
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(item_icon)

	# Name
	item_name = Label.new()
	item_name.text = item_data.get("name", "Unknown Item")
	item_name.add_theme_color_override("font_color", Color.WHITE)
	item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(item_name)

	# Description
	item_description = Label.new()
	item_description.text = item_data.get("description", "No description available")
	item_description.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	item_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_description.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(item_description)

	# Action Buttons Container
	action_buttons_container = VBoxContainer.new()
	action_buttons_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	action_buttons_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_buttons_container.add_theme_constant_override("separation", 8)
	root.add_child(action_buttons_container)

	# Create action buttons
	create_action_buttons(item_data)

func create_action_buttons(item_data: Dictionary):
	var actions = get_available_actions(item_data)
	
	for action in actions:
		var button = Button.new()
		button.text = action.capitalize()
		button.pressed.connect(_on_action_button_pressed.bind(action))
		action_buttons_container.add_child(button)

func get_available_actions(item_data: Dictionary) -> Array:
	# Return different actions based on item type
	var item_type = item_data.get("type", "misc")
	match item_type:
		"weapon", "armor":
			return ["equip", "examine", "drop"]
		"consumable":
			return ["use", "examine", "drop"]
		_:
			return ["examine", "drop"]

func _on_action_button_pressed(action: String):
	item_action_selected.emit(action, current_item_data)
	close_submenu()

func close_submenu():
	submenu_closed.emit()
	queue_free()

func _ready():
	# Add close button or ESC key handling
	if Input.is_action_just_pressed("ui_cancel"):
		close_submenu()
