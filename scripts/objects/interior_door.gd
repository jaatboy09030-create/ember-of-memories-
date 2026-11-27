class_name InteriorDoor
extends Interactable
## INTERIOR DOOR: a hinged door that starts locked and is unlocked by the story.
## Once unlocked the player can open/close it by looking at it and pressing "interact".
## It refuses to close while the player stands in the doorway (DoorwayClearance area).
## A LOCKED door still answers: the prompt says "locked", and trying it makes the leaf jerk
## against the latch with a double clack (rattle()).
## lock_behind_player (the front door): once the player has walked through to the inside and
## is clear of the swing, the door shuts and locks for good - there is no going back out.
## From the moment it starts closing, an invisible OutsideBlocker just outside the doorway is
## switched on: if the player turns back, the door reopens (it never closes onto them) but
## they still can't step out, and it closes again once they walk away.
##
## How to change it:
##   door_id       -> name the story uses to unlock it (see Memory.unlocks_door_id)
##   open_angle    -> how far it swings open, in degrees
##   open_time / close_time -> swing speed in seconds
##   locked_prompt, rattle_degrees, rattle_time, rattle_sound -> the "it's locked" feedback
##   lock_behind_player, inside_is_negative_z, lock_distance -> the one-way front door
## Rotate the whole scene instance to fit a wall; the hinge is on the DoorHinge node.

## Name used by the story to unlock this door ("front", "kid", "hall", "bed", "parent").
@export var door_id := "front"
## Locked doors can't be opened until the story calls unlock_and_open(); trying one rattles it.
@export var locked := true
@export var open_angle := 100.0
@export var open_time := 1.6
@export var close_time := 1.3
## Prompt shown while looking at the door when it is locked.
@export var locked_prompt := "locked"
## How far the leaf jerks against the latch when someone tries a locked door (degrees).
@export var rattle_degrees := 1.8
## Length of the rattle, seconds.
@export var rattle_time := 0.42
## Clip from assets/audio (no extension), played twice as the latch clacks.
@export var rattle_sound := "door_rattle"
## Shut and lock this door once the player has walked through it to the inside.
@export var lock_behind_player := false
## Which side counts as "inside": true = the door's local -Z side (the front door: the house is at -Z).
@export var inside_is_negative_z := true
## The player must be this far from the hinge (metres) before the door swings shut behind them,
## so the leaf never sweeps through the player or the camera.
@export var lock_distance := 1.8

@onready var hinge: Node3D = $DoorHinge
@onready var clearance: Area3D = $DoorwayClearance
@onready var outside_blocker_shape: CollisionShape3D = $OutsideBlocker/BlockerShape

var is_open := false
var _swing: Tween
var _rattle: Tween
var _lock_when_clear: Node3D
var _closing_behind := false


func _ready() -> void:
	super._ready()
	add_to_group("interior_door")
	clearance.body_exited.connect(_on_clearance_body_exited)
	# the blocker always sits on the OUTSIDE of the doorway
	var outside_block := $OutsideBlocker as Node3D
	outside_block.position.z = absf(outside_block.position.z) * (1.0 if inside_is_negative_z else -1.0)


func get_prompt() -> String:
	if locked or _closing_behind:
		return locked_prompt
	return "close" if is_open else "open"


## A locked door gets no glow (it is not an invitation), but still reports the hover so the
## HUD shows "locked".
func on_hover() -> void:
	if locked:
		is_hovered = true
		hovered.emit()
		return
	super.on_hover()


func on_interact() -> void:
	super.on_interact()
	if _closing_behind:
		return  # the one-way door is shutting behind you: it can't be stopped from inside
	if locked:
		rattle()
		return
	if is_open and _player_in_doorway():
		return  # closing would sweep through the player
	swing(not is_open)


## The story beat: unlock the door and swing it open.
func unlock_and_open() -> void:
	locked = false
	swing(true)


## Someone tried a locked door: it jerks against the latch, which clacks twice.
func rattle() -> void:
	if (_rattle and _rattle.is_running()) or (_swing and _swing.is_running()):
		return  # never fight a swing that is still moving the leaf
	var rest := hinge.rotation.y
	var a := deg_to_rad(rattle_degrees)
	var step := rattle_time / 6.0
	var sound_pos := hinge.global_position + Vector3(0, 1.0, 0)
	Sound.play_at(rattle_sound, sound_pos, -14.0)
	get_tree().create_timer(rattle_time * 0.45).timeout.connect(func(): Sound.play_at(rattle_sound, sound_pos, -19.0))
	_rattle = create_tween()
	for k in [1.0, 0.15, 0.8, 0.1, 0.45, 0.0]:
		_rattle.tween_property(hinge, "rotation:y", rest + a * k, step).set_trans(Tween.TRANS_SINE)


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


## The player stepped out of the doorway: if this is the one-way door, wait until they are
## inside and clear of the swing, then shut and lock it (see _physics_process).
func _on_clearance_body_exited(body: Node3D) -> void:
	if lock_behind_player and not locked and is_open and body is PlayerBody:
		_lock_when_clear = body


## While the one-way door is closing behind the player: if anyone steps back into the
## doorway it swings open again (it never closes onto the player), and it only locks once
## the leaf is fully shut.
func _physics_process(_delta: float) -> void:
	if _lock_when_clear == null:
		return
	if _closing_behind:
		if _player_in_doorway():
			_closing_behind = false
			swing(true)  # stays armed: tries again once the player is clear
		return
	var p := _lock_when_clear.global_position
	var local_z := to_local(p).z
	var inside := local_z < 0.0 if inside_is_negative_z else local_z > 0.0
	var h := hinge.global_position
	if inside and Vector2(p.x - h.x, p.z - h.z).length() > lock_distance:
		_closing_behind = true
		outside_blocker_shape.set_deferred("disabled", false)  # player is inside and far: safe to switch on
		swing(false)
		_swing.tween_callback(_finish_lock_behind)


func _finish_lock_behind() -> void:
	_closing_behind = false
	_lock_when_clear = null
	locked = true
	outside_blocker_shape.set_deferred("disabled", true)  # the shut, locked leaf blocks from here on
