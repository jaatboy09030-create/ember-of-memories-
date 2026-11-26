class_name PhotoFrame
extends Interactable
## PHOTO FRAME lying face down on the dresser in the parent's room (memory 5).
## Using it emits `chosen`; PhotoMemory then plays the reveal cutscene and calls flip().
## How to change it: flip_time / lift_height = how the photo turns over.

signal chosen

@export var flip_time := 1.3
@export var lift_height := 0.13

@onready var frame_pivot: Node3D = $FramePivot


func _ready() -> void:
	super._ready()
	enabled = false
	frame_pivot.rotation = Vector3(PI, 0, 0)  # face down


func on_interact() -> void:
	super.on_interact()
	enabled = false
	chosen.emit()


## Turn the photo over and lift it a little toward the player.
func flip() -> void:
	Sound.play("photo_flip", -2.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(frame_pivot, "rotation:x", PI * 0.5, flip_time).set_trans(Tween.TRANS_SINE)
	tw.tween_property(frame_pivot, "position:y", frame_pivot.position.y + lift_height, flip_time)
