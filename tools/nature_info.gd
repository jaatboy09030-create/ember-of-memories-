extends SceneTree
const DIR := "res://assets/stylised assets/stylised assets/Stylized_Nature_MegaKitStandard/glTF/"
func _initialize() -> void:
	for n in ["Pine_1","Pine_2","Pine_3","Pine_4","Pine_5","DeadTree_1","DeadTree_3","TwistedTree_1","CommonTree_1","Bush_Common","Fern_1","Plant_1","Rock_Medium_1","Rock_Medium_2","Pebble_Round_1","Grass_Wispy_Tall","Grass_Common_Short","Mushroom_Common"]:
		var path: String = DIR + n + ".gltf"
		if not ResourceLoader.exists(path):
			print("MISSING ", n); continue
		var root := ModelFit.load_native(path)
		var tris := 0
		var mats: Array = []
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			var m: Mesh = (mi as MeshInstance3D).mesh
			for si in m.get_surface_count():
				var arr := m.surface_get_arrays(si)
				var idx = arr[Mesh.ARRAY_INDEX]
				tris += (idx.size() / 3) if idx else (arr[Mesh.ARRAY_VERTEX].size() / 3)
				var mat := m.surface_get_material(si)
				if mat is BaseMaterial3D:
					var b := mat as BaseMaterial3D
					mats.append("%s[tr=%d tex=%s cull=%d]" % [b.resource_name, b.transparency, b.albedo_texture.resource_path.get_file() if b.albedo_texture else "-", b.cull_mode])
		print(n, " size=", root.get_meta("size"), " tris=", tris, " ", mats)
		root.free()
	quit()
