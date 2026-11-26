class_name StudyDoor
extends Interactable
## STUDY DOOR at the end of the hallway (memory 3, "hold the door").
## Press "interact" on it to start: the door shoves back in pulses and the player mashes
## "interact" to hold it open. They can slow it down but never win: after struggle_time
## seconds it slams shut. Light leaks from under the door the whole time.
##
## How to change it:
##   struggle_time   -> seconds before the door always wins
##   push_per_press  -> how much one press opens it (0..1)
##   max_open        -> the furthest the player can ever push it (0..1)
##   base_shove / shove_growth -> how hard the door pushes back (gets stronger over time)

signal struggle_started
signal pushed        # the player pushed (one press)
signal shoved        # the door shoved back (a pulse)
signal slammed

@export var struggle_time := 6.5
@export var push_per_press := 0.13
@export var max_open := 0.85
@export var base_shove := 0.35
@export var shove_growth := 0.08
@export var shove_interval := 1.3
## How far the door leaf turns / slides when fully pushed.
@export var open_rotation := 1.1
@export var open_slide := 0.42

@onready var door_leaf: Node3D = $DoorLeaf

## 0 = shut, 1 = fully pushed open.
var push_amount := 0.0
var is_struggling := false
var _time := 0.0


func get_progress() -> float:
	return push_amount if is_struggling else -1.0


func on_interact() -> void:
	super.on_interact()
	if not is_struggling:
		is_struggling = true
		enabled = false
		struggle_started.emit()


func _physics_process(delta: float) -> void:
	if not is_struggling:
		return
	_time += delta
	push_amount = maxf(push_amount - delta * (base_shove + _time * shove_growth), 0.0)
	if Input.is_action_just_pressed("interact"):
		push_amount = minf(push_amount + push_per_press, max_open)
		Sound.play_at("pack_item", door_leaf.global_position, -2.0)
		pushed.emit()
	if fmod(_time, shove_interval) < delta:
		shoved.emit()
	door_leaf.rotation.y = -push_amount * open_rotation
	door_leaf.position.x = push_amount * open_slide
	if _time > struggle_time:
		_slam()


func _slam() -> void:
	is_struggling = false
	push_amount = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(door_leaf, "rotation:y", 0.0, 0.12)
	tw.tween_property(door_leaf, "position:x", 0.0, 0.12)
	slammed.emit()
