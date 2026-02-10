extends Node

const BASE_TEMPLATE = """
extends Node

var drone # Referencia al dron

func _run_code():
{USER_CODE}
"""

var _compiled_script: GDScript = null
var last_status: String = ""
var last_feedback: String = ""
var last_error_line: int = -1

func transpilar(user_text: String) -> GDScript:
	var http_request = HTTPRequest.new()
	add_child(http_request)

	var url = GLOBAL.api_url("/compile")
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"code": user_text})

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("Error al iniciar la petición HTTP.")
		return null

	var result = await http_request.request_completed
	
	var response_code = result[1]
	var response_body_raw = result[3]

	if result[0] != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_error("La petición de transpilación falló. Código: " + str(response_code))
		return null

	var response_body = response_body_raw.get_string_from_utf8()
	var json_result = JSON.parse_string(response_body)
	print(json_result)

	# Guardar información de retroalimentación
	if json_result:
		last_status = json_result.get("status", "error")
		last_feedback = json_result.get("feedback", "Sin retroalimentación")
		last_error_line = json_result.get("error_on_line", -1) if json_result.get("error_on_line") != null else -1

	if json_result and json_result.has("compiled_code") and json_result.get("status") == "success":
		# Insertar el código transpilado por IA en el BASE_TEMPLATE
		# Agregar indentación al código compilado
		var compiled_code = json_result.compiled_code
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
			return null
		
		_compiled_script = script
		return script
	else:
		var error_message = "Respuesta inválida del servidor de transpilación."
		if json_result and json_result.has("error"):
			error_message += " Detalles: " + json_result.error
		push_error(error_message)
		return null
