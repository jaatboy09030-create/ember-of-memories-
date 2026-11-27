class_name HouseExterior
extends SnowyProp
## HOUSE EXTERIOR: the two-storey shell around the rooms (assets/house/house_exterior.glb,
## assembled in Blender from the Tripo parts: walls, roof, porch, windows, chimney, snow, icicles).
## Like any SnowyProp it is grey while the world is a frozen memory and carries snow on top.
## It also owns the opening's foreshadowing: one upstairs window that can glow warm with
## someone standing in it (LitWindowGlow + WindowSilhouette, both modelled in Blender).
##
## How to change it:
##   window_warmth 0..1   -> how lit the upstairs window is (the title sequence animates it)
##   someone_there 0..1   -> how visible the figure in that window is
##   window_color         -> the colour of the light in the window

@export_range(0.0, 1.0) var window_warmth := 0.0:
	set(v):
		window_warmth = v
		_update_window()
@export_range(0.0, 1.0) var someone_there := 0.0:
	set(v):
		someone_there = v
		_update_window()
@export var window_color := Color(1.0, 0.58, 0.26)
## Every other window, lit warm behind curtains (shaders/curtain_window.gdshader). The opening turns it up.
@export_range(0.0, 1.0) var all_windows_warmth := 0.0:
	set(v):
		all_windows_warmth = v
		if _panes_mat:
			_panes_mat.set_shader_parameter("warmth", v)
## Multiplies the siding colour of the walls and gables (darker = the charcoal house of the opening).
@export var wall_tint := Color(0.36, 0.38, 0.45)

const KEEP_OWN_LOOK := ["LitWindowGlow", "WindowSilhouette"]
const HOUSE_LAYER := 1 << 3

var _glow: MeshInstance3D
var _figure: MeshInstance3D
var _glow_mat: StandardMaterial3D
var _figure_mat: StandardMaterial3D
var _light: OmniLight3D
var _panes_mat: ShaderMaterial

const CURTAIN_SHADER := preload("res://shaders/curtain_window.gdshader")


func _ready() -> void:
	add_to_group("house_exterior")
	for mi in find_children("*", "MeshInstance3D", true, false):
		var n := String(mi.name)
		if n.begins_with("LitWindowGlow"):
			_glow = mi
		elif n.begins_with("WindowSilhouette"):
			_figure = mi
		elif n.begins_with("WindowGlass"):
			_panes_mat = ShaderMaterial.new()
			_panes_mat.shader = CURTAIN_SHADER
			_panes_mat.set_shader_parameter("warmth", all_windows_warmth)
			(mi as MeshInstance3D).material_override = _panes_mat
			(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			_apply(mi as MeshInstance3D)
			# render layer 4 = "house only", so the opening's warm gable light (cull mask 8) touches nothing else
			(mi as MeshInstance3D).layers |= HOUSE_LAYER
			if n.begins_with("Walls") or n.begins_with("Gable"):
				_tint_walls(mi as MeshInstance3D)
	if _glow:
		_glow_mat = StandardMaterial3D.new()
		_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_glow.material_override = _glow_mat
		_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# a little of that light spills onto the snow below
		_light = OmniLight3D.new()
		_light.name = "WindowSpill"
		_light.light_color = window_color
		_light.omni_range = 7.0
		_light.omni_attenuation = 1.6
		_light.shadow_enabled = false
		add_child(_light)
		# just outside the glass (the house front faces +Z)
		_light.global_position = _glow.global_transform * _glow.get_aabb().get_center() + Vector3(0, -1.2, 2.6)
	if _figure:
		_figure_mat = StandardMaterial3D.new()
		_figure_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_figure_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_figure_mat.albedo_color = Color(0.02, 0.015, 0.012, 0.0)
		_figure.material_override = _figure_mat
		_figure.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_update_window()


func _tint_walls(mi: MeshInstance3D) -> void:
	for i in mi.get_surface_override_material_count():
		var sm := mi.get_surface_override_material(i) as ShaderMaterial
		if sm:
			sm.set_shader_parameter("tint", (sm.get_shader_parameter("tint") as Color) * wall_tint)


func _update_window() -> void:
	if not is_node_ready() or _glow_mat == null:
		return
	var dark := Color(0.015, 0.02, 0.035)
	_glow_mat.albedo_color = dark.lerp(window_color * 0.9, window_warmth)
	_glow.visible = window_warmth > 0.01
	if _light:
		_light.light_energy = window_warmth * 0.9
	if _figure_mat:
		_figure_mat.albedo_color.a = someone_there * window_warmth
		_figure.visible = someone_there * window_warmth > 0.01
