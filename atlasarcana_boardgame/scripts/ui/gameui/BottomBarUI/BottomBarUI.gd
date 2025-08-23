# BottomBarUI.gd - Main Bottom Bar Coordinator
extends Control
class_name BottomBarUI

# Section Components
var menu_section: BottomLeftUI
var action_section: BottomCenterUI
var turn_section: BottomRightUI

# Background
var background_panel: Panel

# Layout configuration
var bar_height: int = 80
var section_margin: int = 10
var section_spacing: int = 15

# Signals
signal menu_button_pressed(menu_type: String)
signal action_button_pressed(action_type: String)
signal action_failed(message: String)

func _ready():
	print("BottomBarUI _ready() called")
	# Don't create UI components here - wait for setup_layout

func create_background():
	"""Create the main background (transparent for separate sections)"""
	background_panel = Panel.new()
	background_panel.name = "BottomBarBackground"
	add_child(background_panel)
	
	# Make the main background transparent so sections show individually
	create_transparent_background()

func create_transparent_background():
	"""Create a transparent background so sections show individually"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	background_panel.add_theme_stylebox_override("panel", style)

func create_sections():
	"""Create the three main sections"""
	# Menu section (left)
	menu_section = BottomLeftUI.new()
	menu_section.name = "MenuSection"
	add_child(menu_section)
	
	# Action section (center)
	action_section = BottomCenterUI.new()
	action_section.name = "ActionSection"
	add_child(action_section)
	
	# Turn section (right)
	turn_section = BottomRightUI.new()
	turn_section.name = "TurnSection"
	add_child(turn_section)
	
	connect_section_signals()

func connect_section_signals():
	"""Connect signals from all sections"""
	# Menu section signals
	menu_section.menu_button_pressed.connect(_on_menu_button_pressed)
	
	# Action section signals
	action_section.action_button_pressed.connect(_on_action_button_pressed)
	
	# Turn section signals
	turn_section.advance_turn_requested.connect(_on_advance_turn_requested)

func _on_menu_button_pressed(menu_type: String):
	"""Handle menu button presses and forward signal"""
	menu_section.animate_button_press(menu_type)
	menu_button_pressed.emit(menu_type)

func _on_action_button_pressed(action_type: String):
	"""Handle action button presses and forward signal"""
	action_section.animate_button_press(action_type)
	action_button_pressed.emit(action_type)

func _on_advance_turn_requested():
	"""Handle advance turn requests"""
	print("Turn advancement requested from BottomBarUI")

func setup_layout(viewport_size: Vector2):
	"""Setup the layout of the bottom bar and its sections"""
	# Position and size the main control
	position = Vector2(0, viewport_size.y - bar_height)
	size = Vector2(viewport_size.x, bar_height)
	mouse_filter = Control.MOUSE_FILTER_PASS
	visible = true
	
	create_sections()

	# Layout sections
	layout_sections(viewport_size)

func layout_sections(viewport_size: Vector2):
	"""Layout the three sections as separate blocks"""
	var section_height = bar_height
	
	# Menu section (left) - auto-sized to content
	var menu_width = 550  # Width for 5 menu buttons
	menu_section.position = Vector2(section_spacing, 0)
	menu_section.setup_layout(Vector2(menu_width, section_height), section_margin)
	
	# Turn section (right) - auto-sized to content
	var turn_width = 130  # Width for turn control
	turn_section.position = Vector2(viewport_size.x - turn_width - section_spacing, 0)
	turn_section.setup_layout(Vector2(turn_width, section_height), section_margin)
	
	# Action section (center) - takes remaining space
	var action_start_x = menu_width + (section_spacing * 8)
	var action_end_x = viewport_size.x - turn_width - (section_spacing * 8)
	var action_width = action_end_x - action_start_x
	action_width = 450
	#action_section.position = Vector2(action_start_x, 0)
	action_section.position = Vector2((viewport_size.x/2.2), 0)
	action_section.setup_layout(Vector2(action_width, section_height), section_margin)
	

# Public interface methods - delegate to appropriate sections

# Menu methods
func highlight_menu_button(menu_type: String):
	"""Highlight a specific menu button"""
	if menu_section:
		menu_section.highlight_menu_button(menu_type)

func reset_menu_button_styles():
	"""Reset all menu buttons to normal appearance"""
	if menu_section:
		menu_section.reset_all_button_styles()

func set_menu_button_enabled(menu_type: String, enabled: bool):
	"""Enable or disable a specific menu button"""
	if menu_section:
		menu_section.set_button_enabled(menu_type, enabled)

# Action methods
func highlight_action_button(action_type: String, active_text: String = ""):
	"""Highlight a specific action button"""
	if action_section:
		action_section.highlight_action_button(action_type, active_text)

func reset_action_button_styles():
	"""Reset all action buttons to normal appearance"""
	if action_section:
		action_section.reset_all_button_styles()

func set_action_button_enabled(action_type: String, enabled: bool):
	"""Enable or disable a specific action button"""
	if action_section:
		action_section.set_button_enabled(action_type, enabled)

func update_action_buttons_availability(current_action_points: int):
	"""Update action button appearance based on available action points"""
	if action_section:
		action_section.update_buttons_availability(current_action_points)

# Turn methods
func update_turn_info(turn_number: int):
	"""Update turn information"""
	if turn_section:
		turn_section.update_turn_info(turn_number)

func set_can_advance_turn(can_advance: bool):
	"""Enable or disable turn advancement"""
	if turn_section:
		turn_section.set_can_advance_turn(can_advance)

func show_turn_processing():
	"""Show that turn is being processed"""
	if turn_section:
		turn_section.show_turn_processing()

# Mode management (for backwards compatibility)
func update_button_states(active_mode):
	"""Update button visual states based on active mode"""
	if action_section:
		action_section.reset_all_button_styles()
		
		# Highlight the appropriate action button based on mode
		# Note: You may need to adjust these enum references based on your GameManager structure
	match active_mode:
		GameManager.action_controller.ActionMode.MOVEMENT:
			action_section.highlight_action_button("move", "Move (Active)")
		GameManager.action_controller.ActionMode.BUILD:
			action_section.highlight_action_button("build", "Build (Active)")
		GameManager.action_controller.ActionMode.ATTACK:
			action_section.highlight_action_button("attack", "Attack (Active)")
		GameManager.action_controller.ActionMode.INTERACT:
			action_section.highlight_action_button("interact", "Interact (Active)")

# Component access methods
func get_menu_section() -> BottomLeftUI:
	"""Get the menu section"""
	return menu_section

func get_action_section() -> BottomCenterUI:
	"""Get the action section"""
	return action_section

func get_turn_section() -> BottomRightUI:
	"""Get the turn section"""
	return turn_section

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

func set_section_layout(left_width: int = 450, right_width: int = 130, spacing: int = 15):
	"""Set custom section widths and spacing"""
	section_spacing = spacing
	var viewport_size = get_viewport().get_visible_rect().size
	layout_sections_custom(viewport_size, left_width, right_width)

func layout_sections_custom(viewport_size: Vector2, left_width: int, right_width: int):
	"""Layout sections with custom widths"""
	var section_height = bar_height
	
	# Menu section (left)
	menu_section.position = Vector2(section_spacing, 0)
	menu_section.setup_layout(Vector2(left_width, section_height), section_margin)
	
	# Turn section (right)
	turn_section.position = Vector2(viewport_size.x - right_width - section_spacing, 0)
	turn_section.setup_layout(Vector2(right_width, section_height), section_margin)
	
	# Action section (center)
	var action_start_x = left_width + (section_spacing * 2)
	var action_end_x = viewport_size.x - right_width - (section_spacing * 2)
	var action_width = action_end_x - action_start_x
	action_section.position = Vector2(action_start_x, 0)
	action_section.setup_layout(Vector2(action_width, section_height), section_margin)

# Legacy methods for backwards compatibility
func get_action_buttons() -> Array:
	"""Get all action buttons for external access"""
	if action_section:
		return action_section.get_all_buttons()
	return []

# Debug method
func debug_print_state():
	"""Debug method to print current state"""
	print("=== BottomBarUI Debug State ===")
	print("Visible: ", visible)
	print("Size: ", size)
	print("Position: ", position)
	print("Parent: ", get_parent())
	print("Children count: ", get_children().size())
	print("Menu section exists: ", menu_section != null)
	print("Action section exists: ", action_section != null)
	print("Turn section exists: ", turn_section != null)
	print("Section spacing: ", section_spacing)
	if menu_section:
		print("Menu section position: ", menu_section.position)
		print("Menu section size: ", menu_section.size)
	if action_section:
		print("Action section position: ", action_section.position)
		print("Action section size: ", action_section.size)
	if turn_section:
		print("Turn section position: ", turn_section.position)
		print("Turn section size: ", turn_section.size)
	print("==============================")
