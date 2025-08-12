# ItemFactory.gd - For creating test items
extends Node
class_name ItemFactory

static func create_test_equipment() -> Array:
	"""Create test equipment items"""
	var items = []
	
	# Test Sword
	var test_sword = EquipmentItem.new()
	test_sword.item_id = "test_sword"
	test_sword.item_name = "Test Sword"
	test_sword.description = "A basic sword for testing"
	test_sword.item_type = BaseItem.ItemType.EQUIPMENT
	test_sword.compatible_slots.append(EquipmentSlot.SlotType.MAIN_HAND)
	test_sword.stat_modifiers = {"Attack": 10}
	test_sword.rarity = BaseItem.ItemRarity.COMMON
	test_sword.value = 50
	items.append(test_sword)
	
	# Test Helmet
	var test_helmet = EquipmentItem.new()
	test_helmet.item_id = "test_helmet"
	test_helmet.item_name = "Test Helmet"
	test_helmet.description = "A protective helmet for testing"
	test_helmet.item_type = BaseItem.ItemType.EQUIPMENT
	test_helmet.compatible_slots.append(EquipmentSlot.SlotType.HELMET)
	test_helmet.stat_modifiers = {"Defense": 5, "Health": 15}
	test_helmet.rarity = BaseItem.ItemRarity.UNCOMMON
	test_helmet.value = 30
	items.append(test_helmet)
	
	# Test Shield
	var test_shield = EquipmentItem.new()
	test_shield.item_id = "test_shield"
	test_shield.item_name = "Test Shield"
	test_shield.description = "A sturdy shield for testing"
	test_shield.item_type = BaseItem.ItemType.EQUIPMENT
	test_shield.compatible_slots.append(EquipmentSlot.SlotType.OFF_HAND)
	test_shield.stat_modifiers = {"Defense": 8}
	test_shield.rarity = BaseItem.ItemRarity.COMMON
	test_shield.value = 40
	items.append(test_shield)
	
	return items

static func create_test_consumables() -> Array:
	"""Create test consumable items"""
	var items = []
	
	# Health Potion
	var health_potion = ConsumableItem.new()
	health_potion.item_id = "health_potion"
	health_potion.item_name = "Health Potion"
	health_potion.description = "Restores 50 health instantly"
	health_potion.consumable_type = ConsumableItem.ConsumableType.HEALTH_POTION
	health_potion.effect_stats = {"Health": 50}
	health_potion.rarity = BaseItem.ItemRarity.COMMON
	health_potion.value = 25
	health_potion.stack_size = 20
	items.append(health_potion)
	
	# Strength Boost
	var strength_boost = ConsumableItem.new()
	strength_boost.item_id = "strength_boost"
	strength_boost.item_name = "Strength Elixir"
	strength_boost.description = "Temporarily increases attack by 5 for 60 seconds"
	strength_boost.consumable_type = ConsumableItem.ConsumableType.STAT_BOOST
	strength_boost.effect_stats = {"Attack": 5}
	strength_boost.duration = 60.0
	strength_boost.rarity = BaseItem.ItemRarity.UNCOMMON
	strength_boost.value = 75
	strength_boost.stack_size = 10
	items.append(strength_boost)
	
	# Food Item
	var bread = ConsumableItem.new()
	bread.item_id = "bread"
	bread.item_name = "Fresh Bread"
	bread.description = "Restores 20 health and satisfies hunger"
	bread.consumable_type = ConsumableItem.ConsumableType.FOOD
	bread.effect_stats = {"Health": 20}
	bread.rarity = BaseItem.ItemRarity.COMMON
	bread.value = 5
	bread.stack_size = 50
	items.append(bread)
	
	return items

static func create_test_misc_items() -> Array:
	"""Create test miscellaneous items"""
	var items = []
	
	# Crafting Material
	var iron_ore = BaseItem.new()
	iron_ore.item_id = "iron_ore"
	iron_ore.item_name = "Iron Ore"
	iron_ore.description = "Raw iron ore used for crafting"
	iron_ore.item_type = BaseItem.ItemType.CRAFTING
	iron_ore.rarity = BaseItem.ItemRarity.COMMON
	iron_ore.value = 10
	iron_ore.stack_size = 100
	items.append(iron_ore)
	
	# Quest Item
	var ancient_key = BaseItem.new()
	ancient_key.item_id = "ancient_key"
	ancient_key.item_name = "Ancient Key"
	ancient_key.description = "A mysterious key from a forgotten age"
	ancient_key.item_type = BaseItem.ItemType.QUEST
	ancient_key.rarity = BaseItem.ItemRarity.RARE
	ancient_key.value = 0
	ancient_key.stack_size = 1
	ancient_key.is_droppable = false
	items.append(ancient_key)
	
	return items

static func get_all_test_items() -> Array:
	"""Get all test items"""
	var all_items = []
	all_items.append_array(create_test_equipment())
	all_items.append_array(create_test_consumables())
	all_items.append_array(create_test_misc_items())
	return all_items
