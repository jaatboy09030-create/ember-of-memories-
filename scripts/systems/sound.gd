extends Node
## SOUND (autoload, reachable from any script as `Sound`).
## Plays one-shot effects, positional effects, voice lines and the music track, mixed the way a
## sound designer would set up a small game:
##   - VARIANTS: if <name>_1, <name>_2 ... exist, every play picks one at random (never the same one
##     twice in a row), so footsteps and pickups don't machine-gun the same clip.
##   - BUSES (made at start): "Music", "Voice" (present-day inner voice, dry and close),
##     "Memory" (remembered voices + memory sounds: low-passed with a soft room reverb).
##   - DUCKING: while any voice line plays, the Music bus dips by `duck_db` and comes back slowly.
##
## How to use:   Sound.play("door_slam")                     -> flat sound
##               Sound.play_at("fire_loop", pos, -4, true)   -> 3D sound, looping
##               Sound.play_voice("v_home")                  -> voice line (ducks music); returns its length
##               Sound.play_music("theme_full")              -> crossfades the music
## How to add a sound: drop <name>.ogg / .mp3 / .wav into res://assets/audio/ (or <name>_1, _2 ...
## for variants) and call it by <name>. Missing files are skipped silently.
## Loops should be .ogg (MP3 adds a tiny gap at the loop point).

## Folder that holds every sound file.
@export_dir var audio_folder := "res://assets/audio/"
## How far a 3D sound carries (bigger = audible from further away).
@export var positional_unit_size := 3.0
## Sounds that belong to a memory (played through the "Memory" bus).
@export var memory_sounds: PackedStringArray = ["memory_restore", "memory_wake", "heartbeat", "argument_muffled"]
## Voice lines that are someone in a memory speaking (Memory bus). Every other v_* line is the
## player's own present-day inner voice (Voice bus: close and dry).
@export var memory_voices: PackedStringArray = ["v_scarf", "v_artist", "v_letter", "v_slam"]
## How far the music dips under a voice line (dB) and how fast it recovers (s).
@export var duck_db := -8.0
@export var duck_release := 1.2

@onready var music_player: AudioStreamPlayer = $MusicPlayer

const MEMORY_BUS := "Memory"
const VOICE_BUS := "Voice"
const MUSIC_BUS := "Music"
const EXTS := [".ogg", ".mp3", ".wav"]

var _variants := {}       # name -> Array[AudioStream] (cached)
var _last_variant := {}   # name -> index played last
var _duck_tween: Tween
var _duck_until := 0.0
var _voice_player: AudioStreamPlayer  # the dialogue channel: one voice at a time
## Voice lines play this much faster, same pitch (1 = as recorded). Set it before the first line.
var voice_speed := 1.0


func _ready() -> void:
	_make_music_bus()
	_make_voice_bus()
	_make_memory_bus()
	music_player.bus = MUSIC_BUS


func _new_bus(bus_name: String) -> int:
	var existing := AudioServer.get_bus_index(bus_name)
	if existing != -1:
		return -1
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus_name)
	AudioServer.set_bus_send(i, "Master")
	return i


func _make_music_bus() -> void:
	_new_bus(MUSIC_BUS)


func _make_voice_bus() -> void:
	var i := _new_bus(VOICE_BUS)
	if i == -1:
		return
	var comp := AudioEffectCompressor.new()  # keeps whispers and louder words close together
	comp.threshold = -18.0
	comp.ratio = 2.0
	comp.attack_us = 8000.0
	comp.release_ms = 180.0
	AudioServer.add_bus_effect(i, comp)
	var rv := AudioEffectReverb.new()        # just a breath of room, so it sits in the space
	rv.room_size = 0.25
	rv.damping = 0.7
	rv.dry = 1.0
	rv.wet = 0.08
	AudioServer.add_bus_effect(i, rv)


func _make_memory_bus() -> void:
	var i := _new_bus(MEMORY_BUS)
	if i == -1:
		return
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 6500.0
	AudioServer.add_bus_effect(i, lp)
	var rv := AudioEffectReverb.new()
	rv.room_size = 0.72
	rv.damping = 0.6
	rv.spread = 0.8
	rv.predelay_msec = 40.0
	rv.dry = 0.85
	rv.wet = 0.28
	AudioServer.add_bus_effect(i, rv)


func _bus_for(sound_name: String) -> StringName:
	if sound_name.begins_with("blink/bvm_"):
		return MEMORY_BUS
	if sound_name.begins_with("blink/bvn_"):
		return VOICE_BUS
	if sound_name in memory_sounds or sound_name in memory_voices:
		return MEMORY_BUS
	if sound_name.begins_with("v_"):
		return VOICE_BUS
	return &"Master"


func _load_one(base: String) -> AudioStream:
	for ext in EXTS:
		var path := audio_folder.path_join(base + ext)
		if ResourceLoader.exists(path):
			return load(path)
	return null


## Finds res://assets/audio/<sound_name>.(ogg|mp3|wav), or one of its numbered variants
## (<sound_name>_1, _2 ...) at random. Returns null if nothing exists.
func get_stream(sound_name: String) -> AudioStream:
	if not _variants.has(sound_name):
		var list: Array[AudioStream] = []
		var k := 1
		while true:
			var s := _load_one("%s_%d" % [sound_name, k])
			if not s:
				break
			list.append(s)
			k += 1
		_variants[sound_name] = list
	var vs: Array = _variants[sound_name]
	if vs.is_empty():
		return _load_one(sound_name)
	var idx := randi() % vs.size()
	if vs.size() > 1 and idx == _last_variant.get(sound_name, -1):
		idx = (idx + 1 + randi() % (vs.size() - 1)) % vs.size()
	_last_variant[sound_name] = idx
	return vs[idx]


## Plays a flat (non-positional) sound once. pitch_variation adds a little randomness.
func play(sound_name: String, volume_db := 0.0, pitch_variation := 0.0) -> void:
	var stream := get_stream(sound_name)
	if not stream:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	p.bus = _bus_for(sound_name)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	if sound_name.begins_with("v_"):
		duck_music(stream.get_length())


## Plays a voice line on the dialogue channel (a new line replaces the one still speaking, and the
## music ducks under it). Returns its length in seconds (0 if missing), so captions can stay up
## exactly as long as the line.
func play_voice(voice_name: String, volume_db := 0.0) -> float:
	var stream := get_stream(voice_name)
	if not stream:
		return 0.0
	stop_voice()
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.bus = _bus_for(voice_name)
	if not is_equal_approx(voice_speed, 1.0):
		p.pitch_scale = voice_speed           # faster...
		p.bus = _pitch_fix_bus(p.bus)         # ...but the same pitch
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	_voice_player = p
	var length := stream.get_length() / voice_speed
	duck_music(length)
	return length


## 0..1 how far the line being spoken has got (-1 = nothing speaking).
func voice_progress() -> float:
	if _voice_player and is_instance_valid(_voice_player) and _voice_player.playing and _voice_player.stream:
		return _voice_player.get_playback_position() / maxf(0.01, _voice_player.stream.get_length())
	return -1.0


## Seconds left in the line being spoken (0 = nothing speaking).
func voice_time_left() -> float:
	if _voice_player and is_instance_valid(_voice_player) and _voice_player.playing and _voice_player.stream:
		return (_voice_player.stream.get_length() - _voice_player.get_playback_position()) / voice_speed
	return 0.0


## A bus that undoes the pitch rise of voice_speed, then sends to `target`.
func _pitch_fix_bus(target: StringName) -> StringName:
	var bus_name := String(target) + "_Paced"
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, target)
		var ps := AudioEffectPitchShift.new()
		ps.pitch_scale = 1.0 / voice_speed
		AudioServer.add_bus_effect(i, ps)
	return StringName(bus_name)


## Cuts the line being spoken (a blink, a scene cut) with a 40 ms fade so it doesn't click.
func stop_voice() -> void:
	if _voice_player and is_instance_valid(_voice_player):
		var p := _voice_player
		_voice_player = null
		var tw := p.create_tween()
		tw.tween_property(p, "volume_db", -60.0, 0.04)
		tw.tween_callback(p.queue_free)


## Length of a voice clip in seconds (0 if there is none).
func voice_length(voice_name: String) -> float:
	var s := get_stream(voice_name)
	return s.get_length() / voice_speed if s else 0.0


## Dips the Music bus for `seconds`, then brings it back slowly.
func duck_music(seconds: float) -> void:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus == -1:
		return
	_duck_until = maxf(_duck_until, Time.get_ticks_msec() / 1000.0 + seconds)
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_method(func(v: float): AudioServer.set_bus_volume_db(bus, v),
		AudioServer.get_bus_volume_db(bus), duck_db, 0.25)
	_duck_tween.tween_interval(maxf(0.0, _duck_until - Time.get_ticks_msec() / 1000.0 - 0.25))
	_duck_tween.tween_method(func(v: float): AudioServer.set_bus_volume_db(bus, v), duck_db, 0.0, duck_release)


## Plays a sound at a world position. Looping sounds are returned so the caller can stop them.
func play_at(sound_name: String, world_position: Vector3, volume_db := 0.0, looped := false) -> AudioStreamPlayer3D:
	var stream := get_stream(sound_name)
	if not stream:
		return null
	if looped:
		_set_loop(stream)
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.volume_db = volume_db
	p.unit_size = positional_unit_size
	p.bus = _bus_for(sound_name)
	add_child(p)
	p.global_position = world_position
	p.play()
	if not looped:
		p.finished.connect(p.queue_free)
	return p


## Fades the current track out and the new one in. Pass "" to just fade to silence.
func play_music(track_name: String, volume_db := -8.0, fade_time := 2.0) -> void:
	var stream := get_stream(track_name) if track_name != "" else null
	var tw := create_tween()
	if music_player.playing:
		tw.tween_property(music_player, "volume_db", -60.0, fade_time)
	if not stream:
		tw.tween_callback(music_player.stop)
		return
	_set_loop(stream)
	tw.tween_callback(func():
		music_player.stream = stream
		music_player.volume_db = -60.0
		music_player.play())
	tw.tween_property(music_player, "volume_db", volume_db, fade_time)


func _set_loop(stream: AudioStream) -> void:
	if "loop" in stream:
		stream.set("loop", true)
