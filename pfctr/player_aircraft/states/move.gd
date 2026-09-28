class_name AircraftStateMove extends AircraftState

func init() -> void:
	pass

func enter() -> void:
	player.animation_player.play( "move" )
	pass

func exit() -> void:
	pass

func handle_input( _event: InputEvent ) -> AircraftState:
	if _event.is_action_pressed( "overboost" ):
		return overboost
	return next_state


func process( _delta: float) -> AircraftState:
	if player.direction.x == 0:
		return idle
	#elif player.direction.y > 0.5:
		#return crouch
	return next_state

func physics_process( _delta: float) -> AircraftState:
	player.velocity.x = player.direction.x * player.move_speed
	#if player.is_on_floor() == false:
		#return fall
	return next_state	
