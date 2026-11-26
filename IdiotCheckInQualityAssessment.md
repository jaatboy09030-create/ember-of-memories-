# IdiotCheckInQualityAssessment — House fixes (owner feedback round 1)

## 1. Verdict and assessed scope

> **Update (same day, after fixes — see §7):** F1, F2, F3, F4, F5 and F7 are fixed and verified. U2 is now fully met. Remaining: F6 (kept by choice), U11 (undetermined), and the owner play-test items Q1–Q6.

**Original verdict: acceptance MET for 10 of the 11 owner requirements. U11 is UNDETERMINED (interpretation not confirmed). One requirement (U2, "no exiting") is met only partially — finding F1.** Remaining items are low-severity cleanup. Look-and-feel requirements (U1, U4, U6, U7, U9) are verified by renders and tests, but the owner's subjective sign-off by playing is still outstanding.

| | |
|---|---|
| Audited | Everything that implements the owner's 11-point feedback: `IdiotHandOffGuide-house-fixes.md` (G1) as executed, plus the manager's review repairs (ledger `IdiotHandOffManager-status.md`). This includes all 42 changed and 10 new files, and the consumers they affect (HUD, InteractionRaycast, GameDirector, memories, DevTests, OutdoorCulling, title sequence). |
| Revision | Branch `fix/house-feedback`, uncommitted, on top of `main` @ `9d83308`. 52 status entries (42 modified/deleted, 10 untracked). Diff against baseline: 2419+ / 3614−, mostly the regenerated `house_level.tscn`. |
| Baseline | `9d83308` (worn-camera guide already merged). Regression attribution is against this commit. |
| Runtime | Godot 4.7.2 stable, Windows 11, Forward+ (windowed runs) and dummy renderer (headless runs). |
| Standards | Owner requirements U1–U11 (verbatim request). G1 requirements R1–R13. Project rules in `MEMORY/08-conventions.md` (scene tree first, one script per node, Input Map only with keyboard/mouse + gamepad bindings, `##` headers, `@export` with docs, static typing). `CLAUDE.md`/`AGENTS.md` (keep `MEMORY/` updated). |
| Coverage limits | (a) No real mouse/gamepad play session: feel of hold-and-look, rattle audio and frost animation were not exercised by a human. (b) No frame-rate measurement. (c) z-fighting checked by renders from 15 viewpoints, not exhaustively (it depends on the viewing angle). (d) The headless dummy renderer does not compile shaders; shader compilation was checked in windowed runs. |

## 2. Requirement and component coverage

### 2.1 Requirements
| ID | Requirement (source) | Implementation | Evidence | Disposition |
|---|---|---|---|---|
| U1 | Wall and door texture not "too smooth / weird" (owner #1) | `level_builder.gd` `_tex_mat` (specular, normal) + all wallpapers → `painted_plaster_wall`; `door_wood.tres` / `door_panel.tres` object triplanar | C10 renders, C2 source | verified (owner taste pending, M1) |
| U2 | Exiting not allowed: locked door → vibrate, sound, "locked" (owner #2) | `interior_door.gd` `rattle()`, `get_prompt()`, `lock_behind_player`; builder sets it on FrontDoor | C3 doortest, C4 walktest, C7 probe | **partially met — F1, F2** |
| U3 | No meshes passing through each other (lamp, kid's leg, books, pillow…) (owner #3) | Minimal fixed-position furniture; SeatPoint z 0.08 ×2; photo layers | C5 overlap_check 0 problems, C10 side renders | verified (figures by render only) |
| U4 | No z-fighting on walls (owner #4) | Wainscot/rail/cornice/beam boxes removed | C10 corner/doorway renders, C2 geometry review | verified within sampled views |
| U5 | Remove micro-detail not relevant to the story (owner #5) | 20 furniture wrappers + counter; no trims/beams | C6 counts (21 props, 0 trims) | verified |
| U6 | Look around freely while holding; rotate with a key (owner #6) | `player_body.gd` `holding_item`/`item_turn`/`_rotating_item`; `suitcase_memory.gd` follow + `turn_by`; input `rotate_item` (R + joypad 3) | C1 storytest (debug path), C2 source trace | verified statically; real-input feel unverified (Q1) |
| U7 | Frozen/grey look aesthetic, thrilling (owner #7) | `memory_grade.gd/.gdshader`, `screen_effects.tscn` MemoryGrade→GradeCopy→FilmLook | C10 renders (frozen, 0.0, ripple), C9 no shader errors | verified technically; subjective sign-off pending (M7) |
| U8 | No white gradient blob in rooms (owner #8) | GroundMist z 0.5–40.5 + `outdoor_only`; MoonlightBeam removed; interior lights fog energy 0 | C6 counts, C10 renders | verified |
| U9 | Realistic, non-random lighting/shadows (owner #9) | One shadowed `RoomFillLight` + pendant per room; SDFGI off; SSAO lighter | C6 (8 omnis), C10 renders | verified (perf unmeasured, Q2) |
| U10 | Camera never through the head in transitions (owner #10) | PuzzleCamera `cull_mask`; `photo_memory.gd` `_pull_back`; `hide_face()` | C2 math review (reviewer: ≥0.87 m after reveal), C1 storytest | verified statically; cutscene not visually captured (Q3) |
| U11 | Third-person camera control feels weird (owner #11) | Interpreted as "body stays visible after the photo reveal" → `hide_face()` | C2 | **undetermined** — no third-person mode exists; interpretation unconfirmed (Q4) |
| R12 | No regressions | — | C1–C4, C9 | verified; `--walktest --gate` is a pre-existing fail (F7) |
| R13 | MEMORY/ updated | S19 + repair notes | C8 | verified except stale lines F3 |

### 2.2 Components
| Component | Review | Result |
|---|---|---|
| `scripts/objects/interior_door.gd` | source, callers (raycast, HUD, director, DevTests), runtime C3/C4/C7 | F1, F2 |
| `scripts/player/player_body.gd` | source; both setters' raycast logic; input paths | verified |
| `scripts/memories/suitcase_memory.gd`, `scripts/objects/packable_item.gd` | source; `spin` callers removed (grep 0) | verified |
| `scripts/player/player_camera.gd` (`hide_face`) | source | verified; F5 |
| `scripts/memories/photo_memory.gd` | source, reviewer math | verified (Q3) |
| `scripts/systems/memory_grade.gd`, `shaders/memory_grade.gdshader` | source, renders, windowed compile | verified |
| `scripts/systems/screen_effects.gd/.tscn`, `shaders/camera_fx.gdshader` | source; setter null-safety; node order | verified; F4 |
| `scripts/characters/ember.gd` | source | verified (group in code follows the `Room`/`InteriorDoor` precedent: not a finding) |
| `tools/level_builder.gd` + `scenes/level/house_level.tscn` + `materials/level/*` | source diff, regen output, material reference sweep (all 26 used) | verified; F3 |
| `tools/overlap_check.gd` | source, run | verified (excludes figures/floors by design) |
| `scenes/objects/house_window.tscn`, `photo_frame.tscn`, `torn_drawing_puzzle.tscn`, `drawing/scarf_memory.tscn`, `main.tscn`, `room.gd`, `project.godot` | source | verified; F5 |
| `scripts/dev/dev_tests.gd` | source, runs | verified |
| `MEMORY/*.md` | grep for stale terms | F3, F4 |

### 2.3 Category accounting
| Category | Result |
|---|---|
| A Pending / half-finished | U11 interpretation open (Q4); otherwise no unwired paths found (all new nodes, actions, groups and calls have callers). |
| B Symptom-only fixes | Each owner issue was traced to its cause (see G1 §A table). The repair for the door soft-lock trades it for an escape window — F1. |
| C Defects / regressions | F1, F2 (introduced); F7 (pre-existing). |
| D Quality standards | F2 (misleading prompt); feel/perf unverified (Q1, Q2). |
| E Dead code | F3 (MEMORY_OWNED branch), F4 (camera_fx `world_sat`). |
| F Duplication / overengineering | F5 (render-mask magic number in three places). The two line-of-sight raycasts (`screen_effects.gd:145`, `memory_grade.gd:65`) serve different targets: not worth merging, not a finding. |

## 3. Prioritized findings

Counts: **critical 0 · high 0 · medium 1 · low 6**

### F1 — [B, C] The front door can be walked back out of during its 1.3 s close — medium
- **Requirement:** U2 "exiting isn't allowed". **Impact:** the player can get back outside to the garden. They are still held in by the gate and fence. The door re-closes when they come back in.
- **Location:** `scripts/objects/interior_door.gd:138-160` (`_physics_process`, `_finish_lock_behind`); the reopen happens at line 144.
- **Trigger:**
  - Walk in until the door starts closing (more than 1.8 m from the hinge).
  - Turn back into the doorway within 1.3 s.
  - **Expected:** you cannot leave.
  - **Actual:** the door swings back open, unlocked, and you can walk out onto the porch.
- **Evidence (C7, scratch probe):** `PROBE stepped back in: open=true locked=false PASS`. There is no collider outside the doorway: the clearance Area3D only detects; the leaf is the only blocker.
- **Root cause (confirmed):** the review repair that prevents closing the leaf onto the player has only one safe action, "reopen". Nothing else stops the player passing back through.
- **Attribution:** introduced, by the manager's review repair. The original guide version closed onto the player, risking a lock-outside soft-lock, which is worse.
- **Fix:**
  - Give `interior_door.tscn` an `OutsideBlocker` StaticBody3D. Its thin box sits at local z ≈ +0.65, outside the clearance box (±0.55) and the leaf's sweep (which is −z).
  - Keep it disabled by default. Enable it when `lock_behind_player` arms (`_lock_when_clear` set), as `GardenGate.ClosedGateBlocker` does.
  - Keep the reopen-if-in-doorway safety.
- **Verify:** extend the probe/doortest. After stepping back into the doorway mid-close, push the player toward +z for 1 s. Their z must stay below 0.65 and the door must still lock once they walk away.

### F2 — [C, D] Prompt says "open" while the one-way door is closing, but interact does nothing — low
- **Location:** `interior_door.gd:58-61` (`get_prompt`) together with the early return at `:76`.
- **Trigger:**
  - Look at the front door during its 1.3 s close.
  - **Expected:** a prompt that matches what happens (none, or "locked").
  - **Actual:** "open", and pressing interact is ignored.
- **Evidence:** static. While closing, `locked=false` and `is_open=false`, so `get_prompt` returns "open".
- **Attribution:** introduced (repair).
- **Fix:** `if locked or _closing_behind: return locked_prompt`.
- **Verify:** a unit check on `get_prompt()` with `_closing_behind = true`.

### F3 — [E] `MEMORY_OWNED` path is dead and two MEMORY notes now describe it wrongly — low
- **Location:**
  - `tools/level_builder.gd:62` and `:807-808`: the branch never runs, because `vintage_suitcase` is no longer placed.
  - `MEMORY/04-memories.md:49` says it is "listed as MEMORY_OWNED … (removed from the level)".
  - `MEMORY/06-recipes.md:69` says regeneration "prints positions of MEMORY_OWNED props such as the suitcase".
- **Evidence:** `grep vintage_suitcase tools/level_builder.gd` finds only the constant; the regeneration output (C6) prints no `MEMORY_OWNED` line.
- **Impact:** a future reader will look for output that never appears.
- **Attribution:** introduced (G1/S18 kept the constant).
- **Fix:**
  - Delete the constant and the two-line branch, or keep the constant and document it as a guard for re-adding memory props.
  - Update the two MEMORY lines.
- **Verify:** regenerate. The node count stays 1461 and `overlap_check` stays at 0.

### F4 — [E] `camera_fx.gdshader` `world_sat` is unused but still configured and documented as active — low
- **Location:** `shaders/camera_fx.gdshader:15` (declared) and `:56` (comment); `scenes/systems/screen_effects.tscn:16` (`shader_parameter/world_sat = 1.0` on FilmLookMaterial); `MEMORY/05-assets-shaders-audio.md:44` (listed among the live uniforms).
- **Evidence:** `screen_effects.gd` no longer sets it (grep: only the global parameter and MemoryGrade).
- **Root cause:** it was kept on purpose so old materials still load (comment at `:56`).
- **Attribution:** introduced (G1/S13).
- **Fix:** remove the uniform and the tscn line together, or mark the MEMORY/05 entry as "unused (compat)".
- **Verify:** windowed run shows no SHADER ERROR; storytest PASS.

### F5 — [F] The "hide the player's body" render mask is hard-coded in three places — low
- **Location:** `scenes/player/player.tscn:110` (`cull_mask = 1048573`), `scenes/objects/torn_drawing_puzzle.tscn:49` (same literal), and `scripts/player/player_camera.gd:207`, which computes it from `PlayerBody.BODY_RENDER_LAYER`.
- **Impact:** moving the body to another render layer means editing three places. A missed one brings back the "camera sees inside the head" bug (U10).
- **Attribution:**
  - `player.tscn` literal: pre-existing.
  - Puzzle literal: introduced.
- **Fix:** document the rule in MEMORY/07 (already partly there), or set the puzzle camera's mask from `PlayerBody.BODY_RENDER_LAYER` in `TornDrawingPuzzle._ready()`.
- **Verify:** puzzle glide renders show no hair (M9).

### F6 — [D] Turn hint text hard-codes the key names — low
- **Location:** `scripts/memories/suitcase_memory.gd:15` (`"hold R / Y to turn it"`).
- **Impact:** the hint goes stale if the `rotate_item` bindings change. It is now documented on `:14`.
- **Attribution:** introduced.
- **Fix:** acceptable as an exported string. Optionally build it from `InputMap.action_get_events("rotate_item")`.
- **Verify:** the HUD prompt shows the right keys.

### F7 — [C] `--walktest --gate` always reports FAIL — low, pre-existing
- **Location:** `scripts/dev/dev_tests.gd` `_walk_test` (420 physics frames).
- **Evidence:** C4 prints `TEST walk end z=3.0  FAIL (stuck)` on this branch. It does the same on clean `9d83308` (checked earlier on the untouched checkout; documented in MEMORY/07).
- **Cause:** the 7 s walk covers 12.25 m, but gate-to-inside is 16 m.
- **Attribution:** pre-existing.
- **Fix:** run 600 frames when `from_gate` is set.
- **Verify:** `--walktest --gate` reports PASS (inside).

## 4. Checks and evidence

All runs from the repo root on `fix/house-feedback`, final state unless noted.

| ID | Check | Command / action | Result |
|---|---|---|---|
| C1 | Story test | `Godot --headless --path . -- --storytest` (after the review repair) | PASS: 7 memories, 4 ray checks; doors open front/kid/hall/bed/parent; saturation 1.0; story finished |
| C2 | Source trace | Read every changed script and its callers; independent read-only reviewer pass (5 questions) | findings F1, F2 (the reviewer's 4 issues were repaired, see ledger); setter null-safety, input state machine and photo-camera math confirmed |
| C3 | Door test | `-- --doortest` | `locked door rattles and stays shut: PASS`; FrontDoor ray PASS; 100 / 0 / 100 / 100 |
| C4 | Walk tests | `-- --walktest`; `-- --walktest --gate` | PASS (inside) + `front door shut and locked behind the player: PASS`; gate run FAIL (F7, pre-existing) |
| C5 | Overlap | `-s res://tools/overlap_check.gd` (level and memory scenes unchanged since the run) | `overlap_check: 0 problem(s)`; 2 known StudyDoor lines |
| C6 | Structure | grep counts in `house_level.tscn`; regeneration output | lock_behind 1, MoonlightBeam 0, CeilingLamp 6, GroundMist outdoor_only 1, trims/beams 0, OmniLight3D 8, prop wrappers 21; `PLACED` ×7 unchanged; nodes 1461; 26 materials, all referenced |
| C7 | Door abort probe | Scratch copy, temporary `--abortprobe` (deleted afterwards) | closing started → step back in: `open=true locked=false` → walk away: `open=false locked=true angle=0` (repair works; also proves F1's escape window) |
| C8 | MEMORY sweep | grep MEMORY for `MEMORY_OWNED`, `settle`, `SDFGI`, `world_sat`, removed node names | F3, F4; no other stale references |
| C9 | Shader compile | Windowed `-- --storytest`, grep SHADER/SCRIPT/Parse | no errors (shaders unchanged since; the review repair only touched GDScript, recompiled by C1–C4) |
| C10 | Renders | Windowed probe cameras, 1280×720, saved to the session scratchpad: 6 rooms + kid/grandma side views, two corners, the kid doorway, the photo dresser and the bedroom nightstand | duotone grade, no blobs, one light per room; kid shins and grandma feet clear of chairs; photo lies flat; no visible z-fighting in the sampled views |
| C11 | Dead-reference sweep | grep for removed nodes/functions (`CeilingBeams`, `Wainscot`, `MoonlightBeam`, `.spin(`, `_settle_props`, chandeliers, display shelves, cupboard) across `.gd`/`.tscn`/`.md` | 0 references |
| — | Skipped | FPS measurement; human mouse/gamepad play; video capture of the photo/puzzle cutscenes | see §5 |

## 5. Unverified risks and blocked investigation
| ID | What | Why it matters | Next check | Affects |
|---|---|---|---|---|
| Q1 | Hold-and-look with real input (mouse feel, R + mouse rotation direction, gamepad Y + stick) | U6 is about feel; the test only uses `debug_complete()` | Owner play-test M6 | U6 |
| Q2 | Frame rate: 6 shadowed omni lights plus ember/fire shadows; per-frame halo raycast | Shadowed omnis cost cube-map shadow passes (SDFGI removal saves cost, but nothing was measured) | `Godot --path . --print-fps`, stand in the living room and hallway, compare with `9d83308` | U9 |
| Q3 | Puzzle glide and photo pull-back seen in motion | U10 fixes are proven by mask and geometry, not by video | Owner play-test M9, or capture frames during the cutscenes | U10 |
| Q4 | Meaning of "third person camera mode" | No third-person mode exists; if the owner wants one, that is new work | Ask the owner | U11 |
| Q5 | z-fighting at angles not sampled | Depends on the view | Owner walk-through M4 | U4 |
| Q6 | Subjective "thrilling / exciting" | Aesthetic sign-off | Owner play-test M7 | U7 |

## 6. Correction order and completion criteria
1. **F1 + F2 together** (same file, same state machine): add `OutsideBlocker` to `interior_door.tscn`, enabled while the lock-behind is armed. Return `locked_prompt` while `_closing_behind`. **Done when:** an extended `--doortest`/probe shows the player cannot get past z 0.65 after stepping back during the close, and the door still locks; `--walktest` and `--storytest` PASS.
2. **F3, F4** (docs/dead code, independent): remove or document the `MEMORY_OWNED` branch and the camera_fx `world_sat` uniform, and fix MEMORY/04:49, 06:69 and 05:44. **Done when:** regeneration is unchanged (1461 nodes), `overlap_check` reports 0, and there are no shader errors.
3. **F5, F6** (optional hardening).
4. **F7** (pre-existing test length).
5. **Q1–Q6:** the owner play-test (guide §E M1–M9) and an FPS sample before committing.

Commit note (not a finding): the new `.uid` files (`memory_grade.gd.uid`, `memory_grade.gdshader.uid`, `overlap_check.gd.uid`) must be committed with their sources (MEMORY/07 rule).

## 7. Resolution (fixes applied after this assessment)

| Finding | Status | What changed | Verified by |
|---|---|---|---|
| F1 | **fixed** | `scenes/objects/interior_door.tscn`: new `OutsideBlocker` StaticBody (box 1.6 × 2.2 × 0.1 at local z +0.7, outside the clearance box and the leaf sweep). Its shape is disabled by default. `interior_door.gd` turns it on when the one-way close starts (the player is inside and > 1.8 m away, so it can never overlap them), keeps it on while the door reopens for someone in the doorway, and turns it off once the shut leaf is locked. The script mirrors it to the outside side when `inside_is_negative_z` is false. | `--doortest` (new `_one_way_door_test`): `starts closing PASS`, `reopens instead of closing onto the player PASS`, `player can't walk back out (z=0.4) PASS`, `shuts and locks once they walk away PASS` |
| F2 | **fixed** | `get_prompt()` returns `locked_prompt` while `_closing_behind` | source; same test path |
| F3 | **fixed** | `MEMORY_OWNED` and its branch removed; `_report_and_remove_memory_owned` → `_report_placed()` (report only); MEMORY/04 and 06 lines corrected | builder rerun to a scratch path: the 7 `PLACED` lines are unchanged and the normalized node/transform diff against the committed `house_level.tscn` is **0 lines**, so no regeneration was needed. The builder's `nodes=1471` vs the earlier 1461 is the +2 nodes per door instance (OutsideBlocker + shape) counted inside instances. |
| F4 | **fixed** | `world_sat` uniform removed from `camera_fx.gdshader` and from FilmLookMaterial in `screen_effects.tscn`; MEMORY/05 updated | windowed `--storytest`: no SHADER/SCRIPT/Parse errors |
| F5 | **fixed** | `PlayerBody.CAMERA_MASK_WITHOUT_BODY` const; used by `PlayerCamera.hide_face()` and set on PuzzleCamera in `TornDrawingPuzzle._ready()` (the literal was removed from `torn_drawing_puzzle.tscn`). The remaining literal is the player camera's scene default in `player.tscn:110`; it is kept because the project prefers scene-tree values, and it is documented in MEMORY/07. | `--storytest` DrawingMemory PASS |
| F6 | kept (by choice) | The exported hint string, documented on `suitcase_memory.gd:14`. Generating key names from the InputMap would add code for a string the owner can edit in the Inspector. | — |
| F7 | **fixed** | The gate walk test runs 600 frames | `--walktest --gate`: `walk end z=-2.16 PASS (inside)` |

**Re-run after the fixes (repo root, final state):**
- `--storytest`: all PASS; doors open front/kid/hall/bed/parent; saturation 1.0.
- `--walktest`: PASS + front door locked behind.
- `--walktest --gate`: PASS.
- `--doortest`: 10/10 lines as expected (all PASS).
- `overlap_check: 0 problem(s)`.
- Windowed run: no shader/script errors.

**Still open:** U11 interpretation (Q4) and the owner play-test (Q1–Q3, Q5, Q6); FPS not measured (Q2).
