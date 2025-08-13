# WarbandManager.gd - Basic Warband Management System
extends RefCounted
class_name WarbandManager

# Warband data
var warband_name: String = "The Iron Company"
var warband_level: int = 1
var members: Array = []

# Signals
signal member_added(member_data: Dictionary)
signal member_removed(member_index: int)
signal member_status_changed(member_index: int, new_status: String)

func _init():
	# Initialize with some sample members for testing
	add_sample_members()

func add_sample_members():
	"""Add some sample members for testing"""
	var sample_members = [
		{
			"name": "Sir Gareth",
			"level": 5,
			"class": "Knight",
			"portrait_path": "res://assets/portraits/knight.png",
			"hp": 85,
			"max_hp": 100,
			"status": "Ready",
			"experience": 1250,
			"skills": ["Sword Mastery", "Shield Wall"],
			"equipment": {}
		},
		{
			"name": "Elena Swift",
			"level": 3,
			"class": "Archer",
			"portrait_path": "res://assets/portraits/archer.png",
			"hp": 60,
			"max_hp": 75,
			"status": "Ready",
			"experience": 450,
			"skills": ["Precise Shot", "Eagle Eye"],
			"equipment": {}
		},
		{
			"name": "Magnus Iron",
			"level": 4,
			"class": "Warrior",
			"portrait_path": "res://assets/portraits/warrior.png",
			"hp": 45,
			"max_hp": 90,
			"status": "Injured",
			"experience": 800,
			"skills": ["Berserker Rage", "Thick Skin"],
			"equipment": {}
		},
		{
			"name": "Lydia Wise",
			"level": 6,
			"class": "Mage",
			"portrait_path": "res://assets/portraits/mage.png",
			"hp": 55,
			"max_hp": 65,
			"status": "Ready",
			"experience": 1800,
			"skills": ["Fireball", "Heal", "Mana Shield"],
			"equipment": {}
		}
	]
	
	for member in sample_members:
		members.append(member)

# Public interface methods
func get_warband_name() -> String:
	return warband_name

func set_warband_name(new_name: String):
	warband_name = new_name

func get_warband_level() -> int:
	return warband_level

func get_total_members() -> int:
	return members.size()

func get_member_count() -> int:
	return members.size()

func get_member(index: int) -> Dictionary:
	if index >= 0 and index < members.size():
		return members[index]
	return {}

func get_all_members() -> Array:
	return members.duplicate()

func add_member(member_data: Dictionary):
	"""Add a new member to the warband"""
	members.append(member_data)
	member_added.emit(member_data)

func remove_member(index: int):
	"""Remove a member from the warband"""
	if index >= 0 and index < members.size():
		members.remove_at(index)
		member_removed.emit(index)

func update_member_status(index: int, new_status: String):
	"""Update a member's status"""
	if index >= 0 and index < members.size():
		members[index]["status"] = new_status
		member_status_changed.emit(index, new_status)

func heal_member(index: int, amount: int):
	"""Heal a member"""
	if index >= 0 and index < members.size():
		var member = members[index]
		member["hp"] = min(member["hp"] + amount, member["max_hp"])
		
		# Update status if fully healed
		if member["hp"] >= member["max_hp"] and member["status"] == "Injured":
			update_member_status(index, "Ready")

func get_ready_members() -> Array:
	"""Get all members with 'Ready' status"""
	var ready_members = []
	for i in range(members.size()):
		if members[i].get("status", "Ready") == "Ready":
			ready_members.append({"index": i, "member": members[i]})
	return ready_members

func get_injured_members() -> Array:
	"""Get all members with 'Injured' status"""
	var injured_members = []
	for i in range(members.size()):
		if members[i].get("status", "Ready") == "Injured":
			injured_members.append({"index": i, "member": members[i]})
	return injured_members

func level_up_member(index: int):
	"""Level up a member"""
	if index >= 0 and index < members.size():
		members[index]["level"] += 1
		members[index]["max_hp"] += 10  # Simple HP increase
		members[index]["hp"] = members[index]["max_hp"]  # Full heal on level up

func add_experience_to_member(index: int, exp: int):
	"""Add experience to a member"""
	if index >= 0 and index < members.size():
		members[index]["experience"] = members[index].get("experience", 0) + exp
		
		# Simple level up check (every 500 exp)
		var current_exp = members[index]["experience"]
		var current_level = members[index]["level"]
		var required_exp = current_level * 500
		
		if current_exp >= required_exp:
			level_up_member(index)

# Save/Load functionality (basic)
func get_save_data() -> Dictionary:
	"""Get warband data for saving"""
	return {
		"warband_name": warband_name,
		"warband_level": warband_level,
		"members": members
	}

func load_save_data(data: Dictionary):
	"""Load warband data from save"""
	warband_name = data.get("warband_name", "The Iron Company")
	warband_level = data.get("warband_level", 1)
	members = data.get("members", [])

# Debug methods
func print_warband_info():
	"""Print warband information for debugging"""
	print("=== Warband Info ===")
	print("Name: ", warband_name)
	print("Level: ", warband_level)
	print("Total Members: ", members.size())
	for i in range(members.size()):
		var member = members[i]
		print("  ", i, ": ", member.get("name", "Unknown"), " (", member.get("class", "Unknown"), ") - Level ", member.get("level", 1))
	print("===================")

func get_warband_stats() -> Dictionary:
	"""Get overall warband statistics"""
	var stats = {
		"total_members": members.size(),
		"ready_members": 0,
		"injured_members": 0,
		"average_level": 0,
		"total_experience": 0
	}
	
	var total_level = 0
	for member in members:
		var status = member.get("status", "Ready")
		if status == "Ready":
			stats.ready_members += 1
		elif status == "Injured":
			stats.injured_members += 1
		
		total_level += member.get("level", 1)
		stats.total_experience += member.get("experience", 0)
	
	if members.size() > 0:
		stats.average_level = float(total_level) / float(members.size())
	
	return stats
