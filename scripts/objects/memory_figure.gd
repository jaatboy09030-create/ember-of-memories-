class_name MemoryFigure
extends Node3D
## MEMORY FIGURE: the parent or child seen inside a memory, frozen mid-moment.
## They are drawn as faint ember-gold ghosts and their faces are pixelated on screen
## (ScreenEffects reads the "memory_face" group). When the memory is restored, wake()
## lets the animation play, the ghost flares warmly, then fades away.
##
## How to use: instance memory_figure.tscn, add the character (a Mixamo .fbx) as a child
## named "CharacterModel". Optionally add a Marker3D child and assign it to seat_point so
## a sitting figure's hips land exactly on the chair.
##
## How to change it: frozen_at = which moment of the animation it is frozen on (0..1).

## Moment of the animation the figure is frozen on (0 = start, 1 = end).
@export_range(0.0, 1.0) var frozen_at := 0.3
## Optional: for sitting animations, the hips are moved onto this point.
@export var seat_point: Marker3D
## Seconds after waking before the figure disappears.
@export var vanish_after := 13.5

const GHOST_SHADER := preload("res://shaders/ghost.gdshader")
const HEAD_BONE := "mixamorig_Head"
const HIPS_BONE := "mixamorig_Hips"

@onready var character: Node3D = $CharacterModel

var _anim: AnimationPlayer
var _ghost_materials: Array[ShaderMaterial] = []


func _ready() -> void:
	ModelUtils.fix_cull(character)
	_make_ghost(character)
	var skeleton := ModelUtils.find_skeleton(character)
	_add_face_anchor(skeleton)
	_freeze_animation()
	if seat_point and skeleton:
		_sit_on_seat(skeleton)


func wake() -> void:
	if _anim:
		create_tween().tween_property(_anim, "speed_scale", 1.0, 2.0)
	for g in _ghost_materials:
		var tw := create_tween()
		tw.tween_property(g, "shader_parameter/strength", 1.8, 1.2)
		tw.tween_interval(6.0)
		tw.tween_property(g, "shader_parameter/strength", 0.0, 5.0)
	var gone := create_tween()
	gone.tween_interval(vanish_after)
	gone.tween_callback(hide)  # the memory has passed: no ghost, no mosaic


## Every surface keeps its own texture but is drawn faded and glowing.
func _make_ghost(n: Node) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var mi := n as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i)
			var gm := ShaderMaterial.new()
			gm.shader = GHOST_SHADER
			gm.set_shader_parameter("strength", 1.0)
			if src is BaseMaterial3D:
				gm.set_shader_parameter("tint", (src as BaseMaterial3D).albedo_color)
				if (src as BaseMaterial3D).albedo_texture:
					gm.set_shader_parameter("albedo_tex", (src as BaseMaterial3D).albedo_texture)
					gm.set_shader_parameter("has_tex", true)
			mi.set_surface_override_material(i, gm)
			_ghost_materials.append(gm)
	for c in n.get_children():
		_make_ghost(c)


## A point that follows the head bone; the screen effect pixelates the face around it.
func _add_face_anchor(skeleton: Skeleton3D) -> void:
	if not skeleton or skeleton.find_bone(HEAD_BONE) < 0:
		return
	var att := BoneAttachment3D.new()
	att.name = "HeadAttachment"
	att.bone_name = HEAD_BONE
	skeleton.add_child(att)
	var face := Node3D.new()
	face.name = "FaceAnchor"
	face.position = Vector3(0, 0.1, 0.05)
	face.add_to_group("memory_face")
	att.add_child(face)


func _freeze_animation() -> void:
	_anim = ModelUtils.find_animation_player(character)
	if not _anim:
		return
	var clip := ""
	for a in _anim.get_animation_list():
		if a != "RESET":
			clip = a
	if clip == "":
		return
	_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	_anim.play(clip)
	_anim.seek(_anim.current_animation_length * frozen_at, true)
	_anim.speed_scale = 0.0  # frozen memory


func _sit_on_seat(skeleton: Skeleton3D) -> void:
	var hb := skeleton.find_bone(HIPS_BONE)
	if hb < 0:
		return
	var hips: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(hb).origin
	global_position += seat_point.global_position - hips
