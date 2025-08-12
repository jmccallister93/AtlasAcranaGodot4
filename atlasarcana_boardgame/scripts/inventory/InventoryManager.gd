# InventoryManager.gd
extends Node
class_name InventoryManager

signal inventory_changed(slot_index: int)
signal item_added(item: BaseItem, amount: int)
signal item_removed(item: BaseItem, amount: int)
signal item_used(item: BaseItem)
signal inventory_full()

@export var max_slots: int = 40
var inventory_slots: Array = []
var character: Character

func _init():
	initialize_inventory()

func initialize_inventory():
	"""Initialize empty inventory slots"""
	inventory_slots.clear()
	for i in range(max_slots):
		var slot = InventorySlot.new()
		inventory_slots.append(slot)

func set_character(char: Character):
	"""Set the character reference"""
	character = char

func add_item(item: BaseItem, amount: int = 1) -> bool:
	"""Add item to inventory, returns true if successful"""
	var remaining_amount = amount
	
	# First try to stack with existing items
	if item.can_stack():
		for i in range(inventory_slots.size()):
			var slot = inventory_slots[i]
			if not slot.is_empty() and slot.item.item_id == item.item_id:
				remaining_amount = slot.add_item(item, remaining_amount)
				inventory_changed.emit(i)
				
				if remaining_amount <= 0:
					item_added.emit(item, amount)
					return true
	
	# Then try to add to empty slots
	for i in range(inventory_slots.size()):
		var slot = inventory_slots[i]
		if slot.is_empty():
			remaining_amount = slot.add_item(item, remaining_amount)
			inventory_changed.emit(i)
			
			if remaining_amount <= 0:
				item_added.emit(item, amount)
				return true
	
	# If we get here, inventory is full
	if remaining_amount < amount:
		item_added.emit(item, amount - remaining_amount)
	
	inventory_full.emit()
	return remaining_amount <= 0

func remove_item(item_id: String, amount: int = 1) -> int:
	"""Remove item from inventory, returns amount actually removed"""
	var removed_amount = 0
	var remaining_to_remove = amount
	
	for i in range(inventory_slots.size()):
		var slot = inventory_slots[i]
		if not slot.is_empty() and slot.item.item_id == item_id:
			var removed_from_slot = slot.remove_item(remaining_to_remove)
			removed_amount += removed_from_slot
			remaining_to_remove -= removed_from_slot
			inventory_changed.emit(i)
			
			if remaining_to_remove <= 0:
				break
	
	if removed_amount > 0:
		# Get the item for the signal (from first non-empty slot)
		var sample_item = get_item_by_id(item_id)
		if sample_item:
			item_removed.emit(sample_item, removed_amount)
	
	return removed_amount

func get_item_by_id(item_id: String) -> BaseItem:
	"""Get the first item with the given ID"""
	for slot in inventory_slots:
		if not slot.is_empty() and slot.item.item_id == item_id:
			return slot.item
	return null

func get_item_count(item_id: String) -> int:
	"""Get total count of an item in inventory"""
	var total = 0
	for slot in inventory_slots:
		if not slot.is_empty() and slot.item.item_id == item_id:
			total += slot.quantity
	return total

func has_item(item_id: String, amount: int = 1) -> bool:
	"""Check if inventory contains enough of an item"""
	return get_item_count(item_id) >= amount

func use_item_at_slot(slot_index: int) -> bool:
	"""Use an item at a specific slot"""
	if slot_index < 0 or slot_index >= inventory_slots.size():
		return false
	
	var slot = inventory_slots[slot_index]
	if slot.is_empty():
		return false
	
	var item = slot.item
	
	# Only consumables can be used
	if item.item_type != BaseItem.ItemType.CONSUMABLE:
		return false
	
	if not character:
		print("No character reference set")
		return false
	
	# Use the item
	if item.use_item(character):
		slot.remove_item(1)
		inventory_changed.emit(slot_index)
		item_used.emit(item)
		return true
	
	return false

func equip_item_at_slot(slot_index: int) -> bool:
	"""Equip an item from inventory"""
	if slot_index < 0 or slot_index >= inventory_slots.size():
		return false
	
	var slot = inventory_slots[slot_index]
	if slot.is_empty():
		return false
	
	var item = slot.item
	
	# Only equipment can be equipped
	if item.item_type != BaseItem.ItemType.EQUIPMENT:
		return false
	
	if not character or not character.equipment_manager:
		print("No character or equipment manager reference")
		return false
	
	# Try to equip the item
	var equipment_item = item as EquipmentItem
	if not equipment_item:
		return false
	
	# Find a compatible slot
	for slot_type in equipment_item.compatible_slots:
		if character.equipment_manager.can_equip_item(equipment_item, slot_type):
			# Unequip any existing item first
			var old_item = character.equipment_manager.unequip_item(slot_type)
			if old_item:
				add_item(old_item, 1)
			
			# Equip the new item
			if character.equipment_manager.equip_item(equipment_item, slot_type):
				slot.remove_item(1)
				inventory_changed.emit(slot_index)
				return true
			else:
				# Re-equip the old item if equipping failed
				if old_item:
					character.equipment_manager.equip_item(old_item, slot_type)
					remove_item(old_item.item_id, 1)
	
	return false

func drop_item_at_slot(slot_index: int, amount: int = 1) -> bool:
	"""Drop an item from inventory"""
	if slot_index < 0 or slot_index >= inventory_slots.size():
		return false
	
	var slot = inventory_slots[slot_index]
	if slot.is_empty():
		return false
	
	if not slot.item.is_droppable:
		return false
	
	var removed_amount = slot.remove_item(amount)
	if removed_amount > 0:
		inventory_changed.emit(slot_index)
		item_removed.emit(slot.item, removed_amount)
		#print("Dropped ", removed_amount, "x ", slot.item.item_name)
		return true
	
	return false

func get_slot(index: int) -> InventorySlot:
	"""Get inventory slot by index"""
	if index >= 0 and index < inventory_slots.size():
		return inventory_slots[index]
	return null

func get_all_items() -> Array:
	"""Get all non-empty slots"""
	var items = []
	for slot in inventory_slots:
		if not slot.is_empty():
			items.append(slot)
	return items

func get_items_by_type(item_type: BaseItem.ItemType) -> Array:
	"""Get all items of a specific type"""
	var items = []
	for slot in inventory_slots:
		if not slot.is_empty() and slot.item.item_type == item_type:
			items.append(slot)
	return items

func is_full() -> bool:
	"""Check if inventory is full"""
	for slot in inventory_slots:
		if slot.is_empty():
			return false
	return true

func get_empty_slot_count() -> int:
	"""Get number of empty slots"""
	var count = 0
	for slot in inventory_slots:
		if slot.is_empty():
			count += 1
	return count
