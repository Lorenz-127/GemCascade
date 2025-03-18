class_name GridManager
extends Node2D

# Properties
@export var grid_width: int = 9
@export var grid_height: int = 9
@export var cell_size: float = 100.0

# References
var game_board

# Internal data
var grid = []

func _ready():
	game_board = get_parent()

func initialize():
	grid = make_2d_array()
	# Additional initialization logic

# Creates a 2D array to represent the game grid
func make_2d_array():
	var array = []
	for i in grid_width:
		array.append([])
		for j in grid_height:
			array[i].append(null)
	return array
