class_name TitleSequence
extends Node3D
## TITLE SEQUENCE: the opening, one continuous shot with no cuts.
## The ember writes an unfinished line in the night sky, the words cool to ash, the name
## forms, and on any button press the ember falls to the garden gate while the camera
## follows it down into the player's eyes. Emits `finished` when the player has control.
##
## How to change it:
##   unfinished_line             -> the text written in the sky (empty = none)
##   TitleOverlay/Wordmark       -> the game's name (assets/ui/unsent_wordmark.png, the owner's logo wordmark)
##   camera_start / camera_look  -> the opening camera shot
##   gate_point                  -> where the ember lands
## The ash, the warm window and the "press any button" prompt are child nodes in the scene.
## A few dry leaves (assets/vfx/burning_leaf.glb) drift down through the shot and burn away
## from the edges as they fall (shaders/burning_leaf.gdshader), gliding side to side like real
## leaves (shaders/leaf_fall.gdshader) and shedding flame; leaf_count sets how many.
## The house itself (HouseExterior) has one upstairs window that is lit with someone standing
## in it while the line is written; when the line breaks off, they are gone and it goes dark.
## Later it warms again, empty.
## The sky letters are created from the text when the sequence starts (one Label3D per
## letter, so each can light up and crumble on its own).

signal finished

## Leave empty to skip the sky line and open straight on the window and the name.
@export var unfinished_line := ""
@export var camera_start := Vector3(11.9, 0.85, 8.7)  # low, off the front-right corner, looking up
@export var camera_look := Vector3(3.8, 5.4, -2.5)
## How far the player looks up when the first scene opens (degrees), so the house and sky fill the view.
@export var first_scene_pitch := 2.5
## The first scene opens on a narrower, more cinematic lens (like the owner's reference); it widens to the
## normal field of view as soon as the player starts walking.
@export var first_scene_fov := 56.0
## Where the ember waits for the player in the first scene: over the garden gate in the fence.
@export var gate_point := Vector3(0, 1.3, 10.0)
## Distance in front of the camera at which the words float.
@export var text_distance := 9.0
@export var line_color := Color(1.9, 0.62, 0.16)
## Where the ember comes to rest beside the name, as a height in the sky plane.
@export var name_y := -3.7
## Anything closer than this (the framing branches) is blurred in the opening.
@export var near_blur_distance := 1.9
## World colour during the opening (the game itself starts grey; it drains as you walk in).
@export_range(0.0, 1.0) var opening_saturation := 0.9
## How dark the frame's edges are during the opening (the game's own vignette returns on continue).
@export_range(0.0, 1.0) var opening_vignette := 0.6
## Burning leaves drifting through the opening shot (0 = none).
@export var leaf_count := 14

const LEAF_MODEL := "res://assets/vfx/burning_leaf.glb"
const LEAF_SHADER := preload("res://shaders/burning_leaf.gdshader")
const LEAF_FALL := preload("res://shaders/leaf_fall.gdshader")

@onready var title_sky: Node3D = $TitleSky
@onready var ash: CPUParticles3D = $TitleSky/TitleAsh
@onready var window_glow: OmniLight3D = $WindowGlow
## Warm light only the opening uses (porch lantern glow, the burning-leaf glow on the gable). Fades out on continue.
@onready var title_lights: Node3D = $TitleLights
@onready var wordmark: TextureRect = $TitleOverlay/Wordmark
@onready var name_glow: TextureRect = $TitleOverlay/NameGlow
## The game's lily mark, bottom-right (assets/ui/unsent_lily.png, cut from the logo). Fades in with the prompt.
@onready var logo_mark: TextureRect = $TitleOverlay/LogoMark
## Snowy bare branches framing the opening shot (assets/vfx/foreground_branches.glb, modelled in Blender).
## Their transforms are in camera space: the node is snapped to the opening camera when the sequence plays.
@onready var foreground_branches: Node3D = $ForegroundBranches
@onready var tap_prompt: Label = $TitleOverlay/TapPrompt

var game: GameDirector
var _line_letters: Array[Label3D] = []
var _waiting_for_press := false
var _running := false
var _time := 0.0
var _ember_rest := Vector3.ZERO
var _house: HouseExterior
var _leaves: GPUParticles3D
var _prompt_tween: Tween


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
	# depth of field only up close: the foreground branches go soft, the house and the sky stay sharp
	var attr := cam.attributes as CameraAttributesPractical
	if attr:
		attr.dof_blur_far_enabled = false
		attr.dof_blur_near_enabled = true
		attr.dof_blur_near_distance = near_blur_distance
		attr.dof_blur_near_transition = 0.8
		attr.dof_blur_amount = 0.16
	game.hud.set_crosshair_visible(false)
	game.hud.letterbox(false, 0.0)  # full frame, like the owner's reference
	Sound.play_music("theme_piano" if Sound.get_stream("theme_piano") else "theme_broken", -9.0, 3.0)
	game.screen_effects.world_saturation = opening_saturation
	_apply_opening_look()
	game.screen_effects.set_vignette(opening_vignette, 0.0)  # dark edges, like the owner's mock-up
	foreground_branches.global_transform = Transform3D(Basis.looking_at(camera_look - camera_start, Vector3.UP), camera_start)
	_house = get_tree().get_first_node_in_group("house_exterior") as HouseExterior
	if _house:
		_house.window_warmth = 1.0
		_house.someone_there = 1.0
	_place_sky()
	_start_leaves()
	_line_letters = _write_letters(unfinished_line, _hand_font(), 112, 0.0034, 0.55, line_color)
	_ember_rest = title_sky.to_global(Vector3(2.2, name_y, 0.05))
	_write_the_line()


# ---------------------------------------------------------------- the opening's own look

## The opening keeps the look it was tuned with (moon high-left and big, brighter haze); the first scene
## at the gate uses the level's own settings, tuned to the owner's reference (research/00 recipe).
## They are swapped while the screen is black.
@export var opening_moon_basis := Basis(Vector3(-0.5, 0, 0.866), Vector3(0.42, 0.874, 0.2425), Vector3(-0.757, 0.485, -0.437))
@export var opening_moon_size := 0.15
@export var opening_exposure := 1.05
@export var opening_ambient := 0.3
@export var opening_glow := Vector2(0.7, 0.06)  # intensity, bloom
@export var opening_moon_fill := 0.16
@export var opening_fog := Vector3(0.011, 0.7, 0.6)  # density, anisotropy, moon fog energy
@export var opening_moon_color := Color(0.55, 0.66, 1.0)
@export var opening_cloud_cover := 0.46
@export var opening_cloud_far := 0.4
@export var opening_sdfgi := 1.1

var _gameplay_look := {}
var _widen_on_move := false


func _apply_opening_look() -> void:
	var env := game.world_environment.environment
	var sky_mat := env.sky.sky_material as ShaderMaterial
	var moon := game.get_node_or_null("Moon") as DirectionalLight3D
	var fill := game.get_node_or_null("MoonFill") as DirectionalLight3D
	_gameplay_look = {
		"exposure": env.tonemap_exposure, "ambient": env.ambient_light_energy,
		"glow": env.glow_intensity, "bloom": env.glow_bloom,
		"agx_contrast": env.tonemap_agx_contrast, "agx_white": env.tonemap_agx_white,
		"moon_size": sky_mat.get_shader_parameter("moon_size") if sky_mat else null,
		"moon_basis": moon.global_basis if moon else Basis(), "fill": fill.light_energy if fill else 0.0,
		"fog_density": env.volumetric_fog_density, "fog_aniso": env.volumetric_fog_anisotropy,
		"moon_fog": moon.light_volumetric_fog_energy if moon else 0.0, "moon_color": moon.light_color if moon else Color.WHITE,
		"cloud_cover": sky_mat.get_shader_parameter("cloud_cover") if sky_mat else null,
		"cloud_far": sky_mat.get_shader_parameter("cloud_far") if sky_mat else null,
		"cloud_focus": sky_mat.get_shader_parameter("cloud_focus") if sky_mat else null,
		"sdfgi": env.sdfgi_energy,
	}
	env.volumetric_fog_density = opening_fog.x
	env.volumetric_fog_anisotropy = opening_fog.y
	if moon:
		moon.light_volumetric_fog_energy = opening_fog.z
		moon.light_color = opening_moon_color
	env.sdfgi_energy = opening_sdfgi
	if sky_mat:
		sky_mat.set_shader_parameter("cloud_cover", opening_cloud_cover)
		sky_mat.set_shader_parameter("cloud_far", opening_cloud_far)
		sky_mat.set_shader_parameter("cloud_focus", 1.0)
	env.tonemap_exposure = opening_exposure
	env.ambient_light_energy = opening_ambient
	env.glow_intensity = opening_glow.x
	env.glow_bloom = opening_glow.y
	env.tonemap_agx_contrast = ClassDB.class_get_property_default_value(&"Environment", &"tonemap_agx_contrast")
	env.tonemap_agx_white = ClassDB.class_get_property_default_value(&"Environment", &"tonemap_agx_white")
	if sky_mat:
		sky_mat.set_shader_parameter("moon_size", opening_moon_size)
	if moon:
		moon.global_basis = opening_moon_basis
	if fill:
		fill.light_energy = opening_moon_fill


func _restore_gameplay_look() -> void:
	if _gameplay_look.is_empty():
		return
	var env := game.world_environment.environment
	var sky_mat := env.sky.sky_material as ShaderMaterial
	var moon := game.get_node_or_null("Moon") as DirectionalLight3D
	var fill := game.get_node_or_null("MoonFill") as DirectionalLight3D
	env.tonemap_exposure = _gameplay_look.exposure
	env.ambient_light_energy = _gameplay_look.ambient
	env.glow_intensity = _gameplay_look.glow
	env.glow_bloom = _gameplay_look.bloom
	env.tonemap_agx_contrast = _gameplay_look.agx_contrast
	env.tonemap_agx_white = _gameplay_look.agx_white
	if sky_mat and _gameplay_look.moon_size != null:
		sky_mat.set_shader_parameter("moon_size", _gameplay_look.moon_size)
	env.volumetric_fog_density = _gameplay_look.fog_density
	env.volumetric_fog_anisotropy = _gameplay_look.fog_aniso
	env.sdfgi_energy = _gameplay_look.sdfgi
	if sky_mat and _gameplay_look.cloud_cover != null:
		sky_mat.set_shader_parameter("cloud_cover", _gameplay_look.cloud_cover)
		sky_mat.set_shader_parameter("cloud_far", _gameplay_look.cloud_far)
		sky_mat.set_shader_parameter("cloud_focus", _gameplay_look.cloud_focus)
	if moon:
		moon.global_basis = _gameplay_look.moon_basis
		moon.light_volumetric_fog_energy = _gameplay_look.moon_fog
		moon.light_color = _gameplay_look.moon_color
	if fill:
		fill.light_energy = _gameplay_look.fill
	_gameplay_look = {}


## Height of the words above the line of sight (keeps them in the sky above the roof).
@export var text_lift := 1.6

## A plane of words floating in the snow between the camera and the house, facing the camera.
func _place_sky() -> void:
	var d := (camera_look - camera_start).normalized()
	var center := camera_start + d * text_distance + Vector3(0, text_lift, 0)
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
	if _line_letters.is_empty():
		# no line: the window goes dark, then straight on to the name
		if _house:
			tw.tween_property(_house, "someone_there", 0.0, 0.9).set_trans(Tween.TRANS_SINE)
			tw.tween_property(_house, "window_warmth", 0.0, 1.4).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(_cool_the_words)
		return
	var first := _line_letters[0]
	tw.tween_property(ember, "global_position", title_sky.to_global(first.position + Vector3(-0.08, -0.05, 0.05)), 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for letter in _line_letters:
		tw.tween_property(ember, "global_position", title_sky.to_global(letter.position + Vector3(0.05, -0.04, 0.05)), 0.1)
		tw.parallel().tween_property(letter, "modulate:a", 1.0, 0.22)
	# the pen hesitates where the next word should be... and never writes it
	var last := _line_letters[_line_letters.size() - 1]
	tw.tween_property(ember, "global_position", title_sky.to_global(last.position + Vector3(0.22, -0.02, 0.05)), 0.5).set_trans(Tween.TRANS_SINE)
	# ...and in the window, whoever was waiting steps away. The light goes out.
	if _house:
		tw.tween_property(_house, "someone_there", 0.0, 0.9).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_house, "window_warmth", 0.0, 1.4).set_trans(Tween.TRANS_SINE)
	else:
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
	if _house:
		seq.parallel().tween_property(_house, "window_warmth", 0.8, 0.5)
	seq.tween_interval(0.5)
	seq.tween_property(window_glow, "light_energy", 0.0, 1.4)
	if _house:
		seq.parallel().tween_property(_house, "window_warmth", 0.0, 1.4)
	seq.tween_callback(func(): ash.emitting = false)
	# the name forms out of the drifting ash
	var name_in := create_tween()
	name_in.tween_interval(1.6)
	name_in.tween_property(wordmark, "modulate:a", 1.0, 2.2).set_trans(Tween.TRANS_SINE)
	var glow := create_tween()
	glow.tween_interval(1.8)
	glow.tween_property(name_glow, "modulate:a", 0.45, 2.0)
	seq.tween_property(game.ember, "global_position", _ember_rest, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	seq.tween_interval(0.6)
	seq.tween_callback(func():
		_waiting_for_press = true
		_prompt_tween = create_tween()
		_prompt_tween.tween_property(tap_prompt, "modulate:a", 1.0, 1.0)
		_prompt_tween.parallel().tween_property(logo_mark, "modulate:a", 0.9, 1.6))


func _process(delta: float) -> void:
	if _widen_on_move and game and game.player.is_moving():
		_widen_on_move = false
		var c: PlayerCamera = game.player.cam
		create_tween().tween_property(c, "fov", c.default_fov, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if not _waiting_for_press:
		return
	_time += delta
	tap_prompt.modulate.a = 0.3 + 0.55 * (0.5 + 0.5 * sin(_time * 2.0))
	# every so often, the window remembers being warm
	var w := maxf(sin(_time * 0.37) * sin(_time * 0.91), 0.0)
	window_glow.light_energy = pow(w, 6.0) * 3.0
	if _house:
		_house.window_warmth = pow(w, 6.0) * 0.8  # empty now


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
	if _prompt_tween:
		_prompt_tween.kill()  # pressed while it was still fading in
	create_tween().tween_property(tap_prompt, "modulate:a", 0.0, 0.6)
	if _leaves:
		_leaves.emitting = false
	create_tween().tween_property(window_glow, "light_energy", 0.0, 0.6)
	for l in title_lights.get_children():
		create_tween().tween_property(l, "light_energy", 0.0, 3.5)
	game.screen_effects.fade_saturation(game.start_saturation, 4.5)
	game.screen_effects.reset_vignette(4.5)
	if _house:
		create_tween().tween_property(_house, "window_warmth", 0.0, 0.6)
	# the name crumbles into the snow
	ash.position = Vector3(0, -0.35, 0)
	ash.gravity = Vector3(0.1, -0.15, 0)
	ash.restart()
	ash.emitting = true
	create_tween().tween_property(name_glow, "modulate:a", 0.0, 1.2)
	create_tween().tween_property(logo_mark, "modulate:a", 0.0, 1.2)
	create_tween().tween_property(wordmark, "modulate", Color(0.55, 0.58, 0.65, 0.0), 1.4)
	# the ember falls toward the gate along a curve...
	var e0 := ember.global_position
	var mid := Vector3(0.3, 3.2, 13.5)
	var fall := create_tween()
	fall.tween_method(func(t: float): ember.global_position = e0.lerp(mid, t).lerp(mid.lerp(gate_point, t), t), 0.0, 1.0, 4.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fall.parallel().tween_property(ember, "scale", Vector3.ONE, 4.2)
	fall.tween_callback(func(): ember.wait_at(gate_point))
	# ...the camera stays where it is and only turns its head to watch it go (no flying through
	# the garden), then the eyes close and open again as the player, standing at the gate.
	var eye := player.head_position() + player.facing() * 0.12
	var fade := game.hud.screen_fade
	var tw := create_tween()
	tw.tween_method(func(_t: float): cam.look_target = cam.look_target.lerp(ember.global_position, 0.06), 0.0, 1.0, 3.8)
	tw.parallel().tween_property(cam, "fov", 40.0, 3.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "global_position", camera_start + Vector3(0, 0.15, 0), 3.8).set_trans(Tween.TRANS_SINE)
	# eyes close
	tw.tween_property(fade, "color:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		cam.global_position = eye
		cam.look_target = eye + Vector3(0, -0.1, -5.0)
		cam.fov = first_scene_fov
		_widen_on_move = true
		# while it's black: the first scene's own look (research/00 recipe), every window lit
		_restore_gameplay_look()
		if _leaves:
			_leaves.visible = false  # the title's leaves belong to the title
		if _house:
			_house.all_windows_warmth = 1.0
		# the front door stands open, warm light inside
		var front: InteriorDoor = game.doors.get("front")
		if front:
			front.unlock_and_open()
		player.target_pitch = deg_to_rad(first_scene_pitch))
	tw.tween_interval(0.7)
	# and open, at the gate, the ember waiting in the doorway at the end of the path
	tw.tween_callback(_hand_over_control)
	tw.tween_property(fade, "color:a", 0.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _hand_over_control() -> void:
	var player: PlayerBody = game.player
	Sound.play_music("theme_broken", -10.0, 4.0)  # the piano belongs to the opening only
	game.hud.letterbox(false, 1.8)
	game.hud.set_crosshair_visible(true, 2.0)
	# keep the opening's blur: PlayerCamera's autofocus takes over from the 14 m title focus
	if not player.cam.gameplay_dof:
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
	var house := get_tree().get_first_node_in_group("house_exterior") as HouseExterior
	if house:
		house.window_warmth = 0.0
	title_lights.visible = false
	if house:
		house.all_windows_warmth = 1.0
	foreground_branches.visible = false
	game.ember.scale = Vector3.ONE
	game.ember.global_position = gate_point
	game.ember.wait_at(gate_point)
	_hand_over_control()


# ---------------------------------------------------------------- sky letters

func _hand_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Ink Free", "Segoe Script", "Bradley Hand ITC", "cursive"])
	return f


## One Label3D per character, laid out as a centred line (spaces are skipped).
func _write_letters(text: String, font: Font, size: int, pixel: float, y: float, color: Color, tracking := 0.0) -> Array[Label3D]:
	var out: Array[Label3D] = []
	var total := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + tracking * (text.length() - 1)
	for i in text.length():
		var ch := text.substr(i, 1)
		if ch == " ":
			continue
		var before := font.get_string_size(text.substr(0, i), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + tracking * i
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


## Dry leaves falling between the camera and the gate, catching fire and burning to nothing.
func _start_leaves() -> void:
	if leaf_count <= 0 or not ResourceLoader.exists(LEAF_MODEL):
		return
	var model: Node = (load(LEAF_MODEL) as PackedScene).instantiate()
	var mi := model.find_children("*", "MeshInstance3D", true, false)
	if mi.is_empty():
		model.free()
		return
	var mesh: Mesh = (mi[0] as MeshInstance3D).mesh.duplicate()
	model.free()
	var noise := NoiseTexture2D.new()
	noise.seamless = true
	var fn := FastNoiseLite.new()
	fn.frequency = 0.03
	noise.noise = fn
	var sm := ShaderMaterial.new()
	sm.shader = LEAF_SHADER
	sm.set_shader_parameter("noise_tex", noise)
	mesh.surface_set_material(0, sm)
	_leaves = GPUParticles3D.new()
	_leaves.name = "BurningLeaves"
	_leaves.amount = leaf_count
	_leaves.lifetime = 14.0
	_leaves.preprocess = 7.0
	_leaves.draw_pass_1 = mesh
	_leaves.visibility_aabb = AABB(Vector3(-12, -12, -10), Vector3(24, 16, 20))
	# the fall itself: slow, side-to-side glide and rocking (see the shader)
	var m := ShaderMaterial.new()
	m.shader = LEAF_FALL
	_leaves.process_material = m
	add_child(_leaves)
	# above and in front of the opening camera, between it and the gate
	_leaves.global_position = camera_start + (camera_look - camera_start).normalized() * 6.5 + Vector3(0, 3.0, 0)
	# flame tongues licking off each burning leaf (emitted by leaf_fall.gdshader)
	var flames := _leaf_flames(noise)
	add_child(flames)
	_leaves.sub_emitter = _leaves.get_path_to(flames)


func _leaf_flames(noise: Texture2D) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "LeafFlames"
	p.amount = leaf_count * 24
	p.lifetime = 0.8
	p.local_coords = false
	p.randomness = 0.4
	p.visibility_aabb = AABB(Vector3(-14, -14, -14), Vector3(28, 28, 28))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	var m := ParticleProcessMaterial.new()
	m.gravity = Vector3(0, 0.8, 0)  # heat rises off the leaf
	m.damping_min = 0.8
	m.damping_max = 1.5
	m.angle_min = -30.0
	m.angle_max = 30.0
	m.scale_min = 0.7
	m.scale_max = 1.2
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.5))
	sc.add_point(Vector2(0.2, 1.0))
	sc.add_point(Vector2(1.0, 0.0))
	var sct := CurveTexture.new()
	sct.curve = sc
	m.scale_curve = sct
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	g.colors = PackedColorArray([Color(1.0, 0.75, 0.35, 0.9), Color(1.0, 0.42, 0.08, 0.75),
		Color(0.8, 0.14, 0.02, 0.4), Color(0.2, 0.02, 0.0, 0.0)])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 1.2
	m.turbulence_noise_scale = 2.0
	m.turbulence_influence_min = 0.05
	m.turbulence_influence_max = 0.15
	p.process_material = m
	var quad := QuadMesh.new()
	quad.size = Vector2(0.13, 0.13)
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/ember_wisp.gdshader")
	sm.set_shader_parameter("noise_tex", noise)
	sm.set_shader_parameter("energy", 1.8)
	sm.set_shader_parameter("stretch", 1.9)
	quad.material = sm
	p.draw_pass_1 = quad
	return p
