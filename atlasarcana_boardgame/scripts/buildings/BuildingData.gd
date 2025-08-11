# BuildingData.gd
extends Resource
class_name BuildingData

# Building types enum
enum BuildingType {
#	Resource
	ESSENCE_COLLECTOR,
	FARM,
	LUMBER_MILL,
	MINE,
	#Character
	BLACKSMITH,
	ACADEMY,
	SHOP,
	#Warband
	BARRACKS,
	ARCHERY_RANGE,
	MAGE_TOWER,
	#Defensive
	OUTPOST,
	BUNKER,
	BASTION,
	BASIC_STRUCTURE
}

# Building categories
enum BuildingCategory {
	RESOURCE,
	CHARACTER,
	WARBAND,
	DEFENSE,
	BASIC_STRUCTURE
}

# Static building definitions
static func get_building_definitions() -> Dictionary:
	return {
		BuildingType.ESSENCE_COLLECTOR: {
			"name": "Essenece Collector",
			"description": "Produces essence each turn.",
			"category": BuildingCategory.RESOURCE,
			"cost": {"gold": 50, },
			"base_production": {"essence": 10},
			"sprite_color": Color(0.2, 0.2, 0.8), 
		},
		#FOOD
		BuildingType.FARM: {
			"name": "Farm",
			"description": "Produces food each turn. Gets bonus on grassland tiles.",
			"category": BuildingCategory.RESOURCE,
			"cost": {"gold": 50, },
			"base_production": {"food": 10},
			"biome_bonuses": {
				BiomeTile.BiomeType.GRASSLAND: {"food": 5}
			},
			"sprite_color": Color(0.2, 0.8, 0.2),  
		},
		#WOOD
		BuildingType.LUMBER_MILL: {
			"name": "Lumber Mill",
			"description": "Produces wood each turn. Gets large bonus on forest tiles.",
			"category": BuildingCategory.RESOURCE,
			"cost": {"gold": 75,},
			"base_production": {"wood": 10},
			"biome_bonuses": {
				BiomeTile.BiomeType.FOREST: {"wood": 5}
			},
			"sprite_color": Color(0.6, 0.3, 0.1),  
		},
#		STONE
		BuildingType.MINE: {
			"name": "Mine",
			"description": "Produces stone and metal. Gets huge bonus on mountain tiles.",
			"category": BuildingCategory.RESOURCE,
			"cost": {"gold": 100, },
			"base_production": {"stone": 10},
			"biome_bonuses": {
				BiomeTile.BiomeType.MOUNTAIN: {"stone": 5, }
			},
			"sprite_color": Color(0.5, 0.5, 0.5),  # Gray for mines
		},
#		CHARACTER ITEMS
		BuildingType.SHOP: {
			"name": "Shop",
			"description": "Allows purchase of items.",
			"category": BuildingCategory.CHARACTER,
			"cost": {"gold": 120, },
			"base_production": {},
			"biome_bonuses": {},
			"sprite_color": Color(1.0, 0.3, 0.1),  # Orange-red for forge
			"utility_type": "character",
			"utility_description": "Create Character items."
		},
		BuildingType.BLACKSMITH: {
			"name": "Blacksmith",
			"description": "Allows creation of weapons and armor.",
			"category": BuildingCategory.CHARACTER,
			"cost": {"gold": 120, },
			"base_production": {},
			"biome_bonuses": {},
			"sprite_color": Color(1.0, 0.3, 0.1),  # Orange-red for forge
			"utility_type": "character",
			"utility_description": "Create Character weapons and armor."
		},
		BuildingType.ACADEMY: {
			"name": "Academy",
			"description": "Research into character skills.",
			"category": BuildingCategory.CHARACTER,
			"cost": {"gold": 120, },
			"base_production": {},
			"biome_bonuses": {},
			"sprite_color": Color(1.0, 0.3, 0.1),  # Orange-red for forge
			"utility_type": "character",
			"utility_description": "Create Character skills/abilities."
		},
#		UNITS
		BuildingType.BARRACKS: {
			"name": "Barracks",
			"description": "Provides close combat unit recruitment for warband.",
			"category": BuildingCategory.WARBAND,
			"cost": {"gold": 150,},
			"base_production": {},
			"biome_bonuses": {},
			"sprite_color": Color(0.8, 0.1, 0.1),  # Dark red for military
			"utility_type": "warband",
			"utility_description": "Purchase Tanks, Heavy Melee, Fast Melee units."
		},
			BuildingType.ARCHERY_RANGE: {
			"name": "Archery Range",
			"description": "Provides ranged unit recruitment for warband.",
			"category": BuildingCategory.WARBAND,
			"cost": {"gold": 150,},
			"base_production": {},
			"biome_bonuses": {},
			"sprite_color": Color(0.8, 0.1, 0.1),  # Dark red for military
			"utility_type": "warband",
			"utility_description": "Purchase Heavy Ranged, Fast Ranged, Utility (trap) Ranged units."
		},
			BuildingType.MAGE_TOWER: {
			"name": "Mage Tower",
			"description": "Provides magic units recruitment for warband.",
			"category": BuildingCategory.WARBAND,
			"cost": {"gold": 150,},
			"base_production": {},
			"biome_bonuses": {},
			"sprite_color": Color(0.8, 0.1, 0.1),  # Dark red for military
			"utility_type": "warband",
			"utility_description": "Purchase AoE, Single Target, Crowd Control magic units."
		},
		BuildingType.OUTPOST: {
			"name": "Outpost",
			"description": "Provides ranged defense for buildings in area.",
			"category": BuildingCategory.DEFENSE,
			"cost": {"gold": 50,},
			"base_production": {},
			"biome_bonuses": {},
			"sprite_color": Color(0.5, 0.5, 0.1),  
			"utility_type": "defense",
			"utility_description": "Create Ranged defense structure."
		},
		BuildingType.BUNKER: {
			"name": "Bunker",
			"description": "Provides close combat defense for buildings in area.",
			"category": BuildingCategory.DEFENSE,
			"cost": {"gold": 50,},
			"base_production": {},
			"biome_bonuses": {},
			"sprite_color": Color(0.5, 0.5, 0.1),  
			"utility_type": "defense",
			"utility_description": "Create Close combat defense structure."
		},
		BuildingType.BASTION: {
			"name": "Bastion",
			"description": "Provides magic defense for buildings in area.",
			"category": BuildingCategory.DEFENSE,
			"cost": {"gold": 50,},
			"base_production": {},
			"biome_bonuses": {},
			"sprite_color": Color(0.5, 0.5, 0.1),  
			"utility_type": "defense",
			"utility_description": "Create Magic defense structure."
		},
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
	
static func get_utility_description(building_type: BuildingType) -> String:
	var data = get_building_data(building_type)
	return data.get("utility_description", "")
