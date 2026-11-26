extends Memory
## MEMORY 5: THE PHOTO (parent's room) - the reveal.
## A photo lies face down on the dresser. Turning it over starts the one cutscene where
## the camera leaves the body: we lean in, then slowly circle round to see our own face for
## the first time. Silence. Then the letter.
##
## How to change it: letter_line / letter_voice; the shot timings are the numbers in
## _play_reveal() (each tween line is one camera move, in seconds).

@export var letter_line := "\"I kept the fire going, in case you came home.\""
@export var letter_voice := "v_letter"

@onready var photo: PhotoFrame = $PhotoFrame

var _head := Vector3.ZERO


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
	# 2. For the first time, the camera leaves the body: slow pull back over the shoulder
	tw.tween_callback(func():
		player.reveal_face()
		Sound.play("heartbeat", -6.0))
	var back_pos := _head - player.facing() * 1.7 + Vector3(0.35, 0.35, 0)
	tw.tween_property(cam, "global_position", back_pos, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "look_target", _head + Vector3(0, -0.1, 0), 3.5)
	tw.parallel().tween_property(cam, "fov", 50.0, 3.5)
	tw.parallel().tween_callback(func(): cam.focus(1.7)).set_delay(1.5)
	# 3. ...and circles round to the face. Long lens, shallow focus.
	tw.tween_method(_orbit, 0.0, 1.0, 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "fov", 34.0, 6.5)
	tw.parallel().tween_callback(func(): cam.focus(0.85)).set_delay(4.0)
	# 4. Silence. Let it land.
	tw.tween_interval(3.5)
	# 5. The letter
	tw.tween_callback(func(): game.hud.say(letter_line, 7.5, letter_voice))
	tw.tween_interval(8.5)
	tw.tween_callback(func():
		game.set_cinematic(false)
		cam.cinematic = false
		cam.look_target = Vector3.INF
		cam.fov = cam.default_fov
		player.can_move = true
		finish())


## t: 0 = behind the shoulder, 1 = in front of the face, just below it looking up.
func _orbit(t: float) -> void:
	var cam: PlayerCamera = game.player.cam
	var dir := (-game.player.facing()).rotated(Vector3.UP, t * PI * 0.95)
	cam.global_position = _head + dir * lerpf(1.6, 0.85, t) + Vector3(0, lerpf(0.5, -0.2, t), 0)
	cam.look_target = _head.lerp(_head + Vector3(0, -0.02, 0), t)


func debug_complete() -> void:
	photo.on_interact()
