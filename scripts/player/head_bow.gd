class_name HeadBow
extends SkeletonModifier3D
## HEAD BOW: tips the neck and head forward on top of the animation, so the character looks
## down at something held in the hands (memory 5's photo). Off while `influence` is 0;
## PlayerHands fades it in and out.
##
## How to change it: angle_degrees = how far the head bows at influence 1; neck_share =
## how much of it the neck does (the head does the rest).

@export var angle_degrees := 24.0
@export_range(0.0, 1.0) var neck_share := 0.4
## The body pivot (its +Z is where the character faces).
@export var body_pivot: Node3D


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if not sk or not body_pivot:
		return
	var facing := body_pivot.global_basis.z.normalized()
	# positive rotation around (up x facing) tips the face downward
	var axis := (sk.global_basis.inverse() * Vector3.UP.cross(facing)).normalized()
	var angle := deg_to_rad(angle_degrees)
	_tilt(sk, "mixamorig_Neck", axis, angle * neck_share)
	_tilt(sk, "mixamorig_Head", axis, angle * (1.0 - neck_share))


func _tilt(sk: Skeleton3D, bone_name: String, axis: Vector3, angle: float) -> void:
	var i := sk.find_bone(bone_name)
	if i < 0:
		return
	var pose := sk.get_bone_global_pose(i)
	pose.basis = Basis(axis, angle) * pose.basis
	sk.set_bone_global_pose(i, pose)
