class_name AircraftStateDeath extends AircraftState

#sfx
@export_group("Fire")
@export var fire_scene: PackedScene
@export var fire_spawn_count: int = 12
@export var fire_alpha_param: StringName = &"fire_alpha"
@export var fire_fade_in: float = 0.1
@export var fire_hold: float = 0.3
@export var fire_fade_out: float = 0.25
@export var fire_end_scale: float = 0.7      # fire condenses as it dies

@export_group("Smoke")
@export var smoke_scene: PackedScene
@export var smoke_alpha_param: StringName = &"fire_alpha"
@export var smoke_overlap: float = 0.25      # how long smoke fades in while the fire fades out
@export var smoke_fade_in: float = 0.25
@export var smoke_hold: float = 0.3
@export var smoke_fade_out: float = 0.5
@export var smoke_start_scale: float = 0.7   # match fire_end_scale for a seamless handoff
@export var smoke_end_scale: float = 1.4     # smoke expands as it fades

func init() -> void:
	pass

func enter() -> void:
	pass
