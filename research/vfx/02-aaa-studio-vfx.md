# 02: How big studios make VFX (case studies, pipelines, team practice)

Scope: Riot, Blizzard, Naughty Dog, Santa Monica Studio, Sucker Punch, Insomniac, Bungie, FromSoftware, Epic, miHoYo/HoYoverse and Remedy. For each studio this file covers what its VFX has to do, the techniques it has documented, its tools and pipeline, how the team works, and what a small Godot team can reuse.

Evidence legend: claims without a marker come from fetched pages listed in Sources. "(snippet)" means the claim comes only from a search-result snippet. "(analysis)" marks my own reading. Several primary GDC Vault pages are members-only, and a few studio pages (Epic tech blog, ArtStation Magazine, bungie.net) returned 403 or empty content, so those claims are marked as snippets.

---

## 1. Key takeaways

- **Gameplay comes first, written down and ranked.** Riot (LoL style guide, VFX-update goals), Blizzard (Diablo IV "Gameplay First"), FromSoftware (boss effects: "gameplay first, then visual balance"), Bungie ("VFX's main job is communication") and Valorant (competitive integrity is one of three pillars) all put readability above beauty in a ranked list. Riot's VFX-update team ranks its goals explicitly: gameplay fixes, then readability and noise, then theme.
- **Visual loudness should match gameplay power.** Riot ties an effect's size and brightness to its gameplay impact. Diablo IV keeps loud effects for ultimates and lets weak skills recede. Elden Ring shifted Stone Pellet from blue to green because the blue crystal looked too strong for a basic spell.
- **Use a three-beat, non-linear envelope: anticipation, then impact, then dissipation.** Riot's guide puts peak value and saturation inside the first quarter of an effect's life and calls linear timing harmful. A Riot-style breakdown uses a hit flash of about 0.1 s.
- **One shared world signal can drive everything.** Ghost of Tsushima runs a single wind field through grass, trees, cloth, rope, smoke, leaves, mud, blood and even quest navigation (the "windicator"). God of War built wind motors and receivers on a fluid-sim wind field. This is the best value-for-effort idea in this file for a small team (analysis).
- **Small teams ship huge results.** Ghost of Tsushima's VFX team was two people for most of development and relied on automated, self-correcting placement rather than hand placement. Destiny's Spec Ops team was small and cross-discipline, so each person took an idea from start to finish.
- **Expression-driven, in-engine authoring with sub-second iteration.** Sucker Punch (text expressions compiled to PS4 compute shaders), Bungie (expression node graphs with an HLSL converter and a bytecode interpreter on CPU or GPU) and FromSoftware (an in-house FX Editor chosen for fast iteration on console) all made the authoring loop short above everything else.
- **Make particles live in the world.** Sucker Punch smoke casts and receives shadows and blends with haze. Diablo IV moved from unlit to lit, PBR-aware particles. The Last of Us Part II spawns and simulates on geometry through screen-space data. All of these exist so an effect never looks composited on top of the scene.
- **Use priority tiers and LOD rather than lowering quality everywhere.** Destiny sorts particles into priorities 1 (essential), 2 (flavor) and 3 (environment) and drops the low ones first under load. Elden Ring uses reduced buffers and per-effect LOD, and distant effects lose glow and point lights. Niagara Effect Types cull systems by budget.
- **Mesh shaders beat particle spam.** Destiny's Gambit Mote and raid orbs use mesh shaders (crossed quads, cylinders, inverted shells) to reduce overdraw and stay outside particle budgets. A Riot-style artist uses one animated mesh particle "about 95% of the time".
- **Restraint is a deliberate art direction.** Elden Ring avoided bright primaries, desaturated boss effects, and used translucent rather than additive blending to stop detail blowing out. That suits a dark, melancholy game such as *Unsent* well (analysis).
- **Effects artists sit with designers and audio.** Overwatch's Rachel Day iterates projectile speed with designers. Riot builds VFX updates "with constant feedback from sound and game designers". At FromSoftware, animators make spell motion first and effects and sound follow.

---

## 2. Deep dive: studio by studio

### Riot Games (League of Legends, Valorant, Arcane-style look)

**What the VFX must do.** Spells must stay readable in a five-versus-five teamfight seen from a fixed top-down camera. The public LoL VFX style guide lists four goals in order: gameplay clarity, minimal clutter, the champion's theme, then surprise and delight.

**Documented techniques (LoL style guide, via the VFX Apprentice summary):**
- *Primary and secondary layers.* The primary layer carries the gameplay signal with high value, clear silhouette, high opacity and a sharp focal point. Secondary layers use lower value, lower opacity, blurred simple shapes and subtle motion.
- *Value.* Pure black and pure white are not allowed. The body of an effect stays in mid values, and the highest spike is reserved for the instant flash at impact.
- *Saturation by layer.* The environment has the lowest saturation, UI is controlled, and VFX gets the widest and highest range so it cuts through.
- *Complementary colour pairs* follow a strict dominant-to-submissive ratio. The accent hue is desaturated and kept to small highlights.
- *Shape.* Shapes are hand-painted, mixing hard and soft edges, with no photo textures or noisy procedural detail. Stacked alpha layers are limited because they turn teamfight silhouettes to mush.
- *Missile focus.* The brightest, highest-contrast part sits at the leading tip, with bright values next to dark ones at the front. Riot's Illaoi post says the tip of Test of Spirit should draw the eye because that is the part enemies must avoid (snippet).
- *Timing.* A quick wind-up comes first, peak value and saturation arrive within the first 25% of the lifetime, and the effect then erodes smoothly. Lingering transparent particles are called out as a source of overdraw on low-spec PCs.

**Concrete numbers from a League-style craft breakdown (80.lv):** the hit flash lasts about 0.1 s. Decay order is main glow, then lens flare, then sparks, with bokeh dots last. Sparks outlive the projectile trail. Alpha over life follows 0, then 0.5, then 0. Textures are mostly greyscale so colour comes from the particle colour ramp. The projectile's hot point must match the collision box exactly. A darkened base under the glow increases the usable brightness range.

**Team practice.** The VFX-update programme started as one artist's personal project on Veigar's cage. It changes only VFX, which lets it ship faster than full visual updates. The process runs: choose a champion, build the base with sound and design, update skins to match, test, run on the PBE, then ship. Skin tiers set how much new VFX a skin gets: 750 RP gets at most one tweak, 975 RP a recolour, 1350 RP fully new VFX, and 1820+ RP new VFX plus emote VFX. Any indicator resize on the base must be copied to every skin. Feedback is only acted on when it is actionable, objective and mostly unanimous.

**Valorant.** VFX is not scaled by quality tier at all. Only small cosmetic details change, so every player sees the same gameplay information. Vision-blocking smoke uses a hard geometric edge to avoid translucency-sorting leaks, and Omen's smoke is a hard sphere with optional wisps. Sova's ultimate changed from large translucent cylinders to a thin opaque outline. The frame budget is 6.9 ms (a 144 fps target) on 2012-era integrated graphics. Character shaders get a red rim (fresnel) on enemies and a neutral blue one on allies, brighter at distance with a clamp. Third-party testers record framerates for each ability on low- and medium-spec PCs.

**Arcane-style effects.** The show drew explosions, smoke and fire as 2D elements over its painterly look (snippet). In League, painted flipbooks and the style guide's "hand-painted, no photo textures" rule produce the same graphic feel (analysis). An Arcade-skin breakdown deliberately uses *fewer* flipbook frames to look retro (snippet). Low frame counts are a style choice, not only a budget choice.

**What transfers.** Write a one-page style guide with ranked goals. Use the 25%-peak envelope. Keep pure black and white out. Make the collision point the brightest pixel. Hold VFX at the same quality across settings when it carries gameplay information.

### Blizzard (Overwatch, Diablo IV)

**Overwatch.** Senior VFX artist Rachel Day describes a stylized, hand-painted, fairly basic effects system. Its value is that it lets artists convey a feeling rather than match physics. Her working habits: build in close back-and-forth with designers and gameplay engineers (designers set projectile speed, she shows how it looks in motion), push each effect to the extreme and then pull it back, and test around 20 assets at once when building a system. She stresses animation timing as the core skill. Hanzo's dragon portal, made of two map-sized dragons, was mainly a problem of making something huge cheap enough. 80.lv's technical overview notes the comic-book explosions and muzzle flashes are strong but controlled, so they don't wash out the action. Blizzard's Hadidjah Chamberlin co-taught GDC 2017's "Artistic Principles of VFX" bootcamp with Riot's Jason Keyser (snippet). Industry fundamentals are shared across studios.

**Diablo IV (Daniel Briggs, Lead VFX Artist).**
- *Gameplay First.* Skills, telegraphs, traps, damage areas and character states must read in every biome and lighting setup. Ultimates are loud and weak skills recede.
- *From unlit to lit.* Earlier Diablo games used unlit particles, which looked too bright in dark dungeons. Diablo IV's particles are lit, so Whirlwind's blades reflect sun outdoors and torchlight underground, and its dust takes on the local light.
- *Bending PBR for readability.* The shader library can break PBR rules for gameplay elements while ambient effects stay fully physical. Emission is added so combat effects cast light in dark spaces, and some ultimates briefly change weather and lighting.
- *Payload sync.* Damage areas are animated over several frames to match the visuals. Whirlwind is an animated pie wedge that follows the character. Hit effects follow the attack direction, using animation data to find the impact point and push ragdolls.
- *Handmade scaling ranges.* When a skill grows through upgrades, artists retune spawn rate, velocity, emission and colour rather than scaling the whole effect uniformly. Weapon buffs work on any weapon and get more intense as power stacks.
- *Graphics side.* Volumetrics light the airborne dust and were described as an unplanned but key part of the dark tone. Stained glass emits light into the air. Small cross-discipline teams (engineers, tech artists, artists) own each feature.

**What transfers.** Lit particles for ambient effects, with emission to rescue gameplay effects. Hand-tuned scaling curves rather than one scale knob. Strike-team ownership.

### Naughty Dog (The Last of Us Part II)

**What the VFX must do.** Effects support grounded realism and close, intimate camera work, so they must stick to and interact with characters and the world.

**Documented techniques (SIGGRAPH 2020, Artem Kovalovs):**
- Particles moved from CPU to GPU for performance. That move made screen-space data usable for spawning and simulation.
- *Screen-space collision.* Snow collides with and sticks to characters and the environment using screen-space information rather than 3D geometry, which the article says was much cheaper.
- *Surface-living drips.* Chains of connected GPU particles crawl over moving character geometry, following gravity and surface properties. They are used for rain water and wound blood, and a drop is released when a drip reaches a set curvature.
- *Character render targets* store blood and wetness. Earlier games could only show predetermined results in those targets.
- *Much less manual placement* than earlier titles, which hand-placed emitters in the world or on joints.
- *Froxel volumetric fog.* A view-space frustum voxel grid in a 3D texture, which can exceed 5 million froxels on PS4. It takes flashlights, torches, sun and indirect light, and composites with glass and particles.
- A separate optimisation talk names alpha geometry and full-screen shaders as the costliest parts of the 30 fps PS4 frame.
- Wataru Ikeda's GDC 2021 talk covered edge ripples on water, a self-colliding "curl wave" at the beach, and depth of field on small particles (snippet).

**What transfers.** Effects that react to the surface they touch, such as drips, snow build-up and wetness masks, sell realism more than particle counts do. In Godot, GPUParticlesCollisionHeightField3D and SDF colliders cover a cheap version (analysis).

### Santa Monica Studio (God of War 2018, Ragnarök)

**Documented work.**
- *Interactive wind and vegetation* (GDC 2019, Sean Feeley). A fluid-simulated wind field carries speed and direction across a level. "Wind motors" emit wind and "wind receivers" respond. The talk also covers mesh data processed in compute, wind LODs, character collision through foliage, and authoring practices. The stated goals: players should see that their actions affect the wind, the wind's direction should be readable, and speed and direction should vary across space. The team wanted to move past "if wind, then wiggle" towards believable rather than realistic motion.
- Rupert Renard's GDC 2019 talks covered running the wind fluid sim efficiently on GPU, and a high-quality particle-emission technique for dissolving corpses off screen (snippet).
- *Ragnarök snow.* GPU-driven VFX cards and models bounce off displaced snow geometry through GPU collision (snippet). Niflheim ice was modelled procedurally in Houdini with ZBrush and Substance.
- *VFX as a game-design language* (Game Developer analysis): a non-diegetic growing yellow ring shows parry timing on any enemy. Status effects are separated by hue and accent (Hex is magenta with black, Bifrost is indigo with rainbow chromatic accents). Atreus's shield is tuned to read in every arena. Fast-travel door particles grow at distance and shrink up close. Sluice steam tells you whether water is flowing even when you can't see it.

**What transfers.** Non-diegetic telegraphs can be consistent across every enemy. Distance-scaled particles work as wayfinding. Wind is built from emitters and receivers.

### Sucker Punch (inFAMOUS Second Son, Ghost of Tsushima)

**inFAMOUS Second Son (Matt Vainio, fxguide; Bill Rockenbeck, GDC 2014).**
- The particle system is an in-engine, real-time editor using *text expressions* compiled to PS4 compute shaders. Expressions were chosen over a node UI because nodes limited artists, while with expressions "everything's exposed". Rockenbeck's talk covered curl noise, animated meshes and parent/child systems (snippet).
- *Smoke* uses multiple octaves of curl noise confined to spheres and cylinders for a crunchy look. It stays attached to the hero through tendrils. Embers lead and smoke trails behind them, and ash and embers at the head give the smoke weight.
- *Neon* uses single-octave curl noise for smoother motion. Particles spawn from sign textures wherever emissive pixels pass a brightness threshold and inherit that colour. The sign's emission, reflections and lights switch off at the same instant, so the handoff reads.
- *Lighting.* A few large lights beat thousands of tiny ones, so only some particles emit light. Particles are PBR and energy-conserving, cast and receive shadows, and blend with haze.
- *Emission from animation.* Joints are turned into splines used as emit and target references, because five or six blended animation clips make the motion unpredictable. A low-res hero mesh acts as a "particle mesh" emitter.
- *Ribbons* stream their UVs and can twist their faces.

**Ghost of Tsushima (PlayStation Blog by Vainio; Game Developer on Rockenbeck's GDC 2021 talk).**
- Two VFX artists covered most of development, with a world much larger than Second Son's, dynamic weather and a 24-hour cycle.
- The art direction rule was that everything needed to move.
- Particles read global wind, player-generated wind, character displacement, terrain, water, wetness and time of day. A conditional event system changes behaviour when a threshold is crossed.
- *Vorticles* are invisible particles that output position, orientation, radius and a direction vector. They are appended to one small global array, and any emitter can opt in and sum their influence through a brute-force loop over hundreds of them. They drive swirling leaves around campfires, candles snuffed by sword swings, and animals scattered by arrows.
- *Wind* prioritises volume over accuracy, with no fluid dynamics. One authored vector has its strength modulated by time-varying Perlin noise, and emitters add curl noise. The guiding wind is simply a vector from the hero to the objective, and players do their own pathfinding.
- *Terrain* is a tiled, multi-resolution height map. Particles sample it several steps ahead and get an upward push so they float over hills rather than hugging them.
- *Biome map.* One camera-following system reads a real-time biome map, shared with lighting, and replaced hundreds of placed emitters. Noise softens the biome edges.
- *Scale.* Tens of thousands of leaves can be on screen, each a disc that tumbles from torque when it lands. Some scenes reach about 60,000 leaf particles (snippet).
- *Bug fix as design.* Leaves landing unburnt in campfires were fixed with an upward wind emitter inside every fire.
- *Debug views* include a green and red grass-displacement trail and crabs that change colour by movement state.

**What transfers.** One global wind uniform. Opt-in local wind sources, which Godot's GPUParticlesAttractor3D approximates. Height-field collision. Camera-following ambient systems instead of hand-placed emitters. Debug colouring.

### Insomniac (Marvel's Spider-Man)

Public detail is thin. What I found:
- Associate VFX artist Jenna Ruth splits the work into *cinematic* effects (spectacle meant to pass as a pre-rendered Marvel film) and *gameplay* effects (information that has to survive open-world scale, ground clutter, combat and fast traversal). She worked on most suit powers from the concept stage. She cites Joseph Gilland's *Elemental Magic* for thinking about forces acting on matter. From earlier VR work she learned to balance the number of focal points against how flashy each one is.
- Houdini was used for a first pass when building the game and to generate road, alley, terrain and building sets procedurally (snippet).
- Senior tech artist Xray Halperin's talk "Ten Years of Tech Art for Marvel's Spider-Man" covers procedural tech art across the series (snippet).
- On Rift Apart, debris breaks into pieces that persist or fly based on the weapon used (snippet).

**What transfers.** Write a separate brief for cinematic and gameplay effects. Use procedural generation for volume work, so artists spend their time on hero effects.

### Bungie (Destiny, Destiny 2)

**Tech (SIGGRAPH 2017, Brandon Whitley, via 80.lv).** Particle systems are node graphs in which every parameter is an *expression*. An expression-to-HLSL converter and a bytecode interpreter run the same graph on CPU or GPU with sub-second iteration. "Motion primitives" (spheres, points, planes) steer particles. The goal was to cover the whole range of Destiny's "space magic" with fast iteration and good performance.

**Production habits (Mike Stavrides, 80.lv):**
- Players must instantly tell what is dangerous, what is on a timer, and what marks a capture or deny zone. If an effect hurts gameplay, change the effect, and playtest to see what players actually read.
- *Complexity from simple layers.* Particles, mesh shaders, a dynamic light, post-process, camera shake and controller rumble are stacked. A little camera shake makes an effect feel bigger.
- *Hiding source textures.* Remix a shared library of about 512×512 textures. Multiply two textures against themselves at different tile rates and pan speeds, use depth-buffer intersection for hot contact lines, add Fresnel for soft edges, and use vertex colour as a free mask.
- *Gambit Mote.* An opaque inverted-normal shell uses a palette lookup that scrolls a greyscale triangle texture, so facets light up in turn. One normal map is reused three times and its green channel doubles as a mask.
- *Raid orb.* The warm-up uses cards and mesh particles. The impact adds a dynamic light, radial bloom, camera shake and rumble. The idle state uses crossed quads plus a cylinder. A decal sits at the base. Existing effects were retuned rather than rebuilt.
- *Priorities.* P1 is essential to the look, P2 is flavor and P3 is environment, and the lowest priorities are culled first under load. Effects fade near the camera with no popping. Quarter-resolution buffers (1/16 the pixel cost) hold full-screen dust and volume fill.
- *Teams.* Work is split across Systems, Scenario and Vanguard groups (snippet). Modular FX kits are reused across the game.

**What transfers.** Priority tiers, mesh shaders over particle spam, a shared texture library at 512², the depth-fade contact line and camera shake.

### FromSoftware (Elden Ring)

Source: CGWORLD vol. 286, an interview with lead VFX/UI artist Hirokazu Akino.
- More than twice the effects of earlier FromSoftware titles: spells, weapon skills, environment, items, buffs and debuffs, and blood.
- *Tools.* An in-house FX Editor, chosen because it is light, predictable and quick to iterate on console. A Time Act Editor syncs effect timing to animation, and MovieSequencer handles cutscenes. Source assets come from 3ds Max, Photoshop and After Effects, FumeFX for fluids, and Trapcode Particular and Optical Flares.
- *Art direction.* The director asked for no over-flashy effects, so bright primaries were avoided and boss effects were desaturated.
- *Order of work.* Animators finish the spell motion first, then effects and sound are added.
- *Stone Pellet.* It started blue, changed to green so it would not look too powerful, then gained a dark core and meteor-like particles for a "universe" feel. Comet Azur builds on the same motif.
- *Godrick's flame breath.* The flame's volume was cut while the hitbox stayed the same, which improved both visibility and frame cost.
- *Weapon skills* attach to dummy polygons on each weapon type and scale with weapon size.
- *Weather splashes* use raycasts to spawn secondary hits, and an occlusion system stops rain indoors. Map fog moved mostly into post-processing.
- *Sites of Grace* got particle trails after playtesters struggled to find them from a distance.
- *Optimisation.* Reduced buffers and per-effect LOD rather than lower overall quality. Landmarks keep a long draw distance, and distant effects lose glow and point lights.
- *Rendering choices.* Effects render *after TAA* to keep fine sparks and lightning crisp. An inverse-exposure coefficient (0 to 1) cancels auto-exposure on light sources so torches stay equally bright indoors and out. Glow is set per emitter. Translucent blending is preferred over additive because it costs more but avoids blowout.

**What transfers.** This is the most relevant studio for a dark, restrained game (analysis). Use desaturated palettes, translucent rather than additive blending, per-emitter glow, exposure-stable light sources, and particle trails as subtle wayfinding.

### Epic (Fortnite and Niagara)

- Fortnite is Epic's sandbox for Niagara: the studio "dog foods" its own tools (snippet, from Scott Kennedy's Epic tech blog, which returned 403 here). An FX technical artist (Andrew Melnychuk) supports the FX team by writing modules and complex math (snippet). The pattern is one tech artist building reusable modules for several content artists.
- *Effect Types* set scalability once and apply it to many systems. Budget scaling culls systems when global usage passes a threshold, can reduce max distance and instance counts, and at very high usage renders only nearby systems (snippet, Epic docs).
- In UEFN, built-in Fortnite effects are locked, and creators make their own in Niagara (snippet).

**What transfers.** Central "effect type" presets for budget and LOD, rather than per-effect tuning. A tool-builder role, even part-time, writing shared shader functions and particle-shader includes (analysis).

### miHoYo / HoYoverse (Genshin Impact)

Public material is mostly rendering-side. Genshin runs on a heavily customised Unity with separate console and mobile pipelines and a PBR-based stylised look (snippet, Unite talk by Zhenzhong Yi). Characters are forward-shaded for full control of their lighting while the world is deferred (snippet). A Japanese VFX artist's frame study of Citlali's star particles gives craft detail:
- Lifetime random range of about 2×, so fades are staggered.
- Hand-tuned ease-in and ease-out scale curves: slow growth, then a quick scale up and down just before death. Not linear and not a sine wave.
- A colour gradient only on the upper half of the star, inset from the edge, with pale-blue tips.
- Likely alpha-blended rather than additive, with a pink to blue-violet to dark blue-violet glow that bloom alone can't produce, so it is probably a painted glow texture.
- Natlan's graffiti, Spider-Verse-like VFX shows how a regional art theme can extend to effects.
- Signature colour keys per element were described in secondary commentary (snippet, low reliability).

**What transfers.** Polish lives in curves and lifetime randomness, not particle counts. Paint the glow into the texture when you need a hue shift that bloom can't give.

### Remedy (Control)

- Johannes Richter (Principal VFX Artist) gave the GDC 2020 talk "Destructible Environments in Control: Lessons in Procedural Destruction", built around a Houdini procedural workflow.
- Destruction is layered in three tiers (snippet, CGWORLD report). Large debris and props are rigid bodies. Small fragments mix particles, rigid-body hierarchies and decals. Sparks, fire and dust are flipbook billboards or particles.
- Northlight decides which events and particles react, and NVIDIA's physics engine simulates the rigid bodies (snippet).
- Environment artists build the static stage, and the VFX team rigs it for destruction and authors cinematic breakup animations in Houdini before importing to Northlight (snippet).

**What transfers.** Destruction works as a layered effect: a few real rigid bodies, many cheap particles and decals, and flipbook dust to cover the seams (analysis).

---

## 3. Examples (what makes each one work)

| Effect | Why it works |
|---|---|
| LoL Illaoi Test of Spirit | The brightest, sharpest pixel is the missile tip, which is exactly the part to dodge. |
| Valorant Omen smoke | A hard opaque sphere has no sort leaks, and gameplay is identical on every setting. Wisps are only cosmetic. |
| Valorant Sova ult | Big translucent cylinders were swapped for a thin opaque outline: less overdraw and a clearer read. |
| Diablo IV Whirlwind | Lit blades and dust reflect local light, and the payload is an animated pie wedge that follows the visual. |
| GoT windicator | One vector to the objective replaces a UI marker, and the world itself guides the player. |
| GoT campfire leaves | Vorticles swirl leaves, an upward wind emitter keeps them out of the fire, and it all reads as physical. |
| inFAMOUS neon drain | Particles spawn from emissive pixels and the sign goes dark at the same instant, so the handoff is unmistakable. |
| TLOU2 drips | GPU particle chains crawl over animated characters and release at a curvature threshold. |
| GoW Ragnarök parry ring | A non-diegetic yellow ring gives the same timing language on every enemy. |
| Destiny Gambit Mote | A mesh-shader shell with a palette scroll keeps it out of particle budgets, so it can't be culled. |
| Elden Ring Godrick breath | Less flame volume with the same hitbox improves both readability and performance. |
| Elden Ring Site of Grace | Particle trails act as a quiet beacon for the player, added after playtest feedback. |
| Genshin Citlali stars | Staggered lifetimes and eased scale curves give a twinkling rhythm from few particles. |

---

## 4. Common mistakes (the studios' own lessons)

1. **Linear lifetime curves.** Riot calls them harmful, and Genshin's polish comes entirely from eased curves.
2. **Visual weight that doesn't match gameplay weight.** Elden Ring's blue Stone Pellet looked too strong, and Riot reserves loudness for high-impact spells.
3. **Lingering translucent layers.** They cause overdraw (Riot, Naughty Dog's alpha-geometry cost) and hide enemy silhouettes. End dissipation promptly.
4. **Unlit effects in dark spaces.** Diablo III-style unlit particles glowed wrongly in dungeons. Light the ambient effects and use emission on gameplay effects.
5. **Hand-placing ambient emitters across a big world.** Ghost of Tsushima's growth-placed emitters left gaps, and fixes broke other forests. One camera-following, data-driven system replaced them.
6. **Scaling a whole effect with one knob.** Diablo IV retunes spawn rate, velocity, emission and colour per size range.
7. **Letting graphics settings change gameplay information.** Valorant keeps VFX identical across tiers.
8. **Additive everything.** It blows out detail under bloom. Elden Ring prefers translucent blending, and Riot keeps pure white out.
9. **Rebuilding instead of retuning.** Bungie reuses modular kits and retunes existing effects.
10. **Acting on loud but unactionable feedback.** Riot filters feedback for being actionable, objective and mostly unanimous.
11. **Particles that ignore the world** (no shadows, no haze, no collision). Sucker Punch and Naughty Dog both say this makes effects look composited on.

---

## 5. Apply in Godot 4 (4.7, Forward+, AgX, glow on)

### 5.1 A one-page VFX style guide for *Unsent* (Riot and FromSoftware model)
Ranked goals: (1) the narrative beat must read, (2) no clutter, (3) the melancholy theme, (4) quiet delight. Rules: no pure white cores (cap emission so AgX doesn't clip to white), translucent before additive, desaturated accents, one dominant hue per effect (ember orange) with a desaturated complement (cold blue-grey smoke).

### 5.2 Riot envelope in a billboard spatial shader
With `ParticleProcessMaterial`, `INSTANCE_CUSTOM.y` holds the particle's normalised age.
```glsl
shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_never, cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(1.0, 0.55, 0.2);
uniform float peak_emission = 3.0; // keep under AgX white-clip
uniform float peak_at = 0.22;      // peak inside first 25% of life

float envelope(float t) {
    float rise = smoothstep(0.0, peak_at, t);           // fast anticipation/pop
    float fall = 1.0 - smoothstep(peak_at, 1.0, t);     // smooth erosion
    return rise * fall * fall;                          // non-linear tail
}
void fragment() {
    float t = INSTANCE_CUSTOM.y;
    vec4 s = texture(tex, UV);
    float e = envelope(t);
    // erosion: raise alpha threshold over life (dissolve, not just fade)
    float a = smoothstep(t * 0.8, t * 0.8 + 0.15, s.r) * e;
    ALBEDO = tint * mix(1.0, peak_emission, e);
    ALPHA = a * COLOR.a;
}
```
Turn on billboard mode in the material, or use `ParticleProcessMaterial` with `particle_flag_align_y` as needed. Keep the textures greyscale so colour comes from `tint` or the colour ramp (Riot practice).

### 5.3 Ghost of Tsushima global wind in Godot
1. In Project Settings > Shader Globals, add `wind_dir` (vec3) and `wind_strength` (float).
2. Drive them from one autoload: `RenderingServer.global_shader_parameter_set("wind_strength", base + noise.get_noise_1d(t) * gust)`.
3. Read the same globals in the foliage vertex shaders, the cloth or hair shaders, and the custom `shader_type particles` leaf shader:
```glsl
shader_type particles;
global uniform vec3 wind_dir;
global uniform float wind_strength;
uniform float drag = 1.5;
void process() {
    vec3 wind = normalize(wind_dir) * wind_strength;
    // cheap curl-ish swirl: offset by position-based sin noise
    vec3 p = TRANSFORM[3].xyz;
    wind += 0.3 * wind_strength * vec3(sin(p.z * 1.7 + TIME), 0.0, cos(p.x * 1.3 + TIME));
    VELOCITY += (wind - VELOCITY) * drag * DELTA;
}
```
4. For local "vorticles", add `GPUParticlesAttractor3D` nodes (sphere or vector-field) with `cull_mask` set so only the opted-in emitters react, such as leaves around a burning letter. Use a negative `strength` for push, positive for pull, and `directionality` near 1.0 for a gust.
5. For terrain, use `GPUParticlesCollisionHeightField3D` around the camera (`follow_camera_enabled = true`, resolution 512–1024, `update_mode = WHEN_MOVED`), the equivalent of GoT's height-map snapping.

### 5.4 Destiny-style priority tiers
Group effects in Godot as `vfx_p1`, `vfx_p2` and `vfx_p3`. A budget manager scales the tiers:
```gdscript
func apply_budget(load: float) -> void: # 0..1 from Performance.get_monitor(Performance.TIME_PROCESS) etc.
    for p in get_tree().get_nodes_in_group("vfx_p3"):
        p.amount_ratio = clamp(1.0 - load * 2.0, 0.0, 1.0)
    for p in get_tree().get_nodes_in_group("vfx_p2"):
        p.amount_ratio = clamp(1.5 - load * 1.5, 0.25, 1.0)
    # p1 never scaled (gameplay/story-critical)
```
Also set `visibility_range_end` and `visibility_range_end_margin` (fade mode `SELF`) on GeometryInstance3D emitters. This matches Elden Ring and Destiny: fade out at distance, drop the glow and the light first, and keep landmarks longer.

### 5.5 Mesh shaders rather than particle spam (Destiny, Riot "95% one mesh")
For portals, auras and shockwaves, use a `MeshInstance3D` (cylinder, crossed quads, inverted sphere) with a scrolling-UV shader. Multiply two noise samples at different tile and pan rates (Destiny's mask trick), and use `DEPTH_TEXTURE` for a soft contact line:
```glsl
uniform sampler2D depth_tex : hint_depth_texture;
// in fragment():
float scene_z = texture(depth_tex, SCREEN_UV).r;
vec4 ndc = vec4(SCREEN_UV * 2.0 - 1.0, scene_z, 1.0);
vec4 view = INV_PROJECTION_MATRIX * ndc; view.xyz /= view.w;
float dist = VERTEX.z - view.z;                 // both negative in view space
float contact = 1.0 - clamp(abs(dist) / 0.15, 0.0, 1.0);
EMISSION += hot_color * contact * 2.0;          // "hot intersection line"
```

### 5.6 FromSoftware-style restraint under AgX and glow
- Prefer `blend_mix` with emission over `blend_add`, so detail survives the glow.
- Set glow per effect with emission strength instead of raising `glow_intensity` globally. Keep `glow_hdr_threshold` around 1.0–1.5 so only true highlights bloom.
- For exposure-stable light sources (an inverse-exposure-like trick), if you use auto-exposure (`CameraAttributesPractical.auto_exposure_enabled`), clamp `auto_exposure_min_sensitivity` and `max_sensitivity` tightly in interiors, or multiply candle emission by a script-set uniform tied to the current exposure.
- Godot doesn't let you render effects after TAA. If tiny sparks smear, use FXAA or SMAA with no TAA, or make sparks larger and with longer trails (analysis).

### 5.7 Lit particles (Diablo IV and Sucker Punch)
Smoke from the burning letters should use a lit material (`shading_mode = per-vertex` or per-pixel), not `unshaded`, so it takes on room light and sits in the volumetric fog (`Environment.volumetric_fog_enabled`, with `GPUParticles3D` smoke that fades with distance). Keep the flame core unshaded and emissive. That mirrors Diablo IV's split of physical ambient and emissive gameplay. Add one `OmniLight3D` per fire cluster rather than one per particle (Sucker Punch's "few big lights"), and flicker its energy with noise in sync with the flame's envelope.

### 5.8 Team habits for a small team
- Write ranked goals and test changes against them (Riot).
- Build animation first, then VFX and audio together (FromSoftware). In Godot, key emitter `emitting` and the envelope uniforms on an `AnimationPlayer` track next to the animation, the equivalent of a Time Act Editor.
- Push each effect to the extreme, then dial it back. Review about 20 variants side by side (Overwatch).
- Make debug views that colour particles by state (GoT).
- Keep a shared library of greyscale noise, mask and flipbook textures at 512², and remix it instead of authoring new textures (Destiny, Riot).
- Retune existing effects before rebuilding them (Bungie).

---

## 6. Sources

1. Riot Games, "Dev: League's VFX Style Guide": https://nexus.leagueoflegends.com/en-us/2017/10/dev-leagues-vfx-style-guide/
2. Riot Games, LoL VFX Style Guide (PDF): https://nexus.leagueoflegends.com/wp-content/uploads/2017/10/VFX_Styleguide_final_public_hidpjqwx7lqyx0pjj3ss.pdf
3. VFX Apprentice, "10 Design Tips from the League of Legends VFX Style Guide": https://www.vfxapprentice.com/blog/10-league-of-legends-vfx-design-tips
4. League of Legends, "Dev: Behind the Scenes of VFX Updates": https://www.leagueoflegends.com/en-us/news/dev/dev-behind-the-scenes-of-vfx-updates/
5. Riot Games, "Resistance Illaoi: the final update" (snippet): https://nexus.leagueoflegends.com/en-us/2018/02/resistance-illaoi-the-final-update/
6. Riot Games, "VALORANT Shaders and Gameplay Clarity": https://www.riotgames.com/en/news/valorant-shaders-and-gameplay-clarity
7. 80.lv, "Constructing VFX Worthy of League of Legends": https://80.lv/articles/constructing-vfx-worthy-of-league-of-legends/
8. 80.lv, "Reinventing Arrow VFX from League of Legends" (snippet): https://80.lv/articles/reinventing-arrow-vfx-from-league-of-legends
9. VFX Voice, "Riot Games and Fortiche get revolutionary with Arcane Season 2" (snippet): https://vfxvoice.com/riot-games-and-fortiche-get-revolutionary-with-arcane-season-2/
10. GDC Vault, "Visual Effects Bootcamp: Artistic Principles of VFX" (Chamberlin, Keyser) (snippet): https://www.gdcvault.com/play/1024439/Visual-Effects-Bootcamp-Artistic-Principles
11. VFX Voice, profile of Rachel Day (Overwatch): https://vfxvoice.com/?p=624080
12. 80.lv, "Overwatch Technical Overview": https://80.lv/articles/overwatch-technical-overview
13. Blizzard, Diablo IV Quarterly Update, December 2021 (VFX by Daniel Briggs): https://news.blizzard.com/en-us/diablo4/23746639
14. Blizzard, "Peeling Back the Varnish: The Graphics of Diablo IV": https://news.blizzard.com/en-gb/article/23964183/iv
15. Naughty Dog, "Naughty Dog at SIGGRAPH 2020": https://www.naughtydog.com/blog/naughty_dog_at_siggraph_2020
16. ACM SIGGRAPH Blog, Q&A with Artem Kovalovs (TLOU2 GPU effects): https://blog.siggraph.org/?p=11909
17. GDC Vault, "Creative and Experimental VFX in The Last of Us Part II" (Ikeda) (snippet): https://www.gdcvault.com/play/1027072/contactUs
18. 80.lv, "Santa Monica Studio showed how interactive wind and vegetation were made for God of War": https://80.lv/articles/santa-monica-studio-showed-how-interactive-wind-and-vegetation-were-made-for-god-of-war
19. Game Developer, "GDC 2019 God of War talks" (Renard) (snippet): https://www.gamedeveloper.com/audio/-boy-does-gdc-2019-offer-more-great-i-god-of-war-i-talks-than-you-can-shake-an-axe-at-
20. 80.lv, "Santa Monica's senior programmer on how God of War Ragnarök's snow system was made" (snippet): https://80.lv/articles/santa-monica-s-senior-programmer-on-how-god-of-war-ragnar-k-s-snow-system-was-made
21. 80.lv, "A Look at God of War Ragnarök's Snow and Ice": https://80.lv/articles/a-look-at-god-of-war-ragnar-k-s-snow-and-ice
22. Game Developer, "VFX as game design tools: the ludology of VFX in God of War Ragnarök and Halo Infinite": https://gamedeveloper.com/design/vfx-as-game-design-tools-the-ludology-of-vfx-in-god-of-war-ragnarok-and-halo-infinite
23. fxguide, "Art directing effects for inFAMOUS: Second Son": https://www.fxguide.com/fxfeatured/art-directing-effects-for-infamous-second-son/
24. GDC Vault, "The inFAMOUS: Second Son Particle System Architecture" (snippet): https://gdcvault.com/play/1020367/contactUs
25. Game Developer, "inFAMOUS: Second Son particle system explained at GDC 2014": https://www.gamedeveloper.com/programming/-i-infamous-second-son-i-particle-system-explained-at-gdc-2014
26. PlayStation Blog, "How stunning visual effects bring Ghost of Tsushima to life": https://blog.playstation.com/?p=345372
27. 80.lv, "Insights into Building VFX for Ghost of Tsushima": https://80.lv/articles/insights-into-building-vfx-for-ghost-of-tsushima/
28. Game Developer, "Using vorticles to simulate wind in Ghost of Tsushima": https://gamedeveloper.com/design/using-vorticles-to-simulate-wind-in-i-ghost-of-tsushima-i-
29. GDC Vault, "Blowing from the West: Simulating Wind in Ghost of Tsushima" (snippet): https://gdcvault.com/play/1027350/Blowing-from-the-West-Simulating
30. VFX Voice, "Jenna Ruth: raising the creative VFX level in Marvel's Spider-Man": https://vfxvoice.com/jenna-ruth-raising-the-creative-vfx-level-in-marvels-spider-man/
31. The Ringer, "Marvel's Spider-Man swing success" (snippet): https://www.theringer.com/2018/09/24/video-games/marvels-spider-man-swing-success
32. Vimeo, "Ten Years of Tech Art for Marvel's Spider-Man", Xray Halperin (snippet): https://vimeo.com/982767414
33. Chaos CG Garage, Craig "Xray" Halperin, Insomniac: https://www.chaos.com/cg-garage/craig-xray-halperin-insomniac-games
34. MobileSyrup, interview with Mike Fitzgerald on Rift Apart (snippet): https://mobilesyrup.com/2021/05/12/insomniac-core-tech-director-mike-fitzgerald-ratchet-and-clank-rift-apart-ps5-interview/
35. 80.lv, "SIGGRAPH: The Destiny Particle Architecture": https://80.lv/articles/siggraph-the-destiny-particle-architecture/
36. 80.lv, "Destiny 2 VFX Production Tips": https://80.lv/articles/destiny-2-vfx-production-tips/
37. ArtStation Magazine, "A Day on the Destiny 2 VFX Team" (snippet, 403 on fetch): https://magazine.artstation.com/2023/08/a-day-on-the-destiny-2-vfx-team/
38. GDC Vault, "The Visual Effects Technology of Destiny" (snippet): https://gdcvault.com/play/1025282/contactUs
39. CGWORLD vol. 286, Elden Ring effects feature (Japanese): https://cgworld.jp/article/202206-cgw286-eldenring03.html
40. Game Watch Impress, CEDEC 2022 Elden Ring atmosphere session (snippet): https://game.watch.impress.co.jp/docs/kikaku/1434499.html
41. Epic Games, "How Epic is integrating Niagara into Fortnite" (snippet, 403 on fetch): https://www.unrealengine.com/tech-blog/how-epic-is-integrating-niagara-into-fortnite
42. Epic docs, "Performance Budgeting Using Effect Types in Niagara" (snippet): https://dev.epicgames.com/documentation/unreal-engine/performance-budgeting-using-effect-types-in-niagara-for-unreal-engine
43. Epic docs, "Effects and particle systems in UEFN" (snippet): https://dev.epicgames.com/documentation/en-us/uefn/effects-and-particle-systems-in-unreal-editor-for-fortnite
44. Unity Japan, Unite slides "From Mobile to Console" by Zhenzhong Yi, miHoYo (snippet): https://www.docswell.com/s/UnityJapan/KWRPQ5-210617-unity-dojo20211mihoyozhenzhongyi
45. Zenn (kurie), Genshin Impact VFX frame study (Japanese): https://zenn.dev/kurie/articles/c06bdd7728db12
46. VANAS, "The incredible visuals of Genshin Impact" (snippet, low reliability): https://www.vanas.ca/en/blog/the-incredible-visuals-of-genshin-impact
47. 80.lv, "GDC Talk: Destructible Environments in Control": https://80.lv/articles/gdc-talk-destructible-environments-in-control
48. GDC Vault, "Destructible Environments in Control: Lessons in Procedural Destruction" (snippet): https://gdcvault.com/play/1030643/Destructible-Environments-in-Control-Lessons
49. CGWORLD, "Modern destruction in CONTROL: GDC Summer report (2)" (snippet; page body not retrievable): https://cgworld.jp/feature/202008-gdccontrol-2.html
50. JangaFX, EmberGen (snippet, tool context): https://jangafx.com/software/embergen
