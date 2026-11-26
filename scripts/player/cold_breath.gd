extends GPUParticles3D
## COLD BREATH: a small puff of vapour every few seconds, only outside in the snow.
## How to change it: min_gap / max_gap = seconds between breaths. The look of the puff
## is in the particle settings in the Inspector.

@export var min_gap := 3.2
@export var max_gap := 4.6
## Turned off by cutscenes that need silence (the ending).
@export var breathing := true

@onready var player: PlayerBody = owner

var _timer := 2.0


func _process(delta: float) -> void:
	if not breathing or not player.is_outside():
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(min_gap, max_gap)
		restart()
