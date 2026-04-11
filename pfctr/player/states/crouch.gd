class_name PlayerStateCrouch extends PlayerState

@export var deceleration_rate : float = 8

func init() -> void:
	pass

func enter() -> void:
	player.animation_player.play( "crouch" )
	player.collision_stand.disabled = true
	player.collision_crouch.disabled = false
	pass

func exit() -> void:
	player.collision_stand.disabled = false
	player.collision_crouch.disabled = true
	pass

func handle_input( _event: InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "jump" ):
		player.shape_cast_2d.force_shapecast_update()
		if player.shape_cast_2d.is_colliding():
			player.position.y += 4
			return fall
		return jump
	return next_state


func process( _delta: float) -> PlayerState:
	if player.direction.y <= 0.5:
		return idle
	return next_state

func physics_process( _delta: float) -> PlayerState:
	player.velocity.x -= player.velocity.x *deceleration_rate * _delta
	if player.is_on_floor() == false:
		return fall
	return next_state
