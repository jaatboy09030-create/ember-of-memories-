# CHANGELOG (newest first)

Format: `YYYY-MM-DD — who/what — summary (files)`. Record *why* when it isn't obvious.

## 2026-11-27
- **Photo memory rework** — picks the photo up in both hands (TwoBoneIK3D arms + HeadBow), camera goes over the shoulder
  (half face + photo), slow push-in while the glass becomes a mirror showing the face (SubViewport ReflectionCamera +
  photo_glass shader), tears, letter, fade back to first person. Camera kept out of walls with `PlayerCamera.safe_position`
  and picks the roomier shoulder. Face mosaics off during it. New `--phototest`. Known issue: tear spawn points not yet on
  the eyes. (photo_memory.gd, photo_frame.gd/.tscn, photo_glass.gdshader, player.tscn, player_body.gd, player_hands.gd,
  head_bow.gd, player_tears.gd, player_camera.gd, screen_effects.gd, dev_tests.gd, MEMORY 03/04/05/07)

## 2026-11-26
- **Title blur kept in gameplay** — the cinematic depth of field no longer switches off when the title hands over
  control: `PlayerCamera.gameplay_dof` autofocuses on the World surface in view (same `dof_blur_amount` 0.08, starts
  at the title's 14 m), and `TitleSequence._hand_over_control` only calls `focus(-1)` if it's off. Owner asked for the
  game to look like the opening. (player_camera.gd, title_sequence.gd, MEMORY 03)
- **QA fixes (IdiotCheckInQualityAssessment.md F1–F5, F7)** — One-way front door: `OutsideBlocker` StaticBody switched on
  when the close starts, so turning back reopens the door but can't take you outside (F1); prompt "locked" while it
  closes (F2); dead MEMORY_OWNED path removed from level_builder (`_report_placed`), stale MEMORY lines fixed (F3);
  unused `world_sat` uniform removed from camera_fx + FilmLook material (F4); `PlayerBody.CAMERA_MASK_WITHOUT_BODY` used
  by PlayerCamera and the puzzle camera instead of typed numbers (F5); `--walktest --gate` walks 10 s and passes (F7);
  new `--doortest` checks for the one-way door. Level output unchanged (verified). (interior_door.gd/.tscn,
  player_body.gd, player_camera.gd, torn_drawing_puzzle.gd/.tscn, level_builder.gd, camera_fx.gdshader,
  screen_effects.tscn, dev_tests.gd, MEMORY 03/04/05/06/07)
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
- **AI (Claude)** — Investigated the owner's 11-point feedback (textures, locked doors, clipping, z-fighting, clutter,
  hold-and-look, grey look, white blob, lighting, camera through head) and wrote `IdiotHandOffGuide-house-fixes.md`
  (root) with exact code, validated on a scratch copy. Applied the same day (entry above; ledger
  `IdiotHandOffManager-status.md`). Review repairs on top of the guide: the one-way front door reopens if the player
  steps back into the doorway while it closes and only locks once fully shut (avoided a lock-outside soft-lock); no
  rattle during a swing; MemoryGrade restarts an interrupted ripple; pull-back aims at the head (no aim jump).
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
