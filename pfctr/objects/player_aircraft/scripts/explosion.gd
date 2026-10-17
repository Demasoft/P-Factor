extends Node2D
# Explosion with burning debris that leaves smoke trails.
# Layers: flash, fireball, sparks, debris (+ smoke-trail sub-emitter), smoke.

var debris: GPUParticles2D
var trail: GPUParticles2D
var layers: Array[GPUParticles2D] = []

func _ready() -> void:
	var soft := _soft_circle(64)
	var hard := _soft_circle(16, 0.6)

	# 1. Flash (a single instant burst)
	layers.append(_make(soft, 1, 0.15, true, _flash_material()))

	# 2. Fireball
	layers.append(_make(soft, 40, 0.7, true, _fire_material(), true))

	# 3. Sparks
	layers.append(_make(hard, 60, 0.9, true, _spark_material(), true))

	# 4. Smoke trail (sub-emitter spawned by each debris piece)
	trail = _make(soft, 1500, 0.9, false, _trail_material())
	trail.emitting = false

	# 5. Burning debris
	debris = _make(hard, 24, 1.6, true, _debris_material(), true)
	debris.sub_emitter = get_path_to(trail)
	layers.append(debris)

	# 6. Lingering smoke cloud
	layers.append(_make(soft, 30, 2.5, true, _smoke_material()))

	for l in layers:
		l.emitting = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		explode(get_global_mouse_position())

func explode(pos: Vector2) -> void:
	global_position = pos
	for l in layers:
		l.restart()
		l.emitting = true

# ---------------------------------------------------------------- helpers

func _make(tex: Texture2D, amount: int, life: float, one_shot: bool,
		mat: ParticleProcessMaterial, additive := false) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.texture = tex
	p.amount = amount
	p.lifetime = life
	p.one_shot = one_shot
	p.explosiveness = 1.0 if one_shot else 0.0
	p.process_material = mat
	p.local_coords = false
	if additive:
		var cm := CanvasItemMaterial.new()
		cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = cm
	add_child(p)
	return p

func _soft_circle(size: int, hardness := 0.0) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(clampf(hardness, 0.0, 0.95), Color.WHITE if hardness > 0 else Color(1, 1, 1, 0.5))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = size
	t.height = size
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	return t

func _ramp(stops: Array) -> GradientTexture1D:
	# stops: [[offset, Color], ...]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array()
	g.colors = PackedColorArray()
	for s in stops:
		g.add_point(s[0], s[1])
	# remove the two default points
	g.remove_point(0)
	g.remove_point(0)
	var t := GradientTexture1D.new()
	t.gradient = g
	return t

func _curve(points: Array) -> CurveTexture:
	var c := Curve.new()
	for p in points:
		c.add_point(Vector2(p[0], p[1]))
	var t := CurveTexture.new()
	t.curve = c
	return t

# ------------------------------------------------------- process materials

func _flash_material() -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.gravity = Vector3.ZERO
	m.scale_min = 4.0
	m.scale_max = 5.0
	m.color_ramp = _ramp([[0.0, Color(1, 1, 0.9, 1)], [1.0, Color(1, 0.7, 0.2, 0)]])
	return m

func _fire_material() -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 10.0
	m.direction = Vector3(0, -1, 0)
	m.spread = 180.0
	m.gravity = Vector3(0, -60, 0)
	m.initial_velocity_min = 60.0
	m.initial_velocity_max = 220.0
	m.damping_min = 80.0
	m.damping_max = 140.0
	m.scale_min = 1.2
	m.scale_max = 2.4
	m.scale_curve = _curve([[0, 0.6], [0.3, 1.0], [1, 0.2]])
	m.color_ramp = _ramp([
		[0.0, Color(1, 0.95, 0.6, 1)],
		[0.3, Color(1, 0.55, 0.1, 0.9)],
		[0.7, Color(0.7, 0.15, 0.05, 0.5)],
		[1.0, Color(0.2, 0.05, 0.0, 0)]])
	return m

func _spark_material() -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0, -1, 0)
	m.spread = 180.0
	m.gravity = Vector3(0, 500, 0)
	m.initial_velocity_min = 250.0
	m.initial_velocity_max = 700.0
	m.damping_min = 40.0
	m.damping_max = 90.0
	m.scale_min = 0.15
	m.scale_max = 0.4
	m.color_ramp = _ramp([
		[0.0, Color(1, 0.9, 0.5, 1)],
		[0.5, Color(1, 0.45, 0.1, 1)],
		[1.0, Color(0.8, 0.1, 0.0, 0)]])
	return m

func _debris_material() -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0, -1, 0)
	m.spread = 90.0                       # biased upward; raise to 180 for all directions
	m.gravity = Vector3(0, 700, 0)
	m.initial_velocity_min = 250.0
	m.initial_velocity_max = 650.0
	m.damping_min = 20.0
	m.damping_max = 50.0
	m.angle_min = 0.0
	m.angle_max = 360.0
	m.scale_min = 0.5
	m.scale_max = 1.1
	m.color_ramp = _ramp([
		[0.0, Color(1, 0.85, 0.4, 1)],
		[0.4, Color(1, 0.4, 0.05, 1)],
		[0.8, Color(0.3, 0.08, 0.02, 0.9)],
		[1.0, Color(0.1, 0.05, 0.05, 0)]])
	# Every debris piece continuously spawns smoke particles = trail
	m.sub_emitter_mode = ParticleProcessMaterial.SUB_EMITTER_CONSTANT
	m.sub_emitter_frequency = 45.0
	m.sub_emitter_keep_velocity = false
	return m

func _trail_material() -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.gravity = Vector3(0, -40, 0)        # smoke drifts up
	m.initial_velocity_min = 0.0
	m.initial_velocity_max = 15.0
	m.spread = 180.0
	m.direction = Vector3(0, -1, 0)
	m.angle_min = 0.0
	m.angle_max = 360.0
	m.scale_min = 0.25
	m.scale_max = 0.4
	m.scale_curve = _curve([[0, 0.5], [1, 2.2]])   # puffs expand as they fade
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 2.0
	m.color_ramp = _ramp([
		[0.0, Color(1, 0.6, 0.2, 0.7)],   # glowing near the debris
		[0.15, Color(0.35, 0.3, 0.28, 0.6)],
		[1.0, Color(0.1, 0.1, 0.1, 0)]])
	return m

func _smoke_material() -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 20.0
	m.direction = Vector3(0, -1, 0)
	m.spread = 120.0
	m.gravity = Vector3(0, -30, 0)
	m.initial_velocity_min = 20.0
	m.initial_velocity_max = 90.0
	m.damping_min = 30.0
	m.damping_max = 60.0
	m.angle_min = 0.0
	m.angle_max = 360.0
	m.scale_min = 1.5
	m.scale_max = 3.0
	m.scale_curve = _curve([[0, 0.4], [1, 1.6]])
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 1.5
	m.color_ramp = _ramp([
		[0.0, Color(0.15, 0.13, 0.12, 0.0)],
		[0.15, Color(0.2, 0.18, 0.17, 0.7)],
		[1.0, Color(0.08, 0.08, 0.08, 0)]])
	return m
