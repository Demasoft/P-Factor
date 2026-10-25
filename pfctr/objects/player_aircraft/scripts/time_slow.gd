extends Node

var _tween: Tween


func slow( target: float = 0.3, duration: float = 0.25 ) -> void:
	_ease_to( target, duration )


func restore( duration: float = 0.25 ) -> void:
	_ease_to( 1.0, duration )


func _ease_to( target: float, duration: float ) -> void:
	if _tween:
		_tween.kill()
	# ignore_time_scale, otherwise the tween would be slowed by the very thing it controls
	_tween = create_tween().set_ignore_time_scale( true )
	_tween.tween_property( Engine, "time_scale", target, duration )
