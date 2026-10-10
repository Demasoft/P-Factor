class_name PlayerAircraft extends CharacterBody2D

@onready var sprite_2d: AircraftSprite = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var move_speed : float = 180
@export var shooting_speed : float = 360

@export var rest_frame: int = 0
@export var bank_deadzone: float = 0.05   # the Input Map deadzone already filters most noise
@export var bank_response: float = 0.6    # below 1.0 makes small pushes bank more
@export var bank_follow: float = 14.0     # higher = snappier

const NORMAL_SPEED : float = 360.0
const SHOOTING_SPEED : float = 180.0

var is_shooting: bool = false

var is_banking: bool = false

var bank_value: float = 0.0               # -1 = full up, +1 = full down
var bank_enabled: bool = true
var states: Array[ AircraftState ]
var current_state: AircraftState : 
	get : return states.front()
var previous_state : AircraftState : 
	get : return states[ 1 ]

var hp : float = 20 :
	set( value ):
		hp = clampf( value, 0, max_hp )
		Messages.player_health_changed.emit( hp, max_hp )
var max_hp : float = 20 :
	set( value ):
		max_hp = value
		Messages.player_health_changed.emit( hp, max_hp )
#var skill : bool = false

var direction : Vector2 = Vector2.ZERO

func _ready() -> void:
	if get_tree().get_first_node_in_group( "PlayerAircraft" ) != self:
		self.queue_free()
	initialize_states()
	reparent.call_deferred(get_tree().current_scene)
	Messages.player_healed.connect( _on_player_healed )

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed( "interact" ):
		Messages.player_interacted.emit( self )
	elif event.is_action_pressed( "pause" ):
		get_tree().paused = true
		var pause_menu : PauseMenu= load( "uid://bdi104xa86306" ).instantiate()
		add_child( pause_menu )
		return
		
	change_state( current_state.handle_input( event ) )

func _process(_delta: float) -> void:
	update_direction()
	change_state(current_state.process(_delta))
	update_bank(_delta)

func _physics_process(_delta: float) -> void:
	is_shooting = Input.is_action_pressed("shoot")
	move_speed = SHOOTING_SPEED if is_shooting else NORMAL_SPEED
	
	change_state(current_state.physics_process(_delta))
	move_and_slide()

func initialize_states() -> void:
	states = []
	#gather states
	for c in $States.get_children():
		if c is AircraftState:
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

func change_state( new_state : AircraftState ) -> void:
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
	direction = Input.get_vector("left", "right", "up", "down")

func _on_player_healed( amount : float ) -> void:
	hp += amount
	
func update_bank(delta: float) -> void:
	if not bank_enabled:
		return

	var y := direction.y
	var target := 0.0
	if absf(y) > bank_deadzone:
		target = signf(y) * pow(absf(y), bank_response)

	bank_value = lerpf(bank_value, target, 1.0 - exp(-bank_follow * delta))
	if absf(bank_value - target) < 0.005:
		bank_value = target

	# LEVEL: hand control back to the AnimationPlayer
	if absf(bank_value) < 0.001:
		bank_value = 0.0
		if is_banking or animation_player.current_animation != "idle":
			is_banking = false
			animation_player.play("idle")
			animation_player.advance(0.0)   # apply frame 0 immediately, no one-frame lag
		return

	# BANKING: we drive the clip by hand
	is_banking = true
	if animation_player.is_playing():
		animation_player.pause()

	var clip := "move_up" if bank_value < 0.0 else "move_down"
	var length := animation_player.get_animation(clip).length
	animation_player.assigned_animation = clip
	animation_player.seek(absf(bank_value) * length, true)
