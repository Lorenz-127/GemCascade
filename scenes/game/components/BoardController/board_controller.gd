class_name BoardController
extends Node

# Game states
enum GameState {WAITING_INPUT, GEM_SELECTED, PROCESSING, GAME_OVER}

# Signals
signal game_state_changed(state)
signal board_processing_complete()
signal invalid_swap_completed
signal swap_animation_completed

# References
var grid_manager: GridManager
var gem_manager: GemManager
var match_detector: MatchDetector

# Variables to track special gems
var _queued_special_gems = []  # For tracking gems to create after matches
var last_swap_position = Vector2i(-1, -1)  # Track swap position for special gem placement

# State
var current_state = GameState.WAITING_INPUT
var chain_count = 0

func _ready():
	pass

func initialize(grid_mgr: GridManager, gem_mgr: GemManager, match_det: MatchDetector):
	# Existing initialization code
	grid_manager = grid_mgr
	gem_manager = gem_mgr
	match_detector = match_det
	
	# Connect to match detector signals
	match_detector.connect("matches_found", _on_matches_found)
	match_detector.connect("no_matches_found", _on_no_matches_found)
	
	# Connect to special match signals
	match_detector.connect("special_match_detected", _on_special_match_detected)
	match_detector.connect("match_4_detected", _on_match_4_detected)
	match_detector.connect("match_5_detected", _on_match_5_detected)
	match_detector.connect("match_6_detected", _on_match_6_detected)
	match_detector.connect("match_7_plus_detected", _on_match_7_plus_detected)
	
	# Start in waiting input state
	change_state(GameState.WAITING_INPUT)

# Change game state and emit signal
func change_state(new_state):
	current_state = new_state
	emit_signal("game_state_changed", current_state)

# Process a player move (swap attempt)
func process_player_move(gem1, gem2):
	# Enter processing state to prevent further input
	change_state(GameState.PROCESSING)
	
	# Find the grid positions of both selected gems
	var pos1 = find_gem_position(gem1)
	var pos2 = find_gem_position(gem2)
	
	# Store the swap position for special gem creation
	last_swap_position = pos1
	
	# Check if either gem is a special gem
	var is_special_gem1 = gem_manager.is_special_gem(gem1)
	var is_special_gem2 = gem_manager.is_special_gem(gem2)
	
	# If both are special gems, handle special combination
	if is_special_gem1 and is_special_gem2:
		await process_special_gem_combination(gem1, gem2, pos1, pos2)
		return
	
	# Swap the gems in the grid data structure
	swap_gems_in_grid(pos1, pos2)
	
	# Animate the swap
	await animate_swap(gem1, gem2, pos1, pos2)
	
	# Emit signal to deselect the gem immediately after swap animation
	emit_signal("swap_animation_completed")
	
	# Check if a special gem was activated
	if is_special_gem1 or is_special_gem2:
		# Activate the special gem
		if is_special_gem1:
			await activate_special_gem(gem1, pos2)  # Position after swap
		else:
			await activate_special_gem(gem2, pos1)  # Position after swap
			
		# Process the turn sequence
		process_turn_sequence()
		return
	
	# Continue with match checking and processing
	if match_detector.check_board_for_matches():
		# Found matches, mark them for visual feedback
		match_detector.mark_matched_gems()
		
		# Start the full turn sequence
		process_turn_sequence()
	else:
		# No matches created, swap the gems back
		await swap_gems_back(pos1, pos2)

# Find the position of a gem in the grid
func find_gem_position(gem) -> Vector2i:
	var dims = grid_manager.get_grid_dimensions()
	for x in range(dims.x):
		for y in range(dims.y):
			if grid_manager.get_gem_at(x, y) == gem:
				return Vector2i(x, y)
	
	return Vector2i(-1, -1)

# Swap two gems in the grid data structure
func swap_gems_in_grid(pos1: Vector2i, pos2: Vector2i):
	var gem1 = grid_manager.get_gem_at(pos1.x, pos1.y)
	var gem2 = grid_manager.get_gem_at(pos2.x, pos2.y)
	
	grid_manager.set_gem_at(pos1.x, pos1.y, gem2)
	grid_manager.set_gem_at(pos2.x, pos2.y, gem1)

# Animate the swap between two gems
func animate_swap(gem1, gem2, pos1: Vector2i, pos2: Vector2i):
	# Calculate pixel positions for animation
	var pos1_pixel = grid_manager.grid_to_pixel(pos1.x, pos1.y)
	var pos2_pixel = grid_manager.grid_to_pixel(pos2.x, pos2.y)
	
	# Center the gems in their cells
	pos1_pixel.x += grid_manager.cell_size / 2
	pos1_pixel.y += grid_manager.cell_size / 2
	pos2_pixel.x += grid_manager.cell_size / 2
	pos2_pixel.y += grid_manager.cell_size / 2
	
	# Create a tween for smooth animation
	var tween = create_tween()
	tween.tween_property(gem1, "position", pos2_pixel, 0.3)
	tween.parallel().tween_property(gem2, "position", pos1_pixel, 0.3)
	
	# Wait for the animation to complete
	await tween.finished

# Swap gems back if no match was made
func swap_gems_back(pos1: Vector2i, pos2: Vector2i):
	# Swap back in the grid
	swap_gems_in_grid(pos1, pos2)
	
	# Animate the swap back
	var gem1 = grid_manager.get_gem_at(pos1.x, pos1.y)
	var gem2 = grid_manager.get_gem_at(pos2.x, pos2.y)
	
	await animate_swap(gem1, gem2, pos1, pos2)
	
	# Play invalid move feedback
	if gem1:
		gem1.shake_gem()
	if gem2:
		gem2.shake_gem()
	
	# Return to waiting state
	change_state(GameState.WAITING_INPUT)
	emit_signal("invalid_swap_completed")

# Process the full turn sequence
func process_turn_sequence():
	print("\n=== TURN SEQUENCE STARTED ===")
	# Set game state to processing
	change_state(GameState.PROCESSING)
	
	# Clear the special gem queue
	_queued_special_gems = []
	
	# Set the last swap position in match detector to help determine special gem placement
	match_detector.set_last_swap_position(last_swap_position)
	
	# Reset chain reaction counter
	chain_count = 0
	
	# Process matches until no more are found
	var continue_chain = true
	
	while continue_chain:
		print("\n--- Chain reaction count: ", chain_count, " ---")
		
		# Remove matched gems
		print("Removing matched gems...")
		var removal_success = await remove_matched_gems()
		print("Gem removal completed, success: ", removal_success)
		
		if removal_success:
			# After removing matched gems, create any queued special gems
			if _queued_special_gems.size() > 0:
				print("Creating special gems: ", _queued_special_gems.size())
				for special_gem_info in _queued_special_gems:
					var pos = special_gem_info.position
					gem_manager.convert_to_special_gem(
						pos.x, pos.y, 
						special_gem_info.special_type, 
						special_gem_info.orientation
					)
				
				# Clear the queue
				_queued_special_gems = []
			
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
			var dims = grid_manager.get_grid_dimensions()
			for x in range(dims.x):
				for y in range(dims.y):
					var gem = grid_manager.get_gem_at(x, y)
					if gem != null:
						gem.matched = false
						
			if match_detector.check_board_for_matches():
				print("New matches found! Continuing chain reaction...")
				match_detector.mark_matched_gems()
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
	change_state(GameState.WAITING_INPUT)
	
	# Emit signal that board processing is complete
	emit_signal("board_processing_complete")

# Remove matched gems from the board
func remove_matched_gems():
	# Track gems to be removed
	var gems_to_remove = []
	
	# Find all matched gems
	var dims = grid_manager.get_grid_dimensions()
	for x in range(dims.x):
		for y in range(dims.y):
			var gem = grid_manager.get_gem_at(x, y)
			if gem != null and gem.matched:
				gems_to_remove.append({"gem": gem, "position": Vector2i(x, y)})
				
				# Clear the grid position
				grid_manager.set_gem_at(x, y, null)
	
	# If no gems to remove, exit early
	if gems_to_remove.size() == 0:
		return false
	
	# Animate removal of all stored gems
	for gem_data in gems_to_remove:
		var gem = gem_data.gem
		
		# Create removal animation
		var tween = create_tween()
		tween.tween_property(gem, "modulate:a", 0.0, 0.2) # Fade out
		tween.parallel().tween_property(gem, "scale", Vector2(0.1, 0.1), 0.2) # Shrink

	# Wait for animations to complete
	await get_tree().create_timer(0.3).timeout
	
	# Free the gem instances
	for gem_data in gems_to_remove:
		# You might want to return gems to a pool instead of freeing them
		# if you implement object pooling fully
		gem_data.gem.queue_free()
	
	return true

# Collapse gems to fill empty spaces
func collapse_grid():
	# Track if any gems were moved
	var grid_changed = false
	
	print("=== STARTING GRID COLLAPSE ===")
	var dims = grid_manager.get_grid_dimensions()
	
	# Process each column
	for column_index in range(dims.x):
		print("Processing column ", column_index, "...")
		var column_changed = collapse_column(column_index)
		
		if column_changed:
			grid_changed = true
	
	# If nothing changed, we can skip waiting
	if not grid_changed:
		print("No gems collapsed - grid unchanged")
		return false
	
	# Wait for animations to complete
	await get_tree().create_timer(0.35).timeout
	print("Collapse animations complete")
	
	return grid_changed

# Collapse a single column
func collapse_column(column_index: int):
	# Track if anything moved in this column
	var column_changed = false
	var dims = grid_manager.get_grid_dimensions()
	
	# Start from the bottom and work up
	for row_index in range(dims.y - 1, -1, -1):
		# If this position is empty
		if grid_manager.get_gem_at(column_index, row_index) == null:
			# Look for the nearest gem above
			for above_row in range(row_index - 1, -1, -1):
				var gem_to_move = grid_manager.get_gem_at(column_index, above_row)
				if gem_to_move != null:
					# Found a gem to move down
					
					# Update the grid array - remove from old position
					grid_manager.set_gem_at(column_index, above_row, null)
					
					# Place in new position
					grid_manager.set_gem_at(column_index, row_index, gem_to_move)
					
					# Calculate the target pixel position
					var target_position = grid_manager.grid_to_pixel(column_index, row_index)
					
					# Center the gem in the cell
					target_position.x += grid_manager.cell_size / 2
					target_position.y += grid_manager.cell_size / 2
					
					# Create falling animation
					var tween = create_tween()
					tween.tween_property(gem_to_move, "position", target_position, 0.3)
					
					# Track that we moved something
					column_changed = true
					
					# Only move one gem per empty space
					break
	
	return column_changed

# Refill the board with new gems
func refill_board():
	# Track if any new gems were added
	var new_gems_added = false
	
	var dims = grid_manager.get_grid_dimensions()
	
	# Check each column
	for column_index in range(dims.x):
		# Count empty spaces in this column
		var empty_spaces = 0
		var empty_rows = []
		
		# Find all empty spaces in this column
		for row_index in range(dims.y):
			if grid_manager.get_gem_at(column_index, row_index) == null:
				empty_spaces += 1
				empty_rows.append(row_index)
		
		# If we have empty spaces, fill from the top
		if empty_spaces > 0:
			# Create a new gem for each empty space
			for i in range(empty_spaces):
				# Row index where this gem will end up
				var target_row = empty_rows[i]
				
				# Create a new gem with a valid type for this position
				var _new_gem = spawn_gem_above_grid(column_index, target_row)
				
				# Mark that we've added new gems
				new_gems_added = true
	
	# If no new gems were added, we're done
	if not new_gems_added:
		return false
	
	# Wait for falling animations to complete
	await get_tree().create_timer(0.4).timeout
	
	return true

# Create a new gem above the grid that will fall into position
func spawn_gem_above_grid(column: int, target_row: int):
	# Determine a valid gem type
	var valid_types = gem_manager.get_valid_gem_types(column, target_row)
	
	# If no valid types, use any random type
	var gem_type
	if valid_types.size() == 0:
		gem_type = randi() % gem_manager.get_gem_types_count()
	else:
		gem_type = valid_types[randi() % valid_types.size()]
	
	# Create the new gem off-screen
	var new_gem = gem_manager.create_gem(gem_type, column, target_row)
	
	# Calculate the final position (where it will land)
	var final_position = grid_manager.grid_to_pixel(column, target_row)
	final_position.x += grid_manager.cell_size / 2
	final_position.y += grid_manager.cell_size / 2
	
	# Calculate the starting position (above the grid)
	var start_position = final_position
	start_position.y = -grid_manager.cell_size  # Start above the visible grid
	
	# Position the gem initially at the start position
	new_gem.position = start_position
	
	# Create animation for falling into place
	var tween = create_tween()
	tween.tween_property(new_gem, "position", final_position, 0.3)
	
	return new_gem

# Check if there are valid moves on the board
func check_for_valid_moves() -> bool:
	var dims = grid_manager.get_grid_dimensions()
	
	# Check horizontal swaps
	for y in range(dims.y):
		for x in range(dims.x - 1):
			# Try swapping with right neighbor
			if check_move_valid(x, y, x+1, y):
				return true
	
	# Check vertical swaps
	for x in range(dims.x):
		for y in range(dims.y - 1):
			# Try swapping with gem below
			if check_move_valid(x, y, x, y+1):
				return true
	
	return false

# Check if a swap would create a match
func check_move_valid(x1: int, y1: int, x2: int, y2: int) -> bool:
	if !grid_manager.is_within_grid(x1, y1) or !grid_manager.is_within_grid(x2, y2):
		return false
	
	var gem1 = grid_manager.get_gem_at(x1, y1)
	var gem2 = grid_manager.get_gem_at(x2, y2)
	
	if gem1 == null or gem2 == null:
		return false
	
	# Store original types
	var type1 = gem1.type
	var type2 = gem2.type
	
	# If the types are the same, swapping wouldn't change anything
	if type1 == type2:
		return false
	
	# Simulate the swap in our check
	var valid_move = false
	
	# Temporarily swap types
	gem1.type = type2
	gem2.type = type1
	
	# Check if this creates a match
	if match_detector.check_for_matches_at(x1, y1) or match_detector.check_for_matches_at(x2, y2):
		valid_move = true
	
	# Restore original types
	gem1.type = type1
	gem2.type = type2
	
	return valid_move

# Get the current game state
func get_current_state():
	return current_state

# Signal handlers
func _on_matches_found(matches):
	# Handle matches found
	print("Matches found: ", matches.size())
	# This will be processed as part of the turn sequence

func _on_no_matches_found():
	# Handle no matches found
	print("No matches found")
	# Check if we need to take any action

# Handle special match detection
func _on_special_match_detected(match_info):
	# Just log the special match - specific handling done in length-specific handlers
	print("Special match detected: ", match_info.special_gem_type)

# Handle match-4 detection (Line Blast)
func _on_match_4_detected(match_info):
	print("Match-4 detected: Line Blast")
	var special_pos = match_info.get("special_gem_position", match_info.positions[0])
	
	# Queue special gem creation for after current matches are processed
	_queue_special_gem_creation(special_pos.x, special_pos.y, "line_blast", match_info.orientation)

# Handle match-5 detection (Cross Blast)
func _on_match_5_detected(match_info):
	print("Match-5 detected: Cross Blast")
	var special_pos = match_info.get("special_gem_position", match_info.positions[0])
	
	# Queue special gem creation
	_queue_special_gem_creation(special_pos.x, special_pos.y, "cross_blast")

# Handle match-6 detection (Color Bomb)
func _on_match_6_detected(match_info):
	print("Match-6 detected: Color Bomb")
	var special_pos = match_info.get("special_gem_position", match_info.positions[0])
	
	# Queue special gem creation
	_queue_special_gem_creation(special_pos.x, special_pos.y, "color_bomb")

# Handle match-7+ detection (Super Bomb)
func _on_match_7_plus_detected(match_info):
	print("Match-7+ detected: Super Bomb")
	var special_pos = match_info.get("special_gem_position", match_info.positions[0])
	
	# Queue special gem creation
	_queue_special_gem_creation(special_pos.x, special_pos.y, "super_bomb")

# Queue special gem creation for after current matches are processed
func _queue_special_gem_creation(x: int, y: int, special_type: String, orientation: String = ""):
	_queued_special_gems.append({
		"position": Vector2i(x, y),
		"special_type": special_type,
		"orientation": orientation
	})

# Activate a special gem based on its type
func activate_special_gem(gem, position: Vector2i):
	print("Activating special gem: ", gem.special_type, " at ", position)
	
	# Call gem's activation animation
	await gem.activate()
	
	# Process activation based on gem type
	match gem.special_type:
		"line_blast":
			# Clear entire row or column based on orientation
			await activate_line_blast(position.x, position.y, gem.orientation)
		"cross_blast":
			# Clear both row and column
			await activate_cross_blast(position.x, position.y)
		"color_bomb":
			# Clear all gems of matching color
			var target_color = gem.type  # Use gem's color as default
			await activate_color_bomb(position.x, position.y, target_color)
		"super_bomb":
			# Clear a large area (radius blast)
			await activate_super_bomb(position.x, position.y)
	
	# Mark the special gem itself as matched for removal
	gem.matched = true
	
	return true

# Handle special gem combination
func process_special_gem_combination(gem1, gem2, pos1: Vector2i, pos2: Vector2i):
	print("Processing special gem combination!")
	
	# Swap the gems in the grid data structure
	swap_gems_in_grid(pos1, pos2)
	
	# Animate the swap
	await animate_swap(gem1, gem2, pos1, pos2)
	
	# Emit signal to deselect the gem
	emit_signal("swap_animation_completed")
	
	# Get types of both special gems
	var type1 = gem1.special_type
	var type2 = gem2.special_type
	
	# Combination effects based on gem types
	# Line + Line = Cross Blast effect
	if type1 == "line_blast" and type2 == "line_blast":
		print("Line + Line combo: Cross blast effect!")
		await activate_cross_blast(pos1.x, pos1.y)
		await activate_cross_blast(pos2.x, pos2.y)
	
	# Line + Cross = Enhanced cross (larger area)
	elif (type1 == "line_blast" and type2 == "cross_blast") or \
		 (type1 == "cross_blast" and type2 == "line_blast"):
		print("Line + Cross combo: Enhanced cross blast!")
		await activate_cross_blast(pos1.x, pos1.y)
		await activate_cross_blast(pos2.x, pos2.y)
	
	# Line + Color Bomb = Clear all gems in that row/column
	elif (type1 == "line_blast" and type2 == "color_bomb") or \
		 (type1 == "color_bomb" and type2 == "line_blast"):
		print("Line + Color Bomb combo: Clear all in row/column!")
		var line_gem = gem1 if type1 == "line_blast" else gem2
		await activate_line_blast(pos1.x, pos1.y, line_gem.orientation)
		await activate_color_bomb(pos2.x, pos2.y, gem1.type)
	
	# Cross + Color Bomb = Clear all gems in rows and columns
	elif (type1 == "cross_blast" and type2 == "color_bomb") or \
		 (type1 == "color_bomb" and type2 == "cross_blast"):
		print("Cross + Color Bomb combo: Clear rows and columns!")
		await activate_cross_blast(pos1.x, pos1.y)
		await activate_color_bomb(pos2.x, pos2.y, gem1.type)
	
	# Color Bomb + Color Bomb = Clear entire board
	elif type1 == "color_bomb" and type2 == "color_bomb":
		print("Color Bomb + Color Bomb combo: Clear entire board!")
		await activate_entire_board()
	
	# Any + Super Bomb = Enhanced area blast
	elif type1 == "super_bomb" or type2 == "super_bomb":
		print("Super Bomb combo: Enhanced area blast!")
		await activate_super_bomb(pos1.x, pos1.y, 3)  # Larger radius
	
	# Mark both gems as matched for removal
	gem1.matched = true
	gem2.matched = true
	
	# Process the board after activation
	process_turn_sequence()

# Activate line blast effect (clear row or column)
func activate_line_blast(x: int, y: int, orientation: String):
	var dims = grid_manager.get_grid_dimensions()
	
	if orientation == "horizontal":
		print("Activating horizontal line blast at row: ", y)
		# Clear the entire row
		for col in range(dims.x):
			var gem = grid_manager.get_gem_at(col, y)
			if gem != null and !gem.matched:
				gem.matched = true
	else:  # vertical
		print("Activating vertical line blast at column: ", x)
		# Clear the entire column
		for row in range(dims.y):
			var gem = grid_manager.get_gem_at(x, row)
			if gem != null and !gem.matched:
				gem.matched = true
	
	# Wait a moment for visual effect
	await get_tree().create_timer(0.2).timeout

# Activate cross blast effect (clear row and column)
func activate_cross_blast(x: int, y: int):
	print("Activating cross blast at: ", Vector2i(x, y))
	
	# Clear horizontal line
	await activate_line_blast(x, y, "horizontal")
	
	# Clear vertical line
	await activate_line_blast(x, y, "vertical")

# Activate color bomb effect (clear all gems of target color)
func activate_color_bomb(x: int, y: int, target_color: int):
	print("Activating color bomb for color: ", target_color)
	
	var dims = grid_manager.get_grid_dimensions()
	var gems_cleared = 0
	
	# Clear all gems of the target color
	for col in range(dims.x):
		for row in range(dims.y):
			var gem = grid_manager.get_gem_at(col, row)
			if gem != null and !gem.matched and gem.type == target_color:
				gem.matched = true
				gems_cleared += 1
	
	print("Color bomb cleared ", gems_cleared, " gems")
	
	# Wait a moment for visual effect
	await get_tree().create_timer(0.2).timeout

# Activate super bomb effect (clear gems in radius)
func activate_super_bomb(x: int, y: int, radius: int = 2):
	print("Activating super bomb at: ", Vector2i(x, y), " with radius: ", radius)
	
	var dims = grid_manager.get_grid_dimensions()
	
	# Clear gems in a radius around the position
	for col in range(max(0, x - radius), min(dims.x, x + radius + 1)):
		for row in range(max(0, y - radius), min(dims.y, y + radius + 1)):
			# Calculate distance from center
			var distance = Vector2i(col, row).distance_to(Vector2i(x, y))
			
			# If within radius, clear the gem
			if distance <= radius:
				var gem = grid_manager.get_gem_at(col, row)
				if gem != null and !gem.matched:
					gem.matched = true
	
	# Wait a moment for visual effect
	await get_tree().create_timer(0.2).timeout

# Activate entire board effect (clear all gems)
func activate_entire_board():
	print("Activating entire board clear!")
	
	var dims = grid_manager.get_grid_dimensions()
	
	# Mark all gems as matched
	for col in range(dims.x):
		for row in range(dims.y):
			var gem = grid_manager.get_gem_at(col, row)
			if gem != null and !gem.matched:
				gem.matched = true
	
	# Wait a moment for visual effect
	await get_tree().create_timer(0.3).timeout
