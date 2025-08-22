# TopLeftUI.gd - Top Left: Corruption and Conquest Meters
extends Control
class_name TopLeftUI

# UI Components
var background_panel: Panel
var meters_container: VBoxContainer
var corruption_container: VBoxContainer
var conquest_container: VBoxContainer

# Corruption meter components
var corruption_label: Label
var corruption_progress_bar: ProgressBar
var corruption_background: Panel

# Conquest meter components
var conquest_label: Label
var conquest_progress_bar: ProgressBar
var conquest_background: Panel

# Meter data
var corruption_value: float = 0.0
var corruption_max: float = 100.0
var conquest_value: float = 0.0
var conquest_max: float = 100.0

func _ready():
	create_ui_components()
	setup_styling()
	update_all_displays()

func create_ui_components():
	"""Create all meter display components"""
	# Background panel
	background_panel = Panel.new()
	background_panel.name = "MetersBackground"
	add_child(background_panel)
	
	# Main container
	meters_container = VBoxContainer.new()
	meters_container.name = "MetersContainer"
	background_panel.add_child(meters_container)
	
	# Create corruption meter
	create_corruption_meter()
	
	# Add spacer between meters
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(1, 8)
	meters_container.add_child(spacer)
	
	# Create conquest meter
	create_conquest_meter()

func create_corruption_meter():
	"""Create the corruption meter components"""
	corruption_container = VBoxContainer.new()
	corruption_container.name = "CorruptionContainer"
	meters_container.add_child(corruption_container)
	
	# Corruption label
	corruption_label = Label.new()
	corruption_label.text = "Corruption: 0/100"
	corruption_label.name = "CorruptionLabel"
	corruption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	corruption_container.add_child(corruption_label)
	
	# Progress bar background
	corruption_background = Panel.new()
	corruption_background.name = "CorruptionBackground"
	corruption_background.custom_minimum_size = Vector2(160, 12)
	corruption_container.add_child(corruption_background)
	
	# Corruption progress bar
	corruption_progress_bar = ProgressBar.new()
	corruption_progress_bar.name = "CorruptionProgressBar"
	corruption_progress_bar.min_value = 0
	corruption_progress_bar.max_value = corruption_max
	corruption_progress_bar.value = corruption_value
	corruption_progress_bar.show_percentage = false
	corruption_background.add_child(corruption_progress_bar)

func create_conquest_meter():
	"""Create the conquest meter components"""
	conquest_container = VBoxContainer.new()
	conquest_container.name = "ConquestContainer"
	meters_container.add_child(conquest_container)
	
	# Conquest label
	conquest_label = Label.new()
	conquest_label.text = "Conquest: 0/100"
	conquest_label.name = "ConquestLabel"
	conquest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conquest_container.add_child(conquest_label)
	
	# Progress bar background
	conquest_background = Panel.new()
	conquest_background.name = "ConquestBackground"
	conquest_background.custom_minimum_size = Vector2(160, 12)
	conquest_container.add_child(conquest_background)
	
	# Conquest progress bar
	conquest_progress_bar = ProgressBar.new()
	conquest_progress_bar.name = "ConquestProgressBar"
	conquest_progress_bar.min_value = 0
	conquest_progress_bar.max_value = conquest_max
	conquest_progress_bar.value = conquest_value
	conquest_progress_bar.show_percentage = false
	conquest_background.add_child(conquest_progress_bar)

func setup_styling():
	"""Apply styling to components"""
	# Background styling
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_bottom_left = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.5, 0.7, 0.6)
	background_panel.add_theme_stylebox_override("panel", style)
	
	# Corruption label styling
	corruption_label.add_theme_font_size_override("font_size", 12)
	corruption_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Conquest label styling
	conquest_label.add_theme_font_size_override("font_size", 12)
	conquest_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Style the progress bars
	style_corruption_meter()
	style_conquest_meter()

func style_corruption_meter():
	"""Apply styling to corruption meter"""
	# Background styling
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.1, 0.1, 0.8)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.4, 0.2, 0.2, 0.8)
	corruption_background.add_theme_stylebox_override("panel", bg_style)
	
	# Progress bar styling - corruption (red tones)
	var progress_style = StyleBoxFlat.new()
	progress_style.bg_color = Color(0.8, 0.2, 0.2, 0.9)  # Dark red
	progress_style.corner_radius_top_left = 3
	progress_style.corner_radius_bottom_left = 3
	corruption_progress_bar.add_theme_stylebox_override("fill", progress_style)
	
	# Progress bar background
	var progress_bg_style = StyleBoxFlat.new()
	progress_bg_style.bg_color = Color(0.1, 0.05, 0.05, 0.9)
	corruption_progress_bar.add_theme_stylebox_override("background", progress_bg_style)

func style_conquest_meter():
	"""Apply styling to conquest meter"""
	# Background styling
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.2, 0.8)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.2, 0.2, 0.4, 0.8)
	conquest_background.add_theme_stylebox_override("panel", bg_style)
	
	# Progress bar styling - conquest (blue/gold tones)
	var progress_style = StyleBoxFlat.new()
	progress_style.bg_color = Color(0.2, 0.4, 0.8, 0.9)  # Dark blue
	progress_style.corner_radius_top_left = 3
	progress_style.corner_radius_bottom_left = 3
	conquest_progress_bar.add_theme_stylebox_override("fill", progress_style)
	
	# Progress bar background
	var progress_bg_style = StyleBoxFlat.new()
	progress_bg_style.bg_color = Color(0.05, 0.05, 0.1, 0.9)
	conquest_progress_bar.add_theme_stylebox_override("background", progress_bg_style)

func setup_layout(section_size: Vector2, margin: int = 10):
	"""Setup the layout of this section"""
	size = section_size
	
	# Position background
	background_panel.position = Vector2.ZERO
	background_panel.size = section_size
	
	# Center the container
	meters_container.position = Vector2(margin, margin)
	meters_container.size = Vector2(section_size.x - (margin * 2), section_size.y - (margin * 2))
	
	# Position progress bars within their backgrounds
	position_progress_bars()

func position_progress_bars():
	"""Position the progress bars within their background panels"""
	# Position corruption progress bar
	corruption_progress_bar.position = Vector2(2, 2)
	corruption_progress_bar.size = Vector2(corruption_background.size.x - 4, corruption_background.size.y - 4)
	
	# Position conquest progress bar
	conquest_progress_bar.position = Vector2(2, 2)
	conquest_progress_bar.size = Vector2(conquest_background.size.x - 4, conquest_background.size.y - 4)

# Public interface methods
func update_corruption(value: float, max_value: float = -1):
	"""Update the corruption meter"""
	corruption_value = value
	if max_value > 0:
		corruption_max = max_value
		corruption_progress_bar.max_value = corruption_max
	
	corruption_progress_bar.value = corruption_value
	corruption_label.text = "Corruption: " + str(int(corruption_value)) + "/" + str(int(corruption_max))
	
	# Update color based on corruption level
	update_corruption_color()
	animate_meter_change(corruption_progress_bar)

func update_conquest(value: float, max_value: float = -1):
	"""Update the conquest meter"""
	conquest_value = value
	if max_value > 0:
		conquest_max = max_value
		conquest_progress_bar.max_value = conquest_max
	
	conquest_progress_bar.value = conquest_value
	conquest_label.text = "Conquest: " + str(int(conquest_value)) + "/" + str(int(conquest_max))
	
	# Update color based on conquest level
	update_conquest_color()
	animate_meter_change(conquest_progress_bar)

func update_corruption_color():
	"""Update corruption meter color based on level"""
	var corruption_percentage = corruption_value / corruption_max if corruption_max > 0 else 0.0
	var progress_style = StyleBoxFlat.new()
	
	if corruption_percentage < 0.3:
		# Low corruption - dark red
		progress_style.bg_color = Color(0.5, 0.1, 0.1, 0.9)
	elif corruption_percentage < 0.6:
		# Medium corruption - red
		progress_style.bg_color = Color(0.8, 0.2, 0.2, 0.9)
	elif corruption_percentage < 0.9:
		# High corruption - bright red
		progress_style.bg_color = Color(1.0, 0.3, 0.3, 0.9)
	else:
		# Maximum corruption - pulsing red
		progress_style.bg_color = Color(1.0, 0.1, 0.1, 1.0)
	
	progress_style.corner_radius_top_left = 3
	progress_style.corner_radius_bottom_left = 3
	corruption_progress_bar.add_theme_stylebox_override("fill", progress_style)

func update_conquest_color():
	"""Update conquest meter color based on level"""
	var conquest_percentage = conquest_value / conquest_max if conquest_max > 0 else 0.0
	var progress_style = StyleBoxFlat.new()
	
	if conquest_percentage < 0.3:
		# Low conquest - dark blue
		progress_style.bg_color = Color(0.1, 0.2, 0.5, 0.9)
	elif conquest_percentage < 0.6:
		# Medium conquest - blue
		progress_style.bg_color = Color(0.2, 0.4, 0.8, 0.9)
	elif conquest_percentage < 0.9:
		# High conquest - bright blue
		progress_style.bg_color = Color(0.3, 0.5, 1.0, 0.9)
	else:
		# Maximum conquest - gold
		progress_style.bg_color = Color(1.0, 0.8, 0.2, 1.0)
	
	progress_style.corner_radius_top_left = 3
	progress_style.corner_radius_bottom_left = 3
	conquest_progress_bar.add_theme_stylebox_override("fill", progress_style)

func update_all_displays():
	"""Refresh all meter displays"""
	corruption_progress_bar.value = corruption_value
	conquest_progress_bar.value = conquest_value
	corruption_label.text = "Corruption: " + str(int(corruption_value)) + "/" + str(int(corruption_max))
	conquest_label.text = "Conquest: " + str(int(conquest_value)) + "/" + str(int(conquest_max))
	
	update_corruption_color()
	update_conquest_color()

# Animation methods
func animate_meter_change(progress_bar: ProgressBar):
	"""Create a brief animation for meter changes"""
	var tween = create_tween()
	var original_scale = progress_bar.scale
	
	tween.tween_property(progress_bar, "scale", original_scale * 1.05, 0.1)
	tween.tween_property(progress_bar, "scale", original_scale, 0.1)

func animate_corruption_threshold():
	"""Special animation when corruption reaches certain thresholds"""
	var tween = create_tween()
	var original_color = corruption_label.get_theme_color("font_color")
	
	corruption_label.add_theme_color_override("font_color", Color.RED)
	tween.tween_callback(func(): corruption_label.add_theme_color_override("font_color", original_color)).set_delay(0.5)

func animate_conquest_threshold():
	"""Special animation when conquest reaches certain thresholds"""
	var tween = create_tween()
	var original_color = conquest_label.get_theme_color("font_color")
	
	conquest_label.add_theme_color_override("font_color", Color.GOLD)
	tween.tween_callback(func(): conquest_label.add_theme_color_override("font_color", original_color)).set_delay(0.5)

# Getters
func get_corruption_value() -> float:
	return corruption_value

func get_corruption_max() -> float:
	return corruption_max

func get_corruption_percentage() -> float:
	return corruption_value / corruption_max if corruption_max > 0 else 0.0

func get_conquest_value() -> float:
	return conquest_value

func get_conquest_max() -> float:
	return conquest_max

func get_conquest_percentage() -> float:
	return conquest_value / conquest_max if conquest_max > 0 else 0.0

# Utility methods
func set_corruption_range(min_val: float, max_val: float):
	"""Set the corruption meter range"""
	corruption_progress_bar.min_value = min_val
	corruption_progress_bar.max_value = max_val
	corruption_max = max_val

func set_conquest_range(min_val: float, max_val: float):
	"""Set the conquest meter range"""
	conquest_progress_bar.min_value = min_val
	conquest_progress_bar.max_value = max_val
	conquest_max = max_val

func add_corruption(amount: float):
	"""Add to corruption value"""
	update_corruption(corruption_value + amount)
	
	# Special effects for threshold crossing
	var percentage = get_corruption_percentage()
	if percentage >= 0.5 and percentage - (amount / corruption_max) < 0.5:
		animate_corruption_threshold()

func add_conquest(amount: float):
	"""Add to conquest value"""
	update_conquest(conquest_value + amount)
	
	# Special effects for threshold crossing
	var percentage = get_conquest_percentage()
	if percentage >= 0.5 and percentage - (amount / conquest_max) < 0.5:
		animate_conquest_threshold()
