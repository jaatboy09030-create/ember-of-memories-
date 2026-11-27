class_name BeatCue
extends Node
## BEAT CUE (blink demo): something that happens on its own, `delay` seconds after its
## memory (MemoryBeat parent) opens: a sound, a door swinging, headlights in the lane.
## Put it as a child of a MemoryBeat. It is cancelled if the memory is cut first.
##
## How to change it: delay, then any of: sound (assets/audio name), synth (a SynthTone
## node to play), target + method + args (e.g. FrontDoor, "swing", [true]).

@export var delay := 1.0
## Sound name from assets/audio (no extension). "" = none.
@export var sound := ""
@export var volume_db := 0.0
## A generated sound to play instead (e.g. the car engine).
@export var synth: AudioStreamPlayer
@export var target: Node
@export var method := ""
@export var args: Array = []

var _tw: Tween


func start() -> void:
	stop()
	_tw = create_tween()
	_tw.tween_interval(delay)
	_tw.tween_callback(_fire)


func stop() -> void:
	if _tw and _tw.is_valid():
		_tw.kill()


func _fire() -> void:
	if sound != "":
		Sound.play(sound, volume_db)
	if synth:
		synth.play()
	if target and method != "" and target.has_method(method):
		target.callv(method, args)
