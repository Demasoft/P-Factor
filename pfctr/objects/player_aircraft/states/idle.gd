class_name AircraftStateIdle extends AircraftState

func init() -> void:
	pass

func enter() -> void:
	player.animation_player.play("idle")

func exit() -> void:
	pass

func handle_input(event: InputEvent) -> AircraftState:
	if event.is_action_pressed("jump"):
		if player.use_overboost():
			return overboost

	return self

func process(_delta: float) -> AircraftState:
	if player.direction != Vector2.ZERO:
		return move

	return self

func physics_process(_delta: float) -> AircraftState:
	player.velocity = Vector2.ZERO
	return self
