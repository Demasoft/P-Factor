class_name EnemyStateIdle extends EnemyState

const MAX_PICK_ATTEMPTS: int = 8

# Roam area as a fraction of the viewport: x, y, width, height.
# Default = right half of the screen with a small margin.
@export var roam_area_ratio: Rect2 = Rect2(0.5, 0.1, 0.45, 0.8)
@export var min_travel_distance: float = 120.0
@export var arrive_radius: float = 8.0
@export var max_speed: float = 140.0
@export var acceleration: float = 400.0
@export var arrival_gain: float = 3.0       # higher = brakes later
@export var hold_duration: float = 0.8      # pause at the target before attacking
@export var bob_amplitude: float = 6.0      # pixels
@export var bob_frequency: float = 3.0      # radians per second

var target_position: Vector2 = Vector2.ZERO
var has_arrived: bool = false
var hold_elapsed: float = 0.0
var bob_time: float = 0.0


func enter() -> void:
	has_arrived = false
	hold_elapsed = 0.0
	pick_target()


func process(delta: float) -> EnemyState:
	if not has_arrived:
		var distance: float = enemy.global_position.distance_to(target_position)
		has_arrived = distance <= arrive_radius
		return self

	hold_elapsed += delta
	if hold_elapsed >= hold_duration:
		return enemy.state_attack
	return self


func physics_process(delta: float) -> EnemyState:
	bob_time += delta

	var desired_velocity: Vector2 = Vector2.ZERO
	if not has_arrived:
		var to_target: Vector2 = target_position - enemy.global_position
		var desired_speed: float = minf(max_speed, to_target.length() * arrival_gain)
		desired_velocity = to_target.normalized() * desired_speed

	desired_velocity.y += cos(bob_time * bob_frequency) * bob_amplitude * bob_frequency
	enemy.velocity = enemy.velocity.move_toward(desired_velocity, acceleration * delta)
	return self


func pick_target() -> void:
	var viewport_size: Vector2 = enemy.get_viewport_rect().size
	var area_position: Vector2 = viewport_size * roam_area_ratio.position
	var area_size: Vector2 = viewport_size * roam_area_ratio.size

	for _attempt: int in range(MAX_PICK_ATTEMPTS):
		target_position = Vector2(
			randf_range(area_position.x, area_position.x + area_size.x),
			randf_range(area_position.y, area_position.y + area_size.y)
		)
		var travel: float = enemy.global_position.distance_to(target_position)
		if travel >= min_travel_distance:
			return
