extends Node2D


func play() -> void:
	for child in get_children():
		if child is GPUParticles2D:
			child.restart()
