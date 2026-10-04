class_name PlayerStateShoot extends PlayerState

@export var deceleration_rate : float = 8

func init() -> void:
	pass

func enter() -> void:
	player.animation_player.play("shoot")
	pass

func exit() -> void:
	pass

func handle_input( _event: InputEvent ) -> PlayerState:
	if _event.is_action_released("shoot"):
		return idle
	return next_state


func process( _delta: float) -> PlayerState:
	
	return next_state

func physics_process( _delta: float) -> PlayerState:
	return next_state
