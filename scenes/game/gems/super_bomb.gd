extends "res://scenes/game/gems/special_gem_base.gd"

func _ready():
	# Call parent ready function
	super._ready()
	
	# Set specific properties for super bomb
	special_type = "super_bomb"
	
	# Add super bomb specific visual enhancements
	enhance_super_bomb_visuals()

func enhance_super_bomb_visuals():
	# Add pulsing effect and other visual elements
	# to emphasize this is the most powerful gem
	
	# Create a pulsing glow
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	
	# Stronger pulse animation with color shifts
	pulse_tween.tween_property($Sprite2D, "modulate", 
							  Color(1.2, 1.0, 1.0), 0.5)  # Reddish
	pulse_tween.tween_property($Sprite2D, "modulate", 
							  Color(1.0, 1.0, 1.2), 0.5)  # Bluish
	pulse_tween.tween_property($Sprite2D, "modulate", 
							  Color(1.0, 1.2, 1.0), 0.5)  # Greenish
	pulse_tween.tween_property($Sprite2D, "modulate", 
							  Color(1.0, 1.0, 1.0), 0.5)  # Normal

func activate():
	# Call parent activate for common effects
	var activation_started = await super.activate()
	
	# Play super bomb activation animation
	play_super_bomb_animation()
	
	# The actual gem clearing logic will be in BoardController
	# which calls this method and handles clearing a large area (3x3 or 5x5)
	
	# Return true to signal successful activation
	return activation_started

func play_super_bomb_animation():
	# Create a powerful explosion effect
	
	# First a flash
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0.9)
	flash.size = Vector2(1000, 1000)  # Big enough to cover screen
	flash.position = Vector2(-500, -500)  # Center it
	add_child(flash)
	
	# Circle explosion
	var explosion = Node2D.new()
	add_child(explosion)
	
	# Create a series of expanding circles
	for i in range(8):  # More circles for bigger effect
		var circle = create_circle(10 + i * 20, Color(1, 1, 1, 0.9 - i * 0.1))
		explosion.add_child(circle)
	
	# Animate the flash and explosion
	var tween = create_tween()
	
	# Flash fades quickly
	tween.tween_property(flash, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_callback(flash.queue_free)
	
	# Explosion grows and fades
	tween.tween_property(explosion, "scale", Vector2(5, 5), 0.7)
	tween.parallel().tween_property(explosion, "modulate", Color(1, 1, 1, 0), 0.7)
	
	# Clean up
	tween.tween_callback(explosion.queue_free)
	
	# Also add some camera shake - we'll emit a signal that GameBoard can respond to
	# Placeholder for when we implement signal system
	# emit_signal("request_camera_shake", 0.5, 10.0)  # duration, intensity

# Helper function to create a circle shape (same as in ColorBomb)
func create_circle(radius: float, color: Color) -> Node2D:
	var circle = Node2D.new()
	
	# Add properties as metadata
	circle.set_meta("radius", radius)
	circle.set_meta("color", color)
	
	# Create a simpler script
	var script = GDScript.new()
	script.source_code = """
extends Node2D

func _draw():
	var radius = get_meta("radius")
	var color = get_meta("color")
	
	var circle_points = PackedVector2Array()
	for i in range(36):
		var angle = i * PI * 2 / 36
		circle_points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	draw_colored_polygon(circle_points, color)
"""
	
	circle.set_script(script)
	return circle
