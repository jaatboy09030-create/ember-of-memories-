class_name SynthTone
extends AudioStreamPlayer
## SYNTH TONE (blink demo): makes its own short sound when the game starts, so the demo
## needs no new audio files. Used for the metronome tick (a high wooden click) and the
## eyelid shutter (a soft low thump).
##
## How to change it: frequency, length, decay, noise and sweep below.

## Pitch in Hz.
@export var frequency := 1800.0
## Seconds.
@export var length := 0.05
## How fast it dies away (bigger = shorter).
@export var decay := 90.0
## 0 = pure tone .. 1 = pure noise.
@export_range(0.0, 1.0) var noise := 0.4
## Pitch change per second (negative = falls).
@export var sweep := 0.0

const RATE := 44100


func _ready() -> void:
	var n := int(RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += TAU * maxf(20.0, frequency + sweep * t) / RATE
		var env := exp(-decay * t) * minf(1.0, t * 2000.0)
		var v := (sin(phase) * (1.0 - noise) + rng.randf_range(-1.0, 1.0) * noise) * env
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	stream = wav
