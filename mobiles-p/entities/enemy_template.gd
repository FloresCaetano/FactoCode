class_name Enemy
extends CharacterBody2D

var life : float = 100
var strenght : float = 10

signal dead

func _physics_process(delta: float) -> void:
	if life <= 0:
		queue_free()
