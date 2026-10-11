class_name EnemyBullet extends Node2D

@export var damage: float = 1.0
@export var max_lifetime: float = 10.0   # safety net if it never enters the screen

@onready var hit_area: Area2D = $Area2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var velocity: Vector2 = Vector2.ZERO
var age: float = 0.0
var has_hit: bool = false


func _ready() -> void:
	hit_area.body_entered.connect(_on_body_entered)
	screen_notifier.screen_exited.connect(queue_free)


func launch(angle: float, speed: float) -> void:
	velocity = Vector2.from_angle(angle) * speed
	rotation = angle


func _physics_process(delta: float) -> void:
	position += velocity * delta
	age += delta
	if age >= max_lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return

	var player: PlayerAircraft = body as PlayerAircraft
	if player == null:
		return

	has_hit = true
	player.hp -= damage
	queue_free()
