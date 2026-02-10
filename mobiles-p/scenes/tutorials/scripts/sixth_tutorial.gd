extends Tutorial

@onready var drones : Array = get_tree().get_nodes_in_group("drone")

var narrator_lines : Array[String] = [
	"Un bucle for doble te permite recorrer una grilla y crear estructuras con grosor.",
	"Vamos a construir una barrera de 2 de grosor y 10 de largo (10x2).",
	"Tarea: Escribir un for doble: for x in range(10) y dentro for y in range(2), construyendo en Vector2(-9 + x, -5 + y)."
]

var required_coords : Array[Vector2] = []
var built_coords : Array[Vector2] = []

func _ready() -> void:
	await get_tree().process_frame
	load_tutorial()
	for x in range(10):
		for y in range(2):
			required_coords.append(Vector2(-9 + x, -5 + y))
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
			"Gran trabajo. Ya sabes usar bucles anidados para construir estructuras con grosor.",
			"Con esto completas la introduccion a bucles.",
			"recuerda que puedes crear mas drones en la base para automatizar la recoleccion de materiales y la construccion de defensas",
			"Para esto prueba abrir el menu de la base y crear un dron con craft_drone(), toda la logica que haz aprendido hasta ahora puede ser aplicada al codigo en la base",
			"Estas listo para iniciar la primera oleada, preparate cuanto necesites y cuando estes listo, inicia la oleada"
		])
		tutorial_completed()
