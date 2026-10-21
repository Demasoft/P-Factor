class_name Bullet extends Node2D

@export var speed: float = 600.0
@export var damage: float = 1.0
@export var hit_radius: float = 6.0
@export var splash_duration: float = 0.1  ## Used if the splash isn't an AnimatedSprite2D

@onready var hit_area: Area2D = $Area2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
	 
@onready var splash: Node2D = $Splash   
@onready var bullet: Sprite2D = %Bullet

var has_hit: bool = false


func _ready() -> void:
	splash.hide()
	hit_area.body_entered.connect(_on_body_entered)
	screen_notifier.screen_exited.connect(queue_free)


func _physics_process(delta: float) -> void:
	if has_hit:
		return

	position.x += speed * delta

	for swarm: ParticleSwarm in ParticleSwarm.active:
		if swarm.try_hit(global_position, hit_radius, damage):
			_play_splash()
			return


func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return

	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	_play_splash()


func _play_splash() -> void:
	has_hit = true
	hit_area.set_deferred("monitoring", false)

	bullet.hide()
	splash.show()
	splash.scale = Vector2(0.5, 0.5)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(splash, "scale", Vector2(1.2, 1.2), splash_duration)
	tween.tween_property(splash, "modulate:a", 0.0, splash_duration)
	await tween.finished
	queue_free()
