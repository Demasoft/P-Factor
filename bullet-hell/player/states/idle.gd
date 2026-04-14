class_name PlayerStateIdle extends PlayerState

func init() -> void:
	pass

func enter() -> void:
	player.animation_player.play( "idle" )
	pass

func exit() -> void:
	pass

func handle_input( _event: InputEvent ) -> PlayerState:
	#if _event.is_action_pressed( "jump" ):
		#return jump
	if _event.is_action_pressed( "shoot" ):
		return shoot
	return next_state


func process( _delta: float) -> PlayerState:
	if player.direction.length() >= 0.1:
		return move
	return next_state

func physics_process( _delta: float) -> PlayerState:
	player.velocity.x = 0
	player.velocity.y = 0
	#if player.is_on_floor() == false:
		#return fall
	return next_state
