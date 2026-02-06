extends Node

const BASE_TEMPLATE = """
extends Node

var drone # Referencia al dron

func _run_code():
{USER_CODE}
"""

func transpilar(user_text: String) -> GDScript:
	# 1. LIMPIEZA DE INDENTACIÓN (Evita el error de Mixed Tabs/Spaces)
	# Convertimos 4 espacios en un Tab y nos aseguramos de que no haya espacios sueltos al inicio
	var clean_text = user_text.replace("    ", "\t") 
	
	var lines = clean_text.split("\n")
	var processed_lines = []
	
	var drone_actions = ["move", "build", "rotate", "scan"] 
	
	for line in lines:
		# Ignorar líneas vacías para no meter tabs innecesarios
		if line.strip_edges() == "":
			processed_lines.append("")
			continue
			
		var final_line = line
		
		# 2. Reemplazos de Keywords
		final_line = final_line.replace("True", "true").replace("False", "false").replace("None", "null")
		
		# 3. Inyectar Awaits y Referencias
		for action in drone_actions:
			var pattern = action + "("
			if pattern in final_line:
				if "drone." in final_line:
					if not "await " in final_line:
						final_line = final_line.replace("drone.", "await drone.")
				else:
					final_line = final_line.replace(pattern, "await drone." + pattern)
		
		# 4. Forzar un tabulador extra para que quede dentro de _run_code()
		# Usamos siempre \t para coincidir con el template
		processed_lines.append("\t" + final_line)
	
	var full_code = BASE_TEMPLATE.replace("{USER_CODE}", "\n".join(processed_lines))
	
	# Debug opcional: ver en consola el código final para chequear tabs
	# print(full_code.replace("\t", "[TAB]")) 
	
	var script = GDScript.new()
	script.source_code = full_code
	
	var err = script.reload()
	if err != OK:
		push_error("Error de sintaxis en el código del usuario. Código error: " + str(err))
		
	return script
