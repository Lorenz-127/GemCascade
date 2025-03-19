extends "res://scenes/game/gems/gem_base.gd"

# Special gem properties
var special_type: String = ""  # "line_blast", "cross_blast", "color_bomb", "super_bomb"
var orientation: String = ""   # "horizontal", "vertical" (for directional special gems)

# Visual effects
var glow_effect: Node2D = null
var particles: Node2D = null

# Flags
var is_activating: bool = false

func _ready():
	# Setup visual effects
	setup_visual_effects()
	
# Set up the special gem's visual effects
func setup_visual_effects():
	# Add a subtle glow effect
	if glow_effect == null:
		# Create a simple glow using a sprite with a shader
		# This is a placeholder - you can implement actual effects
		glow_effect = Sprite2D.new()
		glow_effect.texture = $Sprite2D.texture  # Use same texture as main sprite
		glow_effect.modulate = Color(1, 1, 1, 0.3)  # Semi-transparent
		glow_effect.scale = Vector2(1.2, 1.2)  # Slightly larger
		add_child(glow_effect)
		glow_effect.z_index = -1  # Place behind main sprite
		
		# Add subtle animation
		var tween = create_tween()
		tween.set_loops()  # Make the animation loop
		tween.tween_property(glow_effect, "modulate:a", 0.15, 1.0)
		tween.tween_property(glow_effect, "modulate:a", 0.3, 1.0)

# Override highlight method to add special highlight effect
func highlight():
	# Call the parent highlight method
	super.highlight()
	
	# Add additional special gem highlight effects
	if glow_effect:
		glow_effect.modulate = Color(1, 1, 1, 0.5)  # Make glow more intense
		
		# Pulse animation
		var tween = create_tween()
		tween.set_loops(2)  # Pulse twice
		tween.tween_property(glow_effect, "scale", Vector2(1.4, 1.4), 0.2)
		tween.tween_property(glow_effect, "scale", Vector2(1.2, 1.2), 0.2)

# Override unhighlight method
func unhighlight():
	# Call the parent unhighlight method
	super.unhighlight()
	
	# Reset glow effect
	if glow_effect:
		glow_effect.modulate = Color(1, 1, 1, 0.3)
		glow_effect.scale = Vector2(1.2, 1.2)

# Activation method - to be overridden by specific special gem types
func activate():
	is_activating = true
	
	# Play activation animation
	play_activation_animation()
	
	# This is where specific gem types will implement their effects
	# For now, just a placeholder
	print("Special gem activated: ", special_type)
	
	# Wait for animation to complete
	await get_tree().create_timer(0.5).timeout
	
	is_activating = false
	
	# Return true to indicate activation was successful
	return true

# Play the activation animation
func play_activation_animation():
	# Create a flash effect
	var flash = Sprite2D.new()
	flash.texture = $Sprite2D.texture
	flash.modulate = Color(1, 1, 1, 0)
	add_child(flash)
	
	# Flash animation
	var tween = create_tween()
	tween.tween_property(flash, "modulate", Color(1, 1, 1, 0.8), 0.1)
	tween.tween_property(flash, "modulate", Color(1, 1, 1, 0), 0.1)
	tween.tween_callback(flash.queue_free)
	
	# Scale animation
	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", scale * 1.5, 0.2)
	scale_tween.tween_property(self, "scale", scale, 0.2)

# Method to make the gem stand out before activation
func prepare_for_activation():
	# Make the gem pulse to indicate it's about to activate
	var tween = create_tween()
	tween.tween_property(self, "scale", scale * 1.3, 0.2)
	tween.tween_property(self, "scale", scale, 0.2)
	tween.set_loops(2)

# Helper to add particle effects
func add_particles(particle_type: String):
	# This could be implemented later with actual particle systems
	pass

# Method called when the gem is about to be destroyed
func prepare_for_destruction():
	# Visual effect before destruction
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.3)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	
	# Wait for animation to complete
	await tween.finished

# Override shake_gem for special gems
func shake_gem():
	var original_position = position
	var shake_strength = 8.0  # Stronger shake for special gems
	
	var tween = create_tween()
	tween.tween_property(self, "position", original_position + Vector2(shake_strength, 0), 0.05)
	tween.tween_property(self, "position", original_position - Vector2(shake_strength, 0), 0.05)
	tween.tween_property(self, "position", original_position, 0.05)
