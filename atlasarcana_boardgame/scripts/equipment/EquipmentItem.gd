# EquipmentItem.gd
extends Resource
class_name EquipmentItem

@export var item_id: String
@export var item_name: String
@export var description: String
@export var icon_path: String
@export var rarity: ItemRarity = ItemRarity.COMMON
@export var level_requirement: int = 1

# What slots this item can fit into
@export var compatible_slots: Array[EquipmentSlot.SlotType] = []

# Stat modifiers this item provides
@export var stat_modifiers: Dictionary = {}

# Special effects or abilities
@export var special_effects: Array[String] = []

enum ItemRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

func can_fit_in_slot(slot_type: EquipmentSlot.SlotType) -> bool:
	return slot_type in compatible_slots

func get_stat_modifier(stat_name: String) -> int:
	return stat_modifiers.get(stat_name, 0)

func get_all_stat_modifiers() -> Dictionary:
	return stat_modifiers.duplicate()

func get_rarity_color() -> Color:
	match rarity:
		ItemRarity.COMMON:
			return Color.WHITE
		ItemRarity.UNCOMMON:
			return Color.GREEN
		ItemRarity.RARE:
			return Color.BLUE
		ItemRarity.EPIC:
			return Color.PURPLE
		ItemRarity.LEGENDARY:
			return Color.ORANGE
		_:
			return Color.WHITE
