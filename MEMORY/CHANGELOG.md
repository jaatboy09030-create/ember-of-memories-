# CHANGELOG (newest first)

Format: `YYYY-MM-DD — who/what — summary (files)`. Record *why* when it isn't obvious.

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
