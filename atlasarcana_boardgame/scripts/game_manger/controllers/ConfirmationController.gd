# ConfirmationController.gd
extends Node
class_name ConfirmationController

signal confirmation_timeout(confirmation_type: String)
signal confirmation_completed(confirmation_type: String, result: bool)

enum ConfirmationType {
	MOVEMENT,
	BUILD,
	ATTACK,
	INTERACT
}

# Pending confirmations storage
var pending_confirmations: Dictionary = {}

# Timeout settings
var confirmation_timeout_duration: float = 30.0  # 30 seconds
var timeout_timers: Dictionary = {}

func _ready():
	"""Initialize the confirmation controller"""
	print("ConfirmationController: Initialized")

# ═══════════════════════════════════════════════════════════
# CONFIRMATION REGISTRATION
# ═══════════════════════════════════════════════════════════

func register_pending_confirmation(confirmation_type: String, data: Dictionary):
	"""Register a new pending confirmation"""
	print("ConfirmationController: Registering confirmation - ", confirmation_type)
	
	# Store the confirmation data
	pending_confirmations[confirmation_type] = {
		"data": data,
		"timestamp": Time.get_ticks_msec()
	}
	
	# Start timeout timer
	_start_timeout_timer(confirmation_type)

func clear_confirmation(confirmation_type: String):
	"""Clear a pending confirmation"""
	if pending_confirmations.has(confirmation_type):
		print("ConfirmationController: Clearing confirmation - ", confirmation_type)
		pending_confirmations.erase(confirmation_type)
		_stop_timeout_timer(confirmation_type)
		confirmation_completed.emit(confirmation_type, true)

func cancel_confirmation(confirmation_type: String):
	"""Cancel a pending confirmation"""
	if pending_confirmations.has(confirmation_type):
		print("ConfirmationController: Cancelling confirmation - ", confirmation_type)
		pending_confirmations.erase(confirmation_type)
		_stop_timeout_timer(confirmation_type)
		confirmation_completed.emit(confirmation_type, false)

# ═══════════════════════════════════════════════════════════
# CONFIRMATION QUERIES
# ═══════════════════════════════════════════════════════════

func has_pending_confirmation(confirmation_type: String) -> bool:
	"""Check if a specific confirmation is pending"""
	return pending_confirmations.has(confirmation_type)

func get_pending_confirmation_data(confirmation_type: String) -> Dictionary:
	"""Get data for a pending confirmation"""
	if pending_confirmations.has(confirmation_type):
		return pending_confirmations[confirmation_type]["data"]
	return {}

func get_pending_confirmations() -> Array:
	"""Get all pending confirmation types"""
	return pending_confirmations.keys()

func get_pending_count() -> int:
	"""Get number of pending confirmations"""
	return pending_confirmations.size()

func is_any_confirmation_pending() -> bool:
	"""Check if any confirmations are pending"""
	return pending_confirmations.size() > 0

# ═══════════════════════════════════════════════════════════
# TIMEOUT MANAGEMENT
# ═══════════════════════════════════════════════════════════

func _start_timeout_timer(confirmation_type: String):
	"""Start a timeout timer for a confirmation"""
	# Stop existing timer if it exists
	_stop_timeout_timer(confirmation_type)
	
	# Create new timer
	var timer = Timer.new()
	timer.wait_time = confirmation_timeout_duration
	timer.one_shot = true
	timer.timeout.connect(_on_confirmation_timeout.bind(confirmation_type))
	
	add_child(timer)
	timeout_timers[confirmation_type] = timer
	timer.start()
	
	print("ConfirmationController: Started timeout timer for ", confirmation_type)

func _stop_timeout_timer(confirmation_type: String):
	"""Stop the timeout timer for a confirmation"""
	if timeout_timers.has(confirmation_type):
		var timer = timeout_timers[confirmation_type]
		if is_instance_valid(timer):
			timer.queue_free()
		timeout_timers.erase(confirmation_type)

func _on_confirmation_timeout(confirmation_type: String):
	"""Handle confirmation timeout"""
	print("ConfirmationController: Confirmation timed out - ", confirmation_type)
	
	# Clean up the confirmation
	if pending_confirmations.has(confirmation_type):
		pending_confirmations.erase(confirmation_type)
	
	_stop_timeout_timer(confirmation_type)
	confirmation_timeout.emit(confirmation_type)

# ═══════════════════════════════════════════════════════════
# BULK OPERATIONS
# ═══════════════════════════════════════════════════════════

func clear_all_confirmations():
	"""Clear all pending confirmations"""
	print("ConfirmationController: Clearing all confirmations")
	
	for confirmation_type in pending_confirmations.keys():
		clear_confirmation(confirmation_type)

func cancel_all_confirmations():
	"""Cancel all pending confirmations"""
	print("ConfirmationController: Cancelling all confirmations")
	
	for confirmation_type in pending_confirmations.keys():
		cancel_confirmation(confirmation_type)

# ═══════════════════════════════════════════════════════════
# CONFIRMATION TIMEOUT SETTINGS
# ═══════════════════════════════════════════════════════════

func set_timeout_duration(duration: float):
	"""Set the timeout duration for confirmations"""
	confirmation_timeout_duration = max(5.0, duration)  # Minimum 5 seconds
	print("ConfirmationController: Timeout duration set to ", confirmation_timeout_duration)

func get_timeout_duration() -> float:
	"""Get the current timeout duration"""
	return confirmation_timeout_duration

# ═══════════════════════════════════════════════════════════
# CONFIRMATION STATUS TRACKING
# ═══════════════════════════════════════════════════════════

func get_confirmation_age(confirmation_type: String) -> float:
	"""Get how long a confirmation has been pending (in seconds)"""
	if pending_confirmations.has(confirmation_type):
		var start_time = pending_confirmations[confirmation_type]["timestamp"]
		var current_time = Time.get_ticks_msec()
		return (current_time - start_time) / 1000.0
	return 0.0

func get_confirmation_remaining_time(confirmation_type: String) -> float:
	"""Get remaining time before confirmation timeout"""
	var age = get_confirmation_age(confirmation_type)
	return max(0.0, confirmation_timeout_duration - age)

func is_confirmation_close_to_timeout(confirmation_type: String, warning_threshold: float = 5.0) -> bool:
	"""Check if confirmation is close to timing out"""
	var remaining = get_confirmation_remaining_time(confirmation_type)
	return remaining <= warning_threshold and remaining > 0.0

# ═══════════════════════════════════════════════════════════
# VALIDATION HELPERS
# ═══════════════════════════════════════════════════════════

func validate_confirmation_data(confirmation_type: String, required_keys: Array) -> bool:
	"""Validate that confirmation data contains required keys"""
	if not pending_confirmations.has(confirmation_type):
		return false
	
	var data = pending_confirmations[confirmation_type]["data"]
	for key in required_keys:
		if not data.has(key):
			print("ConfirmationController: Missing required key '", key, "' in ", confirmation_type)
			return false
	
	return true

# ═══════════════════════════════════════════════════════════
# DEBUG AND MONITORING
# ═══════════════════════════════════════════════════════════

func debug_pending_confirmations():
	"""Debug print all pending confirmations"""
	print("ConfirmationController Debug:")
	print("  Total pending: ", pending_confirmations.size())
	
	for confirmation_type in pending_confirmations:
		var age = get_confirmation_age(confirmation_type)
		var remaining = get_confirmation_remaining_time(confirmation_type)
		print("  ", confirmation_type, ": Age=", "%.1f" % age, "s, Remaining=", "%.1f" % remaining, "s")

func get_confirmation_summary() -> Dictionary:
	"""Get a summary of all pending confirmations"""
	var summary = {}
	
	for confirmation_type in pending_confirmations:
		summary[confirmation_type] = {
			"age": get_confirmation_age(confirmation_type),
			"remaining": get_confirmation_remaining_time(confirmation_type),
			"close_to_timeout": is_confirmation_close_to_timeout(confirmation_type)
		}
	
	return summary

# ═══════════════════════════════════════════════════════════
# CLEANUP
# ═══════════════════════════════════════════════════════════

func cleanup():
	"""Clean up all confirmations and timers"""
	print("ConfirmationController: Cleaning up...")
	
	# Stop all timers
	for timer in timeout_timers.values():
		if is_instance_valid(timer):
			timer.queue_free()
	
	timeout_timers.clear()
	pending_confirmations.clear()
	
	print("ConfirmationController: Cleanup complete")

func _exit_tree():
	"""Handle node removal"""
	cleanup()
