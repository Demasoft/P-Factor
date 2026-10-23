class_name EnemyBullet extends Node2D

const NO_SPIN: float = 0.0

@export var damage: float = 1.0
@export var max_lifetime: float = 10.0
@export var spin_speed_degrees: float = 360.0

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
	if is_zero_approx(spin_speed_degrees):
		rotation = angle

func _physics_process(delta: float) -> void:
	position += velocity * delta
	update_rotation(delta)

	age += delta
	if age >= max_lifetime:
		queue_free()

func update_rotation(delta: float) -> void:
	if is_zero_approx(spin_speed_degrees):
		if velocity != Vector2.ZERO:
			rotation = velocity.angle()
		return

	rotation += deg_to_rad(spin_speed_degrees) * delta

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return
	if body is not PlayerAircraft:
		return

	has_hit = true
	Messages.player_hit.emit( damage )
	queue_free()
