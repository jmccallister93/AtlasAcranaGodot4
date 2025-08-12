# EnhancedInventoryMenu.gd
extends BaseMenu
class_name InventoryMenu

# UI Components
@onready var add_button: Button
@onready var remove_button: Button
@onready var filter_buttons: HBoxContainer
@onready var tooltip_panel: PanelContainer
@onready var tooltip_label: RichTextLabel
@onready var tooltip_timer: Timer

# State
var inventory_manager: InventoryManager
var selected_slot_index: int = -1
var selected_item_panel: Panel = null
var hovered_item: Control = null
var current_filter: BaseItem.ItemType = BaseItem.ItemType.MISC  # Show all by default
var current_submenu: ItemSubmenu = null
var slot_counter_label: Label

# Visual components for each slot
var slot_panels: Array = []

func ready_post():
	menu_title = "Inventory"
	title_label.text = menu_title
	
	# Initialize inventory manager first
	setup_inventory_manager()
	
	# Create UI elements
	create_filter_buttons()
	create_slot_counter()  
	#create_action_buttons()
	create_tooltip()
	
	# Adjust item_container positioning AFTER creating header elements
	setup_item_container_layout()
	
	# Populate with test items for demo
	populate_with_test_items()
	
	# Refresh display
	refresh_inventory_display()
	
	# Update counter
	update_slot_counter()

func setup_item_container_layout():
	"""Setup the item container layout to avoid overlaps"""
	if item_container:
		# Position item container below all header elements
		# Title: 0-50, Filters: 50-90, Counter: 100-130, Padding: 130-140
		item_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		item_container.offset_top = 140   # Below all header elements
		item_container.offset_bottom = -90  # Space for action buttons (35px) + margins (55px)
		item_container.offset_left = 20
		item_container.offset_right = -20
	
	# Update counter
	update_slot_counter()

func setup_inventory_manager():
	"""Initialize the inventory manager"""
	inventory_manager = InventoryManager.new()
	add_child(inventory_manager)
	
	# Connect signals
	inventory_manager.inventory_changed.connect(_on_inventory_changed)
	inventory_manager.item_added.connect(_on_item_added)
	inventory_manager.item_removed.connect(_on_item_removed)
	inventory_manager.item_used.connect(_on_item_used)
	inventory_manager.inventory_full.connect(_on_inventory_full)
	
	# Set character reference if available
	if GameManager and GameManager.character:
		inventory_manager.set_character(GameManager.character)

func create_filter_buttons():
	"""Create filter buttons for different item types"""
	filter_buttons = HBoxContainer.new()
	filter_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	filter_buttons.add_theme_constant_override("separation", 10)
	
	# Position filter buttons with dedicated space
	filter_buttons.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	filter_buttons.offset_top = 50   # Below title
	filter_buttons.offset_bottom = 90  # 40px height for buttons
	filter_buttons.offset_left = 20
	filter_buttons.offset_right = -20
	
	# Create filter buttons
	var filter_types = [
		{"type": BaseItem.ItemType.MISC, "name": "All", "color": Color.WHITE},
		{"type": BaseItem.ItemType.EQUIPMENT, "name": "Equipment", "color": Color.ORANGE},
		{"type": BaseItem.ItemType.CONSUMABLE, "name": "Consumables", "color": Color.GREEN},
		{"type": BaseItem.ItemType.CRAFTING, "name": "Materials", "color": Color.BROWN},
		{"type": BaseItem.ItemType.QUEST, "name": "Quest", "color": Color.GOLD}
	]
	
	for filter_data in filter_types:
		var button = create_filter_button(filter_data.name, filter_data.type, filter_data.color)
		filter_buttons.add_child(button)
	
	add_child(filter_buttons)
	
	# Create slot counter
	create_slot_counter()

func create_filter_button(text: String, filter_type: BaseItem.ItemType, color: Color) -> Button:
	"""Create a single filter button"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(80, 30)
	
	# Style the button
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	normal_style.border_color = color
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color * 0.3
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color * 0.5
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", Color.WHITE)
	
	# Connect signal
	button.pressed.connect(_on_filter_button_pressed.bind(filter_type))
	
	return button

func create_slot_counter():
	"""Create slot usage counter display"""
	slot_counter_label = Label.new()
	slot_counter_label.text = "0/40 slots used"
	slot_counter_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	slot_counter_label.add_theme_font_size_override("font_size", 14)
	slot_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Position below filter buttons with proper spacing
	slot_counter_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	slot_counter_label.offset_top = 100   # Below filter buttons (90) + padding (10)
	slot_counter_label.offset_bottom = 130  # 30px height for counter
	slot_counter_label.offset_left = 20
	slot_counter_label.offset_right = -20
	
	add_child(slot_counter_label)

func update_slot_counter():
	"""Update the slot counter display"""
	var occupied_slots = 0
	for slot in inventory_manager.inventory_slots:
		if not slot.is_empty():
			occupied_slots += 1
	
	slot_counter_label.text = str(occupied_slots) + "/" + str(inventory_manager.max_slots) + " slots used"
	
	# Change color based on fullness
	var fullness_ratio = float(occupied_slots) / float(inventory_manager.max_slots)
	if fullness_ratio > 0.9:
		slot_counter_label.add_theme_color_override("font_color", Color.RED)
	elif fullness_ratio > 0.7:
		slot_counter_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		slot_counter_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	"""Create action buttons for inventory operations"""
	# Add Item button (for testing)
	add_button = Button.new()
	add_button.text = "Add Test Item"
	add_button.pressed.connect(_on_add_button_pressed)
	style_action_button(add_button, Color.PURPLE)
	
	add_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	add_button.offset_left = 10
	add_button.offset_bottom = -10
	add_child(add_button)
	
	# Remove Item button
	remove_button = Button.new()
	remove_button.text = "Remove Selected"
	remove_button.pressed.connect(_on_remove_button_pressed)
	style_action_button(remove_button, Color.RED)
	
	remove_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	remove_button.offset_right = -10
	remove_button.offset_bottom = -10
	add_child(remove_button)

func style_action_button(button: Button, color: Color):
	"""Apply consistent styling to action buttons"""
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.custom_minimum_size = Vector2(120, 35)
	
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

func create_tooltip():
	"""Create the tooltip system"""
	tooltip_timer = Timer.new()
	tooltip_timer.wait_time = 0.8
	tooltip_timer.one_shot = true
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
	add_child(tooltip_timer)
	
	tooltip_panel = PanelContainer.new()
	tooltip_panel.visible = false
	tooltip_panel.z_index = 1000
	tooltip_panel.custom_minimum_size = Vector2(250, 100)
	
	var tooltip_style = StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	tooltip_style.border_color = Color.YELLOW
	tooltip_style.border_width_left = 2
	tooltip_style.border_width_right = 2
	tooltip_style.border_width_top = 2
	tooltip_style.border_width_bottom = 2
	tooltip_style.corner_radius_top_left = 6
	tooltip_style.corner_radius_top_right = 6
	tooltip_style.corner_radius_bottom_left = 6
	tooltip_style.corner_radius_bottom_right = 6
	tooltip_style.content_margin_left = 10
	tooltip_style.content_margin_right = 10
	tooltip_style.content_margin_top = 8
	tooltip_style.content_margin_bottom = 8
	tooltip_panel.add_theme_stylebox_override("panel", tooltip_style)
	
	tooltip_label = RichTextLabel.new()
	tooltip_label.bbcode_enabled = true
	tooltip_label.custom_minimum_size = Vector2(230, 80)
	tooltip_label.fit_content = true
	tooltip_panel.add_child(tooltip_label)
	
	add_child(tooltip_panel)

func populate_with_test_items():
	"""Add some test items for demonstration"""
	var test_items = ItemFactory.get_all_test_items()
	
	for item in test_items:
		var amount = 1
		if item.can_stack():
			amount = randi() % 5 + 1  # 1-5 items
		inventory_manager.add_item(item, amount)

func refresh_inventory_display():
	"""Refresh the inventory display - only show occupied slots + a few empty ones"""
	# Clear existing panels
	for panel in slot_panels:
		if panel:
			panel.queue_free()
	slot_panels.clear()
	
	# Clear item container
	for child in item_container.get_children():
		child.queue_free()
	
	# Get occupied slots that match current filter
	var slots_to_show = []
	
	for i in range(inventory_manager.max_slots):
		var slot = inventory_manager.get_slot(i)
		if should_show_slot(slot):
			slots_to_show.append({"slot": slot, "index": i})
	
	# Add a few empty slots for new items (only in "All" view)
	if current_filter == BaseItem.ItemType.MISC:
		var empty_slots_shown = 0
		for i in range(inventory_manager.max_slots):
			var slot = inventory_manager.get_slot(i)
			if slot.is_empty() and empty_slots_shown < 6:  # Show max 6 empty slots
				slots_to_show.append({"slot": slot, "index": i})
				empty_slots_shown += 1
	
	# Create panels for slots to show
	for slot_data in slots_to_show:
		var slot = slot_data.slot
		var index = slot_data.index
		var panel = create_slot_panel(slot, index)
		slot_panels.append(panel)
		item_container.add_child(panel)
	
	# Update slot counter
	update_slot_counter()
	#refresh_inventory_display()

func should_show_slot(slot: InventorySlot) -> bool:
	"""Check if a slot should be shown based on current filter"""
	# Always show non-empty slots that match the filter
	if not slot.is_empty():
		if current_filter == BaseItem.ItemType.MISC:  # "All" filter
			return true
		return slot.item.item_type == current_filter
	
	# For empty slots, only show in "All" view (handled in refresh_inventory_display)
	return false

func create_slot_panel(slot: InventorySlot, slot_index: int) -> Panel:
	"""Create a visual panel for an inventory slot"""
	var panel = Panel.new()
	panel.name = "InventorySlot_" + str(slot_index)
	panel.custom_minimum_size = Vector2(120, 150)  # Slightly smaller
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Store slot index as metadata
	panel.set_meta("slot_index", slot_index)
	
	# Set panel style based on item type and selection
	style_slot_panel(panel, slot, slot_index == selected_slot_index)
	
	# Create content
	create_slot_content(panel, slot)
	
	# Connect signals
	panel.gui_input.connect(_on_slot_panel_input.bind(panel, slot_index))
	panel.mouse_entered.connect(_on_slot_mouse_entered.bind(panel, slot))
	panel.mouse_exited.connect(_on_slot_mouse_exited)
	
	return panel

func style_slot_panel(panel: Panel, slot: InventorySlot, is_selected: bool):
	"""Apply styling to a slot panel"""
	var style = StyleBoxFlat.new()
	
	if slot.is_empty():
		# Empty slot style
		style.bg_color = Color(0.1, 0.1, 0.1, 0.5)
		style.border_color = Color(0.3, 0.3, 0.3, 0.8)
	else:
		# Item slot style based on rarity
		var rarity_color = slot.item.get_rarity_color()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
		style.border_color = rarity_color
	
	if is_selected:
		style.border_color = Color.YELLOW
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
	else:
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
	
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	
	panel.add_theme_stylebox_override("panel", style)

func create_slot_content(panel: Panel, slot: InventorySlot):
	"""Create the content inside a slot panel"""
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	
	if slot.is_empty():
		# Empty slot
		var empty_label = Label.new()
		empty_label.text = "Empty"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size = Vector2(0, 70)  # Adjust for smaller panel
		vbox.add_child(empty_label)
	else:
		# Item icon
		var icon_container = create_item_icon(slot.item)
		vbox.add_child(icon_container)
		
		# Item name and quantity (more compact)
		var name_label = Label.new()
		name_label.text = slot.item.item_name
		if slot.quantity > 1:
			name_label.text += " (" + str(slot.quantity) + ")"
		name_label.add_theme_color_override("font_color", slot.item.get_rarity_color())
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.clip_contents = true
		name_label.custom_minimum_size = Vector2(0, 25)  # Smaller height
		vbox.add_child(name_label)
		
		# Item type indicator (smaller and at bottom)
		var type_label = Label.new()
		type_label.text = slot.item.get_type_name()
		type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		type_label.add_theme_font_size_override("font_size", 9)
		type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_label.custom_minimum_size = Vector2(0, 12)  # Smaller
		vbox.add_child(type_label)
	
	panel.add_child(vbox)

func create_item_icon(item: BaseItem) -> PanelContainer:
	"""Create an icon container for an item"""
	var icon_container = PanelContainer.new()
	icon_container.custom_minimum_size = Vector2(70, 70)  # Smaller to fit better
	
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	#icon_style.border_color = item.get_rarity_color()
	icon_style.border_width_left = 1
	icon_style.border_width_right = 1
	icon_style.border_width_top = 1
	icon_style.border_width_bottom = 1
	icon_style.corner_radius_top_left = 6
	icon_style.corner_radius_top_right = 6
	icon_style.corner_radius_bottom_left = 6
	icon_style.corner_radius_bottom_right = 6
	icon_container.add_theme_stylebox_override("panel", icon_style)
	
	var icon = TextureRect.new()
	# Try to load item icon, fall back to default
	var icon_texture = null
	if item.icon_path != "":
		icon_texture = load(item.icon_path)
	if not icon_texture:
		icon_texture = preload("res://assets/ui/menus/default.png")
	
	icon.texture = icon_texture
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(50, 50)  # Smaller icon
	icon_container.add_child(icon)
	
	return icon_container

# Event Handlers
func _on_filter_button_pressed(filter_type: BaseItem.ItemType):
	"""Handle filter button press"""
	current_filter = filter_type
	refresh_inventory_display()

func _on_add_button_pressed():
	"""Add a random test item"""
	var test_items = ItemFactory.get_all_test_items()
	if test_items.size() > 0:
		var random_item = test_items[randi() % test_items.size()]
		var amount = 1
		if random_item.can_stack():
			amount = randi() % 3 + 1
		
		if inventory_manager.add_item(random_item, amount):
			print("Added ", amount, "x ", random_item.item_name)
		else:
			print("Failed to add item - inventory full")

func _on_remove_button_pressed():
	"""Remove selected item"""
	if selected_slot_index >= 0:
		var slot = inventory_manager.get_slot(selected_slot_index)
		if not slot.is_empty():
			inventory_manager.drop_item_at_slot(selected_slot_index, 1)

func _on_slot_panel_input(event: InputEvent, panel: Panel, slot_index: int):
	"""Handle input on slot panels"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var slot = inventory_manager.get_slot(slot_index)
			if not slot.is_empty():
				show_item_details_view(slot_index)
			#select_slot(slot_index)
			
			# Double-click to show details (instead of use/equip)
			#if event.double_click:
				#var slot = inventory_manager.get_slot(slot_index)
				#if not slot.is_empty():
					#show_item_details_view(slot_index)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right-click to show context menu
			show_item_submenu(slot_index)
			
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			# Middle-click for quick details
			var slot = inventory_manager.get_slot(slot_index)
			if not slot.is_empty():
				show_item_details_view(slot_index)

func show_item_details_view(slot_index: int):
	"""Show the detailed item view using GameUI's ItemDetailView"""
	var slot = inventory_manager.get_slot(slot_index)
	if slot.is_empty():
		return
	
	# Get the GameUI reference and show item detail
	if GameManager and GameManager.game_ui:
		GameManager.game_ui.show_item_detail(slot.item, slot_index)
	else:
		print("GameUI not available for item detail view")

func select_slot(slot_index: int):
	"""Select a specific inventory slot"""
	selected_slot_index = slot_index
	
	# Update visual selection
	for i in range(slot_panels.size()):
		var panel = slot_panels[i]
		if panel:
			var slot = inventory_manager.get_slot(i)
			style_slot_panel(panel, slot, i == selected_slot_index)

func use_or_equip_item(slot_index: int):
	"""Show item details instead of immediate use/equip"""
	show_item_details_view(slot_index)
	#"""Use or equip an item based on its type"""
	#var slot = inventory_manager.get_slot(slot_index)
	#if slot.is_empty():
		#return
	#
	#match slot.item.item_type:
		#BaseItem.ItemType.CONSUMABLE:
			#inventory_manager.use_item_at_slot(slot_index)
		#BaseItem.ItemType.EQUIPMENT:
			#inventory_manager.equip_item_at_slot(slot_index)
		#_:
			#print("Cannot use item: ", slot.item.item_name)

func show_item_submenu(slot_index: int):
	"""Show context menu for an item"""
	var slot = inventory_manager.get_slot(slot_index)
	if slot.is_empty():
		return
	
	# Close existing submenu
	if current_submenu:
		current_submenu.queue_free()
	
	# Create item data for submenu - ADD DETAILS ACTION
	var item_data = {
		"name": slot.item.item_name,
		"description": slot.item.description,
		"type": slot.item.get_type_name().to_lower(),
		"slot_index": slot_index,
		"quantity": slot.quantity,
		"has_details": true  # Flag to show details option
	}
	
	# Create submenu (reuse existing ItemSubmenu class)
	current_submenu = ItemSubmenu.new()
	current_submenu.item_action_selected.connect(_on_item_action_selected)
	current_submenu.submenu_closed.connect(_on_submenu_closed)
	
	get_tree().current_scene.add_child(current_submenu)
	current_submenu.setup_item(item_data)
	
	# Position submenu
	var viewport_size = get_viewport().get_visible_rect().size
	current_submenu.global_position = (viewport_size - current_submenu.size) / 2
	
func _on_slot_mouse_entered(panel: Panel, slot: InventorySlot):
	"""Handle mouse entering a slot"""
	if not slot.is_empty():
		hovered_item = panel
		tooltip_timer.start()

func _on_slot_mouse_exited():
	"""Handle mouse leaving a slot"""
	hovered_item = null
	tooltip_timer.stop()
	tooltip_panel.visible = false

func _on_tooltip_timer_timeout():
	"""Show tooltip for hovered item"""
	if hovered_item:
		var slot_index = hovered_item.get_meta("slot_index")
		var slot = inventory_manager.get_slot(slot_index)
		
		if not slot.is_empty():
			tooltip_label.text = slot.item.get_tooltip_text()
			
			# Position tooltip
			var mouse_pos = get_global_mouse_position() - global_position
			tooltip_panel.position = mouse_pos + Vector2(15, -15)
			
			# Keep in bounds
			var menu_rect = get_rect()
			tooltip_panel.position.x = clamp(tooltip_panel.position.x, 10, menu_rect.size.x - 270)
			tooltip_panel.position.y = clamp(tooltip_panel.position.y, 10, menu_rect.size.y - 120)
			
			tooltip_panel.visible = true

func _on_item_action_selected(action: String, item_data: Dictionary):
	"""Handle actions from the submenu"""
	var slot_index = item_data.get("slot_index", -1)
	if slot_index < 0:
		return
	
	match action:
		"use":
			inventory_manager.use_item_at_slot(slot_index)
		"equip":
			inventory_manager.equip_item_at_slot(slot_index)
		"drop":
			inventory_manager.drop_item_at_slot(slot_index, 1)
		"examine":
			show_item_details(slot_index)  # Keep old console method
		"details":  # NEW ACTION
			show_item_details_view(slot_index)
			
func show_item_details(slot_index: int):
	"""Show detailed information about an item"""
	var slot = inventory_manager.get_slot(slot_index)
	if not slot.is_empty():
		print("=== ", slot.item.item_name, " ===")
		print("Type: ", slot.item.get_type_name())
		print("Rarity: ", BaseItem.ItemRarity.keys()[slot.item.rarity])
		print("Description: ", slot.item.description)
		if slot.item.item_type == BaseItem.ItemType.EQUIPMENT:
			var eq_item = slot.item as EquipmentItem
			if eq_item and eq_item.stat_modifiers.size() > 0:
				print("Stats: ", eq_item.stat_modifiers)

func _on_submenu_closed():
	"""Handle submenu closing"""
	current_submenu = null

# Inventory Manager Signal Handlers
func _on_inventory_changed(slot_index: int):
	"""Handle inventory slot change"""
	# Refresh the entire display when inventory changes
	refresh_inventory_display()

func _on_item_added(item: BaseItem, amount: int):
	"""Handle item added to inventory"""
	print("Added to inventory: ", amount, "x ", item.item_name)

func _on_item_removed(item: BaseItem, amount: int):
	"""Handle item removed from inventory"""
	print("Removed from inventory: ", amount, "x ", item.item_name)

func _on_item_used(item: BaseItem):
	"""Handle item used"""
	print("Used item: ", item.item_name)

func _on_inventory_full():
	"""Handle inventory full"""
	print("Inventory is full!")
	# You could show a notification here
