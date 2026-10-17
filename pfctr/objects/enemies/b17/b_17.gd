class_name B17 extends CharacterBody2D

signal death(enemy: B17)

const PLAYER_GROUP: StringName = &"PlayerAircraft"
const DEFAULT_AIM_ANGLE: float = PI   # faces left when no player exists
#const LAYER_WORLD: int = 1
#const LAYER_ENEMY: int = 2

@export var max_hp: float = 10.0
@export var move_speed: float = 120.0
@export var bullet_scene: PackedScene
@export var patterns: Array[BulletPattern] = []

@onready var collision_polygon_2d: CollisionPolygon2D = $CollisionPolygon2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var muzzle: Marker2D = $Muzzle

@onready var state_enter: EnemyStateEnter = $States/Enter
@onready var state_idle: EnemyStateIdle = $States/Idle
@onready var state_attack: EnemyStateAttack = $States/Attack
@onready var state_dead: EnemyStateDeath = $States/Death

var current_state: EnemyState = null
var hp: float = 0.0
var pattern_index: int = 0
var anchor_y: float = 0.0   # height the enemy bobs around while idle

func _ready() -> void:
	#configure_collision()
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
	if hp <= 0.0:
		change_state(state_dead)


func get_player() -> PlayerAircraft:
	var node: Node = get_tree().get_first_node_in_group(PLAYER_GROUP)
	return node as PlayerAircraft


func get_aim_angle() -> float:
	var player: PlayerAircraft = get_player()
	if player == null:
		return DEFAULT_AIM_ANGLE
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
