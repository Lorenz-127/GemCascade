class_name InputHandler
extends Node

# References
var game_board
var grid_manager
var gem_manager

# Selection state
var gem_one = null
var gem_two = null

# Signals
signal gem_selected(gem)
signal gem_deselected()
signal gems_swapped(gem_one, gem_two, valid_swap)

func _ready():
	game_board = get_parent()
	
func initialize(grid_mgr, gem_mgr):
	grid_manager = grid_mgr
	gem_manager = gem_mgr
	
func _input(event):
	# Input handling logic will go here
	pass
