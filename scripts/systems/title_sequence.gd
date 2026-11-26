class_name TitleSequence
extends Node3D
## TITLE SEQUENCE: the opening, one continuous shot with no cuts.
## The ember writes an unfinished line in the night sky, the words cool to ash, the name
## forms, and on any button press the ember falls to the garden gate while the camera
## follows it down into the player's eyes. Emits `finished` when the player has control.
##
## How to change it:
##   unfinished_line / game_name -> the text written in the sky
##   camera_start / camera_look  -> the opening camera shot
##   gate_point                  -> where the ember lands
## The ash, the warm window and the "press any button" prompt are child nodes in the scene.
## The sky letters are created from the text when the sequence starts (one Label3D per
## letter, so each can light up and crumble on its own).

signal finished

@export var unfinished_line := "I kept the fire going, in case you"
@export var game_name := "Unsent"
@export var camera_start := Vector3(1.5, 6.5, 22.0)
@export var camera_look := Vector3(0.0, 2.6, 0.0)
@export var gate_point := Vector3(0, 1.3, 10.0)
## Distance in front of the camera at which the words float.
@export var text_distance := 9.0
@export var line_color := Color(1.9, 0.62, 0.16)
@export var name_color := Color(0.86, 0.89, 0.97)

@onready var title_sky: Node3D = $TitleSky
@onready var ash: CPUParticles3D = $TitleSky/TitleAsh
@onready var window_glow: OmniLight3D = $WindowGlow
@onready var tap_prompt: Label = $TitleOverlay/TapPrompt

var game: GameDirector
var _line_letters: Array[Label3D] = []
var _name_letters: Array[Label3D] = []
var _waiting_for_press := false
var _running := false
var _time := 0.0
var _ember_rest := Vector3.ZERO


func play(game_director: GameDirector) -> void:
	game = game_director
	_running = true
	var player: PlayerBody = game.player
	var cam: PlayerCamera = player.cam
	player.can_move = false
	player.look_scale = 0.0
	cam.cinematic = true
	cam.global_position = camera_start
	cam.fov = 45.0
	cam.look_target = camera_look
	cam.focus(text_distance)
	game.hud.set_crosshair_visible(false)
	game.hud.letterbox(true, 0.0)
	Sound.play_music("theme_piano" if Sound.get_stream("theme_piano") else "theme_broken", -9.0, 3.0)
	_place_sky()
	_line_letters = _write_letters(unfinished_line, _hand_font(), 112, 0.0034, 0.55, line_color)
	_name_letters = _write_letters(game_name, _serif_font(500), 230, 0.0042, -0.45, name_color)
	var last_name_letter := _name_letters[_name_letters.size() - 1]
	_ember_rest = title_sky.to_global(last_name_letter.position + Vector3(0.38, 0.05, 0.05))
	_write_the_line()


## A plane of words floating in the snow between the camera and the house, facing the camera.
func _place_sky() -> void:
	var d := (camera_look - camera_start).normalized()
	var center := camera_start + d * text_distance + Vector3(0, 1.85, 0)
	title_sky.global_position = center
	title_sky.look_at(center + (center - camera_start), Vector3.UP)  # +Z (readable side) faces the camera


func _write_the_line() -> void:
	var ember: Ember = game.ember
	ember.wait_at(Vector3.INF)
	ember.global_position = title_sky.to_global(Vector3(0, 0.2, 0))
	ember.scale = Vector3.ONE * 0.6
	game.hud.screen_fade.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(game.hud.screen_fade, "color:a", 0.0, 3.0)
	tw.tween_interval(0.6)
	var first := _line_letters[0]
	tw.tween_property(ember, "global_position", title_sky.to_global(first.position + Vector3(-0.08, -0.05, 0.05)), 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for letter in _line_letters:
		tw.tween_property(ember, "global_position", title_sky.to_global(letter.position + Vector3(0.05, -0.04, 0.05)), 0.1)
		tw.parallel().tween_property(letter, "modulate:a", 1.0, 0.22)
	# the pen hesitates where the next word should be... and never writes it
	var last := _line_letters[_line_letters.size() - 1]
	tw.tween_property(ember, "global_position", title_sky.to_global(last.position + Vector3(0.22, -0.02, 0.05)), 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(1.8)
	tw.tween_callback(_cool_the_words)


func _cool_the_words() -> void:
	var cold := Color(0.5, 0.53, 0.6, 1.0)
	for i in _line_letters.size():
		var letter := _line_letters[i]
		var t := create_tween()
		t.tween_interval(0.06 * i)
		t.tween_property(letter, "modulate", cold, 1.1)
		t.tween_interval(0.5 + randf() * 0.4)
		t.tween_property(letter, "modulate:a", 0.0, 0.9)
		t.parallel().tween_property(letter, "position:y", letter.position.y + 0.12, 0.9)
	var seq := create_tween()
	seq.tween_interval(1.2)
	seq.tween_callback(func(): ash.emitting = true)
	# the window: warm for a heartbeat, then grey again
	seq.tween_property(window_glow, "light_energy", 3.0, 0.5)
	seq.tween_interval(0.5)
	seq.tween_property(window_glow, "light_energy", 0.0, 1.4)
	seq.tween_callback(func(): ash.emitting = false)
	# the name forms out of the drifting ash
	var order := range(_name_letters.size())
	order.shuffle()
	for j in order.size():
		var letter := _name_letters[order[j]]
		var target_y := letter.position.y
		letter.position.y -= 0.12
		var t := create_tween()
		t.tween_interval(1.6 + 0.09 * j)
		t.tween_property(letter, "modulate:a", 1.0, 1.1)
		t.parallel().tween_property(letter, "position:y", target_y, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	seq.tween_property(game.ember, "global_position", _ember_rest, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	seq.tween_interval(0.6)
	seq.tween_callback(func(): _waiting_for_press = true)
	seq.tween_property(tap_prompt, "modulate:a", 1.0, 1.0)


func _process(delta: float) -> void:
	if not _waiting_for_press:
		return
	_time += delta
	tap_prompt.modulate.a = 0.3 + 0.55 * (0.5 + 0.5 * sin(_time * 2.0))
	# every so often, the window remembers being warm
	var w := maxf(sin(_time * 0.37) * sin(_time * 0.91), 0.0)
	window_glow.light_energy = pow(w, 6.0) * 3.0


## Any button on any device continues.
func _input(event: InputEvent) -> void:
	if not _running:
		return
	if event.is_pressed() and not event.is_echo() and not event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()
		if _waiting_for_press:
			continue_to_game()


func continue_to_game() -> void:
	_waiting_for_press = false
	_running = false
	var player: PlayerBody = game.player
	var cam: PlayerCamera = player.cam
	var ember: Ember = game.ember
	Sound.play("ember_chime", -8.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	create_tween().tween_property(tap_prompt, "modulate:a", 0.0, 0.6)
	create_tween().tween_property(window_glow, "light_energy", 0.0, 0.6)
	# the name crumbles into the snow
	ash.position = Vector3(0, -0.35, 0)
	ash.gravity = Vector3(0.1, -0.15, 0)
	ash.restart()
	ash.emitting = true
	for letter in _name_letters:
		var t := create_tween()
		t.tween_interval(randf() * 0.7)
		t.tween_property(letter, "modulate", Color(0.55, 0.58, 0.65, 0.0), 1.2)
		t.parallel().tween_property(letter, "position:y", letter.position.y - 0.2, 1.2)
	# the ember falls toward the gate along a curve...
	var e0 := ember.global_position
	var mid := Vector3(0.3, 3.2, 13.5)
	var fall := create_tween()
	fall.tween_method(func(t: float): ember.global_position = e0.lerp(mid, t).lerp(mid.lerp(gate_point, t), t), 0.0, 1.0, 4.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fall.parallel().tween_property(ember, "scale", Vector3.ONE, 4.2)
	fall.tween_callback(func(): ember.wait_at(gate_point))
	# ...and the camera follows it down, into the eyes
	var eye := player.head_position() + player.facing() * 0.12
	var look0 := cam.look_target
	var tw := create_tween()
	tw.tween_method(func(t: float): cam.look_target = look0.lerp(ember.global_position, smoothstep(0.0, 1.0, t)), 0.0, 1.0, 1.6)
	tw.tween_callback(func(): cam.focus(14.0))
	tw.parallel().tween_property(cam, "global_position", Vector3(0.6, 2.4, 17.0), 5.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_method(func(_t: float): cam.look_target = cam.look_target.lerp(ember.global_position, 0.12), 0.0, 1.0, 5.2)
	tw.tween_property(cam, "global_position", eye, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "look_target", eye + Vector3(0, -0.1, -5.0), 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "fov", cam.default_fov, 2.4)
	tw.tween_callback(_hand_over_control)


func _hand_over_control() -> void:
	var player: PlayerBody = game.player
	Sound.play_music("theme_broken", -10.0, 4.0)  # the piano belongs to the opening only
	game.hud.letterbox(false, 1.8)
	game.hud.set_crosshair_visible(true, 2.0)
	player.cam.focus(-1.0)
	player.cam.cinematic = false
	player.cam.look_target = Vector3.INF
	player.can_move = true
	create_tween().tween_property(player, "look_scale", 1.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	finished.emit()
	var t := create_tween()
	t.tween_interval(4.0)
	t.tween_callback(hide)


## Skip straight to gameplay (dev tests).
func skip(game_director: GameDirector) -> void:
	game = game_director
	_running = false
	_waiting_for_press = false
	game.hud.screen_fade.color.a = 0.0
	game.ember.scale = Vector3.ONE
	game.ember.global_position = gate_point
	game.ember.wait_at(gate_point)
	_hand_over_control()


# ---------------------------------------------------------------- sky letters

func _hand_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Ink Free", "Segoe Script", "Bradley Hand ITC", "cursive"])
	return f


func _serif_font(weight := 500) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Cormorant Garamond", "Palatino Linotype", "Book Antiqua", "Georgia", "serif"])
	f.font_weight = weight
	return f


## One Label3D per character, laid out as a centred line (spaces are skipped).
func _write_letters(text: String, font: Font, size: int, pixel: float, y: float, color: Color) -> Array[Label3D]:
	var out: Array[Label3D] = []
	var total := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	for i in text.length():
		var ch := text.substr(i, 1)
		if ch == " ":
			continue
		var before := font.get_string_size(text.substr(0, i), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var l := Label3D.new()
		l.name = "Letter%d" % i
		l.text = ch
		l.font = font
		l.font_size = size
		l.pixel_size = pixel
		l.outline_size = 0
		l.shaded = false
		l.double_sided = true
		l.render_priority = 10
		l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS  # writes depth, so depth of field keeps it sharp
		l.alpha_scissor_threshold = 0.35
		l.position = Vector3((before + w * 0.5 - total * 0.5) * pixel, y, 0)
		l.modulate = Color(color, 0.0)
		title_sky.add_child(l)
		out.append(l)
	return out
