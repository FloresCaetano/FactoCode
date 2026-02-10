extends Node

const mineral_names = ["brown_mineral", "blue_mineral"]

var PATHS = {
	"p_barrier" : "uid://bllpwsppr7qpc",
	"p_turret" : "uid://cwr7wc05kwfiw",
	"p_bullet" : "uid://l4s2abrexjtb"
}

var core_health : int:
	get:
		return PATHS.core.health

var ia_assistance_used : int = 0
var drones_built : int = 1

var enemies_alive : int = 0
var wave_number : int = 0
var is_tutorial_active : bool = true
