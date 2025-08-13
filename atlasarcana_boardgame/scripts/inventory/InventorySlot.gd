# InventorySlot.gd
extends Resource
class_name InventorySlot

@export var item: BaseItem
@export var quantity: int = 0

func is_empty() -> bool:
	return item == null or quantity <= 0

func can_add_item(new_item: BaseItem, amount: int = 1) -> bool:
	if is_empty():
		return true
	
	# Can only stack if same item and item allows stacking
	if item.item_id == new_item.item_id and item.can_stack():
		return quantity + amount <= item.stack_size
	
	return false

func add_item(new_item: BaseItem, amount: int = 1) -> int:
	"""Add item to slot, returns amount that couldn't be added"""
	if is_empty():
		item = new_item
		quantity = min(amount, new_item.stack_size)
		return amount - quantity
	
	if item.item_id == new_item.item_id and item.can_stack():
		var space_available = item.stack_size - quantity
		var amount_to_add = min(amount, space_available)
		quantity += amount_to_add
		return amount - amount_to_add
	
	return amount  # Couldn't add any

func remove_item(amount: int) -> int:
	"""Remove items from slot, returns actual amount removed"""
	if is_empty():
		return 0
	
	var amount_to_remove = min(amount, quantity)
	quantity -= amount_to_remove
	
	# Clear the slot if empty
	if quantity <= 0:
		item = null
		quantity = 0
	
	return amount_to_remove

func get_display_name() -> String:
	if is_empty():
		return ""
	
	var display = item.item_name
	if quantity > 1:
		display += " (" + str(quantity) + ")"
	
	return display
