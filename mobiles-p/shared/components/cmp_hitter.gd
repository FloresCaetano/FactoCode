class_name CMP_Hitter
extends Area2D

@export var target : Node2D
var damage : float

func delete():
	target.queue_free()
