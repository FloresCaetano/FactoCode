class_name Bullet
extends Sprite2D

var bullet_speed = 0
var damage = 0

func _physics_process(_delta: float) -> void:
	position.y += bullet_speed
	$CMP_Hitter.damage = damage

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	self.queue_free()
