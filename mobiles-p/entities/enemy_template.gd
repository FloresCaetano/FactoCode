class_name Enemy
extends CharacterBody2D

var hp : float = 100
var strength : float = 10

signal die


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		die.emit()
		GLOBAL.enemies_alive -= 1
		queue_free()