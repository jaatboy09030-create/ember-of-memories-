extends SceneTree
func _initialize() -> void:
	var scene: PackedScene = load("res://assets/mixamo/player_idle.fbx")
	var m: Node3D = scene.instantiate()
	root.add_child(m)
	_dump(m, 0)
	quit()
func _dump(n: Node, d: int) -> void:
	var s := "  ".repeat(d) + n.name + " (" + n.get_class() + ")"
	if n is Node3D:
		s += " pos=" + str((n as Node3D).position) + " scale=" + str((n as Node3D).scale) + " rot=" + str((n as Node3D).rotation_degrees)
	if n is MeshInstance3D:
		s += " aabb=" + str((n as MeshInstance3D).get_aabb()) + " skel=" + str((n as MeshInstance3D).skeleton)
	if d < 4:
		print(s)
	for c in n.get_children():
		_dump(c, d + 1)
