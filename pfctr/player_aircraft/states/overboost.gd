class_name AircraftStateOverboost extends AircraftState

@export var jump_velocity : float = 450

func init() -> void:
	pass

func enter() -> void:
	player.animation_player.play( "overboost" )
	player.animation_player.pause()
	#player.velocity.y =- jump_velocity
	
	#if player.previous_state == fall and not Input.is_action_pressed( "jump" ):
		#await get_tree().physics_frame
		#player.velocity.y *= 0.5
		#player.change_state( fall )

func exit() -> void:
	pass

func handle_input( event: InputEvent ) -> AircraftState:
	if event.is_action_released( "overboost" ) :
		player.velocity.x *= 0.5
		#return fall
	return next_state

func process( _delta: float) -> AircraftState:
	set_boost_frame()
	return next_state

func physics_process( _delta: float) -> AircraftState:
	#if player.is_on_floor():
		#return idle
	#elif player.velocity.y >= 0 :
		#return fall
	#player.velocity.x = player.direction.x * player.move_speed
	return next_state	

func set_boost_frame() -> void:
	var frame : float = remap( player.velocity.y, -jump_velocity, 0.0, 0.0, 0.5)
	player.animation_player.seek( frame, true )
	pass
