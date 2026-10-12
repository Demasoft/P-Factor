class_name RadialPattern extends BulletPattern

const MIN_ARMS: int = 1

@export var arms: int = 12
@export var spin_degrees_per_volley: float = 0.0
@export var start_aimed_at_player: bool = false
@export var fixed_start_degrees: float = 0.0


func get_angles(aim_angle: float, volley_index: int) -> Array[float]:
	var angles: Array[float] = []
	var arm_count: int = maxi(arms, MIN_ARMS)

	var base_angle: float = deg_to_rad(fixed_start_degrees)
	if start_aimed_at_player:
		base_angle = aim_angle

	var spin: float = deg_to_rad(spin_degrees_per_volley) * float(volley_index)
	var arm_step: float = TAU / float(arm_count)

	for index: int in range(arm_count):
		angles.append(base_angle + spin + arm_step * float(index))

	return angles
