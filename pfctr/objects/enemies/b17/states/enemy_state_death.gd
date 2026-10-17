class_name EnemyStateDeath extends EnemyState

const DEATH_ANIMATION: StringName = &"death"


func enter() -> void:
	enemy.velocity = Vector2.ZERO
	enemy.collision_polygon_2d.set_deferred("disabled", true)
	enemy.death.emit(enemy)

	if enemy.animation_player.has_animation(DEATH_ANIMATION):
		enemy.animation_player.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)
		enemy.animation_player.play(DEATH_ANIMATION)
	else:
		enemy.queue_free()


func _on_animation_finished(_animation_name: StringName) -> void:
	ExplosionGreat.explode(self.global_position)
	enemy.queue_free()
