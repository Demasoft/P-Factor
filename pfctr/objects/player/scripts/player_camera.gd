class_name PlayerCamera extends Camera2D

func _ready() -> void:
	SceneManager.new_scene_ready.connect( _on_scene_transition )
	
func _on_scene_transition( _t, _o ) -> void:
	reset_smoothing.call_deferred()
