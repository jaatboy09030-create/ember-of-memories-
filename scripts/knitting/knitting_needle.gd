class_name KnittingNeedle
extends Node3D
## KNITTING NEEDLE: a straight steel needle the player holds by its TIP.
## The tip glides toward the cursor; the eye end is loose: it lags behind with a little
## inertia and swings back toward a relaxed angle, like holding a pin by its point.
## When the needle is threaded through a hole, the minigame pins its line to the hole
## (set_eye_position) so it can only pivot there.
## This node's origin is always the tip; its +Y axis points from the tip to the eye.
##
## How to change it:
##   eye_distance   -> tip-to-eye length (match the model)
##   smoothing      -> how long the tip takes to catch up with the cursor (lower = snappier)
##   swing_stiffness / swing_damping -> how loosely the needle swings (lower = looser)
##   rest_direction -> which way it lies from the tip at the start
##   trail_turn_speed -> how quickly it swings round to trail behind a new direction of motion

@export var eye_distance := 0.05
@export var smoothing := 0.06
@export var swing_stiffness := 14.0
@export var swing_damping := 5.0
@export var rest_direction := Vector3(-1.0, 0.05, 0.0)
@export var trail_turn_speed := 5.0
## Top speed of the eye end (metres per second): stops it whipping round, so the yarn
## tied to it moves smoothly.
@export var max_eye_speed := 0.22
## Material forced onto the imported needle model (it arrives untextured).
@export var needle_material: Material

var tip := Vector3.ZERO      # parent space
var target := Vector3.ZERO
var eye := Vector3.ZERO      # parent space
var _velocity := Vector3.ZERO
var _eye_velocity := Vector3.ZERO
var _trail_dir := Vector3.LEFT   # the eye relaxes to this side of the tip
var _tip_step := 0.0             # how far the tip moved this frame
var _size := 1.0                 # the node's scale from the editor (needle size)


func _ready() -> void:
	# honour the size set on this node in the editor (scale), and keep the eye in step
	_size = scale.x
	eye_distance *= _size
	if needle_material:
		for mi in find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = needle_material


## Put the tip at `p`, needle relaxed (lying toward `direction`, default rest_direction).
func place_at(p: Vector3, direction := Vector3.ZERO) -> void:
	tip = p
	target = p
	_trail_dir = (direction if direction != Vector3.ZERO else rest_direction).normalized()
	eye = p + _trail_dir * eye_distance
	_velocity = Vector3.ZERO
	_eye_velocity = Vector3.ZERO
	_apply()


func set_target(p: Vector3) -> void:
	target = p


## Smoothed next tip position toward the target (critically damped spring). Not applied yet.
func step_toward(delta: float) -> Vector3:
	var omega := 2.0 / maxf(smoothing, 0.001)
	var x := omega * delta
	var k := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change := tip - target
	var temp := (_velocity + omega * change) * delta
	_velocity = (_velocity - omega * temp) * k
	return target + (change + temp) * k


## Commit the tip; the loose eye end swings after it.
func move_tip(p: Vector3, delta: float) -> void:
	var moved := p - tip
	_tip_step = moved.length()
	if _velocity.dot(moved) <= 0.0 or moved.length() < 0.00001:
		_velocity = Vector3.ZERO  # blocked by the rail: don't keep pushing
	tip = p
	# the eye trails behind the direction the tip is being pulled
	if delta > 0.0 and moved.length() / delta > 0.03:
		var behind := -moved.normalized()
		var turned := _trail_dir.lerp(behind, clampf(trail_turn_speed * delta, 0.0, 1.0))
		if turned.length() < 0.05:  # exact reversal: swing round sideways instead
			turned = Vector3(-_trail_dir.y, _trail_dir.x, 0.0)
		_trail_dir = turned.normalized()
	var relaxed := tip + _trail_dir * eye_distance
	var acc := (relaxed - eye) * swing_stiffness - _eye_velocity * swing_damping
	_eye_velocity += acc * delta
	_set_eye_limited(eye + _eye_velocity * delta, delta)


## Move the eye toward `p`, keeping the needle's length, but never faster than max_eye_speed
## (beyond what the tip itself moved, which the eye always follows).
func _set_eye_limited(p: Vector3, delta: float) -> void:
	var want := tip + (p - tip).normalized() * eye_distance
	var step := want - eye
	var limit := max_eye_speed * maxf(delta, 0.0001) + _tip_step
	if step.length() > limit:
		want = eye + step.normalized() * limit
		want = tip + (want - tip).normalized() * eye_distance
	eye = want
	_apply()


## Override where the eye is (used to ease the needle into a ring). The eye keeps only the
## part of its own swing that still fits the new position, so the yarn is never yanked.
func set_eye_position(p: Vector3) -> void:
	var along := (p - tip).normalized()
	_eye_velocity = (_eye_velocity - along * _eye_velocity.dot(along)) * 0.6
	_set_eye_limited(p, get_process_delta_time())


func eye_position() -> Vector3:
	return eye


## Direction from the tip to the eye.
func direction() -> Vector3:
	return (eye - tip).normalized()


## Pose the needle directly (used while it slides through a hole); the swing stops.
func set_pose(new_tip: Vector3, new_eye: Vector3) -> void:
	tip = new_tip
	target = new_tip
	eye = new_tip + (new_eye - new_tip).normalized() * eye_distance
	_velocity = Vector3.ZERO
	_eye_velocity = Vector3.ZERO
	_apply()


func _apply() -> void:
	var y := (eye - tip).normalized()
	var x := Vector3.BACK.cross(y)
	if x.length() < 0.3:  # pointing straight through the cloth: use up as the reference
		x = Vector3.UP.cross(y)
	x = x.normalized()
	var z := x.cross(y)
	transform = Transform3D(Basis(x, y, z).scaled(Vector3.ONE * _size), tip)
