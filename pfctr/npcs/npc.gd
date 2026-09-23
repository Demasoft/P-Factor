class_name NPC extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D

@export var move_speed : float = 180 
@export var max_fall_velocity: float = 600

var states: Array[ NPCState ]
var current_state: NPCState : 
	get : return states.front()
var previous_state : NPCState : 
	get : return states[ 1 ]

var direction : Vector2 = Vector2.ZERO
#var gravity : float = 980
#var gravity_multiplier : float = 1.0

func _ready() -> void:
	initialize_states()
	pass

func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed( "interact" ):
		#Messages.player_interacted.emit( self )
	#elif event.is_action_pressed( "pause" ):
		#get_tree().paused = true
		#var pause_menu : PauseMenu= load( "uid://bdi104xa86306" ).instantiate()
		#add_child( pause_menu )
		#return
		
	change_state( current_state.handle_input( event ) )
	pass


func _process(_delta: float) -> void:
	update_direction()
	change_state(current_state.process(_delta))

func _physics_process(_delta: float) -> void:
	#velocity.y += gravity * _delta * gravity_multiplier
	#velocity.y = clampf( velocity.y, -1000, max_fall_velocity )
	#move_and_slide()
	change_state( current_state.physics_process( _delta ) )

func initialize_states() -> void:
	states = []
	#gather states
	for c in $States.get_children():
		if c is NPCState:
			states.append( c )
			c.npc = self
		pass

	if states.size() == 0:
		return

	#initialize states
	for state in states:
		state.init()
		
	change_state( current_state )
	current_state.enter()
	$Label.text = current_state.name
	pass

func change_state( new_state : NPCState ) -> void:
	if new_state == null:
		return
	elif new_state == current_state:
		return
	
	if current_state:
		current_state.exit()
	
	states.push_front( new_state )
	current_state.enter()
	states.resize( 3 ) 
	$Label.text = current_state.name
	pass
	
func update_direction() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	var x_axis = player.global_position.x
	var y_axis = player.global_position.y
	direction = Vector2(x_axis,y_axis) 
	
	if x_axis < global_position.x:
		sprite_2d.flip_h = true
	elif direction.x > 0:
		sprite_2d.flip_h = false
	
