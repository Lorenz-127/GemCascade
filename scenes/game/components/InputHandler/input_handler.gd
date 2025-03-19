class_name InputHandler
extends Node

# Signals
signal gem_selected(gem, grid_position)
signal gem_deselected()
signal swap_attempted(gem1, gem2)

# References
var grid_manager: GridManager
var gem_manager: GemManager

# State
var selected_gem = null
var input_enabled = true

func _ready():
	pass

func initialize(grid_mgr: GridManager, gem_mgr: GemManager):
	grid_manager = grid_mgr
	gem_manager = gem_mgr
	
	# Enable input by default
	input_enabled = true

# Enables player input processing
func enable_input():
	input_enabled = true

# Disables player input processing
func disable_input():
	input_enabled = false

# Gets the currently selected gem
func get_selected_gem():
	return selected_gem

# Process input event
func _input(event):
	if !input_enabled:
		return
		
	# Handle gem selection with mouse/touch
	if event.is_action_pressed("gem_select"):
		handle_selection()
		
	# Handle gem deselection
	if event.is_action_pressed("gem_deselect"):
		deselect_current_gem()
		
	# Process keyboard input
	process_keyboard_input(event)

# Handle gem selection
func handle_selection():
	# Get the mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Convert to grid coordinates
	var grid_pos = grid_manager.pixel_to_grid(mouse_pos.x, mouse_pos.y)
	
	# Check if position is valid
	if grid_manager.is_within_grid(grid_pos.x, grid_pos.y):
		var gem = grid_manager.get_gem_at(grid_pos.x, grid_pos.y)
		
		# Ignore null or matched gems
		if gem == null or gem.matched:
			return
			
		# If no gem is currently selected
		if selected_gem == null:
			# Select this gem
			selected_gem = gem
			highlight_gem(gem)
			emit_signal("gem_selected", gem, grid_pos)
		
		# If a gem is already selected
		else:
			# Store the second gem
			var second_gem = gem
			
			# Check if they're different gems
			if selected_gem != second_gem:
				# Check if they're adjacent
				if are_adjacent(selected_gem, second_gem):
					# Attempt to swap
					emit_signal("swap_attempted", selected_gem, second_gem)
				else:
					# Not adjacent, provide feedback
					play_invalid_move_feedback()
					
					# Deselect first gem
					unhighlight_gem(selected_gem)
					
					# Make this the new selected gem
					selected_gem = second_gem
					highlight_gem(selected_gem)
					emit_signal("gem_selected", selected_gem, grid_pos)
			else:
				# Same gem clicked, just deselect
				deselect_current_gem()

# Call this function after a swap has been completed
func on_swap_completed():
	deselect_current_gem()

# Check if two gems are adjacent
func are_adjacent(gem1, gem2) -> bool:
	var pos1 = find_gem_position(gem1)
	var pos2 = find_gem_position(gem2)
	
	if pos1.x == -1 or pos2.x == -1:
		return false
	
	return (abs(pos1.x - pos2.x) == 1 and pos1.y == pos2.y) or \
		   (abs(pos1.y - pos2.y) == 1 and pos1.x == pos2.x)

# Find the grid position of a gem
func find_gem_position(gem) -> Vector2i:
	var dims = grid_manager.get_grid_dimensions()
	for x in range(dims.x):
		for y in range(dims.y):
			if grid_manager.get_gem_at(x, y) == gem:
				return Vector2i(x, y)
	
	return Vector2i(-1, -1)

# Highlight a gem
func highlight_gem(gem):
	if gem:
		gem.highlight()

# Remove highlight from a gem
func unhighlight_gem(gem):
	if gem:
		gem.unhighlight()

# Deselect the current gem
func deselect_current_gem():
	if selected_gem:
		unhighlight_gem(selected_gem)
		selected_gem = null
		emit_signal("gem_deselected")

# Provide feedback for invalid moves
func play_invalid_move_feedback():
	# Play an animation or sound effect
	# For now, let's just make the gems shake
	if selected_gem != null:
		selected_gem.shake_gem()

# Process keyboard input
func process_keyboard_input(event):
	# Implement arrow key navigation
	# This would be for accessibility purposes
	# You can add this functionality later
	pass
