class_name MGBullet extends Node2D

@export var speed: float = 600.0
@export var damage: float = 1.0

@onready var area: Area2D = $Area2D

func _ready() -> void:
	var notifier := VisibleOnScreenNotifier2D.new()
	add_child(notifier)
	notifier.screen_exited.connect(queue_free)
	area.area_entered.connect(_on_hit)
	area.body_entered.connect(_on_hit)

func _physics_process(delta: float) -> void:
	position.x += speed * delta

func _on_hit(_other: Node) -> void:
	# apply damage here once you have enemies
	queue_free()
