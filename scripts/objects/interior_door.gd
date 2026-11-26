class_name InteriorDoor
extends Interactable
## INTERIOR DOOR: a hinged door that starts locked and is unlocked by the story.
## Once unlocked the player can open/close it by looking at it and pressing "interact".
## It refuses to close while the player stands in the doorway (DoorwayClearance area).
##
## How to change it:
##   door_id       -> name the story uses to unlock it (see Memory.unlocks_door_id)
##   open_angle    -> how far it swings open, in degrees
##   open_time / close_time -> swing speed in seconds
## Rotate the whole scene instance to fit a wall; the hinge is on the DoorHinge node.

## Name used by the story to unlock this door ("front", "kid", "hall", "bed", "parent").
@export var door_id := "front"
## Locked doors can't be used until the story calls unlock_and_open().
@export var locked := true:
	set(v):
		locked = v
		enabled = not v
@export var open_angle := 100.0
@export var open_time := 1.6
@export var close_time := 1.3

@onready var hinge: Node3D = $DoorHinge
@onready var clearance: Area3D = $DoorwayClearance

var is_open := false
var _swing: Tween


func _ready() -> void:
	super._ready()
	add_to_group("interior_door")
	enabled = not locked


func get_prompt() -> String:
	return "close" if is_open else "open"


func on_interact() -> void:
	super.on_interact()
	if is_open and _player_in_doorway():
		return  # closing would sweep through the player
	swing(not is_open)


## The story beat: unlock the door and swing it open.
func unlock_and_open() -> void:
	locked = false
	swing(true)


func swing(open: bool) -> void:
	is_open = open
	if _swing and _swing.is_valid():
		_swing.kill()
	var sound_pos := hinge.global_position + Vector3(0, 1.3, 0)
	Sound.play_at("door_creak", sound_pos, -2.0 if open else -8.0)
	_swing = create_tween()
	_swing.tween_property(hinge, "rotation:y", deg_to_rad(open_angle) if open else 0.0,
		open_time if open else close_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT if open else Tween.EASE_IN)
	if not open:
		_swing.tween_callback(func(): Sound.play_at("door_slam", sound_pos, -16.0))


func _player_in_doorway() -> bool:
	for b in clearance.get_overlapping_bodies():
		if b is CharacterBody3D:
			return true
	return false
