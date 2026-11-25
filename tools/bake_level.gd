extends SceneTree
## Builds the level from scripts/main.gd and saves it as scenes/level.tscn
## (every wall, prop and light becomes a normal, editable node).
## Run:  Godot --headless --path <project> -s res://tools/bake_level.gd
## WARNING: overwrites scenes/level.tscn (any hand edits in it are lost).


func _initialize() -> void:
	var main: Node3D = load("res://scripts/main.gd").new()
	main.bake_mode = true
	main._build_exterior()
	main._build_house()
	main._build_rooms()
	main._place_props()
	var level := Node3D.new()
	level.name = "Level"
	for c in main.get_children():
		c.owner = null
		main.remove_child(c)
		level.add_child(c)
	_own(level, level)
	var ps := PackedScene.new()
	var err := ps.pack(level)
	if err == OK:
		err = ResourceSaver.save(ps, "res://scenes/level.tscn")
	main.free()
	print("bake_level: ", "OK" if err == OK else "FAILED %d" % err, " nodes=", _count(level))
	quit()


func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		if c.scene_file_path != "":
			continue  # instanced model (glTF): keep its insides as-is
		_own(c, owner_node)


func _count(n: Node) -> int:
	var t := 1
	for c in n.get_children():
		t += _count(c)
	return t
