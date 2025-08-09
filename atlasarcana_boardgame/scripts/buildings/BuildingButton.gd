# BuildingButton.gd
extends Control
class_name BuildingButton

signal building_selected(building_type: BuildingData.BuildingType)
signal building_hovered(building_type: BuildingData.BuildingType)

var building_type: BuildingData.BuildingType
var building_data: Dictionary
var target_tile: BiomeTile
var is_affordable: bool = true

var background: ColorRect
var icon: ColorRect
var name_label: Label
var cost_label: Label
var button_area: Button

func _ready():
	create_components()
	# If we have building data waiting, set it up
	if building_data:
		setup_button()

func initialize(type: BuildingData.BuildingType, data: Dictionary, tile: BiomeTile):
	"""Initialize the building button"""
	building_type = type
	building_data = data
	target_tile = tile
	
	print("Initializing BuildingButton with type: ", type)
	print("Building data: ", data.get("name", "Unknown"))
	
	# Setup button immediately if components are ready
	if background != null:
		setup_button()
	else:
		print("Components not ready, will setup in _ready()")

func create_components():
	"""Create button components"""
	size = Vector2(110, 90)
	custom_minimum_size = Vector2(110, 90)
	
	# Background
	background = ColorRect.new()
	background.size = size
	background.position = Vector2.ZERO
	add_child(background)
	
	# Icon (colored square for now)
	icon = ColorRect.new()
	icon.size = Vector2(40, 40)
	icon.position = Vector2(35, 10)
	add_child(icon)
	
	# Name label
	name_label = Label.new()
	name_label.position = Vector2(5, 55)
	name_label.size = Vector2(100, 15)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	add_child(name_label)
	
	# Cost label
	cost_label = Label.new()
	cost_label.position = Vector2(5, 70)
	cost_label.size = Vector2(100, 15)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 8)
	add_child(cost_label)
	
	# Invisible button for clicking
	button_area = Button.new()
	button_area.size = size
	button_area.position = Vector2.ZERO
	button_area.flat = true
	button_area.pressed.connect(_on_button_pressed)
	button_area.mouse_entered.connect(_on_mouse_entered)
	add_child(button_area)
	
	print("BuildingButton components created with size: ", size)

func setup_button():
	"""Setup button with building data"""
	if not building_data or not background:
		print("Cannot setup button - missing data or components")
		return
	
	print("Setting up button for: ", building_data.get("name", "Unknown"))
	
	# Set icon color based on building type
	var sprite_color = building_data.get("sprite_color", Color.PURPLE)
	icon.color = sprite_color
	print("Set icon color to: ", sprite_color)
	
	# Set name
	name_label.text = building_data.get("name", "Unknown")
	print("Set name to: ", name_label.text)
	
	# Set cost with better formatting
	var cost = building_data.get("cost", {})
	var cost_text = ""
	var cost_parts = []
	for resource in cost:
		cost_parts.append("%d %s" % [cost[resource], resource.capitalize()])
	
	# Format cost text to fit in button
	if cost_parts.size() == 1:
		cost_label.text = cost_parts[0]
	elif cost_parts.size() == 2:
		cost_label.text = cost_parts[0] + "\n" + cost_parts[1]
	else:
		cost_label.text = cost_parts[0] + "\n" + cost_parts[1] + "..."
	
	print("Set cost text to: ", cost_label.text)
	
	# Make sure icon is visible
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_affordable(affordable: bool):
	"""Set whether the building is affordable"""
	is_affordable = affordable
	
	# Safety check - make sure components exist
	if not background or not button_area:
		print("Cannot set affordability - missing components")
		return
	
	if affordable:
		# Use a subtle background that doesn't interfere with icon color
		background.color = Color(0.2, 0.2, 0.2, 1.0)
		modulate = Color.WHITE
		button_area.disabled = false
		
		# Add a subtle border that matches the building type
		var border_color = building_data.get("sprite_color", Color.PURPLE) * 0.7
		add_colored_border(border_color)
	else:
		# Red tint for unaffordable buildings
		background.color = Color(0.4, 0.1, 0.1, 1.0)
		modulate = Color(0.6, 0.6, 0.6, 1.0)
		button_area.disabled = true
		
		# Red border for unaffordable
		add_colored_border(Color.RED)

func add_colored_border(border_color: Color):
	"""Add a colored border to the button"""
	# Remove existing border if any
	remove_existing_border()
	
	# Create border using ColorRect
	var border = ColorRect.new()
	border.name = "Border"
	border.color = border_color
	border.size = size + Vector2(4, 4)  # 2px border on each side
	border.position = Vector2(-2, -2)
	border.z_index = -1  # Behind other elements
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)

func remove_existing_border():
	"""Remove existing border if present"""
	var existing_border = get_node_or_null("Border")
	if existing_border:
		existing_border.queue_free()

func _on_button_pressed():
	"""Handle button press"""
	if is_affordable:
		print("BuildingButton pressed for type: ", building_type)
		building_selected.emit(building_type)

func _on_mouse_entered():
	"""Handle mouse hover"""
	building_hovered.emit(building_type)
