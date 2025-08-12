# BaseItem.gd
extends Resource
class_name BaseItem

enum ItemType {
	EQUIPMENT,
	CONSUMABLE,
	MISC,
	QUEST,
	CRAFTING
}

enum ItemRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export var item_id: String
@export var item_name: String
@export var description: String
@export var icon_path: String
@export var item_type: ItemType = ItemType.MISC
@export var rarity: ItemRarity = ItemRarity.COMMON
@export var level_requirement: int = 1
@export var stack_size: int = 1  # How many can stack in one slot
@export var value: int = 0  # Gold value for selling
@export var is_tradeable: bool = true
@export var is_droppable: bool = true

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

func get_type_name() -> String:
	match item_type:
		ItemType.EQUIPMENT:
			return "Equipment"
		ItemType.CONSUMABLE:
			return "Consumable"
		ItemType.MISC:
			return "Miscellaneous"
		ItemType.QUEST:
			return "Quest Item"
		ItemType.CRAFTING:
			return "Crafting Material"
		_:
			return "Unknown"

func can_stack() -> bool:
	return stack_size > 1

func get_tooltip_text() -> String:
	var tooltip = "[b]" + item_name + "[/b]\n"
	tooltip += "[color=gray]" + get_type_name() + "[/color]\n\n"
	tooltip += description + "\n\n"
	
	if level_requirement > 1:
		tooltip += "[color=yellow]Requires Level " + str(level_requirement) + "[/color]\n"
	
	if value > 0:
		tooltip += "[color=gold]Value: " + str(value) + " gold[/color]\n"
	
	return tooltip

# Virtual methods to override in subclasses
func use_item(character: Character) -> bool:
	print("Base item cannot be used")
	return false

func get_available_actions() -> Array:
	var actions = ["examine"]
	if is_droppable:
		actions.append("drop")
	return actions
