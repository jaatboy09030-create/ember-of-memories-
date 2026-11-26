extends Node
## DEV TESTS: automatic checks that only run when the game is started with a test flag.
## Normal play never touches this node. Run from a terminal in the project folder:
##   Godot --path . -- --storytest   plays every memory automatically and reports each step
##   Godot --path . -- --walktest    walks from the path through the front door (add --gate
##                                   to start outside the gate)
##   Godot --path . -- --doortest    opens/closes the front door and checks it stays put
##   Godot --path . -- --titleshot   plays the opening and screenshots it (_shots/o*.png)
##   Godot --path . -- --tour        screenshots the house and garden from set spots
##                                   (saved to _shots/t*.png; needs a window)
##   Godot --path . -- --embershot   screenshots the burning ember resting and in flight
##                                   (saved to _shots/e1_rest, e2_moving, e3_settle; needs a window)
##   Godot --path . -- --phototest   skips to memory 5, plays the photo cutscene and saves a
##                                   screenshot every second to user://phototest/ (needs a
##                                   window: no --headless)
## Add --headless before --path to run without a window. Lines starting with TEST are results.

const FLAGS := ["--storytest", "--walktest", "--doortest", "--embershot", "--tour", "--titleshot", "--phototest"]

var game: GameDirector


func wants_to_run() -> bool:
	for f in FLAGS:
		if f in OS.get_cmdline_user_args():
			return true
	return false


func run(game_director: GameDirector) -> void:
	game = game_director
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	if "--titleshot" in args:
		await _title_shot()
		get_tree().quit()
		return
	game.title_sequence.skip(game)
	if "--storytest" in args:
		await _story_test()
	elif "--walktest" in args:
		await _walk_test("--gate" in args)
	elif "--doortest" in args:
		await _door_test()
	elif "--embershot" in args:
		await _ember_shot()
	elif "--tour" in args:
		await _tour()
	elif "--phototest" in args:
		await _photo_test()
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Teleport the player to `stand`, look at `target`, and report what the raycast sees.
func _check_ray(stand: Vector3, target: Vector3, expected: String) -> void:
	var player: PlayerBody = game.player
	player.global_position = stand
	player.face_towards(target)
	var d := target - player.head_position()
	player.target_pitch = atan2(d.y, Vector2(d.x, d.z).length())
	player.pitch = player.target_pitch
	await _wait(0.3)
	var ray: RayCast3D = player.interaction_raycast
	var t: Interactable = ray.current_target
	var got := String(t.name) if t else "nothing"
	print("TEST ray at ", expected, ": ", got, "  ", "PASS" if got == expected else "FAIL")
	if got != expected:
		var c := ray.get_collider() as Node
		print("     ray enabled=", ray.enabled, " collider=", c.get_path() if c else "none",
			" from=", ray.global_position, " to=", ray.to_global(ray.target_position))


func _story_test() -> void:
	game.start_story()
	for m in game.memories:
		var memory: Memory = m
		print("TEST begin ", memory.name)
		await _wait(2.0)  # let the previous memory's camera glance finish
		match String(memory.name):
			"ScarfMemory":
				await _check_ray(Vector3(0.95, 0.1, -1.6), Vector3(0.95, 1.0, -0.42), "ScarfCoatRack")
			"DoorMemory":
				await _check_ray(Vector3(-0.75, 0.1, -7.7), Vector3(-0.75, 1.1, -8.84), "StudyDoor")
			"PhotoMemory":
				await _check_ray(Vector3(-5.0, 0.1, -8.1), Vector3(-3.9, 1.17, -8.1), "PhotoFrame")
			"FireplaceMemory":
				await _check_ray(Vector3(-5.2, 0.1, -5.75), Vector3(-6.4, 0.6, -5.75), "Fireplace")
		var done := [false]
		memory.completed.connect(func(): done[0] = true, CONNECT_ONE_SHOT)
		memory.debug_complete()
		var t := 0.0
		while not done[0] and t < 45.0:
			await get_tree().process_frame
			t += get_process_delta_time()
		print("TEST done  ", memory.name, " in ", snappedf(t, 0.1), "s  ", "PASS" if done[0] else "FAIL (timeout)")
	var open := []
	for id in game.doors:
		if game.doors[id].is_open:
			open.append(id)
	print("TEST doors open: ", open)
	print("TEST saturation at end: ", snappedf(game.screen_effects.world_saturation, 0.01))
	print("TEST story finished")


## Fast-forward to the photo memory, play its cutscene for real, save a frame every second.
func _photo_test() -> void:
	game.start_story()
	for m in game.memories:
		var memory: Memory = m
		if String(memory.name) == "PhotoMemory":
			await _wait(2.0)
			await _check_ray(Vector3(-5.0, 0.1, -8.1), Vector3(-3.9, 1.17, -8.1), "PhotoFrame")
			var done := [false]
			memory.completed.connect(func(): done[0] = true, CONNECT_ONE_SHOT)
			memory.debug_complete()
			DirAccess.make_dir_recursive_absolute("user://phototest")
			var t := 0
			while not done[0] and t < 45:
				await _wait(1.0)
				t += 1
				get_viewport().get_texture().get_image().save_png("user://phototest/shot_%02d.png" % t)
				var photo: PhotoFrame = memory.get_node("PhotoFrame")
				photo.reflection_viewport.get_texture().get_image().save_png("user://phototest/glass_%02d.png" % t)
			print("TEST photo cutscene ", t, "s  ", "PASS" if done[0] else "FAIL (timeout)")
			print("TEST shots in ", ProjectSettings.globalize_path("user://phototest"))
			return
		var done := [false]
		memory.completed.connect(func(): done[0] = true, CONNECT_ONE_SHOT)
		await _wait(0.5)
		memory.debug_complete()
		while not done[0]:
			await get_tree().process_frame


func _walk_test(from_gate: bool) -> void:
	var player: PlayerBody = game.player
	game.doors["front"].unlock_and_open()
	player.global_position = Vector3(0, 0.2, 15.0 if from_gate else 3.0)
	player.face_towards(Vector3(0, 0, -5))
	player.auto_input = Vector2(0, 1)
	# 7 s from the path; 10 s from the gate (16 m to get inside at walking speed)
	for i in (600 if from_gate else 420):
		await get_tree().physics_frame
		if i % 60 == 0:
			print("TEST walk t=", i / 60.0, "s z=", snappedf(player.global_position.z, 0.01), " y=", snappedf(player.global_position.y, 0.01))
	var z := player.global_position.z
	print("TEST walk end z=", snappedf(z, 0.01), "  ", "PASS (inside)" if z < -1.0 else "FAIL (stuck)")
	if not from_gate:
		var front: InteriorDoor = game.doors["front"]
		var shut := front.locked and not front.is_open
		print("TEST front door shut and locked behind the player: ", "PASS" if shut else "FAIL (locked=%s open=%s)" % [front.locked, front.is_open])


func _door_test() -> void:
	var player: PlayerBody = game.player
	var kid_door: InteriorDoor = game.doors["kid"]
	await _wait(1.0)  # let the slow first frames after loading pass
	kid_door.on_interact()
	var most := 0.0
	for i in 40:
		await get_tree().process_frame
		most = maxf(most, absf(kid_door.hinge.rotation.y))
	await _wait(0.5)
	var jerked := most > 0.001
	var settled := absf(kid_door.hinge.rotation.y) < 0.001
	print("TEST locked door rattles and stays shut: ", "PASS" if jerked and settled and kid_door.locked and not kid_door.is_open else "FAIL")
	var door: InteriorDoor = game.doors["front"]
	player.global_position = Vector3(0, 0.1, 1.2)
	door.unlock_and_open()
	await _wait(2.5)
	print("TEST door open after unlock: ", snappedf(rad_to_deg(door.hinge.rotation.y), 1))
	await _check_ray(Vector3(0, 0.1, 1.6), Vector3(0, 1.1, 0), "FrontDoor")
	door.on_interact()
	await _wait(2.0)
	print("TEST door after interact (close): ", snappedf(rad_to_deg(door.hinge.rotation.y), 1))
	door.on_interact()
	await _wait(2.0)
	print("TEST door after interact (open): ", snappedf(rad_to_deg(door.hinge.rotation.y), 1))
	player.global_position = Vector3(0, 0.1, -3.5)
	await _wait(3.0)
	print("TEST door after walking away (should stay open): ", snappedf(rad_to_deg(door.hinge.rotation.y), 1))
	await _one_way_door_test(door)


## The front door shuts behind you. Turning back while it closes reopens it (never onto you),
## but the OutsideBlocker still stops you walking out; walking away again shuts and locks it.
func _one_way_door_test(door: InteriorDoor) -> void:
	var player: PlayerBody = game.player
	player.global_position = Vector3(0, 0.1, 0.0)  # in the doorway
	for i in 10:
		await get_tree().physics_frame
	player.global_position = Vector3(0.2, 0.1, -2.6)  # inside and clear: it starts closing
	var t := 0
	while not door._closing_behind and t < 120:
		await get_tree().physics_frame
		t += 1
	print("TEST one-way door starts closing behind the player: ", "PASS" if door._closing_behind else "FAIL")
	for i in 15:
		await get_tree().physics_frame
	player.global_position = Vector3(0, 0.1, -0.2)  # turn back into the doorway mid-close
	for i in 10:
		await get_tree().physics_frame
	print("TEST it reopens instead of closing onto the player: ", "PASS" if door.is_open and not door.locked else "FAIL")
	player.face_towards(Vector3(0, 0, 10))
	player.auto_input = Vector2(0, 1)  # try to walk out
	for i in 90:
		await get_tree().physics_frame
	player.auto_input = Vector2.ZERO
	var z := player.global_position.z
	print("TEST player can't walk back out (z=", snappedf(z, 0.01), "): ", "PASS" if z < 0.65 else "FAIL")
	player.global_position = Vector3(0.2, 0.1, -2.6)
	await _wait(3.0)
	print("TEST it shuts and locks once they walk away: ", "PASS" if door.locked and not door.is_open else "FAIL")


## Close-up of the ember by the gate: resting, then swept sideways to show the trail.
func _ember_shot() -> void:
	var player: PlayerBody = game.player
	var ember: Ember = game.ember
	player.global_position = Vector3(0.0, 0.1, 12.0)
	player.face_towards(Vector3(0, 1.3, 0))
	ember.wait_at(Vector3(0, 1.5, 10.6))
	ember.global_position = ember.anchor
	await _wait(3.0)
	_save_shot("e1_rest")
	ember.anchor = Vector3.INF
	var t := create_tween()
	t.tween_property(ember, "global_position", Vector3(-1.3, 1.7, 10.6), 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(ember, "global_position", Vector3(1.2, 1.4, 10.6), 0.9).set_trans(Tween.TRANS_SINE)
	await t.finished
	_save_shot("e2_moving")
	t = create_tween()
	t.tween_property(ember, "global_position", Vector3(0.4, 1.6, 10.6), 0.5).set_trans(Tween.TRANS_SINE)
	await t.finished
	_save_shot("e3_settle")


func _save_shot(n: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://_shots"))
	get_viewport().get_texture().get_image().save_png("res://_shots/%s.png" % n)
	print("TEST shot ", n)


## Fixed viewpoints for judging the look: [name, stand, look at].
const TOUR := [
	["t1_lane", Vector3(0.6, 0.1, 17.5), Vector3(0, 3.5, 0)],
	["t2_garden", Vector3(-6.0, 0.1, 8.5), Vector3(-1.0, 3.0, 0)],
	["t3_porch", Vector3(0.4, 0.1, 3.6), Vector3(0, 1.6, 0)],
	["t4_side", Vector3(10.0, 0.1, 4.5), Vector3(3.0, 3.0, -4.0)],
	["t5_living", Vector3(1.5, 0.1, -3.6), Vector3(-1.0, 1.4, 0)],
	["t6_kidroom", Vector3(-3.6, 0.1, -3.6), Vector3(-7.5, 1.4, -1.0)],
	["t7_fireplace", Vector3(-3.0, 0.1, -6.0), Vector3(-7.5, 1.0, -5.75)],
]


func _tour() -> void:
	var player: PlayerBody = game.player
	for d in game.doors.values():
		d.unlock_and_open()
	for t in TOUR:
		player.global_position = t[1]
		player.face_towards(t[2])
		var dv: Vector3 = t[2] - player.head_position()
		player.target_pitch = atan2(dv.y, Vector2(dv.x, dv.z).length())
		player.pitch = player.target_pitch
		await _wait(1.6)
		_save_shot(t[0])


## The opening, frame by frame: writing, the window going dark, the title, the fall to the gate.
func _title_shot() -> void:
	var ts: TitleSequence = game.title_sequence
	ts.play(game)
	for k in [[4.0, "o1_writing"], [3.4, "o2_line_done"], [2.4, "o3_window_dark"], [5.5, "o4_title"]]:
		await _wait(k[0])
		_save_shot(k[1])
	while not ts._waiting_for_press:
		await get_tree().process_frame
	_save_shot("o5a_waiting")
	ts.continue_to_game()
	for k in [[2.5, "o5_fall"], [4.0, "o6_descend"], [3.0, "o7_eyes"]]:
		await _wait(k[0])
		_save_shot(k[1])
