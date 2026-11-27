# 06 — Atmosphere: Fog, Volumetrics, God Rays, Aerial Perspective, Particles

*Research for Unsent. Engine: Godot 4.7 Forward+ with volumetric fog on (density 0.011, low sky affect), GPUParticles3D and a custom sky shader. Target: `reference_target.webp`, a snowy house at night.*

---

## 1. Takeaways

1. **Fog is a compositional tool before it is a physical one.** Every game studied here uses fog to decide what the player sees and what they don't. Silent Hill hides the town, Inside uses depth fog to flatten the background into mood, and Hollow Knight and Ori fade parallax layers with depth. Physics is the starting point, and the final look is art-directed.
2. **Use two fog systems, not one.** Volumetric (froxel) fog is short-range and lit, so it gives shafts, halos and local haze. Analytic height or depth fog is long-range and cheap, so it gives the fade to black-blue at the horizon. Godot's docs recommend pairing them because volumetric fog has a finite range. Death Stranding's Decima fog and Frostbite both combine a physically based base layer with an analytic, artist-controlled layer.
3. **God rays need three things together: a bright source, an occluder with gaps, and a medium.** In the reference, those are the moon, the pine branches and cloud edges, and the haze. Raising fog density everywhere won't make shafts. You need *local* density where the occluder is, and *contrast*, meaning dark fog everywhere else.
4. **Aerial perspective at night runs toward dark blue, not light grey.** In daylight, distance lightens and desaturates. Under moonlight, distant pines should sink toward the fog/sky colour, a deep desaturated blue. Each layer back should be one value step closer to that colour, with softer edges.
5. **Particles carry the emotion and the scale.** Snow density sets the weather mood. Embers or fireflies give the eye a warm path through a cold scene. Lit dust motes inside a light shaft make the shaft feel like air.
6. **Cheat freely where the camera is predictable.** Unsent's opening has an authored camera, so shaft cards, painted fog planes and hand-placed fog volumes are as valid as Inside's hand-placed lighting decals.
7. **Performance is spent on screen coverage, not node count.** Godot fog volumes cost in proportion to screen size and material complexity, and particles cost in proportion to overdraw. Keep volumes small, keep particle quads small, and set `volumetric_fog_energy` to 0 on lights that don't need it.

---

## 2. Techniques

### 2.1 Height fog vs volumetric fog

- **Analytic or height fog.** A closed-form function of distance and height is evaluated per pixel. It is very cheap and has infinite range, but it has no light shafts or local shadowing. In Godot it is the classic `fog_*` group on `Environment`: exponential or depth mode, `fog_height`/`fog_height_density`, `fog_sun_scatter` and `fog_aerial_perspective`, which blends fog colour toward the sky. Death Stranding's SIGGRAPH 2017 system put an "analytic height fog" layer on top of a precomputed scattering LUT, specifically so artists could get dense and coloured fog that physics alone wouldn't give.
- **Volumetric (froxel) fog.** Bart Wronski's SIGGRAPH 2014 talk for Assassin's Creed IV introduced the method most engines use today. A 3D texture is aligned to the camera frustum (a "froxel" grid). Compute shaders inject density and lighting into each cell, then integrate along depth. Meshes and transparents just sample the result. Hillaire's Frostbite talk (SIGGRAPH 2015) extended it to a unified, physically parameterised system, with particles voxelised into the volume and volumetric shadow maps. The Last of Us Part II built its own froxel system and focused on blending with glass and particles and on fixing grid artifacts. Godot's implementation follows Wronski's approach, with a 64×64×64 default grid and slices that grow with distance.
- **Practical difference.** Volumetric fog gives shafts, light halos and shadows in the air, but it is limited in range and resolution, so thin features flicker and dense fog bands. Height fog gives scale and the horizon fade. Use both.

### 2.2 Fog colour tied to sky and moon

- Fog should look as if it were lit by the same sky the player sees. Godot exposes this through `fog_aerial_perspective`, which samples the sky's radiance for fog colour, and through `volumetric_fog_ambient_inject`, which lets ambient or sky light tint the volumetric fog.
- On a moonlit night, the fog's albedo sets how it scatters *direct* moonlight, so a near-white albedo gives silvery shafts. Its emission sets the *floor* brightness of the fog, its colour in shadow. Keep emission very dark blue so shadowed fog reads as "night air" rather than black.
- Match the fog's far colour to the sky shader's horizon colour. If the sky horizon is #121a2b, the distant fog must converge to that value, or the treeline will show a seam. With a custom sky shader, keep the horizon colour as a uniform shared by a script that also drives `Environment.fog_light_color`.
- Anisotropy, Godot's Henyey–Greenstein `g`, controls how strongly fog lights up when you look toward the moon. Forward scattering of 0.5–0.8 makes the area around the moon bloom and makes shafts read when the camera faces the light. That is the reference's top-left composition.

### 2.3 Depth layering with fog

Gurney's value-and-distance analysis puts it concretely: nearby darks lighten fastest as they recede, and distant planes bunch together in value. Painters exaggerate this, pushing distance cooler, lighter (by day) and less saturated than measured. For games:

- **Foreground** is a near silhouette: the fence and the framing branch top-left. It is the darkest or most contrasted, can be slightly out of focus, and has almost no fog.
- **Midground** is the house, lamp and mailbox, where all the warm accents live. Fog is light and the full value range is used.
- **Background** is two or three rows of pines. Each row adds fog, loses contrast, shifts toward the fog colour, and has its snow highlights dimmed.
- **Infinity** is the sky and fog colour. The last pine row should be only slightly darker than it.

Hollow Knight and Silksong do this with literal stacked layers. Silksong is built in 3D, with many 2D layers offset in Z so parallax and fog-by-depth work together. Ori's team used a custom fog with colour and transparency blended over depth on a custom curve rather than a linear one. Ori's *Making Of* notes that a light touch of fog behind the gameplay layer was added purely for readability. Limbo and Inside take it to the extreme: monochrome layers, with depth fog as the main tool. The Inside GDC talk notes that the team clamps fog so very bright lights still punch through it.

### 2.4 God rays and crepuscular rays

| Approach | How | Pros | Cons |
|---|---|---|---|
| **Screen-space radial blur** (Mitchell, GPU Gems 3) | Render occluders black and the light white, then blur radially toward the light's screen position, with exposure/weight/decay controls, and add the result | Cheap, works at any density, very "cinematic" | Fades out when the light source leaves the screen; only on-screen occluders count; no shafts seen from the side |
| **Volumetric (froxel) shafts** | A shadowed light scatters in the fog grid | Correct from any angle, interacts with fog volumes, no setup | Low-res, so thin branches blur out; needs density; cost; temporal ghosting |
| **Shaft cards / cones** | An additive mesh (plane or cone) with fresnel edge-fade, a length gradient and scrolling noise | Total art control, near-zero cost, crisp | Breaks if the camera walks through or orbits; doesn't occlude; must be placed by hand |
| **Painted into sky or matte** | Rays baked into the sky texture or a backdrop card | Free | Static |

Card best practice comes from Unreal forum threads and the Godot "Fake Godrays" shader. Use an additive blend and fade alpha by fresnel so silhouette edges vanish. Fade along the beam with a gradient, and add a depth fade where the card meets geometry. Scroll a noise texture to suggest drifting dust, and fade the card out as the camera gets close. Several posters note that cards fall apart once the player can walk into the beam, and that's when you switch to real volumetrics.

### 2.5 Light shafts through trees

- Shafts need *gaps*. A solid pine canopy casts uniform shadow and gives no shafts. Alpha-cut branch cards with real holes, plus a moon at a low-to-mid elevation, give striping.
- Froxel resolution (Godot's default is 64 slices wide) can't resolve needle-scale gaps at distance. Shafts from trees work best when the trees are *near* the camera, where froxels are small. Raising `volumetric_fog_detail_spread` puts more slices near the camera, and lowering `volumetric_fog_length` concentrates the resolution.
- A light cookie or projector texture (Inside added cookies late in development to fake richer shadowing) can add branch-pattern striping to a SpotLight without needing real geometry gaps.
- Hybrid is common. Real volumetric fog gives the soft glow and broad shafts, and a couple of hand-placed cards add the crisp hero rays the reference shows.

### 2.6 Particles that sell mood

- **Snowfall density.** Light, sparse snow reads as quiet and nostalgic. Dense snow plus wind reads as hostile. Big slow flakes near the camera and tiny fast ones far away fake depth. Ghost of Tsushima's lesson is that a *single camera-following emitter* driven by biome or wind data replaced "hundreds" of placed systems, and that everything shares one wind. Its leaves, pollen and ash all sample a global wind field built from "vorticles", invisible wind-generating particles. Rockenbeck's GDC 2021 talk stresses choosing volume over accuracy.
- **Lit flakes.** Flakes only "sparkle" where light hits them. Make them unshaded and white-blue, with brightness modulated by distance to the lamp or moon-shaft. Or make them shaded so they pick up the warm lamp. The reference's flakes glow in the moon shaft and near the lamp and vanish in the dark, and that selective visibility is the effect.
- **Embers and fireflies.** These are warm, emissive, small and few (tens, not thousands). They rise or wander with turbulence and flicker via colour-ramp alpha. Their job is compositional: a warm trail that leads the eye from the door to the right-hand pines.
- **Dust motes.** These sit only inside shaft volumes, slow and with large size variance. They make a shaft read as air.
- **Breath.** A short-lifetime, soft, alpha-blended sprite puff from the mouth is spawned on a breathing timer. It's a cheap cue that it's cold, and it's lit by nearby lights.

### 2.7 Art-directed vs physically correct

- Frostbite's own abstract says particles and post-process fog have been used as workarounds for real participating media. Studios that go physically based (Frostbite, Hillaire's sky) still expose artist controls on top.
- Death Stranding added an analytic artist layer because the physical atmosphere couldn't produce the dense or coloured fog the art wanted, and it changed fog by story beat.
- Alan Wake 2's Northlight team describes pipelines that give finer control over *where* fog is placed in the world. That is authored fog, not simulated weather.
- RDR2's clouds and fog are driven by a world weather map, but per Bauer's SIGGRAPH 2019 talk (via secondary summaries), artists also hand-placed fog concentrations.
- Inside lit scenes almost entirely with hand-placed decals and effects for a painterly, "targeted" fidelity. It used no automated GI.
- Silent Hill's fog may have started as a draw-distance limit, and it became the identity. Masahiro Ito criticised the HD Collection for thinning it.

### 2.8 Performance trade-offs

- **Godot volumetric fog.** The cost is the froxel grid (`volume_size`, `volume_depth`), the number of lights with non-zero `volumetric_fog_energy`, GI and ambient inject (small cost each), and FogVolume screen coverage and material complexity. A 3D density texture should be 64³ or smaller. Thin volumes flicker unless you raise `volume_depth` or shorten `volumetric_fog_length`. Temporal reprojection ghosts behind moving lights.
- **Banding.** Dense fog bands, so keep it moderate and rely on debanding (Godot's `rendering/anti_aliasing/quality/use_debanding`) or dithering.
- **Particles.** Overdraw matters far more than count. A few hundred tiny flakes are cheap, while a dozen huge alpha-blended fog sprites filling the screen are not. Set `visibility_aabb` tightly and use `fixed_fps` for distant or cheap systems.
- **Shaft cards** are almost free, apart from additive overdraw where they overlap.
- **Remasters and settings.** Alan Wake 2's Low and Medium presets primarily cut volumetric density, so plan a "low" fog preset early.

---

## 3. Game examples

- **Red Dead Redemption 2.** A world-scale cloud map, two density layers updated by weather and time of day, raymarched volumetrics near the camera, and cheaper rays far away. Volumetric fog and light-shaft generation get their own downsampled-depth pass. Bloom is increased in distant fog so lights glow through haze. The lesson is that glow in the distance sells wetness and cold air.
- **The Last of Us Part II.** A custom froxel volumetric system whose main challenge was making glass, particles and fog agree. Fog has to tint transparents the same way it tints opaques, or snow and embers will float "outside" the air.
- **God of War (2018).** Sony Santa Monica's indirect lighting pipeline used a unified volume-texture approach that extended to volumetric effects, so fog is lit by the same irradiance as surfaces. The forests use heavy forward-scattered shafts through canopy as wayfinding toward the light.
- **Inside.** Linear depth fog alone already made the scene moody. Fog intensity is capped so bright sources pierce it. Local shadowed volumetrics are used for hero beams such as flashlights and windows. Lighting is hand-placed throughout.
- **Limbo.** Monochrome, with depth expressed entirely through fog and blur by layer. The background layers lose all detail into grey.
- **Journey.** Nava credits the atmosphere to light, fog and wind together. Fog is coloured by the time of day of each chapter, and wind-blown sand and cloth particles make the air visible.
- **Ghost of Tsushima.** One global wind drives grass, trees, cloth, smoke and tens of thousands of leaves. A biome map feeds one camera-following ambient emitter. Wind-direction particles double as navigation (the "Guiding Wind"), so particles carry gameplay as well as mood.
- **Alan Wake 2.** Transparency is rendered at multiple resolutions with MBOIT so fog, effects and transparent geometry blend correctly. Fog placement is hand-authored, and the PS5 Pro update improved fog and volumetric stability.
- **Silent Hill (1, 2, and the 2024 remake).** Fog is both a limit and the identity: you hear monsters before you see them. Removing the fog, as the HD Collection and fog-removal mods do, kills the dread.
- **Death Stranding.** Precomputed scattering plus an analytic height-fog layer for artist control, dynamic per mission and mood.
- **Ori and the Blind Forest.** Every asset was hand-lit, with custom depth fog (colour plus transparency on a curve) and layered painterly depth. A light touch of fog was added behind the gameplay layer for readability.
- **Hollow Knight and Silksong.** Many 2D layers are placed in 3D for parallax, fog and blur increase by layer, and two or more foreground layers frame the scene. This is the same foreground/midground/background recipe Unsent needs.

---

## 4. Apply to Unsent's opening

**Goal from the reference:** moon top-left with cool shafts slanting down through the cloud edge and the top-left pine branch. Thin ground haze. Warm windows, door and lamp with soft halos. Lit snowflakes. Warm embers or butterflies drifting near the right-hand pines. Three or more pine rows dissolving into blue-black.

### 4.1 Environment: two fog layers

Keep volumetric fog for nearby lighting, and add classic fog for distance. Suggested starting values (tune by eye at the authored camera):

```
# WorldEnvironment > Environment
volumetric_fog_enabled            = true
volumetric_fog_density            = 0.011        # keep; local volumes add the rest
volumetric_fog_albedo             = Color(0.82, 0.87, 0.95)   # near-white, slightly cool
volumetric_fog_emission           = Color(0.020, 0.030, 0.055) # dark blue floor: fog in shadow
volumetric_fog_emission_energy    = 1.0
volumetric_fog_anisotropy         = 0.6          # forward scatter: halo/shafts toward moon
volumetric_fog_length             = 48.0         # scene is ~40 m deep; shorter = sharper shafts
volumetric_fog_detail_spread      = 2.5          # more slices near camera (branches, lamp)
volumetric_fog_ambient_inject     = 0.15         # let sky ambient tint fog slightly
volumetric_fog_gi_inject          = 0.0
volumetric_fog_sky_affect         = 0.1          # low, as now; sky shader owns the sky
volumetric_fog_temporal_reprojection_enabled = true
volumetric_fog_temporal_reprojection_amount  = 0.85   # drop to ~0.7 if embers' lights ghost

# Classic fog for beyond volumetric range (Godot 4.3+ fog_mode)
fog_enabled            = true
fog_mode               = FOG_MODE_EXPONENTIAL
fog_light_color        = Color(0.07, 0.09, 0.15)  # = sky shader horizon colour
fog_light_energy       = 1.0
fog_density            = 0.004
fog_sky_affect         = 0.0
fog_aerial_perspective = 0.3                      # pull far fog toward sky colour
fog_sun_scatter        = 0.0                      # moon glow handled volumetrically
fog_height             = 1.5
fog_height_density     = 0.15                     # thicker near ground, thins upward
```

Project settings: `rendering/environment/volumetric_fog/volume_size = 96` (up from 64, for crisper branch shafts; measure the cost) and `volume_depth = 96`, with `use_filter = true`. Fall back to 64/64 on the low preset. Enable `use_debanding`.

### 4.2 The moon and its shafts

**Option A: volumetric (primary).**
- `DirectionalLight3D` "Moon": colour `#AFC3E8` (cool, slightly desaturated), energy 0.35–0.5, shadows on, `directional_shadow_max_distance` ~40 m, `light_volumetric_fog_energy` = **3–5**. Fog energy is decoupled from surface energy, so you can boost shafts without over-lighting the snow. Aim it so its direction matches the moon's position in the sky shader. Drive both from one script.
- Shafts only appear where something occludes. Put the framing pine bough top-left close to the camera, as alpha-scissor branch cards with real gaps, and add a few cloud-edge occluder cards (shadow-only, `cast_shadow = SHADOW_CASTING_SETTING_SHADOWS_ONLY`) between the moon and the house.
- **Shaft FogVolume:** a `FogVolume`, shape Box or Cylinder, rotated to lie along the moon direction from the top-left pines down to the yard. Use a `FogMaterial` with density 0.03–0.05, albedo near white, `edge_fade` 0.5–0.8 and `height_falloff` 0. Shafts appear only inside this denser slab, which is exactly the reference's top-left wedge. Optionally add a `NoiseTexture3D` (32³, seamless) as `density_texture` for clumpy air.

**Option B: shaft cards (hero detail and fallback).** Add three to five thin `QuadMesh` or cone strips under the bough, using a spatial shader like the following.

```glsl
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec3 tint : source_color = vec3(0.62, 0.72, 0.95);
uniform float intensity = 0.25;
uniform sampler2D noise : repeat_enable;
uniform float scroll = 0.02;
uniform float near_fade = 3.0;       // fade as camera approaches
uniform sampler2D depth_tex : hint_depth_texture;
void fragment() {
    float along = smoothstep(0.0, 0.15, UV.y) * (1.0 - UV.y);     // soft ends
    float across = sin(UV.x * 3.14159);                           // soft sides
    float fres = pow(abs(dot(NORMAL, VIEW)), 1.5);                // edge-on fade
    float n = texture(noise, UV * vec2(1.0, 0.3) + vec2(0.0, TIME * scroll)).r;
    float scene_z = texture(depth_tex, SCREEN_UV).r;              // soft intersection
    vec4 ndc = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, scene_z, 1.0);
    float soft = clamp((-ndc.z / ndc.w) - (-VERTEX.z), 0.0, 1.0);
    float cam = clamp(-VERTEX.z / near_fade, 0.0, 1.0);
    ALBEDO = tint;
    ALPHA = along * across * fres * mix(0.6, 1.0, n) * soft * cam * intensity;
}
```

Keep intensity low (0.15–0.3). The cards should *sharpen* the volumetric shafts, not replace them. Since the opening camera is authored, the cards won't be seen edge-on.

**Avoid** screen-space radial blur here: the moon sits near the frame edge, and the effect dies when it leaves the frame.

### 4.3 Ground haze

- A `FogVolume`, Box, about 60 × 1.2 × 40 m, centred at y = 0.5. Use a `FogMaterial` with density 0.025, albedo `#C8D2E6`, `height_falloff` 1.5–2.5 (dense at the snow, gone by knee height) and `edge_fade` 1.0. Add a slow-scrolling `NoiseTexture3D` in a custom fog shader if it looks too uniform.
- Thin volumes flicker. If the haze shimmers while the camera moves, make the box taller and rely on `height_falloff` rather than a thin box.
- Add a **negative-density** box (density about −0.02) inside the house interior and porch, so the warm interior seen through the door stays crisp.

### 4.4 Warm lights in the fog

- Window and door `OmniLight3D`s: colour `#FFB36B`, `light_volumetric_fog_energy` 0.4–0.8, for a small warm halo in the haze that reads as cold air outside. Turn shadows off on most of them.
- Street lamp: `OmniLight3D` with energy about 2, range 6, shadows on (the fence-picket shadows in the reference are a hero detail), fog energy 1.0.
- Any minor fill lights get `light_volumetric_fog_energy = 0`, which also saves cost.

### 4.5 Depth layering of pines

- Place three pine rows at roughly 15 m, 25 m and 40 m, and make the last row a cheap billboard or impostor.
- Check the value ladder with a greyscale screenshot. Foreground fence and branch: darkest and sharpest. House: full range. Pine row 1: snow highlights at about 70%. Row 2: about 40%. Row 3: about 15%, almost the fog colour. If the rows don't separate, raise `fog_density` or add a large, low-density FogVolume (density 0.008, albedo matching the fog colour) covering only the back rows. Don't raise global density.
- Option: a far "fog card" plane between rows 2 and 3, an unshaded alpha gradient in the sky horizon colour. This is Hollow Knight's trick, and it's free.

### 4.6 Snow particles

Use one camera-attached `GPUParticles3D` (the Ghost of Tsushima approach) plus one near-field emitter for big flakes.

```
# Far/mid snow
amount = 1500, lifetime = 8.0, preprocess = 8.0, local_coords = false
visibility_aabb = AABB(-20,-6,-20, 40,16,40)
ParticleProcessMaterial:
  emission_shape = BOX, emission_box_extents = (18, 1, 18)  # positioned ~10 m above ground
  direction = (0.15, -1, 0), spread = 10
  initial_velocity_min/max = 0.6 / 1.0
  gravity = (0, -0.4, 0)
  damping_min/max = 0.2 / 0.4
  turbulence_enabled = true
  turbulence_noise_strength = 0.6, turbulence_noise_scale = 4.0, turbulence_noise_speed = (0.1,0,0.05)
  turbulence_influence_min/max = 0.05 / 0.15
  scale_min/max = 0.4 / 1.0                                # quad ~0.02 m
  collision_mode = HIDE_ON_CONTACT                          # with GPUParticlesCollisionHeightField3D
draw_pass_1 = QuadMesh 0.02 m, StandardMaterial3D:
  billboard_mode = BILLBOARD_PARTICLES, transparency = ALPHA, shading_mode = PER_PIXEL (shaded),
  albedo = #E8EEF8, soft round texture, roughness 1, emission off
```

- Keep the flakes **shaded**, so they glow warm near the lamp, silver in the moon shaft and vanish in shadow. That gives the reference's "lit snowflakes" for free.
- Near-field emitter: about 120 flakes, 0.05–0.08 m, slower (velocity 0.3–0.5). Spawn them only within 2–6 m of the camera, and optionally use slight motion-stretch or depth-of-field blur. They sell depth.
- **Mood dial:** sparse and quiet for the opening (as above). For tension, double `amount`, raise `direction.x` to 0.6 and turbulence strength to 1.5, and raise fog density to about 0.02.

### 4.7 Embers and butterflies (right-hand pines)

```
amount = 24–40, lifetime = 6.0, preprocess = 6.0
emission_shape = BOX, emission_box_extents = (3, 2, 2)  # around the right pines / from roofline
direction = (0.3, 1, 0), spread = 45
initial_velocity_min/max = 0.1 / 0.3, gravity = (0, 0.05, 0)  # slight lift
turbulence_enabled = true, turbulence_noise_strength = 1.2, turbulence_noise_scale = 1.5,
turbulence_influence_min/max = 0.3 / 0.6                       # wandering, firefly-like
scale_min/max = 0.6 / 1.2
color_ramp: 0.0 alpha 0 -> 0.15 #FFC06A a1 -> 0.7 #FF8A3A a1 -> 1.0 #FF5A1F a0
draw_pass_1 = QuadMesh 0.03 m, StandardMaterial3D: unshaded, blend ADD,
  albedo #FFB060, emission energy ~3 (feeds Glow), billboard PARTICLES
```

- For **butterflies**, use a two-frame flap flipbook (`particles_anim_h_frames = 2`, `anim_speed`) or a tiny mesh with a vertex-shader flap, plus a sub-emitter (`sub_emitter_mode = CONSTANT`, frequency about 20) trailing a few spark dots. That gives the reference's glittery trail from the roof edge.
- Enable `Environment.glow_enabled` with a threshold around 1.0, so only embers, lamp and windows bloom.
- Don't attach `OmniLight3D`s to individual embers. If you want a warm glow on the snow, use one shadowless omni that follows the swarm's centre, with `volumetric_fog_energy` 0.3.

### 4.8 Dust motes in the shaft and breath

- **Motes:** 60 particles, emission box matching the shaft FogVolume, velocity about 0.02, turbulence influence 0.05, size 0.01–0.03, unshaded additive `#BFD0F0` at low alpha. Spawn them only inside the shaft.
- **Breath** (if the character is on screen): a one-shot `GPUParticles3D` every 3–4 s, 6 particles, lifetime 1.2 s, velocity 0.4 forward, damping 1.0. Use a soft smoke texture, alpha blend, shaded, so the lamp lights it. Scale ramps from 0.05 to 0.3 and alpha fades from 0.25 to 0.

### 4.9 Colour palette summary

| Element | Colour |
|---|---|
| Sky horizon / far fog | `#121A2B` |
| Volumetric fog albedo | `#D1DEF2` |
| Volumetric fog emission (shadowed air) | `#05080E` |
| Moonlight | `#AFC3E8` |
| Shaft card tint | `#9EB8F2` |
| Ground haze albedo | `#C8D2E6` |
| Window / door / lamp | `#FFB36B` (lamp core `#FFD49A`) |
| Embers | `#FFC06A` → `#FF5A1F` |
| Snow albedo | `#E8EEF8` |

The rule is to keep only two temperatures: cool blue for the sky, moon, fog and snow, and warm amber for the house, lamp and embers. Fog should never be warm except inside the small light halos.

### 4.10 Performance budget (Forward+, mid GPU)

- Volumetric fog at 96³ with about 6 fog-affecting lights and 3–4 small FogVolumes should stay around 1–2 ms. Verify in the Godot profiler's GPU tab, and keep a 64³ preset as the fallback.
- Particles total under 2,000 small quads. Embers are cheap. Watch overdraw only if you add large smoke sprites.
- Shaft cards are effectively free. Prefer adding a card over raising froxel resolution.

---

## 5. Sources

1. Godot Docs, Volumetric fog and fog volumes (stable). https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html
2. Godot Docs, Volumetric fog (4.7). https://docs.godotengine.org/en/4.7/tutorials/3d/volumetric_fog.html
3. Godot Docs, FogVolume class. https://docs.godotengine.org/en/4.2/classes/class_fogvolume.html
4. Godot Docs, ParticleProcessMaterial. https://docs.godotengine.org/en/stable/classes/class_particleprocessmaterial.html
5. Godot blog, Fog Volumes arrive in Godot 4. https://godotengine.org/article/fog-volumes-arrive-in-godot-4
6. Godot Shaders, Fake Godrays (Godot 4.x). https://godotshaders.com/?p=9979
7. Godot Shaders, Screen Space God Rays (4.3). https://godotshaders.com/shader/screen-space-god-rays-godot-4-3/
8. Bramwell, Godot 4 Beginners: Volumetric Fog and God Rays. https://bramwell.itch.io/godot-4-beginners/devlog/588028/volumetric-fog-and-god-rays
9. Wronski, Volumetric Fog, SIGGRAPH 2014. https://www.advances.realtimerendering.com/s2014/wronski/bwronski_volumetric_fog_siggraph2014.pdf
10. Wronski, AC4 GDC 2014 deck. https://bartwronski.com/wp-content/uploads/2014/03/ac4_gdc.pdf
11. Hillaire / EA, Physically Based and Unified Volumetric Rendering in Frostbite. https://www.ea.com/news/physically-based-unified-volumetric-rendering-in-frostbite
12. Hillaire / EA, Physically Based Sky, Atmosphere and Cloud Rendering. https://www.ea.com/news/physically-based-sky-atmosphere-and-cloud-rendering
13. Hillaire, SIGGRAPH 2020 PBS slides. https://blog.selfshadow.com/publications/s2020-shading-course/hillaire/s2020_pbs_hillaire_slides.pdf
14. Mitchell, GPU Gems 3 ch. 13, Volumetric Light Scattering as a Post-Process. https://developer.nvidia.com/gpugems/gpugems3/part-ii-light-and-shadows/chapter-13-volumetric-light-scattering-post-process
15. Kovalovs, Volumetric Effects of The Last of Us Part Two (SIGGRAPH). https://history.siggraph.org/learning/volumetric-effects-of-the-last-of-us-part-two-by-kovalovs
16. RDR2 graphics study (imgeself). https://imgeself.github.io/posts/2020-06-19-graphics-study-rdr2
17. DTF, RDR2 visual effects (summary of Bauer SIGGRAPH 2019). https://dtf.ru/id17412/62607-kak-v-red-dead-redemption-2-ustroeny-vizualnye-effekty
18. Schneider, Nubis: Decima volumetric cloudscapes (SIGGRAPH 2017). https://advances.realtimerendering.com/s2017/Nubis%20-%20Authoring%20Realtime%20Volumetric%20Cloudscapes%20with%20the%20Decima%20Engine%20-%20Final%20.pdf
19. 80.lv, The Beautiful Fog of Death Stranding. https://80.lv/articles/the-beautiful-fog-of-death-stranding
20. DualShockers, Death Stranding fog system. https://www.dualshockers.com/death-stranding-fog-model-ps4/
21. Playdead, The Lighting of INSIDE. https://blog.playdead.com/articles/the_lighting_of_inside/lighting_of_inside.html
22. Game Developer, How Playdead rendered Inside (GDC video). https://gamedeveloper.com/programming/video-how-playdead-rendered-the-unique-visuals-of-i-inside-i-
23. 80.lv, The Rendering of INSIDE. https://80.lv/articles/the-rendering-of-inside-low-complexity-high-fidelity
24. GDC, Limbo devs share tips on striking visuals. https://gdconf.com/news/gdc_2016_limbo_devs_share_tips
25. 80.lv, Insights into Building VFX for Ghost of Tsushima. https://80.lv/articles/insights-into-building-vfx-for-ghost-of-tsushima/
26. PlayStation Blog, How stunning visual effects bring Ghost of Tsushima to life. https://blog.playstation.com/?p=345372
27. Game Developer, Using vorticles to simulate wind in Ghost of Tsushima. https://gamedeveloper.com/design/using-vorticles-to-simulate-wind-in-i-ghost-of-tsushima-i-
28. GDC Vault, Blowing from the West: Simulating Wind in Ghost of Tsushima. https://gdcvault.com/play/1027350/Blowing-from-the-West-Simulating
29. Real-Time VFX forum, VFX of Ghost of Tsushima thread. https://realtimevfx.com/t/vfx-of-ghost-of-tsushima-a-recent-blog/15815
30. Remedy, How Northlight makes Alan Wake 2 shine. https://remedygames.com/article/how-northlight-makes-alan-wake-2-shine
31. Remedy, Alan Wake 2 on PS5 Pro: Behind the Scenes. https://remedygames.com/article/alan-wake-2-on-playstation-5-pro---behind-the-scenes
32. GDC Vault, The Indirect Lighting Pipeline of God of War. https://gdcvault.com/play/1026046/The-Indirect-Lighting-Pipeline-of
33. ArtStation Magazine, Santa Monica Studio God of War Art Blast: Environment and Lighting. https://magazine.artstation.com/2018/06/santa-monica-studio-god-war-art-blast-environment/
34. GDC Vault, Sand Rendering in Journey. https://gdcvault.com/play/1017742/Sand-Rendering-in
35. Game Developer, Deconstructing the art design of Journey. https://gamedeveloper.com/art/video-deconstructing-the-art-design-of-i-journey-i-
36. PC Gamer, Silent Hill 2 remake fog mods. https://pcgamer.com/games/horror/silent-hill-2-players-are-modding-away-the-fog-and-freeing-the-camera-to-discover-hidden-detail-in-the-remake
37. The Mary Sue, Silent Hill HD release misses the point. https://themarysue.com/silent-hill-hd-release-misses-point
38. Superjump, Through Mist, Light, and Darkness. https://www.superjumpmagazine.com/drafting-through-the-mists/
39. 80.lv, Hollow Knight Silksong's world isn't actually 2D. https://80.lv/articles/hollow-knight-silksong-s-game-world-isn-t-actually-2d
40. 80.lv, Breakdown of Hollow Knight's art style. https://80.lv/articles/breakdown-hollow-knights-art-style
41. Polycount, Ori depth fog and layering discussion. https://polycount.com/discussion/comment/2267931
42. Airborn Studios, Ori project page. https://airborn-studios.com/projects/ori
43. James Gurney, Atmospheric Value and Distance. https://jamesgurney.substack.com/p/atmospheric-value-and-distance
44. Draw Paint Academy, How to Paint Atmospheric Perspective. https://drawpaintacademy.com/atmospheric-perspective/
45. Unreal forums, Stylized fake animated light shafts with fireflies. https://forums.unrealengine.com/t/stylized-fake-animated-light-shafts-with-fireflies/1941111
46. Unreal forums, Tutorial: godrays (depth-fade cards). https://forums.unrealengine.com/t/tutorial-godrays/29596

*Coverage note:* The shared web-search budget ran out partway through this research. Reddit (r/godot, r/unrealengine, r/vfx) and X threads by VFX artists could not be searched directly, so community practice here comes from the Godot, Unreal and Polycount forums and the Real-Time VFX thread instead. The specific Godot values in Section 4 are suggested starting points derived from the docs. They have not been measured in Unsent's project and should be tuned in-engine.
