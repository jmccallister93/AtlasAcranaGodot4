extends BaseMenu
class_name CharacterMenu

func ready_post():
	menu_title = "Character"
	title_label.text = menu_title 
	populate_character(["Stats", "Other", "Thing", ])


func populate_character(item_names: Array):
	# Clear existing items
	for child in item_container.get_children():
		child.queue_free()

	# Create new labels dynamically
	for name in item_names:
		var label = Label.new()
		label.text = name
		label.add_theme_color_override("font_color", Color.BLUE)
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color.LIGHT_BLUE
		label.add_theme_stylebox_override("normal", stylebox)
		item_container.add_child(label)
