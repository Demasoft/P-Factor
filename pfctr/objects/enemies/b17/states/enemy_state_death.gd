class_name EnemyStateDeath extends EnemyState

@export var drift_time: float = 1.5
@export var drift_distance: float = 60.0

@export_group("Fire")
@export var fire_scene: PackedScene
@export var fire_spawn_count: int = 12
@export var fire_alpha_param: StringName = &"fire_alpha"
@export var fire_fade_in: float = 0.1
@export var fire_hold: float = 0.3
@export var fire_fade_out: float = 0.25
@export var fire_end_scale: float = 0.7      # fire condenses as it dies

@export_group("Smoke")
@export var smoke_scene: PackedScene
@export var smoke_alpha_param: StringName = &"fire_alpha"
@export var smoke_overlap: float = 0.25      # how long smoke fades in while the fire fades out
@export var smoke_fade_in: float = 0.25
@export var smoke_hold: float = 0.3
@export var smoke_fade_out: float = 0.5
@export var smoke_start_scale: float = 0.7   # match fire_end_scale for a seamless handoff
@export var smoke_end_scale: float = 1.4     # smoke expands as it fades


func enter() -> void:
	enemy.velocity = Vector2.ZERO
	enemy.collision_polygon_2d.set_deferred("disabled", true)
	enemy.death.emit(enemy)

	_schedule_fires()

	var target: Vector2 = enemy.global_position + Vector2.from_angle(deg_to_rad(120.0)) * drift_distance
	var tween: Tween = enemy.create_tween()
	tween.tween_property(enemy, "global_position", target, drift_time).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_on_drift_finished)


func _schedule_fires() -> void:
	if fire_scene == null and smoke_scene == null:
		return

	# Parallel tween: every callback runs at its own random time within the drift
	var spawner: Tween = enemy.create_tween().set_parallel(true)
	for i in fire_spawn_count:
		spawner.tween_callback(_spawn_fire).set_delay(randf() * drift_time)


func _spawn_fire() -> void:
	var local_pos: Vector2 = enemy.to_local(_random_point_in_polygon())

	# Smoke starts fading in while the fire is still fading out
	var fire_total: float = fire_fade_in + fire_hold + fire_fade_out
	var smoke_delay: float = maxf(fire_total - smoke_overlap, 0.0)

	_spawn_faded(fire_scene, local_pos, fire_alpha_param, 0.0,
			fire_fade_in, fire_hold, fire_fade_out, 1.0, fire_end_scale)
	_spawn_faded(smoke_scene, local_pos, smoke_alpha_param, smoke_delay,
			smoke_fade_in, smoke_hold, smoke_fade_out, smoke_start_scale, smoke_end_scale)


func _spawn_faded(scene: PackedScene, local_pos: Vector2, alpha_param: StringName, delay: float,
		fade_in: float, hold: float, fade_out: float, start_scale: float, end_scale: float) -> void:
	if scene == null:
		return

	var node: Node2D = scene.instantiate()
	enemy.add_child(node)
	node.position = local_pos
	node.scale = Vector2.ONE * start_scale

	# Give each sprite its own material copy so instances don't fade together
	var mats: Array[ShaderMaterial] = []
	for child in node.find_children("*", "CanvasItem", true, false):
		var item := child as CanvasItem
		if item.material is ShaderMaterial:
			var mat := (item.material as ShaderMaterial).duplicate() as ShaderMaterial
			item.material = mat
			mats.append(mat)

	var set_alpha := func(v: float) -> void:
		for m in mats:
			m.set_shader_parameter(alpha_param, v)
	set_alpha.call(0.0)

	var total: float = fade_in + hold + fade_out

	# Alpha
	var life: Tween = node.create_tween()
	if delay > 0.0:
		life.tween_interval(delay)
	life.tween_method(set_alpha, 0.0, 1.0, fade_in).set_trans(Tween.TRANS_SINE)
	life.tween_interval(hold)
	life.tween_method(set_alpha, 1.0, 0.0, fade_out).set_trans(Tween.TRANS_SINE)
	life.tween_callback(node.queue_free)

	# Scale runs alongside, over the same lifetime
	var grow: Tween = node.create_tween()
	if delay > 0.0:
		grow.tween_interval(delay)
	grow.tween_property(node, "scale", Vector2.ONE * end_scale, total) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _random_point_in_polygon() -> Vector2:
	var poly_node: CollisionPolygon2D = enemy.collision_polygon_2d
	var poly: PackedVector2Array = poly_node.polygon

	# Rejection sampling inside the polygon's bounding box
	var min_p: Vector2 = poly[0]
	var max_p: Vector2 = poly[0]
	for p in poly:
		min_p = min_p.min(p)
		max_p = max_p.max(p)

	for attempt in 20:
		var candidate := Vector2(randf_range(min_p.x, max_p.x), randf_range(min_p.y, max_p.y))
		if Geometry2D.is_point_in_polygon(candidate, poly):
			return poly_node.to_global(candidate)

	return poly_node.global_position  # fallback


func _on_drift_finished() -> void:
	ExplosionGreat.explode(enemy.global_position)
	enemy.queue_free()
