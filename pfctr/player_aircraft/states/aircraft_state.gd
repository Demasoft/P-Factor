class_name AircraftState extends Node

var player : PlayerAircraft
var next_state : AircraftState

@onready var idle: AircraftStateIdle = %Idle
@onready var move: AircraftStateMove = %Move
@onready var overboost: AircraftStateOverboost = %Overboost

func init() -> void:
	pass

func enter() -> void:
	pass

func exit() -> void:
	pass

func handle_input( _event: InputEvent ) -> AircraftState:
	return next_state


func process( _delta: float) -> AircraftState:
	return next_state

func physics_process( _delta: float) -> AircraftState:
	return next_state
