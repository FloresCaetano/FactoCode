extends Enemy

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var attack_timer: Timer = $AttackTimer
@export var rotatable_nodes: Array[Node2D] = []

var movement_speed : float = 300.0
var damage : int = 10
var attack_cooldown : float = 1.0
var _actual_target : Node2D = null
var actual_target : Node2D:
	set(value):
		if _actual_target == value:
			return
		_actual_target = value
		if _actual_target != null:
			navigation_agent_2d.target_position = _actual_target.global_position
			_look_update_elapsed = 0.0
	get:
		return _actual_target
var update_interval : float = 0.1
var look_update_interval : float = 0.1
var movement_smoothing : float = 0.1

var _move_tween : Tween = null

var _update_elapsed : float = 0.0
var _look_update_elapsed : float = 0.0
var _is_on_screen : bool = false

enum State {
	SEARCHING,
	MOVING,
	ATTACKING
}

var state : State = State.SEARCHING

func _ready() -> void:
	set_physics_process(false)

func _process(delta: float) -> void:
	_update_elapsed += delta
	if _update_elapsed < update_interval:
		return
	var step_delta = _update_elapsed
	_update_elapsed = 0.0
	_tick(step_delta)

func _tick(delta: float) -> void:
	match state:
		State.SEARCHING:
			search_for_target()
		State.MOVING:
			move(delta)
		State.ATTACKING:
			if attack_timer.is_stopped():
				attack()

func search_for_target() -> void:
	if PATHS.core != null:
		actual_target = PATHS.core
		_set_state(State.MOVING)
	
func move(delta: float) -> void:
	if actual_target == null:
		_set_state(State.SEARCHING)
		return

	_look_update_elapsed += delta

	if not navigation_agent_2d.is_target_reached():
		if _is_on_screen and _look_update_elapsed >= look_update_interval:
			_look_update_elapsed = 0.0
			for node in rotatable_nodes:
				node.look_at(actual_target.global_position)

		var nav_point_direction = to_local(navigation_agent_2d.get_next_path_position()).normalized()
		velocity = nav_point_direction * movement_speed
		var desired_position = global_position + velocity * delta
		if _is_on_screen:
			if _move_tween and _move_tween.is_running():
				_move_tween.kill()
			_move_tween = get_tree().create_tween()
			_move_tween.tween_property(self, "global_position", desired_position, movement_smoothing)
		else:
			global_position = desired_position

func attack() -> void:
	if not actual_target:
		_set_state(State.SEARCHING)
		return
	
	actual_target.take_damage(damage)
	attack_timer.start(attack_cooldown)

func _on_search_area_body_entered(body: Node2D) -> void:
	if body is Structure and (actual_target == PATHS.core or actual_target == null):
		actual_target = body
		_set_state(State.MOVING)
		actual_target.destroyed.connect(_on_target_destroyed)
	
func _on_target_destroyed() -> void:
	actual_target = null
	_set_state(State.SEARCHING)

func _on_collision_detector_body_entered(body: Node2D) -> void:
	if body == actual_target and state != State.ATTACKING:
		_set_state(State.ATTACKING)

func _set_state(next_state: State) -> void:
	if state == next_state:
		return
	state = next_state
	if state == State.MOVING and actual_target != null:
		navigation_agent_2d.target_position = actual_target.global_position
		_look_update_elapsed = 0.0


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	_is_on_screen = true

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	_is_on_screen = false
