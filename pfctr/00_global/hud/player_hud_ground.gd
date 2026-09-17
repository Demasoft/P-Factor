extends CanvasLayer

@onready var label: Label = $Control/Label
@onready var sprite_2d: Sprite2D = $Control/Label/Sprite2D


func _ready() -> void:
	var material := label.material as ShaderMaterial

	if material == null:
		push_error("Label does not have a ShaderMaterial.")
		return

	material.set_shader_parameter(
		"inside_texture",
		sprite_2d.texture
	)
