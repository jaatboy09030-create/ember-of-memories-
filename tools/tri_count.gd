extends SceneTree
func _initialize() -> void:
	var dir := DirAccess.open("res://assets/polyhaven")
	var rows: Array = []
	for d in dir.get_directories():
		var path := "res://assets/polyhaven/%s/%s.gltf" % [d, d]
		if not ResourceLoader.exists(path):
			continue
		var inst: Node = (load(path) as PackedScene).instantiate()
		var tris := 0
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var m: Mesh = (mi as MeshInstance3D).mesh
			if m:
				for si in m.get_surface_count():
					var arr := m.surface_get_arrays(si)
					var idx = arr[Mesh.ARRAY_INDEX]
					tris += (idx.size() / 3) if idx else (arr[Mesh.ARRAY_VERTEX].size() / 3)
		rows.append([tris, d])
		inst.free()
	rows.sort_custom(func(a, b): return a[0] > b[0])
	for r in rows.slice(0, 30):
		print("TRIS ", r[0], " ", r[1])
	quit()
