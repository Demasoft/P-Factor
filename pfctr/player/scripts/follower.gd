extends CharacterBody2D

@export var follow_distance := 10.0

@onready var player = get_tree().get_first_node_in_group("Player")


func _process(_delta: float) -> void:
	if player == null:
		return

	global_position = player.global_position - player.velocity.normalized() * follow_distance
	
