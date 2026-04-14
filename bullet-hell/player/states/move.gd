class_name PlayerStateMove extends PlayerState

func init() -> void:
	pass

func enter() -> void:
	player.animation_player.play( "move" )
	pass

func exit() -> void:
	pass

func handle_input( _event: InputEvent ) -> PlayerState:
	#if _event.is_action_pressed( "overboost" ):
		#return overboost
	#elif _event.is_action_pressed( "shoot" ):
		#return shoot
	return next_state


func process( _delta: float) -> PlayerState:
	if player.direction.length() < 0.1:
		return idle
	return next_state

func physics_process( _delta: float) -> PlayerState:
	player.velocity.x = player.direction.x * player.move_speed
	player.velocity.y = player.direction.y * player.move_speed
	return next_state
