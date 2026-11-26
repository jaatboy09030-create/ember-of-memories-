extends Node
## SOUND (autoload, reachable from any script as `Sound`).
## Plays one-shot effects, positional effects and the music track.
##
## How to use:   Sound.play("door_slam")            -> flat sound
##               Sound.play_at("fire_loop", pos, -4, true)  -> 3D sound, looping
##               Sound.play_music("theme_full")     -> crossfades the music
## How to add a sound: drop <name>.mp3 / .ogg / .wav into res://assets/audio/ and call it
## by <name>. Missing files are skipped silently, so the game never crashes on audio.

## Folder that holds every sound file.
@export_dir var audio_folder := "res://assets/audio/"
## How far a 3D sound carries (bigger = audible from further away).
@export var positional_unit_size := 3.0

@onready var music_player: AudioStreamPlayer = $MusicPlayer


## Finds res://assets/audio/<sound_name>.(mp3|ogg|wav). Returns null if it doesn't exist.
func get_stream(sound_name: String) -> AudioStream:
	for ext in [".mp3", ".ogg", ".wav"]:
		var path := audio_folder.path_join(sound_name + ext)
		if ResourceLoader.exists(path):
			return load(path)
	return null


## Plays a flat (non-positional) sound once. pitch_variation adds a little randomness.
func play(sound_name: String, volume_db := 0.0, pitch_variation := 0.0) -> void:
	var stream := get_stream(sound_name)
	if not stream:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


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
