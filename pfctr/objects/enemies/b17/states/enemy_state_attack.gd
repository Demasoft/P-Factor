class_name EnemyStateAttack extends EnemyState

var current_pattern: BulletPattern = null
var volleys_fired: int = 0
var volley_timer: float = 0.0


func enter() -> void:
	current_pattern = enemy.next_pattern()
	volleys_fired = 0
	volley_timer = 0.0   


func process(delta: float) -> EnemyState:
	if current_pattern == null:
		return enemy.state_idle

	volley_timer -= delta
	if volley_timer > 0.0:
		return self

	fire_volley()
	volleys_fired += 1
	volley_timer = current_pattern.volley_interval

	if volleys_fired >= current_pattern.volleys:
		return enemy.state_idle
	return self


func physics_process(_delta: float) -> EnemyState:
	enemy.velocity = Vector2.ZERO
	return self


func fire_volley() -> void:
	#var aim_angle: float = enemy.get_aim_angle()
	#var angles: Array[float] = current_pattern.get_angles(aim_angle, volleys_fired)
#
	#for angle: float in angles:
		#enemy.fire_bullet(angle, current_pattern.bullet_speed)

# Will now fire from turrets, yet to adjust
	pass
