# 09 — Camera look ("worn camera", body-cam blend)

Phase 1 implemented: lens + sensor + motion + comfort. Research summary and backlog below so
nobody redoes the research.

## What it is (and is not)
A blend of body-cam / found-footage *feel* with Unsent's quiet look. Deliberately NOT a copy of
Bodycam (Reissad) / Unrecord (DRAMA): camera stays at the eyes (no chest mount), mild barrel
lens (k1 0.1, not fisheye 0.3+), no police HUD, no crosshair removal, DOF/vignette/gold palette kept.

## Where each piece lives
| Piece | Where | Tune |
|---|---|---|
| Lens bend + edge fringe | `shaders/camera_fx.gdshader` (`lens_uv`), driven by `ScreenEffects._update_lens` | ScreenEffects › Lens group |
| Lens off for non-player cameras, 60 % in cutscenes | `ScreenEffects._update_lens` (checks `cam is PlayerCamera`, `.cinematic`) | `cinematic_lens_scale`, `lens_fade_speed` |
| Shadow-weighted grain | shader `shadow_noise`, set in `ScreenEffects.apply_comfort` | `resting_grain`, `shadow_noise` |
| Drift, start/stop spring sway, turn bank, uneven steps, noise shake | `PlayerCamera` (`_update_sway`, `_handheld_rotation`, `_follow_head`) | PlayerCamera › Worn camera sway / Shake |
| Auto exposure | `PlayerCamera.apply_comfort` on the `CameraFocus` CameraAttributesPractical | PlayerCamera › Exposure |
| Accessibility master sliders | `settings/camera_comfort.tres` (`CameraComfort`: motion, shake, lens, grain, exposure_adapt) | Inspector; future options menu calls both `apply_comfort()` |

## Rules learned from the research (keep them)
- Camera MOTION sells the effect more than any filter; filters alone read as "a filter".
- Never make distortion/blur scale with mouse speed (documented nausea cause, itch.io "Fractured Mind").
- Never add input lag to mouse look; sway goes on top of look, never replaces it (Game Accessibility Guidelines).
- Rotational shake > translational; smooth noise (FastNoiseLite) > randf white noise.
- Overscan or crop the lens so edges never smear/black out; bend AFTER deciding what screen pixel
  maps where (face mosaics are tested in flat space after the bend).
- Any screen-space distortion breaks mouse picking via `project_ray_origin` → lens must be off for
  cameras that use the mouse (drawing puzzle).
- Ship every effect with a 0 setting (Xbox Accessibility Guideline 117).

## Research sources (2026-11-26)
- Bodycam lens = post-process material + a physical border image that reacts to light/shake: https://80.lv/articles/developing-a-game-with-realistic-graphics-in-unreal-engine/
- Unrecord realism: photogrammetry + fisheye + shake + exposure lag: https://guided.news/en/special/unrecord-why-it-is-not-fake/
- UE bodycam plugin design (spring sub-stepping, overscan before fisheye): https://forums.unrealengine.com/t/matify-games-bodycam-camera-system-true-first-person-multiplayer-v1-0-0/2848471
- Godot bodycam shader (cyanone): https://godotshaders.com/shader/bodycam/ ; Unity presets (fisheye 0.15–0.3 "police"): https://fronkongames.github.io/store/spiceup
- Godot screen-reading shaders: https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html
- Godot motion blur (not built in as of 4.7; PR #115027 open): sphynx-owner addon https://github.com/sphynx-owner/Godot-Motion-Blur-Addon
- Accessibility: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117

## Rejected for phase 1 (and why)
- Chest mount (camera ~0.25 m lower): breaks the title's "fall into the eyes" shot, interaction ray aim, and dev-test ray positions; the story is about the adult's own eyes.
- Strong fisheye / ~120° FOV: reads as police footage, fights the intimate tone, nauseating.
- Rolling-shutter skew and motion-triggered blur: scale with mouse speed → motion sickness.
- Full CompositorEffect pipeline: far more code for no visible gain over the one canvas pass.

## Phase 2 backlog (needs the owner's decision)
1. Options menu wired to `CameraComfort` (+ FOV slider). Needed before release.
2. Motion blur via sphynx-owner addon (camera-rotation blur kept low), default off.
3. Diegetic overlay: REC dot + timestamp on the night of return; childhood dates in memory rooms stop at the year the child left (twist clue).
4. Memory rooms switch to an old-camcorder look (4:3, softer lens, chroma bleed); restoring a memory "tracks in" and steadies the image.
5. Auto-exposure re-meters toward the ember when it flares.
6. Physics interpolation (Godot 4.4+) to remove camera stepping on >60 Hz screens — project-wide, needs its own test pass.
