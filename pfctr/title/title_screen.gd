extends CanvasLayer

@onready var main_menu: VBoxContainer = %MainMenu
@onready var new_game_menu: VBoxContainer = %NewGameMenu
@onready var load_game_menu: VBoxContainer = %LoadGameMenu

@onready var new_game: Button = %NewGame
@onready var load_game: Button = %LoadGame

@onready var new_slot: Button = %NewSlot
@onready var new_slot_2: Button = %NewSlot2
@onready var new_slot_3: Button = %NewSlot3

@onready var load_slot: Button = %LoadSlot
@onready var load_slot_2: Button = %LoadSlot2
@onready var load_slot_3: Button = %LoadSlot3

@onready var animation_player: AnimationPlayer = $Control/MainMenu/Logo/AnimationPlayer

func _ready() -> void:
	new_game.pressed.connect( show_new_game_menu )
	load_game.pressed.connect( show_load_game_menu )
	
	new_slot.pressed.connect( _on_new_game_pressed.bind( 0 ) )
	new_slot_2.pressed.connect( _on_new_game_pressed.bind( 1 ) )
	new_slot_3.pressed.connect( _on_new_game_pressed.bind( 2 ) )
	
	load_slot.pressed.connect( _on_load_game_pressed.bind( 0 ) )
	load_slot_2.pressed.connect( _on_load_game_pressed.bind( 1 ) )
	load_slot_3.pressed.connect( _on_load_game_pressed.bind( 2 ) )
	
	show_main_menu()
	animation_player.animation_finished.connect( _on_animation_finished )
	pass

func _unhandled_input( event : InputEvent ) -> void:
	if event.is_action_pressed( "ui_cancel" ):
		if main_menu.visible == false:
			show_main_menu()

func show_main_menu() -> void:
	main_menu.visible = true
	new_game_menu.visible = false
	load_game_menu.visible = false
	
	if not SaveManager.save_file_check( 0 ) and not SaveManager.save_file_check( 1 ) and not SaveManager.save_file_check( 2 ):
		load_game.disabled = true
		new_game.grab_focus()
	else: 
		load_game.grab_focus()

func show_new_game_menu() -> void:
	main_menu.visible = false
	new_game_menu.visible = true
	load_game_menu.visible = false
	new_slot.grab_focus()
	
	if SaveManager.save_file_check( 0 ):
		new_slot.text = "Replace slot 1"
		
	if SaveManager.save_file_check( 1 ):
		new_slot_2.text = "Replace slot 2"
		
	if SaveManager.save_file_check( 2 ):
		new_slot_3.text = "Replace slot 3"

func show_load_game_menu() -> void:
	main_menu.visible = false
	new_game_menu.visible = false
	load_game_menu.visible = true
	load_slot.grab_focus()
	
	load_slot.disabled = not SaveManager.save_file_check( 0 )
	load_slot_2.disabled = not SaveManager.save_file_check( 1 )
	load_slot_3.disabled = not SaveManager.save_file_check( 2 )

func _on_new_game_pressed( slot: int ) -> void:
	SaveManager.create_new_save_game( slot )

func _on_load_game_pressed( slot: int ) -> void:
	SaveManager.load_game( slot )

func _on_animation_finished( animation: String ) -> void:
	if animation == "logo":
		animation_player.play( "loop" )
