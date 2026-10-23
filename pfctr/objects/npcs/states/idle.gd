class_name NPCStateIdle extends NPCState

func init() -> void:
	pass

func enter() -> void:
	npc.animation_player.play( "idle" )
	

func exit() -> void:
	pass

func handle_input( _event: InputEvent ) -> NPCState:
	return next_state

func process( _delta: float) -> NPCState:
	return next_state

func physics_process( _delta: float) -> NPCState:
	npc.velocity.x = 0
	return next_state
