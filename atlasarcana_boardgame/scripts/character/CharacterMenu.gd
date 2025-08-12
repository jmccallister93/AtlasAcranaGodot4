# CharacterMenu.gd
extends BaseMenu
class_name CharacterMenu

# Equipment Panel Components
var equipment_panel: PanelContainer
var equipment_slots_container: GridContainer
var equipment_slot_buttons: Dictionary = {}

# Stats Panel Components
var stats_panel: PanelContainer
var stats_categories_container: VBoxContainer

# Main layout
var main_container: HBoxContainer

# Tab system for skills
var tab_container: TabContainer
var skills_tab: Control

# Tooltip system
var tooltip: PanelContainer
var tooltip_timer: Timer
var current_hovered_item: Control

# References
var character_stats: CharacterStats
var equipment_manager: EquipmentManager
var skill_manager: SkillManager

# Signals
signal equipment_slot_clicked(slot_type: EquipmentSlot.SlotType)
signal item_equipped(item: EquipmentItem, slot: EquipmentSlot.SlotType)
signal item_unequipped(item: EquipmentItem, slot: EquipmentSlot.SlotType)

func ready_post():
	menu_title = "Character"
	title_label.text = menu_title
	initialize_references()
	create__interface()
	connect_signals()

func initialize_references():
	"""Initialize references to game systems"""
	# Get character from GameManager
	if GameManager and GameManager.character:
		var character = GameManager.character
		
		# Get or create character stats
		if character.stats is CharacterStats:
			character_stats = character.stats
		else:
			# Convert old stats to new system
			character_stats = CharacterStats.new()
			character_stats.character_name = character.stats.character_name if character.stats else "Hero"
			character.stats = character_stats
		
		# IMPORTANT FIX: Use the character's existing equipment manager instead of creating new one
		if character.has_method("get_equipment_manager") and character.get_equipment_manager():
			equipment_manager = character.get_equipment_manager()
			print("✅ Using existing equipment manager from character")
		elif character.equipment_manager:
			equipment_manager = character.equipment_manager
			print("✅ Using character.equipment_manager")
		else:
			# Only create new if character doesn't have one
			equipment_manager = EquipmentManager.new()
			character.equipment_manager = equipment_manager
			print("⚠️ Created new equipment manager for character")
		
		# Set up the relationships
		equipment_manager.set_character_stats(character_stats)
		character_stats.set_equipment_manager(equipment_manager)
		
		# Create skill manager (same approach)
		if character.has_method("get_skill_manager") and character.get_skill_manager():
			skill_manager = character.get_skill_manager()
		elif character.skill_manager:
			skill_manager = character.skill_manager
		else:
			skill_manager = SkillManager.new()
			character.skill_manager = skill_manager
		
		skill_manager.set_character_stats(character_stats)
		character_stats.set_skill_manager(skill_manager)
		
		# Give some initial skill points for testing
		if not skill_manager.has_method("get_skill_points") or skill_manager.get_skill_points() == 0:
			skill_manager.add_skill_points(10)

func create__interface():
	"""Create the new  character interface"""
	# Clear existing content
	for child in item_container.get_children():
		child.queue_free()
	
	create_main_layout()
	create_tooltip_system()
	
	# Initial data refresh
	refresh_all_displays()

func create_main_layout():
	"""Create the main side-by-side layout"""
	main_container = HBoxContainer.new()
	main_container.add_theme_constant_override("separation", 20)
	
	create_equipment_panel()
	create_stats_panel()
	
	main_container.add_child(equipment_panel)
	main_container.add_child(stats_panel)
	
	item_container.add_child(main_container)

func create_equipment_panel():
	"""Create the equipment panel"""
	equipment_panel = PanelContainer.new()
	equipment_panel.custom_minimum_size = Vector2(300, 500)
	
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
	var equipment_header = create_section_header("Equipment")
	equipment_vbox.add_child(equipment_header)
	
	# Equipment slots
	create_equipment_slots(equipment_vbox)
	
	equipment_panel.add_child(equipment_vbox)

func create_equipment_slots(parent: VBoxContainer):
	"""Create equipment slots in a logical layout"""
	# Create equipment layout container
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
	# Add belt in the center bottom
	accessories_grid.add_child(Control.new())  # Spacer
	accessories_grid.add_child(create_equipment_slot(EquipmentSlot.SlotType.BELT))
	accessories_grid.add_child(Control.new())  # Spacer
	
	equipment_layout.add_child(accessories_grid)
	
	parent.add_child(equipment_layout)

func create_equipment_slot(slot_type: EquipmentSlot.SlotType) -> Button:
	"""Create a single equipment slot button"""
	var slot_button = Button.new()
	slot_button.custom_minimum_size = Vector2(60, 60)
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
	"""Create the stats panel with categories"""
	stats_panel = PanelContainer.new()
	stats_panel.custom_minimum_size = Vector2(400, 500)
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
	
	# Create tab container for stats and skills
	tab_container = TabContainer.new()
	tab_container.tab_alignment = TabBar.ALIGNMENT_CENTER
	
	# Stats tab
	var stats_tab = ScrollContainer.new()
	stats_tab.name = "Stats"
	stats_categories_container = VBoxContainer.new()
	stats_categories_container.add_theme_constant_override("separation", 20)
	
	create_stats_categories()
	
	stats_tab.add_child(stats_categories_container)
	tab_container.add_child(stats_tab)
	
	# Skills tab
	skills_tab = create_skills_tab()
	tab_container.add_child(skills_tab)
	
	stats_panel.add_child(tab_container)

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
	container.add_theme_constant_override("separation", 8)
	
	# Category header
	var header = create_section_header(category.category_name)
	header.add_theme_color_override("font_color", category.category_color)
	container.add_child(header)
	
	# Description
	var desc = Label.new()
	desc.text = category.description
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(desc)
	
	# Stats grid
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 15)
	stats_grid.add_theme_constant_override("v_separation", 5)
	
	for stat_name in category.stats:
		var stat = category.stats[stat_name]
		var stat_display = create_stat_display(stat, category.category_color)
		stats_grid.add_child(stat_display)
	
	container.add_child(stats_grid)
	
	return container

func create_stat_display(stat: StatData, category_color: Color) -> PanelContainer:
	"""Create display for a single stat"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 60)
	
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
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	
	# Stat name
	var name_label = Label.new()
	name_label.text = stat.stat_name.replace("_", " ")
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)
	
	# Stat value with breakdown
	var value_container = create_stat_value_breakdown(stat)
	vbox.add_child(value_container)
	
	panel.add_child(vbox)
	
	# Tooltip
	panel.mouse_entered.connect(_on_stat_mouse_entered.bind(stat, panel))
	panel.mouse_exited.connect(_on_stat_mouse_exited.bind(stat))
	
	return panel

func create_stat_value_breakdown(stat: StatData) -> VBoxContainer:
	"""Create detailed value breakdown for a stat"""
	var container = VBoxContainer.new()
	
	# Total value (prominent)
	var total_label = Label.new()
	total_label.text = str(stat.get_total_value())
	total_label.add_theme_font_size_override("font_size", 18)
	total_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	container.add_child(total_label)
	
	# Breakdown (if there are modifiers)
	if stat.equipment_modifier != 0 or stat.skill_modifier != 0:
		var breakdown = Label.new()
		var breakdown_text = str(stat.base_value)
		
		if stat.equipment_modifier != 0:
			breakdown_text += " + " + str(stat.equipment_modifier) + " (eq)"
		if stat.skill_modifier != 0:
			breakdown_text += " + " + str(stat.skill_modifier) + " (skill)"
		if stat.temporary_modifier != 0:
			breakdown_text += " + " + str(stat.temporary_modifier) + " (temp)"
		
		breakdown.text = breakdown_text
		breakdown.add_theme_font_size_override("font_size", 10)
		breakdown.add_theme_color_override("font_color", Color.GRAY)
		container.add_child(breakdown)
	
	return container

func create_skills_tab() -> Control:
	"""Create the skills tab"""
	var skills_container = ScrollContainer.new()
	skills_container.name = "Skills"
	
	var skills_vbox = VBoxContainer.new()
	skills_vbox.add_theme_constant_override("separation", 15)
	
	# Skill points display
	var sp_container = HBoxContainer.new()
	var sp_label = Label.new()
	sp_label.text = "Skill Points: "
	sp_label.add_theme_font_size_override("font_size", 16)
	sp_label.add_theme_color_override("font_color", Color.WHITE)
	sp_container.add_child(sp_label)
	
	var sp_value = Label.new()
	sp_value.name = "SkillPointsValue"
	sp_value.text = "0"
	sp_value.add_theme_font_size_override("font_size", 16)
	sp_value.add_theme_color_override("font_color", Color.YELLOW)
	sp_container.add_child(sp_value)
	
	skills_vbox.add_child(sp_container)
	
	# Skill trees
	if skill_manager:
		for tree in skill_manager.get_all_skill_trees():
			var tree_display = create_skill_tree_display(tree)
			skills_vbox.add_child(tree_display)
	
	skills_container.add_child(skills_vbox)
	return skills_container

func create_skill_tree_display(tree: SkillTree) -> VBoxContainer:
	"""Create display for a skill tree"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	
	# Tree header
	var header = create_section_header(tree.tree_name)
	header.add_theme_color_override("font_color", tree.tree_color)
	container.add_child(header)
	
	# Tree description
	var desc = Label.new()
	desc.text = tree.tree_description
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	container.add_child(desc)
	
	# Skills grid
	var skills_grid = GridContainer.new()
	skills_grid.columns = 3
	skills_grid.add_theme_constant_override("h_separation", 10)
	skills_grid.add_theme_constant_override("v_separation", 10)
	
	for skill in tree.get_all_skills():
		var skill_button = create_skill_button(skill)
		skills_grid.add_child(skill_button)
	
	container.add_child(skills_grid)
	
	return container

func create_skill_button(skill: SkillNode) -> Button:
	"""Create a button for a skill"""
	var button = Button.new()
	button.custom_minimum_size = Vector2(100, 80)
	button.text = skill.skill_name + "\n" + str(skill.current_level) + "/" + str(skill.max_level)
	
	# Style based on skill state
	var style = StyleBoxFlat.new()
	if skill.is_learned():
		style.bg_color = Color(0.2, 0.6, 0.2, 0.8)  # Green for learned
		style.border_color = Color.GREEN
	elif skill_manager and skill_manager.get_skill_tree(skill.tree_category).can_learn_skill(skill, character_stats, skill_manager.learned_skills):
		style.bg_color = Color(0.6, 0.6, 0.2, 0.8)  # Yellow for available
		style.border_color = Color.YELLOW
	else:
		style.bg_color = Color(0.3, 0.3, 0.3, 0.8)  # Gray for locked
		style.border_color = Color.GRAY
	
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_font_size_override("font_size", 10)
	
	# Connect signals
	button.pressed.connect(_on_skill_button_clicked.bind(skill))
	button.mouse_entered.connect(_on_skill_mouse_entered.bind(skill, button))
	button.mouse_exited.connect(_on_skill_mouse_exited.bind(skill))
	
	return button

func create_section_header(text: String) -> Label:
	"""Create a section header label"""
	var header = Label.new()
	header.text = text
	header.add_theme_font_size_override("font_size", 18)
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
		# Disconnect any existing connections first
		if equipment_manager.equipment_changed.is_connected(_on_equipment_changed):
			equipment_manager.equipment_changed.disconnect(_on_equipment_changed)
		
		# Connect to equipment changes
		equipment_manager.equipment_changed.connect(_on_equipment_changed)
		print("✅ Connected to equipment_manager.equipment_changed signal")
	else:
		print("❌ No equipment_manager to connect signals to")
	
	if skill_manager:
		if skill_manager.skill_learned.is_connected(_on_skill_learned):
			skill_manager.skill_learned.disconnect(_on_skill_learned)
		if skill_manager.skill_unlearned.is_connected(_on_skill_unlearned):
			skill_manager.skill_unlearned.disconnect(_on_skill_unlearned)
		if skill_manager.skill_points_changed.is_connected(_on_skill_points_changed):
			skill_manager.skill_points_changed.disconnect(_on_skill_points_changed)
			
		skill_manager.skill_learned.connect(_on_skill_learned)
		skill_manager.skill_unlearned.connect(_on_skill_unlearned)
		skill_manager.skill_points_changed.connect(_on_skill_points_changed)
	
	if character_stats:
		if character_stats.stats_recalculated.is_connected(_on_stats_recalculated):
			character_stats.stats_recalculated.disconnect(_on_stats_recalculated)
		character_stats.stats_recalculated.connect(_on_stats_recalculated)

# Event handlers
func _on_equipment_slot_clicked(slot_type: EquipmentSlot.SlotType):
	"""Handle equipment slot click"""
	equipment_slot_clicked.emit(slot_type)
	print("Equipment slot clicked: ", EquipmentSlot.SlotType.keys()[slot_type])
	
	# Check if there's already an item equipped
	var equipped_item = equipment_manager.get_equipped_item(slot_type)
	
	if equipped_item:
		# Show item detail view for the equipped item
		if GameManager and GameManager.game_ui:
			GameManager.game_ui.show_item_detail(equipped_item)
	else:
		# Handle empty slot click - offer helpful options
		handle_empty_slot_click(slot_type)

func handle_empty_slot_click(slot_type: EquipmentSlot.SlotType):
	"""Handle clicking on an empty equipment slot"""
	var slot_name = equipment_manager.get_slot_display_name(slot_type)
	
	# Option 1: Show a helpful message
	if GameManager and GameManager.game_ui:
		GameManager.game_ui.show_info("No item equipped in " + slot_name + " slot. Check your inventory for compatible equipment.")
	
	# Option 2: Auto-open inventory menu (uncomment if you want this behavior)
	# if GameManager and GameManager.game_ui and GameManager.game_ui.inventory_menu:
	#	 GameManager.game_ui.inventory_menu.show_menu()
	#	 GameManager.game_ui.show_info("Opening inventory - look for " + slot_name + " equipment")
	
	# Option 3: Show available compatible items from inventory (more advanced)
	show_compatible_items_for_slot(slot_type)

func show_compatible_items_for_slot(slot_type: EquipmentSlot.SlotType):
	"""Show available items that can be equipped in this slot"""
	if not GameManager or not GameManager.inventory_manager:
		return
	
	var inventory = GameManager.inventory_manager
	var compatible_items = []
	
	# Check all inventory slots for compatible equipment
	for i in range(inventory.max_slots):
		var slot = inventory.get_slot(i)
		if not slot.is_empty() and slot.item.item_type == BaseItem.ItemType.EQUIPMENT:
			var equipment_item = slot.item as EquipmentItem
			if equipment_item and slot_type in equipment_item.compatible_slots:
				compatible_items.append({
					"item": equipment_item,
					"slot_index": i,
					"quantity": slot.quantity
				})
	
	# Show results
	if compatible_items.size() > 0:
		var slot_name = equipment_manager.get_slot_display_name(slot_type)
		var message = "Found " + str(compatible_items.size()) + " compatible item(s) for " + slot_name + ":"
		
		for item_data in compatible_items:
			message += "\n• " + item_data.item.item_name
		
		message += "\n\nOpen your inventory to equip these items."
		
		if GameManager and GameManager.game_ui:
			GameManager.game_ui.show_info(message)
		
		print("Compatible items for ", EquipmentSlot.SlotType.keys()[slot_type], ":")
		for item_data in compatible_items:
			print("  - ", item_data.item.item_name, " (slot ", item_data.slot_index, ")")
	else:
		var slot_name = equipment_manager.get_slot_display_name(slot_type)
		if GameManager and GameManager.game_ui:
			GameManager.game_ui.show_warning("No compatible equipment found for " + slot_name + " slot in your inventory.")

func _on_equipment_changed(slot_type: EquipmentSlot.SlotType, old_item: EquipmentItem, new_item: EquipmentItem):
	"""Handle equipment changes"""
	update_equipment_slot_display(slot_type)
	refresh_stats_display()
	
	# Emit signals for other systems
	if old_item and new_item:
		item_equipped.emit(new_item, slot_type)
	elif new_item:
		item_equipped.emit(new_item, slot_type)
	elif old_item:
		item_unequipped.emit(old_item, slot_type)

func _on_skill_button_clicked(skill: SkillNode):
	"""Handle skill button click"""
	if skill_manager:
		if skill.is_learned():
			# Try to unlearn (for respec)
			skill_manager.unlearn_skill(skill.skill_id)
		else:
			# Try to learn
			skill_manager.learn_skill(skill.skill_id)

func _on_skill_learned(skill: SkillNode):
	"""Handle skill learned"""
	refresh_skills_display()

func _on_skill_unlearned(skill: SkillNode):
	"""Handle skill unlearned"""
	refresh_skills_display()

func _on_skill_points_changed(current_points: int):
	"""Handle skill points changed"""
	var sp_label = skills_tab.get_node("VBoxContainer/HBoxContainer/SkillPointsValue")
	if sp_label:
		sp_label.text = str(current_points)

func _on_stats_recalculated():
	"""Handle stats recalculation"""
	refresh_stats_display()

func _on_equipment_slot_mouse_entered(slot_type: EquipmentSlot.SlotType, button: Button):
	"""Handle mouse enter on equipment slot"""
	current_hovered_item = button
	tooltip_timer.start()

func _on_equipment_slot_mouse_exited(slot_type: EquipmentSlot.SlotType):
	"""Handle mouse exit on equipment slot"""
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

func _on_skill_mouse_entered(skill: SkillNode, button: Button):
	"""Handle mouse enter on skill"""
	current_hovered_item = button
	tooltip_timer.start()

func _on_skill_mouse_exited(skill: SkillNode):
	"""Handle mouse exit on skill"""
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
	
	# Determine what kind of item this is and create appropriate tooltip
	if item in equipment_slot_buttons.values():
		tooltip_text = create_equipment_slot_tooltip(item)
	# Add other tooltip types as needed
	
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
		text += "\n[color=gray]Click to unequip[/color]"
		return text
	else:
		return "[b]" + slot_name + "[/b]\n\nEmpty slot\n\n[color=gray]Click to equip item[/color]"

# Display update methods
func update_equipment_slot_display(slot_type: EquipmentSlot.SlotType):
	"""Update the display of a specific equipment slot"""
	if not equipment_slot_buttons.has(slot_type):
		print("No button found for slot type: ", EquipmentSlot.SlotType.keys()[slot_type])
		return
	
	var button = equipment_slot_buttons[slot_type]
	var equipped_item = equipment_manager.get_equipped_item(slot_type) if equipment_manager else null
	
	if equipped_item:
		# Show first letter of item name + star
		var display_text = equipped_item.item_name.substr(0, 1).to_upper() + "★"
		button.text = display_text
		button.add_theme_color_override("font_color", equipped_item.get_rarity_color())
		
		# Update button style to show equipped state
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
		
		print("Updated equipment slot ", EquipmentSlot.SlotType.keys()[slot_type], " with item: ", equipped_item.item_name)
	else:
		button.text = ""
		button.add_theme_color_override("font_color", Color.WHITE)
		
		# Reset to default style
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
		
		print("Updated equipment slot ", EquipmentSlot.SlotType.keys()[slot_type], " to empty")

func refresh_stats_display():
	"""Refresh the entire stats display"""
	if not stats_categories_container:
		return
	
	# Clear and recreate stats display
	for child in stats_categories_container.get_children():
		child.queue_free()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	create_stats_categories()

func refresh_skills_display():
	"""Refresh the skills display"""
	if not skills_tab:
		return
	
	# Remove old skills display and recreate
	var old_skills = skills_tab.get_child(0)
	if old_skills:
		old_skills.queue_free()
	
	await get_tree().process_frame
	
	var new_skills = create_skills_tab().get_child(0)
	skills_tab.add_child(new_skills)

func refresh_all_displays():
	"""Public method to refresh all displays - can be called externally"""
	if not is_inside_tree():
		return
	
	refresh_stats_display()
	refresh_skills_display()
	refresh_equipment_display()
	
	# Update all equipment slots
	for slot_type in equipment_slot_buttons:
		update_equipment_slot_display(slot_type)
		
func refresh_equipment_display():
	"""Refresh all equipment slot displays"""
	for slot_type in equipment_slot_buttons:
		update_equipment_slot_display(slot_type)
