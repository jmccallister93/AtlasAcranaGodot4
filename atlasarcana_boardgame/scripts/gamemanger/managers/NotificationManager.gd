# NotificationManager.gd
extends Control
class_name NotificationManager

# Notification queue and management
var active_notifications: Array[Control] = []
var notification_queue: Array[Dictionary] = []
var max_visible_notifications: int = 3
var notification_spacing: int = 10

# Default notification settings
var default_duration: float = 3.0
var fade_in_time: float = 0.3
var fade_out_time: float = 0.3

func _ready():
	# Set up the notification manager
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1000  # Ensure notifications appear above everything
	
	# Fill the entire screen for positioning
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func show_notification(message: String, duration: float = 0.0, color: Color = Color.WHITE, notification_type: String = "info"):
	"""Show a notification with customizable properties"""
	if duration <= 0.0:
		duration = default_duration
	
	var notification_data = {
		"message": message,
		"duration": duration,
		"color": color,
		"type": notification_type,
		
	}
	
	# Add to queue or show immediately
	if active_notifications.size() < max_visible_notifications:
		create_and_show_notification(notification_data)
	else:
		notification_queue.append(notification_data)

func create_and_show_notification(notification_data: Dictionary):
	"""Create and display a notification"""
	var notification = create_notification_ui(notification_data)
	active_notifications.append(notification)
	add_child(notification)
	
	# Position the notification
	position_notification(notification)
	
	# Animate the notification
	animate_notification_in(notification, notification_data.duration)

func create_notification_ui(notification_data: Dictionary) -> Control:
	"""Create the UI for a single notification"""
	var container = PanelContainer.new()
	container.name = "Notification_" + str(Time.get_ticks_msec())
	
	# Create background style based on notification type
	var background_style = create_notification_style(notification_data.type, notification_data.color)
	container.add_theme_stylebox_override("panel", background_style)
	
	# Create content container
	var content = HBoxContainer.new()
	container.add_child(content)
	
	# Add icon based on type
	var icon = create_notification_icon(notification_data.type)
	if icon:
		content.add_child(icon)
	
	# Add message label
	var label = Label.new()
	label.text = notification_data.message
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(200, 0)
	content.add_child(label)
	
	# Add close button
	var close_button = create_close_button()
	close_button.pressed.connect(func(): remove_notification(container))
	content.add_child(close_button)
	
	return container

func create_notification_style(notification_type: String, base_color: Color) -> StyleBoxFlat:
	"""Create background style for notification"""
	var style = StyleBoxFlat.new()
	
	# Set background color based on type
	match notification_type:
		"success":
			style.bg_color = Color(0.2, 0.8, 0.2, 0.9)
		"warning":
			style.bg_color = Color(0.8, 0.6, 0.2, 0.9)
		"error":
			style.bg_color = Color(0.8, 0.2, 0.2, 0.9)
		"info":
			style.bg_color = Color(0.2, 0.6, 0.8, 0.9)
		_:
			style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
	
	# If a specific color was provided, use it
	if base_color != Color.WHITE:
		style.bg_color = Color(base_color.r, base_color.g, base_color.b, 0.9)
	
	# Border and corner styling
	style.border_color = Color.WHITE
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	# Content margins
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.content_margin_left = 15
	style.content_margin_right = 15
	
	return style

func create_notification_icon(notification_type: String) -> Control:
	"""Create an icon for the notification type"""
	var icon_container = Control.new()
	icon_container.custom_minimum_size = Vector2(20, 20)
	
	var icon_rect = ColorRect.new()
	icon_rect.size = Vector2(16, 16)
	icon_rect.position = Vector2(2, 2)
	
	match notification_type:
		"success":
			icon_rect.color = Color.GREEN
		"warning":
			icon_rect.color = Color.YELLOW
		"error":
			icon_rect.color = Color.RED
		"info":
			icon_rect.color = Color.CYAN
		_:
			icon_rect.color = Color.WHITE
	
	icon_container.add_child(icon_rect)
	return icon_container

func create_close_button() -> Button:
	"""Create a close button for notifications"""
	var button = Button.new()
	button.text = "×"
	button.custom_minimum_size = Vector2(20, 20)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)
	
	# Style the close button
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.5, 0.1, 0.1, 0.8)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	button.add_theme_stylebox_override("normal", style)
	
	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.7, 0.1, 0.1, 1.0)
	button.add_theme_stylebox_override("hover", hover_style)
	
	return button

func position_notification(notification: Control):
	"""Position a notification on screen"""
	var viewport_size = get_viewport().get_visible_rect().size
	var notification_height = 60  # Estimated height
	var margin = 20
	
	# Position from top-right corner
	var y_offset = margin
	for existing_notification in active_notifications:
		if existing_notification != notification:
			y_offset += notification_height + notification_spacing
	
	# Set position (will be refined after the notification is added to tree)
	call_deferred("_finalize_notification_position", notification, y_offset)

func _finalize_notification_position(notification: Control, y_offset: int):
	"""Finalize notification position after it's been added to tree"""
	var viewport_size = get_viewport().get_visible_rect().size
	var margin = 20
	
	# Get actual notification size
	var notification_size = notification.size
	if notification_size == Vector2.ZERO:
		notification_size = Vector2(300, 60)  # Fallback size
	
	# Position from top-right
	notification.position = Vector2(
		viewport_size.x - notification_size.x - margin,
		y_offset
	)

func animate_notification_in(notification: Control, duration: float):
	"""Animate notification appearing with correct Godot 4 syntax"""
	if not notification or not is_instance_valid(notification):
		print("Warning: Invalid notification passed to animate_notification_in")
		return
	
	# Start invisible and slide in from the right
	var start_pos = notification.position
	notification.position.x += 300
	notification.modulate.a = 0.0
	
	var tween = create_tween()
	
	# Ensure tween is valid
	if not tween:
		print("Error: Could not create tween for notification")
		notification.position = start_pos  # Reset position
		notification.modulate.a = 1.0     # Make visible
		return
	
	# Set up tween properties (parallel animations)
	tween.set_parallel(true)
	tween.tween_property(notification, "position:x", start_pos.x, fade_in_time)
	tween.tween_property(notification, "modulate:a", 1.0, fade_in_time)
	
	# Calculate display time with safety check
	var display_time = max(0.1, duration - fade_in_time - fade_out_time)
	
	# Chain the delay and callback (sequential operations)
	tween.set_parallel(false)
	tween.tween_interval(display_time)  # FIX: Use tween_interval() instead of tween_delay()
	tween.tween_callback(func(): 
		if is_instance_valid(notification):
			animate_notification_out(notification)
	)

func animate_notification_out(notification: Control):
	"""Animate notification disappearing with error handling"""
	if not notification or not is_instance_valid(notification):
		return
	
	var tween = create_tween()
	if not tween:
		remove_notification(notification)  # Fallback to immediate removal
		return
	
	tween.set_parallel(true)
	tween.tween_property(notification, "position:x", notification.position.x + 300, fade_out_time)
	tween.tween_property(notification, "modulate:a", 0.0, fade_out_time)
	tween.set_parallel(false)
	tween.tween_callback(func(): 
		if is_instance_valid(notification):
			remove_notification(notification)
	)
func remove_notification(notification: Control):
	"""Remove a notification and reposition others"""
	if notification in active_notifications:
		active_notifications.erase(notification)
		notification.queue_free()
		
		# Reposition remaining notifications
		reposition_notifications()
		
		# Show next queued notification if any
		if notification_queue.size() > 0:
			var next_notification_data = notification_queue.pop_front()
			create_and_show_notification(next_notification_data)

func reposition_notifications():
	"""Reposition all active notifications"""
	var y_offset = 20
	for notification in active_notifications:
		var tween = create_tween()
		tween.tween_property(notification, "position:y", y_offset, 0.2)
		y_offset += 70  # notification height + spacing

# Convenience methods for common notification types
func show_success(message: String, duration: float = 3.0):
	"""Show a success notification"""
	show_notification(message, duration, Color.GREEN, "success")

func show_warning(message: String, duration: float = 4.0):
	"""Show a warning notification"""
	show_notification(message, duration, Color.ORANGE, "warning")

func show_error(message: String, duration: float = 999.0):
	"""Show an error notification"""
	show_notification(message, duration, Color.RED, "error")

func show_info(message: String, duration: float = 3.0):
	"""Show an info notification"""
	show_notification(message, duration, Color.CYAN, "info")

func clear_all_notifications():
	"""Clear all notifications immediately"""
	for notification in active_notifications:
		notification.queue_free()
	active_notifications.clear()
	notification_queue.clear()

# Configuration methods
func set_max_notifications(max_count: int):
	"""Set maximum number of visible notifications"""
	max_visible_notifications = max_count

func set_default_duration(duration: float):
	"""Set default notification duration"""
	default_duration = duration
