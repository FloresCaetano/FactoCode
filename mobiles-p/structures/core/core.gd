class_name Core
extends Structure

@export var code_edit: CodeEdit
@export var feedback_line: RichTextLabel
@onready var craft_drone_delay: Timer = $CraftDroneDelay

func _ready() -> void:
    PATHS.core = self
    setup_highlighter()

var inventory : Dictionary = {
    GLOBAL.mineral_names[0]: 100,
    GLOBAL.mineral_names[1]: 100,
    "turrets": 0,
    "barriers": 0
}
var vars = {}

var last_drone_built_position : Vector2 = global_position

func craft_drone() -> void:
    if inventory[GLOBAL.mineral_names[0]] < 1 or inventory[GLOBAL.mineral_names[1]] < 1:
        return

    if not craft_drone_delay.is_stopped():
        await craft_drone_delay.timeout

    craft_drone_delay.start()
    await craft_drone_delay.timeout

    if inventory[GLOBAL.mineral_names[0]] >= 1 and inventory[GLOBAL.mineral_names[1]] >= 1:
        inventory[GLOBAL.mineral_names[0]] -= 1
        inventory[GLOBAL.mineral_names[1]] -= 1
        var drone_scene : PackedScene = load("res://entities/drones/drone.tscn")
        var drone : Node2D = drone_scene.instantiate()
        add_child(drone)
        drone.global_position = global_position + Vector2(0, -300)
        
        var space_state = get_world_2d().direct_space_state
        var query = PhysicsPointQueryParameters2D.new()
        query.position = last_drone_built_position
        query.collide_with_areas = false
        query.collide_with_bodies = true
        var result = space_state.intersect_point(query)
        if result.size() > 0:
            var collider = result[0].collider
            if collider is Drone:
                drone.global_position = collider.global_position + Vector2(0, -100)
        
        last_drone_built_position = drone.global_position

func craft_structure(structure_name : String) -> bool:
    match structure_name:
        "torreta":
            if inventory[GLOBAL.mineral_names[0]] >= 2:
                inventory[GLOBAL.mineral_names[0]] -= 2
                inventory["turrets"] += 1
                return true
        "barrera":
            if inventory[GLOBAL.mineral_names[1]] >= 2:
                inventory[GLOBAL.mineral_names[1]] -= 2
                inventory["barriers"] += 1
                return true
    
    return false

func run_core_program(code: String, target_core: Node2D):
    var script = ExperimentalTranspiler.transpilar(code, "core")
    
    # Mostrar retroalimentación
    if PythonTranspiler.last_status == "success":
        feedback_line.text = "[color=green]" + PythonTranspiler.last_feedback + "[/color]"
    else:
        var error_msg = PythonTranspiler.last_feedback
        if PythonTranspiler.last_error_line > 0:
            error_msg = "Línea " + str(PythonTranspiler.last_error_line) + ": " + error_msg
        feedback_line.text = "[color=red]" + error_msg + "[/color]"
    
    if script == null:
        return
    
    var brain = Node.new()
    brain.set_script(script)
    
    # IMPORTANTE: Asignar la referencia antes de añadirlo al árbol
    brain.core = target_core
    
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
    
    # booleanos y nulos
    code_edit.add_code_completion_option(CodeEdit.KIND_CONSTANT, "True", "True", Color.LIGHT_BLUE)
    code_edit.add_code_completion_option(CodeEdit.KIND_CONSTANT, "False", "False", Color.LIGHT_BLUE)
    code_edit.add_code_completion_option(CodeEdit.KIND_CONSTANT, "None", "None", Color.LIGHT_BLUE)

    # utilidades basicas
    code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, "print", "print()", Color.LIGHT_CORAL)
    
    # funciones del core
    code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, "craft_drone", "craft_drone()", Color.AQUAMARINE)
    
    code_edit.update_code_completion_options(false)

func setup_highlighter():
    var highlighter = CodeHighlighter.new()
    
    # color de los simbolos (esto pintara los :, (, ), =, etc.)
    highlighter.symbol_color = Color.AQUAMARINE
    
    # palabras clave
    highlighter.add_keyword_color("if", Color.GREEN_YELLOW)
    highlighter.add_keyword_color("elif", Color.GREEN_YELLOW)
    highlighter.add_keyword_color("else", Color.GREEN_YELLOW)
    highlighter.add_keyword_color("return", Color.RED)
    
    highlighter.add_keyword_color("for", Color.ORANGE)
    highlighter.add_keyword_color("while", Color.ORANGE)
    
    # funciones del core
    highlighter.add_keyword_color("craft_drone()", Color.CHARTREUSE)
    
    # numeros y strings
    highlighter.number_color = Color.LIGHT_CORAL
    highlighter.add_color_region('"', '"', Color.YELLOW)
    
    # comentarios
    highlighter.add_color_region("#", "", Color.GRAY)
    
    code_edit.syntax_highlighter = highlighter

func _on_button_pressed() -> void:
    run_core_program(code_edit.text, self)

func _on_control_gui_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        if $Vbox.visible == false:
            $Vbox.visible = true
        else:
            $Vbox.visible = false


