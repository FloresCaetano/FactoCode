extends Tutorial

@onready var drones : Array = get_tree().get_nodes_in_group("drone")

var movements_completed : int = 0

var narrator_lines : Array[String] = [
	"Ahora que la torreta esta operativa vamos a construir una barrera para proteger la base. Para eso, usaremos la función build(). Esta función necesita el nombre de la estructura a construir (String) y la coordenada donde construirla (Vector2). Construye la barrera en el punto (-10, -6).",
    "Tarea: Escribir build(\"barrera\", Vector2(-10, -10))",
    "Como vez, no dispones de material suficiente para construir la barrera. Necesitamos extraer mas mineral marron para poder construirla. Extrae 5 unidades del mineral marron en la veta cerca de la base",
    "Pero vamos a hacer algo diferente, esta vez quiero que extraigas el mineral y luego construyas la barrera sin tener que ejecutar el codigo 2 veces, para eso vamos a usar condicionales.",
    "Los condicionales son estructuras de control que nos permiten ejecutar ciertas partes del código solo si se cumplen ciertas condiciones. En este caso, queremos que el dron extraiga el mineral y luego construya la barrera solo si en base existen al menos 5 de mineral marron.",
    "Para eso, vamos a usar la función if. Esta función nos permite ejecutar un bloque de código solo si se cumple una condición. La sintaxis es la siguiente: if condición: bloque de código. En nuestro caso, la condición sería algo así como: if drone.has_material(\"mineral_marron\") >= 5:",
    "Y el bloque de código sería el código para extraer el mineral y construir la barrera. Recuerda que el bloque de código debe estar indentado (con tabulaciones o espacios) para que el dron sepa que pertenece al if.",
    "Tarea: Escribir if base.has_material(\"mineral_marron\") >= 5: \n\tbuild(\"barrera\", Vector2(-10, -10)) \nelse:\n\textract()"
]

func _ready() -> void:
	await get_tree().process_frame
	load_tutorial()
	PATHS.narrator.start_dialog(narrator_lines)
	for drone in drones:
		drone.build_finished.connect(check_build_finished)

var completed_first_movement : bool = false

func check_build_finished(structure_name : String, grid_coords : Vector2) -> void:
	if structure_name == "barrera" and grid_coords == Vector2(-10, -10):
		PATHS.narrator.start_dialog([
			"Increible!, ahora ya sabes usar condicionales para que el dron ejecute diferentes acciones dependiendo de la situación. Esto es fundamental para poder enfrentar el desafio de combate, donde tendrás que tomar decisiones en tiempo real para proteger la base.",
            "Estas un paso mas cerca de la automatizacion total de la base, pero antes de eso, vamos a aprender a usar bucles para poder repetir acciones sin tener que escribir el mismo código una y otra vez."
		])
		tutorial_completed()