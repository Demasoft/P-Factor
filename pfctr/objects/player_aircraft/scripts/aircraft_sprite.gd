class_name AircraftSprite extends Node2D

var tween : Tween

func tween_color( duration : float = 0.5, color : Color = Color.FIREBRICK ) -> void:
	if tween:
		tween.kill()
	modulate = color
	tween = create_tween()
	tween.tween_property( self, "modulate", Color.CORNSILK, duration )

func trail() -> void:
	var effect : Node2D = Node2D.new()
	var p : Node2D = get_parent()
	p.add_sibling( effect )
	effect.z_index = 1
	effect.global_position = p.global_position
	effect.modulate = Color(0.69803923, 0.13333334, 0.13333334, 0.75)
	
	var ghost: Sprite2D = duplicate()
	effect.add_child( ghost )

	var t : Tween = create_tween()
	t.set_ease( Tween.EASE_OUT )
	t.tween_property( effect, "modulate", Color.WHITE, 0.2 )
	t.chain().tween_callback( effect.queue_free )
