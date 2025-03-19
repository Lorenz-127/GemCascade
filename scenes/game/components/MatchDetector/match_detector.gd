class_name MatchDetector
extends Node

# Signals
signal matches_found(matches)
signal no_matches_found()
# signals for specific match lengths
signal match_4_detected(match_info)
signal match_5_detected(match_info)
signal match_6_detected(match_info)
signal match_7_plus_detected(match_info)
# Generic signal for any special match
signal special_match_detected(match_info)

# References
var grid_manager: GridManager
var gem_manager: GemManager

# Internal state
var current_matches = []
var last_swap_position = Vector2i(-1, -1) # Track the last swap position for special gem placement

func _ready():
	pass

# Initialize the match detector with grid and gem managers
func initialize(grid_mgr: GridManager, gem_mgr: GemManager):
	grid_manager = grid_mgr
	gem_manager = gem_mgr

# Set the last swap position (called by InputHandler or BoardController)
func set_last_swap_position(pos: Vector2i):
	last_swap_position = pos

# Get the last swap position
func get_last_swap_position() -> Vector2i:
	return last_swap_position

# Checks for matches at a specific position
func check_for_matches_at(x: int, y: int) -> bool:
	if !grid_manager.is_within_grid(x, y):
		return false
		
	var gem = grid_manager.get_gem_at(x, y)
	if gem == null or gem.matched:
		return false
	
	var current_type = gem.type
	
	# Check for horizontal match (at least 3 in a row)
	var horizontal_count = 1
	
	# Count gems of the same type to the right
	var i = x + 1
	var dims = grid_manager.get_grid_dimensions()
	while i < dims.x:
		var next_gem = grid_manager.get_gem_at(i, y)
		if next_gem != null and !next_gem.matched and next_gem.type == current_type:
			horizontal_count += 1
			i += 1
		else:
			break
	
	# Count gems of the same type to the left
	i = x - 1
	while i >= 0:
		var next_gem = grid_manager.get_gem_at(i, y)
		if next_gem != null and !next_gem.matched and next_gem.type == current_type:
			horizontal_count += 1
			i -= 1
		else:
			break
	
	# Check for vertical match (at least 3 in a column)
	var vertical_count = 1
	
	# Count gems of the same type below
	var j = y + 1
	while j < dims.y:
		var next_gem = grid_manager.get_gem_at(x, j)
		if next_gem != null and !next_gem.matched and next_gem.type == current_type:
			vertical_count += 1
			j += 1
		else:
			break
	
	# Count gems of the same type above
	j = y - 1
	while j >= 0:
		var next_gem = grid_manager.get_gem_at(x, j)
		if next_gem != null and !next_gem.matched and next_gem.type == current_type:
			vertical_count += 1
			j -= 1
		else:
			break
	
	# Return true if we found at least 3 in a row or column
	return horizontal_count >= 3 or vertical_count >= 3

# Checks the entire board for matches
func check_board_for_matches() -> bool:
	var dims = grid_manager.get_grid_dimensions()
	for x in range(dims.x):
		for y in range(dims.y):
			if check_for_matches_at(x, y):
				return true
	
	return false

# Marks all matched gems for removal
# Marks all matched gems for removal and identifies special matches
func mark_matched_gems():
	var found_matches = false
	var dims = grid_manager.get_grid_dimensions()
	
	# Clear previous match state and current matches array
	current_matches = []
	for x in range(dims.x):
		for y in range(dims.y):
			var gem = grid_manager.get_gem_at(x, y)
			if gem != null:
				gem.matched = false
	
	# Check horizontal matches
	for y in range(dims.y):
		var current_match = []
		var current_type = -1
		
		for x in range(dims.x):
			var gem = grid_manager.get_gem_at(x, y)
			
			if gem != null and !gem.matched:
				if current_type == -1 or gem.type != current_type:
					# Process any prior match
					if current_match.size() >= 3:
						# Use process_match instead of directly handling here
						process_match(current_match, current_type, "horizontal")
						found_matches = true
					
					# Start a new potential match
					current_match = [Vector2i(x, y)]
					current_type = gem.type
				else:
					# Extend current match
					current_match.append(Vector2i(x, y))
			else:
				# Process any prior match before gap
				if current_match.size() >= 3:
					# Use process_match instead of directly handling here
					process_match(current_match, current_type, "horizontal")
					found_matches = true
				
				# Reset for next potential match
				current_match = []
				current_type = -1
		
		# End of row, check for match
		if current_match.size() >= 3:
			# Use process_match instead of directly handling here
			process_match(current_match, current_type, "horizontal")
			found_matches = true
	
	# Check vertical matches
	for x in range(dims.x):
		var current_match = []
		var current_type = -1
		
		for y in range(dims.y):
			var gem = grid_manager.get_gem_at(x, y)
			
			if gem != null and !gem.matched:
				if current_type == -1 or gem.type != current_type:
					# Process any prior match
					if current_match.size() >= 3:
						# Use process_match instead of directly handling here
						process_match(current_match, current_type, "vertical")
						found_matches = true
					
					# Start a new potential match
					current_match = [Vector2i(x, y)]
					current_type = gem.type
				else:
					# Extend current match
					current_match.append(Vector2i(x, y))
			else:
				# Process any prior match before gap
				if current_match.size() >= 3:
					# Use process_match instead of directly handling here
					process_match(current_match, current_type, "vertical")
					found_matches = true
				
				# Reset for next potential match
				current_match = []
				current_type = -1
		
		# End of column, check for match
		if current_match.size() >= 3:
			# Use process_match instead of directly handling here
			process_match(current_match, current_type, "vertical")
			found_matches = true
	
	# Apply visual effect to matched gems
	for x in range(dims.x):
		for y in range(dims.y):
			var gem = grid_manager.get_gem_at(x, y)
			if gem != null and gem.matched:
				gem.modulate = Color(1, 1, 1, 0.6)  # Semi-transparent
	
	# Emit signal based on result
	if found_matches:
		emit_signal("matches_found", current_matches)
	else:
		emit_signal("no_matches_found")
		
	return found_matches

# Process a match of any length
func process_match(positions: Array, gem_type: int, orientation: String):
	var match_length = positions.size()
	
	# Debug print
	print("MatchDetector: Processing match of length " + str(match_length) + " with orientation " + orientation)
	
	# Mark all gems in the match as matched
	for pos in positions:
		var gem = grid_manager.get_gem_at(pos.x, pos.y)
		if gem != null:
			gem.matched = true
	
	# Create match info with enhanced data
	var match_data = {
		"type": gem_type,
		"positions": positions,
		"orientation": orientation,
		"length": match_length,
		"special_gem_type": determine_special_gem_type(match_length)
	}
	
	# Debug print special gem type
	print("MatchDetector: Special gem type determined: " + match_data["special_gem_type"])
	
	# Add the swap position to match info if it's part of this match
	if positions.has(last_swap_position):
		match_data["swap_position"] = last_swap_position
	elif last_swap_position != Vector2i(-1, -1):
		# Find the closest position to the swap position
		var closest_pos = positions[0]
		var min_distance = closest_pos.distance_to(last_swap_position)
		
		for pos in positions:
			var dist = pos.distance_to(last_swap_position)
			if dist < min_distance:
				min_distance = dist
				closest_pos = pos
		
		match_data["special_gem_position"] = closest_pos
	else:
		# If no swap position is set, use the first position
		match_data["special_gem_position"] = positions[0]
	
	# Add to current matches
	current_matches.append(match_data)
	
	# Emit signals based on match length
	match match_length:
		4:
			emit_signal("match_4_detected", match_data)
		5:
			emit_signal("match_5_detected", match_data)
		6:
			emit_signal("match_6_detected", match_data)
		_:
			if match_length >= 7:
				emit_signal("match_7_plus_detected", match_data)
	
	# Emit generic special match signal for matches of length 4+
	if match_length >= 4:
		emit_signal("special_match_detected", match_data)

# Determine special gem type based on match length
func determine_special_gem_type(match_length: int) -> String:
	match match_length:
		4:
			return "line_blast"
		5:
			return "cross_blast"
		6:
			return "color_bomb"
		_:
			if match_length >= 7:
				return "super_bomb"
			else:
				return "none"

# Returns information about current matches
func get_matches() -> Array:
	return current_matches

# Reset the match detector state
func reset():
	current_matches = []
	last_swap_position = Vector2i(-1, -1)
