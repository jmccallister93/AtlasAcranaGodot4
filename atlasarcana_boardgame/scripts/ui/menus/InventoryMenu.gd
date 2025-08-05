extends BaseMenu
class_name InventoryMenu

@onready var add_button 
@onready var remove_button
@onready var item_box
var selected_item_box: Panel = null
@onready var tooltip_panel = Panel.new()
@onready var tooltip_label = Label.new()
@onready var tooltip_timer = Timer.new()
var hovered_item: Control = null

var current_submenu: ItemSubmenu = null

func ready_post():
	menu_title = "Inventory"
	title_label.text = menu_title 
	populate_inventory(["Sword", "Potion", "Book", "Shield", "Gloves", "Fireball", "Helmet", "Boots", "Bag", "Chest"])
	create_add_button()
	create_remove_button()
	create_tooltip()


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

func create_tooltip():
	var style = StyleBoxFlat.new()
	style.bg_color = Color.DIM_GRAY
	style.set_border_color(Color.LIGHT_GRAY)
	style.set_border_width(SIDE_LEFT, 1)
	style.set_border_width(SIDE_RIGHT, 1)
	style.set_border_width(SIDE_TOP, 1)
	style.set_border_width(SIDE_BOTTOM, 1)
	
	tooltip_panel.visible = false
	tooltip_panel.z_index = 1000
	tooltip_panel.custom_minimum_size = Vector2(200, 50)
	tooltip_panel.set("theme_override_styles/panel", style)
	
	tooltip_label.text = ""
	tooltip_label.add_theme_color_override("font_color", Color.WHITE)
	tooltip_panel.add_child(tooltip_label)
	
	add_child(tooltip_panel)

	# Timer for hover delay
	tooltip_timer.wait_time = 1.0
	tooltip_timer.one_shot = true
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
	add_child(tooltip_timer)

func _on_remove_button_pressed():
	if item_container.get_child_count() > 0:
		var item_to_remove = selected_item_box  # Or whichever index you want
		item_to_remove.queue_free()

func _on_add_button_pressed():
	add_item("New", preload("res://assets/ui/menus/default.png"))

func _on_item_mouse_entered(item: Control, name: String):
	hovered_item = item
	tooltip_label.text = "Details about: " + name  # Replace with real data
	tooltip_timer.start()

func _on_item_mouse_exited():
	hovered_item = null
	tooltip_timer.stop()
	tooltip_panel.visible = false

func _on_tooltip_timer_timeout():
	if hovered_item:
		var mouse_pos = get_viewport().get_mouse_position()
		var tooltip_size = tooltip_panel.get_size()
		var viewport_size = get_viewport().get_visible_rect().size
		var pos = mouse_pos + Vector2(10, 10)
		
		# Clamp so it doesn't go off the screen
		pos.x = clamp(pos.x, 0, viewport_size.x - tooltip_size.x)
		pos.y = clamp(pos.y, 0, viewport_size.y - tooltip_size.y)
		
		# Use global_position instead of position
		tooltip_panel.global_position = pos
		tooltip_panel.visible = true

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
	panel.set_meta("item_data", {
		"name": name,
		"texture": icon_texture,
		"type": "misc",  # You can pass this as a parameter too
		"description": "A mysterious " + name.to_lower()
	})

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
	item_box.name = "ItemContainer"
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
	
	#Add hover tooltip
	panel.mouse_entered.connect(_on_item_mouse_entered.bind(panel, name))
	panel.mouse_exited.connect(_on_item_mouse_exited)

	item_container.add_child(panel)

func _on_item_box_input(event: InputEvent, item: Panel):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			highlight_selected_item(item)
#			TODO
			#show_item_submenu(item)

func _on_item_hover(event: InputEvent, item: Panel):
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
	
func show_item_submenu(item: Panel):
	# Close existing submenu if open
	if current_submenu:
		current_submenu.queue_free()
	
	# Get item data (you'll need to store this in your item panels)
	var item_data = get_item_data_from_panel(item)
	
	# Create and setup submenu
	var submenu_scene = preload("res://scenes/ui/menus/ItemSubmenu.tscn")
	current_submenu = submenu_scene.instantiate()
	
	
	# Connect signals
	current_submenu.item_action_selected.connect(_on_item_action_selected)
	current_submenu.submenu_closed.connect(_on_submenu_closed)
		# Add to scene (use a CanvasLayer for proper layering)
	get_tree().current_scene.add_child(current_submenu)
	current_submenu.setup_item(item_data)
	# Position in the center of the viewport

	var viewport_size = get_viewport().get_visible_rect().size
	var submenu_size = current_submenu.get_size()
	var center_pos = (viewport_size - submenu_size) / 2

	current_submenu.global_position = center_pos
	
func get_item_data_from_panel(item: Panel) -> Dictionary:
	return item.get_meta("item_data", {})

func _on_item_action_selected(action: String, item_data: Dictionary):
	print("Action: ", action, " on item: ", item_data.name)
	# Handle the action (equip, use, drop, etc.)
	#match action:
		#"use":
			#use_item(item_data)
		#"equip":
			#equip_item(item_data)
		#"drop":
			#drop_item(item_data)
		#"examine":
			#examine_item(item_data)

func _on_submenu_closed():
	current_submenu = null
