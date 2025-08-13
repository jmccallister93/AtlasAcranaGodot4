# MenuManager.gd
extends Control
class_name MenuManager

# This is a simple container for legacy menu system
# In the future, this could be expanded to handle menu animations,
# transitions, and more sophisticated menu management

var active_menus: Array[Control] = []

func _ready():
	# Make sure this doesn't interfere with other UI
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50  # Above game UI but below notifications/dialogs

func register_menu(menu: Control):
	"""Register a menu with the manager"""
	if menu not in active_menus:
		active_menus.append(menu)

func unregister_menu(menu: Control):
	"""Unregister a menu from the manager"""
	active_menus.erase(menu)

func close_all_menus():
	"""Close all registered menus"""
	for menu in active_menus:
		if menu.has_method("hide_menu"):
			menu.hide_menu()
		else:
			menu.hide()

func is_any_menu_open() -> bool:
	"""Check if any menu is currently open"""
	for menu in active_menus:
		if menu.visible:
			return true
	return false

func get_open_menus() -> Array[Control]:
	"""Get all currently open menus"""
	var open_menus: Array[Control] = []
	for menu in active_menus:
		if menu.visible:
			open_menus.append(menu)
	return open_menus
