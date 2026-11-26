class_name PlayerCamera
extends Camera3D
## PLAYER CAMERA: first-person view with a heavy, slow "worn camera" feel:
## head bob with uneven steps, breathing, a slow hand-held drift, a sway that lags behind
## starting and stopping, a bank into turns, smooth noise shake, and glancing toward things
## you touch. Brightness slowly adapts between dark and bright places (auto exposure).
## In cutscenes set `cinematic = true`: the camera stops following the head and the
## cutscene moves it freely; if `look_target` is set it keeps looking at that point, and
## drift + shake still play on top so cutscenes feel hand-held too.
##
## How to change it: the @export values below (grouped in the Inspector). Overall strength
## and accessibility: settings/camera_comfort.tres. focus(dist) for depth of field.
## The lens bend itself is a screen effect (ScreenEffects), not this camera.

@export var bob_walk := 0.032
@export var bob_jog := 0.045
@export var breathing_sway := 0.004
## Vertical field of view in degrees. A bit wider than before (70) because the screen lens
## effect crops about 10 % of the picture to bend it.
@export var default_fov := 74.0
## Shared strength sliders (motion / shake / exposure). Empty = everything at full.
@export var comfort: CameraComfort

@export_group("Worn camera sway")
## Start/stop sway spring speed in Hz (lower = looser, floatier).
@export var sway_frequency := 2.2
## Spring damping: 1 = settles with no wobble, lower = a little overshoot.
@export_range(0.1, 1.5) var sway_damping := 0.55
## Tilt (radians) per m/s² of speeding up or slowing down.
@export var accel_tilt := 0.004
## Largest start/stop tilt, radians.
@export var max_accel_tilt := 0.035
## Roll (radians) per radian/second of turning: the camera banks into turns.
@export var turn_roll := 0.012
## Largest turn bank, radians.
@export var max_turn_roll := 0.03
## Slow hand-held drift, degrees.
@export var drift_degrees := 0.35
## Drift speed (higher = more nervous hands).
@export var drift_speed := 0.18
## One foot lands a little heavier than the other (0 = identical steps).
@export_range(0.0, 1.0) var step_asymmetry := 0.25

@export_group("Shake")
## Shake rotation in degrees at shake = 1.
@export var shake_degrees := 1.8
## Shake position jolt in metres at shake = 1.
@export var shake_offset := 0.02
## How fast the shake jitters (noise speed).
@export var shake_speed := 14.0

@export_group("Exposure")
## How strongly brightness adapts (0 = off). Keep low: the night must stay dark.
@export_range(0.0, 1.0) var exposure_adapt_strength := 0.2
## How fast it adapts (lower = slower, more like a cheap camera).
@export var exposure_adapt_speed := 0.8

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
var _noise := FastNoiseLite.new()
var _last_velocity := Vector3.ZERO
var _last_yaw := 0.0
var _has_last_yaw := false
var _sway := Vector2.ZERO  # x = pitch tilt, y = roll tilt (radians), spring position
var _sway_velocity := Vector2.ZERO
var _turn_bank := 0.0

@onready var player: PlayerBody = get_parent()


func _ready() -> void:
	fov = default_fov
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 1.0
	_noise.seed = 7
	apply_comfort()


## Re-read the comfort resource (call after an options menu changes it).
func apply_comfort() -> void:
	var attr := attributes as CameraAttributesPractical
	if not attr:
		return
	attr.auto_exposure_enabled = exposure_adapt_strength > 0.0 and (comfort == null or comfort.exposure_adapt)
	attr.auto_exposure_scale = exposure_adapt_strength
	attr.auto_exposure_speed = exposure_adapt_speed


func _physics_process(delta: float) -> void:
	_time += delta
	if player.just_stopped:
		_settle = 1.0  # tiny dip as you come to rest
	_settle = move_toward(_settle, 0.0, delta * 2.5)
	_roll = lerpf(_roll, -player.strafe * 0.025, clampf(6.0 * delta, 0.0, 1.0))
	_update_sway(delta)
	if cinematic:
		if look_target != Vector3.INF:
			look_at(look_target)
			var h := _handheld_rotation()
			rotate_object_local(Vector3.UP, h.y)
			rotate_object_local(Vector3.RIGHT, h.x)
			rotate_object_local(Vector3.BACK, h.z)
		return
	var heavy_foot := int(floorf(player.step_phase / PI)) % 2 == 1
	var bob := -absf(sin(player.step_phase)) * (bob_jog if player.is_jogging else bob_walk) \
		* (1.0 + (step_asymmetry if heavy_foot else 0.0))
	bob += sin(_time * 1.3) * breathing_sway - sin(_settle * PI) * 0.02
	_follow_head(bob * _motion())


## Start/stop sway (a spring that lags behind changes of speed) and the bank into turns.
func _update_sway(delta: float) -> void:
	if delta <= 0.0:
		return
	var v := player.velocity
	var acc := (v - _last_velocity) / delta
	_last_velocity = v
	var fwd := player.facing()
	var right := fwd.cross(Vector3.UP).normalized()
	var target := Vector2(
		clampf(-acc.dot(fwd) * accel_tilt, -max_accel_tilt, max_accel_tilt),
		clampf(-acc.dot(right) * accel_tilt, -max_accel_tilt, max_accel_tilt))
	var w := TAU * sway_frequency
	_sway_velocity += (-2.0 * sway_damping * w * _sway_velocity - w * w * (_sway - target)) * delta
	_sway += _sway_velocity * delta
	var yaw := player.pivot.rotation.y
	if not _has_last_yaw:
		_last_yaw = yaw
		_has_last_yaw = true
	var yaw_rate := angle_difference(_last_yaw, yaw) / delta
	_last_yaw = yaw
	var bank := clampf(yaw_rate * turn_roll, -max_turn_roll, max_turn_roll)
	_turn_bank = lerpf(_turn_bank, bank, 1.0 - exp(-8.0 * delta))


## Slow hand-held drift plus smooth shake, as (pitch, yaw, roll) in radians.
func _handheld_rotation() -> Vector3:
	var drift := deg_to_rad(drift_degrees) * _motion()
	var t := _time * drift_speed
	var r := Vector3(_noise.get_noise_2d(t, 0.0), _noise.get_noise_2d(t, 50.0), _noise.get_noise_2d(t, 100.0) * 0.6) * drift
	var s := shake * _shake_scale()
	if s > 0.0:
		var ts := _time * shake_speed
		r += Vector3(_noise.get_noise_2d(ts, 200.0), _noise.get_noise_2d(ts, 300.0), _noise.get_noise_2d(ts, 400.0) * 0.5) \
			* deg_to_rad(shake_degrees) * s
	return r


func _follow_head(bob: float) -> void:
	var yaw := player.pivot.rotation.y + PI
	var p := player.pitch
	if _glance_amount > 0.001 and _glance_point != Vector3.INF:
		var d := _glance_point - player.head_position()
		yaw = lerp_angle(yaw, atan2(-d.x, -d.z), _glance_amount)
		p = lerpf(p, atan2(d.y, Vector2(d.x, d.z).length()), _glance_amount)
	var m := _motion()
	var step_roll := sin(player.step_phase) * 0.006 * m
	var idle_roll := sin(_time * 0.7) * 0.003 * m
	var h := _handheld_rotation()
	var roll := (_roll + _sway.y + _turn_bank) * m + step_roll + idle_roll + h.z
	var b := Basis(Vector3.UP, yaw + h.y) * Basis(Vector3.RIGHT, p + h.x + _sway.x * m) * Basis(Vector3.BACK, roll)
	var s := shake * _shake_scale()
	var ts := _time * shake_speed
	var jolt := Vector2(_noise.get_noise_2d(ts, 500.0), _noise.get_noise_2d(ts, 600.0)) * shake_offset * s
	global_transform = Transform3D(b, player.head_position() + player.facing() * 0.12 + Vector3(jolt.x, bob + jolt.y, 0))


func _motion() -> float:
	return comfort.motion if comfort else 1.0


func _shake_scale() -> float:
	return comfort.shake if comfort else 1.0


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
