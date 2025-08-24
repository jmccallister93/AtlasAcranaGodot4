# TerrainMaterialLibrary.gd - Material library for 3D terrain tiles
extends Node
class_name TerrainMaterialLibrary

# Material cache
var materials: Dictionary = {}
var textures: Dictionary = {}

# Material settings
var base_metallic: float = 0.0
var base_roughness: float = 0.7
var base_emission_energy: float = 0.0

func _ready():
	"""Initialize the material library"""
	create_default_materials()

func create_default_materials():
	"""Create default materials for each biome type"""
	
	# Grassland
	materials[BiomeTile3D.BiomeType.GRASSLAND] = create_biome_material(
		Color(0.4, 0.8, 0.2),  # Green
		0.0, 0.9,  # Non-metallic, rough
		"grassland"
	)
	
	# Forest
	materials[BiomeTile3D.BiomeType.FOREST] = create_biome_material(
		Color(0.2, 0.6, 0.2),  # Dark green
		0.0, 0.9,
		"forest"
	)
	
	# Mountain
	materials[BiomeTile3D.BiomeType.MOUNTAIN] = create_biome_material(
		Color(0.6, 0.5, 0.4),  # Brown/gray
		0.2, 0.8,  # Slightly metallic, rough
		"mountain"
	)
	
	# Water
	materials[BiomeTile3D.BiomeType.WATER] = create_water_material()
	
	# Desert
	materials[BiomeTile3D.BiomeType.DESERT] = create_biome_material(
		Color(0.8, 0.7, 0.4),  # Sand
		0.0, 0.6,
		"desert"
	)
	
	# Swamp
	materials[BiomeTile3D.BiomeType.SWAMP] = create_biome_material(
		Color(0.4, 0.5, 0.3),  # Muddy green
		0.0, 0.8,
		"swamp"
	)

func create_biome_material(color: Color, metallic: float, roughness: float, texture_name: String) -> StandardMaterial3D:
	"""Create a standard material for a biome"""
	var material = StandardMaterial3D.new()
	
	# Basic properties
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	
	# Try to load texture if available
	var texture_path = "res://assets/tiles/3d/" + texture_name + "_texture.png"
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path) as Texture2D
		if texture:
			material.albedo_texture = texture
	
	# Enable texture detail for better close-up appearance
	material.detail_enabled = true
	material.detail_mask = material.albedo_texture
	material.detail_albedo = material.albedo_texture
	material.detail_uv_layer = StandardMaterial3D.DETAIL_UV_1
	
	return material

func create_water_material() -> StandardMaterial3D:
	"""Create special water material with transparency and reflection"""
	var material = StandardMaterial3D.new()
	
	# Water properties
	material.albedo_color = Color(0.2, 0.4, 0.8, 0.7)  # Semi-transparent blue
	material.metallic = 0.0
	material.roughness = 0.1  # Very smooth for reflections
	
	# Transparency
	material.flags_transparent = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Refraction for underwater effect
	material.refraction_enabled = true
	material.refraction_scale = 0.1
	
	# Subtle emission for luminosity
	material.emission_enabled = true
	material.emission = Color(0.1, 0.2, 0.4)
	material.emission_energy = 0.2
	
	# Try to load water texture
	var texture_path = "res://assets/tiles/3d/water_texture.png"
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path) as Texture2D
		if texture:
			material.albedo_texture = texture
	
	return material

func get_material(biome_type: BiomeTile3D.BiomeType) -> StandardMaterial3D:
	"""Get material for a specific biome type"""
	if materials.has(biome_type):
		return materials[biome_type]
	else:
		# Return default material
		return create_default_material()

func create_default_material() -> StandardMaterial3D:
	"""Create a default fallback material"""
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GRAY
	material.metallic = base_metallic
	material.roughness = base_roughness
	return material

func create_highlight_material(color: Color) -> StandardMaterial3D:
	"""Create a highlight overlay material"""
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.flags_transparent = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	material.flags_unshaded = true
	material.flags_do_not_use_blend_alpha = false
	return material

func update_material_quality(high_quality: bool):
	"""Update material quality settings"""
	for biome_type in materials:
		var material = materials[biome_type] as StandardMaterial3D
		if material:
			if high_quality:
				material.detail_enabled = true
				material.normal_enabled = true
			else:
				material.detail_enabled = false
				material.normal_enabled = false

func preload_textures():
	"""Preload all terrain textures"""
	var texture_names = ["grassland", "forest", "mountain", "water", "desert", "swamp"]
	
	for texture_name in texture_names:
		var texture_path = "res://assets/tiles/3d/" + texture_name + "_texture.png"
		if ResourceLoader.exists(texture_path):
			textures[texture_name] = load(texture_path)
			print("Loaded texture: ", texture_name)
		else:
			print("Texture not found: ", texture_path)

func apply_material_to_tile(tile: BiomeTile3D):
	"""Apply appropriate material to a tile"""
	if not tile or not tile.mesh_instance:
		return
	
	var material = get_material(tile.biome_type)
	tile.mesh_instance.material_override = material

func create_custom_material(color: Color, metallic: float = 0.0, roughness: float = 0.7, transparent: bool = false) -> StandardMaterial3D:
	"""Create a custom material with specified properties"""
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	
	if transparent:
		material.flags_transparent = true
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	return material

# Seasonal material variations (future enhancement)
func apply_seasonal_effects(season: String):
	"""Apply seasonal color/texture changes to materials"""
	match season:
		"spring":
			modify_grassland_for_spring()
		"summer":
			modify_materials_for_summer()
		"autumn":
			modify_materials_for_autumn()
		"winter":
			modify_materials_for_winter()

func modify_grassland_for_spring():
	"""Make grassland more vibrant for spring"""
	var grassland_material = materials[BiomeTile3D.BiomeType.GRASSLAND] as StandardMaterial3D
	if grassland_material:
		grassland_material.albedo_color = Color(0.3, 0.9, 0.1)  # Brighter green

func modify_materials_for_summer():
	"""Apply summer color variations"""
	pass  # Implementation for summer effects

func modify_materials_for_autumn():
	"""Apply autumn color variations"""
	pass  # Implementation for autumn effects

func modify_materials_for_winter():
	"""Apply winter color variations"""
	pass  # Implementation for winter effects
