extends "res://scenes/game/gems/special_gem_base.gd"

func _ready():
	# Call parent ready function
	super._ready()
	
	# Set specific properties for horizontal line blast
	special_type = "line_blast"
	orientation = "horizontal"
	
	# Add any horizontal-specific visual enhancements
	add_horizontal_indicators()

func add_horizontal_indicators():
	# Optional: Add additional visual elements to reinforce horizontal orientation
	# This could be arrows or lines indicating the gem will affect the entire row
	pass

func activate():
	# Call parent activate for common effects
	var activation_started = await super.activate()
	
	# Play horizontal blast animation
	play_horizontal_blast_animation()
	
	# The actual gem clearing logic will be in BoardController
	# which calls this method and then handles the row clearing
	
	# Return true to signal successful activation
	return activation_started

func play_horizontal_blast_animation():
	# Create horizontal beam effect
	var beam = ColorRect.new()
	beam.color = Color(1, 1, 1, 0.7)  # Semi-transparent white
	
	# Set beam size and position (thin horizontal rectangle)
	var grid_cell_size = 100  # This should come from GridManager
	beam.size = Vector2(grid_cell_size * 9, 10)  # Width covers entire grid, height is thin
	beam.position = Vector2(-grid_cell_size * 4, -5)  # Center beam on gem
	
	add_child(beam)
	
	# Create beam animation
	var tween = create_tween()
	tween.tween_property(beam, "modulate", Color(1, 1, 1, 0), 0.4)
	tween.tween_callback(beam.queue_free)
