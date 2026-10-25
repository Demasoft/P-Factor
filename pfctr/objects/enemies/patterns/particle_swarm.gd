class_name ParticleSwarm extends Node2D
## Particle swarm enemy. Particles leave one after another and fly toward the
## target in a weaving stream. Data lives in packed arrays and is drawn with one
## MultiMesh, using the Sprite2D and AnimationPlayer children of this scene.

## Bullets call try_hit() themselves (see ParticleSwarm.active).

signal cleared

enum SpawnMode { INSTANT, STREAM, ON_SOURCE_DEATH }

const SHADER: Shader = preload("uid://btshx7hjfq86s")

## Every live swarm. Bullets iterate this instead of using node groups.
static var active: Array[ParticleSwarm] = []

const NO_SPAWN: int = 0
const LAST_OFFSET: int = 1
const STEP_DOWN: int = -1
const MIN_DISTANCE: float = 0.001
const MIN_FRAMES: int = 1

@export var explosion_scene: PackedScene  

@export_group("Swarm")
@export var swarm_count: int = 40                 # total particles, read once at spawn
@export var spawn_radius: float = 20.0
@export var particle_hp: float = 1.0
@export var particle_scale: float = 1.0

@export_group("Target")
@export var target: PlayerAircraft = null         # assign in the Inspector or from code

@export_group("Spawning")
@export var spawn_mode: SpawnMode = SpawnMode.INSTANT
@export var spawn_source: Node2D = null           # optional: boss or emitter
@export var stream_rate: float = 20.0             # particles per second (STREAM only)

@export_group("Stream")
@export var launch_interval: float = 0.08         # seconds between particles leaving
@export var weave_speed: float = 120.0            # sideways speed of the wave
@export var weave_frequency: float = 5.0          # radians per second
@export var weave_fade_distance: float = 140.0    # the wave calms down this close to the target

@export_group("Movement")
@export var max_speed: float = 260.0
@export var acceleration: float = 900.0           # lower = wider, lazier turns
@export var rotate_to_velocity: bool = true       # sprite is assumed to face right

@export_group("Animation")
@export var animation_name: StringName = &"fly"   # leave empty to not play anything
@export var desync_frames: bool = true            # particles don't flap in unison

@export_group("Combat")
@export var contact_damage: float = 1.0
@export var particle_radius: float = 6.0
@export var player_hit_radius: float = 14.0

@onready var template_sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var positions: PackedVector2Array = PackedVector2Array()
var velocities: PackedVector2Array = PackedVector2Array()
var launch_times: PackedFloat32Array = PackedFloat32Array()
var frame_offsets: PackedFloat32Array = PackedFloat32Array()
var hit_points: PackedFloat32Array = PackedFloat32Array()

var alive_count: int = 0
var spawned_total: int = 0
var spawn_accumulator: float = 0.0
var spawn_origin: Vector2 = Vector2.ZERO
var time_alive: float = 0.0
var frame_count: int = MIN_FRAMES

var multimesh: MultiMesh = null
var renderer: MultiMeshInstance2D = null
var shader_material: ShaderMaterial = null


func _ready() -> void:
	active.append(self)

	spawn_origin = global_position
	top_level = true                      # particles live in world space
	global_position = Vector2.ZERO

	allocate_arrays()
	setup_renderer()
	setup_animation()
	configure_spawning()
	#Messages.particle_removed.connect(_on_particle_removed)

func _exit_tree() -> void:
	active.erase(self)


func _physics_process(delta: float) -> void:
	time_alive += delta
	update_stream(delta)

	if alive_count == NO_SPAWN:
		update_renderer()
		finish_if_done()
		return

	resolve_player_contact()
	simulate(delta)
	update_renderer()


# ---------- public API ----------

## Called by bullets. Returns true if the bullet hit a particle.
func try_hit(point: Vector2, hit_radius: float, damage: float) -> bool:
	var reach: float = particle_radius + hit_radius
	var reach_squared: float = reach * reach

	for index: int in range(alive_count):
		if positions[index].distance_squared_to(point) > reach_squared:
			continue

		hit_points[index] -= damage
		if hit_points[index] <= 0.0:
			remove_particle(index)
		return true

	return false


# ---------- setup ----------

func allocate_arrays() -> void:
	positions.resize(swarm_count)
	velocities.resize(swarm_count)
	launch_times.resize(swarm_count)
	frame_offsets.resize(swarm_count)
	hit_points.resize(swarm_count)
	alive_count = NO_SPAWN


func setup_renderer() -> void:
	var sheet_frames: Vector2 = Vector2(template_sprite.hframes, template_sprite.vframes)
	frame_count = maxi(template_sprite.hframes * template_sprite.vframes, MIN_FRAMES)
	template_sprite.visible = false       # only used as the data source

	var quad: QuadMesh = QuadMesh.new()
	quad.size = template_sprite.texture.get_size() / sheet_frames * particle_scale

	shader_material = ShaderMaterial.new()
	shader_material.shader = SHADER
	shader_material.set_shader_parameter(&"h_frames", template_sprite.hframes)
	shader_material.set_shader_parameter(&"v_frames", template_sprite.vframes)

	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_custom_data = true      # must be set before instance_count
	multimesh.mesh = quad
	multimesh.instance_count = swarm_count
	multimesh.visible_instance_count = alive_count

	renderer = MultiMeshInstance2D.new()
	renderer.multimesh = multimesh
	renderer.texture = template_sprite.texture
	renderer.material = shader_material
	add_child(renderer)


func setup_animation() -> void:
	if animation_name == &"" or not animation_player.has_animation(animation_name):
		return
	animation_player.play(animation_name)


func update_renderer() -> void:
	shader_material.set_shader_parameter(&"base_frame", template_sprite.frame)
	multimesh.visible_instance_count = alive_count

	for index: int in range(alive_count):
		var angle: float = 0.0
		if rotate_to_velocity:
			angle = velocities[index].angle()
		multimesh.set_instance_transform_2d(index, Transform2D(angle, positions[index]))
		multimesh.set_instance_custom_data(index, Color(frame_offsets[index], 0.0, 0.0, 0.0))


# ---------- spawning ----------

func configure_spawning() -> void:
	if spawn_mode == SpawnMode.ON_SOURCE_DEATH:
		if spawn_source == null:
			push_warning("ParticleSwarm: ON_SOURCE_DEATH needs a spawn_source, using INSTANT")
			spawn_mode = SpawnMode.INSTANT
		else:
			spawn_source.tree_exiting.connect(_on_source_exiting)

	if spawn_mode == SpawnMode.INSTANT:
		spawn_particles(swarm_count, get_spawn_origin())


func get_spawn_origin() -> Vector2:
	# Remembers the last known position, so a freed source doesn't reset the origin.
	if is_instance_valid(spawn_source):
		spawn_origin = spawn_source.global_position
	return spawn_origin


func update_stream(delta: float) -> void:
	if spawn_mode != SpawnMode.STREAM or spawned_total >= swarm_count:
		return

	spawn_accumulator += stream_rate * delta
	var whole_particles: int = int(spawn_accumulator)
	if whole_particles <= NO_SPAWN:
		return

	spawn_accumulator -= float(whole_particles)
	spawn_particles(whole_particles, get_spawn_origin())


func spawn_particles(requested: int, origin: Vector2) -> void:
	var count: int = mini(requested, swarm_count - spawned_total)

	for step: int in range(count):
		var index: int = alive_count
		var angle: float = randf_range(0.0, TAU)
		var radius: float = sqrt(randf()) * spawn_radius   # sqrt = uniform over the disc
		positions[index] = origin + Vector2.from_angle(angle) * radius
		velocities[index] = Vector2.ZERO
		# Particles of the same batch leave one after another, forming the stream.
		launch_times[index] = time_alive + float(step) * launch_interval
		frame_offsets[index] = 0.0
		if desync_frames:
			frame_offsets[index] = float(randi_range(0, frame_count - LAST_OFFSET))
		hit_points[index] = particle_hp
		alive_count += 1
		spawned_total += 1


func _on_source_exiting() -> void:
	spawn_particles(swarm_count - spawned_total, spawn_source.global_position)


func finish_if_done() -> void:
	if spawned_total < swarm_count:
		return
	cleared.emit()
	queue_free()


# ---------- simulation ----------

func simulate(delta: float) -> void:
	var has_target: bool = is_instance_valid(target)
	var target_position: Vector2 = Vector2.ZERO
	if has_target:
		target_position = target.global_position

	for index: int in range(alive_count):
		var desired: Vector2 = Vector2.ZERO
		if has_target and time_alive >= launch_times[index]:
			desired = compute_desired_velocity(index, target_position)

		velocities[index] = velocities[index].move_toward(desired, acceleration * delta)
		positions[index] += velocities[index] * delta


func compute_desired_velocity(index: int, target_position: Vector2) -> Vector2:
	var to_target: Vector2 = target_position - positions[index]
	var distance: float = maxf(to_target.length(), MIN_DISTANCE)
	var direction: Vector2 = to_target / distance

	# The wave depends on the time since launch, so every particle draws the
	# same curve and together they form one continuous weaving stream.
	var age: float = time_alive - launch_times[index]
	var fade: float = clampf(distance / maxf(weave_fade_distance, MIN_DISTANCE), 0.0, 1.0)
	var lateral: Vector2 = direction.orthogonal() * sin(age * weave_frequency) * weave_speed * fade

	return direction * max_speed + lateral


# ---------- collisions ----------

func resolve_player_contact() -> void:
	if not is_instance_valid(target):
		return

	var reach: float = particle_radius + player_hit_radius
	var reach_squared: float = reach * reach
	var target_position: Vector2 = target.global_position

	# Descending order keeps swap-remove safe while looping.
	for index: int in range(alive_count - LAST_OFFSET, STEP_DOWN, STEP_DOWN):
		if positions[index].distance_squared_to(target_position) <= reach_squared:
			target.hp -= contact_damage
			remove_particle(index)


func remove_particle(index: int) -> void:
	var last: int = alive_count - LAST_OFFSET
	positions[index] = positions[last]
	velocities[index] = velocities[last]
	launch_times[index] = launch_times[last]
	frame_offsets[index] = frame_offsets[last]
	hit_points[index] = hit_points[last]
	alive_count -= 1
	
#func _on_particle_removed(world_position: Vector2, killed_by_player: bool) -> void:
	#if not killed_by_player:
		#return
	#var fx: Node2D = explosion_scene.instantiate()
	#get_tree().current_scene.add_child(fx)   # NOT as a child of the swarm, see below
	#fx.explode(world_position)
	#pass
