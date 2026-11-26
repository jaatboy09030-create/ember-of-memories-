class_name WarpThreads
extends MeshInstance3D
## WARP THREADS: the vertical threads already strung across the hole, anchored in the knit
## below the hole and held at the top by the darning loom's hooks.
## When the loom is flicked, alternate threads bow toward the front / back above the woven
## part, opening a gap for the needle; below the newest row they lie flat (already woven).
##
## How to change it: shed_depth = how far the threads part; radius = thread thickness.

@export var radius := 0.0026
@export var shed_depth := 0.007
@export var shed_time := 0.3

var xs := PackedFloat32Array()   # one x per thread (minigame space)
var bottom_y := 0.0              # anchored in the knit here
var top_y := 0.0                 # held by the loom here
var woven_top_y := 0.0           # highest woven row: threads are flat below it
var parity := -1
var _shed := 0.0                 # 0 closed .. 1 fully open


func setup(thread_xs: PackedFloat32Array, bottom: float, top: float) -> void:
	xs = thread_xs
	bottom_y = bottom
	top_y = top
	woven_top_y = bottom
	_rebuild()


## Lift alternate threads (parity 0/1) and open the gap.
func open_shed(new_parity: int) -> void:
	parity = new_parity
	create_tween().tween_method(_set_shed, _shed, 1.0, shed_time).set_trans(Tween.TRANS_SINE)


func close_shed() -> void:
	create_tween().tween_method(_set_shed, _shed, 0.0, shed_time).set_trans(Tween.TRANS_SINE)


func set_woven_top(y: float) -> void:
	woven_top_y = y
	_rebuild()


## +1 = lifted to the front, -1 = pushed back, for thread i at the current parity.
func side_of(i: int) -> float:
	if parity < 0:
		return 0.0
	return 1.0 if (i + parity) % 2 == 0 else -1.0


func _set_shed(v: float) -> void:
	_shed = v
	_rebuild()


func _rebuild() -> void:
	var strands: Array = []
	var gap_mid := (woven_top_y + top_y) * 0.5
	for i in xs.size():
		var x := xs[i]
		var z := side_of(i) * shed_depth * _shed
		strands.append(PackedVector3Array([
			Vector3(x, bottom_y, 0.0),
			Vector3(x, woven_top_y, 0.0),
			Vector3(x, lerpf(woven_top_y, gap_mid, 0.5), z * 0.8),
			Vector3(x, gap_mid, z),
			Vector3(x, top_y, 0.0),
		]))
	mesh = YarnMesh.build_many(strands, radius, 6, 3)
