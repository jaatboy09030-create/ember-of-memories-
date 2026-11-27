extends Node3D
## BLINK DEMO (root of scenes/prototypes/blink_demo.tscn): a playable prototype of a
## Before Your Eyes style blink mechanic, staged inside the real game (main.tscn, with
## the story switched off). Four memories (Beats), each seen from one spot:
##   Gate -> Living room (grandma knitting) -> Kid's room (the drawing) -> Leaving (suitcase)
##
## The rules of a blink (Eyelids reads the "blink" action: Space / left mouse / pad A):
##   1. Early in a memory a blink is SAFE: the lids close and open, nothing changes.
##   2. Reticle on the white EYE + blink = look closer: ghosts wake, the island blooms,
##      a voice line, colour and warmth come back. (The eye always wins over a skip.)
##   3. Once the METRONOME ticks, your next blink lets go: the memory is cut, mid-line if
##      needed, and you open your eyes somewhere else, years apart.
##   4. Keep your eyes CLOSED and you hear what the memory hides.
## Every swap happens while the lids are fully shut, so the cut is never seen.
##
## Run: Godot --path . res://scenes/prototypes/blink_demo.tscn
## Add `-- --blinkshots=<folder>` to play it automatically and save screenshots.
##
## How to change it: each Beat's Inspector (lines, timing, colour, closed-eyes sound),
## its Islands / EyeHotspot children, and the exports below.

@export var game: GameDirector
@export var memory_camera: MemoryCamera
@export var memory_void: MemoryVoid
@export var eyelids: Eyelids
@export var blink_ui: BlinkUI
@export var caption: BlinkCaption
@export var title_card: BlinkCaption
@export var metronome_sound: AudioStreamPlayer
@export var lid_sound: AudioStreamPlayer
## Cards shown one after another on black before the first memory.
@export_multiline var intro_cards: Array[String] = []
## Seconds each intro card stays.
@export var intro_card_time := 4.0
## Seconds for the eyes to open on the first memory (waking up).
@export var first_open_time := 3.0
## Seconds of black between two memories.
@export var cut_black_time := 0.4
## Dialogue pace: voice playback speed (same pitch) and line timing multiplier (< 1 = sooner).
@export var voice_speed := 1.12
@export var line_pace := 0.85
## After this long with the metronome ticking, the eyes start to get heavy.
@export var heavy_eyes_after := 14.0
## Music under the demo (assets/audio name, "" = none).
@export var music := "theme_broken"

@onready var beats_root: Node3D = $Beats

var beats: Array[MemoryBeat] = []
var index := -1
var beat_time := 0.0
var armed := false
var _armed_time := 0.0
var _cutting := false
var _closed_played := false
var _finished := false
var _can_restart := false
var _line_tween: Tween
var _said := 0  # how many of the current beat's lines have started
var _talk_end := 0.0  # beat_time when the current beat's last line ends
var _listen_leaked := false  # this beat's hidden sound has leaked through once
var _listen_hints_shown := 0  # beats that showed the "hold" eye so far
var _colour_tween: Tween
var _closed_tween: Tween
var _closed_index := 0
var _montage_index := 0
var _lines_done := false
var _first_blink_done := false
var _shots_dir := ""


func _exit_tree() -> void:
	Sound.voice_speed = 1.0


func _ready() -> void:
	Sound.voice_speed = voice_speed
	for b in beats_root.get_children():
		if b is MemoryBeat:
			beats.append(b)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--blinkshots="):
			_shots_dir = a.trim_prefix("--blinkshots=")
	_quiet_the_game()
	eyelids.shut.connect(_on_eyes_shut)
	eyelids.held_closed.connect(_on_eyes_held_closed)
	eyelids.opened.connect(_on_eyes_opened)
	blink_ui.metronome_tick.connect(metronome_sound.play)
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	memory_camera.make_current()
	if music != "":
		Sound.play_music(music, -16.0, 3.0)
	if "--blinknovoid" in OS.get_cmdline_user_args():  # debug: see the whole room, no black void
		memory_void.visible = false
	if "--blinkcheck" in OS.get_cmdline_user_args():
		_check_figures()
	elif _shots_dir != "":
		_autoplay()
	else:
		_intro()


## The main scene is used only as the place: no story, no player, no HUD, no title.
func _quiet_the_game() -> void:
	game.hud.visible = false
	game.title_sequence.visible = false
	for layer in game.title_sequence.find_children("*", "CanvasLayer", true, false):
		(layer as CanvasLayer).visible = false
	game.player.process_mode = Node.PROCESS_MODE_DISABLED
	memory_camera.cull_mask = game.player.cam.cull_mask  # never see the player's own body
	game.ember.visible = false


func _intro() -> void:
	eyelids.forced_closed = true
	await _wait(1.0)
	for card in intro_cards:
		title_card.say(card, intro_card_time - 1.5)
		await _wait(intro_card_time)
	_enter_beat(0)
	await _wait(0.6)
	eyelids.enabled = true
	eyelids.open_slowly(first_open_time)


func _enter_beat(i: int) -> void:
	if index >= 0:
		beats[index].leave()
	index = i
	var b := beats[i]
	b.enter()
	memory_camera.place(b.camera_point.global_position, b.look_target.global_position)
	var cp := b.camera_point.global_position
	game.player.global_position = Vector3(cp.x, 0.1, cp.z)  # ambience + snow follow "you"
	_set_colour_tween(null)
	game.screen_effects.world_saturation = b.saturation
	if b.drain_to >= 0.0:
		_set_colour_tween(game.screen_effects.fade_saturation(b.drain_to, b.drain_time))
	blink_ui.hotspot = b.hotspot
	blink_ui.metronome_on = false
	eyelids.set_flutter(0.0)
	armed = false
	beat_time = 0.0
	_armed_time = 0.0
	_closed_played = false
	_closed_index = 0
	_listen_leaked = false
	blink_ui.listen_on = false
	_montage_index = 0
	_first_blink_done = false
	for n in b.montage_show:
		if n:
			n.visible = false
	_lines_done = b.lines.is_empty()
	if b.music == "none":
		Sound.play_music("", -16.0, 2.0)
	elif b.music != "keep":
		Sound.play_music(b.music, -14.0, 2.5)
	if b.ember_point:
		game.ember.visible = true
		game.ember.scale = Vector3.ONE
		game.ember.global_position = b.ember_point.global_position
		game.ember.wait_at(b.ember_point.global_position)
	else:
		game.ember.visible = false
	_play_lines(b)


## Only one colour change runs at a time (a slow drain must not leak into the next memory).
func _set_colour_tween(tw: Tween) -> void:
	if _colour_tween and _colour_tween.is_valid():
		_colour_tween.kill()
	_colour_tween = tw


func _play_lines(b: MemoryBeat) -> void:
	if _line_tween:
		_line_tween.kill()
	_line_tween = create_tween()
	var t := 0.0
	var free_at := 0.0  # when the previous spoken line ends
	_said = 0
	# beats with timed cues (door, steps, engine) keep their written timing so lines stay in sync
	var pace := line_pace
	for c in b.get_children():
		if c is BeatCue:
			pace = 1.0
	for k in b.lines.size():
		var at: float = (b.line_times[k] if k < b.line_times.size() else t + 3.5) * pace
		at = maxf(at, free_at)  # never talk over the previous line
		_line_tween.tween_interval(maxf(0.0, at - t))
		_line_tween.tween_callback(func():
			_said = k + 1
			caption.say(b.lines[k], 3.2))
		t = at
		free_at = at + BlinkCaption.voice_length(b.lines[k]) + 0.3
	_talk_end = free_at - 0.3  # when the last line finishes being said
	_line_tween.tween_interval(3.0)
	_line_tween.tween_callback(func(): _lines_done = true)


func _process(delta: float) -> void:
	if _finished:
		if _can_restart and Input.is_action_just_pressed("blink"):
			get_tree().reload_current_scene()
		return
	if index < 0:
		return
	var b := beats[index]
	memory_void.show_islands(b.islands())
	if _cutting:
		return
	beat_time += delta
	if b.auto_end_after > 0.0 and beat_time >= b.auto_end_after:
		_cut()
		return
	var eye_done := b.hotspot == null or b.hotspot.used or not b.wait_for_hotspot
	if b.wait_for_closed_lines and _closed_index < b.closed_eyes_lines.size():
		eye_done = false
	# never offer the blink while someone is still talking (ok in the last ~0.35 s of the last line)
	var talk_done := beat_time >= _talk_end - 0.35 and Sound.voice_time_left() <= 0.35
	_update_listen_hint(b, talk_done)
	if not armed and talk_done and beat_time >= b.protect_time and (eye_done or beat_time >= b.max_wait):
		armed = true
		blink_ui.metronome_on = true
	if armed:
		_armed_time += delta
		var heavy := b.heavy_eyes_after if b.heavy_eyes_after >= 0.0 else heavy_eyes_after
		if _armed_time > heavy:
			eyelids.set_flutter(0.22 * (0.5 + 0.5 * sin(_armed_time * 1.7)))


## Something is waiting behind closed eyes in this beat and hasn't been heard yet: show the
## "hold" eye, and let a faint leak of it through (the murmur behind the door, steps outside).
func _update_listen_hint(b: MemoryBeat, talk_done: bool) -> void:
	var hidden := b.closed_eyes_sound != "" or b.closed_eyes_caption != "" or b.closed_eyes_lines.size() > 0
	var unheard := not _closed_played or _closed_index < b.closed_eyes_lines.size()
	var show := hidden and unheard and talk_done and eyelids.closure < 0.5 \
		and beat_time >= minf(b.protect_time, 4.0)
	blink_ui.listen_on = show
	blink_ui.listen_words = _listen_hints_shown < 3  # the word only until you've got it
	if show and not _listen_leaked:
		_listen_leaked = true
		_listen_hints_shown += 1
		var leak := b.closed_eyes_sound
		if b.closed_eyes_lines.size() > 0:
			var v := BlinkCaption.voice_for(b.closed_eyes_lines[0])
			if v != "":
				leak = v
		if leak != "" and not leak.begins_with("@"):
			Sound.play(leak, -26.0)  # barely there: you'd have to close your eyes to hear it


## The lids just closed fully. Decide what this blink does.
func _on_eyes_shut() -> void:
	lid_sound.play()
	if _cutting or _finished or index < 0:
		return
	var b := beats[index]
	if not _first_blink_done:  # what was there before you blinked, isn't
		_first_blink_done = true
		for n in b.first_blink_hide:
			if n:
				n.visible = false
		for n in b.first_blink_show:
			if n:
				n.visible = true
	if blink_ui.hovering and b.hotspot and b.hotspot.is_active():
		_look_closer(b.hotspot)
	elif b.montage_lines.size() > 0 and _montage_index < b.montage_lines.size() and beat_time >= b.protect_time:
		_montage_step(b)
	elif armed:
		_cut()


## Montage: one blink, one step forward (a year gone). The islands shrink a little each time.
func _montage_step(b: MemoryBeat) -> void:
	var n := b.montage_lines.size()
	if _line_tween:
		_line_tween.kill()
	caption.say(b.montage_lines[_montage_index], 0.0)
	if _montage_index < b.montage_show.size():
		if _montage_index > 0 and b.montage_show[_montage_index - 1]:
			b.montage_show[_montage_index - 1].visible = false
		if b.montage_show[_montage_index]:
			b.montage_show[_montage_index].visible = true
	_montage_index += 1
	_play_sound(b.montage_sound, -6.0)
	var left := 1.0 - 0.6 * float(_montage_index) / float(n)
	for island in b.islands():
		if not island.hidden_at_start:
			island.wither(left, 0.25)
	if game.ember.visible:
		create_tween().tween_property(game.ember, "scale", Vector3.ONE * maxf(0.25, left), 0.25)
	_set_colour_tween(game.screen_effects.fade_saturation(b.saturation * left, 0.25))
	_armed_time = 0.0


## Blinked at the eye: the memory comes back while the lids are shut.
func _look_closer(h: EyeHotspot) -> void:
	h.trigger()
	game.screen_effects.remember()
	if h.voice != "":
		Sound.play(h.voice)
	if h.caption != "":
		caption.say(h.caption, 3.8)
	if h.saturation_after >= 0.0:
		_set_colour_tween(game.screen_effects.fade_saturation(h.saturation_after, 2.0))
	if h.warm_room_id != "" and game.rooms.has(h.warm_room_id):
		game.rooms[h.warm_room_id].warm_up()
	if h.warm_all_rooms:
		for r in game.rooms.values():
			r.warm_up(1.8)
	if h.music != "":
		Sound.play_music(h.music, -8.0, 2.0)
	if h.ember_goes_here and game.ember.visible:
		game.ember.wait_at(h.global_position)
	if h.clear_void:
		var tw := create_tween()
		tw.tween_interval(1.0)
		tw.tween_method(memory_void.set_fade, 1.0, 0.0, 6.0).set_trans(Tween.TRANS_SINE)
	game.screen_effects.warm_flash()


## Let go of this memory: everything changes behind the closed lids.
func _cut() -> void:
	_cutting = true
	blink_ui.metronome_on = false
	blink_ui.listen_on = false
	eyelids.set_flutter(0.0)
	eyelids.forced_closed = true
	if _line_tween:
		_line_tween.kill()
	var b := beats[index]
	var heard := Sound.voice_progress()
	if b.final_beat:
		caption.cut()
	elif _said > 0 and heard >= 0.0 and heard < 0.9:  # blinked over someone talking
		caption.interrupt(b.lines[_said - 1], heard)
	elif _said < b.lines.size():  # blinked just before the next line
		caption.interrupt(b.lines[_said])
	else:
		caption.cut()
	if b.final_beat:
		_ending(b)
		return
	await get_tree().create_timer(cut_black_time).timeout
	var next := beats[index + 1]
	if next.time_card != "":  # a jump in time, said in the dark
		title_card.say(next.time_card, 1.8)
		await _wait(3.0)
	_enter_beat(index + 1)
	await get_tree().process_frame
	eyelids.forced_closed = false
	_cutting = false


## Eyes kept shut: the sound (once), then the hidden lines, one by one, for as long as
## they stay shut. They pick up where they stopped next time.
func _on_eyes_held_closed() -> void:
	if _cutting or _finished or index < 0:
		return
	var b := beats[index]
	if not _closed_played:
		_closed_played = true
		_play_sound(b.closed_eyes_sound, -4.0)
		if b.closed_eyes_caption != "" and b.closed_eyes_lines.is_empty():
			caption.say(b.closed_eyes_caption, 3.5)
	if _closed_index >= b.closed_eyes_lines.size():
		return
	if _line_tween:
		_line_tween.kill()
	if _closed_tween:
		_closed_tween.kill()
	_closed_tween = create_tween()
	for k in range(_closed_index, b.closed_eyes_lines.size()):
		_closed_tween.tween_callback(func():
			caption.say(b.closed_eyes_lines[k], 2.4)
			if k < b.closed_eyes_line_sounds.size():
				_play_sound(b.closed_eyes_line_sounds[k], -3.0)
			_closed_index = k + 1)
		_closed_tween.tween_interval(maxf(3.0, BlinkCaption.voice_length(b.closed_eyes_lines[k]) + 0.4))
	if b.closed_lines_done_caption != "":
		_closed_tween.tween_callback(caption.say.bind(b.closed_lines_done_caption, 4.0))


## "name" = assets/audio file, "@Name" = a SynthTone node under BlinkDemo, "" = nothing.
func _play_sound(sound_name: String, volume_db := 0.0) -> void:
	if sound_name == "":
		return
	if sound_name.begins_with("@"):
		var p := get_node_or_null(sound_name.substr(1)) as AudioStreamPlayer
		if p:
			p.play()
	else:
		Sound.play(sound_name, volume_db)


func _on_eyes_opened() -> void:
	if _closed_tween and _closed_tween.is_valid():
		_closed_tween.kill()
		caption.cut()


func _ending(b: MemoryBeat) -> void:
	_finished = true
	eyelids.enabled = false
	var blinked := not _lines_done and not b.ending_lines_if_blinked.is_empty()
	b.leave()
	await get_tree().create_timer(1.6).timeout
	for line in (b.ending_lines_if_blinked if blinked else b.ending_lines):
		caption.say(line, 2.6)
		await get_tree().create_timer(maxf(3.8, BlinkCaption.voice_length(line) + 0.8)).timeout
	title_card.say("UNSENT", 0.0)
	await get_tree().create_timer(3.0).timeout
	title_card.say("UNSENT\n\nblink to remember again", 0.0)
	_can_restart = true


# ---------------------------------------------------------------- placement check

## `-- --blinkcheck`: every ghost figure must stand on the floor and not pass through
## furniture or walls. Prints one CHECK line per figure, then quits.
func _check_figures() -> void:
	for k in 3:
		await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	var bad := 0
	for f in find_children("*", "MemoryFigure", true, false):
		var fig := f as MemoryFigure
		var skel := ModelUtils.find_skeleton(fig.character)
		if not skel:
			continue
		# posed body: hips, spine, neck, head and legs (not arms or fingers)
		var box := AABB()
		var first := true
		for i in skel.get_bone_count():
			var bn := skel.get_bone_name(i).to_lower()
			if "arm" in bn or "hand" in bn or "finger" in bn or "thumb" in bn or "index" in bn or "shoulder" in bn:
				continue
			var p := skel.global_transform * skel.get_bone_global_pose(i).origin
			if first:
				box = AABB(p, Vector3.ZERO)
				first = false
			else:
				box = box.expand(p)
		if first:
			continue
		box = box.grow(0.08)  # flesh around the bones
		var core := box
		core.position.y += 0.2  # the feet may touch the floor
		core.size.y -= 0.2
		if fig.seat_point:  # a sitting figure rests on its seat
			core.position.y += 0.35
			core.size.y = maxf(0.1, core.size.y - 0.35)
		var q := PhysicsShapeQueryParameters3D.new()
		var shape := BoxShape3D.new()
		shape.size = core.size.max(Vector3.ONE * 0.05)
		q.shape = shape
		q.transform = Transform3D(Basis(), core.get_center())
		var hits := space.intersect_shape(q, 8)
		var names: PackedStringArray = []
		for h in hits:
			var c := h.collider as Node
			if c:
				names.append(String(c.get_parent().name) + "/" + String(c.name))
		var foot := Vector3(box.get_center().x, box.position.y + 0.08, box.get_center().z)
		var down := space.intersect_ray(PhysicsRayQueryParameters3D.create(foot + Vector3.UP * 0.3, foot + Vector3.DOWN * 0.6))
		var floor_gap := 9.9 if down.is_empty() else foot.y - 0.08 - (down.position as Vector3).y
		var ok := (names.is_empty() or fig.seat_point != null) and (fig.seat_point != null or absf(floor_gap) < 0.15)
		if not ok:
			bad += 1
			# suggest the nearest free spot (same height, within 1.5 m)
			var best := Vector3.INF
			for r in range(1, 16):
				for a in 16:
					var off := Vector3(cos(a * TAU / 16.0), 0, sin(a * TAU / 16.0)) * r * 0.1
					q.transform = Transform3D(Basis(), core.get_center() + off)
					if space.intersect_shape(q, 1).is_empty():
						best = fig.global_position + off
						break
				if best != Vector3.INF:
					break
			print("CHECK   free spot for ", fig.name, ": ", best.snapped(Vector3.ONE * 0.01))
		var shown := 0
		for mi in fig.find_children("*", "MeshInstance3D", true, false):
			var vm := mi as VisualInstance3D
			if (vm.layers & memory_camera.cull_mask) != 0:
				shown += 1
		print("CHECK ", fig.get_path().get_concatenated_names().right(60), "  ", "OK" if ok else "BAD", "  meshes_seen=", shown,
			"  feet_gap=%.2f" % floor_gap, "  box=", box.size.snapped(Vector3.ONE * 0.01), "  hits=", names)
	# props placed by the beats: each must rest on something (no floating, no sinking)
	for props in beats_root.find_children("Props", "Node3D", true, false):
		for n in props.get_children():
			if not (n is Node3D) or n is MemoryFigure or n is Light3D:
				continue
			var box := AABB()
			var first := true
			for mi in (n as Node).find_children("*", "MeshInstance3D", true, false) + ([n] if n is MeshInstance3D else []):
				var m := mi as MeshInstance3D
				if not m.mesh:
					continue
				var a := m.global_transform * m.get_aabb()
				box = a if first else box.merge(a)
				first = false
			if first or box.size.y > 2.5:
				continue
			var c := box.get_center()
			if absf(box.size.y) < 0.02 and absf(c.y - 1.5) < 0.6:
				continue  # flat on a wall (calendar)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(c.x, box.position.y + 0.25, c.z), Vector3(c.x, box.position.y - 1.0, c.z)))
			var gap := 9.9 if hit.is_empty() else box.position.y - (hit.position as Vector3).y
			var on := "" if hit.is_empty() else String((hit.collider as Node).get_parent().name)
			if on == "SnowGround" and box.position.y < 0.2:
				gap -= 0.06  # room floors are visual boxes 6 cm thick with no collider
			var ok := absf(gap) < 0.04 or n.name in ["StreetLamp", "Wreck"]
			if not ok:
				bad += 1
			print("CHECK prop ", n.get_path().get_concatenated_names().right(55), "  ", "OK" if ok else "BAD", "  gap=%.3f" % gap,
				"  rests_on=", "nothing" if hit.is_empty() else String((hit.collider as Node).get_parent().name))
	print("CHECK done, bad=", bad)
	get_tree().quit()


# ---------------------------------------------------------------- automatic run (screenshots)

func _autoplay() -> void:
	DirAccess.make_dir_recursive_absolute(_shots_dir)
	blink_ui.set_process_input(false)  # a real mouse over the window must not steer the test
	eyelids.forced_closed = true
	var first := 0
	var last := beats.size() - 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--blinkonly="):  # only this beat (by node name), then quit
			for k in beats.size():
				if beats[k].name == a.trim_prefix("--blinkonly="):
					first = k
					last = k
	_enter_beat(first)
	eyelids.open_slowly(0.3)
	for i in range(first, last + 1):
		while _cutting:
			await _wait(0.1)
		var b := beats[i]
		await _wait(2.4)
		_shot("%d_%s_a_open" % [i, b.name])
		if b.closed_eyes_lines.size() > 0:  # keep the eyes shut and listen
			eyelids.forced_closed = true
			await _wait(eyelids.hold_time + 1.6)
			_shot("%d_%s_closed_eyes" % [i, b.name])
			await _wait(3.0 * b.closed_eyes_lines.size() + 1.5)
			eyelids.forced_closed = false
			await _wait(0.5)
		for k in b.montage_lines.size():
			await _wait(maxf(0.0, b.protect_time - beat_time) + 0.2)
			await _blink()
			await _wait(1.2)
			_shot("%d_%s_m%d_montage" % [i, b.name, k])
		if b.hotspot:
			await _wait(maxf(0.0, b.hotspot.appear_after - 2.4) + 0.3)
			# the view leans toward the reticle, so keep re-aiming until it settles
			for k in 40:
				blink_ui.cursor = memory_camera.unproject_position(b.hotspot.global_position)
				await get_tree().process_frame
			_shot("%d_%s_b_eye" % [i, b.name])
			await _blink()
			await _wait(3.2)
			_shot("%d_%s_c_restored" % [i, b.name])
		blink_ui.cursor = get_viewport().get_visible_rect().size * Vector2(0.3, 0.45)
		if b.final_beat and b.auto_end_after > 0.0:  # don't blink: watch it to the end
			await _wait(b.auto_end_after * 0.6)
			_shot("%d_%s_d_dont_blink" % [i, b.name])
			while not _finished:
				await _wait(0.2)
			break
		while not armed:
			await _wait(0.2)
		await _wait(1.2)
		_shot("%d_%s_d_metronome" % [i, b.name])
		eyelids.set_flutter(0.6)  # lids half shut, to see their shape
		await _wait(0.5)
		_shot("%d_%s_e_closing" % [i, b.name])
		eyelids.set_flutter(0.0)
		await _blink()
		await _wait(0.8)
	await _wait(6.0)
	_shot("9_ending")
	print("BLINKDEMO done, screenshots in ", _shots_dir)
	get_tree().quit()


func _blink() -> void:
	eyelids.forced_closed = true
	await _wait(0.12)
	if not _cutting:
		eyelids.forced_closed = false
	await _wait(0.25)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_shots_dir.path_join(label + ".png"))
	print("BLINKDEMO shot ", label, " beat=", index, " armed=", armed, " sat=", game.screen_effects.world_saturation)
