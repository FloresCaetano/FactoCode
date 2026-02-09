extends Node

@onready var drones : Array = get_tree().get_nodes_in_group("drone")

var movements_completed : int = 0

var narrator_lines : Array[String] = [
	"Excelente. El dron está funcionando, pero no tenemos materiales para construir defensas. Hay una veta de mineral azul cerca de la base",
	"Necesitamos que el dron extraiga el mineral para poder construir defensas. Para eso, usaremos la función extract().",
	"Esta función también necesita una mochila de datos. En este caso, la coordenada del mineral (Vector2) y la cantidad a extraer (int). La veta de mineral azul está en el punto (2, -1) y necesitamos 5 unidades para construir una defensa básica.",
	"Tarea: Escribir extract(Vector2(2, -1), 5)"
]

func _ready() -> void:
	await get_tree().process_frame
	PATHS.narrator.start_dialog(narrator_lines)
	for drone in drones:
		drone.extract_finished.connect(check_extract_finished)
		drone.build_finished.connect(check_build_finished)

var completed_first_movement : bool = false

func check_extract_finished(grid_coords : Vector2) -> void:
	if grid_coords == Vector2(2, -1):
		PATHS.narrator.start_dialog([
			"¡Perfecto! Has extraído el mineral necesario para construir defensas. Ahora, para proteger la base, necesitamos construir una torreta de defensa básica.",
			"Para eso, usaremos la función build(). Esta función necesita el nombre de la estructura a construir (String) y la coordenada donde construirla (Vector2). Construye la torreta en el punto (1, 0).",
			"Tarea: Escribir build(\"torreta\", Vector2(-10, -6))"
		])

func check_build_finished(structure_name : String, grid_coords : Vector2) -> void:
	if structure_name == "torreta" and grid_coords == Vector2(-10, -6):
		PATHS.narrator.start_dialog([
			"¡Excelente trabajo, Ingeniero! Has construido tu primera defensa. Ahora estás listo para fortificar la base."
		])