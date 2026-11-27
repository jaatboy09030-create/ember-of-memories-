class_name Eyelids
extends ColorRect
## EYELIDS (blink demo): the player's eyes. Reads the "blink" input action (Space / left
## mouse / gamepad A) and closes the curved lids drawn by shaders/eyelids.gdshader.
## A tap = one quick blink. Holding = eyes stay closed (the screen stays black).
## Signals tell the demo the exact moment the lids are fully shut, which is when a
## memory can be swapped without the player ever seeing the cut.
##
## How to change it: close_time / open_time for blink speed, hold_time for how long the
## eyes must stay shut before "held_closed" fires.

## Lids fully closed (fires once per blink): the moment to cut.
signal shut
## Eyes kept closed past hold_time.
signal held_closed
## Lids opened again after being shut.
signal opened

## Seconds for the lids to close.
@export var close_time := 0.07
## Seconds for the lids to open.
@export var open_time := 0.16
## A tap keeps the lids shut at least this long, so even a tiny tap is a full blink.
@export var min_shut_time := 0.06
## Seconds of closed eyes before held_closed fires.
@export var hold_time := 0.65

## 0 = open .. 1 = shut.
var closure := 1.0
## True = lids stay shut whatever the player does (cuts, intro, ending).
var forced_closed := true
## False = the blink action is ignored.
var enabled := false

var _now := 0.0
var _shut_until := 0.0
var _was_shut := false
var _held_sent := false
var _closed_time := 0.0
var _flutter := 0.0
var _slow_open := 0.0

@onready var mat: ShaderMaterial = material


func _process(delta: float) -> void:
	_now += delta
	if enabled and Input.is_action_just_pressed("blink"):
		_shut_until = _now + min_shut_time
	var want_closed := forced_closed or _now < _shut_until or (enabled and Input.is_action_pressed("blink"))
	var target := 1.0 if want_closed else _flutter
	var open_speed := 1.0 / (_slow_open if _slow_open > 0.0 else open_time)
	var speed := 1.0 / close_time if target > closure else open_speed
	closure = move_toward(closure, target, speed * delta)
	if closure >= 1.0:
		_closed_time += delta
		if not _was_shut:
			_was_shut = true
			_held_sent = false
			shut.emit()
		if not _held_sent and _closed_time >= hold_time:
			_held_sent = true
			held_closed.emit()
	elif _was_shut and closure < 0.5:
		_was_shut = false
		_closed_time = 0.0
		_slow_open = 0.0
		opened.emit()
	mat.set_shader_parameter("closure", closure)
	visible = closure > 0.001


## Open the eyes slowly (waking up) over `time` seconds.
func open_slowly(time: float) -> void:
	_slow_open = time
	forced_closed = false


## Lids droop a little on their own (dry, tired eyes). 0 = none.
func set_flutter(amount: float) -> void:
	_flutter = clampf(amount, 0.0, 0.9)
