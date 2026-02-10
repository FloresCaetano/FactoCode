extends Tutorial

@onready var drones : Array = get_tree().get_nodes_in_group("drone")

var narrator_lines : Array[String] = [
	"Los bucles for sirven para repetir una accion un numero fijo de veces.",
	"Vamos a construir una barrera de 10 de largo con un solo bucle for.",
	"Tarea: Escribir un for i in range(10) que construya barrera en Vector2(-8 + i, 11).",
	"para esto escribe: \nfor i in range(10): \n\tbuild(\"barrier\", Vector2(-8 + i, 11))"
]

var required_coords : Array[Vector2] = []
var built_coords : Array[Vector2] = []

func _ready() -> void:
	await get_tree().process_frame
	load_tutorial()

	for i in range(10):
		required_coords.append(Vector2(-8 + i, 11))
	PATHS.narrator.start_dialog(narrator_lines)
	for drone in drones:
		drone.build_finished.connect(check_build_finished)

func check_build_finished(structure_name : String, grid_coords : Vector2) -> void:
	if structure_name != "barrier":
		return
	if required_coords.has(grid_coords) and not built_coords.has(grid_coords):
		built_coords.append(grid_coords)
	if built_coords.size() == required_coords.size():
		PATHS.narrator.start_dialog([
			"Excelente. Con un for puedes crear estructuras en linea de forma rapida.",
			"Ahora aprenderemos a usar un for doble para crear una barrera con grosor."
		])
		tutorial_completed()
