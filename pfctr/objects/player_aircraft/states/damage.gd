class_name PlayerStateDamage extends AircraftState

@export var hit_color: Color = Color(1.0, 1.0, 1.0, 0.0)
@export var blink_time: float = 0.01
@export var invincibility_time: float = 3.0

var pending_damage: float = 0.0
var invincible: bool = false
var blink_tween: Tween

func init() -> void:
	Messages.player_hit.connect( _on_player_hit )

func _on_player_hit( amount: float ) -> void:
	if invincible or player.current_state == death:
		return
	pending_damage = amount
	player.change_state( self )

func enter() -> void:
	player.hp -= pending_damage
	pending_damage = 0.0
	player.damage_taken.emit()
	if player.hp > 0.0:
		start_invincibility()

func process( _delta: float ) -> AircraftState:
	if player.hp <= 0.0:
		return death
	return idle

func start_invincibility() -> void:
	invincible = true

	if blink_tween:
		blink_tween.kill()
	blink_tween = create_tween().set_loops()  # loops until killed
	blink_tween.tween_property( player.sprite_2d, "modulate", hit_color, blink_time )
	blink_tween.tween_property( player.sprite_2d, "modulate", Color.WHITE, blink_time )

	await get_tree().create_timer( invincibility_time ).timeout
	end_invincibility()

func end_invincibility() -> void:
	invincible = false
	if blink_tween:
		blink_tween.kill()
	player.sprite_2d.modulate = Color.WHITE
