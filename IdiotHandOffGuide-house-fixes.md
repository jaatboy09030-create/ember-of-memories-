# IdiotHandOffGuide — House fixes (owner feedback round 1) for *Unsent*

## A. Execution contract

**Outcome.** Fix the 11 problems the owner reported after playing:

1. Walls and doors look too smooth / plastic.
2. You may not leave the house: locked doors must say "locked", jerk in the frame and clack when tried; the front door shuts and locks behind you.
3. Meshes pass through each other (lamp, kid's legs, books, pillows, kitchen items, ...).
4. Z-fighting on the walls.
5. Too much decorative micro-detail: keep only what the story needs.
6. While holding a picked-up item you cannot look around; you must be able to look freely and turn the item with a key.
7. The grey "frozen memory" look is dull; it must feel atmospheric, thrilling, exciting.
8. A white, half-transparent gradient blob floats in the middle of rooms.
9. Room lighting and shadows look random.
10. Cameras pass through the player's head in transitions (you see your own hair).
11. Third-person-looking camera moments feel wrong.

**Root causes found (evidence in F):**
| # | Cause | Fix |
|---|---|---|
| 1 | Living room, kid room and hallway walls use `beige_wall_001_diff.jpg`, a flat single-colour image; all walls glossy (specular 0.5); doors use **world** triplanar wood, so the grain slides across a swinging door; door panels are a flat colour | All walls use the detailed `painted_plaster_wall`, matte, deeper normal; doors use object triplanar wood, panels textured |
| 2 | Locked doors were simply disabled (no hover, no reaction); nothing stops walking back out | `InteriorDoor`: "locked" prompt + `rattle()`; `lock_behind_player` on FrontDoor |
| 3 | `level_builder.gd` "settle" moved furniture but not the items on it (kitchen items 100 % inside the counter, lamp/books/pillows/candles sunk, side table and cupboard through walls, desk into the wall lining); seated ghosts' shins inside chair fronts; photo layers poke into the dresser | Minimal furniture at fixed, verified positions; ghost seat points moved forward 0.11 m; photo layers thinned |
| 4 | Corner overlaps of wainscot / chair-rail / cornice boxes from adjacent walls (coplanar faces) | Those boxes are removed (wallpaper + skirting only) |
| 5 | ~90 clutter props, ceiling beams, wall trims | Removed; only story furniture kept |
| 6 | `SuitcaseMemory` sets `player.can_move = false` (kills look) and auto-spins the item | New `PlayerBody.holding_item`: no walking, free look; hold `rotate_item` (R / gamepad Y) to turn the item |
| 7 | `camera_fx` only mixes toward flat luminance grey | New `MemoryGrade` pass: moonlit duotone, breathing frost from the edges, colour halo around the ember, warm ripple when a memory is restored |
| 8 | The exterior `GroundMist` FogVolume (z −13…37) fills the whole house; room lights and window spotlights (volumetric energy 2.5) light it | Mist limited to z > 0.5 and put in `outdoor_only`; interior lights have fog energy 0; window spotlights removed |
| 9 | Per room: one unshadowed centre fill light + 9 fake "moonbeam" spotlights from opaque windows (no shadows) + SDFGI leaking through 0.2 m walls + heavy SSAO | One shadowed light per room under a visible pendant lamp; window lights removed; SDFGI off; SSAO lighter |
| 10 | `PuzzleCamera` has the default cull mask, so the glide from the eyes renders the inside of the head; the photo pull-back flies in a straight line through the head | Puzzle camera hides render layer 2; pull-back swings round the side and shows the body only when clear |
| 11 | No real third-person mode exists. After the photo reveal `cull_mask` is never restored, so normal first person shows your own body/hair from inside — the "third person" feel | `PlayerCamera.hide_face()` called when the reveal ends |

**Assumption (owner may overrule):** item 11 refers to the body becoming visible after the photo memory. If the owner actually wants a playable third-person mode, that is new work, not in this guide.

**Scope.** Exactly the files in section C. No new assets are downloaded. No commit/push (the owner commits). The other guide in the repo, `IdiotHandOffGuide.md` (worn camera), is **already applied** in this baseline and must not be modified.

**Environment.**
- Root: `C:\Users\suyas\OneDrive\Documents\ember-of-memories-` (all paths relative to it).
- Shell: PowerShell 5.1. Python 3 on PATH (`python`).
- Engine: Godot **4.7.2** at `C:\Program Files\Godot\Godot.exe` (not on PATH). In commands below `$G` means that path: run `$G = "C:\Program Files\Godot\Godot.exe"` once per PowerShell session.
- Baseline: branch `main` @ `9d83308` (worn-camera merged), working tree clean. Files are LF line endings, UTF-8.

**Readiness: READY.** The author applied every step of this guide to a full scratch copy of the project at `9d83308` and ran the checks in E there (results in F). Your run on the real checkout is still the real verification.

**Operational sequence:**
1. Run S00. If a baseline check fails, stop that step and every step that depends on it, report the path and mismatch.
2. Apply S01–S19 in order. Use the code exactly as given. For a "replace block" edit, the original text must occur exactly once; if it occurs 0 or 2+ times, stop that step and report.
3. Run V1–V6 and compare with the expected results. Then hand M1–M8 (by-eye checks) to the owner.
4. Report following F.

**Resuming a half-applied run.** Every step has a postcondition. Check postconditions from S01 on; skip steps whose postcondition already holds; resume at the first that does not. A replace-block edit whose *replacement* text is already present counts as applied.

**Unknown error:** report the exact error text and the step ID; do not improvise a fix.

**Do not:** commit, push, edit `IdiotHandOffGuide.md`, or run `tools/level_builder.gd` except in S18 exactly as written.

---

## B. Requirements and acceptance map

| ID | Requirement (observable) | Steps | Checks |
|---|---|---|---|
| R1 | Interior walls show plaster texture and are matte; door wood grain stays fixed on the leaf while it swings; door panels are textured | S15, S18 | M1 |
| R2a | Looking at a locked door shows prompt `locked`, no glow; pressing interact makes the leaf jerk and a double latch clack plays; it stays shut and locked | S14 | V2, M2 |
| R2b | After walking in through the front door, once you are ~1.8 m from its hinge it swings shut and locks; it then behaves as R2a | S14, S18 | V2, M2 |
| R3 | No prop, wall or memory object passes through another (except the study door set into the hallway wall, by design); seated ghosts' legs clear their chairs; face-down photo does not sink into the dresser | S09, S11, S18 | V4, M3 |
| R4 | No z-fighting flicker on walls/corners | S18 | M4 |
| R5 | Rooms contain only story furniture (list in S18); no ceiling beams, wainscot, chair rails, cornices, clutter | S18 | V5, M5 |
| R6 | While holding a bedroom item: can't walk, can look around freely, the item stays in front of the view; holding R (gamepad Y) + mouse/stick turns the item; interact packs it | S03, S04, S05, S06 | V1, M6 |
| R7 | Frozen memory = moonlit blue/silver duotone with frost breathing in from the edges; colour glows back around the ember; a warm ring sweeps out when a memory is restored; lamps/fire keep their warm colour | S01, S13 | V6, M7 |
| R8 | No white/grey fog blob inside the house | S12, S18 | M8 |
| R9 | Each room is lit by one ceiling pendant; shadows all fall away from it; no light patches from windows | S12, S18 | V5, M8 |
| R10 | Drawing-puzzle glide and the photo reveal never show the inside of the player's head or hair | S07, S08, S10 | M9 |
| R11 | After the photo memory the player's own body is invisible again in first person | S07, S10 | M9 |
| R12 | No regressions: storytest, walktest, doortest PASS; no script/shader/parse errors | all | V1–V3, V6 |
| R13 | MEMORY knowledge base and CHANGELOG updated | S19 | V5 |

**Not covered:** a playable third-person mode (see assumption in A); the pre-existing `--walktest --gate` FAIL (documented in `MEMORY/07`, unrelated).

---

## C. File-change manifest

| Path | Op | Step |
|---|---|---|
| `shaders/memory_grade.gdshader` | create | S01 |
| `scripts/systems/memory_grade.gd` | create | S01 |
| `tools/overlap_check.gd` | create | S02 |
| `project.godot` | insert block (input action `rotate_item`) | S03 |
| `scripts/player/player_body.gd` | 3 replace blocks | S04 |
| `scripts/objects/packable_item.gd` | 2 replace blocks | S05 |
| `scripts/memories/suitcase_memory.gd` | replace entire file | S06 |
| `scripts/player/player_camera.gd` | 1 replace block (adds `hide_face`) | S07 |
| `scenes/objects/torn_drawing_puzzle.tscn` | 1 replace block | S08 |
| `scenes/objects/photo_frame.tscn` | 6 replace blocks | S09 |
| `scripts/memories/photo_memory.gd` | replace entire file | S10 |
| `scenes/memories/drawing_memory.tscn`, `scenes/memories/scarf_memory.tscn` | 1 replace block each | S11 |
| `scenes/objects/house_window.tscn` | delete block (`MoonlightBeam`) | S12 |
| `scenes/main.tscn` | 1 replace block (environment) | S12 |
| `scripts/level/room.gd` | 1 replace block | S12 |
| `scripts/characters/ember.gd` | 1 replace block | S13 |
| `scenes/systems/screen_effects.tscn` | 3 replace blocks | S13 |
| `scripts/systems/screen_effects.gd` | 4 replace blocks | S13 |
| `shaders/camera_fx.gdshader` | 1 replace block | S13 |
| `scripts/objects/interior_door.gd` | replace entire file | S14 |
| `materials/door_wood.tres`, `materials/door_panel.tres` | replace entire file | S15 |
| `scripts/dev/dev_tests.gd` | 2 replace blocks | S16 |
| `.godot/global_script_class_cache.cfg`, `scripts/systems/memory_grade.gd.uid`, `shaders/memory_grade.gdshader.uid`, `tools/overlap_check.gd.uid` (if Godot makes them) | generated by import | S17 |
| `tools/level_builder.gd` | patched by script | S18 |
| `scenes/level/house_level.tscn` | regenerated by `level_builder.gd` | S18 |
| `materials/level/*.tres` | regenerated (all rewritten; new `lamp_shade.tres`, `lamp_bulb.tres`) | S18 |
| `materials/level/ceiling_beam_wood.tres`, `wainscot_wood.tres`, `wall_trim_wood.tres` | delete (nothing references them after S18) | S18 |
| `MEMORY/02-architecture.md`, `03-scripts-reference.md`, `04-memories.md`, `05-assets-shaders-audio.md`, `06-recipes.md`, `07-gotchas-and-learnings.md`, `CHANGELOG.md` | edited by script | S19 |

No renames. New input action `rotate_item`, new group `colour_source`, new class `MemoryGrade`.

---

## D. Ordered implementation steps

### S00 — Baseline check
PowerShell, in the root:
```powershell
git rev-parse --short HEAD
git status --short
(Get-FileHash "scripts/objects/interior_door.gd" -Algorithm SHA256).Hash.Substring(0,16)
(Get-FileHash "scripts/memories/suitcase_memory.gd" -Algorithm SHA256).Hash.Substring(0,16)
(Get-FileHash "scripts/memories/photo_memory.gd" -Algorithm SHA256).Hash.Substring(0,16)
(Get-FileHash "materials/door_wood.tres" -Algorithm SHA256).Hash.Substring(0,16)
(Get-FileHash "materials/door_panel.tres" -Algorithm SHA256).Hash.Substring(0,16)
(Get-FileHash "tools/level_builder.gd" -Algorithm SHA256).Hash.Substring(0,16)
(Get-FileHash "scenes/level/house_level.tscn" -Algorithm SHA256).Hash.Substring(0,16)
```
**Expected:** `9d83308` (or a later commit that touches none of the files in C); status empty, or only `?? IdiotHandOffGuide-house-fixes.md` and ` M MEMORY/CHANGELOG.md` (the line that records this guide); then, in this order:
- `scripts/objects/interior_door.gd` → `2F261B22254C784E`
- `scripts/memories/suitcase_memory.gd` → `2879A2D85D2EA3EE`
- `scripts/memories/photo_memory.gd` → `24DE56AEE8E1E8E6`
- `materials/door_wood.tres` → `657D74400F4FFEAF`
- `materials/door_panel.tres` → `F4E4CA367774140E`
- `tools/level_builder.gd` → `C96B84BA84B2A7C3`
- `scenes/level/house_level.tscn` → `E70C626A9435401E`

A different hash means the file was edited after this guide was written: stop the step that replaces it (S06, S10, S14, S15, S18) and report. Block-edit steps check themselves (the original block must match exactly once).

---

### S01 — Create the frozen-memory grade (shader + script)
Prerequisite: S00. Neither file may exist.

`shaders/memory_grade.gdshader`:
```glsl
shader_type canvas_item;
// MEMORY GRADE: how a frozen memory looks (ScreenEffects > MemoryGrade, runs before FilmLook).
// Driven by scripts/systems/memory_grade.gd. Instead of flat grey:
//   - a moonlit duotone: shadows sink into deep blue, highlights turn cold silver
//   - warm light sources (lamps, fire, the ember itself) keep their colour
//   - colour glows back in a halo around the ember (it carries the warmth through the house)
//   - frost creeps in from the screen edges and slowly breathes while the memory is frozen
//   - a warm ring of colour sweeps out from the centre when a memory is restored
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
// 0 = frozen memory .. 1 = full colour (ScreenEffects.world_saturation).
uniform float world_sat = 1.0;
uniform vec3 shadow_tint : source_color = vec3(0.10, 0.17, 0.36);
uniform vec3 highlight_tint : source_color = vec3(0.86, 0.92, 1.0);
// Extra contrast in the frozen look (0 = none).
uniform float frozen_contrast : hint_range(0.0, 1.0) = 0.25;
// 0..1: how far the frost reaches in from the edges when fully frozen.
uniform float frost : hint_range(0.0, 1.0) = 0.6;
// Breaths per second of the frost (a slow, uneasy pulse).
uniform float frost_breath = 0.45;
// Ember halo: xy = centre (px), z = radius (px), w = strength 0..1.
uniform vec4 ember = vec4(0.0);
// Restore ripple: radius in screen heights (< 0 = off) and how much colour it carries.
uniform float ripple = -1.0;
uniform float ripple_hold = 0.0;
uniform vec3 ripple_color : source_color = vec3(1.0, 0.62, 0.3);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 px = SCREEN_UV * res;
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float lum = luma(c);
	float frozen = 1.0 - clamp(world_sat, 0.0, 1.0);

	// 1. moonlit duotone (keeps brightness, changes only the hue)
	float l = mix(lum, smoothstep(0.0, 1.0, lum), frozen_contrast);
	vec3 st = shadow_tint / max(luma(shadow_tint), 0.001);
	vec3 ht = highlight_tint / max(luma(highlight_tint), 0.001);
	vec3 duo = l * mix(st, ht, smoothstep(0.02, 0.45, lum));

	// 2. how much real colour survives here
	float keep = max(world_sat, smoothstep(0.55, 1.1, lum));      // warm lights stay warm
	float d_ember = distance(px, ember.xy);
	float halo = ember.w * (1.0 - smoothstep(ember.z * 0.25, ember.z, d_ember));
	keep = max(keep, halo);
	vec2 q = (SCREEN_UV - 0.5) * vec2(res.x / res.y, 1.0);
	float dr = length(q);
	float rim = 0.0;
	if (ripple >= 0.0) {
		keep = max(keep, (1.0 - smoothstep(ripple - 0.08, ripple, dr)) * ripple_hold);
		rim = exp(-pow((dr - ripple) * 12.0, 2.0)) * ripple_hold;
	}
	vec3 outc = mix(duo, c, clamp(keep, 0.0, 1.0));
	outc += rim * ripple_color * 0.35;

	// 3. frost creeping in from the edges, breathing slowly; the ember's halo melts it
	float breath = 0.5 + 0.5 * sin(TIME * frost_breath * 6.2832);
	float n = vnoise(px / 140.0 + vec2(TIME * 0.02, 0.0)) * 0.65 + vnoise(px / 28.0) * 0.35;
	float reach = frost * frozen * (0.85 + 0.15 * breath);
	float edge = length(q * vec2(0.8, 1.0)) + (n - 0.5) * 0.22;
	float f = smoothstep(0.78 - reach * 0.38, 0.95, edge) * (1.0 - halo);
	vec3 ice = mix(vec3(l) * ht, ht * 0.75, 0.35);
	outc = mix(outc, ice, f * 0.6 * frozen);
	// thin bright crystal veins inside the frost
	float vein = 1.0 - smoothstep(0.0, 0.035, abs(vnoise(px / 55.0) - 0.5));
	outc += vein * f * frozen * 0.08 * ht;

	COLOR = vec4(outc, 1.0);
}
```

`scripts/systems/memory_grade.gd`:
```gdscript
class_name MemoryGrade
extends ColorRect
## MEMORY GRADE: how a frozen memory looks on screen (shaders/memory_grade.gdshader).
## Replaces the old flat grey with:
##   - a moonlit duotone: shadows sink into deep blue, highlights go cold silver; lamps, fire
##     and the ember keep their warm colour
##   - colour glowing back in a halo around the ember (any node in group "colour_source"),
##     so the companion visibly carries warmth through the grey house
##   - frost creeping in from the screen edges that slowly breathes while frozen
##   - a warm ring of colour sweeping out from the centre when a memory is restored (ripple())
## It sits first inside ScreenEffects, before GradeCopy + FilmLook (lens, vignette, grain).
## ScreenEffects.world_saturation drives it through set_world_saturation().
##
## How to change it: the @export values below; colours, frost reach and breathing speed are on
## Material in the Inspector (memory_grade.gdshader uniforms).

## Halo radius around the ember, in screen heights, when the ember is 2 m away.
@export var halo_size := 0.22
## How strongly colour comes back around the ember (0 = off, 1 = full colour).
@export_range(0.0, 1.0) var halo_strength := 0.85
## How fast the halo fades in/out when the ember goes behind a wall or off screen (per second).
@export var halo_fade_speed := 3.0
## Seconds the restore ripple takes to cross the screen.
@export var ripple_time := 1.6
## Seconds the colour inside the ripple lingers before the new world colour takes over.
@export var ripple_fade_time := 1.4

@onready var grade: ShaderMaterial = material

var _halo := 0.0


func set_world_saturation(value: float) -> void:
	grade.set_shader_parameter("world_sat", value)


## A memory comes back: a warm ring of colour sweeps out from the middle of the screen.
func ripple() -> void:
	grade.set_shader_parameter("ripple_hold", 1.0)
	var tw := create_tween()
	tw.tween_method(func(r: float): grade.set_shader_parameter("ripple", r), 0.0, 1.6, ripple_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(h: float): grade.set_shader_parameter("ripple_hold", h), 1.0, 0.0, ripple_fade_time)
	tw.tween_callback(func(): grade.set_shader_parameter("ripple", -1.0))


## Every frame: where the ember is on screen, how big its halo is, and whether it is visible.
func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var src := get_tree().get_first_node_in_group("colour_source") as Node3D
	var target := 0.0
	var centre := Vector2.ZERO
	var radius := 0.0
	if cam and src and src.is_visible_in_tree() and not cam.is_position_behind(src.global_position):
		var p := src.global_position
		centre = cam.unproject_position(p)
		var dist := maxf(cam.global_position.distance_to(p), 0.5)
		radius = get_viewport_rect().size.y * halo_size * clampf(2.0 / dist, 0.35, 1.5)
		target = halo_strength
		# hidden behind a wall? then no colour bleeds through it
		var hit := src.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(cam.global_position, p))
		if not hit.is_empty() and (hit.position as Vector3).distance_to(p) > 0.4:
			target = 0.0
	_halo = move_toward(_halo, target, delta * halo_fade_speed)
	grade.set_shader_parameter("ember", Vector4(centre.x, centre.y, radius, _halo))
```

Postcondition: both files exist with exactly this content.

---

### S02 — Create `tools/overlap_check.gd`
Prerequisite: S00. File must not exist. (A headless tool like the others in `tools/`; never runs in the game.)
```gdscript
extends SceneTree
## OVERLAP CHECK (tool, NOT used while the game runs).
## Finds meshes that pass through each other in the house: props sunk into furniture, things
## poking through walls, memory objects buried in the furniture they rest on.
## It loads the level plus the memory scenes, samples each object's mesh vertices and tests
## whether they lie inside another object's mesh.
##   Godot --headless --path <project> -s res://tools/overlap_check.gd
## Optional: pass another level scene after "--" to check it instead of house_level.tscn.
## Every "OVERLAP" line is a problem, except the ones listed in KNOWN_OK (see MEMORY/06-recipes R12).
## Floors and rugs are not checked as targets (props stand on them by design), and ghost figures
## are not checked (bones are not meshes; check seated figures by eye).

const MEMORY_SCENES := ["res://scenes/memories/scarf_memory.tscn", "res://scenes/memories/drawing_memory.tscn",
	"res://scenes/memories/door_memory.tscn", "res://scenes/memories/suitcase_memory.tscn",
	"res://scenes/memories/photo_memory.tscn", "res://scenes/memories/fireplace_memory.tscn"]
## The study door is built into the hallway's back wall on purpose.
const KNOWN_OK := ["DoorMemory/StudyDoor"]

var _objs: Array = []  # {name, tris (world space), aabb, pts}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var level_path: String = args[0] if args.size() > 0 else "res://scenes/level/house_level.tscn"
	var world := Node3D.new()
	root.add_child(world)
	var level: Node = load(level_path).instantiate()
	world.add_child(level)
	for m in MEMORY_SCENES:
		world.add_child(load(m).instantiate())
	await process_frame
	await process_frame
	for room in level.get_node("Rooms").get_children():
		for p in room.get_node("Props").get_children():
			_add(room.name + "/" + p.name, p, true)
		for side in room.get_node("WallLining").get_children():
			_add(room.name + "/Lining" + side.name, side, false)
	for w in level.get_node("House/InnerWalls").get_children() + level.get_node("House/OuterWalls").get_children():
		_add("Wall/" + w.name, w, false)
	for i in range(1, world.get_child_count()):
		var mem := world.get_child(i)
		for c in mem.get_children():
			if c is MemoryFigure or not c is Node3D or c.name == "EmberRestPoint":
				continue
			if c.name in ["PackableItems", "DrawingPieces"]:
				for cc in c.get_children():
					_add(mem.name + "/" + cc.name, cc, true)
			else:
				_add(mem.name + "/" + c.name, c, true)
	var problems := 0
	for a in _objs:
		if not a.subject:
			continue
		for b in _objs:
			if a == b or not a.aabb.grow(0.01).intersects(b.aabb):
				continue
			var inside := 0
			for p in a.pts:
				if b.aabb.has_point(p) and _inside(p, b.tris):
					inside += 1
			var frac: float = float(inside) / float(a.pts.size())
			if inside >= 3 and frac > 0.015:
				var known: bool = String(a.name) in KNOWN_OK
				if not known:
					problems += 1
				print("%s %-45s INSIDE %-40s %5.1f%% of its vertices" % ["known  " if known else "OVERLAP", a.name, b.name, frac * 100.0])
	print("overlap_check: ", problems, " problem(s)")
	quit()


func _meshes(n: Node, out: Array) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).visible and (n as MeshInstance3D).mesh and not (n as MeshInstance3D).skin:
		out.append(n)
	for c in n.get_children():
		_meshes(c, out)


func _add(label: String, node: Node, subject: bool) -> void:
	var ms: Array = []
	_meshes(node, ms)
	var tris := PackedVector3Array()
	for mi in ms:
		var t: Transform3D = mi.global_transform
		for v in (mi as MeshInstance3D).mesh.get_faces():
			tris.append(t * v)
	if tris.is_empty():
		return
	var box := AABB(tris[0], Vector3.ZERO)
	for v in tris:
		box = box.expand(v)
	var step: int = maxi(1, int(tris.size() / 1500))
	var pts := PackedVector3Array()
	for i in range(0, tris.size(), step):
		pts.append(tris[i])
	_objs.append({"name": label, "tris": tris, "aabb": box, "pts": pts, "subject": subject})


## Ray-parity test: a point is inside a closed mesh when a ray from it crosses an odd number of triangles.
func _inside(p: Vector3, t: PackedVector3Array) -> bool:
	var hits := 0
	var dir := Vector3(0.0123, 1.0, 0.0071).normalized()
	for i in range(0, t.size(), 3):
		var a: Vector3 = t[i]
		var b: Vector3 = t[i + 1]
		var c: Vector3 = t[i + 2]
		if maxf(a.x, maxf(b.x, c.x)) < p.x - 0.001 or minf(a.x, minf(b.x, c.x)) > p.x + 0.001:
			continue
		if maxf(a.z, maxf(b.z, c.z)) < p.z - 0.001 or minf(a.z, minf(b.z, c.z)) > p.z + 0.001:
			continue
		if Geometry3D.ray_intersects_triangle(p, dir, a, b, c) != null:
			hits += 1
	return hits % 2 == 1
```

Postcondition: file exists with this content.

---

### S03 — Input action `rotate_item` (R key + gamepad Y)
Keyboard **and** gamepad binding, as the project rules require. Gamepad button 3 = Y; R and Y are unused elsewhere.

**Edit S03.1 — `project.godot`** (replace block; the original must match exactly once)

Original:
```ini

[layer_names]
```
Replacement:
```ini
rotate_item={
"deadzone": 0.2,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":82,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":3,"pressure":0.0,"pressed":false,"script":null)
]
}

[layer_names]
```

Postcondition: `project.godot` contains `rotate_item={` exactly once, right before `[layer_names]`.

---

### S04 — `PlayerBody`: free look while holding an item

**Edit S04.1 — `scripts/player/player_body.gd`** (replace block; the original must match exactly once)

Original:
```gdscript
## false during cutscenes and mini-games: no walking, no looking, no interacting.
var can_move := true:
	set(v):
		can_move = v
		if is_node_ready():
			interaction_raycast.enabled = v
```
Replacement:
```gdscript
## false during cutscenes and mini-games: no walking, no looking, no interacting.
var can_move := true:
	set(v):
		can_move = v
		if is_node_ready():
			interaction_raycast.enabled = v and not holding_item
## true while an object is held up to the eyes (SuitcaseMemory): no walking and no
## interacting, but looking around stays free. While "rotate_item" is held, mouse/stick
## movement goes into item_turn (for the holder to turn the object) instead of the view.
var holding_item := false:
	set(v):
		holding_item = v
		if is_node_ready():
			interaction_raycast.enabled = can_move and not v
## Turn input collected while holding "rotate_item" (radians: x = around the view's up axis,
## y = around its right axis). The holder reads it and sets it back to zero.
var item_turn := Vector2.ZERO
```

**Edit S04.2 — `scripts/player/player_body.gd`** (replace block; the original must match exactly once)

Original:
```gdscript
	elif event is InputEventMouseMotion and can_move and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_turn(event.relative * mouse_sensitivity)
```
Replacement:
```gdscript
	elif event is InputEventMouseMotion and can_move and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if _rotating_item():
			item_turn += event.relative * mouse_sensitivity * 2.0
		else:
			_turn(event.relative * mouse_sensitivity)


## Holding an object and pressing "rotate_item": turn the object, not the head.
func _rotating_item() -> bool:
	return holding_item and Input.is_action_pressed("rotate_item")
```

**Edit S04.3 — `scripts/player/player_body.gd`** (replace block; the original must match exactly once)

Original:
```gdscript
	if can_move:
		input = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
		is_jogging = Input.is_action_pressed("sprint") and input.y > 0.0
		var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
		if stick != Vector2.ZERO:
			_turn(stick * gamepad_look_speed * delta)
```
Replacement:
```gdscript
	if can_move:
		if not holding_item:
			input = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
			is_jogging = Input.is_action_pressed("sprint") and input.y > 0.0
		var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
		if stick != Vector2.ZERO:
			if _rotating_item():
				item_turn += stick * gamepad_look_speed * 1.5 * delta
			else:
				_turn(stick * gamepad_look_speed * delta)
```

Postcondition: the file contains `var holding_item := false:`, `var item_turn := Vector2.ZERO` and `func _rotating_item() -> bool:` once each.

---

### S05 — `PackableItem`: turn on demand instead of auto-spin

**Edit S05.1 — `scripts/objects/packable_item.gd`** (replace block; the original must match exactly once)

Original:
```gdscript
## A belonging lying in the bedroom. Using it lifts it in front of the player's eyes, it
## turns slowly while its memory line is shown, and "interact" again packs it into the
## suitcase. SuitcaseMemory does the inspecting (it owns the camera); this script only
## holds the item's data and flies it into the suitcase.
```
Replacement:
```gdscript
## A belonging lying in the bedroom. Using it lifts it in front of the player's eyes while
## its memory line is shown (the player can look around; holding "rotate_item" turns the
## item through turn_by()), and "interact" again packs it into the suitcase. SuitcaseMemory
## does the holding; this script only holds the item's data, turns it and flies it away.
```

**Edit S05.2 — `scripts/objects/packable_item.gd`** (replace block; the original must match exactly once)

Original:
```gdscript
## Turns the item slowly while it is being looked at.
func spin(delta: float) -> void:
	rotate_y(delta * 0.7)
```
Replacement:
```gdscript
## Turns the held item the way the mouse/stick moves: amount.x around the view's up axis,
## amount.y around the view's right axis (radians). view = the camera's global basis.
func turn_by(amount: Vector2, view: Basis) -> void:
	global_rotate(view.y.normalized(), amount.x)
	global_rotate(view.x.normalized(), amount.y)
```

Postcondition: `func turn_by(` present, `func spin(` gone. (`spin` was only called by SuitcaseMemory, replaced in S06.)

---

### S06 — Replace entire file `scripts/memories/suitcase_memory.gd`
Prerequisites: S04, S05. Baseline hash `2879A2D85D2EA3EE` (S00). Behaviour kept: item counting, captions, saturation drain, suitcase close, `debug_complete()`. Changed: holding uses `player.holding_item` (look stays free), the item follows the camera every frame, turn via `player.item_turn`, no depth-of-field while holding (it would blur the room you can now look at).

```gdscript
extends Memory
## MEMORY 4: PACK THE SUITCASE (bedroom).
## Belongings the parent kept lie around the room. Picking one up holds it in front of the
## eyes while its memory is read out. While holding it the player can't walk, but can look
## around freely (the item stays in front of the view). Holding "rotate_item" (R / gamepad Y)
## turns the item with the mouse or right stick instead of turning the view. "interact" packs
## it. Every packed item drains a little more colour. When all are packed, closing the
## suitcase fades to black: "I left that night." Then the parent's room opens.
##
## How to change it: each PackableItem's memory_line; add/remove items under PackableItems
## (the count is automatic); the lines below; hold_offset = where a held item floats.

@export var pack_prompt := "pack it"
@export var turn_hint := "hold R / Y to turn it"
@export var leave_line := "I left that night. I never came back."
## Colour at the start of this memory (it drains to 0 as items are packed).
@export var start_saturation := 0.3
## Where a held item floats, relative to the camera (x right, y up, -z forward), metres.
@export var hold_offset := Vector3(0, -0.06, -0.5)
## Seconds the item takes to rise from where it lay into view.
@export var lift_time := 0.6

@onready var items_root: Node3D = $PackableItems
@onready var suitcase: Suitcase = $Suitcase

var _items_total := 0
var _items_left := 0
var _held: PackableItem
var _ready_to_pack := false
var _lift: Tween
var _lift_from := Vector3.ZERO
var _lift_t := 0.0


func _ready() -> void:
	suitcase.closed.connect(_on_suitcase_closed)


func begin() -> void:
	for it in items_root.get_children():
		if it is PackableItem:
			_items_total += 1
			it.enabled = true
			it.chosen.connect(_inspect)
	_items_left = _items_total


## Lift the item in front of the eyes and let its memory speak.
func _inspect(item: PackableItem) -> void:
	_held = item
	_ready_to_pack = false
	game.player.holding_item = true
	game.player.item_turn = Vector2.ZERO
	Sound.play("paper_pickup", -6.0, 0.1)
	_lift_from = item.global_position
	_lift_t = 0.0
	_lift = create_tween()
	_lift.tween_property(self, "_lift_t", 1.0, lift_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_lift.tween_callback(func():
		_ready_to_pack = true
		game.hud.say(item.memory_line, 3.5)
		game.hud.show_prompt(pack_prompt + "      " + turn_hint))
	game.screen_effects.set_vignette(0.55)


## The held item follows the view every frame, so looking around keeps it in front of you.
func _process(_delta: float) -> void:
	if not _held:
		return
	var cam: Camera3D = game.player.cam
	_held.global_position = _lift_from.lerp(cam.global_transform * hold_offset, _lift_t)
	var turn: Vector2 = game.player.item_turn
	if turn != Vector2.ZERO:
		_held.turn_by(turn, cam.global_basis)
		game.player.item_turn = Vector2.ZERO
	if _ready_to_pack and Input.is_action_just_pressed("interact"):
		_pack_held()


func _pack_held() -> void:
	var item := _held
	_held = null
	if _lift and _lift.is_valid():
		_lift.kill()
	game.hud.show_prompt("")
	game.screen_effects.reset_vignette()
	game.player.holding_item = false
	item.fly_into(suitcase.pack_point.global_position)
	_items_left -= 1
	game.screen_effects.fade_saturation(start_saturation * _items_left / float(_items_total), 1.5)
	if _items_left == 0:
		suitcase.enabled = true


func _on_suitcase_closed() -> void:
	game.player.can_move = false
	Sound.play_music("", 0.0, 3.0)
	var tw := game.hud.fade_to(1.0, 1.5)
	tw.tween_callback(func(): game.hud.say(leave_line, 3.5))
	tw.tween_interval(3.5)
	tw.tween_callback(func():
		finish()
		game.player.can_move = true)
	tw.tween_property(game.hud.screen_fade, "color:a", 0.0, 1.5)


func debug_complete() -> void:
	for it in items_root.get_children():
		if it is PackableItem:
			it.on_interact()
			_ready_to_pack = true
			_pack_held()
	suitcase.on_interact()
```

Postcondition: file content equals the block above.

---

### S07 — `PlayerCamera.hide_face()`
The anchor exists in the worn-camera version of this file.

**Edit S07.1 — `scripts/player/player_camera.gd`** (replace block; the original must match exactly once)

Original:
```gdscript
func reveal_face() -> void:
	cull_mask = 0xFFFFF
```
Replacement:
```gdscript
func reveal_face() -> void:
	cull_mask = 0xFFFFF


## Normal first person again: the camera stops seeing the body (after the photo reveal), so
## you never look down into your own hair, shoulders or the inside of your head.
func hide_face() -> void:
	cull_mask = 0xFFFFF & ~(1 << (PlayerBody.BODY_RENDER_LAYER - 1))
```

Postcondition: `func hide_face() -> void:` present once. `1048573` = all 20 render layers except layer 2 (PlayerBody), the same value `player.tscn` uses.

---

### S08 — Puzzle camera never sees the body

**Edit S08.1 — `scenes/objects/torn_drawing_puzzle.tscn`** (replace block; the original must match exactly once)

Original:
```ini
[node name="PuzzleCamera" type="Camera3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 0.14834, 0.98894, 0, -0.98894, 0.14834, 0, 0.55, 0.08)
```
Replacement:
```ini
[node name="PuzzleCamera" type="Camera3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 0.14834, 0.98894, 0, -0.98894, 0.14834, 0, 0.55, 0.08)
cull_mask = 1048573
```

Postcondition: the `PuzzleCamera` node has `cull_mask = 1048573`.

---

### S09 — Photo layers stay inside the frame
The face-down photo's paper and figure strips stuck out 2 cm below the frame and sank into the dresser. They become 4 mm thin and sit inside the frame, so the frame (at its unchanged position y 1.1708) rests on the dresser top (y 1.1508) with nothing below it.

**Edit S09.1 — `scenes/objects/photo_frame.tscn`** (replace block; the original must match exactly once)

Original:
```ini
size = Vector3(0.3, 0.01, 0.38)
```
Replacement:
```ini
size = Vector3(0.3, 0.004, 0.38)
```

**Edit S09.2 — `scenes/objects/photo_frame.tscn`** (replace block; the original must match exactly once)

Original:
```ini
size = Vector3(0.09, 0.012, 0.24)
```
Replacement:
```ini
size = Vector3(0.09, 0.004, 0.24)
```

**Edit S09.3 — `scenes/objects/photo_frame.tscn`** (replace block; the original must match exactly once)

Original:
```ini
size = Vector3(0.06, 0.012, 0.14)
```
Replacement:
```ini
size = Vector3(0.06, 0.004, 0.14)
```

**Edit S09.4 — `scenes/objects/photo_frame.tscn`** (replace block; the original must match exactly once)

Original:
```ini
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.02, 0)
mesh = SubResource("PaperMesh")
```
Replacement:
```ini
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.0135, 0)
mesh = SubResource("PaperMesh")
```

**Edit S09.5 — `scenes/objects/photo_frame.tscn`** (replace block; the original must match exactly once)

Original:
```ini
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.06, 0.03, 0.03)
```
Replacement:
```ini
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.06, 0.0175, 0.03)
```

**Edit S09.6 — `scenes/objects/photo_frame.tscn`** (replace block; the original must match exactly once)

Original:
```ini
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.07, 0.03, 0.08)
```
Replacement:
```ini
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.07, 0.0175, 0.08)
```

Postcondition: no `0.012` and no `0.02, 0)` left in `photo_frame.tscn` sizes/transforms of those three meshes.

---

### S10 — Replace entire file `scripts/memories/photo_memory.gd`
Prerequisite: S07 (`hide_face`). Baseline hash `24DE56AEE8E1E8E6`. Shots 1, 3, 4, 5 and their timings are unchanged. Shot 2 now swings round the side (`_pull_back`) instead of flying through the head and ends exactly where the orbit starts; the body is shown only once the camera is clear; `hide_face()` runs when the scene ends.

```gdscript
extends Memory
## MEMORY 5: THE PHOTO (parent's room) - the reveal.
## A photo lies face down on the dresser. Turning it over starts the one cutscene where
## the camera leaves the body: we lean in, then the camera swings round the side to behind
## the shoulder and slowly circles round to see our own face for the first time. Silence.
## Then the letter. Afterwards the body is hidden from the camera again (hide_face), so normal
## first person never shows your own hair or shoulders.
## The camera never passes through the head: on the way out it keeps head_clearance from it,
## and the body only becomes visible once the camera is clear of it.
##
## How to change it: letter_line / letter_voice; head_clearance; the shot timings are the
## numbers in _play_reveal() (each tween line is one camera move, in seconds).

@export var letter_line := "\"I kept the fire going, in case you came home.\""
@export var letter_voice := "v_letter"
## On the way out the camera swings at least this far (metres) from the head.
@export var head_clearance := 0.6

@onready var photo: PhotoFrame = $PhotoFrame

var _head := Vector3.ZERO
var _pull_from := Vector3.ZERO
var _face_shown := false


func _ready() -> void:
	photo.chosen.connect(_play_reveal)


func begin() -> void:
	photo.enabled = true


func _play_reveal() -> void:
	var player: PlayerBody = game.player
	var cam: PlayerCamera = player.cam
	player.can_move = false
	cam.cinematic = true
	player.get_node("PlayerCamera/ColdBreath").breathing = false
	player.face_towards(photo.global_position)
	_head = player.face_position()
	var to_photo := photo.global_position - cam.global_position
	to_photo.y = 0.0
	to_photo = to_photo.normalized()
	cam.look_target = photo.global_position
	game.set_cinematic(true)
	Sound.play_music("", 0.0, 2.0)  # the house goes quiet
	var tw := create_tween()
	# 1. Insert shot: we lean in as our own hands turn the photo over
	tw.tween_property(cam, "global_position", photo.global_position - to_photo * 0.75 + Vector3(0, 0.35, 0), 2.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "fov", 42.0, 2.0)
	tw.parallel().tween_callback(photo.flip).set_delay(0.8)
	tw.tween_callback(func():
		cam.focus(0.75)
		game.screen_effects.fade_saturation(0.55, 2.5)
		Sound.play("memory_restore", -6.0))
	tw.tween_interval(3.0)
	# 2. For the first time, the camera leaves the body: it swings round the side to behind
	#    the shoulder (never through the head); the body appears once the camera is clear.
	tw.tween_callback(func():
		_pull_from = cam.global_position
		_face_shown = false
		Sound.play("heartbeat", -6.0))
	tw.tween_method(_pull_back, 0.0, 1.0, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "look_target", _head + Vector3(0, -0.1, 0), 3.5)
	tw.parallel().tween_property(cam, "fov", 50.0, 3.5)
	tw.parallel().tween_callback(func(): cam.focus(1.7)).set_delay(1.5)
	# 3. ...and circles round to the face. Long lens, shallow focus.
	tw.tween_callback(player.reveal_face)  # in case the pull-back never got far enough
	tw.tween_method(_orbit, 0.0, 1.0, 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(cam, "fov", 34.0, 6.5)
	tw.parallel().tween_callback(func(): cam.focus(0.85)).set_delay(4.0)
	# 4. Silence. Let it land.
	tw.tween_interval(3.5)
	# 5. The letter
	tw.tween_callback(func(): game.hud.say(letter_line, 5.5, letter_voice))
	tw.tween_interval(6.5)
	tw.tween_callback(func():
		game.set_cinematic(false)
		cam.hide_face()
		cam.cinematic = false
		cam.look_target = Vector3.INF
		cam.fov = cam.default_fov
		player.can_move = true
		finish())


## t: 0 = where the insert shot ended (in front of the face) .. 1 = behind the shoulder,
## exactly where _orbit() starts. Swings round the side with an outward bulge so it never
## comes near the head; shows the body once the camera is clear of it.
func _pull_back(t: float) -> void:
	var player: PlayerBody = game.player
	var start := _pull_from - _head
	var end := _orbit_offset(0.0)
	var a0 := atan2(start.x, start.z)
	var a := a0 + fposmod(atan2(end.x, end.z) - a0, TAU) * t
	var r0 := Vector2(start.x, start.z).length()
	var r1 := Vector2(end.x, end.z).length()
	var r := lerpf(r0, r1, t) + sin(t * PI) * head_clearance
	player.cam.global_position = _head + Vector3(sin(a) * r, lerpf(start.y, end.y, t), cos(a) * r)
	if not _face_shown and t > 0.3 and r >= head_clearance + 0.25:
		_face_shown = true
		player.reveal_face()


## Camera offset from the head for orbit position t (0 = behind the shoulder, 1 = in front
## of the face, just below it looking up).
func _orbit_offset(t: float) -> Vector3:
	var dir := (-game.player.facing()).rotated(Vector3.UP, t * PI * 0.95)
	return dir * lerpf(1.6, 0.85, t) + Vector3(0, lerpf(0.5, -0.2, t), 0)


func _orbit(t: float) -> void:
	var cam: PlayerCamera = game.player.cam
	cam.global_position = _head + _orbit_offset(t)
	cam.look_target = _head.lerp(_head + Vector3(0, -0.02, 0), t)


func debug_complete() -> void:
	photo.on_interact()
```

Postcondition: file content equals the block above.

---

### S11 — Seated ghosts: shins clear the chair fronts
Measured: the boy's shins were 17 cm inside the school chair, grandma's legs inside the armchair front. Moving the hips 0.11 m forward (local +Z = the way the figure faces) clears both (checked from the side, see F).

**Edit S11.1 — `scenes/memories/drawing_memory.tscn`** (replace block; the original must match exactly once)

Original:
```ini
[node name="SeatPoint" type="Marker3D" parent="BoyAtDesk"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.52, -0.03)
```
Replacement:
```ini
[node name="SeatPoint" type="Marker3D" parent="BoyAtDesk"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.52, 0.08)
```

**Edit S11.2 — `scenes/memories/scarf_memory.tscn`** (replace block; the original must match exactly once)

Original:
```ini
[node name="SeatPoint" type="Marker3D" parent="GrandmaKnitting"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.56, 0)
```
Replacement:
```ini
[node name="SeatPoint" type="Marker3D" parent="GrandmaKnitting"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.56, 0.08)
```

Postcondition: both `SeatPoint` transforms end in `, 0.08)`.

---

### S12 — Lighting: no fake window beams, lighter environment, warm-up scale

**Edit S12.1 — `scenes/objects/house_window.tscn`** (replace block; the original must match exactly once)

Original:
```ini
[node name="MoonlightBeam" type="SpotLight3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 0.80178, 0.59762, 0, -0.59762, 0.80178, 0, 0.55, -0.25)
light_color = Color(0.55, 0.66, 1, 1)
light_energy = 2.0
light_volumetric_fog_energy = 2.5
light_size = 0.6
light_specular = 0.5
spot_range = 7.0
spot_attenuation = 0.8
spot_angle = 32.0

```
Replacement: *(nothing — delete the block, including its trailing blank line)*

**Edit S12.2 — `scenes/main.tscn`** (replace block; the original must match exactly once)

Original:
```ini
ambient_light_energy = 0.14
tonemap_mode = 4
tonemap_exposure = 1.05
ssao_enabled = true
ssao_radius = 1.1
ssao_intensity = 1.8
ssao_power = 1.5
ssil_intensity = 1.1
sdfgi_enabled = true
sdfgi_use_occlusion = true
sdfgi_cascades = 3
sdfgi_min_cell_size = 0.12
sdfgi_bounce_feedback = 0.45
sdfgi_energy = 1.1
```
Replacement:
```ini
ambient_light_energy = 0.18
tonemap_mode = 4
tonemap_exposure = 1.05
ssao_enabled = true
ssao_radius = 0.6
ssao_intensity = 1.0
ssao_power = 1.2
ssil_intensity = 1.1
```

**Edit S12.3 — `scripts/level/room.gd`** (replace block; the original must match exactly once)

Original:
```gdscript
	tw.tween_property(fill_light, "light_energy", energy * 0.6, warm_time)
```
Replacement:
```gdscript
	tw.tween_property(fill_light, "light_energy", energy * 0.9, warm_time)
```

Postconditions: `house_window.tscn` has no `MoonlightBeam`; `main.tscn` has no `sdfgi_` lines and has `ssao_intensity = 1.0`; `room.gd` uses `energy * 0.9` (rooms now start at 0.9, so the old 0.6 factor would make a "warmed" room darker than a frozen one).

---

### S13 — Wire the frozen-memory grade
Prerequisite: S01. `MemoryGrade` is drawn first in the ScreenEffects layer, `GradeCopy` (BackBufferCopy, viewport mode) hands its result to `FilmLook`, which keeps the lens, vignette, grain and face mosaics. `FilmLook` no longer greys the image. All anchors below exist in the current (worn-camera) versions of these files.

**Edit S13.1 — `scripts/characters/ember.gd`** (replace block; the original must match exactly once)

Original:
```gdscript
var _time := 0.0
```
Replacement:
```gdscript
var _time := 0.0


func _ready() -> void:
	add_to_group("colour_source")  # MemoryGrade brings colour back in a halo around the ember
```

**Edit S13.2 — `scenes/systems/screen_effects.tscn`** (replace block; the original must match exactly once)

Original:
```ini
[ext_resource type="Resource" path="res://settings/camera_comfort.tres" id="3_comfort"]
```
Replacement:
```ini
[ext_resource type="Resource" path="res://settings/camera_comfort.tres" id="3_comfort"]
[ext_resource type="Shader" path="res://shaders/memory_grade.gdshader" id="4_grade_shader"]
[ext_resource type="Script" path="res://scripts/systems/memory_grade.gd" id="5_grade"]
```

**Edit S13.3 — `scenes/systems/screen_effects.tscn`** (replace block; the original must match exactly once)

Original:
```ini
[node name="ScreenEffects" type="CanvasLayer"]
```
Replacement:
```ini
[sub_resource type="ShaderMaterial" id="MemoryGradeMaterial"]
shader = ExtResource("4_grade_shader")
shader_parameter/world_sat = 0.3

[node name="ScreenEffects" type="CanvasLayer"]
```

**Edit S13.4 — `scenes/systems/screen_effects.tscn`** (replace block; the original must match exactly once)

Original:
```ini
[node name="FilmLook" type="ColorRect" parent="."]
```
Replacement:
```ini
[node name="MemoryGrade" type="ColorRect" parent="."]
material = SubResource("MemoryGradeMaterial")
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
script = ExtResource("5_grade")

[node name="GradeCopy" type="BackBufferCopy" parent="."]
copy_mode = 2

[node name="FilmLook" type="ColorRect" parent="."]
```

**Edit S13.5 — `scripts/systems/screen_effects.gd`** (replace block; the original must match exactly once)

Original:
```gdscript
## stronger in the dark, warm/cold tint, the grey "frozen memory" look, and the pixelated
## faces of the memory figures.
```
Replacement:
```gdscript
## stronger in the dark, warm/cold tint and the pixelated faces of the memory figures.
## The frozen-memory look itself (moonlit duotone, frost, ember halo, restore ripple) is the
## MemoryGrade child, drawn first; GradeCopy hands its result to FilmLook.
```

**Edit S13.6 — `scripts/systems/screen_effects.gd`** (replace block; the original must match exactly once)

Original:
```gdscript
@onready var mat: ShaderMaterial = film_look.material
```
Replacement:
```gdscript
@onready var mat: ShaderMaterial = film_look.material
@onready var memory_grade: MemoryGrade = $MemoryGrade
```

**Edit S13.7 — `scripts/systems/screen_effects.gd`** (replace block; the original must match exactly once)

Original:
```gdscript
		if mat:
			mat.set_shader_parameter("world_sat", v)
```
Replacement:
```gdscript
		if memory_grade:
			memory_grade.set_world_saturation(v)
```

**Edit S13.8 — `scripts/systems/screen_effects.gd`** (replace block; the original must match exactly once)

Original:
```gdscript
func warm_flash() -> void:
	var tw := create_tween()
```
Replacement:
```gdscript
func warm_flash() -> void:
	memory_grade.ripple()
	var tw := create_tween()
```

**Edit S13.9 — `shaders/camera_fx.gdshader`** (replace block; the original must match exactly once)

Original:
```glsl
	// frozen memory: grey, except bright light sources keep their warmth
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	float keep = max(world_sat, smoothstep(0.55, 1.1, lum));
	c = mix(vec3(lum), c, clamp(keep, 0.0, 1.0));
```
Replacement:
```glsl
	// (The frozen-memory colour grade runs before this pass: ScreenEffects > MemoryGrade,
	//  shaders/memory_grade.gdshader. world_sat stays declared so old materials still load.)
```

Postconditions: `screen_effects.tscn` has nodes in the order `MemoryGrade`, `GradeCopy`, `FilmLook`; `screen_effects.gd` contains `memory_grade.ripple()` and `memory_grade.set_world_saturation(v)`; `camera_fx.gdshader` no longer contains `mix(vec3(lum), c`; `ember.gd` contains `add_to_group("colour_source")`.

---

### S14 — Replace entire file `scripts/objects/interior_door.gd`
Baseline hash `2F261B22254C784E`. Kept: `door_id`, `locked`, `open_angle`, `open_time`, `close_time`, `is_open`, `hinge`, `unlock_and_open()`, `swing()`, doorway safety, group `interior_door`. Changed: `locked` no longer disables the interactable (so the HUD can say "locked"); locked doors don't glow; trying one calls `rattle()` (leaf jerks up to 1.8° toward open and back, `door_slam` played at −14 dB then −19 dB — the latch clack; swap `rattle_sound` if a dedicated clip is added later). New one-way behaviour for `lock_behind_player` (set on FrontDoor in S18).

```gdscript
class_name InteriorDoor
extends Interactable
## INTERIOR DOOR: a hinged door that starts locked and is unlocked by the story.
## Once unlocked the player can open/close it by looking at it and pressing "interact".
## It refuses to close while the player stands in the doorway (DoorwayClearance area).
## A LOCKED door still answers: the prompt says "locked", and trying it makes the leaf jerk
## against the latch with a double clack (rattle()).
## lock_behind_player (the front door): once the player has walked through to the inside and
## is clear of the swing, the door shuts and locks for good - there is no going back out.
##
## How to change it:
##   door_id       -> name the story uses to unlock it (see Memory.unlocks_door_id)
##   open_angle    -> how far it swings open, in degrees
##   open_time / close_time -> swing speed in seconds
##   locked_prompt, rattle_degrees, rattle_time, rattle_sound -> the "it's locked" feedback
##   lock_behind_player, inside_is_negative_z, lock_distance -> the one-way front door
## Rotate the whole scene instance to fit a wall; the hinge is on the DoorHinge node.

## Name used by the story to unlock this door ("front", "kid", "hall", "bed", "parent").
@export var door_id := "front"
## Locked doors can't be opened until the story calls unlock_and_open(); trying one rattles it.
@export var locked := true
@export var open_angle := 100.0
@export var open_time := 1.6
@export var close_time := 1.3
## Prompt shown while looking at the door when it is locked.
@export var locked_prompt := "locked"
## How far the leaf jerks against the latch when someone tries a locked door (degrees).
@export var rattle_degrees := 1.8
## Length of the rattle, seconds.
@export var rattle_time := 0.42
## Clip from assets/audio (no extension), played twice as the latch clacks.
@export var rattle_sound := "door_slam"
## Shut and lock this door once the player has walked through it to the inside.
@export var lock_behind_player := false
## Which side counts as "inside": true = the door's local -Z side (the front door: the house is at -Z).
@export var inside_is_negative_z := true
## The player must be this far from the hinge (metres) before the door swings shut behind them,
## so the leaf never sweeps through the player or the camera.
@export var lock_distance := 1.8

@onready var hinge: Node3D = $DoorHinge
@onready var clearance: Area3D = $DoorwayClearance

var is_open := false
var _swing: Tween
var _rattle: Tween
var _lock_when_clear: Node3D


func _ready() -> void:
	super._ready()
	add_to_group("interior_door")
	clearance.body_exited.connect(_on_clearance_body_exited)


func get_prompt() -> String:
	if locked:
		return locked_prompt
	return "close" if is_open else "open"


## A locked door gets no glow (it is not an invitation), but still reports the hover so the
## HUD shows "locked".
func on_hover() -> void:
	if locked:
		is_hovered = true
		hovered.emit()
		return
	super.on_hover()


func on_interact() -> void:
	super.on_interact()
	if locked:
		rattle()
		return
	if is_open and _player_in_doorway():
		return  # closing would sweep through the player
	swing(not is_open)


## The story beat: unlock the door and swing it open.
func unlock_and_open() -> void:
	locked = false
	swing(true)


## Someone tried a locked door: it jerks against the latch, which clacks twice.
func rattle() -> void:
	if _rattle and _rattle.is_running():
		return
	var rest := hinge.rotation.y
	var a := deg_to_rad(rattle_degrees)
	var step := rattle_time / 6.0
	var sound_pos := hinge.global_position + Vector3(0, 1.0, 0)
	Sound.play_at(rattle_sound, sound_pos, -14.0)
	get_tree().create_timer(rattle_time * 0.45).timeout.connect(func(): Sound.play_at(rattle_sound, sound_pos, -19.0))
	_rattle = create_tween()
	for k in [1.0, 0.15, 0.8, 0.1, 0.45, 0.0]:
		_rattle.tween_property(hinge, "rotation:y", rest + a * k, step).set_trans(Tween.TRANS_SINE)


func swing(open: bool) -> void:
	is_open = open
	if _swing and _swing.is_valid():
		_swing.kill()
	var sound_pos := hinge.global_position + Vector3(0, 1.3, 0)
	Sound.play_at("door_creak", sound_pos, -2.0 if open else -8.0)
	_swing = create_tween()
	_swing.tween_property(hinge, "rotation:y", deg_to_rad(open_angle) if open else 0.0,
		open_time if open else close_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT if open else Tween.EASE_IN)
	if not open:
		_swing.tween_callback(func(): Sound.play_at("door_slam", sound_pos, -16.0))


func _player_in_doorway() -> bool:
	for b in clearance.get_overlapping_bodies():
		if b is CharacterBody3D:
			return true
	return false


## The player stepped out of the doorway: if this is the one-way door, wait until they are
## inside and clear of the swing, then shut and lock it (see _physics_process).
func _on_clearance_body_exited(body: Node3D) -> void:
	if lock_behind_player and not locked and is_open and body is PlayerBody:
		_lock_when_clear = body


func _physics_process(_delta: float) -> void:
	if _lock_when_clear == null:
		return
	var p := _lock_when_clear.global_position
	var local_z := to_local(p).z
	var inside := local_z < 0.0 if inside_is_negative_z else local_z > 0.0
	var h := hinge.global_position
	if inside and Vector2(p.x - h.x, p.z - h.z).length() > lock_distance:
		_lock_when_clear = null
		locked = true
		swing(false)
```

Postcondition: file content equals the block above.

---

### S15 — Door materials: local triplanar, textured, matte
Baseline hashes `657D74400F4FFEAF` (door_wood) and `F4E4CA367774140E` (door_panel). `uv1_world_triplanar` is removed so the texture moves with the leaf.

`materials/door_wood.tres` (replace entire file):
```ini
[gd_resource type="StandardMaterial3D" format=3]

[ext_resource type="Texture2D" path="res://assets/textures/dark_wooden_planks/dark_wooden_planks_diff.jpg" id="1_diff"]
[ext_resource type="Texture2D" path="res://assets/textures/dark_wooden_planks/dark_wooden_planks_nor.jpg" id="2_nor"]
[ext_resource type="Texture2D" path="res://assets/textures/dark_wooden_planks/dark_wooden_planks_rough.jpg" id="3_rough"]

[resource]
resource_name = "door_wood"
albedo_color = Color(1, 0.93, 0.82, 1)
albedo_texture = ExtResource("1_diff")
metallic_specular = 0.3
roughness_texture = ExtResource("3_rough")
normal_enabled = true
normal_scale = 1.4
normal_texture = ExtResource("2_nor")
uv1_scale = Vector3(1.1, 1.1, 1.1)
uv1_triplanar = true
uv1_triplanar_sharpness = 4.0
texture_filter = 5
```

`materials/door_panel.tres` (replace entire file):
```ini
[gd_resource type="StandardMaterial3D" format=3]

[ext_resource type="Texture2D" path="res://assets/textures/dark_wooden_planks/dark_wooden_planks_diff.jpg" id="1_diff"]
[ext_resource type="Texture2D" path="res://assets/textures/dark_wooden_planks/dark_wooden_planks_nor.jpg" id="2_nor"]
[ext_resource type="Texture2D" path="res://assets/textures/dark_wooden_planks/dark_wooden_planks_rough.jpg" id="3_rough"]

[resource]
resource_name = "door_panel"
albedo_color = Color(0.72, 0.6, 0.5, 1)
albedo_texture = ExtResource("1_diff")
metallic_specular = 0.3
roughness_texture = ExtResource("3_rough")
normal_enabled = true
normal_scale = 1.2
normal_texture = ExtResource("2_nor")
uv1_scale = Vector3(1.8, 1.8, 1.8)
uv1_triplanar = true
uv1_triplanar_sharpness = 4.0
texture_filter = 5
```

Postcondition: neither file contains `uv1_world_triplanar`.

---

### S16 — Dev tests for the doors
Adds two automated checks: the front door shuts and locks after `--walktest`, and a locked door rattles and stays shut in `--doortest` (it waits 1 s first: the first headless frames after loading have huge deltas).

**Edit S16.1 — `scripts/dev/dev_tests.gd`** (replace block; the original must match exactly once)

Original:
```gdscript
	var z := player.global_position.z
	print("TEST walk end z=", snappedf(z, 0.01), "  ", "PASS (inside)" if z < -1.0 else "FAIL (stuck)")
```
Replacement:
```gdscript
	var z := player.global_position.z
	print("TEST walk end z=", snappedf(z, 0.01), "  ", "PASS (inside)" if z < -1.0 else "FAIL (stuck)")
	if not from_gate:
		var front: InteriorDoor = game.doors["front"]
		var shut := front.locked and not front.is_open
		print("TEST front door shut and locked behind the player: ", "PASS" if shut else "FAIL (locked=%s open=%s)" % [front.locked, front.is_open])
```

**Edit S16.2 — `scripts/dev/dev_tests.gd`** (replace block; the original must match exactly once)

Original:
```gdscript
func _door_test() -> void:
	var player: PlayerBody = game.player
	var door: InteriorDoor = game.doors["front"]
```
Replacement:
```gdscript
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
```

Postcondition: `dev_tests.gd` contains `TEST front door shut and locked behind the player` and `TEST locked door rattles and stays shut`.

---

### S17 — Register the new class with Godot
`class_name MemoryGrade` is only known after a rescan (see MEMORY/07). Root, PowerShell:
```powershell
$G = "C:\Program Files\Godot\Godot.exe"
& $G --headless --path . --import
Select-String -Path .godot/global_script_class_cache.cfg -Pattern '"MemoryGrade"'
```
**Expected:** no `Parse Error` / `SCRIPT ERROR` lines; the `Select-String` prints one match. If `--import` is rejected, run `& $G --headless --path . --editor --quit` and check the same. If OneDrive locks a file: pause OneDrive sync and rerun.

---

### S18 — Patch `tools/level_builder.gd` and regenerate the level
Prerequisites: S12 (window scene), S14 (`lock_behind_player` must exist on the door script, or the builder's `set()` is silently ignored), S17.

What the patch changes (all inside `level_builder.gd`):
- `_tex_mat` gets `normal_strength` and `specular` parameters.
- All six room wall materials and the ceiling use `painted_plaster_wall`, matte (specular 0.25/0.2), normal 1.5; exterior cladding tiled realistically (scale 0.18) and the inner plaster tuned.
- `GroundMist` covers only z 0.5…40.5 (outside) and joins `outdoor_only`.
- FrontDoor gets `lock_behind_player = true`.
- No ceiling beams; wall lining = wallpaper + skirting only (no wainscot / chair rail / cornice).
- Each room's `RoomFillLight` is a shadowed omni at the ceiling centre (y 2.18), energy 0.9, range from room size, volumetric fog energy 0, under a new `CeilingLamp` pendant (Shade, Bulb, Cord; none casts shadows).
- Rugs 4 mm thick, just above the floor. Kitchen wall cupboard (it went through the wall) removed.
- `_place_props` = minimal story furniture at the exact positions they already had (so memory scenes still line up); the automatic `_settle_props`/`_snap_to_wall` and their constants are deleted.

Kept furniture: Living — sofa, coffee table, armchair (grandma). Kid — day bed, school desk + chair (puzzle, boy), painted shelves, shelf. Kitchen — counter, stove, table, 2 chairs. Hallway — nothing. Parent — bed, nightstand, dresser (photo), rocking chair. Bedroom — day bed, nightstand (alarm clock), table (school notes), chair. (Memory-scene objects such as the coat rack, fireplace, suitcase and items are unaffected.)

1. Save the following script **outside the repo** as `$env:TEMP\patch_level_builder.py` (it refuses to write anything if any anchor does not match exactly once, and checks the hash of the replaced region):
```python
"""Patch tools/level_builder.gd for the IdiotHandOffGuide (steps S-LB).
usage: python patch_level_builder.py <path to level_builder.gd>
Every edit must match exactly once, otherwise nothing is written."""
import hashlib
import sys

path = sys.argv[1]
src = open(path, "rb").read().decode("utf-8")
out = src


def sub(old: str, new: str, label: str) -> None:
    global out
    n = out.count(old)
    if n != 1:
        sys.exit(f"STOP: edit '{label}' matched {n} times (expected 1). Nothing written.")
    out = out.replace(old, new)


# --- 1. _tex_mat: adjustable bump strength and shine --------------------------------------
sub('''## Textured, world-triplanar material (textures from res://assets/textures/<tex>/).
func _tex_mat(mat_name: String, tex := "", tint := Color.WHITE, scale := 0.5, rough := 0.85) -> Material:''',
'''## Textured, world-triplanar material (textures from res://assets/textures/<tex>/).
## normal_strength = how deep the surface bumps look; specular = shine (0.5 = Godot default,
## lower = more matte, e.g. painted plaster).
func _tex_mat(mat_name: String, tex := "", tint := Color.WHITE, scale := 0.5, rough := 0.85,
		normal_strength := 0.9, specular := 0.5) -> Material:''', "tex_mat signature")
sub('''		m.normal_scale = 0.9''', '''		m.normal_scale = normal_strength''', "tex_mat normal")
sub('''	m.uv1_scale = Vector3.ONE * scale
	m.texture_filter''', '''	m.uv1_scale = Vector3.ONE * scale
	m.metallic_specular = specular
	m.texture_filter''', "tex_mat specular")

# --- 2. constants that only the removed auto-placement used -------------------------------
sub('''const WALL_HUNG := ["hanging_picture_frame", "fancy_picture_frame", "wall_clock", "vintage_telephone_wall_clock",
	"ornate_mirror", "dartboard"]
const CEILING := ["Chandelier", "lantern_chandelier", "ceiling_fan"]
const DESK_POS := Vector3(-4.6, 0, -4.15)
const FIRE_Z := -5.75
# Props that belong to a memory scene: placed here only so the others settle around them,
# then removed (their final spot is printed so the memory scene can match it).
const MEMORY_OWNED := ["vintage_suitcase"]''',
'''const FIRE_Z := -5.75
# Props that belong to a memory scene (the scene owns them, so the level must not place them).
const MEMORY_OWNED := ["vintage_suitcase"]''', "constants")
sub('''	_place_props(rooms)
	_settle_props()
''', '''	_place_props(rooms)
''', "initialize settle call")

# --- 3. exterior: ground mist stays outside the house -------------------------------------
sub('''	mist.size = Vector3(90, 2.4, 50)
	mist.position = Vector3(0, 0.6, 12)''',
'''	# Outside only: the volume starts at z 0.5 (just in front of the house) so no mist drifts
	# into the rooms, and OutdoorCulling hides it completely while the camera is indoors.
	mist.size = Vector3(90, 2.4, 40)
	mist.position = Vector3(0, 0.6, 20.5)
	mist.add_to_group("outdoor_only", true)''', "mist")

# --- 4. house shell materials + locked front door -----------------------------------------
sub('''	var clad := _tex_mat("wall_cladding", "exterior_wall_cladding", Color(0.78, 0.8, 0.88), 0.45)
	var plaster := _tex_mat("wall_plaster", "painted_plaster_wall", Color(0.92, 0.9, 0.86), 0.4)''',
'''	var clad := _tex_mat("wall_cladding", "exterior_wall_cladding", Color(0.78, 0.8, 0.88), 0.18, 0.85, 1.3, 0.3)
	var plaster := _tex_mat("wall_plaster", "painted_plaster_wall", Color(0.92, 0.9, 0.86), 0.6, 0.85, 1.4, 0.25)''',
    "shell materials")
sub('''		inst.set("door_id", d[1])
''', '''		inst.set("door_id", d[1])
		if d[1] == "front":
			inst.set("lock_behind_player", true)  # once you are inside there is no way back out
''', "front door lock")

# --- 5. rooms: textured plaster walls, no beams, one shadowed ceiling lamp per room --------
sub('''	_tex_mat("wallpaper_kid", "beige_wall_001", Color(0.8, 0.88, 1.0), 0.5)
	_tex_mat("wallpaper_living", "beige_wall_001", Color(1.0, 0.93, 0.82), 0.5)
	_tex_mat("wallpaper_kitchen", "painted_plaster_wall", Color(0.95, 0.97, 0.88), 0.45)
	_tex_mat("wallpaper_parent", "painted_plaster_wall", Color(1.0, 0.86, 0.82), 0.45)
	_tex_mat("wallpaper_hall", "beige_wall_001", Color(0.95, 0.9, 0.82), 0.5)
	_tex_mat("wallpaper_bedroom", "painted_plaster_wall", Color(0.84, 0.92, 0.86), 0.45)
	var ceiling_m := _col_mat("ceiling_white", Color(0.93, 0.92, 0.9))
	var beam_m := _tex_mat("ceiling_beam_wood", "dark_wooden_planks", Color(0.85, 0.7, 0.58), 1.0, 0.8)''',
'''	# All walls use the detailed plaster texture (beige_wall_001 is a flat single colour, which
	# is what made the walls look plastic-smooth). Matte (low specular) and a deeper bump.
	_tex_mat("wallpaper_kid", "painted_plaster_wall", Color(0.82, 0.9, 1.0), 0.6, 0.85, 1.5, 0.25)
	_tex_mat("wallpaper_living", "painted_plaster_wall", Color(1.0, 0.93, 0.82), 0.6, 0.85, 1.5, 0.25)
	_tex_mat("wallpaper_kitchen", "painted_plaster_wall", Color(0.95, 0.97, 0.88), 0.6, 0.85, 1.5, 0.25)
	_tex_mat("wallpaper_parent", "painted_plaster_wall", Color(1.0, 0.86, 0.82), 0.6, 0.85, 1.5, 0.25)
	_tex_mat("wallpaper_hall", "painted_plaster_wall", Color(0.95, 0.9, 0.82), 0.6, 0.85, 1.5, 0.25)
	_tex_mat("wallpaper_bedroom", "painted_plaster_wall", Color(0.84, 0.92, 0.86), 0.6, 0.85, 1.5, 0.25)
	var ceiling_m := _tex_mat("ceiling_white", "painted_plaster_wall", Color(0.97, 0.96, 0.94), 0.5, 0.9, 0.8, 0.2)''',
    "room materials")
sub('''		var beams := _group(room, "CeilingBeams")
		var bx: float = r[2] + 0.75
		while bx < r[3] - 0.4:
			_box(beams, "Beam", Vector3(0.16, 0.2, dpt - 0.25), Vector3(bx, WALL_H - 0.12, cz), beam_m)
			bx += 1.5
''', '', "beams")
sub('''		var fill := _light(room, "RoomFillLight", Vector3(cx, 1.5, cz), Color(0.6, 0.65, 0.8), 0.66, 6.0)
		fill.omni_attenuation = 1.4
		fill.light_size = 0.4
		fill.light_specular = 0.2
		fill.distance_fade_enabled = true
		fill.distance_fade_begin = 16.0''',
'''		# The room's ONE light: a pendant lamp in the middle of the ceiling (_pendant).
		# Every shadow in the room falls away from that lamp, so the lighting reads as real.
		var lamp_pos := Vector3(cx, WALL_H - 0.62, cz)
		var fill := _light(room, "RoomFillLight", lamp_pos, Color(0.62, 0.68, 0.86), 0.9, maxf(w, dpt) * 0.85 + 1.0, true)
		fill.omni_attenuation = 1.0
		fill.light_specular = 0.25
		fill.shadow_blur = 1.5
		fill.light_volumetric_fog_energy = 0.0
		fill.distance_fade_enabled = true
		fill.distance_fade_begin = 16.0
		_pendant(room, lamp_pos)''', "room light")
sub('''		_box(rooms_root.get_node(room_name), "Rug", rg[3], rg[4], _tex_mat(rg[0], "fabric_pattern_05", rg[1], rg[2], 0.95))''',
'''		# Paper-thin, just above the floor: furniture legs stand on it instead of sinking in.
		var rug_size: Vector3 = rg[3]
		var rug_pos: Vector3 = rg[4]
		_box(rooms_root.get_node(room_name), "Rug", Vector3(rug_size.x, 0.004, rug_size.z), Vector3(rug_pos.x, 0.063, rug_pos.z),
			_tex_mat(rg[0], "fabric_pattern_05", rg[1], rg[2], 0.95))''', "rugs")
sub('''	_sketchfab(kprops, "KitchenCupboard", "kitchen_cupboard", Vector3(4.85, 1.55, -4.2), 0.0, false).remove_meta("size")
''', '', "kitchen cupboard")

# --- 6. wall lining: wallpaper + skirting only --------------------------------------------
sub('''## Wallpaper, wainscot, rails and skirting on the inside of each wall, leaving doorway gaps.''',
    '''## Wallpaper and skirting on the inside of each wall, leaving doorway gaps (kept minimal).''', "lining doc")
sub('''	var wood := _tex_mat("wainscot_wood", "dark_wooden_planks", Color(1.0, 0.82, 0.68), 1.3, 0.7)
	var trim := _col_mat("wall_trim_wood", Color(0.32, 0.21, 0.14))
''', '', "lining materials")
sub('''			_box(side, "Wainscot", sz.call(0.03, 0.95), Vector3(pos.x, 0.475, pos.z) + off * 1.12, wood)
			_box(side, "ChairRail", sz.call(0.06, 0.05), Vector3(pos.x, 0.97, pos.z) + off * 1.2, trim)
			_box(side, "Cornice", sz.call(0.07, 0.1), Vector3(pos.x, WALL_H - 0.08, pos.z) + off * 1.2, trim)
''', '', "lining boxes")

# --- 7. props: minimal story furniture at fixed spots; auto-placement removed --------------
a = out.index("func _place_props(rooms_root: Node3D) -> void:")
b = out.index("func _report_and_remove_memory_owned() -> void:")
region = out[a:b]
if hashlib.sha256(region.encode()).hexdigest() != "28d95efd04ee8aa73dda5a70b877115907f5bfba2ab645478eaec0c3a52523c0":
    sys.exit("STOP: the _place_props.._settle_props region differs from the observed baseline. Nothing written.")
NEW_PROPS = '''func _place_props(rooms_root: Node3D) -> void:
	# Story furniture only - kept minimal on purpose (no clutter that isn't part of a memory).
	# [id, position, rotation (deg), collide]. Real-world scale. 0 deg = front faces +Z.
	# Positions are FINAL (there is no automatic shuffling any more). Memory scenes put people
	# and objects on some of these (armchair, desk + chair, dresser, nightstands, bedroom table),
	# so moving one means moving that memory scene's nodes too (MEMORY/04-memories.md).
	# After any change run the overlap check in MEMORY/06-recipes.md.
	var L := [
		# ---------------- LIVING - grandma's armchair (ScarfMemory/GrandmaKnitting sits in it)
		["painted_wooden_sofa", Vector3(1.5, 0.06, -3.946342), 0, true],
		["CoffeeTable_01", Vector3(0.7107189, 0.06, -2.85), 0, true],
		["ArmChair_01", Vector3(-1.5430429, 0.06, -2.42159), 55, true],
		# ---------------- KID ROOM - the little desk (DrawingMemory puzzle + BoyAtDesk)
		["vintage_day_bed", Vector3(-6.912612, 0.06, -3.35), 90, true],
		["SchoolDesk_01", Vector3(-4.6, 0.06, -4.140611), 0, true],
		["SchoolChair_01", Vector3(-4.6, 0.06, -3.5), 180, true],
		["painted_wooden_shelves", Vector3(-3.45, 0.06, -3.9), -90, true],
		["Shelf_01", Vector3(-5.95, 0.06, -4.2), 0, true],
		# ---------------- KITCHEN - counter run (KitchenCounter is added in _build_rooms), table
		["electric_stove", Vector3(3.45, 0.06, -4.0161896), 0, true],
		["WoodenTable_02", Vector3(4.688613, 0.06, -1.9), 90, true],
		["painted_wooden_chair_02", Vector3(4.2310486, 0.06, -1.9), 90, true],
		["painted_wooden_chair_02", Vector3(5.2, 0.06, -1.9), -90, true],
		# ---------------- HALLWAY - a bare corridor to the study door (no furniture)
		# ---------------- PARENT ROOM - fireplace (memory scene), bed, the photo dresser
		["GothicBed_01", Vector3(-5.3, 0.06, -7.82), 0, true],
		["ClassicNightstand_01", Vector3(-6.85, 0.06, -8.627904), 0, true],
		["vintage_wooden_drawer_01", Vector3(-3.9034564, 0.06, -7.982443), -90, true],
		["Rockingchair_01", Vector3(-4.7, 0.06, -5.1352453), -110, true],
		# ---------------- BEDROOM - the room the player left (SuitcaseMemory items rest on these)
		["vintage_day_bed", Vector3(5.412612, 0.06, -7.8537226), -90, true],
		["ClassicNightstand_01", Vector3(4.55, 0.06, -8.627904), 0, true],
		["WoodenTable_01", Vector3(2.9, 0.06, -4.9885874), 180, true],
		["painted_wooden_chair_01", Vector3(2.9, 0.06, -5.617087), 0, true],
	]
	for it in L:
		var room: Array = _room_of(it[1])
		var props_node := rooms_root.get_node("%s/Props" % room[4])
		var p := _prop(props_node, it[0], it[1], it[2], it[3])
		if p:
			_props.append(p)


func _room_of(pos: Vector3) -> Array:
	for r in ROOMS:
		if pos.x > r[2] and pos.x < r[3] and pos.z > r[4] and pos.z < r[5]:
			return [r[2], r[3], r[4], r[5], r[0]]
	return []


## A plain pendant lamp hanging from the ceiling: cord, open shade, glowing bulb.
## light_pos = where the room's light sits (just under the bulb). Shade, bulb and cord cast
## no shadow, so the ceiling stays softly lit instead of going pitch black.
func _pendant(room: Node3D, light_pos: Vector3) -> void:
	var lamp := _group(room, "CeilingLamp")
	var shade_m := _col_mat("lamp_shade", Color(0.18, 0.16, 0.14)) as StandardMaterial3D
	shade_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	ResourceSaver.save(shade_m, shade_m.resource_path)
	var bulb_m: Material = _mats.get("lamp_bulb")
	if bulb_m == null:
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(1.0, 0.95, 0.85)
		bm.emission_enabled = true
		bm.emission = Color(1.0, 0.9, 0.75)
		bm.emission_energy_multiplier = 2.5
		bulb_m = _save_mat("lamp_bulb", bm)
	var shade_mesh := CylinderMesh.new()
	shade_mesh.top_radius = 0.07
	shade_mesh.bottom_radius = 0.2
	shade_mesh.height = 0.18
	shade_mesh.cap_bottom = false
	var shade := MeshInstance3D.new()
	shade.name = "Shade"
	shade.mesh = shade_mesh
	shade.material_override = shade_m
	shade.position = light_pos + Vector3(0, 0.12, 0)
	shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lamp.add_child(shade)
	var bulb_mesh := SphereMesh.new()
	bulb_mesh.radius = 0.045
	bulb_mesh.height = 0.09
	var bulb := MeshInstance3D.new()
	bulb.name = "Bulb"
	bulb.mesh = bulb_mesh
	bulb.material_override = bulb_m
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bulb.position = light_pos + Vector3(0, 0.08, 0)
	lamp.add_child(bulb)
	var cord_top := WALL_H - 0.05
	var cord_bottom := light_pos.y + 0.21
	var cord := _box(lamp, "Cord", Vector3(0.012, cord_top - cord_bottom, 0.012), Vector3(light_pos.x, (cord_top + cord_bottom) * 0.5, light_pos.z), shade_m)
	cord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


'''
out = out[:a] + NEW_PROPS + out[b:]

open(path, "wb").write(out.encode("utf-8"))
print("level_builder.gd patched OK")
```
2. Run, in the root:
```powershell
python "$env:TEMP\patch_level_builder.py" tools/level_builder.gd
$G = "C:\Program Files\Godot\Godot.exe"
& $G --headless --path . -s res://tools/level_builder.gd
Remove-Item materials/level/ceiling_beam_wood.tres, materials/level/wainscot_wood.tres, materials/level/wall_trim_wood.tres -Confirm:$false
foreach ($p in 'lock_behind_player = true', 'MoonlightBeam', 'node name="CeilingLamp"', 'node name="GroundMist".*outdoor_only') { (Select-String -Path scenes/level/house_level.tscn -Pattern $p | Measure-Object).Count }
Select-String -Path scenes/level/house_level.tscn -Pattern "ceiling_beam_wood|wainscot_wood|wall_trim_wood|Wainscot|ChairRail|Cornice|CeilingBeams" | Measure-Object | Select-Object -ExpandProperty Count
```
**Expected:**
- `level_builder.gd patched OK`.
- Builder prints 7 `PLACED ...` lines (same positions as before, e.g. `PLACED SchoolDesk_01 pos=(-4.6, 0.06, -4.140611)`) and `level_builder: OK nodes=1461`.
- The four counts: `1`, `0`, `6`, `1` (front door locks behind you; no window beams; one pendant per room; mist is outdoor-only). Next count: `0` (no trims/beams left).
- `materials/level/` now has 26 `.tres` files, including `lamp_shade.tres` and `lamp_bulb.tres`.

If the patch script prints `STOP`, nothing was written: report the message. If the builder prints a `SCRIPT ERROR`: run `git checkout -- tools/level_builder.gd scenes/level/house_level.tscn materials/level` to restore (only files this step touches) and report.

---

### S19 — Update the MEMORY knowledge base
Save as `$env:TEMP\memory_update.py` (outside the repo) and run `python "$env:TEMP\memory_update.py" .` from the root. It writes nothing if any block does not match exactly once.
````python
"""MEMORY/ updates for the house-fixes guide (step S16), as (path, old, new)."""
MEM = []


def M(path, old, new):
    MEM.append((path, old, new))


M("MEMORY/02-architecture.md", '''| `outdoor_only` | set in scenes (Snowfall, forest, foliage) | OutdoorCulling |
''', '''| `outdoor_only` | set in scenes (Snowfall, forest, foliage, GroundMist) | OutdoorCulling |
| `colour_source` | `Ember._ready` | MemoryGrade (colour halo around the ember) |
''')
M("MEMORY/02-architecture.md", '''| release_mouse | Esc | button 4 (Back) |
''', '''| release_mouse | Esc | button 4 (Back) |
| rotate_item | R (hold) | button 3 (Y) — while holding a SuitcaseMemory item, mouse/stick turn the item |
''')
M("MEMORY/03-scripts-reference.md", '''| interior_door.gd | InteriorDoor / Interactable | locked hinged door; open/close when unlocked; won't close on player | — | `door_id, locked, unlock_and_open(), swing(open)`; nodes `DoorHinge`, `DoorwayClearance` |''',
  '''| interior_door.gd | InteriorDoor / Interactable | hinged door; locked = prompt "locked" + `rattle()` (jerk + double clack, no glow); open/close when unlocked; won't close on player; `lock_behind_player` (FrontDoor) shuts + locks once the player is inside and `lock_distance` from the hinge | — | `door_id, locked, unlock_and_open(), swing(open), rattle()`; nodes `DoorHinge`, `DoorwayClearance` |''')
M("MEMORY/03-scripts-reference.md", '''| packable_item.gd | PackableItem / Interactable | bedroom belonging | chosen(item) | `memory_line, spin(delta), fly_into(point)`; child `ItemModel` |''',
  '''| packable_item.gd | PackableItem / Interactable | bedroom belonging | chosen(item) | `memory_line, turn_by(amount, view_basis), fly_into(point)`; child `ItemModel` |''')
M("MEMORY/03-scripts-reference.md", '''Signal `stepped(on_snow)`. Vars: `can_move` (also toggles raycast), `look_scale`, `target_yaw/pitch`, `auto_input` (tests).''',
  '''Signal `stepped(on_snow)`. Vars: `can_move` (also toggles raycast), `holding_item` (no walking/interacting, looking stays free;
with `rotate_item` held the mouse/stick fill `item_turn` instead of turning the view), `look_scale`, `target_yaw/pitch`, `auto_input` (tests).''')
M("MEMORY/03-scripts-reference.md", '''**room.gd** (`Room`) — `room_id`, `warm_up(energy)` tweens `RoomFillLight`. Adds itself to group `room`.''',
  '''**room.gd** (`Room`) — `room_id`, `warm_up(energy)` tweens `RoomFillLight` (the room's one shadowed pendant light) to `energy * 0.9`. Adds itself to group `room`.''')
M("MEMORY/03-scripts-reference.md", '''| debug_model.gd | Dumps node tree of `assets/mixamo/player_idle.fbx` (edit path to inspect others). |''',
  '''| debug_model.gd | Dumps node tree of `assets/mixamo/player_idle.fbx` (edit path to inspect others). |
| overlap_check.gd | Reports meshes passing through each other in the house (level + memory scenes). See 06 R12. |''')
M("MEMORY/03-scripts-reference.md", '''## Level (`scripts/level/`)''', '''**memory_grade.gd** (`MemoryGrade`, ColorRect, child of ScreenEffects, drawn before `GradeCopy` + `FilmLook`) — the frozen-memory
look (memory_grade.gdshader): moonlit blue/silver duotone, frost breathing in from the edges, colour halo around the
`colour_source` node (ember; hidden by walls), `ripple()` = warm ring of colour on restore. API `set_world_saturation(v)`
(called by `ScreenEffects.world_saturation`), `ripple()` (called by `ScreenEffects.warm_flash`). PlayerCamera also has `hide_face()`
(undo `reveal_face()`; PhotoMemory calls it at the end).

## Level (`scripts/level/`)''')
M("MEMORY/04-memories.md", '''Item `chosen` → lift in front of camera (tween), caption = `item.memory_line`, prompt "pack it". Next interact (polled in
`_process`, not via raycast) packs it.''', '''Item `chosen` → `player.holding_item = true`, item rises into view and then follows the camera every frame (`hold_offset`);
the player can look around freely; holding `rotate_item` (R / Y) turns the item (`player.item_turn` → `PackableItem.turn_by`).
Caption = `item.memory_line`, prompt "pack it   hold R / Y to turn it". Next interact (polled in `_process`, not via raycast) packs it.''')
M("MEMORY/04-memories.md", '''pull back over shoulder → `player.reveal_face()` (camera now renders render-layer 2) → orbit to face → letter voice `v_letter`.''',
  '''swing round the side to behind the shoulder (`_pull_back`, keeps `head_clearance` from the head; the body is shown only once
the camera is clear) → `player.reveal_face()` → orbit to face → letter voice `v_letter` → `cam.hide_face()` (body hidden again).''')
M("MEMORY/04-memories.md", '''## Memory figures (ghost people)''', '''Seated ghosts: `GrandmaKnitting/SeatPoint` z = 0.08 and `BoyAtDesk/SeatPoint` z = 0.08 (local, forward) so their
shins clear the front of the armchair / school chair. Re-check by eye if a chair or figure model changes.

## Memory figures (ghost people)''')
M("MEMORY/05-assets-shaders-audio.md", '''| interact_highlight.gdshader |''', '''| memory_grade.gdshader | canvas_item | ScreenEffects `MemoryGrade` (before `GradeCopy` BackBufferCopy + `FilmLook`) | frozen look: `world_sat`, `shadow_tint`, `highlight_tint`, `frozen_contrast`, `frost`, `frost_breath`, `ember` (vec4 px/radius/strength), `ripple`, `ripple_hold`, `ripple_color`. camera_fx no longer greys the image |
| interact_highlight.gdshader |''')
M("MEMORY/05-assets-shaders-audio.md", '''Builder RNG seed 2026 → deterministic forest/props.''', '''Builder RNG seed 2026 → deterministic forest/props.
Interior (kept minimal on purpose): walls = textured `painted_plaster_wall` (matte, deeper normal) + skirting only; no beams,
wainscot, chair rails, cornices or clutter props. Only story furniture, at fixed positions listed in `_place_props` (no auto
"settle" any more). Lighting: each room has ONE light, `RoomFillLight`, shadowed, under a plain pendant (`CeilingLamp`:
Shade/Bulb/Cord, no shadows); windows have no lights (their glass is opaque, so moonbeams through them were fake);
`GroundMist` covers only z > 0.5 (outside) and is in `outdoor_only`. Environment: no SDFGI (it leaked through the 0.2 m walls),
lighter SSAO. Doors use object-local triplanar wood (`materials/door_wood.tres`, `door_panel.tres`) so the grain moves with the leaf.''')
M("MEMORY/06-recipes.md", '''## R11. Finish any change''', '''## R12. Check that nothing passes through anything
```powershell
& "C:\\Program Files\\Godot\\Godot.exe" --headless --path . -s res://tools/overlap_check.gd
```
Last line must be `overlap_check: 0 problem(s)`. `known` lines (the study door set into the hallway wall) are fine. Run it
after moving props, regenerating the level (R8) or moving memory objects. Ghost figures are not checked: look at seated
figures from the side in the editor.

## R11. Finish any change''')
M("MEMORY/07-gotchas-and-learnings.md", '''## Repo / tooling''', '''- **White/grey transparent blob in the middle of rooms** → the exterior `GroundMist` FogVolume reached into the house and
  the room lights lit it up (plus window spotlights with volumetric fog energy) → keep fog volumes outside (z > 0.5) and in
  `outdoor_only`; interior lights use `light_volumetric_fog_energy = 0`.
- **Walls look plastic / "too smooth"** → `beige_wall_001_diff.jpg` is a flat single colour → use `painted_plaster_wall`,
  low `metallic_specular`, normal ~1.5.
- **Texture slides across a door while it swings** → world-triplanar material on a moving mesh → use object triplanar.
- **Lighting looks random** → several unrelated lights per room (centre fill + fake window moonbeams) with no shadows, plus
  SDFGI leaking through thin walls → one shadowed light per room at a visible lamp.
- **Props buried in furniture after regenerating** → the old builder "settle" moved furniture but not the things on it →
  props are now placed at fixed positions; verify with R12.
- **Second camera shows the inside of the player's head** → every Camera3D other than PlayerCamera needs
  `cull_mask = 1048573` (render layer 2 off); and call `PlayerCamera.hide_face()` after any `reveal_face()` cutscene.
- **Timing-based dev tests flaky right after load** → headless first frames have huge deltas; wait ~1 s before sampling tweens.

## Repo / tooling''')
M("MEMORY/CHANGELOG.md", '''## 2026-11-26
''', '''## 2026-11-26
- **House fixes (IdiotHandOffGuide-house-fixes.md)** — Owner feedback round: textured matte plaster walls + local-triplanar
  doors; locked doors say "locked" and rattle, front door shuts + locks behind you (no exiting); minimal story-only furniture
  at fixed spots (no clipping: kitchen items, lamp, pillows, books, cupboard through wall, desk in wall, seated ghosts'
  legs, photo layers); wainscot/rails/cornices/beams removed (corner z-fighting gone); hold-an-item lets you look around,
  hold R / Y to turn it; new frozen-memory grade (moonlit duotone, breathing frost, ember colour halo, restore ripple);
  ground mist kept outside (the white blob); one shadowed pendant light per room, fake window moonbeams removed, SDFGI off;
  puzzle camera no longer sees the player's head, body hidden again after the photo reveal, pull-back swings round the
  head. New `tools/overlap_check.gd`. (level_builder.gd → house_level.tscn + materials/level, interior_door.gd,
  player_body.gd, player_camera.gd, packable_item.gd, suitcase_memory.gd, photo_memory.gd, ember.gd, room.gd,
  screen_effects.gd/.tscn, memory_grade.gd/.gdshader, camera_fx.gdshader, house_window.tscn, photo_frame.tscn,
  torn_drawing_puzzle.tscn, drawing/scarf_memory.tscn, main.tscn, door_wood/door_panel.tres, project.godot, dev_tests.gd)
''')
M("MEMORY/03-scripts-reference.md", '''| level_builder.gd (978 lines) |''', '''| level_builder.gd |''')


if __name__ == "__main__":
    import sys
    root = sys.argv[1]
    texts = {}
    for path, old, new in MEM:
        full = root + "/" + path
        s = texts.get(full) or open(full, "rb").read().decode("utf-8")
        n = s.count(old)
        if n != 1:
            sys.exit(f"STOP: {path} block matched {n} times (expected 1): {old[:60]!r}. Nothing written.")
        texts[full] = s.replace(old, new)
    for full, s in texts.items():
        open(full, "wb").write(s.encode("utf-8"))
    print("MEMORY updated OK:", len(MEM), "edits")
````
**Expected:** `MEMORY updated OK: 17 edits`. Postcondition: `MEMORY/CHANGELOG.md` contains `House fixes (IdiotHandOffGuide-house-fixes.md)`; `MEMORY/06-recipes.md` contains `## R12.`.

---

## E. Verification and failure handling

Root, PowerShell, `$G = "C:\Program Files\Godot\Godot.exe"`. Use headless runs for PASS/FAIL (windowed runs grab the mouse and can disturb ray checks, see MEMORY/07).

**V1 — story test (R6, R10–R12):**
```powershell
& $G --headless --path . -- --storytest
```
Every `TEST` line ends in `PASS`; `TEST doors open: ["front", "kid", "hall", "bed", "parent"]`; `TEST saturation at end: 1.0`; `TEST story finished`. No `SCRIPT ERROR` / `Parse Error`.

**V2 — doors (R2a, R2b):**
```powershell
& $G --headless --path . -- --walktest
& $G --headless --path . -- --doortest
```
Walktest: `TEST walk end z=... PASS (inside)` and `TEST front door shut and locked behind the player: PASS`. Doortest: `TEST locked door rattles and stays shut: PASS`, `TEST ray at FrontDoor: FrontDoor  PASS`, `door open after unlock: 100`, `after interact (close): 0`, `(open): 100`, `after walking away (should stay open): 100`.

**V3 — known pre-existing failure (not part of this change):** `--walktest --gate` prints `FAIL (stuck)` at z=3.0 on the baseline too (MEMORY/07). Report it as pre-existing if seen.

**V4 — nothing passes through anything (R3):**
```powershell
& $G --headless --path . -s res://tools/overlap_check.gd
```
Takes about a minute. Expected: exactly two `known` lines for `DoorMemory/StudyDoor` (set into the hallway wall on purpose), no `OVERLAP` lines, last line `overlap_check: 0 problem(s)`.

**V5 — structure (R5, R9, R13):**
```powershell
Select-String -Path scenes/level/house_level.tscn -Pattern 'type="OmniLight3D"' | Measure-Object | Select-Object -ExpandProperty Count
Select-String -Path scenes/level/house_level.tscn -Pattern 'parent="Rooms/[A-Za-z]+/Props"' | Measure-Object | Select-Object -ExpandProperty Count
git status --short
```
Expected: `8` (6 room lights + porch lantern + street lamp); `21` (20 furniture wrappers + KitchenCounter); status lists only the files in C (plus the new `.uid` files, if Godot created them).

**V6 — shaders compile (R7, R12):** headless runs use a dummy renderer and never compile shaders, so run once with a window:
```powershell
& $G --path . -- --storytest 2>&1 | Select-String "SHADER ERROR","SCRIPT ERROR","Parse Error"
```
Expected: no output (ignore PASS/FAIL of this windowed run; V1 is authoritative).

**By-eye checks for the owner (play normally, `& $G --path .`):**
- **M1** Walls show soft plaster texture, not shiny; open/close a door — the wood grain stays put on the leaf.
- **M2** Before the scarf is knitted, look at the kid-room door: prompt `locked`, no glow; press E: it jerks and clacks, stays shut. Walk in through the front door and on into the living room: the door closes behind you; go back and try it: `locked` + rattle.
- **M3** Kid room: the boy at the desk — legs in front of the chair, not through it. Living room: grandma's legs clear of the armchair. Parent room: the face-down photo lies on the dresser, nothing poking into it. No objects buried in furniture.
- **M4** Walk along walls and look into corners: no flickering stripes.
- **M5** Rooms are sparse: only the listed furniture.
- **M6** Bedroom memory: pick up an item — you can look all around while it stays in front of you; hold R and move the mouse to turn it (gamepad: hold Y + right stick); E packs it.
- **M7** Grey phases look moonlit blue with frost slowly breathing at the screen edges; colour glows around the ember; finishing a memory sends a warm ring of colour outward.
- **M8** No white haze blob in any room; each room lit from its pendant, shadows consistent; no bright patches under windows.
- **M9** Drawing puzzle: the camera glides from your eyes to the desk without showing hair/inside of the head; photo memory: the camera swings round you (never through the head); after it ends, looking down shows no body.

**Recovery (only for files this guide touches):** `git checkout -- <path>` restores one file to the baseline; for S18 use the command given there. Never `git reset --hard` or `git clean` (other work may be present).

---

## F. Completion report contract and author validation

**Executor reports:** applied step IDs; changed files (`git status --short`); each V check with the command and the actual `TEST`/result lines; skipped checks and why; any STOP messages; M1–M9 handed to the owner (not claimed). Complete = S01–S19 applied and V1, V2, V4, V5, V6 as expected. V3 is informational.

**What the author actually ran (on a full scratch copy of the project at `9d83308`, not on the real checkout):**
- Confirmed `tools/level_builder.gd` regenerates the committed `house_level.tscn` exactly (node/transform diff: 0 lines), so regenerating is safe.
- Measured the problems before fixing (mesh-inside-mesh probe): WineBottles/MetalJug/CuttingBoard/Onion/Spoon/Bowl 90–100 % inside KitchenCounter; KitchenCupboard 0.48 m into MiddleWall; SideTable into the kitchen wall and the sofa; SchoolDesk into the kid-room lining; VintageOilLamp in ClassicConsole; ThrowPillows 52 % in the sofa and in both day beds; Ukulele, WickerBasket, Candlestick, DryBranches, Stationery, BookEncyclopediaSet, DeskLampArm sunk; PhotoFrame 25 % in the dresser; Postcards in the display shelves; BoyAtDesk shins 17.5 cm inside SchoolChair; GrandmaKnitting legs inside ArmChair; wall-hung WallClock/Dartboard in the lining. Renders showed the bright mist/beam blobs, black kitchen-counter items, unshadowed lighting.
- Applied S01–S19 exactly as written to the scratch copy (every anchor matched once), ran S17 import and S18 regenerate (`level_builder: OK nodes=1461`, `lock_behind_player = true` present once).
- Results there: storytest all PASS (7 memories, 4 ray checks, doors open front/kid/hall/bed/parent, saturation 1.0); walktest PASS + `front door shut and locked behind the player: PASS`; doortest all PASS incl. `locked door rattles and stays shut: PASS`; `overlap_check: 0 problem(s)` (2 known StudyDoor lines); windowed run: no SHADER/SCRIPT/Parse errors; renders of all six rooms showed the duotone grade, ember halo, ripple, one coherent pendant light per room, no blobs, ghosts' legs clear (side views at seat z −0.03 / 0.08 / 0.16 compared; 0.08 chosen).
- `--walktest --gate` FAILs identically on the untouched baseline (pre-existing).
- Not verified by the author: the hold-and-look feel with a real mouse/gamepad (M6), audio of the rattle (M2), and anything on the real checkout.
