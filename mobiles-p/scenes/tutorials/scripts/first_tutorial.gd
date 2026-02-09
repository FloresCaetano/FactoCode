extends Tutorial

@onready var drones : Array = get_tree().get_nodes_in_group("drone")

var movements_completed : int = 0

var narrator_lines : Array[String] = [
	"Conexión establecida, Ingeniero. Mi nombre es OMNIS y seré tu interfaz de control. El núcleo de la base está en reserva; para reactivarlo, necesitamos que el dron de servicio se posicione en la plataforma de carga.",
	"En programación, enviamos órdenes mediante 'Funciones'. Una función es un nombre seguido de paréntesis. Piensa en los paréntesis como la 'mochila' donde guardas la información que el dron necesita para cumplir la orden.",
	"Para mover al dron, usamos la función move. Dentro de su mochila de datos, debemos poner una coordenada tipo Vector2(x, y). El nucleo esta en el punto (0, 0)",
	"Tarea: Escribir move(Vector2(0, 0))",
]

func _ready() -> void:
	await get_tree().process_frame
	load_tutorial()
	PATHS.narrator.start_dialog(narrator_lines)
	for drone in drones:
		drone.move_finished.connect(check_drone_moved)

var completed_first_movement : bool = false

func check_drone_moved(to : Vector2) -> void:
	if completed_first_movement:
		movements_completed += 1
	
	if movements_completed == 3:
		for drone in drones: drone.shoot_particles()
		PATHS.narrator.start_dialog([
            "¡Perfecto! Has completado el tutorial de movimiento. Ahora estás listo para enfrentar el desafio de construccion"
		])
		tutorial_completed()
		return
	
	if to == Vector2(0,0):
		completed_first_movement = true
		PATHS.narrator.start_dialog([
			"¡Excelente trabajo, Ingeniero!",
            "Para asegurarme de que lo haz comprendido adecuadamente, necesito que muevas el dron de servicio 3 veces"
		])
	
