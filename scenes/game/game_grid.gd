extends Node2D

enum GameState {WAITING_INPUT, GEM_SELECTED, PROCESSING}
var current_state = GameState.WAITING_INPUT

@export var grid_width: int = 9
@export var grid_height: int = 9
@export var cell_size: float = 100.0


@onready var possible_gems = [
	preload("res://assets/components/GemManager/gems/blue_tile.svg"),
	preload("res://assets/components/GemManager/gems/green_tile.svg"),
	preload("res://assets/components/GemManager/gems/purple_tile.svg"),
	preload("res://assets/components/GemManager/gems/red_tile.svg"),
	preload("res://assets/components/GemManager/gems/teal_tile.svg"),
	preload("res://assets/components/GemManager/gems/yellow_tile.svg"),
]

var all_gems = []
var gem_one = null
var gem_two = null

var current_score: int = 0
var score_label: Label = null

var grid = []
var offset = Vector2.ZERO

# Initializes the game board, sets up grid positioning, and populates with initial gems
func _ready():
	# Initialize the grid
	grid = make_2d_array()
	
	# Calculate initial grid position
	calculate_grid_position()
	
	# Populate the grid with gems
	initialize_board()

	# Find the score label by traversing up and then down the scene tree
	var main = get_tree().get_root().get_child(0)  # Get the Main node
	score_label = main.find_child("ScoreValueLabel", true, false)
	
	# Initialize score
	current_score = 0
	update_score_display()	

# Handles player input based on the current game state
func _input(event):
	# Skip input if we're processing animations
	if current_state == GameState.PROCESSING:
		return
		
	# Handle mouse/touch selection
	if event.is_action_pressed("gem_select"):
		handle_selection()
		
	# Handle deselection
	if event.is_action_pressed("gem_deselect"):
		deselect_current_gem()
		
	# Handle keyboard navigation (implement later for accessibility)

# Processes player selection of gems based on mouse/touch position
func handle_selection():
	# Get the mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Convert to grid coordinates
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	
	# Check if position is valid
	if is_within_grid(grid_pos.x, grid_pos.y) and grid[grid_pos.x][grid_pos.y] != null:
		# Ignore matched gems (they're waiting to be processed)
		if grid[grid_pos.x][grid_pos.y].matched:
			return
			
		# If no gem is currently selected
		if current_state == GameState.WAITING_INPUT:
			# Select this gem
			gem_one = grid[grid_pos.x][grid_pos.y]
			highlight_gem(gem_one)
			current_state = GameState.GEM_SELECTED
		
		# If a gem is already selected
		elif current_state == GameState.GEM_SELECTED:
			# Store the second gem
			gem_two = grid[grid_pos.x][grid_pos.y]
			
			# Check if they're different gems
			if gem_one != gem_two:
				# Check if they're adjacent
				if are_adjacent(gem_one, gem_two):
					# Attempt to swap
					swap_gems()
				else:
					# Not adjacent, provide feedback
					play_invalid_match()
					
					# Deselect first gem
					unhighlight_gem(gem_one)
					
					# Make this the new selected gem
					gem_one = gem_two
					gem_two = null
					highlight_gem(gem_one)
			else:
				# Same gem clicked, just deselect
				deselect_current_gem()

# Checks if three consecutive horizontal gems of the same type exist at position (x,y)
func match_horizontal_at(x, y, type):
	# Need at least 2 more of the same type to the right
	if x > grid_width - 3:
		return false
		
	return grid[x+1][y] != null and grid[x+1][y].type == type and \
		   grid[x+2][y] != null and grid[x+2][y].type == type

# Checks if three consecutive vertical gems of the same type exist at position (x,y)
func match_vertical_at(x, y, type):
	# Need at least 2 more of the same type below
	if y > grid_height - 3:
		return false
		
	return grid[x][y+1] != null and grid[x][y+1].type == type and \
		   grid[x][y+2] != null and grid[x][y+2].type == type

# Marks all horizontally matching gems starting from position (x,y) as matched
func mark_horizontal_match(x, y, type):
	# Mark the current gem and at least 2 to the right
	var count = 0
	var i = x
	
	while i < grid_width and count < 3:
		if grid[i][y] != null and grid[i][y].type == type:
			grid[i][y].matched = true
			count += 1
			i += 1
		else:
			break

# Identifies and marks all matched gems on the board for removal
func mark_matched_gems():
	print("Marking matched gems")
	# Clear previous match state
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != null:
				grid[x][y].matched = false
	
	# Find and mark all matched gems
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != null:
				# Check horizontal matches
				if match_horizontal_at(x, y, grid[x][y].type):
					mark_horizontal_match(x, y, grid[x][y].type)
				
				# Check vertical matches
				if match_vertical_at(x, y, grid[x][y].type):
					mark_vertical_match(x, y, grid[x][y].type)
	
	# Apply visual effect to matched gems
	var match_count = 0
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != null and grid[x][y].matched:
				# Add a visual indicator (e.g., transparency or tint)
				grid[x][y].modulate = Color(1, 1, 1, 0.6)  # Semi-transparent
				match_count += 1  # Add this line
	print("Marked", match_count, "gems")

# Marks all vertically matching gems starting from position (x,y) as matched
func mark_vertical_match(x, y, type):
	# Mark the current gem and at least 2 below
	var count = 0
	var j = y
	
	while j < grid_height and count < 3:
		if grid[x][j] != null and grid[x][j].type == type:
			grid[x][j].matched = true
			count += 1
			j += 1
		else:
			break

# Applies visual highlight effect to the selected gem
func highlight_gem(gem):
	# Add visual highlight to gem
	# You'll need to add a highlight method to your gem script
	gem.highlight()

# Removes visual highlight effect from the selected gem
func unhighlight_gem(gem):
	# Remove highlight from gem
	gem.unhighlight()

# Resets gem selection state and returns to waiting for input
func deselect_current_gem():
	if gem_one != null:
		unhighlight_gem(gem_one)
	
	gem_one = null
	gem_two = null
	current_state = GameState.WAITING_INPUT

# Checks if two gems are adjacent to each other on the grid
func are_adjacent(gem_a, gem_b):
	# Find grid positions of both gems
	var pos_a = find_gem_position(gem_a)
	var pos_b = find_gem_position(gem_b)
	
	# Check if they're adjacent (one step in one direction)
	return (abs(pos_a.x - pos_b.x) == 1 and pos_a.y == pos_b.y) or \
		   (abs(pos_a.y - pos_b.y) == 1 and pos_a.x == pos_b.x)

# Finds the grid coordinates of a specific gem
func find_gem_position(gem):
	# Find the grid position of a gem
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] == gem:
				return Vector2(x, y)
	
	# Gem not found
	return Vector2(-1, -1)

# Provides visual feedback when an invalid match is attempted
func play_invalid_match():
	# Play a shake animation on both gems
	if gem_one != null and gem_two != null:
		gem_one.shake_gem()
		gem_two.shake_gem()

# Animates the swapping of two gems and checks for resulting matches
func swap_gems():
	# Enter processing state to prevent user input during animations
	current_state = GameState.PROCESSING
	
	# Find the grid positions of both selected gems
	var pos_a = find_gem_position(gem_one)
	var pos_b = find_gem_position(gem_two)
	
	# Swap the gems in the grid data structure
	grid[pos_a.x][pos_a.y] = gem_two
	grid[pos_b.x][pos_b.y] = gem_one
	
	# Calculate pixel positions for animation
	var pos_a_pixel = grid_to_pixel(pos_a.x, pos_a.y)
	var pos_b_pixel = grid_to_pixel(pos_b.x, pos_b.y)
	
	# Center the gems in their cells
	pos_a_pixel.x += cell_size / 2
	pos_a_pixel.y += cell_size / 2
	pos_b_pixel.x += cell_size / 2
	pos_b_pixel.y += cell_size / 2
	
	# Create a tween for smooth animation of both gems simultaneously
	var tween = create_tween()
	tween.tween_property(gem_one, "position", pos_b_pixel, 0.3)
	tween.parallel().tween_property(gem_two, "position", pos_a_pixel, 0.3)
	
	# Wait for the swap animation to complete before proceeding
	await tween.finished
	
	# Remove highlight from the first selected gem
	unhighlight_gem(gem_one)
	
	# Check if this swap created any matches
	if check_board_for_matches():
		# Found matches, mark them for visual feedback
		mark_matched_gems()
		
		# Clear gem selections
		gem_one = null
		gem_two = null
		
		# Start the full turn sequence
		process_turn_sequence()
	else:
		# No matches created, swap the gems back to their original positions
		swap_back_gems(pos_a, pos_b)

# Reverses an invalid swap and provides feedback to the player
func swap_back_gems(pos_a, pos_b):
	# Swap back in the grid array
	var temp = grid[pos_a.x][pos_a.y]
	grid[pos_a.x][pos_a.y] = grid[pos_b.x][pos_b.y]
	grid[pos_b.x][pos_b.y] = temp
	
	# Animate the swap back
	var pos_a_pixel = grid_to_pixel(pos_a.x, pos_a.y)
	var pos_b_pixel = grid_to_pixel(pos_b.x, pos_b.y)
	
	# Center the positions
	pos_a_pixel.x += cell_size / 2
	pos_a_pixel.y += cell_size / 2
	pos_b_pixel.x += cell_size / 2
	pos_b_pixel.y += cell_size / 2
	
	# Create a tween for the swap back
	var tween = create_tween()
	tween.tween_property(grid[pos_a.x][pos_a.y], "position", pos_a_pixel, 0.3)
	tween.parallel().tween_property(grid[pos_b.x][pos_b.y], "position", pos_b_pixel, 0.3)
	
	# Reset state when done
	await tween.finished
	
	# Play invalid move feedback
	play_invalid_match()
	
	current_state = GameState.WAITING_INPUT
	gem_one = null
	gem_two = null

# Scans the entire board to find any valid matches
func check_board_for_matches():
	print("Checking board for matches")
	# Check the entire board for NEW matches (ignoring already matched gems)
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != null and not grid[x][y].matched:
				if check_for_matches_at(x, y):
					return true
	
	# No new matches found
	return false

# Removes all matched gems from the board with fade-out animation
func remove_matched_gems():
	# Enter the processing state
	current_state = GameState.PROCESSING
	
	# Create a count of gems to be removed
	var gems_to_remove = 0
	var gems_to_animate = []
	
	# Debug: Print matched gems per column
	print("=== MATCH REMOVAL STARTED ===")
	for x in range(grid_width):
		var column_matches = 0
		for y in range(grid_height):
			if grid[x][y] != null and grid[x][y].matched:
				column_matches += 1
		if column_matches > 0:
			print("Column ", x, " has ", column_matches, " matched gems")
	
	# First, collect all the gems to remove
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != null and grid[x][y].matched:
				gems_to_remove += 1
				
				# Store the gem for animation
				var gem_to_remove = grid[x][y]
				gems_to_animate.append(gem_to_remove)
				
				# Mark this position as empty in the grid immediately
				grid[x][y] = null
	
	# If no gems to remove, exit early
	if gems_to_remove == 0:
		print("No gems to remove, exiting early")
		return false
	
	print("Starting removal, gems to remove:", gems_to_remove)
	
	# Now animate all the stored gems
	print("Creating fade animations for ", gems_to_animate.size(), " gems")
	for gem in gems_to_animate:
		var tween = create_tween()
		tween.tween_property(gem, "modulate:a", 0.0, 0.2) # Fade out
		tween.parallel().tween_property(gem, "scale", Vector2(0.1, 0.1), 0.2) # Shrink
	
	# Wait longer for all animations to complete
	print("Waiting for animations to complete...")
	await get_tree().create_timer(0.3).timeout
	
	# Count empty spaces in grid after removal
	var empty_count = 0
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] == null:
				empty_count += 1
	print("Empty spaces in grid after removal: ", empty_count)
	
	# Remove gems AFTER animations
	print("Removing ", gems_to_animate.size(), " gem nodes from scene")
	for gem in gems_to_animate:
		gem.queue_free()
	
	print("Removal complete - grid ready for collapse")
	return true

# Creates fade-out and shrink animation for a gem being removed
func animate_gem_removal(gem):
	# Create a tween for fade-out and scale-down
	var tween = create_tween()
	tween.tween_property(gem, "modulate:a", 0.0, 0.3) # Fade out
	tween.parallel().tween_property(gem, "scale", Vector2(0.1, 0.1), 0.3) # Shrink
	
	# Setup a callback for when the tween finishes
	tween.finished.connect(func():
		# Find gem position in grid
		var pos = find_gem_position(gem)
		if pos.x >= 0 and pos.y >= 0:
			# Remove gem from scene tree
			gem.queue_free()
			
			# Update grid array
			grid[pos.x][pos.y] = null
	)
	
	return tween

# Initiates the removal process for all matched gems
func start_gem_removal():
	# Count how many gems need to be removed
	var gems_to_remove = 0
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != null and grid[x][y].matched:
				gems_to_remove += 1
	
	# If no gems to remove, skip this step
	if gems_to_remove == 0:
		# Move to next phase (falling gems)
		# This would be implemented in the next sprint
		current_state = GameState.WAITING_INPUT
		return
	
	# Enter processing state
	current_state = GameState.PROCESSING
	
	# Start removal animations for all matched gems
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != null and grid[x][y].matched:
				# Start animation and wait for it to complete
				animate_gem_removal(grid[x][y])

# Centers the grid within its parent container based on its scale
func calculate_grid_position():
	# The parent is a Control node (Panel)
	var parent_size = get_parent().size
	
	# Account for the node's scale when calculating grid pixel size
	# Since the node is scaled by 1.5x, we need to consider this in our calculations
	var effective_cell_size = cell_size * scale.x
	var grid_pixel_size = Vector2(grid_width * effective_cell_size, grid_height * effective_cell_size)
	
	# Center the grid within the parent panel
	# We're dividing by scale because the position will be affected by the node's scale
	position.x = (parent_size.x - grid_pixel_size.x) / (2 * scale.x)
	position.y = (parent_size.y - grid_pixel_size.y) / (2 * scale.y)
	
	# The offset should now be zero since we're using the node's position
	offset = Vector2.ZERO
	
	# Update any existing gem positions if needed
	update_all_gem_positions()
	
	# Force redraw
	queue_redraw()

# Centers the grid within a specified rectangular area
func center_in_rect(rect: Rect2):
	# Calculate the total grid size in pixels
	var grid_pixel_size = Vector2(grid_width * cell_size, grid_height * cell_size)
	
	# Center the grid within the given rectangle
	offset.x = rect.position.x + (rect.size.x - grid_pixel_size.x) / 2
	offset.y = rect.position.y + (rect.size.y - grid_pixel_size.y) / 2
	
	# Update position if needed
	update_all_gem_positions()

# Creates a 2D array to represent the game grid
func make_2d_array():
	var array = []
	for i in grid_width:
		array.append([])
		for j in grid_height:
			array[i].append(null)
	return array

# Converts grid coordinates to pixel position on screen
func grid_to_pixel(column, row):
	# Convert grid coordinates to pixel coordinates
	var pixel_x = column * cell_size
	var pixel_y = row * cell_size
	return Vector2(pixel_x, pixel_y)

# Converts pixel position to grid coordinates
func pixel_to_grid(pixel_x, pixel_y):
	# Convert pixel coordinates to grid coordinates
	# First convert to local coordinates
	var local_x = pixel_x - global_position.x
	var local_y = pixel_y - global_position.y
	
	# Then convert to grid coordinates, accounting for scale
	var grid_x = floor(local_x / (cell_size * scale.x))
	var grid_y = floor(local_y / (cell_size * scale.y))
	
	# Ensure coordinates are within grid bounds
	if grid_x >= 0 and grid_x < grid_width and grid_y >= 0 and grid_y < grid_height:
		return Vector2(grid_x, grid_y)
	return Vector2(-1, -1)  # Invalid position

# Updates the position of all gems based on their grid coordinates
func update_all_gem_positions():
	for i in range(grid_width):
		for j in range(grid_height):
			if grid[i][j] != null:
				var pos = grid_to_pixel(i, j)
				# Center the gem in the cell
				pos.x += cell_size / 2
				pos.y += cell_size / 2
				grid[i][j].position = pos

# Draws the grid background and lines for visual representation
func _draw():
	# Draw the grid lines
	draw_grid_background()
	draw_grid_lines()

# Draws the background color for the game grid
func draw_grid_background():
	var rect = Rect2(Vector2.ZERO, Vector2(grid_width * cell_size, grid_height * cell_size))
	draw_rect(rect, Color("#16162a"), true)  # Grid background

# Draws the grid lines to visually separate cells
func draw_grid_lines():
	var line_color = Color("#3a3a64")
	var line_width = 1.0
	
	# Draw vertical lines
	for i in range(grid_width + 1):
		var start_point = Vector2(i * cell_size, 0)
		var end_point = Vector2(i * cell_size, grid_height * cell_size)
		draw_line(start_point, end_point, line_color, line_width)
	
	# Draw horizontal lines
	for i in range(grid_height + 1):
		var start_point = Vector2(0, i * cell_size)
		var end_point = Vector2(grid_width * cell_size, i * cell_size)
		draw_line(start_point, end_point, line_color, line_width)

# Creates a new gem of random type at the specified grid position
func spawn_gem(column, row):
	# Randomly select a gem type
	var gem_type = randi() % possible_gems.size()
	var new_gem = possible_gems[gem_type].instantiate()
	
	# Add gem to the scene
	add_child(new_gem)
	
	# Position the gem according to grid coordinates
	var pos = grid_to_pixel(column, row)
	
	# Add half the cell size to center the gem in the cell
	pos.x += cell_size / 2
	pos.y += cell_size / 2
	
	new_gem.position = pos
	
	# Scale the gem to fit the cell
	var scale_factor = (cell_size -2) / 64.0
	new_gem.scale = Vector2(scale_factor, scale_factor)
	
	# Store the gem in the grid array
	grid[column][row] = new_gem
	
	# Set the type property
	new_gem.type = gem_type
	
	return new_gem

# Sets up the initial game board with gems in valid positions
func initialize_board():
	# Clear any existing gems
	for column in grid:
		for gem in column:
			if gem != null:
				gem.queue_free()
	
	# Reset grid array
	grid = make_2d_array()
	
	# Fill the grid with gems that don't create initial matches
	for i in grid_width:
		for j in grid_height:
			spawn_gem_no_match(i, j)
	
	# Check if the board has valid moves
	if !check_for_valid_moves():
		# If not, reinitialize
		initialize_board()

# Creates a gem at the specified position that doesn't form an initial match
func spawn_gem_no_match(column, row):
	# Get list of gem types that won't create a match
	var valid_types = get_valid_gem_types(column, row)
	
	# If no valid types (rare case), use any random type
	if valid_types.size() == 0:
		return spawn_gem(column, row)
	
	# Pick a random type from valid ones
	var type_index = valid_types[randi() % valid_types.size()]
	
	# Instantiate the gem with the chosen type
	var new_gem = possible_gems[type_index].instantiate()
	
	# Add gem to the scene
	add_child(new_gem)
	
	# Position the gem according to grid coordinates
	var pos = grid_to_pixel(column, row)
	
	# Add half the cell size to center the gem in the cell
	pos.x += cell_size / 2
	pos.y += cell_size / 2
	
	new_gem.position = pos
	
	# Scale the gem to fit the cell
	var scale_factor = (cell_size -2) / 64.0
	new_gem.scale = Vector2(scale_factor, scale_factor)
	
	# Store the gem in the grid array
	grid[column][row] = new_gem
	
	# Store the type (this assumes you've added a type property to each gem)
	new_gem.type = type_index
	
	return new_gem

# Determines which gem types can be placed at a position without creating matches
func get_valid_gem_types(column, row):
	# Start with all possible gem types
	var valid_types = []
	for i in range(possible_gems.size()):
		valid_types.append(i)
	
	# Check for potential horizontal matches (two to the left)
	if column >= 2:
		if grid[column-1][row] != null and grid[column-2][row] != null:
			if grid[column-1][row].type == grid[column-2][row].type:
				# This would create a match, remove this type from valid types
				valid_types.erase(grid[column-1][row].type)
	
	# Check for potential vertical matches (two above)
	if row >= 2:
		if grid[column][row-1] != null and grid[column][row-2] != null:
			if grid[column][row-1].type == grid[column][row-2].type:
				# This would create a match, remove this type from valid types
				valid_types.erase(grid[column][row-1].type)
	
	return valid_types

# Verifies if there are valid moves available on the current board
func check_for_valid_moves():
	# Iterate through each gem on the board
	for i in range(grid_width):
		for j in range(grid_height):
			# Check if swapping with each adjacent position creates a match
			if check_move_valid(i, j, i+1, j) or \
			   check_move_valid(i, j, i-1, j) or \
			   check_move_valid(i, j, i, j+1) or \
			   check_move_valid(i, j, i, j-1):
					return true  # Found a valid move
	
	# No valid moves found after checking all positions
	return false

# Checks if swapping gems at the specified positions would create a match
func check_move_valid(x1, y1, x2, y2):
	# Check if both positions are within bounds
	if !is_within_grid(x1, y1) or !is_within_grid(x2, y2):
		return false
	
	# Check if both positions have gems
	if grid[x1][y1] == null or grid[x2][y2] == null:
		return false
	
	# Store original types
	var type1 = grid[x1][y1].type
	var type2 = grid[x2][y2].type
	
	# If the types are the same, swapping wouldn't change anything
	if type1 == type2:
		return false
	
	# Simulate the swap in our local check
	var valid_move = false
	
	# Temporarily swap types
	grid[x1][y1].type = type2
	grid[x2][y2].type = type1
	
	# Check if this creates a match
	if check_for_matches_at(x1, y1) or check_for_matches_at(x2, y2):
		valid_move = true
	
	# Undo the swap
	grid[x1][y1].type = type1
	grid[x2][y2].type = type2
	
	return valid_move

# Verifies if coordinates are within the grid boundaries
func is_within_grid(x, y):
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height

# Checks if the gem at position (x,y) is part of a match
func check_for_matches_at(x, y):
	if !is_within_grid(x, y) or grid[x][y] == null or grid[x][y].matched:
		return false
	
	var current_type = grid[x][y].type
	
	# Check for horizontal match (at least 3 in a row)
	var horizontal_count = 1
	
	# Count gems of the same type to the right
	var i = x + 1
	while i < grid_width and grid[i][y] != null and not grid[i][y].matched and grid[i][y].type == current_type:
		horizontal_count += 1
		i += 1
	
	# Count gems of the same type to the left
	i = x - 1
	while i >= 0 and grid[i][y] != null and not grid[i][y].matched and grid[i][y].type == current_type:
		horizontal_count += 1
		i -= 1
	
	# Check for vertical match (at least 3 in a column)
	var vertical_count = 1
	
	# Count gems of the same type below
	var j = y + 1
	while j < grid_height and grid[x][j] != null and not grid[x][j].matched and grid[x][j].type == current_type:
		vertical_count += 1
		j += 1
	
	# Count gems of the same type above
	j = y - 1
	while j >= 0 and grid[x][j] != null and not grid[x][j].matched and grid[x][j].type == current_type:
		vertical_count += 1
		j -= 1
	
	# Return true if we found at least 3 in a row or column
	return horizontal_count >= 3 or vertical_count >= 3

# Moves gems downward in a column to fill empty spaces
func collapse_column(column_index):
	print("Collapsing column ", column_index)
	# Track if anything moved in this column
	var column_changed = false
	
	# Start from the bottom and work up
	for row_index in range(grid_height - 1, -1, -1):
		# If this position is empty
		if grid[column_index][row_index] == null:
			# Look for the nearest gem above
			for above_row in range(row_index - 1, -1, -1):
				if grid[column_index][above_row] != null:
					# Found a gem to move down
					
					# Get the gem reference
					var gem_to_move = grid[column_index][above_row]
					
					# Update the grid array - remove from old position
					grid[column_index][above_row] = null
					
					# Place in new position
					grid[column_index][row_index] = gem_to_move
					
					# Calculate the target pixel position
					var target_position = grid_to_pixel(column_index, row_index)
					
					# Center the gem in the cell
					target_position.x += cell_size / 2
					target_position.y += cell_size / 2
					
					# Create falling animation
					var tween = create_tween()
					tween.tween_property(gem_to_move, "position", target_position, 0.3)
					
					# Track that we moved something
					column_changed = true
					
					# Only move one gem per empty space
					break
	
	# Return whether anything changed in this column
	print("Column ", column_index, " collapse complete. Changed: ", column_changed)
	return column_changed

# Processes the entire grid to make gems fall into empty spaces
func collapse_grid():
	# Track if any gems were moved during collapse
	var grid_changed = false
	
	print("=== STARTING GRID COLLAPSE ===")
	# Process each column
	for column_index in range(grid_width):
		print("Processing column ", column_index, "...")
		# Move gems in this column
		var column_changed = collapse_column(column_index)
		
		if column_changed:
			grid_changed = true
	
	# If nothing changed, we can skip waiting
	if not grid_changed:
		print("No gems collapsed - grid unchanged")
		return false
	
	# Wait a bit for animations to complete
	print("Waiting for collapse animations to complete...")
	await get_tree().create_timer(0.35).timeout
	print("Collapse animations complete")
	
	# Return whether the grid changed
	return grid_changed

# Adds new gems to fill empty spaces at the top of the grid
func refill_board():
	# Track if any new gems were added
	var new_gems_added = false
	print("=== STARTING BOARD REFILL ===")
	
	# Check each column
	for column_index in range(grid_width):
		# Count empty spaces in this column
		var empty_spaces = 0
		var empty_rows = []
		
		# Find all empty spaces in this column
		for row_index in range(grid_height):
			if grid[column_index][row_index] == null:
				empty_spaces += 1
				empty_rows.append(row_index)
		
		if empty_spaces > 0:
			print("Column ", column_index, " has ", empty_spaces, " empty spaces")
		
		# If we have empty spaces, fill from the top
		if empty_spaces > 0:
			# Create a new gem for each empty space
			print("Creating ", empty_spaces, " new gems for column ", column_index)
			for i in range(empty_spaces):
				# Row index where this gem will end up
				var target_row = empty_rows[i]
				
				# Create a new gem with a valid type for this position
				var _new_gem = spawn_gem_above_grid(column_index, target_row)
				
				# Mark that we've added new gems
				new_gems_added = true
	
	# If no new gems were added, we're done
	if not new_gems_added:
		print("No new gems needed to be added")
		return false
	
	# Wait for falling animations to complete
	print("Waiting for gem falling animations to complete...")
	await get_tree().create_timer(0.4).timeout
	print("Refill complete - all new gems in place")
	return true

# Creates a new gem above the grid that will fall into the target position
func spawn_gem_above_grid(column, target_row):
	# Determine a valid gem type that won't create immediate matches
	var valid_types = get_valid_gem_types(column, target_row)
	
	# If no valid types, use any random type
	var gem_type
	if valid_types.size() == 0:
		gem_type = randi() % possible_gems.size()
	else:
		gem_type = valid_types[randi() % valid_types.size()]
	
	# Create the new gem
	var new_gem = possible_gems[gem_type].instantiate()
	add_child(new_gem)
	
	# Calculate the final position (where it will land)
	var final_position = grid_to_pixel(column, target_row)
	final_position.x += cell_size / 2
	final_position.y += cell_size / 2
	
	# Calculate the starting position (above the grid)
	var start_position = final_position
	start_position.y = -cell_size  # Start above the visible grid
	
	# Position the gem initially at the start position
	new_gem.position = start_position
	
	# Scale the gem to fit the cell
	var scale_factor = (cell_size - 2) / 64.0
	new_gem.scale = Vector2(scale_factor, scale_factor)
	
	# Update the grid array
	grid[column][target_row] = new_gem
	
	# Set the gem type
	new_gem.type = gem_type
	
	# Create animation for falling into place
	var tween = create_tween()
	tween.tween_property(new_gem, "position", final_position, 0.3)
	
	return new_gem

# Identifies matches, removes gems, and handles cascading effects
func check_and_process_matches():
	# Mark all matched gems
	var has_matches = false
	
	# Find and mark all matched gems
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != null:
				# Check horizontal matches
				if match_horizontal_at(x, y, grid[x][y].type):
					mark_horizontal_match(x, y, grid[x][y].type)
					has_matches = true
				
				# Check vertical matches
				if match_vertical_at(x, y, grid[x][y].type):
					mark_vertical_match(x, y, grid[x][y].type)
					has_matches = true
	
	# If no matches found, return false
	if not has_matches:
		return false
	
	# Apply visual effect to matched gems
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != null and grid[x][y].matched:
				# Add a visual indicator
				grid[x][y].modulate = Color(1, 1, 1, 0.6)  # Semi-transparent
	
	# Remove matches
	await remove_matched_gems()
	
	# Collapse the grid
	await collapse_grid()
	
	# Refill the board
	await refill_board()
	
	# Check for new matches (chain reaction)
	await check_and_process_matches()
	
	return true

# Executes the complete sequence after a successful match (remove, collapse, refill, chain)
func process_turn_sequence():
	print("\n=== TURN SEQUENCE STARTED ===")
	# Set game state to processing
	current_state = GameState.PROCESSING
	
	# Track chain reaction counter for scoring
	var chain_count = 0
	
	# Instead of checking again, use the fact that gems are already marked
	print("Checking for matched gems...")
	var has_matches = false
	
	# Count how many gems are already matched
	var matched_count = 0
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != null and grid[x][y].matched:
				matched_count += 1
				has_matches = true
	
	print("Found ", matched_count, " matched gems")
	
	if has_matches:
		# Process matches until no more are found
		var continue_chain = true
		
		while continue_chain:
			print("\n--- Chain reaction count: ", chain_count, " ---")
			
			# Update score based on matches and chain level
			update_score_for_matches(chain_count)
			
			# Remove matched gems
			print("Removing matched gems...")
			var removal_success = await remove_matched_gems()
			print("Gem removal completed, success: ", removal_success)
			
			if removal_success:
				# Increment chain counter for scoring purposes
				chain_count += 1
			
				# Collapse the grid (gems fall down to fill gaps)
				print("Collapsing gems...")
				var grid_collapsed = await collapse_grid()
				print("Grid collapse completed, changed: ", grid_collapsed)
				
				# Refill the board with new gems
				print("Refilling board...")
				var board_refilled = await refill_board()
				print("Board refill completed, added new gems: ", board_refilled)
				
				# Check for new matches created by falling/new gems
				print("Checking for new matches...")
				# Clear previous match flags before checking
				for x in range(grid_width):
					for y in range(grid_height):
						if grid[x][y] != null:
							grid[x][y].matched = false
							
				if check_board_for_matches():
					print("New matches found! Continuing chain reaction...")
					mark_matched_gems()
					# Continue the loop to process these new matches
				else:
					print("No new matches - chain reaction complete")
					continue_chain = false
			else:
				# No gems were removed, exit the chain
				print("No gems removed - ending process")
				continue_chain = false
		
		# Turn sequence complete, return to waiting state
		print("=== TURN SEQUENCE COMPLETE ===")
	else:
		print("No matches found")
	
	# Reset game state
	current_state = GameState.WAITING_INPUT

# 
func calculate_match_points(matched_gems_count: int, chain_level: int = 0) -> int:
	# Base points for matching 3 gems
	var base_points = 10
	
	# More points for matching more gems (exponential scaling)
	var match_size_multiplier = 1.0 + (matched_gems_count - 3) * 0.75
	
	# Chain reaction multiplier (increases with each chain)
	var chain_multiplier = 1.0 + chain_level * 0.4
	
	# Calculate total points
	var points = int(base_points * match_size_multiplier * chain_multiplier)
	
	return points

#
func update_score_display():
	if score_label:
		score_label.text = str(current_score)

#
func update_score_for_matches(chain_level: int = 0):
	var matched_gems_count = 0
	
	# Count all matched gems on the board
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != null and grid[x][y].matched:
				matched_gems_count += 1
	
	# Only update score if we have matches
	if matched_gems_count >= 3:
		var points = calculate_match_points(matched_gems_count, chain_level)
		current_score += points
		update_score_display()
		
		# Optional: Show visual feedback of points gained
		show_score_popup(points)
	
	#
func show_score_popup(points: int):
	# Create a label for the score popup
	var popup = Label.new()
	popup.text = "+" + str(points)
	popup.add_theme_font_size_override("font_size", 32)
	popup.add_theme_color_override("font_color", Color("#ffd700"))  # Gold color
	
	# Add to scene and position in center of visible matches
	add_child(popup)
	
	# Find center of matched gems
	var center = find_center_of_matched_gems()
	popup.position = center
	
	# Create animation
	var tween = create_tween()
	tween.tween_property(popup, "position:y", center.y - 100, 1.0)
	tween.parallel().tween_property(popup, "modulate:a", 0, 1.0)
	
	# Remove when animation completes
	tween.tween_callback(popup.queue_free)

#
func find_center_of_matched_gems() -> Vector2:
	# Variables to track total and count of matched gems
	var total_position = Vector2.ZERO
	var matched_count = 0
	
	# Iterate through all grid positions
	for x in range(grid_width):
		for y in range(grid_height):
			# Check if there's a matched gem at this position
			if grid[x][y] != null and grid[x][y].matched:
				# Add this gem's position to our total
				total_position += grid[x][y].position
				matched_count += 1
	
	# Calculate the average position (center)
	if matched_count > 0:
		return total_position / matched_count
	else:
		# If no matches (shouldn't happen when this is called), return center of grid
		return Vector2(
			(grid_width * cell_size) / 2,
			(grid_height * cell_size) / 2
		)
