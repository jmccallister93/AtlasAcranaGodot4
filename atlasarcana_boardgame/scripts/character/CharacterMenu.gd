extends BaseMenu
class_name CharacterMenu

# Stat data structure
var stat_data = {
	"Health": {"value": 100, "max": 120, "description": "Your life force. When it reaches 0, you die."},
	"Movement": {"value": 15, "max": 20, "description": "How fast you can move and traverse the world."},
	"Attack": {"value": 25, "max": 30, "description": "Your physical damage output in combat."},
	"Defense": {"value": 18, "max": 25, "description": "Your ability to resist and mitigate incoming damage."},
	"Stamina": {"value": 80, "max": 100, "description": "Energy for special abilities and sustained actions."},
	"Build": {"value": 12, "max": 15, "description": "Your construction and crafting capabilities."}
}

# UI References
var tooltip: PanelContainer
var tooltip_timer: Timer
var detailed_view: PanelContainer
var current_hovered_stat: String = ""
var stat_panels: Dictionary = {}  # Store panel references

func ready_post():
	menu_title = "Character"
	title_label.text = menu_title
	create_character_interface()

func create_character_interface():
	# Clear existing items
	for child in item_container.get_children():
		child.queue_free()
	
	# Clear panel references
	stat_panels.clear()
	
	# Create main stats container
	var stats_container = create_stats_container()
	item_container.add_child(stats_container)
	
	# Create tooltip system
	create_tooltip_system()
	
	# Create detailed view system
	create_detailed_view_system()

func create_stats_container() -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	
	# Create header
	var header = create_section_header("Character Stats")
	container.add_child(header)
	
	# Create grid for stats
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 10)
	
	# Add stats to grid
	for stat_name in stat_data.keys():
		var stat_panel = create_stat_panel(stat_name)
		stat_panels[stat_name] = stat_panel  # Store reference
		grid.add_child(stat_panel)
	
	container.add_child(grid)
	return container

func create_section_header(text: String) -> Label:
	var header = Label.new()
	header.text = text
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color.GOLD)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Add some styling
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color.GOLD
	stylebox.corner_radius_top_left = 5
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_left = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.content_margin_top = 8
	stylebox.content_margin_bottom = 8
	header.add_theme_stylebox_override("normal", stylebox)
	
	return header

func create_stat_panel(stat_name: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 80)
	panel.name = "StatPanel_" + stat_name
	
	# Create panel style
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	stylebox.border_width_left = 3
	stylebox.border_width_right = 3
	stylebox.border_width_top = 3
	stylebox.border_width_bottom = 3
	stylebox.border_color = Color(0.4, 0.4, 0.6, 1.0)
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.content_margin_left = 12
	stylebox.content_margin_right = 12
	stylebox.content_margin_top = 8
	stylebox.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", stylebox)
	
	# Create content container
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	
	# Stat name label
	var name_label = Label.new()
	name_label.text = stat_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)
	
	# Value display
	var value_container = create_stat_value_display(stat_name)
	vbox.add_child(value_container)
	
	panel.add_child(vbox)
	
	# Make panel interactive
	panel.mouse_entered.connect(_on_stat_panel_mouse_entered.bind(stat_name, panel))
	panel.mouse_exited.connect(_on_stat_panel_mouse_exited.bind(stat_name))
	panel.gui_input.connect(_on_stat_panel_input.bind(stat_name))
	
	return panel

func create_stat_value_display(stat_name: String) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	
	var stat = stat_data[stat_name]
	
	# Current value
	var value_label = Label.new()
	value_label.text = str(stat.value)
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	container.add_child(value_label)
	
	# Separator
	var separator = Label.new()
	separator.text = "/"
	separator.add_theme_color_override("font_color", Color.GRAY)
	container.add_child(separator)
	
	# Max value
	var max_label = Label.new()
	max_label.text = str(stat.max)
	max_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	container.add_child(max_label)
	
	# Progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(100, 8)
	progress_bar.max_value = stat.max
	progress_bar.value = stat.value
	progress_bar.show_percentage = false
	
	# Style the progress bar
	var progress_stylebox = StyleBoxFlat.new()
	progress_stylebox.bg_color = Color(0.2, 0.6, 0.2, 1.0)
	progress_stylebox.corner_radius_top_left = 4
	progress_stylebox.corner_radius_top_right = 4
	progress_stylebox.corner_radius_bottom_left = 4
	progress_stylebox.corner_radius_bottom_right = 4
	progress_bar.add_theme_stylebox_override("fill", progress_stylebox)
	
	var bg_stylebox = StyleBoxFlat.new()
	bg_stylebox.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	bg_stylebox.corner_radius_top_left = 4
	bg_stylebox.corner_radius_top_right = 4
	bg_stylebox.corner_radius_bottom_left = 4
	bg_stylebox.corner_radius_bottom_right = 4
	progress_bar.add_theme_stylebox_override("background", bg_stylebox)
	
	container.add_child(progress_bar)
	
	return container

func create_tooltip_system():
	# Create tooltip timer
	tooltip_timer = Timer.new()
	tooltip_timer.wait_time = 1.0
	tooltip_timer.one_shot = true
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
	add_child(tooltip_timer)
	
	# Create tooltip panel
	tooltip = PanelContainer.new()
	tooltip.visible = false
	tooltip.z_index = 100
	
	# Tooltip styling
	var tooltip_style = StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	tooltip_style.border_width_left = 2
	tooltip_style.border_width_right = 2
	tooltip_style.border_width_top = 2
	tooltip_style.border_width_bottom = 2
	tooltip_style.border_color = Color.YELLOW
	tooltip_style.corner_radius_top_left = 6
	tooltip_style.corner_radius_top_right = 6
	tooltip_style.corner_radius_bottom_left = 6
	tooltip_style.corner_radius_bottom_right = 6
	tooltip_style.content_margin_left = 10
	tooltip_style.content_margin_right = 10
	tooltip_style.content_margin_top = 8
	tooltip_style.content_margin_bottom = 8
	tooltip.add_theme_stylebox_override("panel", tooltip_style)
	
	# Tooltip label
	var tooltip_label = Label.new()
	tooltip_label.name = "TooltipLabel"
	tooltip_label.add_theme_color_override("font_color", Color.WHITE)
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_label.custom_minimum_size = Vector2(200, 0)
	tooltip.add_child(tooltip_label)
	
	add_child(tooltip)

func create_detailed_view_system():
	detailed_view = PanelContainer.new()
	detailed_view.visible = false
	detailed_view.z_index = 50
	detailed_view.custom_minimum_size = Vector2(400, 300)
	
	# Center the detailed view within the character menu
	detailed_view.anchor_left = 0.5
	detailed_view.anchor_top = 0.5
	detailed_view.anchor_right = 0.5
	detailed_view.anchor_bottom = 0.5
	detailed_view.offset_left = -200  # Half of width to center
	detailed_view.offset_top = -150   # Half of height to center
	detailed_view.offset_right = 200
	detailed_view.offset_bottom = 150
	
	# Detailed view styling
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	detail_style.border_width_left = 3
	detail_style.border_width_right = 3
	detail_style.border_width_top = 3
	detail_style.border_width_bottom = 3
	detail_style.border_color = Color.CYAN
	detail_style.corner_radius_top_left = 10
	detail_style.corner_radius_top_right = 10
	detail_style.corner_radius_bottom_left = 10
	detail_style.corner_radius_bottom_right = 10
	detailed_view.add_theme_stylebox_override("panel", detail_style)
	
	# Content container
	var detail_vbox = VBoxContainer.new()
	detail_vbox.name = "DetailContainer"
	detailed_view.add_child(detail_vbox)
	
	add_child(detailed_view)

func create_detailed_content(stat_name: String) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 15)
	
	# Header with close button
	var header_container = HBoxContainer.new()
	
	var title = Label.new()
	title.text = stat_name + " Details"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.CYAN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(title)
	
	var close_button = Button.new()
	close_button.text = "×"
	close_button.add_theme_font_size_override("font_size", 20)
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.pressed.connect(_on_detailed_view_close)
	header_container.add_child(close_button)
	
	container.add_child(header_container)
	
	# Stat info
	var stat = stat_data[stat_name]
	
	var info_label = RichTextLabel.new()
	info_label.custom_minimum_size = Vector2(350, 200)
	info_label.bbcode_enabled = true
	info_label.text = "[b]%s[/b]\n\n[color=lightgreen]Current Value:[/color] %d\n[color=lightblue]Maximum Value:[/color] %d\n\n[color=yellow]Description:[/color]\n%s\n\n[color=orange]Effects:[/color]\n• Affects overall character performance\n• Can be upgraded through various means\n• Influences other stats and abilities" % [stat_name, stat.value, stat.max, stat.description]
	
	container.add_child(info_label)
	
	return container

# Event handlers
func _on_stat_panel_mouse_entered(stat_name: String, panel: PanelContainer):
	current_hovered_stat = stat_name
	tooltip_timer.start()
	
	# Highlight panel
	var stylebox = panel.get_theme_stylebox("panel").duplicate()
	stylebox.border_color = Color.YELLOW
	stylebox.bg_color = Color(0.2, 0.2, 0.35, 0.9)
	panel.add_theme_stylebox_override("panel", stylebox)

func _on_stat_panel_mouse_exited(stat_name: String):
	current_hovered_stat = ""
	tooltip_timer.stop()
	tooltip.visible = false
	
	# Reset panel highlight using stored reference
	var panel = stat_panels.get(stat_name)
	if panel:
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.15, 0.15, 0.25, 0.9)
		stylebox.border_width_left = 3
		stylebox.border_width_right = 3
		stylebox.border_width_top = 3
		stylebox.border_width_bottom = 3
		stylebox.border_color = Color(0.4, 0.4, 0.6, 1.0)
		stylebox.corner_radius_top_left = 8
		stylebox.corner_radius_top_right = 8
		stylebox.corner_radius_bottom_left = 8
		stylebox.corner_radius_bottom_right = 8
		stylebox.content_margin_left = 12
		stylebox.content_margin_right = 12
		stylebox.content_margin_top = 8
		stylebox.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", stylebox)

func _on_stat_panel_input(event: InputEvent, stat_name: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_stat_clicked(stat_name)

func _on_stat_clicked(stat_name: String):
	# Clear existing content
	var detail_container = detailed_view.get_node("DetailContainer")
	for child in detail_container.get_children():
		child.queue_free()
	
	# Add new content
	var content = create_detailed_content(stat_name)
	detail_container.add_child(content)
	
	# Show detailed view
	detailed_view.visible = true
	tooltip.visible = false

func _on_tooltip_timer_timeout():
	if current_hovered_stat != "":
		_on_show_tooltip(current_hovered_stat)

func _on_show_tooltip(stat_name: String):
	var tooltip_label = tooltip.get_node("TooltipLabel")
	tooltip_label.text = stat_data[stat_name].description
	
	# Position tooltip near mouse using local coordinates
	var global_mouse_pos = get_global_mouse_position()
	var local_mouse_pos = global_mouse_pos - global_position
	
	# Offset tooltip to avoid covering the cursor
	var tooltip_pos = local_mouse_pos + Vector2(15, -15)
	
	# Keep tooltip within menu bounds
	var menu_rect = get_rect()
	tooltip_pos.x = clamp(tooltip_pos.x, 10, menu_rect.size.x - tooltip.custom_minimum_size.x - 10)
	tooltip_pos.y = clamp(tooltip_pos.y, 10, menu_rect.size.y - 100)  # Leave room for tooltip height
	
	tooltip.position = tooltip_pos
	tooltip.visible = true

func _on_detailed_view_close():
	detailed_view.visible = false

# Utility function to update stat values (for when you connect real data)
func update_stat_value(stat_name: String, new_value: int, new_max: int = -1):
	if stat_name in stat_data:
		stat_data[stat_name].value = new_value
		if new_max > 0:
			stat_data[stat_name].max = new_max
		
		# Refresh the display
		create_character_interface()
