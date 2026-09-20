class_name DialogueTrigger extends Node2D

@onready var area_2d: Area2D = %Area2D

func _ready() -> void:
	area_2d.body_entered.connect( _on_player_entered )
	#area_2d.body_exited.connect( _on_player_exited )

func _on_player_entered( _n : Node2D ) -> void:
	if Dialogic.current_timeline != null:
		return
	Dialogic.start('timeline_test')
	get_viewport().set_input_as_handled()
	

#func _on_player_exited( _n : Node2D ) -> void:
	#Messages.player_interacted.disconnect( _on_player_interacted )
	#Messages.input_hint_changed.emit( "" )
