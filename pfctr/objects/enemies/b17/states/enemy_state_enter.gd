class_name EnemyStateEnter extends EnemyState

const HALF: float = 0.5

@export var entry_distance: float = 300.0 

var entry_direction: Vector2 = Vector2.LEFT
var distance_travelled: float = 0.0


func enter() -> void:
	distance_travelled = 0.0

	var screen_center_x: float = enemy.get_viewport_rect().size.x * HALF
	if enemy.global_position.x < screen_center_x:
		entry_direction = Vector2.RIGHT
	else:
		entry_direction = Vector2.LEFT


func exit() -> void:
	enemy.anchor_y = enemy.global_position.y


func process(_delta: float) -> EnemyState:
	if distance_travelled >= entry_distance:
		return enemy.state_idle
	return self


func physics_process(delta: float) -> EnemyState:
	enemy.velocity = entry_direction * enemy.move_speed
	distance_travelled += enemy.move_speed * delta
	return self
