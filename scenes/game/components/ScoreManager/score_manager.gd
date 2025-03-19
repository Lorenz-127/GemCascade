class_name ScoreManager
extends Node

# Signals
signal score_updated(new_score)
signal high_score_achieved(score)

# References
var game_board
var board_controller: BoardController
var grid_manager: GridManager

# State
var current_score: int = 0
var high_score: int = 0
var score_label: Label = null

func _ready():
	game_board = get_parent()

func initialize():
	# Get references to other components
	grid_manager = game_board.grid_manager
	
	# Find the score label by traversing up and then down the scene tree
	var main = get_tree().get_root().get_child(0)  # Get the Main node
	score_label = main.find_child("ScoreValueLabel", true, false)
	
	# Initialize score
	current_score = 0
	update_score_display()
	
	# Load high score if saved
	load_high_score()

# Update the score based on match information
func update_score_for_matches(matched_gems_count: int, chain_level: int = 0, matches = null):
	var points = calculate_match_points(matched_gems_count, chain_level)
	current_score += points
	update_score_display()
	
	# Check for high score
	if current_score > high_score:
		high_score = current_score
		emit_signal("high_score_achieved", high_score)
		save_high_score()
	
	# Show visual feedback
	show_score_popup(points, matches, chain_level)
	
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
func show_score_popup(points: int, matches = null, chain_level: int = 0):
	# Create a label for the score popup
	var popup = Label.new()
	
	# Format text based on chain level
	if chain_level <= 1:
		popup.text = "+" + str(points)
	else:
		# Add chain level indicator for cascades
		popup.text = "+" + str(points) + " Chain x" + str(chain_level)
	
	# Style based on chain level - higher chains get more exciting visuals
	var font_size = 32 + min(chain_level * 4, 16)  # Max font size increase of 16
	popup.add_theme_font_size_override("font_size", font_size)
	
	# Color gets more intense with higher chains - from gold to bright orange/red
	var color
	if chain_level <= 1:
		color = Color("#ffd700")  # Gold
	elif chain_level == 2:
		color = Color("#ffaa00")  # Orange-gold
	elif chain_level == 3:
		color = Color("#ff8800")  # Orange
	else:
		color = Color("#ff5500")  # Red-orange
	
	popup.add_theme_color_override("font_color", color)
	
	# Add to scene and position
	add_child(popup)
	
	# Find center of matched gems
	var center = find_center_of_matched_gems(matches)
	
	# Convert position to global space
	center = game_board.to_global(center)
	
	# Set initial position
	popup.position = center - popup.size / 2  # Center the label at the position
	
	# Create animation - higher chains get more dramatic animations
	var tween = create_tween()
	var rise_distance = 100 + (chain_level * 20)  # Longer rise for higher chains
	var duration = 1.0 + (chain_level * 0.1)  # Slightly longer duration for higher chains
	
	tween.tween_property(popup, "position:y", popup.position.y - rise_distance, duration)
	tween.parallel().tween_property(popup, "modulate:a", 0, duration)
	
	# Add a scale effect for higher chains
	if chain_level > 1:
		popup.scale = Vector2(1.0, 1.0)
		tween.parallel().tween_property(popup, "scale", Vector2(1.2, 1.2), 0.2)
		tween.parallel().tween_property(popup, "scale", Vector2(1.0, 1.0), duration - 0.2)
	
	# Remove when animation completes
	tween.tween_callback(popup.queue_free)

# Find the center position of matched gems
func find_center_of_matched_gems(matches = null) -> Vector2:
	# Default center position (fallback)
	var default_center = Vector2(
		grid_manager.position.x + grid_manager.get_grid_dimensions().x * grid_manager.cell_size / 2,
		grid_manager.position.y + grid_manager.get_grid_dimensions().y * grid_manager.cell_size / 2
	)
	
	# If no matches provided, return default center
	if matches == null or matches.size() == 0:
		return default_center
	
	# Calculate the center of all matched positions
	var sum_x = 0
	var sum_y = 0
	var total_positions = 0
	
	# Loop through all match groups
	for match_info in matches:
		var positions = match_info.positions
		
		for pos in positions:
			# Convert grid position to pixel coordinates
			var pixel_pos = grid_manager.grid_to_pixel(pos.x, pos.y)
			
			# Add cell_size/2 to center in the cell
			pixel_pos.x += grid_manager.cell_size / 2
			pixel_pos.y += grid_manager.cell_size / 2
			
			sum_x += pixel_pos.x
			sum_y += pixel_pos.y
			total_positions += 1
	
	# Calculate average position (center)
	if total_positions > 0:
		return Vector2(sum_x / total_positions, sum_y / total_positions)
	else:
		return default_center

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
