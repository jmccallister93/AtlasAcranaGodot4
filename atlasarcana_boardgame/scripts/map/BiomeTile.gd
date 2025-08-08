extends Area2D
class_name BiomeTile

# Tile properties
@export var grid_position: Vector2i  # Position in the grid
@export var biome_type: BiomeType = BiomeType.GRASSLAND
var tile_size: int = 64  # Set by MapManager - no longer exported

# Reference to map manager for accessing map-wide functionality
var map_manager: MapManager

# Game logic data
#var buildings: Array[Building] = []  # Buildings on this tile
#var characters: Array[Character] = []  # Characters on this tile
var resources: Dictionary = {}  # Resource amounts on this tile
var is_occupied: bool = false
var movement_cost: float = 1.0

# Visual components - created in code
var sprite: Sprite2D
var collision_shape: CollisionShape2D
var hover_label: Label
#Highlights for movement
var is_movement_highlighted: bool = false
var movement_highlight_overlay: ColorRect
#Highlights for building
var is_build_highlighted: bool = false
var build_highlight_overlay: ColorRect

# Signals for game events
signal tile_clicked(tile: BiomeTile)
signal tile_hovered(tile: BiomeTile)
#signal building_placed(tile: Tile, building: Building)
#signal character_entered(tile: Tile, character: Character)

enum BiomeType {
	GRASSLAND,
	FOREST,
	MOUNTAIN,
	WATER,
	DESERT,
	SWAMP
}

func _ready():
	# Create all components first
	create_sprite()
	create_collision_shape()
	create_hover_label()
	
	# Connect signals
#	TODO
	#input_event.connect(_on_input_event)
	#mouse_entered.connect(_on_mouse_entered)
	#mouse_exited.connect(_on_mouse_exited)
	
	# Initialize tile
	setup_tile()
	setup_hover_label()
	setup_movement_highlight_overlay()
	setup_build_highlight_overlay()

func create_sprite():
	"""Create and setup the sprite component"""
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	add_child(sprite)

func create_collision_shape():
	"""Create and setup the collision shape"""
	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	
	# Create rectangle shape for the tile
	var shape = RectangleShape2D.new()
	shape.size = Vector2(tile_size, tile_size)
	collision_shape.shape = shape

	
	add_child(collision_shape)

func create_hover_label():
	"""Create and setup the hover label"""
	hover_label = Label.new()
	hover_label.name = "HoverLabel"
	
	# Basic label setup
	hover_label.visible = false
	hover_label.z_index = 10  # Ensure it appears above other elements
	
	# Set size flags for auto-sizing
	hover_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hover_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	add_child(hover_label)

func setup_tile():
	"""Initialize the tile based on its biome type"""
	var biome_data = get_biome_data(biome_type)
	
	# Set sprite texture based on biome
	sprite.texture = biome_data.texture
	
	# Set tile properties from biome
	movement_cost = biome_data.movement_cost
	resources = biome_data.base_resources.duplicate()
	
	# Position the tile in world space
	global_position = Vector2(
		grid_position.x * tile_size  + tile_size/2, 
		grid_position.y * tile_size + tile_size/2
		)

func setup_hover_label():
	"""Setup the hover label properties"""
	if hover_label:
		# Position label at top-left corner of tile with small offset
		hover_label.position = Vector2(2, 2)
		
		# Style the label
		hover_label.add_theme_color_override("font_color", Color.WHITE)
		hover_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		hover_label.add_theme_constant_override("shadow_offset_x", 1)
		hover_label.add_theme_constant_override("shadow_offset_y", 1)
		hover_label.add_theme_font_size_override("font_size", 10)
		
		# Create a background for better readability
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0, 0, 0, 0.8)  # Semi-transparent black
		style_box.corner_radius_top_left = 4
		style_box.corner_radius_top_right = 4
		style_box.corner_radius_bottom_left = 4
		style_box.corner_radius_bottom_right = 4
		style_box.content_margin_top = 4
		style_box.content_margin_bottom = 4
		style_box.content_margin_left = 8
		style_box.content_margin_right = 8
		hover_label.add_theme_stylebox_override("normal", style_box)

func setup_movement_highlight_overlay():
	"""Setup the highlight overlay for movement indication"""
	movement_highlight_overlay = ColorRect.new()
	movement_highlight_overlay.color = Color(0, 0, 1, 0.3)  # Semi-transparent green
	movement_highlight_overlay.size = Vector2(tile_size/2, tile_size/2)  # Use dynamic tile_size instead of hardcoded 64
	movement_highlight_overlay.position = Vector2(-tile_size/2, -tile_size/2) 
	movement_highlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse events
	movement_highlight_overlay.visible = false

	add_child(movement_highlight_overlay)
	
func setup_build_highlight_overlay():
	"""Setup the build highlight overlay"""
	build_highlight_overlay = ColorRect.new()
	build_highlight_overlay.color = Color(0.8, 0.4, 0.8, 0.3)  # Semi-transparent purple
	build_highlight_overlay.size = Vector2(tile_size/2, tile_size/2)
	build_highlight_overlay.position = Vector2(-tile_size/2, -tile_size/2)
	build_highlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_highlight_overlay.visible = false
	add_child(build_highlight_overlay)
	
func set_movement_highlighted(highlighted: bool):
	"""Set the highlight state of this tile"""
	is_movement_highlighted = highlighted
	if movement_highlight_overlay:
		movement_highlight_overlay.visible = highlighted

func set_build_highlighted(highlighted: bool):
	"""Set the build highlight state of this tile"""
	is_build_highlighted = highlighted
	if build_highlight_overlay:
		build_highlight_overlay.visible = highlighted
	

func get_biome_data(biome: BiomeType) -> Dictionary:
	"""Return biome-specific data"""
	match biome:
		BiomeType.GRASSLAND:
			return {
				"texture": preload("res://assets/tiles/grassland.png"),
				"movement_cost": 1.0,
				"base_resources": {"food": 2, "wood": 0},
				"building_bonus": {"farm": 1.5},
				"name": "Grassland"
			}
		BiomeType.FOREST:
			return {
				"texture": preload("res://assets/tiles/forest.png"),
				"movement_cost": 1.5,
				"base_resources": {"food": 1, "wood": 3},
				"building_bonus": {"lumber_mill": 2.0},
				"name": "Forest"
			}
		BiomeType.MOUNTAIN:
			return {
				"texture": preload("res://assets/tiles/mountain.png"),
				"movement_cost": 2.0,
				"base_resources": {"stone": 2, "metal": 1},
				"building_bonus": {"mine": 2.0},
				"name": "Mountain"
			}
		BiomeType.WATER:
			return {
				"texture": preload("res://assets/tiles/water.png"),
				"movement_cost": 999.0,  # Impassable
				"base_resources": {"fish": 2},
				"building_bonus": {"dock": 1.5},
				"name": "Water"
			}
		BiomeType.DESERT:
			return {
				"texture": preload("res://assets/tiles/default.png"),
				"movement_cost": 1.3,
				"base_resources": {"stone": 1},
				"building_bonus": {"mine": 1.2},
				"name": "Desert"
			}
		BiomeType.SWAMP:
			return {
				"texture": preload("res://assets/tiles/default.png"),
				"movement_cost": 2.5,
				"base_resources": {"wood": 1, "herbs": 2},
				"building_bonus": {"farm": 0.8},
				"name": "Swamp"
			}
		_:
			return {
				"texture": preload("res://assets/tiles/default.png"),
				"movement_cost": 1.0,
				"base_resources": {},
				"building_bonus": {},
				"name": "Unknown"
			}

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	"""Handle tile clicking"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			tile_clicked.emit(self)
			show_tile_details()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			show_context_menu()

func _on_mouse_entered():
	"""Handle mouse hover"""
	tile_hovered.emit(self)
	# Add hover visual effect
	modulate = Color(1.2, 1.2, 1.2, 1.0)
	# Show hover label with tile info
	show_hover_info()

func _on_mouse_exited():
	"""Handle mouse exit"""
	# Remove hover visual effect
	modulate = Color.WHITE
	
	# Hide hover label
	if hover_label:
		hover_label.visible = false
	
func show_hover_info():
	"""Display hover information in the label"""
	if not hover_label:
		return
	
	var biome_data = get_biome_data(biome_type)
	var info_text = ""
	
	# Build the info text
	info_text += biome_data.name + "\n"
	info_text += "Pos: (%d, %d)\n" % [grid_position.x, grid_position.y]
	
	# Show resources if any
	if not resources.is_empty():
		info_text += "Resources: "
		var resource_strings = []
		for resource in resources:
			if resources[resource] > 0:
				resource_strings.append("%s: %d" % [resource.capitalize(), resources[resource]])
		info_text += ", ".join(resource_strings) + "\n"
	
	# Show movement cost
	if movement_cost < 999:
		info_text += "Movement: %.1f" % movement_cost
	else:
		info_text += "Impassable"
	
	# Set the text and show the label
	hover_label.text = info_text
	hover_label.visible = true

func show_tile_details():
	"""Show detailed information about the tile"""
	var biome_data = get_biome_data(biome_type)
	
	# Update details panel (you'll need to create UI elements)
	# This is a simplified version - you'd want a proper UI
	print("=== TILE DETAILS ===")
	print("Biome: ", biome_data.name)
	print("Position: ", grid_position)
	print("Resources: ", resources)
	#print("Buildings: ", buildings.size())
	#print("Characters: ", characters.size())
	print("Movement Cost: ", movement_cost)

func show_context_menu():
	"""Show context menu for tile actions"""
	print("=== TILE ACTIONS ===")
	print("1. Build Structure")
	print("2. Harvest Resources")
	print("3. Move Character Here")

# Utility functions for changing tile properties
func change_biome_type(new_biome: BiomeType):
	"""Change the biome type and update visual/properties"""
	biome_type = new_biome
	setup_tile()

func set_custom_texture(texture: Texture2D):
	"""Set a custom texture for this tile"""
	if sprite:
		sprite.texture = texture

func update_tile_size(new_size: int):
	"""Update the tile size and collision shape"""
	tile_size = new_size
	
	# Update collision shape
	if collision_shape and collision_shape.shape:
		var rect_shape = collision_shape.shape as RectangleShape2D
		if rect_shape:
			rect_shape.size = Vector2(tile_size, tile_size)
			
	# Update movement highlight overlay size
	if movement_highlight_overlay:
		movement_highlight_overlay.size = Vector2(tile_size, tile_size)
	
		# Update build highlight overlay
	if build_highlight_overlay:
		build_highlight_overlay.size = Vector2(tile_size, tile_size)
		build_highlight_overlay.position = Vector2(-tile_size/2, -tile_size/2)

# Building management
func can_place_building(building_type: String) -> bool:
	"""Check if a building can be placed on this tile"""
	if is_occupied:
		return false
	
	var biome_data = get_biome_data(biome_type)
	# Add specific building placement rules here
	match building_type:
		"dock":
			return biome_type == BiomeType.WATER
		"mine":
			return biome_type == BiomeType.MOUNTAIN
		_:
			return biome_type != BiomeType.WATER

#func place_building(building: Building) -> bool:
	#"""Place a building on this tile"""
	#if can_place_building(building.type):
		#buildings.append(building)
		#is_occupied = true
		#building_placed.emit(self, building)
		#return true
	#return false

#func remove_building(building: Building):
	#"""Remove a building from this tile"""
	#buildings.erase(building)
	#if buildings.is_empty():
		#is_occupied = false

# Character management
#func add_character(character: Character):
	#"""Add a character to this tile"""
	#if not characters.has(character):
		#characters.append(character)
		#character_entered.emit(self, character)
#
#func remove_character(character: Character):
	#"""Remove a character from this tile"""
	#characters.erase(character)

# Resource management
func get_resource_production() -> Dictionary:
	"""Calculate total resource production including bonuses"""
	var total_production = resources.duplicate()
	
	# Apply building bonuses
	var biome_data = get_biome_data(biome_type)
	#for building in buildings:
		#if building.type in biome_data.building_bonus:
			#var bonus = biome_data.building_bonus[building.type]
			#for resource in building.production:
				#if resource in total_production:
					#total_production[resource] *= bonus
	
	return total_production

func harvest_resources() -> Dictionary:
	"""Harvest resources from this tile"""
	var harvested = get_resource_production()
	# Could implement resource depletion here
	return harvested

# Utility functions
func get_distance_to(other_tile: BiomeTile) -> float:
	"""Get distance to another tile"""
	return abs(grid_position.x - other_tile.grid_position.x) + abs(grid_position.y - other_tile.grid_position.y)

func get_neighbors() -> Array[BiomeTile]:
	"""Get neighboring tiles using the map manager"""
	if not map_manager:
		push_warning("BiomeTile has no map_manager reference")
		return []
	return map_manager.get_neighbors(self)
