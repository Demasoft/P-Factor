class_name MachineGun extends Node2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 20.0          # shots per second
@export var shoot_action: StringName = &"shoot"

@onready var muzzle: Marker2D = $Muzzle
@onready var flash_player: AnimationPlayer = $FlashPlayer

var cooldown: float = 0.0
var enabled: bool = true                    # states can switch this off


func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)

	if enabled and cooldown <= 0.0 and Input.is_action_pressed(shoot_action):
		fire()


func fire() -> void:
	cooldown = 1.0 / fire_rate

	var bullet: Node2D = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	get_tree().current_scene.add_child(bullet)

	#flash_player.stop()
	#flash_player.play("flash")
