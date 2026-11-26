extends SceneTree
## One-off tool: paints the child's crayon drawing (house, sun, parent and child holding
## hands, red scarf) and saves it as assets/textures/kids_drawing/kids_drawing.png.
## The puzzle and the wall drawing use that PNG. Replace the PNG with a real drawing any time.
##   Godot --headless --path <project> -s res://tools/make_kids_drawing.gd

const OUT := "res://assets/textures/kids_drawing/kids_drawing.png"


func _initialize() -> void:
	var img := Image.create(384, 384, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.97, 0.95, 0.88))
	# sun, grass, house
	img.fill_rect(Rect2i(300, 24, 56, 56), Color(1.0, 0.8, 0.15))
	img.fill_rect(Rect2i(0, 236, 384, 148), Color(0.35, 0.65, 0.3))
	img.fill_rect(Rect2i(36, 140, 96, 96), Color(0.85, 0.35, 0.25))
	img.fill_rect(Rect2i(66, 180, 30, 56), Color(0.4, 0.25, 0.15))
	for i in 48:
		img.fill_rect(Rect2i(36 + i * 2, 140 - i, 2, i * 2 if i < 24 else (96 - i * 2)), Color(0.45, 0.2, 0.15))
	# parent (tall) and child (small, red scarf) holding hands
	img.fill_rect(Rect2i(200, 110, 28, 28), Color(0.95, 0.8, 0.65))
	img.fill_rect(Rect2i(194, 138, 40, 70), Color(0.3, 0.45, 0.85))
	img.fill_rect(Rect2i(198, 208, 10, 30), Color(0.2, 0.2, 0.3))
	img.fill_rect(Rect2i(220, 208, 10, 30), Color(0.2, 0.2, 0.3))
	img.fill_rect(Rect2i(258, 160, 22, 22), Color(0.95, 0.8, 0.65))
	img.fill_rect(Rect2i(252, 182, 34, 10), Color(0.85, 0.1, 0.1))
	img.fill_rect(Rect2i(254, 192, 30, 30), Color(0.95, 0.75, 0.2))
	img.fill_rect(Rect2i(256, 222, 8, 16), Color(0.2, 0.2, 0.3))
	img.fill_rect(Rect2i(274, 222, 8, 16), Color(0.2, 0.2, 0.3))
	img.fill_rect(Rect2i(234, 176, 22, 5), Color(0.95, 0.8, 0.65))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := img.save_png(OUT)
	print("make_kids_drawing: ", "OK" if err == OK else "FAILED %d" % err)
	quit()
