# InteractableEntity.gd - More configurable version
extends Node2D
class_name InteractableEntity

# Signals for interaction events
signal interacted_with(entity: InteractableEntity, character: Character)
signal interaction_attempted(entity: InteractableEntity)

# Entity properties
@export var entity_type: String = "generic"
@export var interaction_name: String = "Interact"
@export var can_be_interacted_with: bool = true
@export var interaction_cost: int = 1  # Action points needed
@export var max_uses: int = -1  # -1 means infinite uses
@export var current_uses: int = 0

# Visual configuration
@export var visual_color: Color = Color.CYAN
@export var visual_size: Vector2 = Vector2(20, 20)
@export var visual_shape: String = "rectangle"  # "rectangle", "circle", "custom"

# Interaction configuration
@export var interaction_message: String = ""
@export var interaction_effects: Dictionary = {}

# Position and visual
var grid_position: Vector2i
var visual_component: Node2D
var interaction_radius: int = 1  # Usually 1 for adjacent interaction

func _ready():
	create_visual_component()
	setup_interaction_area()

func create_visual_component():
	"""Create the visual representation based on configuration"""
	visual_component = Node2D.new()
	visual_component.name = "VisualComponent"
	add_child(visual_component)
	
	match visual_shape:
		"rectangle":
			create_rectangle_visual()
		"circle":
			create_circle_visual()
		"custom":
			create_custom_visual()
		_:
			create_rectangle_visual()

func create_rectangle_visual():
	"""Create a rectangular visual"""
	var visual = ColorRect.new()
	visual.size = visual_size
	visual.position = Vector2(-visual_size.x/2, -visual_size.y/2)
	visual.color = visual_color
	visual.z_index = 12
	visual_component.add_child(visual)

func create_circle_visual():
	"""Create a circular visual (using TextureRect with circular texture or ColorRect)"""
	# For now, create a smaller square that looks more circular
	var visual = ColorRect.new()
	var circle_size = min(visual_size.x, visual_size.y)
	visual.size = Vector2(circle_size, circle_size)
	visual.position = Vector2(-circle_size/2, -circle_size/2)
	visual.color = visual_color
	visual.z_index = 12
	visual_component.add_child(visual)

func create_custom_visual():
	"""Override this in subclasses for custom visuals"""
	create_rectangle_visual()  # Fallback to rectangle

func setup_interaction_area():
	"""Setup any additional interaction components"""
	# This can be overridden by subclasses to add collision areas, etc.
	pass

func can_interact(character: Character) -> bool:
	"""Check if this entity can be interacted with by the character"""
	if not can_be_interacted_with:
		return false
	
	# Check if character has enough action points
	if character.current_action_points < interaction_cost:
		return false
	
	# Check if entity has uses remaining
	if max_uses > 0 and current_uses >= max_uses:
		return false
	
	# Check distance (usually handled by InteractManager, but can double-check here)
	var distance = abs(grid_position.x - character.grid_position.x) + abs(grid_position.y - character.grid_position.y)
	if distance > interaction_radius:
		return false
	
	return true

func interact(character: Character) -> Dictionary:
	"""Perform the interaction"""
	if not can_interact(character):
		return {"success": false, "message": "Cannot interact with this entity"}
	
	# Emit signals
	interaction_attempted.emit(self)
	
	# Perform interaction
	var result = perform_interaction(character)
	
	if result.get("success", false):
		current_uses += 1
		interacted_with.emit(self, character)
		
		# Update visual if exhausted
		if is_exhausted():
			update_visual_for_exhausted_state()
	
	return result

func perform_interaction(character: Character) -> Dictionary:
	"""Perform the actual interaction - can be overridden in subclasses"""
	var message = interaction_message
	if message == "":
		message = "You interacted with " + entity_type
	
	return {
		"success": true,
		"message": message,
		"effects": interaction_effects.duplicate()
	}

func update_visual_for_exhausted_state():
	"""Update visual when entity is exhausted"""
	if visual_component:
		for child in visual_component.get_children():
			if child is ColorRect:
				child.color = child.color.darkened(0.6)

func get_interaction_info() -> Dictionary:
	"""Get information about this interactable for UI display"""
	return {
		"name": interaction_name,
		"type": entity_type,
		"can_interact": can_be_interacted_with,
		"cost": interaction_cost,
		"uses_remaining": max_uses - current_uses if max_uses > 0 else -1,
		"description": get_description()
	}

func get_description() -> String:
	"""Get description for this interactable"""
	if is_exhausted():
		return "A depleted " + entity_type + "."
	else:
		return "A " + entity_type + " that can be interacted with."

func set_grid_position(pos: Vector2i, tile_size: int):
	"""Set the grid position and update world position"""
	grid_position = pos
	global_position = Vector2(
		pos.x * tile_size + tile_size / 2,
		pos.y * tile_size + tile_size / 2
	)

func disable_interaction():
	"""Disable interaction with this entity"""
	can_be_interacted_with = false

func enable_interaction():
	"""Enable interaction with this entity"""
	can_be_interacted_with = true

# Utility methods
func is_exhausted() -> bool:
	"""Check if this entity has been used up"""
	return max_uses > 0 and current_uses >= max_uses

func get_remaining_uses() -> int:
	"""Get remaining uses (returns -1 for infinite)"""
	if max_uses <= 0:
		return -1
	return max_uses - current_uses

# Configuration methods for easy setup
func configure_visual(color: Color, size: Vector2 = Vector2(20, 20), shape: String = "rectangle"):
	"""Configure the visual appearance"""
	visual_color = color
	visual_size = size
	visual_shape = shape
	
	# Recreate visual if already created
	if visual_component:
		visual_component.queue_free()
		call_deferred("create_visual_component")

func configure_interaction(name: String, message: String, effects: Dictionary = {}, cost: int = 1, uses: int = -1):
	"""Configure the interaction behavior"""
	interaction_name = name
	interaction_message = message
	interaction_effects = effects
	interaction_cost = cost
	max_uses = uses
