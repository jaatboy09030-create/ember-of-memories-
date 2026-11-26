# Session notes: Unsent

Game: **Unsent** (formerly *Ember Letters*, briefly *What the Fire Keeps*). It is a first-person Godot 4.7.2 game. A grown child comes home to a snowy house, meets frozen memories and an ember guide, plays mini-games, sees a photo flip and a face reveal, and relights the fire.

Repo: https://github.com/jaatboy09030-create/ember-of-memories- (public, `main`)

---

## 1. What was done

### Trees and foliage (Quaternius Stylized Nature MegaKit)
- The kit lives at `assets/stylised assets/stylised assets/Stylized_Nature_MegaKitStandard/glTF/` (the `NATURE_DIR` constant in `scripts/main.gd`).
- `_build_nature()` is called from `_build_exterior()`. It places:
  - garden pines `Pine_1`–`5` at scale 0.6–0.85, with trunk colliders and shadows;
  - young pines and `Bush_Common` along the front wall;
  - rocks, pebbles and straw-tinted grass tufts;
  - trees along the lane;
  - a forest ring: RNG seed 2026, grid step 4.6, with the garden and lane kept clear.
- New shader `shaders/foliage_snow.gdshader`:
  - alpha cut, wind sway weighted by height, and backlit leaves;
  - snow settles on faces that point up.
- Foliage nodes carry the metas `foliage`, `snow`, `shadow` and `tint`. In `_bind_level` they join `outdoor_heavy` and get `visibility_range_end = 80`.

### GitHub
- The project is pushed as a public repo.
- `.gitignore` excludes:
  - `.godot/` and `_shots/`;
  - the two Poly Haven pines (`pine_tree_01`, `pine_sapling_medium`), which are over 100 MB and unused.
- `.gitattributes` sets `text=auto eol=lf` and marks binary files.
- Pushing needs the GitHub CLI credential helper, because the stored Windows credential belongs to another account and gets a 403:
  ```
  git -c credential.helper= -c 'credential.https://github.com/.helper=!"/c/Program Files/GitHub CLI/gh.exe" auth git-credential' push
  ```
- Commits: `417302a` (initial), `c33ac44` (MegaKit), `94052db` (updates), `4412ded` (opening, piano, real props, door controls).

### Name change
- `project.godot`: `config/name="Unsent"`.
- The end card reads `UNSENT / thank you for coming home`.

### Opening screen v1 (one continuous shot)
- Camera at `TITLE_CAM (1.5, 6.5, 22)`, looking at `TITLE_LOOK (0, 2.6, 0)`. Letterboxed, with depth of field.
- The ember writes **"I kept the fire going, in case you"** in the sky:
  - in a hand font (Ink Free or Segoe Script), one `Label3D` per character, in a warm colour;
  - the letters use `ALPHA_CUT_OPAQUE_PREPASS` so the depth of field doesn't blur them.
- The sentence stops unfinished and cools to grey. Ash drifts up, and the house window flickers.
- **"Unsent"** forms in a cold serif font, and a breathing **"tap to continue"** prompt appears.
- Any key, click, touch or gamepad button continues:
  - the name crumbles and the ember arcs down to the gate;
  - the camera follows, to the player's eye;
  - then `_title_handover()` runs: the in-game music starts, the black bars lift, mouse look eases back in, the crosshair fades in, and the title nodes are freed.
- Test mode `--titleshot` saves shots `00a`–`00i`.

### Music
- The opening piano theme is `assets/audio/theme_piano.mp3`: ElevenLabs take 2, about 2:00, in a Moonlight Sonata mood. Take 1 was too muddy.
- The piano plays only on the opening screen. The rest of the game keeps `theme_broken`.
- The ElevenLabs credit cap is **30k** in total.

### Props: home-made box models replaced with Sketchfab models
All models are CC-BY and credited in `assets/sketchfab/CREDITS.md`.

| Object | Model file | Notes |
|---|---|---|
| Gate | `gate_leaf_l/r.glb`, `gate_post.glb` | `GATE_HALF = 1.3`; leaves pivot at ±1.3 and open to −100°×side |
| Fence | `fence_panel.glb`, `fence_post.glb` | tiled per run by `_fence()`, about 1.9 m panels |
| Mailbox | `mailbox_post.glb` | at (2.2, 0, 10.6) |
| Coat rack and scarf | `coat_rack_scarf.glb` | the scarf mesh is `Scarf__0`; the knitting mini-game reveals it row by row with `shaders/scarf_reveal.gdshader` (cut by world height, warm glowing edge) |
| Fireplace | `fireplace_rustic.glb` | the model's own flames were removed; ours are a `GPUParticles3D` at `FIRE_POS (-7.05, 0.32, -5.75)` |
| Kitchen | `kitchen_counter.glb`, `kitchen_cupboard.glb` | the cabinet moved to z = −2.85 |
| Firewood | `firewood_logs.glb` | exported but **not placed yet** |

- The helper `_model(file, pos, rot_deg, collide, s)` loads `res://assets/sketchfab/<file>.glb`.
- The models were prepared in Blender, in a separate scene named "SwapExport", then exported as GLB.

### Doors
- Doors unlock through the story, then the player opens and closes them with **E**:
  - the prompt appears when you face a door within 1.8 m;
  - it is hidden while you stand in the doorway (within 0.75 m).
- Doors creak as they swing and slam softly when they close.
- Automatic closing was tried and then removed.
- Test mode `--doortest` passes.

---

## 2. Dev test modes
`--shots`, `--walktest [--gate]`, `--minitest`, `--perf`, `--titleshot`, `--doortest`

---

## 3. Proposed opening v2 (not built yet)

**Problems with v1**
- The camera is high and centred, and the tilt-shift blur makes the house look like a toy model.
- The sky is empty and flat, with no moon and little snow.
- Every window is dark from the first frame, so there is no mystery.
- The handwriting is too small, and the letters pop in instead of being drawn.
- "Unsent" looks like a generic logo with no link to the sentence.
- The move to the gate is a glide with no sense of arrival.

**Proposed changes**

*Opening screen*
1. **Human-eye camera.** Place the camera low at the end of the lane and remove the tilt-shift blur. Add a slow handheld drift and breath fog.
2. **A living night.** Add a hazy moon behind cloud, stars, ground fog, and close snowfall that catches the ember's glow.
3. **One lit window.** A warm flicker shows in one window and goes dark when the sentence breaks off.

*Title*

4. **Real handwriting.** Make the text bigger and draw it stroke by stroke with a glowing trail. It stops mid-air at "in case you", and the ember flickers.
5. **The sentence becomes the title.** The ash from the sentence gathers into "Unsent". The prompt becomes a small, fading "press any key".

*Transition into play*

6. **The ember leads you in.** On a key press, "Unsent" crumbles into snow. The ember drops to the gate, and the camera walks the lane at a person's pace with footsteps.
7. **Smooth handover.** The black bars open slowly at the gate, the piano fades into wind and the in-game theme, and control returns gradually.
8. **Sound.** Wind, a distant crackle that stops when the window goes dark, and snow footsteps. These would be ElevenLabs sound effects, a few hundred credits.

---

## 4. Still open
- Decide on and build opening v2 (see above).
- The opening still lacks:
  - window silhouettes;
  - the ending callback, where the camera rises to the sky to finish the sentence.
- The house walls, roof, chimney, porch, doors and windows are still hand-built. The options are rebuilding them with the Medieval Village kit or finding realistic replacements.
- Place `firewood_logs.glb`.
- Do a full manual playthrough.

## 5. Working rules
- Keep ElevenLabs use under **30k credits**.
- The user enters API keys and logins themselves. Never paste keys or type passwords.
- In Blender, work only in the "SwapExport" scene; the other scenes have unsaved user work.
- Don't touch the Godot editor while it has unsaved changes.

---

## 6. Later in the session: new house and look pass

- **Pull:** pulled Suyash's restructure (`c806893`). The game now lives in `scripts/<area>/` folders, `scenes/level/house_level.tscn` holds the hand-editable level, and `tools/level_builder.gd` is a one-off builder.
- **Burning ember:** moved to `scripts/characters/ember_fire.gd` (`EmberFire`, a child node of `scenes/characters/ember.tscn`). It has the Vefects flame body plus a trail, sparks and smoke. Test it with `--embershot`.
- **Vefects Stylized Fire:** installed at `res://Vefects/`. It is **gitignored**, because its licence forbids public repositories.
- **New house (two storeys):** built in Blender, scene **TripoHouse**, collection `TripoAssembly`.
  - It combines Tripo parts (roof, window ×18, porch, steps, chimney, lantern) with Blender-built walls, gables, trim, roof and porch snow, icicles, glass panes, and the lit-window glow and silhouette.
  - It is exported to `assets/house/house_exterior.glb`, and `tools/swap_house_exterior.gd` put it into the level:
    - it adds `House/ExteriorShell` (`HouseExterior` script);
    - the old outer walls are hidden but keep their collision;
    - the old roof and porch meshes are removed.
  - The outside parts of `house_window.tscn` are hidden, since the Tripo windows replace them.
- **Look:**
  - `shaders/night_sky.gdshader`: gradient, stars, hazy moon and drifting cloud.
  - The moon is moved behind the house for a backlit look.
  - A faint `MoonFill` light keeps the garden readable.
  - Fog and ambient light are raised.
- **Opening:**
  - The camera starts at eye level at the end of the lane, with the words in the sky above the roof.
  - A figure stands in the warm upstairs window while the line is written, then steps away; the window goes dark and later warms again, empty.
  - Burning leaves (`assets/vfx/burning_leaf.glb`, modelled in Blender in scene **VFXParts**, plus `shaders/burning_leaf.gdshader`) drift through the shot.
  - Fixed a bug where the prompt stayed on screen if you pressed early.
- **New dev tests:** `--tour` (fixed viewpoints, `_shots/t*`) and `--titleshot` (the opening, `_shots/o*`).
- **Still open:**
  - The Blender file is **not saved**; save it to keep the TripoHouse and VFXParts scenes.
  - The upstairs floor is outside only.
  - Nothing from this round is committed yet.

## 7. Sky, leaves, sound (same day, later)

- **Sky** (`shaders/night_sky.gdshader`), modelled on the user's reference:
  - near-black sky;
  - a large detailed full moon (seas, craters with rims, grain, darker edge);
  - a faint brown-violet Milky Way behind the moon;
  - three layers of crisp warm and cool stars.
- **Title shot:** depth of field is off (`cam.focus(-1.0)`) so the sky stays sharp, and fog barely touches the sky (`volumetric_fog_sky_affect` 0.04).
- **Leaves:**
  - `shaders/leaf_fall.gdshader` (particle process shader) makes them glide side to side like a pendulum, rocking and slowly turning, at about 0.22 m/s.
  - They shed flame tongues through a sub-emitter (`LeafFlames`).
  - The leaf mesh was rebuilt in Blender (VFXParts, `BurningLeaf`) with a lobed outline, a stem and a midrib fold.
  - `burning_leaf.gdshader` adds veins and a heat glow ahead of the burning edge.
- **Sound:**
  - New "Memory" audio bus (reverb plus low-pass), made in `sound.gd`. Every `v_*` voice line plays through it, as do `memory_restore`, `heartbeat` and `argument_muffled`.
  - **To do:** regenerate the voice-over (`v_scarf`, `v_artist`, `v_letter`) with `eleven_v3`, an acted voice and emotion tags. Replace the bright "cheerful" cinematic sounds (`memory_restore`, `ember_chime`, `fire_ignite`) with low, slow swells.
  - Blocked because the ElevenLabs API key is invalid (401).
  - Decided: the parent (the letter, "My little artist") is the **mother**; Grandma speaks the scarf line.

## 8. Opening from the user's sketch, voices, transition

- **Camera:** low, off the front-right corner, looking up: `camera_start (11.9, 0.85, 8.7)`, `camera_look (3.8, 5.4, -2.5)`, `text_lift` 1.6.
  - To open the view, garden `Pine2` moved to (13.4, 0, 5.2) and `Pine3` to (11.6, 0, 0.2).
- **Moon:** low on the left, at roof height and partly behind the pines. The Moon light was re-aimed at about 16° up and 66° left of −Z, which also changes in-game moonlight. `moon_size` is 0.075.
- **Clouds:** puffy banks above the rooftops with dark bodies and moonlit edges. Set by `cloud_cover` (lower = more cloud) and `cloud_amount`.
- **Transition:** the camera no longer flies through the garden. It turns to watch the ember fall to the gate, fades to black like closing the eyes, then opens as the player at the gate.
- **Voices:** the ElevenLabs voices "Grandma - Unsent" (Maria Moody) and "Mother - Unsent" (Valentyna) were added to the account.
  - Lines were made with `eleven_v3` plus emotion tags, then slowed with ffmpeg (`atempo 0.84`) and warmed slightly (+2.5 dB bass, −2.5 dB treble).
  - Caption times were lengthened to match. The old files are in the scratchpad (`audio_old`).
- **Sound effects:** `memory_restore`, `ember_chime` and `fire_ignite` were replaced with darker ElevenLabs takes.
