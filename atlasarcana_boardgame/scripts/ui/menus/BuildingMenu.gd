extends BaseMenu
class_name BuildingMenu

# Building data structure
#var building_data = {
	#"Farm": {
		#"type": "production",
		#"owned": 3,
		#"coordinates": [Vector2(10, 15), Vector2(12, 18), Vector2(8, 20)],
		#"production_rate": 25,
		#"production_type": "Food",
		#"description": "Produces food to feed your population. Essential for growth.",
		#"upgrade_levels": ["Basic Farm", "Advanced Farm", "Mega Farm"],
		#"current_level": 1,
		#"can_craft": false
	#},
	#"Lumber Mill": {
		#"type": "production",
		#"owned": 2,
		#"coordinates": [Vector2(5, 8), Vector2(22, 12)],
		#"production_rate": 18,
		#"production_type": "Wood",
		#"description": "Harvests and processes wood for construction projects.",
		#"upgrade_levels": ["Basic Mill", "Steam Mill", "Industrial Mill"],
		#"current_level": 0,
		#"can_craft": false
	#},
	#"Forge": {
		#"type": "crafting",
		#"owned": 1,
		#"coordinates": [Vector2(15, 10)],
		#"production_rate": 0,
		#"production_type": "",
		#"description": "Crafts weapons, tools, and metal goods from raw materials.",
		#"upgrade_levels": ["Basic Forge", "Master Forge", "Legendary Forge"],
		#"current_level": 0,
		#"can_craft": true,
		#"craft_options": ["Iron Sword", "Steel Hammer", "Bronze Shield", "Iron Pickaxe"]
	#},
	#"Stables": {
		#"type": "utility",
		#"owned": 1,
		#"coordinates": [Vector2(18, 14)],
		#"production_rate": 0,
		#"production_type": "",
		#"description": "Houses and trains horses for faster movement and cavalry units.",
		#"upgrade_levels": ["Basic Stables", "War Stables", "Royal Stables"],
		#"current_level": 0,
		#"can_craft": false
	#},
	#"Docks": {
		#"type": "utility",
		#"owned": 0,
		#"coordinates": [],
		#"production_rate": 0,
		#"production_type": "",
		#"description": "Enables water trade routes and naval unit construction.",
		#"upgrade_levels": ["Wooden Dock", "Stone Harbor", "Naval Fortress"],
		#"current_level": 0,
		#"can_craft": false
	#},
	#"Mine": {
		#"type": "production",
		#"owned": 0,
		#"coordinates": [],
		#"production_rate": 30,
		#"production_type": "Stone & Ore",
		#"description": "Extracts valuable stone and metal ore from underground deposits.",
		#"upgrade_levels": ["Shallow Mine", "Deep Mine", "Excavation Complex"],
		#"current_level": 0,
		#"can_craft": false
	#}
#}
var build_manager: BuildManager
var building_data: Dictionary = {}
# UI References
var building_tooltip: PanelContainer
var building_tooltip_timer: Timer
var building_detail_view: PanelContainer
var current_hovered_building: String = ""
var building_panels: Dictionary = {}

func ready_post():
	menu_title = "Building Management"
	title_label.text = menu_title
	# Connect to BuildManager for real data
	connect_to_build_manager()
	
	# Load initial building data
	refresh_building_data()
	create_building_interface()

func connect_to_build_manager():
	"""Connect to BuildManager to get real building data"""
	if GameManager and GameManager.build_manager:
		build_manager = GameManager.build_manager
		
		# Connect to building events for real-time updates
		build_manager.building_completed.connect(_on_building_placed)
		# Remove this line: build_manager.building_placed.connect(_on_building_placed_direct)
		
		print("✅ BuildingMenu connected to BuildManager")

func _on_building_placed(new_building: Building, tile: BiomeTile):
	"""Handle new building placement"""
	print("BuildingMenu: New building placed - ", new_building.get_building_name())
	refresh_building_data()
	create_building_interface()

func _on_building_placed_direct():
	"""Handle direct building placement signal"""
	print("BuildingMenu: Building placed (direct signal)")
	refresh_building_data()
	create_building_interface()

func refresh_building_data():
	"""Load real building data from BuildManager and BuildingData"""
	building_data.clear()
	
	if not build_manager:
		create_fallback_data()
		return
	
	# Get all building types from BuildingData
	var building_definitions = BuildingData.get_building_definitions()
	
	for building_type in building_definitions:
		var building_definition = building_definitions[building_type]
		var building_name = building_data.get("name", "Unknown")
		
		# Get actual buildings of this type from BuildManager
		var placed_buildings = build_manager.get_buildings_of_type(building_name)
		
		# Calculate coordinates and production
		var coordinates = []
		var total_production = 0
		var production_type = ""
		
		for building in placed_buildings:
			coordinates.append(building.tile.grid_position)
			var building_production = building.get_production()
			for resource in building_production:
				total_production += building_production[resource]
				if production_type == "":
					production_type = resource.capitalize()
		
		# Create building data entry
		building_data[building_name] = {
			"type": _determine_building_type(building_data),
			"owned": placed_buildings.size(),
			"coordinates": coordinates,
			"production_rate": total_production,
			"production_type": production_type,
			"description": building_data.get("description", "No description available."),
			"upgrade_levels": ["Basic", "Advanced", "Master"],  # Could be from BuildingData
			"current_level": 0,  # Could be tracked per building
			"can_craft": building_data.get("crafting_recipes", {}).size() > 0,
			"craft_options": building_data.get("crafting_recipes", {}).keys(),
			"building_type_enum": building_type  # Store for building new ones
		}
	
	print("BuildingMenu: Refreshed data for ", building_data.size(), " building types")

func _determine_building_type(building_data: Dictionary) -> String:
	"""Determine building category from building data"""
	var base_production = building_data.get("base_production", {})
	var crafting_recipes = building_data.get("crafting_recipes", {})
	
	if crafting_recipes.size() > 0:
		return "crafting"
	elif base_production.size() > 0:
		return "production"
	else:
		return "utility"

func create_fallback_data():
	"""Create minimal fallback data if BuildManager not available"""
	building_data = {
		"Basic Structure": {
			"type": "utility",
			"owned": 0,
			"coordinates": [],
			"production_rate": 0,
			"production_type": "",
			"description": "A basic building structure.",
			"upgrade_levels": ["Basic"],
			"current_level": 0,
			"can_craft": false,
			"craft_options": [],
			"building_type_enum": BuildingData.BuildingType.BASIC_STRUCTURE
		}
	}

# Update all methods that used building_data to use real_building_data
func create_building_categories(container: VBoxContainer):
	# Group buildings by type
	var production_buildings = []
	var crafting_buildings = []
	var utility_buildings = []
	
	for building_name in building_data.keys():
		var building = building_data[building_name]
		match building.type:
			"production":
				production_buildings.append(building_name)
			"crafting":
				crafting_buildings.append(building_name)
			"utility":
				utility_buildings.append(building_name)
	
	# Create sections
	if production_buildings.size() > 0:
		create_building_section(container, "Production Buildings", production_buildings, Color("#228B22"))
	if crafting_buildings.size() > 0:
		create_building_section(container, "Crafting Buildings", crafting_buildings, Color("#CD853F"))
	if utility_buildings.size() > 0:
		create_building_section(container, "Utility Buildings", utility_buildings, Color("#4682B4"))

func create_building_panel(building_name: String, accent_color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 100)
	panel.name = "BuildingPanel_" + building_name
	
	var building = building_data[building_name]  # Use real_building_data
	
	# Create panel style with construction theme (keep existing styling)
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color("#2F1B14")
	stylebox.border_width_left = 2
	stylebox.border_width_right = 2
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = accent_color
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	stylebox.content_margin_left = 10
	stylebox.content_margin_right = 10
	stylebox.content_margin_top = 8
	stylebox.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", stylebox)
	
	# Create content
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	# Left side - Building info
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Building name
	var name_label = Label.new()
	name_label.text = building_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color("#F4A460"))
	left_vbox.add_child(name_label)
	
	# Count and coordinates
	var info_label = Label.new()
	var info_text = "Owned: %d" % building.owned
	if building.owned > 0:
		info_text += "\nLocations: " + _format_coordinates(building.coordinates)
	else:
		info_text += "\nNot built yet"
	info_label.text = info_text
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	left_vbox.add_child(info_label)
	
	hbox.add_child(left_vbox)
	
	# Right side - Production/Status
	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size.x = 100
	
	if building.type == "production" and building.owned > 0:
		var production_label = Label.new()
		production_label.text = "Production"
		production_label.add_theme_font_size_override("font_size", 12)
		production_label.add_theme_color_override("font_color", Color("#90EE90"))
		production_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right_vbox.add_child(production_label)
		
		var rate_label = Label.new()
		rate_label.text = "%d %s/turn" % [building.production_rate, building.production_type]
		rate_label.add_theme_font_size_override("font_size", 14)
		rate_label.add_theme_color_override("font_color", Color("#32CD32"))
		rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right_vbox.add_child(rate_label)
	elif building.can_craft:
		var craft_label = Label.new()
		craft_label.text = "Crafting\nAvailable"
		craft_label.add_theme_font_size_override("font_size", 12)
		craft_label.add_theme_color_override("font_color", Color("#FFD700"))
		craft_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right_vbox.add_child(craft_label)
	else:
		var status_label = Label.new()
		status_label.text = "Utility\nBuilding"
		status_label.add_theme_font_size_override("font_size", 12)
		status_label.add_theme_color_override("font_color", Color("#87CEEB"))
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right_vbox.add_child(status_label)
	
	hbox.add_child(right_vbox)
	panel.add_child(hbox)
	
	# Make interactive
	panel.mouse_entered.connect(_on_building_panel_mouse_entered.bind(building_name, panel))
	panel.mouse_exited.connect(_on_building_panel_mouse_exited.bind(building_name))
	panel.gui_input.connect(_on_building_panel_input.bind(building_name))
	
	return panel

func create_building_detail_content(building_name: String) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 12)
	
	var building = building_data[building_name]  # Use real_building_data
	
	# Header with close button (keep existing code)
	var header_container = HBoxContainer.new()
	
	var title = Label.new()
	title.text = building_name + " Management"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#F4A460"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(title)
	
	var close_button = Button.new()
	close_button.text = "×"
	close_button.add_theme_font_size_override("font_size", 20)
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.pressed.connect(_on_building_detail_close)
	header_container.add_child(close_button)
	
	container.add_child(header_container)
	
	# Building information (updated with real data)
	var info_text = RichTextLabel.new()
	info_text.custom_minimum_size = Vector2(400, 150)
	info_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_text.bbcode_enabled = true
	
	var info_content = "[b]%s[/b]\n[color=lightgray]%s[/color]\n\n" % [building_name, building.description]
	info_content += "[color=orange]Owned:[/color] %d buildings\n" % building.owned
	
	if building.owned > 0:
		info_content += "[color=orange]Locations:[/color] %s\n" % _format_coordinates(building.coordinates)
	
	if building.type == "production" and building.production_rate > 0:
		info_content += "[color=lightgreen]Total Production:[/color] %d %s per turn\n" % [building.production_rate, building.production_type]
	
	info_content += "[color=yellow]Upgrade Level:[/color] %s" % building.upgrade_levels[building.current_level]
	
	info_text.text = info_content
	container.add_child(info_text)
	
	# Spacer to push action buttons to bottom
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(spacer)
	
	# Action buttons at the bottom
	var action_container = create_building_actions(building_name)
	container.add_child(action_container)
	
	return container

# Update the build new function to use real building system
func _on_build_new(building_name: String):
	print("Building new ", building_name)
	
	# Hide this menu
	hide_menu()
	
	# Start build mode for this specific building type
	if build_manager and GameManager:
		var building_data = building_data[building_name]
		var building_type_enum = building_data.get("building_type_enum", BuildingData.BuildingType.BASIC_STRUCTURE)
		
		# Set the building type in build manager
		build_manager.set_building_type(building_type_enum)
		
		# Start build mode through GameManager
		GameManager.start_build_mode()
		
		print("Started build mode for: ", building_name)

# Add refresh method for external calls
func refresh_display():
	"""Public method to refresh the building display"""
	refresh_building_data()
	create_building_interface()

# Update tooltip to use real data
func _on_show_building_tooltip(building_name: String):
	var tooltip_label = building_tooltip.get_node("BuildingTooltipLabel")
	tooltip_label.text = building_data[building_name].description  # Use real_building_data
	
	# Position tooltip using local coordinates (keep existing positioning code)
	var global_mouse_pos = get_global_mouse_position()
	var local_mouse_pos = global_mouse_pos - global_position
	
	var tooltip_pos = local_mouse_pos + Vector2(15, -15)
	
	var menu_rect = get_rect()
	tooltip_pos.x = clamp(tooltip_pos.x, 10, menu_rect.size.x - building_tooltip.custom_minimum_size.x - 10)
	tooltip_pos.y = clamp(tooltip_pos.y, 10, menu_rect.size.y - 120)
	
	building_tooltip.position = tooltip_pos
	building_tooltip.visible = true

func create_building_interface():
	# Clear existing items
	for child in item_container.get_children():
		child.queue_free()
	
	# Clear panel references
	building_panels.clear()
	
	# Create main building container
	var buildings_container = create_buildings_container()
	item_container.add_child(buildings_container)
	
	# Create tooltip system
	create_building_tooltip_system()
	
	# Create detail view system
	create_building_detail_system()

func create_buildings_container() -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 15)
	
	# Create header
	var header = create_building_header("Building Overview")
	container.add_child(header)
	
	# Create categories
	create_building_categories(container)
	
	return container

func create_building_header(text: String) -> Label:
	var header = Label.new()
	header.text = text
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color("#8B4513"))  # Brown theme
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Construction-themed styling
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color("#F4A460")  # Sandy brown
	stylebox.border_width_top = 3
	stylebox.border_width_bottom = 3
	stylebox.border_color = Color("#8B4513")  # Dark brown
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.content_margin_top = 10
	stylebox.content_margin_bottom = 10
	header.add_theme_stylebox_override("normal", stylebox)
	
	return header


func create_building_section(container: VBoxContainer, section_name: String, buildings: Array, accent_color: Color):
	# Section header
	var section_label = Label.new()
	section_label.text = section_name
	section_label.add_theme_font_size_override("font_size", 18)
	section_label.add_theme_color_override("font_color", accent_color)
	container.add_child(section_label)
	
	# Buildings grid for this section
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	
	for building_name in buildings:
		var building_panel = create_building_panel(building_name, accent_color)
		building_panels[building_name] = building_panel
		grid.add_child(building_panel)
	
	container.add_child(grid)


func create_building_tooltip_system():
	# Create timer
	building_tooltip_timer = Timer.new()
	building_tooltip_timer.wait_time = 1.0
	building_tooltip_timer.one_shot = true
	building_tooltip_timer.timeout.connect(_on_building_tooltip_timer_timeout)
	add_child(building_tooltip_timer)
	
	# Create tooltip
	building_tooltip = PanelContainer.new()
	building_tooltip.visible = false
	building_tooltip.z_index = 100
	
	# Construction-themed tooltip
	var tooltip_style = StyleBoxFlat.new()
	tooltip_style.bg_color = Color("#8B4513")  # Dark brown
	tooltip_style.border_width_left = 2
	tooltip_style.border_width_right = 2
	tooltip_style.border_width_top = 2
	tooltip_style.border_width_bottom = 2
	tooltip_style.border_color = Color("#F4A460")  # Sandy brown
	tooltip_style.corner_radius_top_left = 6
	tooltip_style.corner_radius_top_right = 6
	tooltip_style.corner_radius_bottom_left = 6
	tooltip_style.corner_radius_bottom_right = 6
	tooltip_style.content_margin_left = 12
	tooltip_style.content_margin_right = 12
	tooltip_style.content_margin_top = 10
	tooltip_style.content_margin_bottom = 10
	building_tooltip.add_theme_stylebox_override("panel", tooltip_style)
	
	var tooltip_label = Label.new()
	tooltip_label.name = "BuildingTooltipLabel"
	tooltip_label.add_theme_color_override("font_color", Color.WHITE)
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_label.custom_minimum_size = Vector2(250, 0)
	building_tooltip.add_child(tooltip_label)
	
	add_child(building_tooltip)

func create_building_detail_system():
	building_detail_view = PanelContainer.new()
	building_detail_view.visible = false
	building_detail_view.z_index = 50
	building_detail_view.custom_minimum_size = Vector2(450, 350)
	
	# Center within menu
	building_detail_view.anchor_left = 0.5
	building_detail_view.anchor_top = 0.5
	building_detail_view.anchor_right = 0.5
	building_detail_view.anchor_bottom = 0.5
	building_detail_view.offset_left = -225
	building_detail_view.offset_top = -175
	building_detail_view.offset_right = 225
	building_detail_view.offset_bottom = 175
	
	# Construction-themed detail style
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = Color("#1C1C1C")  # Very dark
	detail_style.border_width_left = 4
	detail_style.border_width_right = 4
	detail_style.border_width_top = 4
	detail_style.border_width_bottom = 4
	detail_style.border_color = Color("#8B4513")  # Brown border
	detail_style.corner_radius_top_left = 12
	detail_style.corner_radius_top_right = 12
	detail_style.corner_radius_bottom_left = 12
	detail_style.corner_radius_bottom_right = 12
	building_detail_view.add_theme_stylebox_override("panel", detail_style)
	
	var detail_vbox = VBoxContainer.new()
	detail_vbox.name = "BuildingDetailContainer"
	building_detail_view.add_child(detail_vbox)
	
	add_child(building_detail_view)


func create_building_actions(building_name: String) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	
	var building = building_data[building_name]
	
	# Upgrade section
	if building.current_level < building.upgrade_levels.size() - 1:
		var upgrade_button = Button.new()
		var next_level = building.upgrade_levels[building.current_level + 1]
		upgrade_button.text = "Upgrade to " + next_level
		upgrade_button.add_theme_color_override("font_color", Color("#90EE90"))
		upgrade_button.pressed.connect(_on_building_upgrade.bind(building_name))
		container.add_child(upgrade_button)
	
	# Crafting section
	if building.can_craft and building.owned > 0:
		var craft_label = Label.new()
		craft_label.text = "Available Crafting Options:"
		craft_label.add_theme_color_override("font_color", Color("#FFD700"))
		container.add_child(craft_label)
		
		for craft_item in building.craft_options:
			var craft_button = Button.new()
			craft_button.text = "Craft " + craft_item
			craft_button.add_theme_color_override("font_color", Color("#DDA0DD"))
			craft_button.pressed.connect(_on_craft_item.bind(building_name, craft_item))
			container.add_child(craft_button)
	
	# Build new button (if not at max capacity)
	var build_button = Button.new()
	build_button.text = "Build New " + building_name
	build_button.add_theme_color_override("font_color", Color("#87CEEB"))
	build_button.pressed.connect(_on_build_new.bind(building_name))
	container.add_child(build_button)
	
	return container

# Event handlers
func _on_building_panel_mouse_entered(building_name: String, panel: PanelContainer):
	current_hovered_building = building_name
	building_tooltip_timer.start()
	
	# Highlight panel
	var stylebox = panel.get_theme_stylebox("panel").duplicate()
	stylebox.border_color = Color("#F4A460")  # Bright sandy brown
	stylebox.bg_color = Color("#3D2814")  # Lighter brown
	panel.add_theme_stylebox_override("panel", stylebox)

func _on_building_panel_mouse_exited(building_name: String):
	current_hovered_building = ""
	building_tooltip_timer.stop()
	building_tooltip.visible = false
	
	# Reset panel highlight
	var panel = building_panels.get(building_name)
	if panel:
		var building = building_data[building_name]
		var accent_color = _get_accent_color_for_type(building.type)
		
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color("#2F1B14")
		stylebox.border_width_left = 2
		stylebox.border_width_right = 2
		stylebox.border_width_top = 2
		stylebox.border_width_bottom = 2
		stylebox.border_color = accent_color
		stylebox.corner_radius_top_left = 6
		stylebox.corner_radius_top_right = 6
		stylebox.corner_radius_bottom_left = 6
		stylebox.corner_radius_bottom_right = 6
		stylebox.content_margin_left = 10
		stylebox.content_margin_right = 10
		stylebox.content_margin_top = 8
		stylebox.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", stylebox)

func _on_building_panel_input(event: InputEvent, building_name: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_building_clicked(building_name)

func _on_building_clicked(building_name: String):
	# Clear existing content
	var detail_container = building_detail_view.get_node("BuildingDetailContainer")
	for child in detail_container.get_children():
		child.queue_free()
	
	# Wait for children to be freed
	await get_tree().process_frame
	
	# Add new content
	var content = create_building_detail_content(building_name)
	detail_container.add_child(content)
	
	# Show detail view
	building_detail_view.visible = true
	building_tooltip.visible = false
	print("Building detail view opened for: ", building_name)  # Debug line

func _on_building_tooltip_timer_timeout():
	if current_hovered_building != "":
		_on_show_building_tooltip(current_hovered_building)


func _on_building_detail_close():
	building_detail_view.visible = false
	print("Building detail view closed", building_detail_view)  # Debug line to confirm function is called

# Action handlers (placeholders for actual game logic)
func _on_building_upgrade(building_name: String):
	print("Upgrading ", building_name)
	# Placeholder - implement actual upgrade logic
	building_data[building_name].current_level += 1
	# Refresh detail view
	_on_building_clicked(building_name)

func _on_craft_item(building_name: String, item_name: String):
	print("Crafting ", item_name, " at ", building_name)
	# Placeholder - implement actual crafting logic


# Utility functions
func _format_coordinates(coords: Array) -> String:
	if coords.is_empty():
		return "None"
	var coord_strings = []
	for coord in coords:
		coord_strings.append("(%d,%d)" % [coord.x, coord.y])
	return ", ".join(coord_strings)

func _get_accent_color_for_type(type: String) -> Color:
	match type:
		"production":
			return Color("#228B22")  # Green
		"crafting":
			return Color("#CD853F")  # Brown
		"utility":
			return Color("#4682B4")  # Blue
		_:
			return Color.WHITE

# Function to update building data (for when connecting real game data)
func update_building_data(new_building_data: Dictionary):
	building_data = new_building_data
	create_building_interface()
