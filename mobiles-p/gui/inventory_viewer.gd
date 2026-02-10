extends VBoxContainer

@onready var lbl_blue: Label = $BrownMineral/LblBlue
@onready var lbl_brown: Label = $BlueMineral/LblBrown
@onready var lbl_turrets: Label = $Turrets/LblTurrets
@onready var lbl_barriers: Label = $Barriers/LblBarriers

func _process(_delta: float) -> void:
	lbl_blue.text = str(PATHS.core.inventory[GLOBAL.mineral_names[1]])
	lbl_brown.text = str(PATHS.core.inventory[GLOBAL.mineral_names[0]])
	lbl_turrets.text = str(PATHS.core.inventory["turrets"])
	lbl_barriers.text = str(PATHS.core.inventory["barriers"])
