class_name Turret
extends Structure

var bullet_speed : float = 20
var bullet_damage : float = 35
var cooldown : float = 1.0

@export var bullet_spawner: Node2D
@export var sonnar: Area2D

@export var top: Sprite2D
@export var cooldown_timer: Timer

var enemies : Array[Enemy]
var active_target : Enemy

func shoot():
	var bullet : Bullet = load(GLOBAL.PATHS.p_bullet).instantiate()
	bullet_spawner.add_child(bullet)
	bullet.bullet_speed = bullet_speed
	bullet.damage = bullet_damage
	cooldown_timer.start(cooldown)

func _physics_process(_delta: float) -> void:
	if enemies.size() != 0 and not active_target:
		active_target = enemies.pop_back()
		active_target.die.connect(_on_enemy_dead)
	
	if active_target and cooldown_timer.is_stopped():
		top.look_at(active_target.global_position)
		shoot()

func _on_enemy_dead():
	active_target = null

func _on_sonnar_body_entered(body: Node2D) -> void:
	if body is Enemy:
		enemies.append(body)
