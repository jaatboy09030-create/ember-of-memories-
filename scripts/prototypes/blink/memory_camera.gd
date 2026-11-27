class_name MemoryCamera
extends Camera3D
## MEMORY CAMERA (blink demo): you don't walk inside a memory, you stand in one spot and
## look. The view leans toward the reticle within tight limits and slides a few
## centimetres sideways too, which makes near and far things shift against each other
## like a diorama. Focus racks to whatever the reticle is on (near prop or far ghost),
## and everything at other depths goes soft.
##
## How to change it: the sway limits and focus values below.

## Where the reticle is (BlinkUI).
@export var cursor_source: BlinkUI
## Turn limits (degrees) at the screen edges.
@export var max_yaw_deg := 14.0
@export var max_pitch_deg := 9.0
## Sideways / up-down slide (metres) at the screen edges: the parallax.
@export var sway_slide := Vector2(0.14, 0.06)
## How quickly the view follows the reticle.
@export var follow_speed := 2.6
## How quickly focus racks to a new depth.
@export var focus_speed := 6.0
## Sharp zone either side of the focus point (metres).
@export var focus_band := 0.45
## Blur strength out of focus.
@export var blur_amount := 0.16
## Slow breathing drift (metres).
@export var breathing := 0.008

var _base := Transform3D.IDENTITY
var _offset := Vector2.ZERO
var _focus := 2.0
var _time := 0.0

@onready var attrs: CameraAttributesPractical = attributes


## Stand at `at` looking at `look`. Called behind closed lids, so it can snap.
func place(at: Vector3, look: Vector3) -> void:
	_base = Transform3D(Basis.looking_at(look - at, Vector3.UP), at)
	_focus = at.distance_to(look)
	global_transform = _base


func _process(delta: float) -> void:
	_time += delta
	var m := cursor_source.normalized_cursor() if cursor_source else Vector2.ZERO
	_offset = _offset.lerp(m, 1.0 - exp(-follow_speed * delta))
	var yaw := -_offset.x * deg_to_rad(max_yaw_deg)
	var pitch := -_offset.y * deg_to_rad(max_pitch_deg)
	var b := _base.basis * Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	var breath := Vector3(sin(_time * 0.7) * 0.5, sin(_time * 1.13), 0.0) * breathing
	var slide := Vector3(_offset.x * sway_slide.x, -_offset.y * sway_slide.y, 0.0)
	global_transform = Transform3D(b, _base.origin + _base.basis * (slide + breath))
	_update_focus(delta)


func _update_focus(delta: float) -> void:
	if not attrs:
		return
	var cur := cursor_source.cursor if cursor_source else get_viewport().get_visible_rect().size * 0.5
	var target := _focus
	var from := project_ray_origin(cur)
	var to := from + project_ray_normal(cur) * 30.0
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if not hit.is_empty():
		target = from.distance_to(hit.position)
	# ghosts have no collision: a face near the reticle wins
	for f in get_tree().get_nodes_in_group("memory_face"):
		var face := f as Node3D
		if not face.is_visible_in_tree() or is_position_behind(face.global_position):
			continue
		if unproject_position(face.global_position).distance_to(cur) < 150.0:
			target = minf(target, global_position.distance_to(face.global_position))
	if cursor_source and cursor_source.hovering:
		target = global_position.distance_to(cursor_source.hotspot_position)
	target = maxf(target, 0.35)
	_focus = lerpf(_focus, target, 1.0 - exp(-focus_speed * delta))
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_near_enabled = true
	attrs.dof_blur_far_distance = _focus + focus_band
	attrs.dof_blur_far_transition = maxf(0.8, _focus * 0.45)
	attrs.dof_blur_near_distance = maxf(0.05, _focus - focus_band)
	attrs.dof_blur_near_transition = maxf(0.3, _focus * 0.35)
	attrs.dof_blur_amount = blur_amount
