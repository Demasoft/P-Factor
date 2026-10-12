
@tool
class_name TurretGun extends Node2D

signal fire_frame_reached

const TARGET_GROUP: StringName = &"PlayerAircraft"
const FULL_CIRCLE_DEGREES: float = 360.0
const HALF: float = 0.5
const ARC_POINTS: int = 32
const GIZMO_COLOR: Color = Color(1.0, 0.3, 0.2, 0.8)
const GIZMO_WIDTH: float = 2.0

@export_group("Firing Range")
@export_range(-360.0, 360.0, 1.0) var arc_start_degrees: float = 135.0:
	set(value):
		arc_start_degrees = value
		queue_redraw()

@export_range(-360.0, 360.0, 1.0) var arc_end_degrees: float = 225.0:
	set(value):
		arc_end_degrees = value
		queue_redraw()

@export var gizmo_radius: float = 120.0:
	set(value):
		gizmo_radius = value
		queue_redraw()

@export var show_arc_in_game: bool = false

@export_group("Aiming")
@export var turn_speed_degrees: float = 120.0
@export var aim_tolerance_degrees: float = 4.0
@export var target: Node2D = null

@export_group("Shooting")
@export var enabled: bool = true
@export var bullet_scene: PackedScene
@export var patterns: Array[BulletPattern] = []
@export var fire_cooldown: float = 1.5

@onready var pivot: Node2D = $Pivot
@onready var muzzle: Marker2D = $Pivot/Muzzle

var pattern_index: int = 0
var current_pattern: BulletPattern = null
var volleys_fired: int = 0
var is_firing: bool = false
var cooldown: float = 0.0


func _ready() -> void:
	queue_redraw()

	if Engine.is_editor_hint():
		return

	pivot.rotation = deg_to_rad(get_rest_degrees())


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not enabled:
		return

	cooldown = maxf(cooldown - delta, 0.0)

	if is_firing:
		return

	aim(delta)

	if cooldown <= 0.0 and can_fire_at_target():
		start_attack()


func _draw() -> void:
	if not Engine.is_editor_hint() and not show_arc_in_game:
		return

	var sweep: float = get_sweep_degrees()
	var start_angle: float = deg_to_rad(arc_start_degrees)
	var end_angle: float = start_angle + deg_to_rad(sweep)

	if sweep >= FULL_CIRCLE_DEGREES:
		draw_arc(Vector2.ZERO, gizmo_radius, 0.0, TAU,
			ARC_POINTS, GIZMO_COLOR, GIZMO_WIDTH)
		return

	draw_arc(Vector2.ZERO, gizmo_radius, start_angle, end_angle,
		ARC_POINTS, GIZMO_COLOR, GIZMO_WIDTH)
	draw_line(Vector2.ZERO, Vector2.from_angle(start_angle) * gizmo_radius,
		GIZMO_COLOR, GIZMO_WIDTH)
	draw_line(Vector2.ZERO, Vector2.from_angle(end_angle) * gizmo_radius,
		GIZMO_COLOR, GIZMO_WIDTH)


# ---------- firing range ----------

func get_sweep_degrees() -> float:
	var sweep: float = fposmod(
		arc_end_degrees - arc_start_degrees,
		FULL_CIRCLE_DEGREES
	)

	if is_zero_approx(sweep):
		return FULL_CIRCLE_DEGREES

	return sweep


func get_rest_degrees() -> float:
	var sweep: float = get_sweep_degrees()

	if sweep >= FULL_CIRCLE_DEGREES:
		return arc_start_degrees

	return arc_start_degrees + sweep * HALF


func get_arc_offset(angle_degrees: float) -> float:
	return fposmod(
		angle_degrees - arc_start_degrees,
		FULL_CIRCLE_DEGREES
	)


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
	var past_end: float = offset - sweep
	var before_start: float = FULL_CIRCLE_DEGREES - offset

	if past_end < before_start:
		return arc_start_degrees + sweep

	return arc_start_degrees


# ---------- aiming ----------

func get_target() -> Node2D:
	if is_instance_valid(target):
		return target

	return get_tree().get_first_node_in_group(TARGET_GROUP) as Node2D


func get_target_degrees(target_node: Node2D) -> float:
	return rad_to_deg(
		to_local(target_node.global_position).angle()
	)


func aim(delta: float) -> void:
	var target_node: Node2D = get_target()

	if target_node == null:
		return

	var desired_degrees: float = clamp_to_arc(
		get_target_degrees(target_node)
	)
	var max_step: float = turn_speed_degrees * delta

	if get_sweep_degrees() >= FULL_CIRCLE_DEGREES:
		var desired_angle: float = deg_to_rad(desired_degrees)
		var remaining: float = angle_difference(
			pivot.rotation,
			desired_angle
		)

		pivot.rotation += deg_to_rad(
			clampf(rad_to_deg(remaining), -max_step, max_step)
		)
		return

	# Follow the arc without crossing the restricted region.
	var current_degrees: float = rad_to_deg(pivot.rotation)
	var current_offset: float = get_arc_offset(
		clamp_to_arc(current_degrees)
	)
	var desired_offset: float = get_arc_offset(desired_degrees)
	var new_offset: float = move_toward(
		current_offset,
		desired_offset,
		max_step
	)

	pivot.rotation = deg_to_rad(arc_start_degrees + new_offset)


func can_fire_at_target() -> bool:
	var target_node: Node2D = get_target()

	if target_node == null:
		return false

	var target_degrees: float = get_target_degrees(target_node)

	if not is_in_arc(target_degrees):
		return false

	var error: float = absf(
		angle_difference(
			pivot.rotation,
			deg_to_rad(target_degrees)
		)
	)

	return error <= deg_to_rad(aim_tolerance_degrees)


# ---------- shooting ----------

func start_attack() -> void:
	current_pattern = next_pattern()

	if current_pattern == null or bullet_scene == null:
		cooldown = fire_cooldown
		return

	volleys_fired = 0
	is_firing = true

	# Fire all volleys immediately, respecting the pattern's volley count.
	while volleys_fired < current_pattern.volleys:
		fire_volley()
	
	is_firing = false
	cooldown = fire_cooldown


func next_pattern() -> BulletPattern:
	if patterns.is_empty():
		return null

	var pattern: BulletPattern = patterns[pattern_index]
	pattern_index = (pattern_index + 1) % patterns.size()

	return pattern


func fire_volley() -> void:
	fire_frame_reached.emit()

	var aim_angle: float = pivot.global_rotation
	var angles: Array[float] = current_pattern.get_angles(
		aim_angle,
		volleys_fired
	)

	for angle: float in angles:
		fire_bullet(angle, current_pattern.bullet_speed)

	volleys_fired += 1


func fire_bullet(angle: float, speed: float) -> void:
	var bullet: EnemyBullet = bullet_scene.instantiate() as EnemyBullet

	if bullet == null:
		return

	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.launch(angle, speed)
