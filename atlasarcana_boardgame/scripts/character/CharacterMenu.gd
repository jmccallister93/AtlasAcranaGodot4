# CharacterMenu.gd (Modified for Skills Only)
extends BaseMenu
class_name CharacterMenu

# Skills Panel Components
var skills_panel: PanelContainer
var skills_categories_container: VBoxContainer

# Tooltip system
var tooltip: PanelContainer
var tooltip_timer: Timer
var current_hovered_item: Control

# References
var character_stats: CharacterStats
var skill_manager: SkillManager

# Signals for skills
signal skill_learned(skill: SkillNode)
signal skill_unlearned(skill: SkillNode)

func ready_post():
	menu_title = "Character Skills"
	title_label.text = menu_title
	initialize_references()
	create_skills_interface()
	connect_signals()

func initialize_references():
	"""Initialize references to game systems"""
	# Get character from GameManager
	if GameManager and GameManager.character:
		var character = GameManager.character
		
		# Get or create character stats
		if character.stats is CharacterStats:
			character_stats = character.stats
		else:
			# Convert old stats to new system
			character_stats = CharacterStats.new()
			character_stats.character_name = character.stats.character_name if character.stats else "Hero"
			character.stats = character_stats
		
		# Create skill manager (same approach)
		if character.has_method("get_skill_manager") and character.get_skill_manager():
			skill_manager = character.get_skill_manager()
		elif character.skill_manager:
			skill_manager = character.skill_manager
		else:
			skill_manager = SkillManager.new()
			character.skill_manager = skill_manager
		
		skill_manager.set_character_stats(character_stats)
		character_stats.set_skill_manager(skill_manager)
		
		# Give some initial skill points for testing
		if not skill_manager.has_method("get_skill_points") or skill_manager.get_skill_points() == 0:
			skill_manager.add_skill_points(10)

func create_skills_interface():
	"""Create the skills-only interface"""
	# Clear existing content
	for child in item_container.get_children():
		child.queue_free()
	
	create_main_layout()
	create_tooltip_system()
	
	# Initial data refresh
	refresh_all_displays()

func create_main_layout():
	"""Create the main layout for skills"""
	create_skills_panel()
	item_container.add_child(skills_panel)

func create_skills_panel():
	"""Create the skills panel"""
	skills_panel = PanelContainer.new()
	skills_panel.custom_minimum_size = Vector2(600, 500)
	skills_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skills_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.2, 0.9)
	style.border_color = Color(0.4, 0.5, 0.7)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	skills_panel.add_theme_stylebox_override("panel", style)
	
	# Create scrollable container for skills
	var skills_scroll = ScrollContainer.new()
	skills_categories_container = VBoxContainer.new()
	skills_categories_container.add_theme_constant_override("separation", 20)
	
	# Create skills content
	create_skills_content()
	
	skills_scroll.add_child(skills_categories_container)
	skills_panel.add_child(skills_scroll)

func create_skills_content():
	"""Create all skills content"""
	# Character info header
	create_character_info_header()
	
	# Skill points display
	create_skill_points_display()
	
	# Skill trees
	if skill_manager:
		for tree in skill_manager.get_all_skill_trees():
			var tree_display = create_skill_tree_display(tree)
			skills_categories_container.add_child(tree_display)

func create_character_info_header():
	"""Create character information header"""
	var header_container = VBoxContainer.new()
	header_container.add_theme_constant_override("separation", 10)
	
	# Character name and level
	var character_header = Label.new()
	if character_stats:
		character_header.text = character_stats.character_name + " - Level " + str(character_stats.character_level)
	else:
		character_header.text = "Character Skills"
	character_header.add_theme_font_size_override("font_size", 20)
	character_header.add_theme_color_override("font_color", Color.GOLD)
	character_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_container.add_child(character_header)
	
	# Experience information
	if character_stats:
		var exp_label = Label.new()
		exp_label.text = "Experience: " + str(character_stats.experience)
		exp_label.add_theme_font_size_override("font_size", 14)
		exp_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
		exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header_container.add_child(exp_label)
	
	# Separator
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 5)
	header_container.add_child(separator)
	
	skills_categories_container.add_child(header_container)

func create_skill_points_display():
	"""Create skill points display"""
	var sp_container = HBoxContainer.new()
	sp_container.alignment = BoxContainer.ALIGNMENT_CENTER
	sp_container.add_theme_constant_override("separation", 10)
	
	var sp_label = Label.new()
	sp_label.text = "Available Skill Points: "
	sp_label.add_theme_font_size_override("font_size", 16)
	sp_label.add_theme_color_override("font_color", Color.WHITE)
	sp_container.add_child(sp_label)
	
	var sp_value = Label.new()
	sp_value.name = "SkillPointsValue"
	#sp_value.text = str(skill_manager.get_skill_points() if skill_manager else "0")
	sp_value.add_theme_font_size_override("font_size", 18)
	sp_value.add_theme_color_override("font_color", Color.YELLOW)
	sp_container.add_child(sp_value)
	
	# Add skill points button for testing
	var add_sp_button = Button.new()
	add_sp_button.text = "+5 SP"
	add_sp_button.custom_minimum_size = Vector2(60, 30)
	add_sp_button.pressed.connect(_on_add_skill_points_pressed)
	sp_container.add_child(add_sp_button)
	
	skills_categories_container.add_child(sp_container)

func create_skill_tree_display(tree: SkillTree) -> VBoxContainer:
	"""Create display for a skill tree"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 15)
	
	# Tree header with background
	var header_panel = PanelContainer.new()
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = tree.tree_color * 0.3
	header_style.border_color = tree.tree_color
	header_style.border_width_left = 2
	header_style.border_width_right = 2
	header_style.border_width_top = 2
	header_style.border_width_bottom = 2
	header_style.corner_radius_top_left = 6
	header_style.corner_radius_top_right = 6
	header_style.corner_radius_bottom_left = 6
	header_style.corner_radius_bottom_right = 6
	header_panel.add_theme_stylebox_override("panel", header_style)
	
	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 5)
	
	var header = Label.new()
	header.text = tree.tree_name
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", tree.tree_color)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_vbox.add_child(header)
	
	# Tree description
	var desc = Label.new()
	desc.text = tree.tree_description
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_vbox.add_child(desc)
	
	header_panel.add_child(header_vbox)
	container.add_child(header_panel)
	
	# Skills grid
	var skills_grid = GridContainer.new()
	skills_grid.columns = 4  # More columns for better layout
	skills_grid.add_theme_constant_override("h_separation", 15)
	skills_grid.add_theme_constant_override("v_separation", 15)
	
	for skill in tree.get_all_skills():
		var skill_button = create_skill_button(skill)
		skills_grid.add_child(skill_button)
	
	container.add_child(skills_grid)
	
	return container

func create_skill_button(skill: SkillNode) -> Button:
	"""Create a button for a skill"""
	var button = Button.new()
	button.custom_minimum_size = Vector2(120, 100)
	
	# Create skill button text with better formatting
	var button_text = skill.skill_name + "\n"
	button_text += "Level: " + str(skill.current_level) + "/" + str(skill.max_level) + "\n"
	
	# Add cost information
	#if skill.current_level < skill.max_level:
		#var cost = skill.get_skill_point_cost(skill.current_level + 1)
		#button_text += "Cost: " + str(cost) + " SP"
	#else:
		#button_text += "MAXED"
	
	button.text = button_text
	
	# Style based on skill state
	var style = StyleBoxFlat.new()
	var text_color = Color.WHITE
	
	if skill.current_level >= skill.max_level:
		# Maxed skill
		style.bg_color = Color(0.2, 0.6, 0.2, 0.9)  # Green for maxed
		style.border_color = Color.GREEN
		text_color = Color.WHITE
	elif skill.is_learned():
		# Learned but not maxed
		style.bg_color = Color(0.4, 0.4, 0.8, 0.9)  # Blue for learned
		style.border_color = Color.CYAN
		text_color = Color.WHITE
	elif skill_manager and skill_manager.get_skill_tree(skill.tree_category).can_learn_skill(skill, character_stats, skill_manager.learned_skills):
		# Available to learn
		style.bg_color = Color(0.8, 0.6, 0.2, 0.9)  # Gold for available
		style.border_color = Color.YELLOW
		text_color = Color.BLACK
	else:
		# Locked
		style.bg_color = Color(0.3, 0.3, 0.3, 0.8)  # Gray for locked
		style.border_color = Color.GRAY
		text_color = Color.LIGHT_GRAY
	
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	button.add_theme_stylebox_override("normal", style)
	
	# Hover effect
	var hover_style = style.duplicate()
	hover_style.bg_color = hover_style.bg_color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover_style)
	
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_font_size_override("font_size", 10)
	
	# Connect signals
	button.pressed.connect(_on_skill_button_clicked.bind(skill))
	button.mouse_entered.connect(_on_skill_mouse_entered.bind(skill, button))
	button.mouse_exited.connect(_on_skill_mouse_exited.bind(skill))
	
	return button

func create_tooltip_system():
	"""Create the tooltip system"""
	tooltip_timer = Timer.new()
	tooltip_timer.wait_time = 0.8
	tooltip_timer.one_shot = true
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
	add_child(tooltip_timer)
	
	tooltip = PanelContainer.new()
	tooltip.visible = false
	tooltip.z_index = 100
	
	var tooltip_style = StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	tooltip_style.border_color = Color.YELLOW
	tooltip_style.border_width_left = 2
	tooltip_style.border_width_right = 2
	tooltip_style.border_width_top = 2
	tooltip_style.border_width_bottom = 2
	tooltip_style.corner_radius_top_left = 6
	tooltip_style.corner_radius_top_right = 6
	tooltip_style.corner_radius_bottom_left = 6
	tooltip_style.corner_radius_bottom_right = 6
	tooltip.add_theme_stylebox_override("panel", tooltip_style)
	
	var tooltip_label = RichTextLabel.new()
	tooltip_label.name = "TooltipLabel"
	tooltip_label.bbcode_enabled = true
	tooltip_label.custom_minimum_size = Vector2(250, 100)
	tooltip_label.fit_content = true
	tooltip.add_child(tooltip_label)
	
	add_child(tooltip)

func connect_signals():
	"""Connect all signals"""
	if skill_manager:
		if skill_manager.skill_learned.is_connected(_on_skill_learned_internal):
			skill_manager.skill_learned.disconnect(_on_skill_learned_internal)
		if skill_manager.skill_unlearned.is_connected(_on_skill_unlearned_internal):
			skill_manager.skill_unlearned.disconnect(_on_skill_unlearned_internal)
		if skill_manager.skill_points_changed.is_connected(_on_skill_points_changed):
			skill_manager.skill_points_changed.disconnect(_on_skill_points_changed)
			
		skill_manager.skill_learned.connect(_on_skill_learned_internal)
		skill_manager.skill_unlearned.connect(_on_skill_unlearned_internal)
		skill_manager.skill_points_changed.connect(_on_skill_points_changed)

# Event handlers
func _on_skill_button_clicked(skill: SkillNode):
	"""Handle skill button click"""
	if not skill_manager:
		return
		
	if skill.current_level >= skill.max_level:
		# Already maxed
		if GameManager and GameManager.game_ui:
			GameManager.game_ui.show_info("Skill is already at maximum level!")
		return
		
	if skill.is_learned():
		# Try to level up
		if skill_manager.can_level_up_skill(skill.skill_id):
			skill_manager.level_up_skill(skill.skill_id)
		else:
			if GameManager and GameManager.game_ui:
				GameManager.game_ui.show_warning("Not enough skill points to level up this skill!")
	else:
		# Try to learn
		if skill_manager.can_learn_skill(skill.skill_id):
			skill_manager.learn_skill(skill.skill_id)
		else:
			if GameManager and GameManager.game_ui:
				var tree = skill_manager.get_skill_tree(skill.tree_category)
				if not tree.can_learn_skill(skill, character_stats, skill_manager.learned_skills):
					GameManager.game_ui.show_warning("Requirements not met for this skill!")
				else:
					GameManager.game_ui.show_warning("Not enough skill points!")

func _on_add_skill_points_pressed():
	"""Add skill points for testing"""
	if skill_manager:
		skill_manager.add_skill_points(5)
		if GameManager and GameManager.game_ui:
			GameManager.game_ui.show_success("Added 5 skill points!")

func _on_skill_learned_internal(skill: SkillNode):
	"""Handle skill learned internally"""
	refresh_skills_display()
	skill_learned.emit(skill)
	
	if GameManager and GameManager.game_ui:
		GameManager.game_ui.show_success("Learned: " + skill.skill_name)

func _on_skill_unlearned_internal(skill: SkillNode):
	"""Handle skill unlearned internally"""
	refresh_skills_display()
	skill_unlearned.emit(skill)
	
	if GameManager and GameManager.game_ui:
		GameManager.game_ui.show_info("Unlearned: " + skill.skill_name)

func _on_skill_points_changed(current_points: int):
	"""Handle skill points changed"""
	var sp_label = skills_categories_container.get_node_or_null("HBoxContainer/SkillPointsValue")
	if sp_label:
		sp_label.text = str(current_points)

func _on_skill_mouse_entered(skill: SkillNode, button: Button):
	"""Handle mouse enter on skill"""
	current_hovered_item = button
	tooltip_timer.start()

func _on_skill_mouse_exited(skill: SkillNode):
	"""Handle mouse exit on skill"""
	current_hovered_item = null
	tooltip_timer.stop()
	tooltip.visible = false

func _on_tooltip_timer_timeout():
	"""Handle tooltip timer timeout"""
	if current_hovered_item:
		show_skill_tooltip(current_hovered_item)

func show_skill_tooltip(button: Button):
	"""Show tooltip for a skill button"""
	# Find the skill associated with this button
	var skill = find_skill_for_button(button)
	if not skill:
		return
	
	var tooltip_label = tooltip.get_node("TooltipLabel")
	var tooltip_text = create_skill_tooltip_text(skill)
	
	tooltip_label.text = tooltip_text
	
	# Position tooltip
	var mouse_pos = get_global_mouse_position() - global_position
	tooltip.position = mouse_pos + Vector2(15, -15)
	
	# Keep tooltip in bounds
	var menu_rect = get_rect()
	tooltip.position.x = clamp(tooltip.position.x, 10, menu_rect.size.x - 300)
	tooltip.position.y = clamp(tooltip.position.y, 10, menu_rect.size.y - 150)
	
	tooltip.visible = true

func find_skill_for_button(button: Button) -> SkillNode:
	"""Find the skill associated with a button"""
	if not skill_manager:
		return null
	
	# This is a bit of a hack - we could store skill references in button metadata
	# For now, we'll find by name in the button text
	var button_text = button.text
	var skill_name = button_text.split("\n")[0]
	
	for tree in skill_manager.get_all_skill_trees():
		for skill in tree.get_all_skills():
			if skill.skill_name == skill_name:
				return skill
	
	return null

func create_skill_tooltip_text(skill: SkillNode) -> String:
	"""Create tooltip text for a skill"""
	pass
	return ""
	#var text = "[b]" + skill.skill_name + "[/b]\n\n"
	#text += skill.skill_description + "\n\n"
	#
	#text += "[color=yellow]Current Level:[/color] " + str(skill.current_level) + "/" + str(skill.max_level) + "\n"
	#
	#if skill.current_level < skill.max_level:
		#var cost = skill.get_skill_point_cost(skill.current_level + 1)
		#text += "[color=cyan]Next Level Cost:[/color] " + str(cost) + " SP\n"
	#
	## Show requirements if not met
	#if not skill.is_learned() and skill_manager:
		#var tree = skill_manager.get_skill_tree(skill.tree_category)
		#if not tree.can_learn_skill(skill, character_stats, skill_manager.learned_skills):
			#text += "\n[color=red]Requirements not met[/color]\n"
			#
			## Show specific requirements
			#for req_stat in skill.stat_requirements:
				#var required_value = skill.stat_requirements[req_stat]
				#var current_value = character_stats.get_stat_value("combat", req_stat) if character_stats else 0
				#var color = "green" if current_value >= required_value else "red"
				#text += "[color=" + color + "]• " + req_stat.replace("_", " ") + ": " + str(current_value) + "/" + str(required_value) + "[/color]\n"
	#
	## Show current effects
	#if skill.is_learned():
		#text += "\n[color=lightgreen]Current Effects:[/color]\n"
		#for effect in skill.skill_effects:
			#text += "• " + effect + "\n"
	#
	#return text

# Display update methods
func refresh_all_displays():
	"""Public method to refresh all displays"""
	if not is_inside_tree():
		return
	
	refresh_skills_display()

func refresh_skills_display():
	"""Refresh the skills display"""
	if not skills_categories_container:
		return
	
	# Clear and recreate skills display
	for child in skills_categories_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	create_skills_content()
