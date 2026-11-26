class_name YarnMesh
## Builds yarn geometry: smooth round tubes that follow a list of points.
## Used by the trailing YarnThread and by every knitted row of KnitCloth, so the cloth is
## literally made of the same thread. Static helpers: YarnMesh.build([...], radius).
##
## UVs: u = distance along the yarn divided by its circumference, v = around the tube.
## shaders/yarn.gdshader uses them to draw the twisted plies.


## One tube along `points` (smoothed). Returns a ready ArrayMesh, or null if < 2 points.
static func build(points: PackedVector3Array, radius: float, sides := 7, smooth_steps := 4) -> ArrayMesh:
	var arrays := _new_arrays()
	add_tube(arrays, points, radius, sides, smooth_steps)
	return commit(arrays)


## Several tubes in one mesh (one draw call). Each entry of `strands` is a PackedVector3Array.
static func build_many(strands: Array, radius: float, sides := 7, smooth_steps := 4) -> ArrayMesh:
	var arrays := _new_arrays()
	for s in strands:
		add_tube(arrays, s, radius, sides, smooth_steps)
	return commit(arrays)


static func _new_arrays() -> Dictionary:
	return {"v": PackedVector3Array(), "n": PackedVector3Array(), "uv": PackedVector2Array(), "i": PackedInt32Array()}


static func commit(a: Dictionary) -> ArrayMesh:
	if a["v"].size() == 0:
		return null
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = a["v"]
	arr[Mesh.ARRAY_NORMAL] = a["n"]
	arr[Mesh.ARRAY_TEX_UV] = a["uv"]
	arr[Mesh.ARRAY_INDEX] = a["i"]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


static func add_tube(a: Dictionary, raw_points: PackedVector3Array, radius: float, sides: int, smooth_steps: int) -> void:
	var pts := smooth(raw_points, smooth_steps)
	if pts.size() < 2:
		return
	var verts: PackedVector3Array = a["v"]
	var norms: PackedVector3Array = a["n"]
	var uvs: PackedVector2Array = a["uv"]
	var idx: PackedInt32Array = a["i"]
	var base := verts.size()
	var circumference := TAU * radius
	# a side vector carried along the curve (parallel transport) so the tube never twists
	var tangent := (pts[1] - pts[0]).normalized()
	var side := tangent.cross(Vector3.UP)
	if side.length() < 0.01:
		side = tangent.cross(Vector3.RIGHT)
	side = side.normalized()
	var dist := 0.0
	for p in pts.size():
		if p > 0:
			dist += pts[p].distance_to(pts[p - 1])
		var t: Vector3
		if p == 0:
			t = pts[1] - pts[0]
		elif p == pts.size() - 1:
			t = pts[p] - pts[p - 1]
		else:
			t = pts[p + 1] - pts[p - 1]
		t = t.normalized()
		side = (side - t * side.dot(t)).normalized()
		var up := t.cross(side)
		for s in sides + 1:
			var ang := TAU * float(s) / sides
			var n := side * cos(ang) + up * sin(ang)
			verts.append(pts[p] + n * radius)
			norms.append(n)
			uvs.append(Vector2(dist / circumference, float(s) / sides))
	var ring := sides + 1
	for p in pts.size() - 1:
		for s in sides:
			var i0 := base + p * ring + s
			var i1 := i0 + ring
			idx.append_array([i0, i1, i0 + 1, i0 + 1, i1, i1 + 1])
	a["v"] = verts
	a["n"] = norms
	a["uv"] = uvs
	a["i"] = idx


## Catmull-Rom smoothing: `steps` extra points between each pair.
static func smooth(points: PackedVector3Array, steps: int) -> PackedVector3Array:
	if points.size() < 3 or steps <= 0:
		return points
	var out := PackedVector3Array()
	for i in points.size() - 1:
		var p0 := points[maxi(i - 1, 0)]
		var p1 := points[i]
		var p2 := points[i + 1]
		var p3 := points[mini(i + 2, points.size() - 1)]
		for s in steps:
			var t := float(s) / steps
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t))
	out.append(points[points.size() - 1])
	return out
