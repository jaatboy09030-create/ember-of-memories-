# 02 — Architecture & dependency map

## main.tscn tree (root `Main`, script `scripts/main.gd`, class `GameDirector`)
```
Main (GameDirector)                exports wired in Inspector: player, ember, hud, screen_effects,
│                                  title_sequence, world_environment; start_saturation=0.3
├─ WorldEnvironment, Moon          night lighting (env adjustment_saturation 1.05)
├─ HouseLevel                      instance of scenes/level/house_level.tscn (Exterior / House / Rooms)
├─ Player                          scenes/player/player.tscn (PlayerBody)
├─ Ember                           scenes/characters/ember.tscn
├─ Memories                        ORDER OF CHILDREN = ORDER OF THE STORY
│   ├─ ArrivalMemory → ScarfMemory → DrawingMemory → DoorMemory
│   └─ SuitcaseMemory → PhotoMemory → FireplaceMemory
├─ Snowfall                        particles (group outdoor_only)
├─ TitleSequence                   opening one-shot
├─ HUD                             CanvasLayer
├─ ScreenEffects                   CanvasLayer, film look + world saturation
├─ AmbienceMixer (WindLoop, HouseToneLoop)
├─ OutdoorCulling
└─ DevTests                        only active with --storytest/--walktest/--doortest
```
Autoload: **`Sound`** = `scenes/systems/sound.tscn` (script `scripts/systems/sound.gd`). Reachable everywhere.

## Runtime flow
1. `GameDirector._ready()`:
   - sets `screen_effects.world_saturation`, hooks `hud` to `player.interaction_raycast`
   - collects nodes in group **`room`** → `rooms[room_id]`, group **`interior_door`** → `doors[door_id]`
   - for each `Memory` child: sets `m.game = self`, connects `completed`
   - if DevTests flag → `dev_tests.run(self)` (skips title) and returns
   - else `title_sequence.play(self)`; on `finished` → `start_story()`
2. `_start_memory(i)`: `ember.lead_to(m.ember_rest_point)` (if set) → `m.begin()`.
3. Memory runs its mini-game, calls `finish()` → emits `completed`.
4. `_on_memory_completed(m)` applies the **Inspector-driven restore effects**:
   `saturation_after >= 0` → `screen_effects.fade_saturation`; `warms_room` → `rooms[room_id].warm_up()`;
   `unlocks_door_id` → `doors[id].unlock_and_open()`; then next memory.
5. After the last memory nothing else runs (Fireplace shows the end title itself).

## Who depends on whom (arrows = "calls / reads")
```
GameDirector ──► Memory (begin, completed) ──► game.player / game.hud / game.ember / game.screen_effects
     │                                          game.rooms / game.doors / game.world_environment / game.set_cinematic
     ├──► TitleSequence.play / skip ──► PlayerBody, PlayerCamera, Ember, HUD, Sound
     ├──► Room.warm_up (via group "room")
     ├──► InteriorDoor.unlock_and_open (via group "interior_door")
     └──► DevTests.run ──► every Memory.debug_complete()

PlayerBody ─ owns ─► PlayerCamera ─ owns ─► InteractionRaycast ─► Interactable (on_hover/on_interact/...)
           ├─► PlayerAnimator, Footsteps (listens to stepped), ColdBreath (reads is_outside)
           └─► BodyPivot/ScarfAnchor (player_scarf.gd attaches to neck bone)
HUD ◄── InteractionRaycast.target_changed (prompt + progress come from Interactable.get_prompt/get_progress)
ScreenEffects ──► RenderingServer global shader param "world_sat" ──► memory_prop / foliage_snow shaders
ScreenEffects ◄── group "memory_face" (FaceAnchors made by MemoryFigure) → face pixelation
AmbienceMixer, ColdBreath, Footsteps ──► PlayerBody.is_outside()
OutdoorCulling ──► group "outdoor_only" (hides when camera z < -0.3)
Everything ──► Sound (autoload) by clip name
MemoryFigure, PlayerAnimator, PlayerScarf, PlayerBody.face_position ──► ModelUtils (static helpers)
SnowyProp / SnowyFoliage ──► memory_prop.gdshader / foliage_snow.gdshader
tools/level_builder.gd ──► writes scenes/level/house_level.tscn + materials/level/*.tres
```
**Rule of the codebase:** objects never know about the story. A memory scene owns its objects,
listens to their signals, and talks to the rest of the game only through `game` (the director).

## Physics / render layers (project.godot)
| Layer | Physics name | Used by |
|---|---|---|
| 1 | World | walls, floors, props colliders; blocks the interaction ray |
| 2 | Player | PlayerBody |
| 3 | Interactable | every `Interactable` Area3D (set in code: `collision_layer = 1<<2`, mask 0) |
| 4 | PuzzlePiece | `PuzzlePiece` areas; only TornDrawingPuzzle's mouse ray looks here |

Render layer 2 = **PlayerBody**: all player meshes are moved to it in `_hide_body_from_camera`; the
camera's cull mask hides it until `PlayerCamera.reveal_face()` sets `cull_mask = 0xFFFFF`.

InteractionRaycast mask = `1 | (1<<2)` (World + Interactable), so walls block interaction.

## Groups (string names — grep before renaming!)
| Group | Added by | Read by |
|---|---|---|
| `room` | `Room._ready` | GameDirector |
| `interior_door` | `InteriorDoor._ready` | GameDirector |
| `memory_face` | `MemoryFigure._add_face_anchor` | ScreenEffects (max 4 faces) |
| `outdoor_only` | set in scenes (Snowfall, forest, foliage) | OutdoorCulling |

## IDs that must match across scenes
- **room_id**: `kid`, `living`, `kitchen`, `parent`, `hall`, `bed` (Room nodes in house_level) ↔ `Memory.room_id`.
- **door_id**: `front` (default on FrontDoor), `kid`, `hall`, `bed`, `parent` ↔ `Memory.unlocks_door_id`.
- Sound clip names ↔ file names in `assets/audio/` (no extension).

## Input Map actions (all bound to keyboard/mouse AND gamepad)
| Action | KB/Mouse | Gamepad |
|---|---|---|
| move_forward/back/left/right | W S A D | left stick |
| look_left/right/up/down | (mouse motion, handled in code) | right stick (axes 2/3) |
| sprint | Shift | button 7 (R-stick click) |
| interact | E, left mouse | A (0) |
| needle_left / needle_right | LMB or Q / RMB or E | buttons 9 / 10 (shoulders) |
| select_next / select_previous | ↓/↑ arrows, wheel down/up | d-pad down/up (14/13) |
| release_mouse | Esc | button 4 (Back) |
Note: `E` is bound to both `interact` and `needle_right` — intentional (the scarf rack uses needles while hovered).

## World coordinates (metres; camera starts looking toward −Z)
- Front wall of house at **z = 0**; house spans x −7.5..6, z 0..−9; gate/fence at z = 10.
- Outside = `player.z > 0.3` (`PlayerBody.outside_z`); culling uses camera `z > -0.3`.
- Room layout: see header of `tools/level_builder.gd` (ASCII plan) — copied in 05.
