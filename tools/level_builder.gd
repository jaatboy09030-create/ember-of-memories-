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
const WALL_HUNG := ["hanging_picture_frame", "fancy_picture_frame", "wall_clock", "vintage_telephone_wall_clock",
	"ornate_mirror", "dartboard"]
const CEILING := ["Chandelier", "lantern_chandelier", "ceiling_fan"]
const DESK_POS := Vector3(-4.6, 0, -4.15)
const FIRE_Z := -5.75
# Props that belong to a memory scene: placed here only so the others settle around them,
# then removed (their final spot is printed so the memory scene can match it).
const MEMORY_OWNED := ["vintage_suitcase"]

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
	_settle_props()
	_report_and_remove_memory_owned()
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
func _tex_mat(mat_name: String, tex := "", tint := Color.WHITE, scale := 0.5, rough := 0.85) -> Material:
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
	mist.size = Vector3(90, 2.4, 50)
	mist.position = Vector3(0, 0.6, 12)
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
	var clad := _tex_mat("wall_cladding", "exterior_wall_cladding", Color(0.78, 0.8, 0.88), 0.45)
	var plaster := _tex_mat("wall_plaster", "painted_plaster_wall", Color(0.92, 0.9, 0.86), 0.4)
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
	_tex_mat("wallpaper_kid", "beige_wall_001", Color(0.8, 0.88, 1.0), 0.5)
	_tex_mat("wallpaper_living", "beige_wall_001", Color(1.0, 0.93, 0.82), 0.5)
	_tex_mat("wallpaper_kitchen", "painted_plaster_wall", Color(0.95, 0.97, 0.88), 0.45)
	_tex_mat("wallpaper_parent", "painted_plaster_wall", Color(1.0, 0.86, 0.82), 0.45)
	_tex_mat("wallpaper_hall", "beige_wall_001", Color(0.95, 0.9, 0.82), 0.5)
	_tex_mat("wallpaper_bedroom", "painted_plaster_wall", Color(0.84, 0.92, 0.86), 0.45)
	var ceiling_m := _col_mat("ceiling_white", Color(0.93, 0.92, 0.9))
	var beam_m := _tex_mat("ceiling_beam_wood", "dark_wooden_planks", Color(0.85, 0.7, 0.58), 1.0, 0.8)
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
		var beams := _group(room, "CeilingBeams")
		var bx: float = r[2] + 0.75
		while bx < r[3] - 0.4:
			_box(beams, "Beam", Vector3(0.16, 0.2, dpt - 0.25), Vector3(bx, WALL_H - 0.12, cz), beam_m)
			bx += 1.5
		_line_room(_group(room, "WallLining"), r)
		var fill := _light(room, "RoomFillLight", Vector3(cx, 1.5, cz), Color(0.6, 0.65, 0.8), 0.66, 6.0)
		fill.omni_attenuation = 1.4
		fill.light_size = 0.4
		fill.light_specular = 0.2
		fill.distance_fade_enabled = true
		fill.distance_fade_begin = 16.0
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
		_box(rooms_root.get_node(room_name), "Rug", rg[3], rg[4], _tex_mat(rg[0], "fabric_pattern_05", rg[1], rg[2], 0.95))
	# Kitchen counter run along the back wall, wall cupboard above
	var kprops := rooms_root.get_node("Kitchen/Props")
	_sketchfab(kprops, "KitchenCounter", "kitchen_counter", Vector3(4.85, 0.06, -4.08), 0.0, true).remove_meta("size")
	_sketchfab(kprops, "KitchenCupboard", "kitchen_cupboard", Vector3(4.85, 1.55, -4.2), 0.0, false).remove_meta("size")


## Wallpaper, wainscot, rails and skirting on the inside of each wall, leaving doorway gaps.
func _line_room(lining: Node3D, r: Array) -> void:
	var x0: float = r[2]
	var x1: float = r[3]
	var z0: float = r[4]
	var z1: float = r[5]
	var paper: Material = _mats[r[6]]
	var skirt := _col_mat("skirting_wood", Color(0.3, 0.2, 0.14))
	var wood := _tex_mat("wainscot_wood", "dark_wooden_planks", Color(1.0, 0.82, 0.68), 1.3, 0.7)
	var trim := _col_mat("wall_trim_wood", Color(0.32, 0.21, 0.14))
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
			_box(side, "Wainscot", sz.call(0.03, 0.95), Vector3(pos.x, 0.475, pos.z) + off * 1.12, wood)
			_box(side, "ChairRail", sz.call(0.06, 0.05), Vector3(pos.x, 0.97, pos.z) + off * 1.2, trim)
			_box(side, "Cornice", sz.call(0.07, 0.1), Vector3(pos.x, WALL_H - 0.08, pos.z) + off * 1.2, trim)
			_box(side, "Skirting", sz.call(0.03, 0.14), Vector3(pos.x, 0.07, pos.z) + off * 1.15, skirt)
		for g in gaps:
			var size := Vector3(1.4, WALL_H - 2.2, 0.02) if along_x else Vector3(0.02, WALL_H - 2.2, 1.4)
			var pos := Vector3(g, 2.2 + size.y * 0.5, a.y) if along_x else Vector3(a.x, 2.2 + size.y * 0.5, g)
			_box(side, "WallpaperAboveDoor", size, pos + off, paper)


# ================================================================ props

func _place_props(rooms_root: Node3D) -> void:
	# [id, position, rotation (deg), collide]. Real-world scale. 0 deg = front faces +Z.
	var L := [
		# ---------------- LIVING — focal: grandma's armchair facing the TV
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
		# ---------------- KID ROOM — focal: the little desk
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
		# ---------------- KITCHEN — counter run, small table
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
		["painted_wooden_cabinet_02", Vector3(5.65, 0.06, -2.85), -90, true],
		["wooden_bucket_01", Vector3(5.65, 0.06, -0.4), 0, false],
		["wooden_crate_02", Vector3(3.45, 0.06, -0.4), 20, true],
		["hanging_picture_frame_01", Vector3(3.1, 1.7, -3.6), 90, false],
		# ---------------- HALLWAY — a corridor to the study door
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
		# ---------------- PARENT ROOM — focal: the fireplace and rocking chair
		["GothicBed_01", Vector3(-5.3, 0.06, -7.9), 0, true],
		["throw_pillows_01", Vector3(-5.3, 0.62, -8.6), 0, false],
		["ClassicNightstand_01", Vector3(-6.85, 0.06, -8.7), 0, true],
		["wooden_candlestick", Vector3(-6.85, 0.62, -8.7), 0, false],
		["vintage_wooden_drawer_01", Vector3(-2.85, 0.06, -8.3), -90, true],
		["vintage_oil_lamp", Vector3(-2.85, 1.0, -8.75), 0, false],
		["brass_vase_02", Vector3(-2.85, 1.0, -7.85), 0, false],
		["dry_branches_medium_01", Vector3(-2.85, 1.2, -7.85), 0, false],
		["Rockingchair_01", Vector3(-4.7, 0.06, -5.0), -110, true],
		["spinning_wheel_01", Vector3(-3.3, 0.06, -5.15), 220, true],
		["wicker_basket_02", Vector3(-4.0, 0.06, -5.0), 0, false],
		["Ottoman_01", Vector3(-5.3, 0.06, -6.45), 0, true],
		["wooden_axe", Vector3(-6.3, 0.08, FIRE_Z - 1.15), 20, false],
		["hanging_picture_frame_03", Vector3(-5.3, 1.95, -8.85), 0, false],
		["fancy_picture_frame_02", Vector3(-2.65, 1.6, -5.4), -90, false],
		# ---------------- BEDROOM — the room the player left
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
		["vintage_suitcase", Vector3(3.3, 0.06, -7.0), 0, false],
		["hanging_picture_frame_02", Vector3(2.9, 1.75, -4.62), 180, false],
		["hanging_picture_frame_03", Vector3(4.3, 1.65, -4.62), 180, false],
	]
	for it in L:
		var room: Array = _room_of(it[1])
		var props_node := rooms_root.get_node("%s/Props" % room[4])
		var p := _prop(props_node, it[0], it[1], it[2], it[3])
		if p:
			_props.append(p)


# ---------------------------------------------------------------- placement fixer
const WINDOW_SPOTS := [Vector3(-5.25, 1.45, 0), Vector3(-2.0, 1.45, 0), Vector3(2.0, 1.45, 0), Vector3(4.5, 1.45, 0),
	Vector3(-7.5, 1.45, -2.25), Vector3(6.0, 1.45, -2.25), Vector3(-3.6, 1.45, -9.0), Vector3(3.4, 1.45, -9.0),
	Vector3(6.0, 1.45, -6.1)]


func _room_of(pos: Vector3) -> Array:
	for r in ROOMS:
		if pos.x > r[2] and pos.x < r[3] and pos.z > r[4] and pos.z < r[5]:
			return [r[2], r[3], r[4], r[5], r[0]]
	return []


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


## Fix floating, clipping and overlapping props automatically.
func _settle_props() -> void:
	var inset := 0.16  # wall + wallpaper + wainscot thickness
	var furniture: Array = []
	for p in _props:
		var id: String = p.get_meta("prop_id")
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
					var small: Node3D = b if (b.get_meta("size") as Vector3).length() < (a.get_meta("size") as Vector3).length() else a
					var sgn := 1.0 if small == b else -1.0
					if ox < oz:
						small.position.x += sgn * signf(dx if dx != 0 else 1.0) * ox
					else:
						small.position.z += sgn * signf(dz if dz != 0 else 1.0) * oz
	# 2) small things: rest on the furniture beneath them, or on the floor
	for p in _props:
		var id: String = p.get_meta("prop_id")
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


## Wall items: flat against the nearest wall, facing into the room, clear of doors/windows.
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
	var size: Vector3 = p.get_meta("size")
	var depth: float = minf(size.z, size.x)
	var half_w: float = maxf(size.x, size.z) * 0.5
	var openings: Array = []
	for d in DOORWAYS:
		openings.append([Vector3(d[0].x, 0, d[0].y), 0.85])
	for w in WINDOW_SPOTS:
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


func _report_and_remove_memory_owned() -> void:
	for p in _props.duplicate():
		var id: String = p.get_meta("prop_id")
		if id in ["vintage_wooden_drawer_01", "SchoolDesk_01", "ArmChair_01", "SchoolChair_01", "ClassicNightstand_01", "WoodenTable_01"]:
			print("PLACED ", id, " pos=", p.position, " size=", p.get_meta("size"), " rot=", p.rotation_degrees.y)
		p.remove_meta("prop_id")
		if id in MEMORY_OWNED:
			print("MEMORY_OWNED ", id, " pos=", p.position, " rot=", p.rotation_degrees.y)
			_props.erase(p)
			p.get_parent().remove_child(p)
			p.free()
