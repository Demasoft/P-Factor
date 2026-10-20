extends CanvasLayer

@onready var hp_label: Label = %HPLabel
@onready var timer_label: Label = %TimerLabel
@onready var game_over: Control = %GameOver
@onready var retry: Button = %Retry
@onready var load_last_save: Button = %LoadLastSave
@onready var quit_to_title: Button = %QuitToTitle



func _ready() -> void:
	Messages.player_health_changed.connect(_on_health_changed)
	timer_label.hide()
	game_over.hide()
	retry.pressed.connect( _on_retry_pressed )
	load_last_save.pressed.connect( _on_load_last_pressed )
	quit_to_title.pressed.connect( _on_quit_pressed )


func _on_health_changed(hp: float, _max_hp: float) -> void:
	hp_label.text = "x%d" % ceili(hp)

func show_game_over() -> void:
	retry.hide()
	load_last_save.hide()
	quit_to_title.hide()
	
	game_over.modulate.a = 0
	game_over.show()
	
	var tween: Tween = create_tween()
	tween.tween_property( game_over, "modulate", Color.WHITE, 4.0 )
	await tween.finished
	
	retry.show()
	load_last_save.show()
	quit_to_title.show()
	
	retry.grab_focus()
	
func clear_game_over() -> void:
	retry.hide()
	load_last_save.hide()
	quit_to_title.hide()
	await SceneManager.scene_entered
	game_over.hide()
	#var player: PlayerAircraft = get_tree().get_first_node_in_group( "PlayerAircraft" )
	#player.queue_free()


func start_timer(duration: float) -> void:
	update_timer(duration)


func update_timer(value: float) -> void:
	if not is_instance_valid(timer_label):
		return

	timer_label.visible = value > 0.0

	if value > 0.0:
		var minutes := int(value / 60.0)
		var seconds := int(value) % 60
		var milliseconds := int((value - floorf(value)) * 1000.0)

		timer_label.text = "%02d'%02d'%03d" % [
			minutes, seconds, milliseconds
		]

func _on_retry_pressed() -> void:
	SceneManager.transition_scene( SceneManager.current_scene_uid, "", Vector2.ZERO, "down" )
	clear_game_over()

func _on_load_last_pressed() -> void:
	SaveManager.load_game( SaveManager.current_slot )
	clear_game_over()
	
func _on_quit_pressed() -> void:
	SceneManager.transition_scene( "uid://cv8mro2sepasu", "", Vector2.ZERO, "down" )
	clear_game_over()
	
