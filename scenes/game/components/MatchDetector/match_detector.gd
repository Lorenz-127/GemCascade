class_name MatchDetector
extends Node

# References
var game_board
var grid_manager
var gem_manager

# Signals
signal matches_found(matches)
signal no_matches_found()

func _ready():
	game_board = get_parent()
	
func initialize(grid_mgr, gem_mgr):
	grid_manager = grid_mgr
	gem_manager = gem_mgr
	
func check_for_matches():
	# Match detection logic
	pass
