class_name AimedFanPattern extends BulletPattern

const MIN_BULLETS_FOR_SPREAD: int = 2
const HALF: float = 0.5

@export var bullets_per_volley: int = 5
@export var spread_degrees: float = 40.0


func get_angles(aim_angle: float, _volley_index: int) -> Array[float]:
	var angles: Array[float] = []

	if bullets_per_volley < MIN_BULLETS_FOR_SPREAD:
		angles.append(aim_angle)
		return angles

	var spread_radians: float = deg_to_rad(spread_degrees)
	var start_angle: float = aim_angle - spread_radians * HALF
	var step: float = spread_radians / float(bullets_per_volley - 1)

	for index: int in range(bullets_per_volley):
		angles.append(start_angle + step * float(index))

	return angles
