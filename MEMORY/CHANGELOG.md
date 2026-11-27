# CHANGELOG (newest first)

Format: `YYYY-MM-DD — who/what — summary (files)`. Record *why* when it isn't obvious.

## 2026-11-27
- **Blink demo rewrite + placement fixes** - story rebuilt as a psychological thriller (see 11-blink-demo.md);
  new beat features first_blink_hide/show, montage_show, closed_eyes_line_sounds, hotspot show_nodes;
  `--blinkcheck` placement checker. Level: kitchen dining table (round_wooden_table_01, scale 0.76), props on it,
  chairs pulled out, kitchen fill light raised (house_level.tscn + level_builder.gd).
- **Blink demo prototype** — `scenes/prototypes/blink_demo.tscn` + `scripts/prototypes/` (blink_demo.gd and
  blink/*: Eyelids, MemoryCamera, MemoryVoid, MemoryIsland, MemoryBeat, EyeHotspot, BlinkUI, BlinkCaption,
  SynthTone, BeatCue, SweepLight); shaders `blink_void`, `eyelids`. New input action `blink`. `GameDirector`
  gains `autostart` (off = no title/story) so prototypes can reuse main.tscn. 22-beat story. See 11-blink-demo.md.
- **Mosaic faces rule** — faces are pixelated because the player forgot them. `ScreenEffects.memory_clarity`
  (+`clarity_per_memory` via `remember()`, called from `Memory.play_restore_moment`); looking steadily at a face
  sharpens it up to `gaze_clarity`; a grey world coarsens faces (`drained_clarity_scale`). Woken figures' faces
  resolve to clear before fading. `PlayerBody.reveal_face` adds an always-pixelated OwnFace anchor (photo room
  payoff). Shader `faces[i].w` is now `1 + clarity`. Files: camera_fx.gdshader, screen_effects.gd, memory.gd,
  memory_figure.gd, player_body.gd. Why: research/07-synthesis pillar 1.
- **Design research** — `research/` folder (00 index … 07 synthesis): why the game feels generic, identity
  pillars (mosaic faces as a memory rule, house reacts, shared "hold" verb, losable things), room-by-room
  redesign and build order. No code changed. Why: owner said the game lacks identity and suspense.

## 2026-11-26
- **Worn-camera phase 1** — Lens bend + edge fringe + shadow grain (camera_fx), lens off for non-player cameras;
  PlayerCamera drift / start-stop spring sway / turn bank / uneven steps / noise shake / auto exposure; `CameraComfort`
  accessibility resource (`settings/camera_comfort.tres`); default_fov 70→74; title returns to `default_fov`. Why: blend
  body-cam feel into the existing look without copying Bodycam/Unrecord. (camera_fx.gdshader, player_camera.gd,
  screen_effects.gd, camera_comfort.gd/.tres, player.tscn, screen_effects.tscn, title_sequence.gd, MEMORY 01/03/05/07/09)
- **AI (Claude)** — Researched body-cam cameras (Bodycam, Unrecord, indie/Godot replications, accessibility) and wrote
  `IdiotHandOffGuide.md` (root): phase-1 "worn camera" plan with exact code. No game code changed yet.
- **AI (Claude)** — Created the `MEMORY/` knowledge base from a full audit of commit `c806893`
  (README, 01–08, CHANGELOG). No game code changed.

## History before MEMORY existed (from git log)
- `c806893` 2026-11-26 — Merge PR #1 (refactor/guidelines).
- `7509065` 2026-11-26 Agrim Singh — Split 3,200-line main.gd into scenes, one script per node; level rebuilt as named/grouped
  scene; reusable raycast interaction; Input Map for KB/mouse + gamepad; each memory its own scene; dev tests pass headless.
- `4412ded` 2026-11-26 XMavrik — Renamed game to *Unsent*; one-shot title written in the sky; piano theme on opening only;
  Sketchfab props (fence, gate, mailbox, coat rack+scarf, fireplace, kitchen); scarf reveal row by row; fireplace particles;
  unlocked doors can be closed/reopened.
- `c33ac44` — Quaternius Stylized Nature MegaKit trees/bushes/rocks + foliage_snow shader; deterministic forest ring.
- `417302a` — Initial commit ("Ember Letters").
