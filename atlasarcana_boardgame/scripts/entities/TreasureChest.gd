## TreasureChest.gd - Example of extending InteractableEntity
#extends InteractableEntity
#class_name TreasureChest
#
## Treasure-specific properties
#@export var gold_amount: int = 10
#@export var has_been_opened: bool = false
#@export var chest_color: Color = Color.GOLD
#
#func _ready():
	## Set basic properties
	#entity_type = "treasure_chest"
	#interaction_name = "Open Chest"
	#interaction_cost = 1
	#max_uses = 1  # Can only be opened once
	#
	#super._ready()
#
#func create_visual_component():
	#"""Create treasure chest visual"""
	#visual_component = Node2D.new()
	#visual_component.name = "ChestVisual"
	#add_child(visual_component)
	#
	## Chest body
	#var chest_body = ColorRect.new()
	#chest_body.size = Vector2(28, 20)
	#chest_body.position = Vector2(-14, -10)
	#chest_body.color = chest_color
	#chest_body.z_index = 12
	#visual_component.add_child(chest_body)
	#
	## Chest lid (slightly different color)
	#var chest_lid = ColorRect.new()
	#chest_lid.size = Vector2(28, 8)
	#chest_lid.position = Vector2(-14, -18)
	#chest_lid.color = chest_color.darkened(0.2)
	#chest_lid.z_index = 13
	#visual_component.add_child(chest_lid)
	#
	## Small highlight to make it look more like a chest
	#var highlight = ColorRect.new()
	#highlight.size = Vector2(24, 2)
	#highlight.position = Vector2(-12, -16)
	#highlight.color = Color.WHITE
	#highlight.z_index = 14
	#visual_component.add_child(highlight)
#
#func perform_interaction(character: Character) -> Dictionary:
	#"""Open the treasure chest and give gold to character"""
	#if has_been_opened:
		#return {
			#"success": false,
			#"message": "This chest has already been opened."
		#}
	#
	#has_been_opened = true
	#
	## Change visual to show opened chest
	#update_visual_for_opened_state()
	#
	## Give gold to character (this would connect to your resource system)
	#return {
		#"success": true,
		#"message": "You opened the treasure chest and found " + str(gold_amount) + " gold!",
		#"effects": {"gold": gold_amount}
	#}
#
#func update_visual_for_opened_state():
	#"""Update the chest visual to show it's been opened"""
	#if visual_component:
		## Make the chest appear darker/grayed out
		#for child in visual_component.get_children():
			#if child is ColorRect:
				#child.color = child.color.darkened(0.5)
#
#func can_interact(character: Character) -> bool:
	#"""Override to add chest-specific logic"""
	#if has_been_opened:
		#return false
	#
	#return super.can_interact(character)
#
#func get_description() -> String:
	#"""Get description for this chest"""
	#if has_been_opened:
		#return "An empty treasure chest."
	#else:
		#return "A golden treasure chest that might contain riches!"
#
## Static method to create treasure chests easily
#static func create_chest(position: Vector2i, gold: int = 10, color: Color = Color.GOLD) -> TreasureChest:
	#"""Create a treasure chest with specified properties"""
	#var chest = TreasureChest.new()
	#chest.gold_amount = gold
	#chest.chest_color = color
	#return chest
