extends ColorRect

func play(angle_deg: float = 90.0, duration: float = 1.2) -> void:
	var mat := material as ShaderMaterial
	mat.set_shader_parameter("debris_angle", angle_deg)
	mat.set_shader_parameter("seed", randf() * 100.0)
	mat.set_shader_parameter("progress", 0.0)

	var t := create_tween()
	t.tween_property(mat, "shader_parameter/progress", 1.0, duration)
	t.tween_callback(queue_free)
