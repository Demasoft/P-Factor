class_name DeathExplosion extends RefCounted

const SHADER: Shader = preload("uid://cveowdxnaunsl")
const BLAST_COUNT: int = 8
const BLAST_SIZE: float = 48.0
const MAX_DELAY: float = 0.5


static func play(polygon_node: CollisionPolygon2D, drift_time: float) -> void:
	var scene_root: Node = polygon_node.get_tree().current_scene

	for i in BLAST_COUNT:
		var local_point: Vector2 = _random_point_in(polygon_node.polygon)
		var world_point: Vector2 = polygon_node.global_transform * local_point
		var delay: float = randf_range(0.0, minf(MAX_DELAY, drift_time * 0.5))
		var blast_time: float = maxf(0.01, drift_time - delay)

		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter("seed", randf())
		material.set_shader_parameter("progress", 0.0)

		var blast: ColorRect = ColorRect.new()
		blast.size = Vector2.ONE * BLAST_SIZE * randf_range(0.7, 1.3)
		blast.material = material
		blast.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blast.z_index = 10
		blast.visible = false
		scene_root.add_child(blast)
		blast.global_position = world_point - blast.size * 0.5

		var tween: Tween = blast.create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(blast.show)
		tween.tween_property(material, "shader_parameter/progress", 1.0, blast_time)
		tween.tween_callback(blast.queue_free)


static func _random_point_in(polygon: PackedVector2Array) -> Vector2:
	var bounds: Rect2 = Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)

	for i in 20:
		var candidate: Vector2 = Vector2(
			randf_range(bounds.position.x, bounds.end.x),
			randf_range(bounds.position.y, bounds.end.y)
		)
		if Geometry2D.is_point_in_polygon(candidate, polygon):
			return candidate

	return bounds.get_center()
