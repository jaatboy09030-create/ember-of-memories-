# 04 — The memories (story steps)

All live in `scenes/memories/<name>_memory.tscn` + `scripts/memories/<name>_memory.gd`, instanced
under `Main/Memories` in story order. Config values below are set **inside each memory scene's root**
(not overridden in main.tscn).

## Story chain at a glance
| # | Memory | Room (`room_id`) | Mini-game | `unlocks_door_id` | `saturation_after` | `warms_room` |
|---|---|---|---|---|---|---|
| 0 | ArrivalMemory | outside | walk to gate, then porch | `front` | 0.0 | false |
| 1 | ScarfMemory | `living` | knit: alternate needle presses (tutorial) | `kid` | 0.35 | true |
| 2 | DrawingMemory | `kid` | pick up 3 scraps → rotate 4 pieces at desk | `hall` | 0.6 | true |
| 3 | DoorMemory | `hall` | mash interact to hold study door — always lose | `bed` | 0.3 | false |
| 4 | SuitcaseMemory | `bed` | inspect & pack 4 items; colour drains to 0; close suitcase | `parent` | −1 (drains itself) | false |
| 5 | PhotoMemory | `parent` | flip photo → face-reveal cutscene → letter | — | −1 (self: 0.55) | false |
| 6 | FireplaceMemory | `parent` | relight fire → ending crane shot → end title | — | −1 (self: 1.0) | false (warms all rooms itself) |

Door chain: front → kid → hall → bed → parent. Colour arc: 0.3 → 0 → 0.35 → 0.6 → 0.3 → 0 → 0.55 → 1.0.

## Per memory

### 0 Arrival — `arrival_memory.gd`
Nodes: `GardenGate` (instance), `GateTrigger`, `PorchTrigger` (Area3D), `PorchPoint` (Marker3D). No EmberRestPoint
(TitleSequence leaves the ember at the gate). Gate trigger → `ember.lead_to(PorchPoint)`, `gate.arm()`, chime,
caption "...home.". Porch trigger → `player.glance(glance_point)` → `finish()`. `begin()` re-checks bodies already inside GateTrigger.

### 1 Scarf — `scarf_memory.gd`
Nodes: `ScarfCoatRack`, `GrandmaKnitting` (MemoryFigure + SeatPoint, grandma model), `BoyWatching` (MemoryFigure), `EmberRestPoint`.
Rack disabled until `begin()`. `knitted` → `wake_figures()`, `play_restore_moment`, voice `v_scarf`.
Difficulty: `ScarfCoatRack.stitches_needed` (22), `rows_at_start` 8 / `total_rows` 30.

### 2 Drawing — `drawing_memory.gd`
Nodes: `DrawingPieces/{PieceByTheBed, PieceByTheShelves, PieceByTheBookcase}`, `TornDrawingPuzzle`, `DrawingOnWall`,
`BoyAtDesk` (MemoryFigure + SeatPoint), `EmberRestPoint`. Piece count is automatic. Puzzle enabled after last pickup;
using it locks player, sets `cam.cinematic`, switches to `PuzzleCamera`, mouse becomes visible. `solved` → wake figures,
tape sound, restore moment, drawing pops onto wall, voice `v_artist`.

### 3 Door — `door_memory.gd`
Nodes: `StudyDoor`, `ArgumentSoundPoint`, `EmberRestPoint`. `begin()` enables the door + plays `argument_muffled` at the point.
Struggle drives HUD progress from `study_door.push_amount`. `slammed` → slam sound, big shake, white flash via
`hud.screen_fade`, caption, `finish()`. Tuning on StudyDoor (`struggle_time` 6.5 s etc.).

### 4 Suitcase — `suitcase_memory.gd`
Nodes: `Suitcase` (+`PackPoint`), `PackableItems/{AlarmClock, SchoolNotes, Gamepad, Postcards}` each with child `ItemModel`, `EmberRestPoint`.
Item `chosen` → lift in front of camera (tween), caption = `item.memory_line`, prompt "pack it". Next interact (polled in
`_process`, not via raycast) packs it. Saturation = `start_saturation(0.3) * left/total`. All packed → suitcase enabled →
`closed` → fade to black, "I left that night...", `finish()`.
Note: `vintage_suitcase` is listed as MEMORY_OWNED in level_builder (removed from the level; this scene owns it).

### 5 Photo — `photo_memory.gd`
Node: `PhotoFrame`, `EmberRestPoint`. The only scene where the camera leaves the body: lean in → `photo.flip()` →
pull back over shoulder → `player.reveal_face()` (camera now renders render-layer 2) → orbit to face → letter voice `v_letter`.
Music fades to silence. Disables `PlayerCamera/ColdBreath.breathing` via hard-coded node path.

### 6 Fireplace — `fireplace_memory.gd`
Node: `Fireplace`, `EmberRestPoint`. `chosen` → ember flies to hearth, `fireplace.ignite()`, `theme_full` music,
saturation→1, ambient light warm, shader `warmth` 0.8, every `Room.warm_up(1.8)`, crane shot (positions are exported
world coordinates), after `end_delay` 10.5 s fade to black → `hud.show_end_title()` → `finish()`.

## Memory figures (ghost people)
Instance `scenes/objects/memory_figure.tscn`, add a model as child named **`CharacterModel`** (Mixamo FBX with one animation,
e.g. `assets/mixamo/grandma_sit.fbx`, `boy_sit.fbx`, `boy_happy.fbx`). Optional `SeatPoint` Marker3D assigned to `seat_point`
moves hips onto the seat. `frozen_at` picks the frozen frame. `wake()` is called by `Memory.wake_figures()`.
