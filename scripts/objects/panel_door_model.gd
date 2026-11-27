@tool
class_name PanelDoorModel
extends Node3D
## PANEL DOOR MODEL: the look of a real six-panel wooden door, built from simple meshes when the
## scene loads (no model file needed). It is only the visuals: put it under a door's leaf node,
## centred on the leaf. Optionally builds the frame too (jamb lining + architrave + plinth blocks).
##
## How to change it (Inspector): size, colours, panel layout, frame on/off. Changes rebuild at once.

## Leaf size in metres (width, height, thickness). The hinge side is -X.
@export var leaf_size := Vector3(1.0, 2.1, 0.05):
	set(v):
		leaf_size = v
		_queue_build()
## Wood tint over the fine-grain texture (paint-like when light, stained when dark).
@export var wood_tint := Color(0.62, 0.42, 0.28):
	set(v):
		wood_tint = v
		_queue_build()
## Handle side: the lever sits near +X (away from the hinges).
@export var with_handles := true:
	set(v):
		with_handles = v
		_queue_build()
## Build the leaf itself (off = frame only, for a frame that stays put while the leaf swings).
@export var with_leaf := true:
	set(v):
		with_leaf = v
		_queue_build()
## Also build a frame around where the leaf sits.
@export var with_frame := false:
	set(v):
		with_frame = v
		_queue_build()
## Frame: wall depth the jamb lining covers, and the architrave width on each face.
@export var wall_depth := 0.28:
	set(v):
		wall_depth = v
		_queue_build()
@export var frame_tint := Color(0.42, 0.29, 0.2):
	set(v):
		frame_tint = v
		_queue_build()

const TEX := "res://assets/textures/fine_grained_wood/fine_grained_wood_%s_1k.jpg"

var _pending := false


func _ready() -> void:
	_build()


func _queue_build() -> void:
	if not is_inside_tree() or _pending:
		return
	_pending = true
	_build.call_deferred()


func _wood(tint: Color, scale := 1.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.albedo_texture = load(TEX % "diff")
	m.roughness_texture = load(TEX % "rough")
	m.normal_enabled = true
	m.normal_texture = load(TEX % "nor_gl")
	m.normal_scale = 0.8
	m.uv1_triplanar = true
	m.uv1_triplanar_sharpness = 6.0
	m.uv1_scale = Vector3.ONE * scale
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


func _metal(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 1.0
	m.roughness = rough
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, node_name := "Part") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _cyl(parent: Node3D, r: float, h: float, pos: Vector3, rot: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 20
	mi.mesh = cm
	mi.position = pos
	mi.rotation = rot
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _build() -> void:
	_pending = false
	for c in get_children():
		if c.has_meta("panel_door_part"):
			remove_child(c)
			c.queue_free()
	var root := Node3D.new()
	root.name = "Model"
	root.set_meta("panel_door_part", true)
	add_child(root)
	if with_leaf:
		_build_leaf(root)
	if with_frame:
		_build_frame(root)


func _build_leaf(root: Node3D) -> void:
	var w := leaf_size.x
	var h := leaf_size.y
	var t := leaf_size.z
	var wood := _wood(wood_tint)
	var panel_wood := _wood(wood_tint.darkened(0.08), 2.2)
	var bead_wood := _wood(wood_tint.darkened(0.25), 3.0)
	var recess := 0.009  # panels sit this far below the stiles and rails on each face
	# the core: the panels' back surface
	_box(root, Vector3(w - 0.01, h - 0.01, t - recess * 2.0), Vector3.ZERO, panel_wood, "Core")
	# stiles and rails (full thickness)
	var stile := clampf(w * 0.12, 0.09, 0.13)
	var top_rail := 0.12
	var bottom_rail := 0.22
	var lock_rail := 0.16
	var frieze_rail := 0.11
	_box(root, Vector3(stile, h, t), Vector3(-w * 0.5 + stile * 0.5, 0, 0), wood, "StileHinge")
	_box(root, Vector3(stile, h, t), Vector3(w * 0.5 - stile * 0.5, 0, 0), wood, "StileLock")
	_box(root, Vector3(stile * 0.85, h, t), Vector3.ZERO, wood, "Muntin")
	var y0 := -h * 0.5
	var rails := [
		[y0 + bottom_rail * 0.5, bottom_rail],
		[y0 + h * 0.45, lock_rail],
		[y0 + h * 0.76, frieze_rail],
		[h * 0.5 - top_rail * 0.5, top_rail]]
	for r in rails:
		_box(root, Vector3(w, r[1], t), Vector3(0, r[0], 0), wood, "Rail")
	# panels between the rails, two columns: a raised field with a bevelled border + a moulding bead
	var col_w := (w - stile * 2.0 - stile * 0.85) * 0.5
	var col_x := [-w * 0.5 + stile + col_w * 0.5, w * 0.5 - stile - col_w * 0.5]
	for k in rails.size() - 1:
		var lo: float = rails[k][0] + rails[k][1] * 0.5
		var hi: float = rails[k + 1][0] - rails[k + 1][1] * 0.5
		var ph := hi - lo
		var py := (lo + hi) * 0.5
		for cx in col_x:
			for side in [1.0, -1.0]:
				var face: float = side * (t * 0.5 - recess)
				# raised field (the flat middle of the panel), with a sloping border step
				_box(root, Vector3(col_w - 0.07, ph - 0.07, 0.006), Vector3(cx, py, face + side * 0.003), panel_wood, "Field")
				_box(root, Vector3(col_w - 0.035, ph - 0.035, 0.003), Vector3(cx, py, face + side * 0.0015), panel_wood, "Bevel")
				# moulding bead round the panel, proud of the stiles by a hair
				var bz: float = face + side * 0.006
				var bd := 0.012
				_box(root, Vector3(col_w, bd, 0.012), Vector3(cx, hi - bd * 0.5, bz), bead_wood, "Bead")
				_box(root, Vector3(col_w, bd, 0.012), Vector3(cx, lo + bd * 0.5, bz), bead_wood, "Bead")
				_box(root, Vector3(bd, ph, 0.012), Vector3(cx - col_w * 0.5 + bd * 0.5, py, bz), bead_wood, "Bead")
				_box(root, Vector3(bd, ph, 0.012), Vector3(cx + col_w * 0.5 - bd * 0.5, py, bz), bead_wood, "Bead")
	# hinges on the -X edge
	var iron := _metal(Color(0.18, 0.17, 0.16), 0.55)
	for hy in [h * 0.5 - 0.22, 0.0, -h * 0.5 + 0.25]:
		_box(root, Vector3(0.012, 0.1, t * 0.7), Vector3(-w * 0.5 - 0.004, hy, 0), iron, "Hinge")
		_cyl(root, 0.009, 0.11, Vector3(-w * 0.5 - 0.008, hy, 0), Vector3.ZERO, iron)
	if with_handles:
		_build_handles(root, w, h, t)


func _build_handles(root: Node3D, w: float, h: float, t: float) -> void:
	var brass := _metal(Color(0.78, 0.6, 0.32), 0.32)
	var hx := w * 0.5 - 0.075
	var hy := -h * 0.5 + 1.0
	for side in [1.0, -1.0]:
		var z: float = side * t * 0.5
		var rot := Vector3(PI * 0.5, 0, 0)
		# back plate, the rose, the lever, a keyhole plate below
		_box(root, Vector3(0.045, 0.2, 0.006), Vector3(hx, hy - 0.04, z + side * 0.003), brass, "Backplate")
		_cyl(root, 0.022, 0.014, Vector3(hx, hy, z + side * 0.01), rot, brass)
		_cyl(root, 0.008, 0.05, Vector3(hx, hy, z + side * 0.035), rot, brass)
		_box(root, Vector3(0.12, 0.017, 0.017), Vector3(hx - 0.055, hy, z + side * 0.058), brass, "Lever")
		var key := _box(root, Vector3(0.008, 0.022, 0.003), Vector3(hx, hy - 0.11, z + side * 0.0065),
			_metal(Color(0.05, 0.04, 0.03), 0.9), "Keyhole")
		key.material_override.metallic = 0.0


func _build_frame(root: Node3D) -> void:
	var w := leaf_size.x
	var h := leaf_size.y
	var d := wall_depth
	var trim := _wood(frame_tint, 2.0)
	var dark := _wood(frame_tint.darkened(0.2), 2.5)
	var gap := 0.006
	var ow := w + gap * 2.0  # opening width
	var oh := h + gap        # opening height (from the floor at -h/2)
	var y0 := -h * 0.5
	# jamb lining (inside the wall opening)
	_box(root, Vector3(0.025, oh, d), Vector3(-ow * 0.5 - 0.0125, y0 + oh * 0.5, 0), trim, "Jamb")
	_box(root, Vector3(0.025, oh, d), Vector3(ow * 0.5 + 0.0125, y0 + oh * 0.5, 0), trim, "Jamb")
	_box(root, Vector3(ow + 0.05, 0.025, d), Vector3(0, y0 + oh + 0.0125, 0), trim, "Head")
	# door stop strip the leaf closes against (just behind the leaf's back face)
	var sz := -(leaf_size.z * 0.5 + 0.0185)
	_box(root, Vector3(0.012, oh, 0.035), Vector3(-ow * 0.5 + 0.006, y0 + oh * 0.5, sz), dark, "Stop")
	_box(root, Vector3(0.012, oh, 0.035), Vector3(ow * 0.5 - 0.006, y0 + oh * 0.5, sz), dark, "Stop")
	_box(root, Vector3(ow, 0.012, 0.035), Vector3(0, y0 + oh - 0.006, sz), dark, "Stop")
	# architrave on both faces of the wall: casing, an inner bead, plinth blocks, a head cap
	var aw := 0.08
	for side in [1.0, -1.0]:
		var z: float = side * (d * 0.5 + 0.009)
		var sx := ow * 0.5 + 0.025 + aw * 0.5 - 0.012
		var ch := oh + 0.025 + aw
		for sgn in [-1.0, 1.0]:
			_box(root, Vector3(aw, ch, 0.018), Vector3(sgn * sx, y0 + ch * 0.5, z), trim, "Casing")
			_box(root, Vector3(0.012, ch - 0.2, 0.012), Vector3(sgn * (sx - aw * 0.5 + 0.008), y0 + 0.2 + (ch - 0.2) * 0.5, z + side * 0.012), dark, "CasingBead")
			_box(root, Vector3(aw + 0.012, 0.2, 0.028), Vector3(sgn * sx, y0 + 0.1, z + side * 0.004), trim, "Plinth")
		_box(root, Vector3(sx * 2.0 + aw, aw, 0.018), Vector3(0, y0 + oh + 0.025 + aw * 0.5, z), trim, "HeadCasing")
		_box(root, Vector3(sx * 2.0 + aw + 0.04, 0.022, 0.04), Vector3(0, y0 + oh + 0.025 + aw + 0.011, z + side * 0.008), dark, "HeadCap")
