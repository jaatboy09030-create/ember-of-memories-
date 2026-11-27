# 04 — Stylised and Anime-Style VFX (Toon, Hand-Drawn, Painterly)

Scope: cel/toon effects, hard-edged stepped shapes, smears, hand-drawn flipbooks versus procedural meshes ("2D effects in 3D"), holding frames (on 2s/3s), stylised fire/water/smoke/magic, colour ramps, outlined effects, and Japanese *sakuga* effects-animation principles applied to games.

Note on evidence: several primary talks (Guilty Gear Xrd GDC 2015, Hi-Fi Rush GDC 2024, Kena VFX Summit, the Riot VFX Styleguide PDF) are behind GDC Vault logins or links that are now dead. Where I could not read the primary source, I say so. "(snippet)" means the claim comes only from a search-result snippet. "(analysis)" means my own reasoning.

---

## 1. Key takeaways

- **Stylised VFX are designed, not simulated.** Anime and toon effects come from authored *shapes*: hand-painted masks, modelled meshes and drawn flipbooks. Noise fields stay secondary. Riot's guidance says to avoid photographic or noisy procedural textures, hand-paint shapes and mix soft and hard edges [7].
- **Hard edges come from a threshold, not from the texture.** Store a soft greyscale gradient (or an SDF), then cut it with `step`/`smoothstep` at an animated threshold. One 128×128 SDF can give a crisp shape, an outline and a dissolve at any size [6][11].
- **Timing beats smoothness.** Anime effects use *limited animation*: fewer drawings, held for 2–3 display frames, with irregular spacing. Arc System Works chose limited animation for Guilty Gear Xrd because it reads more clearly than full interpolation [1][2]. Effects for Spider-Verse-style films are animated on 2s [9].
- **Irregularity sells "hand-made".** Veteran anime effects animator Takashi Hashimoto (CEDEC 2011) deliberately breaks regular loops. He swaps cels, inserts odd frames and alternates two patterns ("pakapaka") for sparks. He also notes that 3D game effects are usually *too regular* [10].
- **Use a three-beat envelope, front-loaded.** Anticipation, then climax/impact, then dissipation. The peak should land within about the first 25% of the lifetime, and dissipation should be short [7][4].
- **Colour comes from a ramp, not from texture pixels.** Paint greyscale and drive colour through a 1–4-stop gradient (a LUT). Bake channels as R = colour/ramp lookup, G = emission, B = alpha [4]. A *constant* (stepped) gradient gives cel bands.
- **Value discipline.** Avoid pure 0% black and 100% white in the body of an effect. Keep it in mid-values and save the brightest value for the one-frame "pop" [7].
- **"2D in 3D" is a pipeline, not a filter.** Successful hybrids draw elements as 2D, place them on cards or meshes in 3D, flatten their lighting, and add lines in post. Examples include Spider-Verse, The Bad Guys, Rift, and the Zelda-style combat recreations [9][5].
- **Outlines are controllable data.** Arc System Works' inverted-hull lines use vertex alpha for thickness (0 = none, 0.5 = standard, 1.0 = double) and vertex blue to push the hull back. Width scales with `distance × tan(FOV/2)` [12].
- **Readability first.** Shape language encodes function: knock-ups are vertical, roots sit on the ground, heals are green and non-threatening. "Gameplay readability will always prevail over thematic resonance" (Riot) [8][13].
- **Small flipbooks are enough.** Stylised games usually cap flipbooks at 4×4 = 16 frames [14]. Held frames hide the low count, and motion-vector or flow blending is optional, not required [4].
- **Mind photosensitivity.** Anime-style impact flashes and 1–2-frame colour cells strobe. Hashimoto softens luminance jumps, and platforms flag large luminance changes [10].

---

## 2. Deep dive

### 2.1 Limited animation: holding frames on 2s and 3s

In anime, a drawing is held for 1, 2 or 3 film frames (at 24 fps: 24, 12 or 8 drawings per second). Effects are commonly "on 2s" or "on 3s", and fast impacts drop to 1s. This creates a deliberate *staccato*: shapes jump between strong poses instead of drifting.

- **Guilty Gear Xrd:** Motomura's GDC 2015 talk describes animating the 3D characters with keyframes only, with no inbetween interpolation. This borrows from sprite and cel methods, and the team chose it for *clarity* over smoothness [1][2] (snippet: the talk page and a Japanese report; the PDF handout was unreachable). Kotaku/New Frame Plus singles out attack effects as a major part of the hand-drawn feel [3].
- **Film pipelines:** VFX Voice reports that Sony's Spider-Verse and Mitchells effects animate debris and particles on 2s to stay "hand-drawn" [9].
- **Hashimoto's numbers (CEDEC 2011) [10]:**
  - A 3-second smoke shown in **18 drawings** using a mixed 1/2/2 hold pattern, not one uniform rate.
  - Fire cycles are typically **6–8 drawings**, and loops are often repeated about 16 times. He deliberately replaces these with irregular counts.
  - For Ghibli-style realism, explosions are slowed about **1.3×** relative to ordinary anime timing.
  - CG effect timing should run slightly *longer* than the hand-drawn equivalent, because CG carries more visual information.
  - Mixing time curves in one shot (e.g. stretching an 18-frame explosion over a second while other elements stay snappy) catches the eye.
- **Kanada-school timing:** Animétudes describes the Kanada style as built on limited framerates and strong modulation (holds against bursts), rather than constant motion. One example is a 12-frame hold followed by a return to 1s [15].

**What this means in a 60 fps game (analysis):**
- 24 fps on 2s = 12 drawings/s ≈ each drawing held for 5 game frames.
- On 3s = 8 drawings/s ≈ 7.5 game frames.
- A common practical choice is to step effect time at **12 fps for most effects**, **24 fps for fast impacts and slashes**, and **8 fps for slow, heavy smoke**. Keep the *camera and character* at full rate: the contrast between a smooth camera and stepped effects is what reads as "anime in 3D".
- Step *time*, not just the flipbook frame. If a particle's position, scale and rotation still interpolate every frame, the hold is lost.

### 2.2 Shape design: hard edges, stepped silhouettes, smears

**Thresholded masks.** The key stylised shader move: a soft gradient (noise, painted mask, SDF) passed through `step(t, mask)` gives a crisp silhouette. Animating `t` over the particle's life makes the shape grow and erode with no new texture.
- The HAWKED comic-VFX article converts a large black-and-white drawing into a **128×128 single-channel 16-bit linear SDF** (about 16–43 KB). It then uses `SmoothStep` inside a cutoff function for edges. Shifting the threshold produces an outline, and a "gable roof" gradient from the SDF gives a variable-thickness border offset beneath the shape [6].
- It animates the *threshold* of hand-drawn greyscale textures to get particle animation without flipbook sequences [6].
- Simon Trümpler's RiME material on alpha erosion warns that if the erosion mask doesn't match the shape's volume (e.g. the normal map), the volume illusion breaks during fade-out. Ideally derive the mask from the same sculpt [5].

**Edge bands.** Two thresholds a little apart, `step(t, m) - step(t + w, m)`, give a coloured rim (hot edge on a dissolve, dark ink edge on smoke). This is the "burnt paper edge" trick, and it is also how many toon dissolves add an outline (analysis).

**Stepped shapes, not gradients.** Kanada's explosions used triangular, abstract geometric fire and smoke shapes and flat colour spreads. Dark smoke was set against bright light, and circular paths against straight ones, for dynamism [16] (snippet). Lightning is straight lines and sharp angles. Some effects carry "wakame shadows" (internal line shapes) [15].

**Smears.** In 3D, smears are done with:
- elongated or stretched meshes,
- dedicated "smear meshes" (a swept crescent),
- or a few frames of stretched geometry [17] (snippet).

In VFX, the standard is a **swept slash mesh** (a flat arc or partial torus) with a panning, alpha-thresholded texture. Gabriel Aguiar's stylised slash workflow builds several slash meshes, a dark under-layer and an impact mesh in Blender, then assembles them in Unity [18] (snippet). Riot's guide adds: blur shapes *along* the motion path to show direction, or make the leading tip the brightest, sharpest part against darker trailing values [7].

### 2.3 Sakuga effects principles that transfer to games

Synthesised from Hashimoto (CEDEC 2011) [10], Animétudes on Kanada/Yoshinari [15][16], and VFX Voice [9]:

1. **The silhouette is the motion.** Cel effects are flat, so the outline must change visibly every drawing. Fire, smoke and sparks should vary in height, width and silhouette from frame to frame [10].
2. **Density control per frame.** For debris, alternate large moving pieces with small ones and manage how much is on screen per frame [10]. Use pre-drawn libraries of fragment and flake shapes with several break patterns [10][9].
3. **Break regularity.** Insert odd frames, flip and reuse drawings, and alternate A/B patterns. Add deliberate "snags" (an extra spark) to make the eye pause [10].
4. **Impact frames.** These are brief monochrome or abstract frames inserted at the hit (black, yellow or purple in later Kanada work) [16][15] (snippet). Yoshiyama's modern revival uses a few still, abstract frames that interrupt the action rather than build it [15]. Hashimoto often *omits* the contact frame and shows the pain frame or the reaction instead [10].
5. **Draw from the end pose backward.** Design the final state first, then fill the timing back to the start [10].
6. **Dissipate by breaking up, not by fading.** Turning Red's "panda poof" subdivided cloud shapes over time instead of lowering opacity. A power-law distribution varied when each puff broke, so the rhythm felt hand-timed [9]. This is the single most transferable smoke trick (analysis).
7. **Cheat toward the camera plane.** Push velocities toward the camera plane so silhouettes stay readable [9].
8. **Communicate timing as sound.** Hashimoto writes timing as onomatopoeia so staff share the rhythm [10]. In games this maps naturally to syncing VFX keys to SFX transients (analysis).

### 2.4 Hand-drawn flipbooks vs procedural mesh effects

| | Hand-drawn flipbook | Procedural (mesh + scrolling/threshold shader) |
|---|---|---|
| Look | True sakuga shapes, irregular timing | Smooth, controllable, can feel "too regular" |
| Memory | 4×4 grid on 512–1024 px typical [14] | Tiny: tiling noise + 1 mask |
| Variation | Fixed (flip/rotate/tint) | Infinite via seeds, thresholds |
| Duration change | Must redraw | Retime freely |
| Best for | Hero impacts, explosions, smoke puffs, slashes | Fire loops, auras, trails, water, magic circles |

Numbers [14]:
- Stylised games cap flipbooks at **4×4 (16 frames)**; frame counts are usually powers of two.
- Use **512×512** for top-down/MOBA and **≥1024×1024** for fighting games and side-scrollers with big effects.
- A 512 sheet in 3×3 gives about 170 px cells.
- Draw in black and white and let the engine colour it.
- Wide slashes can use an **8×2** grid.

The "VFX staples" article [4] adds: keep flipbooks small, with just enough frames for the element's lifetime. Prefer meshes with scrolling textures over many particles where possible.

**Hybrid ("2D effects in 3D"):**
- Spider-Verse designed explosions as 2D drawings placed on 3D cards [9].
- Mitchells vs. the Machines advected particles through a partial pyro sim, turned them into camera-facing cards with brush-stroke textures, and had artists draw over the result [9].
- The Bad Guys rendered sims in two tones so they blended with hand-drawn sprites [9].
- Rift (Unreal) used self-emissive animated cards plus a post-process that flattens diffuse light and adds edge lines [9].
- Nello Fontani's EmberGen anime explosions [19]: simple shapes, a large voxel size and mild noise keep the silhouette clean. Low quantisation cuts the palette to a few shades, and a high smoke "dilate" fills small details into a solid silhouette. This is the recipe for *simulated* sources that must read as drawn.

Hand-drawn tooling: OpenToonz (free) is used for frame-by-frame impact flipbooks taken into Unity (Gabriel Aguiar tutorial) [20] (snippet). Krita, Toon Boom Harmony and Adobe Animate also work, and GlueIT packs the grids [14].

### 2.5 Colour ramps and value

- **Channel-packing for stylised effects [4]:**
  - **R** = greyscale driving a 1–4-colour gradient (LUT).
  - **G** = emission mask, so two parts animate separately.
  - **B** = alpha.
  - Vertex alpha fades mesh edges.
  - Fade in/out behaves like a Photoshop *Levels* remap.
- **Contrast envelope [4]:** maximum contrast and saturation at climax; low contrast and low opacity during dissipation.
- **Riot value rules [7]:**
  - Mid-range body values; the highest spike only on the instant primary flash; no 0%/100% extremes.
  - Use a local emission glow to extend the value range.
  - Saturation hierarchy: environment low, UI controlled, VFX highest ceiling.
  - One dominant hue plus a small, desaturated complementary accent.
- **Stepped ramps (analysis):** for cel effects use 2–4 *constant* bands, e.g. fire = core near-white-yellow, mid orange, outer red, plus a dark smoke band that replaces fade-to-transparent. Interpolated ramps read as "realistic"; constant ramps read as "drawn".
- With AgX tonemapping and glow, keep effect albedo/emission below heavy clipping so bands stay distinct (see §5).

### 2.6 Stylised element recipes from sources

- **Fire (Zelda-style recreation, 80.lv) [21]:**
  - Use a tessellated plane (not a sprite), so noise can offset vertices.
  - One RGB texture holds three masks (bottom, left side, right side). The shader rotates the sides inward to meet at the top, and each layer scrolls at a different speed.
  - A gradient mask with a different cutoff gives the brighter inner flame.
- **Fire (RiME) [5]:** simple textures plus UV distortion. The shared David Miranda material is the reference, and geometry with manipulated normals suits stylised effects.
- **Fire (Godot community shader) [22]:**
  - A camera-facing mesh, with noise triplanar-sampled on the XY and ZY planes and blended by the normal.
  - Alpha = noise × mask − (1 − vertex alpha), then `smoothstep(0, edge_softness, alpha)`.
  - Emission = colour × intensity.
  - For a harder toon look, swap the smoothstep for a `step` (analysis).
- **Smoke:**
  - Three hand-painted layers panning upward [21].
  - Lit smoke particles to show volume [5].
  - Dark, angular Kanada smoke against bright fire [16].
  - Dissipation by subdivision, not fade [9].
  - Steamboy-style steam: about 10 stacked layers per cut, with fractal jagged edges; *King of Thorn* steam was drawn as crushed squares rather than circles [10].
- **Explosion cloud [21]:** two texture layers per sprite. The first is distorted by a flow map or UV noise, then dissolves to reveal the second. The Zelda clouds *speed up* their rotation over time, unlike typical decelerating explosions. The author halved the cloud lifetime to match the reference's frame timing.
- **Water [10][5]:**
  - Hand-drawn highlight shapes, then blur.
  - Splashes as grain-like droplets.
  - Vertex-colour shorelines sharpened in the shader.
- **Magic circles (Genshin-style recreation) [23]:**
  - Drawn art plus layered parallax "galaxy" planes moving at different speeds.
  - Screen-space UVs so the inside reads as a portal.
  - An erosion pass for the reveal.
- **Comic/onomatopoeia [6]:** SDF word atlases, halftone dot pattern over the shape, coloured via gradient.

### 2.7 Outlined effects

- **Inverted hull (Arc System Works) [12]:**
  - The mesh is drawn twice; the second pass is front-face culled and pushed out along the normals.
  - Vertex alpha scales thickness (0 / 0.5 / 1.0), and vertex B pushes the hull away from the camera so only the outer rim survives.
  - Width scales by `distance × tan(FOV/2)`, getting tan from `1/P[0][0]`.
  - Use about 1–3 mm on faces in close-up and 7–10 mm in long shots.
  - Set alpha to about 0.1 in valleys to stop floating lines.
  - Store a second smoothed normal set in the tangent slot, because ASW's toon shaders don't use normal maps.
  - The technique dates back to Jet Set Radio (2000).
- **For effects meshes (analysis):** the same hull works on slash crescents, rocks and debris chunks. For alpha-cut sprites, generate the outline from the SDF/threshold band instead (§2.2), because hulls don't work on flat cards.
- **Sable [24]:** flat-shaded base, then shadows, then per-biome distance fog, then outlines. Outline opacity *fades with distance* to avoid pop-in and to reinforce depth. This applies directly to outlined VFX in a big space (analysis).
- **Post outlines:** Moebius-style screen-space edge detection (depth and normals) catches effect meshes too, but not transparent sprites (no depth writes). Give hero effect meshes depth writes or alpha-scissor if they must be outlined (analysis).

### 2.8 Readability and shape language (Riot, Blizzard)

- **Each ability answers three questions [13]:** what is it (identity), what does it do (function), and how strong is it (impact).
  - Roots: ground ring plus a rising cylinder.
  - Knock-ups: vertical elements.
  - Spell shields: pulsing lines moving down the surface.
  - Heals: green, non-threatening shapes.
  - Importance is scored 1–10 per viewer (self, ally, enemy), and some indicators are shown only to relevant players.
- **Overwatch:** lead VFX artist Rachel Day calls VFX "the visual telling of gameplay". The team's approach is a very stylised, hand-painted, basic effects system [25] (snippet).
- **GDC 2017 "Artistic Principles of VFX" (Keyser/Riot, Chamberlin/Blizzard):** the outline covers Shape & Area of Effect, Contrast & Focal Point, Color & Identity, and Timing & Threat Level [25] (snippet; the summary page would not render).

---

## 3. Examples

- **Guilty Gear Xrd / Strive (Arc System Works):**
  - Keyframe-only limited animation for clarity [1][2].
  - Hand-tuned cel shading with no normal maps [12].
  - Inverted-hull lines controlled by vertex colour [12].
  - Effects drawn to match the held-pose rhythm [3].
  - *What works:* every element (character, effect, camera cut) agrees on the same stepped timing, so nothing reveals the 3D interpolation underneath (analysis).
- **Genshin Impact / Honkai / ZZZ (HoYoverse):**
  - miHoYo describes its rendering as PBR-based stylised rendering [26] (snippet).
  - Effects lean on drawn magic circles, parallax layers and erosion reveals [23].
  - Elemental colour coding is strict, one hue family per element (analysis).
  - *What works:* bright, saturated effects on a softer world, which is Riot's saturation hierarchy applied (analysis).
- **Hi-Fi Rush (Tango):**
  - Custom deferred toon renderer in UE4 at 60 fps [27].
  - The talk covers comic shading, toon lighting and toon face shadows.
  - Effects and world props visibly pulse on the music beat (analysis, from play).
  - *What works:* the beat acts as a global "hold" clock, so effects snap to the rhythm the way anime effects snap to drawings (analysis).
- **Zelda BotW/TotK:**
  - Cel shading blended with realism [28].
  - Signature swirling, rotation-accelerating cloud puffs and hard-cut smoke [21].
  - *What works:* very few, very clear shapes per effect, with a short lifetime [21].
- **RiME (Tequila Works):**
  - Simple textures, UV distortion, geometry plus normal manipulation, and erosion matched to volume [5].
- **Ori (Moon Studios):**
  - Effects described as "juicy, painterly, with layers of effects accenting every hit and jump" [29] (snippet, mirror of RPS).
  - *What works:* soft painted glows over hard silhouettes, so layering gives richness without noise (analysis).
- **Kena (Ember Lab, ex-VFX/animation studio):**
  - The GDC VFX Summit talk ties world effects to the restoration theme and covers the Rot effects [30] (snippet; talk gated).
- **Okami:**
  - Real-time sumi-e is rarely attempted outside Okami [31] (snippet).
  - The style relies on ink-wash edges (rich blacks, soft wet edges) and brush-stroke cards (analysis).
- **Sable (Shedworks):**
  - Flat colour plus outlines that fade with distance; fog per biome [24].
- **League of Legends (Riot):**
  - The style guide codifies value, saturation, shape and timing [7][8][13].
- **Film reference, relevant to games:**
  - Spider-Verse, Mitchells, The Bad Guys and Turning Red show the 2D-on-3D card pipeline and on-2s particles [9].

---

## 4. Common mistakes

1. **Stepped flipbook, smooth motion.** The texture is on 2s, but position, scale and rotation interpolate every frame, so it reads as "low-fps texture", not "anime". Step the whole effect clock (analysis).
2. **Regular loops.** A perfect 8-frame fire loop at a uniform rate looks mechanical. Vary hold lengths, add an odd frame, and randomise the start frame [10].
3. **Fading opacity to dissipate.** This looks like realistic VFX. Instead break up, shrink, erode by threshold, or drop to a darker band [9][5].
4. **Gradient ramps on toon effects.** Smooth interpolation undoes the cel look. Use constant (stepped) ramps with 2–4 bands (analysis).
5. **Noise-first design.** Procedural noise without an authored silhouette mask reads as generic. Paint the shape; let noise only *wobble* it [7].
6. **Erosion mask that ignores volume.** The fade then reveals flatness [5].
7. **Too many overlapping alpha layers.** This loses legibility and adds overdraw [7].
8. **Peak too late or tail too long.** Hit the climax within the first quarter; keep dissipation short [7][4].
9. **Values clipping to white.** Under bloom/glow, band edges vanish into a soft blob. Keep the body in mid-values [7].
10. **Uncontrolled strobe.** Impact frames and A/B flicker without luminance limits are a photosensitivity risk [10].
11. **Outlines with constant pixel width at all distances.** Scale with distance and FOV, and fade outlines with distance [12][24].

---

## 5. Apply in Godot 4 (4.7, Forward+, AgX, glow on)

### 5.1 Hold the whole particle system on 2s/3s (no shader needed)

Godot's `GPUParticles3D` has a built-in fixed simulation rate:

```
GPUParticles3D
  fixed_fps     = 12      # 12 = "on 2s" feel; 8 = "on 3s"; 24 for fast slashes
  interpolate   = false   # CRUCIAL: with true, Godot smooths between sim steps and the hold is lost
  fract_delta   = true
```

With `interpolate = false`, particles visibly step 12 times a second while the camera stays at 60+. Try this first on Unsent's burning-leaf sub-emitter flames and Vefects-pack instances, used *selectively* (e.g. a memory or flashback moment). Unsent's default tone is slow and soft, so treat stepping as a stylistic accent, not a blanket rule (analysis).

Flipbooks: in `StandardMaterial3D` with **Billboard Mode = Particle Billboard**, set `particles_anim_h_frames`/`v_frames` (e.g. 4×4). In the `ParticleProcessMaterial`, set `anim_speed_min/max` (cycles per lifetime) or use `anim_offset_min/max = 0–1` for a random start frame. Godot selects frames discretely (no blending) by default, which suits a drawn look.

### 5.2 Stepped time inside a shader (for mesh effects, slashes, auras)

```glsl
// spatial shader on a slash/aura mesh
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform sampler2D shape_mask : hint_default_black, filter_linear_mipmap, repeat_disable; // soft greyscale or SDF
uniform sampler2D noise_tex : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform sampler2D ramp : source_color, filter_nearest, repeat_disable; // GradientTexture1D, interpolation CONSTANT
uniform float hold_fps = 12.0;       // 12 = on 2s at 24, 8 = on 3s
uniform float life = 0.45;           // seconds, set from script / INSTANCE_CUSTOM
uniform float edge_width = 0.06;
uniform vec4 edge_color : source_color = vec4(0.08, 0.03, 0.02, 1.0); // dark ink rim
uniform float emission_boost = 2.0;

instance uniform float start_time = 0.0;

void fragment() {
    float t_raw = (TIME - start_time) / life;
    float t = floor(t_raw * hold_fps * life) / (hold_fps * life); // stepped 0..1
    t = clamp(t, 0.0, 1.0);

    // Pan noise in held steps too, so the wobble also "holds"
    vec2 nuv = UV * vec2(2.0, 1.0) + vec2(-t * 1.5, 0.0);
    float n = texture(noise_tex, nuv).r;

    float m = texture(shape_mask, UV).r * mix(0.75, 1.0, n);

    // Grow fast then erode: peak inside first ~25% of life
    float grow  = smoothstep(0.0, 0.2, t);
    float erode = smoothstep(0.35, 1.0, t);
    float thr = mix(1.0, 0.15, grow) + erode * 0.85;

    float body = step(thr, m);
    float rim  = step(thr - edge_width, m) - body;    // band just outside the body

    vec3 band_col = texture(ramp, vec2(clamp(m, 0.0, 0.999), 0.5)).rgb;
    ALBEDO = mix(edge_color.rgb, band_col, body);
    EMISSION = band_col * body * emission_boost;
    ALPHA = max(body, rim * edge_color.a);
}
```

Ramp setup: create a `GradientTexture1D` and set its `Gradient.interpolation_mode = Constant`. Use 3–4 stops (e.g. `#3a0f0a`, `#c8401c`, `#f29a2e`, `#fff2c0`). Width 64–256 px is plenty; use `filter_nearest` so the bands stay hard.

### 5.3 Toon dissolve for the existing burn shader

Unsent already has a burn/dissolve. To make it read "drawn", replace any smooth edge gradient with two `step`s and a constant ramp:

```glsl
float d = texture(dissolve_noise, UV).r;
float burnt  = step(d, progress);                       // fully gone
float ember  = step(d, progress + 0.04) - burnt;        // hot band
float char_b = step(d, progress + 0.09) - burnt - ember;// dark char band
ALBEDO   = mix(ALBEDO, vec3(0.05, 0.03, 0.02), char_b);
EMISSION = vec3(1.0, 0.45, 0.12) * ember * 3.0;
if (burnt > 0.5) discard;
```

Drive `progress` in stepped increments, e.g. `floor(raw * 12.0) / 12.0` per second of burn, for a paper-flipbook burn (analysis).

### 5.4 Billboard flame and smoke: from soft to toon

In the existing noise-torn billboard shaders:
- Swap `smoothstep(0, softness, a)` for `step(threshold, a)`. Alternatively, keep a *very* small softness (0.01–0.03) to anti-alias without looking soft [22].
- Quantise the colour lookup: `float q = floor(heat * 4.0) / 4.0;`, then sample the ramp with `q`.
- **Smoke dissipation:** don't fade ALPHA. Raise the threshold over life so puffs *shrink and break*, and add a dark band (`step` pair) instead of transparency [9].
- Use `INSTANCE_CUSTOM` (from `ParticleProcessMaterial` → `Custom Data`) to give each particle a random threshold offset and start frame. This provides the irregularity Hashimoto recommends [10].

### 5.5 Outline on effect meshes (inverted hull in Godot)

On the slash or debris `StandardMaterial3D` (or a `ShaderMaterial`), set **Next Pass** to:

```glsl
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;
uniform vec4 line_color : source_color = vec4(0.06, 0.04, 0.05, 1.0);
uniform float base_width = 0.004; // view-space units at 1m, FOV-corrected below

void vertex() {
    float thickness = COLOR.a;                   // vertex alpha: 0 none, 0.5 std, 1 double (ASW)
    vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    float fov_scale = 1.0 / PROJECTION_MATRIX[1][1]; // ~tan(FOV/2)
    float w = base_width * 2.0 * thickness * (-view_pos.z) * fov_scale;
    VERTEX += NORMAL * w;
}
void fragment() { ALBEDO = line_color.rgb; }
```

Paint vertex alpha in Blender (0.5 default; around 0.1 in creases). For long-distance effects, multiply the width by a distance fade, Sable-style [24]. Flat alpha-cut cards get their outline from the threshold rim (§5.2) instead.

### 5.6 Impact frames (screen-space, 1–3 frames)

Use a `CanvasLayer` (layer 100) containing a `ColorRect` (full rect) with a `canvas_item` shader:

```glsl
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount = 0.0;          // 0 off, 1 full
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.0, 1.0);
void fragment() {
    vec3 c = texture(screen_tex, SCREEN_UV).rgb;
    float l = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 inv = vec3(step(0.45, 1.0 - l));      // hard 1-bit inverted silhouette
    COLOR = vec4(mix(c, mix(tint.rgb, vec3(1.0), inv), amount), 1.0);
}
```

Script: on hit, set `amount = 1` for 2 frames (about 33 ms), then 0. Optionally hold the hit-stop for 3–5 frames. **Accessibility:** add a setting to disable it, clamp it to at most 3 flashes per second, and prefer a dark tint over white [10].

### 5.7 Value, glow and AgX

- Keep stylised effect albedo/emission in mid-values: emission energy around 1.5–3 for the body, and save peaks (5+) for the one-frame pop. AgX compresses highlights, so over-bright bands merge (analysis, consistent with [7]).
- In `WorldEnvironment`, raise **Glow HDR Threshold** (e.g. 1.0–1.2) so only the pop and core blooms, not every band.
- For hard toon effects, keep glow `blend_mode` = Additive or Screen at low intensity. Soft-light glow tends to blur cel edges (analysis).

### 5.8 Asset pipeline summary

- Draw flipbooks in Krita or OpenToonz in **black and white**, 4×4 grid on 1024² (or 512² for small effects), with padding around cells [14].
- Import with **Mipmaps on** and **Filter Linear**, then let the ramp colour it [4].
- SDF shapes: 128–256² single-channel. Godot imports greyscale PNG fine, and `filter_linear` keeps SDF edges crisp at scale [6].
- Name effect timing in "drawings at N fps" in design docs (e.g. "slash: 6 drawings at 24, smoke: 8 drawings at 8"). This keeps animators and VFX on one clock (analysis, after [10]).

---

## 6. Sources

1. GDC Vault — "GuiltyGearXrd's Art Style: The X Factor Between 2D and 3D" (Junya C. Motomura, 2015). https://gdcvault.com/play/1022031/GuiltyGearXrd-s-Art-Style-The
2. Game Watch Impress — GDC 2015 report on Guilty Gear Xrd (Japanese; via search snippet). https://game.watch.impress.co.jp/docs/news/20150307_691725.html
3. Kotaku — "Breaking down the animation of Guilty Gear and Dragon Ball FighterZ". https://kotaku.com/breaking-down-the-animation-of-guilty-gear-and-dragonba-1836849279
4. 80.lv — "VFX Staples: Shape, Color and Motion". https://80.lv/articles/vfx-staples-shape-color-and-motion/
5. Simon Trümpler (simonschreibt.de) — "Stylized VFX in RiME". https://simonschreibt.de/gat/stylized-vfx-in-rime/ (talk page: https://www.unrealengine.com/events/unreal-fest-europe-2018/stylized-vfx-in-rime)
6. Game Developer — "How to create comic-book style VFX for games, like in HAWKED". https://gamedeveloper.com/art/how-to-create-comic-book-style-vfx-for-games-like-in-hawked
7. VFX Apprentice — "10 Design Tips from the League of Legends VFX Style Guide". https://www.vfxapprentice.com/blog/10-league-of-legends-vfx-design-tips
8. League of Legends Nexus — "Dev: League's VFX Style Guide" (PDF link now redirects). https://nexus.leagueoflegends.com/en-us/2017/10/dev-leagues-vfx-style-guide/
9. VFX Voice — "The Return of Hand-Drawn and Stylized Effects Animation". https://www.vfxvoice.com/the-return-of-hand-drawn-and-stylized-effects-animation/
10. GIGAZINE — CEDEC 2011 anime effects talk (Takashi Hashimoto). https://gigazine.net/gsc_news/en/20111019_anime_effect_cedec2011
11. Godot Shaders — Flipbook snippet (stepped/floored time pattern). https://godotshaders.com/snippet/flipbook/
12. Arc System Works (ASW Academy) — "Guilty Gear Toon Line Control Techniques [ENG ver.]". https://docswell.com/s/ASW_Academy/5LVY67-GG-Toonline-Eng
13. realtimevfx.com — "Anatomy of a League of Legends missile, Part 2: What are we communicating with our VFX". https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-2-what-are-we-communicating-with-our-vfx/13062
14. VFX Apprentice — "What are Flipbooks? How are They Used in Game FX?". https://www.vfxapprentice.com/blog/what-are-flipbooks-in-games
15. Animétudes — "The Kanada style now". https://animetudes.com/2021/07/09/the-kanada-style-now/
16. Full Frontal — Sakuga Expresso 16: Arcadia of My Youth (Kanada effects; via snippet), and Sakuga Design Club glossary (impact frames; via snippet). https://fullfrontal.moe/sakuga-expresso-16-arcadia-of-my-youth/ ; https://skool.com/sakuga-design-club-8919/sakuga-glossary
17. Prolific Studio — "Exaggerated animation" (smears in 2D vs 3D; via snippet). https://prolificstudio.co/blog/exaggerated-animation/
18. Gabriel Aguiar Prod — "Unity VFX: Stylized Ground Slash" course page (via snippet). https://www.udemy.com/course/unity-vfx-stylized-ground-slash/
19. 80.lv — "Making Anime-Inspired Stylized 3D Explosions with JangaFX's EmberGen". https://80.lv/articles/making-anime-inspired-stylized-3d-explosions-with-jangafx-s-embergen
20. 80.lv — "Tutorial: Frame-by-Frame Effects for Games with OpenToonz" (Gabriel Aguiar). https://80.lv/articles/tutorial-frame-by-frame-effects-for-games-with-opentoonz
21. 80.lv — "Creating Stylized Combat VFX in the Zelda Style" (Soenke Seidel). https://80.lv/articles/creating-stylized-combat-vfx-in-the-zelda-style/
22. Godot Shaders — "Stylized fire (3D)". https://godotshaders.com/shader/stylized-fire-3d/
23. realtimevfx.com — "Genshin Impact VFX — Mona magic breakdown". https://realtimevfx.com/t/genshin-impact-vfx-mona-magic-breakdown/16874
24. Game Developer — "How Shedworks refined the art of Sable in pursuit of readability". https://www.gamedeveloper.com/marketing/how-shedworks-refined-the-art-of-sable-in-pursuit-of-readability
25. VFX Voice — Overwatch VFX (Rachel Day; via snippet) and GDC 2017 "Visual Effects Bootcamp: Artistic Principles of VFX" (via snippet). https://vfxvoice.com/?p=624080 ; https://www.gdcvault.com/play/1024439/Visual-Effects-Bootcamp-Artistic-Principles
26. Unity Dojo / SlideShare — miHoYo Genshin rendering talk (Zhenzhong Yi; via snippet). https://www2.slideshare.net/UnityTechnologiesJapan/210617-unity-dojo20211mihoyozhenzhongyi
27. 80.lv — "The Making of Hi-Fi Rush's 3D Toon Rendering Style" (GDC 2024 summary). https://80.lv/articles/the-making-of-hi-fi-rush-s-3d-toon-rendering-style
28. VFX Apprentice — "Cel Shading: The Legendary Animation Style of Zelda". https://www.vfxapprentice.com/blog/cel-shading-video-games-zelda
29. Ori the Game / Rock Paper Shotgun — "How animation powers Ori and the Will of the Wisps" (via snippet). https://www.orithegame.com/rockpapershotgun-how-animation-powers-ori-and-the-will-of-the-wisps/
30. GDC Vault — "Visual Effects Summit: Restoring the Forest: Capturing the Themes of 'Kena' Through VFX" (via snippet). https://gdcvault.com/play/1027839/Visual-Effects-Summit-Restoring-the
31. Trinity College Dublin dissertation on sumi-e rendering (Okami reference; via snippet). https://publications.scss.tcd.ie/theses/diss/2020/TCD-SCSS-DISSERTATION-2020-056.pdf
32. Animétudes — "Gainax and the Neo-Kanada Renaissance" (context). https://animetudes.com/2021/07/02/gainax-and-the-neo-kanada-renaissance/

Not reachable: the Riot VFX Styleguide PDF (redirects), the Motomura Xrd PDF handout (connection refused), the Unreal Engine Guilty Gear Strive interview (403), Polycount threads (403), and the Notion summary of the GDC 2017 VFX bootcamp (empty render). Harry Alisavakis' and Cyanilux's own pages were not fetched. The searches surfaced only third-party references to them, so they are not used as sources.
