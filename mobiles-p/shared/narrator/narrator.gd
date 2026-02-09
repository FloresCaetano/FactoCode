class_name Narrator
extends CanvasLayer

var dialog_queue : Array[String] = []
@export var text_edit: TextEdit
@export var btn_display_narrator: Button
@export var label: Label
@export var left_arrow: TextureButton
@export var right_arrow: TextureButton
@export var btn_next_tutorial : Button

var current_line_index : int = -1

func _ready() -> void:
	PATHS.narrator = self
	left_arrow.connect("pressed", Callable(self, "show_previous_line"))
	right_arrow.connect("pressed", Callable(self, "show_next_line"))

func start_dialog(dialog_lines: Array[String]) -> void:
	text_edit.visible = true
	btn_display_narrator.button_pressed = false
	left_arrow.disabled = true
	right_arrow.disabled = false

	current_line_index = 0
	dialog_queue = dialog_lines

	label.text = dialog_queue[current_line_index]

func show_next_line() -> void:
	left_arrow.disabled = false

	var new_line_index = current_line_index + 1
	if not new_line_index < dialog_queue.size():
		btn_next_tutorial.visible = true
		right_arrow.disabled = true
		return
	
	current_line_index = new_line_index
	label.text = dialog_queue[current_line_index]

func show_previous_line() -> void:
	btn_next_tutorial.visible = false
	right_arrow.disabled = false

	var new_line_index = current_line_index - 1
	if new_line_index < 0:
		left_arrow.disabled = true
		return
	
	current_line_index = new_line_index
	label.text = dialog_queue[current_line_index]

func _on_btn_display_narrator_toggled(toggled_on: bool) -> void:
	text_edit.visible = not toggled_on
