# WarbandMenu.gd
extends BaseMenu
class_name WarbandMenu

# Warband Components
var warband_panel: PanelContainer
var members_container: VBoxContainer
var members_scroll: ScrollContainer

# Header components
var warband_info_panel: PanelContainer
var warband_stats_container: HBoxContainer

# Member panels
var member_panels: Array = []

# References
var warband_manager: WarbandManager

# Signals
signal warband_member_selected(member_index: int)
signal warband_member_clicked(member_index: int)

func ready_post():
	menu_title = "Warband"
	title_label.text = menu_title
	initialize_references()
	create_warband_interface()
	connect_signals()

func initialize_references():
	"""Initialize references to game systems"""
	# Get warband manager from GameManager
	if GameManager and GameManager.has_method("get_warband_manager"):
		warband_manager = GameManager.get_warband_manager()
	elif GameManager and GameManager.warband_manager:
		warband_manager = GameManager.warband_manager
	else:
		# Create a mock warband manager for now if none exists
		warband_manager = create_mock_warband_manager()

func create_mock_warband_manager():
	"""Create a mock warband manager with sample data for testing"""
	var mock_manager = RefCounted.new()
	
	# Add some sample members
	var sample_members = [
		{
			"name": "Sir Gareth",
			"level": 5,
			"class": "Knight",
			"portrait_path": "res://assets/portraits/knight.png",
			"hp": 85,
			"max_hp": 100,
			"status": "Ready"
		},
		{
			"name": "Elena Swift",
			"level": 3,
			"class": "Archer",
			"portrait_path": "res://assets/portraits/archer.png",
			"hp": 60,
			"max_hp": 75,
			"status": "Ready"
		},
		{
			"name": "Magnus Iron",
			"level": 4,
			"class": "Warrior",
			"portrait_path": "res://assets/portraits/warrior.png",
			"hp": 45,
			"max_hp": 90,
			"status": "Injured"
		},
		{
			"name": "Lydia Wise",
			"level": 6,
			"class": "Mage",
			"portrait_path": "res://assets/portraits/mage.png",
			"hp": 55,
			"max_hp": 65,
			"status": "Ready"
		}
	]
	
	mock_manager.set_script(null)
	mock_manager.members = sample_members
	
	# Add methods to the mock manager
	mock_manager.set("get_member_count", func(): return sample_members.size())
	mock_manager.set("get_member", func(index): return sample_members[index] if index < sample_members.size() else null)
	mock_manager.set("get_all_members", func(): return sample_members)
	mock_manager.set("get_warband_name", func(): return "The Iron Company")
	mock_manager.set("get_warband_level", func(): return 3)
	mock_manager.set("get_total_members", func(): return sample_members.size())
	
	return mock_manager

func create_warband_interface():
	"""Create the warband interface"""
	# Clear existing content
	for child in item_container.get_children():
		child.queue_free()
	
	create_main_layout()
	
	# Initial data refresh
	refresh_warband_display()

func create_main_layout():
	"""Create the main layout for the warband menu"""
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 15)
	
	# Warband info header
	create_warband_info_panel(main_container)
	
	# Members section
	create_members_section(main_container)
	
	item_container.add_child(main_container)

func create_warband_info_panel(parent: VBoxContainer):
	"""Create the warband information header panel"""
	warband_info_panel = PanelContainer.new()
	warband_info_panel.custom_minimum_size = Vector2(600, 80)
	
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
	warband_info_panel.add_theme_stylebox_override("panel", style)
	
	warband_stats_container = HBoxContainer.new()
	warband_stats_container.add_theme_constant_override("separation", 20)
	
	# Warband name and level
	var info_vbox = VBoxContainer.new()
	
	var warband_name_label = Label.new()
	if warband_manager:
		warband_name_label.text = warband_manager.call("get_warband_name")
	else:
		warband_name_label.text = "No Warband"
	warband_name_label.add_theme_font_size_override("font_size", 18)
	warband_name_label.add_theme_color_override("font_color", Color.GOLD)
	info_vbox.add_child(warband_name_label)
	
	var level_label = Label.new()
	if warband_manager:
		level_label.text = "Warband Level: " + str(warband_manager.call("get_warband_level"))
	else:
		level_label.text = "Warband Level: 1"
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	info_vbox.add_child(level_label)
	
	warband_stats_container.add_child(info_vbox)
	
	# Member count
	var member_count_vbox = VBoxContainer.new()
	
	var count_label = Label.new()
	if warband_manager:
		count_label.text = "Members: " + str(warband_manager.call("get_total_members"))
	else:
		count_label.text = "Members: 0"
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	member_count_vbox.add_child(count_label)
	
	var ready_count = 0
	if warband_manager:
		var all_members = warband_manager.call("get_all_members")
		for member in all_members:
			if member.get("status", "Ready") == "Ready":
				ready_count += 1
	
	var ready_label = Label.new()
	ready_label.text = "Ready: " + str(ready_count)
	ready_label.add_theme_font_size_override("font_size", 12)
	ready_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	member_count_vbox.add_child(ready_label)
	
	warband_stats_container.add_child(member_count_vbox)
	
	warband_info_panel.add_child(warband_stats_container)
	parent.add_child(warband_info_panel)

func create_members_section(parent: VBoxContainer):
	"""Create the members list section"""
	warband_panel = PanelContainer.new()
	warband_panel.custom_minimum_size = Vector2(600, 400)
	warband_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warband_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
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
	warband_panel.add_theme_stylebox_override("panel", style)
	
	var members_vbox = VBoxContainer.new()
	members_vbox.add_theme_constant_override("separation", 10)
	
	# Header
	var members_header = create_section_header("Warband Members")
	members_vbox.add_child(members_header)
	
	# Scrollable members list
	members_scroll = ScrollContainer.new()
	members_scroll.custom_minimum_size = Vector2(580, 350)
	members_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	members_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	members_container = VBoxContainer.new()
	members_container.add_theme_constant_override("separation", 8)
	members_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	members_scroll.add_child(members_container)
	members_vbox.add_child(members_scroll)
	
	warband_panel.add_child(members_vbox)
	parent.add_child(warband_panel)

func create_section_header(text: String) -> Label:
	"""Create a section header label"""
	var header = Label.new()
	header.text = text
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color.GOLD)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return header

func refresh_warband_display():
	"""Refresh the entire warband display"""
	if not is_inside_tree():
		return
	
	refresh_members_list()

func refresh_members_list():
	"""Refresh the members list"""
	# Clear existing member panels
	for panel in member_panels:
		if panel:
			panel.queue_free()
	member_panels.clear()
	
	# Clear container
	if members_container:
		for child in members_container.get_children():
			child.queue_free()
	
	if not warband_manager:
		create_no_members_message()
		return
	
	# Get all members
	var all_members = warband_manager.call("get_all_members")
	
	if all_members.is_empty():
		create_no_members_message()
		return
	
	# Create member panels
	for i in range(all_members.size()):
		var member = all_members[i]
		var member_panel = create_member_panel(member, i)
		member_panels.append(member_panel)
		members_container.add_child(member_panel)

func create_no_members_message():
	"""Create a message when no members are available"""
	var no_members_label = Label.new()
	no_members_label.text = "No warband members found.\nRecruit members to build your warband!"
	no_members_label.add_theme_font_size_override("font_size", 14)
	no_members_label.add_theme_color_override("font_color", Color.GRAY)
	no_members_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	no_members_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	no_members_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	members_container.add_child(no_members_label)

func create_member_panel(member: Dictionary, index: int) -> PanelContainer:
	"""Create a panel for a single warband member"""
	var panel = PanelContainer.new()
	panel.name = "MemberPanel_" + str(index)
	panel.custom_minimum_size = Vector2(560, 80)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Store member index as metadata
	panel.set_meta("member_index", index)
	
	# Style based on member status
	style_member_panel(panel, member)
	
	# Create member content
	create_member_content(panel, member, index)
	
	# Connect signals
	panel.gui_input.connect(_on_member_panel_input.bind(panel, index))
	panel.mouse_entered.connect(_on_member_panel_mouse_entered.bind(panel, member))
	panel.mouse_exited.connect(_on_member_panel_mouse_exited.bind(panel))
	
	return panel

func style_member_panel(panel: PanelContainer, member: Dictionary):
	"""Apply styling to a member panel based on status"""
	var style = StyleBoxFlat.new()
	
	# Different styling based on member status
	var status = member.get("status", "Ready")
	match status:
		"Ready":
			style.bg_color = Color(0.1, 0.2, 0.1, 0.8)
			style.border_color = Color.LIGHT_GREEN
		"Injured":
			style.bg_color = Color(0.2, 0.1, 0.1, 0.8)
			style.border_color = Color.ORANGE
		"Unavailable":
			style.bg_color = Color(0.15, 0.15, 0.15, 0.8)
			style.border_color = Color.GRAY
		_:
			style.bg_color = Color(0.1, 0.1, 0.2, 0.8)
			style.border_color = Color.WHITE
	
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	
	panel.add_theme_stylebox_override("panel", style)

func create_member_content(panel: PanelContainer, member: Dictionary, index: int):
	"""Create the content inside a member panel"""
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Portrait section (left)
	var portrait_container = create_member_portrait(member)
	hbox.add_child(portrait_container)
	
	# Info section (right)
	var info_container = create_member_info(member)
	hbox.add_child(info_container)
	
	panel.add_child(hbox)

func create_member_portrait(member: Dictionary) -> PanelContainer:
	"""Create the portrait section for a member"""
	var portrait_container = PanelContainer.new()
	portrait_container.custom_minimum_size = Vector2(60, 60)
	
	# Portrait frame style
	var portrait_style = StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	portrait_style.border_color = Color(0.5, 0.5, 0.5)
	portrait_style.border_width_left = 1
	portrait_style.border_width_right = 1
	portrait_style.border_width_top = 1
	portrait_style.border_width_bottom = 1
	portrait_style.corner_radius_top_left = 4
	portrait_style.corner_radius_top_right = 4
	portrait_style.corner_radius_bottom_left = 4
	portrait_style.corner_radius_bottom_right = 4
	portrait_container.add_theme_stylebox_override("panel", portrait_style)
	
	var portrait_rect = TextureRect.new()
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.custom_minimum_size = Vector2(50, 50)
	
	# Try to load member portrait
	var portrait_path = member.get("portrait_path", "")
	var portrait_texture = null
	
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait_texture = load(portrait_path)
	
	# Fall back to default portrait
	if not portrait_texture:
		portrait_texture = preload("res://assets/ui/menus/default.png")  # Use your default texture
	
	portrait_rect.texture = portrait_texture
	portrait_container.add_child(portrait_rect)
	
	return portrait_container

func create_member_info(member: Dictionary) -> VBoxContainer:
	"""Create the info section for a member"""
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	
	# Top row: Name and Level
	var top_hbox = HBoxContainer.new()
	top_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = member.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(name_label)
	
	var level_label = Label.new()
	level_label.text = "Level " + str(member.get("level", 1))
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_hbox.add_child(level_label)
	
	info_vbox.add_child(top_hbox)
	
	# Middle row: Class
	var class_label = Label.new()
	class_label.text = member.get("class", "Unknown Class")
	class_label.add_theme_font_size_override("font_size", 14)
	class_label.add_theme_color_override("font_color", Color.YELLOW)
	info_vbox.add_child(class_label)
	
	# Bottom row: Health and Status
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var hp_label = Label.new()
	var current_hp = member.get("hp", 100)
	var max_hp = member.get("max_hp", 100)
	hp_label.text = "HP: " + str(current_hp) + "/" + str(max_hp)
	hp_label.add_theme_font_size_override("font_size", 12)
	
	# Color HP based on percentage
	var hp_percentage = float(current_hp) / float(max_hp)
	if hp_percentage > 0.7:
		hp_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	elif hp_percentage > 0.3:
		hp_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		hp_label.add_theme_color_override("font_color", Color.RED)
	
	bottom_hbox.add_child(hp_label)
	
	var status_label = Label.new()
	var status = member.get("status", "Ready")
	status_label.text = status
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	# Color status
	match status:
		"Ready":
			status_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
		"Injured":
			status_label.add_theme_color_override("font_color", Color.ORANGE)
		"Unavailable":
			status_label.add_theme_color_override("font_color", Color.GRAY)
		_:
			status_label.add_theme_color_override("font_color", Color.WHITE)
	
	bottom_hbox.add_child(status_label)
	
	info_vbox.add_child(bottom_hbox)
	
	return info_vbox

func connect_signals():
	"""Connect all signals"""
	# No external signals to connect for now
	pass

# Event handlers
func _on_member_panel_input(event: InputEvent, panel: PanelContainer, index: int):
	"""Handle input on member panels"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_member_clicked(index)

func _on_member_clicked(index: int):
	"""Handle member being clicked"""
	print("Warband member clicked: ", index)
	warband_member_clicked.emit(index)
	
	# For now, just show a message
	if GameManager and GameManager.game_ui:
		var member = warband_manager.call("get_member", index) if warband_manager else null
		if member:
			var member_name = member.get("name", "Unknown")
			GameManager.game_ui.show_info("Clicked on " + member_name + ". (Detail view coming soon!)")

func _on_member_panel_mouse_entered(panel: PanelContainer, member: Dictionary):
	"""Handle mouse entering a member panel"""
	# Add hover effect
	var style = panel.get_theme_stylebox("panel").duplicate()
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	panel.add_theme_stylebox_override("panel", style)

func _on_member_panel_mouse_exited(panel: PanelContainer):
	"""Handle mouse leaving a member panel"""
	# Get member index and re-style
	var index = panel.get_meta("member_index")
	if warband_manager:
		var member = warband_manager.call("get_member", index)
		if member:
			style_member_panel(panel, member)

# Public interface methods
func get_selected_member_index() -> int:
	"""Get the currently selected member index"""
	return -1  # No selection system implemented yet

func refresh_all_displays():
	"""Refresh all displays (called by GameUI)"""
	refresh_warband_display()

# Debug method
func debug_print_warband_state():
	"""Debug method to print current warband state"""
	print("=== WarbandMenu Debug State ===")
	print("Warband Manager: ", warband_manager != null)
	if warband_manager:
		print("Warband Name: ", warband_manager.call("get_warband_name"))
		print("Member Count: ", warband_manager.call("get_total_members"))
	print("Member Panels: ", member_panels.size())
	print("===============================")
