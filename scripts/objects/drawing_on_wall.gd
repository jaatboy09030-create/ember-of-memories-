class_name DrawingOnWall
extends Node3D
## The child's drawing pinned above the desk. Hidden until the torn pieces are taped
## together (memory 2), then it pops onto the wall.
## How to change it: swap the texture on DrawingPicture; pop_time = how long the pop takes.

@export var pop_time := 0.8


func _ready() -> void:
	visible = false


func pop_in() -> void:
	visible = true
	scale = Vector3.ONE * 0.2
	create_tween().tween_property(self, "scale", Vector3.ONE, pop_time).set_trans(Tween.TRANS_BACK)
