class_name AircraftStateMove extends AircraftState

var current_direction_animation: String = ""


func init() -> void:
	pass


func enter() -> void:
	current_direction_animation = ""


func exit() -> void:
	pass


func handle_input(event: InputEvent) -> AircraftState:
	if event.is_action_pressed("jump"):
		
		return overboost

	return self


func process(_delta: float) -> AircraftState:

	if player.direction == Vector2.ZERO:
		return idle


	# UP
	if player.direction.y < 0.0:

		if current_direction_animation != "move_up":
			player.animation_player.play("move_up")
			current_direction_animation = "move_up"


	# DOWN
	elif player.direction.y > 0.0:

		if current_direction_animation != "move_down":
			player.animation_player.play("move_down")
			current_direction_animation = "move_down"


	# LEFT / RIGHT
	else:

		if current_direction_animation != "idle":
			player.animation_player.play("idle")
			current_direction_animation = "idle"


	return self


func physics_process(_delta: float) -> AircraftState:
	player.velocity = player.direction * player.move_speed
	return self
