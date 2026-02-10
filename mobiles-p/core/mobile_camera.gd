extends Camera2D

# Configuration
@export var MAX_ZOOM: float = 4.0
@export var MIN_ZOOM: float = 0.16
@export var coords_label: Label

enum ZOOM_GESTURE { DISABLED, PINCH }
enum MOVEMENT_GESTURE { DISABLED, SINGLE_DRAG, MULTI_DRAG }

@export var zoom_gesture: ZOOM_GESTURE = ZOOM_GESTURE.PINCH
@export var movement_gesture: MOVEMENT_GESTURE = MOVEMENT_GESTURE.SINGLE_DRAG

var effective_limit_left = -10000000
var effective_limit_right = 10000000
var effective_limit_top = -10000000
var effective_limit_bottom = 10000000

var _last_pointer_pos: Vector2 = Vector2.ZERO
var _has_pointer_pos: bool = false

func set_camera_position(p):
	var camera_limits
	var camera_size = get_camera_size() / zoom

	if anchor_mode == ANCHOR_MODE_FIXED_TOP_LEFT:
		camera_limits = [
			Vector2(),
			Vector2(camera_size.x, 0),
			Vector2(0,             camera_size.y),
			Vector2(camera_size.x, camera_size.y),
			Vector2(camera_size.x, 0)
		]
	elif anchor_mode == ANCHOR_MODE_DRAG_CENTER:
		camera_limits = [
			Vector2(-camera_size.x / 2, -camera_size.y / 2),
			Vector2( camera_size.x / 2, -camera_size.y / 2),
			Vector2( camera_size.x / 2,  camera_size.y / 2),
			Vector2(-camera_size.x / 2,  camera_size.y / 2)
		]

	for i in camera_limits.size():
		camera_limits[i] = camera_limits[i].rotated(rotation)

	for camera_limit in camera_limits:
		if p.x > effective_limit_right - camera_limit.x:
			p.x = effective_limit_right - camera_limit.x
		if p.y > effective_limit_bottom - camera_limit.y:
			p.y = effective_limit_bottom - camera_limit.y
		if p.x < effective_limit_left - camera_limit.x:
			p.x = effective_limit_left - camera_limit.x
		if p.y < effective_limit_top - camera_limit.y:
			p.y = effective_limit_top - camera_limit.y

	for camera_limit in camera_limits:
		if (p.x > effective_limit_right - camera_limit.x or
			p.y > effective_limit_bottom - camera_limit.y or
			p.x < effective_limit_left - camera_limit.x or
			p.y < effective_limit_top - camera_limit.y):
			return false

	position = p
	return true

func _unhandled_input(e):
	if (e is InputEventMultiScreenDrag and movement_gesture == MOVEMENT_GESTURE.MULTI_DRAG
		or e is InputEventSingleScreenDrag and movement_gesture == MOVEMENT_GESTURE.SINGLE_DRAG):
		_last_pointer_pos = e.position
		_has_pointer_pos = true
		_move(e)
	elif e is InputEventScreenPinch and zoom_gesture == ZOOM_GESTURE.PINCH:
		_last_pointer_pos = e.position
		_has_pointer_pos = true
		_zoom(e)
	elif e is InputEventSingleScreenLongPress or e is InputEventMultiScreenLongPress:
		_last_pointer_pos = e.position
		_has_pointer_pos = true
		copiar_coordenadas_al_portapapeles()

# Given a position on the camera returns the corresponding global position
func camera2global(_position):
	var camera_center = global_position
	var from_camera_center_pos = _position - get_camera_center_offset()
	return camera_center + (from_camera_center_pos / zoom).rotated(rotation)

func _move(event):
	set_camera_position(position - (event.relative / zoom).rotated(rotation))

func _zoom(event):
	var li = event.distance
	var lf = event.distance - event.relative

	var zi = zoom.x
	var zf = (li * zi) / lf
	var zd = zf - zi

	if zf <= MIN_ZOOM and sign(zd) < 0:
		zf = MIN_ZOOM
		zd = zf - zi
	elif zf >= MAX_ZOOM and sign(zd) > 0:
		zf = MAX_ZOOM
		zd = zf - zi

	zoom = zf * Vector2.ONE

	var from_camera_center_pos = event.position - get_camera_center_offset()
	var relative = (from_camera_center_pos * zd) / (zi * zf)
	if not set_camera_position(position + relative.rotated(rotation)):
		zoom = zi * Vector2.ONE

func get_camera_center_offset():
	if anchor_mode == ANCHOR_MODE_FIXED_TOP_LEFT:
		return Vector2.ZERO
	elif anchor_mode == ANCHOR_MODE_DRAG_CENTER:
		return get_camera_size() / 2

func get_camera_size():
	return get_viewport().get_visible_rect().size

func _ready():
	rotation = 0.0

	var limit_left_tmp = effective_limit_left
	effective_limit_left = limit_left
	limit_left = limit_left_tmp

	var limit_right_tmp = effective_limit_right
	effective_limit_right = limit_right
	limit_right = limit_right_tmp

	var limit_top_tmp = effective_limit_top
	effective_limit_top = limit_top
	limit_top = limit_top_tmp

	var limit_bottom_tmp = effective_limit_bottom
	effective_limit_bottom = limit_bottom
	limit_bottom = limit_bottom_tmp

	set_camera_position(position)

func _process(_delta: float) -> void:
	update_grid_coords()

func update_grid_coords() -> void:
	if coords_label == null:
		return

	var pointer_pos = _last_pointer_pos if _has_pointer_pos else get_viewport().get_mouse_position()
	var world_pos = camera2global(pointer_pos)

	# Snapping cada 50 pixeles
	var snapped_pos = world_pos.snapped(Vector2(50, 50))
	var game_coords = snapped_pos / 100.0
	coords_label.text = "Coordenadas Grid: " + str(game_coords)
	coords_label.global_position = world_pos + Vector2(20, 20)

func copiar_coordenadas_al_portapapeles() -> void:
	var pointer_pos = _last_pointer_pos if _has_pointer_pos else get_viewport().get_mouse_position()
	var world_pos = camera2global(pointer_pos)
	var snapped_pos = world_pos.snapped(Vector2(50, 50))
	var game_coords = snapped_pos / 100.0

	var texto_a_copiar = "Vector2" + str(game_coords)
	DisplayServer.clipboard_set(texto_a_copiar)

	if coords_label:
		coords_label.modulate = Color.GREEN
		get_tree().create_timer(0.2).timeout.connect(func(): coords_label.modulate = Color.WHITE)
