# EquipmentDetailView.gd - Equipment detail menu for equipment items
extends BaseMenu
class_name EquipmentDetailView

signal detail_view_closed
signal equipment_action_completed(action: String, item: BaseItem, slot_index: int)

# Data
var current_item: BaseItem
var current_slot_index: int = -1
var source_menu: String = "equipment"  # Track which menu opened this view
var inventory_manager: InventoryManager
var equipment_manager: EquipmentManager

# UI Components (created fresh each time)
var item_info_container: HBoxContainer
var action_buttons_container: VBoxContainer

func ready_post():
	"""Override BaseMenu's ready_post to setup equipment detail specific UI"""
	menu_title = "Equipment Details"
	title_label.text = menu_title
	
	connect_to_managers()
	
	# Connect BaseMenu's inventory_closed signal to our detail_view_closed signal
	inventory_closed.connect(func(): detail_view_closed.emit())

func connect_to_managers():
	"""Connect to managers for equipment operations"""
	if GameManager and GameManager.inventory_manager:
		inventory_manager = GameManager.inventory_manager
		print("✅ EquipmentDetailView connected to InventoryManager")
	
	if GameManager and GameManager.character and GameManager.character.equipment_manager:
		equipment_manager = GameManager.character.equipment_manager
		print("✅ EquipmentDetailView connected to EquipmentManager")

func show_for_item(item: BaseItem, slot_index: int = -1, source: String = "equipment"):
	"""Show detail view for a specific equipment item"""
	if not item:
		print("Invalid item provided to EquipmentDetailView")
		return
	
	current_item = item
	current_slot_index = slot_index
	source_menu = source
	
	print("Showing equipment detail for: ", item.item_name, " from: ", source)
	
	create_equipment_details_ui()
	show_menu()  # Use BaseMenu's show_menu() method

func create_equipment_details_ui():
	"""Create UI showing details for the selected equipment item"""
	clear_item_container()
	
	# Update title
	if current_item:
		title_label.text = current_item.item_name + " - Equipment Details"
	
	# Create fresh info container each time
	item_info_container = HBoxContainer.new()
	item_info_container.name = "EquipmentInfo"
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
	var info_panel = create_equipment_info_panel()
	item_info_container.add_child(info_panel)
	
	# Right side - Actions panel
	var actions_panel = create_actions_panel()
	item_info_container.add_child(actions_panel)

func create_equipment_info_panel() -> Control:
	"""Create detailed information panel for the current equipment item"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(450, 0)  # Wider for equipment details
	
	# Style the info panel with rarity-based border
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
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
	content.add_theme_constant_override("separation", 15)
	
	# Item icon and basic info
	var header_section = create_equipment_header_section()
	content.add_child(header_section)
	
	# Description
	var description_section = create_description_section()
	content.add_child(description_section)
	
	# Stats (for equipment)
	var stats_section = create_stats_section()
	content.add_child(stats_section)
	
	# Compatible slots section
	var slots_section = create_compatible_slots_section()
	content.add_child(slots_section)
	
	# Properties section
	var properties_section = create_properties_section()
	content.add_child(properties_section)
	
	# Current equipment status
	var status_section = create_equipment_status_section()
	content.add_child(status_section)
	
	panel.add_child(content)
	return panel

func create_equipment_header_section() -> HBoxContainer:
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
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", current_item.get_rarity_color())
	info_vbox.add_child(name_label)
	
	# Item type
	var type_label = Label.new()
	type_label.text = "Equipment - " + current_item.get_type_name()
	type_label.add_theme_font_size_override("font_size", 14)
	type_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	info_vbox.add_child(type_label)
	
	# Rarity
	var rarity_label = Label.new()
	rarity_label.text = BaseItem.ItemRarity.keys()[current_item.rarity].capitalize() + " Quality"
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.add_theme_color_override("font_color", current_item.get_rarity_color())
	info_vbox.add_child(rarity_label)
	
	# Quantity (if from inventory slot and > 1)
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
	"""Create an icon container for the equipment item"""
	var icon_container = PanelContainer.new()
	icon_container.custom_minimum_size = Vector2(90, 90)
	
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color(0.2, 0.2, 0.25, 0.8)
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
	icon.custom_minimum_size = Vector2(70, 70)
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

func create_stats_section() -> VBoxContainer:
	"""Create stats section for equipment items"""
	var section = VBoxContainer.new()
	
	var equipment_item = current_item as EquipmentItem
	if not equipment_item or equipment_item.stat_modifiers.is_empty():
		return section
	
	var title = Label.new()
	title.text = "Statistics"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	section.add_child(title)
	
	# Create a grid for better stat display
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 5)
	
	for stat_name in equipment_item.stat_modifiers:
		var stat_value = equipment_item.stat_modifiers[stat_name]
		
		# Stat name
		var stat_name_label = Label.new()
		stat_name_label.text = stat_name.replace("_", " ").capitalize() + ":"
		stat_name_label.add_theme_color_override("font_color", Color.WHITE)
		stat_name_label.add_theme_font_size_override("font_size", 14)
		stats_grid.add_child(stat_name_label)
		
		# Stat value
		var stat_value_label = Label.new()
		var prefix = "+" if stat_value > 0 else ""
		stat_value_label.text = prefix + str(stat_value)
		
		# Color based on positive/negative
		var stat_color = Color.GREEN if stat_value > 0 else Color.RED if stat_value < 0 else Color.WHITE
		stat_value_label.add_theme_color_override("font_color", stat_color)
		stat_value_label.add_theme_font_size_override("font_size", 14)
		stat_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats_grid.add_child(stat_value_label)
	
	section.add_child(stats_grid)
	return section

func create_compatible_slots_section() -> VBoxContainer:
	"""Create compatible slots section"""
	var section = VBoxContainer.new()
	
	var equipment_item = current_item as EquipmentItem
	if not equipment_item or equipment_item.compatible_slots.is_empty():
		return section
	
	var title = Label.new()
	title.text = "Compatible Equipment Slots"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	section.add_child(title)
	
	var slots_text = []
	for slot_type in equipment_item.compatible_slots:
		slots_text.append(EquipmentSlot.SlotType.keys()[slot_type].replace("_", " ").capitalize())
	
	var slots_label = Label.new()
	slots_label.text = ", ".join(slots_text)
	slots_label.add_theme_color_override("font_color", Color.CYAN)
	slots_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section.add_child(slots_label)
	
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

func create_equipment_status_section() -> VBoxContainer:
	"""Create equipment status section"""
	var section = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "Equipment Status"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	section.add_child(title)
	
	var equipment_item = current_item as EquipmentItem
	if not equipment_item or not equipment_manager:
		var no_info_label = Label.new()
		no_info_label.text = "No equipment status available"
		no_info_label.add_theme_color_override("font_color", Color.GRAY)
		section.add_child(no_info_label)
		return section
	
	# Check if this item is currently equipped
	var equipped_slots = []
	for slot_type in equipment_item.compatible_slots:
		var equipped_item = equipment_manager.get_equipped_item(slot_type)
		if equipped_item and equipped_item.item_id == current_item.item_id:
			equipped_slots.append(EquipmentSlot.SlotType.keys()[slot_type].replace("_", " ").capitalize())
	
	if equipped_slots.size() > 0:
		var equipped_label = Label.new()
		equipped_label.text = "Currently Equipped In: " + ", ".join(equipped_slots)
		equipped_label.add_theme_color_override("font_color", Color.GREEN)
		section.add_child(equipped_label)
	else:
		var not_equipped_label = Label.new()
		not_equipped_label.text = "Not Currently Equipped"
		not_equipped_label.add_theme_color_override("font_color", Color.GRAY)
		section.add_child(not_equipped_label)
	
	return section

func create_actions_panel() -> VBoxContainer:
	"""Create actions panel with equipment-specific buttons"""
	var panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 10)
	panel.custom_minimum_size = Vector2(200, 0)
	
	var title = Label.new()
	title.text = "Actions"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	
	# Create action buttons
	var buttons_container = VBoxContainer.new()
	buttons_container.add_theme_constant_override("separation", 8)
	
	create_equipment_actions(buttons_container)
	add_generic_actions(buttons_container)
	
	panel.add_child(buttons_container)
	return panel

func create_equipment_actions(container: VBoxContainer):
	"""Create actions for equipment items"""
	var equipment_item = current_item as EquipmentItem
	if not equipment_item:
		return
	
	# Check current equipment status
	var is_equipped = false
	var equipped_slot_type = null
	
	if equipment_manager:
		for slot_type in equipment_item.compatible_slots:
			var equipped_item = equipment_manager.get_equipped_item(slot_type)
			if equipped_item and equipped_item.item_id == current_item.item_id:
				is_equipped = true
				equipped_slot_type = slot_type
				break
	
	if is_equipped:
		# Show unequip button
		var unequip_button = create_action_button("Unequip", Color.ORANGE)
		unequip_button.pressed.connect(_on_unequip_button_pressed.bind(equipped_slot_type))
		container.add_child(unequip_button)
	else:
		# Show equip button(s)
		if current_slot_index >= 0:  # Item is in inventory
			var equip_button = create_action_button("Equip Item", Color.GREEN)
			equip_button.pressed.connect(_on_equip_button_pressed)
			
			# Check if item can be equipped
			if equipment_manager:
				var can_equip = false
				for slot_type in equipment_item.compatible_slots:
					if equipment_manager.can_equip_item(equipment_item, slot_type):
						can_equip = true
						break
				
				if not can_equip:
					equip_button.disabled = true
					equip_button.tooltip_text = "Cannot equip this item"
			
			container.add_child(equip_button)

func add_generic_actions(container: VBoxContainer):
	"""Add generic actions available for equipment items"""
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
func _on_equip_button_pressed():
	"""Handle equip button press"""
	print("🔧 Equip button pressed for: ", current_item.item_name)
	
	if current_slot_index >= 0 and inventory_manager:
		var success = inventory_manager.equip_item_at_slot(current_slot_index)
		if success:
			print("✅ Successfully equipped: ", current_item.item_name)
			equipment_action_completed.emit("equip", current_item, current_slot_index)
			
			# Refresh the UI to show updated state
			create_equipment_details_ui()
		else:
			print("❌ Failed to equip: ", current_item.item_name)
			if GameManager and GameManager.game_ui:
				GameManager.game_ui.show_error("Failed to equip item")

func _on_unequip_button_pressed(slot_type: EquipmentSlot.SlotType):
	"""Handle unequip button press"""
	if equipment_manager:
		var unequipped_item = equipment_manager.unequip_item(slot_type)
		if unequipped_item:
			# Add back to inventory
			if inventory_manager:
				inventory_manager.add_item(unequipped_item, 1)
			
			equipment_action_completed.emit("unequip", current_item, current_slot_index)
			# Refresh the UI to show updated state
			create_equipment_details_ui()

func _on_drop_button_pressed():
	"""Handle drop button press"""
	if current_slot_index >= 0 and inventory_manager:
		var success = inventory_manager.drop_item_at_slot(current_slot_index, 1)
		if success:
			equipment_action_completed.emit("drop", current_item, current_slot_index)
			
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
			"equipment":
				GameManager.game_ui._on_equipment_button_pressed()
			"inventory":
				GameManager.game_ui._on_inventory_button_pressed()
			_:
				print("Unknown source menu: ", source_menu)

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
