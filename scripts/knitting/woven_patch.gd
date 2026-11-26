class_name WovenPatch
extends Node3D
## WOVEN PATCH: the rows the player has woven across the hole. Each row is real thread
## going over one warp thread and under the next (and the opposite on the next row), so
## the patch builds up like a real darn. New rows slide down into place ("packed").
##
## How to change it: radius = weft thickness; pack_time = how fast a row settles.

@export var radius := 0.0024
@export var weave_depth := 0.0035
@export var pack_time := 0.35
@export var thread_material: Material

var row_count := 0


## Add a woven row at height y, crossing warp threads at `xs`; parity says which threads
## the row passes behind (the lifted ones are in front of it).
func add_row(y: float, xs: PackedFloat32Array, parity: int, left: float, right: float) -> void:
	var pts := PackedVector3Array([Vector3(left, 0, 0)])
	for i in xs.size():
		var lifted := (i + parity) % 2 == 0
		pts.append(Vector3(xs[i], 0, -weave_depth if lifted else weave_depth))
	pts.append(Vector3(right, 0, 0))
	var row := MeshInstance3D.new()
	row.name = "WovenRow%d" % (row_count + 1)
	row.mesh = YarnMesh.build(pts, radius, 6, 4)
	row.material_override = thread_material
	row.position = Vector3(0, y + 0.012, 0)
	add_child(row)
	row_count += 1
	create_tween().tween_property(row, "position:y", y, pack_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
