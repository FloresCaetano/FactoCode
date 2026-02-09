class_name CMP_DamageHitbox
extends Node2D
@export var target : Node2D
@export var collision_shape : CollisionShape2D

func receive_damage(damage : float):
	target.life -= damage
	if target.life <= 0:
		if target.has_signal("dead"):
			target.dead.emit()
		target.queue_free()

func _ready() -> void:
	if collision_shape:
		var area_2d : Area2D = Area2D.new()
		add_child(area_2d)
		var area_collision : CollisionShape2D = collision_shape.duplicate()
		area_2d.add_child(area_collision)
		area_2d.area_entered.connect(_on_area_entered)

func _on_area_entered(area : Area2D):
	if area is CMP_Hitter:
		receive_damage(area.damage)
		area.delete()
	
