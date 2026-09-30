class_name AircraftStateOverboost extends AircraftState

@export var duration: float = 5.0
@export var boost_speed: float = 360.0

var time_left: float = 0.0


func init() -> void:
	pass


func enter() -> void:
	time_left = duration
	player.animation_player.play("move")


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> AircraftState:
	return self


func process(delta: float) -> AircraftState:
	time_left -= delta

	if time_left <= 0.0:
		if player.direction == Vector2.ZERO:
			return idle
		else:
			return move

	return self


func physics_process(_delta: float) -> AircraftState:
	player.velocity = player.direction * boost_speed
	return self
