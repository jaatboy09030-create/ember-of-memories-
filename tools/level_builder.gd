extends SceneTree
## LEVEL BUILDER (one-off tool, NOT used while the game runs).
## Generates scenes/level/house_level.tscn: the garden, the cottage and its six rooms, with
## every node named and grouped (Exterior / House / Rooms/<Room>/Props ...). Doors and windows
## are instances of their own scenes; props are the real glTF models.
##
## The generated scene is the source of truth: edit it in the editor like any other scene.
## Only run this again if you want to throw away hand edits and rebuild the layout from the
## numbers below:
##   Godot --headless --path <project> -s res://tools/level_builder.gd
##
## Layout (top view, camera looks from +Z):
##   z -9  +-----------+-----------+-----------+
##         | PARENT    | HALLWAY   | BEDROOM   |
##   z -4.5+-----------+-----------+-----------+
##         | KID ROOM  | LIVING    | KITCHEN   |
##   z  0  +-----------+--door-----+-----------+
##                      garden path
##   z 10  ---fence---- GATE -----fence----
##   x:   -7.5        -3          3          6

const OUT_SCENE := "res://scenes/level/house_level.tscn"
const MAT_DIR := "res://materials/level/"
const DOOR_SCENE := "res://scenes/objects/interior_door.tscn"
const WINDOW_SCENE := "res://scenes/objects/house_window.tscn"
const SNOWY_PROP := "res://scripts/level/snowy_prop.gd"
const SNOWY_FOLIAGE := "res://scripts/level/snowy_foliage.gd"
const ROOM_SCRIPT := "res://scripts/level/room.gd"
const NATURE_DIR := "res://assets/stylised assets/stylised assets/Stylized_Nature_MegaKitStandard/glTF/"

const WALL_H := 2.8
const HOUSE_X0 := -7.5
const HOUSE_X1 := 6.0
const HOUSE_Z1 := -9.0
const GATE_HALF := 1.3
const FENCE_S := 0.76
# Doorways: [centre (x,z), along_x]
const DOORWAYS := [[Vector2(0, 0), true], [Vector2(-0.75, -4.5), true], [Vector2(-3.0, -2.25), false],
	[Vector2(3.0, -1.6), false], [Vector2(-2.5, -6.6), false], [Vector2(1.0, -6.6), false]]
const WINDOWS := [
	["WindowFrontKidRoom", Vector3(-5.25, 1.45, 0), Vector3(0, 0, 1)],
	["WindowFrontLivingRoomLeft", Vector3(-2.0, 1.45, 0), Vector3(0, 0, 1)],
	["WindowFrontLivingRoomRight", Vector3(2.0, 1.45, 0), Vector3(0, 0, 1)],
	["WindowFrontKitchen", Vector3(4.5, 1.45, 0), Vector3(0, 0, 1)],
	["WindowWestKidRoom", Vector3(-7.5, 1.45, -2.25), Vector3(-1, 0, 0)],
	["WindowEastKitchen", Vector3(6.0, 1.45, -2.25), Vector3(1, 0, 0)],
	["WindowBackParentRoom", Vector3(-3.6, 1.45, -9.0), Vector3(0, 0, -1)],
	["WindowBackBedroom", Vector3(3.4, 1.45, -9.0), Vector3(0, 0, -1)],
	["WindowEastBedroom", Vector3(6.0, 1.45, -6.1), Vector3(1, 0, 0)],
]
const ROOMS := [
	# [node name, room_id, x0, x1, z0, z1, wallpaper material, floor material]
	["KidRoom", "kid", -7.5, -3.0, -4.5, 0.0, "wallpaper_kid", "floor_old_wood"],
	["LivingRoom", "living", -3.0, 3.0, -4.5, 0.0, "wallpaper_living", "floor_old_wood"],
	["Kitchen", "kitchen", 3.0, 6.0, -4.5, 0.0, "wallpaper_kitchen", "floor_kitchen_planks"],
	["ParentRoom", "parent", -7.5, -2.5, -9.0, -4.5, "wallpaper_parent", "floor_old_wood"],
	["Hallway", "hall", -2.5, 1.0, -9.0, -4.5, "wallpaper_hall", "floor_old_wood"],
	["Bedroom", "bed", 1.0, 6.0, -9.0, -4.5, "wallpaper_bedroom", "floor_old_wood"],
]
const FIRE_Z := -5.75

var level: Node3D
var _mats := {}
var _meshes := {}
var _names := {}       # parent -> {base name: count}
var _props: Array = []  # every indoor prop wrapper (for settling)
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 2026
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAT_DIR))
	level = Node3D.new()
	level.name = "HouseLevel"
	var exterior := _group(level, "Exterior")
	var house := _group(level, "House")
	var rooms := _group(level, "Rooms")
	_build_exterior(exterior)
	_build_house(house)
	_build_rooms(rooms)
	_place_props(rooms)
	_report_placed()
	for p in _props:
		p.remove_meta("size")
	_set_owner(level, level)
	var ps := PackedScene.new()
	var err := ps.pack(level)
	if err == OK:
		err = ResourceSaver.save(ps, OUT_SCENE)
	print("level_builder: ", "OK" if err == OK else "FAILED %d" % err, " nodes=", _count(level))
	level.free()
	quit()


# ================================================================ helpers

func _group(parent: Node, n: String) -> Node3D:
	var g := Node3D.new()
	g.name = n
	parent.add_child(g)
	return g


## Unique readable name under a parent: "Wallpaper", "Wallpaper2", ...
func _unique(parent: Node, base: String) -> String:
	if not _names.has(parent):
		_names[parent] = {}
	var d: Dictionary = _names[parent]
	d[base] = int(d.get(base, 0)) + 1
	return base if d[base] == 1 else "%s%d" % [base, d[base]]


func _pascal(id: String) -> String:
	var out := ""
	for part in id.split("_"):
		if part.is_empty():
			continue
		out += part.substr(0, 1).to_upper() + part.substr(1)
	return out.rstrip("0123456789").rstrip("_") if out.length() > 0 else id


func _save_mat(mat_name: String, m: Material) -> Material:
	m.resource_name = mat_name
	var path := MAT_DIR + mat_name + ".tres"
	ResourceSaver.save(m, path, ResourceSaver.FLAG_CHANGE_PATH)
	m.take_over_path(path)
	_mats[mat_name] = m
	return m


func _col_mat(mat_name: String, c := Color.WHITE) -> Material:
	if _mats.has(mat_name):
		return _mats[mat_name]
	if ResourceLoader.exists("res://materials/" + mat_name + ".tres"):
		_mats[mat_name] = load("res://materials/" + mat_name + ".tres")
		return _mats[mat_name]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return _save_mat(mat_name, m)


## Textured, world-triplanar material (textures from res://assets/textures/<tex>/).
## normal_strength = how deep the surface bumps look; specular = shine (0.5 = Godot default,
## lower = more matte, e.g. painted plaster).
func _tex_mat(mat_name: String, tex := "", tint := Color.WHITE, scale := 0.5, rough := 0.85,
		normal_strength := 0.9, specular := 0.5) -> Material:
	if _mats.has(mat_name):
		return _mats[mat_name]
	var m := StandardMaterial3D.new()
	var base := "res://assets/textures/%s/%s" % [tex, tex]
	if ResourceLoader.exists(base + "_diff.jpg"):
		m.albedo_texture = load(base + "_diff.jpg")
	m.albedo_color = Color(minf(tint.r, 1.0), minf(tint.g, 1.0), minf(tint.b, 1.0))
	if ResourceLoader.exists(base + "_nor.jpg"):
		m.normal_enabled = true
		m.normal_texture = load(base + "_nor.jpg")
		m.normal_scale = normal_strength
	if ResourceLoader.exists(base + "_rough.jpg"):
		m.roughness_texture = load(base + "_rough.jpg")
		m.roughness = 1.0
	else:
		m.roughness = rough
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 4.0
	m.uv1_scale = Vector3.ONE * scale
	m.metallic_specular = specular
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return _save_mat(mat_name, m)


func _box_mesh(size: Vector3) -> BoxMesh:
	var key := str(size)
	if not _meshes.has(key):
		var b := BoxMesh.new()
		b.size = size
		_meshes[key] = b
	return _meshes[key]


## A named box. collide = adds a StaticBody3D "Collision" child with a matching shape.
func _box(parent: Node, n: String, size: Vector3, pos: Vector3, mat: Material, collide := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = _unique(parent, n)
	mi.mesh = _box_mesh(size)
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		body.name = "Collision"
		var cs := CollisionShape3D.new()
		cs.name = "Shape"
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		body.add_child(cs)
		mi.add_child(body)
	return mi


func _shape(body: Node, n: String, pos: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	cs.name = _unique(body, n)
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = pos
	body.add_child(cs)


func _light(parent: Node, n: String, pos: Vector3, color: Color, energy: float, rng: float, shadows := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = n
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = shadows
	parent.add_child(l)
	return l


## A model standing on its origin at real size: wrapper Node3D + the model offset inside it.
func _model(parent: Node, n: String, path: String, pos: Vector3, rot_deg := 0.0, s := 1.0) -> Node3D:
	if not ResourceLoader.exists(path):
		push_warning("missing model " + path)
		return null
	var wrapper := Node3D.new()
	wrapper.name = _unique(parent, n)
	var model: Node3D = (load(path) as PackedScene).instantiate()
	model.name = "Model"
	wrapper.add_child(model)
	var box := ModelUtils.measure(model)
	var c := box.get_center()
	model.position = Vector3(-c.x, -box.position.y, -c.z)
	wrapper.set_meta("size", box.size)
	wrapper.position = pos
	wrapper.rotation_degrees.y = rot_deg
	wrapper.scale = Vector3.ONE * s
	parent.add_child(wrapper)
	return wrapper


## Box collider sized to the model (90% of the footprint).
func _model_collider(m: Node3D) -> void:
	var size: Vector3 = m.get_meta("size")
	var body := StaticBody3D.new()
	body.name = "Collision"
	_shape(body, "Shape", Vector3(0, size.y * 0.5, 0), size * Vector3(0.9, 1.0, 0.9))
	m.add_child(body)


func _sketchfab(parent: Node, n: String, file: String, pos: Vector3, rot := 0.0, collide := false, s := 1.0) -> Node3D:
	var m := _model(parent, n, "res://assets/sketchfab/%s.glb" % file, pos, rot, s)
	if m and collide:
		_model_collider(m)
	return m


## Poly Haven prop. snow > 0 = outdoor prop: grey-in-memory shader with snow on top.
func _prop(parent: Node, id: String, pos: Vector3, rot := 0.0, collide := false, snow := 0.0) -> Node3D:
	var m := _model(parent, _pascal(id), "res://assets/polyhaven/%s/%s.gltf" % [id, id], pos, rot)
	if not m:
		return null
	m.set_meta("prop_id", id)
	if snow > 0.0:
		m.set_script(load(SNOWY_PROP))
		m.set("snow_amount", snow)
	if collide:
		_model_collider(m)
	return m


func _nature(parent: Node, n: String, file: String, pos: Vector3, s: float, rot := 0.0, snow := 0.8,
		trunk_r := 0.0, shadow := false, tint := Color.WHITE) -> Node3D:
	var m := _model(parent, n, NATURE_DIR + file + ".gltf", pos, rot, s)
	if not m:
		return null
	m.remove_meta("size")
	m.set_script(load(SNOWY_FOLIAGE))
	m.set("snow_amount", snow)
	m.set("cast_shadows", shadow)
	m.set("tint", tint)
	if trunk_r > 0.0:
		var body := StaticBody3D.new()
		body.name = "TrunkCollision"
		var cs := CollisionShape3D.new()
		cs.name = "Shape"
		var cyl := CylinderShape3D.new()
		cyl.radius = trunk_r / s
		cyl.height = 2.5 / s
		cs.shape = cyl
		cs.position.y = 1.25 / s
		body.add_child(cs)
		m.add_child(body)
	return m


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


## Axis-aligned wall from a to b with door gaps (centres along the axis). Collides.
func _wall(parent: Node, n: String, a: Vector2, b: Vector2, mat: Material, gaps: Array = []) -> void:
	var along_x := is_equal_approx(a.y, b.y)
	var group := _group(parent, n)
	for seg in _segments(a.x if along_x else a.y, b.x if along_x else b.y, gaps, 1.4):
		var mid: float = (seg[0] + seg[1]) * 0.5
		var length: float = seg[1] - seg[0]
		if along_x:
			_box(group, "WallSegment", Vector3(length, WALL_H, 0.2), Vector3(mid, WALL_H * 0.5, a.y), mat, true)
		else:
			_box(group, "WallSegment", Vector3(0.2, WALL_H, length), Vector3(a.x, WALL_H * 0.5, mid), mat, true)


func _set_owner(n: Node, o: Node) -> void:
	for c in n.get_children():
		c.owner = o
		if c.scene_file_path != "":
			continue  # instanced scene/model: keep its insides as they are
		_set_owner(c, o)


func _count(n: Node) -> int:
	var t := 1
	for c in n.get_children():
		t += _count(c)
	return t


# ================================================================ exterior

func _build_exterior(ext: Node3D) -> void:
	var snow_ground := _tex_mat("ground_snow", "asphalt_snow", Color(1.05, 1.07, 1.12), 0.25, 0.7)
	_box(ext, "SnowGround", Vector3(80, 0.2, 60), Vector3(0, -0.1, 8), snow_ground, true)
	_box(ext, "GardenPath", Vector3(1.6, 0.04, 9.4), Vector3(0, 0.02, 5.3),
		_tex_mat("garden_path_cobblestone", "cobblestone_floor_01", Color(0.85, 0.88, 0.95), 0.6))
	_build_porch(_group(ext, "Porch"))
	_build_fence(_group(ext, "PicketFence"))
	# Invisible walls that keep the player in the garden and the lane
	var boundary := StaticBody3D.new()
	boundary.name = "GardenBoundary"
	ext.add_child(boundary)
	_shape(boundary, "FenceLineLeftOfHouse", Vector3((-12 + HOUSE_X0) * 0.5, 1, 0.3), Vector3(absf(-12 - HOUSE_X0), 2, 0.3))
	_shape(boundary, "FenceLineRightOfHouse", Vector3((12 + HOUSE_X1) * 0.5, 1, 0.3), Vector3(absf(12 - HOUSE_X1), 2, 0.3))
	for w in [["GardenWest", Vector3(-12, 1, 5.1), Vector3(0.3, 2, 9.8)], ["GardenEast", Vector3(12, 1, 5.1), Vector3(0.3, 2, 9.8)],
			["FrontFenceLeft", Vector3(-6.75, 1, 10), Vector3(10.5, 2, 0.3)], ["FrontFenceRight", Vector3(6.75, 1, 10), Vector3(10.5, 2, 0.3)],
			["LaneEnd", Vector3(0, 1, 19), Vector3(14, 2, 0.3)], ["LaneWest", Vector3(-7, 1, 14.5), Vector3(0.3, 2, 9)],
			["LaneEast", Vector3(7, 1, 14.5), Vector3(0.3, 2, 9)]]:
		_shape(boundary, w[0], w[1], w[2])
	var mailbox := _sketchfab(ext, "Mailbox", "mailbox_post", Vector3(2.2, 0, 10.6), 90.0, true)
	mailbox.remove_meta("size")
	# Street lamp outside the gate: the one warm light in the cold
	var lamp := _group(ext, "StreetLamp")
	var lamp_model := _prop(lamp, "street_lamp_02", Vector3(-2.1, 0, 11.0), 0, false, 0.6)
	lamp_model.remove_meta("size")
	var ll := _light(lamp, "StreetLampLight", Vector3(-2.1, 3.1, 11.0), Color(1.0, 0.72, 0.42), 2.2, 9.0, true)
	ll.light_volumetric_fog_energy = 2.0
	var props := _group(ext, "GardenProps")
	for it in [["tree_stump_01", Vector3(5.5, 0, 3.0), 20, false, 1.0], ["garden_gnome", Vector3(3.0, 0, 6.0), 200, false, 0.7],
			["wooden_crate_01", Vector3(-5.5, 0, 1.0), 15, false, 1.0], ["wooden_picnic_table", Vector3(-7.5, 0, 5.5), 20, true, 1.0],
			["tree_stump_02", Vector3(-9.0, 0, 2.5), 70, false, 1.0]]:
		var p := _prop(props, it[0], it[1], it[2], it[3], it[4])
		p.remove_meta("size")
		if String(it[0]).begins_with("tree_stump") or String(it[0]).begins_with("wooden_picnic"):
			p.set("cast_shadows", false)
			p.set("draw_distance", 60.0)
			p.add_to_group("outdoor_only", true)
	_build_nature(_group(ext, "Nature"))
	_snow_drifts(_group(ext, "SnowDrifts"))
	var mist := FogVolume.new()
	mist.name = "GroundMist"
	# Outside only: the volume starts at z 0.5 (just in front of the house) so no mist drifts
	# into the rooms, and OutdoorCulling hides it completely while the camera is indoors.
	mist.size = Vector3(90, 2.4, 40)
	mist.position = Vector3(0, 0.6, 20.5)
	mist.add_to_group("outdoor_only", true)
	var fmat := FogMaterial.new()
	fmat.density = 0.06
	fmat.albedo = Color(0.7, 0.76, 0.92)
	fmat.height_falloff = 1.4
	fmat.edge_fade = 0.6
	mist.material = fmat
	ext.add_child(mist)


func _build_porch(porch: Node3D) -> void:
	var plank := _tex_mat("porch_planks", "dark_wooden_planks", Color(0.9, 0.85, 0.8), 0.7)
	_box(porch, "PorchStepLower", Vector3(3.0, 0.16, 1.2), Vector3(0, 0.08, 0.7), plank)
	_box(porch, "PorchStepUpper", Vector3(2.4, 0.16, 0.5), Vector3(0, 0.08, 1.45), plank)
	# The player can't climb steps: an invisible gentle ramp up onto the porch
	var ramp := StaticBody3D.new()
	ramp.name = "PorchRamp"
	ramp.position = Vector3(0, 0.03, 1.3)
	ramp.rotation.x = atan2(0.2, 3.6)
	_shape(ramp, "Shape", Vector3.ZERO, Vector3(3.0, 0.1, 3.6))
	porch.add_child(ramp)
	_box(porch, "PorchRoof", Vector3(3.4, 0.12, 1.6), Vector3(0, 2.75, 0.75),
		_tex_mat("porch_roof_tiles", "clay_roof_tiles", Color.WHITE, 0.8), true)
	_box(porch, "PorchPostLeft", Vector3(0.14, 2.6, 0.14), Vector3(-1.4, 1.4, 1.4), plank, true)
	_box(porch, "PorchPostRight", Vector3(0.14, 2.6, 0.14), Vector3(1.4, 1.4, 1.4), plank, true)
	# Porch lantern: someone left it burning
	var lantern := _prop(porch, "wooden_lantern_01", Vector3(1.05, 1.75, 0.2))
	lantern.name = "PorchLantern"
	lantern.remove_meta("size")
	_light(porch, "PorchLanternLight", Vector3(1.05, 1.8, 0.5), Color(1.0, 0.6, 0.3), 1.2, 5.0, true)


func _build_fence(fence: Node3D) -> void:
	for run in [["FrontRun", Vector2(-12, 10), Vector2(12, 10), [0.0]], ["WestRun", Vector2(-12, 0.2), Vector2(-12, 10), []],
			["EastRun", Vector2(12, 0.2), Vector2(12, 10), []], ["LeftOfHouseRun", Vector2(-12, 0.3), Vector2(HOUSE_X0 - 0.1, 0.3), []],
			["RightOfHouseRun", Vector2(HOUSE_X1 + 0.1, 0.3), Vector2(12, 0.3), []]]:
		var g := _group(fence, run[0])
		var a: Vector2 = run[1]
		var b: Vector2 = run[2]
		var along_x := is_equal_approx(a.y, b.y)
		for seg in _segments(a.x if along_x else a.y, b.x if along_x else b.y, run[3], GATE_HALF * 2.0 + 0.4):
			var ln: float = seg[1] - seg[0]
			var n := maxi(1, int(round(ln / 1.9)))
			var step := ln / n
			for i in n + 1:
				var t: float = seg[0] + step * i
				var post := _sketchfab(g, "FencePost", "fence_post", Vector3(t, 0, a.y) if along_x else Vector3(a.x, 0, t), 0.0, false, FENCE_S)
				post.remove_meta("size")
			for i in n:
				var c: float = seg[0] + step * (i + 0.5)
				var pm := _sketchfab(g, "FencePanel", "fence_panel", Vector3(c, 0, a.y) if along_x else Vector3(a.x, 0, c), 0.0 if along_x else 90.0, false, FENCE_S)
				pm.scale = Vector3(step / (pm.get_meta("size") as Vector3).x, FENCE_S, FENCE_S)
				pm.remove_meta("size")


func _build_nature(nature: Node3D) -> void:
	nature.add_to_group("outdoor_only", true)
	var garden := _group(nature, "GardenTrees")
	_nature(garden, "Pine", "Pine_3", Vector3(-10.3, 0, 7.0), 0.85, 20, 0.85, 0.3, true)
	_nature(garden, "Pine", "Pine_1", Vector3(10.2, 0, 6.8), 0.8, 140, 0.85, 0.3, true)
	_nature(garden, "Pine", "Pine_5", Vector3(9.9, 0, 2.2), 0.62, 70, 0.85, 0.25, true)
	_nature(garden, "Pine", "Pine_2", Vector3(-10.4, 0, 2.0), 0.66, 200, 0.85, 0.25, true)
	_nature(garden, "YoungPine", "Pine_3", Vector3(-7.6, 0, 8.6), 0.3, 50, 0.9, 0.12, true)
	_nature(garden, "YoungPine", "Pine_4", Vector3(7.3, 0, 8.7), 0.22, 10, 0.9, 0.12, true)
	_nature(garden, "YoungPine", "Pine_2", Vector3(4.6, 0, 8.9), 0.24, 300, 0.9, 0.12, true)
	var bushes := _group(nature, "FrontWallBushes")
	for b in [[-3.1, 30.0, 0.55], [3.3, 110.0, 0.5], [-6.1, 200.0, 0.6], [4.9, 280.0, 0.45]]:
		_nature(bushes, "Bush", "Bush_Common", Vector3(b[0], 0, 0.95), b[2], b[1], 1.0, 0.0, true)
	var rocks := _group(nature, "Rocks")
	_nature(rocks, "Rock", "Rock_Medium_1", Vector3(6.8, -0.12, 5.0), 0.35, 30, 1.0, 0.45)
	_nature(rocks, "Rock", "Rock_Medium_2", Vector3(-3.9, -0.1, 7.6), 0.3, 160, 1.0, 0.4)
	_nature(rocks, "Rock", "Rock_Medium_3", Vector3(8.7, -0.1, 9.0), 0.25, 250, 1.0, 0.0)
	var pebbles := _group(nature, "PathPebbles")
	for k in 8:
		var side := -1.0 if k % 2 == 0 else 1.0
		_nature(pebbles, "Pebble", "Pebble_Round_%d" % (k % 5 + 1), Vector3(side * (1.0 + 0.08 * (k % 3)), -0.03, 1.8 + k * 1.05), 0.55, k * 53.0, 1.0)
	var grass := _group(nature, "WinterGrass")
	var straw := Color(0.95, 0.78, 0.5)
	var tufts := [Vector3(-11.4, 0, 9.4), Vector3(-9.2, 0, 9.6), Vector3(-4.8, 0, 9.5), Vector3(-2.3, 0, 9.6),
		Vector3(2.6, 0, 9.5), Vector3(5.7, 0, 9.6), Vector3(11.3, 0, 9.3), Vector3(11.5, 0, 4.5),
		Vector3(-11.5, 0, 4.8), Vector3(-11.4, 0, 1.2), Vector3(11.4, 0, 1.0), Vector3(1.4, 0, 4.0), Vector3(-1.5, 0, 6.6)]
	for i in tufts.size():
		_nature(grass, "GrassTuft", "Grass_Wispy_Short" if i % 2 == 0 else "Grass_Common_Short", tufts[i], 0.32, i * 41.0, 0.35, 0.0, false, straw)
	var lane := _group(nature, "LaneOutsideGate")
	_nature(lane, "Pine", "Pine_4", Vector3(-5.6, 0, 14.2), 0.7, 90, 0.85, 0.3, true)
	_nature(lane, "Pine", "Pine_1", Vector3(5.9, 0, 16.8), 0.75, 15, 0.85, 0.3, true)
	_nature(lane, "DeadTree", "DeadTree_2", Vector3(4.9, 0, 12.3), 0.42, 120, 0.6, 0.2, true)
	_nature(lane, "Bush", "Bush_Common", Vector3(-3.3, 0, 12.9), 0.5, 60, 1.0)
	_nature(lane, "Bush", "Bush_Common", Vector3(3.5, 0, 17.6), 0.55, 190, 1.0)
	_nature(lane, "Rock", "Rock_Medium_2", Vector3(-4.6, -0.1, 18.0), 0.3, 10, 1.0)
	# The forest beyond: a ring of pines and bare trees for depth (deterministic)
	var forest := _group(nature, "Forest")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var x := -38.0
	while x <= 38.0:
		var z := -21.0
		while z <= 36.0:
			var px := x + rng.randf_range(-1.6, 1.6)
			var pz := z + rng.randf_range(-1.6, 1.6)
			var keep := rng.randf() < 0.62
			var in_garden := absf(px) < 14.0 and pz > -12.0 and pz < 11.5
			var in_lane := absf(px) < 8.5 and pz >= 11.5 and pz < 21.0
			if keep and not in_garden and not in_lane:
				if rng.randf() < 0.78:
					_nature(forest, "ForestPine", "Pine_%d" % rng.randi_range(1, 5), Vector3(px, 0, pz), rng.randf_range(0.75, 1.25), rng.randf() * 360.0, 0.85)
				else:
					_nature(forest, "ForestDeadTree", "DeadTree_%d" % rng.randi_range(1, 5), Vector3(px, 0, pz), rng.randf_range(0.4, 0.6), rng.randf() * 360.0, 0.6)
			z += 4.6
		x += 4.6


## Soft snow banks against the house, the fence and the path edges.
func _snow_drifts(parent: Node3D) -> void:
	var sm := _tex_mat("snow_drift", "asphalt_snow", Color(1.08, 1.1, 1.15), 0.3, 0.65)
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	var spots := []
	for x in range(-7, 6, 2):
		if absf(float(x)) > 1.5:
			spots.append([Vector3(x + _rng.randf_range(-0.4, 0.4), 0, 0.45), Vector3(1.6, 0.35, 0.7)])
		spots.append([Vector3(x + _rng.randf_range(-0.4, 0.4), 0, 9.7), Vector3(1.5, 0.3, 0.6)])
	for z in range(1, 10, 2):
		spots.append([Vector3(-11.7, 0, z), Vector3(0.6, 0.3, 1.5)])
		spots.append([Vector3(11.7, 0, z), Vector3(0.6, 0.3, 1.5)])
	for sp in spots:
		var d := MeshInstance3D.new()
		d.name = _unique(parent, "SnowDrift")
		d.mesh = sphere
		d.material_override = sm
		d.position = sp[0]
		d.scale = sp[1]
		parent.add_child(d)


# ================================================================ house shell

func _build_house(house: Node3D) -> void:
	var clad := _tex_mat("wall_cladding", "exterior_wall_cladding", Color(0.78, 0.8, 0.88), 0.18, 0.85, 1.3, 0.3)
	var plaster := _tex_mat("wall_plaster", "painted_plaster_wall", Color(0.92, 0.9, 0.86), 0.6, 0.85, 1.4, 0.25)
	var outer := _group(house, "OuterWalls")
	_wall(outer, "BackWall", Vector2(HOUSE_X0 - 0.1, HOUSE_Z1), Vector2(HOUSE_X1 + 0.1, HOUSE_Z1), clad)
	_wall(outer, "WestWall", Vector2(HOUSE_X0, HOUSE_Z1), Vector2(HOUSE_X0, 0), clad)
	_wall(outer, "EastWall", Vector2(HOUSE_X1, HOUSE_Z1), Vector2(HOUSE_X1, 0), clad)
	_wall(outer, "FrontWall", Vector2(HOUSE_X0 - 0.1, 0), Vector2(HOUSE_X1 + 0.1, 0), clad, [0.0])
	var inner := _group(house, "InnerWalls")
	_wall(inner, "MiddleWall", Vector2(HOUSE_X0, -4.5), Vector2(HOUSE_X1, -4.5), plaster, [-0.75])
	_wall(inner, "KidLivingWall", Vector2(-3.0, -4.5), Vector2(-3.0, 0), plaster, [-2.25])
	_wall(inner, "LivingKitchenWall", Vector2(3.0, -4.5), Vector2(3.0, 0), plaster, [-1.6])
	_wall(inner, "ParentHallWall", Vector2(-2.5, HOUSE_Z1), Vector2(-2.5, -4.5), plaster, [-6.6])
	_wall(inner, "HallBedroomWall", Vector2(1.0, HOUSE_Z1), Vector2(1.0, -4.5), plaster, [-6.6])
	var headers := _group(house, "DoorwayHeaders")
	for d in DOORWAYS:
		var s := Vector3(1.4, WALL_H - 2.2, 0.2) if d[1] else Vector3(0.2, WALL_H - 2.2, 1.4)
		_box(headers, "Header", s, Vector3(d[0].x, 2.2 + s.y * 0.5, d[0].y), plaster)
	_build_roof(_group(house, "Roof"), clad)
	var frame := _group(house, "FrontDoorFrame")
	var frame_m := _col_mat("door_frame_wood", Color(0.32, 0.2, 0.13))
	_box(frame, "FrameLeft", Vector3(0.12, 2.3, 0.3), Vector3(-0.76, 1.15, 0), frame_m)
	_box(frame, "FrameRight", Vector3(0.12, 2.3, 0.3), Vector3(0.76, 1.15, 0), frame_m)
	var windows := _group(house, "Windows")
	var window_scene: PackedScene = load(WINDOW_SCENE)
	for w in WINDOWS:
		var inst: Node3D = window_scene.instantiate()
		inst.name = w[0]
		inst.position = w[1]
		var out: Vector3 = w[2]
		inst.rotation.y = atan2(out.x, out.z)
		windows.add_child(inst)
	var doors := _group(house, "Doors")
	var door_scene: PackedScene = load(DOOR_SCENE)
	for d in [["FrontDoor", "front", Vector3(0, 0, 0), true], ["KidRoomDoor", "kid", Vector3(-3.0, 0, -2.25), false],
			["HallwayDoor", "hall", Vector3(-0.75, 0, -4.5), true], ["BedroomDoor", "bed", Vector3(1.0, 0, -6.6), false],
			["ParentRoomDoor", "parent", Vector3(-2.5, 0, -6.6), false]]:
		var inst: Node3D = door_scene.instantiate()
		inst.name = d[0]
		inst.set("door_id", d[1])
		if d[1] == "front":
			inst.set("lock_behind_player", true)  # once you are inside there is no way back out
		inst.position = d[2]
		inst.rotation_degrees.y = 0.0 if d[3] else 90.0
		doors.add_child(inst)


func _build_roof(roof: Node3D, clad: Material) -> void:
	var roof_m := _tex_mat("roof_tiles", "clay_roof_tiles", Color(0.9, 0.9, 0.95), 0.7)
	var snow_m := _col_mat("snow_white")
	var cxh := (HOUSE_X0 + HOUSE_X1) * 0.5
	var wid := HOUSE_X1 - HOUSE_X0 + 1.2
	var pitch := atan2(2.2, 4.5)
	var slab := 4.5 / cos(pitch) + 0.6
	for side in [-1.0, 1.0]:
		var label := "Back" if side < 0 else "Front"
		var rs := _box(roof, "RoofSlope" + label, Vector3(wid, 0.18, slab), Vector3(cxh, WALL_H + 1.2, -4.5 + side * 2.25), roof_m)
		rs.rotation.x = side * pitch
		var sn := _box(roof, "RoofSnow" + label, Vector3(wid - 0.2, 0.06, slab - 0.4), Vector3(cxh, WALL_H + 1.32, -4.5 + side * 2.25), snow_m)
		sn.rotation.x = side * pitch
	var prism := PrismMesh.new()
	prism.size = Vector3(9.2, 2.2, 0.2)
	for x in [HOUSE_X0, HOUSE_X1]:
		var g := MeshInstance3D.new()
		g.name = "GableWest" if x < 0 else "GableEast"
		g.mesh = prism
		g.material_override = clad
		g.position = Vector3(x, WALL_H + 1.1, -4.5)
		g.rotation_degrees.y = 90
		roof.add_child(g)
	_box(roof, "Chimney", Vector3(0.9, 3.4, 1.2), Vector3(-7.1, WALL_H + 1.7, -5.75),
		_tex_mat("chimney_brick", "brick_wall_02", Color.WHITE, 0.9))


# ================================================================ rooms

func _build_rooms(rooms_root: Node3D) -> void:
	_tex_mat("floor_old_wood", "old_wood_floor", Color.WHITE, 0.35, 0.7)
	_tex_mat("floor_kitchen_planks", "dark_wooden_planks", Color(1.0, 0.95, 0.9), 0.5)
	# All walls use the detailed plaster texture (beige_wall_001 is a flat single colour, which
	# is what made the walls look plastic-smooth). Matte (low specular) and a deeper bump.
	_tex_mat("wallpaper_kid", "painted_plaster_wall", Color(0.82, 0.9, 1.0), 0.6, 0.85, 1.5, 0.25)
	_tex_mat("wallpaper_living", "painted_plaster_wall", Color(1.0, 0.93, 0.82), 0.6, 0.85, 1.5, 0.25)
	_tex_mat("wallpaper_kitchen", "painted_plaster_wall", Color(0.95, 0.97, 0.88), 0.6, 0.85, 1.5, 0.25)
	_tex_mat("wallpaper_parent", "painted_plaster_wall", Color(1.0, 0.86, 0.82), 0.6, 0.85, 1.5, 0.25)
	_tex_mat("wallpaper_hall", "painted_plaster_wall", Color(0.95, 0.9, 0.82), 0.6, 0.85, 1.5, 0.25)
	_tex_mat("wallpaper_bedroom", "painted_plaster_wall", Color(0.84, 0.92, 0.86), 0.6, 0.85, 1.5, 0.25)
	var ceiling_m := _tex_mat("ceiling_white", "painted_plaster_wall", Color(0.97, 0.96, 0.94), 0.5, 0.9, 0.8, 0.2)
	for r in ROOMS:
		var room := Node3D.new()
		room.name = r[0]
		room.set_script(load(ROOM_SCRIPT))
		room.set("room_id", r[1])
		rooms_root.add_child(room)
		var cx: float = (r[2] + r[3]) * 0.5
		var cz: float = (r[4] + r[5]) * 0.5
		var w: float = r[3] - r[2]
		var dpt: float = r[5] - r[4]
		_box(room, "Floor", Vector3(w, 0.06, dpt), Vector3(cx, 0.03, cz), _mats[r[7]])
		_box(room, "Ceiling", Vector3(w, 0.05, dpt), Vector3(cx, WALL_H - 0.025, cz), ceiling_m)
		_line_room(_group(room, "WallLining"), r)
		# The room's ONE light: a pendant lamp in the middle of the ceiling (_pendant).
		# Every shadow in the room falls away from that lamp, so the lighting reads as real.
		var lamp_pos := Vector3(cx, WALL_H - 0.62, cz)
		var fill := _light(room, "RoomFillLight", lamp_pos, Color(0.62, 0.68, 0.86), 0.9, maxf(w, dpt) * 0.85 + 1.0, true)
		fill.omni_attenuation = 1.0
		fill.light_specular = 0.25
		fill.shadow_blur = 1.5
		fill.light_volumetric_fog_energy = 0.0
		fill.distance_fade_enabled = true
		fill.distance_fade_begin = 16.0
		_pendant(room, lamp_pos)
		var probe := ReflectionProbe.new()
		probe.name = "ReflectionProbe"
		probe.position = Vector3(cx, 1.4, cz)
		probe.size = Vector3(w, WALL_H, dpt)
		probe.box_projection = true
		probe.interior = true
		room.add_child(probe)
		_group(room, "Props")
	# Rugs
	var rugs := {"LivingRoom": ["rug_living", Color(0.85, 0.45, 0.38), 0.9, Vector3(2.6, 0.015, 1.8), Vector3(1.2, 0.07, -2.8)],
		"KidRoom": ["rug_kid", Color(0.35, 0.5, 0.8), 1.0, Vector3(1.8, 0.015, 1.3), Vector3(-5.2, 0.07, -2.1)],
		"Hallway": ["rug_hall_runner", Color(0.75, 0.4, 0.35), 1.1, Vector3(1.1, 0.015, 3.6), Vector3(-0.75, 0.07, -6.75)],
		"ParentRoom": ["rug_parent", Color(0.8, 0.55, 0.45), 1.0, Vector3(1.2, 0.015, 1.6), Vector3(-5.0, 0.07, FIRE_Z)]}
	for room_name in rugs:
		var rg: Array = rugs[room_name]
		# Paper-thin, just above the floor: furniture legs stand on it instead of sinking in.
		var rug_size: Vector3 = rg[3]
		var rug_pos: Vector3 = rg[4]
		_box(rooms_root.get_node(room_name), "Rug", Vector3(rug_size.x, 0.004, rug_size.z), Vector3(rug_pos.x, 0.063, rug_pos.z),
			_tex_mat(rg[0], "fabric_pattern_05", rg[1], rg[2], 0.95))
	# Kitchen counter run along the back wall, wall cupboard above
	var kprops := rooms_root.get_node("Kitchen/Props")
	_sketchfab(kprops, "KitchenCounter", "kitchen_counter", Vector3(4.85, 0.06, -4.08), 0.0, true).remove_meta("size")


## Wallpaper and skirting on the inside of each wall, leaving doorway gaps (kept minimal).
func _line_room(lining: Node3D, r: Array) -> void:
	var x0: float = r[2]
	var x1: float = r[3]
	var z0: float = r[4]
	var z1: float = r[5]
	var paper: Material = _mats[r[6]]
	var skirt := _col_mat("skirting_wood", Color(0.3, 0.2, 0.14))
	var sides := [["BackWall", Vector2(x0, z0), Vector2(x1, z0), Vector3(0, 0, 1)], ["FrontWall", Vector2(x0, z1), Vector2(x1, z1), Vector3(0, 0, -1)],
		["WestWall", Vector2(x0, z0), Vector2(x0, z1), Vector3(1, 0, 0)], ["EastWall", Vector2(x1, z0), Vector2(x1, z1), Vector3(-1, 0, 0)]]
	for s in sides:
		var side := _group(lining, s[0])
		var a: Vector2 = s[1]
		var b: Vector2 = s[2]
		var n: Vector3 = s[3]
		var along_x := is_equal_approx(a.y, b.y)
		var gaps := []
		for d in DOORWAYS:
			var c: Vector2 = d[0]
			if d[1] == along_x:
				if along_x and absf(c.y - a.y) < 0.01 and c.x > a.x and c.x < b.x:
					gaps.append(c.x)
				elif not along_x and absf(c.x - a.x) < 0.01 and c.y > a.y and c.y < b.y:
					gaps.append(c.y)
		var off := Vector3(n.x, 0, n.z) * 0.115
		for seg in _segments(a.x if along_x else a.y, b.x if along_x else b.y, gaps, 1.4):
			var mid: float = (seg[0] + seg[1]) * 0.5
			var length: float = seg[1] - seg[0]
			var pos := Vector3(mid, WALL_H * 0.5, a.y) if along_x else Vector3(a.x, WALL_H * 0.5, mid)
			var sz := func(thick: float, h: float) -> Vector3:
				return Vector3(length, h, thick) if along_x else Vector3(thick, h, length)
			_box(side, "Wallpaper", sz.call(0.02, WALL_H), pos + off, paper)
			_box(side, "Skirting", sz.call(0.03, 0.14), Vector3(pos.x, 0.07, pos.z) + off * 1.15, skirt)
		for g in gaps:
			var size := Vector3(1.4, WALL_H - 2.2, 0.02) if along_x else Vector3(0.02, WALL_H - 2.2, 1.4)
			var pos := Vector3(g, 2.2 + size.y * 0.5, a.y) if along_x else Vector3(a.x, 2.2 + size.y * 0.5, g)
			_box(side, "WallpaperAboveDoor", size, pos + off, paper)


# ================================================================ props

func _place_props(rooms_root: Node3D) -> void:
	# Story furniture only - kept minimal on purpose (no clutter that isn't part of a memory).
	# [id, position, rotation (deg), collide, optional scale]. Real-world scale. 0 deg = front faces +Z.
	# Positions are FINAL (there is no automatic shuffling any more). Memory scenes put people
	# and objects on some of these (armchair, desk + chair, dresser, nightstands, bedroom table),
	# so moving one means moving that memory scene's nodes too (MEMORY/04-memories.md).
	# After any change run the overlap check in MEMORY/06-recipes.md.
	var L := [
		# ---------------- LIVING - grandma's armchair (ScarfMemory/GrandmaKnitting sits in it)
		["painted_wooden_sofa", Vector3(1.5, 0.06, -3.946342), 0, true],
		["CoffeeTable_01", Vector3(0.7107189, 0.06, -2.85), 0, true],
		["ArmChair_01", Vector3(-1.5430429, 0.06, -2.42159), 55, true],
		# ---------------- KID ROOM - the little desk (DrawingMemory puzzle + BoyAtDesk)
		["vintage_day_bed", Vector3(-6.912612, 0.06, -3.35), 90, true],
		["SchoolDesk_01", Vector3(-4.6, 0.06, -4.140611), 0, true],
		["SchoolChair_01", Vector3(-4.6, 0.06, -3.5), 180, true],
		["painted_wooden_shelves", Vector3(-3.45, 0.06, -3.9), -90, true],
		["Shelf_01", Vector3(-5.95, 0.06, -4.2), 0, true],
		# ---------------- KITCHEN - counter run (KitchenCounter is added in _build_rooms), table
		["electric_stove", Vector3(3.45, 0.06, -4.0161896), 0, true],
		["round_wooden_table_01", Vector3(4.7, 0.06, -1.9), 0, true, 0.76],  # dining table (WoodenTable_02 is a 42 cm side table), top at 0.82
		["painted_wooden_chair_02", Vector3(3.95, 0.06, -1.9), 90, true],
		["painted_wooden_chair_02", Vector3(5.45, 0.06, -1.9), -90, true],
		# ---------------- HALLWAY - a bare corridor to the study door (no furniture)
		# ---------------- PARENT ROOM - fireplace (memory scene), bed, the photo dresser
		["GothicBed_01", Vector3(-5.3, 0.06, -7.82), 0, true],
		["ClassicNightstand_01", Vector3(-6.85, 0.06, -8.627904), 0, true],
		["vintage_wooden_drawer_01", Vector3(-3.9034564, 0.06, -7.982443), -90, true],
		["Rockingchair_01", Vector3(-4.7, 0.06, -5.1352453), -110, true],
		# ---------------- BEDROOM - the room the player left (SuitcaseMemory items rest on these)
		["vintage_day_bed", Vector3(5.412612, 0.06, -7.8537226), -90, true],
		["ClassicNightstand_01", Vector3(4.55, 0.06, -8.627904), 0, true],
		["WoodenTable_01", Vector3(2.9, 0.06, -4.9885874), 180, true],
		["painted_wooden_chair_01", Vector3(2.9, 0.06, -5.617087), 0, true],
	]
	for it in L:
		var room: Array = _room_of(it[1])
		var props_node := rooms_root.get_node("%s/Props" % room[4])
		var p := _prop(props_node, it[0], it[1], it[2], it[3])
		if p and it.size() > 4:  # optional 5th field: uniform scale
			p.scale = Vector3.ONE * float(it[4])
		if p:
			_props.append(p)


func _room_of(pos: Vector3) -> Array:
	for r in ROOMS:
		if pos.x > r[2] and pos.x < r[3] and pos.z > r[4] and pos.z < r[5]:
			return [r[2], r[3], r[4], r[5], r[0]]
	return []


## A plain pendant lamp hanging from the ceiling: cord, open shade, glowing bulb.
## light_pos = where the room's light sits (just under the bulb). Shade, bulb and cord cast
## no shadow, so the ceiling stays softly lit instead of going pitch black.
func _pendant(room: Node3D, light_pos: Vector3) -> void:
	var lamp := _group(room, "CeilingLamp")
	var shade_m := _col_mat("lamp_shade", Color(0.18, 0.16, 0.14)) as StandardMaterial3D
	shade_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	ResourceSaver.save(shade_m, shade_m.resource_path)
	var bulb_m: Material = _mats.get("lamp_bulb")
	if bulb_m == null:
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(1.0, 0.95, 0.85)
		bm.emission_enabled = true
		bm.emission = Color(1.0, 0.9, 0.75)
		bm.emission_energy_multiplier = 2.5
		bulb_m = _save_mat("lamp_bulb", bm)
	var shade_mesh := CylinderMesh.new()
	shade_mesh.top_radius = 0.07
	shade_mesh.bottom_radius = 0.2
	shade_mesh.height = 0.18
	shade_mesh.cap_bottom = false
	var shade := MeshInstance3D.new()
	shade.name = "Shade"
	shade.mesh = shade_mesh
	shade.material_override = shade_m
	shade.position = light_pos + Vector3(0, 0.12, 0)
	shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lamp.add_child(shade)
	var bulb_mesh := SphereMesh.new()
	bulb_mesh.radius = 0.045
	bulb_mesh.height = 0.09
	var bulb := MeshInstance3D.new()
	bulb.name = "Bulb"
	bulb.mesh = bulb_mesh
	bulb.material_override = bulb_m
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bulb.position = light_pos + Vector3(0, 0.08, 0)
	lamp.add_child(bulb)
	var cord_top := WALL_H - 0.05
	var cord_bottom := light_pos.y + 0.21
	var cord := _box(lamp, "Cord", Vector3(0.012, cord_top - cord_bottom, 0.012), Vector3(light_pos.x, (cord_top + cord_bottom) * 0.5, light_pos.z), shade_m)
	cord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Prints where the furniture that memory scenes sit people/objects on ended up, so a memory
## scene can be checked against it. (Memory-owned objects such as the suitcase are never
## placed by the level: their memory scene owns them.)
func _report_placed() -> void:
	for p in _props:
		var id: String = p.get_meta("prop_id")
		if id in ["vintage_wooden_drawer_01", "SchoolDesk_01", "ArmChair_01", "SchoolChair_01", "ClassicNightstand_01", "WoodenTable_01"]:
			print("PLACED ", id, " pos=", p.position, " size=", p.get_meta("size"), " rot=", p.rotation_degrees.y)
		p.remove_meta("prop_id")
