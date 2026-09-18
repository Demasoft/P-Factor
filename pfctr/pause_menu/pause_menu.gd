class_name PauseMenu extends CanvasLayer

@onready var pause: Control = %Pause
@onready var system: Control = %System

@onready var system_button: Button = %SystemButton

@onready var back_to_map: Button = %BackToMap
@onready var back_to_title: Button = %BackToTitle
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var system_slider: HSlider = %SystemSlider

var player: Player

func _ready() -> void:
	show_pause_menu()
	system_button.pressed.connect( show_system_menu )
	setup_system()
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed( "pause" ):
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		queue_free()
	if pause.visible == true:
		if event.is_action_pressed( "down" ) or event.is_action_pressed( "right" ):
			system_button.grab_focus()

func show_pause_menu() -> void:
	pause.visible = true
	system.visible = false
	pass

func show_system_menu() -> void:
	pause.visible = false
	system.visible = true
	back_to_map.grab_focus()

func setup_system() -> void:
	back_to_title.pressed.connect( _on_back_to_title_pressed )
	back_to_map.pressed.connect( show_pause_menu )
	
func _on_back_to_title_pressed() -> void:
	SceneManager.transition_scene( "uid://cv8mro2sepasu", "", Vector2.ZERO, "up" )
	get_tree().paused = false
	queue_free()
