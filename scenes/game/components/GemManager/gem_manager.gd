class_name GemManager
extends Node2D

# Signal for gem creation
signal gem_created(gem, position)

# References
var grid_manager: GridManager
var game_board

# Gem types
var possible_gems = []
var special_gem_scenes = {}
var gem_pool = []  # For object pooling

func _ready():
	grid_manager = get_parent()  # GemManager's parent is GridManager
	game_board = grid_manager.get_parent()  # GridManager's parent is GameBoard
	initialize()

func initialize():
	# Existing initialization code...
	
	# Load gem scenes
	possible_gems = [
		preload("res://scenes/game/gems/RedGem.tscn"),
		preload("res://scenes/game/gems/BlueGem.tscn"),
		preload("res://scenes/game/gems/GreenGem.tscn"),
		preload("res://scenes/game/gems/TealGem.tscn"),
		preload("res://scenes/game/gems/PurpleGem.tscn"),
		preload("res://scenes/game/gems/YellowGem.tscn"),
	]
	
	# Initialize the gem pool
	initialize_gem_pool()
	
	# Load special gem scenes
	special_gem_scenes = {
		"line_blast_h": preload("res://scenes/game/gems/LineBlastH.tscn"),
		"line_blast_v": preload("res://scenes/game/gems/LineBlastV.tscn"),
		"cross_blast": preload("res://scenes/game/gems/CrossBlast.tscn"),
		"color_bomb": preload("res://scenes/game/gems/ColorBomb.tscn"),
		"super_bomb": preload("res://scenes/game/gems/SuperBomb.tscn")
	}

# Initialize the gem pool with some gems of each type
func initialize_gem_pool():
	# Create a few instances of each gem type for the pool
	for gem_type in range(possible_gems.size()):
		for i in range(5):  # 5 of each type initially
			var gem = possible_gems[gem_type].instantiate()
			gem.type = gem_type
			gem.visible = false  # Hide until used
			add_child(gem)
			gem_pool.append(gem)

# Get a gem from the pool or create a new one
func get_gem_from_pool(type: int):
	# Look for an existing gem of the requested type
	for gem in gem_pool:
		if is_instance_valid(gem) and not gem.visible and gem.type == type:
			gem.visible = true
			return gem
	
	# If none found, create a new one
	var new_gem = possible_gems[type].instantiate()
	new_gem.type = type
	add_child(new_gem)
	gem_pool.append(new_gem)
	return new_gem

# Clean up the gem pool by removing invalid references
func cleanup_gem_pool():
	var valid_gems = []
	for gem in gem_pool:
		if is_instance_valid(gem):
			valid_gems.append(gem)
	
	print("Cleaned pool: removed ", gem_pool.size() - valid_gems.size(), " invalid gems")
	gem_pool = valid_gems

# Return a gem to the pool
func return_gem_to_pool(gem):
	if is_instance_valid(gem):
		gem.visible = false
		# Reset any gem state as needed
	else:
		# If we're trying to return an invalid gem, cleanup the pool
		cleanup_gem_pool()

# Creates a gem of the specified type at the grid position
func create_gem(type: int, column: int, row: int):
	# Get a gem from the pool
	var new_gem = get_gem_from_pool(type)
	
	# Get the position from GridManager
	var cell_size = get_parent().cell_size  # Get cell size from parent (GridManager)
	var pos = Vector2(column * cell_size, row * cell_size)
	
	# Critical: Center the gem in the cell
	pos.x += cell_size / 2
	pos.y += cell_size / 2
	
	# Set the gem position
	new_gem.position = pos
	
	# Scale the gem to fit the cell
	var scale_factor = (grid_manager.cell_size - 2) / 64.0
	new_gem.scale = Vector2(scale_factor, scale_factor)
	
	# Store the gem in the grid
	grid_manager.set_gem_at(column, row, new_gem)
	
	# Reset matched state
	new_gem.matched = false
	
	# Emit signal
	emit_signal("gem_created", new_gem, Vector2i(column, row))
	
	return new_gem

# Creates a random gem at the specified position
func create_random_gem(column: int, row: int):
	var type = randi() % possible_gems.size()
	return create_gem(type, column, row)

# Creates a gem that doesn't form a match
func create_gem_no_match(column: int, row: int):
	var valid_types = get_valid_gem_types(column, row)
	
	if valid_types.size() == 0:
		return create_random_gem(column, row)
	
	var type_index = valid_types[randi() % valid_types.size()]
	return create_gem(type_index, column, row)

# Returns types that won't create a match
func get_valid_gem_types(column: int, row: int) -> Array:
	# Start with all possible gem types
	var valid_types = []
	for i in range(possible_gems.size()):
		valid_types.append(i)
	
	# Check for potential horizontal matches
	if column >= 2:
		var gem1 = grid_manager.get_gem_at(column-1, row)
		var gem2 = grid_manager.get_gem_at(column-2, row)
		if gem1 != null and gem2 != null and gem1.type == gem2.type:
			valid_types.erase(gem1.type)
	
	# Check for potential vertical matches
	if row >= 2:
		var gem1 = grid_manager.get_gem_at(column, row-1)
		var gem2 = grid_manager.get_gem_at(column, row-2)
		if gem1 != null and gem2 != null and gem1.type == gem2.type:
			valid_types.erase(gem1.type)
	
	return valid_types

# Returns the number of different gem types
func get_gem_types_count() -> int:
	return possible_gems.size()

# Create a special gem at the specified position
func create_special_gem(special_type: String, column: int, row: int, orientation: String = ""):
	var scene_key = special_type
	
	# Handle line blast orientation
	if special_type == "line_blast":
		if orientation == "horizontal":
			scene_key = "line_blast_h"
		else:
			scene_key = "line_blast_v"
	
	# Get the special gem scene
	var gem_scene = special_gem_scenes.get(scene_key)
	if gem_scene == null:
		print("ERROR: Unknown special gem type: ", special_type, " orientation: ", orientation)
		return null
	
	# Create the special gem instance
	var new_gem = gem_scene.instantiate()
	
	# Set the gem position
	var cell_size = grid_manager.cell_size
	var pos = Vector2(column * cell_size, row * cell_size)
	pos.x += cell_size / 2
	pos.y += cell_size / 2
	new_gem.position = pos
	
	# Scale appropriately
	var scale_factor = (grid_manager.cell_size - 2) / 64.0
	new_gem.scale = Vector2(scale_factor, scale_factor)
	
	# Store in the grid
	grid_manager.set_gem_at(column, row, new_gem)
	
	# Add to scene
	add_child(new_gem)
	
	return new_gem

# Convert a regular gem to a special gem
func convert_to_special_gem(column: int, row: int, special_type: String, orientation: String = ""):
	# Remove existing gem
	var existing_gem = grid_manager.get_gem_at(column, row)
	if existing_gem != null:
		# Get the gem type to preserve
		var gem_type = existing_gem.type
		
		# Remove from grid and scene
		grid_manager.set_gem_at(column, row, null)
		existing_gem.queue_free()
		
		# Create special gem
		var special_gem = create_special_gem(special_type, column, row, orientation)
		if special_gem != null:
			# Preserve original gem type
			special_gem.type = gem_type
			
			return special_gem
	
	return null

# Check if a gem is a special gem
func is_special_gem(gem) -> bool:
	return gem != null and gem.get("special_type") != null and gem.special_type != ""

# Get the special gem type (useful for debugging and logic)
func get_special_gem_type(gem) -> String:
	if is_special_gem(gem):
		return gem.special_type
	return ""

# Get the special gem orientation (for line blast gems)
func get_special_gem_orientation(gem) -> String:
	if is_special_gem(gem):
		return gem.orientation
	return ""
