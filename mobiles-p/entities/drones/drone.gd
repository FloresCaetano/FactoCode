class_name Drone
extends StaticBody2D
@onready var gpuparticles_2d: GPUParticles2D = $GPUParticles2D
@onready var code_edit: CodeEdit = $Vbox/CodeEdit

@export var speed : float = 300
@export var progress_bar: ProgressBar
@export var feedback_line: RichTextLabel

var extract_delay : float = 3.0
var extract_amount : int = 1

var vars = {}

#SIGNALS
signal move_finished(to : Vector2)
signal build_finished(structure_name : String, at : Vector2)
signal extract_finished(from : Vector2)

func _ready() -> void:
	progress_bar.visible = false
	setup_highlighter()

func run_drone_program(code: String, target_drone: Node2D):
	#var script = await PythonTranspiler.transpilar(code)
	var script = ExperimentalTranspiler.transpilar(code, "drone")
	
	# Mostrar retroalimentación
	if ExperimentalTranspiler.last_status == "success":
		feedback_line.text = "[color=green]" + ExperimentalTranspiler.last_feedback + "[/color]"
	else:
		var error_msg = ExperimentalTranspiler.last_feedback
		if ExperimentalTranspiler.last_error_line > 0:
			error_msg = "Línea " + str(ExperimentalTranspiler.last_error_line) + ": " + error_msg
		feedback_line.text = "[color=red]" + error_msg + "[/color]"
	
	if script == null:
		return
	
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
	
	# funciones del drone
	code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, "move", "move(grid_coords : Vector2)", Color.AQUAMARINE)
	code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, "build", "build(structure_name : String, grid_coords : Vector2)", Color.AQUAMARINE)
	code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, "extract", "extract(grid_coords : Vector2, amount : int)", Color.AQUAMARINE)
	code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, "base.has_material", "base.has_material(\"brown_mineral\")", Color.AQUAMARINE)
	
	# parametros de las funciones
	code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, "grid_coords", "grid_coords", Color.CHARTREUSE)
	code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, "structure_name", "structure_name", Color.CHARTREUSE)
	code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, "amount", "amount", Color.CHARTREUSE)
	
	code_edit.update_code_completion_options(false)

func setup_highlighter():
	var highlighter = CodeHighlighter.new()
	
	# color de los simbolos (esto pintara los :, (, ), =, etc.)
	highlighter.symbol_color = Color.AQUAMARINE # o el color que prefieras
	
	# palabras clave
	highlighter.add_keyword_color("if", Color.GREEN_YELLOW)
	highlighter.add_keyword_color("elif", Color.GREEN_YELLOW)
	highlighter.add_keyword_color("else", Color.GREEN_YELLOW)
	highlighter.add_keyword_color("Vector2", Color.RED)
	highlighter.add_keyword_color("return", Color.RED)
	
	highlighter.add_keyword_color("for", Color.ORANGE)
	highlighter.add_keyword_color("while", Color.ORANGE)
	
	# parametros
	highlighter.add_keyword_color("move()", Color.CHARTREUSE)
	highlighter.add_keyword_color("build()", Color.CHARTREUSE)
	highlighter.add_keyword_color("extract()", Color.CHARTREUSE)
	highlighter.add_keyword_color("base", Color.CHARTREUSE)
	highlighter.add_keyword_color("has_material", Color.CHARTREUSE)
	
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
	move_finished.emit(pixel_coords)

func build(structure_name : String, grid_coords: Vector2):
	var pixel_coords : Vector2 = grid_coords * 100.0
	
	if not PATHS.core.craft_structure(structure_name):
		feedback_line.text = "[color=red]No tienes los recursos necesarios para construir " + structure_name + "[/color]"
		return

	var structure_uid : String = ""
	match  structure_name:
		"turret":
			structure_uid = GLOBAL.PATHS.p_turret
		"barrier":
			structure_uid = GLOBAL.PATHS.p_barrier
	
	var structure : StaticBody2D = load(structure_uid).instantiate()
	
	move(grid_coords)
	await move_finished
	
	add_sibling(structure)
	structure.global_position = pixel_coords
	
	build_finished.emit(structure_name, grid_coords)

func extract(grid_coords: Vector2, amount: int):
	progress_bar.value = 0
	progress_bar.visible = true

	var pixel_coords : Vector2 = grid_coords * 100.0
	await move(grid_coords)
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pixel_coords
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result = space_state.intersect_point(query)
	
	if result.size() > 0:
		
		var collider = result[0].collider

		if collider is Mineral:
			for i in amount:
				progress_bar.value = 0
				var tween : Tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.tween_property(progress_bar, "value", 100, extract_delay)
				await tween.finished
				collider.extract_mineral(extract_amount)
				
			progress_bar.visible = false
			extract_finished.emit(grid_coords)

func _on_button_pressed() -> void:
	run_drone_program(code_edit.text, self)

func _on_control_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if $Vbox.visible == false:
			$Vbox.visible = true
		else:
			$Vbox.visible = false

func shoot_particles():
	gpuparticles_2d.restart()