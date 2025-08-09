# TopBarUI.gd
extends Control
class_name TopBarUI

# UI Components
var background_panel: Panel
var turn_section: HBoxContainer
var turn_label: Label
var turn_subtext: Label
var resources_section: HBoxContainer
var character_section: VBoxContainer
var character_name_label: Label
var character_stats_container: HBoxContainer
var character_level_label: Label
var character_hp_label: Label
var action_points_label: Label

# Resource labels
var resource_labels: Dictionary = {}

func _ready():
	create_ui_components()
	connect_signals()

func create_ui_components():
	"""Create all top bar UI components"""
	# Background panel
	background_panel = Panel.new()
	background_panel.name = "TopBarBackground"
	add_child(background_panel)
	
	# Style the background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_color = Color(0.3, 0.3, 0.3)
	style.border_width_bottom = 2
	background_panel.add_theme_stylebox_override("panel", style)
	
	create_turn_section()
	create_resources_section()
	create_character_section()

func create_turn_section():
	"""Create turn information section"""
	turn_section = HBoxContainer.new()
	turn_section.name = "TurnSection"
	background_panel.add_child(turn_section)
	
	turn_label = Label.new()
	turn_label.text = "Turn: "
	turn_label.add_theme_font_size_override("font_size", 16)
	turn_label.add_theme_color_override("font_color", Color.WHITE)
	turn_section.add_child(turn_label)
	
	turn_subtext = Label.new()
	turn_subtext.text = "1"
	turn_subtext.add_theme_font_size_override("font_size", 16)
	turn_subtext.add_theme_color_override("font_color", Color.YELLOW)
	turn_section.add_child(turn_subtext)

func create_resources_section():
	"""Create resources display section"""
	resources_section = HBoxContainer.new()
	resources_section.name = "ResourcesSection"
	resources_section.alignment = BoxContainer.ALIGNMENT_CENTER
	background_panel.add_child(resources_section)
	
	# Create resource displays
	var resources = ["Essence", "Gold", "Food", "Wood", "Stone"]
	var colors = [Color.PURPLE, Color.YELLOW, Color.GREEN, Color(0.6, 0.4, 0.2), Color.GRAY]
	
	for i in range(resources.size()):
		var resource_container = create_resource_display(resources[i], colors[i])
		resources_section.add_child(resource_container)
		
		if i < resources.size() - 1:
			# Add spacer between resources
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(20, 1)
			resources_section.add_child(spacer)

func create_resource_display(resource_name: String, color: Color) -> HBoxContainer:
	"""Create a single resource display"""
	var container = HBoxContainer.new()
	container.name = resource_name + "Container"
	
	# Resource icon (simple colored rect for now)
	var icon = ColorRect.new()
	icon.color = color
	icon.custom_minimum_size = Vector2(16, 16)
	container.add_child(icon)
	
	# Resource label
	var label = Label.new()
	label.text = resource_name + ": 0"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(label)
	
	# Store reference for updating
	resource_labels[resource_name.to_lower()] = label
	
	return container

func update_resource(resource_name: String, amount: int):
	"""Update the display of a specific resource"""
	if resource_name in resource_labels:
		var label = resource_labels[resource_name]
		label.text = "%s: %d" % [resource_name.capitalize(), amount]
		
		# Optional: Add visual feedback for resource changes
		create_resource_change_animation(label)

func create_resource_change_animation(label: Label):
	"""Create a brief animation when resources change"""
	var original_scale = label.scale
	var tween = create_tween()
	tween.tween_property(label, "scale", original_scale * 1.2, 0.1)
	tween.tween_property(label, "scale", original_scale, 0.1)

func update_all_resources(resources: Dictionary):
	"""Update all resource displays"""
	for resource_name in resources:
		update_resource(resource_name, resources[resource_name])

func create_character_section():
	"""Create character information section"""
	character_section = VBoxContainer.new()
	character_section.name = "CharacterSection"
	background_panel.add_child(character_section)
	
	# Character name
	character_name_label = Label.new()
	character_name_label.text = "Hero"
	character_name_label.add_theme_font_size_override("font_size", 16)
	character_name_label.add_theme_color_override("font_color", Color.CYAN)
	character_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	character_section.add_child(character_name_label)
	
	# Character stats container
	character_stats_container = HBoxContainer.new()
	character_stats_container.alignment = BoxContainer.ALIGNMENT_END
	character_section.add_child(character_stats_container)
	
	# Level
	character_level_label = Label.new()
	character_level_label.text = "Lvl: 1"
	character_level_label.add_theme_font_size_override("font_size", 12)
	character_level_label.add_theme_color_override("font_color", Color.WHITE)
	character_stats_container.add_child(character_level_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(15, 1)
	character_stats_container.add_child(spacer)
	
	# HP
	character_hp_label = Label.new()
	character_hp_label.text = "HP: 100/100"
	character_hp_label.add_theme_font_size_override("font_size", 12)
	character_hp_label.add_theme_color_override("font_color", Color.RED)
	character_stats_container.add_child(character_hp_label)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(15, 1)
	character_stats_container.add_child(spacer2)
	
	# Action Points
	action_points_label = Label.new()
	action_points_label.text = "AP: 5"
	action_points_label.add_theme_font_size_override("font_size", 12)
	action_points_label.add_theme_color_override("font_color", Color.YELLOW)
	character_stats_container.add_child(action_points_label)

func setup_layout(viewport_size: Vector2):
	"""Setup the layout of the top bar"""
	var bar_height = 80
	var margin = 10
	
	# Position and size the main control
	position = Vector2(0, 0)
	size = Vector2(viewport_size.x, bar_height)
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Position and size the background
	background_panel.position = Vector2.ZERO
	background_panel.size = size
	
	# Layout sections
	layout_sections(viewport_size, bar_height, margin)

func layout_sections(viewport_size: Vector2, bar_height: int, margin: int):
	"""Layout the three main sections"""
	var usable_height = bar_height - (margin * 2)
	
	# Turn section (left)
	turn_section.position = Vector2(margin, margin)
	turn_section.size = Vector2(200, usable_height)
	
	# Resources section (center)
	var resources_width = 400
	resources_section.position = Vector2((viewport_size.x - resources_width) / 2, margin)
	resources_section.size = Vector2(resources_width, usable_height)
	
	# Character section (right)
	var character_width = 250
	character_section.position = Vector2(viewport_size.x - character_width - margin, margin)
	character_section.size = Vector2(character_width, usable_height)

func connect_signals():
	"""Connect to game signals"""
	pass  # Signals will be connected by GameUI

# Public interface methods
func _on_turn_changed(turn_number: int):
	"""Update turn display"""
	turn_subtext.text = str(turn_number)

func _on_action_points_changed(current_action_points: int):
	"""Update action points display"""
	action_points_label.text = "AP: " + str(current_action_points)

#func update_resource(resource_name: String, amount: int):
	#"""Update a specific resource display"""
	#var key = resource_name.to_lower()
	#if key in resource_labels:
		#resource_labels[key].text = resource_name.capitalize() + ": " + str(amount)

func update_character_name(name: String):
	"""Update character name"""
	character_name_label.text = name

func update_character_level(level: int):
	"""Update character level"""
	character_level_label.text = "Lvl: " + str(level)

func update_character_hp(current_hp: int, max_hp: int):
	"""Update character HP"""
	character_hp_label.text = "HP: " + str(current_hp) + "/" + str(max_hp)
	
	# Color coding based on HP percentage
	var hp_percentage = float(current_hp) / float(max_hp)
	if hp_percentage > 0.7:
		character_hp_label.add_theme_color_override("font_color", Color.GREEN)
	elif hp_percentage > 0.3:
		character_hp_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		character_hp_label.add_theme_color_override("font_color", Color.RED)
