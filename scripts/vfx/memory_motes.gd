class_name MemoryMotes
extends Node3D
## MEMORY MOTES: the visual half of a memory coming back. One soft burst of golden motes rising
## from the memory point, plus a brief warm light pop (no shadows, no fog) that touches the room.
## Fired by Memory.play_restore_moment() on the same frame as the restore sound, the glance and the
## warm screen flash (VFX research 09: every channel on the impact frame, then a slow release).
##
## How to use: MemoryMotes.burst(parent, world_position). It frees itself when done.

const LIFE := 2.6


static func burst(parent: Node, at: Vector3) -> MemoryMotes:
	var m := MemoryMotes.new()
	parent.add_child(m)
	m.global_position = at
	return m


func _ready() -> void:
	var p := VFXKit.particles(70, LIFE, 3.0)
	p.one_shot = true
	p.explosiveness = 0.85
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.35
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 70.0
	pm.initial_velocity_min = 0.25
	pm.initial_velocity_max = 0.7
	pm.gravity = Vector3(0, 0.12, 0)
	pm.damping_min = 0.6
	pm.damping_max = 1.2
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	# peak early, long soft tail (never linear)
	pm.scale_curve = VFXKit.curve([[0.0, 0.2], [0.12, 1.0], [0.6, 0.6], [1.0, 0.0]])
	pm.color_ramp = VFXKit.ramp([[0.0, Color(3.0, 2.0, 1.0, 1.0)], [0.25, Color(2.0, 1.1, 0.45, 0.9)],
		[1.0, Color(0.8, 0.35, 0.1, 0.0)]])
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 1.2
	pm.turbulence_noise_scale = 2.0
	pm.turbulence_influence_min = 0.05
	pm.turbulence_influence_max = 0.12
	p.process_material = pm
	p.draw_pass_1 = VFXKit.spark_mesh(0.022)
	add_child(p)
	p.emitting = true
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.68, 0.38)
	light.omni_range = 4.5
	light.light_energy = 0.0
	light.shadow_enabled = false
	light.light_volumetric_fog_energy = 0.0
	add_child(light)
	var tw := create_tween()
	tw.tween_property(light, "light_energy", 2.2, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(light, "light_energy", 0.0, 1.6).set_trans(Tween.TRANS_SINE)
	get_tree().create_timer(LIFE + 0.5).timeout.connect(queue_free)
