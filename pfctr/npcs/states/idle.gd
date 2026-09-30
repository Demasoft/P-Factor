class_name NPCStateIdle extends NPCState

func init() -> void:
	pass

func enter() -> void:
	npc.animation_player.play( "idle" )
	

func exit() -> void:
	pass

func handle_input( _event: InputEvent ) -> NPCState:
	#if _event.is_action_pressed( "jump" ):
		#return jump
	#elif _event.is_action_pressed( "shoot" ):
		#return shoot
	return next_state

func process( _delta: float) -> NPCState:
	#if player.direction.x != 0:
		#return run
	#elif player.direction.y > 0.5:
		#return crouch
	return next_state

func physics_process( _delta: float) -> NPCState:
	npc.velocity.x = 0
	#if npc.is_on_floor() == false:
		#return fall
	return next_state
