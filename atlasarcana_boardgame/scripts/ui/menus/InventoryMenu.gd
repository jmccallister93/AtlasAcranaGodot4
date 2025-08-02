extends Control
class_name InventoryMenu

signal inventory_closed

@onready var close_button = get_node("CloseButton")
@onready var item_container = get_node("BoxContainer/HBoxContainer")
#@onready var background_rect = get_node("Background")

func _ready():
	self.visible = false
	close_button.pressed.connect(_on_close_pressed)
	
	resize_to_screen()
	setup_close_button()
	create_background_panel()
	populate_inventory(["Sword", "Potion", "Book"])


func _on_close_pressed():
	self.hide()
	inventory_closed.emit()

func resize_to_screen():
	var screen_size = get_viewport().get_visible_rect().size
	var target_size = screen_size * 0.5
	size = target_size
	pivot_offset = size / 2
	position = screen_size / 5  # center on screen
	
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
	#style.border_width_all = 4
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10

	panel.add_theme_stylebox_override("panel", style)

	# Add and send to back
	add_child(panel)
	move_child(panel, 0)  # Ensure it's drawn first (at the back)nd)



func setup_close_button():
	close_button.text = "Close Me"
	# Anchor top-right
	close_button.anchor_left = 0.0
	close_button.anchor_top = 0.0
	close_button.anchor_right = 0.0
	close_button.anchor_bottom = 0.0

	# Size of button (optional)
	close_button.custom_minimum_size = Vector2(40, 40)  # adjust as needed

	# Position offset (from top-right corner inward)
	close_button.position = Vector2(200, 10)  # 10px down, 110px left from right edge
	
func populate_inventory(item_names: Array):
	# Clear existing items
	for child in item_container.get_children():
		child.queue_free()

	# Create new labels dynamically
	for name in item_names:
		var label = Label.new()
		label.text = name
		label.add_theme_color_override("font_color", Color.BLUE)
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color.LIGHT_BLUE
		label.add_theme_stylebox_override("normal", stylebox)
		item_container.add_child(label)
