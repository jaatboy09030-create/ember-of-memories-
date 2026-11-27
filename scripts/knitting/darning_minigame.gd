class_name DarningMinigame
extends Node3D
## DARNING MINIGAME (memory 1, the scarf): mending the hole in the scarf the way it's done
## for real, with a darning loom.
## open() glides the view from the player's eyes to DarningCamera, close on the scarf: a
## hole worn through the knitting (TornScarf), warp threads already strung across it from
## the knit below to the little wooden loom above (WarpThreads, DarningLoom).
##
## Each row:
##   1. Press "interact" (LMB / gamepad A) on the loom: its hooks flip and every other warp
##      thread lifts, opening a gap (the "shed").
##   2. Hold "interact" to grab the needle and drag it across the hole through the gap, along
##      the glowing guide line. Leave the line and the thread slips out: start that row again.
##   3. Once the needle's eye is through, the row is pulled tight and packs down.
## The next row flips the hooks the other way and goes back across: over-under, back and
## forth, until the woven patch fills the hole. Then the camera glides back.
## Mouse moves the cursor directly; the left stick on a gamepad.
##
## How to change it: rows_to_weave and the exports below; hole size is on TornScarf; thread
## spacing is the loom's Hooks; the needle feel is on KnittingNeedle.

signal stitch_completed(done: int, total: int)
signal prompt_changed(text: String)
signal finished

@export var rows_to_weave := 6
@export var camera_move_time := 1.2
## Gamepad: how fast the stick moves the cursor (metres per second).
@export var gamepad_needle_speed := 0.16
## Follow the mouse pointer (off = gamepad / scripted input only).
@export var mouse_enabled := true
## The needle tip can't leave this rectangle (local X/Y, metres).
@export var work_area := Rect2(-0.13, -0.06, 0.26, 0.17)
## How far above/below the guide line the needle may stray while passing through (m).
@export var row_tolerance := 0.012
## How far in front of the warp threads the needle floats when not passing through (m).
@export var front_depth := 0.014
@export_multiline var flick_prompt := "Press on the loom to flick the hooks"
@export_multiline var pass_prompt := "Hold LMB and draw the needle across, through the gap"

@onready var camera: Camera3D = $DarningCamera
@onready var scarf: TornScarf = $TornScarf
@onready var loom: DarningLoom = $DarningLoom
@onready var warps: WarpThreads = $WarpThreads
@onready var patch: WovenPatch = $WovenPatch
@onready var needle: KnittingNeedle = $KnittingNeedle
@onready var yarn: YarnThread = $YarnThread
@onready var row_guide: MeshInstance3D = $RowGuide
@onready var needle_rest: Marker3D = $NeedleRestPoint

enum Stage { CLOSED, ENTERING, NEED_FLICK, WEAVING, LEAVING }

var stage := Stage.CLOSED
var rows_done := 0
var _cursor := Vector2.ZERO
var _use_mouse := true
var _return_camera: Camera3D
var _camera_rest: Transform3D
var _thread_from := Vector3.ZERO   # where the weft last came out (end of the previous row)
var _entered := false              # the needle has entered this row's gap
var _xs := PackedFloat32Array()    # warp thread x positions


func _ready() -> void:
	visible = false
	_camera_rest = camera.transform
	for x in loom.hook_xs():
		_xs.append(loom.position.x + x)
	warps.setup(_xs, _hole().position.y - 0.012, loom.position.y - 0.012)
	_reset()


func is_open() -> bool:
	return stage != Stage.CLOSED


func get_progress() -> float:
	return float(rows_done) / rows_to_weave


func open(from_camera: Camera3D) -> void:
	_return_camera = from_camera
	visible = true
	stage = Stage.ENTERING
	_reset()
	yarn.reset(_yarn_waypoints())
	camera.global_transform = from_camera.global_transform
	camera.make_current()
	var tw := create_tween()
	tw.tween_property(camera, "transform", _camera_rest, camera_move_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Input.warp_mouse(camera.unproject_position(to_global(needle.tip)))
		_set_stage(Stage.NEED_FLICK))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_enabled:
		_use_mouse = true


func _process(delta: float) -> void:
	if stage == Stage.CLOSED:
		return
	if stage == Stage.NEED_FLICK or stage == Stage.WEAVING:
		_steer(delta)
	if stage == Stage.NEED_FLICK and Input.is_action_just_pressed("interact") and _cursor_on_loom():
		_flick()
	needle.move_tip(needle.step_toward(delta), delta)
	if stage == Stage.WEAVING:
		_check_pass()
	yarn.set_waypoints(_yarn_waypoints())


# ---------------------------------------------------------------- the hole and the rows

func _hole() -> Rect2:
	var h := scarf.hole
	return Rect2(h.position + Vector2(scarf.position.x, scarf.position.y), h.size)


func _row_y(i: int) -> float:
	var h := _hole()
	return h.position.y + (i + 0.5) * h.size.y / rows_to_weave


## +1: this row goes left to right; -1: right to left (alternates every row).
func _dir() -> float:
	return 1.0 if rows_done % 2 == 0 else -1.0


func _start_x() -> float:
	var h := _hole()
	return h.position.x - 0.004 if _dir() > 0 else h.end.x + 0.004


func _end_x() -> float:
	var h := _hole()
	return h.end.x + 0.004 if _dir() > 0 else h.position.x - 0.004


func _cursor_on_loom() -> bool:
	return absf(_cursor.x - loom.position.x) < 0.065 and absf(_cursor.y - loom.position.y) < 0.022


# ---------------------------------------------------------------- input

func _steer(delta: float) -> void:
	var stick := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	if stick.length() > 0.1:
		_use_mouse = false
		_cursor += stick * gamepad_needle_speed * delta
	elif _use_mouse and mouse_enabled:
		var p: Variant = _mouse_on_plane()
		if p != null:
			_cursor = p
	_cursor = _cursor.clamp(work_area.position, work_area.end)
	if stage == Stage.WEAVING and Input.is_action_pressed("interact"):
		var in_gap := _in_row_band(_cursor) and _between_edges(_cursor.x)
		needle.set_target(Vector3(_cursor.x, _cursor.y, 0.0 if in_gap else front_depth))
	else:
		needle.set_target(Vector3(needle.tip.x, needle.tip.y, front_depth))  # let go: it stays


## Where the mouse points on the plane of the warp threads (local X/Y), or null.
func _mouse_on_plane() -> Variant:
	var mp := get_viewport().get_mouse_position()
	var from := to_local(camera.project_ray_origin(mp))
	var dir := to_local(camera.project_ray_origin(mp) + camera.project_ray_normal(mp)) - from
	if absf(dir.z) < 0.0001:
		return null
	var hit := from + dir * (-from.z / dir.z)
	return Vector2(hit.x, hit.y)


func _in_row_band(p: Vector2) -> bool:
	return absf(p.y - _row_y(rows_done)) < row_tolerance


func _between_edges(x: float) -> bool:
	var h := _hole()
	return x > h.position.x - 0.012 and x < h.end.x + 0.012


# ---------------------------------------------------------------- weaving

func _flick() -> void:
	loom.flick()
	warps.open_shed(loom.parity)
	_entered = false
	_show_guide(true)
	_set_stage(Stage.WEAVING)


## The needle must go in at the row's start side, stay on the line, and come out the far
## side with its eye through: then the row is pulled tight.
func _check_pass() -> void:
	var tip := Vector2(needle.tip.x, needle.tip.y)
	var dir := _dir()
	var along := (tip.x - _start_x()) * dir     # how far across the hole the tip is
	if not _entered:
		if _in_row_band(tip) and absf(along) < 0.015:
			_entered = true                      # into the gap at the right side
		return
	if not _in_row_band(tip) and along < (_end_x() - _start_x()) * dir:
		_entered = false                         # slipped out of the gap: start again
		Sound.play("paper_pickup", -16.0, 0.3)
		return
	var eye_along := (needle.eye_position().x - _start_x()) * dir
	if eye_along > (_end_x() - _start_x()) * dir:
		_finish_row()


func _finish_row() -> void:
	var y := _row_y(rows_done)
	var h := _hole()
	patch.add_row(y, _xs, loom.parity, h.position.x - 0.006, h.end.x + 0.006)
	warps.set_woven_top(y + h.size.y / rows_to_weave * 0.5)
	warps.close_shed()
	loom.settle()
	Sound.play("knit_loop", -8.0, 0.1)
	_nudge_camera()
	_thread_from = Vector3(_end_x(), y, 0.0)
	_entered = false
	_show_guide(false)
	rows_done += 1
	stitch_completed.emit(rows_done, rows_to_weave)
	if rows_done >= rows_to_weave:
		_close()
	else:
		_set_stage(Stage.NEED_FLICK)


## Weft thread: from where it last came out, into this row's gap (once entered), to the eye.
func _yarn_waypoints() -> Array[Vector3]:
	var pts: Array[Vector3] = [_thread_from]
	if stage == Stage.WEAVING and _entered:
		pts.append(Vector3(_start_x(), _row_y(rows_done), 0.0))
	pts.append(needle.eye_position())
	return pts


func _show_guide(on: bool) -> void:
	row_guide.visible = on
	if on:
		var h := _hole()
		row_guide.position = Vector3(h.get_center().x, _row_y(rows_done), -0.001)
		(row_guide.mesh as QuadMesh).size = Vector2(h.size.x + 0.03, 0.003)


func _set_stage(s: Stage) -> void:
	stage = s
	if s == Stage.NEED_FLICK:
		prompt_changed.emit(flick_prompt)
	elif s == Stage.WEAVING:
		prompt_changed.emit(pass_prompt)
	else:
		prompt_changed.emit("")


# ---------------------------------------------------------------- camera / reset

func _nudge_camera() -> void:
	var tw := create_tween()
	tw.tween_property(camera, "position:y", _camera_rest.origin.y - 0.003, 0.08)
	tw.tween_property(camera, "position:y", _camera_rest.origin.y, 0.35).set_trans(Tween.TRANS_SINE)


func _close() -> void:
	_set_stage(Stage.LEAVING)
	needle.set_target(needle_rest.position)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(camera, "global_transform", _return_camera.global_transform, camera_move_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		_return_camera.make_current()
		stage = Stage.CLOSED
		visible = false
		finished.emit())


func _reset() -> void:
	_cursor = Vector2(needle_rest.position.x, needle_rest.position.y)
	needle.place_at(needle_rest.position)
	var h := _hole()
	_thread_from = Vector3(h.position.x - 0.006, h.position.y - 0.004, 0.003)
	_entered = false
	row_guide.visible = false


## Dev tests: weave every remaining row at once.
func debug_weave_all() -> void:
	while rows_done < rows_to_weave:
		loom.flick()
		_finish_row()
