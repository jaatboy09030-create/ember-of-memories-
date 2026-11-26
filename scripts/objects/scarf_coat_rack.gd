class_name ScarfCoatRack
extends Interactable
## SCARF COAT RACK (knitting mini-game, memory 1).
## The red scarf hangs unravelled on the rack. While the player looks at it, they knit by
## alternating the two needle actions (needle_left / needle_right: mouse buttons, Q/E,
## or the gamepad shoulder buttons). Each stitch knits the scarf back a little, top-down.
##
## How to change it:
##   stitches_needed -> how many alternating presses finish the scarf
##   rows_at_start / total_rows -> how much of the scarf is visible before knitting
##   scarf_mesh_path -> the scarf MeshInstance3D inside the imported coat rack model

signal stitch_knitted
signal knitted

@export var stitches_needed := 22
@export var rows_at_start := 8
@export var total_rows := 30
## Path to the scarf mesh inside the coat rack model (the part that gets knitted back).
@export var scarf_mesh_path: NodePath
## Seconds without a stitch before the knitting sound stops.
@export var knit_sound_timeout := 0.45

const SCARF_SHADER := preload("res://shaders/scarf_reveal.gdshader")

var progress := 0.0
var stitches := 0
var _last_needle := ""
var _idle_time := 0.0
var _knit_sound: AudioStreamPlayer3D
var _scarf_mat: ShaderMaterial
var _scarf_top := 0.0
var _scarf_bottom := 0.0


func _ready() -> void:
	super._ready()
	_setup_scarf_material()
	_update_scarf_visual()


func get_progress() -> float:
	return progress if progress > 0.0 else -1.0


func _physics_process(delta: float) -> void:
	_idle_time += delta
	if _knit_sound and _idle_time > knit_sound_timeout:
		_stop_sound()
	if not (enabled and is_hovered):
		return
	var needle := ""
	if Input.is_action_just_pressed("needle_left") and _last_needle != "left":
		needle = "left"
	elif Input.is_action_just_pressed("needle_right") and _last_needle != "right":
		needle = "right"
	if needle != "":
		_knit_stitch(needle)


func _knit_stitch(needle: String) -> void:
	_last_needle = needle
	_idle_time = 0.0
	stitches = mini(stitches + 1, stitches_needed)
	progress = float(stitches) / stitches_needed
	if not _knit_sound:
		_knit_sound = Sound.play_at("knit_loop", global_position + Vector3(0, 1.4, 0), -6.0, true)
	_update_scarf_visual()
	stitch_knitted.emit()
	if stitches >= stitches_needed:
		_stop_sound()
		enabled = false
		knitted.emit()


func _stop_sound() -> void:
	if _knit_sound:
		_knit_sound.queue_free()
		_knit_sound = null


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


func _update_scarf_visual() -> void:
	if not _scarf_mat:
		return
	var rows := (rows_at_start + progress * (total_rows - rows_at_start)) / float(total_rows)
	var finished_nudge := 0.01 if progress >= 1.0 else 0.0
	_scarf_mat.set_shader_parameter("cut_y", _scarf_top - rows * (_scarf_top - _scarf_bottom) - finished_nudge)
