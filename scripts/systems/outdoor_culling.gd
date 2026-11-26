extends Node
## OUTDOOR CULLING: hides heavy outdoor things (snowfall, the forest, garden foliage) while
## the camera is inside the house, and shows them again outside. Pure performance helper.
## Anything in the "outdoor_only" group is affected; add a node to that group to include it.
##
## How to change it: inside_below_z = camera Z at which we count as inside (the front wall).

@export var inside_below_z := -0.3

var _was_outside := true


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	var outside := cam.global_position.z > inside_below_z
	if outside == _was_outside:
		return
	_was_outside = outside
	for n in get_tree().get_nodes_in_group("outdoor_only"):
		(n as Node3D).visible = outside
