extends CanvasLayer
class_name InventoryMenu

signal inventory_closed

@onready var close_button = get_node("BoxContainer/HBoxContainer/CloseButton")

func _ready():
	self.visible = false
	close_button.pressed.connect(_on_close_pressed)

func _on_close_pressed():
	self.hide()
	inventory_closed.emit()
