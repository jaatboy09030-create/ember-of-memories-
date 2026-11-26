class_name ModelUtils
## Small helpers for imported 3D models (glTF / FBX). Static: call as ModelUtils.xxx().
##   find_skeleton / find_animation_player -> dig the node out of an imported model
##   fix_cull   -> stops skinned FBX characters vanishing at screen edges
##   measure    -> bounding box of a model (used by tools/level_builder.gd to stand props
##                 on the floor at their real size)


static func find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := find_skeleton(c)
		if s:
			return s
	return null


static func find_animation_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var a := find_animation_player(c)
		if a:
			return a
	return null


## Skinned meshes from FBX can carry a tiny, offset bind-space AABB, which makes the
## renderer cull the whole character. A generous margin keeps it drawn.
static func fix_cull(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).extra_cull_margin = 16384.0
	for c in n.get_children():
		fix_cull(c)


## Bounding box of every mesh under `node` (in node's parent space).
static func measure(node: Node, xf := Transform3D.IDENTITY) -> AABB:
	var out := AABB()
	var first := true
	var t := xf
	if node is Node3D:
		t = xf * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh:
		var mi := node as MeshInstance3D
		# Skinned meshes are drawn in bind space: their node chain transform does not apply.
		out = mi.get_aabb() if mi.skin else t * mi.get_aabb()
		first = false
	for c in node.get_children():
		var cb := measure(c, t)
		if cb.size == Vector3.ZERO:
			continue
		if first:
			out = cb
			first = false
		else:
			out = out.merge(cb)
	return out
