extends Control

@export var inp_endpoint: LineEdit
@export var options_container: Control

func _ready() -> void:
	inp_endpoint.text = GLOBAL.api_host

func _on_btn_leave_pressed() -> void:
	get_tree().quit()

func _on_btn_config_pressed() -> void:
	options_container.visible = not options_container.visible

func _on_btn_play_pressed() -> void:
	get_tree().change_scene_to_file("uid://typp6dsw6aam")


func _on_inp_endpoint_text_changed(new_text: String) -> void:
	GLOBAL.api_host = new_text.strip_edges()
