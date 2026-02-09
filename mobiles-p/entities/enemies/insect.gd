extends Enemy

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var attack_timer: Timer = $AttackTimer
@export var rotatable_nodes: Array[Node2D] = []

var movement_speed : float = 300.0
var damage : int = 10
var attack_cooldown : float = 1.0
var actual_target : Node2D = null

enum State {
	SEARCHING,
	MOVING,
	ATTACKING
}

var state : State = State.SEARCHING

func _physics_process(_delta: float) -> void:
	match state:
		State.SEARCHING:
			search_for_target()
		State.MOVING:
			move()
		State.ATTACKING:
			if attack_timer.is_stopped():
				attack()

func search_for_target() -> void:
	if PATHS.core != null:
		actual_target = PATHS.core
		state = State.MOVING
	
func move() -> void:
	navigation_agent_2d.target_position = actual_target.global_position
	if not navigation_agent_2d.is_target_reached():

		for node in rotatable_nodes:
			node.look_at(actual_target.global_position)

		var nav_point_direction = to_local(navigation_agent_2d.get_next_path_position()).normalized()
		velocity = nav_point_direction * movement_speed
		move_and_slide()

func attack() -> void:
	if not actual_target:
		state = State.SEARCHING
		return
	
	actual_target.take_damage(damage)
	attack_timer.start(attack_cooldown)

func _on_search_area_body_entered(body: Node2D) -> void:
	if body is Structure and (actual_target == PATHS.core or actual_target == null):
		actual_target = body
		state = State.MOVING
		actual_target.destroyed.connect(_on_target_destroyed)
	
func _on_target_destroyed() -> void:
	actual_target = null
	state = State.SEARCHING

func _on_collision_detector_body_entered(body: Node2D) -> void:
	if body == actual_target and state != State.ATTACKING:
		state = State.ATTACKING
