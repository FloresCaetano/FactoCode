extends Node2D

@onready var camera : Camera2D = $Camera2D

@export var min_zoom : float = 0.5
@export var max_zoom : float = 2.5
@export var zoom_speed : float = 0.4
@export var smoothing : float = 20.0

@export var coords_label : Label

var target_pos : Vector2

func _ready() -> void:
	target_pos = camera.position

func _process(delta: float) -> void:
	camera.position = camera.position.lerp(target_pos, smoothing * delta)
	
	update_grid_coords()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("copy_coords"):
		copiar_coordenadas_al_portapapeles()
	
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("drag_camera"):
			target_pos -= event.relative / camera.zoom
	
	if event.is_action_pressed("zoom_in"):
		zoom_camera(zoom_speed)
	elif event.is_action_pressed("zoom_out"):
		zoom_camera(-zoom_speed)

func zoom_camera(delta: float) -> void:
	var new_zoom = clamp(camera.zoom.x + delta, min_zoom, max_zoom)
	var final_zoom = Vector2(new_zoom, new_zoom)
	
	var tween : Tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "zoom", final_zoom, 0.3)

func update_grid_coords() -> void:
	if coords_label:
		var mouse_pos = get_global_mouse_position()
		
		# Snapping cada 50 píxeles
		var snapped_pos = mouse_pos.snapped(Vector2(50, 50))
		
		# Convertimos a "unidades de juego" (dividiendo para 100)
		var game_coords = snapped_pos / 100.0
		coords_label.text = "Coordenadas Grid: " + str(game_coords)
		
		coords_label.global_position = mouse_pos + Vector2(20, 20)

func copiar_coordenadas_al_portapapeles() -> void:
	var mouse_pos = get_global_mouse_position()
	var snapped_pos = mouse_pos.snapped(Vector2(50, 50))
	var game_coords = snapped_pos / 100.0
	
	# Formateamos el texto exactamente como se escribe en código
	var texto_a_copiar = "Vector2" + str(game_coords)
	
	# Esta es la función mágica de Godot 4
	DisplayServer.clipboard_set(texto_a_copiar)
	
	# Feedback visual opcional: Cambiar el color del label un momento o imprimir en consola
	if coords_label:
		coords_label.modulate = Color.GREEN # Se pone verde un segundo
		get_tree().create_timer(0.2).timeout.connect(func(): coords_label.modulate = Color.WHITE)
