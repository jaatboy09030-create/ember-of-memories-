extends SceneTree
## One-off tool: writes the two BoneMap resources used to RETARGET animations between rigs.
## Both map onto Godot's standard humanoid skeleton (SkeletonProfileHumanoid), so after
## import every bone is called Hips, Spine, LeftUpperArm, ... whichever rig it came from.
##   assets/animations/bone_maps/mixamo_bone_map.tres  -> Mixamo characters (mixamorig_*)
##   assets/animations/bone_maps/ue5_bone_map.tres     -> Unreal mannequin clips (pelvis, spine_01, ...)
## The FBX import settings (Skeleton3D > Retarget > Bone Map) point at these files.
## It also checks every mapped bone exists in a sample file of each rig.
##   Godot --headless --path <project> -s res://tools/make_bone_maps.gd

const OUT_DIR := "res://assets/animations/bone_maps/"
const MIXAMO_SAMPLE := "res://assets/mixamo/boy_happy.fbx"
const UE5_SAMPLE := "res://assets/animations/boy_pull_on_sweater.fbx"

const SIDES := {"Left": ["Left", "_l"], "Right": ["Right", "_r"]}


func _mixamo() -> Dictionary:
	var m := {
		"Hips": "mixamorig_Hips", "Spine": "mixamorig_Spine", "Chest": "mixamorig_Spine1",
		"UpperChest": "mixamorig_Spine2", "Neck": "mixamorig_Neck", "Head": "mixamorig_Head",
	}
	for side in ["Left", "Right"]:
		var s: String = "mixamorig_" + side
		m[side + "Shoulder"] = s + "Shoulder"
		m[side + "UpperArm"] = s + "Arm"
		m[side + "LowerArm"] = s + "ForeArm"
		m[side + "Hand"] = s + "Hand"
		m[side + "ThumbMetacarpal"] = s + "HandThumb1"
		m[side + "ThumbProximal"] = s + "HandThumb2"
		m[side + "ThumbDistal"] = s + "HandThumb3"
		for f in [["Index", "Index"], ["Middle", "Middle"], ["Ring", "Ring"], ["Little", "Pinky"]]:
			m[side + f[0] + "Proximal"] = s + "Hand" + f[1] + "1"
			m[side + f[0] + "Intermediate"] = s + "Hand" + f[1] + "2"
			m[side + f[0] + "Distal"] = s + "Hand" + f[1] + "3"
		m[side + "UpperLeg"] = s + "UpLeg"
		m[side + "LowerLeg"] = s + "Leg"
		m[side + "Foot"] = s + "Foot"
		m[side + "Toes"] = s + "ToeBase"
	return m


func _ue5() -> Dictionary:
	var m := {
		"Root": "root", "Hips": "pelvis", "Spine": "spine_01", "Chest": "spine_03",
		"UpperChest": "spine_05", "Neck": "neck_01", "Head": "head",
	}
	for side in ["Left", "Right"]:
		var x: String = SIDES[side][1]
		m[side + "Shoulder"] = "clavicle" + x
		m[side + "UpperArm"] = "upperarm" + x
		m[side + "LowerArm"] = "lowerarm" + x
		m[side + "Hand"] = "hand" + x
		m[side + "ThumbMetacarpal"] = "thumb_01" + x
		m[side + "ThumbProximal"] = "thumb_02" + x
		m[side + "ThumbDistal"] = "thumb_03" + x
		for f in [["Index", "index"], ["Middle", "middle"], ["Ring", "ring"], ["Little", "pinky"]]:
			m[side + f[0] + "Proximal"] = f[1] + "_01" + x
			m[side + f[0] + "Intermediate"] = f[1] + "_02" + x
			m[side + f[0] + "Distal"] = f[1] + "_03" + x
		m[side + "UpperLeg"] = "thigh" + x
		m[side + "LowerLeg"] = "calf" + x
		m[side + "Foot"] = "foot" + x
		m[side + "Toes"] = "ball" + x
	return m


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var ok := _save("mixamo_bone_map", _mixamo(), MIXAMO_SAMPLE)
	ok = _save("ue5_bone_map", _ue5(), UE5_SAMPLE) and ok
	print("make_bone_maps: ", "OK" if ok else "PROBLEMS (see above)")
	quit()


func _save(file: String, mapping: Dictionary, sample: String) -> bool:
	var profile := SkeletonProfileHumanoid.new()
	var bm := BoneMap.new()
	bm.profile = profile
	var ok := true
	var skel_bones := _bones_of(sample)
	for profile_bone in mapping:
		if profile.find_bone(profile_bone) < 0:
			push_error("%s: '%s' is not a humanoid profile bone" % [file, profile_bone])
			ok = false
			continue
		if not skel_bones.has(mapping[profile_bone]):
			push_error("%s: '%s' not found in %s" % [file, mapping[profile_bone], sample])
			ok = false
			continue
		bm.set_skeleton_bone_name(profile_bone, mapping[profile_bone])
	var err := ResourceSaver.save(bm, OUT_DIR + file + ".tres")
	print(file, ": mapped ", mapping.size(), " of ", profile.bone_size, " humanoid bones, save=", err)
	return ok and err == OK


func _bones_of(path: String) -> PackedStringArray:
	var s: Node = (load(path) as PackedScene).instantiate()
	var skel := ModelUtils.find_skeleton(s)
	var out := PackedStringArray()
	if skel:
		for b in skel.get_bone_count():
			out.append(skel.get_bone_name(b))
	s.free()
	return out
