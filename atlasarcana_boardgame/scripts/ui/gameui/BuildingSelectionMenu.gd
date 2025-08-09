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

# Building buttons
var building_buttons: Array[BuildingButton] = []

# Current player resources and target tile
var player_resources: Dictionary = {}
var target_tile: BiomeTile

func ready_post():
	"""Override BaseMenu's ready_post to setup building selection specific UI"""
	menu_title = "Select Building to Construct"
	title_label.text = menu_title
	
	# Customize the grid for building buttons
	item_container.columns = 3  # 3 buildings per row
	
	# Create the info panel AFTER BaseMenu has set everything up
	create_info_panel()
	
	# Connect BaseMenu's inventory_closed signal to our menu_closed signal
	inventory_closed.connect(func(): menu_closed.emit())
	resize_to_screen()

func resize_to_screen():
	var screen_size = get_viewport().get_visible_rect().size
	var target_size = screen_size * 0.6
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
	info_description.offset_top = 45
	info_description.offset_right = -10
	info_description.offset_bottom = 145
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
	info_cost.offset_bottom = 255
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
	
	create_building_buttons()
	show_menu()  # Call BaseMenu's show_menu()

func create_building_buttons():
	"""Create buttons for all available buildings"""
	# Clear existing buttons
	cleanup_buttons()
	
	var building_definitions = BuildingData.get_building_definitions()
	
	print("=== BUILDING MENU DEBUG ===")
	print("Creating building buttons for biome: ", target_tile.biome_type)
	print("Player resources: ", player_resources)
	
	var buttons_created = 0
	
	# Create buttons for building types
	for building_type in BuildingData.BuildingType.values():
		if building_type in building_definitions:
			var building_data = building_definitions[building_type]
			
			# Check if building can be built on this biome
			var can_build = BuildingData.can_build_on_biome(building_type, target_tile.biome_type)
			
			# SHOW ALL BUILDINGS FOR NOW (comment out to enable biome restriction)
			# if not can_build:
			#     continue
			
			var button = create_building_button(building_type, building_data)
			if button:
				building_buttons.append(button)
				item_container.add_child(button)  # Use BaseMenu's item_container
				buttons_created += 1
				print("✅ Created button %d for: %s" % [buttons_created, building_data.get("name", "Unknown")])
	
	print("Total buttons created: ", buttons_created)
	print("=========================")
	
	# Show info for first building if any exist
	if building_buttons.size() > 0:
		var first_building_type = building_buttons[0].building_type
		update_info_panel(first_building_type)

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
	info_title.text = building_data.get("name", "Unknown")
	
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
			production_text += "\n[color=yellow]✨ Biome bonus active![/color]"
	
	info_production.text = production_text

func cleanup_buttons():
	"""Clean up building buttons"""
	for button in building_buttons:
		if button and is_instance_valid(button):
			button.queue_free()
	building_buttons.clear()
	
	# Clear item container children (BaseMenu's grid container)
	for child in item_container.get_children():
		child.queue_free()

# Override BaseMenu's hide_menu to add cleanup
func hide_menu():
	super.hide_menu()  # Call BaseMenu's hide_menu()
	cleanup_buttons()
