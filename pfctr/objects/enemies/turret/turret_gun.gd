@tool
class_name TurretGun extends Node2D

const TARGET_GROUP: StringName = &"PlayerAircraft"
const IDLE_ANIMATION: StringName = &"idle"
const FIRE_ANIMATION: StringName = &"fire"
enum RestDirection { RIGHT, LEFT }

const REST_RIGHT_DEGREES: float = 0.0
const REST_LEFT_DEGREES: float = 180.0
const FULL_CIRCLE_DEGREES: float = 360.0
const ARC_POINTS: int = 32
const GIZMO_COLOR: Color = Color(1.0, 0.3, 0.2, 0.8)
const GIZMO_WIDTH: float = 2.0
const NO_TIME: float = 0.0
const SCALE_NORMAL: float = 1.0
const SCALE_FLIPPED: float = -1.0

@export_group("Firing Range")
@export_range(-360.0, 360.0, 1.0) var arc_start_degrees: float = 135.0:
	set(value):
		arc_start_degrees = value
		queue_redraw()
@export_range(-360.0, 360.0, 1.0) var arc_end_degrees: float = 225.0:
	set(value):
		arc_end_degrees = value
		queue_redraw()
@export var rest_direction: RestDirection = RestDirection.LEFT:
	set(value):
		rest_direction = value
		queue_redraw()
@export var detection_radius: float = 400.0:
	set(value):
		detection_radius = value
		queue_redraw()

@export_group("Aiming")
@export var turn_speed_degrees: float = 120.0
@export var aim_tolerance_degrees: float = 4.0
@export var flip_when_aiming_left: bool = true
@export var target: Node2D = null

@export_group("Shooting")
@export var enabled: bool = true:
	set(value):
		enabled = value
		if not enabled:
			is_firing = false
@export var bullet_scene: PackedScene
@export var patterns: Array[BulletPattern] = []
@export var fire_cooldown: float = 1.5

@onready var pivot: Node2D = $Pivot
@onready var muzzle: Marker2D = $Pivot/Muzzle
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

var pattern_index: int = 0
var current_pattern: BulletPattern = null
var volleys_left: int = 0
var volley_timer: float = NO_TIME
var cooldown: float = NO_TIME
var is_firing: bool = false


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return

	pivot.rotation = deg_to_rad(get_rest_degrees())
	update_flip()
	play_animation(IDLE_ANIMATION)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not enabled:
		return

	cooldown = maxf(cooldown - delta, NO_TIME)

	if is_firing:
		update_burst(delta)
		return

	var aim_degrees: float = get_rest_degrees()
	var has_target: bool = false
	var target_node: Node2D = get_target()
	if target_node != null and is_in_range(target_node):
		var target_degrees: float = get_target_degrees(target_node)
		if is_in_arc(target_degrees):
			aim_degrees = target_degrees
			has_target = true

	aim(aim_degrees, delta)
	if has_target and cooldown <= NO_TIME and can_fire(aim_degrees):
		start_burst()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var radius: float = detection_radius
	var sweep: float = get_sweep_degrees()
	if sweep >= FULL_CIRCLE_DEGREES:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, ARC_POINTS, GIZMO_COLOR, GIZMO_WIDTH)
	else:
		var start_angle: float = deg_to_rad(arc_start_degrees)
		var end_angle: float = start_angle + deg_to_rad(sweep)
		draw_arc(Vector2.ZERO, radius, start_angle, end_angle, ARC_POINTS, GIZMO_COLOR, GIZMO_WIDTH)
		draw_line(Vector2.ZERO, Vector2.from_angle(start_angle) * radius, GIZMO_COLOR, GIZMO_WIDTH)
		draw_line(Vector2.ZERO, Vector2.from_angle(end_angle) * radius, GIZMO_COLOR, GIZMO_WIDTH)

	var rest_color: Color = Color(GIZMO_COLOR, GIZMO_COLOR.a * 0.5)
	draw_line(Vector2.ZERO, Vector2.from_angle(deg_to_rad(get_rest_degrees())) * radius, rest_color, GIZMO_WIDTH)


func get_sweep_degrees() -> float:
	var sweep: float = fposmod(arc_end_degrees - arc_start_degrees, FULL_CIRCLE_DEGREES)
	if is_zero_approx(sweep):
		return FULL_CIRCLE_DEGREES
	return sweep


func get_rest_degrees() -> float:
	if rest_direction == RestDirection.RIGHT:
		return clamp_to_arc(REST_RIGHT_DEGREES)
	return clamp_to_arc(REST_LEFT_DEGREES)


func get_arc_offset(angle_degrees: float) -> float:
	return fposmod(angle_degrees - arc_start_degrees, FULL_CIRCLE_DEGREES)


func is_in_arc(angle_degrees: float) -> bool:
	var sweep: float = get_sweep_degrees()
	if sweep >= FULL_CIRCLE_DEGREES:
		return true
	return get_arc_offset(angle_degrees) <= sweep


func clamp_to_arc(angle_degrees: float) -> float:
	if is_in_arc(angle_degrees):
		return angle_degrees

	var sweep: float = get_sweep_degrees()
	var offset: float = get_arc_offset(angle_degrees)
	if offset - sweep < FULL_CIRCLE_DEGREES - offset:
		return arc_start_degrees + sweep
	return arc_start_degrees


func get_target() -> Node2D:
	if is_instance_valid(target):
		return target
	return get_tree().get_first_node_in_group(TARGET_GROUP) as Node2D


func is_in_range(target_node: Node2D) -> bool:
	if detection_radius <= 0.0:
		return true
	return global_position.distance_to(target_node.global_position) <= detection_radius


func get_target_degrees(target_node: Node2D) -> float:
	return rad_to_deg(to_local(target_node.global_position).angle())


func aim(desired_degrees: float, delta: float) -> void:
	var max_step: float = turn_speed_degrees * delta

	if get_sweep_degrees() >= FULL_CIRCLE_DEGREES:
		var remaining: float = rad_to_deg(angle_difference(pivot.rotation, deg_to_rad(desired_degrees)))
		pivot.rotation += deg_to_rad(clampf(remaining, -max_step, max_step))
	else:
		var current_offset: float = get_arc_offset(clamp_to_arc(rad_to_deg(pivot.rotation)))
		var new_offset: float = move_toward(current_offset, get_arc_offset(desired_degrees), max_step)
		pivot.rotation = deg_to_rad(arc_start_degrees + new_offset)

	update_flip()


func update_flip() -> void:
	if flip_when_aiming_left and cos(pivot.rotation) < 0.0:
		pivot.scale.y = SCALE_FLIPPED
	else:
		pivot.scale.y = SCALE_NORMAL


func is_aimed_at(target_degrees: float) -> bool:
	var error: float = absf(angle_difference(pivot.rotation, deg_to_rad(target_degrees)))
	return error <= deg_to_rad(aim_tolerance_degrees)


func can_fire(target_degrees: float) -> bool:
	return bullet_scene != null and has_valid_pattern() and is_aimed_at(target_degrees)


func start_burst() -> void:
	current_pattern = next_pattern()
	if current_pattern == null:
		cooldown = fire_cooldown
		return

	volleys_left = current_pattern.volleys
	volley_timer = NO_TIME
	is_firing = true


func update_burst(delta: float) -> void:
	volley_timer -= delta
	if volley_timer > NO_TIME:
		return

	fire_volley()
	volleys_left -= 1
	volley_timer = current_pattern.volley_interval

	if volleys_left <= 0:
		is_firing = false
		cooldown = fire_cooldown


func next_pattern() -> BulletPattern:
	for _attempt: int in range(patterns.size()):
		var pattern: BulletPattern = patterns[pattern_index]
		pattern_index = (pattern_index + 1) % patterns.size()
		if pattern != null:
			return pattern
	return null


func has_valid_pattern() -> bool:
	for pattern: BulletPattern in patterns:
		if pattern != null:
			return true
	return false


func fire_volley() -> void:
	var volley_index: int = current_pattern.volleys - volleys_left
	var angles: Array[float] = current_pattern.get_angles(pivot.global_rotation, volley_index)
	for angle: float in angles:
		fire_bullet(angle, current_pattern.bullet_speed)

	play_animation(FIRE_ANIMATION)
	queue_animation(IDLE_ANIMATION)


func fire_bullet(angle: float, speed: float) -> void:
	var bullet: EnemyBullet = bullet_scene.instantiate() as EnemyBullet
	if bullet == null:
		push_error("%s: bullet_scene root must use the EnemyBullet script" % name)
		return

	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.launch(angle, speed)


func play_animation(animation_name: StringName) -> void:
	if animation_player != null and animation_player.has_animation(animation_name):
		animation_player.stop()
		animation_player.play(animation_name)


func queue_animation(animation_name: StringName) -> void:
	if animation_player != null and animation_player.has_animation(animation_name):
		animation_player.queue(animation_name)
