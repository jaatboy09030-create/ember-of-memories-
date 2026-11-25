extends CharacterBody3D
## FIRST-PERSON grown child.
## The body exists (it casts shadows) but the first-person camera can't see it
## (visual layer 2 is culled). Only at the ending does the camera leave the body
## and turn round to show the face for the first time.

## Feel inspired by RE7/Village first person: heavy, slow, every step felt.
const WALK_SPEED := 1.75
const JOG_SPEED := 2.9
const EYE_HEIGHT := 1.62
const MOUSE_SENS := 0.0022
const LOOK_SMOOTH := 16.0   # higher = snappier; adds a little weight to the head
const ACCEL := 7.0

signal stepped(on_snow: bool)
const BODY_LAYER := 2  # visual layer bit used for the player's own body
const IDLE_PATH := "res://assets/mixamo/player_idle.fbx"
const WALK_PATH := "res://assets/mixamo/player_walk.fbx"

var can_move := true
var cam_locked := false
var look_scale := 1.0  # eased 0 -> 1 when control is handed over after a cinematic
var cam: Camera3D
var pivot: Node3D       # yaw: body + view direction (local +Z = forward)
var pitch := 0.0
var anim: AnimationPlayer
var skel: Skeleton3D
var bob_t := 0.0
var target_yaw := PI
var target_pitch := 0.0
var shake := 0.0            # camera shake amount (main.gd tweens it)
var roll := 0.0
var settle := 0.0           # small dip when you stop walking
var time := 0.0
var lean_to := Vector3.INF  # camera gently turns toward an interacted object
var lean_amt := 0.0
var breath_enabled := true
var auto_input := Vector2.ZERO  # dev: scripted walking for tests
var breath: GPUParticles3D
var _breath_timer := 2.0
var _last_step := 0.0


func _ready() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.25
	cap.height = 1.7
	col.shape = cap
	col.position.y = 0.85
	add_child(col)

	pivot = Node3D.new()
	pivot.rotation.y = PI  # start facing the house (-Z)
	add_child(pivot)
	var model: Node3D
	if ResourceLoader.exists(IDLE_PATH) and ResourceLoader.exists(WALK_PATH):
		# Mixamo exports stand on the origin at real scale (~1.8 m): no fitting needed.
		model = Node3D.new()
		var inner: Node3D = (load(IDLE_PATH) as PackedScene).instantiate()
		inner.scale = Vector3.ONE * (1.75 / 1.8)
		model.add_child(inner)
		ModelFit._fix_cull(inner)
		pivot.add_child(model)
		_setup_anims(model)
	else:
		model = ModelFit.load_fitted("res://assets/characters/father.glb", 1.75)
		pivot.add_child(model)
		ModelFit.relax_arms(model)
	# The faded red scarf: follows the neck bone when the character is animated.
	skel = ModelFit._find_skeleton(model)
	var neck := skel.find_bone("mixamorig_Neck") if skel else -1
	var scarf_parent: Node3D = pivot
	var base := Vector3(0, 1.43, 0)
	if neck >= 0:
		var att := BoneAttachment3D.new()
		att.bone_name = "mixamorig_Neck"
		skel.add_child(att)
		var holder := Node3D.new()
		att.add_child(holder)
		# undo any skeleton scale so the scarf keeps real-world size
		holder.scale = Vector3.ONE / skel.global_transform.basis.get_scale().x if skel.is_inside_tree() else Vector3.ONE
		scarf_parent = holder
		base = Vector3(0, 0.02, 0.01)
	var scarf := TorusMesh.new()
	scarf.inner_radius = 0.075
	scarf.outer_radius = 0.135
	_part(scarf, base, Color(0.6, 0.27, 0.25), scarf_parent).scale = Vector3(1, 0.8, 1)
	var tail := BoxMesh.new()
	tail.size = Vector3(0.085, 0.3, 0.03)
	var t := _part(tail, base + Vector3(0.06, -0.16, 0.11), Color(0.6, 0.27, 0.25), scarf_parent)
	t.rotation_degrees = Vector3(-14, 0, 6)
	_set_layer(pivot)

	cam = Camera3D.new()
	cam.top_level = true
	cam.fov = 70
	cam.near = 0.05
	cam.cull_mask = 0xFFFFF & ~(1 << (BODY_LAYER - 1))
	add_child(cam)
	target_yaw = pivot.rotation.y
	_update_fp_camera(0.0)
	_build_breath()

	if not Engine.is_editor_hint():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _set_layer(n: Node) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = 1 << (BODY_LAYER - 1)
	for c in n.get_children():
		_set_layer(c)


func _part(mesh: Mesh, pos: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mi.material_override = mat
	(parent if parent else pivot).add_child(mi)
	return mi


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and can_move and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		target_yaw -= event.relative.x * MOUSE_SENS * look_scale
		target_pitch = clampf(target_pitch - event.relative.y * MOUSE_SENS * look_scale, -1.25, 1.25)


# ---------------------------------------------------------------- helpers used by main.gd

func head_position() -> Vector3:
	return global_position + Vector3(0, EYE_HEIGHT, 0)


## Where the face actually is (follows the animated head bone).
func face_position() -> Vector3:
	if skel:
		var i := skel.find_bone("mixamorig_Head")
		if i >= 0:
			return skel.global_transform * skel.get_bone_global_pose(i).origin + Vector3(0, 0.07, 0)
	return head_position()


func facing() -> Vector3:
	return pivot.global_transform.basis.z.normalized()


func face_towards(point: Vector3) -> void:
	var d := point - global_position
	pivot.rotation.y = atan2(d.x, d.z)
	target_yaw = pivot.rotation.y


## Briefly turn the head toward something you interacted with (RE-style focus).
func glance(point: Vector3, amount := 0.35) -> void:
	lean_to = point
	var tw := create_tween()
	tw.tween_property(self, "lean_amt", amount, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.6)
	tw.tween_property(self, "lean_amt", 0.0, 0.8).set_trans(Tween.TRANS_SINE)


func add_shake(amount: float, time_s := 0.5) -> void:
	shake = maxf(shake, amount)
	var tw := create_tween()
	tw.tween_property(self, "shake", 0.0, time_s).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


## The ending: let the camera see the body (and the face) for the first time.
func reveal_face() -> void:
	cam.cull_mask = 0xFFFFF


# ---------------------------------------------------------------- movement

func _physics_process(delta: float) -> void:
	time += delta
	var input := Vector2.ZERO
	var jog := false
	if can_move:
		input.x = int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A))
		input.y = int(Input.is_physical_key_pressed(KEY_W)) - int(Input.is_physical_key_pressed(KEY_S))
		jog = Input.is_physical_key_pressed(KEY_SHIFT) and input.y > 0
		# weighty head: the view eases toward the mouse target
		pivot.rotation.y = lerp_angle(pivot.rotation.y, target_yaw, clampf(LOOK_SMOOTH * delta, 0, 1))
		pitch = lerpf(pitch, target_pitch, clampf(LOOK_SMOOTH * delta, 0, 1))
	if auto_input != Vector2.ZERO:
		input = auto_input
	input = input.normalized()
	var fwd := facing()
	fwd.y = 0
	var right := fwd.cross(Vector3.UP).normalized()
	var dir := fwd * input.y + right * input.x
	var spd := JOG_SPEED if jog else WALK_SPEED
	var target_v := dir * spd
	velocity.x = lerpf(velocity.x, target_v.x, clampf(ACCEL * delta, 0, 1))
	velocity.z = lerpf(velocity.z, target_v.z, clampf(ACCEL * delta, 0, 1))
	velocity.y = 0.0 if is_on_floor() else velocity.y - 9.8 * delta
	move_and_slide()

	var hspeed := Vector2(velocity.x, velocity.z).length()
	var moving := hspeed > 0.25
	if anim:
		var want := "ember/walk" if moving else "ember/idle"
		if anim.current_animation != want and anim.has_animation(want):
			anim.play(want, 0.25)
	# footstep cycle: one step every half cycle
	if moving:
		bob_t += delta * hspeed * 3.4
		var step_phase := floorf(bob_t / PI)
		if step_phase != _last_step:
			_last_step = step_phase
			stepped.emit(global_position.z > 0.3)
		settle = 0.0
	elif bob_t != 0.0:
		bob_t = 0.0
		settle = 1.0  # tiny dip as you come to rest
	settle = move_toward(settle, 0.0, delta * 2.5)
	roll = lerpf(roll, -input.x * 0.025, clampf(6.0 * delta, 0, 1))

	_breath_tick(delta)
	if not cam_locked:
		var bob := -absf(sin(bob_t)) * (0.045 if jog else 0.032)
		bob += sin(time * 1.3) * 0.004 - sin(settle * PI) * 0.02  # breathing + settle
		_update_fp_camera(bob)


func _update_fp_camera(bob: float) -> void:
	var yaw := pivot.rotation.y + PI
	var p := pitch
	# glance toward an object we just touched
	if lean_amt > 0.001 and lean_to != Vector3.INF:
		var d := lean_to - head_position()
		var want_yaw := atan2(-d.x, -d.z)
		var want_pitch := atan2(d.y, Vector2(d.x, d.z).length())
		yaw = lerp_angle(yaw, want_yaw, lean_amt)
		p = lerpf(p, want_pitch, lean_amt)
	var step_roll := sin(bob_t) * 0.006
	var idle_roll := sin(time * 0.7) * 0.003
	var sh := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake
	var b := Basis(Vector3.UP, yaw + sh.x * 0.03) * Basis(Vector3.RIGHT, p + sh.y * 0.03) * Basis(Vector3.BACK, roll + step_roll + idle_roll)
	cam.global_transform = Transform3D(b, head_position() + facing() * 0.12 + Vector3(sh.x * 0.02, bob + sh.y * 0.02, 0))


# ---------------------------------------------------------------- cold breath

func _build_breath() -> void:
	breath = GPUParticles3D.new()
	breath.amount = 18
	breath.lifetime = 2.2
	breath.one_shot = true
	breath.explosiveness = 0.55
	breath.emitting = false
	breath.local_coords = false
	breath.position = Vector3(0, -0.28, -0.5)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0.15, -1)
	pm.spread = 18.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.55
	pm.gravity = Vector3(0, 0.12, 0)
	pm.damping_min = 0.4
	pm.damping_max = 0.8
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.3))
	sc.add_point(Vector2(1, 1.6))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	var g := Gradient.new()
	g.set_color(0, Color(0.9, 0.92, 0.96, 0.0))
	g.add_point(0.25, Color(0.9, 0.92, 0.96, 0.045))
	g.set_color(1, Color(0.9, 0.92, 0.96, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	breath.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	# lit, so the vapour picks up lamp/moon light instead of glowing white
	var dg := Gradient.new()
	dg.set_color(0, Color(1, 1, 1, 1))
	dg.set_color(1, Color(1, 1, 1, 0))
	var dt := GradientTexture2D.new()
	dt.gradient = dg
	dt.fill = GradientTexture2D.FILL_RADIAL
	dt.fill_from = Vector2(0.5, 0.5)
	dt.fill_to = Vector2(1.0, 0.5)
	m.albedo_texture = dt
	q.material = m
	breath.draw_pass_1 = q
	cam.add_child(breath)


func _breath_tick(delta: float) -> void:
	if not breath or not breath_enabled or global_position.z < 0.3:
		return  # cold breath only outside in the snow
	_breath_timer -= delta
	if _breath_timer <= 0.0:
		_breath_timer = randf_range(3.2, 4.6)
		breath.restart()


# ---------------------------------------------------------------- Mixamo hookup

func _find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var f := _find_anim_player(c)
		if f:
			return f
	return null


func _first_anim(ap: AnimationPlayer) -> Animation:
	for lib_name in ap.get_animation_library_list():
		var lib := ap.get_animation_library(lib_name)
		for a in lib.get_animation_list():
			if a != "RESET":
				return lib.get_animation(a)
	return null


func _setup_anims(model: Node) -> void:
	anim = _find_anim_player(model)
	if not anim:
		return
	var lib := AnimationLibrary.new()
	var idle := _first_anim(anim)
	var walk_scene: Node = (load(WALK_PATH) as PackedScene).instantiate()
	var walk_ap := _find_anim_player(walk_scene)
	var walk := _first_anim(walk_ap) if walk_ap else null
	if idle:
		idle = idle.duplicate()
		idle.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation("idle", idle)
	if walk:
		walk = walk.duplicate()
		walk.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation("walk", walk)
	walk_scene.free()
	anim.add_animation_library("ember", lib)
	if idle:
		anim.play("ember/idle")
