extends Node
## AMBIENCE MIXER: crossfades the wind outside and the quiet house tone inside, following
## where the player stands.
## How to change it: the four volume values (dB) below; fade_speed = dB per second.

@export var player: PlayerBody
@export var wind_outside_db := -6.0
@export var wind_inside_db := -22.0
@export var house_outside_db := -60.0
@export var house_inside_db := -12.0
@export var fade_speed := 25.0

@onready var wind: AudioStreamPlayer = $WindLoop
@onready var house_tone: AudioStreamPlayer = $HouseToneLoop


func _ready() -> void:
	for p in [wind, house_tone]:
		if p.stream and "loop" in p.stream:
			p.stream.set("loop", true)
		p.play()


func _physics_process(delta: float) -> void:
	if not player:
		return
	var outside := player.is_outside()
	wind.volume_db = move_toward(wind.volume_db, wind_outside_db if outside else wind_inside_db, fade_speed * delta)
	house_tone.volume_db = move_toward(house_tone.volume_db, house_outside_db if outside else house_inside_db, fade_speed * delta)
