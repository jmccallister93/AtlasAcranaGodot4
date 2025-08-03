extends BaseMenu
class_name InventoryMenu

func ready_post():
	menu_title = "Inventory"
	title_label.text = menu_title 
	populate_inventory(["Sword", "Potion", "Book", "Shield", "Gloves", "Fireball", "Helmet", "Boots", "Bag", "Chest"])


#For testing 
func populate_inventory(item_names: Array):
	# Clear existing items
	for child in item_container.get_children():
		child.queue_free()

	for name in item_names:
		var item_box = VBoxContainer.new()
		item_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_box.custom_minimum_size = Vector2(80, 100)  # Set fixed slot size

		# Load icon texture
		var icon_path = "res://assets/ui/menus/%s.png" % name.to_lower()
		var icon_texture = load(icon_path)
		if not icon_texture:
			icon_texture = preload("res://assets/ui/menus/default.png")

		# Create TextureRect
		var icon = TextureRect.new()
		icon.texture = icon_texture
		#icon.expand_mode = TextureRect.EXPAND_KEEP_ASPECT_CENTERED
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(64, 64)
		icon.size_flags_horizontal = Control.SIZE_FILL

		# Create Label
		var label = Label.new()
		label.text = name
		label.add_theme_color_override("font_color", Color.WHITE_SMOKE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		# Add both to item box
		item_box.add_child(icon)
		item_box.add_child(label)

		# Add to grid
		item_container.add_child(item_box)
