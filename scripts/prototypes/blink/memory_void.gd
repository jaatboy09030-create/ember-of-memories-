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

@onready var mat: ShaderMaterial = material_override


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


## 1 = void on, 0 = whole scene visible.
func set_fade(value: float) -> void:
	mat.set_shader_parameter("void_fade", value)
