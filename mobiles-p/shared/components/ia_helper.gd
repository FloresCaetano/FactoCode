extends HBoxContainer

@export var code_edit : CodeEdit
@export var feedback_line : RichTextLabel
@export var endpoint_url : String = "http://127.0.0.1:5000/ask_ia"

@onready var ia_helper_button: Button = $IaHelperButton

func _ready() -> void:
	if ia_helper_button:
		ia_helper_button.pressed.connect(_on_ia_helper_button_pressed)

func _on_ia_helper_button_pressed() -> void:
	if code_edit == null or feedback_line == null:
		print("IA helper: missing code_edit or feedback_line")
		return

	var http_request = HTTPRequest.new()
	add_child(http_request)

	var payload = {
		"code": code_edit.text,
		"error": feedback_line.text
	}
	var headers = ["Content-Type: application/json"]
	var err = http_request.request(endpoint_url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		feedback_line.text = "[color=red]IA request failed to start[/color]"
		print(feedback_line.text)
		http_request.queue_free()
		return
	print("IA helper: request sent")

	var result = await http_request.request_completed
	var response_code = result[1]
	var response_body = result[3]

	if result[0] != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		feedback_line.text = "[color=red]IA request failed: " + str(response_code) + "[/color]"
		print(feedback_line.text)
		http_request.queue_free()
		return

	var body_text = response_body.get_string_from_utf8()
	print("IA helper response: " + body_text)
	var json_result = JSON.parse_string(body_text)
	if typeof(json_result) == TYPE_DICTIONARY:
		if json_result.has("feedback"):
			feedback_line.text = "[color=green]" + str(json_result.feedback).strip_edges() + "[/color]"
			http_request.queue_free()
			return
		if json_result.has("answer"):
			feedback_line.text = "[color=green]" + str(json_result.answer).strip_edges() + "[/color]"
			http_request.queue_free()
			return
		if json_result.has("response"):
			feedback_line.text = "[color=green]" + str(json_result.response).strip_edges() + "[/color]"
			http_request.queue_free()
			return

	feedback_line.text = "[color=green]" + body_text + "[/color]"
	GLOBAL.ia_assistance_used += 1
	http_request.queue_free()

