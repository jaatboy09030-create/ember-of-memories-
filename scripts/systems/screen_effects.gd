class_name ScreenEffects
extends CanvasLayer
## SCREEN EFFECTS: the film / worn-camera look drawn over the 3D view
## (shaders/camera_fx.gdshader): a gentle lens bend (barrel distortion, cropped so there are
## no black edges) with colour fringe toward the edges, vignette, sensor grain that is
## stronger in the dark, warm/cold tint and the pixelated faces of the memory figures.
## The frozen-memory look itself (moonlit duotone, frost, ember halo, restore ripple) is the
## MemoryGrade child, drawn first; GradeCopy hands its result to FilmLook.
##
## The lens is only on while the player's camera (PlayerCamera) is the active camera. It
## fades out for any other camera (e.g. the drawing puzzle, where the mouse must hit exactly
## what it points at) and is softer while a cutscene drives the player camera.
## The HUD is a higher CanvasLayer, so prompts and captions are never bent.
##
## How to change it: the resting values and the Lens group below; overall strength and
## accessibility in settings/camera_comfort.tres; the shader's own uniforms are on
## FilmLook > Material in the Inspector.
##
## World colour: `world_saturation` (0 grey .. 1 full colour) drives BOTH this screen effect
## and every textured prop (the global shader parameter "world_sat").

@export var resting_vignette := 0.32
@export var resting_aberration := 0.0012
## Film grain amount when comfort.grain = 1.
@export var resting_grain := 0.03
## Faces further away than this are not pixelated.
@export var face_blur_distance := 14.0

@export_group("Faces (the mosaic rule)")
## THE RULE: faces are pixelated because the player has forgotten them.
## How much the player remembers overall (0 = nothing .. 1). Rises with each restored memory.
@export_range(0.0, 1.0) var memory_clarity := 0.0
## How much memory_clarity one restored memory adds.
@export_range(0.0, 0.5) var clarity_per_memory := 0.1
## Looking straight at a face slowly sharpens it, by up to this much (never fully clear).
@export_range(0.0, 1.0) var gaze_clarity := 0.35
## Seconds of steady looking to reach gaze_clarity; it fades 3x faster when you look away.
@export var gaze_time := 4.0
## How close to the screen centre counts as "looking at" a face (fraction of screen height).
@export var gaze_radius := 0.18
## A grey (drained) world makes faces coarser: clarity is scaled by mix(this, 1, saturation).
@export_range(0.0, 1.0) var drained_clarity_scale := 0.6
@export_group("")
## Shared strength sliders (lens / grain). Empty = everything at full.
@export var comfort: CameraComfort
## Off = no face mosaics (memory 5 turns it off: the mosaic of a figure behind the photo
## would land on the glass, which has no collision to hide it).
@export var pixelate_faces := true

@export_group("Lens")
## Barrel bend (k1). 0 = flat. ~0.1 = gentle worn-camera curve; 0.3+ = fisheye.
@export_range(0.0, 0.5) var lens_bend := 0.1
## Extra bend toward the far corners (k2).
@export_range(0.0, 0.5) var lens_bend_edges := 0.02
## Colour fringe that grows toward the edges.
@export_range(0.0, 0.02) var lens_fringe := 0.003
## Lens strength while a cutscene drives the player camera (PlayerCamera.cinematic).
@export_range(0.0, 1.0) var cinematic_lens_scale := 0.6
## How fast the lens fades in/out when the active camera changes (full strength per second).
@export var lens_fade_speed := 3.0
## 0..1: how much stronger the grain is in dark areas (cheap-sensor noise).
@export_range(0.0, 1.0) var shadow_noise := 0.6

@onready var film_look: ColorRect = $FilmLook
@onready var mat: ShaderMaterial = film_look.material
@onready var memory_grade: MemoryGrade = $MemoryGrade

var world_saturation := 0.3:
	set(v):
		world_saturation = v
		RenderingServer.global_shader_parameter_set("world_sat", v)
		if memory_grade:
			memory_grade.set_world_saturation(v)

var _lens := 0.0  # 0 = no lens .. 1 = full lens, eased toward its target every frame
var _gaze := {}  # face anchor instance id -> 0..1 how long it has been looked at


func _ready() -> void:
	world_saturation = world_saturation
	apply_comfort()


## Re-read the comfort resource (call after an options menu changes it).
func apply_comfort() -> void:
	var g := comfort.grain if comfort else 1.0
	mat.set_shader_parameter("grain", resting_grain * g)
	mat.set_shader_parameter("shadow_noise", shadow_noise)


## Fade the world's colour to `value` over `time` seconds.
func fade_saturation(value: float, time := 2.5) -> Tween:
	var tw := create_tween()
	tw.tween_property(self, "world_saturation", value, time)
	return tw


func tween_shader(param: String, value: float, time: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(mat, "shader_parameter/" + param, value, time)
	return tw


## A memory was restored: every face in the game gets a little clearer.
func remember(amount := -1.0) -> void:
	var a := clarity_per_memory if amount < 0.0 else amount
	create_tween().tween_property(self, "memory_clarity", clampf(memory_clarity + a, 0.0, 1.0), 2.0)


## A memory comes back: a warm flash that settles slightly warmer than before.
func warm_flash() -> void:
	memory_grade.ripple()
	var tw := create_tween()
	tw.tween_property(mat, "shader_parameter/warmth", 0.6, 0.6)
	tw.tween_property(mat, "shader_parameter/warmth", -0.1, 3.0)


## A hit: vignette and colour fringe spike, then relax.
func pulse(vignette: float, aberration: float) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(mat, "shader_parameter/vignette", vignette, 0.08)
	tw.tween_property(mat, "shader_parameter/aberration", aberration, 0.08)
	tw.chain().tween_interval(0.1)
	tw.chain().tween_property(mat, "shader_parameter/vignette", resting_vignette, 1.2)
	tw.parallel().tween_property(mat, "shader_parameter/aberration", resting_aberration, 1.2)


func set_vignette(value: float, time := 0.6) -> void:
	tween_shader("vignette", value, time)


func reset_vignette(time := 0.6) -> void:
	tween_shader("vignette", resting_vignette, time)


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	_update_lens(cam, delta)
	if not cam:
		return
	_update_faces(cam, delta)


## Lens on for the player camera, softer in cutscenes, off for any other camera.
func _update_lens(cam: Camera3D, delta: float) -> void:
	var target := 0.0
	var player_cam := cam as PlayerCamera
	if player_cam:
		target = cinematic_lens_scale if player_cam.cinematic else 1.0
		if comfort:
			target *= comfort.lens
	_lens = move_toward(_lens, target, delta * lens_fade_speed)
	mat.set_shader_parameter("lens_k1", lens_bend * _lens)
	mat.set_shader_parameter("lens_k2", lens_bend_edges * _lens)
	mat.set_shader_parameter("lens_fringe", lens_fringe * _lens)


## Pixelate the memory figures' faces (nodes in the "memory_face" group).
## Positions are flat-screen pixels; the shader bends first, then tests them, so the
## mosaics stay on the faces with the lens on.
## Clarity of each face (see the "Faces" group): the anchor's own "clarity" meta (a figure
## sets it to 1 as its memory is restored) or memory_clarity + gaze, scaled down in a grey
## world. Anchors with meta "no_gaze" don't sharpen when looked at; "no_occlusion" skips
## the wall check (the player's own face, which sits inside the player's collider).
func _update_faces(cam: Camera3D, delta: float) -> void:
	var faces: Array = []
	var res := get_viewport().get_visible_rect().size
	for f in (get_tree().get_nodes_in_group("memory_face") if pixelate_faces else []):
		var face := f as Node3D
		if not face.is_visible_in_tree():
			continue
		var p := face.global_position
		if cam.is_position_behind(p) or cam.global_position.distance_to(p) > face_blur_distance:
			continue
		# hidden behind a wall? then there's nothing to pixelate
		if not face.get_meta("no_occlusion", false):
			var hit := face.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(cam.global_position, p))
			if not hit.is_empty() and (hit.position as Vector3).distance_to(p) > 0.35:
				continue
		var c := cam.unproject_position(p)
		var edge := cam.unproject_position(p + cam.global_transform.basis.x * 0.13)
		faces.append(Vector4(c.x, c.y, c.distance_to(edge), 1.0 + _face_clarity(face, c, res, delta)))
		if faces.size() == 4:
			break
	while faces.size() < 4:
		faces.append(Vector4.ZERO)
	mat.set_shader_parameter("faces", faces)
	mat.set_shader_parameter("face_count", 4)


func _face_clarity(face: Node3D, screen_pos: Vector2, res: Vector2, delta: float) -> float:
	var own: float = face.get_meta("clarity", 0.0)
	var id := face.get_instance_id()
	var g: float = _gaze.get(id, 0.0)
	if not face.get_meta("no_gaze", false):
		var looking := screen_pos.distance_to(res * 0.5) < gaze_radius * res.y
		g = move_toward(g, 1.0 if looking else 0.0, delta / gaze_time * (1.0 if looking else 3.0))
		_gaze[id] = g
	var drained := lerpf(drained_clarity_scale, 1.0, clampf(world_saturation, 0.0, 1.0))
	var base := clampf(memory_clarity + g * gaze_clarity, 0.0, 0.97) * drained
	return clampf(maxf(own, base), 0.0, 1.0)
