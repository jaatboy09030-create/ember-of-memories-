class_name ModelFit
## Loads a .glb, scales it to a target height and puts its feet at the origin.


## Real-world scale: keep the model's own size; just stand it on the origin.
static func load_native(path: String) -> Node3D:
	var scene: PackedScene = load(path)
	var root := Node3D.new()
	var model: Node3D = scene.instantiate()
	root.add_child(model)
	var box := _aabb(model, Transform3D.IDENTITY)
	var c := box.get_center()
	model.position = Vector3(-c.x, -box.position.y, -c.z)
	root.set_meta("size", box.size)
	return root


static func load_fitted(path: String, height: float) -> Node3D:
	var scene: PackedScene = load(path)
	var root := Node3D.new()
	var model: Node3D = scene.instantiate()
	root.add_child(model)
	var skel := _find_skeleton(model)
	var box := _bone_aabb(model, skel) if skel and skel.get_bone_count() > 3 else _aabb(model, Transform3D.IDENTITY)
	if box.size.y <= 0.0:
		return root
	var s := height / box.size.y
	model.scale = Vector3.ONE * s
	var center := box.get_center()
	model.position = Vector3(-center.x * s, -box.position.y * s, -center.z * s)
	root.set_meta("size", box.size * s)
	if skel:
		_fix_cull(model)
	return root


## Bring T-pose arms down to the sides (for the static Family Pack characters).
## Call after the model is inside the scene tree. drop: 0..1 how far down.
static func relax_arms(model: Node, drop := 0.92) -> void:
	var skel := _find_skeleton(model)
	if not skel:
		return
	var down := (skel.global_transform.basis.inverse() * Vector3.DOWN).normalized()
	for b in skel.get_bone_count():
		var bn := skel.get_bone_name(b)
		if not ("Upperarm" in bn) or "Twist" in bn:
			continue
		var fore := -1
		for c in skel.get_bone_children(b):
			if "Forearm" in skel.get_bone_name(c) and not "Twist" in skel.get_bone_name(c):
				fore = c
		if fore < 0:
			continue
		var g := skel.get_bone_global_pose(b)
		var d := (skel.get_bone_global_pose(fore).origin - g.origin).normalized()
		var out := (d - down * d.dot(down)).normalized()
		var target := (down * drop + out * (1.0 - drop) * 1.6).normalized()
		var q := Quaternion(d, target)
		var new_g := Transform3D(Basis(q) * g.basis, g.origin)
		var parent := skel.get_bone_parent(b)
		var pg := skel.get_bone_global_pose(parent) if parent >= 0 else Transform3D()
		var local := pg.affine_inverse() * new_g
		skel.set_bone_pose_rotation(b, local.basis.get_rotation_quaternion())


## Bounds of a rigged character from its bone positions (mesh AABBs of skinned
## meshes are unreliable: they're in bind space, often in centimetres).
static func _bone_aabb(model: Node, skel: Skeleton3D) -> AABB:
	var xf := Transform3D.IDENTITY
	var chain: Array[Node3D] = []
	var n: Node = skel
	while n and n != model:
		if n is Node3D:
			chain.push_front(n)
		n = n.get_parent()
	for c in chain:
		xf = xf * c.transform
	var box := AABB(xf * skel.get_bone_global_rest(0).origin, Vector3.ZERO)
	for b in skel.get_bone_count():
		box = box.expand(xf * skel.get_bone_global_rest(b).origin)
	# bones stop at the top of the head joint / ankles: pad a little
	box = box.grow(box.size.y * 0.04)
	return box


## Skinned meshes from FBX can carry a tiny, offset bind-space AABB, which makes the
## renderer cull the whole character. A generous margin keeps it drawn.
static func _fix_cull(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).extra_cull_margin = 16384.0
	for c in n.get_children():
		_fix_cull(c)


static func _find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _find_skeleton(c)
		if s:
			return s
	return null


## Swap every StandardMaterial3D for the memory shader (keeps albedo texture + colour).
static func use_memory_shader(node: Node, snow := 0.0) -> void:
	var shader: Shader = load("res://shaders/memory_prop.gdshader")
	_swap(node, shader, snow)


static func _swap(node: Node, shader: Shader, snow := 0.0) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh:
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i)
			if m is BaseMaterial3D:
				var bm := m as BaseMaterial3D
				var sm := ShaderMaterial.new()
				sm.shader = shader
				sm.set_shader_parameter("tint", bm.albedo_color)
				if bm.albedo_texture:
					sm.set_shader_parameter("albedo_tex", bm.albedo_texture)
					sm.set_shader_parameter("has_tex", true)
				sm.set_shader_parameter("roughness_value", bm.roughness)
				sm.set_shader_parameter("snow", snow)
				mi.set_surface_override_material(i, sm)
	for c in node.get_children():
		_swap(c, shader, snow)


static func _aabb(node: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var t := xf
	if node is Node3D:
		t = xf * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh:
		var mi := node as MeshInstance3D
		# Skinned meshes are drawn in skeleton/bind space: their node chain transform
		# (e.g. a 0.01-scaled armature) does not apply to the drawn result.
		var b := (mi.get_aabb() if mi.skin else t * mi.get_aabb())
		out = b
		first = false
	for c in node.get_children():
		var cb := _aabb(c, t)
		if cb.size == Vector3.ZERO:
			continue
		if first:
			out = cb
			first = false
		else:
			out = out.merge(cb)
	return out
