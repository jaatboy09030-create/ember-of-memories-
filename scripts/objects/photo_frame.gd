class_name PhotoFrame
extends Interactable
## PHOTO FRAME lying face down on the dresser in the parent's room (memory 5).
## Using it emits `chosen`; PhotoMemory then plays the cutscene: pick_up() lifts it into
## the player's hands, and set_reflection() slowly turns the glass into a mirror that shows
## the player's face (ReflectionCamera films the face from the glass; the Glass shader shows
## it flipped like a mirror). put_down() lays it back on the dresser, face up.
##
## How to change it: pick_up_time = how long the lift takes; the glass look is the
## photo_glass shader's material on FramePivot/Glass; HandGripLeft/Right = where the
## wrists go; FaceGlow = the pale light the glass throws on the face.

signal chosen

@export var pick_up_time := 1.6
## Field of view of the reflection (lower = the face fills more of the glass).
@export var reflection_fov := 30.0
## How far behind the glass the reflection is filmed from (metres). Like a real mirror the
## face looks as far away again behind the glass; larger = flatter, less distorted face.
## Everything nearer than the glass (frame, hands) is cut away by the camera's near plane.
@export var reflection_depth := 0.45
## Brightest the FaceGlow light gets at full reflection.
@export var face_glow_energy := 0.5

@onready var frame_pivot: Node3D = $FramePivot
@onready var glass: MeshInstance3D = $FramePivot/Glass
@onready var face_glow: OmniLight3D = $FramePivot/FaceGlow
@onready var grip_left: Marker3D = $FramePivot/HandGripLeft
@onready var grip_right: Marker3D = $FramePivot/HandGripRight
@onready var reflection_viewport: SubViewport = $ReflectionViewport
@onready var reflection_camera: Camera3D = $ReflectionViewport/ReflectionCamera

## World point the reflection looks at (the face). Vector3.INF = reflection off.
var reflect_target := Vector3.INF
var _rest: Transform3D
var _glass_mat: ShaderMaterial


func _ready() -> void:
	super._ready()
	enabled = false
	_rest = frame_pivot.transform  # face down, as placed in the scene
	_glass_mat = glass.get_surface_override_material(0)
	_glass_mat.set_shader_parameter("reflection_tex", reflection_viewport.get_texture())
	reflection_camera.fov = reflection_fov
	reflection_camera.near = reflection_depth + 0.02


func on_interact() -> void:
	super.on_interact()
	enabled = false
	chosen.emit()


## Lift the photo off the dresser and turn it over into `hold` (a world transform: +Y = the
## picture side, facing the eyes; -Z = the far edge).
func pick_up(hold: Transform3D) -> void:
	Sound.play("photo_flip", -2.0)
	var from := frame_pivot.global_transform
	var lift := from.translated(Vector3(0, 0.12, 0))
	var tw := create_tween()
	tw.tween_method(func(t: float): frame_pivot.global_transform = from.interpolate_with(lift, t), 0.0, 1.0, pick_up_time * 0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(t: float): frame_pivot.global_transform = lift.interpolate_with(hold, t), 0.0, 1.0, pick_up_time * 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Follow the hands while held (the caller adds the small breathing motion).
func hold_at(hold: Transform3D) -> void:
	frame_pivot.global_transform = hold


## Lay it back down on the dresser, picture side up.
func put_down() -> void:
	set_reflection(0.0, 0.0)
	reflect_target = Vector3.INF
	frame_pivot.transform = Transform3D(Basis.IDENTITY, _rest.origin)


## Turn the glass into a mirror: 0 = clear, 1 = full reflection, over `time` seconds.
func set_reflection(amount: float, time: float) -> void:
	reflection_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if amount > 0.0 or time > 0.0 \
		else SubViewport.UPDATE_DISABLED
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_glass_mat, "shader_parameter/reflect", amount, time).set_trans(Tween.TRANS_SINE)
	tw.tween_property(face_glow, "light_energy", face_glow_energy * amount, time).set_trans(Tween.TRANS_SINE)
	if amount <= 0.0:
		tw.chain().tween_callback(func(): reflection_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED)


func _process(_delta: float) -> void:
	if reflect_target == Vector3.INF:
		return
	# film the face from the glass, top of the picture = top of the photo (-Z = far edge)
	var b := frame_pivot.global_basis.orthonormalized()
	var eye := glass.global_position - b.y * reflection_depth
	reflection_camera.global_transform = Transform3D(Basis.IDENTITY, eye).looking_at(reflect_target, -b.z)
