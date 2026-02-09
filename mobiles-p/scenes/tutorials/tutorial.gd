class_name Tutorial
extends Node

@export var next_tutorial_scene : PackedScene
@onready var btn_next_tutorial : Button = get_tree().get_first_node_in_group("btn_next_tutorial")

func load_tutorial() -> void:
	btn_next_tutorial.disabled = true
	btn_next_tutorial.connect("pressed", Callable(self, "_on_btn_next_tutorial_pressed"))

func tutorial_completed() -> void:
	btn_next_tutorial.disabled = false

func _on_btn_next_tutorial_pressed() -> void:
	if next_tutorial_scene:
		var next_scene_instance = next_tutorial_scene.instantiate()
		add_sibling(next_scene_instance)
		queue_free()
