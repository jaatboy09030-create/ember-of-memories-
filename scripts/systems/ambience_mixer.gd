extends Node
## AMBIENCE MIXER: the sound of the world, mixed like a small game's ambience pass.
##   - Beds: wind + a quiet snow-night bed outside, the house tone inside; crossfaded by where
##     the player stands.
##   - Sprinkles: random one-shots on top of the beds (wind gusts outside, the house creaking
##     inside), never on a fixed rhythm, so the loops never feel like loops.
##   - Clock: a ticking clock as a 3D sound in the hallway.
##   - One wind: every gust also raises the global shader value `wind_strength`, so the trees lean
##     and the snow drifts on the same beat you hear it (VFX research: one wind for everything).
## How to change it: the volumes (dB) and gap ranges (s) below; fade_speed = dB per second.

@export var player: PlayerBody
@export var wind_outside_db := -6.0
@export var wind_inside_db := -22.0
@export var house_outside_db := -60.0
@export var house_inside_db := -12.0
@export var snow_bed_outside_db := -10.0
@export var fade_speed := 25.0
## Random gaps between one-shots, in seconds (min, max).
@export var gust_gap := Vector2(14.0, 30.0)
@export var creak_gap := Vector2(20.0, 45.0)
@export var gust_db := -4.0
@export var creak_db := -6.0
## Where the hallway clock ticks (empty = no clock).
@export var clock_position := Vector3(0.0, 2.0, -8.7)
@export var clock_db := -10.0
## How strong a gust pushes the shared wind (1 = calm).
@export var gust_wind_peak := 2.6

@onready var wind: AudioStreamPlayer = $WindLoop
@onready var house_tone: AudioStreamPlayer = $HouseToneLoop

var _snow_bed: AudioStreamPlayer
var _next_gust := 6.0
var _next_creak := 12.0
var _wind := 1.0
var _clock: AudioStreamPlayer3D


func _ready() -> void:
	for p in [wind, house_tone]:
		if p.stream and "loop" in p.stream:
			p.stream.set("loop", true)
		p.play()
	var bed := Sound.get_stream("snow_night_loop")
	if bed:
		Sound._set_loop(bed)
		_snow_bed = AudioStreamPlayer.new()
		_snow_bed.stream = bed
		_snow_bed.volume_db = -60.0
		add_child(_snow_bed)
		_snow_bed.play()
	if clock_position != Vector3.ZERO:
		_clock = Sound.play_at("clock_tick_loop", clock_position, clock_db, true)
		if _clock:
			_clock.unit_size = 1.6
			_clock.max_distance = 9.0
	RenderingServer.global_shader_parameter_set("wind_strength", 1.0)


func _physics_process(delta: float) -> void:
	if not player:
		return
	var outside := player.is_outside()
	wind.volume_db = move_toward(wind.volume_db, wind_outside_db if outside else wind_inside_db, fade_speed * delta)
	house_tone.volume_db = move_toward(house_tone.volume_db, house_outside_db if outside else house_inside_db, fade_speed * delta)
	if _snow_bed:
		_snow_bed.volume_db = move_toward(_snow_bed.volume_db, snow_bed_outside_db if outside else -60.0, fade_speed * delta)
	_next_gust -= delta
	if _next_gust <= 0.0:
		_next_gust = randf_range(gust_gap.x, gust_gap.y)
		_gust(outside)
	_next_creak -= delta
	if _next_creak <= 0.0:
		_next_creak = randf_range(creak_gap.x, creak_gap.y)
		if not outside:
			Sound.play_at("house_creak", player.global_position + Vector3(randf_range(-4, 4), 2.2, randf_range(-4, 4)), creak_db)


## A gust: heard (louder outside, muffled through the walls inside) and seen (trees lean).
func _gust(outside: bool) -> void:
	Sound.play("wind_gust", gust_db if outside else gust_db - 14.0, 0.06)
	var tw := create_tween()
	tw.tween_method(_set_wind, _wind, gust_wind_peak, 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_method(_set_wind, gust_wind_peak, 1.0, 3.0).set_trans(Tween.TRANS_SINE)


func _set_wind(v: float) -> void:
	_wind = v
	RenderingServer.global_shader_parameter_set("wind_strength", v)
