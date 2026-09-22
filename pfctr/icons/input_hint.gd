class_name InputHints extends Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

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
	visible = false
	Messages.input_hint_changed.connect( _on_hint_changed )
	pass

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

func _on_hint_changed( hint : String ) -> void:
	if hint == "":
		animation_player.play("show")
	else:
		animation_player.play("hide")
		await animation_player.animation_finished
		animation_player.play( "pointer" )
		visible = true
		sprite_2d.frame = HINT_MAP[ controller_type ].get( hint, "0" )
