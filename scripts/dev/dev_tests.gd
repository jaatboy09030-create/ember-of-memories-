extends Node
## DEV TESTS: automatic checks that only run when the game is started with a test flag.
## Normal play never touches this node. Run from a terminal in the project folder:
##   Godot --path . -- --storytest   plays every memory automatically and reports each step
##   Godot --path . -- --walktest    walks from the path through the front door (add --gate
##                                   to start outside the gate)
##   Godot --path . -- --doortest    opens/closes the front door and checks it stays put
## Add --headless before --path to run without a window. Lines starting with TEST are results.

const FLAGS := ["--storytest", "--walktest", "--doortest"]

var game: GameDirector


func wants_to_run() -> bool:
	for f in FLAGS:
		if f in OS.get_cmdline_user_args():
			return true
	return false


func run(game_director: GameDirector) -> void:
	game = game_director
	await get_tree().process_frame
	game.title_sequence.skip(game)
	var args := OS.get_cmdline_user_args()
	if "--storytest" in args:
		await _story_test()
	elif "--walktest" in args:
		await _walk_test("--gate" in args)
	elif "--doortest" in args:
		await _door_test()
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
