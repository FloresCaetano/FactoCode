class_name Enemy
extends CharacterBody2D

var life : float = 100
var strenght : float = 10

signal dead


func take_damage(amount: float) -> void:
	life -= amount
	if life <= 0:
		dead.emit()
		queue_free()