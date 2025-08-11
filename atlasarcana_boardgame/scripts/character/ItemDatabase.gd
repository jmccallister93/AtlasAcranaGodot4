# ItemDatabase.gd - For creating predefined items
extends Node
class_name ItemDatabase

static var items: Dictionary = {}

static func initialize():
	"""Initialize the item database with predefined items"""
	create_weapons()
	create_armor()
	create_accessories()

static func create_weapons():
	"""Create weapon items"""
	# Iron Sword
	var iron_sword = EquipmentItem.new()
	iron_sword.item_id = "iron_sword"
	iron_sword.item_name = "Iron Sword"
	iron_sword.description = "A sturdy iron sword. Reliable and sharp."
	iron_sword.compatible_slots = [EquipmentSlot.SlotType.MAIN_HAND]
	iron_sword.stat_modifiers = {"Attack": 8, "Critical_Chance": 2}
	iron_sword.level_requirement = 1
	items["iron_sword"] = iron_sword
	
	# Steel Sword
	var steel_sword = EquipmentItem.new()
	steel_sword.item_id = "steel_sword"
	steel_sword.item_name = "Steel Sword"
	steel_sword.description = "A finely crafted steel sword with superior balance."
	steel_sword.compatible_slots = [EquipmentSlot.SlotType.MAIN_HAND]
	steel_sword.stat_modifiers = {"Attack": 12, "Critical_Chance": 3}
	steel_sword.rarity = EquipmentItem.ItemRarity.UNCOMMON
	steel_sword.level_requirement = 3
	items["steel_sword"] = steel_sword

static func create_armor():
	"""Create armor items"""
	# Leather Helmet
	var leather_helmet = EquipmentItem.new()
	leather_helmet.item_id = "leather_helmet"
	leather_helmet.item_name = "Leather Helmet"
	leather_helmet.description = "Basic protection for your head."
	leather_helmet.compatible_slots = [EquipmentSlot.SlotType.HELMET]
	leather_helmet.stat_modifiers = {"Defense": 2, "Health": 5}
	items["leather_helmet"] = leather_helmet
	
	# Iron Chestplate
	var iron_chestplate = EquipmentItem.new()
	iron_chestplate.item_id = "iron_chestplate"
	iron_chestplate.item_name = "Iron Chestplate"
	iron_chestplate.description = "Heavy iron armor that provides excellent protection."
	iron_chestplate.compatible_slots = [EquipmentSlot.SlotType.CHEST]
	iron_chestplate.stat_modifiers = {"Defense": 8, "Health": 15}
	iron_chestplate.rarity = EquipmentItem.ItemRarity.UNCOMMON
	items["iron_chestplate"] = iron_chestplate

static func create_accessories():
	"""Create accessory items"""
	# Power Ring
	var power_ring = EquipmentItem.new()
	power_ring.item_id = "power_ring"
	power_ring.item_name = "Ring of Power"
	power_ring.description = "A magical ring that enhances the wearer's combat prowess."
	power_ring.compatible_slots = [EquipmentSlot.SlotType.RING_1, EquipmentSlot.SlotType.RING_2]
	power_ring.stat_modifiers = {"Attack": 3, "Critical_Damage": 5}
	power_ring.rarity = EquipmentItem.ItemRarity.RARE
	items["power_ring"] = power_ring
	
	# Leadership Amulet
	var leadership_amulet = EquipmentItem.new()
	leadership_amulet.item_id = "leadership_amulet"
	leadership_amulet.item_name = "Amulet of Leadership"
	leadership_amulet.description = "An ancient amulet that inspires loyalty in followers."
	leadership_amulet.compatible_slots = [EquipmentSlot.SlotType.NECKLACE]
	leadership_amulet.stat_modifiers = {"Leadership": 5, "Morale_Bonus": 3}
	leadership_amulet.rarity = EquipmentItem.ItemRarity.EPIC
	items["leadership_amulet"] = leadership_amulet

static func get_item(item_id: String) -> EquipmentItem:
	"""Get an item by ID"""
	return items.get(item_id)

static func get_all_items() -> Array[EquipmentItem]:
	"""Get all items"""
	var item_array: Array[EquipmentItem] = []
	for item in items.values():
		item_array.append(item)
	return item_array

static func create_random_item(level: int = 1) -> EquipmentItem:
	"""Create a random item appropriate for the given level"""
	var available_items: Array[EquipmentItem] = []
	
	for item in items.values():
		if item.level_requirement <= level:
			available_items.append(item)
	
	if available_items.size() > 0:
		return available_items[randi() % available_items.size()]
	
	return null
