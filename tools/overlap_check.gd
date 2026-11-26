extends SceneTree
## OVERLAP CHECK (tool, NOT used while the game runs).
## Finds meshes that pass through each other in the house: props sunk into furniture, things
## poking through walls, memory objects buried in the furniture they rest on.
## It loads the level plus the memory scenes, samples each object's mesh vertices and tests
## whether they lie inside another object's mesh.
##   Godot --headless --path <project> -s res://tools/overlap_check.gd
## Optional: pass another level scene after "--" to check it instead of house_level.tscn.
## Every "OVERLAP" line is a problem, except the ones listed in KNOWN_OK (see MEMORY/06-recipes R12).
## Floors and rugs are not checked as targets (props stand on them by design), and ghost figures
## are not checked (bones are not meshes; check seated figures by eye).

const MEMORY_SCENES := ["res://scenes/memories/scarf_memory.tscn", "res://scenes/memories/drawing_memory.tscn",
	"res://scenes/memories/door_memory.tscn", "res://scenes/memories/suitcase_memory.tscn",
	"res://scenes/memories/photo_memory.tscn", "res://scenes/memories/fireplace_memory.tscn"]
## The study door is built into the hallway's back wall on purpose.
const KNOWN_OK := ["DoorMemory/StudyDoor"]

var _objs: Array = []  # {name, tris (world space), aabb, pts}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var level_path: String = args[0] if args.size() > 0 else "res://scenes/level/house_level.tscn"
	var world := Node3D.new()
	root.add_child(world)
	var level: Node = load(level_path).instantiate()
	world.add_child(level)
	for m in MEMORY_SCENES:
		world.add_child(load(m).instantiate())
	await process_frame
	await process_frame
	for room in level.get_node("Rooms").get_children():
		for p in room.get_node("Props").get_children():
			_add(room.name + "/" + p.name, p, true)
		for side in room.get_node("WallLining").get_children():
			_add(room.name + "/Lining" + side.name, side, false)
	for w in level.get_node("House/InnerWalls").get_children() + level.get_node("House/OuterWalls").get_children():
		_add("Wall/" + w.name, w, false)
	for i in range(1, world.get_child_count()):
		var mem := world.get_child(i)
		for c in mem.get_children():
			if c is MemoryFigure or not c is Node3D or c.name == "EmberRestPoint":
				continue
			if c.name in ["PackableItems", "DrawingPieces"]:
				for cc in c.get_children():
					_add(mem.name + "/" + cc.name, cc, true)
			else:
				_add(mem.name + "/" + c.name, c, true)
	var problems := 0
	for a in _objs:
		if not a.subject:
			continue
		for b in _objs:
			if a == b or not a.aabb.grow(0.01).intersects(b.aabb):
				continue
			var inside := 0
			for p in a.pts:
				if b.aabb.has_point(p) and _inside(p, b.tris):
					inside += 1
			var frac: float = float(inside) / float(a.pts.size())
			if inside >= 3 and frac > 0.015:
				var known: bool = String(a.name) in KNOWN_OK
				if not known:
					problems += 1
				print("%s %-45s INSIDE %-40s %5.1f%% of its vertices" % ["known  " if known else "OVERLAP", a.name, b.name, frac * 100.0])
	print("overlap_check: ", problems, " problem(s)")
	quit()


func _meshes(n: Node, out: Array) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).visible and (n as MeshInstance3D).mesh and not (n as MeshInstance3D).skin:
		out.append(n)
	for c in n.get_children():
		_meshes(c, out)


func _add(label: String, node: Node, subject: bool) -> void:
	var ms: Array = []
	_meshes(node, ms)
	var tris := PackedVector3Array()
	for mi in ms:
		var t: Transform3D = mi.global_transform
		for v in (mi as MeshInstance3D).mesh.get_faces():
			tris.append(t * v)
	if tris.is_empty():
		return
	var box := AABB(tris[0], Vector3.ZERO)
	for v in tris:
		box = box.expand(v)
	var step: int = maxi(1, int(tris.size() / 1500))
	var pts := PackedVector3Array()
	for i in range(0, tris.size(), step):
		pts.append(tris[i])
	_objs.append({"name": label, "tris": tris, "aabb": box, "pts": pts, "subject": subject})


## Ray-parity test: a point is inside a closed mesh when a ray from it crosses an odd number of triangles.
func _inside(p: Vector3, t: PackedVector3Array) -> bool:
	var hits := 0
	var dir := Vector3(0.0123, 1.0, 0.0071).normalized()
	for i in range(0, t.size(), 3):
		var a: Vector3 = t[i]
		var b: Vector3 = t[i + 1]
		var c: Vector3 = t[i + 2]
		if maxf(a.x, maxf(b.x, c.x)) < p.x - 0.001 or minf(a.x, minf(b.x, c.x)) > p.x + 0.001:
			continue
		if maxf(a.z, maxf(b.z, c.z)) < p.z - 0.001 or minf(a.z, minf(b.z, c.z)) > p.z + 0.001:
			continue
		if Geometry3D.ray_intersects_triangle(p, dir, a, b, c) != null:
			hits += 1
	return hits % 2 == 1
