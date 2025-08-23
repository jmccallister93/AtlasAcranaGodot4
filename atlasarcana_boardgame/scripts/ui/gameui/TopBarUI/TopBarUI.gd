# TopBarUI.gd - Main Top Bar Coordinator
extends Control
class_name TopBarUI

# Section Components
var meters_section: TopLeftUI  # Now contains corruption and conquest meters
var resources_section: TopCenterUI
var character_section: TopRightUI

# Background and animation
var background_panel: Panel
var gradient_animation_timer: Timer
var current_gradient: Gradient
var color_palettes = []
var current_palette_index = 0

# Layout configuration
var bar_height: int = 80
var section_margin: int = 10
var section_spacing: int = 15  # Space between sections

func _ready():
	create_background()
	create_sections()
	#setup_gradient_animation()

func create_background():
	"""Create the main background (now transparent)"""
	background_panel = Panel.new()
	background_panel.name = "TopBarBackground"
	add_child(background_panel)
	
	# Make the main background transparent so sections show individually
	create_transparent_background()

func create_sections():
	"""Create the three main sections"""
	# Meters section (left) - corruption and conquest meters
	meters_section = TopLeftUI.new()
	meters_section.name = "MetersSection"
	add_child(meters_section)
	
	# Resources section (center)
	resources_section = TopCenterUI.new()
	resources_section.name = "ResourcesSection"
	add_child(resources_section)
	
	# Character section (right)
	character_section = TopRightUI.new()
	character_section.name = "CharacterSection"
	add_child(character_section)

func create_transparent_background():
	"""Create a transparent background so sections show individually"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	background_panel.add_theme_stylebox_override("panel", style)



func setup_layout(viewport_size: Vector2):
	"""Setup the layout of the top bar and its sections"""
	position = Vector2(0, 0)
	size = Vector2(viewport_size.x, bar_height)
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Setup background
	background_panel.position = Vector2.ZERO
	background_panel.size = size
	
	# Calculate section sizes and positions
	layout_sections(viewport_size)

func layout_sections(viewport_size: Vector2):
	"""Layout the three sections as separate blocks"""
	var section_height = bar_height
	
	# Meters section (left) - auto-sized to content
	var meters_width = 180  # Reduced to fit content better
	meters_section.position = Vector2(section_spacing, 0)
	meters_section.setup_layout(Vector2(meters_width, (section_height+50)), section_margin)
	
	# Character section (right) - auto-sized to content
	var character_width = 200  # Reduced to fit content better
	character_section.position = Vector2(viewport_size.x - character_width - section_spacing, 0)
	character_section.setup_layout(Vector2(character_width, section_height), section_margin)
	
	# Resources section (center) - auto-sized to content
	var resources_start_x = meters_width + (section_spacing * 2)
	var resources_end_x = viewport_size.x - character_width - (section_spacing * 2)
	var resources_width = resources_end_x - resources_start_x
	resources_width = 650
	#resources_section.position = Vector2(resources_start_x, 0)
	resources_section.position = Vector2((viewport_size.x/2.4), 0)
	resources_section.setup_layout(Vector2(resources_width, section_height), section_margin)

# Public interface methods - delegate to appropriate sections

# NEW: Meter-related methods (replacing turn methods)
func update_corruption(value: float, max_value: float = -1):
	"""Update corruption meter"""
	if meters_section:
		meters_section.update_corruption(value, max_value)

func update_conquest(value: float, max_value: float = -1):
	"""Update conquest meter"""
	if meters_section:
		meters_section.update_conquest(value, max_value)

func add_corruption(amount: float):
	"""Add to corruption meter"""
	if meters_section:
		meters_section.add_corruption(amount)

func add_conquest(amount: float):
	"""Add to conquest meter"""
	if meters_section:
		meters_section.add_conquest(amount)

func set_corruption_range(min_val: float, max_val: float):
	"""Set corruption meter range"""
	if meters_section:
		meters_section.set_corruption_range(min_val, max_val)

func set_conquest_range(min_val: float, max_val: float):
	"""Set conquest meter range"""
	if meters_section:
		meters_section.set_conquest_range(min_val, max_val)

# LEGACY: Turn methods (kept for backwards compatibility but do nothing)
func _on_turn_changed(turn_number: int):
	"""Legacy method - no longer functional with meter display"""
	print("Warning: Turn display has been replaced with corruption/conquest meters")

func update_turn_phase(phase: String):
	"""Legacy method - no longer functional with meter display"""
	print("Warning: Turn phase display has been replaced with corruption/conquest meters")

# Character and resource methods (unchanged)
func _on_action_points_changed(current_action_points: int):
	"""Update action points display"""
	if character_section:
		character_section.update_action_points(current_action_points)

func update_resource(resource_name: String, amount: int):
	"""Update a specific resource display"""
	if resources_section:
		resources_section.update_resource(resource_name, amount)

func update_all_resources(resources: Dictionary):
	"""Update all resource displays"""
	if resources_section:
		resources_section.update_all_resources(resources)

func update_character_name(name: String):
	"""Update character name"""
	if character_section:
		character_section.update_character_name(name)

func update_character_level(level: int):
	"""Update character level"""
	if character_section:
		character_section.update_character_level(level)

func update_character_hp(current_hp: int, max_hp: int):
	"""Update character HP"""
	if character_section:
		character_section.update_character_hp(current_hp, max_hp)

# Getter methods for accessing section data
func get_corruption_value() -> float:
	"""Get current corruption value"""
	return meters_section.get_corruption_value() if meters_section else 0.0

func get_corruption_percentage() -> float:
	"""Get corruption as percentage"""
	return meters_section.get_corruption_percentage() if meters_section else 0.0

func get_conquest_value() -> float:
	"""Get current conquest value"""
	return meters_section.get_conquest_value() if meters_section else 0.0

func get_conquest_percentage() -> float:
	"""Get conquest as percentage"""
	return meters_section.get_conquest_percentage() if meters_section else 0.0

func get_resource_amount(resource_name: String) -> int:
	"""Get current amount of a resource"""
	return resources_section.get_resource_amount(resource_name) if resources_section else 0

func get_all_resources() -> Dictionary:
	"""Get all current resource amounts"""
	return resources_section.get_all_resources() if resources_section else {}

func get_character_data() -> Dictionary:
	"""Get all character data"""
	if not character_section:
		return {}
	
	return {
		"name": character_section.get_character_name(),
		"level": character_section.get_character_level(),
		"current_hp": character_section.get_current_hp(),
		"max_hp": character_section.get_max_hp(),
		"current_ap": character_section.get_current_action_points(),
		"max_ap": character_section.get_max_action_points()
	}

func get_meters_data() -> Dictionary:
	"""Get all meter data"""
	if not meters_section:
		return {}
	
	return {
		"corruption_value": meters_section.get_corruption_value(),
		"corruption_max": meters_section.get_corruption_max(),
		"corruption_percentage": meters_section.get_corruption_percentage(),
		"conquest_value": meters_section.get_conquest_value(),
		"conquest_max": meters_section.get_conquest_max(),
		"conquest_percentage": meters_section.get_conquest_percentage()
	}

# Component access methods
func get_meters_section() -> TopLeftUI:
	"""Get the meters display section"""
	return meters_section

func get_resources_section() -> TopCenterUI:
	"""Get the resources display section"""
	return resources_section

func get_character_section() -> TopRightUI:
	"""Get the character display section"""
	return character_section

# LEGACY: Kept for backwards compatibility
func get_turn_section() -> TopLeftUI:
	"""Legacy method - returns meters section"""
	print("Warning: get_turn_section() is deprecated, use get_meters_section()")
	return meters_section

func get_current_turn() -> int:
	"""Legacy method - no longer functional"""
	print("Warning: Turn tracking has been replaced with corruption/conquest meters")
	return 1

# Resource utility methods (unchanged)
func add_resource_display(resource_name: String, initial_amount: int = 0):
	"""Add a new resource to the display"""
	if resources_section:
		resources_section.add_resource_display(resource_name, initial_amount)

func remove_resource_display(resource_name: String):
	"""Remove a resource from the display"""
	if resources_section:
		resources_section.remove_resource_display(resource_name)

func set_resource_visibility(resource_name: String, visible: bool):
	"""Show or hide a specific resource"""
	if resources_section:
		resources_section.set_resource_visibility(resource_name, visible)

# Section spacing control methods
func set_section_spacing(spacing: int):
	"""Set the spacing between sections"""
	section_spacing = spacing
	# Re-layout sections with new spacing
	var viewport_size = get_viewport().get_visible_rect().size
	layout_sections(viewport_size)

func get_section_spacing() -> int:
	"""Get current section spacing"""
	return section_spacing

func increase_section_spacing(amount: int = 5):
	"""Increase spacing between sections"""
	set_section_spacing(section_spacing + amount)

func decrease_section_spacing(amount: int = 5):
	"""Decrease spacing between sections"""
	set_section_spacing(max(0, section_spacing - amount))

func set_section_layout(left_width: int = 180, right_width: int = 200, spacing: int = 15):
	"""Set custom section widths and spacing"""
	section_spacing = spacing
	# Store custom widths for layout
	var viewport_size = get_viewport().get_visible_rect().size
	layout_sections_custom(viewport_size, left_width, right_width)

func layout_sections_custom(viewport_size: Vector2, left_width: int, right_width: int):
	"""Layout sections with custom widths"""
	var section_height = bar_height
	
	# Meters section (left)
	meters_section.position = Vector2(section_spacing, 0)
	meters_section.setup_layout(Vector2(left_width, section_height), section_margin)
	
	# Character section (right)
	character_section.position = Vector2(viewport_size.x - right_width - section_spacing, 0)
	character_section.setup_layout(Vector2(right_width, section_height), section_margin)
	
	# Resources section (center)
	var resources_start_x = left_width + (section_spacing * 2)
	var resources_end_x = viewport_size.x - right_width - (section_spacing * 2)
	var resources_width = resources_end_x - resources_start_x
	resources_section.position = Vector2(resources_start_x, 0)
	resources_section.setup_layout(Vector2(resources_width, section_height), section_margin)
