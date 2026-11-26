class_name PlayerCamera
extends Camera3D
## PLAYER CAMERA: first-person view with a heavy, slow feel (head bob, breathing sway,
## a small dip when you stop, camera shake, glancing toward things you touch).
## In cutscenes set `cinematic = true`: the camera stops following the head and the
## cutscene moves it freely; if `look_target` is set it keeps looking at that point.
##
## How to change it: the bob/sway amounts and FOV below; focus(dist) for depth of field.

@export var bob_walk := 0.032
@export var bob_jog := 0.045
@export var breathing_sway := 0.004
@export var default_fov := 70.0

## true = a cutscene drives the camera (position/rotation are left alone by this script).
var cinematic := false
## While cinematic, look at this point every frame (Vector3.INF = don't).
var look_target := Vector3.INF

var shake := 0.0
var _roll := 0.0
var _settle := 0.0
var _time := 0.0
var _glance_point := Vector3.INF
var _glance_amount := 0.0

@onready var player: PlayerBody = get_parent()


func _ready() -> void:
	fov = default_fov


func _physics_process(delta: float) -> void:
	_time += delta
	if player.just_stopped:
		_settle = 1.0  # tiny dip as you come to rest
	_settle = move_toward(_settle, 0.0, delta * 2.5)
	_roll = lerpf(_roll, -player.strafe * 0.025, clampf(6.0 * delta, 0.0, 1.0))
	if cinematic:
		if look_target != Vector3.INF:
			look_at(look_target)
		return
	var bob := -absf(sin(player.step_phase)) * (bob_jog if player.is_jogging else bob_walk)
	bob += sin(_time * 1.3) * breathing_sway - sin(_settle * PI) * 0.02
	_follow_head(bob)


func _follow_head(bob: float) -> void:
	var yaw := player.pivot.rotation.y + PI
	var p := player.pitch
	if _glance_amount > 0.001 and _glance_point != Vector3.INF:
		var d := _glance_point - player.head_position()
		yaw = lerp_angle(yaw, atan2(-d.x, -d.z), _glance_amount)
		p = lerpf(p, atan2(d.y, Vector2(d.x, d.z).length()), _glance_amount)
	var step_roll := sin(player.step_phase) * 0.006
	var idle_roll := sin(_time * 0.7) * 0.003
	var sh := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake
	var b := Basis(Vector3.UP, yaw + sh.x * 0.03) * Basis(Vector3.RIGHT, p + sh.y * 0.03) \
		* Basis(Vector3.BACK, _roll + step_roll + idle_roll)
	global_transform = Transform3D(b, player.head_position() + player.facing() * 0.12 + Vector3(sh.x * 0.02, bob + sh.y * 0.02, 0))


## Briefly turn the head toward something you interacted with.
func glance(point: Vector3, amount := 0.35) -> void:
	_glance_point = point
	var tw := create_tween()
	tw.tween_property(self, "_glance_amount", amount, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.6)
	tw.tween_property(self, "_glance_amount", 0.0, 0.8).set_trans(Tween.TRANS_SINE)


func add_shake(amount: float, time_s := 0.5) -> void:
	shake = maxf(shake, amount)
	create_tween().tween_property(self, "shake", 0.0, time_s).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


## The ending: let the camera see the body (and the face) for the first time.
func reveal_face() -> void:
	cull_mask = 0xFFFFF


## Depth of field: keep things `dist` metres away sharp. dist <= 0 turns it off.
func focus(dist: float) -> void:
	var attr := attributes as CameraAttributesPractical
	if not attr:
		return
	if dist <= 0.0:
		attr.dof_blur_far_enabled = false
		attr.dof_blur_near_enabled = false
		return
	attr.dof_blur_far_enabled = true
	attr.dof_blur_far_distance = dist + 0.6
	attr.dof_blur_far_transition = maxf(dist * 0.8, 0.8)
	attr.dof_blur_near_enabled = dist > 1.0
	attr.dof_blur_near_distance = maxf(dist * 0.4, 0.1)
	attr.dof_blur_near_transition = 0.3
