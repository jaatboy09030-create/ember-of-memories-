@tool
class_name SnowTrack
extends Node3D
## SNOW TRACK: a line of footprints in snow, projected (Decal) onto whatever is below - porch
## boards, a road, a step. Optionally lays a patch of snow along the track first, so a bare
## surface (the porch) gets snow for the prints to sit in. Textures are generated, no files.
##
## The prints walk along this node's -Z axis, from the origin for `length` metres.
## How to change it (Inspector): length, stride, fill (0 = fresh, 1 = nearly snowed over),
## snow_patch (0 = no snow cover), flip to make them walk the other way.

@export var length := 3.0:
	set(v):
		length = v
		_queue_build()
## Distance between one foot and the next (metres).
@export var stride := 0.62:
	set(v):
		stride = v
		_queue_build()
## Sideways gap between left and right prints.
@export var gauge := 0.2:
	set(v):
		gauge = v
		_queue_build()
@export var print_size := Vector2(0.16, 0.34):
	set(v):
		print_size = v
		_queue_build()
## 0 = fresh prints, 1 = nearly filled in with snow.
@export_range(0.0, 1.0) var fill := 0.3:
	set(v):
		fill = v
		_queue_build()
## Prints point toward -Z (false) or come toward +Z (true).
@export var flip := false:
	set(v):
		flip = v
		_queue_build()
## Width of a snow patch laid along the whole track (0 = none: the ground is already snowy).
@export var snow_patch := 0.0:
	set(v):
		snow_patch = v
		_queue_build()
## How far down the decals reach (metres) - enough to cover steps.
@export var depth := 0.6:
	set(v):
		depth = v
		_queue_build()
## Decals (follow steps and uneven surfaces) or flat meshes (level open ground: put this node ON
## the ground). Outdoors use flat meshes - decals on the snow ground didn't show.
@export var use_decals := true:
	set(v):
		use_decals = v
		_queue_build()
## Darkens the prints (outdoors the ground mist lifts them: use ~0.4 there).
@export_range(0.1, 1.0) var shade := 1.0:
	set(v):
		shade = v
		_queue_build()
@export var rng_seed := 7:
	set(v):
		rng_seed = v
		_queue_build()

static var _print_tex: ImageTexture
static var _print_nor: ImageTexture
static var _snow_tex: ImageTexture

var _pending := false


func _ready() -> void:
	_build()


func _queue_build() -> void:
	if not is_inside_tree() or _pending:
		return
	_pending = true
	_build.call_deferred()


func _build() -> void:
	_pending = false
	for c in get_children():
		if c.has_meta("snow_track_part"):
			remove_child(c)
			c.queue_free()
	_make_textures()
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	if snow_patch > 0.0:
		var d := Decal.new()
		d.set_meta("snow_track_part", true)
		d.name = "SnowCover"
		d.texture_albedo = _snow_tex
		d.size = Vector3(snow_patch, depth, length + 0.6)
		d.position = Vector3(0, 0, -length * 0.5)
		d.modulate = Color(0.93, 0.95, 1.0)
		d.albedo_mix = 1.0
		d.sorting_offset = 0.0
		d.normal_fade = 0.6
		d.cull_mask = 1
		add_child(d)
	var n := int(floor(length / stride)) + 1
	var flat_mat: StandardMaterial3D
	if not use_decals:
		flat_mat = StandardMaterial3D.new()
		flat_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		flat_mat.albedo_texture = _print_tex
		flat_mat.normal_enabled = true
		flat_mat.normal_texture = _print_nor
		flat_mat.roughness = 1.0
		flat_mat.albedo_color = Color(shade, shade, shade, lerpf(1.0, 0.45, fill))
		flat_mat.render_priority = 1
	for i in n:
		var side := -1.0 if i % 2 == 0 else 1.0
		var z := -i * stride - rng.randf_range(-0.04, 0.04)
		if not use_decals:  # a flat print lying on level ground (this node's y = the ground)
			var mi := MeshInstance3D.new()
			mi.set_meta("snow_track_part", true)
			mi.name = "Print%d" % i
			var pm := PlaneMesh.new()
			pm.size = print_size
			mi.mesh = pm
			mi.material_override = flat_mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.position = Vector3(side * gauge * 0.5 + rng.randf_range(-0.02, 0.02), 0.006, z)
			mi.rotation.y = (PI if flip else 0.0) + side * rng.randf_range(0.04, 0.14)
			add_child(mi)
			continue
		var d := Decal.new()
		d.set_meta("snow_track_part", true)
		d.name = "Print%d" % i
		d.texture_albedo = _print_tex
		d.texture_normal = _print_nor
		d.size = Vector3(print_size.x, depth, print_size.y)
		d.position = Vector3(side * gauge * 0.5 + rng.randf_range(-0.02, 0.02), 0, z)
		d.rotation.y = (PI if flip else 0.0) + side * rng.randf_range(0.04, 0.14)
		d.modulate = Color(shade, shade, shade, lerpf(1.0, 0.45, fill) * rng.randf_range(0.85, 1.0))
		d.albedo_mix = 1.0
		d.normal_fade = 0.3
		d.sorting_offset = 1.0
		add_child(d)


## A boot sole: a wide forefoot and a separate heel, blue shadow inside, snow crumbs at the rim.
func _make_textures() -> void:
	if _print_tex and _snow_tex:
		return
	var w := 64
	var h := 144
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var hmap := PackedFloat32Array()
	hmap.resize(w * h)
	var noise := FastNoiseLite.new()
	noise.frequency = 0.18
	for y in h:
		for x in w:
			var u := (x + 0.5) / w * 2.0 - 1.0
			var v := (y + 0.5) / h  # 0 = toe, 1 = heel
			# forefoot ellipse (toe at top) and heel ellipse, a narrow waist between
			var fore := pow(u / 0.92, 2.0) + pow((v - 0.3) / 0.3, 2.0)
			var heel := pow(u / 0.75, 2.0) + pow((v - 0.82) / 0.16, 2.0)
			var waist := pow(u / 0.55, 2.0) + pow((v - 0.6) / 0.14, 2.0)
			var dist := minf(minf(fore, heel), waist)
			var nz := noise.get_noise_2d(x, y) * 0.18
			var inside := 1.0 - smoothstep(0.75, 1.05, dist + nz)
			var rim := smoothstep(0.85, 1.0, dist + nz) * (1.0 - smoothstep(1.0, 1.35, dist + nz))
			var tread := 0.08 * (0.5 + 0.5 * sin(v * 70.0)) * inside
			var tone := 0.3 + 0.32 * dist - tread
			var c := Color(tone * 0.82, tone * 0.9, tone * 1.08, inside)
			if rim > 0.01:  # bright crumbs pushed up at the edge
				c = c.lerp(Color(1, 1, 1, rim * 0.7), rim)
			img.set_pixel(x, y, c)
			hmap[y * w + x] = inside - rim * 0.3
	img.generate_mipmaps()
	_print_tex = ImageTexture.create_from_image(img)
	var nor := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var l := hmap[y * w + maxi(x - 1, 0)]
			var r := hmap[y * w + mini(x + 1, w - 1)]
			var t := hmap[maxi(y - 1, 0) * w + x]
			var b := hmap[mini(y + 1, h - 1) * w + x]
			var nv := Vector3((l - r) * 2.0, (t - b) * 2.0, 1.0).normalized()
			nor.set_pixel(x, y, Color(nv.x * 0.5 + 0.5, nv.y * 0.5 + 0.5, nv.z * 0.5 + 0.5, 1))
	nor.generate_mipmaps()
	_print_nor = ImageTexture.create_from_image(nor)
	# snow cover: white with a ragged, drifting edge
	var s := 256
	var snow := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var n2 := FastNoiseLite.new()
	n2.frequency = 0.03
	n2.fractal_octaves = 4
	for y in s:
		for x in s:
			var u := (x + 0.5) / s * 2.0 - 1.0
			var v := (y + 0.5) / s * 2.0 - 1.0
			var edge := maxf(absf(u), absf(v) * 0.85)
			var nz := n2.get_noise_2d(x, y)
			var a := 1.0 - smoothstep(0.55, 0.95, edge + nz * 0.35)
			var g := 0.9 + nz * 0.08
			snow.set_pixel(x, y, Color(g, g + 0.01, g + 0.04, a))
	snow.generate_mipmaps()
	_snow_tex = ImageTexture.create_from_image(snow)
