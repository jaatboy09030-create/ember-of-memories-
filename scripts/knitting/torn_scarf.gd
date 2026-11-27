class_name TornScarf
extends Node3D
## TORN SCARF: a close-up piece of the red knitted scarf with a hole worn through it.
## The knitting is real yarn (rows of "V" stitches built with YarnMesh); every stitch whose
## centre falls inside `hole` is missing, so the hole shows through. A soft backing sits
## behind the knitting everywhere except the hole.
##
## How to change it: size = the piece of scarf shown; hole = the torn area (x, y, width,
## height in metres, centred on this node); stitch_columns / stitch_rows = knit density.

@export var size := Vector2(0.2, 0.16)
@export var hole := Rect2(-0.05, -0.05, 0.1, 0.1)
@export var stitch_columns := 10
@export var stitch_rows := 8
@export var yarn_radius := 0.0042
@export var yarn_material: Material
@export var backing_material: Material

@onready var knitting: MeshInstance3D = $Knitting
@onready var backing: Node3D = $Backing


func _ready() -> void:
	knitting.mesh = YarnMesh.build_many(_stitches(), yarn_radius, 6, 3)
	knitting.material_override = yarn_material
	_build_backing()


## Every knit "V" except the ones inside the hole.
func _stitches() -> Array:
	var strands: Array = []
	var sw := size.x / stitch_columns
	var h := size.y / stitch_rows
	for r in stitch_rows:
		var cy := -size.y * 0.5 + (r + 0.5) * h
		for k in stitch_columns:
			var cx := -size.x * 0.5 + (k + 0.5) * sw
			if hole.grow(-0.002).has_point(Vector2(cx, cy)):
				continue
			strands.append(PackedVector3Array([
				Vector3(cx - sw * 0.48, cy + h * 0.55, 0.001),
				Vector3(cx - sw * 0.2, cy + h * 0.05, 0.006),
				Vector3(cx, cy - h * 0.5, 0.003),
				Vector3(cx + sw * 0.2, cy + h * 0.05, 0.006),
				Vector3(cx + sw * 0.48, cy + h * 0.55, 0.001),
			]))
	return strands


## Four strips of backing around the hole.
func _build_backing() -> void:
	var l := -size.x * 0.5
	var r := size.x * 0.5
	var b := -size.y * 0.5
	var t := size.y * 0.5
	var pieces := {
		"BackingTop": Rect2(l, hole.end.y, r - l, t - hole.end.y),
		"BackingBottom": Rect2(l, b, r - l, hole.position.y - b),
		"BackingLeft": Rect2(l, hole.position.y, hole.position.x - l, hole.size.y),
		"BackingRight": Rect2(hole.end.x, hole.position.y, r - hole.end.x, hole.size.y),
	}
	for n in pieces:
		var rect: Rect2 = pieces[n]
		var q := QuadMesh.new()
		q.size = rect.size
		var mi := MeshInstance3D.new()
		mi.name = n
		mi.mesh = q
		mi.material_override = backing_material
		mi.position = Vector3(rect.get_center().x, rect.get_center().y, -0.003)
		backing.add_child(mi)
