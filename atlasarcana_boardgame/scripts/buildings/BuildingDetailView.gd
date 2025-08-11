# BuildingDetailView.gd - Updated to use BaseMenu approach
extends BaseMenu
class_name BuildingDetailView

signal detail_view_closed

# Data
var current_building: Building
var available_buildings: Array[Building] = []
var building_type_name: String = ""
var build_manager: BuildManager

# UI Components (created fresh each time)
var building_selection_container: VBoxContainer  # Temporary reference
var building_info_container: VBoxContainer  # Temporary reference

# States
enum ViewState {
	BUILDING_SELECTION,  # Choosing which building of this type
	BUILDING_DETAILS     # Viewing specific building details
}
var current_state: ViewState = ViewState.BUILDING_DETAILS

func ready_post():
	"""Override BaseMenu's ready_post to setup building detail specific UI"""
	menu_title = "Building Details"
	title_label.text = menu_title
	
	connect_to_build_manager()
	
	# Connect BaseMenu's inventory_closed signal to our detail_view_closed signal
	inventory_closed.connect(func(): detail_view_closed.emit())

func connect_to_build_manager():
	"""Connect to BuildManager for building data"""
	if GameManager and GameManager.build_manager:
		build_manager = GameManager.build_manager
		print("✅ BuildingDetailView connected to BuildManager")

func show_for_building(building: Building):
	"""Show detail view for a specific building"""
	if not building or not is_instance_valid(building):
		print("Invalid building provided to BuildingDetailView")
		return
	
	current_building = building
	building_type_name = building.get_building_name()
	current_state = ViewState.BUILDING_DETAILS
	
	print("Showing building detail for: ", building_type_name)
	
	create_building_details_ui()
	show_menu()  # Use BaseMenu's show_menu() method

func show_for_building_type(type_name: String):
	"""Show detail view for a building type (may show selection first)"""
	if not build_manager:
		print("No BuildManager available")
		return
	
	building_type_name = type_name
	available_buildings = build_manager.get_buildings_of_type(type_name)
	
	print("Showing detail for building type: ", type_name)
	print("Found buildings: ", available_buildings.size())
	
	if available_buildings.size() == 0:
		print("No buildings of type ", type_name, " found")
		return
	elif available_buildings.size() == 1:
		# Only one building, go directly to details
		show_for_building(available_buildings[0])
	else:
		# Multiple buildings, show selection first
		current_state = ViewState.BUILDING_SELECTION
		create_building_selection_ui()
		show_menu()  # Use BaseMenu's show_menu() method

func create_building_selection_ui():
	"""Create UI for selecting which building to view when multiple exist"""
	clear_item_container()
	
	# Update title
	title_label.text = "Select " + building_type_name
	
	# Create fresh selection container each time
	building_selection_container = VBoxContainer.new()
	building_selection_container.name = "BuildingSelection"
	building_selection_container.add_theme_constant_override("separation", 10)
	
	# Add selection container to the BaseMenu's item_container
	item_container.add_child(building_selection_container)
	
	# Instructions
	var instruction_label = Label.new()
	instruction_label.text = "You have %d %s buildings. Select one to view details:" % [available_buildings.size(), building_type_name]
	instruction_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	building_selection_container.add_child(instruction_label)
	
	# Building selection grid
	var selection_grid = GridContainer.new()
	selection_grid.columns = 2
	selection_grid.add_theme_constant_override("h_separation", 15)
	selection_grid.add_theme_constant_override("v_separation", 10)
	
	for i in range(available_buildings.size()):
		var building = available_buildings[i]
		var selection_button = create_building_selection_button(building, i + 1)
		selection_grid.add_child(selection_button)
	
	building_selection_container.add_child(selection_grid)

func create_building_selection_button(building: Building, number: int) -> Button:
	"""Create a button for selecting a specific building"""
	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 80)
	
	# Get building info
	var tile_pos = building.tile_position
	var biome = building.tile.biome_type if building.tile else "unknown"
	var production = building.get_production()
	
	# Create button text
	var button_text = "%s #%d\n" % [building_type_name, number]
	button_text += "Location: (%d, %d)\n" % [tile_pos.x, tile_pos.y]
	button_text += "Biome: %s" % str(biome).capitalize()
	
	if not production.is_empty():
		button_text += "\nProducing: "
		var production_parts = []
		for resource in production:
			production_parts.append("%d %s" % [production[resource], resource])
		button_text += ", ".join(production_parts)
	
	button.text = button_text
	button.add_theme_font_size_override("font_size", 11)
	
	# Style the button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.2, 0.3)
	button_style.border_color = Color(0.4, 0.6, 0.8)
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_width_top = 2
	button_style.border_width_bottom = 2
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	button_style.content_margin_left = 10
	button_style.content_margin_right = 10
	button_style.content_margin_top = 10
	button_style.content_margin_bottom = 10
	
	button.add_theme_stylebox_override("normal", button_style)
	button.add_theme_stylebox_override("hover", button_style)
	button.add_theme_stylebox_override("pressed", button_style)
	
	# Connect to selection
	button.pressed.connect(_on_building_selected.bind(building))
	
	return button

func create_building_details_ui():
	"""Create UI showing details for the selected building"""
	clear_item_container()
	
	# Update title
	if current_building:
		title_label.text = current_building.get_building_name() + " Details"
	
	# Create fresh info container each time
	building_info_container = VBoxContainer.new()
	building_info_container.name = "BuildingInfo"
	building_info_container.add_theme_constant_override("separation", 12)
	
	# Add info container to the BaseMenu's item_container
	item_container.add_child(building_info_container)
	
	if not current_building or not is_instance_valid(current_building):
		var error_label = Label.new()
		error_label.text = "Building no longer exists"
		error_label.add_theme_color_override("font_color", Color.RED)
		building_info_container.add_child(error_label)
		return
	
	# Building information panel
	var info_panel = create_building_info_panel()
	building_info_container.add_child(info_panel)
	
	# Actions section (placeholder for future building-specific actions)
	var actions_panel = create_actions_panel()
	building_info_container.add_child(actions_panel)

func create_building_info_panel() -> Control:
	"""Create detailed information panel for the current building"""
	var panel = PanelContainer.new()
	
	# Style the info panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.15)
	panel_style.border_color = Color(0.3, 0.3, 0.3)
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 15
	panel_style.content_margin_right = 15
	panel_style.content_margin_top = 15
	panel_style.content_margin_bottom = 15
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Content container
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	
	# Basic information
	var basic_info = create_basic_info_section()
	content.add_child(basic_info)
	
	# Production information
	if not current_building.get_production().is_empty():
		var production_info = create_production_info_section()
		content.add_child(production_info)
	
	# Location and biome information
	var location_info = create_location_info_section()
	content.add_child(location_info)
	
	# Status information
	var status_info = create_status_info_section()
	content.add_child(status_info)
	
	panel.add_child(content)
	return panel

func create_basic_info_section() -> VBoxContainer:
	"""Create basic building information section"""
	var section = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "Building Information"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	section.add_child(title)
	
	var building_info = current_building.get_building_info()
	var description = building_info.get("description", "No description available.")
	
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section.add_child(desc_label)
	
	return section

func create_production_info_section() -> VBoxContainer:
	"""Create production information section"""
	var section = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "Production"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	section.add_child(title)
	
	var production = current_building.get_production()
	var base_production = current_building.get_base_production()
	var biome_bonus = current_building.get_biome_bonus()
	
	for resource in production:
		var amount = production[resource]
		var base_amount = base_production.get(resource, 0)
		var bonus_amount = biome_bonus.get(resource, 0)
		
		var prod_label = Label.new()
		if bonus_amount > 0:
			prod_label.text = "%s: %d per turn (%d base + %d biome bonus)" % [resource.capitalize(), amount, base_amount, bonus_amount]
			prod_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			prod_label.text = "%s: %d per turn" % [resource.capitalize(), amount]
			prod_label.add_theme_color_override("font_color", Color.WHITE)
		
		section.add_child(prod_label)
	
	return section

func create_location_info_section() -> VBoxContainer:
	"""Create location and biome information section"""
	var section = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "Location"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.6))
	section.add_child(title)
	
	var pos_label = Label.new()
	pos_label.text = "Grid Position: (%d, %d)" % [current_building.tile_position.x, current_building.tile_position.y]
	pos_label.add_theme_color_override("font_color", Color.WHITE)
	section.add_child(pos_label)
	
	if current_building.tile:
		var biome_label = Label.new()
		biome_label.text = "Biome: %s" % str(current_building.tile.biome_type).capitalize()
		biome_label.add_theme_color_override("font_color", Color.WHITE)
		section.add_child(biome_label)
	
	return section

func create_status_info_section() -> VBoxContainer:
	"""Create status information section"""
	var section = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "Status"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.8))
	section.add_child(title)
	
	var health_label = Label.new()
	health_label.text = "Health: %d / %d" % [current_building.health, current_building.max_health]
	var health_color = Color.GREEN if current_building.health == current_building.max_health else Color.YELLOW
	if current_building.health < current_building.max_health * 0.3:
		health_color = Color.RED
	health_label.add_theme_color_override("font_color", health_color)
	section.add_child(health_label)
	
	var active_label = Label.new()
	active_label.text = "Status: " + ("Active" if current_building.is_active else "Inactive")
	active_label.add_theme_color_override("font_color", Color.GREEN if current_building.is_active else Color.RED)
	section.add_child(active_label)
	
	return section

func create_actions_panel() -> VBoxContainer:
	"""Create actions panel (placeholder for future building-specific actions)"""
	var panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 8)
	
	var title = Label.new()
	title.text = "Actions"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	panel.add_child(title)
	
	# Placeholder for future actions
	var placeholder = Label.new()
	placeholder.text = "Building-specific actions will be added here..."
	placeholder.add_theme_color_override("font_color", Color.GRAY)
	#placeholder.add_theme_font_style_override("font_style", TextServer.FONT_ITALIC)
	panel.add_child(placeholder)
	
	# Utility building actions
	if current_building.is_utility_building():
		var utility_button = Button.new()
		utility_button.text = "Open " + current_building.get_utility_type().capitalize() + " Menu"
		utility_button.custom_minimum_size = Vector2(200, 35)
		utility_button.pressed.connect(_on_utility_action_pressed)
		panel.add_child(utility_button)
	
	return panel

func clear_item_container():
	"""Clear the BaseMenu's item container"""
	for child in item_container.get_children():
		child.queue_free()

# Event Handlers
func _on_building_selected(building: Building):
	"""Handle selection of a specific building from the selection screen"""
	current_building = building
	current_state = ViewState.BUILDING_DETAILS
	create_building_details_ui()

func _on_utility_action_pressed():
	"""Handle utility building action"""
	if current_building and current_building.is_utility_building():
		current_building.open_utility_menu()

# Public interface for external components
func is_showing() -> bool:
	"""Check if the detail view is currently showing"""
	return visible

func get_current_building() -> Building:
	"""Get the currently viewed building"""
	return current_building

# Override BaseMenu's hide_menu to emit our specific signal
func hide_menu():
	super.hide_menu()  # Call BaseMenu's hide_menu()
	detail_view_closed.emit()

# Handle input to close with Escape key
func _input(event):
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		hide_menu()
		get_viewport().set_input_as_handled()
