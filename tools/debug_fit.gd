extends SceneTree
func _initialize() -> void:
	var r := ModelFit.load_fitted("res://assets/mixamo/player_idle.fbx", 1.75)
	root.add_child(r)
	var m: Node3D = r.get_child(0)
	print("size=", r.get_meta("size"), " model.scale=", m.scale, " model.pos=", m.position)
	var sk := ModelFit._find_skeleton(r)
	print("bones=", sk.get_bone_count(), " b0=", sk.get_bone_name(0), " rest0=", sk.get_bone_global_rest(0).origin)
	for b in [5, 10, 20, 40]:
		if b < sk.get_bone_count():
			print(sk.get_bone_name(b), " ", sk.get_bone_global_rest(b).origin)
	quit()
