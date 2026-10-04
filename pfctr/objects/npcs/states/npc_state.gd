class_name NPCState extends Node

var npc : NPC
var next_state : NPCState

@onready var idle: NPCStateIdle = %Idle

func init() -> void:
	pass

func enter() -> void:
	pass

func exit() -> void:
	pass

func handle_input( _event: InputEvent ) -> NPCState:
	return next_state

func process( _delta: float) -> NPCState:
	return next_state

func physics_process( _delta: float) -> NPCState:
	return next_state
