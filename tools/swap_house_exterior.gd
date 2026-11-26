extends SceneTree
## ONE-OFF TOOL: puts the Blender-built two-storey house (assets/house/house_exterior.glb, made
## from the Tripo parts in Blender) around the existing rooms in scenes/level/house_level.tscn.
##   - adds House/ExteriorShell (SnowyProp: grey while frozen, snow on the roof and sills)
##   - hides the old outer wall meshes (their collision stays, so the player can't walk out)
##   - removes the old roof, gables and box chimney, and the old porch meshes
##   - moves the porch lamp onto the new lantern, adds colliders for the new porch posts
## Safe to run once; running again just reports that the shell is already there.
##   Godot --headless --path <project> -s res://tools/swap_house_exterior.gd

const LEVEL := "res://scenes/level/house_level.tscn"
const SHELL := "res://assets/house/house_exterior.glb"
const SNOWY_PROP := "res://scripts/level/snowy_prop.gd"


func _initialize() -> void:
	var root: Node3D = (load(LEVEL) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var house := root.get_node("House")
	if house.has_node("ExteriorShell"):
		print("swap_house_exterior: already done")
		quit()
		return
	# new shell
	var shell := Node3D.new()
	shell.name = "ExteriorShell"
	shell.set_script(load(SNOWY_PROP))
	shell.set("snow_amount", 0.75)
	house.add_child(shell)
	shell.owner = root
	var model: Node3D = (load(SHELL) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	model.name = "Model"
	shell.add_child(model)
	model.owner = root
	# old outer walls: invisible, still solid
	for w in house.get_node("OuterWalls").find_children("*", "MeshInstance3D", true, false):
		(w as MeshInstance3D).visible = false
	# old roof, gables, chimney
	_free(house.get_node("Roof"))
	# old porch meshes (keep the walk-up ramp and the lamp light)
	var porch := root.get_node("Exterior/Porch")
	for n in ["PorchStepLower", "PorchStepUpper", "PorchRoof", "PorchPostLeft", "PorchPostRight", "PorchLantern"]:
		if porch.has_node(n):
			_free(porch.get_node(n))
	var lamp := porch.get_node("PorchLanternLight") as OmniLight3D
	lamp.position = Vector3(1.1, 1.85, 0.4)
	# the Tripo porch: posts at its front corners, roof ~3 m
	var posts := StaticBody3D.new()
	posts.name = "PorchPosts"
	porch.add_child(posts)
	posts.owner = root
	for side in [-1.0, 1.0]:
		var cs := CollisionShape3D.new()
		cs.name = "Post" + ("Left" if side < 0 else "Right")
		var b := BoxShape3D.new()
		b.size = Vector3(0.2, 2.8, 0.2)
		cs.shape = b
		cs.position = Vector3(1.55 * side, 1.4, 1.6)
		posts.add_child(cs)
		cs.owner = root
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err == OK:
		err = ResourceSaver.save(ps, LEVEL)
	print("swap_house_exterior: ", "OK" if err == OK else "FAILED %d" % err)
	root.free()
	quit()


func _free(n: Node) -> void:
	n.get_parent().remove_child(n)
	n.free()
