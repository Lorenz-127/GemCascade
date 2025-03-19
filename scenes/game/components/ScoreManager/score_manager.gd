class_name ScoreManager
extends Node

# Signals
signal score_updated(new_score)
signal high_score_achieved(score)

# References
var game_board
var board_controller: BoardController

# State
var current_score: int = 0
var high_score: int = 0
var score_label: Label = null

func _ready():
	game_board = get_parent()

func initialize():
	# Find the score label by traversing up and then down the scene tree
	var main = get_tree().get_root().get_child(0)  # Get the Main node
	score_label = main.find_child("ScoreValueLabel", true, false)
	
	# Initialize score
	current_score = 0
	update_score_display()
	
	# Load high score if saved
	load_high_score()

# Update the score based on match information
func update_score_for_matches(matched_gems_count: int, chain_level: int = 0):
	var points = calculate_match_points(matched_gems_count, chain_level)
	current_score += points
	update_score_display()
	
	# Check for high score
	if current_score > high_score:
		high_score = current_score
		emit_signal("high_score_achieved", high_score)
		save_high_score()
	
	# Show visual feedback
	show_score_popup(points)
	
	# Emit signal
	emit_signal("score_updated", current_score)

# Calculate points for a match
func calculate_match_points(matched_gems_count: int, chain_level: int = 0) -> int:
	# Base points for matching 3 gems
	var base_points = 10
	
	# More points for matching more gems (exponential scaling)
	var match_size_multiplier = 1.0 + (matched_gems_count - 3) * 0.75
	
	# Chain reaction multiplier (increases with each chain)
	var chain_multiplier = 1.0 + chain_level * 0.4
	
	# Calculate total points
	var points = int(base_points * match_size_multiplier * chain_multiplier)
	
	return points

# Update the score display
func update_score_display():
	if score_label:
		score_label.text = str(current_score)

# Show a score popup
func show_score_popup(points: int):
	# Create a label for the score popup
	var popup = Label.new()
	popup.text = "+" + str(points)
	popup.add_theme_font_size_override("font_size", 32)
	popup.add_theme_color_override("font_color", Color("#ffd700"))  # Gold color
	
	# Add to scene and position
	add_child(popup)
	
	# Find center of matched gems
	var center = find_center_of_matched_gems()
	popup.position = center
	
	# Create animation
	var tween = create_tween()
	tween.tween_property(popup, "position:y", center.y - 100, 1.0)
	tween.parallel().tween_property(popup, "modulate:a", 0, 1.0)
	
	# Remove when animation completes
	tween.tween_callback(popup.queue_free)

# Find the center position of matched gems
func find_center_of_matched_gems() -> Vector2:
	# Default center position (fallback)
	var center = Vector2(
		game_board.position.x + 200,
		game_board.position.y + 200
	)
	
	return center
	
	# This method would be improved by actually calculating
	# the center of all matched gems - will be implemented later

# Return the current score
func get_current_score() -> int:
	return current_score

# Reset the score
func reset_score():
	current_score = 0
	update_score_display()
	emit_signal("score_updated", current_score)

# Load high score from save
func load_high_score():
	if FileAccess.file_exists("user://highscore.save"):
		var file = FileAccess.open("user://highscore.save", FileAccess.READ)
		high_score = file.get_var()
	else:
		high_score = 0

# Save high score
func save_high_score():
	var file = FileAccess.open("user://highscore.save", FileAccess.WRITE)
	file.store_var(high_score)
