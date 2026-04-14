class_name PlayerStateShoot extends PlayerState

func init() -> void:
	pass

func enter() -> void:
	player.animation_player.play("shoot")
	pass

func exit() -> void:
	pass

func handle_input( _event: InputEvent ) -> PlayerState:
	if _event.is_action_pressed("shoot"):
		return shoot
	return next_state


func process( _delta: float) -> PlayerState:
	
	return next_state

func physics_process( _delta: float) -> PlayerState:
	return next_state
