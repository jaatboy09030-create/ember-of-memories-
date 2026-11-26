class_name DarningLoom
extends Node3D
## DARNING LOOM: the little wooden comb that holds the warp threads across the hole.
## Its hooks flip as a group: flick() swaps which half of the warp threads is lifted toward
## the front and which is pushed back, opening the gap (the "shed") the needle slides through.
## Each row the hooks are flicked the other way, which gives the over-under weave.
##
## How to change it: hook_tilt_degrees = how far the hooks flip; flick_time = how fast.

signal flicked(parity: int)

@export var hook_tilt_degrees := 28.0
@export var flick_time := 0.25

@onready var hooks: Node3D = $Hooks

## 0 or 1: which alternate warp threads are lifted. -1 = hooks flat (no gap open).
var parity := -1


## Flip the hooks: lifts every other thread (alternating each time).
func flick() -> void:
	parity = 0 if parity != 0 else 1
	Sound.play("paper_pickup", -8.0, 0.2)
	var tw := create_tween().set_parallel(true)
	var i := 0
	for hook in hooks.get_children():
		var lifted := (i + parity) % 2 == 0
		var angle := deg_to_rad(hook_tilt_degrees) * (-1.0 if lifted else 1.0)
		tw.tween_property(hook, "rotation:x", angle, flick_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1
	flicked.emit(parity)


## Hooks back to flat (the gap closes, e.g. after the row is pulled tight).
func settle() -> void:
	var tw := create_tween().set_parallel(true)
	for hook in hooks.get_children():
		tw.tween_property(hook, "rotation:x", 0.0, flick_time).set_trans(Tween.TRANS_SINE)


## X positions (local) of the hooks, one per warp thread.
func hook_xs() -> PackedFloat32Array:
	var xs := PackedFloat32Array()
	for hook in hooks.get_children():
		xs.append((hook as Node3D).position.x)
	return xs
