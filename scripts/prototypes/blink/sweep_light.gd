class_name SweepLight
extends SpotLight3D
## SWEEP LIGHT (blink demo): headlights turning into the lane. sweep() slides the light
## from where it stands to `travel` metres away while it brightens, holds, then dies,
## so a pale bar of light crosses the walls through the window. Started by a BeatCue.
##
## How to change it: travel, time, peak energy.

## How far the light slides (metres, world space).
@export var travel := Vector3(-6, 0, 0)
@export var time := 3.5
@export var peak_energy := 6.0

var _start := Vector3.ZERO


func _ready() -> void:
	_start = global_position
	light_energy = 0.0


func sweep() -> void:
	global_position = _start
	light_energy = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "global_position", _start + travel, time).set_trans(Tween.TRANS_SINE)
	var e := create_tween()
	e.tween_property(self, "light_energy", peak_energy, time * 0.3)
	e.tween_interval(time * 0.4)
	e.tween_property(self, "light_energy", 0.0, time * 0.3)
