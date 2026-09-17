extends CharacterBody2D

@export var follow_distance: float = 20.0
@export var follow_speed: float = 3.5

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("Player")


func _physics_process(delta: float) -> void:
	if player == null:
		return

	var direction: Vector2 = player.velocity.normalized()

	if direction == Vector2.ZERO:
		return

	var target_position: Vector2 = (
		player.global_position - direction * follow_distance
	)

	var weight: float = 1.0 - exp(-follow_speed * delta)

	global_position = global_position.lerp(
		target_position,
		weight
	)
