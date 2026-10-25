extends Node2D

@export var player: PlayerAircraft

func _process(delta: float) -> void:
	if player == null:
		return

	for child in get_children():
		if child is Parallax2D:
			child.scroll_offset -= (
				player.velocity
				* child.movement_multiplier
				* delta
			)
