class_name AircraftStateMove extends AircraftState

func init() -> void:
	pass

func enter() -> void:
	player.animation_player.play("move")

func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> AircraftState:
	if _event.is_action_pressed("jump"):
		return overboost

	return self

func process(_delta: float) -> AircraftState:
	if player.direction == Vector2.ZERO:
		return idle

	return self

func physics_process(_delta: float) -> AircraftState:
	player.velocity = player.direction * player.move_speed
	return self
