# 05 — Assets, shaders, audio, materials

## Asset folders (`assets/`)
| Folder | Format | Source / licence | Used for | Status |
|---|---|---|---|---|
| `audio/` | mp3 | project audio | all sound (see table below) | used |
| `mixamo/` | FBX + extracted PNGs | Mixamo (Adobe) characters + animations | player (`player_idle.fbx` model, `player_walk.fbx` walk clip), memory figures (`grandma_sit`, `boy_sit`, `boy_happy`) | used |
| `characters/` | glb (boy, father, grandma) | unknown / earlier import | — | **unused** by any scene/script (as of 2026-11-26) |
| `polyhaven/<id>/<id>.gltf` | glTF + 1k textures | Poly Haven, CC0 | almost every indoor/outdoor prop; packable items; suitcase | used |
| `sketchfab/` | glb | Sketchfab CC-BY 4.0 — **credits required**, see `assets/sketchfab/CREDITS.md` | coat rack + scarf, fireplace, gate leaves/post, fence, mailbox, kitchen counter/cupboard, firewood | used |
| `stylised assets/stylised assets/Stylized_Nature_MegaKitStandard/glTF/` | glTF | Quaternius (CC0) | trees, bushes, rocks, grass (via SnowyFoliage) | used |
| `stylised assets/stylised assets/Medieval_Village_MegaKitStandard/` | — | Quaternius | — | **unused** |
| `textures/<name>/` | jpg PBR sets | Poly Haven textures (CC0) | level materials; `kids_drawing/kids_drawing.png` (generated) | used |

Excluded from git (>100 MB, GitHub limit): `assets/polyhaven/pine_tree_01/`, `assets/polyhaven/pine_sapling_medium/` (.gitignore).
`.gitattributes`: LF line endings for text; images/audio/models marked binary. No Git LFS.

When adding a Sketchfab (CC-BY) model: **add a row to `assets/sketchfab/CREDITS.md`**.

## Audio clips (`assets/audio/<name>.mp3`) → who plays them
| Clip | Played by |
|---|---|
| theme_piano | TitleSequence (opening only; falls back to theme_broken if missing) |
| theme_broken | TitleSequence `_hand_over_control` (gameplay music) |
| theme_full | FireplaceMemory (ending) |
| wind_loop, house_tone_loop | AmbienceMixer (AudioStreamPlayers in main.tscn) |
| step_snow, step_wood, floor_creak | player_footsteps.gd |
| ember_chime | ArrivalMemory, TitleSequence |
| door_creak, door_slam | GardenGate, InteriorDoor, DoorMemory |
| argument_muffled | DoorMemory (positional) |
| knit_loop | ScarfCoatRack (positional loop) |
| paper_pickup | DrawingPiece, PuzzlePiece, SuitcaseMemory |
| tape | DrawingMemory, TornDrawingPuzzle |
| pack_item | PackableItem, StudyDoor (push sound) |
| suitcase_close | Suitcase |
| photo_flip | PhotoFrame |
| heartbeat, memory_restore | PhotoMemory; memory_restore also Memory.play_restore_moment |
| fire_ignite, fire_loop | Fireplace |
| v_scarf, v_artist, v_letter | voice lines via `hud.say(text, dur, voice)` |

## Shaders (`shaders/`)
| Shader | Type | Used by | Notes |
|---|---|---|---|
| camera_fx.gdshader | canvas_item | ScreenEffects `FilmLook` | uniforms: vignette, grain, aberration, warmth, world_sat, faces[4], face_count |
| interact_highlight.gdshader | spatial overlay | Interactable, PuzzlePiece | additive rim, `highlight_color`, `strength` |
| ghost.gdshader | spatial | MemoryFigure | `albedo_tex`, `has_tex`, `tint`, `strength` |
| scarf_reveal.gdshader | spatial | ScarfCoatRack | hides below world-height `cut_y` |
| memory_prop.gdshader | spatial | SnowyProp | reads **global** `world_sat`; `snow` on up-faces |
| foliage_snow.gdshader | spatial | SnowyFoliage | global `world_sat`, alpha-cut, `sway`, `snow` |
| memory_surface.gdshader | spatial | **nothing** (level materials are StandardMaterial3D) | orphan — triplanar surface |
| face_blur.gdshader | spatial | **nothing** (faces now pixelated in camera_fx) | orphan |

Global shader parameter **`world_sat`** (float, default 0.3) is declared in `project.godot [shader_globals]` and set only by
`ScreenEffects.world_saturation`. Any new shader that should grey out with the story: `global uniform float world_sat;`.

## Materials (`materials/`)
- `materials/*.tres` — hand-made (brass, curtains, doors, window glass, snow...).
- `materials/level/*.tres` — **written by `tools/level_builder.gd`** (StandardMaterial3D with Poly Haven textures).
  Rerunning the builder rewrites them.

## Level layout (from tools/level_builder.gd)
```
  z -9  +-----------+-----------+-----------+
        | PARENT    | HALLWAY   | BEDROOM   |
  z -4.5+-----------+-----------+-----------+
        | KID ROOM  | LIVING    | KITCHEN   |
  z  0  +-----------+--door-----+-----------+
                     garden path
  z 10  ---fence---- GATE -----fence----
  x:   -7.5        -3          3          6
```
Wall height 2.8 m. house_level.tscn groups: `Exterior` (porch, fence, nature, snow drifts), `House` (walls, roof, `Doors/`, windows),
`Rooms/<Room>` (Room script, RoomFillLight, lining, `Props`). Doors are instances of `interior_door.tscn`, windows of `house_window.tscn`.
Builder RNG seed 2026 → deterministic forest/props.
