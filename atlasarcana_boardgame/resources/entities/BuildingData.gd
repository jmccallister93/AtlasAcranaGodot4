# BuildingData.gd
extends Resource
class_name BuildingData

# Building types enum
enum BuildingType {
	ESSENCE_COLLECTOR,
	FARM,
	LUMBER_MILL,
	MINE,
	FORGE,
	BARRACKS,
	ARCHERY_RANGE,
	MAGE_TOWER,
	DOCK,
	OUTPOST,
	BASIC_STRUCTURE
}

# Building categories
enum BuildingCategory {
	RESOURCE_PRODUCTION,
	UTILITY,
	WARBAND,
	INFRASTRUCTURE,
	DEFENSE
}

# Static building definitions
static func get_building_definitions() -> Dictionary:
	return {
		BuildingType.ESSENCE_COLLECTOR: {
			"name": "Essenece Collector",
			"description": "Produces essence each turn.",
			"category": BuildingCategory.RESOURCE_PRODUCTION,
			"cost": {"gold": 50, },
			"base_production": {"essence": 10},
			#"biome_bonuses": {
				#BiomeTile.BiomeType.GRASSLAND: {"food": 5}
			#},
			"sprite_color": Color(0.2, 0.2, 0.8),  # Bright green for farms

		},
		#FOOD
		BuildingType.FARM: {
			"name": "Farm",
			"description": "Produces food each turn. Gets bonus on grassland tiles.",
			"category": BuildingCategory.RESOURCE_PRODUCTION,
			"cost": {"gold": 50, },
			"base_production": {"food": 10},
			"biome_bonuses": {
				BiomeTile.BiomeType.GRASSLAND: {"food": 5}
			},
			"sprite_color": Color(0.2, 0.8, 0.2),  # Bright green for farms

		},
			BuildingType.DOCK: {
			"name": "Dock",
			"description": "Provides fish and enables water trade routes.",
			"category": BuildingCategory.INFRASTRUCTURE,
			"cost": {"gold": 80},
			"base_production": {"food": 10},
			"biome_bonuses": {
				BiomeTile.BiomeType.WATER: {"food": 5}
			},
			"sprite_color": Color(0.1, 0.5, 0.9),  # Blue for water buildings
			"allowed_biomes": [
				BiomeTile.BiomeType.WATER
			]
		},
#		WOOD
		BuildingType.LUMBER_MILL: {
			"name": "Lumber Mill",
			"description": "Produces wood each turn. Gets large bonus on forest tiles.",
			"category": BuildingCategory.RESOURCE_PRODUCTION,
			"cost": {"gold": 75,},
			"base_production": {"wood": 10},
			"biome_bonuses": {
				BiomeTile.BiomeType.FOREST: {"wood": 5}
			},
			"sprite_color": Color(0.6, 0.3, 0.1),  # Brown for lumber

		},
#		STONE
		BuildingType.MINE: {
			"name": "Mine",
			"description": "Produces stone and metal. Gets huge bonus on mountain tiles.",
			"category": BuildingCategory.RESOURCE_PRODUCTION,
			"cost": {"gold": 100, },
			"base_production": {"stone": 10},
			"biome_bonuses": {
				BiomeTile.BiomeType.MOUNTAIN: {"stone": 5, }
			},
			"sprite_color": Color(0.5, 0.5, 0.5),  # Gray for mines

		},
#		CHARACTER ITEMS
		BuildingType.FORGE: {
			"name": "Forge",
			"description": "Allows creation of weapons and tools. Requires metal.",
			"category": BuildingCategory.UTILITY,
			"cost": {"gold": 120, },
			"base_production": {},
			"biome_bonuses": {},
			"sprite_color": Color(1.0, 0.3, 0.1),  # Orange-red for forge

			"utility_type": "weapon_crafting"
		},
#		UNITS
		BuildingType.BARRACKS: {
			"name": "Barracks",
			"description": "Trains close combat units for combat.",
			"category": BuildingCategory.WARBAND,
			"cost": {"gold": 150,},
			"base_production": {},
			"biome_bonuses": {},
			"sprite_color": Color(0.8, 0.1, 0.1),  # Dark red for military

			"utility_type": "unit_training"
		},
			BuildingType.ARCHERY_RANGE: {
			"name": "Archery Range",
			"description": "Trains ranged units for combat.",
			"category": BuildingCategory.WARBAND,
			"cost": {"gold": 150,},
			"base_production": {},
			"biome_bonuses": {},
			"sprite_color": Color(0.8, 0.1, 0.1),  # Dark red for military

			"utility_type": "unit_training"
		},
			BuildingType.MAGE_TOWER: {
			"name": "Mage Tower",
			"description": "Trains magic units for combat.",
			"category": BuildingCategory.WARBAND,
			"cost": {"gold": 150,},
			"base_production": {},
			"biome_bonuses": {},
			"sprite_color": Color(0.8, 0.1, 0.1),  # Dark red for military

			"utility_type": "unit_training"
		},
		
		BuildingType.OUTPOST: {
			"name": "Outpost",
			"description": "Helps defend areas from attacks.",
			"category": BuildingCategory.DEFENSE,
			"cost": {"gold": 50,},
			"base_production": {},
			"biome_bonuses": {},
			"sprite_color": Color(0.5, 0.5, 0.1),  

			"utility_type": "defense"
		},


		#BuildingType.BASIC_STRUCTURE: {
			#"name": "Basic Structure",
			#"description": "A simple building with no special function.",
			#"category": BuildingCategory.INFRASTRUCTURE,
			#"cost": {"gold": 25},
			#"base_production": {},
			#"biome_bonuses": {},
			#"sprite_color": Color(0.6, 0.4, 0.8),  # Purple for basic
			#"allowed_biomes": [
				#BiomeTile.BiomeType.GRASSLAND,
				#BiomeTile.BiomeType.FOREST,
				#BiomeTile.BiomeType.DESERT
			#]
		#}
	}

static func get_building_data(building_type: BuildingType) -> Dictionary:
	"""Get data for a specific building type"""
	var definitions = get_building_definitions()
	return definitions.get(building_type, {})

static func can_build_on_biome(building_type: BuildingType, biome_type: BiomeTile.BiomeType) -> bool:
	"""Check if a building can be built on a specific biome"""
	var data = get_building_data(building_type)
	
	# If no allowed_biomes key exists, allow on any biome
	if not data.has("allowed_biomes"):
		return true
	
	# If allowed_biomes exists, check if biome is in the list
	var allowed_biomes = data.get("allowed_biomes", [])
	return biome_type in allowed_biomes


static func get_total_production(building_type: BuildingType, biome_type: BiomeTile.BiomeType) -> Dictionary:
	"""Get total production including biome bonuses"""
	var data = get_building_data(building_type)
	var base_production = data.get("base_production", {}).duplicate()
	var biome_bonuses = data.get("biome_bonuses", {})
	
	if biome_type in biome_bonuses:
		var bonus = biome_bonuses[biome_type]
		for resource in bonus:
			if resource in base_production:
				base_production[resource] += bonus[resource]
			else:
				base_production[resource] = bonus[resource]
	
	return base_production

static func get_building_cost(building_type: BuildingType) -> Dictionary:
	"""Get the cost to build this building"""
	var data = get_building_data(building_type)
	return data.get("cost", {})
