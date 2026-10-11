class_name Bullet extends Node2D

@export var speed: float = 600.0
@export var damage: float = 1.0

@onready var hit_area: Area2D = $Area2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var has_hit: bool = false


func _ready() -> void:
	hit_area.body_entered.connect(_on_body_entered)
	screen_notifier.screen_exited.connect(queue_free)


func _physics_process(delta: float) -> void:
	position.x += speed * delta


func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return

	has_hit = true
	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	queue_free()
