extends Memory
## MEMORY 5: THE PHOTO (parent's room) - the reveal.
## A photo lies face down on the dresser. Turning it over starts the one cutscene where
## the camera leaves the body: we lean in, then the camera swings round the side to behind
## the shoulder and slowly circles round to see our own face for the first time. Silence.
## Then the letter. Afterwards the body is hidden from the camera again (hide_face), so normal
## first person never shows your own hair or shoulders.
## The camera never passes through the head: on the way out it keeps head_clearance from it,
## and the body only becomes visible once the camera is clear of it.
##
## How to change it: letter_line / letter_voice; head_clearance; the shot timings are the
## numbers in _play_reveal() (each tween line is one camera move, in seconds).

@export var letter_line := "\"I kept the fire going, in case you came home.\""
@export var letter_voice := "v_letter"
## On the way out the camera swings at least this far (metres) from the head.
@export var head_clearance := 0.6

@onready var photo: PhotoFrame = $PhotoFrame

var _head := Vector3.ZERO
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
	_head = player.face_position()
	var to_photo := photo.global_position - cam.global_position
	to_photo.y = 0.0
	to_photo = to_photo.normalized()
	cam.look_target = photo.global_position
	game.set_cinematic(true)
	Sound.play_music("", 0.0, 2.0)  # the house goes quiet
	var tw := create_tween()
	# 1. Insert shot: we lean in as our own hands turn the photo over
	tw.tween_property(cam, "global_position", photo.global_position - to_photo * 0.75 + Vector3(0, 0.35, 0), 2.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "fov", 42.0, 2.0)
	tw.parallel().tween_callback(photo.flip).set_delay(0.8)
	tw.tween_callback(func():
		cam.focus(0.75)
		game.screen_effects.fade_saturation(0.55, 2.5)
		Sound.play("memory_restore", -6.0))
	tw.tween_interval(3.0)
	# 2. For the first time, the camera leaves the body: it swings round the side to behind
	#    the shoulder (never through the head); the body appears once the camera is clear.
	tw.tween_callback(func():
		_pull_from = cam.global_position
		_face_shown = false
		Sound.play("heartbeat", -6.0))
	tw.tween_method(_pull_back, 0.0, 1.0, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "look_target", _head, 3.5)  # = where _orbit(0) looks: no aim jump
	tw.parallel().tween_property(cam, "fov", 50.0, 3.5)
	tw.parallel().tween_callback(func(): cam.focus(1.7)).set_delay(1.5)
	# 3. ...and circles round to the face. Long lens, shallow focus.
	tw.tween_callback(player.reveal_face)  # in case the pull-back never got far enough
	tw.tween_method(_orbit, 0.0, 1.0, 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "fov", 34.0, 6.5)
	tw.parallel().tween_callback(func(): cam.focus(0.85)).set_delay(4.0)
	# 4. Silence. Let it land.
	tw.tween_interval(3.5)
	# 5. The letter
	tw.tween_callback(func(): game.hud.say(letter_line, 5.5, letter_voice))
	tw.tween_interval(6.5)
	tw.tween_callback(func():
		game.set_cinematic(false)
		cam.hide_face()
		cam.cinematic = false
		cam.look_target = Vector3.INF
		cam.fov = cam.default_fov
		player.can_move = true
		finish())


## t: 0 = where the insert shot ended (in front of the face) .. 1 = behind the shoulder,
## exactly where _orbit() starts. Swings round the side with an outward bulge so it never
## comes near the head; shows the body once the camera is clear of it.
func _pull_back(t: float) -> void:
	var player: PlayerBody = game.player
	var start := _pull_from - _head
	var end := _orbit_offset(0.0)
	var a0 := atan2(start.x, start.z)
	var a := a0 + fposmod(atan2(end.x, end.z) - a0, TAU) * t
	var r0 := Vector2(start.x, start.z).length()
	var r1 := Vector2(end.x, end.z).length()
	var r := lerpf(r0, r1, t) + sin(t * PI) * head_clearance
	player.cam.global_position = _head + Vector3(sin(a) * r, lerpf(start.y, end.y, t), cos(a) * r)
	if not _face_shown and t > 0.3 and r >= head_clearance + 0.25:
		_face_shown = true
		player.reveal_face()


## Camera offset from the head for orbit position t (0 = behind the shoulder, 1 = in front
## of the face, just below it looking up).
func _orbit_offset(t: float) -> Vector3:
	var dir := (-game.player.facing()).rotated(Vector3.UP, t * PI * 0.95)
	return dir * lerpf(1.6, 0.85, t) + Vector3(0, lerpf(0.5, -0.2, t), 0)


func _orbit(t: float) -> void:
	var cam: PlayerCamera = game.player.cam
	cam.global_position = _head + _orbit_offset(t)
	cam.look_target = _head.lerp(_head + Vector3(0, -0.02, 0), t)


func debug_complete() -> void:
	photo.on_interact()
