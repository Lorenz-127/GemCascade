extends "res://scenes/game/gems/special_gem_base.gd"

func _ready():
	# Call parent ready function
	super._ready()
	
	# Set specific properties for vertical line blast
	special_type = "line_blast"
	orientation = "vertical"
	
	# Add any vertical-specific visual enhancements
	add_vertical_indicators()

func add_vertical_indicators():
	# Optional: Add additional visual elements to reinforce vertical orientation
	# This could be arrows or lines indicating the gem will affect the entire column
	pass

func activate():
	# Call parent activate for common effects
	var activation_started = await super.activate()
	
	# Play vertical blast animation
	play_vertical_blast_animation()
	
	# The actual gem clearing logic will be in BoardController
	# which calls this method and then handles the column clearing
	
	# Return true to signal successful activation
	return activation_started

func play_vertical_blast_animation():
	# Create vertical beam effect
	var beam = ColorRect.new()
	beam.color = Color(1, 1, 1, 0.7)  # Semi-transparent white
	
	# Set beam size and position (thin vertical rectangle)
	var grid_cell_size = 100  # This should come from GridManager
	beam.size = Vector2(10, grid_cell_size * 9)  # Height covers entire grid, width is thin
	beam.position = Vector2(-5, -grid_cell_size * 4)  # Center beam on gem
	
	add_child(beam)
	
	# Create beam animation
	var tween = create_tween()
	tween.tween_property(beam, "modulate", Color(1, 1, 1, 0), 0.4)
	tween.tween_callback(beam.queue_free)
