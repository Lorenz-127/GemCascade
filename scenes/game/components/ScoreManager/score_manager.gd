class_name ScoreManager
extends Node

# References
var game_board
var ui_score_label

# Score tracking
var current_score: int = 0
var highest_combo: int = 0

# Signals
signal score_updated(new_score)
signal high_score_achieved(score)

func _ready():
	game_board = get_parent()
	
func initialize():
	# Find score label in UI
	pass
	
