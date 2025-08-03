extends Control
class_name InventoryMenu

signal inventory_closed

#@onready var close_button = get_node("CloseButton")
#@onready var item_container = get_node("HBoxContainer")
var item_container: GridContainer
var close_button: Button

func _ready():
	self.visible = false
	
	
	resize_to_screen()
	create_close_button()
	
	create_background_panel()
	create_grid_container()
	populate_inventory(["Sword", "Potion", "Book", "Shield", "Bow", "Arrow", "Helmet", "Boots", "Ring", "Necklace"])

#Fit to screen size
func resize_to_screen():
	var screen_size = get_viewport().get_visible_rect().size
	var target_size = screen_size * 0.5
	size = target_size
	pivot_offset = size / 2
	position = screen_size / 5  # center on screen

#Create child objects
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
	move_child(panel, 0)  # Ensure it's drawn first (at the back)nd)

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
	item_container.columns = 4  # Adjust based on how many items per row you want
	
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
	self.hide()
	inventory_closed.emit()

#For testing 
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
