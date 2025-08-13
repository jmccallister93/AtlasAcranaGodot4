# ItemDetailView.gd - Item detail menu with source navigation
extends BaseMenu
class_name ItemDetailView

signal detail_view_closed
signal item_action_completed(action: String, item: BaseItem, slot_index: int)

# Data
var current_item: BaseItem
var current_slot_index: int = -1
var source_menu: String = "inventory"  # Track which menu opened this view
var inventory_manager: InventoryManager

# UI Components (created fresh each time)
var item_info_container: HBoxContainer
var action_buttons_container: VBoxContainer

func ready_post():
	"""Override BaseMenu's ready_post to setup item detail specific UI"""
	menu_title = "Item Details"
	title_label.text = menu_title
	
	connect_to_inventory_manager()
	
	# Connect BaseMenu's inventory_closed signal to our detail_view_closed signal
	inventory_closed.connect(func(): detail_view_closed.emit())

func connect_to_inventory_manager():
	"""Connect to InventoryManager for item operations"""
	inventory_manager = GameManager.manager_registry.inventory_manager

func show_for_item(item: BaseItem, slot_index: int = -1, source: String = "inventory"):
	"""Show detail view for a specific item"""
	if not item:
		print("Invalid item provided to ItemDetailView")
		return
	
	current_item = item
	current_slot_index = slot_index
	source_menu = source
	
	print("Showing item detail for: ", item.item_name, " from: ", source)
	
	create_item_details_ui()
	show_menu()  # Use BaseMenu's show_menu() method

func create_item_details_ui():
	"""Create UI showing details for the selected item"""
	clear_item_container()
	
	# Update title
	if current_item:
		title_label.text = current_item.item_name + " - Details"
	
	# Create fresh info container each time
	item_info_container = HBoxContainer.new()
	item_info_container.name = "ItemInfo"
	item_info_container.add_theme_constant_override("separation", 15)
	
	# Add info container to the BaseMenu's item_container
	item_container.add_child(item_info_container)
	
	if not current_item:
		var error_label = Label.new()
		error_label.text = "Item no longer exists"
		error_label.add_theme_color_override("font_color", Color.RED)
		item_info_container.add_child(error_label)
		return
	
	# Left side - Item information panel
	var info_panel = create_item_info_panel()
	item_info_container.add_child(info_panel)
	
	# Right side - Actions panel
	var actions_panel = create_actions_panel()
	item_info_container.add_child(actions_panel)

func create_item_info_panel() -> Control:
	"""Create detailed information panel for the current item"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 0)  # Give it a good width
	
	# Style the info panel with rarity-based border
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	panel_style.border_color = current_item.get_rarity_color()
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 15
	panel_style.content_margin_bottom = 15
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Content container
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	
	# Item icon and basic info
	var header_section = create_item_header_section()
	content.add_child(header_section)
	
	# Description
	var description_section = create_description_section()
	content.add_child(description_section)
	
	# Properties section
	var properties_section = create_properties_section()
	content.add_child(properties_section)
	
	# Effects section (for consumables)
	if current_item.item_type == BaseItem.ItemType.CONSUMABLE:
		var effects_section = create_effects_section()
		content.add_child(effects_section)
	
	panel.add_child(content)
	return panel

func create_item_header_section() -> HBoxContainer:
	"""Create the header section with icon and basic info"""
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 15)
	
	# Item icon
	var icon_container = create_item_icon()
	header.add_child(icon_container)
	
	# Basic info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Item name with rarity color
	var name_label = Label.new()
	name_label.text = current_item.item_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", current_item.get_rarity_color())
	info_vbox.add_child(name_label)
	
	# Item type
	var type_label = Label.new()
	type_label.text = current_item.get_type_name()
	type_label.add_theme_font_size_override("font_size", 14)
	type_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	info_vbox.add_child(type_label)
	
	# Rarity
	var rarity_label = Label.new()
	rarity_label.text = BaseItem.ItemRarity.keys()[current_item.rarity].capitalize() + " Quality"
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.add_theme_color_override("font_color", current_item.get_rarity_color())
	info_vbox.add_child(rarity_label)
	
	# Quantity (if from inventory slot)
	if current_slot_index >= 0 and inventory_manager:
		var slot = inventory_manager.get_slot(current_slot_index)
		if slot and not slot.is_empty() and slot.quantity > 1:
			var quantity_label = Label.new()
			quantity_label.text = "Quantity: " + str(slot.quantity)
			quantity_label.add_theme_font_size_override("font_size", 12)
			quantity_label.add_theme_color_override("font_color", Color.WHITE)
			info_vbox.add_child(quantity_label)
	
	header.add_child(info_vbox)
	return header

func create_item_icon() -> PanelContainer:
	"""Create an icon container for the item"""
	var icon_container = PanelContainer.new()
	icon_container.custom_minimum_size = Vector2(80, 80)
	
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	icon_style.border_color = current_item.get_rarity_color()
	icon_style.border_width_left = 2
	icon_style.border_width_right = 2
	icon_style.border_width_top = 2
	icon_style.border_width_bottom = 2
	icon_style.corner_radius_top_left = 6
	icon_style.corner_radius_top_right = 6
	icon_style.corner_radius_bottom_left = 6
	icon_style.corner_radius_bottom_right = 6
	icon_container.add_theme_stylebox_override("panel", icon_style)
	
	var icon = TextureRect.new()
	# Try to load item icon, fall back to default
	var icon_texture = null
	if current_item.icon_path != "":
		icon_texture = load(current_item.icon_path)
	if not icon_texture:
		icon_texture = preload("res://assets/ui/menus/default.png")
	
	icon.texture = icon_texture
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(60, 60)
	icon_container.add_child(icon)
	
	return icon_container

func create_description_section() -> VBoxContainer:
	"""Create description section"""
	var section = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "Description"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	section.add_child(title)
	
	var desc_label = Label.new()
	desc_label.text = current_item.description if current_item.description != "" else "No description available."
	desc_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section.add_child(desc_label)
	
	return section

func create_properties_section() -> VBoxContainer:
	"""Create properties section"""
	var section = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "Properties"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.6))
	section.add_child(title)
	
	# Stackable
	var stackable_label = Label.new()
	stackable_label.text = "Stackable: " + ("Yes" if current_item.can_stack() else "No")
	stackable_label.add_theme_color_override("font_color", Color.WHITE)
	section.add_child(stackable_label)
	
	# Droppable
	var droppable_label = Label.new()
	droppable_label.text = "Droppable: " + ("Yes" if current_item.is_droppable else "No")
	droppable_label.add_theme_color_override("font_color", Color.WHITE)
	section.add_child(droppable_label)
	
	# Value (if implemented)
	if current_item.has_method("get_value"):
		var value_label = Label.new()
		value_label.text = "Value: " + str(current_item.get_value()) + " gold"
		value_label.add_theme_color_override("font_color", Color.YELLOW)
		section.add_child(value_label)
	
	return section

func create_effects_section() -> VBoxContainer:
	"""Create effects section for consumable items"""
	var section = VBoxContainer.new()
	
	var consumable_item = current_item as ConsumableItem
	if not consumable_item:
		return section
	
	var title = Label.new()
	title.text = "Effects"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 1.0))
	section.add_child(title)
	
	# This would depend on your ConsumableItem implementation
	# For now, show generic effect info
	var effect_label = Label.new()
	effect_label.text = "Use this item to gain its benefits"
	effect_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	section.add_child(effect_label)
	
	return section

func create_actions_panel() -> VBoxContainer:
	"""Create actions panel with context-sensitive buttons"""
	var panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 10)
	panel.custom_minimum_size = Vector2(200, 0)
	
	var title = Label.new()
	title.text = "Actions"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	
	# Create action buttons based on item type
	var buttons_container = VBoxContainer.new()
	buttons_container.add_theme_constant_override("separation", 8)
	
	match current_item.item_type:
		BaseItem.ItemType.CONSUMABLE:
			create_consumable_actions(buttons_container)
		_:
			create_generic_actions(buttons_container)
	
	# Always add generic actions
	add_generic_actions(buttons_container)
	
	panel.add_child(buttons_container)
	return panel

func create_consumable_actions(container: VBoxContainer):
	"""Create actions for consumable items"""
	var use_button = create_action_button("Use Item", Color.CYAN)
	use_button.pressed.connect(_on_use_button_pressed)
	container.add_child(use_button)

func create_generic_actions(container: VBoxContainer):
	"""Create actions for other item types"""
	var examine_button = create_action_button("Examine", Color.GRAY)
	examine_button.pressed.connect(_on_examine_button_pressed)
	container.add_child(examine_button)

func add_generic_actions(container: VBoxContainer):
	"""Add generic actions available for all items"""
	# Only show drop button if we have a valid slot index
	if current_slot_index >= 0:
		var drop_button = create_action_button("Drop Item", Color.RED)
		drop_button.pressed.connect(_on_drop_button_pressed)
		
		if not current_item.is_droppable:
			drop_button.disabled = true
			drop_button.tooltip_text = "This item cannot be dropped"
		
		container.add_child(drop_button)
	
	# Back button (goes to source menu)
	var back_button = create_action_button("Back to " + source_menu.capitalize(), Color.BLUE)
	back_button.pressed.connect(_on_back_button_pressed)
	container.add_child(back_button)
	
	# Close button
	var close_button = create_action_button("Close", Color.DARK_GRAY)
	close_button.pressed.connect(hide_menu)
	container.add_child(close_button)

func create_action_button(text: String, color: Color) -> Button:
	"""Create a styled action button"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180, 40)
	
	# Style the button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = color * 0.7
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_width_top = 2
	button_style.border_width_bottom = 2
	button_style.border_color = color
	button_style.corner_radius_top_left = 6
	button_style.corner_radius_top_right = 6
	button_style.corner_radius_bottom_left = 6
	button_style.corner_radius_bottom_right = 6
	button.add_theme_stylebox_override("normal", button_style)
	
	var button_hover_style = button_style.duplicate()
	button_hover_style.bg_color = color
	button.add_theme_stylebox_override("hover", button_hover_style)
	
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 14)
	
	return button

func clear_item_container():
	"""Clear the BaseMenu's item container"""
	for child in item_container.get_children():
		child.queue_free()

# Event Handlers
func _on_use_button_pressed():
	"""Handle use button press"""
	if current_slot_index >= 0 and inventory_manager:
		var success = inventory_manager.use_item_at_slot(current_slot_index)
		if success:
			item_action_completed.emit("use", current_item, current_slot_index)
			# Close the detail view since item was consumed
			hide_menu()
		else:
			if GameManager and GameManager.game_ui:
				GameManager.game_ui.show_error("Failed to use item")

func _on_drop_button_pressed():
	"""Handle drop button press"""
	if current_slot_index >= 0 and inventory_manager:
		var success = inventory_manager.drop_item_at_slot(current_slot_index, 1)
		if success:
			item_action_completed.emit("drop", current_item, current_slot_index)
			
			# Go back to source menu
			_on_back_button_pressed()
		else:
			if GameManager and GameManager.game_ui:
				GameManager.game_ui.show_error("Cannot drop this item")

func _on_back_button_pressed():
	"""Handle back button press - return to source menu"""
	hide_menu()
	
	# Navigate back to the source menu
	if GameManager and GameManager.game_ui:
		match source_menu:
			"inventory":
				GameManager.game_ui._on_inventory_button_pressed()
			"equipment":
				GameManager.game_ui._on_equipment_button_pressed()
			_:
				print("Unknown source menu: ", source_menu)

func _on_examine_button_pressed():
	"""Handle examine button press - show detailed info in console"""
	print("=== ITEM EXAMINATION ===")
	print("Name: ", current_item.item_name)
	print("ID: ", current_item.item_id)
	print("Type: ", current_item.get_type_name())
	print("Rarity: ", BaseItem.ItemRarity.keys()[current_item.rarity])
	print("Description: ", current_item.description)
	print("Stackable: ", current_item.can_stack())
	print("Droppable: ", current_item.is_droppable)
	print("========================")
	
	if GameManager and GameManager.game_ui:
		GameManager.game_ui.show_info("Item examination complete - check console for details")

# Public interface
func is_showing() -> bool:
	"""Check if the detail view is currently showing"""
	return visible

func get_current_item() -> BaseItem:
	"""Get the currently viewed item"""
	return current_item

# Override BaseMenu's hide_menu to emit our specific signal
func hide_menu():
	super.hide_menu()  # Call BaseMenu's hide_menu()
	detail_view_closed.emit()

# Handle input to close with Escape key
func _input(event):
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		hide_menu()
		get_viewport().set_input_as_handled()
