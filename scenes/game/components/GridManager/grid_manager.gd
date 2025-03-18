class_name GridManager
extends Node2D

# Exported properties for configuration
@export var grid_width: int = 9
@export var grid_height: int = 9
@export var cell_size: float = 100.0

# Reference to the game board
var game_board
var grid = []  # 2D array to store references to gems

func _ready():
	game_board = get_parent()
	initialize()

func initialize():
	# Create the 2D array
	grid = make_2d_array()
	
	# Draw the grid (queue_redraw() will call _draw())
	queue_redraw()

# Creates a 2D array to represent the game grid
func make_2d_array() -> Array:
	var array = []
	for i in grid_width:
		array.append([])
		for j in grid_height:
			array[i].append(null)
	return array
	
# Returns the dimensions of the grid
func get_grid_dimensions() -> Vector2i:
	return Vector2i(grid_width, grid_height)
	
# Converts grid coordinates to pixel position
func grid_to_pixel(column: int, row: int) -> Vector2:
	var pixel_x = column * cell_size
	var pixel_y = row * cell_size
	return Vector2(pixel_x, pixel_y)
	
# Converts pixel position to grid coordinates
func pixel_to_grid(pixel_x: float, pixel_y: float) -> Vector2i:
	# Convert to local coordinates
	var local_x = pixel_x - global_position.x
	var local_y = pixel_y - global_position.y
	
	# Convert to grid coordinates
	var grid_x = int(local_x / cell_size)
	var grid_y = int(local_y / cell_size)
	
	# Ensure coordinates are within grid bounds
	if is_within_grid(grid_x, grid_y):
		return Vector2i(grid_x, grid_y)
	return Vector2i(-1, -1)  # Invalid position
	
# Checks if coordinates are within grid boundaries
func is_within_grid(x: int, y: int) -> bool:
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height
	
# Returns the gem at the specified grid position
func get_gem_at(x: int, y: int):
	if is_within_grid(x, y):
		return grid[x][y]
	return null
	
# Places a gem at the specified grid position
func set_gem_at(x: int, y: int, gem_instance):
	if is_within_grid(x, y):
		grid[x][y] = gem_instance
		return true
	return false

# Draws the grid background and lines
func _draw():
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
