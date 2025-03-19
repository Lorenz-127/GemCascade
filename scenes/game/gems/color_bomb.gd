extends "res://scenes/game/gems/special_gem_base.gd"

var target_color_type: int = -1  # Type of gem to clear, set during activation

func _ready():
	# Call parent ready function
	super._ready()
	
	# Set specific properties for color bomb
	special_type = "color_bomb"
	
	# Add rainbow pulsing or other special visuals
	enhance_color_bomb_visuals()

func enhance_color_bomb_visuals():
	# Add a rainbow/pulsing effect to make the color bomb stand out
	var rainbow_tween = create_tween()
	rainbow_tween.set_loops()
	
	# Cycle through some hue shifts for a rainbow-like effect
	# This is a simple version, could be enhanced with a shader
	rainbow_tween.tween_property($Sprite2D, "modulate", 
							   Color(1.0, 0.8, 0.8), 0.7)  # Reddish
	rainbow_tween.tween_property($Sprite2D, "modulate", 
							   Color(1.0, 1.0, 0.8), 0.7)  # Yellowish
	rainbow_tween.tween_property($Sprite2D, "modulate", 
							   Color(0.8, 1.0, 0.8), 0.7)  # Greenish
	rainbow_tween.tween_property($Sprite2D, "modulate", 
							   Color(0.8, 0.8, 1.0), 0.7)  # Bluish
	rainbow_tween.tween_property($Sprite2D, "modulate", 
							   Color(1.0, 0.8, 1.0), 0.7)  # Purplish
	rainbow_tween.tween_property($Sprite2D, "modulate", 
							   Color(1.0, 1.0, 1.0), 0.7)  # Back to normal

func activate():
	# Call parent activate for common effects
	var activation_started = await super.activate()
	
	# Play color bomb activation animation
	play_color_bomb_animation()
	
	# The actual gem clearing logic will be in BoardController
	# which calls this method and then handles clearing all gems of target color
	
	# Return true to signal successful activation
	return activation_started

func set_target_color(color_type: int):
	# Set which color type this bomb will clear when activated
	target_color_type = color_type

func play_color_bomb_animation():
	# Create a radial explosion effect
	var explosion = Node2D.new()
	add_child(explosion)
	
	# Create a series of expanding circles
	for i in range(5):
		var circle = create_circle(5 + i * 15, Color(1, 1, 1, 0.8 - i * 0.15))
		explosion.add_child(circle)
	
	# Animate the explosion outward
	var tween = create_tween()
	tween.tween_property(explosion, "scale", Vector2(3, 3), 0.5)
	tween.parallel().tween_property(explosion, "modulate", Color(1, 1, 1, 0), 0.5)
	
	# Clean up
	tween.tween_callback(explosion.queue_free)

# Helper function to create a circle shape
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
