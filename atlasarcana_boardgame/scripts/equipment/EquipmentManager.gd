# EquipmentManager.gd
extends Node
class_name EquipmentManager

signal equipment_changed(slot_type: EquipmentSlot.SlotType, old_item: EquipmentItem, new_item: EquipmentItem)
signal stats_recalculated(new_stats: Dictionary)

var equipment_slots: Dictionary = {}
var character_stats: EnhancedCharacterStats

func _init():
	initialize_equipment_slots()

func initialize_equipment_slots():
	"""Initialize all equipment slots"""
	for slot_type in EquipmentSlot.SlotType.values():
		var slot = EquipmentSlot.new()
		slot.slot_type = slot_type
		slot.slot_name = get_slot_display_name(slot_type)
		equipment_slots[slot_type] = slot

func get_slot_display_name(slot_type: EquipmentSlot.SlotType) -> String:
	match slot_type:
		EquipmentSlot.SlotType.MAIN_HAND:
			return "Main Hand"
		EquipmentSlot.SlotType.OFF_HAND:
			return "Off Hand"
		EquipmentSlot.SlotType.HELMET:
			return "Helmet"
		EquipmentSlot.SlotType.CHEST:
			return "Chest"
		EquipmentSlot.SlotType.LEGS:
			return "Legs"
		EquipmentSlot.SlotType.HANDS:
			return "Hands"
		EquipmentSlot.SlotType.FEET:
			return "Feet"
		EquipmentSlot.SlotType.RING_1:
			return "Ring 1"
		EquipmentSlot.SlotType.RING_2:
			return "Ring 2"
		EquipmentSlot.SlotType.NECKLACE:
			return "Necklace"
		EquipmentSlot.SlotType.BELT:
			return "Belt"
		_:
			return "Unknown"

func set_character_stats(stats: EnhancedCharacterStats):
	"""Set the character stats reference for automatic updates"""
	character_stats = stats

func equip_item(item: EquipmentItem, slot_type: EquipmentSlot.SlotType) -> bool:
	"""Equip an item to a specific slot"""
	if not equipment_slots.has(slot_type):
		return false
		
	var slot = equipment_slots[slot_type]
	if not slot.can_equip(item):
		return false
	
	var old_item = slot.equip_item(item)
	equipment_changed.emit(slot_type, old_item, item)
	
	if character_stats:
		character_stats.recalculate_stats()
	
	return true

func unequip_item(slot_type: EquipmentSlot.SlotType) -> EquipmentItem:
	"""Unequip an item from a specific slot"""
	if not equipment_slots.has(slot_type):
		return null
		
	var slot = equipment_slots[slot_type]
	var old_item = slot.unequip_item()
	
	if old_item:
		equipment_changed.emit(slot_type, old_item, null)
		
		if character_stats:
			character_stats.recalculate_stats()
	
	return old_item

func get_equipped_item(slot_type: EquipmentSlot.SlotType) -> EquipmentItem:
	"""Get the item equipped in a specific slot"""
	if equipment_slots.has(slot_type):
		return equipment_slots[slot_type].equipped_item
	return null

func get_all_equipped_items() -> Dictionary:
	"""Get all equipped items as a dictionary"""
	var equipped = {}
	for slot_type in equipment_slots:
		var item = equipment_slots[slot_type].equipped_item
		if item:
			equipped[slot_type] = item
	return equipped

func get_total_stat_modifiers() -> Dictionary:
	"""Calculate total stat modifiers from all equipped items"""
	var total_modifiers = {}
	
	for slot_type in equipment_slots:
		var item = equipment_slots[slot_type].equipped_item
		if item:
			var item_mods = item.get_all_stat_modifiers()
			for stat_name in item_mods:
				if not total_modifiers.has(stat_name):
					total_modifiers[stat_name] = 0
				total_modifiers[stat_name] += item_mods[stat_name]
	
	return total_modifiers

func get_equipment_slot(slot_type: EquipmentSlot.SlotType) -> EquipmentSlot:
	"""Get a specific equipment slot"""
	return equipment_slots.get(slot_type)

func get_all_equipment_slots() -> Dictionary:
	"""Get all equipment slots"""
	return equipment_slots.duplicate()

func can_equip_item(item: EquipmentItem, slot_type: EquipmentSlot.SlotType) -> bool:
	"""Check if an item can be equipped to a specific slot"""
	if not equipment_slots.has(slot_type):
		return false
	return equipment_slots[slot_type].can_equip(item)
