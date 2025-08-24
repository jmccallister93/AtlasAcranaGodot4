# ManagerStub.gd - Stub implementation for missing manager classes
extends Node
class_name ManagerStub

var manager_type: String = "Unknown"
var character: Character
var map_manager

func _ready():
	"""Initialize the manager stub"""
	manager_type = name.replace("_Stub", "")
	print("ManagerStub created for: ", manager_type)

# Common methods that managers might have
func initialize(char: Character, map):
	"""Safe initialization method"""
	character = char
	map_manager = map
	print("ManagerStub initialized: ", manager_type)

func set_character(char: Character):
	"""Set character reference"""
	character = char
	print("ManagerStub character set: ", manager_type)

func set_map_manager(map):
	"""Set map manager reference"""
	map_manager = map
	print("ManagerStub map manager set: ", manager_type)

# Stub methods for common manager functionality
func start_mode():
	"""Stub for start mode methods"""
	print("ManagerStub: start_mode called on ", manager_type, " (stub - no implementation)")

func end_mode():
	"""Stub for end mode methods"""
	print("ManagerStub: end_mode called on ", manager_type, " (stub - no implementation)")

func can_perform_action() -> bool:
	"""Stub for action validation"""
	print("ManagerStub: can_perform_action called on ", manager_type, " (stub - returning false)")
	return false

func perform_action(position = null, data = null):
	"""Stub for action execution"""
	print("ManagerStub: perform_action called on ", manager_type, " (stub - no implementation)")

# Handle any method calls dynamically
func _get(property):
	"""Handle unknown property access"""
	print("ManagerStub: Property '", property, "' accessed on ", manager_type, " (stub)")
	return null

func _set(property, value):
	"""Handle unknown property setting"""
	print("ManagerStub: Property '", property, "' set to '", value, "' on ", manager_type, " (stub)")
	return true

# Override has_method to return true for common methods
#func has_method(method_name: String) -> bool:
	#"""Return true for common manager methods"""
	#var common_methods = [
		#"initialize", "set_character", "set_map_manager",
		#"start_mode", "end_mode", "can_perform_action", "perform_action"
	#]
	#
	#if method_name in common_methods:
		#return true
	#
	## Check if the method actually exists
	#return super.has_method(method_name)

# Debug method
func debug_info():
	"""Print debug information about this stub"""
	print("=== ManagerStub Debug ===")
	print("Type: ", manager_type)
	print("Character: ", character.name if character else "None")
	print("Map Manager: ", map_manager.name if map_manager else "None")
	print("========================")
