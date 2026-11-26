class_name ScreenEffects
extends CanvasLayer
## SCREEN EFFECTS: the film look drawn over the 3D view (shaders/camera_fx.gdshader):
## vignette, grain, colour fringe, warm/cold tint, the grey "frozen memory" look, and the
## pixelated faces of the memory figures.
##
## How to change it: the resting values below; the shader's own uniforms are on
## FilmLook > Material in the Inspector.
##
## World colour: `world_saturation` (0 grey .. 1 full colour) drives BOTH this screen effect
## and every textured prop (the global shader parameter "world_sat").

@export var resting_vignette := 0.32
@export var resting_aberration := 0.0012
## Faces further away than this are not pixelated.
@export var face_blur_distance := 14.0

@onready var film_look: ColorRect = $FilmLook
@onready var mat: ShaderMaterial = film_look.material

var world_saturation := 0.3:
	set(v):
		world_saturation = v
		RenderingServer.global_shader_parameter_set("world_sat", v)
		if mat:
			mat.set_shader_parameter("world_sat", v)


func _ready() -> void:
	world_saturation = world_saturation


## Fade the world's colour to `value` over `time` seconds.
func fade_saturation(value: float, time := 2.5) -> Tween:
	var tw := create_tween()
	tw.tween_property(self, "world_saturation", value, time)
	return tw


func tween_shader(param: String, value: float, time: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(mat, "shader_parameter/" + param, value, time)
	return tw


## A memory comes back: a warm flash that settles slightly warmer than before.
func warm_flash() -> void:
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


## Pixelate the memory figures' faces (nodes in the "memory_face" group).
func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	var faces: Array = []
	for f in get_tree().get_nodes_in_group("memory_face"):
		var face := f as Node3D
		if not face.is_visible_in_tree():
			continue
		var p := face.global_position
		if cam.is_position_behind(p) or cam.global_position.distance_to(p) > face_blur_distance:
			continue
		# hidden behind a wall? then there's nothing to pixelate
		var hit := face.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(cam.global_position, p))
		if not hit.is_empty() and (hit.position as Vector3).distance_to(p) > 0.35:
			continue
		var c := cam.unproject_position(p)
		var edge := cam.unproject_position(p + cam.global_transform.basis.x * 0.13)
		faces.append(Vector4(c.x, c.y, c.distance_to(edge), 1.0))
		if faces.size() == 4:
			break
	while faces.size() < 4:
		faces.append(Vector4.ZERO)
	mat.set_shader_parameter("faces", faces)
	mat.set_shader_parameter("face_count", 4)
