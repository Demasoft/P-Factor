class_name Player extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_stand: CollisionShape2D = $CollisionStand
@onready var collision_crouch: CollisionShape2D = $CollisionCrouch
@onready var shape_cast_2d: ShapeCast2D = $ShapeCast2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


@export var move_speed : float = 180 
@export var max_fall_velocity: float = 600

var states: Array[ PlayerState ]
var current_state: PlayerState : 
	get : return states.front()
var previous_state : PlayerState : 
	get : return states[ 1 ]

var hp : float = 20
var max_hp : float = 20
#var skill : bool = false

var direction : Vector2 = Vector2.ZERO
var gravity : float = 980
var gravity_multiplier : float = 1.0

func _ready() -> void:
	if get_tree().get_first_node_in_group( "Player" ) != self:
		self.queue_free()
	initialize_states()
	reparent.call_deferred(get_tree().root)
	Messages.player_healed.connect( _on_player_healed )

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed( "interact" ):
		Messages.player_interacted.emit( self )
	change_state( current_state.handle_input( event ) )

func _process(_delta: float) -> void:
	update_direction()
	change_state( current_state.process( _delta ) )
	pass

func _physics_process(_delta: float) -> void:
	velocity.y += gravity * _delta * gravity_multiplier
	velocity.y = clampf( velocity.y, -1000, max_fall_velocity )
	move_and_slide()
	change_state( current_state.physics_process( _delta ) )
	pass


func initialize_states() -> void:
	states = []
	#gather states
	for c in $States.get_children():
		if c is PlayerState:
			states.append( c )
			c.player = self
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

func change_state( new_state : PlayerState ) -> void:
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
	var prev_direction : Vector2 = direction
	
	var x_axis = Input.get_axis("left","right")
	var y_axis = Input.get_axis("up","down")
	direction = Vector2(x_axis,y_axis) 
	
	if prev_direction.x != direction.x:
		if direction.x < 0:
			sprite_2d.flip_h = false
		elif direction.x > 0:
			sprite_2d.flip_h = true
	pass

func _on_player_healed( amount : float ) -> void:
	hp += amount
	print(amount)
