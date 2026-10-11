class_name EnemyStateIdle extends EnemyState

@export var rest_duration: float = 1.5
@export var sway_amplitude: float = 30.0   # pixels
@export var sway_frequency: float = 2.0    # radians per second
@export var follow_gain: float = 8.0       # higher = tighter follow

var elapsed: float = 0.0
var sway_time: float = 0.0


func enter() -> void:
	elapsed = 0.0


func process(delta: float) -> EnemyState:
	elapsed += delta
	if elapsed >= rest_duration:
		return enemy.state_attack
	return self


func physics_process(delta: float) -> EnemyState:
	sway_time += delta
	var target_y: float = enemy.anchor_y + sin(sway_time * sway_frequency) * sway_amplitude
	var gap: float = target_y - enemy.global_position.y
	enemy.velocity = Vector2(0.0, gap * follow_gain)
	return self
