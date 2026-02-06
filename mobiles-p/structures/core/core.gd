class_name Core
extends StaticBody2D

func _ready() -> void:
    GLOBAL.PATHS.core = self

var inventory : Dictionary = {
    GLOBAL.mineral_names[0]: 0,
    GLOBAL.mineral_names[1]: 0,
    "turrents": 0,
    "barriers": 0
}