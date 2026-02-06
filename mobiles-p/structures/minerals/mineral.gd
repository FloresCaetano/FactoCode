@tool
class_name Mineral
extends Node2D

@export var mineral_type : String
@export var quantity : int = 100

@export_group("Textures_and_Nodes")
@export var blue_mineral: Texture2D
@export var brown_mineral: Texture2D
@export var sprite_2d: Sprite2D

func _ready() -> void:
    if Engine.is_editor_hint():
        update_mineral_texture()

func _process(_delta: float) -> void:
    if Engine.is_editor_hint():
        update_mineral_texture()

func update_mineral_texture() -> void:
    if mineral_type == GLOBAL.mineral_names[0]:
        sprite_2d.texture = brown_mineral
    elif mineral_type == GLOBAL.mineral_names[1]:
        sprite_2d.texture = blue_mineral

func on_mined(mined_quantity: int) -> void:
    var new_quantity = quantity - mined_quantity
    if new_quantity <= 0:
        queue_free()
        return
    
    quantity = new_quantity
    GLOBAL.PATHS.core.inventory[mineral_type] += mined_quantity