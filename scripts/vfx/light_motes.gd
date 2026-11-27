class_name LightMotes
extends Node3D
## LIGHT MOTES: warm dust and tiny embers drifting slowly in the pool of a lamp or doorway, the
## kind of life a still night scene needs (VFX research 07: warm motes in the light instead of
## fireflies on a snowy night). Few, slow, dim - never brighter than the light they sit in.
##
## How to change it: extents = the box they drift in (metres); count; brightness.

@export var extents := Vector3(1.2, 1.0, 1.2)
@export var count := 18
@export var brightness := 1.0


func _ready() -> void:
	var p := VFXKit.particles(count, 7.0, maxf(extents.x, maxf(extents.y, extents.z)) + 1.0)
	p.preprocess = 3.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = extents
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.01
	pm.initial_velocity_max = 0.05
	pm.gravity = Vector3(0.015, 0.02, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	pm.scale_curve = VFXKit.curve([[0.0, 0.0], [0.2, 1.0], [0.8, 1.0], [1.0, 0.0]])
	pm.color_ramp = VFXKit.ramp([[0.0, Color(1.4, 0.8, 0.35, 0.0)], [0.3, Color(1.4 * brightness, 0.8 * brightness, 0.35 * brightness, 0.8)],
		[0.7, Color(1.1 * brightness, 0.55 * brightness, 0.2 * brightness, 0.6)], [1.0, Color(0.8, 0.35, 0.1, 0.0)]])
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 1.5
	pm.turbulence_influence_min = 0.03
	pm.turbulence_influence_max = 0.08
	p.process_material = pm
	p.draw_pass_1 = VFXKit.spark_mesh(0.012)
	add_child(p)
