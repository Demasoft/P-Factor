class_name SavePoint extends Node2D

@export var owner_node: Node
@onready var area_2d: Area2D = $Area2D
@onready var animation_player: AnimationPlayer = $Node2D/AnimationPlayer


func _ready() -> void:
	area_2d.body_entered.connect( _on_player_entered )
	area_2d.body_exited.connect( _on_player_exited )

func _on_player_entered(_n: Node2D) -> void:
	Messages.player_interacted.connect(_on_player_interacted)
	Messages.input_hint_changed.emit(self, "Interact")


func _on_player_exited(_n: Node2D) -> void:
	Messages.player_interacted.disconnect(_on_player_interacted)
	Messages.input_hint_changed.emit(self, "")

func _on_player_interacted( player : Player ) -> void:
	Messages.player_healed.emit( player.max_hp )
	SaveManager.save_game()
	print("saved")
	animation_player.play( "game_saved" )
	
