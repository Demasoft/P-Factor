#class_name AircraftStateOverboost extends AircraftState
#
#@export var duration: float = 7.0
#
#var time_left: float = 0.0
#
#func init() -> void:
	#pass
#
#
#func enter() -> void:
	#time_left = duration
	#player.bank_enabled = false
	#player.bank_value = 0.0
#
	#var ap: AnimationPlayer = player.animation_player
	#if not ap.animation_finished.is_connected(_on_anim_finished):
		#ap.animation_finished.connect(_on_anim_finished)
	#ap.play("overboost")
#
#
#func _on_anim_finished(anim_name: StringName) -> void:
	#if anim_name == &"overboost":
		#player.bank_value = 0.0
		#player.bank_enabled = true
#
#
#func exit() -> void:
	#var ap := player.animation_player
	#if ap.animation_finished.is_connected(_on_anim_finished):
		#ap.animation_finished.disconnect(_on_anim_finished)
	#if ap.current_animation == "overboost":
		#ap.stop()
	#player.bank_value = 0.0
	#player.bank_enabled = true
#
#func handle_input(_event: InputEvent) -> AircraftState:
	#return self
#
#
#func process(delta: float) -> AircraftState:
	#time_left -= delta
#
	#if time_left <= 0.0:
		#if player.direction == Vector2.ZERO:
			#return idle
		#else:
			#return move
#
	#player.sprite_2d.trail()
	#
	#return self
#
#
#func physics_process(_delta: float) -> AircraftState:
	#player.velocity = player.direction * player.move_speed
	#return self
	
	
class_name AircraftStateOverboost extends AircraftState

@export var duration: float = 3.0
@export var slow_scale: float = 0.3

var time_left: float = 0.0


func init() -> void:
	pass


func enter() -> void:
	time_left = duration
	PlayerHudGround.start_timer(duration)
	player.bank_enabled = false
	player.bank_value = 0.0

	var ap: AnimationPlayer = player.animation_player
	if not ap.animation_finished.is_connected( _on_anim_finished ):
		ap.animation_finished.connect( _on_anim_finished )
	ap.play( "overboost" )

	TimeSlow.slow( slow_scale )


func _on_anim_finished( anim_name: StringName ) -> void:
	if anim_name == &"overboost":
		player.bank_value = 0.0
		player.bank_enabled = true


func exit() -> void:
	TimeSlow.restore()

	var ap := player.animation_player
	ap.speed_scale = 1.0
	if ap.animation_finished.is_connected( _on_anim_finished ):
		ap.animation_finished.disconnect( _on_anim_finished )
	if ap.current_animation == "overboost":
		ap.stop()
	player.bank_value = 0.0
	player.bank_enabled = true


func handle_input( _event: InputEvent ) -> AircraftState:
	return self


func process(delta: float) -> AircraftState:
	var compensation: float = 1.0 / maxf(Engine.time_scale, 0.01)

	# Countdown uses real-world seconds.
	time_left = maxf(time_left - delta * compensation, 0.0)

	player.animation_player.speed_scale = compensation
	PlayerHudGround.update_timer(time_left)

	if time_left <= 0.0:
		return idle if player.direction == Vector2.ZERO else move

	player.sprite_2d.trail()
	return self


func physics_process( _delta: float ) -> AircraftState:
	# move_and_slide() uses the slowed delta, so scale the velocity back up
	var compensation: float = 1.0 / maxf( Engine.time_scale, 0.01 )
	player.velocity = player.direction * player.move_speed * compensation
	return self
