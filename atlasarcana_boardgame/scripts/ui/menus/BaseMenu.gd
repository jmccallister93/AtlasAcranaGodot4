extends Control
class_name BaseMenu
signal inventory_closed

var item_container: GridContainer
var close_button: Button
var title_label: Label
var menu_title: String = ""
var target_position: Vector2
var hidden_position: Vector2

func _ready():
	self.visible = false
	resize_to_screen()
	create_title_label()
	create_close_button()
	create_background_panel()
	create_grid_container()
	ready_post()

# Fit to screen size and set up positions for animation
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

# Show menu with slide-up animation
func show_menu():
	self.visible = true
	var tween = create_tween()
	tween.parallel().tween_property(self, "position", target_position, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)

# Hide menu with slide-down animation
func hide_menu():
	var tween = create_tween()
	tween.parallel().tween_property(self, "position", hidden_position, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	# Hide after animation completes
	await tween.finished
	self.visible = false

# Create child objects
func create_title_label():
	title_label = Label.new()
	title_label.text = menu_title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	# Anchors: Top full width
	title_label.anchor_left = 0.0
	title_label.anchor_top = 0.0
	title_label.anchor_right = 1.0
	title_label.anchor_bottom = 0.0
	title_label.offset_top = 10
	title_label.offset_bottom = 40  # Space for the title area
	# Optional: Style
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_font_size_override("font_size", 20)
	add_child(title_label)
	
func create_background_panel():
	var panel = Panel.new()
	# Full-size fill
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
	# Style it
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2e2e2e")
	style.border_color = Color.WHITE
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	# Add and send to back
	add_child(panel)
	move_child(panel, 0)  # Ensure it's drawn first (at the back)

func create_grid_container():
	# Create a ScrollContainer
	var scroll_container = ScrollContainer.new()
	scroll_container.anchor_left = 0.0
	scroll_container.anchor_top = 0.0
	scroll_container.anchor_right = 1.0
	scroll_container.anchor_bottom = 1.0
	scroll_container.offset_left = 10
	scroll_container.offset_top = 60
	scroll_container.offset_right = -10
	scroll_container.offset_bottom = -10
	
	# Create a GridContainer and assign it to item_container
	item_container = GridContainer.new()
	item_container.columns = 5  # Adjust based on how many items per row you want
	
	# Add to scroll container and scene
	scroll_container.add_child(item_container)
	add_child(scroll_container)
	
	# Enable vertical scrolling for grid layout
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

func create_close_button():
	close_button = Button.new()
	close_button.pressed.connect(_on_close_pressed)
	close_button.text = "X"
	
	# Use set_anchors_and_offsets_preset for cleaner positioning
	close_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	
	# Add to scene tree
	add_child(close_button)
	
func _on_close_pressed():
	hide_menu()
	inventory_closed.emit()

func ready_post():
	pass  # overridden in child
