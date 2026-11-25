extends Node3D
## EMBER LETTERS - full grey-box.
## The static level lives in scenes/level.tscn (instanced as "Level" in main.tscn) and
## can be edited in the editor. Key nodes are found by NAME, so don't rename:
##   WorldEnvironment, Light_<room>, Door_<name>, ScarfMesh, DrawingWall, StudyDoor,
##   Photo, FireMesh, FireLight, MarkerGate, MarkerFront.
## Rebuild it from code with:  godot --headless --path . -s res://tools/bake_level.gd
## Outside in snow -> gate ember -> house -> 4 memories -> final room reveal -> relight fire.
##
## Layout (top view, camera looks from +Z):
##   z -10 +-----------+-----------+-----------+
##         | PARENT    | HALLWAY   | BEDROOM   |
##         | (final)   | (argument)| (suitcase)|
##   z  -5 +-----------+-----------+-----------+
##         | KID ROOM  | LIVING    | KITCHEN   |
##         | (drawing) | (scarf)   | (decor)   |
##   z   0 +-----------+--door-----+-----------+
##                      garden path
##   z  10 ---fence---- GATE -----fence----
##   x:   -12         -4          4          12

var env: Environment
var player: CharacterBody3D
var ember: Node3D
var hint: Label
var caption: Label
var bar: ProgressBar
var fade: ColorRect
var title: Label
var snow: GPUParticles3D

var mats: Array = []          # [material, original colour] for desaturation
var room_lights := {}         # name -> OmniLight3D
var room_lamps := {}          # room -> Array[OmniLight3D] practical lamps
var doors := {}               # name -> MeshInstance3D blocker
var interacts: Array = []     # active interaction points
var e_prev := false
var cutscene := false
var cam_look := Vector3.ZERO
var stage := 0
var _knit: AudioStreamPlayer3D
var _knit_idle := 0.0
var _last_needle := -1
var _lmb_prev := false
var _rmb_prev := false
var _inspecting := false
var _puzzle_on := false

var sat := 0.3:
	set(v):
		sat = v
		RenderingServer.global_shader_parameter_set("world_sat", v)
		if fx_mat:
			fx_mat.set_shader_parameter("world_sat", v)


# ------------------------------------------------------------------ setup

## true only while tools/bake_level.gd builds scenes/level.tscn
var bake_mode := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var lvl := get_node_or_null("Level")
	if lvl:
		_build_environment()  # GI, fog, sky: runtime only (keeps the editor light)
		_bind_level(lvl)
		call_deferred("_scarf_visual", 0.0)
		_add_probes()  # level was baked into main.tscn: editable in the editor
	else:
		if not bake_mode:
			_build_environment()
		_build_exterior()
		_build_house()
		_build_rooms()
		_place_props()
	if bake_mode:
		return

	player = preload("res://scripts/player.gd").new()
	player.position = Vector3(0, 0.1, 15.0)
	add_child(player)

	ember = preload("res://scripts/ember.gd").new()
	ember.player = player
	ember.follow = false
	ember.anchor = Vector3(0, 1.3, 10.0)  # waits on the gate
	add_child(ember)

	_place_figures()
	_build_snow()
	_build_ui()
	_build_camera_fx()

	_build_audio()
	player.stepped.connect(_on_step)
	sat = 0.3
	if "--minitest" in OS.get_cmdline_user_args():
		_mini_test()
		return
	if "--walktest" in OS.get_cmdline_user_args():
		_walk_test()
		return
	if "--perf" in OS.get_cmdline_user_args():
		_perf_test()
		return
	if "--shots" in OS.get_cmdline_user_args():
		_shot_tour()
		return
	_opening()


func _mat(c: Color, emission := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	else:
		mats.append([m, c])
	return m


func _box(size: Vector3, pos: Vector3, c, collide := true, parent: Node = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = c if c is Material else _mat(c)
	parent.add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		body.add_child(cs)
		mi.add_child(body)
	return mi


func _marker(pos: Vector3) -> Marker3D:
	var m := Marker3D.new()
	m.position = pos
	add_child(m)
	return m


## Axis-aligned wall from a to b (on the ground) with door gaps (centres along the axis).
func _wall(a: Vector2, b: Vector2, h: float, c, gaps: Array = [], gap_w := 1.4) -> void:
	var along_x := is_equal_approx(a.y, b.y)
	var s := minf(a.x, b.x) if along_x else minf(a.y, b.y)
	var e := maxf(a.x, b.x) if along_x else maxf(a.y, b.y)
	var cuts: Array = []
	for g in gaps:
		cuts.append([g - gap_w * 0.5, g + gap_w * 0.5])
	cuts.sort()
	var cur := s
	for cut in cuts + [[e, e]]:
		var seg_end: float = cut[0]
		if seg_end - cur > 0.05:
			var mid := (cur + seg_end) * 0.5
			var length := seg_end - cur
			if along_x:
				_box(Vector3(length, h, 0.2), Vector3(mid, h * 0.5, a.y), c)
			else:
				_box(Vector3(0.2, h, length), Vector3(a.x, h * 0.5, mid), c)
		cur = cut[1]


const WALL_H := 2.8

func _door(door_name: String, pos: Vector3, along_x: bool) -> void:
	var size := Vector3(1.3, 2.15, 0.06) if along_x else Vector3(0.06, 2.15, 1.3)
	var paint := _tmat("dark_wooden_planks", Color(1.15, 1.0, 0.85), 1.1, 0.7)
	var d := _box(size, Vector3(pos.x, 1.075, pos.z), paint)
	d.name = "Door_" + door_name
	d.set_meta("along_x", along_x)
	doors[door_name] = d
	# raised panels both sides, brass knobs
	var panel := _mat(Color(0.42, 0.28, 0.18))
	for side in [-1.0, 1.0]:
		for py in [0.45, -0.35]:
			var ps := Vector3(0.95, 0.75, 0.02) if along_x else Vector3(0.02, 0.75, 0.95)
			var po := Vector3(0, py, 0.04 * side) if along_x else Vector3(0.04 * side, py, 0)
			_box(ps, po, panel, false, d)
		var knob := MeshInstance3D.new()
		var km := SphereMesh.new()
		km.radius = 0.035
		km.height = 0.07
		knob.mesh = km
		knob.material_override = _mat(Color(0.75, 0.58, 0.3))
		knob.position = (Vector3(0.5, -0.07, 0.06 * side) if along_x else Vector3(0.06 * side, -0.07, 0.5))
		d.add_child(knob)
	# frame trim around the opening (static)
	var trim := _mat(Color(0.3, 0.2, 0.13))
	for e in [-0.7, 0.7]:
		var ts := Vector3(0.09, 2.25, 0.28) if along_x else Vector3(0.28, 2.25, 0.09)
		var tp := Vector3(pos.x + e, 1.125, pos.z) if along_x else Vector3(pos.x, 1.125, pos.z + e)
		_box(ts, tp, trim, false)
	var hs := Vector3(1.58, 0.1, 0.28) if along_x else Vector3(0.28, 0.1, 1.58)
	_box(hs, Vector3(pos.x, 2.22, pos.z), trim, false)


func _open_door(door_name: String) -> void:
	if not doors.has(door_name):
		return
	var d: MeshInstance3D = doors[door_name]
	doors.erase(door_name)
	_sfx3d("door_creak", d.global_position + Vector3(0, 0.2, 0), -2.0)
	# swing 100 degrees on the left hinge, into the room ahead
	var along_x: bool = d.get_meta("along_x", absf(d.scale.x) >= 0.0 and (d.mesh as BoxMesh).size.x > 0.5)
	var hinge := d.position + (Vector3(-0.65, 0, 0) if along_x else Vector3(0, 0, 0.65))
	var start := d.position - hinge
	var tw := create_tween()
	tw.tween_method(func(a: float):
		d.rotation.y = a
		d.position = hinge + start.rotated(Vector3.UP, a), 0.0, deg_to_rad(100.0), 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _light(room: String, pos: Vector3, energy := 0.6) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = Color(0.6, 0.65, 0.8)
	l.light_energy = energy
	l.omni_range = 6.0
	l.omni_attenuation = 1.4
	l.light_size = 0.4         # very soft fill
	l.light_specular = 0.2
	l.shadow_enabled = false
	l.distance_fade_enabled = true
	l.distance_fade_begin = 16.0
	l.shadow_blur = 1.3
	add_child(l)
	room_lights[room] = l
	l.name = "Light_" + room


## A practical lamp (oil lamp, desk lamp, candle): dark while the memory is frozen,
## warm when it is restored.
func _lamp(room: String, pos: Vector3, energy := 1.3, rng := 5.0) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = Color(1.0, 0.62, 0.32)
	l.light_energy = 0.0
	l.omni_range = rng
	l.omni_attenuation = 1.6
	l.light_size = 0.06
	l.shadow_enabled = false
	l.distance_fade_enabled = true
	l.distance_fade_begin = 14.0
	l.set_meta("e", energy)
	l.name = "Lamp_%s_%d" % [room, room_lamps.get(room, []).size()]
	add_child(l)
	if not room_lamps.has(room):
		room_lamps[room] = []
	room_lamps[room].append(l)


func _warm_room(room: String, energy := 1.6) -> void:
	var l: OmniLight3D = room_lights[room]
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "light_color", Color(1.0, 0.7, 0.45), 2.5)
	tw.tween_property(l, "light_energy", energy * 0.6, 2.5)
	for lamp in room_lamps.get(room, []):
		tw.tween_property(lamp, "light_energy", float(lamp.get_meta("e", 1.3)), 3.0).set_trans(Tween.TRANS_SINE)


func _set_sat(v: float, time := 2.5) -> void:
	create_tween().tween_property(self, "sat", v, time)


# ------------------------------------------------------------------ world

var _tm_cache := {}

## Textured triplanar material (follows the memory colour level).
func _tmat(tex: String, tint := Color.WHITE, scale := 0.5, rough := 0.85) -> StandardMaterial3D:
	var key := "%s|%s|%s|%s" % [tex, tint, scale, rough]
	if _tm_cache.has(key):
		return _tm_cache[key]
	var m := StandardMaterial3D.new()
	var base := "res://assets/textures/%s/%s" % [tex, tex]
	m.albedo_texture = load(base + "_diff.jpg")
	m.albedo_color = Color(minf(tint.r, 1.0), minf(tint.g, 1.0), minf(tint.b, 1.0))
	if ResourceLoader.exists(base + "_nor.jpg"):
		m.normal_enabled = true
		m.normal_texture = load(base + "_nor.jpg")
		m.normal_scale = 0.9
	if ResourceLoader.exists(base + "_rough.jpg"):
		m.roughness_texture = load(base + "_rough.jpg")
		m.roughness = 1.0
	else:
		m.roughness = rough
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 4.0
	m.uv1_scale = Vector3.ONE * scale
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_tm_cache[key] = m
	return m


func _glow_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func _build_environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.018, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.38, 0.6)
	env.ambient_light_energy = 0.14
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.05
	# Real-time global illumination: light bounces off walls, floors and snow
	env.sdfgi_enabled = true
	env.sdfgi_use_occlusion = true
	env.sdfgi_cascades = 3
	env.sdfgi_min_cell_size = 0.12
	env.sdfgi_bounce_feedback = 0.45
	env.sdfgi_energy = 1.1
	env.ssao_enabled = true
	env.ssao_radius = 1.1
	env.ssao_intensity = 1.8
	env.ssao_power = 1.5
	env.ssil_enabled = false
	env.ssil_intensity = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 1.4
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.0025   # almost clear air: only light shafts read
	env.volumetric_fog_albedo = Color(0.85, 0.88, 1.0)
	env.volumetric_fog_emission = Color(0, 0, 0)
	env.volumetric_fog_anisotropy = 0.7    # forward scattering = beams toward camera
	env.volumetric_fog_gi_inject = 0.0
	# Colour grade
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.05
	var we: WorldEnvironment = get_node_or_null("WorldEnvironment")
	if not we:
		we = WorldEnvironment.new()
		we.name = "WorldEnvironment"
		add_child(we)
	we.environment = env

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-38, 25, 0)
	moon.light_color = Color(0.55, 0.66, 1.0)
	moon.light_energy = 0.5
	moon.light_angular_distance = 0.6  # soft moon shadows
	moon.shadow_enabled = true
	moon.shadow_blur = 1.5
	moon.directional_shadow_max_distance = 60.0
	moon.light_volumetric_fog_energy = 0.6
	moon.name = "Moon"
	add_child(moon)


func _build_exterior() -> void:
	var snow_m := _tmat("asphalt_snow", Color(1.05, 1.07, 1.12), 0.25, 0.7)
	_box(Vector3(80, 0.2, 60), Vector3(0, -0.1, 8), snow_m)
	# Cobblestone path (snow-dusted) from the gate to the porch
	var path_m := _tmat("cobblestone_floor_01", Color(0.85, 0.88, 0.95), 0.6)
	_box(Vector3(1.6, 0.04, 9.4), Vector3(0, 0.02, 5.3), path_m, false)
	# Porch steps + porch roof
	var plank := _tmat("dark_wooden_planks", Color(0.9, 0.85, 0.8), 0.7)
	_box(Vector3(3.0, 0.16, 1.2), Vector3(0, 0.08, 0.7), plank, false)
	_box(Vector3(2.4, 0.16, 0.5), Vector3(0, 0.08, 1.45), plank, false)
	# Walkable: an invisible gentle ramp up onto the porch (the player can't climb steps)
	var ramp := StaticBody3D.new()
	var rs := CollisionShape3D.new()
	var rb := BoxShape3D.new()
	rb.size = Vector3(3.0, 0.1, 3.6)
	rs.shape = rb
	ramp.add_child(rs)
	# top surface: ~0.17 at the doorway, slightly below the ground at the path end (no lip)
	ramp.position = Vector3(0, 0.03, 1.3)
	ramp.rotation.x = atan2(0.2, 3.6)  # high end toward the door (-z)
	add_child(ramp)
	_box(Vector3(3.4, 0.12, 1.6), Vector3(0, 2.75, 0.75), _tmat("clay_roof_tiles", Color.WHITE, 0.8))
	for x in [-1.4, 1.4]:
		_box(Vector3(0.14, 2.6, 0.14), Vector3(x, 1.4, 1.4), plank)
	# Picket fence with the gate gap (MultiMesh: cheap and clean)
	_fence(Vector2(-12, 10), Vector2(12, 10), [0.0])
	_fence(Vector2(-12, 0.2), Vector2(-12, 10), [])
	_fence(Vector2(12, 0.2), Vector2(12, 10), [])
	_fence(Vector2(-12, 0.3), Vector2(HOUSE_X0 - 0.1, 0.3), [])
	_fence(Vector2(HOUSE_X1 + 0.1, 0.3), Vector2(12, 0.3), [])
	_collider(Vector3((-12 + HOUSE_X0) * 0.5, 1, 0.3), Vector3(absf(-12 - HOUSE_X0), 2, 0.3))
	_collider(Vector3((12 + HOUSE_X1) * 0.5, 1, 0.3), Vector3(absf(12 - HOUSE_X1), 2, 0.3))
	# Invisible boundary so the player stays in the garden / lane
	for wpos in [[Vector3(-12, 1, 5.1), Vector3(0.3, 2, 9.8)], [Vector3(12, 1, 5.1), Vector3(0.3, 2, 9.8)],
			[Vector3(-6.6, 1, 10), Vector3(10.8, 2, 0.3)], [Vector3(6.6, 1, 10), Vector3(10.8, 2, 0.3)],
			[Vector3(0, 1, 19), Vector3(14, 2, 0.3)], [Vector3(-7, 1, 14.5), Vector3(0.3, 2, 9)], [Vector3(7, 1, 14.5), Vector3(0.3, 2, 9)]]:
		_collider(wpos[0], wpos[1])
	# Gate posts with lanterns, gate leaves left open
	var post_m := _tmat("dark_wooden_planks", Color(0.95, 0.92, 0.88), 0.8)
	for x in [-0.95, 0.95]:
		_box(Vector3(0.22, 1.3, 0.22), Vector3(x, 0.65, 10), post_m)
		_box(Vector3(0.3, 0.06, 0.3), Vector3(x, 1.33, 10), _mat(Color(0.95, 0.97, 1.0)), false)
	for side in [-1.0, 1.0]:
		var leaf := Node3D.new()
		leaf.name = "GateL" if side < 0 else "GateR"
		leaf.position = Vector3(0.85 * side, 0, 10.0)
		leaf.rotation_degrees.y = -100.0 * side
		add_child(leaf)
		var gm := _mat(Color(0.86, 0.84, 0.8))
		for k in 4:
			_box(Vector3(0.08, 0.95, 0.03), Vector3(side * (0.12 + k * 0.2), 0.5, 0), gm, false, leaf)
		for y in [0.3, 0.75]:
			_box(Vector3(0.8, 0.06, 0.03), Vector3(side * 0.42, y, 0.02), gm, false, leaf)
	# Mailbox
	_box(Vector3(0.1, 1.0, 0.1), Vector3(2.0, 0.5, 10.6), post_m)
	_box(Vector3(0.36, 0.28, 0.55), Vector3(2.0, 1.12, 10.6), _mat(Color(0.5, 0.16, 0.14)))
	_box(Vector3(0.4, 0.05, 0.6), Vector3(2.0, 1.28, 10.6), _mat(Color(0.95, 0.97, 1.0)), false)
	# Street lamp outside the gate: the one warm light in the cold
	_prop("street_lamp_02", Vector3(-2.1, 0, 11.0), 3.4, 0, false, 0.6)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(-2.1, 3.1, 11.0)
	lamp.light_color = Color(1.0, 0.72, 0.42)
	lamp.light_energy = 2.2
	lamp.omni_range = 9.0
	lamp.shadow_enabled = true
	lamp.light_volumetric_fog_energy = 2.0
	add_child(lamp)
	# Pine trees around the house and the lane
	var pines := [Vector3(-10.5, 0, 6.5), Vector3(10.5, 0, 7.0), Vector3(-17, 0, -3), Vector3(17, 0, -7),
		Vector3(-12, 0, 17), Vector3(12, 0, 18), Vector3(-19, 0, 10), Vector3(19, 0, 11)]
	for i in pines.size():
		_pine(pines[i], 6.0 + float(i % 3) * 1.3, float(i) * 47.0)
	for p in [Vector3(-7.5, 0, 8.0), Vector3(7.0, 0, 8.2), Vector3(-5.5, 0, 5.0), Vector3(9.0, 0, 3.0), Vector3(-10.0, 0, 2.5)]:
		_pine(p, 2.2, p.x * 30.0)
	_prop("tree_stump_01", Vector3(5.5, 0, 3.0), 0.45, 20, false, 1.0)
	_prop("garden_gnome", Vector3(3.0, 0, 6.0), 0.4, 200, false, 0.7)
	_prop("wooden_crate_01", Vector3(-5.5, 0, 1.0), 0.5, 15, false, 1.0)
	# More garden: shrubs along the house, picnic table, saplings, snow drifts
	for sp in [[Vector3(-3.0, 0, 0.9), "shrub_02"], [Vector3(3.2, 0, 0.9), "shrub_03"], [Vector3(-8.5, 0, 0.8), "shrub_02"], [Vector3(6.5, 0, 0.9), "shrub_03"], [Vector3(10.5, 0, 0.8), "shrub_02"]]:
		_prop(sp[1], sp[0], 0.9, sp[0].x * 40.0, false, 0.9)
	_prop("wooden_picnic_table", Vector3(-7.5, 0, 5.5), 0.8, 20, true, 1.0)
	for p2 in [Vector3(9.5, 0, 8.5), Vector3(-10.0, 0, 8.6), Vector3(4.5, 0, 8.8)]:
		_prop("pine_sapling_small", p2, 0.9, p2.x * 13.0, false, 0.9)
	_prop("tree_stump_02", Vector3(-9.0, 0, 2.5), 0.4, 70, false, 1.0)
	_snow_drifts()
	var mist := FogVolume.new()
	mist.size = Vector3(90, 2.4, 50)
	mist.position = Vector3(0, 0.6, 12)
	var fmat := FogMaterial.new()
	fmat.density = 0.06
	fmat.albedo = Color(0.7, 0.76, 0.92)
	fmat.height_falloff = 1.4
	fmat.edge_fade = 0.6
	mist.material = fmat
	add_child(mist)


func _fence(a: Vector2, b: Vector2, gaps: Array) -> void:
	var along_x := is_equal_approx(a.y, b.y)
	var length := (b - a).length()
	var count := int(length / 0.2)
	var xforms: Array[Transform3D] = []
	for i in count:
		var t := (float(i) + 0.5) / count
		var p := a.lerp(b, t)
		var along := p.x if along_x else p.y
		var skip := false
		for g in gaps:
			if absf(along - g) < 1.0:
				skip = true
		if skip:
			continue
		var h := 0.95 + 0.04 * sin(float(i) * 1.7)
		xforms.append(Transform3D(Basis.from_scale(Vector3(0.09, h, 0.035)).rotated(Vector3.UP, 0.0 if along_x else PI * 0.5), Vector3(p.x, h * 0.5, p.y)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _mat(Color(0.86, 0.84, 0.8))
	add_child(mmi)
	# Rails + snow caps
	var s0 := a.x if along_x else a.y
	var s1 := b.x if along_x else b.y
	for seg in _segments(s0, s1, gaps, 2.0):
		var m: float = (seg[0] + seg[1]) * 0.5
		var ln: float = seg[1] - seg[0]
		var rail := Vector3(ln, 0.06, 0.04) if along_x else Vector3(0.04, 0.06, ln)
		var rp := Vector3(m, 0, a.y) if along_x else Vector3(a.x, 0, m)
		for y in [0.3, 0.75]:
			_box(rail, Vector3(rp.x, y, rp.z), _mat(Color(0.8, 0.78, 0.74)), false)


func _collider(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	add_child(body)


# Room rectangles: [name, x0, x1, z0, z1, wall material, floor material]
var _rooms := []
## Compact cottage (13.5 x 9 m). Front row: kid | living | kitchen. Back row: parent | hall | bedroom.
const HOUSE_X0 := -7.5
const HOUSE_X1 := 6.0
const HOUSE_Z1 := -9.0
# Doorways: [centre (x,z), along_x]
const DOORWAYS := [[Vector2(0, 0), true], [Vector2(-0.75, -4.5), true], [Vector2(-3.0, -2.25), false],
	[Vector2(3.0, -1.6), false], [Vector2(-2.5, -6.6), false], [Vector2(1.0, -6.6), false]]


func _build_house() -> void:
	var clad := _tmat("exterior_wall_cladding", Color(0.78, 0.8, 0.88), 0.45)
	var plaster := _tmat("painted_plaster_wall", Color(0.92, 0.9, 0.86), 0.4)
	var floor_m := _tmat("old_wood_floor", Color.WHITE, 0.35, 0.7)
	_rooms = [
		["kid", -7.5, -3.0, -4.5, 0.0, _tmat("beige_wall_001", Color(0.8, 0.88, 1.0), 0.5), floor_m],
		["living", -3.0, 3.0, -4.5, 0.0, _tmat("beige_wall_001", Color(1.0, 0.93, 0.82), 0.5), floor_m],
		["kitchen", 3.0, 6.0, -4.5, 0.0, _tmat("painted_plaster_wall", Color(0.95, 0.97, 0.88), 0.45), _tmat("dark_wooden_planks", Color(1.0, 0.95, 0.9), 0.5)],
		["parent", -7.5, -2.5, -9.0, -4.5, _tmat("painted_plaster_wall", Color(1.0, 0.86, 0.82), 0.45), floor_m],
		["hall", -2.5, 1.0, -9.0, -4.5, _tmat("beige_wall_001", Color(0.95, 0.9, 0.82), 0.5), floor_m],
		["bed", 1.0, 6.0, -9.0, -4.5, _tmat("painted_plaster_wall", Color(0.84, 0.92, 0.86), 0.45), floor_m],
	]
	# Structural walls (outer: cladding; inner: plaster)
	_wall(Vector2(HOUSE_X0 - 0.1, HOUSE_Z1), Vector2(HOUSE_X1 + 0.1, HOUSE_Z1), WALL_H, clad)
	_wall(Vector2(HOUSE_X0, HOUSE_Z1), Vector2(HOUSE_X0, 0), WALL_H, clad)
	_wall(Vector2(HOUSE_X1, HOUSE_Z1), Vector2(HOUSE_X1, 0), WALL_H, clad)
	_wall(Vector2(HOUSE_X0 - 0.1, 0), Vector2(HOUSE_X1 + 0.1, 0), WALL_H, clad, [0.0])
	_wall(Vector2(HOUSE_X0, -4.5), Vector2(HOUSE_X1, -4.5), WALL_H, plaster, [-0.75])
	_wall(Vector2(-3.0, -4.5), Vector2(-3.0, 0), WALL_H, plaster, [-2.25])
	_wall(Vector2(3.0, -4.5), Vector2(3.0, 0), WALL_H, plaster, [-1.6])
	_wall(Vector2(-2.5, HOUSE_Z1), Vector2(-2.5, -4.5), WALL_H, plaster, [-6.6])
	_wall(Vector2(1.0, HOUSE_Z1), Vector2(1.0, -4.5), WALL_H, plaster, [-6.6])
	for d in DOORWAYS:
		var s := Vector3(1.4, WALL_H - 2.2, 0.2) if d[1] else Vector3(0.2, WALL_H - 2.2, 1.4)
		_box(s, Vector3(d[0].x, 2.2 + s.y * 0.5, d[0].y), plaster, false)
	for r in _rooms:
		var cx: float = (r[1] + r[2]) * 0.5
		var cz: float = (r[3] + r[4]) * 0.5
		var w: float = r[2] - r[1]
		var dpt: float = r[4] - r[3]
		_box(Vector3(w, 0.06, dpt), Vector3(cx, 0.03, cz), r[6], false)
		_box(Vector3(w, 0.05, dpt), Vector3(cx, WALL_H - 0.025, cz), _mat(Color(0.93, 0.92, 0.9)), false)
		_line_room(r)
		var beam := _tmat("dark_wooden_planks", Color(0.85, 0.7, 0.58), 1.0, 0.8)
		var bx: float = r[1] + 0.75
		while bx < r[2] - 0.4:
			_box(Vector3(0.16, 0.2, dpt - 0.25), Vector3(bx, WALL_H - 0.12, cz), beam, false)
			bx += 1.5
	# Roof (ridge along X over the middle wall), snow, gables, chimney
	var roof_m := _tmat("clay_roof_tiles", Color(0.9, 0.9, 0.95), 0.7)
	var cxh := (HOUSE_X0 + HOUSE_X1) * 0.5
	var wid := HOUSE_X1 - HOUSE_X0 + 1.2
	var pitch := atan2(2.2, 4.5)
	var slab := 4.5 / cos(pitch) + 0.6
	for side in [-1.0, 1.0]:
		var rs := _box(Vector3(wid, 0.18, slab), Vector3(cxh, WALL_H + 1.1 + 0.1, -4.5 + side * 2.25), roof_m, false)
		rs.rotation.x = side * pitch
		var sn := _box(Vector3(wid - 0.2, 0.06, slab - 0.4), Vector3(cxh, WALL_H + 1.1 + 0.22, -4.5 + side * 2.25), _mat(Color(0.93, 0.95, 1.0)), false)
		sn.rotation.x = side * pitch
	for x in [HOUSE_X0, HOUSE_X1]:
		var g := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(9.2, 2.2, 0.2)
		g.mesh = pm
		g.material_override = clad
		g.position = Vector3(x, WALL_H + 1.1, -4.5)
		g.rotation_degrees.y = 90
		add_child(g)
	_box(Vector3(0.9, 3.4, 1.2), Vector3(-7.1, WALL_H + 1.7, -5.75), _tmat("brick_wall_02", Color.WHITE, 0.9), false)
	# Windows: [pos on wall, outward normal]
	for w in WINDOW_LIST:
		_window(w[0], w[1])
	var frame_m := _mat(Color(0.32, 0.2, 0.13))
	_box(Vector3(0.12, 2.3, 0.3), Vector3(-0.76, 1.15, 0), frame_m, false)
	_box(Vector3(0.12, 2.3, 0.3), Vector3(0.76, 1.15, 0), frame_m, false)
	# Gated doors (the kitchen is an open archway)
	_door("front", Vector3(0, 0, 0), true)
	_door("kid", Vector3(-3.0, 0, -2.25), false)
	_door("hall", Vector3(-0.75, 0, -4.5), true)
	_door("bed", Vector3(1.0, 0, -6.6), false)
	_door("parent", Vector3(-2.5, 0, -6.6), false)
	# Soft fill per room (cool while the memory is frozen)
	for r in _rooms:
		_light(r[0], Vector3((r[1] + r[2]) * 0.5, 1.5, (r[3] + r[4]) * 0.5), 0.6)
	for l in room_lights.values():
		l.light_energy *= 1.1
	# Porch lantern: someone left it burning
	_prop("wooden_lantern_01", Vector3(1.05, 1.75, 0.2), 0.35)
	var porch := OmniLight3D.new()
	porch.position = Vector3(1.05, 1.8, 0.5)
	porch.light_color = Color(1.0, 0.6, 0.3)
	porch.light_energy = 1.2
	porch.omni_range = 5.0
	porch.shadow_enabled = true
	add_child(porch)


const WINDOW_LIST := [
	[Vector3(-5.25, 1.45, 0), Vector3(0, 0, 1)], [Vector3(-2.0, 1.45, 0), Vector3(0, 0, 1)],
	[Vector3(2.0, 1.45, 0), Vector3(0, 0, 1)], [Vector3(4.5, 1.45, 0), Vector3(0, 0, 1)],
	[Vector3(-7.5, 1.45, -2.25), Vector3(-1, 0, 0)], [Vector3(6.0, 1.45, -2.25), Vector3(1, 0, 0)],
	[Vector3(-3.6, 1.45, -9.0), Vector3(0, 0, -1)], [Vector3(3.4, 1.45, -9.0), Vector3(0, 0, -1)],
	[Vector3(6.0, 1.45, -6.1), Vector3(1, 0, 0)],
]


## Wallpaper lining + skirting on the inside of each room, leaving doorway gaps.
func _line_room(r: Array) -> void:
	var x0: float = r[1]
	var x1: float = r[2]
	var z0: float = r[3]
	var z1: float = r[4]
	var paper: Material = r[5]
	var skirt := _mat(Color(0.3, 0.2, 0.14))
	var sides := [[Vector2(x0, z0), Vector2(x1, z0), Vector3(0, 0, 1)], [Vector2(x0, z1), Vector2(x1, z1), Vector3(0, 0, -1)],
		[Vector2(x0, z0), Vector2(x0, z1), Vector3(1, 0, 0)], [Vector2(x1, z0), Vector2(x1, z1), Vector3(-1, 0, 0)]]
	for s in sides:
		var a: Vector2 = s[0]
		var b: Vector2 = s[1]
		var n: Vector3 = s[2]
		var along_x := is_equal_approx(a.y, b.y)
		var gaps := []
		for d in DOORWAYS:
			var c: Vector2 = d[0]
			if d[1] == along_x:
				if along_x and absf(c.y - a.y) < 0.01 and c.x > a.x and c.x < b.x:
					gaps.append(c.x)
				elif not along_x and absf(c.x - a.x) < 0.01 and c.y > a.y and c.y < b.y:
					gaps.append(c.y)
		var off := Vector2(n.x, n.z) * 0.115
		var segs := _segments(a.x if along_x else a.y, b.x if along_x else b.y, gaps, 1.4)
		for seg in segs:
			var mid: float = (seg[0] + seg[1]) * 0.5
			var length: float = seg[1] - seg[0]
			var size := Vector3(length, WALL_H, 0.02) if along_x else Vector3(0.02, WALL_H, length)
			var pos := Vector3(mid, WALL_H * 0.5, a.y) if along_x else Vector3(a.x, WALL_H * 0.5, mid)
			_box(size, pos + Vector3(off.x, 0, off.y), paper, false)
			var wood := _tmat("dark_wooden_planks", Color(1.0, 0.82, 0.68), 1.3, 0.7)
			var trim := _mat(Color(0.32, 0.21, 0.14))
			var ws := Vector3(length, 0.95, 0.03) if along_x else Vector3(0.03, 0.95, length)
			_box(ws, Vector3(pos.x, 0.475, pos.z) + Vector3(off.x, 0, off.y) * 1.12, wood, false)
			var rs := Vector3(length, 0.05, 0.06) if along_x else Vector3(0.06, 0.05, length)
			_box(rs, Vector3(pos.x, 0.97, pos.z) + Vector3(off.x, 0, off.y) * 1.2, trim, false)
			var cs := Vector3(length, 0.1, 0.07) if along_x else Vector3(0.07, 0.1, length)
			_box(cs, Vector3(pos.x, WALL_H - 0.08, pos.z) + Vector3(off.x, 0, off.y) * 1.2, trim, false)
			var ss := Vector3(length, 0.14, 0.03) if along_x else Vector3(0.03, 0.14, length)
			_box(ss, Vector3(pos.x, 0.07, pos.z) + Vector3(off.x, 0, off.y) * 1.15, skirt, false)
		for g in gaps:
			var size := Vector3(1.4, WALL_H - 2.2, 0.02) if along_x else Vector3(0.02, WALL_H - 2.2, 1.4)
			var pos := Vector3(g, 2.2 + size.y * 0.5, a.y) if along_x else Vector3(a.x, 2.2 + size.y * 0.5, g)
			_box(size, pos + Vector3(off.x, 0, off.y), paper, false)


func _segments(s: float, e: float, gaps: Array, gap_w: float) -> Array:
	var out := []
	var cuts := []
	for g in gaps:
		cuts.append([g - gap_w * 0.5, g + gap_w * 0.5])
	cuts.sort()
	var cur := minf(s, e)
	for cut in cuts + [[maxf(s, e), maxf(s, e)]]:
		if cut[0] - cur > 0.05:
			out.append([cur, cut[0]])
		cur = cut[1]
	return out


## Window: frame + night glass on both faces of an outer wall, and moonlight falling in.
func _window(pos: Vector3, outward: Vector3) -> void:
	var along_x := absf(outward.z) > 0.5
	var frame_m := _mat(Color(0.88, 0.86, 0.82))
	var glass := _glow_mat(Color(0.07, 0.11, 0.24), 0.35)
	for side in [-1.0, 1.0]:
		var o: Vector3 = outward * 0.13 * side
		var gsize := Vector3(1.1, 1.2, 0.02) if along_x else Vector3(0.02, 1.2, 1.1)
		var g := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = gsize
		g.mesh = bm
		g.material_override = glass
		g.position = pos + o
		add_child(g)
		var t := 0.07
		var bars := [[Vector3(1.24, t, 0.05), Vector3(0, 0.63, 0)], [Vector3(1.24, t, 0.05), Vector3(0, -0.63, 0)],
			[Vector3(t, 1.32, 0.05), Vector3(0.6, 0, 0)], [Vector3(t, 1.32, 0.05), Vector3(-0.6, 0, 0)],
			[Vector3(1.2, 0.04, 0.04), Vector3(0, 0, 0)], [Vector3(0.04, 1.2, 0.04), Vector3(0, 0, 0)]]
		for bar in bars:
			var sz: Vector3 = bar[0]
			var off: Vector3 = bar[1]
			if not along_x:
				sz = Vector3(sz.z, sz.y, sz.x)
				off = Vector3(off.z, off.y, off.x)
			_box(sz, pos + o * 1.15 + off, frame_m, false)
		if side > 0:  # snow on the outside sill
			var sill := Vector3(1.3, 0.06, 0.2) if along_x else Vector3(0.2, 0.06, 1.3)
			_box(sill, pos + outward * 0.2 + Vector3(0, -0.66, 0), _mat(Color(0.93, 0.95, 1.0)), false)
	var spot := SpotLight3D.new()
	spot.position = pos - outward * 0.25 + Vector3(0, 0.55, 0)
	add_child(spot)
	spot.look_at(pos - outward * 3.0 + Vector3(0, -1.5, 0), Vector3.UP)
	spot.light_color = Color(0.55, 0.66, 1.0)
	spot.light_energy = 2.2
	spot.spot_range = 7.0
	spot.spot_angle = 32.0
	spot.shadow_enabled = false
	spot.light_volumetric_fog_energy = 2.5
	spot.light_energy = 2.0
	spot.light_size = 0.6
	spot.spot_attenuation = 0.8
	# Curtains + rod on the inside
	var inward := -outward
	var along := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	var cloth := _tmat("fabric_pattern_05", Color(0.62, 0.36, 0.34), 1.6, 0.95)
	for sgn in [-1.0, 1.0]:
		var csize := Vector3(0.42, 2.05, 0.05) if along_x else Vector3(0.05, 2.05, 0.42)
		var cpos: Vector3 = pos + inward * 0.2 + along * 0.86 * sgn
		cpos.y = 1.33
		_box(csize, cpos, cloth, false)
	var rsize := Vector3(2.2, 0.03, 0.03) if along_x else Vector3(0.03, 0.03, 2.2)
	var rpos: Vector3 = pos + inward * 0.2
	rpos.y = 2.38
	_box(rsize, rpos, _mat(Color(0.25, 0.18, 0.12)), false)


# ------------------------------------------------------------------ rooms & memories

var scarf_mesh: MeshInstance3D
var drawing_pieces_left := 3
var drawing_wall: Node3D
var study_door: MeshInstance3D
var suitcase_items_left := 4
var suitcase_pos := Vector3(3.3, 0, -7.0)
var photo: Node3D
var fire_light: OmniLight3D
var fire_mesh: MeshInstance3D
var m_gate: Marker3D
var m_front: Marker3D


func _build_rooms() -> void:
	m_gate = _marker(Vector3(0, 0, 10))
	m_gate.name = "MarkerGate"
	m_front = _marker(Vector3(0, 0, 0.9))
	m_front.name = "MarkerFront"
	var dark_wood := _mat(Color(0.3, 0.19, 0.12))

	# LIVING: coat stand by the front door, the unravelled scarf on it
	var stand := SCARF_STAND
	_box(Vector3(0.06, 1.8, 0.06), stand + Vector3(0, 0.9, 0), dark_wood)
	_box(Vector3(0.45, 0.04, 0.45), stand + Vector3(0, 0.02, 0), dark_wood, false)
	for a in [0.0, 90.0, 180.0, 270.0]:
		var peg := _box(Vector3(0.22, 0.03, 0.03), stand + Vector3(0, 1.72, 0), dark_wood, false)
		peg.rotation_degrees = Vector3(0, a, 25)
	scarf_mesh = _box(Vector3(0.2, 1.0, 0.04), stand + Vector3(0, 1.5, -0.08), Color(0.78, 0.16, 0.15), false)
	scarf_mesh.name = "ScarfMesh"
	_scarf_visual(0.0)
	_box(Vector3(2.6, 0.015, 1.8), Vector3(1.2, 0.07, -2.8), _tmat("fabric_pattern_05", Color(0.85, 0.45, 0.38), 0.9), false)

	# KID ROOM: the drawing above the desk (hidden until taped back together)
	drawing_wall = Node3D.new()
	drawing_wall.name = "DrawingWall"
	drawing_wall.position = Vector3(-4.6, 1.55, -4.36)
	drawing_wall.visible = false
	add_child(drawing_wall)
	_box(Vector3(0.8, 0.6, 0.01), Vector3.ZERO, Color(0.97, 0.96, 0.9), false, drawing_wall)
	_box(Vector3(0.1, 0.28, 0.012), Vector3(-0.13, -0.05, 0.01), Color(0.3, 0.45, 0.85), false, drawing_wall)
	_box(Vector3(0.07, 0.18, 0.012), Vector3(0.1, -0.1, 0.01), Color(0.85, 0.2, 0.2), false, drawing_wall)
	_box(Vector3(0.11, 0.11, 0.012), Vector3(0.27, 0.18, 0.01), Color(1, 0.8, 0.2), false, drawing_wall)
	_box(Vector3(1.8, 0.015, 1.3), Vector3(-5.2, 0.07, -2.1), _tmat("fabric_pattern_05", Color(0.35, 0.5, 0.8), 1.0), false)

	# HALLWAY: the study door at the end, light leaking underneath
	study_door = _box(Vector3(1.0, 2.1, 0.08), Vector3(-0.75, 1.05, -8.84), Color(0.36, 0.22, 0.14), false)
	study_door.name = "StudyDoor"
	_box(Vector3(0.12, 2.25, 0.16), Vector3(-1.33, 1.12, -8.86), dark_wood, false)
	_box(Vector3(0.12, 2.25, 0.16), Vector3(-0.17, 1.12, -8.86), dark_wood, false)
	_box(Vector3(1.28, 0.12, 0.16), Vector3(-0.75, 2.2, -8.86), dark_wood, false)
	var leak := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(0.95, 0.02, 0.02)
	leak.mesh = lb
	leak.material_override = _glow_mat(Color(1.0, 0.7, 0.4), 4.0)
	leak.position = Vector3(-0.75, 0.02, -8.79)
	add_child(leak)
	_box(Vector3(1.1, 0.015, 3.6), Vector3(-0.75, 0.07, -6.75), _tmat("fabric_pattern_05", Color(0.75, 0.4, 0.35), 1.1), false)

	# PARENT ROOM: brick fireplace on the west wall, the face-down photo on the dresser
	var fz := FIRE_Z
	var brick := _tmat("brick_wall_02", Color.WHITE, 0.9)
	_box(Vector3(0.75, 1.25, 2.0), Vector3(-7.0, 0.62, fz), brick)
	_box(Vector3(0.5, 1.55, 1.5), Vector3(-7.15, 2.05, fz), brick, false)
	_box(Vector3(0.95, 0.09, 2.2), Vector3(-6.95, 1.29, fz), dark_wood, false)  # mantel
	_box(Vector3(0.1, 0.75, 1.1), Vector3(-6.6, 0.45, fz), _mat(Color(0.04, 0.035, 0.03)), false)  # firebox
	_box(Vector3(0.9, 0.06, 2.3), Vector3(-6.7, 0.03, fz), _tmat("brick_wall_02", Color(0.6, 0.55, 0.5), 1.2), false)  # hearth
	for i in 3:
		var lg := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.06
		cm.bottom_radius = 0.06
		cm.height = 0.7
		lg.mesh = cm
		lg.material_override = _mat(Color(0.18, 0.12, 0.08))
		lg.position = Vector3(-6.75 + i * 0.04, 0.12 + (0.1 if i == 2 else 0.0), fz + (i - 1) * 0.13)
		lg.rotation_degrees = Vector3(90, 0, 0)
		add_child(lg)
	_box(Vector3(1.2, 0.015, 1.6), Vector3(-5.9, 0.07, fz), _tmat("fabric_pattern_05", Color(0.8, 0.55, 0.45), 1.0), false)
	photo = Node3D.new()
	photo.name = "Photo"
	photo.position = Vector3(-2.95, 1.0, -8.3)
	photo.rotation.x = PI  # face down
	add_child(photo)
	_box(Vector3(0.36, 0.03, 0.46), Vector3.ZERO, Color(0.4, 0.26, 0.15), false, photo)
	_box(Vector3(0.3, 0.01, 0.38), Vector3(0, 0.02, 0), Color(0.85, 0.8, 0.7), false, photo)
	_box(Vector3(0.09, 0.012, 0.24), Vector3(-0.06, 0.03, 0.03), Color(0.5, 0.45, 0.4), false, photo)
	_box(Vector3(0.06, 0.012, 0.14), Vector3(0.07, 0.03, 0.08), Color(0.8, 0.2, 0.2), false, photo)
	fire_mesh = MeshInstance3D.new()
	fire_mesh.name = "FireMesh"
	var fm := SphereMesh.new()
	fm.radius = 0.22
	fm.height = 0.5
	fire_mesh.mesh = fm
	fire_mesh.material_override = _glow_mat(Color(1, 0.45, 0.1), 9.0)
	fire_mesh.position = Vector3(-6.6, 0.32, fz)
	fire_mesh.visible = false
	add_child(fire_mesh)
	fire_light = OmniLight3D.new()
	fire_light.name = "FireLight"
	fire_light.position = Vector3(-6.1, 0.7, fz)
	fire_light.light_color = Color(1, 0.5, 0.2)
	fire_light.light_energy = 0.0
	fire_light.omni_range = 9.0
	fire_light.shadow_enabled = true
	add_child(fire_light)

	# KITCHEN: counter run along the back wall, wall cupboard above
	var counter_m := _tmat("dark_wooden_planks", Color(1.0, 0.95, 0.9), 0.8)
	_box(Vector3(2.15, 0.9, 0.62), Vector3(4.85, 0.45, -4.17), counter_m)
	_box(Vector3(2.2, 0.05, 0.66), Vector3(4.85, 0.92, -4.17), _mat(Color(0.88, 0.87, 0.84)), false)
	_box(Vector3(1.4, 0.7, 0.35), Vector3(4.85, 1.85, -4.33), counter_m, false)


## Real model props (Poly Haven CC0). height = target height; collide adds a box collider.
func _prop(id: String, pos: Vector3, height: float, rot_deg := 0.0, collide := false, snow_amt := 0.0) -> Node3D:
	var path := "res://assets/polyhaven/%s/%s.gltf" % [id, id]
	if not ResourceLoader.exists(path):
		push_warning("missing prop " + path)
		return null
	var p := ModelFit.load_native(path)  # Poly Haven models are authored in real metres
	p.name = id
	p.add_to_group("memory_prop", true)
	p.set_meta("snow", snow_amt)
	if not bake_mode and snow_amt > 0.0:
		ModelFit.use_memory_shader(p, snow_amt)
	p.position = pos
	p.rotation_degrees.y = rot_deg
	add_child(p)
	if collide and p.has_meta("size"):
		var size: Vector3 = p.get_meta("size")
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size * Vector3(0.9, 1.0, 0.9)
		cs.shape = shape
		cs.position = Vector3(0, size.y * 0.5, 0)
		body.add_child(cs)
		p.add_child(body)
	return p


func _place_props() -> void:
	# Each entry: [id, position, rotation (deg), collide]. Real-world scale.
	# Rotation convention: 0 = front faces +Z (toward the front of the house).
	var L := [
		# ---------------- LIVING (x -3..3, z 0..-4.5) — focal: grandma's armchair facing the TV
		["painted_wooden_sofa", Vector3(1.5, 0.06, -4.05), 0, true],
		["throw_pillows_01", Vector3(1.5, 0.5, -4.0), 0, false],
		["Ukulele_01", Vector3(2.45, 0.5, -3.95), -30, false],
		["side_table_01", Vector3(2.75, 0.06, -4.1), 0, true],
		["ceramic_vase_03", Vector3(2.75, 0.6, -4.1), 0, false],
		["CoffeeTable_01", Vector3(1.4, 0.06, -2.85), 0, true],
		["vintage_oil_lamp", Vector3(1.7, 0.5, -2.85), 0, false],
		["chess_set", Vector3(1.1, 0.5, -2.85), 20, false],
		["ArmChair_01", Vector3(-1.75, 0.06, -2.95), 55, true],
		["Ottoman_01", Vector3(-1.0, 0.06, -2.2), 0, true],
		["wicker_basket_01", Vector3(-2.55, 0.06, -3.6), 0, false],
		["ClassicConsole_01", Vector3(2.75, 0.06, -3.1), -90, true],
		["Television_01", Vector3(2.75, 0.85, -3.1), -90, false],
		["cassette_player", Vector3(2.75, 0.85, -3.55), -90, false],
		["wooden_bookshelf_worn", Vector3(-2.2, 0.06, -4.2), 0, true],
		["mantel_clock_01", Vector3(-2.2, 2.0, -4.25), 0, false],
		["vintage_grandfather_clock_01", Vector3(-2.75, 0.06, -0.38), 180, true],
		["potted_plant_01", Vector3(2.75, 0.06, -0.4), 0, false],
		["Chandelier_01", Vector3(0.2, WALL_H - 0.75, -2.3), 0, false],
		["fancy_picture_frame_02", Vector3(1.5, 1.75, -4.4), 0, false],
		["hanging_picture_frame_01", Vector3(-2.9, 1.6, -3.7), 90, false],
		["hanging_picture_frame_03", Vector3(-2.9, 1.7, -1.0), 90, false],
		["vintage_telephone_wall_clock", Vector3(2.9, 1.8, -3.1), -90, false],
		# ---------------- KID ROOM (x -7.5..-3, z 0..-4.5) — focal: the little desk
		["vintage_day_bed", Vector3(-6.95, 0.06, -3.35), 90, true],
		["throw_pillows_01", Vector3(-6.95, 0.5, -3.35), 90, false],
		["SchoolDesk_01", DESK_POS + Vector3(0, 0.06, 0), 0, true],
		["SchoolChair_01", DESK_POS + Vector3(0, 0.06, 0.65), 180, true],
		["stationery_supplies", DESK_POS + Vector3(-0.2, 0.8, 0), 0, false],
		["desk_lamp_arm_01", DESK_POS + Vector3(0.3, 0.8, -0.1), -20, false],
		["painted_wooden_shelves", Vector3(-3.45, 0.06, -3.9), -90, true],
		["horse_statue_01", Vector3(-3.45, 1.6, -3.7), -90, false],
		["Camera_01", Vector3(-3.45, 1.6, -4.15), -90, false],
		["Shelf_01", Vector3(-5.95, 0.06, -4.2), 0, true],
		["book_encyclopedia_set_01", Vector3(-5.95, 0.9, -4.2), 0, false],
		["treasure_chest", Vector3(-6.7, 0.06, -0.45), 180, true],
		["standing_chalkboard_01", Vector3(-3.55, 0.06, -0.6), 220, true],
		["rubber_duck_toy", Vector3(-5.0, 0.08, -1.7), 30, false],
		["gamepad", Vector3(-5.6, 0.08, -2.3), 70, false],
		["gaming_console", Vector3(-5.2, 0.08, -2.5), 30, false],
		["american_football", Vector3(-4.2, 0.08, -1.2), 60, false],
		["baseball_01", Vector3(-6.2, 0.08, -2.6), 0, false],
		["potted_plant_04", Vector3(-7.1, 0.06, -1.2), 0, false],
		["dartboard", Vector3(-3.1, 1.7, -3.2), -90, false],
		["hanging_picture_frame_02", Vector3(-6.2, 1.8, -4.4), 0, false],
		# ---------------- KITCHEN (x 3..6, z 0..-4.5) — counter run, small table
		["electric_stove", Vector3(3.45, 0.06, -4.15), 0, true],
		["wooden_cutting_board", Vector3(4.6, 0.95, -4.15), 10, false],
		["yellow_onion", Vector3(4.45, 0.98, -4.1), 0, false],
		["wooden_spoon", Vector3(4.85, 0.95, -4.25), 70, false],
		["wooden_bowl_01", Vector3(5.3, 0.95, -4.15), 0, false],
		["wine_bottles_01", Vector3(5.7, 0.95, -4.2), 0, false],
		["metal_jug", Vector3(4.1, 0.95, -4.2), 0, false],
		["pot_enamel_01", Vector3(3.45, 0.96, -4.1), 0, false],
		["WoodenTable_02", Vector3(4.5, 0.06, -1.9), 90, true],
		["painted_wooden_chair_02", Vector3(3.8, 0.06, -1.9), 90, true],
		["painted_wooden_chair_02", Vector3(5.2, 0.06, -1.9), -90, true],
		["tea_set_01", Vector3(4.5, 0.8, -2.1), 0, false],
		["carrot_cake", Vector3(4.5, 0.8, -1.6), 0, false],
		["food_pears_asian_01", Vector3(4.4, 0.8, -2.4), 0, false],
		["painted_wooden_cabinet_02", Vector3(5.65, 0.06, -3.3), -90, true],
		["wooden_bucket_01", Vector3(5.65, 0.06, -0.4), 0, false],
		["wooden_crate_02", Vector3(3.45, 0.06, -0.4), 20, true],
		["hanging_picture_frame_01", Vector3(3.1, 1.7, -3.6), 90, false],
		# ---------------- HALLWAY (x -2.5..1, z -4.5..-9) — a corridor to the study door
		["ClassicConsole_01", Vector3(-2.15, 0.06, -8.1), 90, true],
		["wooden_candlestick", Vector3(-2.15, 0.85, -8.4), 0, false],
		["carved_wooden_plate", Vector3(-2.15, 0.85, -7.9), 90, false],
		["ornate_mirror_01", Vector3(-2.4, 1.55, -8.1), 90, false],
		["side_table_tall_01", Vector3(0.65, 0.06, -5.2), -90, true],
		["ceramic_vase_02", Vector3(0.65, 0.95, -5.2), 0, false],
		["potted_plant_02", Vector3(0.6, 0.06, -8.55), 0, false],
		["wooden_crate_02", Vector3(-2.1, 0.06, -5.0), 15, true],
		["wall_clock", Vector3(0.9, 1.9, -8.0), -90, false],
		["hanging_picture_frame_02", Vector3(0.9, 1.6, -5.2), -90, false],
		["lantern_chandelier_01", Vector3(-0.75, WALL_H - 0.75, -6.75), 0, false],
		# ---------------- PARENT ROOM (x -7.5..-2.5, z -4.5..-9) — focal: the fireplace and rocking chair
		["GothicBed_01", Vector3(-5.3, 0.06, -7.9), 0, true],
		["throw_pillows_01", Vector3(-5.3, 0.62, -8.6), 0, false],
		["ClassicNightstand_01", Vector3(-6.85, 0.06, -8.7), 0, true],
		["wooden_candlestick", Vector3(-6.85, 0.62, -8.7), 0, false],
		["vintage_wooden_drawer_01", Vector3(-2.85, 0.06, -8.3), -90, true],
		["vintage_oil_lamp", Vector3(-2.85, 1.0, -8.75), 0, false],
		["brass_vase_02", Vector3(-2.85, 1.0, -7.85), 0, false],
		["dry_branches_medium_01", Vector3(-2.85, 1.2, -7.85), 0, false],
		["Rockingchair_01", Vector3(-5.6, 0.06, -5.3), -110, true],
		["spinning_wheel_01", Vector3(-3.3, 0.06, -5.15), 220, true],
		["wicker_basket_02", Vector3(-4.0, 0.06, -5.0), 0, false],
		["Ottoman_01", Vector3(-5.3, 0.06, -6.45), 0, true],
		["brass_candleholders", Vector3(-6.95, 1.34, FIRE_Z - 0.75), 90, false],
		["mantel_clock_01", Vector3(-6.95, 1.34, FIRE_Z), 90, false],
		["ceramic_vase_01", Vector3(-6.95, 1.34, FIRE_Z + 0.75), 0, false],
		["fancy_picture_frame_01", Vector3(-7.35, 2.0, FIRE_Z), 90, false],
		["wooden_axe", Vector3(-6.3, 0.08, FIRE_Z - 1.15), 20, false],
		["hanging_picture_frame_03", Vector3(-5.3, 1.95, -8.85), 0, false],
		["fancy_picture_frame_02", Vector3(-2.65, 1.6, -5.4), -90, false],
		# ---------------- BEDROOM (x 1..6, z -4.5..-9) — the room the player left
		["vintage_day_bed", Vector3(5.45, 0.06, -7.95), -90, true],
		["throw_pillows_01", Vector3(5.45, 0.5, -8.4), -90, false],
		["Ukulele_01", Vector3(5.3, 0.5, -7.3), 20, false],
		["ClassicNightstand_01", Vector3(4.55, 0.06, -8.7), 0, true],
		["WoodenTable_01", Vector3(2.9, 0.06, -4.9), 180, true],
		["painted_wooden_chair_01", Vector3(2.9, 0.06, -5.55), 0, true],
		["boombox", Vector3(3.3, 0.8, -4.85), 180, false],
		["book_encyclopedia_set_01", Vector3(2.4, 0.8, -4.85), 0, false],
		["desk_lamp_arm_01", Vector3(3.6, 0.8, -4.8), 200, false],
		["painted_wooden_cabinet", Vector3(5.6, 0.06, -4.95), -90, true],
		["wooden_display_shelves_01", Vector3(1.95, 0.06, -8.65), 0, true],
		["potted_plant_01", Vector3(1.35, 0.06, -5.0), 0, false],
		["american_football", Vector3(3.9, 0.08, -6.0), 120, false],
		["vintage_suitcase", suitcase_pos + Vector3(0, 0.06, 0), 0, false],
		["hanging_picture_frame_02", Vector3(2.9, 1.75, -4.62), 180, false],
		["hanging_picture_frame_03", Vector3(4.3, 1.65, -4.62), 180, false],
	]
	for it in L:
		var p := _prop(it[0], it[1], 1.0, it[2], it[3])
		if p and it[0] == "vintage_wooden_drawer_01":
			# the face-down photo lies on the dresser top
			photo.position.y = it[1].y + (p.get_meta("size") as Vector3).y + 0.02
	_settle_props()


var _scarf_rows: Array = []

## A real knitted scarf hanging from the stand: rows appear stitch by stitch.
func _scarf_visual(p: float) -> void:
	if not scarf_mesh:
		return
	if _scarf_rows.is_empty() and not bake_mode and is_inside_tree():
		scarf_mesh.visible = false
		var knit := _tmat("fabric_pattern_05", Color(0.75, 0.16, 0.14), 6.0, 0.95)
		var knit_dark := _tmat("fabric_pattern_05", Color(0.6, 0.11, 0.1), 6.0, 0.95)
		var top: Vector3 = SCARF_STAND + Vector3(0.0, 1.72, -0.06)
		for i in 30:
			var row := MeshInstance3D.new()
			var bm := CapsuleMesh.new()
			bm.radius = 0.016
			bm.height = 0.19
			bm.radial_segments = 10
			bm.rings = 2
			row.mesh = bm
			row.material_override = knit if i % 2 == 0 else knit_dark
			row.position = top + Vector3(sin(float(i) * 0.55) * 0.012, -0.03 - float(i) * 0.031, sin(float(i) * 0.3) * 0.01)
			row.rotation_degrees = Vector3(randf_range(-4, 4), 0, 90.0 + randf_range(-3, 3))
			add_child(row)
			_scarf_rows.append(row)
		# loose yarn ball and needles below
		var ball := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.07
		sm.height = 0.14
		ball.mesh = sm
		ball.material_override = knit
		ball.position = SCARF_STAND + Vector3(0.25, 0.1, -0.15)
		add_child(ball)
		for k in 2:
			var nd := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.004
			cm.bottom_radius = 0.004
			cm.height = 0.32
			nd.mesh = cm
			nd.material_override = _mat(Color(0.55, 0.42, 0.28))
			nd.position = SCARF_STAND + Vector3(0.22 + k * 0.03, 0.12, -0.12)
			nd.rotation_degrees = Vector3(70, 30 + k * 15, 0)
			add_child(nd)
		var lamp := OmniLight3D.new()
		lamp.position = SCARF_STAND + Vector3(-0.4, 1.9, -0.6)
		lamp.light_color = Color(0.85, 0.85, 1.0)
		lamp.light_energy = 0.5
		lamp.omni_range = 3.0
		add_child(lamp)
	var shown := int(round(p * 22.0)) + 8  # starts half-unravelled: 8 rows left
	for i in _scarf_rows.size():
		_scarf_rows[i].visible = i < shown


func _add(pos: Vector3, kind: String, cb: Callable, extra := {}) -> Dictionary:
	var d := {"pos": pos, "r": 1.4, "kind": kind, "cb": cb, "p": 0.0, "t": 0.0, "hold": 4.0, "upd": Callable()}
	d.merge(extra, true)
	interacts.append(d)
	return d


func _nearest() -> Dictionary:
	var best := {}
	var best_d := 1e9
	for d in interacts:
		var a: Vector3 = d.pos
		var dist := Vector2(a.x, a.z).distance_to(Vector2(player.global_position.x, player.global_position.z))
		if dist < d.r and dist < best_d:
			best = d
			best_d = dist
	return best


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or bake_mode or not player:
		return
	if cutscene:
		player.cam.look_at(cam_look)
	_update_snow()
	_update_mosaic()
	var outside: bool = player.cam.global_position.z > -0.3
	if outside != _was_outside:
		_was_outside = outside
		for v in outdoor_heavy:
			v.visible = outside
		if snow:
			snow.visible = outside
	_update_stage_triggers()

	var e_now := Input.is_physical_key_pressed(KEY_E)
	var pressed := e_now and not e_prev
	e_prev = e_now
	var lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var rmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var l_click := lmb and not _lmb_prev
	var r_click := rmb and not _rmb_prev
	_lmb_prev = lmb
	_rmb_prev = rmb

	if _inspecting:
		_update_inspect(delta, pressed)
		return
	if _puzzle_on:
		_update_puzzle(l_click)
		return

	var d := _nearest() if player.can_move else {}
	hint.visible = not d.is_empty()
	bar.visible = false
	if d.is_empty():
		return
	match d.kind:
		"press":
			hint.text = "[ E ]"
			if pressed:
				interacts.erase(d)
				d.cb.call()
		"hold":
			hint.text = "hold [ E ]"
			if e_now and not _knit:
				_knit = _sfx3d("knit_loop", d.pos + Vector3(0, 1.4, 0), -4.0, true)
			elif not e_now and _knit:
				_knit.queue_free()
				_knit = null
			if e_now:
				d.p = minf(d.p + delta / d.hold, 1.0)
				if d.upd.is_valid():
					d.upd.call(d.p)
			bar.visible = d.p > 0.0
			bar.value = d.p * 100.0
			if d.p >= 1.0:
				if _knit:
					_knit.queue_free()
					_knit = null
				interacts.erase(d)
				d.cb.call()
		"knit":
			# Two needles: alternate left and right clicks to knit a stitch.
			hint.text = "knit:  LMB  ·  RMB"
			var stitch := (l_click and _last_needle != 1) or (r_click and _last_needle != 0)
			if stitch:
				_last_needle = 0 if l_click else 1
				d.p = minf(d.p + 1.0 / 22.0, 1.0)
				_knit_idle = 0.0
				if not _knit:
					_knit = _sfx3d("knit_loop", d.pos + Vector3(0, 1.4, 0), -6.0, true)
				player.add_shake(0.04, 0.15)
				if d.upd.is_valid():
					d.upd.call(d.p)
			_knit_idle += delta
			if _knit and _knit_idle > 0.45:
				_knit.queue_free()
				_knit = null
			bar.visible = d.p > 0.0
			bar.value = d.p * 100.0
			if d.p >= 1.0:
				if _knit:
					_knit.queue_free()
					_knit = null
				interacts.erase(d)
				d.cb.call()
		"mash":
			# The door shoves back in pulses. Mash E to hold it... you can't win.
			hint.text = "mash [ E ]"
			d.t += delta
			var shove: float = 0.35 + d.t * 0.08
			d.p = maxf(d.p - delta * shove, 0.0)
			if pressed:
				d.p = minf(d.p + 0.13, 0.85)
				player.add_shake(0.35, 0.25)
				_sfx3d("pack_item", study_door.global_position, -2.0)
			if fmod(d.t, 1.3) < delta:
				player.add_shake(0.5, 0.35)  # a shove from the other side
			study_door.rotation.y = -d.p * 1.1
			study_door.position.x = -0.75 + d.p * 0.42
			bar.visible = true
			bar.value = d.p * 100.0
			if d.t > 6.5:
				interacts.erase(d)
				d.cb.call()
		"struggle":
			# The door pushes back. You can slow it, never win.
			hint.text = "hold [ E ]"
			if e_now:
				d.p = minf(d.p + delta * 0.35, 0.8)
				d.t += delta
			else:
				d.p = maxf(d.p - delta * 0.25, 0.0)
			d.p = maxf(d.p - delta * 0.15, 0.0)
			study_door.rotation.y = -d.p * 1.2
			study_door.position.x = d.p * 0.45
			bar.visible = true
			bar.value = d.p * 100.0
			if d.t > 5.0:
				interacts.erase(d)
				d.cb.call()


func _update_stage_triggers() -> void:
	var pp := player.global_position
	if not gate_closed and stage >= 1 and pp.z < 8.2:
		_close_gate()
	if stage == 0 and pp.distance_to(m_gate.position) < 1.8:
		stage = 1
		ember.follow = true
		ember.target = m_front
		_sfx("ember_chime", -4.0)
		_say("...home.", 2.5)
	elif stage == 1 and pp.distance_to(m_front.position) < 1.8:
		stage = 2
		_open_door("front")
		_set_sat(0.0, 2.0)
		player.glance(Vector3(0, 1.2, -3.0), 0.25)
		var m := _marker(SCARF_STAND)
		ember.target = m
		_add(SCARF_STAND + Vector3(0, 0, -0.5), "knit", _scarf_done, {"upd": _scarf_visual})


func _scarf_done() -> void:
	_wake_figures("living")
	_restore_fx(SCARF_STAND + Vector3(0, 1.4, 0))
	_set_sat(0.35)
	_warm_room("living")
	_say("\"There. Now you won't get cold.\"", 3.5, "v_scarf")
	_open_door("kid")
	stage = 3
	ember.target = _marker(DESK_POS)
	for p in [Vector3(-6.2, 0, -1.0), Vector3(-3.7, 0, -2.9), Vector3(-5.7, 0, -3.3)]:
		var piece := _box(Vector3(0.3, 0.01, 0.22), p + Vector3(0, 0.08, 0), Color(0.97, 0.96, 0.9), false)
		piece.rotation.y = randf() * TAU
		_add(p, "press", _piece_found.bind(piece))


func _piece_found(piece: MeshInstance3D) -> void:
	player.glance(piece.global_position, 0.4)
	_sfx("paper_pickup", -4.0, 0.1)
	piece.queue_free()
	drawing_pieces_left -= 1
	if drawing_pieces_left == 0:
		_add(DESK_POS + Vector3(0, 0, 0.9), "press", _start_puzzle)


func _drawing_taped() -> void:
	_wake_figures("kid")
	_sfx("tape", -4.0)
	_restore_fx(drawing_wall.global_position)
	drawing_wall.visible = true
	for c in drawing_wall.get_children():
		c.visible = false
	var pic := MeshInstance3D.new()
	var pq := QuadMesh.new()
	pq.size = Vector2(0.6, 0.6)
	pic.mesh = pq
	var pmat := StandardMaterial3D.new()
	pmat.albedo_texture = _drawing_texture()
	pic.material_override = pmat
	pic.position = Vector3(0, 0, 0.012)
	drawing_wall.add_child(pic)
	drawing_wall.scale = Vector3(0.2, 0.2, 0.2)
	create_tween().tween_property(drawing_wall, "scale", Vector3.ONE, 0.8).set_trans(Tween.TRANS_BACK)
	_set_sat(0.6)
	_warm_room("kid")
	_say("\"My little artist.\"", 3.0, "v_artist")
	_open_door("hall")
	stage = 4
	ember.target = _marker(STRUGGLE_SPOT)
	_add(STRUGGLE_SPOT, "mash", _door_slammed, {"r": 1.6})
	_sfx3d("argument_muffled", Vector3(-0.75, 1.4, -9.6), -2.0)


func _door_slammed() -> void:
	_sfx("door_slam", 2.0)
	player.add_shake(1.0, 0.9)
	_fx_pulse(0.7, 0.012)
	var tw := create_tween()
	tw.tween_property(study_door, "rotation:y", 0.0, 0.12)
	tw.parallel().tween_property(study_door, "position:x", 0.0, 0.12)
	tw.tween_property(fade, "color:a", 0.6, 0.05)
	tw.tween_property(fade, "color:a", 0.0, 0.6)
	_say("\"...then go!\"", 2.5)
	_set_sat(0.3, 1.0)
	_open_door("bed")
	stage = 5
	ember.target = _marker(suitcase_pos)
	var items := [
		["alarm_clock_01", Vector3(4.55, 0.7, -8.7), "The clock she set for my first day of school.", Vector3(4.4, 0, -8.0)],
		["binder_notebook", Vector3(2.6, 0.8, -4.9), "My old school notes. She kept every one.", Vector3(2.6, 0, -5.7)],
		["gamepad", Vector3(4.2, 0.08, -5.8), "She saved for months to buy me this.", Vector3(4.2, 0, -5.8)],
		["postcard_set_01", Vector3(1.8, 0.08, -7.9), "Postcards. All addressed to me. Never sent.", Vector3(1.8, 0, -7.9)],
	]
	for it in items:
		var mi := _prop(it[0], it[1], 1.0, randf() * 360.0)
		if mi:
			_add(it[3], "press", _inspect.bind(mi, String(it[2]), _pack_item.bind(mi)))


func _pack_item(mi: Node3D) -> void:
	_sfx("pack_item", -4.0, 0.1)
	var tw := create_tween()
	tw.tween_property(mi, "global_position", suitcase_pos + Vector3(randf_range(-0.25, 0.25), 0.3, randf_range(-0.12, 0.12)), 0.7).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(mi, "rotation", Vector3(0, randf() * TAU, 0), 0.7)
	suitcase_items_left -= 1
	_set_sat(0.3 * suitcase_items_left / 4.0, 1.5)  # every packed item drains colour
	if suitcase_items_left == 0:
		_add(suitcase_pos, "press", _leave)


func _leave() -> void:
	player.can_move = false
	_sfx("suitcase_close", -2.0)
	_play_music("", 0.0, 3.0)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 1.5)
	tw.tween_callback(func(): _say("I left that night. I never came back.", 3.5))
	tw.tween_interval(3.5)
	tw.tween_callback(func():
		_open_door("parent")
		stage = 6
		ember.target = _marker(Vector3(-2.95, 0, -8.3))
		_add(PHOTO_SPOT, "press", _flip_photo)
		player.can_move = true)
	tw.tween_property(fade, "color:a", 0.0, 1.5)


# ------------------------------------------------------------------ ending

func _flip_photo() -> void:
	player.can_move = false
	cutscene = true
	player.cam_locked = true
	player.breath_enabled = false
	player.face_towards(photo.global_position)
	var head: Vector3 = player.face_position()
	var eye: Vector3 = player.cam.global_position
	var to_photo: Vector3 = (photo.global_position - eye)
	to_photo.y = 0
	to_photo = to_photo.normalized()
	cam_look = photo.global_position
	_cinema(true)
	_play_music("", 0.0, 2.0)  # the house goes quiet
	var tw := create_tween()
	# 1. Insert shot: we lean in as our own hands turn the photo over
	tw.tween_property(player.cam, "global_position", photo.global_position - to_photo * 0.75 + Vector3(0, 0.35, 0), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(player.cam, "fov", 42.0, 2.0)
	tw.parallel().tween_callback(func(): _sfx("photo_flip", -2.0)).set_delay(0.8)
	tw.parallel().tween_property(photo, "rotation:x", PI * 0.5, 1.3).set_delay(0.8).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(photo, "position:y", 1.3, 1.3).set_delay(0.8)
	tw.tween_callback(func():
		_focus(0.75)
		_set_sat(0.55, 2.5)
		_sfx("memory_restore", -6.0))
	tw.tween_interval(3.0)
	# 2. For the first time, the camera leaves the body: slow pull back over the shoulder
	tw.tween_callback(func():
		player.reveal_face()
		_sfx("heartbeat", -6.0))
	var back_pos: Vector3 = head - player.facing() * 1.7 + Vector3(0.35, 0.35, 0)
	tw.tween_property(player.cam, "global_position", back_pos, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(self, "cam_look", head + Vector3(0, -0.1, 0), 3.5)
	tw.parallel().tween_property(player.cam, "fov", 50.0, 3.5)
	tw.parallel().tween_callback(func(): _focus(1.7)).set_delay(1.5)
	# 3. ...and circles round to the face. Long lens, shallow focus.
	tw.tween_method(_orbit_cam.bind(head), 0.0, 1.0, 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(player.cam, "fov", 34.0, 6.5)
	tw.parallel().tween_callback(func(): _focus(0.85)).set_delay(4.0)
	# 4. Silence. Let it land.
	tw.tween_interval(3.5)
	# 5. The letter
	tw.tween_callback(func(): _say("\"I kept the fire going, in case you came home.\"", 5.5, "v_letter"))
	tw.tween_interval(6.5)
	tw.tween_callback(func():
		_cinema(false)
		cutscene = false
		player.cam_locked = false
		player.cam.fov = 70.0
		player.can_move = true
		stage = 7
		ember.target = _marker(Vector3(-6.6, 0, FIRE_Z))
		_add(HEARTH_SPOT, "press", _relight, {"r": 1.6}))


## t: 0 = behind the shoulder, 1 = in front of the face.
func _orbit_cam(t: float, head: Vector3) -> void:
	var back: Vector3 = -player.facing()
	var angle := t * PI
	var dir := back.rotated(Vector3.UP, angle * 0.95)
	var dist := lerpf(1.6, 0.85, t)
	# ends just below the bowed face, looking up into it
	player.cam.global_position = head + dir * dist + Vector3(0, lerpf(0.5, -0.2, t), 0)
	cam_look = head.lerp(head + Vector3(0, -0.02, 0), t)


func _relight() -> void:
	player.can_move = false
	cutscene = true
	player.cam_locked = true
	ember.follow = false
	ember.anchor = fire_mesh.position
	fire_mesh.visible = true
	fire_mesh.scale = Vector3(0.05, 0.05, 0.05)
	_cinema(true)
	# 1. Low on the hearth: the ember goes in, the fire catches
	player.cam.global_position = Vector3(-5.5, 0.55, FIRE_Z + 0.9)
	cam_look = Vector3(-6.6, 0.35, FIRE_Z)
	player.cam.fov = 40.0
	_focus(1.3)
	_sfx("fire_ignite", 0.0)
	player.add_shake(0.25, 1.2)
	var fire3d := _sfx3d("fire_loop", Vector3(-6.6, 0.4, FIRE_Z), -4.0, true)
	_play_music("theme_full", -6.0, 4.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fire_mesh, "scale", Vector3.ONE, 1.8).set_trans(Tween.TRANS_BACK)
	tw.tween_property(fire_light, "light_energy", 4.5, 3.0)
	tw.tween_property(self, "sat", 1.0, 5.0)
	tw.tween_property(env, "ambient_light_color", Color(0.9, 0.65, 0.45), 5.0)
	tw.tween_property(env, "ambient_light_energy", 0.3, 5.0)
	tw.tween_property(fx_mat, "shader_parameter/warmth", 0.8, 6.0)
	for room in room_lights.keys():
		_warm_room(room, 1.8)
	# 2. Slow crane back and up: the whole room glowing again
	var cam_tw := create_tween()
	cam_tw.tween_interval(3.0)
	cam_tw.tween_property(player.cam, "global_position", Vector3(-3.0, 2.3, -4.9), 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	cam_tw.parallel().tween_property(self, "cam_look", Vector3(-6.3, 0.9, -7.2), 7.0)
	cam_tw.parallel().tween_property(player.cam, "fov", 55.0, 7.0)
	cam_tw.parallel().tween_callback(func(): _focus(5.0)).set_delay(2.0)
	var end := create_tween()
	end.tween_interval(10.5)
	end.tween_property(fade, "color:a", 1.0, 3.0)
	end.tween_callback(func(): title.visible = true)
	end.tween_property(title, "modulate:a", 1.0, 2.5)


# ------------------------------------------------------------------ snow, UI, opening

func _build_snow() -> void:
	var tex := _soft_dot()
	# dense fine flakes + fewer big soft flakes close to camera = depth
	snow = _snow_layer(tex, 2200, 0.04, Vector2(0.6, 1.3), 10.0, Vector3(0.28, -0.85, 0.06))
	_snow_layer(tex, 250, 0.06, Vector2(0.7, 1.1), 8.0, Vector3(0.35, -0.7, 0.1))
	# Flakes vanish where they touch the ground / roofs: no snow indoors
	var hf := GPUParticlesCollisionHeightField3D.new()
	hf.size = Vector3(80, 30, 70)
	hf.position = Vector3(0, 6, 2)
	hf.resolution = GPUParticlesCollisionHeightField3D.RESOLUTION_512
	add_child(hf)


func _update_snow() -> void:
	pass  # emitter is fixed; roofs/ground collide with the flakes


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	hint = Label.new()
	hint.add_theme_font_size_override("font_size", 26)
	hint.add_theme_color_override("font_color", Color(1, 0.8, 0.55))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.anchor_right = 1.0
	hint.anchor_top = 0.74
	hint.anchor_bottom = 0.74
	hint.visible = false
	layer.add_child(hint)

	bar = ProgressBar.new()
	bar.show_percentage = false
	bar.anchor_left = 0.42
	bar.anchor_right = 0.58
	bar.anchor_top = 0.79
	bar.anchor_bottom = 0.8
	bar.visible = false
	layer.add_child(bar)

	var dot := Label.new()
	dot.text = "·"
	dot.add_theme_font_size_override("font_size", 32)
	dot.add_theme_color_override("font_color", Color(1, 0.9, 0.75, 0.7))
	dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dot.set_anchors_preset(Control.PRESET_FULL_RECT)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dot)

	caption = Label.new()
	caption.add_theme_font_size_override("font_size", 30)
	caption.add_theme_color_override("font_color", Color(1, 0.93, 0.82))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.anchor_right = 1.0
	caption.anchor_top = 0.86
	caption.anchor_bottom = 0.86
	caption.modulate.a = 0.0
	layer.add_child(caption)

	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)

	title = Label.new()
	title.text = "EMBER LETTERS\n\nthank you for coming home"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1, 0.75, 0.45))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.modulate.a = 0.0
	title.visible = false
	layer.add_child(title)


var _say_tween: Tween

func _say(text: String, dur := 3.0, voice := "") -> void:
	if voice != "":
		_sfx(voice, 0.0)
	if _say_tween:
		_say_tween.kill()
	caption.text = text
	caption.modulate.a = 0.0
	_say_tween = create_tween()
	_say_tween.tween_property(caption, "modulate:a", 1.0, 0.6)
	_say_tween.tween_interval(dur)
	_say_tween.tween_property(caption, "modulate:a", 0.0, 0.8)


func _opening() -> void:
	player.can_move = false
	player.cam_locked = true
	cutscene = true
	_cinema(true, 0.0)
	var eye: Vector3 = player.head_position() + player.facing() * 0.12
	player.cam.global_position = Vector3(1.5, 6.5, 22.0)
	cam_look = Vector3(0, 1.5, 0)
	player.cam.fov = 45.0
	_focus(20.0)
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(fade, "color:a", 0.0, 4.0)
	tw.parallel().tween_property(player.cam, "global_position", Vector3(0.6, 2.4, 17.0), 8.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(player.cam, "global_position", eye, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(self, "cam_look", eye + Vector3(0, -0.1, -5.0), 2.5)
	tw.parallel().tween_property(player.cam, "fov", 70.0, 2.5)
	tw.tween_callback(func():
		_cinema(false)
		_focus(-1.0)
		cutscene = false
		player.cam_locked = false
		player.can_move = true)


# ------------------------------------------------------------------ baked level binding

var outdoor_heavy: Array = []
var _was_outside := true


var gate_leaves: Array = []
var gate_closed := false


func _bind_level(lvl: Node) -> void:
	for gn in ["GateL", "GateR"]:
		var g := lvl.get_node_or_null(gn)
		if g:
			gate_leaves.append(g)
	var old_we := lvl.get_node_or_null("WorldEnvironment")
	if old_we:
		old_we.queue_free()
	var old_moon := lvl.get_node_or_null("Moon")
	if old_moon:
		old_moon.queue_free()
	for c in lvl.get_children():
		var n := String(c.name)
		if n.begins_with("Light_"):
			room_lights[n.substr(6)] = c
		elif n.begins_with("Door_"):
			doors[n.substr(5)] = c
	scarf_mesh = lvl.get_node("ScarfMesh")
	drawing_wall = lvl.get_node("DrawingWall")
	study_door = lvl.get_node("StudyDoor")
	photo = lvl.get_node("Photo")
	fire_mesh = lvl.get_node("FireMesh")
	fire_light = lvl.get_node("FireLight")
	m_gate = lvl.get_node("MarkerGate")
	m_front = lvl.get_node("MarkerFront")
	_collect_mats(lvl)
	for p in get_tree().get_nodes_in_group("memory_prop"):
		var pid := String(p.name)
		if pid.begins_with("pine") or pid.begins_with("shrub") or pid.begins_with("tree_stump") or pid.begins_with("wooden_picnic"):
			outdoor_heavy.append(p)
			for gi in p.find_children("*", "GeometryInstance3D", true, false):
				(gi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				(gi as GeometryInstance3D).visibility_range_end = 60.0
		if float(p.get_meta("snow", 0.0)) > 0.0:
			ModelFit.use_memory_shader(p, float(p.get_meta("snow", 0.0)))
	for c in lvl.get_children():
		var n2 := String(c.name)
		if n2.begins_with("Lamp_"):
			var room := n2.split("_")[1]
			if not room_lamps.has(room):
				room_lamps[room] = []
			room_lamps[room].append(c)


## Plain-colour materials take part in the grey -> colour fade.
func _collect_mats(n: Node) -> void:
	if n.is_in_group("memory_prop"):
		return
	if n is MeshInstance3D:
		var m = (n as MeshInstance3D).material_override
		if m is StandardMaterial3D and not m.emission_enabled:
			m = m.duplicate()
			(n as MeshInstance3D).material_override = m
			mats.append([m, m.albedo_color])
	for c in n.get_children():
		_collect_mats(c)


# ------------------------------------------------------------------ screenshot tour (dev)
## Run: Godot --path <project> -- --shots   -> saves PNGs into _shots/

func _shot_tour() -> void:
	fade.color.a = 0.0
	player.can_move = false
	var shots := [
		["01_start", Vector3(0, 0.1, 15), Vector3(0, 1.2, 0), 0.3],
		["02_gate", Vector3(0, 0.1, 11.5), Vector3(0, 1.4, 0), 0.3],
		["03_living_grey", Vector3(0.6, 0.1, -0.6), Vector3(-1.2, 0.9, -3.6), 0.0],
		["04_living_colour", Vector3(-0.6, 0.1, -0.6), Vector3(1.6, 0.7, -3.8), 1.0],
		["05_kid", Vector3(-3.6, 0.1, -0.7), Vector3(-6.0, 0.8, -3.6), 0.6],
		["06_hall", Vector3(-0.75, 0.1, -4.9), Vector3(-0.75, 1.1, -9), 0.35],
		["07_bedroom", Vector3(1.5, 0.1, -5.1), Vector3(4.6, 0.6, -8.2), 0.3],
		["08_parent", Vector3(-3.0, 0.1, -5.1), Vector3(-6.4, 0.8, -7.4), 0.5],
		["09_kitchen", Vector3(3.4, 0.1, -0.5), Vector3(5.0, 0.8, -3.6), 1.0],
	]
	var out := ProjectSettings.globalize_path("res://_shots")
	for s in shots:
		sat = s[3]
		player.global_position = s[1]
		player.face_towards(s[2])
		var d: Vector3 = s[2] - player.head_position()
		player.pitch = atan2(d.y, Vector2(d.x, d.z).length())
		for i in 25:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(out.path_join(s[0] + ".png"))
		print("FPS ", s[0], " ", Engine.get_frames_per_second())
	# Reveal: the face
	player.global_position = PHOTO_SPOT + Vector3(0, 0.1, 0)
	player.face_towards(photo.global_position)
	player.reveal_face()
	player.cam_locked = true
	var head: Vector3 = player.face_position()
	player.cam.global_position = head + player.facing() * 0.85 + Vector3(0, -0.2, 0)
	player.cam.look_at(head)
	sat = 0.6
	for i in 25:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out.path_join("10_reveal.png"))
	# Debug: wide shot of the player in the hallway
	player.global_position = Vector3(0.0, 0.1, -1.6)
	player.cam.global_position = Vector3(0.6, 1.5, -3.9)
	player.cam.look_at(Vector3(0.0, 0.9, -1.6))
	for i in 25:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out.path_join("11_player_wide.png"))
	player.global_position = Vector3(4.5, 0.1, -3.0)
	sat = 0.0
	player.cam.global_position = Vector3(0.6, 1.5, -1.0)
	player.cam.look_at(Vector3(-1.6, 0.8, -3.1))
	for i in 25:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out.path_join("12_figures_grey.png"))
	sat = 1.0
	_wake_figures("living")
	for i in 60:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out.path_join("13_figures_colour.png"))
	print("SHOTS DONE")
	get_tree().quit()


# ------------------------------------------------------------------ memory figures
## Parent and child appear inside each memory: frozen mid-moment, faces blurred.
## They come back to life (animation plays) when that memory is restored.
var figures := {}  # room -> Array[AnimationPlayer]
var face_nodes: Array[Node3D] = []
var figure_roots := {}  # room -> Array[Node3D]

const FIGURES := [
	# [file, position, facing (deg), room, frozen-at (0..1), seat point for the hips (or null)]
	["res://assets/mixamo/grandma_sit.fbx", Vector3(-1.75, 0.06, -2.95), 55.0, "living", 0.3, Vector3(-1.75, 0.62, -2.95)],
	["res://assets/mixamo/boy_happy.fbx", Vector3(-0.7, 0.06, -3.5), 230.0, "living", 0.5, null],
	["res://assets/mixamo/boy_sit.fbx", DESK_POS + Vector3(0, 0.06, 0.65), 180.0, "kid", 0.4, DESK_POS + Vector3(0, 0.58, 0.68)],
]


func _place_figures() -> void:
	for f in FIGURES:
		if not ResourceLoader.exists(f[0]):
			continue
		var root := Node3D.new()
		root.position = f[1]
		root.rotation_degrees.y = f[2]
		add_child(root)
		if not figure_roots.has(f[3]):
			figure_roots[f[3]] = []
		figure_roots[f[3]].append(root)
		var model: Node3D = (load(f[0]) as PackedScene).instantiate()
		root.add_child(model)
		ModelFit._fix_cull(model)
		_make_ghost(model, root)
		var skel := ModelFit._find_skeleton(model)
		if skel and skel.find_bone("mixamorig_Head") >= 0:
			var att := BoneAttachment3D.new()
			att.bone_name = "mixamorig_Head"
			skel.add_child(att)
			var face := Node3D.new()
			face.position = Vector3(0, 0.1, 0.05)
			att.add_child(face)
			face_nodes.append(face)  # mosaic follows this point on screen
		var ap := _find_ap(model)
		if ap:
			var clip := ""
			for a in ap.get_animation_list():
				if a != "RESET":
					clip = a
			if clip != "":
				ap.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
				ap.play(clip)
				ap.seek(ap.current_animation_length * f[4], true)
				ap.speed_scale = 0.0  # frozen memory
				# Sitting: move the figure so its hips land exactly on the chair seat
				if f[5] != null and skel:
					var hb := skel.find_bone("mixamorig_Hips")
					if hb >= 0:
						var hips: Vector3 = skel.global_transform * skel.get_bone_global_pose(hb).origin
						root.global_position += (f[5] as Vector3) - hips
				if not figures.has(f[3]):
					figures[f[3]] = []
				figures[f[3]].append(ap)


func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_ap(c)
		if r:
			return r
	return null


func _wake_figures(room: String) -> void:
	for ap in figures.get(room, []):
		create_tween().tween_property(ap, "speed_scale", 1.0, 2.0)
	# ghosts flare up warmly as the memory returns, then slowly fade away
	for g in ghost_mats.get(room, []):
		var tw := create_tween()
		tw.tween_property(g, "shader_parameter/strength", 1.8, 1.2)
		tw.tween_interval(6.0)
		tw.tween_property(g, "shader_parameter/strength", 0.0, 5.0)
	var gone := create_tween()
	gone.tween_interval(13.5)
	gone.tween_callback(func():
		for r in figure_roots.get(room, []):
			r.visible = false)  # the memory has passed: no ghost, no mosaic


# ------------------------------------------------------------------ snow helpers

func _soft_dot() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


func _snow_layer(tex: Texture2D, amount: int, size: float, scale_rng: Vector2, life: float, grav: Vector3) -> GPUParticles3D:
	var ps := GPUParticles3D.new()
	ps.amount = amount
	ps.lifetime = life
	ps.preprocess = life
	ps.position = Vector3(0, 11, 3)
	ps.visibility_aabb = AABB(Vector3(-40, -14, -35), Vector3(80, 28, 70))
	ps.collision_base_size = 0.02
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(30, 0.5, 26)
	pm.gravity = grav
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 0.25
	pm.scale_min = scale_rng.x
	pm.scale_max = scale_rng.y
	pm.turbulence_enabled = false
	pm.turbulence_noise_strength = 0.8
	pm.turbulence_noise_scale = 4.0
	pm.turbulence_influence_min = 0.02
	pm.turbulence_influence_max = 0.07
	pm.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT
	ps.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_texture = tex
	m.albedo_color = Color(0.92, 0.95, 1.0, 0.75)
	m.emission_enabled = true
	m.emission = Color(0.4, 0.45, 0.6)
	m.emission_energy_multiplier = 0.08
	m.shadow_to_opacity = false
	q.material = m
	ps.draw_pass_1 = q
	add_child(ps)
	return ps


## Soft snow banks against the house, the fence and the path edges.
func _snow_drifts() -> void:
	var sm := _tmat("asphalt_snow", Color(1.08, 1.1, 1.15), 0.3, 0.65)
	var spots := []
	for x in range(-7, 6, 2):
		if absf(float(x)) > 1.5:
			spots.append([Vector3(x + randf_range(-0.4, 0.4), 0, 0.45), Vector3(1.6, 0.35, 0.7)])
		spots.append([Vector3(x + randf_range(-0.4, 0.4), 0, 9.7), Vector3(1.5, 0.3, 0.6)])
	for z in range(1, 10, 2):
		spots.append([Vector3(-11.7, 0, z), Vector3(0.6, 0.3, 1.5)])
		spots.append([Vector3(11.7, 0, z), Vector3(0.6, 0.3, 1.5)])
	for sp in spots:
		var d := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.5
		sph.height = 1.0
		d.mesh = sph
		d.material_override = sm
		d.position = sp[0]
		d.scale = sp[1]
		add_child(d)


# ------------------------------------------------------------------ room dressing

func _dress_rooms() -> void:
	pass


# ------------------------------------------------------------------ ghosts

var ghost_mats := {}  # room -> Array[ShaderMaterial]

## Memory figures are ghosts: translucent ember-gold light, sparks drifting off them.
func _make_ghost(model: Node, root: Node3D) -> void:
	var room := ""
	for f in FIGURES:
		if (f[1] as Vector3).is_equal_approx(root.position):
			room = f[3]
	if not ghost_mats.has(room):
		ghost_mats[room] = []
	_apply_ghost(model, ghost_mats[room])

	# a faint warm light so the ghost touches the room around it
	var gl := OmniLight3D.new()
	gl.position = Vector3(0, 1.0, 0)
	gl.light_color = Color(1.0, 0.6, 0.3)
	gl.light_energy = 0.35
	gl.omni_range = 2.2
	root.add_child(gl)


## Each surface keeps its own texture, drawn faded and glowing.
func _apply_ghost(n: Node, store: Array) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var mi := n as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i)
			var gm := ShaderMaterial.new()
			gm.shader = load("res://shaders/ghost.gdshader")
			gm.set_shader_parameter("strength", 1.0)
			if src is BaseMaterial3D:
				var bm := src as BaseMaterial3D
				gm.set_shader_parameter("tint", bm.albedo_color)
				if bm.albedo_texture:
					gm.set_shader_parameter("albedo_tex", bm.albedo_texture)
					gm.set_shader_parameter("has_tex", true)
			mi.set_surface_override_material(i, gm)
			store.append(gm)
	for c in n.get_children():
		_apply_ghost(c, store)


# ------------------------------------------------------------------ camera fx & cinema

var fx_mat: ShaderMaterial
var bars: Array = []
var cam_attr: CameraAttributesPractical

func _build_camera_fx() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_mat = ShaderMaterial.new()
	fx_mat.shader = load("res://shaders/camera_fx.gdshader")
	fx_mat.set_shader_parameter("warmth", -0.35)
	fx_mat.set_shader_parameter("vignette", 0.32)
	fx_mat.set_shader_parameter("aberration", 0.0012)
	fx_mat.set_shader_parameter("grain", 0.03)
	fx_mat.set_shader_parameter("world_sat", 1.0)
	rect.material = fx_mat
	layer.add_child(rect)
	# letterbox bars (on the UI layer, under captions)
	var ui: CanvasLayer = caption.get_parent()
	for top in [true, false]:
		var b := ColorRect.new()
		b.color = Color.BLACK
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.anchor_right = 1.0
		b.anchor_top = 0.0 if top else 1.0
		b.anchor_bottom = 0.0 if top else 1.0
		ui.add_child(b)
		ui.move_child(b, 0)
		bars.append(b)
	cam_attr = CameraAttributesPractical.new()
	cam_attr.auto_exposure_enabled = false
	cam_attr.dof_blur_amount = 0.08
	player.cam.attributes = cam_attr


## Letterbox in/out.
func _cinema(on: bool, time := 1.2) -> void:
	var vs := get_viewport().get_visible_rect().size
	var h := maxf((vs.y - vs.x / 2.35) * 0.5, 0.0)  # letterbox to 2.35:1
	for i in bars.size():
		var b: ColorRect = bars[i]
		var tw := create_tween()
		if i == 0:
			tw.tween_property(b, "offset_bottom", h if on else 0.0, time).set_trans(Tween.TRANS_SINE)
		else:
			tw.tween_property(b, "offset_top", -h if on else 0.0, time).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(fx_mat, "shader_parameter/vignette", 0.5 if on else 0.32, time)


## Depth of field: keep the subject at `dist` metres sharp, blur what's behind/in front.
func _focus(dist: float) -> void:
	if not cam_attr:
		return
	if dist <= 0.0:
		cam_attr.dof_blur_far_enabled = false
		cam_attr.dof_blur_near_enabled = false
		return
	cam_attr.dof_blur_far_enabled = true
	cam_attr.dof_blur_far_distance = dist + 0.6
	cam_attr.dof_blur_far_transition = maxf(dist * 0.8, 0.8)
	cam_attr.dof_blur_near_enabled = dist > 1.0
	cam_attr.dof_blur_near_distance = maxf(dist * 0.4, 0.1)
	cam_attr.dof_blur_near_transition = 0.3


func _fx_pulse(vig: float, ab: float) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fx_mat, "shader_parameter/vignette", vig, 0.08)
	tw.tween_property(fx_mat, "shader_parameter/aberration", ab, 0.08)
	var back := create_tween().set_parallel(true)
	back.tween_interval(0.1)
	back.chain().tween_property(fx_mat, "shader_parameter/vignette", 0.32, 1.2)
	back.parallel().tween_property(fx_mat, "shader_parameter/aberration", 0.0012, 1.2)


## A memory comes back: warm flash, sound, a breath of camera movement.
func _restore_fx(at: Vector3) -> void:
	_sfx("memory_restore", -2.0)
	player.glance(at, 0.45)
	player.add_shake(0.15, 0.8)
	var tw := create_tween()
	tw.tween_property(fx_mat, "shader_parameter/warmth", 0.6, 0.6)
	tw.tween_property(fx_mat, "shader_parameter/warmth", -0.1, 3.0)


# ------------------------------------------------------------------ audio
## Every sound is optional: drop files into res://assets/audio/<name>.mp3 and they play.

const AUDIO_DIR := "res://assets/audio/"
var music: AudioStreamPlayer
var amb_out: AudioStreamPlayer
var amb_in: AudioStreamPlayer


func _aud(n: String) -> AudioStream:
	for ext in [".mp3", ".ogg", ".wav"]:
		if ResourceLoader.exists(AUDIO_DIR + n + ext):
			return load(AUDIO_DIR + n + ext)
	return null


func _build_audio() -> void:
	music = AudioStreamPlayer.new()
	add_child(music)
	amb_out = _loop_player("wind_loop", -6.0)
	amb_in = _loop_player("house_tone_loop", -60.0)
	_play_music("theme_broken", -10.0, 3.0)


func _loop_player(n: String, vol: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	var st := _aud(n)
	if st:
		if "loop" in st:
			st.set("loop", true)
		p.stream = st
		p.volume_db = vol
		p.play()
	return p


func _play_music(n: String, vol := -8.0, fade_t := 2.0) -> void:
	var st := _aud(n) if n != "" else null
	var tw := create_tween()
	if music.playing:
		tw.tween_property(music, "volume_db", -60.0, fade_t)
	if not st:
		tw.tween_callback(music.stop)
		return
	if "loop" in st:
		st.set("loop", true)
	tw.tween_callback(func():
		music.stream = st
		music.volume_db = -60.0
		music.play())
	tw.tween_property(music, "volume_db", vol, fade_t)


func _sfx(n: String, vol := 0.0, pitch_var := 0.0) -> void:
	var st := _aud(n)
	if not st:
		return
	var p := AudioStreamPlayer.new()
	p.stream = st
	p.volume_db = vol
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func _sfx3d(n: String, pos: Vector3, vol := 0.0, looped := false) -> AudioStreamPlayer3D:
	var st := _aud(n)
	if not st:
		return null
	if looped and "loop" in st:
		st.set("loop", true)
	var p := AudioStreamPlayer3D.new()
	p.stream = st
	p.volume_db = vol
	p.position = pos
	p.unit_size = 3.0
	add_child(p)
	p.play()
	if not looped:
		p.finished.connect(p.queue_free)
	return p


## Footsteps: crunching snow outside, creaking floorboards inside.
func _on_step(on_snow: bool) -> void:
	if on_snow:
		_sfx("step_snow", -8.0, 0.12)
	else:
		_sfx("step_wood", -9.0, 0.1)
		if randf() < 0.3:
			_sfx("floor_creak", -11.0, 0.15)


func _physics_process(delta: float) -> void:
	if not player or not amb_out:
		return
	var outside := player.global_position.z > 0.3
	amb_out.volume_db = move_toward(amb_out.volume_db, -6.0 if outside else -22.0, 25.0 * delta)
	amb_in.volume_db = move_toward(amb_in.volume_db, -60.0 if outside else -12.0, 25.0 * delta)


## Floating dust: lit material, so motes only show where light (window beams, lamps) hits them.
func _dust(center: Vector3) -> void:
	var ps := GPUParticles3D.new()
	ps.amount = 90
	ps.lifetime = 12.0
	ps.preprocess = 12.0
	ps.position = center
	ps.visibility_aabb = AABB(Vector3(-5, -2, -3.5), Vector3(10, 4, 7))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(3.6, 1.2, 2.2)
	pm.gravity = Vector3(0, -0.005, 0)
	pm.initial_velocity_max = 0.03
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.3
	pm.turbulence_influence_min = 0.01
	pm.turbulence_influence_max = 0.03
	var cr := Gradient.new()
	cr.set_color(0, Color(1, 1, 1, 0))
	cr.add_point(0.3, Color(1, 1, 1, 0.55))
	cr.add_point(0.7, Color(1, 1, 1, 0.55))
	cr.set_color(1, Color(1, 1, 1, 0))
	var crt := GradientTexture1D.new()
	crt.gradient = cr
	pm.color_ramp = crt
	ps.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.012, 0.012)
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _soft_dot()
	m.albedo_color = Color(1.4, 1.35, 1.25)
	q.material = m
	ps.draw_pass_1 = q
	add_child(ps)


func _add_probes() -> void:
	for r in ROOM_RECTS:
		var probe := ReflectionProbe.new()
		probe.position = Vector3((r[0] + r[1]) * 0.5, 1.4, (r[2] + r[3]) * 0.5)
		probe.size = Vector3(r[1] - r[0], WALL_H, r[3] - r[2])
		probe.box_projection = true
		probe.interior = true
		add_child(probe)


## Pixelate the ghosts' faces on screen (memories can't quite be seen).
func _update_mosaic() -> void:
	if not fx_mat:
		return
	var cam: Camera3D = player.cam
	var list: Array = []
	for f in face_nodes:
		if not is_instance_valid(f) or not f.is_visible_in_tree():
			continue
		var p: Vector3 = f.global_position
		if cam.is_position_behind(p) or cam.global_position.distance_to(p) > 14.0:
			continue
		# hidden behind a wall? then there's nothing to pixelate
		var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(cam.global_position, p))
		if not hit.is_empty() and (hit.position as Vector3).distance_to(p) > 0.35:
			continue
		var c := cam.unproject_position(p)
		var edge := cam.unproject_position(p + cam.global_transform.basis.x * 0.13)
		var r := c.distance_to(edge)
		list.append(Vector4(c.x, c.y, r, 1.0))
		if list.size() == 4:
			break
	while list.size() < 4:
		list.append(Vector4.ZERO)
	fx_mat.set_shader_parameter("faces", list)
	fx_mat.set_shader_parameter("face_count", 4)


# ------------------------------------------------------------------ dense set dressing
## A lived-in house: every wall, shelf and table carries something.
func _dress_dense() -> void:
	pass


# ------------------------------------------------------------------ placement fixer
const WINDOWS := [Vector3(-5.25, 1.45, 0), Vector3(-2.0, 1.45, 0), Vector3(2.0, 1.45, 0), Vector3(4.5, 1.45, 0),
	Vector3(-7.5, 1.45, -2.25), Vector3(6.0, 1.45, -2.25), Vector3(-3.6, 1.45, -9.0), Vector3(3.4, 1.45, -9.0),
	Vector3(6.0, 1.45, -6.1)]
const WALL_HUNG := ["hanging_picture_frame", "fancy_picture_frame", "wall_clock", "vintage_telephone_wall_clock",
	"ornate_mirror", "dartboard"]
const CEILING := ["Chandelier", "lantern_chandelier", "ceiling_fan"]
const ROOM_RECTS := [[-7.5, -3.0, -4.5, 0.0], [-3.0, 3.0, -4.5, 0.0], [3.0, 6.0, -4.5, 0.0],
	[-7.5, -2.5, -9.0, -4.5], [-2.5, 1.0, -9.0, -4.5], [1.0, 6.0, -9.0, -4.5]]


func _starts(id: String, list: Array) -> bool:
	for x in list:
		if id.begins_with(x):
			return true
	return false


## Footprint half-extents on the floor, taking the Y rotation into account.
func _half(p: Node3D) -> Vector2:
	var sz: Vector3 = p.get_meta("size", Vector3(0.3, 0.3, 0.3))
	var a := absf(fmod(p.rotation.y, PI))
	var c := absf(cos(a))
	var sn := absf(sin(a))
	return Vector2(sz.x * c + sz.z * sn, sz.x * sn + sz.z * c) * 0.5


func _room_of(pos: Vector3) -> Array:
	for r in ROOM_RECTS:
		if pos.x > r[0] and pos.x < r[1] and pos.z > r[2] and pos.z < r[3]:
			return r
	return []


## Fix floating, clipping and overlapping props automatically.
func _settle_props() -> void:
	var props: Array = []
	for c in get_children():
		if c is Node3D and c.has_meta("size") and c.is_in_group("memory_prop"):
			props.append(c)
	var inset := 0.16  # wall + wallpaper + wainscot thickness
	var furniture: Array = []
	for p in props:
		var id := String(p.name).rstrip("0123456789")
		var sz: Vector3 = p.get_meta("size")
		var room: Array = _room_of(p.position)
		if room.is_empty() or _starts(id, CEILING):
			continue
		if _starts(id, WALL_HUNG):
			_snap_to_wall(p, room)
			continue
		if sz.y >= 0.35 and p.position.y < 0.2:
			furniture.append(p)
	# 1) furniture: inside walls, clear of doorways, not overlapping each other
	for it in 6:
		for p in furniture:
			var room: Array = _room_of(p.position)
			if room.is_empty():
				continue
			var h: Vector2 = _half(p)
			p.position.x = clampf(p.position.x, room[0] + inset + h.x, room[1] - inset - h.x)
			p.position.z = clampf(p.position.z, room[2] + inset + h.y, room[3] - inset - h.y)
			for d in DOORWAYS:
				var dc: Vector2 = d[0]
				var ext := Vector2(0.75, 0.9) if d[1] else Vector2(0.9, 0.75)
				var dx: float = p.position.x - dc.x
				var dz: float = p.position.z - dc.y
				var ox: float = ext.x + h.x - absf(dx)
				var oz: float = ext.y + h.y - absf(dz)
				if ox > 0 and oz > 0:
					if d[1]:
						p.position.z += signf(dz if dz != 0 else -1.0) * oz
					else:
						p.position.x += signf(dx if dx != 0 else 1.0) * ox
		for i in furniture.size():
			for j in range(i + 1, furniture.size()):
				var a: Node3D = furniture[i]
				var b: Node3D = furniture[j]
				var ha := _half(a)
				var hb := _half(b)
				var dx: float = b.position.x - a.position.x
				var dz: float = b.position.z - a.position.z
				var ox: float = ha.x + hb.x + 0.03 - absf(dx)
				var oz: float = ha.y + hb.y + 0.03 - absf(dz)
				if ox > 0 and oz > 0:
					# move the smaller one along the axis of least overlap
					var small: Node3D = b if (b.get_meta("size") as Vector3).length() < (a.get_meta("size") as Vector3).length() else a
					var sgn := 1.0 if small == b else -1.0
					if ox < oz:
						small.position.x += sgn * signf(dx if dx != 0 else 1.0) * ox
					else:
						small.position.z += sgn * signf(dz if dz != 0 else 1.0) * oz
	# 2) small things: rest on the furniture beneath them, or on the floor
	for p in props:
		var id := String(p.name).rstrip("0123456789")
		if _starts(id, WALL_HUNG) or _starts(id, CEILING) or furniture.has(p):
			continue
		var room: Array = _room_of(p.position)
		if room.is_empty():
			continue
		var best := 0.06
		var inside := false
		for f in furniture:
			var h := _half(f)
			if absf(p.position.x - f.position.x) < h.x and absf(p.position.z - f.position.z) < h.y:
				var top: float = f.position.y + (f.get_meta("size") as Vector3).y
				if p.position.y > 0.12 and p.position.y < top - 0.1:
					inside = true  # sits on an inner shelf: leave it
				elif top <= p.position.y + 0.35 and top > best:
					best = top
		if not inside:
			p.position.y = best
		var h2 := _half(p)
		p.position.x = clampf(p.position.x, room[0] + inset + h2.x, room[1] - inset - h2.x)
		p.position.z = clampf(p.position.z, room[2] + inset + h2.y, room[3] - inset - h2.y)


## Wall items: flat against the nearest wall, facing into the room.
func _snap_to_wall(p: Node3D, room: Array) -> void:
	var sides := [
		[absf(p.position.z - room[2]), Vector3(0, 0, 1), room[2]],
		[absf(p.position.z - room[3]), Vector3(0, 0, -1), room[3]],
		[absf(p.position.x - room[0]), Vector3(1, 0, 0), room[0]],
		[absf(p.position.x - room[1]), Vector3(-1, 0, 0), room[1]],
	]
	sides.sort_custom(func(a, b): return a[0] < b[0])
	var n: Vector3 = sides[0][1]
	var plane: float = sides[0][2]
	p.rotation.y = atan2(n.x, n.z)
	var depth: float = minf((p.get_meta("size") as Vector3).z, (p.get_meta("size") as Vector3).x)
	var half_w: float = maxf((p.get_meta("size") as Vector3).x, (p.get_meta("size") as Vector3).z) * 0.5
	# slide along the wall until clear of every door and window opening
	var openings: Array = []
	for d in DOORWAYS:
		openings.append([Vector3(d[0].x, 0, d[0].y), 0.85])
	for w in WINDOWS:
		openings.append([w, 0.8])
	for o in openings:
		var op: Vector3 = o[0]
		var r: float = o[1] + half_w + 0.05
		if absf(n.z) > 0.5 and absf(op.z - plane) < 0.3 and absf(p.position.x - op.x) < r:
			p.position.x = op.x + signf(p.position.x - op.x if p.position.x != op.x else 1.0) * r
		elif absf(n.x) > 0.5 and absf(op.x - plane) < 0.3 and absf(p.position.z - op.z) < r:
			p.position.z = op.z + signf(p.position.z - op.z if p.position.z != op.z else 1.0) * r
	var off := 0.125 + depth * 0.5
	if absf(n.z) > 0.5:
		p.position.z = plane + n.z * off
	else:
		p.position.x = plane + n.x * off

const SCARF_STAND := Vector3(0.95, 0, -0.42)
const FIRE_Z := -5.75
const DESK_POS := Vector3(-4.6, 0, -4.15)
const PHOTO_SPOT := Vector3(-3.6, 0, -8.3)
const HEARTH_SPOT := Vector3(-6.0, 0, -5.75)
const STRUGGLE_SPOT := Vector3(-0.75, 0, -8.0)


## Dev: measure FPS with each expensive feature toggled off in turn.
func _perf_test() -> void:
	fade.color.a = 0.0
	player.can_move = false
	player.global_position = Vector3(0.0, 0.1, -0.8)
	player.face_towards(Vector3(-1.0, 0.9, -3.5))
	for i in 120:
		await get_tree().process_frame
	var tests := [
		["baseline", func(): pass],
		["no_sdfgi", func(): env.sdfgi_enabled = false],
		["no_volfog", func(): env.volumetric_fog_enabled = false],
		["no_ssao", func(): env.ssao_enabled = false],
		["no_glow", func(): env.glow_enabled = false],
		["no_snow", func():
			for c in get_children():
				if c is GPUParticles3D:
					c.emitting = false
					c.visible = false],
		["no_shadows", func():
			for c in get_tree().get_nodes_in_group("_none"): pass
			for l in find_children("*", "Light3D", true, false):
				(l as Light3D).shadow_enabled = false],
		["no_probes", func():
			for pr in find_children("*", "ReflectionProbe", true, false):
				pr.visible = false],
	]
	for t in tests:
		t[1].call()
		for i in 60:
			await get_tree().process_frame
		var t0 := Time.get_ticks_usec()
		for i in 120:
			await get_tree().process_frame
		var fps := 120.0 / ((Time.get_ticks_usec() - t0) / 1000000.0)
		print("PERF ", t[0], " (cumulative) fps=", snappedf(fps, 0.1),
			" process_ms=", snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.1),
			" physics_ms=", snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.1),
			" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			" objects=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			" prims=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			" nodes=", Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		if t[0] == "no_glow":
			break
	get_tree().quit()


## Lightweight stylized snowy pine (a few hundred triangles instead of 17 million).
func _pine(pos: Vector3, height: float, rot: float) -> void:
	var root := Node3D.new()
	root.name = "pine_lite"
	root.position = pos
	root.rotation_degrees.y = rot
	add_child(root)
	var bark := _mat(Color(0.22, 0.15, 0.1))
	var needles := _mat(Color(0.09, 0.17, 0.13))
	var snowm := _mat(Color(0.86, 0.9, 0.98))
	var trunk := MeshInstance3D.new()
	var tc := CylinderMesh.new()
	tc.top_radius = height * 0.02
	tc.bottom_radius = height * 0.045
	tc.height = height * 0.35
	tc.radial_segments = 8
	trunk.mesh = tc
	trunk.material_override = bark
	trunk.position.y = tc.height * 0.5
	root.add_child(trunk)
	var tiers := 4
	for i in tiers:
		var f := float(i) / tiers
		var r := height * lerpf(0.32, 0.1, f)
		var th := height * 0.34
		var y := height * (0.22 + f * 0.62)
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = r
		cm.height = th
		cm.radial_segments = 10
		cm.rings = 1
		cone.mesh = cm
		cone.material_override = needles
		cone.position.y = y + th * 0.5
		cone.rotation_degrees.y = i * 17.0
		root.add_child(cone)
		var cap := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 0.0
		sm.bottom_radius = r * 0.92
		sm.height = th * 0.55
		sm.radial_segments = 10
		sm.rings = 1
		cap.mesh = sm
		cap.material_override = snowm
		cap.position.y = y + th * 0.5 + th * 0.28
		root.add_child(cap)


## Dev: walk forward from the path through the open front door and report progress.
func _walk_test() -> void:
	fade.color.a = 0.0
	_open_door("front")
	var start_z := 15.0 if "--gate" in OS.get_cmdline_user_args() else 3.0
	player.global_position = Vector3(0, 0.2, start_z)
	player.face_towards(Vector3(0, 0, -5))
	player.auto_input = Vector2(0, 1)
	for i in 420:
		await get_tree().physics_frame
		if i % 60 == 0:
			var hit := ""
			for k in player.get_slide_collision_count():
				var col := player.get_slide_collision(k).get_collider()
				var nd := col as Node
				hit += " hit=" + (str(nd.get_path()) if nd else str(col))
			print("WALK t=", i / 60.0, "s z=", snappedf(player.global_position.z, 0.01), " y=", snappedf(player.global_position.y, 0.01), hit)
	print("WALK end z=", snappedf(player.global_position.z, 0.01), (" PASS (inside)" if player.global_position.z < -1.0 else " FAIL (stuck)"))
	get_tree().quit()


# ------------------------------------------------------------------ inspect (RE-style)
var _insp_node: Node3D
var _insp_done: Callable
var _insp_ready := false

## Lift an object in front of the eyes, turn it slowly, let its memory speak. E to continue.
func _inspect(n: Node3D, line: String, done: Callable) -> void:
	_inspecting = true
	_insp_ready = false
	_insp_node = n
	_insp_done = done
	player.can_move = false
	hint.visible = false
	bar.visible = false
	_sfx("paper_pickup", -6.0, 0.1)
	var target: Vector3 = player.cam.global_transform * Vector3(0, -0.04, -0.5)
	var tw := create_tween()
	tw.tween_property(n, "global_position", target, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		_insp_ready = true
		_focus(0.5)
		_say(line, 3.5))
	create_tween().tween_property(fx_mat, "shader_parameter/vignette", 0.55, 0.6)


func _update_inspect(delta: float, pressed: bool) -> void:
	if is_instance_valid(_insp_node):
		_insp_node.rotate_y(delta * 0.7)
	hint.visible = _insp_ready
	hint.text = "[ E ]  pack it"
	if _insp_ready and pressed:
		_inspecting = false
		hint.visible = false
		_focus(-1.0)
		create_tween().tween_property(fx_mat, "shader_parameter/vignette", 0.32, 0.6)
		player.can_move = true
		_insp_done.call()


# ------------------------------------------------------------------ drawing puzzle
var _strips: Array = []
var _strip_rot: Array = []
var _puzzle_root: Node3D
var _cam_before: Transform3D

func _drawing_texture() -> ImageTexture:
	var img := Image.create(384, 384, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.97, 0.95, 0.88))
	var ink := func(r: Rect2i, c: Color): img.fill_rect(r, c)
	# sky crayon scribbles, sun, ground, house
	ink.call(Rect2i(300, 24, 56, 56), Color(1.0, 0.8, 0.15))
	ink.call(Rect2i(0, 236, 384, 148), Color(0.35, 0.65, 0.3))
	ink.call(Rect2i(36, 140, 96, 96), Color(0.85, 0.35, 0.25))
	ink.call(Rect2i(66, 180, 30, 56), Color(0.4, 0.25, 0.15))
	for i in 48:
		ink.call(Rect2i(36 + i * 2, 140 - i, 2, i * 2 if i < 24 else (96 - i * 2)), Color(0.45, 0.2, 0.15))
	# parent (tall) and child (small, red scarf) holding hands
	ink.call(Rect2i(200, 110, 28, 28), Color(0.95, 0.8, 0.65))
	ink.call(Rect2i(194, 138, 40, 70), Color(0.3, 0.45, 0.85))
	ink.call(Rect2i(198, 208, 10, 30), Color(0.2, 0.2, 0.3))
	ink.call(Rect2i(220, 208, 10, 30), Color(0.2, 0.2, 0.3))
	ink.call(Rect2i(258, 160, 22, 22), Color(0.95, 0.8, 0.65))
	ink.call(Rect2i(252, 182, 34, 10), Color(0.85, 0.1, 0.1))
	ink.call(Rect2i(254, 192, 30, 30), Color(0.95, 0.75, 0.2))
	ink.call(Rect2i(256, 222, 8, 16), Color(0.2, 0.2, 0.3))
	ink.call(Rect2i(274, 222, 8, 16), Color(0.2, 0.2, 0.3))
	ink.call(Rect2i(234, 176, 22, 5), Color(0.95, 0.8, 0.65))
	return ImageTexture.create_from_image(img)


func _start_puzzle() -> void:
	_puzzle_on = true
	player.can_move = false
	player.cam_locked = true
	hint.visible = false
	_cam_before = player.cam.global_transform
	var desk_top := DESK_POS + Vector3(0, 0.84, 0.05)
	var down := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(DESK_POS + Vector3(0, 2.0, 0.05), DESK_POS + Vector3(0, -0.5, 0.05)))
	if not down.is_empty():
		desk_top = (down.position as Vector3) + Vector3(0, 0.004, 0)
	var tw := create_tween()
	tw.tween_property(player.cam, "global_transform", Transform3D(Basis.looking_at(Vector3(0, -1, -0.15), Vector3(0, 0, -1)), desk_top + Vector3(0, 0.55, 0.08)), 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_say("Turn the pieces until it's whole again.", 3.0))
	_puzzle_root = Node3D.new()
	add_child(_puzzle_root)
	_puzzle_root.global_position = desk_top
	var tex := _drawing_texture()
	var w := 0.19
	_strips.clear()
	_strip_rot.clear()
	for i in 4:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(w, 0.01, w)
		cs.shape = bs
		body.add_child(cs)
		var q := MeshInstance3D.new()
		var qm := PlaneMesh.new()
		qm.size = Vector2(w, w)
		q.mesh = qm
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex
		m.uv1_scale = Vector3(0.5, 0.5, 1)
		m.uv1_offset = Vector3(0.5 * float(i % 2), 0.5 * float(i / 2), 0)
		m.roughness = 0.95
		q.material_override = m
		body.add_child(q)
		body.position = Vector3((float(i % 2) - 0.5) * (w + 0.01), 0, (float(i / 2) - 0.5) * (w + 0.01))
		var r: int = [1, 2, 3, 2][i]  # every piece starts turned the wrong way
		body.rotation.y = r * PI * 0.5
		_puzzle_root.add_child(body)
		_strips.append(body)
		_strip_rot.append(r)


func _update_puzzle(l_click: bool) -> void:
	hint.visible = true
	hint.text = "click a piece to turn it"
	if not l_click:
		return
	var mp := get_viewport().get_mouse_position()
	var from: Vector3 = player.cam.project_ray_origin(mp)
	var to: Vector3 = from + player.cam.project_ray_normal(mp) * 3.0
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if hit.is_empty():
		return
	var idx := _strips.find(hit.collider)
	if idx < 0:
		return
	_strip_rot[idx] = (_strip_rot[idx] + 1) % 4
	var s: Node3D = _strips[idx]
	_sfx("paper_pickup", -6.0, 0.15)
	create_tween().tween_property(s, "rotation:y", s.rotation.y + PI * 0.5, 0.18).set_trans(Tween.TRANS_SINE)
	var solved := true
	for r in _strip_rot:
		if r % 4 != 0:
			solved = false
	if solved:
		_puzzle_on = false
		hint.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var tw := create_tween()
		tw.tween_interval(0.5)
		tw.tween_callback(func(): _sfx("tape", -2.0))
		tw.tween_interval(1.2)
		tw.tween_property(player.cam, "global_transform", _cam_before, 1.0).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func():
			player.cam_locked = false
			player.can_move = true
			_puzzle_root.queue_free()
			_drawing_taped())


## Dev: drive each mini-game and screenshot it.
func _mini_test() -> void:
	fade.color.a = 0.0
	sat = 0.6
	var out := ProjectSettings.globalize_path("res://_shots")
	var snap := func(n: String):
		for i in 20:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))
		print("MINI shot ", n)
	# 1. knitting: half done
	player.global_position = SCARF_STAND + Vector3(0, 0.1, -1.0)
	player.face_towards(SCARF_STAND + Vector3(0, 1.3, 0))
	player.target_pitch = 0.15
	_scarf_visual(0.5)
	await snap.call("30_knit")
	# 2. drawing puzzle
	player.global_position = DESK_POS + Vector3(0, 0.1, 0.9)
	player.face_towards(DESK_POS)
	_start_puzzle()
	await get_tree().create_timer(1.4).timeout
	await snap.call("31_puzzle")
	for i in 4:
		while _strip_rot[i] % 4 != 0:
			_strip_rot[i] = (_strip_rot[i] + 1) % 4
			_strips[i].rotation.y += PI * 0.5
	await snap.call("32_puzzle_solved")
	_puzzle_on = false
	player.cam_locked = false
	player.can_move = true
	_puzzle_root.queue_free()
	_drawing_taped()
	await get_tree().create_timer(1.5).timeout
	player.global_position = DESK_POS + Vector3(0, 0.1, 1.4)
	player.face_towards(drawing_wall.global_position)
	await snap.call("33_drawing_on_wall")
	# 3. door struggle
	player.global_position = STRUGGLE_SPOT + Vector3(0, 0.1, 0)
	player.face_towards(study_door.global_position)
	study_door.rotation.y = -0.6
	study_door.position.x = -0.75 + 0.25
	await snap.call("34_door")
	# 4. inspect
	player.global_position = Vector3(3.4, 0.1, -6.2)
	player.face_towards(Vector3(3.4, 1.0, -8.0))
	var mi := _prop("postcard_set_01", Vector3(1.8, 0.08, -7.9), 1.0, 30)
	await get_tree().create_timer(0.3).timeout
	_inspect(mi, "Postcards. All addressed to me. Never sent.", func(): pass)
	await get_tree().create_timer(1.6).timeout
	await snap.call("35_inspect")
	get_tree().quit()


## Once you're through, the garden gate swings shut behind you. No way back.
func _close_gate() -> void:
	gate_closed = true
	_sfx3d("door_creak", Vector3(0, 1.0, 10.0), -4.0)
	var tw := create_tween().set_parallel(true)
	for g in gate_leaves:
		tw.tween_property(g, "rotation:y", 0.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var clank := create_tween()
	clank.tween_interval(1.6)
	clank.tween_callback(func():
		_sfx3d("door_slam", Vector3(0, 1.0, 10.0), -10.0)
		player.add_shake(0.08, 0.3))
	_collider(Vector3(0, 1, 10), Vector3(1.9, 2, 0.25))
