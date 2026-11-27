class_name MemoryBeat
extends Node3D
## MEMORY BEAT (blink demo): one remembered moment, seen from one spot.
## Children: CameraPoint + LookTarget (where you stand and look), Islands (MemoryIsland
## nodes: what shows through the void), optional EyeHotspot, MemoryLight, EmberPoint.
## While a beat is not playing it is hidden (its light is off too).
##
## Blink rules (from Before Your Eyes): blinking is SAFE until protect_time has passed
## (and the eye was used, if wait_for_hotspot). Then the metronome appears and the next
## blink cuts to the next beat, even mid-sentence.
##
## How to change it: lines / line_times for what is said, the times below for pacing.

## Shown on black just before this beat opens (a jump in time). "" = none.
@export var time_card := ""
## Captions shown during the beat.
@export_multiline var lines: Array[String] = []
## Seconds into the beat for each line.
@export var line_times: Array[float] = []
## Blinks are safe for this long.
@export var protect_time := 6.0
## Keep blinks safe until the eye hotspot is used (or max_wait passes).
@export var wait_for_hotspot := true
## The metronome arms after this long anyway.
@export var max_wait := 16.0
## World colour (0 grey .. 1 full) when the beat opens.
@export_range(0.0, 1.0) var saturation := 0.3
## >= 0: the colour drains to this over drain_time while you watch.
@export_range(-1.0, 1.0) var drain_to := -1.0
@export var drain_time := 20.0
## > 0: the islands shrink to wither_to over this many seconds (the memory slipping away).
@export var wither_time := 0.0
@export_range(0.0, 1.0) var wither_to := 0.4
## Played (once) when the player keeps their eyes closed in this beat.
@export var closed_eyes_sound := ""
@export_multiline var closed_eyes_caption := ""
## Heard ONLY while the eyes stay closed, one after another (opening the eyes stops them).
## The reward for not looking.
@export_multiline var closed_eyes_lines: Array[String] = []
## Seconds of a ticking metronome before the eyes grow heavy. -1 = the demo's default.
@export var heavy_eyes_after := -1.0
## MONTAGE: each blink is one step (a year...): the next line shows, the islands shrink.
## After the last step the next blink lets go. Empty = a normal beat.
@export_multiline var montage_lines: Array[String] = []
@export var montage_sound := ""
## Hidden when this beat opens (e.g. ghosts that are gone in this memory).
@export var hide_on_enter: Array[Node3D] = []
## Shown when this beat opens (e.g. the drawings back on the wall).
@export var show_on_enter: Array[Node3D] = []
## Changed behind the lids on the FIRST blink in this beat (the thing that was there, and isn't).
@export var first_blink_hide: Array[Node3D] = []
@export var first_blink_show: Array[Node3D] = []
## Montage only: node shown at each step (index = step); the previous step's node hides.
## E.g. a figure a little closer every blink.
@export var montage_show: Array[Node3D] = []
## Sound for each closed_eyes_line (same index). "" = none. "@Name" = a SynthTone node.
@export var closed_eyes_line_sounds: Array[String] = []
## The metronome waits until every closed_eyes_line has been heard (or max_wait).
@export var wait_for_closed_lines := false
## Shown once all closed_eyes_lines have been heard.
@export_multiline var closed_lines_done_caption := ""
## Music when this beat opens: "keep" = carry on, "none" = silence, else a track name.
@export var music := "keep"
## > 0: the beat ends by itself after this many seconds (if no blink cuts it first).
@export var auto_end_after := 0.0
## Final beat only: lines heard instead of ending_lines if a blink cut it short.
@export_multiline var ending_lines_if_blinked: Array[String] = []
## The last beat: its cut ends the demo instead of opening a new memory.
@export var final_beat := false
## Lines heard in the dark after the final cut.
@export_multiline var ending_lines: Array[String] = []

@onready var camera_point: Marker3D = $CameraPoint
@onready var look_target: Marker3D = $LookTarget
@onready var islands_root: Node3D = $Islands
@onready var hotspot: EyeHotspot = get_node_or_null("EyeHotspot")
@onready var light: OmniLight3D = get_node_or_null("MemoryLight")
@onready var ember_point: Marker3D = get_node_or_null("EmberPoint")

var _light_energy := 0.0


func _ready() -> void:
	if light:
		_light_energy = light.light_energy
	leave()


func islands() -> Array[MemoryIsland]:
	var out: Array[MemoryIsland] = []
	for c in islands_root.get_children():
		if c is MemoryIsland:
			out.append(c)
	return out


func enter() -> void:
	visible = true
	for n in hide_on_enter:
		if n:
			n.visible = false
	for n in show_on_enter:
		if n:
			n.visible = true
			n.scale = Vector3.ONE
	for c in get_children():
		if c is BeatCue:
			c.start()
	for island in islands():
		island.enter()
		if wither_time > 0.0 and not island.hidden_at_start:
			var tw := create_tween()
			tw.tween_interval(island.bloom_time)
			tw.tween_callback(island.wither.bind(wither_to, wither_time))
	if hotspot:
		hotspot.reset()
	if light:
		light.light_energy = 0.0
		create_tween().tween_property(light, "light_energy", _light_energy, 1.5)


func leave() -> void:
	visible = false
	for c in get_children():
		if c is BeatCue:
			c.stop()
