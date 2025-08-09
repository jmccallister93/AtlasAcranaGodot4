# BuildingSelectionMenu.gd
extends BaseMenu
class_name BuildingSelectionMenu

signal building_selected(building_type: BuildingData.BuildingType)
signal menu_closed

# Info panel components (BaseMenu provides title_label, close_button, item_container)
var info_panel: Control
var info_title: Label
var info_description: Label
var info_cost: RichTextLabel
var info_production: RichTextLabel

# Category system
var category_sections: Dictionary = {}  # BuildingCategory -> CategorySection
var category_headers: Dictionary = {}   # BuildingCategory -> Button
var category_containers: Dictionary = {} # BuildingCategory -> GridContainer
var category_expanded: Dictionary = {}   # BuildingCategory -> bool

# Building buttons
var building_buttons: Array[BuildingButton] = []

# Current player resources and target tile
var player_resources: Dictionary = {}
var target_tile: BiomeTile

func ready_post():
	"""Override BaseMenu's ready_post to setup building selection specific UI"""
	menu_title = "Select Building to Construct"
	title_label.text = menu_title
	
	# Convert item_container from GridContainer to VBoxContainer for categories
	setup_category_layout()
	
	# Create the info panel AFTER BaseMenu has set everything up
	create_info_panel()
	
	# Connect BaseMenu's inventory_closed signal to our menu_closed signal
	inventory_closed.connect(func(): menu_closed.emit())
	resize_to_screen()


func setup_category_layout():
	"""Convert the layout to support categories"""
	# Work with the existing GridContainer but configure it for vertical layout
	if item_container:
		item_container.columns = 1  # Single column = vertical layout like VBoxContainer
		item_container.add_theme_constant_override("v_separation", 10)  # Spacing between categories
		print("✅ Configured GridContainer for category layout")
		
func resize_to_screen():
	var screen_size = get_viewport().get_visible_rect().size
	var target_size = screen_size * 0.7  # Slightly larger for categories
	size = target_size
	pivot_offset = size / 2
	
	# Calculate target position (slightly above bottom center)
	target_position = Vector2(
		(screen_size.x - size.x) / 2,  # Center horizontally
		screen_size.y - size.y - 50    # 50 pixels from bottom
	)
	
	# Calculate hidden position (completely off-screen at bottom)
	hidden_position = Vector2(
		target_position.x,
		screen_size.y + 50  # Off-screen below
	)
	
	# Start at hidden position
	position = hidden_position

func create_info_panel():
	"""Create the information panel on the right side"""
	# First, adjust the existing scroll container to make room for info panel
	var scroll_container = item_container.get_parent()
	if scroll_container:
		scroll_container.anchor_right = 0.65  # Take up left 65% instead of full width
		scroll_container.offset_right = -10
	
	info_panel = Control.new()
	info_panel.name = "InfoPanel"
	add_child(info_panel)
	
	# Position info panel on the right side
	info_panel.anchor_left = 0.65
	info_panel.anchor_top = 0.0
	info_panel.anchor_right = 1.0
	info_panel.anchor_bottom = 1.0
	info_panel.offset_left = 10
	info_panel.offset_top = 60  # Below title
	info_panel.offset_right = -10
	info_panel.offset_bottom = -10
	
	# Background for info panel
	var info_background = Panel.new()
	info_background.anchor_left = 0.0
	info_background.anchor_top = 0.0
	info_background.anchor_right = 1.0
	info_background.anchor_bottom = 1.0
	
	var info_style = StyleBoxFlat.new()
	info_style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	info_style.border_color = Color(0.4, 0.4, 0.4)
	info_style.border_width_left = 2
	info_style.border_width_right = 2
	info_style.border_width_top = 2
	info_style.border_width_bottom = 2
	info_style.corner_radius_top_left = 8
	info_style.corner_radius_top_right = 8
	info_style.corner_radius_bottom_left = 8
	info_style.corner_radius_bottom_right = 8
	info_background.add_theme_stylebox_override("panel", info_style)
	
	info_panel.add_child(info_background)
	info_panel.move_child(info_background, 0)  # Send to back
	
	# Info components with dynamic sizing
	info_title = Label.new()
	info_title.add_theme_font_size_override("font_size", 16)
	info_title.add_theme_color_override("font_color", Color.WHITE)
	info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_title.anchor_left = 0.0
	info_title.anchor_top = 0.0
	info_title.anchor_right = 1.0
	info_title.anchor_bottom = 0.0
	info_title.offset_left = 10
	info_title.offset_top = 10
	info_title.offset_right = -10
	info_title.offset_bottom = 35
	info_panel.add_child(info_title)
	
	info_description = Label.new()
	info_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_description.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	info_description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	info_description.anchor_left = 0.0
	info_description.anchor_top = 0.0
	info_description.anchor_right = 1.0
	info_description.anchor_bottom = 0.0
	info_description.offset_left = 10
	info_description.offset_top = 55
	info_description.offset_right = -10
	info_description.offset_bottom = 55
	info_panel.add_child(info_description)
	
	info_cost = RichTextLabel.new()
	info_cost.bbcode_enabled = true
	info_cost.fit_content = true
	info_cost.anchor_left = 0.0
	info_cost.anchor_top = 0.0
	info_cost.anchor_right = 1.0
	info_cost.anchor_bottom = 0.0
	info_cost.offset_left = 10
	info_cost.offset_top = 155
	info_cost.offset_right = -10
	info_cost.offset_bottom = 75
	info_panel.add_child(info_cost)
	
	info_production = RichTextLabel.new()
	info_production.bbcode_enabled = true
	info_production.fit_content = true
	info_production.anchor_left = 0.0
	info_production.anchor_top = 0.0
	info_production.anchor_right = 1.0
	info_production.anchor_bottom = 1.0
	info_production.offset_left = 10
	info_production.offset_top = 265
	info_production.offset_right = -10
	info_production.offset_bottom = -10
	info_panel.add_child(info_production)

func show_menu_with_data(tile: BiomeTile, resources: Dictionary):
	"""Show the building selection menu with building data"""
	target_tile = tile
	player_resources = resources
	
	create_category_sections()
	show_menu()  # Call BaseMenu's show_menu()

# ============================================================================
# CATEGORY SYSTEM
# ============================================================================

func create_category_sections():
	"""Create collapsible sections for each building category"""
	cleanup_categories()
	
	var building_definitions = BuildingData.get_building_definitions()
	
	print("=== BUILDING CATEGORY MENU DEBUG ===")
	print("Creating category sections for biome: ", target_tile.biome_type)
	print("Player resources: ", player_resources)
	
	# Group buildings by category
	var buildings_by_category = group_buildings_by_category(building_definitions)
	
	# Create sections for categories that have buildings
	for category in BuildingData.BuildingCategory.values():
		if category in buildings_by_category and buildings_by_category[category].size() > 0:
			create_category_section(category, buildings_by_category[category])
	
	print("Created %d category sections" % category_sections.size())
	print("===================================")

func group_buildings_by_category(building_definitions: Dictionary) -> Dictionary:
	"""Group buildings by their category"""
	var buildings_by_category = {}
	
	# Initialize all categories
	for category in BuildingData.BuildingCategory.values():
		buildings_by_category[category] = []
	
	# Group buildings
	for building_type in BuildingData.BuildingType.values():
		if building_type in building_definitions:
			var building_data = building_definitions[building_type]
			
			# Check if building can be built on this biome (optional filtering)
			var can_build = BuildingData.can_build_on_biome(building_type, target_tile.biome_type)
			# SHOW ALL BUILDINGS FOR NOW (uncomment next line to enable biome restriction)
			# if not can_build: continue
			
			var category = building_data.get("category", BuildingData.BuildingCategory.INFRASTRUCTURE)
			buildings_by_category[category].append({
				"type": building_type,
				"data": building_data
			})
	
	return buildings_by_category

func create_category_section(category: BuildingData.BuildingCategory, buildings: Array):
	"""Create a collapsible section for a building category"""
	# Create category header button
	var header_button = create_category_header(category)
	item_container.add_child(header_button)
	
	# Create buildings container (initially hidden)
	var buildings_container = create_buildings_container_for_category(category, buildings)
	item_container.add_child(buildings_container)
	
	# Store references
	category_headers[category] = header_button
	category_containers[category] = buildings_container
	category_expanded[category] = false  # Start collapsed
	
	# Set initial visibility
	buildings_container.visible = false
	
	print("Created category section: %s with %d buildings" % [get_category_name(category), buildings.size()])

func create_category_header(category: BuildingData.BuildingCategory) -> Button:
	"""Create a header button for a category"""
	var header = Button.new()
	header.text = "▶ " + get_category_name(category)
	header.custom_minimum_size = Vector2(0, 40)
	header.add_theme_font_size_override("font_size", 14)
	
	# Style the header button
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = get_category_color(category)
	header_style.border_color = Color.WHITE
	header_style.border_width_top = 1
	header_style.border_width_bottom = 1
	header_style.corner_radius_top_left = 5
	header_style.corner_radius_top_right = 5
	header_style.corner_radius_bottom_left = 5
	header_style.corner_radius_bottom_right = 5
	header_style.content_margin_left = 15
	header_style.content_margin_right = 15
	header_style.content_margin_top = 8
	header_style.content_margin_bottom = 8
	
	header.add_theme_stylebox_override("normal", header_style)
	header.add_theme_stylebox_override("hover", header_style)
	header.add_theme_stylebox_override("pressed", header_style)
	header.add_theme_color_override("font_color", Color.WHITE)
	
	# Connect toggle signal
	header.pressed.connect(_on_category_header_pressed.bind(category))
	
	return header

func create_buildings_container_for_category(category: BuildingData.BuildingCategory, buildings: Array) -> GridContainer:
	"""Create a container with buildings for a specific category"""
	var container = GridContainer.new()
	container.columns = 2  # 2 buildings per row within category
	container.add_theme_constant_override("h_separation", 10)
	container.add_theme_constant_override("v_separation", 8)
	
	# Add padding directly to the GridContainer
	container.add_theme_constant_override("margin_left", 20)
	container.add_theme_constant_override("margin_right", 20)
	container.add_theme_constant_override("margin_top", 5)
	container.add_theme_constant_override("margin_bottom", 10)
	
	# Create building buttons
	for building_info in buildings:
		var building_type = building_info.type
		var building_data = building_info.data
		
		var button = create_building_button(building_type, building_data)
		if button:
			building_buttons.append(button)
			container.add_child(button)
	
	return container
func get_category_name(category: BuildingData.BuildingCategory) -> String:
	"""Get display name for a category"""
	match category:
		BuildingData.BuildingCategory.RESOURCE_PRODUCTION:
			return "Resource Production"
		BuildingData.BuildingCategory.UTILITY:
			return "Utility Buildings"
		BuildingData.BuildingCategory.WARBAND:
			return "Military & Warband"
		BuildingData.BuildingCategory.INFRASTRUCTURE:
			return "Infrastructure"
		BuildingData.BuildingCategory.DEFENSE:
			return "Defensive Structures"
		_:
			return "Other"

func get_category_color(category: BuildingData.BuildingCategory) -> Color:
	"""Get color theme for a category"""
	match category:
		BuildingData.BuildingCategory.RESOURCE_PRODUCTION:
			return Color(0.2, 0.7, 0.2)  # Green
		BuildingData.BuildingCategory.UTILITY:
			return Color(0.4, 0.6, 0.8)  # Blue
		BuildingData.BuildingCategory.WARBAND:
			return Color(0.8, 0.2, 0.2)  # Red
		BuildingData.BuildingCategory.INFRASTRUCTURE:
			return Color(0.6, 0.4, 0.8)  # Purple
		BuildingData.BuildingCategory.DEFENSE:
			return Color(0.6, 0.6, 0.6)  # Gray
		_:
			return Color(0.5, 0.5, 0.5)  # Default gray

func _on_category_header_pressed(category: BuildingData.BuildingCategory):
	"""Handle category header button press"""
	var is_expanded = category_expanded.get(category, false)
	var container = category_containers.get(category)
	var header = category_headers.get(category)
	
	if container and header:
		# Toggle visibility
		is_expanded = !is_expanded
		category_expanded[category] = is_expanded
		container.visible = is_expanded
		
		# Update header text
		var category_name = get_category_name(category)
		if is_expanded:
			header.text = "▼ " + category_name
		else:
			header.text = "▶ " + category_name
		
		print("Toggled category %s: %s" % [category_name, "expanded" if is_expanded else "collapsed"])

# ============================================================================
# BUILDING BUTTON MANAGEMENT
# ============================================================================

func create_building_button(building_type: BuildingData.BuildingType, building_data: Dictionary) -> BuildingButton:
	"""Create a single building button"""
	var button = BuildingButton.new()
	
	# Initialize the button
	button.initialize(building_type, building_data, target_tile)
	
	# Check affordability
	var can_afford = check_affordability(building_data.get("cost", {}))
	button.set_affordable(can_afford)
	
	# Connect signals
	button.building_selected.connect(_on_building_selected)
	button.building_hovered.connect(_on_building_hovered)
	
	return button

func check_affordability(cost: Dictionary) -> bool:
	"""Check if player can afford the building"""
	for resource in cost:
		var required = cost[resource]
		var available = player_resources.get(resource, 0)
		if available < required:
			return false
	return true

func _on_building_selected(building_type: BuildingData.BuildingType):
	"""Handle building selection"""
	print("Building selected from menu: ", building_type)
	building_selected.emit(building_type)
	hide_menu()  # Use BaseMenu's hide_menu()

func _on_building_hovered(building_type: BuildingData.BuildingType):
	"""Handle building button hover"""
	update_info_panel(building_type)

func update_info_panel(building_type: BuildingData.BuildingType):
	"""Update the information panel with building details"""
	var building_data = BuildingData.get_building_data(building_type)
	
	# Title
	info_title.text = building_data.get("name")
	
	# Description
	info_description.text = building_data.get("description", "No description available.")
	
	# Cost
	var cost_text = "[b]Cost:[/b]\n"
	var cost = building_data.get("cost", {})
	if cost.is_empty():
		cost_text += "[color=gray]Free[/color]"
	else:
		for resource in cost:
			var required = cost[resource]
			var available = player_resources.get(resource, 0)
			var color_code = "red" if available < required else "white"
			cost_text += "[color=%s]%s: %d/%d[/color]\n" % [color_code, resource.capitalize(), required, available]
	info_cost.text = cost_text
	
	# Production
	var production_text = "[b]Production:[/b]\n"
	var total_production = BuildingData.get_total_production(building_type, target_tile.biome_type)
	
	if total_production.is_empty():
		production_text += "[color=gray]None[/color]"
	else:
		for resource in total_production:
			var amount = total_production[resource]
			production_text += "[color=green]%s: +%d per turn[/color]\n" % [resource.capitalize(), amount]
		
		# Show biome bonus if applicable
		var base_production = building_data.get("base_production", {})
		var has_bonus = false
		for resource in total_production:
			var base_amount = base_production.get(resource, 0)
			if total_production[resource] > base_amount:
				has_bonus = true
				break
		
		if has_bonus:
			production_text += "\n[color=yellow]Biome bonus: +5[/color]"
	
	info_production.text = production_text

# ============================================================================
# CLEANUP AND UTILITIES
# ============================================================================

func cleanup_categories():
	"""Clean up all category sections"""
	# Clear category data
	category_sections.clear()
	category_headers.clear()
	category_containers.clear()
	category_expanded.clear()
	
	# Clean up buttons
	cleanup_buttons()
	
	# Clear item container children
	for child in item_container.get_children():
		child.queue_free()

func cleanup_buttons():
	"""Clean up building buttons"""
	for button in building_buttons:
		if button and is_instance_valid(button):
			button.queue_free()
	building_buttons.clear()

# Override BaseMenu's hide_menu to add cleanup
func hide_menu():
	super.hide_menu()  # Call BaseMenu's hide_menu()
	cleanup_categories()

# ============================================================================
# UTILITY METHODS FOR CATEGORIES
# ============================================================================

func expand_all_categories():
	"""Expand all category sections"""
	for category in category_expanded.keys():
		if not category_expanded[category]:
			_on_category_header_pressed(category)

func collapse_all_categories():
	"""Collapse all category sections"""
	for category in category_expanded.keys():
		if category_expanded[category]:
			_on_category_header_pressed(category)

func expand_category(category: BuildingData.BuildingCategory):
	"""Expand a specific category"""
	if category in category_expanded and not category_expanded[category]:
		_on_category_header_pressed(category)

func get_buildings_in_category(category: BuildingData.BuildingCategory) -> Array:
	"""Get all building types in a specific category"""
	var buildings_in_category = []
	var building_definitions = BuildingData.get_building_definitions()
	
	for building_type in BuildingData.BuildingType.values():
		if building_type in building_definitions:
			var building_data = building_definitions[building_type]
			var building_category = building_data.get("category", BuildingData.BuildingCategory.INFRASTRUCTURE)
			if building_category == category:
				buildings_in_category.append(building_type)
	
	return buildings_in_category
