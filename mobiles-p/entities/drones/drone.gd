extends Node2D

@onready var code_edit: CodeEdit = $Vbox/CodeEdit

@export var speed : float = 300

#SIGNALS
signal move_finished
signal build_finished

func _ready() -> void:
	setup_highlighter()

func run_drone_program(code: String, target_drone: Node2D):
	var script = PythonTranspiler.transpilar(code)
	var brain = Node.new()
	brain.set_script(script)
	
	# IMPORTANTE: Asignar la referencia antes de añadirlo al árbol
	brain.drone = target_drone 
	
	add_child(brain)
	await brain._run_code()
	brain.queue_free()

func _on_code_edit_code_completion_requested() -> void:
	# estructuras de condicion
	code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, "if", "if :", Color.GREEN_YELLOW)
	code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, "elif", "elif :", Color.GREEN_YELLOW)
	code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, "else", "else:", Color.GREEN_YELLOW)
	
	# bucles (loops)
	code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, "for", "for i in range():", Color.ORANGE)
	code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, "while", "while :", Color.ORANGE)
	
	# funciones y retorno
	code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, "def", "def ():", Color.AQUAMARINE)
	code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, "return", "return ", Color.AQUAMARINE)
	
	# booleanos y nulos (estos suelen ir en otro color)
	code_edit.add_code_completion_option(CodeEdit.KIND_CONSTANT, "True", "True", Color.LIGHT_BLUE)
	code_edit.add_code_completion_option(CodeEdit.KIND_CONSTANT, "False", "False", Color.LIGHT_BLUE)
	code_edit.add_code_completion_option(CodeEdit.KIND_CONSTANT, "None", "None", Color.LIGHT_BLUE)

	# utilidades basicas
	code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, "print", "print()", Color.LIGHT_CORAL)
	
	code_edit.update_code_completion_options(false)

func setup_highlighter():
	var highlighter = CodeHighlighter.new()
	
	# color de los simbolos (esto pintara los :, (, ), =, etc.)
	highlighter.symbol_color = Color.AQUAMARINE # o el color que prefieras
	
	# palabras clave
	highlighter.add_keyword_color("if", Color.GREEN_YELLOW)
	highlighter.add_keyword_color("elif", Color.GREEN_YELLOW)
	highlighter.add_keyword_color("else", Color.GREEN_YELLOW)
	
	highlighter.add_keyword_color("for", Color.ORANGE)
	highlighter.add_keyword_color("while", Color.ORANGE)
	
	# numeros y strings
	highlighter.number_color = Color.LIGHT_CORAL
	highlighter.add_color_region('"', '"', Color.YELLOW)
	
	# comentarios
	highlighter.add_color_region("#", "", Color.GRAY)
	
	code_edit.syntax_highlighter = highlighter

func move(grid_coords: Vector2):
	var pixel_coords = grid_coords * 100.0
	var distance = global_position.distance_to(pixel_coords)
	var time : float = distance / speed
	
	var tween : Tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await tween.tween_property(self, "global_position", pixel_coords, time).finished
	move_finished.emit()

func build(structure_name : String, grid_coords: Vector2):
	var pixel_coords : Vector2 = grid_coords * 100.0
	
	var structure_uid : String = ""
	match  structure_name:
		"torreta":
			structure_uid = GLOBAL.PATHS.p_turret
		"barrera":
			structure_uid = GLOBAL.PATHS.p_barrier
	
	var structure : StaticBody2D = load(structure_uid).instantiate()
	
	move(grid_coords)
	await move_finished
	
	add_sibling(structure)
	structure.global_position = pixel_coords
	
	build_finished.emit()

func _on_button_pressed() -> void:
	run_drone_program(code_edit.text, self)

func _on_control_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if $Vbox.visible == false:
			$Vbox.visible = true
		else:
			$Vbox.visible = false
