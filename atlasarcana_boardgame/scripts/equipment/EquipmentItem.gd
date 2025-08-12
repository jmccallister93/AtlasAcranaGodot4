# EquipmentItem.gd
extends BaseItem
class_name EquipmentItem

@export var compatible_slots: Array = []
@export var stat_modifiers: Dictionary = {}
@export var special_effects: Array = []


func _init():

	item_type = BaseItem.ItemType.EQUIPMENT
	stack_size = 1  # Equipment doesn't stack

func can_fit_in_slot(slot_type: EquipmentSlot.SlotType) -> bool:
	return slot_type in compatible_slots

func get_stat_modifier(stat_name: String) -> int:
	return stat_modifiers.get(stat_name, 0)

func get_all_stat_modifiers() -> Dictionary:
	return stat_modifiers.duplicate()

func get_available_actions() -> Array:
	var actions = super.get_available_actions()
	actions.insert(0, "equip")  # Add equip action
	return actions

func get_tooltip_text() -> String:
	var tooltip = super.get_tooltip_text()
	
	# Add equipment-specific info
	if stat_modifiers.size() > 0:
		tooltip += "\n[color=lightgreen][b]Stats:[/b][/color]\n"
		for stat_name in stat_modifiers:
			var modifier = stat_modifiers[stat_name]
			tooltip += "• " + stat_name.replace("_", " ") + ": +"
			tooltip += str(modifier) + "\n"
	
	if special_effects.size() > 0:
		tooltip += "\n[color=cyan][b]Special Effects:[/b][/color]\n"
		for effect in special_effects:
			tooltip += "• " + effect + "\n"
	
	return tooltip
