extends BaseMenu
class_name InventoryMenu

@onready var add_button 
@onready var remove_button
@onready var item_box
var selected_item_box: Panel = null


func ready_post():
	menu_title = "Inventory"
	title_label.text = menu_title 
	populate_inventory(["Sword", "Potion", "Book", "Shield", "Gloves", "Fireball", "Helmet", "Boots", "Bag", "Chest"])
	create_add_button()
	create_remove_button()


func create_add_button():
	add_button = Button.new()
	add_button.pressed.connect(_on_add_button_pressed)
	add_button.text = "Add"
	
	# Use set_anchors_and_offsets_preset for cleaner positioning
	add_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	
	# Add to scene tree
	add_child(add_button)


func create_remove_button():
	remove_button = Button.new()
	remove_button.pressed.connect(_on_remove_button_pressed)
	remove_button.text = "Remove"
	
	# Use set_anchors_and_offsets_preset for cleaner positioning
	remove_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	
	# Add to scene tree
	add_child(remove_button)

func _on_remove_button_pressed():
	if item_container.get_child_count() > 0:
		var item_to_remove = selected_item_box  # Or whichever index you want
		item_to_remove.queue_free()

func _on_add_button_pressed():
	add_item("New", preload("res://assets/ui/menus/default.png"))


func populate_inventory(item_names: Array):
	for child in item_container.get_children():
		child.queue_free()

	for name in item_names:
		var icon_path = "res://assets/ui/menus/%s.png" % name.to_lower()
		var icon_texture = load(icon_path)
		if not icon_texture:
			icon_texture = preload("res://assets/ui/menus/default.png")

		add_item(name, icon_texture)


func add_item(name: String, icon_texture: Texture2D):
	var panel = Panel.new()
	panel.name = "ItemPanel"
	panel.custom_minimum_size = Vector2(128, 164)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS

	# Set default border style
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_border_color(Color.DODGER_BLUE)
	style.set_border_width(SIDE_LEFT, 1)
	style.set_border_width(SIDE_RIGHT, 1)
	style.set_border_width(SIDE_TOP, 1)
	style.set_border_width(SIDE_BOTTOM, 1)
	panel.add_theme_stylebox_override("panel", style)

	# VBoxContainer inside the panel
	var item_box = VBoxContainer.new()
	item_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_box.mouse_filter = Control.MOUSE_FILTER_IGNORE  # so the panel catches clicks

	# Icon
	var icon = TextureRect.new()
	icon.texture = icon_texture
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(64, 64)
	icon.size_flags_horizontal = Control.SIZE_FILL
	item_box.add_child(icon)

	# Label
	var label = Label.new()
	label.text = name
	label.add_theme_color_override("font_color", Color.WHITE_SMOKE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_box.add_child(label)

	panel.add_child(item_box)

	# Connect input
	panel.gui_input.connect(_on_item_box_input.bind(panel))

	item_container.add_child(panel)

func _on_item_box_input(event: InputEvent, item: Panel):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		highlight_selected_item(item)


func highlight_selected_item(item: Panel):
	# Deselect previous
	if selected_item_box:
		var prev_stylebox = selected_item_box.get_theme_stylebox("panel") as StyleBoxFlat
		prev_stylebox.bg_color = Color.TRANSPARENT

	# Highlight new
	selected_item_box = item
	var stylebox = selected_item_box.get_theme_stylebox("panel") as StyleBoxFlat
	stylebox.bg_color = Color.DODGER_BLUE.darkened(0.5)
