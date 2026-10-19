extends Node2D

var fx := GPUParticles2D.new()
var proc := ShaderMaterial.new()

func _ready() -> void:
	proc.shader = load("res://shaders/explosion.gdshader")

	var draw := ShaderMaterial.new()
	draw.shader = load("res://shaders/debri.gdshader")

	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)

	fx.texture = ImageTexture.create_from_image(img)
	fx.amount = 465                    # must match TOTAL in the shader
	fx.lifetime = 3.0                  # must exceed the longest-living particle             # must exceed the longest-living particle      # must exceed the longest-living particle
	fx.one_shot = true
	fx.explosiveness = 1.0
	fx.local_coords = true
	fx.process_material = proc
	fx.material = draw
	fx.visibility_rect = Rect2(-1200, -1400, 2400, 2000)
	fx.emitting = false
	add_child(fx)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		explode(get_global_mouse_position())

func explode(pos: Vector2) -> void:
	fx.global_position = pos
	proc.set_shader_parameter("seed", randi() % 100000)   # different shape each time
	fx.restart()
	fx.emitting = true
