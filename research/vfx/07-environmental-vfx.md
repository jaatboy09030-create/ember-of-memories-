# 07 — Environmental and Ambient VFX

Topics: fire, smoke, embers, sparks, torches and campfires; snow, rain, splashes, wind and leaves; fog and mist cards; waterfalls and foam; dust motes, fireflies and moths; lightning; magic ambience (portals, auras, runes); destruction debris; baking pipelines vs real-time; light flicker. Extra depth on **fire, embers, smoke, snow and fireflies/moths** for a cozy-melancholy snowy night.

---

## 1. Key takeaways

1. **One global wind drives everything.** Ghost of Tsushima gives grass, leaves, smoke, sparks, fire, cloth and ropes the same wind vector, and adds local "vorticles", invisible spheres of wind that particles sample [1][2]. If the smoke leans one way and the snow drifts another, the scene feels fake (analysis).
2. **Ambient VFX should be a system, not hand-placed props.** Sucker Punch replaced hundreds of hand-placed particle systems per location with one biome system that follows the camera [1]. Snow, dust, fireflies and ash should all be emitters that follow the camera, with their density set by data.
3. **Fire is a stack of layers, not one effect.** A typical campfire has a flame body, a hot core, embers, smoke, heat distortion, a glowing wood bed, fake moving shadows and lights. One UE4 campfire uses 14 emitters across 6 shader types [3].
4. **Colour fire with a ramp, not a texture.** Bake or paint fire in greyscale (density, emission or temperature), then map it through a blackbody gradient at runtime. This lets one asset be a campfire, a candle or a magic flame [4].
5. **A flipbook's resolution is split across its frames.** A 2048² sheet in an 8×8 grid gives 256 px per frame. Motion-vector blending halves the frames you need, so each frame gets about twice the resolution [4][5].
6. **The light sells the fire more than the sprite does.** Flicker the intensity with layered noise or a Quake-style string. Valve's lightstyles run at 10 Hz, where `m` is normal brightness and `a` is black [6]. Jitter the light's position by a few cm so the shadows move too (analysis).
7. **Restraint beats spectacle for mood.** Elden Ring's director limited glow, flash and primary colours [7]. Firewatch claimed less visual noise makes a stronger emotional backbone [8]. Melancholy scenes want fewer, slower, softer particles.
8. **Keep weather out of interiors.** Elden Ring uses an occlusion system for rain and snow under roofs [7]. Godot uses heightfield collision that follows the camera [9]. Rain lines can also be cut using a depth capture from a top-down orthographic camera [10].
9. **Snow should be dim and varied.** Mix flake sizes for depth, keep fall speed low (about 1 m/s), and add sway. If snow is too bright it looks like "fireflies or magic dust" (snippet) [11].
10. **Use soft particles and fade them near the camera.** Every smoke, fog or mist card needs a depth fade where it meets geometry, plus a fade near the camera. Otherwise cards show hard intersections and fill the screen with overdraw [12][13].
11. **Gameplay and readability come before realism.** Elden Ring added guiding particle trails to Sites of Grace after testers couldn't spot them. It also reduced Godrick's flame volume while keeping the same hitbox [7]. Readability beats accuracy here too: in Diablo 2, players accepted rain ripples that didn't line up with the drops [14].
12. **Render fine particles after TAA.** Elden Ring renders grace trails and lightning after TAA so they stay crisp [7]. In Godot, tiny embers and fireflies smear under TAA, so prefer FSR2 or MSAA tuning, or make sparks larger and less sub-pixel (analysis).

---

## 2. Deep dive

### 2.1 Fire: anatomy of a good flame

**Layers.** Build a fire from pieces that fit together, not one big sprite. RealtimeVFX advice is to make "smaller flame pieces that can go together" (snippet) [15]. A proven stack, from bottom to top, follows [3] plus analysis:

| Layer | Purpose | Typical settings (analysis unless cited) |
|---|---|---|
| Ember bed / glowing logs | Grounds the fire and shows the heat source | An emissive mask on the log mesh, with noise-panned flicker [3] |
| Core flames | Bright, short, fast | 3–6 particles, 0.4–0.8 s life, sitting low |
| Body flames | The silhouette | 6–12 particles, 0.8–1.4 s, rising 0.5–1 m/s with a slight turn into the wind |
| Flame tips / licks | Breakup at the top | Small, fast, short-lived (0.3 s), stretched along velocity |
| Embers | Scale, life and drift | 10–40 alive, 1.5–4 s, sine flicker [3] |
| Smoke | Mood, and shows the wind direction | 4–10 large soft cards, 4–8 s, lit by the fire |
| Heat distortion | Sells the heat at a glance | A refraction card with normal-map strength fading 1.1 → 1 [3] |
| Light(s) | The thing players actually feel | 1–2 omni lights with flicker; 2 light emitters in [3] |
| Fake shadows | Firelight dancing on the ground | A distorted dark texture projected under the fire [3] |

**Motion.** The most common critique on RealtimeVFX is that the body "never seems to rise": it shifts side to side while only the embers go up [16]. Flame bodies need upward velocity and need to accelerate as they rise. Hot gas speeds up with buoyancy, so use an ease-in velocity curve (analysis). Flipbook frames must play in sequence. Random frames read as flicker without lift [16]. Avoid a plain directional blur over flipbooks, because it fights the motion already in the frames (snippet) [15]. Spawn particles invisible and fade them in quickly to avoid popping [3].

**Shape language.** Flames are teardrop shapes with forked tips. Silhouette matters more than interior detail at game distances (analysis). Procedural flames use two noise textures scrolling at different speeds and directions, multiplied by a teardrop mask and cut off with a step or smoothstep threshold. The papaya-games stylized fire uses exactly this [17]. One UE4 campfire found that switching to a *less* noisy noise texture was what finally made the flame read as realistic [3].

**Colour.** Use a blackbody ramp. Low emission is deep red (about #3a0500). Mid emission is orange (#ff5a00). High emission is yellow (#ffc040). The core is nearly white but warm, never pure white (analysis, consistent with [4]). In HDR with AgX, push the core to an emissive multiplier of about 3–8 so glow picks it up, and keep the edges under 1.0 so they don't bloom into mush (analysis). Stylized fire benefits from hard cuts between a limited set of hues (snippet) [18]. Channel packing helps here: explosion artists pack temperature and density into separate channels so they can recolour in-engine (snippet) [19].

**Smoke from fire.** In TLOU2, campfire smoke columns are subtly tinted by the fire's colour and light (snippet) [20]. Elden Ring had the opposite problem: a night bonfire over-lit its own smoke and had to be fixed with runtime light adjustment [7]. Smoke near the flames should be warm and backlit. Higher up it should go cool, desaturated and darker than the sky behind it at night (analysis).

### 2.2 Embers and sparks

- **Size:** "only a few pixels big" (snippet) [19]. A big ember reads as a firefly or a UI dot (analysis).
- **Behaviour:** sparks from impacts burst in clumps, not in a perfect radial spray. A "leader" spark can spawn short-lived secondary sparks as it travels (snippet) [19]. Campfire embers are different. They rise on the plume, drift with the wind and turbulence, and slow down as they cool (analysis).
- **Cooling curve:** colour over life should go from white-yellow to orange to dim red, then fade out. Alpha holds steady and drops off sharply in the last 20%, which reads as "burning out" (analysis).
- **Flicker:** ember brightness follows a sine flicker [3]. Add a random phase per particle so they don't pulse together (analysis).
- **Velocity stretch:** align embers to their velocity (PSA Velocity in Cascade [3]). Stretch length should scale with speed so slow embers read as round dots (analysis).
- **Texture variety:** one artist used a separate ember emitter with a 4-image atlas chosen at random (snippet) [21].
- **Physically driven embers:** Ignitement's embers are GPU particles that sample the fire sim's velocity field, so they swirl with the flames [22]. Ghost of Tsushima gets the same effect more cheaply: an upward vorticle in every campfire, which also fixed leaves sitting unburnt beside fires [1].

### 2.3 Smoke

- Large, soft, slow cards with 4–8 s lifetimes. They should grow over life (roughly 1× → 3×) and rotate slowly (±10–20°/s), since fast spin reads as cartoonish (analysis).
- Panning cloud noise plus distortion, with a soft edge mask. This is simpler than the flame shader [3].
- **Lighting smoke:** with baked flipbooks, bake a lighting pass. The TLRB technique stores top, left, right and bottom light in the RGBA channels of a second texture. At runtime you blend them by light direction, and front and back are estimated [4]. Godot's simpler option is to leave the smoke material lit (not unshaded) with a normal map, or use a wrapped-diffuse spatial shader. Smoke can also pick up the firelight through the light's own falloff (analysis).
- **Depth fade:** soft particles (scene-depth fade) are essential [12].
- **Wind:** lean the smoke with the global wind, and add turbulence that grows with wind speed. Ghost of Tsushima increases turbulence as the wind gets stronger [1].

### 2.4 Light flicker for fire

Quake lightstyles, still used in Half-Life: Alyx, are strings sampled at **10 frames per second**. `a` is dark, `m` is normal and `z` is double brightness, and each letter step is about 1/12 of normal [6]:

- Flicker 1: `mmnmmommommnonmmonqnmmo`
- Flicker 6: `nmonqnmomnmomomno`
- Candle 3: `mmmmmaaaaammmmmaaaaaabcdefgabcdefg` [6]

These show the pattern well: mostly within ±10–20% of `m`, with occasional deeper dips. The candle strings are too harsh for cozy scenes, because their `a` blackouts read as a dying bulb (analysis).

**Recipe for natural fire light (analysis, synthesising [6][17][23]):**
- **Base layer:** slow noise at about 0.5–1 Hz, ±8% intensity. This is the fire "breathing".
- **Detail layer:** faster noise at about 6–10 Hz, ±5–10%. This is the flicker.
- **Gusts:** rare dips of -25 to -35% lasting 100–200 ms, linked to wind gusts or a log shifting.
- **Position jitter:** move the light 2–5 cm with slow noise so shadows sway. This matters more than intensity flicker.
- **Colour temperature:** shift slightly warmer when intensity dips, roughly 1700 K at the dips and 2000 K at the peaks.
- **Keep it tied to the visuals:** drive the flame sprite alpha and emission from the same noise value, so a dip in light matches a dip in flame.

Elden Ring adds an **inverse-exposure coefficient** per light. Torches use 1.0 so auto-exposure never makes them pump brighter or dimmer when moving between indoors and outdoors [7]. In Godot you get the same effect by using fixed exposure in a scene like this, or by compensating the light energy in script (analysis).

### 2.5 Baking pipelines vs real-time

| Route | Strengths | Costs | Notes |
|---|---|---|---|
| **Houdini Pyro → Labs Flipbook Textures (MDC)** | Highest control. Exports motion vectors plus lighting passes; renders through the viewport, no Mantra needed | Learning curve, sim time | Needs a pyrobakevolume node. Light rotations must be adjusted for TLRB [4][5] |
| **EmberGen** | Near-instant iteration; exports flipbook, motion vectors and TLRB natively | Default 256² per frame looks pixelated when scaled; 512² frames balloon to 8k×4k sheets [24] | v1.0.5 had a top/right channel swap bug, so check your channels [4] |
| **Blender Mantaflow** | Free; can render with an alpha channel and pack with Sequenced Bake | Slow, crash-prone on some versions; Eevee fire is less convincing than Cycles (snippet) [25] | Keep the OpenVDB cache next to the .blend [25] |
| **Pure real-time (shader noise)** | No texture memory, infinitely variable, wind-reactive | Harder to get realism, ALU cost | Best for stylized or distant fire, candles and magic [17] |
| **Real-time 2D fluid sim** | Interactive, gameplay-readable | Complex | Ignitement: 1024² density/temperature/reaction, 512² velocity, camera-following domain, fragment-shader solver [22] |

Elden Ring sourced fluids from **FumeFX**, with After Effects (Particular, Optical Flares) for elements [7].

**Flipbook rules [5][26]:**
- Use power-of-two sheet sizes, with ratios between 8:1 and 1:8.
- Crop tightly so the card doesn't spend fill rate on empty alpha, then fade the alpha near the edges.
- Remap time so the motion eases in and out.
- Looping needs a source sequence longer than the loop.
- With motion vectors, a 6×6 grid of 32 frames can replace an 11×11 grid of 121 frames [4].

Practical budgets (analysis): campfire body 2048² as 8×8 at 256 px per frame; candle flame 512² as 4×4; smoke 2048² as 8×8 with motion vectors, or 1024² as 4×4 with noise distortion.

### 2.6 Snow

**Falling snow (analysis plus [11][27]):**
- Real snowflakes fall at about 0.5–1.5 m/s (physics knowledge, analysis). Unity's tutorial starts snow at speed about 1 and rain at about 10 (snippet) [11].
- Use at least three layers for depth:
  - near: large, few, slightly blurred, faded near the camera;
  - mid: the main field;
  - far: many tiny flakes, or a scrolling screen-space or cylinder card.
- **Sway:** horizontal sine with a per-particle phase, 0.2–0.6 Hz, with an amplitude of 5–20 cm. Add wind drift on top. Spin flakes slowly, and use an angular velocity setting on the process material with particle billboards [27].
- **Brightness:** keep the albedo modest and the material lit. Snow catching a warm window should go warm (analysis). Overly bright snow reads as magic dust (snippet) [11].
- **Pre-warm** the system so a full cycle already exists when the scene starts (snippet) [11].
- Collide with terrain and keep snow out of interiors (heightfield collision that follows the camera) [9]. God of War Ragnarök shows the ideal case: snow cards collide on the GPU with displaced terrain, so they aren't limited to screen-space depth [28].
- **Ground and deformation:**
  - God of War Ragnarök moved from parallax mapping to tessellated displacement. Characters and physics objects push the snow down with capsules, and VFX writes a top-down alpha mask of trails [28].
  - RDR2's troughs are reproduced by hobbyists using a blurred top-down depth capture (snippet) [29].
- **Blowing ground snow:** low, wind-aligned streaks of spindrift that hug the ground. Use the same depth-masked scrolling noise as rain mist [10].
- Snow is also a light-catcher. A warm firelight radius in falling snow sells cozy instantly (analysis).

### 2.7 Rain, splashes, puddles

- **Streaks:** stretched lines or velocity-aligned billboards. Their lifetime is cut by an orthographic depth capture from above, so drops stop at roofs [10].
- **Splashes:**
  - Flipbook particles spawned on the ground, aligned to the surface normal, facing the camera [10].
  - Elden Ring spawns splashes with raycasts where rain hits [7].
  - Only spawn splashes near the camera (snippet) [14].
  - A Sobel filter on the depth map keeps splashes off walls and ledges [10].
- **Ripples:**
  - Use a normal texture, with two layers at offset start times.
  - Animate the strength with `1 - pow(2x - 1, 2)`.
  - Rain intensity culls a percentage of ripples [10].
- **Puddles:** use vertex colour plus height blending [10]. Tatarchuk's 2006 ATI talk remains the classic reference for rain [30].

### 2.8 Wind, leaves and grass (Ghost of Tsushima)

- **Base wind:** one authored constant direction, with its magnitude varied by time-varying Perlin noise. Particles add higher-frequency curl noise [2].
- **Vorticles:** invisible spheres with a position, radius and direction vector. They produce vortexes, gusts or outward blasts. A brute-force sum over a world list works "even up to hundreds" [2]. Sampling is opt-in per emitter [2].
- **Leaves:**
  - Discs that rotate when torque is applied on ground contact.
  - Tens of thousands on screen.
  - They float on water and sink after waterfalls.
  - In duels they part around characters using the grass-displacement data [1].
- **Terrain look-ahead:** particles sample the height map ahead of them and get upward velocity, so they float over hills [2].
- **Grass:** procedural, with blades animated individually. A secondary write-up claims about 83k blades in about 2.5 ms (snippet, unverified) [31].
- The **"windicator"** turned ambient VFX into navigation [1][32]. It's a good model for using ambient VFX to guide players without a UI.

### 2.9 Fog and mist

- **Fog cards:** large soft quads with depth fade, a camera fade, and slow UV panning in two directions. Rotate them slowly or billboard them only around the Y axis so they don't swing with the camera (analysis, [12][13]).
- **Volumetric fog:** TLOU2 uses a view-frustum voxel ("froxel") grid that has to composite correctly with glass and particles [33]. Godot 4's volumetric fog is the same family of technique.
- **Fog as colour script:** Firewatch fades distant pixels into a gradient texture indexed by depth, as a post effect. Gradients change by time of day and area [8][34]. Jane Ng credited the stylized approach with letting two or three artists build the world [8].
- **Interaction:** Ghost of Tsushima parts fog at the player's feet [1].

### 2.10 Water: waterfalls, rivers, foam

- **Waterfall:**
  - A mesh with flowing UVs and a scrolling greyscale mask that picks between water colour and foam colour, using alpha cutout. This is RiME-inspired, after Simon Trümpler's talk [35].
  - Duplicate meshes with shifted or flipped UVs add layers [35].
- **Foam:**
  - Two scrolling copies with staggered phases blended together, so the flow keeps moving without a visible reset. Flow supplies the motion and masks decide where foam appears [35].
  - Add a mist and spray particle layer at the base, plus a ripple disc [35].
- **TLOU2:** environment VFX include edge ripples on water, curling beach waves, and small particles with depth of field (snippet) [20].

### 2.11 Dust motes, fireflies, moths

- **Dust motes:**
  - Tiny, very slow, near-zero gravity, with low-strength turbulence.
  - Visible only inside light shafts. Multiply alpha by a light-volume mask, or rely on lit particles plus volumetric fog (analysis).
- **Fireflies:**
  - Use noise or turbulence for wander, and animate colour and size over life for a pulse (snippet) [36][37].
  - Unity's tutorial attaches real lights to a few particles, but warns to limit the count [36].
  - Real firefly flashes are short pulses with long dark gaps, about 0.1–0.5 s on and 1–5 s off. Use a pulse function, not a sine (analysis).
  - Keep 1–2 real lights per group at most, and fake the rest with emission plus bloom (analysis).
- **Moths around a lamp or fire:**
  - An orbit attractor (sphere attractor with small strength) plus strong high-frequency turbulence gives erratic darting.
  - Lit, non-emissive, small. They should catch the lamplight and cast nothing (analysis).
  - Flutter can come from a 2–4 frame wing flipbook at 15–25 fps with random phase, or from scaling the quad's X with `abs(sin)` (analysis).
  - Fireflies belong to summer. A snowy night should swap them for drifting embers, or ash and snow motes in the window light, to keep the same "small living lights" feeling (analysis).

### 2.12 Lightning

- **Structure:** a main trunk plus branches with fewer segments than their parent, so the recursion ends [38]. Or regenerate the noise between fixed start and end points [38].
- **Timing:**
  - Lifetime about 0.3–0.4 s [38].
  - Flash patterns built from 5–7 on/off durations of 0.01–0.25 s [38].
  - Keep one path through several flashes so the eye can read it [38].
- **World:** lights along the bolt path [38]. The sky and ambient flash is typically a brief environment-energy spike. Then a 1–3 s delay before the thunder audio, scaled by distance (analysis).

### 2.13 Magic ambience: portals, auras, runes

- **Elden Ring's restraint principle [7]:**
  - Avoid primary colours and overblown glow.
  - Use translucent (alpha) blending with a colour-scale boost rather than additive. Additive blending loses detail.
  - Glow is a per-emitter RGB+intensity filter.
- **Grace:** a golden aura with guiding trails, reworked several times for visibility [7][39].
- **Portals (analysis):**
  - Polar-coordinate UVs with radial scrolling noise.
  - A refraction or distortion ring.
  - Inward-drawn particles from a sphere attractor with negative falloff.
  - An inner "void" darker than the surroundings.
- **Glowing runes (analysis):**
  - An emissive mask with a slow travelling pulse, such as `smoothstep` on `fract(uv.x - TIME*0.2)`.
  - A faint additive halo card.
  - A few motes rising off the strokes.
- **Hogwarts Legacy:** the available sources only confirm a UE / Niagara / Houdini / EmberGen toolchain and authored weather parameters per weather type (snippet) [40][41]. Treat any specific breakdown claim with caution.

### 2.14 Destruction debris (brief)

- **Debris layers (analysis):**
  - large chunks as rigid bodies or mesh particles;
  - medium mesh particles with collision;
  - fine sprite grit;
  - a dust bloom that lingers 2–4 times longer than the chunks.
- **Clumping:** burst in clumps, not radially (snippet) [19].
- **Settling:** the lingering dust and a few late, slow falling bits sell the weight.
- **Elden Ring LOD:** near and far versions. Far versions drop glow and point lights [7].

---

## 3. Examples

- **Ghost of Tsushima:**
  - Wind as both a design pillar and a navigation tool.
  - Tens of thousands of leaves, and one biome system that follows the camera.
  - Candles snuffed by sword-swing wind, which spawns smoke wisps.
  - A two-person VFX team for most of development [1][2][32].
  - Why it works: every ambient element answers the same invisible force, so the world feels like one living system.
- **Red Dead Redemption 2:**
  - Atmosphere comes from a world cloud map plus volumetric fog. Fabien Bauer's SIGGRAPH 2019 talk covers this. Artists also hand-placed fog hotspots (snippet) [29].
  - Snow troughs stay persistent as characters move through.
  - Why it works: weather is simulated across the whole world, and VFX layers on top.
- **The Last of Us Part II:**
  - Froxel volumetric fog composited with particles [33].
  - Smoke tinted by the campfire.
  - Volumetric snow particles billowing in the air.
  - Small depth-of-field particles in the environment (snippet) [20].
  - Blood pooling in snow and water (snippet) [20].
  - GPU-driven particles were ported from CPU for performance (snippet) [20].
- **Elden Ring:**
  - The most transferable lessons on discipline [7]:
    - restrained glow;
    - translucent rather than additive blending;
    - an inverse-exposure coefficient for torches;
    - post-TAA rendering for fine effects;
    - near and far LOD;
    - weather occlusion under roofs;
    - raycast rain splashes.
- **Hogwarts Legacy:** dense ambient magic and authored weather parameters including snow (snippet) [41]. It shows how a cozy-magical tone relies on many small, slow ambient effects (analysis).
- **Journey:**
  - Mood comes from the material, not particles. The sand shading pairs diffuse contrast with glitter specular, plus anisotropic masking and sharpened mipmaps [42].
  - The lesson: sparkle and drift on a surface can be the "ambient VFX" (analysis).
- **Firewatch:**
  - Gradient-texture fog as colour script [8][34].
  - The lesson: for melancholy, one controlled atmospheric gradient does more than a hundred particles.

---

## 4. Common mistakes

1. **Fire that doesn't rise.** The body jitters sideways but never lifts, or the flipbook frames play randomly [16].
2. **A pure white or unclamped additive core** that blows out into a white blob under AgX and glow. Keep the core warm-tinted and the edges below 1.0 (analysis).
3. **A static light next to an animated flame**, or a flicker that is too fast or too deep (strobing). Real fire mostly breathes within ±10–20% [6].
4. **Different wind for different systems.** Smoke goes east and snow goes west [1][2].
5. **Weather in interiors.** Snow passing through roofs [7][9][10].
6. **Hard intersections and camera-filling cards.** Missing soft-particle and camera fades [12][13].
7. **Bright, uniform snow.** One size and one speed reads as a screensaver, or as magic dust [11].
8. **Too many real lights.** Fireflies and embers each with an OmniLight3D. Fake most of them with emission [36].
9. **Pixelated baked flipbooks.** Scaling 256-px frames up to a large on-screen fire [24]. Choose frame resolution based on screen size.
10. **Over-glow and over-saturation** killing the mood [7][8].
11. **Wasted fill rate on flipbooks.** Uncropped frames with large transparent borders [26].
12. **Sub-pixel sparks** that shimmer or vanish under TAA [7].
13. **Smoke over-lit at night** by its own fire light [7].

---

## 5. Apply in Godot 4 (4.7, Forward+, AgX, glow)

### 5.1 Global wind as a singleton

Create an autoload `Wind` that exposes `direction: Vector3` and `strength: float`, with strength driven by `FastNoiseLite` over time (Ghost of Tsushima style [2]). Each frame, push it into a global shader uniform: Project Settings → Shader Globals → `wind_vec` (vec3) and `wind_gust` (float), set with `RenderingServer.global_shader_parameter_set("wind_vec", dir * strength)`. Grass, foliage, smoke billboards, snow and the custom particle shader all read `global uniform vec3 wind_vec;`. For local gusts, such as the updraft over a campfire, add a `GPUParticlesAttractorSphere3D` with negative `strength` or a `GPUParticlesAttractorVectorField3D` (attractors need `attractor_interaction_enabled = true` on the process material) [9][27].

### 5.2 Campfire stack (complements the Vefects Stylized Fire pack)

Use the Vefects flames for the body and add these around them:

- **Embers:** `GPUParticles3D`
  - `amount` 32, `lifetime` 3.0, `preprocess` 3.0, `fixed_fps` 0 with `interpolate` on.
  - Process material:
    - `emission_shape` Sphere, radius 0.25.
    - `direction` (0,1,0), `spread` 15°, `initial_velocity` 0.6–1.4.
    - `gravity` = (0, 0.4, 0) (buoyant) + wind.
    - `damping` 0.3–0.6.
    - `turbulence_enabled` true, `turbulence_noise_strength` 1.5, `turbulence_noise_scale` 2.5, `turbulence_influence_min/max` 0.05/0.15. Use turbulence on only a few systems because of its 3D noise cost [43].
    - `color_ramp`: (1.0,0.85,0.5) → (1.0,0.45,0.1) → (0.5,0.08,0.02), with alpha ramping to 0 in the last 20%.
    - `scale_min/max` 0.6/1.2.
  - Draw pass: QuadMesh 0.02 m with a StandardMaterial3D:
    - unshaded, blend add or mix;
    - `billboard_mode` Particles;
    - `vertex_color_use_as_albedo`;
    - `emission` energy about 4.
  - Add `fog_disabled` if using additive in volumetric fog.
- **Smoke:** `GPUParticles3D`
  - `amount` 8, `lifetime` 7.
  - Velocity 0.3–0.5 up, plus wind; scale curve 1 → 3; `angle_velocity` ±15.
  - The material must be lit (not unshaded) so the fire's OmniLight tints it, as in TLOU2 [20]. Use `proximity_fade_enabled` true with distance 0.5, and `distance_fade_mode` PixelAlpha with min 0.3 / max 1.5 [12][13].
  - Albedo dark warm grey (0.18, 0.16, 0.15), alpha about 0.35.
- **Heat haze:** a camera-facing quad with a `screen_texture` refraction shader. Offset UVs by panned noise × 0.004, multiplied by a vertical soft mask.
- **Log bed:** emission texture × `0.6 + 0.4 * noise(TIME)` on the log material.
- **Light:** `OmniLight3D`
  - `light_color` (1.0, 0.55, 0.25), `light_energy` about 2.5, `omni_range` 6–8, `omni_attenuation` about 1.5.
  - `shadow_enabled` true; `light_size` 0.05 for soft shadows.
  - Use the flicker script below.

```gdscript
# fire_light.gd — attach to OmniLight3D
extends OmniLight3D
@export var base_energy := 2.5
@export var flames: Array[GeometryInstance3D] = []   # optional: sync flame emission
var _n := FastNoiseLite.new()
var _t := 0.0
var _origin: Vector3
var _dip := 0.0
func _ready() -> void:
    _n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    _n.seed = randi()
    _origin = position
func _process(dt: float) -> void:
    _t += dt
    var breath := _n.get_noise_1d(_t * 0.8 * 100.0) * 0.08      # ~0.8 Hz, ±8%
    var flick := _n.get_noise_1d(_t * 8.0 * 100.0 + 500.0) * 0.07 # ~8 Hz, ±7%
    if randf() < dt * 0.15: _dip = 0.3                          # rare gust dip
    _dip = move_toward(_dip, 0.0, dt * 2.0)                     # ~150 ms recovery
    var k := 1.0 + breath + flick - _dip
    light_energy = base_energy * k
    light_color = Color(1.0, 0.50 + 0.08 * k, 0.22 + 0.06 * k)  # warmer when dim
    position = _origin + Vector3(
        _n.get_noise_1d(_t * 150.0 + 900.0),
        _n.get_noise_1d(_t * 120.0 + 1300.0) * 0.5,
        _n.get_noise_1d(_t * 150.0 + 1700.0)) * 0.04             # ±4 cm shadow sway
    for f in flames:
        f.set_instance_shader_parameter("flicker", k)
```

(The `get_noise_1d(x * 100)` scaling assumes the default frequency of 0.01. Tune by eye.) If the camera moves between interior and exterior, use fixed exposure, or scale `base_energy` inversely with exposure, which is Elden Ring's coefficient of 1.0 [7].

### 5.3 Snow: three layers that follow the camera

- Parent the emitters to a `Node3D` that copies the camera's x/z each frame. Set `local_coords = false` so flakes stay in world space when you turn. Set `visibility_aabb` to cover the box.
- Add a `GPUParticlesCollisionHeightField3D` with `follow_camera_enabled = true` and resolution 512–1024, so flakes die on the ground and stay out of interiors [9]. Use `collision_mode` Hide On Contact for far and mid flakes, and Rigid with `collision_friction` 1 for near flakes so a few settle (analysis).
- **Mid layer:** `amount` 3000.
  - Box emission 30×1×30 m at +12 m.
  - `lifetime` 14, `preprocess` 14.
  - `gravity` (0, -0.9, 0) + wind.
  - `initial_velocity` 0.
  - `scale` 0.6–1.4 on a 0.02 m quad.
  - Albedo (0.85, 0.88, 0.95), lit, `billboard_mode` Particles, alpha from a soft-dot texture.
- **Near layer:** `amount` 150, box 6×3×6 m.
  - Larger flakes at 0.035 m.
  - `distance_fade` min 0.2 / max 0.8 so flakes never smear across the lens.
- **Far layer:** `amount` 6000 at 0.012 m, box 80×1×80 m. Alternatively, use a camera-facing cylinder card with scrolling snow textures (cheapest).
- Sway in a custom `shader_type particles` `process()`:

```glsl
// inside process(), after the default motion
float ph = float(INDEX) * 12.9898;
VELOCITY.x += sin(TIME * 2.2 + ph) * 0.25 * DELTA * 10.0;
VELOCITY.z += cos(TIME * 1.7 + ph * 1.3) * 0.25 * DELTA * 10.0;
VELOCITY.xz = mix(VELOCITY.xz, wind_vec.xz, 0.5 * DELTA);  // relax toward global wind
```

(Or convert the ParticleProcessMaterial to a ShaderMaterial and paste this into the generated `process()`.)
- Snow should be **lit**. Window light and firelight will make nearby flakes glow warm, which is the main cozy cue. Keep `glow_hdr_threshold` at or above 1.0 so ordinary snow never blooms (analysis).

### 5.4 Fireflies / moths / warm motes

- **Motes in window or fire light:** `amount` 40, sphere emission r=3, `lifetime` 10, gravity (0, 0.02, 0), turbulence strength 0.6, scale 0.008 m. The material is lit, so motes only appear where light hits them (a dust-in-light-shaft look). Volumetric fog with `volumetric_fog_enabled` makes the shafts visible.
- **Firefly blink** in the draw-pass spatial shader (with the default process material, `INSTANCE_CUSTOM` carries per-particle data: x = angle, y = normalized age):

```glsl
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, fog_disabled;
uniform vec3 glow_col : source_color = vec3(1.0, 0.85, 0.35);
uniform float energy = 6.0;
void vertex() {
    // billboard
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
        INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
    // INSTANCE_CUSTOM.x = particle angle; set angle_min/max to -180/180 in the
    // process material so it acts as a per-particle random seed
    float phase = fract(INSTANCE_CUSTOM.x * 7.31);            // per-particle random
    float t = fract(TIME * 0.35 + phase);                      // ~2.9 s period
    float pulse = smoothstep(0.0, 0.05, t) * (1.0 - smoothstep(0.05, 0.2, t)); // short flash, long dark
    float d = length(UV - 0.5) * 2.0;
    float a = pow(clamp(1.0 - d, 0.0, 1.0), 3.0);
    ALBEDO = glow_col * energy * pulse * a;
}
```

- **Moths:** a `GPUParticlesAttractorSphere3D` on the lamp (`strength` 2, `attenuation` 0.5, radius 1.2) plus turbulence strength 3, noise scale 1.0 for darting. Use a lit material. Flutter by scaling the quad's X with `abs(sin(TIME*30.0 + phase))` in `vertex()`.
- For a snowy night, prefer **rising embers and warm motes** over fireflies (analysis).

### 5.5 Fog and mist

- **Global:** in the Environment, enable `volumetric_fog_enabled` with density about 0.01–0.03, albedo slightly blue (0.8, 0.85, 0.95), and `volumetric_fog_emission` near black. Set `volumetric_fog_temporal_reprojection_enabled` to on so it stays smooth. Firelight then naturally creates a warm halo.
- **Local:** use a `FogVolume` with a `FogMaterial` (`density` 0.5, `height_falloff` 1.5, `edge_fade` 0.3, plus a 3D noise `density_texture` scrolled by script) for ground mist in hollows. Fog volumes are a Forward+ feature, so they suit this project.
- **Cheap cards:** a lit or unshaded quad with `proximity_fade` and `distance_fade` [12][13]. Use two noise UVs panning in opposite directions at 0.01–0.03 units/s, with alpha ≤ 0.25.
- **Firewatch-style colour fog:** depth fog in a full-screen quad shader that samples a `GradientTexture1D` by linearized depth [34]. Godot's regular `fog_*` handles the basic version. Add the gradient-texture version for an art-directed horizon.

### 5.6 Rain and lightning quickies

- **Rain:** the same camera-follow rig as snow.
  - Gravity -9 to -12, with velocity-aligned particles (`particle_flag_align_y` + a stretched quad).
  - Collision mode Hide On Contact, with a sub-emitter `SUB_EMITTER_COLLISION` spawning a 4–6-frame splash flipbook (`particles_anim_h_frames`) [9].
  - Ripples in the ground shader via the curve `1 - pow(2x-1, 2)` [10].
- **Lightning:**
  - Drive `Environment.background_energy_multiplier` (or a `DirectionalLight3D` energy) through a sequence such as [on 0.05, off 0.08, on 0.12, off 0.2, on 0.04] [38].
  - Spawn a branching `ImmediateMesh` bolt or a pre-made mesh for 0.3–0.4 s with emission about 20.
  - Play the thunder after a distance-based delay.

### 5.7 Performance checklist

- At most 2–3 systems with turbulence on screen [43].
- At most 2–4 shadowed OmniLights near the fire. Fireflies and embers use emission plus glow only.
- Keep `visibility_aabb` tight on local effects, and generous on camera-follow weather.
- Use `fixed_fps` 30 with `interpolate` on for distant or background systems.
- Use `draw_order` View Depth for alpha-blended smoke, and Index for additive.

---

## 6. Sources

1. PlayStation Blog — "How stunning visual effects bring Ghost of Tsushima to life" — https://blog.playstation.com/?p=345372
2. Game Developer — "Using vorticles to simulate wind in Ghost of Tsushima" — https://gamedeveloper.com/design/using-vorticles-to-simulate-wind-in-i-ghost-of-tsushima-i-
3. 80.lv — "Creating a Campfire VFX in UE4" — https://80.lv/articles/creating-a-campfire-vfx-in-ue4
4. Loronso — "Creating optimized, convincing explosions for Unreal Engine 5" — https://loronsodev.github.io/posts/explosion-fx
5. SideFX — Labs Flipbook Textures docs — https://sidefx.com/docs/houdini/nodes/out/labs--flipbook_textures-1.0.html
6. Alan Zucconi — "The Secret Behind Valve's Flickering Lights" — https://www.alanzucconi.com/2021/06/15/valve-flickering-lights/
7. CGWorld — Elden Ring VFX interview (Japanese) — https://cgworld.jp/article/202206-cgw286-eldenring03.html
8. MCV/Develop — "The art and soul of visual design" (Jane Ng, Firewatch) — https://mcvuk.com/development-news/the-art-and-soul-of-visual-design/ (search snippet)
9. Godot Engine — "Improvements to GPUParticles in Godot 4.0" — https://godotengine.org/article/improvements-gpuparticles-godot-40
10. Sheehan Ahmed — "Realtime Rain VFX Breakdown" — https://www.sheehanahmed.com/realtime-rain-vfx-breakdown/
11. Unity Learn — "Create an environmental Particle System", plus snow-tips search results — https://learn.unity.com/tutorial/create-an-environmental-particle-system (snippet)
12. godotshaders.com — Synty "Particles" shader (soft particles and camera fade) — https://godotshaders.com/shader/synty-core-drop-in-particles-shader-generic_particlesunlit/ (snippet)
13. VFXDoc — Fading — https://vfxdoc.readthedocs.io/en/latest/shaders/fading/ (snippet)
14. 80.lv — "How rain works in video games" — https://80.lv/articles/how-rain-works-in-video-games (snippet)
15. Unreal Forums — "Stylized fire, how?" and RealtimeVFX sketch threads — https://forums.unrealengine.com/t/stylized-fire-how/74299 (snippet)
16. RealtimeVFX — "Stylized Fire" thread — https://realtimevfx.com/t/stylized-fire/5226
17. Papaya Games — "How to make a stylized fire shader" — https://papaya-games.itch.io/duck-in-town/devlog/95149/how-to-make-an-stylized-fire-shader (snippet)
18. ArtStation — zoinn stylized fire project — https://zoinn.artstation.com/projects/qJ5xVP (snippet)
19. RealtimeVFX — "Looking for feedback on Explosion VFX" — https://realtimevfx.com/t/looking-for-feedback-on-explosion-vfx/29528 (snippet)
20. GamingBolt TLOU2 graphics analysis; Naughty Dog at SIGGRAPH 2020; FX reference collection — https://gamingbolt.com/the-last-of-us-part-2-graphics-analysis-one-of-the-best-looking-games-of-all-time , https://www.naughtydog.com/blog/naughty_dog_at_siggraph_2020 (snippets)
21. ArtStation — Robert Rageson fire project — https://robertrageson.artstation.com/projects/dO3XWQ (snippet)
22. Unity Blog — "Making fire feel alive: Real-time fluid simulation in Ignitement" — https://unity.com/blog/real-time-fluid-simulation-fire-vfx-ignitement-breakdown
23. Blender Artists — "Simulate a light from a fireplace" — https://blenderartists.org/t/simulate-a-light-from-a-fireplace-without-the-fire/1160737 (snippet)
24. RealtimeVFX — "Embergen resolution issue" — https://realtimevfx.com/t/embergen-resolution-issue/14270 (snippet)
25. Packt — "Learn Blender Simulations the Right Way" (Mantaflow) and Blender bug T73766 — https://www.packtpub.com/en-eg/product/learn-blender-simulations-the-right-way-9781803234151 , https://developer.blender.org/T73766 (snippets)
26. VFXDoc — "Flipbooks and Texture Sheets" — https://vfxdoc.readthedocs.io/en/latest/textures/flipbooks/
27. Godot Forum — "How to spin or rotate particles over time (GPUParticles3D)"; Godot docs, Particle attractors — https://forum.godotengine.org/t/how-to-spin-or-rotate-particles-over-time-gpuparticles3d/36713 , https://docs.godotengine.org/en/4.7/tutorials/3d/particles/index.html (snippets)
28. 80.lv — "Santa Monica's senior programmer on how God of War Ragnarök's snow system was made" — https://80.lv/articles/santa-monica-s-senior-programmer-on-how-god-of-war-ragnar-k-s-snow-system-was-made
29. DTF — "How RDR2's visual effects work" (Russian); imgeself RDR2 graphics study; snow deformation hobby post — https://dtf.ru/id17412/62607-kak-v-red-dead-redemption-2-ustroeny-vizualnye-effekty , https://imgeself.github.io/posts/2020-06-19-graphics-study-rdr2 , https://pappaniels.github.io/posts/2025/01/23/Snow-Deformation.html (snippets)
30. Tatarchuk — "Artist-Directable Real-Time Rain Rendering in City Environments" (SIGGRAPH 2006) — https://advances.realtimerendering.com/s2006/Chapter3-Artist-Directable_Real-Time_Rain_Rendering_in_City_Environments.pdf (snippet)
31. GDC Vault — "Procedural Grass in Ghost of Tsushima"; Hashnode write-up — https://gdcvault.com/play/1027214/contactUs , https://hashnode.com/posts/what-we-can-learn-from-grass-in-ghost-of-tsushima-renders/69e130b2ffbb787634eb9ef4 (snippets)
32. 80.lv — "Insights into Building VFX for Ghost of Tsushima" — https://80.lv/articles/insights-into-building-vfx-for-ghost-of-tsushima/
33. ACM SIGGRAPH History — "Volumetric Effects of The Last of Us: Part Two" (Kovalovs) — https://history.siggraph.org/learning/volumetric-effects-of-the-last-of-us-part-two-by-kovalovs
34. grrava blog — "Stylistic fog from Firewatch with Unity's PostFX v2" — https://grrava.blogspot.com/2018/08/stylistic-fog-from-firewatch-with.html
35. The Rookies — "Stylized VFX in Unity: a RiME-inspired waterfall"; GameDev.net "Foam with flow mapping"; Unity nature shaders blog — https://discover.therookies.co/2019/11/05/stylized-vfx-in-unity-a-rime-inspired-waterfall/ , https://gamedev.net/shaderlab/53-foam-with-flow-mapping/ , https://unity.com/blog/engine-platform/nature-shaders-with-shader-graph-in-2022-lts (snippets)
36. Unity Learn — "Particle System: Lights" — https://learn.unity.com/tutorial/particle-system-lights-2019-3?version=2019.3 (snippet)
37. Unity Discussions — "Firefly glow effect" — https://discussions.unity.com/t/firefly-glow-effect/68061 (snippet)
38. Pierce Krouse — "Electricity in Unity Part 3"; 80.lv "How to set up lightning effects with UE5"; Unity forum lightning thread — https://medium.com/@pierce.krouse/electricity-in-unity-part-3-of-3-522f923a516a , https://80.lv/articles/how-to-set-up-lightning-effects-with-unreal-engine-5 , https://discussions.unity.com/t/lightning-effect-particle-system/37186 (snippets)
39. Elden Ring wiki — Grace / Guidance of Grace — https://eldenring.fandom.com/wiki/Grace (snippet)
40. VFX Apprentice — "Alohomora! Unlock the Magical VFX Behind Hogwarts Legacy" — https://www.vfxapprentice.com/blog/magical-vfx-behind-hogwarts-legacy
41. James Watt — Hogwarts Legacy VFX blog post — https://james-watt-e62s.squarespace.com/blog/2022/11/20/hogwarts-legacy (snippet)
42. Alan Zucconi — "A Journey Into Journey's Sand Shader"; GDC Vault "Sand Rendering in Journey" — https://www.alanzucconi.com/2019/10/08/journey-sand-shader-1/ , https://gdcvault.com/play/1017742/Sand-Rendering-in (snippets)
43. Godot Docs — "Turbulence" (3D particles) — https://docs.godotengine.org/en/stable/tutorials/3d/particles/turbulence.html
