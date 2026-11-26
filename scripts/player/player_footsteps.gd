extends Node
## FOOTSTEPS: crunching snow outside, creaking floorboards inside.
## Listens to the player's `stepped` signal.
## How to change it: the volumes below; creak_chance = how often a board creaks (0..1).

@export var snow_volume := -8.0
@export var wood_volume := -9.0
@export var creak_volume := -11.0
@export_range(0.0, 1.0) var creak_chance := 0.3


func _ready() -> void:
	(get_parent() as PlayerBody).stepped.connect(_on_stepped)


func _on_stepped(on_snow: bool) -> void:
	if on_snow:
		Sound.play("step_snow", snow_volume, 0.12)
	else:
		Sound.play("step_wood", wood_volume, 0.1)
		if randf() < creak_chance:
			Sound.play("floor_creak", creak_volume, 0.15)
