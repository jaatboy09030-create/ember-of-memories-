class_name MemoryVoid
extends MeshInstance3D
## MEMORY VOID (blink demo): a full-screen quad on the camera that paints everything
## outside the active memory islands pure black, with a ragged ink edge
## (shaders/blink_void.gdshader). It doesn't move or know about the story: the demo
## hands it the islands to show every frame.
##
## How to change it: the edge look (ink teeth, droplets, boil) is on the material's
## shader parameters in the Inspector.

const MAX_ISLANDS := 8

## Ghosts draw after the void (whose material is at render_priority 100).
const GHOST_PRIORITY := 105

@onready var mat: ShaderMaterial = material_override

var _centres: Array = []
var _shapes: Array = []
var _count := 0
var _fade := 1.0


func show_islands(list: Array[MemoryIsland]) -> void:
	var centres: Array = []
	var shapes: Array = []
	for island in list:
		if centres.size() >= MAX_ISLANDS:
			break
		centres.append(island.packed_centre())
		shapes.append(island.packed_shape())
	var count := centres.size()
	while centres.size() < MAX_ISLANDS:
		centres.append(Vector4.ZERO)
		shapes.append(Vector4.ONE)
	mat.set_shader_parameter("islands", centres)
	mat.set_shader_parameter("island_shape", shapes)
	mat.set_shader_parameter("island_count", count)
	_centres = centres
	_shapes = shapes
	_count = count
	# ghosts are see-through: the void can't see them, so they draw over it, clipped to the islands
	var on := visible and _fade > 0.5
	var ghost_count := (count if count > 0 else 1) if on else 0  # 1 with an empty slot = hide all
	for fig in get_tree().get_nodes_in_group("memory_figure"):
		fig.clip_to_islands(centres, shapes, ghost_count, GHOST_PRIORITY)


## Is this world point inside a shown island (with `slack` metres to spare)?
func point_visible(p: Vector3, slack := 0.2) -> bool:
	if not visible or _fade <= 0.5:
		return true
	for i in _count:
		var c: Vector4 = _centres[i]
		if c.w <= 0.0001:
			continue
		var s: Vector4 = _shapes[i]
		var d := ((p - Vector3(c.x, c.y, c.z)) * Vector3(s.x, s.y, s.z).max(Vector3.ONE * 0.05)).length() - c.w
		if d < slack:
			return true
	return false


## 1 = void on, 0 = whole scene visible.
func set_fade(value: float) -> void:
	_fade = value
	mat.set_shader_parameter("void_fade", value)
