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
	add_button.text = "Add Item"
	
	# Style the button
	add_button.add_theme_font_size_override("font_size", 14)
	add_button.add_theme_color_override("font_color", Color.WHITE)
	add_button.custom_minimum_size = Vector2(100, 35)
	
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color("#6A0DAD")  # Purple
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_width_top = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color("#9370DB")  # Medium purple
	button_style.corner_radius_top_left = 6
	button_style.corner_radius_top_right = 6
	button_style.corner_radius_bottom_left = 6
	button_style.corner_radius_bottom_right = 6
	add_button.add_theme_stylebox_override("normal", button_style)
	
	var button_hover_style = button_style.duplicate()
	button_hover_style.bg_color = Color("#8A2BE2")  # Brighter purple
	add_button.add_theme_stylebox_override("hover", button_hover_style)
	
	# Use set_anchors_and_offsets_preset for cleaner positioning
	add_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	add_button.offset_left = 10
	add_button.offset_bottom = -10
	
	# Add to scene tree
	add_child(add_button)

func create_remove_button():
	remove_button = Button.new()
	remove_button.pressed.connect(_on_remove_button_pressed)
	remove_button.text = "Remove Item"
	
	# Style the button
	remove_button.add_theme_font_size_override("font_size", 14)
	remove_button.add_theme_color_override("font_color", Color.WHITE)
	remove_button.custom_minimum_size = Vector2(100, 35)
	
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color("#8B0000")  # Dark red
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_width_top = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color("#DC143C")  # Crimson
	button_style.corner_radius_top_left = 6
	button_style.corner_radius_top_right = 6
	button_style.corner_radius_bottom_left = 6
	button_style.corner_radius_bottom_right = 6
	remove_button.add_theme_stylebox_override("normal", button_style)
	
	var button_hover_style = button_style.duplicate()
	button_hover_style.bg_color = Color("#B22222")  # Fire brick
	remove_button.add_theme_stylebox_override("hover", button_hover_style)
	
	# Use set_anchors_and_offsets_preset for cleaner positioning
	remove_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	remove_button.offset_right = -10
	remove_button.offset_bottom = -10
	
	# Add to scene tree
	add_child(remove_button)

func create_tooltip():
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2E1A47")  # Dark purple
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color("#9370DB")  # Medium purple
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	
	tooltip_panel.visible = false
	tooltip_panel.z_index = 1000
	tooltip_panel.custom_minimum_size = Vector2(200, 50)
	tooltip_panel.add_theme_stylebox_override("panel", style)
	
	tooltip_label.text = ""
	tooltip_label.add_theme_color_override("font_color", Color("#E6E6FA"))  # Lavender
	tooltip_label.add_theme_font_size_override("font_size", 12)
	#tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
		if item_to_remove:
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
		# Use local coordinates like the other menus
		var global_mouse_pos = get_global_mouse_position()
		var local_mouse_pos = global_mouse_pos - global_position
		
		# Offset tooltip to avoid covering the cursor
		var tooltip_pos = local_mouse_pos + Vector2(15, -15)
		
		# Keep tooltip within menu bounds
		var menu_rect = get_rect()
		tooltip_pos.x = clamp(tooltip_pos.x, 10, menu_rect.size.x - tooltip_panel.custom_minimum_size.x - 10)
		tooltip_pos.y = clamp(tooltip_pos.y, 10, menu_rect.size.y - 100)
		
		tooltip_panel.position = tooltip_pos
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

	# Set enhanced border style
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1A0D26")  # Very dark purple
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color("#483D8B")  # Dark slate blue
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	# VBoxContainer inside the panel
	var item_box = VBoxContainer.new()
	item_box.name = "ItemContainer"
	item_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_box.mouse_filter = Control.MOUSE_FILTER_IGNORE  # so the panel catches clicks
	item_box.add_theme_constant_override("separation", 6)

	# Icon with background
	var icon_container = PanelContainer.new()
	icon_container.custom_minimum_size = Vector2(80, 80)
	
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color("#2E1A47")  # Dark purple background
	icon_style.border_width_left = 1
	icon_style.border_width_right = 1
	icon_style.border_width_top = 1
	icon_style.border_width_bottom = 1
	icon_style.border_color = Color("#6A0DAD")  # Purple border
	icon_style.corner_radius_top_left = 6
	icon_style.corner_radius_top_right = 6
	icon_style.corner_radius_bottom_left = 6
	icon_style.corner_radius_bottom_right = 6
	icon_container.add_theme_stylebox_override("panel", icon_style)
	
	var icon = TextureRect.new()
	icon.texture = icon_texture
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(64, 64)
	icon.size_flags_horizontal = Control.SIZE_FILL
	icon_container.add_child(icon)
	item_box.add_child(icon_container)

	# Enhanced label
	var label = Label.new()
	label.text = name
	label.add_theme_color_override("font_color", Color("#E6E6FA"))  # Lavender
	label.add_theme_font_size_override("font_size", 13)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	# Deselect previous with enhanced styling
	if selected_item_box:
		var prev_stylebox = StyleBoxFlat.new()
		prev_stylebox.bg_color = Color("#1A0D26")  # Very dark purple
		prev_stylebox.border_width_left = 2
		prev_stylebox.border_width_right = 2
		prev_stylebox.border_width_top = 2
		prev_stylebox.border_width_bottom = 2
		prev_stylebox.border_color = Color("#483D8B")  # Dark slate blue
		prev_stylebox.corner_radius_top_left = 8
		prev_stylebox.corner_radius_top_right = 8
		prev_stylebox.corner_radius_bottom_left = 8
		prev_stylebox.corner_radius_bottom_right = 8
		prev_stylebox.content_margin_left = 8
		prev_stylebox.content_margin_right = 8
		prev_stylebox.content_margin_top = 8
		prev_stylebox.content_margin_bottom = 8
		selected_item_box.add_theme_stylebox_override("panel", prev_stylebox)

	# Highlight new with enhanced styling
	selected_item_box = item
	var selected_stylebox = StyleBoxFlat.new()
	selected_stylebox.bg_color = Color("#4B0082")  # Indigo background
	selected_stylebox.border_width_left = 3
	selected_stylebox.border_width_right = 3
	selected_stylebox.border_width_top = 3
	selected_stylebox.border_width_bottom = 3
	selected_stylebox.border_color = Color("#9370DB")  # Medium purple border
	selected_stylebox.corner_radius_top_left = 8
	selected_stylebox.corner_radius_top_right = 8
	selected_stylebox.corner_radius_bottom_left = 8
	selected_stylebox.corner_radius_bottom_right = 8
	selected_stylebox.content_margin_left = 8
	selected_stylebox.content_margin_right = 8
	selected_stylebox.content_margin_top = 8
	selected_stylebox.content_margin_bottom = 8
	selected_item_box.add_theme_stylebox_override("panel", selected_stylebox)
	
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
