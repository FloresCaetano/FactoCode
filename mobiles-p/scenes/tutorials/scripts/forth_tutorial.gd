extends Tutorial

@onready var drones : Array = get_tree().get_nodes_in_group("drone")

var narrator_lines : Array[String] = [
	"Vamos a usar un bucle while para automatizar la recoleccion. La idea es crear un bucle infinito y revisar dentro si falta material.",
	"Si falta mineral marron, el dron debe minar automaticamente.",
	"Sintaxis base: while True: bloque_de_codigo (recuerda la indentacion).",
	"Tarea: Escribir un bucle while True que revise si base.has_material(\"brown_mineral\") < 55 y, si falta, haga extract(Vector2(-5, 3), 5)."
]

var target_build_coords : Vector2 = Vector2(-12, -10)

func _ready() -> void:
	await get_tree().process_frame
	load_tutorial()
	PATHS.narrator.start_dialog(narrator_lines)
	for drone in drones:
		drone.extract_finished.connect(check_extract_finished)

func check_extract_finished(_grid_coords : Vector2) -> void:
	if PATHS.core.inventory["brown_mineral"] >= 55:
		PATHS.narrator.start_dialog([
			"¡Perfecto! Has extraído el mineral necesario para construir mas drones"
		])
		tutorial_completed()
