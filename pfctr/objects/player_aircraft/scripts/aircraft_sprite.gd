class_name AircraftSprite extends Sprite2D

var tween : Tween

func tween_color( duration : float = 0.5, color : Color = Color(1.825, 0.0, 0.295, 1.0) ) -> void:
	if tween:
		tween.kill()
	modulate = color
	tween = create_tween()
	tween.tween_property( self, "modulate", Color.WHITE, duration )

func trail() -> void:
	var effect : Node2D = Node2D.new()
	var p : Node2D = get_parent()
	p.add_sibling( effect )
	effect.get_parent().move_child( effect, 0 )
	effect.z_index = 1
	effect.global_position = p.global_position
	effect.modulate = Color(18.892, 0.0, 0.0, 0.749)
	
	var ghost: Sprite2D = duplicate()
	effect.add_child( ghost )

	var t : Tween = create_tween()
	t.set_ease( Tween.EASE_OUT )
	t.tween_property( effect, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.2 )
	t.chain().tween_callback( effect.queue_free )
