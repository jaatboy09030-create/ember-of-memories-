extends Node3D
## PLAYER SCARF: the faded red scarf worn from the first shot (the story's clue thread).
## On start it attaches itself to the character's neck bone so it follows the animation.
## How to change it: neck_offset nudges it on the neck; edit ScarfLoop / ScarfTail meshes
## for its shape and colour.

@export var neck_bone := "mixamorig_Neck"
@export var neck_offset := Vector3(0, 0.02, 0.01)


func _ready() -> void:
	# wait one frame so the character model is in the tree and posed
	await get_tree().process_frame
	var skel := ModelUtils.find_skeleton(get_parent())
	if not skel or skel.find_bone(neck_bone) < 0:
		return  # no rig: stay where we are in the scene
	var att := BoneAttachment3D.new()
	att.name = "NeckAttachment"
	att.bone_name = neck_bone
	skel.add_child(att)
	reparent(att, false)
	position = neck_offset
	rotation = Vector3.ZERO
	# undo the skeleton's import scale so the scarf keeps its real size
	scale = Vector3.ONE / skel.global_transform.basis.get_scale().x
