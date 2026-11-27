class_name EyeHotspot
extends Marker3D
## EYE HOTSPOT (blink demo): a white eye icon floating on something in the memory.
## Put the reticle on it and blink: instead of skipping time, the blink LOOKS CLOSER.
## Behind the closed lids it wakes the ghosts, blooms hidden islands, plays a sound; the
## demo adds the caption, voice, colour and warmth when the eyes open again.
##
## How to change it: everything is in the Inspector. Leave a field empty to skip it.

signal triggered(hotspot: EyeHotspot)

## Ghost figures that come alive.
@export var figures_to_wake: Array[MemoryFigure] = []
## Something in the memory to set off, and the method to call on it
## (e.g. DrawingOnWall + "pop_in", PhotoFrame + "flip", Fireplace + "ignite").
@export var call_target: Node
@export var call_method := ""
@export var call_args: Array = []
## Things that appear (e.g. a clipping on the back of the photo).
@export var show_nodes: Array[Node3D] = []
## Hidden islands that bloom open.
@export var islands_to_bloom: Array[MemoryIsland] = []
## Sound name from assets/audio (no extension).
@export var sound := ""
## Voice line name from assets/audio, played with the caption.
@export var voice := ""
@export_multiline var caption := ""
## World colour afterwards (0 grey .. 1 full). -1 = unchanged.
@export_range(-1.0, 1.0) var saturation_after := -1.0
## Room (room_id) whose lights turn warm. "" = none.
@export var warm_room_id := ""
## Every room turns warm (the ending).
@export var warm_all_rooms := false
## Music track to switch to (assets/audio name). "" = keep.
@export var music := ""
## The black void dissolves: the whole house is seen at once (the ending).
@export var clear_void := false
## The Ember drifts to this hotspot (e.g. into the fire).
@export var ember_goes_here := false
## Seconds into the beat before the eye appears.
@export var appear_after := 1.5

var used := false
var _time := 0.0


func reset() -> void:
	used = false
	_time = 0.0


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_time += delta


func is_active() -> bool:
	return not used and _time >= appear_after and is_visible_in_tree()


func trigger() -> void:
	used = true
	for f in figures_to_wake:
		if f:
			f.wake(false)  # faces stay pixelated in the blink demo: you never get them back
	if call_target and call_method != "" and call_target.has_method(call_method):
		call_target.callv(call_method, call_args)
	for n in show_nodes:
		if n:
			n.visible = true
	for island in islands_to_bloom:
		if island:
			island.bloom()
	if sound != "":
		Sound.play(sound, -2.0)
	triggered.emit(self)
