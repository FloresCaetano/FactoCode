extends Tutorial

@onready var drones : Array = get_tree().get_nodes_in_group("drone")

var narrator_lines : Array[String] = [
	"Vamos a usar un bucle while para automatizar la recoleccion. La idea es crear un bucle infinito y revisar dentro si falta material.",
	"Si falta mineral marron, el dron debe minar automaticamente. Si ya hay suficiente, construira una barrera.",
	"Sintaxis base: while True: bloque_de_codigo (recuerda la indentacion).",
	"Tarea: Escribir un bucle while True que revise si base.has_material(\"brown_mineral\") < 5 y, si falta, haga extract(Vector2(-5, 3), 5). Si no falta, que haga build(\"barrera\", Vector2(-12, -10))."
]

var target_build_coords : Vector2 = Vector2(-12, -10)

func _ready() -> void:
	await get_tree().process_frame
	PATHS.narrator.start_dialog(narrator_lines)
	for drone in drones:
		drone.build_finished.connect(check_build_finished)

func check_build_finished(structure_name : String, grid_coords : Vector2) -> void:
	if structure_name == "barrera" and grid_coords == target_build_coords:
		PATHS.narrator.start_dialog([
			"Perfecto. Ese bucle while mantiene la base abastecida y automatiza la decision de minar o construir.",
			"Ahora aprenderemos a usar bucles for para repetir acciones con un rango definido."
		])
