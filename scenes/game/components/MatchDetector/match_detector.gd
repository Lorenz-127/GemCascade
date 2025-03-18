class_name MatchDetector
extends Node

# Signals
signal matches_found(matches)
signal no_matches_found()

# References
var grid_manager: GridManager
var gem_manager: GemManager

# Internal state
var current_matches = []

func _ready():
	pass

func initialize(grid_mgr: GridManager, gem_mgr: GemManager):
	grid_manager = grid_mgr
	gem_manager = gem_mgr

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
func mark_matched_gems():
	var found_matches = false
	var match_info = []
	var dims = grid_manager.get_grid_dimensions()
	
	# Clear previous match state
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
						found_matches = true
						for match_pos in current_match:
							var match_gem = grid_manager.get_gem_at(match_pos.x, match_pos.y)
							match_gem.matched = true
						
						match_info.append({
							"type": current_type,
							"positions": current_match,
							"orientation": "horizontal"
						})
					
					# Start a new potential match
					current_match = [Vector2i(x, y)]
					current_type = gem.type
				else:
					# Extend current match
					current_match.append(Vector2i(x, y))
			else:
				# Process any prior match before gap
				if current_match.size() >= 3:
					found_matches = true
					for match_pos in current_match:
						var match_gem = grid_manager.get_gem_at(match_pos.x, match_pos.y)
						match_gem.matched = true
					
					match_info.append({
						"type": current_type,
						"positions": current_match,
						"orientation": "horizontal"
					})
				
				# Reset for next potential match
				current_match = []
				current_type = -1
		
		# End of row, check for match
		if current_match.size() >= 3:
			found_matches = true
			for match_pos in current_match:
				var match_gem = grid_manager.get_gem_at(match_pos.x, match_pos.y)
				match_gem.matched = true
			
			match_info.append({
				"type": current_type,
				"positions": current_match,
				"orientation": "horizontal"
			})
	
	# Check vertical matches
	for x in range(dims.x):
		var current_match = []
		var current_type = -1
		
		for y in range(dims.y):
			var gem = grid_manager.get_gem_at(x, y)
			
			if gem != null:
				if current_type == -1 or gem.type != current_type:
					# Process any prior match
					if current_match.size() >= 3:
						found_matches = true
						for match_pos in current_match:
							var match_gem = grid_manager.get_gem_at(match_pos.x, match_pos.y)
							match_gem.matched = true
						
						match_info.append({
							"type": current_type,
							"positions": current_match,
							"orientation": "vertical"
						})
					
					# Start a new potential match
					current_match = [Vector2i(x, y)]
					current_type = gem.type
				else:
					# Extend current match
					current_match.append(Vector2i(x, y))
			else:
				# Process any prior match before gap
				if current_match.size() >= 3:
					found_matches = true
					for match_pos in current_match:
						var match_gem = grid_manager.get_gem_at(match_pos.x, match_pos.y)
						match_gem.matched = true
					
					match_info.append({
						"type": current_type,
						"positions": current_match,
						"orientation": "vertical"
					})
				
				# Reset for next potential match
				current_match = []
				current_type = -1
		
		# End of column, check for match
		if current_match.size() >= 3:
			found_matches = true
			for match_pos in current_match:
				var match_gem = grid_manager.get_gem_at(match_pos.x, match_pos.y)
				match_gem.matched = true
			
			match_info.append({
				"type": current_type,
				"positions": current_match,
				"orientation": "vertical"
			})
	
	# Apply visual effect to matched gems
	for x in range(dims.x):
		for y in range(dims.y):
			var gem = grid_manager.get_gem_at(x, y)
			if gem != null and gem.matched:
				gem.modulate = Color(1, 1, 1, 0.6)  # Semi-transparent
	
	# Store current matches for later reference
	current_matches = match_info
	
	# Emit signal based on result
	if found_matches:
		emit_signal("matches_found", match_info)
	else:
		emit_signal("no_matches_found")
		
	return found_matches

# Returns information about current matches
func get_matches() -> Array:
	return current_matches
