class_name BoardController
extends Node

# References
var game_board
var grid_manager
var gem_manager
var match_detector

# Game states
enum GameState {WAITING_INPUT, GEM_SELECTED, PROCESSING}
var current_state = GameState.WAITING_INPUT

# Signals
signal board_state_changed(state)
signal board_processing_complete()

func _ready():
	game_board = get_parent()
	
func initialize(grid_mgr, gem_mgr, match_det):
	grid_manager = grid_mgr
	gem_manager = gem_mgr
	match_detector = match_det
	
func process_turn_sequence():
	# Turn sequence processing logic
	pass
