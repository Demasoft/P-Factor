class_name PlayerState extends Node

var player : Player
var next_state : PlayerState

@onready var idle: PlayerStateIdle = %Idle
@onready var move: PlayerStateMove = %Move
#@onready var jump: PlayerStateJump = %Jump
@onready var shoot: PlayerStateShoot = %Shoot
@onready var overboost: PlayerStateOverboost = $Overboost

func init() -> void:
	pass

func enter() -> void:
	pass

func exit() -> void:
	pass

func handle_input( _event: InputEvent ) -> PlayerState:
	return next_state


func process( _delta: float) -> PlayerState:
	return next_state

func physics_process( _delta: float) -> PlayerState:
	return next_state
