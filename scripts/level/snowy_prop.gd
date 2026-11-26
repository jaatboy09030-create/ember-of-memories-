class_name SnowyProp
extends Node3D
## SNOWY PROP: an outdoor model (lantern, crate, stump...) that is grey while the world is
## a frozen memory and carries snow on its upward-facing surfaces.
## On start it swaps the model's materials for shaders/memory_prop.gdshader, keeping each
## surface's own texture and colour.
##
## How to change it: snow_amount 0 = no snow, 1 = fully snow-covered tops.
## outdoor_only = hide it while the camera is inside the house (saves performance).

@export_range(0.0, 1.0) var snow_amount := 0.6
## Cast shadows? Off is cheaper for small or distant props.
@export var cast_shadows := true
## Distance (m) beyond which the prop is not drawn. 0 = always drawn.
@export var draw_distance := 0.0

const MEMORY_SHADER := preload("res://shaders/memory_prop.gdshader")


func _ready() -> void:
	for mi in find_children("*", "MeshInstance3D", true, false):
		_apply(mi as MeshInstance3D)


func _apply(mi: MeshInstance3D) -> void:
	if not mi.mesh:
		return
	if not cast_shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if draw_distance > 0.0:
		mi.visibility_range_end = draw_distance
	for i in mi.mesh.get_surface_count():
		var bm := mi.get_active_material(i) as BaseMaterial3D
		if not bm:
			continue
		var sm := ShaderMaterial.new()
		sm.shader = MEMORY_SHADER
		sm.set_shader_parameter("tint", bm.albedo_color)
		if bm.albedo_texture:
			sm.set_shader_parameter("albedo_tex", bm.albedo_texture)
			sm.set_shader_parameter("has_tex", true)
		sm.set_shader_parameter("roughness_value", bm.roughness)
		sm.set_shader_parameter("snow", snow_amount)
		mi.set_surface_override_material(i, sm)
