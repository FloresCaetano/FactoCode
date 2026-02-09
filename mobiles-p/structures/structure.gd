class_name Structure
extends StaticBody2D

@export var health : int = 100
var progress_var : ProgressBar = null

signal destroyed

func take_damage(damage_amount: int) -> void:
	health -= damage_amount

	progress_var.visible = true
	progress_var.value = health

	if health <= 0:
		destroyed.emit()
		queue_free()

func _init():
	progress_var = load(PATHS.COMPONENTS["progress_bar"]).instantiate()
	add_child(progress_var)
	progress_var.position = Vector2(0, -50)
	progress_var.visible = false
	progress_var.max_value = health
	progress_var.z_index = 1
