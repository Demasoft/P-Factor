extends CanvasLayer

@onready var hp_label: Label = %Label
@onready var timer_label: Label = %TimerLabel


func _ready() -> void:
	Messages.player_health_changed.connect(_on_health_changed)
	timer_label.hide()


func _on_health_changed(hp: float, _max_hp: float) -> void:
	hp_label.text = "x%d" % ceili(hp)


func start_timer(duration: float) -> void:
	update_timer(duration)


func update_timer(value: float) -> void:
	if not is_instance_valid(timer_label):
		return

	timer_label.visible = value > 0.0

	if value > 0.0:
		var minutes := int(value / 60.0)
		var seconds := int(value) % 60
		var milliseconds := int((value - floorf(value)) * 1000.0)

		timer_label.text = "%02d'%02d'%03d" % [
			minutes, seconds, milliseconds
		]
