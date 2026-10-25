class_name InputHints extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var owner_node: Node

const HINT_MAP : Dictionary = {
	"keyboard" : {
		"Interact" : 0,
		"Attack" : 0,
	},
	"playstation" : {
		"Interact" : 0,
		"Attack" : 0,
	}
}

var controller_type: String = "keyboard"

@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	Messages.input_hint_changed.connect( _on_hint_changed )

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey:
		controller_type = "keyboard"
	elif event is InputEventJoypadButton:
		get_controller_type( event.device )
	
func get_controller_type( device_id: int ) -> void:
	var n : String = Input.get_joy_name( device_id ).to_lower()
	
	if "xbox" in n:
		controller_type = "xbox"
	elif "playstation" in n or "ps" in n or "dualsense" in n:
		controller_type = "playstation"
	else: 
		controller_type = "playstation"
	
	print(controller_type)
	set_process_input( false )

func _on_hint_changed(source: Node, hint: String) -> void:
	if source != owner_node:
		return

	if hint == "":
		fade_out_sprite(sprite_2d)
		await fade_out_sprite(sprite_2d)
		animation_player.pause()
		return

	sprite_2d.frame = HINT_MAP[controller_type].get(hint, 0)
	animation_player.play("pointer")
	fade_in_sprite(sprite_2d)
	
func fade_in_sprite(sprite: Sprite2D, duration: float = 0.2) -> void:
	sprite.modulate.a = 0.0
	
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, duration)

func fade_out_sprite(sprite: Sprite2D, duration: float = 0.2) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, duration)
	
	await tween.finished
