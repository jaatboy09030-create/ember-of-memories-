# IdiotHandOffManager — status ledger (house fixes)

**State: COMPLETE** — all required steps verified; owner by-eye checks M1–M9 outstanding (not claimable by an agent).

## Guides
| ID | Path | Identity | Status |
|---|---|---|---|
| G1 | `IdiotHandOffGuide-house-fixes.md` | sha256 `04bba1f8cadb5252…` (as executed) | executed |
| — | `IdiotHandOffGuide.md` (worn camera) | already applied in HEAD `9d83308` | excluded (not re-run) |

## Baseline
- Branch `main` @ `9d83308`, clean except `?? IdiotHandOffGuide-house-fixes.md` and ` M MEMORY/CHANGELOG.md` (guide record) — allowed by G1/S00.
- All 7 S00 hashes matched. Work done on new branch `fix/house-feedback` (project rule: branch off `main`). Nothing committed.

## Execution
Agents: steps applied serially by the manager (shared files and strict guide order; parallel workers would only have contended for the same files). One independent read-only reviewer subagent checked the applied diff.

| Item | Work | State | Evidence |
|---|---|---|---|
| G1/S00 | baseline check | verified | HEAD 9d83308; 7/7 hashes equal |
| G1/S01–S16 | 8 created/replaced files + 30 block edits, applied from the guide's own payloads | verified | every anchor matched once; 24 files byte-equal to the author's validated copy (dev_tests.gd differs only in line endings there; repo keeps LF) |
| G1/S17 | `--import`, class cache | verified | `"MemoryGrade"` in global_script_class_cache.cfg; no parse errors |
| G1/S18 | patch builder, regenerate, delete 3 materials | verified | `patched OK`; 7 `PLACED` lines unchanged; `nodes=1461`; counts 1/0/6/1 and 0; 26 materials |
| G1/S19 | MEMORY update | verified | `MEMORY updated OK: 17 edits` |
| R1 | manager repair from review (see below) | verified | tests re-run + abort probe |

## Checks (cwd = repo root, headless unless noted)
| Check | Result |
|---|---|
| V1 `--storytest` | all PASS (7 memories, 4 ray checks); doors open front/kid/hall/bed/parent; saturation 1.0; story finished |
| V2 `--walktest` | `PASS (inside)`; `front door shut and locked behind the player: PASS` |
| V2 `--doortest` | `locked door rattles and stays shut: PASS`; FrontDoor ray PASS; 100 / 0 / 100 / 100 |
| V3 `--walktest --gate` | `FAIL (stuck)` z=3.0 — pre-existing on baseline (MEMORY/07), unrelated |
| V4 `tools/overlap_check.gd` | `overlap_check: 0 problem(s)` (2 `known` StudyDoor lines) |
| V5 structure | 8 OmniLight3D; 21 prop wrappers; status = files in G1/C + new `.uid`s + this ledger |
| V6 windowed `--storytest` | no SHADER / SCRIPT / Parse errors |
| After repair | storytest, walktest, doortest re-run: all PASS as above |
| Repair probe (scratch copy, temporary `--abortprobe`) | closing started → step back into doorway: `open=true locked=false PASS` → walk away: `open=false locked=true angle=0 PASS` |

## Review findings and repairs (deviation from G1, applied by manager)
| Finding | Severity | Action |
|---|---|---|
| Front door could close onto a player who turns back during the 1.3 s close and could leave them locked outside (soft-lock) | medium | `interior_door.gd`: `_closing_behind` state; while closing, a body in the doorway reopens it (stays armed); `locked` set only in `_finish_lock_behind()` after the leaf is shut; interact ignored while it closes |
| `rattle()` could fight a running swing | low | `rattle()` returns while `_swing` runs |
| Back-to-back `ripple()` cut each other off | low | `memory_grade.gd` keeps `_ripple` and kills it before restarting |
| 3.4° aim jump between pull-back and orbit | low | pull-back look target = `_head` (same as `_orbit(0)`) |
| `turn_hint` lacked `##` doc | low | doc added |
| Ember joins `colour_source` in code, not in the scene | note | kept: same pattern as `Room`/`InteriorDoor` groups |
Recorded in `MEMORY/CHANGELOG.md` and `MEMORY/03`. The guide file is left as written.

## Outstanding
- Owner by-eye checks M1–M9 (guide section E): textures, door rattle sound, seated ghosts, z-fighting, sparse rooms, hold-and-look feel with real mouse/gamepad, new grade, no blob, camera transitions.
- Commit when the owner approves (branch `fix/house-feedback`).
