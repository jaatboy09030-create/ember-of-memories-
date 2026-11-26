class_name PlayerBody
extends CharacterBody3D
## PLAYER BODY: the grown child, played in first person. Handles walking and looking.
## Input comes only from Input Map actions (move_*, look_*, sprint), so keyboard/mouse and
## gamepad both work and this script never checks for a device.
## The body model exists (it casts shadows) but the first-person camera can't see it
## until the ending (see PlayerCamera.reveal_face()).
##
## Children and their jobs:
##   BodyPivot        -> turns with the view (yaw); holds the character model and scarf
##   PlayerCamera     -> first-person camera, head bob, shake, cutscene mode (player_camera.gd)
##   PlayerAnimator   -> idle / walk animation (player_animator.gd)
##   Footsteps        -> footstep sounds (player_footsteps.gd)
##
## How to change it: speeds, mouse/gamepad sensitivity and smoothing are @export values below.

## Emitted on every footstep. on_snow = the player is outside.
signal stepped(on_snow: bool)

@export var walk_speed := 1.75
@export var jog_speed := 2.9
## Height of the eyes above the feet, in metres.
@export var eye_height := 1.62
@export var mouse_sensitivity := 0.0022
## Gamepad right-stick turn speed, radians per second.
@export var gamepad_look_speed := 2.4
## Higher = the view follows the mouse more snappily (lower feels heavier).
@export var look_smoothing := 16.0
@export var acceleration := 7.0
## Anything further toward +Z than this counts as outside in the snow.
@export var outside_z := 0.3

const BODY_RENDER_LAYER := 2  # the camera hides this render layer until the ending

@onready var pivot: Node3D = $BodyPivot
@onready var cam: PlayerCamera = $PlayerCamera
@onready var interaction_raycast: RayCast3D = $PlayerCamera/InteractionRaycast

## false during cutscenes and mini-games: no walking, no looking, no interacting.
var can_move := true:
	set(v):
		can_move = v
		if is_node_ready():
			interaction_raycast.enabled = v
## Eased from 0 to 1 when control is handed back after a cutscene.
var look_scale := 1.0
var target_yaw := PI
var target_pitch := 0.0
var pitch := 0.0
## Dev tests only: scripted walking input (x = right, y = forward).
var auto_input := Vector2.ZERO
## Read by the camera for head bob.
var step_phase := 0.0
var is_jogging := false
var strafe := 0.0
var just_stopped := false

var _last_step := 0.0


func _ready() -> void:
	target_yaw = pivot.rotation.y
	_hide_body_from_camera(pivot)
	if not Engine.is_editor_hint():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _hide_body_from_camera(n: Node) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = 1 << (BODY_RENDER_LAYER - 1)
	for c in n.get_children():
		_hide_body_from_camera(c)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and can_move and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and can_move and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_turn(event.relative * mouse_sensitivity)


func _turn(amount: Vector2) -> void:
	target_yaw -= amount.x * look_scale
	target_pitch = clampf(target_pitch - amount.y * look_scale, -1.25, 1.25)


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	is_jogging = false
	if can_move:
		input = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
		is_jogging = Input.is_action_pressed("sprint") and input.y > 0.0
		var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
		if stick != Vector2.ZERO:
			_turn(stick * gamepad_look_speed * delta)
		# weighty head: the view eases toward the target
		var k := clampf(look_smoothing * delta, 0.0, 1.0)
		pivot.rotation.y = lerp_angle(pivot.rotation.y, target_yaw, k)
		pitch = lerpf(pitch, target_pitch, k)
	if auto_input != Vector2.ZERO:
		input = auto_input
	if input.length() > 1.0:
		input = input.normalized()
	_move(input, delta)
	_track_steps(delta)
	strafe = input.x


func _move(input: Vector2, delta: float) -> void:
	var fwd := facing()
	fwd.y = 0.0
	var right := fwd.cross(Vector3.UP).normalized()
	var target_v := (fwd * input.y + right * input.x) * (jog_speed if is_jogging else walk_speed)
	var k := clampf(acceleration * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, target_v.x, k)
	velocity.z = lerpf(velocity.z, target_v.z, k)
	velocity.y = 0.0 if is_on_floor() else velocity.y - 9.8 * delta
	move_and_slide()


## One footstep every half walk cycle.
func _track_steps(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	just_stopped = false
	if speed > 0.25:
		step_phase += delta * speed * 3.4
		var step := floorf(step_phase / PI)
		if step != _last_step:
			_last_step = step
			stepped.emit(is_outside())
	elif step_phase != 0.0:
		step_phase = 0.0
		just_stopped = true


func is_moving() -> bool:
	return Vector2(velocity.x, velocity.z).length() > 0.25


func is_outside() -> bool:
	return global_position.z > outside_z


# ---------------------------------------------------------------- helpers used by the story

func head_position() -> Vector3:
	return global_position + Vector3(0, eye_height, 0)


## Where the face actually is (follows the animated head bone).
func face_position() -> Vector3:
	var skel := ModelUtils.find_skeleton(pivot)
	if skel:
		var i := skel.find_bone("mixamorig_Head")
		if i >= 0:
			return skel.global_transform * skel.get_bone_global_pose(i).origin + Vector3(0, 0.07, 0)
	return head_position()


## Direction the body faces (flat, unit length).
func facing() -> Vector3:
	return pivot.global_transform.basis.z.normalized()


func face_towards(point: Vector3) -> void:
	var d := point - global_position
	pivot.rotation.y = atan2(d.x, d.z)
	target_yaw = pivot.rotation.y


## Turn body and view to look straight at `point` (yaw and pitch), instantly.
func look_at_point(point: Vector3) -> void:
	face_towards(point)
	var d := point - head_position()
	target_pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), -1.25, 1.25)
	pitch = target_pitch


func glance(point: Vector3, amount := 0.35) -> void:
	cam.glance(point, amount)


func add_shake(amount: float, time_s := 0.5) -> void:
	cam.add_shake(amount, time_s)


func reveal_face() -> void:
	cam.reveal_face()
