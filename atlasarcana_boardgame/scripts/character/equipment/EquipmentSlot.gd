# EquipmentSlot.gd
extends Resource
class_name EquipmentSlot

enum SlotType {
	MAIN_HAND,
	OFF_HAND,
	HELMET,
	CHEST,
	LEGS,
	HANDS,
	FEET,
	RING_1,
	RING_2,
	NECKLACE,
	BELT
}

@export var slot_type: SlotType
@export var slot_name: String
@export var equipped_item: EquipmentItem
@export var is_locked: bool = false  # For progression systems

func can_equip(item: EquipmentItem) -> bool:
	if is_locked:
		return false
	return item != null and item.can_fit_in_slot(slot_type)

func equip_item(item: EquipmentItem) -> EquipmentItem:
	var previous_item = equipped_item
	equipped_item = item
	return previous_item

func unequip_item() -> EquipmentItem:
	var item = equipped_item
	equipped_item = null
	return item

func is_empty() -> bool:
	return equipped_item == null
