class_name Fireplace
extends Interactable
## FIREPLACE in the parent's room (memory 6, "relight the fire").
## Cold and dark until the end. Using it emits `chosen`; FireplaceMemory then plays the
## ending and calls ignite(), which grows the flames and brings up the fire light.
##
## How to change it: fire_light_energy = brightness of the lit fire; ignite_time = how
## long the flames take to catch. The flames themselves are the HearthFire/Flames particles.

signal chosen

@export var fire_light_energy := 4.5
@export var ignite_time := 1.8

@onready var hearth_fire: Node3D = $HearthFire
@onready var fire_light: FlickerLight = $FireLight
@onready var fire_layers: FireVFX = $HearthFire/FireLayers

var _crackle_in := 2.0


func _ready() -> void:
	super._ready()
	enabled = false
	hearth_fire.visible = false
	fire_light.base_energy = 0.0
	set_process(false)


func on_interact() -> void:
	super.on_interact()
	enabled = false
	chosen.emit()


## Where the ember flies to when it relights the fire.
func get_fire_position() -> Vector3:
	return hearth_fire.global_position


func ignite() -> void:
	Sound.play("fire_ignite", 0.0)
	Sound.play_at("fire_loop", hearth_fire.global_position + Vector3(0, 0.1, 0), -4.0, true)
	hearth_fire.visible = true
	hearth_fire.scale = Vector3.ONE * 0.05
	var tw := create_tween().set_parallel(true)
	tw.tween_property(hearth_fire, "scale", Vector3.ONE, ignite_time).set_trans(Tween.TRANS_BACK)
	tw.tween_property(fire_light, "base_energy", fire_light_energy, 3.0)
	# the light flares once as it catches, then settles (impact first, slow release)
	fire_light.light_energy = 0.0
	set_process(true)


## While lit: a crackle or pop every few seconds, never on a beat.
func _process(delta: float) -> void:
	_crackle_in -= delta
	if _crackle_in <= 0.0:
		_crackle_in = randf_range(1.8, 5.5)
		Sound.play_at("fire_crackle", hearth_fire.global_position + Vector3(randf_range(-0.2, 0.2), 0.15, 0), randf_range(-10.0, -4.0))
