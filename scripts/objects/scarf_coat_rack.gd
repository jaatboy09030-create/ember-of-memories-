class_name ScarfCoatRack
extends Interactable
## SCARF COAT RACK (memory 1). The red scarf hangs unravelled on the rack.
## Using it ("interact") emits `interacted`; ScarfMemory then opens the KnittingMinigame.
## set_progress() knits the hanging scarf back from the top down as stitches are made.
##
## How to change it:
##   rows_at_start / total_rows -> how much of the scarf is visible before knitting
##   scarf_mesh_path -> the scarf MeshInstance3D inside the imported coat rack model

@export var rows_at_start := 8
@export var total_rows := 30
## Path to the scarf mesh inside the coat rack model (the part that gets knitted back).
@export var scarf_mesh_path: NodePath

const SCARF_SHADER := preload("res://shaders/scarf_reveal.gdshader")

var _scarf_mat: ShaderMaterial
var _scarf_top := 0.0
var _scarf_bottom := 0.0


func _ready() -> void:
	super._ready()
	_setup_scarf_material()
	set_progress(0.0)


func on_interact() -> void:
	super.on_interact()
	enabled = false


## 0 = unravelled (only the top rows), 1 = fully knitted.
func set_progress(progress: float) -> void:
	if not _scarf_mat:
		return
	var rows := (rows_at_start + progress * (total_rows - rows_at_start)) / float(total_rows)
	var finished_nudge := 0.01 if progress >= 1.0 else 0.0
	_scarf_mat.set_shader_parameter("cut_y", _scarf_top - rows * (_scarf_top - _scarf_bottom) - finished_nudge)


## Swap the scarf's material for the reveal shader, which hides everything below a height.
func _setup_scarf_material() -> void:
	var scarf := get_node_or_null(scarf_mesh_path) as MeshInstance3D
	if not scarf:
		push_warning("ScarfCoatRack: scarf_mesh_path not found")
		return
	var base := scarf.get_active_material(0) as BaseMaterial3D
	_scarf_mat = ShaderMaterial.new()
	_scarf_mat.shader = SCARF_SHADER
	if base and base.albedo_texture:
		_scarf_mat.set_shader_parameter("albedo_tex", base.albedo_texture)
		_scarf_mat.set_shader_parameter("has_tex", true)
	scarf.set_surface_override_material(0, _scarf_mat)
	var box: AABB = scarf.global_transform * scarf.get_aabb()
	_scarf_top = box.end.y
	_scarf_bottom = box.position.y
