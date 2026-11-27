class_name VFXKit
extends RefCounted
## VFX KIT: small shared builders for particle effects (gradients, curves, the noise texture,
## a GPUParticles3D with sane defaults). Used by FireVFX, MemoryMotes and LightMotes so every
## effect in the game shares one look (VFX research: one system, shared rules).

static var _noise: NoiseTexture2D


## Seamless noise for the torn-edge flame and smoke shaders. Data, not colour (linear).
static func noise() -> NoiseTexture2D:
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
	return _noise


## Colour over life. stops = [[offset, Color], ...]; HDR so emissive values above 1 bloom.
static func ramp(stops: Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(stops.map(func(s): return s[0]))
	g.colors = PackedColorArray(stops.map(func(s): return s[1]))
	var tex := GradientTexture1D.new()
	tex.gradient = g
	tex.use_hdr = true
	return tex


## A curve over life. points = [[t, value], ...] (never linear: front-load the peak).
static func curve(points: Array) -> CurveTexture:
	var c := Curve.new()
	for p in points:
		c.add_point(Vector2(p[0], p[1]))
	var tex := CurveTexture.new()
	tex.curve = c
	return tex


## Soft round dot (for sparks and motes).
static func dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.45))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 32
	tex.height = 32
	return tex


## A world-space GPU particle system with a tight visibility box (performance research: tight bounds).
static func particles(amount: int, lifetime: float, half_extent := 2.0) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.local_coords = false
	p.randomness = 0.4
	p.visibility_aabb = AABB(Vector3.ONE * -half_extent, Vector3.ONE * half_extent * 2.0)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	return p


## Additive, unshaded, camera-facing glowing dot of `size` metres (sparks, embers, motes).
static func spark_mesh(size: float) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.vertex_color_use_as_albedo = true
	sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	sm.albedo_texture = dot()
	quad.material = sm
	return quad
