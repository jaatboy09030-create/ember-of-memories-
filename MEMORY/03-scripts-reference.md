# 03 — Scripts reference

Format: **script** (`class_name`, extends) — role. *Signals* / *API* / *Depends on* / *Used by*.
Every script starts with a `##` header comment explaining "how to change it" — read that too.

## Core
**scripts/main.gd** (`GameDirector`, Node3D) — runs memories in order, applies restore effects.
API: `start_story()`, `set_cinematic(on, time)`; fields `player, ember, hud, screen_effects,
title_sequence, world_environment, rooms{}, doors{}, memories[]`. Used by: every Memory (`game`), TitleSequence, DevTests.

## Interaction
**interaction/interactable.gd** (`Interactable`, Area3D) — base for everything usable.
Signals `hovered, unhovered, interacted`. Exports `prompt_text, enabled, highlight_color, highlight_strength`.
Virtuals: `get_prompt()`, `get_progress()` (−1 = no bar), `on_hover/on_stop_hover/on_interact/on_interact_held(delta)/on_interact_released`.
Highlight = `interact_highlight.gdshader` set as `material_overlay` on all child GeometryInstance3D.
`_ready` forces layer 3, mask 0 → **subclasses overriding `_ready` must call `super._ready()`**.

**interaction/interaction_raycast.gd** (RayCast3D, on PlayerCamera) — finds the looked-at Interactable
(walks up to 4 parents from the collider), drives hover/interact calls. Signal `target_changed(target)`.
Export `interaction_distance` 2.2 m. Disabled when `player.can_move = false`.

## Memories (`scripts/memories/`) — details in 04-memories.md
**memory.gd** (`Memory`, Node3D) — base. Signal `completed`. Exports `room_id, unlocks_door_id,
saturation_after (−1 = unchanged), saturation_time, warms_room, ember_rest_point`. Var `game`.
API: `begin()` (override), `finish()`, `wake_figures()` (all MemoryFigure descendants),
`play_restore_moment(point)` (sound+glance+shake+warm flash). Convention: each subclass has `debug_complete()` for DevTests.
Subclasses: arrival, scarf, drawing, door, suitcase, photo, fireplace `_memory.gd`.

## Objects (`scripts/objects/`)
| Script | Class / extends | Role | Signals | Key API |
|---|---|---|---|---|
| interior_door.gd | InteriorDoor / Interactable | locked hinged door; open/close when unlocked; won't close on player | — | `door_id, locked, unlock_and_open(), swing(open)`; nodes `DoorHinge`, `DoorwayClearance` |
| study_door.gd | StudyDoor / Interactable | hold-the-door struggle (always lost after `struggle_time`) | struggle_started, pushed, shoved, slammed | `push_amount, is_struggling`; node `DoorLeaf` |
| garden_gate.gd | GardenGate / Node3D | open gate that shuts behind player once `arm()`ed | closed | `arm(), close()`; nodes `LeftLeafHinge, RightLeafHinge, ClosedGateBlocker/BlockerShape, CloseTrigger` |
| scarf_coat_rack.gd | ScarfCoatRack / Interactable | knitting: alternate needle_left/right while hovered | stitch_knitted, knitted | `stitches_needed 22, scarf_mesh_path` (NodePath into imported glb), uses scarf_reveal shader |
| drawing_piece.gd | DrawingPiece / Interactable | floor scrap; pick up → queue_free | picked_up(piece) | `reveal(on)` |
| torn_drawing_puzzle.gd | TornDrawingPuzzle / Interactable | desk puzzle; own camera, rotate 4 pieces | solved | `start_puzzle(cam), finish_puzzle(), get_pieces()`; nodes `PuzzleCamera, Pieces` |
| puzzle_piece.gd | PuzzlePiece / Area3D (layer 4) | one rotatable quarter | — | `turn_quarter(), is_correct(), snap_correct(), set_selected()` |
| drawing_on_wall.gd | DrawingOnWall / Node3D | hidden until `pop_in()` | — | |
| packable_item.gd | PackableItem / Interactable | bedroom belonging | chosen(item) | `memory_line, spin(delta), fly_into(point)`; child `ItemModel` |
| suitcase.gd | Suitcase / Interactable | closes when all packed | closed | node `PackPoint` |
| photo_frame.gd | PhotoFrame / Interactable | face-down photo | chosen | `flip()`; node `FramePivot` |
| fireplace.gd | Fireplace / Interactable | cold hearth → `ignite()` | chosen | `get_fire_position()`; nodes `HearthFire`, `FireLight` |
| memory_figure.gd | MemoryFigure / Node3D | frozen ghost person, pixelated face | — | `wake()`, exports `frozen_at, seat_point, vanish_after`; child **must** be named `CharacterModel` |

## Player (`scripts/player/`)
**player_body.gd** (`PlayerBody`, CharacterBody3D) — movement/look via Input Map only.
Signal `stepped(on_snow)`. Vars: `can_move` (also toggles raycast), `look_scale`, `target_yaw/pitch`, `auto_input` (tests).
API used by story: `head_position(), face_position(), facing(), face_towards(p), glance(p, amt), add_shake(a, t), reveal_face(), is_outside(), is_moving()`.
Nodes: `BodyPivot` (yaw; holds `CharacterModel` + `ScarfAnchor`), `PlayerCamera`, `PlayerCamera/InteractionRaycast`, `PlayerCamera/ColdBreath`, `PlayerAnimator`, `Footsteps`.

**player_camera.gd** (`PlayerCamera`, Camera3D) — head bob (uneven steps), breathing, hand-held drift, start/stop spring
sway, turn bank, noise shake (`add_shake`), glance, auto exposure. `cinematic=true` hands the camera to cutscenes;
`look_target` (Vector3.INF = none; drift+shake still apply when set); `focus(dist)` DOF (≤0 off, needs
CameraAttributesPractical); `default_fov` 74 (lens crops ~10 %); `comfort` + `apply_comfort()`. See 09-camera.md.

**settings/camera_comfort.gd** (`CameraComfort`, Resource) — 0..1 sliders `motion`, `shake`, `lens`, `grain` + `exposure_adapt`.
Instance: `settings/camera_comfort.tres`, assigned to PlayerCamera.comfort and ScreenEffects.comfort.

**player_animator.gd** — builds an AnimationLibrary "player" with `idle` (model's own clip) + `walk` (from `walk_animation` FBX).
**player_footsteps.gd** — step_snow / step_wood / floor_creak. **cold_breath.gd** — GPUParticles puff outside only; `breathing` flag.
**player_scarf.gd** — reparents ScarfAnchor to a BoneAttachment on `mixamorig_Neck` (after one frame).

## Characters
**characters/ember.gd** (`Ember`) — `lead_to(node)` (follow, hovers `hover_height` above), `wait_at(point)` (Vector3.INF = stay). Nodes `EmberCore`, `EmberLight`.

## Systems (`scripts/systems/`)
| Script | Class | Role / API |
|---|---|---|
| sound.gd | (autoload `Sound`) | `play(name, db, pitch_var)`, `play_at(name, pos, db, looped) -> AudioStreamPlayer3D`, `play_music(name or "", db, fade)`, `get_stream(name)`. Looks up `assets/audio/<name>.(mp3/ogg/wav)`; **missing file = silent no-op**. |
| hud.gd | HUD | `connect_interaction(ray)`, `show_prompt(text)`, `set_progress(v)`, `say(text, dur, voice)`, `fade_to(alpha, t) -> Tween`, `letterbox(on, t)`, `set_crosshair_visible`, `show_end_title`. Field `screen_fade` (ColorRect) tweened directly by memories. |
| screen_effects.gd | ScreenEffects | `world_saturation` (setter pushes global `world_sat`), `fade_saturation`, `tween_shader(param, v, t)`, `warm_flash`, `pulse`, `set_vignette`, `reset_vignette`, `apply_comfort()`; per-frame lens strength (on only for PlayerCamera, `cinematic_lens_scale` in cutscenes) and face pixelation. Material on `FilmLook` (camera_fx.gdshader). |
| title_sequence.gd | TitleSequence | `play(game)`, `skip(game)`, signal `finished`. Spawns one Label3D per letter at runtime (intentional: per-letter animation). Uses SystemFont fallbacks (Ink Free, Cormorant Garamond...). |
| ambience_mixer.gd | — | crossfades WindLoop/HouseToneLoop by `player.is_outside()`. |
| outdoor_culling.gd | — | toggles group `outdoor_only`. |

## Level (`scripts/level/`)
**room.gd** (`Room`) — `room_id`, `warm_up(energy)` tweens `RoomFillLight`. Adds itself to group `room`.
**snowy_prop.gd** (`SnowyProp`) / **snowy_foliage.gd** (`SnowyFoliage`) — on `_ready` replace every surface's
material with memory_prop / foliage_snow shader, copying albedo/normal textures. Foliage detects leaves by material name containing `Lea`/`Grass`/`Flower`.

## Utils & dev
**utils/model_utils.gd** (`ModelUtils`, static) — `find_skeleton`, `find_animation_player`, `fix_cull` (extra_cull_margin 16384), `measure(node)` AABB.
**dev/dev_tests.gd** — see 06-recipes "Run the automated tests". Hard-coded test positions per memory in `_story_test`.

## Tools (`tools/`, run headless with `-s`, never in-game)
| Tool | Purpose |
|---|---|
| level_builder.gd (978 lines) | Regenerates `scenes/level/house_level.tscn` + `materials/level/*.tres`. **Overwrites hand edits.** |
| make_kids_drawing.gd | Paints placeholder `assets/textures/kids_drawing/kids_drawing.png`. |
| tri_count.gd | Prints top-30 triangle counts of Poly Haven models. |
| debug_model.gd | Dumps node tree of `assets/mixamo/player_idle.fbx` (edit path to inspect others). |
