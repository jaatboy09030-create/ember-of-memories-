extends Memory
## MEMORY 5: THE PHOTO (parent's room) - the reveal.
## A photo lies face down on the dresser. Using it starts the one cutscene where the camera
## leaves the body: the character picks the photo up in both hands and the camera swings
## round the side of the head to behind the shoulder (half the face and the photo in view).
## Then it slowly pushes in over the shoulder while the glass on the photo turns into a
## mirror: for the first time we see our own face, reflected in it.
## Silence, then the letter, then a fade back to first person (photo left face up).
##
## The camera never clips into walls or furniture: every position is checked with
## PlayerCamera.safe_position(), and it uses the shoulder with more room behind it.
## It never passes through the head either: on the way out it keeps head_clearance from it,
## and the body only becomes visible once the camera is clear of it.
##
## How to change it: letter_line / letter_voice; hold_distance / hold_drop = where the photo
## is held; shoulder_start / shoulder_end = the camera's over-the-shoulder offsets (x = back,
## y = up, z = sideways); the shot timings are the numbers in _play_reveal() (seconds).

@export var letter_line := "\"I kept the fire going, in case you came home.\""
@export var letter_voice := "v_letter"
## On the way out the camera swings at least this far (metres) from the head.
@export var head_clearance := 0.6
## How far in front of the face the photo is held, and how far below it (metres).
@export var hold_distance := 0.3
@export var hold_drop := 0.3
## Over-the-shoulder camera offset from the head at the start of the shot (back, up, side).
@export var shoulder_start := Vector3(0.55, 0.14, 0.42)
## ...and at the end of the slow push-in, close over the shoulder looking into the glass.
@export var shoulder_end := Vector3(0.06, 0.13, 0.36)
## Seconds of the slow push-in while the glass turns into a mirror.
@export var push_in_time := 9.0
## How much of a mirror the glass becomes (0..1).
@export_range(0.0, 1.0) var reflection_strength := 0.95

@onready var photo: PhotoFrame = $PhotoFrame

var _head := Vector3.ZERO
var _facing := Vector3.FORWARD
var _side := Vector3.RIGHT
var _hold := Transform3D.IDENTITY
var _held := false
var _time := 0.0
var _pull_from := Vector3.ZERO
var _face_shown := false


func _ready() -> void:
	photo.chosen.connect(_play_reveal)


func begin() -> void:
	photo.enabled = true


func _play_reveal() -> void:
	var player: PlayerBody = game.player
	var cam: PlayerCamera = player.cam
	player.can_move = false
	cam.cinematic = true
	player.get_node("PlayerCamera/ColdBreath").breathing = false
	player.face_towards(photo.global_position)
	await get_tree().process_frame  # let the body turn before measuring the head
	_head = player.head_position()
	_facing = player.facing()
	_hold = _hold_transform(player.face_position())
	_side = _pick_shoulder()
	cam.look_target = photo.global_position
	game.set_cinematic(true)
	game.screen_effects.pixelate_faces = false
	Sound.play_music("", 0.0, 2.0)  # the house goes quiet

	# 1. He picks the photo up in both hands; the camera leaves the body, swinging round the
	#    side of the head to behind the shoulder (never through the head).
	photo.pick_up(_hold)
	player.hands.hold(photo.grip_left, photo.grip_right, photo.pick_up_time)
	_pull_from = cam.global_position
	_face_shown = false
	var tw := create_tween()
	tw.tween_method(_pull_back, 0.0, 1.0, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "look_target", _shot_look(0.0), 2.6).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(cam, "fov", 50.0, 2.6)
	tw.parallel().tween_callback(func(): _held = true).set_delay(photo.pick_up_time)
	tw.parallel().tween_callback(func(): cam.focus(cam.global_position.distance_to(photo.glass.global_position))).set_delay(2.0)
	# 2. Over the shoulder: half his face, the photo in his hands. Let it sit.
	tw.tween_callback(func():
		player.reveal_face()  # in case the swing never got far enough
		Sound.play("memory_restore", -6.0)
		game.screen_effects.fade_saturation(0.55, 2.5))
	tw.tween_interval(2.0)
	# 3. Slow push-in while the glass slowly becomes a mirror.
	tw.tween_callback(func():
		photo.reflect_target = player.face_position()
		photo.set_reflection(reflection_strength, push_in_time * 0.8)
		Sound.play("heartbeat", -6.0))
	tw.tween_method(_push_in, 0.0, 1.0, push_in_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "fov", 34.0, push_in_time).set_trans(Tween.TRANS_SINE)
	# 4. Silence. Let it land.
	tw.tween_interval(2.5)
	# 5. The letter
	tw.tween_callback(func(): game.hud.say(letter_line, 5.5, letter_voice))
	tw.tween_interval(6.5)
	# 6. Fade back to first person; the photo stays on the dresser, face up.
	tw.tween_callback(func(): game.hud.fade_to(1.0, 1.0))
	tw.tween_interval(1.1)
	tw.tween_callback(func():
		_held = false
		photo.put_down()
		player.hands.release(0.0)
		cam.hide_face()
		cam.cinematic = false
		cam.look_target = Vector3.INF
		cam.fov = cam.default_fov
		game.set_cinematic(false, 0.0)
		game.screen_effects.pixelate_faces = true
		game.hud.fade_to(0.0, 1.2))
	tw.tween_interval(0.6)
	tw.tween_callback(func():
		player.can_move = true
		finish())


func _process(delta: float) -> void:
	if not _held:
		return
	_time += delta
	# the hands are never quite still
	var breath := Vector3(0, sin(_time * 1.3) * 0.004, 0) + _side * sin(_time * 0.7) * 0.002
	photo.hold_at(_hold.translated(breath))
	if photo.reflect_target != Vector3.INF:
		photo.reflect_target = game.player.face_position()


## The photo held in both hands below the face, picture side tilted up toward the eyes.
func _hold_transform(face: Vector3) -> Transform3D:
	var center := face + _facing * hold_distance + Vector3(0, -hold_drop, 0)
	var up := (face - center).normalized()  # the picture faces the eyes
	var near := -_facing  # local +Z = the edge nearest the holder
	near = (near - up * near.dot(up)).normalized()
	var right := up.cross(near)
	return Transform3D(Basis(right, up, near), center)


## The shoulder with more room behind it (right if equal); keeps the camera off walls.
func _pick_shoulder() -> Vector3:
	var cam: PlayerCamera = game.player.cam
	var right := _facing.cross(Vector3.UP).normalized()
	var best := right
	var best_room := -1.0
	for s in [right, -right]:
		var want := _shoulder_point(shoulder_start, s)
		var room := cam.safe_position(_head, want).distance_to(_head) / want.distance_to(_head)
		if room > best_room + 0.05:
			best = s
			best_room = room
	return best


func _shoulder_point(offset: Vector3, side: Vector3) -> Vector3:
	return _head - _facing * offset.x + Vector3.UP * offset.y + side * offset.z


## What the over-the-shoulder camera looks at: the photo, nudged toward the face at t = 0
## so the cheek is in the frame, and straight into the glass at t = 1.
func _shot_look(t: float) -> Vector3:
	var glass := _hold.origin + _hold.basis.y * 0.02
	return glass.lerp(_head, lerpf(0.3, 0.0, t))


## t: 0 = where the camera started (in the eyes) .. 1 = behind the shoulder. Swings round
## the side with an outward bulge so it never comes near the head; shows the body once the
## camera is clear of it.
func _pull_back(t: float) -> void:
	var player: PlayerBody = game.player
	var start := _pull_from - _head
	var end := _shoulder_point(shoulder_start, _side) - _head
	var a0 := atan2(start.x, start.z)
	var a1 := atan2(end.x, end.z)
	# turn the short way round toward the chosen shoulder
	var a := a0 + angle_difference(a0, a1) * t
	var r0 := Vector2(start.x, start.z).length()
	var r1 := Vector2(end.x, end.z).length()
	var r := lerpf(r0, r1, t) + sin(t * PI) * head_clearance
	var want := _head + Vector3(sin(a) * r, lerpf(start.y, end.y, t), cos(a) * r)
	player.cam.global_position = player.cam.safe_position(_head, want)
	if not _face_shown and t > 0.3 and player.cam.global_position.distance_to(_head) >= 0.4:
		_face_shown = true
		player.reveal_face()


## t: 0 = over the shoulder .. 1 = close over the shoulder looking into the glass.
func _push_in(t: float) -> void:
	var cam: PlayerCamera = game.player.cam
	var want := _shoulder_point(shoulder_start, _side).lerp(_shoulder_point(shoulder_end, _side), t)
	cam.global_position = cam.safe_position(_head, want)
	cam.look_target = _shot_look(t)
	cam.focus(cam.global_position.distance_to(photo.glass.global_position))


func debug_complete() -> void:
	photo.on_interact()
