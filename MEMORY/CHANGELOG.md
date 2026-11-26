# CHANGELOG (newest first)

Format: `YYYY-MM-DD — who/what — summary (files)`. Record *why* when it isn't obvious.

## 2026-11-27
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
