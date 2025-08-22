# CharacterDisplaySection.gd - Top Right: Character Information
extends Control
class_name TopRightUI

# UI Components
var background_panel: Panel
var character_container: VBoxContainer
var character_name_label: Label
var stats_container: HBoxContainer
var level_label: Label
var hp_label: Label
var action_points_label: Label

# Character data
var character_name: String = "Hero"
var character_level: int = 1
var current_hp: int = 100
var max_hp: int = 100
var current_action_points: int = 5
var max_action_points: int = 5

func _ready():
	create_ui_components()
	setup_styling()
	update_all_displays()

func create_ui_components():
	"""Create all character display components"""
	# Background panel
	background_panel = Panel.new()
	background_panel.name = "CharacterBackground"
	add_child(background_panel)
	
	# Main container
	character_container = VBoxContainer.new()
	character_container.name = "CharacterContainer"
	background_panel.add_child(character_container)
	
	# Character name
	character_name_label = Label.new()
	character_name_label.text = character_name
	character_name_label.name = "CharacterNameLabel"
	character_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	character_container.add_child(character_name_label)
	
	# Stats container
	stats_container = HBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.alignment = BoxContainer.ALIGNMENT_END
	character_container.add_child(stats_container)
	
	# Level
	level_label = Label.new()
	level_label.text = "Lvl: " + str(character_level)
	level_label.name = "LevelLabel"
	stats_container.add_child(level_label)
	
	# Spacer 1
	add_spacer_to_container(stats_container, 15)
	
	# HP
	hp_label = Label.new()
	hp_label.text = "HP: " + str(current_hp) + "/" + str(max_hp)
	hp_label.name = "HPLabel"
	stats_container.add_child(hp_label)
	
	# Spacer 2
	add_spacer_to_container(stats_container, 15)
	
	# Action Points
	action_points_label = Label.new()
	action_points_label.text = "AP: " + str(current_action_points)
	action_points_label.name = "ActionPointsLabel"
	stats_container.add_child(action_points_label)

func add_spacer_to_container(container: Container, width: int):
	"""Helper to add spacers between stats"""
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(width, 1)
	container.add_child(spacer)

func setup_styling():
	"""Apply styling to components"""
	# Background styling - fitted to content
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.05, 0.15, 0.9)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.5, 0.7, 0.8)
	background_panel.add_theme_stylebox_override("panel", style)
	
	# Character name styling
	character_name_label.add_theme_font_size_override("font_size", 16)
	character_name_label.add_theme_color_override("font_color", Color.CYAN)
	character_name_label.add_theme_font_override("font", load("res://themes/fonts/bold_font.tres") if ResourceLoader.exists("res://themes/fonts/bold_font.tres") else null)
	
	# Level styling
	level_label.add_theme_font_size_override("font_size", 11)
	level_label.add_theme_color_override("font_color", Color.WHITE)
	
	# HP styling
	hp_label.add_theme_font_size_override("font_size", 11)
	update_hp_color()
	
	# Action points styling
	action_points_label.add_theme_font_size_override("font_size", 11)
	action_points_label.add_theme_color_override("font_color", Color.YELLOW)

func setup_layout(section_size: Vector2, margin: int = 10):
	"""Setup the layout of this section"""
	size = section_size
	
	# Position background
	background_panel.position = Vector2.ZERO
	background_panel.size = section_size
	
	# Position container
	character_container.position = Vector2(margin, margin)
	character_container.size = Vector2(section_size.x - (margin * 2), section_size.y - (margin * 2))

# Public interface methods
func update_character_name(new_name: String):
	"""Update the character name"""
	character_name = new_name
	character_name_label.text = character_name
	
	# Brief animation for name changes
	animate_label_change(character_name_label)

func update_character_level(new_level: int):
	"""Update the character level"""
	var old_level = character_level
	character_level = new_level
	level_label.text = "Lvl: " + str(character_level)
	
	# Special animation for level ups
	if new_level > old_level:
		animate_level_up()
	else:
		animate_label_change(level_label)

func update_character_hp(new_current_hp: int, new_max_hp: int = -1):
	"""Update the character HP"""
	current_hp = new_current_hp
	if new_max_hp > 0:
		max_hp = new_max_hp
	
	hp_label.text = "HP: " + str(current_hp) + "/" + str(max_hp)
	update_hp_color()
	
	# Animation for HP changes
	animate_label_change(hp_label)

func update_action_points(new_action_points: int, new_max_action_points: int = -1):
	"""Update the action points"""
	current_action_points = new_action_points
	if new_max_action_points > 0:
		max_action_points = new_max_action_points
	
	action_points_label.text = "AP: " + str(current_action_points)
	if max_action_points != current_action_points:
		action_points_label.text += "/" + str(max_action_points)
	
	# Color based on AP remaining
	update_action_points_color()
	animate_label_change(action_points_label)

func update_hp_color():
	"""Update HP label color based on health percentage"""
	var hp_percentage = float(current_hp) / float(max_hp) if max_hp > 0 else 1.0
	
	if hp_percentage > 0.7:
		hp_label.add_theme_color_override("font_color", Color.GREEN)
	elif hp_percentage > 0.3:
		hp_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		hp_label.add_theme_color_override("font_color", Color.RED)

func update_action_points_color():
	"""Update action points color based on remaining points"""
	var ap_percentage = float(current_action_points) / float(max_action_points) if max_action_points > 0 else 1.0
	
	if ap_percentage > 0.5:
		action_points_label.add_theme_color_override("font_color", Color.YELLOW)
	elif ap_percentage > 0.2:
		action_points_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		action_points_label.add_theme_color_override("font_color", Color.RED)

func update_all_displays():
	"""Refresh all character displays"""
	character_name_label.text = character_name
	level_label.text = "Lvl: " + str(character_level)
	hp_label.text = "HP: " + str(current_hp) + "/" + str(max_hp)
	action_points_label.text = "AP: " + str(current_action_points)
	
	update_hp_color()
	update_action_points_color()

# Animation methods
func animate_label_change(label: Label):
	"""Create a brief animation for label changes"""
	var tween = create_tween()
	var original_scale = label.scale
	
	tween.tween_property(label, "scale", original_scale * 1.2, 0.1)
	tween.tween_property(label, "scale", original_scale, 0.1)

func animate_level_up():
	"""Special animation for level ups"""
	var tween = create_tween()
	var original_scale = level_label.scale
	var original_color = level_label.get_theme_color("font_color")
	
	# Scale and color animation
	tween.tween_property(level_label, "scale", original_scale * 1.5, 0.2)
	level_label.add_theme_color_override("font_color", Color.GOLD)
	
	tween.tween_property(level_label, "scale", original_scale, 0.3)
	tween.tween_callback(func(): level_label.add_theme_color_override("font_color", original_color)).set_delay(0.5)

func animate_hp_change(hp_change: int):
	"""Animate HP changes with color coding"""
	var tween = create_tween()
	var flash_color = Color.GREEN if hp_change > 0 else Color.RED
	var original_color = hp_label.get_theme_color("font_color")
	
	hp_label.add_theme_color_override("font_color", flash_color)
	tween.tween_callback(func(): update_hp_color()).set_delay(0.3)

# Getters
func get_character_name() -> String:
	return character_name

func get_character_level() -> int:
	return character_level

func get_current_hp() -> int:
	return current_hp

func get_max_hp() -> int:
	return max_hp

func get_current_action_points() -> int:
	return current_action_points

func get_max_action_points() -> int:
	return max_action_points

func get_hp_percentage() -> float:
	return float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
