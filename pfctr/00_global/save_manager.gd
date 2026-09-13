extends Node

const SLOTS : Array[ String ] = [
	"save_01", "save_02", "save_03" 
]

var current_slot : int = 0
var save_data : Dictionary
#Will be used to show names of places we've never been at
var discovered_areas : Array = []
var persistent_data: Dictionary = {}

func _ready() -> void:
	pass

func _unhandled_key_input( event: InputEvent ) -> void:
	#Maintain for dubugging
	#if event is InputEventKey and event.pressed:
		#if event.keycode == KEY_F9:
			#create_new_save_game()
			
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			save_game()
		elif event.keycode == KEY_F7:
			load_game()
		elif event.keycode == KEY_1:
			current_slot = 0
		elif event.keycode == KEY_2:
			current_slot = 1
		elif event.keycode == KEY_3:
			current_slot = 2

func create_new_save_game() -> void:
	var new_game_scene : String = "uid://cr4vhm31bd2gx"
	discovered_areas.append( new_game_scene )
	save_data = {
		"scene_path" : new_game_scene,
		"x" : 535.0,
		"y" : 226.0,
		"hp" : 20,
		"max_hp" : 20,
		#"dash" : false, #skill
		"discovered_areas" : discovered_areas,
		"persistent_data" : persistent_data,
	}
	
	var save_file = FileAccess.open( get_file_name(), FileAccess.WRITE )
	save_file.store_line( JSON.stringify( save_data ) )
	
func save_game() -> void:
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	save_data = {
		"scene_path" : SceneManager.current_scene_uid,
		"x" : player.global_position.x,
		"y" : player.global_position.y,
		"hp" : player.hp,
		"max_hp" : player.max_hp,
		#"dash" : false, #skill
		"discovered_areas" : discovered_areas,
		"persistent_data" : persistent_data,
	}
	
	var save_file = FileAccess.open( get_file_name(), FileAccess.WRITE )
	save_file.store_line( JSON.stringify( save_data ) )

func load_game() -> void:
	if not FileAccess.file_exists( get_file_name() ):
		return
		
	var save_file = FileAccess.open( get_file_name(), FileAccess.READ )
	save_data = JSON.parse_string( save_file.get_line() )
	
	persistent_data = save_data.get( "persistent_data", {} )
	discovered_areas = save_data.get( "discovered_areas", [] )
	var scene_path : String = save_data.get( "scene_path", "uid://cr4vhm31bd2gx" )
	SceneManager.transition_scene( scene_path, "", Vector2.ZERO, "up" )
	await SceneManager.new_scene_ready
	setup_player()
	
func setup_player() -> void:
	var player : Player = null
	while not player: 
		player = get_tree().get_first_node_in_group( "Player" )
		await  get_tree().process_frame
	
	player.max_hp = save_data.get( "max_hp", 20 )
	player.hp = save_data.get( "hp", 20 )
	
	#player.skill...
	player.global_position = Vector2(
		save_data.get( "x", 0 ),
		save_data.get( "y", 0 )
	)

func get_file_name() -> String:
	return "user://" + SLOTS[current_slot] + ".sav"
