# 06: VFX shaders and texture authoring (the technical-art core)

How real-time VFX artists turn a few greyscale textures and a handful of shader operations into fire, magic, smoke and impacts. This file covers the shader vocabulary (erosion, distortion, panning, flowmaps, polar UVs, gradient maps, Fresnel, vertex offset, depth fade), the texture side (channel packing, tileable noise, flipbooks, motion vectors, normal-mapped and 6-way-lit smoke, resolution budgets) and HDR colour for bloom. The last section maps it all onto Godot 4.7.

> Research note: I could not find a single public talk titled "Shader Tricks" by Riot. Riot material here comes from Shannon Berke's knowledge-share thread, Riot's tech blog and the LoL VFX style guide [12][13][14]. Simon Trümpler's ArtStation class page returned 403, so his material comes from his blog and his realtimevfx posts [4][5][6].

---

## 1. Key takeaways

- **Most stylised VFX is one master shader.** The shader takes greyscale noise and runs it through panning, UV distortion, erosion and then a gradient map. Harry Alisavakis's "VFX Master Shader" and the realtimevfx "bread and butter" thread list nearly the same feature set [7][6].
- **Alpha erosion beats an alpha fade.** Animate a threshold against a greyscale mask, using `step` for hard edges or `smoothstep` for soft ones. The shape then dissolves from its thin parts inward instead of turning uniformly transparent. With a soft edge, remap the driver to `-feather … 1+feather` so that 0 and 1 really mean fully visible and fully gone [1].
- **Erosion, distortion and noise textures are data, not colour.** Import them as linear. Read as sRGB, the erosion timing accelerates or bunches [1][2]. Use the full 0–1 value range so textures behave the same in every material [20].
- **Drive the shader per particle.** Feed the erosion threshold from vertex or particle colour alpha (Alisavakis uses `cutoff = _Cutoff + (1 - color.a)`) or from custom data. One material then serves every particle, and the curves live in the emitter [7][13].
- **Layer the same noise at power-of-two scales (0.5, 1, 2).** Use random per-particle offsets and speeds, multiply the layers by about 2 to restore brightness, and constrain the range around mid-grey. This is Diablo 3's "scale by mids" [9]. Non-power-of-two scale ratios cause visible pulsing.
- **Gradient maps (colour ramps) turn one greyscale texture into many effects.** Skull & Bones keeps tone consistent across all its smoke with a 16×16 albedo ramp and a 128×16 emissive ramp indexed by an animated channel [15].
- **Pack channels only when they share UVs, tiling and resolution.** Put the high-contrast mask in alpha, because under BC3/DXT5 the alpha block gets 8 grey levels per 4×4 block versus 4 for RGB [2].
- **Flipbooks are expensive.** A 2048² sheet of 8×8 frames leaves only 256 px per frame. Motion-vector interpolation let one UE5 explosion drop from 121 to 32 frames, roughly doubling per-frame resolution [10].
- **Motion vectors are RG offsets around mid-grey.** The usual starting strength is about 1/FPS of the bake (Houdini's guidance). They only blend correctly where consecutive silhouettes overlap, and they must be read as linear data [17][18].
- **Lit smoke has a range of options.** In rising cost and quality: a baked gradient, spherical normals, a normal-mapped flipbook, then 4-way or 6-way lightmaps. 6-way stores right/top/back in one RGB, left/bottom/front in another, with alpha and emissive in the spare A channels. The shader blends by squared light-direction components [3][15].
- **HDR colour drives bloom.** Glow comes from emissive values well above the bloom threshold, roughly 2–10× [22]. Luminance is weighted (0.2126R + 0.7152G + 0.0722B), so a saturated blue or magenta needs far more energy than a green to bloom [21].
- **Depth fade (soft particles) and Fresnel are cheap and always worth it.** They remove hard intersection lines on quads and flat silhouettes on meshes [6][19].

---

## 2. Deep dive

### 2.1 Alpha erosion / dissolve

**Mechanism [1].** Take a greyscale mask `m` and a threshold `t` animated from 0 to 1.

- Hard: `a = step(t, m)`. Pixels are fully on or off and edges can alias. This suits alpha-clip (opaque, `discard`) materials.
- Soft: `a = smoothstep(t - f, t + f, m)`, where `f` is the feather width. Because of the feather, `t` must travel from `-f` to `1 + f`, or the shape never fully appears or disappears.
- Dithered: compare against a screen-space Bayer pattern so the material stays opaque but reads as translucent. *Strike Vector EX* used this on explosion and smoke meshes the camera flies through, to kill overdraw [1].

**Authoring the mask (analysis, from [1][5][9]).** The mask's *value distribution* is its animation. Dark values erode first and bright values survive longest.

- A good erosion texture has a broad histogram with lots of mid-greys, so the dissolve moves steadily rather than popping.
- Bake a radial or "core" gradient into it (bright centre, dark edges) so the shape shrinks toward its heart.
- Multiply by a tiling noise for breakup. Clouds plus Directional Warp in Substance Designer, Perlin/Voronoi in Material Maker, or a blurred sim render all work.
- Trümpler's Alpha1 article notes that grey values plus texture filtering make even a 1-bit threshold look smooth and round. Fallout 4 and *Drifting Lands* (a reader comment) also used thresholded or level-shaped alpha on purpose [5].

**Edge glow ("burn edge").** Compute a second, slightly offset threshold: `edge = smoothstep(t, t + w, m) - smoothstep(t + w, t + 2w, m)`. Tint it with an HDR colour. Alisavakis exposes `_BurnCol` and `_BurnSize` for exactly this [7].

**Drive it from the emitter.** Shannon Berke (Riot) keyed League trail erosion to start at 0.2 of the quad's lifetime [13]. Threads also suggest building a gradient from `UV × vertex colour`, so a trail erodes from its tail [13]. Alisavakis deliberately uses vertex-colour alpha rather than another vertex stream, to keep the shader light [7].

### 2.2 Panning noise, UV distortion, flowmaps

**Panning.** `uv += TIME * speed`. Two copies of the same texture panned at different speeds or directions and multiplied create "morphing" motion rather than visible sliding.

- Berke's caustic look: speed 1 and speed −0.5, multiplied, additive blend, no alpha channel needed [13].
- Diablo 3's version, per the JangaFX reconstruction [9]:
  - `A = ((T1·T2·2)·T3·2)·Mask`, with T1–T3 being the same noise at UV scales 0.5, 1 and 2.
  - Per-particle random offset and speed, with speed clamped to (0, 1] so no layer crawls.
  - About 7 particles for the reference effect.
  - Multiply only the noises by 2, never the mask, or alpha blows out.
  - Julian Love's rule: the more you multiply, the more you must constrain the noise range ("scale by mids", contrast around 0.5), or black voids appear to pan instead of morph.

**UV distortion** (Torbach on realtimevfx [6]):

- Read a noise or "distortion" texture, remap 0–1 to −1…+1, and scale it down to about ±0.1 before adding it to UVs. Mid-grey then means no motion.
- An offset of 0.01 moves about 1% of the image; 5–10% is usually plenty.
- Use separate noises for U (R) and V (G) to break uniformity.
- Pan the distortion texture itself, more slowly than the main texture.
- Alisavakis: `displ = (tex.xy*2-1) * _DisplacementAmount` [7].

**Flowmaps** (Catlike Coding [16]):

- An RG texture stores a 2D direction per pixel (`*2-1` decode). Offset UVs by `flow × p`, where `p = frac(time + phase)` is a sawtooth.
- To hide the reset, take two samples with phases 0 and 0.5 and blend them with triangle weights `w = 1 − |1 − 2p|`; the weights always sum to 1.
- Put low-frequency noise in the flowmap's alpha and add it to time, so the pulse is spread across the surface.
- A "jump" offset of about 0.2–0.25 per cycle lengthens the apparent loop.
- Flow strength changes speed without changing timing. A flow offset of −0.5 keeps the cleanest frame at each phase's peak.
- Paint flowmaps in Houdini or FlowMap Painter, or derive them from a sim's velocity.

**Polar coordinates** [7][8]:

```
c = uv * 2 - 1
polar = vec2(atan(c.y, c.x) / TAU + 0.5, length(c))
```

- Panning X spins the texture; panning Y moves it in or out. Use this for portals, shockwave rings, vortexes and sun coronas.
- There is a seam at angle 0/1 unless the texture tiles horizontally.
- The centre pinches; mask it out or cover it with a glow core.
- JangaFX's Diablo 3 orb used Cartesian-to-Polar plus a directional blur in the texture tool to hide the seam [9].

### 2.3 Gradient mapping / colour ramps

- Sample a 1×N (or N×16) ramp with the greyscale result as U: `col = texture(ramp, vec2(g, 0.5))`.
- Benefits [6][15]:
  - one texture gives many colourways (a team-colour or element swap is just a new ramp);
  - colours stay consistent across a whole game;
  - the ramp can contain HDR values for the hot core;
  - a value-to-colour mapping naturally gives "hot centre, cool edge" fire.
- Skull & Bones indexed its emissive ramp with `1 − Mask.R`, a Houdini-rendered heat/emissive key, so the animated channel shifts each pixel between smoke and fire [15].
- Optional banding before the lookup, `round(g·bands)/bands` with `_Bands = 3`, gives cel-shaded stylised VFX [7].
- Blackbody ramps (temperature to colour) give physically plausible fire. The UE5 explosion breakdown stores emissive separately in B so it can be re-tinted that way [10].

### 2.4 Fresnel, vertex animation, depth fade

- **Fresnel:** `pow(1 − saturate(dot(N, V)), p)`. Use it for shield rims, aura edges and waterfall foam. Inverted, it fades a mesh's silhouette so it doesn't read as a hard shell. Noise can be applied only at the rim [6].
- **Matcap** is a related cheap trick: a camera-fixed lookup gives billboards fake volume, which is useful on mobile [6].
- **Vertex offset:** push vertices along the normal by a noise sample (`(n*2-1)*amount`) [7]. Basic world-position offset is "very cheap" because cost scales only with vertex count [6]. Use it for wobbling slashes, swelling orbs and flags. Pan the noise so the motion travels.
- **Depth fade / soft particles:** compare scene depth with fragment depth and fade alpha over a distance (typically 0.1–1 m, analysis). This hides the hard line where a quad cuts into the ground. The Godot "fake depth" smoke uses proximity fade alongside spherical normals [19].

### 2.5 Channel packing and texture formats

From the VFX Documentation project [2]:

- **When packing pays off.** It saves samples only if all channels are read once at the same UV, tiling and offset. Otherwise it saves bindings but not reads.
- **Resolution is shared.** Don't pack a 16×16 tiling mask into a 256² texture.
- **Use alpha for the hard channel.** BC compression shares colour endpoints across RGB in each 4×4 block, so a high-frequency, high-contrast mask in R/G/B causes artifacts in its neighbours. Put it in A, which is compressed independently with 8 grey levels per block in DXT5, versus 4 in RGB.
- **Sizes.** Use power-of-two sizes for mips and multiples of 4 for BC. Non-square textures stop mipping at the short side: 1024×256 ends at 16×4.
- **Bit depth.** An 8-bit channel gives 256 animation states. For long, slow erosions, pack high and low bits across two channels.
- **Typical VFX packs (analysis):**
  - R = erosion/shape;
  - G = noise for distortion;
  - B = secondary detail;
  - A = alpha.
- **Flipbook pack** (UE5 explosion [10]):
  - Texture 1: R/G = motion vector, B = emissive, A = alpha.
  - Texture 2: R/G/B/A = top/left/right/bottom light.
- **Unity 6-way pack [3]:**
  - Map A: R/G/B = right/top/back, A = transparency.
  - Map B: R/G/B = left/bottom/front, A = emissive.

**Value range.** Tyler Walters: use the full 0–1 range in 8-bit greyscale. A texture using only about 80% of the range needs extra shader remapping and breaks swappability. Even a 1024-wide 8-bit gradient has only 256 distinct values, each repeated 4 times. Keep 16-bit sources and ship 8-bit [20].

### 2.6 Tileable noise authoring

**Tools:**

- **Substance Designer:** Perlin, Clouds, Cells, Directional Warp and Tile Sampler are tileable by construction. One example is a Perlin-subtracted Tile Sampler for damage masks [24].
- **Material Maker** (free, MIT, built on Godot): node-based and tileable, with SDF nodes since 1.5. It is not a flipbook tool [23].
- **Godot itself:** `NoiseTexture2D` with `seamless = true`.
- **Houdini COPs.**
- **Photoshop/Krita:** Offset filter (half width/height) and clone the seam. Clouds plus Difference Clouds gives quick wisps.
- **Free packs:** CC0 noise packs at 128/256/512 [25].

**Rules:**

- Remove distinctive shapes. Circles and eyes repeat visibly in space and, worse, in time [2].
- Randomise rotation and offset per particle.
- Keep a broad mid-grey histogram [9][20].
- Author at power-of-two sizes. A 256–512 tileable noise is usually enough because it is tiled and distorted. Masks with soft gradients can be 64–128 (analysis).

### 2.7 Flipbooks from simulations

**Sources:**

- **EmberGen:** real-time; exports PNG/TGA/EXR image sequences and flipbooks plus VDB. Its passes include motion vectors, normals, depth, emission and "six point" lighting [11][26].
- **Houdini:** the Labs Flipbook Textures ROP (MDC) renders through the viewport from a Pyro Bake Volume; the frame-grid size × resolution per frame gives the sheet size [10][27].
- **Blender Mantaflow:** render the sequence, then pack it. No sim loops out of the box, so loop in the sequence editor or an editor by cross-fading [28].
- **Photoshop/Krita/After Effects:** hand-painted or footage-based sheets.

**Layout [2][29]:**

- Use powers of two for grid counts and sheet sizes, with aspect ratios between 8:1 and 1:8.
- 2048² at 8×8 gives 64 frames of 256 px. Going to 512 px per frame for 64 frames needs an 8K×4K sheet, which people on realtimevfx call unworkable [30].
- Crop frames tightly to reduce overdraw, but fade alpha near the card edges.
- Retime long sims; one example squeezes a 150-frame explosion into 32 frames with non-linear remapping.
- Name sheets `_NxM`.
- Don't bake directional light into albedo; bake only self-occlusion [2].

**Frame rate.** About 15 fps playback of an 8×8 sheet worked for Blender explosions on Roblox (snippet [28]). Interpolation makes lower counts viable.

### 2.8 Motion vectors for flipbook interpolation

- **Encoding.** The tool writes per-pixel screen-space displacement between frame N and N+1 into RG, centred on 0.5.
- **Shader** [17][18]:
  1. Sample the current frame at `uv − mv·t·s` and the next frame at `uv_next + mv·(1−t)·s`, where `t` is the sub-frame fraction.
  2. Lerp the two samples by `t`.
- **Strength.** The Godot shader defaults `flow_strength = 0.015` in atlas UV units [17]. Houdini suggests strength ≈ 1/FPS [18].
- **Gotchas:**
  - Import as linear. If the zero point is off-centre, the whole image "swims away diagonally" [18].
  - Vectors exist only inside the silhouette, so blending works only where frames overlap [18].
  - EmberGen vectors appear normalised; Unity users had to drop the scale to about 0.015 to stop flicker [26].
  - EmberGen had a smooth-loop first-frame bug and, in v1.0.5, swapped light channels; verify your export [10][26].
- **Generators:** EmberGen, Houdini Labs, TFlow (Tuatara), Slate Editor (FacedownFX, optical flow) [2][3].
- **Payoff:** 121 to 32 frames in the UE5 example [10]. Unreal also ships a "Flipbook Motion Vectors" material function.

### 2.9 Lighting smoke: normals vs 4-way vs 6-way

**Baked gradient.** Diablo 3 hand-painted a lit-to-shadow gradient into the smoke and couldn't rotate the sprites much, because the shadow had to stay on the bottom. JangaFX modernised it by rotating the gradient toward the sun per level [9].

**Spherical normals.** Bend the quad's normal into a hemisphere. This is cheap and gives a "ball" response. It is standard in Unreal ("Generate Spherical Particle Normals") and Unity, and was used in the Godot fake-depth smoke [19][31].

**Normal-mapped flipbook.** Bake normals from the sim (EmberGen, or CrazyBump/xNormal from greyscale). It works for direct light but can't express internal shadowing. Shuriken needs tangent streams added manually; many shipped games skip it because of texture cost [31].

**4-way (Skull & Bones, Ubisoft)** [15]:

- Two 1K maps, 8×8 at 128 px:
  - Mask1 (uncompressed): RGB = top/left/right, A = bottom.
  - Mask2 (DXT1): R = heat/emissive key, G = alpha.
- Front and back are approximated with a power curve plus saturate.
- The shader picks positive or negative sides by the sign of each tangent-space light component and weights by the squared components.
- Lighting runs per vertex: `lightColor·lightmap + ambient`.
- The whole set is about 8 MB.
- You can't pack top and bottom into one channel, because these are shadows, not normals.

**6-way (Unity VFX Graph)** [3][32]:

- Six directional renders in two RGBA maps (layout in 2.5).
- Supports directional, point, spot and area lights, plus probes evaluated per vertex.
- Colour comes from per-channel absorption or a simple multiply. Smoke is treated as fully diffuse, with no specular.
- Limits: still a flat card (most visible when it receives shadows), with no occlusion between particles.
- Tools: a Houdini HDA (OpenGL or Karma), a Blender add-on (`unity_6way.py`) and EmberGen's "Six point" render (unofficial; no light-intensity control). Motion vectors cut frame counts.

### 2.10 Resolution budgets (analysis, anchored on [2][10][15][29][30])

| Asset | Typical size |
|---|---|
| Tileable noise / distortion | 256–512 (1024 only for close hero shots) |
| Erosion / shape mask | 128–512 |
| Gradient ramp | 256×1 or 128×16 (Skull & Bones) |
| Smoke flipbook | 1K–2K sheet, 64 frames → 128–256 px/frame |
| Hero explosion | 2K–4K sheet, 32–64 frames plus motion vectors |
| Lightmaps (4/6-way) | same as the colour sheet; they are the colour sheet |

Mobile teams typically halve these. Prefer more frames with motion vectors at a lower count over a bigger sheet.

### 2.11 HDR colour for bloom

- Emissive is lighting data in [0, ∞), unlike albedo, which is capped at 1 [21].
- Bloom runs before tonemapping, on luminance (Rec.709 weights). `#FF00FF` at 100 nits does not bloom against a 99-nit threshold [21].
- Aim emissive about 2–10× above the threshold [22]. Tonemappers desaturate very bright values toward white, which is usually desirable for fire cores and bad for saturated magic [22].
- Practical method (analysis):
  - author hue in LDR first, then multiply energy;
  - keep the core in the ramp at about 4–16× and the edges at about 1×;
  - give saturated blue and purple extra energy;
  - avoid isolated single-pixel super-bright sparks, which cause bloom fireflies [22].

---

## 3. Examples

- **Diablo 3 (Blizzard, Julian Love, GDC 2013):**
  - layered self-multiplied noise at octave scales with "scale by mids";
  - per-particle random scroll;
  - hand-painted lit gradients for smoke;
  - blend-add (premultiplied) so emissive spells pop without a white-out from pure additive;
  - clamp tiling on Tyrael's wings.
  - It works because one noise texture and a few particles read as rich, morphing energy [9][33].
- **League of Legends (Riot):**
  - erosion keyed to a fraction of trail lifetime;
  - UV scroll speed keyed over life;
  - two counter-panned copies of one texture, multiplied, for caustics;
  - gradient-mapped greyscale textures.
  - The style guide prioritises gameplay clarity over spectacle [13][14].
- **Skull & Bones (Ubisoft):** relightable 4-way smoke and fire, with one flipbook reused across the game through ramps. About 8 MB for the whole set [15].
- **Unity 6-way demos:** the same smoke sheet lit by sun, sky and dynamic point lights, including backlit rim glow that normal maps can't produce [3].
- **UE5 explosion (Lorenzo HS):** EmberGen flipbook with motion vectors, blackbody-tinted emissive, and TLRB light. Frames dropped from 121 to 32 [10].
- **Fallout 4 / Gears of War 3:** thresholded alpha for animated earth, and an alpha threshold increasing over particle life for slime and blood [5].
- **Strike Vector EX:** dithered erosion on opaque explosion meshes, so the camera can fly through without overdraw [1].
- **Godot "fake depth" smoke:** billboards with spherical normals, a normal map derived from the noise, proximity fade, and a single density slider [19].

---

## 4. Common mistakes

1. **Importing data textures as sRGB** (erosion, noise, flowmaps, motion vectors). The erosion accelerates, and distortion drifts diagonally because 0.5 is no longer zero [1][2][18].
2. **Using an alpha fade where erosion belongs.** A uniformly ghosting fireball looks cheap, so erode it.
3. **Leaving the soft erosion range unremapped.** The effect never fully vanishes, leaving a faint residue at t = 1 [1].
4. **Using partial-range or blob-heavy noise.** Black voids "pan" instead of morph; fix it with full range and more mid-greys [9][20].
5. **Using non-octave tiling scales or very different pan speeds.** These cause visible phasing and two sliding layers [9].
6. **Multiplying the mask instead of the noise by 2.** Alpha blows out [9].
7. **Packing unrelated maps together.** Mixed resolutions or tiling waste memory, and a noisy mask in RGB causes BC artifacts [2].
8. **Baking directional light into flipbook colour.** The smoke can't respond to the scene [2].
9. **Over-cropping flipbook frames, or using distinctive shapes in looping sheets.** This gives seams and temporal repetition [2].
10. **Using too much motion-vector strength, or vectors outside the silhouette.** This causes smearing and ghost edges. Start at 1/FPS [18].
11. **Pure additive everywhere.** Overlapping spells sum to white; use premultiplied or blend-add [9].
12. **Pushing saturated blue to very high values.** It becomes white without blooming, or never blooms because of low luminance. Tune hue, energy and threshold together [21][22].
13. **Leaving quads without depth fade.** A hard line cuts through the floor.

---

## 5. Apply in Godot 4 (4.7, Forward+, AgX, glow on)

### 5.1 Import and sampler rules

- **Godot converts sRGB only where the sampler uniform has `source_color`.**
  - Erosion, noise, flow and motion-vector textures: no hint, or `hint_default_white`/`hint_default_black`. Godot reads them raw, which is correct.
  - Albedo and ramps: use `source_color`.
- **Compression:**
  - Import tileable noise and masks as VRAM Compressed. Tick `compress/high_quality` to get BC7 on desktop, which avoids DXT cross-channel artifacts in packed masks.
  - Import small ramps as Lossless, with `repeat_disable`.
- **Flowmaps and motion vectors:** don't use the "normal map" import. It renormalises vectors and uses RG-only compression, which can break 0.5-centring. Use Lossless or BC7 high quality.
- **Ramps:** a `GradientTexture1D` with `use_hdr = true` gives an editor-authored HDR ramp directly (width 256).
- **Tileable noise:** `NoiseTexture2D` with `seamless = true`, `normalize = true` (full 0–1 range) and FastNoiseLite Cellular/Perlin. For shipping, save it as a PNG so it isn't regenerated at load (analysis).

### 5.2 One master billboard shader: erosion, distortion, ramp, depth fade, HDR

A drop-in for Unsent's flame, smoke and burn materials. Pair it with GPUParticles3D and a ParticleProcessMaterial. The particle's `COLOR.a` drives erosion; set it with ParticleProcessMaterial's `color_ramp`, alpha 1 → 0.

```glsl
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D shape_tex : hint_default_white, filter_linear_mipmap;          // erosion mask (linear)
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable; // tileable noise
uniform sampler2D ramp : source_color, filter_linear, repeat_disable;              // GradientTexture1D, use_hdr
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

uniform vec2  pan_speed = vec2(0.0, -0.35);
uniform vec2  distort_pan = vec2(0.05, -0.2);
uniform float distort_amount : hint_range(0.0, 0.2) = 0.06;
uniform float feather : hint_range(0.001, 0.5) = 0.08;
uniform float edge_width : hint_range(0.0, 0.2) = 0.04;
uniform float emission_energy = 6.0;     // > glow threshold
uniform float fade_distance = 0.4;       // metres, soft-particle fade

varying float v_seed;

void vertex() {
    // Camera-facing billboard that keeps per-particle scale (same idea as StandardMaterial3D "Particle Billboard")
    mat4 mv = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
    MODELVIEW_MATRIX = mv * mat4(vec4(length(MODEL_MATRIX[0].xyz),0,0,0), vec4(0,length(MODEL_MATRIX[1].xyz),0,0), vec4(0,0,length(MODEL_MATRIX[2].xyz),0), vec4(0,0,0,1));
    v_seed = fract(INSTANCE_CUSTOM.x * 0.159 + float(INSTANCE_ID) * 0.618); // per-particle offset
}

void fragment() {
    vec2 seed_off = vec2(v_seed, fract(v_seed * 7.13));
    // UV distortion: remap 0..1 -> -1..1, small amount
    vec2 d = texture(noise_tex, UV * 0.75 + TIME * distort_pan + seed_off).rg * 2.0 - 1.0;
    vec2 uv = UV + d * distort_amount;

    // Two octaves of the same noise, multiplied (Diablo-style), constrained around mid-grey
    float n1 = texture(noise_tex, uv * 1.0 + TIME * pan_speed + seed_off).r;
    float n2 = texture(noise_tex, uv * 2.0 + TIME * pan_speed * 1.37 + seed_off.yx).r;
    float n = clamp(n1 * n2 * 2.0, 0.0, 1.0);

    float m = texture(shape_tex, uv).r * mix(0.6, 1.0, n);   // shape x noise

    // Alpha erosion driven by particle alpha, remapped for feather
    float t = mix(-feather, 1.0 + feather, 1.0 - COLOR.a);
    float a = smoothstep(t - feather, t + feather, m);
    float edge = smoothstep(t, t + edge_width, m) - smoothstep(t + edge_width, t + 2.0 * edge_width, m);

    // Gradient map (HDR ramp) + hot edge
    vec3 col = texture(ramp, vec2(clamp(m, 0.0, 1.0), 0.5)).rgb;
    col += edge * texture(ramp, vec2(1.0, 0.5)).rgb;

    // Depth fade (soft particles). Godot 4.3+ uses reversed-Z; NDC z is raw depth.
    float raw = texture(depth_tex, SCREEN_UV).r;
    vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, raw, 1.0);
    float scene_z = -view.z / view.w;
    float soft = clamp((scene_z - (-VERTEX.z)) / fade_distance, 0.0, 1.0);

    ALBEDO = col * COLOR.rgb * emission_energy;
    ALPHA = a * soft;
}
```

Notes:

- For pure fire, switch to `blend_add` or use premultiplied output. `blend_premul_alpha` exists in Godot 4: output `ALBEDO * ALPHA` and lower ALPHA on the glowing parts to get Diablo-style blend-add.
- For hard-edged burn decals or the leaf burn, use an opaque material with `ALPHA_SCISSOR_THRESHOLD` (or `step`) instead of blending. That gives no sorting or overdraw cost, and `edge` still drives an emissive rim through `EMISSION`.
- For radial effects (shockwave, portal), replace `UV` with polar UVs: `vec2 c = UV*2.0-1.0; vec2 p = vec2(atan(c.y,c.x)/TAU+0.5, length(c));`, then pan `p.x` to spin or `p.y` to expand.
- Fresnel on mesh VFX (shields, auras): `float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);`. Multiply it into ALPHA or emission.
- Vertex offset on meshes: `VERTEX += NORMAL * (texture(noise_tex, UV + TIME*0.2).r * 2.0 - 1.0) * amount;`. Use `textureLod(..., 0.0)` in `vertex()`.

### 5.3 Particle data plumbing

- `ParticleProcessMaterial` fills `CUSTOM`, which the draw material sees as `INSTANCE_CUSTOM` in `vertex()`; pass it to the fragment stage via `varying`.
- In practice the slots are (analysis, from Godot's generated StandardMaterial3D code [17][34]):
  - `.x` = rotation angle;
  - `.y` = lifetime phase (0→1);
  - `.z` = normalised animation frame (driven by `anim_speed_*` / `anim_offset_*`).
- Drive erosion from `COLOR.a` (`color_ramp`) or from `INSTANCE_CUSTOM.y` through a curve texture.
- In a custom `shader_type particles` shader (Unsent's leaves), write extra values into `CUSTOM.w`, for example a per-leaf burn seed. Sub-emitters receive data through `emit_subparticle(..., FLAG_EMIT_CUSTOM)`.

### 5.4 Flipbook with motion-vector interpolation

Add this to a particle material. Set `particles_anim_*` to match the sheet, and give ParticleProcessMaterial an `anim_speed` so `.z` advances.

```glsl
uniform int h_frames = 8;
uniform int v_frames = 8;
uniform sampler2D flip_tex : source_color, filter_linear_mipmap;
uniform sampler2D mv_tex : filter_linear_mipmap;      // RG motion vectors, LINEAR, not normal-map import
uniform float mv_strength = 0.015;                    // start ~1/bake_fps x cell size, tune by eye
varying vec2 uv_a; varying vec2 uv_b; varying float blend;

void vertex() {
    float total = float(h_frames * v_frames);
    float f = INSTANCE_CUSTOM.z * total;
    float fa = mod(floor(f), total);
    float fb = mod(fa + 1.0, total);
    blend = fract(f);
    vec2 cell = 1.0 / vec2(float(h_frames), float(v_frames));
    uv_a = (UV + vec2(mod(fa, float(h_frames)), floor(fa / float(h_frames)))) * cell;
    uv_b = (UV + vec2(mod(fb, float(h_frames)), floor(fb / float(h_frames)))) * cell;
}

void fragment() {
    vec2 mva = texture(mv_tex, uv_a).rg * 2.0 - 1.0;
    vec2 mvb = texture(mv_tex, uv_b).rg * 2.0 - 1.0;
    vec4 a = texture(flip_tex, uv_a - mva * blend * mv_strength);
    vec4 b = texture(flip_tex, uv_b + mvb * (1.0 - blend) * mv_strength);
    vec4 c = mix(a, b, blend);
    ALBEDO = c.rgb * COLOR.rgb;
    ALPHA = c.a * COLOR.a;
}
```

If the image drifts diagonally at high strength, the texture is being read as sRGB or the export isn't 0.5-centred [18]. If particles use random lifetimes, check that the frame stays continuous; a commenter reported needing `fract(INSTANCE_CUSTOM.z * total)` for `blend` [17].

### 5.5 6-way (or 4-way) lit smoke in Godot

There is no built-in output, but a `light()` function does it.

- **The key fact:** in Godot, `LIGHT` in `light()` is in **view space**. For a camera-facing billboard, view-space +X/+Y/+Z are exactly the card's right, up and toward-camera axes. If the card rotates, rotate `LIGHT.xy` by −angle.

```glsl
uniform sampler2D lm_pos : filter_linear_mipmap;  // R=right G=top B=back(toward camera? match your bake) A=alpha
uniform sampler2D lm_neg : filter_linear_mipmap;  // R=left G=bottom B=front A=emissive
void light() {
    vec3 l = LIGHT;                       // view space, unit, toward light
    vec3 wp = max(l, 0.0); wp *= wp;      // squared weights (Skull & Bones / Unity style)
    vec3 wn = max(-l, 0.0); wn *= wn;
    vec3 p = texture(lm_pos, UV).rgb;     // UV here = flipbook UV if computed in vertex()
    vec3 n = texture(lm_neg, UV).rgb;
    float lit = dot(p, wp) + dot(n, wn);
    DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * lit * ALBEDO / PI;
}
```

- Use `render_mode blend_mix, depth_draw_never` and keep the material lit, not `unshaded`. Ambient comes from the normal ambient path, so set a low `ALBEDO` and add ambient via `EMISSION`.
- Check your tool's channel order: Unity right/top/back versus left/bottom/front [3], EmberGen "Six point" [32], and the Blender `unity_6way.py` add-on.
- Cost scales with lights per particle. Keep the lights affecting smoke to the sun plus one or two OmniLights (analysis).
- **Cheaper alternative:** spherical normals. In `fragment()`, set `NORMAL = normalize(vec3(c.x, c.y, sqrt(max(0.0, 1.0 - dot(c,c)))))` with `c = UV*2.0-1.0`, which is already in view space. Optionally perturb it with a normal map from the noise, as in the Godot fake-depth smoke [19].

### 5.6 HDR and glow for Unsent's look

- WorldEnvironment glow:
  - `glow_hdr_threshold` about 1.0–1.5;
  - `glow_hdr_scale` 2;
  - blend mode Additive or Screen;
  - enable levels 3–5 for a soft, wide halo that suits a slow, melancholy mood.
- With AgX, very bright values desaturate toward white. Keep ember cores at 4–8× and leaf-burn edges at 2–4×, and push red/orange higher than you'd expect, since red has low luminance weight [21].
- Use the HDR `GradientTexture1D` ramp for the burn edge: dark red (0.6, 0.05, 0) → orange (3, 0.9, 0.1) → near white (8, 6, 3). This one ramp can be shared by the burn/dissolve shader, the noise-torn flame and the leaf flames so they match (analysis).
- Vefects Stylized Fire: leave its materials intact. If its glow intensity differs from your custom flames, match by adjusting your ramps, not their shaders.

---

## 6. Sources

1. VFX Documentation, "Alpha Erosion": https://vfxdoc.readthedocs.io/en/latest/shaders/alpha-erosion/
2. VFX Documentation, "Textures overview" (packing, compression, mips, sRGB): https://vfxdoc.readthedocs.io/en/latest/textures/overview/
3. Unity Blog, "Realistic smoke lighting with 6-way lighting in VFX Graph": https://unity.com/blog/engine-platform/realistic-smoke-with-6-way-lighting-in-vfx-graph
4. Simon Trümpler VFX Sketchbook (realtimevfx; UV distortion + alpha erosion; search snippet): https://realtimevfx.com/t/simon-trumpler-vfx-sketchbook/4177/375
5. Simon Trümpler, "Alpha1 Top 5" (Game Art Tricks): https://simonschreibt.de/gat/alpha1-top5/
6. realtimevfx, "Most common bread & butter shaders and materials techniques": https://realtimevfx.com/t/most-common-bread-butter-shaders-and-materials-techniques/19127
7. Harry Alisavakis, "My take on shaders: VFX Master Shader, Part II": https://halisavakis.com/my-take-on-shaders-vfx-master-shader-part-ii/
8. VFX Documentation, "Texture coordinates" (polar panning; snippet): https://vfxdoc.readthedocs.io/en/latest/shaders/texcoord/
9. JangaFX, "Exploring and Modernizing the VFX Methods of Diablo 3": https://jangafx.com/insights/diablo-3-vfx-experiments
10. Lorenzo HS, "Creating optimized, convincing explosions for Unreal Engine 5": https://loronsodev.github.io/posts/explosion-fx
11. JangaFX, EmberGen product page: https://jangafx.com/software/embergen
12. Riot Games, "Better Living Through Materials": https://www.riotgames.com/en/news/better-living-through-materials
13. realtimevfx, "Shannon Berke – LoL FX + Knowledge Share": https://realtimevfx.com/t/shannon-berke-lol-fx-knowledge-share/1133?page=6
14. Riot, "League's VFX Style Guide": https://nexus.leagueoflegends.com/en-us/2017/10/dev-leagues-vfx-style-guide/
15. realtimevfx, "Smoke Lighting and texture re-usability in Skull & Bones": https://realtimevfx.com/t/smoke-lighting-and-texture-re-usability-in-skull-bones/5339
16. Catlike Coding, "Texture Distortion" (flowmaps): https://catlikecoding.com/unity/tutorials/flow/texture-distortion/
17. godotshaders, "Particle Flipbook Flowmap Smoothing": https://godotshaders.com/shader/particle-flipbook-flowmap-smoothing/
18. Motion-vector notes: SideFX Labs Motion Vector shader docs https://sidefx.com/docs/houdini/nodes/shop/labs--motionvector_shader.html ; realtimevfx "UE4's Flipbook Motion Vector material function" https://realtimevfx.com/t/ue4s-flip-book-motion-vector-material-function-works-well-image-fixed/2807 ; Polycount "TFlow motion vector generator" https://polycount.com/discussion/228130/tflow-motion-vector-generator (snippets)
19. 80.lv, "Check out this Godot smoke VFX with fake depth": https://80.lv/articles/check-out-this-godot-smoke-vfx-with-fake-depth
20. Tyler Walters, texture "Consistency" thread (via Thread Reader): https://threadreaderapp.com/thread/1566521114914074625
21. Don McCurdy, "Emission and bloom": https://www.donmccurdy.com/2024/04/27/emission-and-bloom/
22. three.js forum, "I still don't get how UnrealBloomPass works" (snippet), plus Catlike Coding "HDR" (snippet): https://discourse.threejs.org/t/i-still-dont-get-how-unrealbloompass-works/57843/2 ; https://catlikecoding.com/unity/tutorials/custom-srp/hdr/
23. CG Channel, "Material Maker 1.5" / "Material Maker 1.0 is out" (snippets): https://www.cgchannel.com/2026/01/check-out-free-material-authoring-software-material-maker-1-5/ ; https://www.cgchannel.com/2022/07/open-source-material-authoring-tool-material-maker-1-0-is-out
24. 80.lv, "Creating mortar-covered bricks in Substance Designer" (snippet): https://80.lv/articles/creating-mortar-covered-bricks-in-substance-designer
25. OpenGameArt, "Noise texture pack" (snippet): https://opengameart.org/content/noise-texture-pack
26. JangaFX forums: "EmberGen + Unity Motion Vector Maps" https://forums.jangafx.com/t/embergen-unity-motion-vector-maps/276 ; "Motion vector export… 16-bit" https://forums.jangafx.com/t/embergen-feature-request-motion-vector-export-and-png-with-16-bit-color-depth/489 ; "Looping simulation motion vectors…first frame" https://forums.jangafx.com/t/embergen-looping-simulation-motion-vectors-are-messed-up-on-first-frame-when-generating-a-flipbook/521 (snippets)
27. SideFX, Labs Flipbook Textures ROP docs (snippet): https://www.sidefx.com/docs/houdini/nodes/out/labs--flipbook_textures-1.0.html
28. Blender Artists, "Looping smoke sim as in Fallout 4", and Roblox DevForum "2 Free Realistic Flipbook Particle Explosions" (snippets): https://blenderartists.org/t/looping-smoke-sim-as-in-fallout-4/659984 ; https://devforum.roblox.com/t/2-free-realistic-flipbook-particle-explosions/3035597
29. VFX Documentation, "Flipbooks and Texture Sheets": https://vfxdoc.readthedocs.io/en/latest/textures/flipbooks/
30. realtimevfx, "Embergen resolution issue" (snippet): https://realtimevfx.com/t/embergen-resolution-issue/14270
31. realtimevfx, "Niagara UE5 Smoke Texture and Normal maps" and "Unity Shuriken Custom Light Setup" (snippets): https://realtimevfx.com/t/niagara-ue5-smoke-texture-and-normal-maps/22227 ; https://realtimevfx.com/t/unity-shuriken-custom-light-setup/24919
32. Unity VFX Graph manual, "Six-way lighting" / "Use tools to generate six-way lightmap textures": https://docs.unity3d.com/Packages/com.unity.visualeffectgraph@17.6/manual/six-way-lighting.html ; https://docs.unity3d.com/Packages/com.unity.visualeffectgraph@17.4/manual/use-tools-generate-six-way-lightmap-textures.html
33. GDC Vault, Julian Love, "Technical Artist Bootcamp: The VFX of Diablo" (GDC 2013), and Simon Trümpler, "Diablo 3 – Wings of Angels": https://gdcvault.com/play/1017660 ; https://simonschreibt.de/gat/diablo-3-wings-of-angels/
34. Godot docs, "Particle shaders" reference, and "Advanced post-processing" (depth texture, reversed-Z): https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/particle_shader.html ; https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html
