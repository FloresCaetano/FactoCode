class_name CodeTranspiler
extends Node

const BASE_TEMPLATE = """
extends Node

var drone # Referencia al dron

func _run_code():
{USER_CODE}
"""

# Lista negra de seguridad
const SECURITY_BLACKLIST = [
	"OS.",
	"FileAccess",
	"load(",
	"preload(",
	"get_tree().change_scene",
	"queue_free",
	"ClassDB",
	"Engine."
]

# Funciones permitidas del drone
const DRONE_FUNCTIONS = ["move", "build", "extract"]
const ALLOWED_FUNCTIONS = ["print", "range", "len", "int", "float", "str", "abs", "min", "max"]

var _compiled_script: GDScript = null
var last_status: String = ""
var last_feedback: String = ""
var last_error_line: int = -1

func transpilar(user_text: String) -> GDScript:
	var result = transpile(user_text)
	
	# Guardar información de retroalimentación
	if result.success:
		last_status = "success"
		last_feedback = "Código transpilado exitosamente"
		last_error_line = -1
	else:
		last_status = "error"
		last_feedback = result.error
		last_error_line = result.error_line
	
	if result.success:
		# Insertar el código transpilado en el BASE_TEMPLATE
		# Agregar indentación al código compilado
		var compiled_code = result.code
		var lines = compiled_code.split("\n")
		var indented_lines = []
		for line in lines:
			if line.strip_edges() == "":
				indented_lines.append("")
			else:
				indented_lines.append("\t" + line)
		var indented_code = "\n".join(indented_lines)
		
		var full_code = BASE_TEMPLATE.replace("{USER_CODE}", indented_code)
		
		var script = GDScript.new()
		script.source_code = full_code
		
		var err = script.reload()
		if err != OK:
			push_error("Error de sintaxis en el código compilado. Código de error: " + str(err))
			last_status = "error"
			last_feedback = "Error de sintaxis en el código compilado"
			return null
		
		_compiled_script = script
		return script
	else:
		push_error("Error de transpilación: " + result.error)
		return null

func transpile(source_code: String) -> Dictionary:
	var result = {
		"success": false,
		"code": "",
		"error": "",
		"error_line": -1
	}
	
	if source_code.strip_edges().is_empty():
		result.error = "El código está vacío"
		return result
	
	# Validar strings cerrados
	var string_check = validate_strings(source_code)
	if not string_check.success:
		result.error = string_check.error
		result.error_line = string_check.line
		return result
	
	# Validar paréntesis balanceados
	var paren_check = validate_parentheses(source_code)
	if not paren_check.success:
		result.error = paren_check.error
		result.error_line = paren_check.line
		return result
	
	var lines = source_code.split("\n")
	var transpiled_lines = []
	var control_stack = []  # Para rastrear estructuras anidadas
	
	for line_num in range(lines.size()):
		var line = lines[line_num]
		var line_number = line_num + 1
		
		# Líneas vacías se mantienen
		if line.strip_edges().is_empty():
			transpiled_lines.append("")
			continue
		
		# Comentarios se mantienen
		if line.strip_edges().begins_with("#"):
			transpiled_lines.append(line)
			continue
		
		# Detectar indentación
		var indent_level = get_indent_level(line)
		var stripped = line.strip_edges()
		
		# Verificar indentación consistente
		if indent_level % 4 != 0 and indent_level > 0:
			result.error = "Indentación inconsistente (debe ser múltiplo de 4 espacios o tabs)"
			result.error_line = line_number
			return result
		
		# Convertir indentación a tabs
		var tabs = "\t".repeat(indent_level / 4)
		
		# Procesar la línea según su tipo
		var processed = process_line(stripped, line_number)
		if not processed.success:
			result.error = processed.error
			result.error_line = line_number
			return result
		
		# Detectar si estamos entrando en una estructura de control
		var is_loop = stripped.begins_with("while ") or stripped.begins_with("for ")
		
		if is_loop:
			control_stack.push_back({"type": "loop", "indent": indent_level})
			transpiled_lines.append(tabs + processed.code)
			# Añadir await para evitar bloqueos en loops
			transpiled_lines.append(tabs + "\t" + "await drone.get_tree().create_timer(0.01).timeout")
		elif stripped.begins_with("if ") or stripped.begins_with("elif ") or stripped.begins_with("else"):
			# No necesitan await
			transpiled_lines.append(tabs + processed.code)
		else:
			# Verificar si salimos de una estructura de control
			while control_stack.size() > 0 and indent_level <= control_stack.back()["indent"]:
				control_stack.pop_back()
			
			transpiled_lines.append(tabs + processed.code)
		
	
	var final_code = "\n".join(transpiled_lines)
	
	# Validar seguridad
	var security_check = check_security(final_code)
	if not security_check.success:
		result.error = security_check.error
		return result
	
	result.success = true
	result.code = final_code
	return result

func process_line(line: String, _line_number: int) -> Dictionary:
	var result = {"success": false, "code": "", "error": ""}
	
	# If/Elif/Else
	if line.begins_with("if "):
		var condition = line.substr(3).trim_suffix(":")
		var transformed = transform_expression(condition)
		result.code = "if " + transformed + ":"
		result.success = true
		return result
	
	if line.begins_with("elif "):
		var condition = line.substr(5).trim_suffix(":")
		var transformed = transform_expression(condition)
		result.code = "elif " + transformed + ":"
		result.success = true
		return result
	
	if line.begins_with("else"):
		result.code = "else:"
		result.success = true
		return result
	
	# While
	if line.begins_with("while "):
		var condition = line.substr(6).trim_suffix(":")
		var transformed = transform_expression(condition)
		result.code = "while " + transformed + ":"
		result.success = true
		return result
	
	# For
	if line.begins_with("for "):
		var for_part = line.trim_suffix(":")
		result.code = for_part + ":"
		result.success = true
		return result
	
	# Funciones del drone (move, build, extract)
	for func_name in DRONE_FUNCTIONS:
		if line.begins_with(func_name + "("):
			var transformed = transform_drone_function(line, func_name)
			if transformed.success:
				result = transformed
				return result
			else:
				return transformed
	
	# Print
	if line.begins_with("print("):
		var args = extract_function_args(line, "print")
		var transformed_args = transform_expression(args)
		result.code = "drone.print(" + transformed_args + ")"
		result.success = true
		return result
	
	# Declaración con var (GDScript)
	if line.begins_with("var "):
		var without_var = line.substr(4).strip_edges()
		var transformed = transform_assignment(without_var)
		if transformed.success:
			result = transformed
			return result
		else:
			return transformed
	
	# Asignación o operación con asignación
	if "=" in line:
		var transformed = transform_assignment(line)
		if transformed.success:
			result = transformed
			return result
		else:
			return transformed
	
	# Llamadas a funciones genéricas
	if "(" in line and ")" in line:
		var func_name = line.substr(0, line.find("("))
		if func_name in ALLOWED_FUNCTIONS:
			result.code = line
			result.success = true
			return result
		else:
			result.error = "Función no permitida: " + func_name
			return result
	
	# Línea no reconocida o expresión simple
	result.code = transform_expression(line)
	result.success = true
	return result

func transform_drone_function(line: String, func_name: String) -> Dictionary:
	var result = {"success": false, "code": "", "error": ""}
	var args = extract_function_args(line, func_name)
	
	match func_name:
		"move":
			# move(Vector2(...))
			var transformed_args = transform_expression(args)
			result.code = "drone.move(" + transformed_args + "); await drone.move_finished"
		
		"build":
			# build("nombre", Vector2(...))
			var parts = split_args(args)
			if parts.size() == 2:
				var _name = parts[0]
				var pos = transform_expression(parts[1])
				result.code = "drone.build(" + _name + ", " + pos + "); await drone.build_finished"
			else:
				result.error = "build() requiere 2 argumentos (nombre, Vector2)"
				return result
		
		"extract":
			# extract(Vector2(...), cantidad)
			var parts = split_args(args)
			if parts.size() == 2:
				var pos = transform_expression(parts[0])
				var cantidad = transform_expression(parts[1])
				result.code = "drone.extract(" + pos + ", " + cantidad + "); await drone.extract_finished"
			else:
				result.error = "extract() requiere 2 argumentos (Vector2, cantidad)"
				return result
	
	result.success = true
	return result

func transform_assignment(line: String) -> Dictionary:
	var result = {"success": false, "code": "", "error": ""}
	
	# Detectar el tipo de operador de asignación
	var operators = ["+=", "-=", "*=", "/=", "="]
	var operator = ""
	var var_name = ""
	var value = ""
	
	for op in operators:
		if op in line:
			var parts = line.split(op, false, 1)
			if parts.size() == 2:
				operator = op
				var_name = parts[0].strip_edges()
				value = parts[1].strip_edges()
				break
	
	if operator.is_empty():
		result.error = "Asignación mal formada"
		return result
	
	# Verificar que el nombre de variable es válido
	if not is_valid_variable_name(var_name):
		result.error = "Nombre de variable inválido: " + var_name
		return result
	
	# Transformar el valor
	var transformed_value = transform_expression(value)
	
	# Generar código
	if operator == "=":
		result.code = 'drone.vars["' + var_name + '"] = ' + transformed_value
	else:
		result.code = 'drone.vars["' + var_name + '"] ' + operator + ' ' + transformed_value
	
	result.success = true
	return result

func transform_expression(expr: String) -> String:
	# Transformar variables a acceso al diccionario
	expr = expr.strip_edges()
	
	# Si es un literal (número, string, booleano), no transformar
	if is_literal(expr):
		return expr
	
	# Si contiene llamadas a funciones, procesarlas
	if "(" in expr:
		# Transformar llamadas a funciones dentro de la expresión
		var regex = RegEx.new()
		regex.compile(r"\b([a-zA-Z_][a-zA-Z0-9_]*)\s*\(")
		var matches = regex.search_all(expr)
		for match in matches:
			var func_name = match.get_string(1)
			if func_name not in ALLOWED_FUNCTIONS:
				# Podría ser una variable que se está llamando, mantener como está
				pass
		return expr
	
	# Transformar operadores y variables
	var tokens = tokenize_expression(expr)
	var result = ""
	
	for i in range(tokens.size()):
		var token = tokens[i]
		var transformed = ""
		
		if is_literal(token) or is_operator(token):
			transformed = token
		elif is_keyword(token):
			transformed = token
		else:
			# Verificar si el token contiene acceso a propiedades (punto)
			if "." in token:
				var parts = token.split(".", false, 1)
				var var_name = parts[0]
				var property = parts[1] if parts.size() > 1 else ""
				
				if is_valid_variable_name(var_name):
					# Es una variable con propiedad: variable.x -> drone.vars["variable"].x
					transformed = 'drone.vars["' + var_name + '"].' + property
				else:
					transformed = token
			elif is_valid_variable_name(token):
				# Es una variable simple, transformar a acceso al diccionario
				transformed = 'drone.vars["' + token + '"]'
			else:
				transformed = token
		
		# Agregar espacio solo cuando sea necesario
		if i > 0:
			var prev_token = tokens[i - 1]
			# No agregar espacio después de ( [ o antes de ) ] ,
			if prev_token not in ["(", "["] and token not in [")", "]", ","]:
				# Agregar espacio antes de operadores y después de ellos
				if is_operator(prev_token) or is_operator(token) or is_keyword(prev_token):
					result += " "
		
		result += transformed
	
	return result

func tokenize_expression(expr: String) -> Array:
	var tokens = []
	var current = ""
	var in_string = false
	var string_char = ""
	
	for i in range(expr.length()):
		var c = expr[i]
		
		if in_string:
			current += c
			if c == string_char:
				in_string = false
				tokens.append(current)
				current = ""
		elif c == '"' or c == "'":
			if current.length() > 0:
				tokens.append(current)
				current = ""
			in_string = true
			string_char = c
			current = c
		elif c in [" ", "\t"]:
			if current.length() > 0:
				tokens.append(current)
				current = ""
		elif c in ["(", ")", "[", "]", ",", "+", "-", "*", "/", "%", "<", ">", "=", "!", "&", "|"]:
			if current.length() > 0:
				tokens.append(current)
				current = ""
			
			# Manejar operadores de dos caracteres
			if i + 1 < expr.length():
				var next_c = expr[i + 1]
				var two_char = c + next_c
				if two_char in ["==", "!=", "<=", ">=", "+=", "-=", "*=", "/=", "&&", "||"]:
					tokens.append(two_char)
					continue
			
			tokens.append(c)
		# NO tokenizar el punto, mantenerlo con la variable
		else:
			current += c
	
	if current.length() > 0:
		tokens.append(current)
	
	return tokens

func is_literal(token: String) -> bool:
	if token.is_empty():
		return false
	
	# Números
	if token.is_valid_int() or token.is_valid_float():
		return true
	
	# Strings
	if (token.begins_with('"') and token.ends_with('"')) or (token.begins_with("'") and token.ends_with("'")):
		return true
	
	# Booleanos
	if token in ["true", "false", "True", "False"]:
		return true
	
	# Null/None
	if token in ["null", "None"]:
		return true
	
	# Vector2
	if token.begins_with("Vector2"):
		return true
	
	return false

func is_operator(token: String) -> bool:
	return token in ["+", "-", "*", "/", "%", "==", "!=", "<", ">", "<=", ">=", "and", "or", "not", "(", ")", "[", "]", ","]

func is_keyword(token: String) -> bool:
	return token in ["if", "elif", "else", "while", "for", "in", "range", "true", "false", "null", "and", "or", "not"]

func is_valid_variable_name(_name: String) -> bool:
	if _name.is_empty():
		return false
	
	# No puede empezar con número
	if _name[0].is_valid_int():
		return false
	
	# Solo puede contener letras, números y guión bajo
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z_][a-zA-Z0-9_]*$")
	return regex.search(_name) != null

func extract_function_args(line: String, _func_name: String) -> String:
	var start = line.find("(")
	var end = line.rfind(")")
	
	if start == -1 or end == -1:
		return ""
	
	return line.substr(start + 1, end - start - 1)

func split_args(args_str: String) -> Array:
	var args = []
	var current = ""
	var paren_depth = 0
	var in_string = false
	var string_char = ""
	
	for c in args_str:
		if in_string:
			current += c
			if c == string_char:
				in_string = false
		elif c == '"' or c == "'":
			in_string = true
			string_char = c
			current += c
		elif c == "(":
			paren_depth += 1
			current += c
		elif c == ")":
			paren_depth -= 1
			current += c
		elif c == "," and paren_depth == 0:
			args.append(current.strip_edges())
			current = ""
		else:
			current += c
	
	if current.length() > 0:
		args.append(current.strip_edges())
	
	return args

func get_indent_level(line: String) -> int:
	var count = 0
	for c in line:
		if c == " ":
			count += 1
		elif c == "\t":
			count += 4
		else:
			break
	return count

func validate_strings(code: String) -> Dictionary:
	var result = {"success": true, "error": "", "line": -1}
	var lines = code.split("\n")
	
	for line_num in range(lines.size()):
		var line = lines[line_num]
		var in_string = false
		var string_char = ""
		var escaped = false
		
		for c in line:
			if escaped:
				escaped = false
				continue
			
			if c == "\\":
				escaped = true
				continue
			
			if c == '"' or c == "'":
				if not in_string:
					in_string = true
					string_char = c
				elif c == string_char:
					in_string = false
		
		if in_string:
			result.success = false
			result.error = "String no cerrado"
			result.line = line_num + 1
			return result
	
	return result

func validate_parentheses(code: String) -> Dictionary:
	var result = {"success": true, "error": "", "line": -1}
	var lines = code.split("\n")
	
	for line_num in range(lines.size()):
		var line = lines[line_num]
		var stack = []
		var in_string = false
		var string_char = ""
		
		for c in line:
			if c == '"' or c == "'":
				if not in_string:
					in_string = true
					string_char = c
				elif c == string_char:
					in_string = false
				continue
			
			if in_string:
				continue
			
			if c == "(":
				stack.append(c)
			elif c == ")":
				if stack.is_empty():
					result.success = false
					result.error = "Paréntesis de cierre sin apertura"
					result.line = line_num + 1
					return result
				stack.pop_back()
		
		if not stack.is_empty():
			result.success = false
			result.error = "Paréntesis no balanceados"
			result.line = line_num + 1
			return result
	
	return result

func check_security(code: String) -> Dictionary:
	var result = {"success": true, "error": ""}
	
	for forbidden in SECURITY_BLACKLIST:
		if forbidden in code:
			result.success = false
			result.error = "Código bloqueado por seguridad: uso de " + forbidden
			return result
	
	return result
