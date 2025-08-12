# ConsumableItem.gd  
extends BaseItem
class_name ConsumableItem

enum ConsumableType {
	HEALTH_POTION,
	MANA_POTION,
	STAT_BOOST,
	FOOD,
	SCROLL,
	MISC
}

@export var consumable_type: ConsumableType = ConsumableType.MISC
@export var effect_stats: Dictionary = {}  # stat_name -> amount
@export var duration: float = 0.0  # 0 = instant, >0 = temporary effect
@export var cooldown: float = 0.0  # Cooldown before can use again
@export var use_sound: String = ""  # Sound effect when used

func _init():
	item_type = ItemType.CONSUMABLE
	stack_size = 50  # Most consumables stack

func use_item(character: Character) -> bool:
	"""Use the consumable item"""
	if not can_use_on_character(character):
		return false
	
	apply_effects(character)
	return true

func can_use_on_character(character: Character) -> bool:
	"""Check if this consumable can be used on the character"""
	if character.stats.character_level < level_requirement:
		return false
	
	# Add specific consumable checks here
	match consumable_type:
		ConsumableType.HEALTH_POTION:
			return character.current_health < character.get_max_health()
		ConsumableType.MANA_POTION:
			# Would check mana if you have it
			return true
		_:
			return true

func apply_effects(character: Character):
	"""Apply the consumable's effects to the character"""
	match consumable_type:
		ConsumableType.HEALTH_POTION:
			var heal_amount = effect_stats.get("Health", 0)
			character.heal(heal_amount)
			print("Healed for ", heal_amount, " health")
		
		ConsumableType.STAT_BOOST:
			# Apply temporary stat boosts
			for stat_name in effect_stats:
				var boost_amount = effect_stats[stat_name]
				apply_temporary_stat_boost(character, stat_name, boost_amount)
		
		ConsumableType.FOOD:
			# Food might restore health and give temporary buffs
			var health_restore = effect_stats.get("Health", 0)
			if health_restore > 0:
				character.heal(health_restore)
		
		_:
			print("Used ", item_name, " with effects: ", effect_stats)

func apply_temporary_stat_boost(character: Character, stat_name: String, amount: int):
	"""Apply a temporary stat boost (you'd need to implement this in your stats system)"""
	print("Applied temporary boost: +", amount, " ", stat_name, " for ", duration, " seconds")
	# This would integrate with your enhanced character stats system

func get_available_actions() -> Array:
	var actions = super.get_available_actions()
	actions.insert(0, "use")  # Add use action at the beginning
	return actions

func get_tooltip_text() -> String:
	var tooltip = super.get_tooltip_text()
	
	if effect_stats.size() > 0:
		tooltip += "\n[color=lightgreen][b]Effects:[/b][/color]\n"
		for stat_name in effect_stats:
			var amount = effect_stats[stat_name]
			tooltip += "• " + stat_name + ": +" + str(amount)
			if duration > 0:
				tooltip += " for " + str(duration) + "s"
			tooltip += "\n"
	
	if cooldown > 0:
		tooltip += "\n[color=orange]Cooldown: " + str(cooldown) + "s[/color]"
	
	return tooltip
