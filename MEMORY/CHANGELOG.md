# CHANGELOG (newest first)

Format: `YYYY-MM-DD — who/what — summary (files)`. Record *why* when it isn't obvious.


## 2026-11-27 (blink feel pass)
- **Faces never clear in the blink demo:** blinking at the eye woke ghosts with `wake()`, which faded their face mosaic fully clear (grandma's face showed), and `remember()` raised global clarity each time. Now `EyeHotspot` calls `wake(false)` and the demo no longer calls `remember()`. Face mosaic cap raised 4 -> 8 (a 5th visible face used to go unpixelated). (`memory_figure.gd`, `eye_hotspot.gd`, `blink_demo.gd`, `screen_effects.gd`, `camera_fx.gdshader`)
- **Ink edge: keep the chaotic world-space one.** A cleaner, smoother splat edge (d3d7bee) was tried and reverted: the user found it smooth and bad. Pulling the camera back was rejected too. Don't smooth the void edge.
- **Blink to begin:** demo waits on black ("Blink to begin.") for one blink before the intro starts (`blink_demo.gd` `start_prompt`).
- **Blink demo pacing:** voices 1.12x at same pitch, line timings x0.85; blink offer (metronome) only once the last line is nearly said; blinking over a line leaves "words—" on screen; blinking before a line plays a snatch of it.
- **"Hold your eyes shut" cue:** closing-eye glyph + "hold" (first 3 times) + faint leak of the hidden sound, whenever a beat hides something behind closed eyes.
- **Doors:** new `PanelDoorModel` six-panel door + frame (Poly Haven fine_grained_wood) on all interior/front doors and the study door; old box frame hidden.
- **Snow:** `SnowTrack` decal footprints on porch (half filled, with a snow patch), road and lane; Dad's coat on the hook visible when the front door opens.

## 2026-11-27 (VFX + sound pass)
- **Blink demo voiced:** 119 lines with a 3-voice cast (son / Mum / new "Dad - Unsent"), lines found by text hash, blink cuts the voice, line timing waits for speech; better eyes-closed sounds. Blink autoplay runs to the ending; storytest PASS. See 12-vfx-and-audio.md.
- **XMavrik + AI (Claude, idiot-vfx skill)** — See `12-vfx-and-audio.md`.
  - `scripts/vfx/` kit: FlickerLight, FireVFX, MemoryMotes, LightMotes, VFXKit.
  - The fireplace is layered and moved onto the grate; it was inside the base.
  - Golden motes and a light pop on every memory restore; warm motes at the gate lamp and doorway.
  - One global `wind_strength`, driven by audible gusts.
  - Moonlight with a window cookie through every window; cold room fills lowered.
  - Sound: variants (6 snow / 6 wood steps), Music/Voice/Memory buses, music ducking under voice, ambience beds and random sprinkles, hallway clock, door rattle, ember whoosh, fire crackles.
  - 7 new voice lines (new voice "Child - Unsent" plus the Mother's "...then go!"), each paced and warmed individually.
  - storytest, doortest, walktest PASS.

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
- **Merge PR #4 + PR #5** — opening/first-scene pass merged on top of the house fixes, photo memory and blur work.
  `house_level.tscn` = PR #5's rebuilt level + `tools/swap_house_exterior.gd` re-run + PR #4's hand edits re-applied
  (ExteriorShell on HouseExterior, DoorwaySpill/PathSpill/FenceShadowLight, street-lamp glow, fence SnowyProp, moved
  Pine2/Pine3/lane bush). Lighting in `main.tscn` follows PR #4 (ambient 0.06 + SDFGI). Title continue-to-game follows
  PR #4; photo letter timing from PR #4 plus PR #5's fade-out; dev_tests has all flags.
- **Tears removed; smoother focus; no camera fight after pickups** — owner asked to drop the tears (player_tears.gd and
  its nodes deleted). Autofocus: 5-ray median, log-space easing with a rate cap, near blur no longer toggles at 1 m
  (`focus()`). Glances: one at a time, cancelled by any look input; no glance on drawing-piece pickup. (player_camera.gd,
  player_body.gd, player.tscn, photo_memory.gd, drawing_memory.gd, MEMORY 03/04/07)
- **Photo memory rework** — picks the photo up in both hands (TwoBoneIK3D arms + HeadBow), camera goes over the shoulder
  (half face + photo), slow push-in while the glass becomes a mirror showing the face (SubViewport ReflectionCamera +
  photo_glass shader), tears, letter, fade back to first person. Camera kept out of walls with `PlayerCamera.safe_position`
  and picks the roomier shoulder. Face mosaics off during it. New `--phototest`. Known issue: tear spawn points not yet on
  the eyes. (photo_memory.gd, photo_frame.gd/.tscn, photo_glass.gdshader, player.tscn, player_body.gd, player_hands.gd,
  head_bow.gd, player_tears.gd, player_camera.gd, screen_effects.gd, dev_tests.gd, MEMORY 03/04/05/07)
- Owner: the ember waits **at the garden gate in the fence** for the player (`TitleSequence.gate_point` (0, 1.3, 10)), not at the house door.
- **XMavrik + AI (Claude)** — First scene matched against the reference in a measured loop. A critic agent compares
  screenshots; see `research/critique_v1.md` and `research/compare_v1..v4.png`.
  - Brightness: the frame now averages ~14% (the reference is 17%).
  - Camera and look:
    - The player starts at z 16.3; the first view uses fov 56 and pitch +2.5 (`TitleSequence.first_scene_fov/pitch`),
      widening to 70 on the first step.
    - The house is a dark silhouette: MoonFill 0.025, ambient 0.06, SDFGI 0.7, fog 0.006 with anisotropy 0.25.
    - The opening swaps all of these back via `_apply_opening_look`.
  - Lights:
    - The street-lamp glass glows: `SnowyProp.glow_surfaces`.
    - `FenceShadowLight` energy is 9, range 6.
    - New `DoorwaySpill` (energy 14) and `PathSpill` lights; porch lantern at 2.4.
    - The front door opens when the first scene starts.
  - Materials:
    - Fence and gate posts are weathered white with snow caps, using the new `SnowyProp.tint` / `saturation` and
      `memory_prop.own_saturation`.
    - Snow colour is never pure white; pine backlight is lower.
    - The ground is a darker snow tint.
  - The lane bush that sat in frame moved to (-5.4, 15.6).
  - Tests: storytest PASS, walktest PASS, doortest PASS. `walktest --gate` stops at z = 3 (12 m walked), the same
    known limit as before.
- **XMavrik + AI (Claude)** — **Research pass + first-scene lighting.**
  - `research/` holds 10 researched reports (~47k words, ~510 sources), an index (`research/README.md`), and the combined
    plan `research/00-unsent-opening-recipe.md`. Read 00 before any lighting or art-direction work.
  - The owner's reference (`research/reference_target.webp`) is the **first gameplay scene** (the player at the gate),
    NOT the title. Changes for it:
    - Moon behind the house, top-left of that view (`moon_size` 0.05).
    - AgX contrast 1.2 / white 9, exposure 0.82, glow 0.5 / bloom 0.03, ambient 0.2, MoonFill 0.08, SSR on.
    - Wet cobble path (darker, roughness 0.38).
    - Every window lit through `shaders/curtain_window.gdshader` (`HouseExterior.all_windows_warmth`); they go out when
      you reach the porch (ArrivalMemory).
    - Street lamp: `FenceShadowLight` sits just behind the fence so picket shadows reach toward the player; the old
      camera-side lamp light is dimmed; a `LampGlassGlow` ball was added.
    - The ember waits in the doorway (`TitleSequence.gate_point` = door).
    - `GameDirector.start_saturation` is 0.8, so the gate scene is in colour and drains on the porch.
  - The title keeps its own look: `TitleSequence._apply_opening_look()` / `_restore_gameplay_look()` swap the moon
    direction and size, exposure, glow, ambient, AgX and MoonFill, switching back while the screen is black.

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
- **XMavrik + AI (Claude)** — Title name is now the owner's wordmark image (`assets/ui/unsent_wordmark.png`,
  `TitleOverlay/Wordmark`, fades in/out; the Bodoni name letters and `game_name`/`name_font` exports are gone — Bodoni Moda
  28pt is still used for the prompt). Lighting matched to the mock-up:
  - darker walls (`wall_tint` 0.36/0.38/0.45);
  - smaller moon haze (`halo` 0.28);
  - stronger porch light;
  - `GableWarmth` (energy 7) only lights the house — house meshes are on **render layer 4** (`HouseExterior.HOUSE_LAYER`),
    and the light's cull mask is 8;
  - `opening_vignette` 0.6.
- **XMavrik + AI (Claude)** — Logo + icon from the owner's lily logo:
  - `assets/ui/unsent_lily.png` (the lily cut from the logo), `unsent_logo.png` (lily + wordmark), `unsent_icon.png/.ico`;
  - `project.godot` `config/icon` + `config/windows_native_icon` now use the lily;
  - title screen: `TitleOverlay/LogoMark` lily bottom-right (fades in with the prompt, out on continue);
  - the name now uses Bodoni Moda **18pt Bold** (sturdier hairlines, closest to the logo wordmark), size 150, no extra tracking.
- **XMavrik + AI (Claude)** — Title text redone from the owner's mock-up:
  - "UNSENT" is now on-screen letters (`TitleOverlay/TitleName`, one Label each so they still form/crumble) in **Bodoni Moda
    72pt SemiBold**, low and centred, with a soft `NameGlow` behind;
  - the prompt reads "‹ TAP TO CONTINUE ›" in Bodoni Moda 28pt Medium with a `PromptGlow`;
  - the opening has no letterbox (full frame);
  - fonts are in `assets/fonts/bodoni_moda/` (OFL, licence file included).
- **XMavrik + AI (Claude)** — Opening matched to the owner's painted reference:
  - snowy bare foreground branches (`assets/vfx/foreground_branches.glb`, Blender scene `Branches`), in the TitleSequence
    scene as `ForegroundBranches`, snapped to the opening camera; near-only depth of field (`near_blur_distance`) blurs them;
  - sky rewritten (huge golden moon `moon_size` 0.15 with sparkle, clouds banked round the moon and drawn over it, blue Milky Way,
    navy sky; colour uniforms are sRGB);
  - Moon light re-aimed high-left (~29 deg up);
  - title-only warm lights `TitleLights/{PorchWarmth, GableWarmth}`; opening is in colour (`opening_saturation` 0.9) and fades
    to `start_saturation` on continue;
  - `HouseExterior.wall_tint` darkens the siding;
  - leaves bigger, closer, fully smouldering, more flame.
  The sky line text is currently empty (`unfinished_line = ""`; edited outside this session) so the title goes straight to the name.
- **XMavrik + AI (Claude)** — Pulled PR #2 (this folder), then (uncommitted when written) the look + opening pass:
  two-storey Tripo/Blender house (`assets/house/`, `scripts/level/house_exterior.gd`, `tools/swap_house_exterior.gd`);
  burning Ember (`scripts/characters/ember_fire.gd`, ember_wisp/ember_smoke shaders; Vefects local only);
  night sky shader (detailed moon, Milky Way, stars, clouds); Moon re-aimed low-left + MoonFill; opening re-shot from the
  owner's sketch (low corner angle), lit-window figure, burning leaves (leaf_fall + burning_leaf shaders, Blender leaf),
  no-fly-through transition (turn + fade); `Memory` audio bus; new voice-over (Grandma/Mother ElevenLabs voices) and darker
  memory_restore / ember_chime / fire_ignite; dev flags `--titleshot --tour --embershot`; garden Pine2/Pine3 moved for the shot.
  storytest + walktest PASS. Docs: 01, 02, 03, 05, 06 (R12-R14), 07.
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
