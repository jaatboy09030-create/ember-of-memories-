class_name PlayerTears
extends Node3D
## PLAYER TEARS: slow tears that well up at the eyes, run down the cheeks and drop.
## Rides on the head bone (HeadAttachment), so tears follow the head when it bows.
## Only seen by cameras that see the body (memory 5's reflection and over-the-shoulder shot).
##
## How to change it: move the LeftEye / RightEye markers (they sit on the lower eyelids, in
## head-bone space; re-check with `--phototest`, which saves what the photo glass reflects).
## The drop look and speed are the LeftTear / RightTear particle settings in the Inspector.
## The particles are top_level and only copy the markers' position, so "down" is always
## world down (the head bone's own axes are tilted and scaled).

@onready var left_eye: Marker3D = $LeftEye
@onready var right_eye: Marker3D = $RightEye
@onready var left_tear: GPUParticles3D = $LeftTear
@onready var right_tear: GPUParticles3D = $RightTear


func _process(_delta: float) -> void:
	left_tear.global_transform = Transform3D(Basis.IDENTITY, left_eye.global_position)
	right_tear.global_transform = Transform3D(Basis.IDENTITY, right_eye.global_position)


func start() -> void:
	left_tear.emitting = true
	right_tear.set_deferred("emitting", true)


func stop() -> void:
	left_tear.emitting = false
	right_tear.emitting = false
