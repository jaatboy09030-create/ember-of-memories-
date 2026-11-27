class_name FlickerLight
extends OmniLight3D
## FLICKER LIGHT: a fire or oil-lamp light that breathes. Brightness follows two layers of
## smooth noise (a slow sway and a quick flutter) and the light drifts a few centimetres so the
## shadows it casts move too. The light sells a fire more than the flames do (VFX research 07).
##
## How to change it: base_energy = average brightness (tween this, not light_energy);
## flicker 0..1 = how much it wavers (fire ~0.35, oil lamp ~0.08); speed = how fast;
## jitter = how far the light wanders (metres).

@export var base_energy := 1.0
@export_range(0.0, 1.0) var flicker := 0.3
@export var speed := 1.0
@export var jitter := 0.03

var _noise := FastNoiseLite.new()
var _home: Vector3
var _t := 0.0


func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.seed = randi()
	_noise.frequency = 1.0
	_home = position


func _process(delta: float) -> void:
	_t += delta * speed
	var slow := _noise.get_noise_1d(_t * 1.3)          # the fire leaning and swelling
	var fast := _noise.get_noise_1d(_t * 9.0 + 100.0)  # quick flutter
	light_energy = maxf(0.0, base_energy * (1.0 + flicker * (0.65 * slow + 0.35 * fast)))
	if jitter > 0.0:
		position = _home + Vector3(_noise.get_noise_1d(_t * 2.1 + 40.0), _noise.get_noise_1d(_t * 1.7 + 70.0) * 0.6, _noise.get_noise_1d(_t * 2.3 + 90.0)) * jitter
