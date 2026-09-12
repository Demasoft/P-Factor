class_name PlayerSpawn extends Node2D

const PLAYER = preload("uid://be2p5bjigf8yd")

func _ready() -> void:
	visible = false
	await get_tree().process_frame
	
	if get_tree().get_first_node_in_group("Player"):
		print("there is player")
		return
	print("No player")

	var player: Player = PLAYER.instantiate()
	get_tree().root.add_child( player )

	player.global_position = self.global_position
	pass 
