# 07 — Gotchas & learnings

Format: **Symptom → Cause → Fix.** Add new ones at the bottom of the right section.

## Models & animation
- **Skinned FBX character disappears at screen edges / some angles** → FBX skinned meshes carry a tiny offset
  bind-space AABB, renderer culls them → `ModelUtils.fix_cull(model)` (extra_cull_margin 16384). Call it on every new character.
- **Need idle + walk on one character** → Mixamo exports one animation per FBX → PlayerAnimator copies the clip from
  `walk_animation` FBX into an AnimationLibrary "player". Same pattern for any extra clip.
- **Measured size of a skinned mesh is wrong** → skinned meshes draw in bind space, node transform doesn't apply →
  `ModelUtils.measure` already special-cases `mi.skin`.
- **Attached item (scarf) is huge/tiny on the character** → skeleton carries the FBX import scale → divide by
  `skel.global_transform.basis.get_scale().x` (see player_scarf.gd). Also wait one frame before attaching to bones.
- **Mixamo bone names** are `mixamorig_Head`, `mixamorig_Neck`, `mixamorig_Hips` (underscore, not colon) after import.
- **Scarf mesh not found warning** → `ScarfCoatRack.scarf_mesh_path` must point into the imported glb's internal tree;
  re-check it if the glb is re-exported (use tools/debug_model.gd to list nodes).

## Interaction & input
- **Can't interact with an object** → check: script calls `super._ready()`; collision shape exists; `enabled` true;
  object is not behind World geometry (ray mask includes World so walls block); within 2.2 m;
  collider's Interactable is ≤4 parents up from the hit body.
- **Interaction stops working in a cutscene** — intended: `player.can_move = false` disables the raycast.
  Always set it back to `true` at the end of a memory/cutscene.
- **E does two things** — it is `interact` *and* `needle_right`. Fine for the scarf rack; beware when adding new needle-like actions.
- **Puzzle pieces got hovered by the normal ray** → they live on physics layer 4 which the InteractionRaycast doesn't scan; keep it that way.
- **Mouse stuck visible / captured** → puzzle sets VISIBLE then CAPTURED; title captures on continue; Esc (`release_mouse`) frees it;
  clicking re-captures only when `can_move`.

## Story / scene wiring
- **Story order** = child order of `Main/Memories`. Reordering nodes reorders the game.
- **Door doesn't open after a memory** → `unlocks_door_id` must equal an `InteriorDoor.door_id` (string match, case-sensitive).
  FrontDoor uses the default `"front"`.
- **Room doesn't warm** → `room_id` mismatch or `warms_room` false.
- **Memory start needs player already inside a trigger** → `body_entered` won't fire; re-check `get_overlapping_bodies()` in
  `begin()` (Arrival does this).
- **Hard-coded node paths across scenes**: PhotoMemory uses `player.get_node("PlayerCamera/ColdBreath")`;
  DevTests uses fixed world positions. Renaming/moving those breaks them silently.
- **Groups are strings** (`room`, `interior_door`, `memory_face`, `outdoor_only`) — grep before renaming.

## Rendering
- **Player sees own body** → player meshes must be on render layer 2 (done automatically in `_hide_body_from_camera`);
  anything added under BodyPivot at runtime after `_ready` is NOT moved — set its layer yourself.
- **Prop doesn't turn grey with the story** → plain StandardMaterial3D ignores `world_sat`; only the screen-space filter greys it.
  Wrap in `SnowyProp` or use a shader with `global uniform float world_sat`.
- **Face pixelation**: max 4 faces at once (`faces[4]` uniform), only within 14 m and line-of-sight.
- **Sky letters blurred by depth-of-field** → Label3D needs `ALPHA_CUT_OPAQUE_PREPASS` to write depth (title_sequence.gd).
- **Indoors frame-rate** — OutdoorCulling hides `outdoor_only` nodes when camera z < −0.3. Put heavy outdoor stuff in that group.
- **Mouse clicks miss in a screen-space-distorted view** → `project_ray_origin(mouse)` uses the flat image but the
  player sees the bent one → ScreenEffects turns the lens off for every camera that is not `PlayerCamera`. Keep any
  mouse-driven mini-game on its own camera.
- **Face mosaic / any screen marker drifts off target with the lens on** → `unproject_position` returns flat pixels →
  in the shader compute the bent UV first, then test markers against it (see camera_fx `lens_uv`).
- **New `class_name` "not declared" when running headless tests** → the global class cache is only rebuilt by the
  editor → run `Godot --headless --path . --import` once after adding a class.
- **Hard-coded FOV numbers in cutscenes** → title used `70.0` while `default_fov` changed → return to `cam.default_fov`.
- **Windowed `--storytest` ray check FAILs at random (PhotoFrame / Fireplace)** → the window captures the real mouse, so any
  mouse/gamepad input changes `target_yaw`/`pitch` during the 0.3 s check → use headless runs for PASS/FAIL; use a windowed
  run only to catch `SHADER ERROR` (headless uses a dummy renderer and never compiles shaders).
- **`--walktest --gate` printed `FAIL (stuck)` at z=3.0** → the test walked 7 s (12.25 m) but gate→inside is 16 m. Fixed:
  the gate run now walks 600 physics frames (10 s).

- **White/grey transparent blob in the middle of rooms** → the exterior `GroundMist` FogVolume reached into the house and
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
  `cull_mask = PlayerBody.CAMERA_MASK_WITHOUT_BODY` (set it in code, don't type 1048573); and call
  `PlayerCamera.hide_face()` after any `reveal_face()` cutscene.
- **A door that must never let the player back out** → reopening it when someone stands in the doorway (needed so the
  leaf never closes onto them) also lets them walk out. `InteriorDoor` switches on `OutsideBlocker` (StaticBody just
  outside the doorway) the moment the one-way close starts; covered by `--doortest`.
- **Timing-based dev tests flaky right after load** → headless first frames have huge deltas; wait ~1 s before sampling tweens.

## Repo / tooling
- **Push rejected: file > 100 MB** → big Poly Haven trees are gitignored (`pine_tree_01`, `pine_sapling_medium`). Check sizes before adding assets.
- **level_builder overwrites hand edits** to `house_level.tscn` and `materials/level/`. Don't run unless asked.
- **Folder name with spaces**: `assets/stylised assets/stylised assets/...` — always quote paths in shell commands.
- **OneDrive**: repo is inside OneDrive; sync can lock files or create conflicted copies during heavy imports.
  If Godot reports a file locked, pause OneDrive sync. Never commit `* (1).tscn`-style conflict copies.
- **`.godot/` is gitignored** — first open re-imports ~4k files (slow). `.import` / `.uid` files ARE tracked; commit them with assets.
- **Godot not on PATH** — use `C:\Program Files\Godot\Godot.exe`.
- **Unused content** (safe to ignore, ask before deleting): `assets/characters/*.glb`, Medieval Village MegaKit,
  `shaders/memory_surface.gdshader`, `shaders/face_blur.gdshader`.

- **New `class_name` "not found in current scope"** → the global class cache is stale; run
  `Godot --headless --path . --import` once after adding scripts with a new class_name.
- **Particles under a BoneAttachment3D fall sideways** → Mixamo head-bone axes are tilted/scaled, and particle direction/gravity
  are emitter-local. Make the particles `top_level` and copy only the position from a marker.
- **Face mosaic drawn on the photo glass** → ScreenEffects occludes faces with a physics ray; the glass has no collision. Turn
  `pixelate_faces` off for such shots.
- **Camera "glitches / won't turn" right after an interaction** → a `glance()` tween was pulling the view toward the object
  while the mouse moved (and pickups started overlapping glances). Glances now cancel on look input; DrawingMemory no longer
  glances at pieces you're already looking at.
- **Depth-of-field pops when focus moves near↔far** → `dof_blur_near_enabled` was switched on/off at 1 m and focus was eased
  linearly with one ray. Keep near blur always on, scale every value with distance, ease in log space, median of 5 rays.

## Design learnings (owner preferences discovered so far)
- Original monolithic `main.gd` (3,200 lines, everything built at runtime) was rejected → everything must be real scenes
  with one script per node (see 08). Don't regress to runtime-built node trees; the only accepted runtime creation is
  procedural content like TitleSequence's per-letter Label3Ds, ghost materials, bone attachments.
