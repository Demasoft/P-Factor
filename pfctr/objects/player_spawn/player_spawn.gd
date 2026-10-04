#class_name PlayerSpawn extends Node2D
#
#const PLAYER = preload("uid://be2p5bjigf8yd")
#
#func _ready() -> void:
	#visible = false
	#await get_tree().process_frame
	#
	#if get_tree().get_first_node_in_group("Player"):
		#print("there is player")
		#return
	#print("No player")
#
	#var player: Player = PLAYER.instantiate()
	#get_tree().root.add_child( player )
#
	#player.global_position = self.global_position
	#pass 
	
class_name PlayerSpawn
extends Node2D

const PLAYER = preload("uid://be2p5bjigf8yd")


func _ready() -> void:
	visible = false

	var existing_player := get_tree().get_first_node_in_group("Player")

	if existing_player:
		print("Player already exists: ", existing_player)
		return

	print("Creating Player")

	var player: Player = PLAYER.instantiate()

	# Add the player to the root so it persists between scenes.
	get_tree().root.call_deferred("add_child", player)

	# Wait until the player is actually inside the tree.
	await player.tree_entered

	print("Player added to tree")

	player.global_position = global_position

	print("Player spawned at: ", player.global_position)
