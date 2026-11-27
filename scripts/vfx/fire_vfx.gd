class_name FireVFX
extends Node3D
## FIRE VFX: the layers a real fire is made of, added around an existing flame emitter
## (VFX research 07: fire is a stack, not one effect).
##   Core   - a soft hot glow at the base; the brightest value in the effect, spent once
##   Embers - small sparks rising and cooling from yellow to deep red, leaning with the world's wind
##   Smoke  - dark, slow, thin wisps above the flames (keeps the fire from looking pasted on)
## The fire light is a FlickerLight; crackle sounds are played by whoever owns the fire.
##
## How to change it: size scales everything; embers / smoke = how many; heat 0..1 fades it.

@export var size := 1.0
@export var embers := 24
@export var smoke := 14
## Re-skin a sibling "Flames" emitter with the torn-edge flame shader (ember_wisp) and a
## hot-core-to-deep-red ramp, so the flame body reads as fire, not a soft white blob.
@export var restyle_sibling_flames := true
@export_range(0.0, 1.0) var heat := 1.0:
	set(v):
		heat = v
		_apply_heat()

var _core: MeshInstance3D
var _core_mat: StandardMaterial3D
var _sparks: GPUParticles3D
var _smoke: GPUParticles3D


func _ready() -> void:
	if restyle_sibling_flames:
		_restyle_flames()
	_core = MeshInstance3D.new()
	_core.name = "Core"
	var q := QuadMesh.new()
	q.size = Vector2(0.55, 0.32) * size
	_core_mat = StandardMaterial3D.new()
	_core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_core_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_core_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_core_mat.albedo_color = Color(0.9, 0.3, 0.06, 0.35)
	_core_mat.albedo_texture = VFXKit.dot()
	_core_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = _core_mat
	_core.mesh = q
	_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_core.position = Vector3(0, 0.06 * size, 0)
	add_child(_core)

	_sparks = VFXKit.particles(embers, 1.8, 2.0)
	_sparks.name = "Embers"
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(0.22, 0.04, 0.12) * size
	m.direction = Vector3(0, 1, 0)
	m.spread = 18.0
	m.initial_velocity_min = 0.35 * size
	m.initial_velocity_max = 0.9 * size
	m.gravity = Vector3(0.06, 0.25, 0)  # heat rises, with the same faint lean as the world's wind
	m.damping_min = 0.4
	m.damping_max = 1.0
	m.scale_min = 0.5
	m.scale_max = 1.2
	m.scale_curve = VFXKit.curve([[0.0, 1.0], [0.6, 0.7], [1.0, 0.0]])
	m.color_ramp = VFXKit.ramp([[0.0, Color(3.0, 1.6, 0.6, 1.0)], [0.35, Color(2.2, 0.7, 0.15, 1.0)],
		[0.8, Color(0.9, 0.15, 0.03, 0.7)], [1.0, Color(0.3, 0.03, 0.0, 0.0)]])
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 2.2
	m.turbulence_noise_scale = 1.4
	m.turbulence_influence_min = 0.15
	m.turbulence_influence_max = 0.4
	_sparks.process_material = m
	_sparks.draw_pass_1 = VFXKit.spark_mesh(0.016 * size)
	add_child(_sparks)

	_smoke = VFXKit.particles(smoke, 4.0, 3.0)
	_smoke.name = "Smoke"
	var s := ParticleProcessMaterial.new()
	s.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	s.emission_box_extents = Vector3(0.18, 0.05, 0.1) * size
	s.direction = Vector3(0, 1, 0)
	s.spread = 12.0
	s.initial_velocity_min = 0.15
	s.initial_velocity_max = 0.3
	s.gravity = Vector3(0.04, 0.18, 0)
	s.angle_min = -180.0
	s.angle_max = 180.0
	s.angular_velocity_min = -15.0
	s.angular_velocity_max = 15.0
	s.scale_min = 0.8
	s.scale_max = 1.3
	s.scale_curve = VFXKit.curve([[0.0, 0.3], [1.0, 1.0]])
	s.color_ramp = VFXKit.ramp([[0.0, Color(0.5, 0.3, 0.2, 0.0)], [0.2, Color(0.3, 0.27, 0.27, 0.32)],
		[1.0, Color(0.18, 0.18, 0.2, 0.0)]])
	s.turbulence_enabled = true
	s.turbulence_noise_strength = 1.4
	s.turbulence_noise_scale = 3.0
	s.turbulence_influence_min = 0.05
	s.turbulence_influence_max = 0.15
	_smoke.process_material = s
	var sq := QuadMesh.new()
	sq.size = Vector2(0.45, 0.45) * size
	var smat := ShaderMaterial.new()
	smat.shader = preload("res://shaders/ember_smoke.gdshader")
	smat.set_shader_parameter("noise_tex", VFXKit.noise())
	smat.set_shader_parameter("density", 0.16)
	sq.material = smat
	_smoke.draw_pass_1 = sq
	_smoke.position = Vector3(0, 0.6 * size, -0.05 * size)  # above and behind the flames, never veiling them
	add_child(_smoke)
	_apply_heat()


func _apply_heat() -> void:
	if _sparks == null:
		return
	_sparks.amount_ratio = heat
	_smoke.amount_ratio = heat
	_core.visible = heat > 0.02
	_core_mat.albedo_color.a = 0.35 * heat


func _restyle_flames() -> void:
	var flames := get_parent().get_node_or_null("Flames") as GPUParticles3D
	if not flames:
		return
	var pm := flames.process_material.duplicate() as ParticleProcessMaterial
	if pm:
		pm.color_ramp = VFXKit.ramp([[0.0, Color(1.0, 0.5, 0.12, 0.0)], [0.1, Color(1.0, 0.4, 0.06, 0.9)],
			[0.4, Color(0.85, 0.2, 0.03, 0.6)], [0.75, Color(0.45, 0.06, 0.01, 0.3)], [1.0, Color(0.15, 0.02, 0.0, 0.0)]])
		pm.angle_min = -12.0
		pm.angle_max = 12.0
		pm.turbulence_enabled = true
		pm.turbulence_noise_strength = 1.2
		pm.turbulence_noise_scale = 2.0
		pm.turbulence_noise_speed = Vector3(0, 0.5, 0)
		pm.turbulence_influence_min = 0.04
		pm.turbulence_influence_max = 0.12
		flames.process_material = pm
	var quad := QuadMesh.new()
	var old := flames.draw_pass_1 as QuadMesh
	quad.size = (old.size if old else Vector2(0.32, 0.42)) * 1.45
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/ember_wisp.gdshader")
	sm.set_shader_parameter("noise_tex", VFXKit.noise())
	sm.set_shader_parameter("energy", 1.15)
	sm.set_shader_parameter("stretch", 1.5)
	sm.set_shader_parameter("wisp", 0.8)
	quad.material = sm
	flames.draw_pass_1 = quad
	flames.amount = maxi(flames.amount, 46)
