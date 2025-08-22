# ResourcesDisplaySection.gd - Top Center: Resources Display
extends Control
class_name TopCenterUI

# UI Components
var background_panel: Panel
var resources_container: HBoxContainer
var resource_displays: Dictionary = {}
var resource_data: Dictionary = {}

# Resource configuration
var resource_config = {
	"essence": {"color": Color.PURPLE, "icon": "⚡"},
	"food": {"color": Color.GREEN, "icon": "🍞"},
	"wood": {"color": Color(0.6, 0.4, 0.2), "icon": "🪵"},
	"stone": {"color": Color.GRAY, "icon": "🪨"},
	"gold": {"color": Color.GOLD, "icon": "💰"}
}

func _ready():
	create_ui_components()
	setup_styling()
	initialize_resources()

func create_ui_components():
	"""Create all resource display components"""
	# Background panel
	background_panel = Panel.new()
	background_panel.name = "ResourcesBackground"
	add_child(background_panel)
	
	# Main container
	resources_container = HBoxContainer.new()
	resources_container.name = "ResourcesContainer"
	resources_container.alignment = BoxContainer.ALIGNMENT_CENTER
	background_panel.add_child(resources_container)

func setup_styling():
	"""Apply styling to the background"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.1, 0.15, 0.9)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.5, 0.7, 0.6)
	background_panel.add_theme_stylebox_override("panel", style)

func initialize_resources():
	"""Initialize default resources"""
	for resource_name in resource_config.keys():
		add_resource_display(resource_name, 0)

func add_resource_display(resource_name: String, initial_amount: int = 0):
	"""Add a new resource display"""
	var resource_key = resource_name.to_lower()
	
	# Don't add if already exists
	if resource_key in resource_displays:
		return
	
	var config = resource_config.get(resource_key, {"color": Color.WHITE, "icon": "?"})
	
	# Create resource container
	var resource_container = HBoxContainer.new()
	resource_container.name = resource_name.capitalize() + "Container"
	
	# Resource icon
	var icon_label = Label.new()
	icon_label.text = config.icon
	icon_label.add_theme_font_size_override("font_size", 16)
	resource_container.add_child(icon_label)
	
	# Small spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(5, 1)
	resource_container.add_child(spacer)
	
	# Resource label
	var resource_label = Label.new()
	resource_label.text = resource_name.capitalize() + ": " + str(initial_amount)
	resource_label.add_theme_font_size_override("font_size", 14)
	resource_label.add_theme_color_override("font_color", config.color)
	resource_container.add_child(resource_label)
	
	# Add to main container
	resources_container.add_child(resource_container)
	
	# Add separator if not the last item
	if resources_container.get_child_count() > 1:
		var separator = create_separator()
		resources_container.add_child(separator)
		resources_container.move_child(separator, resources_container.get_child_count() - 2)
	
	# Store references
	resource_displays[resource_key] = {
		"container": resource_container,
		"label": resource_label,
		"icon": icon_label
	}
	resource_data[resource_key] = initial_amount

func create_separator() -> Control:
	"""Create a visual separator between resources"""
	var separator_container = VBoxContainer.new()
	separator_container.custom_minimum_size = Vector2(20, 1)
	
	var separator_line = ColorRect.new()
	separator_line.color = Color(0.5, 0.5, 0.5, 0.3)
	separator_line.custom_minimum_size = Vector2(1, 30)
	separator_container.add_child(separator_line)
	
	return separator_container

func setup_layout(section_size: Vector2, margin: int = 10):
	"""Setup the layout of this section"""
	size = section_size
	
	# Position background
	background_panel.position = Vector2.ZERO
	background_panel.size = section_size
	
	# Center the container
	resources_container.position = Vector2(margin, margin)
	resources_container.size = Vector2(section_size.x - (margin * 2), section_size.y - (margin * 2))

# Public interface methods
func update_resource(resource_name: String, amount: int):
	"""Update a specific resource display"""
	var resource_key = resource_name.to_lower()
	
	# Add the resource if it doesn't exist
	if resource_key not in resource_displays:
		add_resource_display(resource_name, amount)
		return
	
	var old_amount = resource_data.get(resource_key, 0)
	resource_data[resource_key] = amount
	
	var display = resource_displays[resource_key]
	var label = display.label
	label.text = resource_name.capitalize() + ": " + str(amount)
	
	# Animate resource changes
	animate_resource_change(label, amount - old_amount)

func update_all_resources(resources: Dictionary):
	"""Update all resource displays"""
	for resource_name in resources:
		update_resource(resource_name, resources[resource_name])

func animate_resource_change(label: Label, change_amount: int):
	"""Create an animation for resource changes"""
	if change_amount == 0:
		return
	
	var tween = create_tween()
	var original_scale = label.scale
	
	# Scale animation
	tween.tween_property(label, "scale", original_scale * 1.15, 0.1)
	tween.tween_property(label, "scale", original_scale, 0.1)
	
	# Color flash based on change type
	var flash_color = Color.GREEN if change_amount > 0 else Color.RED
	var original_color = label.get_theme_color("font_color")
	
	label.add_theme_color_override("font_color", flash_color)
	tween.tween_callback(func(): label.add_theme_color_override("font_color", original_color)).set_delay(0.3)

func get_resource_amount(resource_name: String) -> int:
	"""Get the current amount of a resource"""
	var resource_key = resource_name.to_lower()
	return resource_data.get(resource_key, 0)

func get_all_resources() -> Dictionary:
	"""Get all current resource amounts"""
	return resource_data.duplicate()

func remove_resource_display(resource_name: String):
	"""Remove a resource display"""
	var resource_key = resource_name.to_lower()
	
	if resource_key in resource_displays:
		var display = resource_displays[resource_key]
		display.container.queue_free()
		resource_displays.erase(resource_key)
		resource_data.erase(resource_key)

func set_resource_visibility(resource_name: String, visible: bool):
	"""Show or hide a specific resource"""
	var resource_key = resource_name.to_lower()
	
	if resource_key in resource_displays:
		var display = resource_displays[resource_key]
		display.container.visible = visible
