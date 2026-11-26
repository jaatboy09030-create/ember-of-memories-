class_name SnowyFoliage
extends Node3D
## SNOWY FOLIAGE: a tree, bush, rock or grass tuft from the Stylized Nature MegaKit.
## On start it swaps the model's materials for shaders/foliage_snow.gdshader: snow on top,
## leaves sway gently in the wind, the original textures are kept.
##
## How to change it:
##   snow_amount -> 0 no snow .. 1 heavy snow
##   tint        -> colour multiplier (e.g. straw-yellow for dry winter grass)
##   cast_shadows / draw_distance -> performance knobs

@export_range(0.0, 1.0) var snow_amount := 0.85
@export var tint := Color.WHITE
@export var cast_shadows := false
## Distance (m) beyond which it is not drawn.
@export var draw_distance := 80.0

const FOLIAGE_SHADER := preload("res://shaders/foliage_snow.gdshader")


func _ready() -> void:
	for node in find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if not mi.mesh:
			continue
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = draw_distance
		for i in mi.mesh.get_surface_count():
			_apply(mi, i)


func _apply(mi: MeshInstance3D, surface: int) -> void:
	var bm := mi.get_active_material(surface) as BaseMaterial3D
	if not bm:
		return
	var mat_name := String(bm.resource_name)
	var leafy := mat_name.contains("Lea") or mat_name.contains("Grass") or mat_name.contains("Flower")
	var sm := ShaderMaterial.new()
	sm.shader = FOLIAGE_SHADER
	sm.set_shader_parameter("tint", bm.albedo_color * tint)
	if bm.albedo_texture:
		sm.set_shader_parameter("albedo_tex", bm.albedo_texture)
		sm.set_shader_parameter("has_tex", true)
	if bm.normal_enabled and bm.normal_texture:
		sm.set_shader_parameter("normal_tex", bm.normal_texture)
		sm.set_shader_parameter("has_normal", true)
	sm.set_shader_parameter("alpha_cut", 0.5 if bm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED else 0.0)
	sm.set_shader_parameter("sway", 1.0 if leafy else 0.0)
	sm.set_shader_parameter("snow", snow_amount * (0.85 if leafy else 0.6))
	mi.set_surface_override_material(surface, sm)
