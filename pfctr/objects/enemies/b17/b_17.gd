class_name B17 extends CharacterBody2D

@warning_ignore("unused_signal")
signal death(enemy: B17)

const PLAYER_GROUP: StringName = &"PlayerAircraft"

@export var max_hp: float = 10.0
@export var move_speed: float = 120.0
@export var bullet_scene: PackedScene
@export var patterns: Array[BulletPattern] = []

@onready var collision_polygon_2d: CollisionPolygon2D = $CollisionPolygon2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var muzzle: Marker2D = $Muzzle
@onready var sprite: Sprite2D = $Sprite2D

@onready var state_enter: EnemyStateEnter = $States/Enter
@onready var state_idle: EnemyStateIdle = $States/Idle
@onready var state_attack: EnemyStateAttack = $States/Attack
@onready var state_dead: EnemyStateDeath = $States/Death

@export var hit_color: Color = Color(0.0, 0.0, 5.913, 1.0)
@export var hit_flash_time: float = 0.1

var current_state: EnemyState = null
var hp: float = 0.0
var pattern_index: int = 0
var anchor_y: float = 1.0  

func _ready() -> void:
	hp = max_hp
	initialize_states()

func _process(delta: float) -> void:
	change_state(current_state.process(delta))

func _physics_process(delta: float) -> void:
	change_state(current_state.physics_process(delta))
	move_and_slide()

func initialize_states() -> void:
	for child: Node in $States.get_children():
		var state: EnemyState = child as EnemyState
		if state == null:
			continue
		state.enemy = self
		state.init()

	change_state(state_enter)

func change_state(new_state: EnemyState) -> void:
	if new_state == null or new_state == current_state:
		return

	if current_state != null:
		current_state.exit()

	current_state = new_state
	current_state.enter()

func take_damage(amount: float) -> void:
	if current_state == state_dead:
		return

	hp = maxf(hp - amount, 0.0)
	flash_hit()

	if hp <= 0.0:
		change_state(state_dead)

func flash_hit() -> void:
	sprite.modulate = hit_color
	await get_tree().create_timer(hit_flash_time).timeout
	sprite.modulate = Color.WHITE

func get_player() -> PlayerAircraft:
	var node: Node = get_tree().get_first_node_in_group(PLAYER_GROUP)
	return node as PlayerAircraft

func get_aim_angle() -> float:
	var player: PlayerAircraft = get_player()
	return global_position.direction_to(player.global_position).angle()

func next_pattern() -> BulletPattern:
	if patterns.is_empty():
		return null

	var pattern: BulletPattern = patterns[pattern_index]
	pattern_index = (pattern_index + 1) % patterns.size()
	return pattern

func fire_bullet(angle: float, speed: float) -> void:
	var bullet: EnemyBullet = bullet_scene.instantiate() as EnemyBullet
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.launch(angle, speed)
