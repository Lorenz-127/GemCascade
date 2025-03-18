class_name GemManager
extends Node

# Signal for gem creation
signal gem_created(gem, position)

# References
var grid_manager: GridManager
var game_board

# Gem types
var possible_gems = []
var gem_pool = []  # For object pooling

func _ready():
	game_board = get_parent()

func initialize(grid_mgr: GridManager):
	grid_manager = grid_mgr
	
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
		if not gem.visible and gem.type == type:
			gem.visible = true
			return gem
	
	# If none found, create a new one
	var new_gem = possible_gems[type].instantiate()
	new_gem.type = type
	add_child(new_gem)
	gem_pool.append(new_gem)
	return new_gem

# Return a gem to the pool
func return_gem_to_pool(gem):
	gem.visible = false
	# Reset any gem state as needed

# Creates a gem of the specified type at the grid position
func create_gem(type: int, column: int, row: int):
	# Get a gem from the pool
	var new_gem = get_gem_from_pool(type)
	
	# Position the gem
	var pos = grid_manager.grid_to_pixel(column, row)
	pos.x += grid_manager.cell_size / 2
	pos.y += grid_manager.cell_size / 2
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
