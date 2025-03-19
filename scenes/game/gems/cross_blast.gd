extends "res://scenes/game/gems/special_gem_base.gd"

func _ready():
	# Call parent ready function
	super._ready()
	
	# Set specific properties for cross blast
	special_type = "cross_blast"
	
	# Add any cross-specific visual enhancements
	enhance_cross_visuals()

func enhance_cross_visuals():
	# Optional: Add pulsing effect or other visual elements
	# to emphasize the cross-blast nature
	var pulse_tween = create_tween()
	pulse_tween.set_loops()  # Make it loop infinitely
	
	# Subtle pulse animation
	pulse_tween.tween_property($Sprite2D, "modulate", 
							  Color(1, 1, 1, 0.8), 1.0)
	pulse_tween.tween_property($Sprite2D, "modulate", 
							  Color(1, 1, 1, 1.0), 1.0)

func activate():
	# Call parent activate for common effects
	var activation_started = await super.activate()
	
	# Play cross blast animation - combining horizontal and vertical effects
	play_cross_blast_animation()
	
	# The actual gem clearing logic will be in BoardController
	# which calls this method and handles clearing both row and column
	
	# Return true to signal successful activation
	return activation_started

func play_cross_blast_animation():
	# Create horizontal beam
	var h_beam = ColorRect.new()
	h_beam.color = Color(1, 1, 1, 0.7)
	
	var grid_cell_size = 100  # This should come from GridManager
	h_beam.size = Vector2(grid_cell_size * 9, 10)
	h_beam.position = Vector2(-grid_cell_size * 4, -5)
	
	add_child(h_beam)
	
	# Create vertical beam
	var v_beam = ColorRect.new()
	v_beam.color = Color(1, 1, 1, 0.7)
	v_beam.size = Vector2(10, grid_cell_size * 9)
	v_beam.position = Vector2(-5, -grid_cell_size * 4)
	
	add_child(v_beam)
	
	# Animate beams
	var tween = create_tween()
	tween.tween_property(h_beam, "modulate", Color(1, 1, 1, 0), 0.4)
	tween.parallel().tween_property(v_beam, "modulate", Color(1, 1, 1, 0), 0.4)
	
	# Clean up after animation
	tween.tween_callback(h_beam.queue_free)
	tween.tween_callback(v_beam.queue_free)
