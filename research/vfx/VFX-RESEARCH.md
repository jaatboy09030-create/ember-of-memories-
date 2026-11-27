# VFX research: how studios make game VFX outstanding, and how to do it in Godot 4

This is the master file from a ten-researcher study run on 2026-11-27. The ten reports total about 55,000 words and cite about 360 sources:
- GDC and SIGGRAPH talks;
- studio blogs (Riot, Blizzard, Sucker Punch, Bungie, Santa Monica, FromSoftware, Naughty Dog, Epic and others);
- 80.lv and ArtStation breakdowns, and the realtimevfx.com forum;
- shipped code (Celeste's `Player.cs`);
- the Godot docs, godotshaders.com and GitHub;
- Reddit and X, mostly through search results and write-ups, because those sites block direct fetching.

This file pulls together what the reports agree on. For depth, numbers and code, open the topic files below. Each one ends with an "Apply in Godot 4" section and a numbered source list.

| # | File | What it covers | Sources |
|---|---|---|---|
| 01 | [01-vfx-fundamentals.md](01-vfx-fundamentals.md) | Readability, shape language, timing envelope, value budget, layering, animation principles, critique | 26 |
| 02 | [02-aaa-studio-vfx.md](02-aaa-studio-vfx.md) | Riot, Blizzard, Naughty Dog, Santa Monica, Sucker Punch, Insomniac, Bungie, FromSoftware, Epic, miHoYo, Remedy | 50 |
| 03 | [03-combat-attack-vfx.md](03-combat-attack-vfx.md) | Hit stack, hitstop numbers, trauma shake, slashes, trails, muzzle flashes, explosions, telegraphs, dissolves | 37 |
| 04 | [04-stylized-anime-vfx.md](04-stylized-anime-vfx.md) | Anime and toon effects, thresholded shapes, animating on 2s/3s, stepped ramps, outlines, impact frames | 32 |
| 05 | [05-godot-vfx-toolbox.md](05-godot-vfx-toolbox.md) | Every GPUParticles and ProcessMaterial property, particle shaders, sub-emitters, trails, collision, CompositorEffects, 4.0→4.7 changes | 44 |
| 06 | [06-vfx-shaders-textures.md](06-vfx-shaders-textures.md) | Master shader, erosion, panning, distortion, flowmaps, ramps, channel packing, flipbooks, motion vectors, 6-way smoke | 34 |
| 07 | [07-environmental-vfx.md](07-environmental-vfx.md) | Fire, embers, smoke, snow, rain, fog, fireflies, moths, lightning, magic ambience, sim baking | 43 |
| 08 | [08-vfx-performance.md](08-vfx-performance.md) | Overdraw, budgets in ms, GPU vs CPU, pooling, pipeline stutter, culling, mobile | 28 |
| 09 | [09-vfx-integration.md](09-vfx-integration.md) | Lights, bloom, post effects, hitstop, camera, sound sync, haptics, residue, UI feedback | 31 |
| 10 | [10-vfx-workflow-community.md](10-vfx-workflow-community.md) | How pros work, critique culture, beginner mistakes, learning path, asset packs, 20 commandments | 36 |

---

## 1. What makes VFX outstanding: what all ten researchers agreed on

These are ranked by how often and how strongly the sources stressed them.

1. **Timing beats everything.** Pros keep repeating the same advice: spend less time on shaders and more on timing [10]. Every effect has three beats: **anticipation, then impact, then dissipation**.
   - The impact is fully active within the **first ~25% of the effect's life** (Riot).
   - The curves are never linear.
   - Riot again: *"If your FX feel long, they're way too long."* [01, 04, 10]
2. **Readability before beauty, and loudness matches gameplay power.**
   - Riot, Blizzard (Diablo IV "Gameplay First"), FromSoftware, Bungie and Valorant all write this down.
   - Ultimates may be loud; basic attacks and ambient effects stay quiet.
   - Elden Ring recoloured a basic spell because it looked too strong. [01, 02]
3. **Shape and silhouette first, in greyscale.** Block an effect in with crude shapes and no colour, then retime it until it feels right. Textures, shaders and polish come last. [01, 10]
4. **The brightest value is a budget.**
   - Keep the body of an effect in the mid-values, and save peak white for the one-frame flash at the impact point or core.
   - Avoid pure black and pure white.
   - Putting darker darks next to the hot core makes the effect read as powerful. [01, 04]
5. **Layer an effect in three tiers.**
   - Primary: carries the gameplay read, with a clear silhouette and high opacity.
   - Secondary: motion and impact support, lower value, more transparent.
   - Tertiary: sparks, motes and dust, as optional flavour.
   - Every element must have a job. [01, 10]
6. **An effect is a bundle of events, not one particle system.** A good hit fires all of these **on the same frame**: hitstop, a hit pose, a 1–2 frame white flash, sparks at the contact point, a short light, camera shake, a sound transient and rumble. The slow aftermath follows: smoke, scorch marks, embers. Remove any one layer and the hit goes soft. [03, 09]
7. **The effect has to live in the world.**
   - Real short-lived lights.
   - Lit or shadowed particles: Sucker Punch smoke casts shadows, and Diablo IV moved to lit particles.
   - Decals and residue that stay behind.
   - One shared **wind field** driving grass, leaves, smoke, snow and cloth (Ghost of Tsushima's two-person VFX team built their whole look on this).
   - The world reacting to the effect. [02, 07, 09]
8. **Hand-made irregularity.**
   - Vary sizes and speeds, swap variants, and break regular loops.
   - Stylised effects hold frames on 2s or 3s with uneven timing.
   - Effects that are too regular read as computer-made. [04, 06]
9. **Coherence is what separates good from great.** All the effects in a game should form one system: a shared palette and shared value rules, with consistent meaning for each colour and shape. [01, 02]
10. **Restraint is art direction.** Elden Ring limited glow, flashes and primary colours, and used translucent rather than additive blending. Firewatch's team said less visual noise gives a stronger emotional core. For a melancholy game, use fewer, slower, softer particles. [02, 07]

## 2. The anatomy of one effect, as a reusable template

| Beat | Share of life | What happens | Typical tools |
|---|---|---|---|
| **Anticipation** | Lives in the *character animation* and a brief telegraph | Gather, charge-up, glint. Keep the frames before the impact **clean** | Ground decal or telegraph, inward particles, a dimming light |
| **Impact** | Peaks in the first ~25% | Flash (1–2 frames), core shape, sparks, light pop, hitstop, shake, sound | Mesh flash, stretched sparks, OmniLight, camera trauma |
| **Dissipation** | The rest, kept short | Erosion (not a fade), smoke, embers, decal cooling | Alpha-erosion shader, slow smoke cards, scorch decal |

Supporting details from the reports:
- **Shape language:**
  - Circles read as safe, triangles and spikes as dangerous, squares as stable.
  - Stretched sparks that shrink to dots read as speed and power; round dots read as magic.
  - Halo Infinite gives each weapon its own muzzle-flash shape. [01, 03]
- **Colour:**
  - Use one dominant hue plus a small, desaturated accent.
  - Effects get the widest saturation range in the game; keep the environment's saturation lower so effects cut through.
  - Colour has no built-in meaning, so keep each colour's meaning consistent within your game. [01]
- **Animation principles:** anticipation, follow-through, slow-in/slow-out, squash and stretch along velocity, overshoot. [01]

## 3. Combat and attack effects: the numbers

| Thing | Values the sources give | Source |
|---|---|---|
| Hitstop | SFV 8/12/15 frames (light/medium/heavy); Smash formula capped at 20 (Melee) / 30 (Ultimate) frames; Celeste 0.05 s (dash) / 0.1 s (explosion); Godot community 0.04–0.08 s light, 0.10–0.18 s heavy | [03, 09] |
| Who freezes | **Both** attacker and victim; the victim shakes during the freeze with decaying amplitude (side-to-side on the ground, up-down in the air) | Sakurai [03] |
| Hit flash | Full on frame 0, gone in ~100–200 ms | [01, 03] |
| Muzzle flash | 1–2 frames, 4–8 random variants, plus a short light, sparks and lingering smoke | [03] |
| Screen shake | Trauma model: trauma 0–1, decays linearly; offset = trauma² × max × **smooth noise**; clamp it; make it directional where possible | Eiserloh GDC 2016 [03, 09] |
| Audio sync | Sound may trail the visual by ~188 ms unnoticed, but only lead it by ~75 ms. Play it on the impact frame | [09] |
| Many hits at once | Cap new shakes and hitstops at ~1 per frame and new sounds at 2–3 | [09] |
| Slashes | Hero slashes use **authored swipe meshes** with a panning, eroding texture. Ribbon trails are quick but facet on fast swings | [03] |
| Telegraphs | Size them to the real hitbox; the danger area must never lie | Riot [01, 03] |
| Accessibility | Settings for shake intensity and flash/impact-frame toggles; soften big luminance jumps (photosensitivity) | [03, 04] |

God of War (2018) pulled its camera back and cut shake heavily, then won the impact back with sound and bigger hit poses. Feel can come from more than one channel. [09]

## 4. The technical-art core: the master shader

Most stylised VFX is **one master shader** reused everywhere. Harry Alisavakis's "VFX Master Shader", the realtimevfx "bread and butter" thread and Riot artists all list about the same features [06]:
1. **Greyscale noise or shape textures** (data, not colour).
2. **Panning UVs**, with the same noise layered at power-of-two scales (0.5, 1, 2). This is Diablo 3's "scale by mids".
3. **UV distortion and flowmaps**, plus polar coordinates for rings and swirls.
4. **Alpha erosion** in place of an alpha fade: a threshold animated against the mask, `step` for hard edges and `smoothstep` for soft. The shape dissolves from its thin parts inward. Drive the threshold from particle colour alpha, so one material serves every particle.
5. **Gradient map (colour ramp)** to colour it. One greyscale asset then becomes a campfire, a candle or a magic flame; stylised effects use a stepped 2–4 band ramp.
6. **HDR emissive** roughly 2–10× above the bloom threshold. Blue and magenta need far more energy than green to bloom.
7. **Depth fade (soft particles) and Fresnel**: cheap, always worth it, and they remove hard intersection lines.

Texture rules [06]:
- **Import noise, erosion, flow and motion-vector textures as linear.** In Godot, don't use `source_color` on them, or the erosion timing bunches up.
- Use the full 0–1 range.
- Pack channels only when they share UVs and resolution, and put the high-contrast mask in alpha.
- **Flipbooks are expensive:** a 2048² sheet at 8×8 leaves 256 px per frame. Motion-vector blending cut one UE5 explosion from 121 to 32 frames. Stylised games cap flipbooks at 4×4.
- **Smoke lighting, from cheapest to best:** baked gradient → normal-mapped flipbook → 4-way or 6-way lightmaps.

## 5. Environmental and ambient effects

- **One global wind drives everything** (Ghost of Tsushima: wind plus invisible "vorticles"). If the smoke leans one way and the snow another, the scene feels fake. [02, 07]
- **Ambient effects are a system that follows the camera**, not hand-placed props. Snow, dust, fireflies and ash are camera-following emitters whose density comes from data. [07]
- **Fire is a stack:**
  - flame body, hot core, embers, smoke, heat distortion, glowing bed;
  - **a flickering light, which sells the fire more than the sprite does**: layered noise, or Valve's Quake-style 10 Hz light strings, plus a few cm of position jitter so shadows move.
  - One UE4 campfire uses 14 emitters. [07]
- **Snow:** dim, mixed flake sizes, about 1 m/s fall with sway. Snow that's too bright reads as "magic dust". Keep it out of interiors with collision or occlusion. [07]
- **Smoke and fog cards** need a depth fade at geometry *and* a fade near the camera. Render fine sparks big enough to survive TAA, which smears sub-pixel motes. [07]
- **Melancholy scenes:** rising embers and warm motes caught in light beams work better than fireflies on a snowy night. Keep everything slower and softer. [07]

## 6. Performance: what it actually costs

- **The cost is pixels, not particles.** Overdraw = translucent layers × pixels covered × shader instructions. Ten huge smoke quads can cost more than 10,000 tiny sparks. [08]
- **Budgets are small.** DICE's *Battlefront* gave its whole effects budget a little over 1 ms (snippet). Community Niagara targets are under 2 ms on PS5, under 1.5 ms on PS4 and under 1 ms on mobile/VR. Budget for the worst moment, not the showcase. [08]
- **Trim the quad:** an 8-vertex mesh fitted to the alpha shape covers 52% of the original quad's pixels. Use mesh particles for hero shapes; a Riot-style artist uses one animated mesh "about 95% of the time". [02, 08]
- **Use priority tiers** instead of lowering quality everywhere: Destiny's 1 = essential, 2 = flavour, 3 = environment, dropped from the bottom under load. Elden Ring uses per-effect LOD. [02]
- **GPU simulation pays off only at about 1,000+ particles.** In Godot, `amount_ratio` saves nothing, because the full `amount` is still allocated; lower `amount` to actually save. [05, 08]
- **First-use stutter is pipeline compilation.** Godot 4.4+ precompiles pipelines and has ubershaders, and 4.5+ adds the shader baker. Still render every effect once behind cover at load. Avoid large `preprocess` values. [05, 08]
- **Set tight `visibility_aabb` bounds** per effect (the default is an 8 m box). Profile at a fixed resolution with RenderDoc and Godot's visual profiler. [08]

## 7. The Godot 4 playbook (4.7)

**Tool choice** [05]:

| Need | Use |
|---|---|
| Most effects | `GPUParticles3D` + `ParticleProcessMaterial`. CPUParticles is frozen and lacks trails, collision, attractors and sub-emitters |
| Custom motion, spawning from particles | `shader_type particles` (`start()` / `process()`, `CUSTOM`, `emit_subparticle()`) plus a sub-emitter |
| Look of each particle | A spatial shader on the draw-pass mesh (master shader, §4). Colour ramps only show if the draw material reads vertex colour |
| Slashes, shockwaves, rings | A `MeshInstance3D` swipe or ring mesh with an eroding, panning shader, animated by `AnimationPlayer` |
| Trails | Built-in particle trails (`RibbonTrailMesh` / `TubeTrailMesh`), the GPUTrail addon, or 4.8's native `Trail3D` |
| Ground interaction | Particle collision (Box/Sphere/SDF/Heightfield) and attractors. GPU-only; they don't see physics |
| Scorches, residue | `Decal`, fading and cooling over time |
| Screen effects | Distortion via `hint_screen_texture`, which can't see transparent objects; `CompositorEffect` (4.3+) for full-screen passes |
| Sequencing | One scene per effect with `play()` / `stop()`; `AnimationPlayer` for frame-accurate timing; Start / Loop / End parts |

**Gotchas that cost iterations** [05, 08, 09]:
- To fire a one-shot burst again, call `restart()`. Setting `emitting = true` does nothing until all particles are dead.
- Since **4.6, glow blends before tonemapping in Screen mode**, so emissive effects tuned before 4.6 come out too bright. Use AgX, which keeps hot cores from bleaching to white.
- Flash lights: short-lived, no shadows, small range, and **zero volumetric-fog energy**, or temporal reprojection leaves a trail.
- `Engine.time_scale` hitstop needs its restore timer to ignore time scale (`create_timer(t, true, false, true)`).
- Animate the whole system on 2s/3s by setting `fixed_fps` to 12 or 8 with `interpolate = false`. [04]

**Ready-made code is in the topic files:**
- hitstop autoload, trauma shake, hit-flash overlay, swipe-slash shader, shockwave, death dissolve [03];
- master billboard shader, motion-vector flipbook, 6-way lighting [06];
- toon threshold shader, inverted-hull outlines, impact frame [04];
- campfire stack, flicker light, global wind singleton, snow, fireflies, moths [07];
- an effects dispatcher, pooled lights, chromatic aberration and radial blur, scorch decals [09];
- a pooling and warm-up autoload, overdraw checks [08];
- a VFX "lab" scene and slow-motion review [10].

The snippets haven't been compiled in the project yet; test each one before relying on it.

## 8. How pros work: the loop

1. Get a **brief**: what the effect is *for*, and how important it is. [10]
2. Build a **reference board**: real footage, slow motion, anime, other games. [10]
3. List every **element**: core, flash, sparks, smoke, decal, light, shake, sound. [10]
4. **Block it in** in engine, in greyscale, in context. Say the sound out loud ("fwoosh-BANG") to time it. [10]
5. Do a **timing pass** until it feels good with no style at all. [01, 10]
6. **Build the final elements** one emitter at a time. [10]
7. **Integrate**: sync to animation frames, sound, light, camera. [09, 10]
8. **Optimise** using the overdraw view, trimmed sprites, and lower spawn rates until the impact *starts* to drop. [08, 10]
9. **Record** every version, alone and in game. Ask for **specific** feedback ("impact needs more speed", not "add more life"). [10]

**Making an asset pack not look stock** [10]:
- Retime it to your animation and sound.
- Recolour it through a gradient map in your palette.
- Replace the hero texture.
- Kitbash: combine emitters from several effects and add one element of your own.
- Tie it to the world with a light, decal, camera response and sound.

**Learning path:** realtimevfx.com monthly sketches, VFX Apprentice (Jason Keyser), the Riot style guide, Gabriel Aguiar, Sirhaian, godotshaders.com, GDQuest. Build a campfire, then a fireball, then an impact: finish small things rather than watching tutorials. [10]

## 9. The 20 commandments of outstanding VFX (all ten reports, merged)

1. Time it first. Timing is learned; shaders can be copied.
2. Readability before beauty; loudness matches gameplay power.
3. Block in greyscale shapes before any texture or colour.
4. Three beats: anticipation (in the animation), impact in the first quarter, a short dissipation.
5. If it feels long, it's far too long.
6. Never use linear curves.
7. Spend the brightest value once, at the impact or core. No pure black or white.
8. Layer primary, secondary and tertiary; every element has a job.
9. Silhouette and shape language tell the player what the effect does.
10. One dominant hue plus a small accent; colour meanings stay consistent across the game.
11. Erode, don't fade.
12. One master shader, with greyscale data and a gradient ramp for colour.
13. Fire every channel on the impact frame: visual, light, hitstop, shake, sound, rumble.
14. Effects light the world, touch the world and leave residue.
15. One wind for everything.
16. Irregularity reads hand-made; perfect loops read computer-made.
17. Pixels are the cost: trim quads, use meshes, keep it short.
18. Iterate in context, in game, at gameplay speed and in slow motion, with specific feedback.
19. Restraint is a style. Melancholy effects are slower, softer and fewer.
20. Make it a system: shared palette, shared rules, priority tiers, accessibility settings.

## 10. What this means for *Unsent*

- **Fits the tone:** Elden Ring-style restraint. Desaturated effects, translucent rather than additive blending, few slow particles, and light that sells each effect. [02, 07]
- **Next wins, cheapest first:**
  - one global wind uniform shared by the snow, burning leaves, ember smoke and foliage sway [07];
  - a flicker light per fire source, driven by noise or a light string [07];
  - rising embers and warm motes in the gate scene's light instead of fireflies [07];
  - ash or scorch decals where burning leaves land [09];
  - re-check every emissive effect against the 4.6 glow change [05].
- **Existing effects to tidy up:**
  - The burning leaves already use `emit_subparticle` and an erosion-style burn. Add a gradient-ramp colour and a short flicker light [05, 06].
  - The Vefects fire pack: retime it, recolour it with a ramp, add our own core shape, and tie it to a light and decal so it doesn't look stock [10].
- **If combat is added** (the boy's fight scene): use the hit stack and numbers in §3, with gentle values, and provide accessibility toggles for shake and flashes.

## Caveats

- **Reddit and X:** these block automated fetching, so community wisdom comes mostly through search results, the realtimevfx forum, 80.lv write-ups and Polycount.
- **Marked claims:** claims based only on a search snippet are marked "(snippet)" and researcher reasoning "(analysis)" in each file.
- **Paywalled talks:** several GDC Vault talks are members-only, so they are summarised from session pages and secondary coverage.
- **Thin sources:** Insomniac, miHoYo, Fortnite, Control and Hogwarts Legacy have little public material.
- **Untested values:** the Godot snippets and values are starting points that haven't been run in the project. Test them in the editor first.
