# EquipmentMenu.gd
extends BaseMenu
class_name EquipmentMenu

# Equipment Panel Components
var equipment_panel: PanelContainer
var equipment_slots_container: GridContainer
var equipment_slot_buttons: Dictionary = {}

# Stats Panel Components
var stats_panel: PanelContainer
var stats_categories_container: VBoxContainer

# Equipment Items Panel Components
var equipment_items_panel: PanelContainer
var equipment_items_container: GridContainer
var equipment_slot_panels: Array = []

# Main layout
var main_container: VBoxContainer
var top_container: HBoxContainer

# Filter system for equipment items
var current_equipment_filter: EquipmentSlot.SlotType = EquipmentSlot.SlotType.MAIN_HAND
var filter_buttons: HBoxContainer

# Tooltip system
var tooltip: PanelContainer
var tooltip_timer: Timer
var current_hovered_item: Control

# References
var character_stats: CharacterStats
var equipment_manager: EquipmentManager
var inventory_manager: InventoryManager

# Signals
signal equipment_slot_clicked(slot_type: EquipmentSlot.SlotType)
signal item_equipped(item: EquipmentItem, slot: EquipmentSlot.SlotType)
signal item_unequipped(item: EquipmentItem, slot: EquipmentSlot.SlotType)

func ready_post():
	menu_title = "Equipment"
	title_label.text = menu_title
	initialize_references()
	create_equipment_interface()
	connect_signals()

func initialize_references():
	"""Initialize references to game systems"""
	# Get character from GameManager
	if GameManager and GameManager.character:
		var character = GameManager.character
		
		# Get character stats
		if character.stats is CharacterStats:
			character_stats = character.stats
		else:
			character_stats = CharacterStats.new()
			character_stats.character_name = character.stats.character_name if character.stats else "Hero"
			character.stats = character_stats
		
		# Get equipment manager
		if character.has_method("get_equipment_manager") and character.get_equipment_manager():
			equipment_manager = character.get_equipment_manager()
		elif character.equipment_manager:
			equipment_manager = character.equipment_manager
		else:
			equipment_manager = EquipmentManager.new()
			character.equipment_manager = equipment_manager
		
		# Set up relationships
		equipment_manager.set_character_stats(character_stats)
		character_stats.set_equipment_manager(equipment_manager)
	
	# Get inventory manager
	if GameManager and GameManager.inventory_manager:
		inventory_manager = GameManager.inventory_manager

func create_equipment_interface():
	"""Create the equipment interface"""
	# Clear existing content
	for child in item_container.get_children():
		child.queue_free()
	
	create_main_layout()
	create_tooltip_system()
	
	# Initial data refresh
	refresh_all_displays()

func create_main_layout():
	"""Create the main layout with equipment slots, stats, and equipment items"""
	main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 20)
	
	# Top container for equipment slots and stats (side by side)
	top_container = HBoxContainer.new()
	top_container.add_theme_constant_override("separation", 20)
	
	create_equipment_panel()
	create_stats_panel()
	
	top_container.add_child(equipment_panel)
	top_container.add_child(stats_panel)
	
	# Equipment items section (below slots and stats)
	create_equipment_items_panel()
	
	main_container.add_child(top_container)
	main_container.add_child(equipment_items_panel)
	
	item_container.add_child(main_container)

func create_equipment_panel():
	"""Create the equipment slots panel"""
	equipment_panel = PanelContainer.new()
	equipment_panel.custom_minimum_size = Vector2(300, 400)
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.2, 0.9)
	style.border_color = Color(0.4, 0.4, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	equipment_panel.add_theme_stylebox_override("panel", style)
	
	var equipment_vbox = VBoxContainer.new()
	equipment_vbox.add_theme_constant_override("separation", 10)
	
	# Header
	var equipment_header = create_section_header("Equipment Slots")
	equipment_vbox.add_child(equipment_header)
	
	# Equipment slots
	create_equipment_slots(equipment_vbox)
	
	equipment_panel.add_child(equipment_vbox)

func create_equipment_slots(parent: VBoxContainer):
	"""Create equipment slots in a logical layout"""
	var equipment_layout = VBoxContainer.new()
	equipment_layout.add_theme_constant_override("separation", 15)
	
	# Top row: Helmet
	var top_row = HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_child(create_equipment_slot(EquipmentSlot.SlotType.HELMET))
	equipment_layout.add_child(top_row)
	
	# Middle row: Main Hand, Chest, Off Hand
	var middle_row = HBoxContainer.new()
	middle_row.alignment = BoxContainer.ALIGNMENT_CENTER
	middle_row.add_theme_constant_override("separation", 10)
	middle_row.add_child(create_equipment_slot(EquipmentSlot.SlotType.MAIN_HAND))
	middle_row.add_child(create_equipment_slot(EquipmentSlot.SlotType.CHEST))
	middle_row.add_child(create_equipment_slot(EquipmentSlot.SlotType.OFF_HAND))
	equipment_layout.add_child(middle_row)
	
	# Lower body row: Hands, Legs, Feet
	var lower_row = HBoxContainer.new()
	lower_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lower_row.add_theme_constant_override("separation", 10)
	lower_row.add_child(create_equipment_slot(EquipmentSlot.SlotType.HANDS))
	lower_row.add_child(create_equipment_slot(EquipmentSlot.SlotType.LEGS))
	lower_row.add_child(create_equipment_slot(EquipmentSlot.SlotType.FEET))
	equipment_layout.add_child(lower_row)
	
	# Accessories section
	var accessories_header = Label.new()
	accessories_header.text = "Accessories"
	accessories_header.add_theme_font_size_override("font_size", 14)
	accessories_header.add_theme_color_override("font_color", Color.YELLOW)
	accessories_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equipment_layout.add_child(accessories_header)
	
	# Accessories grid
	var accessories_grid = GridContainer.new()
	accessories_grid.columns = 3
	accessories_grid.add_theme_constant_override("h_separation", 10)
	accessories_grid.add_theme_constant_override("v_separation", 10)
	
	accessories_grid.add_child(create_equipment_slot(EquipmentSlot.SlotType.RING_1))
	accessories_grid.add_child(create_equipment_slot(EquipmentSlot.SlotType.NECKLACE))
	accessories_grid.add_child(create_equipment_slot(EquipmentSlot.SlotType.RING_2))
	accessories_grid.add_child(Control.new())  # Spacer
	accessories_grid.add_child(create_equipment_slot(EquipmentSlot.SlotType.BELT))
	accessories_grid.add_child(Control.new())  # Spacer
	
	equipment_layout.add_child(accessories_grid)
	
	parent.add_child(equipment_layout)

func create_equipment_slot(slot_type: EquipmentSlot.SlotType) -> Button:
	"""Create a single equipment slot button"""
	var slot_button = Button.new()
	slot_button.custom_minimum_size = Vector2(50, 50)
	slot_button.text = ""
	
	# Style the slot
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	normal_style.border_color = Color(0.5, 0.5, 0.7)
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	
	var hover_style = normal_style.duplicate()
	hover_style.border_color = Color.YELLOW
	hover_style.bg_color = Color(0.3, 0.3, 0.4, 0.8)
	
	slot_button.add_theme_stylebox_override("normal", normal_style)
	slot_button.add_theme_stylebox_override("hover", hover_style)
	slot_button.add_theme_stylebox_override("pressed", hover_style)
	
	# Connect signals
	slot_button.pressed.connect(_on_equipment_slot_clicked.bind(slot_type))
	slot_button.mouse_entered.connect(_on_equipment_slot_mouse_entered.bind(slot_type, slot_button))
	slot_button.mouse_exited.connect(_on_equipment_slot_mouse_exited.bind(slot_type))
	
	# Store reference
	equipment_slot_buttons[slot_type] = slot_button
	
	# Set initial display
	update_equipment_slot_display(slot_type)
	
	return slot_button

func create_stats_panel():
	"""Create the stats panel"""
	stats_panel = PanelContainer.new()
	stats_panel.custom_minimum_size = Vector2(350, 400)
	stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.2, 0.1, 0.9)
	style.border_color = Color(0.4, 0.6, 0.4)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	stats_panel.add_theme_stylebox_override("panel", style)
	
	var stats_scroll = ScrollContainer.new()
	stats_categories_container = VBoxContainer.new()
	stats_categories_container.add_theme_constant_override("separation", 15)
	
	# Header
	var stats_header = create_section_header("Character Stats")
	stats_categories_container.add_child(stats_header)
	
	create_stats_categories()
	
	stats_scroll.add_child(stats_categories_container)
	stats_panel.add_child(stats_scroll)

func create_equipment_items_panel():
	"""Create the equipment items panel below slots and stats"""
	equipment_items_panel = PanelContainer.new()
	equipment_items_panel.custom_minimum_size = Vector2(700, 300)
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.1, 0.1, 0.9)
	style.border_color = Color(0.6, 0.4, 0.4)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	equipment_items_panel.add_theme_stylebox_override("panel", style)
	
	var items_vbox = VBoxContainer.new()
	items_vbox.add_theme_constant_override("separation", 10)
	
	# Header
	var items_header = create_section_header("Equipment Items")
	items_vbox.add_child(items_header)
	
	# Filter buttons for equipment types
	create_equipment_filter_buttons(items_vbox)
	
	# Scrollable container for equipment items
	var items_scroll = ScrollContainer.new()
	items_scroll.custom_minimum_size = Vector2(680, 200)
	
	equipment_items_container = GridContainer.new()
	equipment_items_container.columns = 6
	equipment_items_container.add_theme_constant_override("h_separation", 10)
	equipment_items_container.add_theme_constant_override("v_separation", 10)
	
	items_scroll.add_child(equipment_items_container)
	items_vbox.add_child(items_scroll)
	
	equipment_items_panel.add_child(items_vbox)

func create_equipment_filter_buttons(parent: VBoxContainer):
	"""Create filter buttons for equipment slot types"""
	filter_buttons = HBoxContainer.new()
	filter_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	filter_buttons.add_theme_constant_override("separation", 8)
	
	var filter_types = [
		{"type": EquipmentSlot.SlotType.MAIN_HAND, "name": "Weapons", "color": Color.RED},
		{"type": EquipmentSlot.SlotType.CHEST, "name": "Armor", "color": Color.BLUE},
		{"type": EquipmentSlot.SlotType.RING_1, "name": "Accessories", "color": Color.PURPLE},
	]
	
	# Add "All" filter
	var all_button = create_equipment_filter_button("All", null, Color.WHITE)
	filter_buttons.add_child(all_button)
	
	for filter_data in filter_types:
		var button = create_equipment_filter_button(filter_data.name, filter_data.type, filter_data.color)
		filter_buttons.add_child(button)
	
	parent.add_child(filter_buttons)

func create_equipment_filter_button(text: String, filter_type, color: Color) -> Button:
	"""Create a single equipment filter button"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(80, 25)
	
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
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 12)
	
	# Connect signal
	button.pressed.connect(_on_equipment_filter_pressed.bind(filter_type))
	
	return button

func create_stats_categories():
	"""Create all stat categories"""
	if not character_stats:
		return
	
	var categories = character_stats.get_stat_categories()
	
	for category in categories:
		var category_container = create_stat_category_display(category)
		stats_categories_container.add_child(category_container)

func create_stat_category_display(category: StatCategory) -> VBoxContainer:
	"""Create display for a single stat category"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	
	# Category header
	var header = Label.new()
	header.text = category.category_name
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", category.category_color)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(header)
	
	# Stats grid
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 10)
	stats_grid.add_theme_constant_override("v_separation", 3)
	
	for stat_name in category.stats:
		var stat = category.stats[stat_name]
		var stat_display = create_stat_display(stat, category.category_color)
		stats_grid.add_child(stat_display)
	
	container.add_child(stats_grid)
	
	return container

func create_stat_display(stat: StatData, category_color: Color) -> PanelContainer:
	"""Create display for a single stat"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 40)
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.25, 0.7)
	style.border_color = category_color * 0.7
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	
	# Stat name
	var name_label = Label.new()
	name_label.text = stat.stat_name.replace("_", " ")
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	
	# Stat value
	var value_label = Label.new()
	value_label.text = str(stat.get_total_value())
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(value_label)
	
	panel.add_child(hbox)
	
	# Tooltip
	panel.mouse_entered.connect(_on_stat_mouse_entered.bind(stat, panel))
	panel.mouse_exited.connect(_on_stat_mouse_exited.bind(stat))
	
	return panel

func create_section_header(text: String) -> Label:
	"""Create a section header label"""
	var header = Label.new()
	header.text = text
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color.GOLD)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return header

func create_tooltip_system():
	"""Create the tooltip system"""
	tooltip_timer = Timer.new()
	tooltip_timer.wait_time = 0.8
	tooltip_timer.one_shot = true
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
	add_child(tooltip_timer)
	
	tooltip = PanelContainer.new()
	tooltip.visible = false
	tooltip.z_index = 100
	
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
	tooltip.add_theme_stylebox_override("panel", tooltip_style)
	
	var tooltip_label = RichTextLabel.new()
	tooltip_label.name = "TooltipLabel"
	tooltip_label.bbcode_enabled = true
	tooltip_label.custom_minimum_size = Vector2(200, 50)
	tooltip_label.fit_content = true
	tooltip.add_child(tooltip_label)
	
	add_child(tooltip)

func connect_signals():
	"""Connect all signals"""
	if equipment_manager:
		if equipment_manager.equipment_changed.is_connected(_on_equipment_changed):
			equipment_manager.equipment_changed.disconnect(_on_equipment_changed)
		equipment_manager.equipment_changed.connect(_on_equipment_changed)
	
	if character_stats:
		if character_stats.stats_recalculated.is_connected(_on_stats_recalculated):
			character_stats.stats_recalculated.disconnect(_on_stats_recalculated)
		character_stats.stats_recalculated.connect(_on_stats_recalculated)
	
	if inventory_manager:
		if inventory_manager.inventory_changed.is_connected(_on_inventory_changed):
			inventory_manager.inventory_changed.disconnect(_on_inventory_changed)
		inventory_manager.inventory_changed.connect(_on_inventory_changed)

func refresh_all_displays():
	"""Refresh all displays"""
	if not is_inside_tree():
		return
	
	refresh_stats_display()
	refresh_equipment_display()
	refresh_equipment_items_display()

func refresh_stats_display():
	"""Refresh the stats display"""
	if not stats_categories_container:
		return
	
	# Clear and recreate stats display
	for child in stats_categories_container.get_children():
		if child.name != "StatsHeader":  # Keep the header
			child.queue_free()
	
	await get_tree().process_frame
	create_stats_categories()

func refresh_equipment_display():
	"""Refresh all equipment slot displays"""
	for slot_type in equipment_slot_buttons:
		update_equipment_slot_display(slot_type)

func refresh_equipment_items_display():
	"""Refresh the equipment items display"""
	# Clear existing panels
	for panel in equipment_slot_panels:
		if panel:
			panel.queue_free()
	equipment_slot_panels.clear()
	
	# Clear container
	for child in equipment_items_container.get_children():
		child.queue_free()
	
	if not inventory_manager:
		return
	
	# Get equipment items from inventory
	var equipment_items = []
	for i in range(inventory_manager.max_slots):
		var slot = inventory_manager.get_slot(i)
		if not slot.is_empty() and slot.item.item_type == BaseItem.ItemType.EQUIPMENT:
			if should_show_equipment_item(slot.item):
				equipment_items.append({"slot": slot, "index": i})
	
	# Create panels for equipment items
	for item_data in equipment_items:
		var slot = item_data.slot
		var index = item_data.index
		var panel = create_equipment_item_panel(slot, index)
		equipment_slot_panels.append(panel)
		equipment_items_container.add_child(panel)

func should_show_equipment_item(item: BaseItem) -> bool:
	"""Check if an equipment item should be shown based on current filter"""
	if current_equipment_filter == null:  # "All" filter
		return true
	
	var equipment_item = item as EquipmentItem
	if not equipment_item:
		return false
	
	# Check if item can fit in the filtered slot type
	return current_equipment_filter in equipment_item.compatible_slots

func create_equipment_item_panel(slot: InventorySlot, slot_index: int) -> Panel:
	"""Create a panel for an equipment item"""
	var panel = Panel.new()
	panel.name = "EquipmentItem_" + str(slot_index)
	panel.custom_minimum_size = Vector2(100, 120)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Store slot index as metadata
	panel.set_meta("slot_index", slot_index)
	
	# Set panel style based on item rarity
	style_equipment_item_panel(panel, slot)
	
	# Create content
	create_equipment_item_content(panel, slot)
	
	# Connect signals
	panel.gui_input.connect(_on_equipment_item_input.bind(panel, slot_index))
	panel.mouse_entered.connect(_on_equipment_item_mouse_entered.bind(panel, slot))
	panel.mouse_exited.connect(_on_equipment_item_mouse_exited)
	
	return panel

func style_equipment_item_panel(panel: Panel, slot: InventorySlot):
	"""Apply styling to an equipment item panel"""
	var style = StyleBoxFlat.new()
	
	# Item slot style based on rarity
	var rarity_color = slot.item.get_rarity_color()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_color = rarity_color
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

func create_equipment_item_content(panel: Panel, slot: InventorySlot):
	"""Create the content inside an equipment item panel"""
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	
	# Item icon
	var icon_container = create_equipment_item_icon(slot.item)
	vbox.add_child(icon_container)
	
	# Item name
	var name_label = Label.new()
	name_label.text = slot.item.item_name
	if slot.quantity > 1:
		name_label.text += " (" + str(slot.quantity) + ")"
	name_label.add_theme_color_override("font_color", slot.item.get_rarity_color())
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_contents = true
	name_label.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(name_label)
	
	panel.add_child(vbox)

func create_equipment_item_icon(item: BaseItem) -> PanelContainer:
	"""Create an icon container for an equipment item"""
	var icon_container = PanelContainer.new()
	icon_container.custom_minimum_size = Vector2(60, 60)
	
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
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
	icon.custom_minimum_size = Vector2(40, 40)
	icon_container.add_child(icon)
	
	return icon_container

# Event Handlers
func _on_equipment_slot_clicked(slot_type: EquipmentSlot.SlotType):
	"""Handle equipment slot click"""
	equipment_slot_clicked.emit(slot_type)
	
	var equipped_item = equipment_manager.get_equipped_item(slot_type)
	
	if equipped_item:
		# Show item detail view for the equipped item
		if GameManager and GameManager.game_ui:
			GameManager.game_ui.show_equipment_detail(equipped_item, -1, "equipment")
	else:
		handle_empty_slot_click(slot_type)

func handle_empty_slot_click(slot_type: EquipmentSlot.SlotType):
	"""Handle clicking on an empty equipment slot"""
	var slot_name = equipment_manager.get_slot_display_name(slot_type)
	
	if GameManager and GameManager.game_ui:
		GameManager.game_ui.show_info("No item equipped in " + slot_name + " slot.")

func _on_equipment_filter_pressed(filter_type):
	"""Handle equipment filter button press"""
	current_equipment_filter = filter_type
	refresh_equipment_items_display()

func _on_equipment_item_input(event: InputEvent, panel: Panel, slot_index: int):
	"""Handle input on equipment item panels"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var slot = inventory_manager.get_slot(slot_index)
			if not slot.is_empty():
				show_equipment_item_details(slot_index)

func show_equipment_item_details(slot_index: int):
	"""Show the detailed equipment item view"""
	var slot = inventory_manager.get_slot(slot_index)
	if slot.is_empty():
		return
	
	if GameManager and GameManager.game_ui:
		GameManager.game_ui.show_equipment_detail(slot.item, slot_index, "equipment")

func update_equipment_slot_display(slot_type: EquipmentSlot.SlotType):
	"""Update the display of a specific equipment slot"""
	if not equipment_slot_buttons.has(slot_type):
		return
	
	var button = equipment_slot_buttons[slot_type]
	var equipped_item = equipment_manager.get_equipped_item(slot_type) if equipment_manager else null
	
	if equipped_item:
		var display_text = equipped_item.item_name.substr(0, 1).to_upper() + "★"
		button.text = display_text
		button.add_theme_color_override("font_color", equipped_item.get_rarity_color())
		
		var equipped_style = StyleBoxFlat.new()
		equipped_style.bg_color = equipped_item.get_rarity_color() * 0.3
		equipped_style.border_color = equipped_item.get_rarity_color()
		equipped_style.border_width_left = 3
		equipped_style.border_width_right = 3
		equipped_style.border_width_top = 3
		equipped_style.border_width_bottom = 3
		equipped_style.corner_radius_top_left = 8
		equipped_style.corner_radius_top_right = 8
		equipped_style.corner_radius_bottom_left = 8
		equipped_style.corner_radius_bottom_right = 8
		button.add_theme_stylebox_override("normal", equipped_style)
	else:
		button.text = ""
		button.add_theme_color_override("font_color", Color.WHITE)
		
		var empty_style = StyleBoxFlat.new()
		empty_style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
		empty_style.border_color = Color(0.5, 0.5, 0.7)
		empty_style.border_width_left = 2
		empty_style.border_width_right = 2
		empty_style.border_width_top = 2
		empty_style.border_width_bottom = 2
		empty_style.corner_radius_top_left = 8
		empty_style.corner_radius_top_right = 8
		empty_style.corner_radius_bottom_left = 8
		empty_style.corner_radius_bottom_right = 8
		button.add_theme_stylebox_override("normal", empty_style)

# Signal handlers
func _on_equipment_changed(slot_type: EquipmentSlot.SlotType, old_item: EquipmentItem, new_item: EquipmentItem):
	"""Handle equipment changes"""
	update_equipment_slot_display(slot_type)
	refresh_stats_display()
	
	if old_item and new_item:
		item_equipped.emit(new_item, slot_type)
	elif new_item:
		item_equipped.emit(new_item, slot_type)
	elif old_item:
		item_unequipped.emit(old_item, slot_type)

func _on_stats_recalculated():
	"""Handle stats recalculation"""
	refresh_stats_display()

func _on_inventory_changed(slot_index: int):
	"""Handle inventory changes"""
	refresh_equipment_items_display()

func _on_equipment_slot_mouse_entered(slot_type: EquipmentSlot.SlotType, button: Button):
	"""Handle mouse enter on equipment slot"""
	current_hovered_item = button
	tooltip_timer.start()

func _on_equipment_slot_mouse_exited(slot_type: EquipmentSlot.SlotType):
	"""Handle mouse exit on equipment slot"""
	current_hovered_item = null
	tooltip_timer.stop()
	tooltip.visible = false

func _on_equipment_item_mouse_entered(panel: Panel, slot: InventorySlot):
	"""Handle mouse entering an equipment item"""
	current_hovered_item = panel
	tooltip_timer.start()

func _on_equipment_item_mouse_exited():
	"""Handle mouse leaving an equipment item"""
	current_hovered_item = null
	tooltip_timer.stop()
	tooltip.visible = false

func _on_stat_mouse_entered(stat: StatData, panel: PanelContainer):
	"""Handle mouse enter on stat"""
	current_hovered_item = panel
	tooltip_timer.start()

func _on_stat_mouse_exited(stat: StatData):
	"""Handle mouse exit on stat"""
	current_hovered_item = null
	tooltip_timer.stop()
	tooltip.visible = false

func _on_tooltip_timer_timeout():
	"""Handle tooltip timer timeout"""
	if current_hovered_item:
		show_tooltip_for_item(current_hovered_item)

func show_tooltip_for_item(item: Control):
	"""Show tooltip for a specific item"""
	var tooltip_label = tooltip.get_node("TooltipLabel")
	var tooltip_text = "No information available"
	
	# Create appropriate tooltip based on item type
	if item in equipment_slot_buttons.values():
		tooltip_text = create_equipment_slot_tooltip(item)
	elif item.has_meta("slot_index"):
		tooltip_text = create_equipment_item_tooltip(item)
	
	tooltip_label.text = tooltip_text
	
	# Position tooltip
	var mouse_pos = get_global_mouse_position() - global_position
	tooltip.position = mouse_pos + Vector2(15, -15)
	
	# Keep tooltip in bounds
	var menu_rect = get_rect()
	tooltip.position.x = clamp(tooltip.position.x, 10, menu_rect.size.x - 250)
	tooltip.position.y = clamp(tooltip.position.y, 10, menu_rect.size.y - 100)
	
	tooltip.visible = true

func create_equipment_slot_tooltip(slot_button: Button) -> String:
	"""Create tooltip text for equipment slot"""
	var slot_type = null
	for type in equipment_slot_buttons:
		if equipment_slot_buttons[type] == slot_button:
			slot_type = type
			break
	
	if slot_type == null:
		return "Unknown slot"
	
	var slot_name = equipment_manager.get_slot_display_name(slot_type)
	var equipped_item = equipment_manager.get_equipped_item(slot_type)
	
	if equipped_item:
		var text = "[b]" + equipped_item.item_name + "[/b]\n"
		text += equipped_item.description + "\n\n"
		text += "[color=yellow]Stats:[/color]\n"
		for stat in equipped_item.stat_modifiers:
			text += "• " + stat.replace("_", " ") + ": +" + str(equipped_item.stat_modifiers[stat]) + "\n"
		text += "\n[color=gray]Click to view details[/color]"
		return text
	else:
		return "[b]" + slot_name + "[/b]\n\nEmpty slot\n\n[color=gray]Equip an item here[/color]"

func create_equipment_item_tooltip(panel: Panel) -> String:
	"""Create tooltip text for equipment item"""
	var slot_index = panel.get_meta("slot_index")
	var slot = inventory_manager.get_slot(slot_index)
	
	if slot and not slot.is_empty():
		return slot.item.get_tooltip_text()
	
	return "Unknown item"
