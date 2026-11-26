class_name YarnThread
extends MeshInstance3D
## YARN THREAD: the working strand, simulated as a soft rope so it really drags behind the
## needle: it has weight, sags, swings and lags a little when the needle moves fast.
##
## The minigame calls set_waypoints() every frame with the fixed points the yarn must pass
## through: where it leaves the cloth, each hole it has been pulled through, and the needle
## eye. Between each pair of waypoints the yarn is a short chain of particles (verlet rope).
##
## How to change it:
##   radius       -> yarn thickness
##   slack        -> spare length (1.0 = taut, 1.1 = loose and droopy)
##   gravity      -> how heavy the yarn feels
##   damping      -> how quickly swinging settles (lower = settles faster)
##   particles_per_span -> rope smoothness (more = smoother, slower)

@export var radius := 0.0032
@export var slack := 1.08
@export var gravity := 1.6
@export_range(0.8, 1.0) var damping := 0.94
@export var particles_per_span := 14
@export var solver_iterations := 14

var _waypoints: Array[Vector3] = []
var _spans: Array = []   # each span: {"p": PackedVector3Array, "old": PackedVector3Array}


## Fixed points (parent space) the yarn passes through, in order.
func set_waypoints(points: Array[Vector3]) -> void:
	if points.size() != _waypoints.size():
		_rebuild_spans(points)
	_waypoints = points.duplicate()


## Instantly lay the yarn straight between the waypoints (no swinging).
func reset(points: Array[Vector3]) -> void:
	_waypoints = []
	_spans.clear()
	set_waypoints(points)


func _physics_process(delta: float) -> void:
	if _waypoints.size() < 2:
		mesh = null
		return
	var g := Vector3(0, -gravity, 0) * delta * delta
	for s in _spans.size():
		_simulate_span(_spans[s], _waypoints[s], _waypoints[s + 1], g)
	_build_mesh()


func _simulate_span(span: Dictionary, a: Vector3, b: Vector3, g: Vector3) -> void:
	var p: PackedVector3Array = span["p"]
	var old: PackedVector3Array = span["old"]
	var n := p.size()
	# move the inner particles with inertia + gravity
	for i in range(1, n - 1):
		var v := (p[i] - old[i]) * damping
		old[i] = p[i]
		p[i] += v + g
	p[0] = a
	p[n - 1] = b
	var rest := a.distance_to(b) * slack / (n - 1)
	for _it in solver_iterations:
		for i in n - 1:
			var d := p[i + 1] - p[i]
			var l := d.length()
			if l < 0.000001:
				continue
			var corr := d * ((l - rest) / l) * 0.5
			if i > 0:
				p[i] += corr
			if i + 1 < n - 1:
				p[i + 1] -= corr
		p[0] = a
		p[n - 1] = b
	span["p"] = p
	span["old"] = old


## When a waypoint is added (threaded through a hole) or removed, re-split the rope while
## keeping the current shape as much as possible.
func _rebuild_spans(points: Array[Vector3]) -> void:
	var old_shape := PackedVector3Array()
	for s in _spans:
		old_shape.append_array(s["p"])
	_spans.clear()
	for i in points.size() - 1:
		var p := PackedVector3Array()
		for k in particles_per_span:
			var t := float(k) / (particles_per_span - 1)
			p.append(points[i].lerp(points[i + 1], t))
		_spans.append({"p": p, "old": p.duplicate()})
	# the first span keeps the old rope's shape (it hasn't moved), only the end is re-pinned
	if old_shape.size() >= particles_per_span and _spans.size() > 0:
		var first: Dictionary = _spans[0]
		var p: PackedVector3Array = first["p"]
		for k in range(1, particles_per_span - 1):
			var src := int(float(k) / (particles_per_span - 1) * (old_shape.size() - 1))
			p[k] = old_shape[src]
		first["p"] = p
		first["old"] = p.duplicate()


func _build_mesh() -> void:
	var path := PackedVector3Array()
	for s in _spans:
		var p: PackedVector3Array = s["p"]
		for i in p.size():
			if path.size() > 0 and i == 0:
				continue  # shared waypoint
			path.append(p[i] - position)
	mesh = YarnMesh.build(path, radius, 6, 1)
