extends Tutorial

@onready var drones : Array = get_tree().get_nodes_in_group("drone")

var narrator_lines : Array[String] = [
	"Un bucle for doble te permite recorrer una grilla y crear estructuras con grosor.",
	"Vamos a construir una barrera de 2 de grosor y 5 de largo (5x2).",
	"Tarea: Escribir un for doble: for x in range(5) y dentro for y in range(2), construyendo en Vector2(-12 + x, -14 + y)."
]

var required_coords : Array[Vector2] = []
var built_coords : Array[Vector2] = []

func _ready() -> void:
	await get_tree().process_frame
	for x in range(5):
		for y in range(2):
			required_coords.append(Vector2(-12 + x, -14 + y))
	PATHS.narrator.start_dialog(narrator_lines)
	for drone in drones:
		drone.build_finished.connect(check_build_finished)

func check_build_finished(structure_name : String, grid_coords : Vector2) -> void:
	if structure_name != "barrera":
		return
	if required_coords.has(grid_coords) and not built_coords.has(grid_coords):
		built_coords.append(grid_coords)
	if built_coords.size() == required_coords.size():
		PATHS.narrator.start_dialog([
			"Gran trabajo. Ya sabes usar bucles anidados para construir estructuras con grosor.",
			"Con esto completas la introduccion a bucles."
		])
