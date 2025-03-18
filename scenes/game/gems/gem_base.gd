extends Node2D

# Type will be set when spawned
var type : int = -1
var matched : bool = false  # For future match detection

func highlight():
	# Scale up slightly for highlight effect
	var tween = create_tween()
	tween.tween_property(self, "scale", scale * 1.2, 0.2)

func unhighlight():
	# Scale back to normal
	var tween = create_tween()
	tween.tween_property(self, "scale", scale / 1.2, 0.2)

func shake_gem():
	var original_position = position
	var shake_strength = 5.0
	
	var tween = create_tween()
	tween.tween_property(self, "position", original_position + Vector2(shake_strength, 0), 0.05)
	tween.tween_property(self, "position", original_position - Vector2(shake_strength, 0), 0.05)
	tween.tween_property(self, "position", original_position, 0.05)
