# GameUI.gd - Simplified Main Coordinator
extends Control
class_name GameUI

# UI Components
var top_bar: TopBarUI
var bottom_bar: BottomBarUI
var action_mode_manager: ActionModeManager
var notification_manager: NotificationManager
var menu_manager: MenuManager
var confirmation_dialog_manager: ConfirmationDialogManager
var building_detail_view: BuildingDetailView

# Legacy menu references (for compatibility)
var inventory_menu: InventoryMenu
var character_menu: EnhancedCharacterMenu
var building_menu: BuildingMenu

# Signals for menu interactions (for compatibility)
signal inventory_opened
signal inventory_closed
signal character_opened
signal character_closed
signal building_opened
signal building_closed

func _ready():
	GameManager.register_game_ui(self)
	create_ui_components()
	setup_layout()
	connect_signals()

func _exit_tree():
	if GameManager:
		GameManager.unregister_game_ui()

func create_ui_components():
	"""Create all UI components programmatically"""
	print("Creating UI components...")
	
	# Create main components
	top_bar = TopBarUI.new()
	bottom_bar = BottomBarUI.new()
	action_mode_manager = ActionModeManager.new()
	notification_manager = NotificationManager.new()
	confirmation_dialog_manager = ConfirmationDialogManager.new()
	
	# Add to scene tree in correct order (z-index matters)
	add_child(top_bar)
	add_child(bottom_bar)
	add_child(action_mode_manager)
	add_child(notification_manager)  # High z-index for visibility
	add_child(confirmation_dialog_manager)  # Highest z-index
	
	# Initialize action mode manager with references
	action_mode_manager.initialize(bottom_bar, notification_manager)
	
	# Create legacy menus for compatibility
	create_legacy_menus()
	
	create_building_detail_view()

func create_legacy_menus():
	"""Create legacy menu system for backward compatibility"""
	menu_manager = MenuManager.new()
	add_child(menu_manager)
	
	# Create the actual menu instances
	var inventory_menu_scene: PackedScene = preload("res://scenes/ui/menus/InventoryMenu.tscn")
	var building_menu_scene: PackedScene = preload("res://scenes/ui/menus/BuildingMenu.tscn")
	
	if inventory_menu_scene:
		inventory_menu = inventory_menu_scene.instantiate()
		menu_manager.add_child(inventory_menu)
		inventory_menu.hide()
	
	# Create enhanced character menu programmatically
	character_menu = EnhancedCharacterMenu.new()
	menu_manager.add_child(character_menu)
	character_menu.hide()
	
	if building_menu_scene:
		building_menu = building_menu_scene.instantiate()
		menu_manager.add_child(building_menu)
		building_menu.hide()
	
	# Connect character menu signals
	if character_menu:
		character_menu.equipment_slot_clicked.connect(_on_equipment_slot_clicked)
		character_menu.item_equipped.connect(_on_item_equipped)
		character_menu.item_unequipped.connect(_on_item_unequipped)


func _on_equipment_slot_clicked(slot_type: EquipmentSlot.SlotType):
	"""Handle equipment slot clicks"""
	print("Equipment slot clicked in GameUI: ", EquipmentSlot.SlotType.keys()[slot_type])
	
	# For demonstration, create and equip a random item
	# In a real game, this would open an inventory or item selection dialog
	if GameManager and GameManager.character:
		create_demo_item_for_slot(slot_type)

func create_demo_item_for_slot(slot_type: EquipmentSlot.SlotType):
	"""Create a demo item for the clicked slot"""
	# Initialize item database if not done already
	ItemDatabase.initialize()
	
	var character = GameManager.character
	var current_item = character.get_equipped_item(slot_type)
	
	if current_item:
		# Unequip current item
		character.unequip_item(slot_type)
		show_info("Unequipped " + current_item.item_name)
	else:
		# Equip a demo item based on slot type
		var demo_item = create_demo_item_for_slot_type(slot_type)
		if demo_item and character.equip_item(demo_item, slot_type):
			show_success("Equipped " + demo_item.item_name)
		else:
			show_error("Failed to equip item")

func create_demo_item_for_slot_type(slot_type: EquipmentSlot.SlotType) -> EquipmentItem:
	"""Create a demo item for a specific slot type"""
	var demo_item = EquipmentItem.new()
	demo_item.compatible_slots = [slot_type]
	
	match slot_type:
		EquipmentSlot.SlotType.MAIN_HAND:
			demo_item.item_id = "demo_sword"
			demo_item.item_name = "Demo Sword"
			demo_item.description = "A demonstration weapon"
			demo_item.stat_modifiers = {"Attack": 10, "Critical_Chance": 3}
			demo_item.rarity = EquipmentItem.ItemRarity.UNCOMMON
			
		EquipmentSlot.SlotType.OFF_HAND:
			demo_item.item_id = "demo_shield"
			demo_item.item_name = "Demo Shield"
			demo_item.description = "A demonstration shield"
			demo_item.stat_modifiers = {"Defense": 6, "Health": 8}
			
		EquipmentSlot.SlotType.HELMET:
			demo_item.item_id = "demo_helmet"
			demo_item.item_name = "Demo Helmet"
			demo_item.description = "A demonstration helmet"
			demo_item.stat_modifiers = {"Defense": 4, "Health": 12}
			
		EquipmentSlot.SlotType.CHEST:
			demo_item.item_id = "demo_chest"
			demo_item.item_name = "Demo Chestplate"
			demo_item.description = "A demonstration chestplate"
			demo_item.stat_modifiers = {"Defense": 12, "Health": 20}
			demo_item.rarity = EquipmentItem.ItemRarity.RARE
			
		EquipmentSlot.SlotType.LEGS:
			demo_item.item_id = "demo_legs"
			demo_item.item_name = "Demo Leggings"
			demo_item.description = "Demonstration leg armor"
			demo_item.stat_modifiers = {"Defense": 8, "Movement": 2}
			
		EquipmentSlot.SlotType.HANDS:
			demo_item.item_id = "demo_gloves"
			demo_item.item_name = "Demo Gloves"
			demo_item.description = "Demonstration gloves"
			demo_item.stat_modifiers = {"Attack": 3, "Build": 2}
			
		EquipmentSlot.SlotType.FEET:
			demo_item.item_id = "demo_boots"
			demo_item.item_name = "Demo Boots"
			demo_item.description = "Demonstration boots"
			demo_item.stat_modifiers = {"Movement": 3, "Defense": 2}
			
		EquipmentSlot.SlotType.RING_1, EquipmentSlot.SlotType.RING_2:
			demo_item.item_id = "demo_ring"
			demo_item.item_name = "Demo Ring"
			demo_item.description = "A demonstration ring"
			demo_item.stat_modifiers = {"Critical_Chance": 2, "Critical_Damage": 8}
			demo_item.rarity = EquipmentItem.ItemRarity.EPIC
			
		EquipmentSlot.SlotType.NECKLACE:
			demo_item.item_id = "demo_necklace"
			demo_item.item_name = "Demo Necklace"
			demo_item.description = "A demonstration necklace"
			demo_item.stat_modifiers = {"Leadership": 4, "Morale_Bonus": 2}
			demo_item.rarity = EquipmentItem.ItemRarity.RARE
			
		EquipmentSlot.SlotType.BELT:
			demo_item.item_id = "demo_belt"
			demo_item.item_name = "Demo Belt"
			demo_item.description = "A demonstration belt"
			demo_item.stat_modifiers = {"Health": 15, "Supply_Management": 3}
	
	return demo_item

func _on_item_equipped(item: EquipmentItem, slot: EquipmentSlot.SlotType):
	"""Handle item equipped"""
	show_success("Equipped " + item.item_name)

func _on_item_unequipped(item: EquipmentItem, slot: EquipmentSlot.SlotType):
	"""Handle item unequipped"""
	show_info("Unequipped " + item.item_name)

func create_building_detail_view():
	"""Create the building detail view as part of the UI system"""
	building_detail_view = BuildingDetailView.new()
	building_detail_view.name = "BuildingDetailView"
	
	# Add to the menu manager so it's positioned with other menus
	menu_manager.add_child(building_detail_view)
	
	# Connect its signals
	building_detail_view.detail_view_closed.connect(_on_building_detail_closed)
	
	# Add to group for other components to find it
	building_detail_view.add_to_group("building_detail_views")

func show_building_detail(building: Building):
	"""Show building detail view for a specific building"""
	if building_detail_view:
		# Close other menus first
		close_all_menus()
		building_detail_view.show_for_building(building)
	else:
		print("BuildingDetailView not available")

func show_building_type_detail(building_type_name: String):
	"""Show building detail view for a building type"""
	if building_detail_view:
		# Close other menus first  
		close_all_menus()
		building_detail_view.show_for_building_type(building_type_name)
	else:
		print("BuildingDetailView not available")

func _on_building_detail_closed():
	"""Handle building detail view being closed"""
	print("Building detail view closed")

func setup_layout():
	"""Setup the overall layout"""
	var viewport_size = get_viewport().get_visible_rect().size
	size = viewport_size
	position = Vector2.ZERO
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Position components
	top_bar.setup_layout(viewport_size)
	bottom_bar.setup_layout(viewport_size)
	
	print("✅ Layout setup complete")

func connect_signals():
	"""Connect signals between components and GameManager"""
	print("Connecting signals...")
	
	# Connect GameManager signals to top bar
	GameManager.initial_turn.connect(top_bar._on_turn_changed)
	GameManager.turn_advanced.connect(top_bar._on_turn_changed)
	GameManager.action_points_spent.connect(top_bar._on_action_points_changed)
	
	# Connect bottom bar menu button signals
	bottom_bar.menu_button_pressed.connect(_on_menu_button_pressed)
	
		# Connect GameManager signals to ActionModeManager
	GameManager.action_points_spent.connect(action_mode_manager._on_action_points_changed)
	
	# Connect bottom bar menu button signals
	bottom_bar.menu_button_pressed.connect(_on_menu_button_pressed)
	
	# Connect confirmation dialog signals
	confirmation_dialog_manager.confirmed.connect(_on_confirmation_dialog_confirmed)
	confirmation_dialog_manager.cancelled.connect(_on_confirmation_dialog_cancelled)

	call_deferred("connect_build_manager_signals_deferred")
	print("✅ All signals connected")

# ═══════════════════════════════════════════════════════════
# MENU SYSTEM (Legacy Compatibility)
# ═══════════════════════════════════════════════════════════

func _on_menu_button_pressed(menu_type: String):
	"""Handle menu button presses"""
	match menu_type:
		"inventory":
			_on_inventory_button_pressed()
		"character":
			_on_character_button_pressed()
		"buildings":
			_on_buildings_button_pressed()

func _on_inventory_button_pressed():
	"""Handle inventory button press"""
	if inventory_menu:
		if inventory_menu.visible:
			inventory_menu.hide_menu()
			inventory_closed.emit()
		else:
			close_all_menus()
			inventory_menu.show_menu()
			inventory_opened.emit()

func _on_character_button_pressed():
	"""Handle character sheet button press"""
	if character_menu:
		if character_menu.visible:
			character_menu.hide_menu()
			character_closed.emit()
		else:
			close_all_menus()
			
			# Refresh character data before showing
			if character_menu is EnhancedCharacterMenu:
				character_menu.refresh_all_displays()
			
			character_menu.show_menu()
			character_opened.emit()

func _on_buildings_button_pressed():
	"""Handle buildings menu button press"""
	if building_menu:
		if building_menu.visible:
			building_menu.hide_menu()
			building_closed.emit()
		else:
			close_all_menus()
			
			# Refresh building data before showing
			building_menu.refresh_display()
			
			building_menu.show_menu()
			building_opened.emit()

func close_all_menus():
	"""Close all open menus"""
	if inventory_menu and inventory_menu.visible:
		inventory_menu.hide_menu()
		inventory_closed.emit()

	if character_menu and character_menu.visible:
		character_menu.hide_menu()
		character_closed.emit()
	
	if building_menu and building_menu.visible:
		building_menu.hide_menu()
		building_closed.emit()
		
	if building_detail_view and building_detail_view.is_showing():
		building_detail_view.hide_with_animation()

# ═══════════════════════════════════════════════════════════
# CONFIRMATION DIALOG SYSTEM
# ═══════════════════════════════════════════════════════════

func _on_confirmation_dialog_confirmed(action_data: Dictionary):
	"""Handle confirmation dialog confirmed"""
	match action_data.get("action_type", ""):
		"movement":
			GameManager.confirm_movement(action_data.target_position)
		"building":
			GameManager.confirm_building(action_data.target_position, action_data.building_type)
		"attack":
			GameManager.confirm_attack(action_data.target_position)
		"interaction":
			GameManager.confirm_interaction(action_data.target_position, action_data.interaction_type)

func _on_confirmation_dialog_cancelled():
	"""Handle confirmation dialog cancelled"""
	print("Action cancelled by user")
	# End the current mode when user cancels
	match GameManager.get_current_action_mode():
		GameManager.ActionMode.MOVEMENT:
			GameManager.end_movement_mode()
		GameManager.ActionMode.BUILD:
			GameManager.end_build_mode()
		GameManager.ActionMode.ATTACK:
			GameManager.end_all_action_modes()
		GameManager.ActionMode.INTERACT:
			GameManager.end_all_action_modes()

# ═══════════════════════════════════════════════════════════
# PUBLIC INTERFACE METHODS
# ═══════════════════════════════════════════════════════════

func connect_build_manager_signals():
	"""Connect BuildManager signals after it's initialized"""
	if GameManager and GameManager.build_manager:
		GameManager.build_manager.building_completed.connect(_on_building_placed)
		GameManager.build_manager.building_data_changed.connect(_on_building_data_changed)
		print("✅ Connected to BuildManager signals")
		
func connect_build_manager_signals_deferred():
	await get_tree().process_frame
	connect_build_manager_signals()
	
func show_movement_confirmation(target_tile: BiomeTile):
	"""Show movement confirmation dialog"""
	confirmation_dialog_manager.show_movement_confirmation(target_tile)

func show_build_confirmation(target_tile: BiomeTile, building_type: String):
	"""Show building confirmation dialog"""
	confirmation_dialog_manager.show_build_confirmation(target_tile, building_type)

func show_attack_confirmation(target_tile: BiomeTile):
	"""Show attack confirmation dialog"""
	confirmation_dialog_manager.show_attack_confirmation(target_tile)

func show_interact_confirmation(target_tile: BiomeTile, interaction_type: String):
	"""Show interaction confirmation dialog"""
	confirmation_dialog_manager.show_interact_confirmation(target_tile, interaction_type)

func show_notification(message: String, duration: float = 3.0, color: Color = Color.RED):
	"""Show a notification to the player"""
	notification_manager.show_notification(message, duration, color)

func update_action_button_states(active_mode):
	"""Update action button visual states"""
	if action_mode_manager:
		action_mode_manager.update_button_states(active_mode)

# Convenience notification methods
func show_success(message: String):
	"""Show success notification"""
	notification_manager.show_success(message)

func show_warning(message: String):
	"""Show warning notification"""
	notification_manager.show_warning(message)

func show_error(message: String):
	"""Show error notification"""
	notification_manager.show_error(message)

func show_info(message: String):
	"""Show info notification"""
	notification_manager.show_info(message)

# ═══════════════════════════════════════════════════════════
# RESOURCE AND CHARACTER UPDATES
# ═══════════════════════════════════════════════════════════

func update_resource(resource_name: String, amount: int):
	"""Update resource display"""
	if top_bar:
		top_bar.update_resource(resource_name, amount)

func update_character_info(name: String = "", level: int = -1, current_hp: int = -1, max_hp: int = -1):
	"""Update character information display"""
	if not top_bar:
		return
		
	if name != "":
		top_bar.update_character_name(name)
	if level >= 0:
		top_bar.update_character_level(level)
	if current_hp >= 0 and max_hp > 0:
		top_bar.update_character_hp(current_hp, max_hp)
# Add these new signal handlers
func _on_building_placed(new_building: Building, tile: BiomeTile):
	"""Handle new building placement - update BuildingMenu"""
	print("GameUI: Building placed, updating building menu")
	if building_menu:
		building_menu.refresh_display()

func _on_building_data_changed():
	"""Handle building data changes - refresh BuildingMenu"""
	print("GameUI: Building data changed, refreshing building menu")
	if building_menu:
		building_menu.refresh_display()
# ═══════════════════════════════════════════════════════════
# DEBUG AND UTILITY METHODS
# ═══════════════════════════════════════════════════════════

func debug_show_component_info():
	"""Debug method to show component information"""
	print("=== GameUI Component Info ===")
	print("TopBar: ", top_bar != null)
	print("BottomBar: ", bottom_bar != null)
	print("ActionModeManager: ", action_mode_manager != null)
	print("NotificationManager: ", notification_manager != null)
	print("ConfirmationDialogManager: ", confirmation_dialog_manager != null)
	print("MenuManager: ", menu_manager != null)
	print("===========================")

func get_component(component_name: String):
	"""Get a specific component by name"""
	match component_name.to_lower():
		"topbar":
			return top_bar
		"bottombar":
			return bottom_bar
		"actionmodemanager":
			return action_mode_manager
		"notificationmanager":
			return notification_manager
		"confirmationdialogmanager":
			return confirmation_dialog_manager
		"menumanager":
			return menu_manager
		_:
			print("Unknown component: ", component_name)
			return null
