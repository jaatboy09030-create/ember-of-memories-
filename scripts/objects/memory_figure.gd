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
## play_clip() makes the figure perform another animation (e.g. putting on the scarf). The
## character and the clip must both be RETARGETED to Godot's humanoid skeleton in their FBX
## import settings (Skeleton3D > Retarget > Bone Map, maps in assets/animations/bone_maps/),
## so clips from other rigs (e.g. Unreal mannequin) fit. Works with either bone naming.
##
## How to change it: frozen_at = which moment of the animation it is frozen on (0..1).

## Moment of the animation the figure is frozen on (0 = start, 1 = end).
@export_range(0.0, 1.0) var frozen_at := 0.3
## Optional: for sitting animations, the hips are moved onto this point.
@export var seat_point: Marker3D
## Seconds after waking before the figure disappears.
@export var vanish_after := 13.5

const GHOST_SHADER := preload("res://shaders/ghost.gdshader")
const GHOST_DEPTH_SHADER := preload("res://shaders/ghost_depth.gdshader")
## Bone names to look for: retargeted (humanoid) first, then original Mixamo.
const HEAD_BONES := ["Head", "mixamorig_Head"]
const HIPS_BONES := ["Hips", "mixamorig_Hips"]
const CLIP_LIBRARY := "memory"

@onready var character: Node3D = $CharacterModel

var _anim: AnimationPlayer
var _ghost_materials: Array[ShaderMaterial] = []
var _depth_materials: Array[ShaderMaterial] = []
var _face: Node3D


## Blink demo: clip this ghost to the memory islands and draw it over the black void
## (priority > the void's). count 0 = normal drawing, no clipping.
func clip_to_islands(centres: Array, shapes: Array, count: int, over_void_priority: int) -> void:
	for m in _depth_materials:
		m.render_priority = over_void_priority if count > 0 else -1
		m.set_shader_parameter("islands", centres)
		m.set_shader_parameter("island_shape", shapes)
		m.set_shader_parameter("island_count", count)
	for m in _ghost_materials:
		m.render_priority = over_void_priority + 1 if count > 0 else 0
		m.set_shader_parameter("islands", centres)
		m.set_shader_parameter("island_shape", shapes)
		m.set_shader_parameter("island_count", count)


func _ready() -> void:
	add_to_group("memory_figure")
	ModelUtils.fix_cull(character)
	_make_ghost(character)
	var skeleton := ModelUtils.find_skeleton(character)
	_add_face_anchor(skeleton)
	_freeze_animation()
	if seat_point and skeleton:
		_sit_on_seat(skeleton)


## face_clarity: how clear the face gets (1 = fully clear; the blink demo stops short, so a
## very slight blur always stays on the face).
func wake(face_clarity := 1.0) -> void:
	if _anim:
		create_tween().tween_property(_anim, "speed_scale", 1.0, 2.0)
	if _face and face_clarity > 0.0:  # remembered: the face resolves before the ghost fades
		var ft := create_tween()
		ft.tween_method(func(v: float): _face.set_meta("clarity", v), 0.0, face_clarity, 2.5)
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
			# depth first (invisible), then the faded ghost: only the outer surface shows
			var depth := ShaderMaterial.new()
			depth.shader = GHOST_DEPTH_SHADER
			depth.render_priority = -1
			depth.next_pass = gm
			mi.set_surface_override_material(i, depth)
			_ghost_materials.append(gm)
			_depth_materials.append(depth)
	for c in n.get_children():
		_make_ghost(c)


## Plays an animation taken from another (retargeted) FBX, e.g. putting on the scarf.
## Tracks for bones this character doesn't have are dropped. Returns the clip's length
## in seconds (0 if nothing could be played).
func play_clip(clip_scene: PackedScene, blend_time := 0.4) -> float:
	var skeleton := ModelUtils.find_skeleton(character)
	if not _anim or not skeleton or not clip_scene:
		return 0.0
	var src := clip_scene.instantiate()
	var src_anim := ModelUtils.find_animation_player(src)
	var clip: Animation = null
	if src_anim:
		for a in src_anim.get_animation_list():
			if a != "RESET":
				clip = src_anim.get_animation(a).duplicate()
				break
	src.free()
	if not clip:
		return 0.0
	var skeleton_path := "%" + String(skeleton.name)
	for t in range(clip.get_track_count() - 1, -1, -1):
		var parts := str(clip.track_get_path(t)).split(":")
		if parts.size() < 2 or parts[0] != skeleton_path or skeleton.find_bone(parts[1]) < 0:
			clip.remove_track(t)  # e.g. Unreal's extra spine/IK bones
	clip.loop_mode = Animation.LOOP_NONE
	if not _anim.has_animation_library(CLIP_LIBRARY):
		_anim.add_animation_library(CLIP_LIBRARY, AnimationLibrary.new())
	var lib := _anim.get_animation_library(CLIP_LIBRARY)
	var clip_name := clip_scene.resource_path.get_file().get_basename()
	if lib.has_animation(clip_name):
		lib.remove_animation(clip_name)
	lib.add_animation(clip_name, clip)
	_anim.speed_scale = 1.0
	_anim.play(CLIP_LIBRARY + "/" + clip_name, blend_time)
	return clip.length


func _find_bone(skeleton: Skeleton3D, names: Array) -> String:
	for n in names:
		if skeleton.find_bone(n) >= 0:
			return n
	return ""


## A point that follows the head bone; the screen effect pixelates the face around it.
func _add_face_anchor(skeleton: Skeleton3D) -> void:
	if not skeleton:
		return
	var head := _find_bone(skeleton, HEAD_BONES)
	if head == "":
		return
	var att := BoneAttachment3D.new()
	att.name = "HeadAttachment"
	att.bone_name = head
	skeleton.add_child(att)
	var face := Node3D.new()
	face.name = "FaceAnchor"
	face.position = Vector3(0, 0.1, 0.05)
	face.add_to_group("memory_face")
	att.add_child(face)
	_face = face


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
	var hb := skeleton.find_bone(_find_bone(skeleton, HIPS_BONES))
	if hb < 0:
		return
	var hips: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(hb).origin
	global_position += seat_point.global_position - hips
