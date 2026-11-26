class_name EmberFire
extends Node3D
## EMBER FIRE: makes the Ember a burning coal instead of a glowing ball.
##   - EmberCore (the sibling sphere) flickers
##   - a soft halo
##   - the Vefects Stylized Fire flame as its body (only if res://Vefects is installed;
##     the pack's licence keeps it out of the public repo, so the game runs without it)
##   - world-space flame tongues that stay behind as it moves: a comet tail
##   - sparks, and thin smoke wisps (shaders/ember_wisp + ember_smoke)
## It burns harder while moving, and the EmberLight flickers with it.
##
## How to change it: intensity (0..1, the title dims it while writing), flame_scale,
## flame_scene to swap the Vefects theme (Flames, Ethereal, Mystic...), tail/spark/smoke amounts.

@export_range(0.0, 1.0) var intensity := 1.0
@export_file("*.tscn") var flame_scene := "res://Vefects/Stylized Fire/VFX/Flames/Particles/VFX_Stylized_Fire_01_Cam_Oriented.tscn"
@export var flame_scale := 0.12
## Tail tongues left when resting (0..1); in flight it rises toward 1.
@export_range(0.0, 1.0) var tail_at_rest := 0.15
@export var light_energy := 2.2

@onready var _core: MeshInstance3D = get_parent().get_node_or_null("EmberCore")
@onready var _light: OmniLight3D = get_parent().get_node_or_null("EmberLight")

var mat: StandardMaterial3D
var _vfx: Node3D
var _halo: MeshInstance3D
var _flame: GPUParticles3D
var _sparks: GPUParticles3D
var _smoke: GPUParticles3D
var _last_pos := Vector3.INF
var _t := 0.0

static var _noise: NoiseTexture2D


func _ready() -> void:
	if _noise == null:
		var fn := FastNoiseLite.new()
		fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		fn.frequency = 0.012
		fn.fractal_octaves = 4
		_noise = NoiseTexture2D.new()
		_noise.width = 256
		_noise.height = 256
		_noise.seamless = true
		_noise.generate_mipmaps = true
		_noise.noise = fn
	if _core:
		mat = (_core.mesh.surface_get_material(0) as StandardMaterial3D)
		if mat:
			mat = mat.duplicate()
			_core.material_override = mat

	# Soft glow around it
	_halo = MeshInstance3D.new()
	_halo.name = "Halo"
	var q := QuadMesh.new()
	q.size = Vector2(0.4, 0.4)
	_halo.mesh = q
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	hm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	hm.albedo_texture = _radial(Color(1.0, 0.42, 0.1, 0.35), Color(0.8, 0.15, 0.02, 0.0))
	hm.albedo_color = Color(1.0, 0.7, 0.45)
	_halo.material_override = hm
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_halo)

	# The flame body: Vefects' hand-painted flame, scaled down to a coal-sized fire
	if flame_scene != "" and ResourceLoader.exists(flame_scene):
		_vfx = (load(flame_scene) as PackedScene).instantiate()
		_vfx.name = "Flame"
		_vfx.scale = Vector3.ONE * flame_scale
		_vfx.position = Vector3(0, -0.03, 0)
		add_child(_vfx)
	# The tail: world-space tongues left behind as it moves
	_flame = _make_flame()
	_flame.name = "Tail"
	add_child(_flame)
	_sparks = _make_sparks()
	_sparks.name = "Sparks"
	add_child(_sparks)
	_smoke = _make_smoke()
	_smoke.name = "Smoke"
	add_child(_smoke)


func _radial(inner: Color, outer: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, inner)
	g.set_color(1, outer)
	g.add_point(0.35, Color(inner.r, inner.g * 0.8, inner.b * 0.6, inner.a * 0.35))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64
	return tex


func _ramp(stops: Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(stops.map(func(s): return s[0]))
	g.colors = PackedColorArray(stops.map(func(s): return s[1]))
	var tex := GradientTexture1D.new()
	tex.gradient = g
	tex.use_hdr = true
	return tex


func _curve(points: Array) -> CurveTexture:
	var c := Curve.new()
	for p in points:
		c.add_point(Vector2(p[0], p[1]))
	var tex := CurveTexture.new()
	tex.curve = c
	return tex


func _base_particles(amount: int, life: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.local_coords = false  # world space: the trail stays where the ember has been
	p.randomness = 0.4
	p.visibility_aabb = AABB(Vector3(-6, -6, -6), Vector3(12, 12, 12))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	return p


func _make_flame() -> GPUParticles3D:
	var p := _base_particles(110, 0.75)
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 0.035
	m.direction = Vector3(0, 1, 0)
	m.spread = 25.0
	m.initial_velocity_min = 0.05
	m.initial_velocity_max = 0.2
	m.gravity = Vector3(0, 0.9, 0)  # heat rises: a resting ember burns like a candle
	m.damping_min = 0.6
	m.damping_max = 1.2
	m.angle_min = -180.0
	m.angle_max = 180.0
	m.angular_velocity_min = -60.0
	m.angular_velocity_max = 60.0
	m.scale_min = 0.6
	m.scale_max = 1.1
	m.scale_curve = _curve([[0.0, 0.55], [0.15, 1.0], [1.0, 0.05]])
	m.color_ramp = _ramp([[0.0, Color(1.0, 0.7, 0.3, 0.8)], [0.2, Color(1.0, 0.42, 0.08, 0.7)],
		[0.55, Color(0.85, 0.16, 0.03, 0.45)], [0.85, Color(0.4, 0.04, 0.01, 0.15)], [1.0, Color(0.15, 0.01, 0.0, 0.0)]])
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 1.4
	m.turbulence_noise_scale = 2.2
	m.turbulence_noise_speed = Vector3(0, 0.6, 0)
	m.turbulence_influence_min = 0.05
	m.turbulence_influence_max = 0.15
	p.process_material = m
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.09)
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/ember_wisp.gdshader")
	sm.set_shader_parameter("noise_tex", _noise)
	sm.set_shader_parameter("energy", 1.1)
	sm.set_shader_parameter("stretch", 1.35)
	quad.material = sm
	p.draw_pass_1 = quad
	return p


func _make_sparks() -> GPUParticles3D:
	var p := _base_particles(36, 1.6)
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 0.05
	m.direction = Vector3(0, 1, 0)
	m.spread = 70.0
	m.initial_velocity_min = 0.15
	m.initial_velocity_max = 0.7
	m.gravity = Vector3(0, 0.25, 0)
	m.damping_min = 0.3
	m.damping_max = 0.8
	m.scale_min = 0.4
	m.scale_max = 1.0
	m.scale_curve = _curve([[0.0, 1.0], [0.7, 0.7], [1.0, 0.0]])
	m.color_ramp = _ramp([[0.0, Color(2.4, 1.3, 0.5, 1.0)], [0.4, Color(2.0, 0.6, 0.12, 1.0)],
		[0.8, Color(1.0, 0.18, 0.03, 0.8)], [1.0, Color(0.5, 0.05, 0.0, 0.0)]])
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 2.5
	m.turbulence_noise_scale = 1.6
	m.turbulence_influence_min = 0.1
	m.turbulence_influence_max = 0.35
	p.process_material = m
	var quad := QuadMesh.new()
	quad.size = Vector2(0.018, 0.018)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.vertex_color_use_as_albedo = true
	sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	sm.albedo_texture = _radial(Color(1, 1, 1, 1), Color(1, 1, 1, 0))
	quad.material = sm
	p.draw_pass_1 = quad
	return p


func _make_smoke() -> GPUParticles3D:
	var p := _base_particles(26, 3.2)
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 0.04
	m.direction = Vector3(0, 1, 0)
	m.spread = 20.0
	m.initial_velocity_min = 0.1
	m.initial_velocity_max = 0.25
	m.gravity = Vector3(0, 0.22, 0)
	m.damping_min = 0.2
	m.damping_max = 0.4
	m.angle_min = -180.0
	m.angle_max = 180.0
	m.angular_velocity_min = -25.0
	m.angular_velocity_max = 25.0
	m.scale_min = 0.8
	m.scale_max = 1.3
	m.scale_curve = _curve([[0.0, 0.25], [1.0, 1.0]])
	m.color_ramp = _ramp([[0.0, Color(0.7, 0.35, 0.15, 0.0)], [0.12, Color(0.55, 0.36, 0.25, 0.5)],
		[0.45, Color(0.32, 0.3, 0.3, 0.35)], [1.0, Color(0.22, 0.22, 0.24, 0.0)]])
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 1.8
	m.turbulence_noise_scale = 3.0
	m.turbulence_noise_speed = Vector3(0.1, 0.3, 0)
	m.turbulence_influence_min = 0.08
	m.turbulence_influence_max = 0.2
	p.process_material = m
	var quad := QuadMesh.new()
	quad.size = Vector2(0.34, 0.34)
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/ember_smoke.gdshader")
	sm.set_shader_parameter("noise_tex", _noise)
	sm.set_shader_parameter("density", 0.3)
	quad.material = sm
	p.draw_pass_1 = quad
	return p


func _process(delta: float) -> void:
	_t += delta
	var speed := 0.0
	if _last_pos != Vector3.INF and delta > 0.0:
		speed = global_position.distance_to(_last_pos) / delta
	_last_pos = global_position
	var k := clampf(intensity, 0.0, 1.0)
	var rush := clampf(speed * 0.4, 0.0, 1.0)  # the air feeds it while it moves
	var flick := 1.0 + sin(_t * 9.0) * 0.06 + sin(_t * 23.0 + 1.3) * 0.04
	if _core:
		_core.scale = Vector3.ONE * flick
	if mat:
		mat.emission_energy_multiplier = (2.2 + 1.3 * k) * flick
	_halo.scale = Vector3.ONE * (0.85 + 0.15 * flick) * (0.6 + 0.4 * k)
	var rest := tail_at_rest if _vfx else 0.35 + 0.65 * k
	_flame.amount_ratio = clampf(rest + rush * 0.85, 0.0, 1.0)
	if _vfx:
		_vfx.scale = Vector3.ONE * flame_scale * (0.7 + 0.3 * k) * flick
	_sparks.amount_ratio = clampf(0.25 + 0.5 * k + rush * 0.5, 0.0, 1.0)
	_smoke.amount_ratio = clampf(0.3 + 0.7 * k - rush * 0.3, 0.0, 1.0)
	if _light:
		_light.light_energy = light_energy * (0.55 + 0.45 * k) * (1.0 + sin(_t * 7.0) * 0.07 + sin(_t * 13.0) * 0.04)
