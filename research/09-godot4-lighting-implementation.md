# 09 — High-End Lighting in Godot 4 (Forward+) for *Unsent*

Researcher 9 of 10. Scope: how to get "showcase" lighting out of Godot 4.7 Forward+ for one static night exterior. This covers the snowy house, warm windows, the foreground lantern throwing fence shadows, wet cobbles, moon god rays, embers and a vignette shown in `research/reference_target.webp`.

Research note: the 2026-11 web search budget ran out partway through. Reddit refuses automated fetches, and searches aimed at X/Twitter returned no posts. Community evidence therefore comes from the Godot forum, godotshaders.com, the Asset Library, GitHub and itch devlogs, not from Reddit or X threads. Items marked *(unverified)* come from secondary or memory sources and should be checked in the editor.

---

## 1. Takeaways

1. **Bake the GI and keep the lights live.** For a single static night exterior, use **LightmapGI** with every light on *Dynamic* bake mode, which bakes indirect light only and keeps direct light and shadows real time. Add one or two **ReflectionProbes** set to *Once*. Skip SDFGI: it is the slowest GI option in the docs' ranking, it leaks, and at night its main benefit (sky and sun bounce) is mostly lost.
2. **The 4.6 changes affect *Unsent*'s settings.** Since 4.6, glow blends *before* tonemapping and defaults to the **Screen** blend mode. The docs warn Screen is "significantly brighter" than the old Soft Light default. Volumetric fog blending also became more physically accurate and therefore brighter. A glow intensity of 0.7 tuned on 4.5 or earlier is probably too hot now. Check `glow_blend_mode` first.
3. **AgX is flat by default, so fix it inside the tonemapper.** 4.6 added `tonemap_agx_contrast` and `tonemap_agx_white`. Raise AgX contrast instead of Adjustments > Contrast, which runs after tonemapping and can shift hues in clipped channels.
4. **Use emission values well above the glow threshold.** With an HDR threshold of 1.4, windows, the lantern glass, embers and the moon disc must output roughly 3–10 linear for clean bloom, while lit snow stays below 1.0. That gap is what makes "every window glowing" read clearly.
5. **Use contact-hardening shadows on the lantern only.** An OmniLight `size` of about 0.05–0.1 gives fence shadows that are crisp at the pickets and soft at the tips, as in the reference. PCSS is expensive, so use it on one hero light.
6. **Fake the god rays in layers.** Real shafts come from volumetric fog: the moon casts shadows through tree branches, with forward-scattering anisotropy and a denser FogVolume placed where the beams should be. Because the moon is in frame, a cheap screen-space radial blur (GPU Gems 3, ch. 13) or hand-placed additive cone meshes add art-directed rays on top.
7. **Wet cobbles need a material first and SSR second.** Darken the albedo, drop roughness to about 0.1–0.25 in a puddle mask, and add a normal map. The 4.6 SSR overhaul handles roughness better and offers half or full resolution. SSR only reflects what is on screen, which suits this framing because the lantern and windows are always visible.
8. **AreaLight3D (new in 4.7) is tempting for windows but costly.** The docs say one visible area light adds cost to *every* object in Forward+. Use emissive panes plus cheap unshadowed Omni or Spot lights per window. A window-grid **projector** on a SpotLight gives the light pools on the snow.

---

## 2. Feature-by-feature guide (stylised night exterior)

Cost tiers are relative estimates for a mid-range desktop GPU at 1080p: **$** negligible, **$$** moderate, **$$$** significant.

### 2.1 GI: SDFGI vs VoxelGI vs LightmapGI vs ReflectionProbes

| Technique | Dynamic? | Leaks | Cost (docs' ranking) | Night-exterior verdict |
|---|---|---|---|---|
| ReflectionProbe | Optional (*Always* is expensive) | n/a | fastest | **Yes.** Use *Once* mode and one box around the porch and path for cobble and window reflections. |
| LightmapGI | Baked; dynamic objects use probes | Few, with supersampling | 2nd fastest | **Yes (primary).** Static scene, best quality, cheapest at runtime. |
| VoxelGI | Fully real time | Walls thinner than one voxel leak | middle | Acceptable fallback if bake iteration is painful. |
| SSIL | Screen-space complement | Edge artifacts | 4th | Optional high-end setting for warm window bounce on the snow. |
| SDFGI | Semi-real-time | Leaks and cascade pops | slowest | **No.** It is designed for large or open worlds and day-night cycles. |

Sources for the table: the GI intro page and the SDFGI page. The SDFGI docs say to enable it outdoors and give Bounce Feedback values of 0.3–1.0. That matters little at night.

**LightmapGI specifics.** Use Quality High, Bounces 3 (the default), Directional on (normal-mapped cobbles read better), Use Denoiser on (JNLM, or OIDN if installed) and Supersampling on for the final bake. Keep Lightmap Texel Size at 0.2 (the default) for the house and path, and use 0.5+ on distant trees and terrain. Set Environment Mode to *Scene* so the night sky contributes.

Put the moon, MoonFill, lantern, porch and window lights on **Dynamic** bake mode. Indirect bounce is baked; direct light and shadows stay live, so the lantern can flicker. Shadowmask Mode (None, Replace, Overlay) affects only the first Dynamic directional light. Use *Overlay* if the moon's far shadow distance must be short for performance. Lightmap shadowmask arrived in the 4.4 cycle *(unverified)*.

Two forum gotchas. First, a bake that "goes dark" usually means bake modes, UV2 or LightmapGI hierarchy problems: only siblings and their children are baked. Second, hiding a light does not exclude it from the bake; set its bake mode to Disabled instead.

Since 4.6, reflection probes use cheaper octahedral maps. Sky roughness layers dropped from 8 to 7.

### 2.2 Volumetric fog and FogVolume ($$, Forward+ only)

- **Global settings.** Density sets the base. Albedo is the colour when lit. Emission gives an ambient glow but lights no surfaces. Anisotropy ranges from forward to back scatter; positive values make shafts brighter when looking toward the moon. Shorter Length gives more detail. Detail Spread puts more slices near the camera. GI and Ambient Inject carry a small cost. Sky Affect controls how much fog is drawn over the sky.
- **Project settings.** Volume Size (default 64) and Volume Depth trade sharpness for cost. Keep Use Filter on unless you need crisp shafts.
- **Per-light.** `light_volumetric_fog_energy` sets how much each light feeds the fog. Use 0 for fill lights and short flashes to save cost and avoid temporal ghosting. A shadowed light also casts its shadows into the fog.
- **FogVolume.** Shapes are Box, Ellipsoid, Cone, Cylinder and World. FogMaterial offers density (negative values subtract), albedo, emission, height falloff, edge fade and a density texture. Keep the density texture at 64³ or smaller (NoiseTexture3D). Write a `fog` shader for animated density.
- **Clay John's art tip from the 4.0 blog.** Put a denser volume where a light beam passes through it to get believable shafts. Use negative-density volumes to keep fog out of interiors.
- **Ghosting.** Temporal reprojection smooths fog edges but trails fast-moving lights and volumes. Flickering lantern energy can smear, so flicker `light_energy` gently or flicker a non-fog light.
- **Changes in 4.6.** Fog renders brighter, and the migration guide says to lower density or per-light fog energy. A 4.5.1 forum report mentions fog fading at screen edges, possibly on AMD. Test on AMD if you can.

### 2.3 Glow and bloom ($–$$)

- Glow shows only when the HDR Threshold is low enough or Bloom > 0. **Bloom** blooms *everything* by that fraction, so 0.06 adds a uniform haze. Lower it to 0.02–0.04 to keep dark snow dark.
- **Blend modes.** Screen is the 4.6+ default and a good all-rounder. Soft Light is the weakest and is described as best on dark scenes, which suits night. Additive is the strongest and looks dreamlike.
- **Levels.** Low levels give tight halos and high levels give screen-wide haze. In 4.6 the defaults changed: levels 2/3/4 = 0.8/0.4/0.1, level 5 = 0, intensity 0.3.
- A **glow map** can add lens dirt or mask the effect. It is cheap and suits the painterly reference.
- **HDR threshold.** Glow now runs on pre-tonemap linear values, so think in scene-referred units. Snow under a 0.2-energy moon sits around 0.1–0.4, and emissives at 4–10 bloom cleanly above 1.4.

### 2.4 Tonemappers and exposure ($)

| Mapper | Character (docs) | Use for *Unsent* |
|---|---|---|
| Linear | clips highlights; fastest | no |
| Reinhard | soft, low contrast | no |
| Filmic | film curve, better contrast | possible |
| ACES | high contrast, desaturates brights, hue skews (yellow/magenta) | possible but skews warm lights |
| **AgX** | desaturates brights while best preserving hue; slowest (but cheaper after 4.6) | **yes** |

- AgX landed in **4.4** (Calinou's PR, from proposal #7545). The "Punchy" variant was dropped; maintainers suggested Adjustments contrast and saturation around 1.3 instead.
- **4.6 (PR #106940).** Added a new AgX curve, `agx_white` (default 16.29, minimum 2.0) and `agx_contrast`, and output now clips at 1.0. AgX is a bit faster than before. Projects from 4.4 and 4.5 stay compatible.
- AgX is less saturated than ACES out of the box (three.js community), so a scene lit for ACES looks washed out after a straight swap.
- **Exposure** scales brightness before tonemapping. Keep exposure manual for a fixed shot.

### 2.5 Adjustments and colour-correction LUT ($)

Adjustments run **after** tonemapping, so they act like display-referred grading.

- **1D gradient:** a GradientTexture1D maps luminance to colour. It is quick for "blue shadows, amber highs".
- **3D LUT:** import the texture as Texture3D with a slice count (17, 33, 51 or 65). Start from the neutral template, grade a screenshot in an image editor, then apply the same grade to the template.
- Keep brightness and contrast at 1.0 and saturation at about 1.05–1.15. Push contrast through `agx_contrast` instead.

### 2.6 SSAO, SSIL, SSR

- **SSAO ($–$$).** It affects *ambient* light only. With sky ambient at 0.3 it grounds fence posts, steps and shrubs. Light Affect pushes AO into direct light (not physical but stylish). Half Size keeps it cheap.
- **SSIL ($$).** Forward+ only. It bounces diffuse *and emissive* light in screen space, so warm window light reaches nearby snow and sills. Large radius values cause spikes. It complements LightmapGI rather than replacing it.
- **SSR ($$–$$$).** Forward+ only. It reflects opaque on-screen geometry only, so transparent materials, particles and screen-reading shaders do not appear. In **4.6** it was completely overhauled (GH-111210 by Skyth): better roughness handling, stability and speed, plus half- and full-resolution modes. The depth-tolerance default changed from 0.2 to 0.5.
- **SSR on wet stone.** A secondary blog reports Hi-Z tracing, GGX importance sampling and temporal accumulation in the new SSR, with suggested stylised values of 32–48 steps, fade-in 0.1–0.15 and fade-out 2–3 *(unverified; key names may differ)*. One 4.6.2 forum user reports false reflections at extreme metallic and roughness values, so keep cobbles non-metallic.
- **Wet material recipe** (community puddle shaders on godotshaders). Build a puddle mask from noise × the normal's up component. Inside the mask, darken the albedo by 30–50%, lower roughness to 0.05–0.2 and flatten the normal map.

### 2.7 DirectionalLight shadows (moon) ($$)

- **PSSM 4 splits** is the default. Each large object renders once per split. For one framed shot, set **Max Distance** to what the camera actually sees (30–60 m). That improves quality and speed.
- **Blend Splits** hides split seams at a small cost. Push the first split toward the camera for detail on the near fence.
- **Bias.** Raise Normal Bias before Bias; too little bias causes acne and too much causes peter-panning. Change Pancake Size only for large unsubdivided meshes.
- **Blur** softens and stabilises shadows but shows grain more. With Soft Medium or higher filter quality, the dither disappears.
- Shadow map size defaults to 4096 (16-bit depth by default). `angular_distance` above 0 enables directional PCSS, which is expensive. The moon is about 0.5°.

### 2.8 Omni and Spot lights: projectors, cull masks, size

- **Shadows.** Omni uses Cube mode (default, accurate) or Dual Paraboloid (fast but distorts). Spot shadows render one map, so they are much cheaper. The default atlas fits 88 shadowed positional lights.
- **Projectors.** A spot projector accepts any texture, mapped like a decal. An omni projector needs a 360° panorama. Projectors multiply light colour, so raise energy to compensate. Set Light Projectors > Filter to a mipmap mode.
- **Cull mask** limits which layers a light *lights*. Excluded objects still cast shadows unless you change their Cast Shadow setting. **Caster Mask** limits which objects cast shadows.
- **Size** is PCSS for omni and spot lights: contact-hardening and expensive, so use it on few lights. **Distance fade** culls far lights and shadows.
- **AreaLight3D (4.7).** A rectangle light with PCSS soft shadows. `area_normalize_energy` keeps output constant when you resize it. It is costly in Forward+, and the docs advise using it only for cinematics or high-end targets.

### 2.9 Decals ($, cost tracks screen coverage)

- Decals provide albedo, normal, ORM and emission. Normal and ORM need an albedo alpha mask. Set `albedo_mix = 0` for roughness-only decals, which suits **wet patches**, footprints and puddles.
- Other options: Normal Fade (small cost), upper and lower fade, distance fade (which removes the decal from the shader once faded) and a cull mask to keep decals off characters and particles.
- No custom shaders and no parallax. They count toward the 512 clustered-element limit. Keep the Y extents short for better culling.

### 2.10 CameraAttributes: DOF and auto-exposure ($–$$)

- *Practical* attributes give DOF blur near and far plus auto-exposure (min and max sensitivity, speed, scale). *Physical* attributes add focal length and aperture with physical light units.
- Physical units need careful values throughout, and the community tutorial author found them hard to balance. Stay on Practical.
- **Auto-exposure at night** pulls the image toward mid-grey and kills the mood. Keep it off for the opening, or use a very low scale.
- **DOF.** A subtle far blur on the treeline adds painterly depth. Moderate GPU cost; quality is set in project settings.

### 2.11 Screen-space god rays (community)

| Approach | How | Pros / cons |
|---|---|---|
| Volumetric fog (built in) | Moon shadows + anisotropy + dense FogVolume in beam | Physically consistent, but only where casters break the light; cost is already paid |
| "Screenspace Godray" (godotshaders) | Quad in front of camera, GPU Gems 3 ch. 13 march toward projected sun, depth texture, Bayer dither; 32 samples | One pass and cheap; needs a `@tool` script feeding `light_world_dir`; fades when not facing the light |
| "Screen Space God Rays (4.3)" | SubViewport occlusion mask + radial blur, 200 samples | Good quality but a second camera render; heavy |
| "Fake Godrays" / SimplestGodRay3D | Additive cone or quad mesh with gradient and noise | Fully art-directed and cheapest; static |
| SIsilicon God Rays plugin | Post-process node under a light | **Godot 3.2 only**; reference value only |

### 2.12 Version changes that matter (4.3–4.7)

- **4.4:** AgX tonemapper. CSG to MeshInstance for lightmap UVs.
- **4.5:** Ambient-based specular occlusion (toggle in project settings). Bent normal maps. Built-in SMAA. Shader Baker to cut shader-compile hitches in exports.
- **4.6:** Glow before tonemap with Screen as the default and new level and intensity defaults. Brighter fog. SSR overhaul. AgX white and contrast. Octahedral probes. D3D12 is the default for new Windows projects.
- **4.7:** HDR display output, which requires checking that glow, tonemapping and debanding still look right with it on. AreaLight3D. Energy-conserving clearcoat. Per-pass environment UBOs (faster).

---

## 3. Community examples and what they teach

- **Godot forum, "Realistic lighting in Godot 4".** Night recipe: moon energy 0–0.4, dark-blue colour, shadow blur about 1, sky contribution about 0.1, and only sky plus practical lights providing illumination. For a scene fixed at one time of day, use an HDR or custom sky, fog density ≤0.01 for clarity, and Sky Affect 0 unless fog should cover the sky. For cloudy or static scenes it suggests skipping SDFGI in favour of probes and screen-space effects. Each enclosed space gets a *Once* probe.
- **Clay John, "Fog Volumes arrive in Godot 4".** Shafts come from a volume intersecting a beam. The defaults are said to be efficient enough for integrated GPUs, and shortening fog length buys detail cheaply.
- **Official Volumetric Fog demo (Asset Library 2754).** A reference project for global density versus local FogVolumes.
- **Bramwell's "Godot 4 Beginners" devlog.** A fog demo built on FogVolumes, with a bonus level dedicated to god rays and links to scattering references.
- **godotshaders: "Rain puddles with screen space reflection"** (CC0, builds on marcelb's SSR) and "Rain Puddles V3". These are ready-made puddle masks for the cobble path.
- **godotshaders god-ray family.** "Screenspace Godray" (GPU Gems), "Screen Space God Rays 4.3" (SubViewport mask) and "Fake Godrays" (cone mesh plus SpotLight). Commenters suggest lowering the SubViewport's 3D scale so fewer samples are needed, and switching `repeat_enable` to `repeat_disable` to avoid a hard edge on the cone.
- **SimplestGodRay3D** (Asset Library, 4.4, MIT). A single-quad stylised shaft node pitched as cheaper than fog.
- **AgX proposal thread #7545.** The community's rationale was hue preservation under overexposure, avoiding the yellow and magenta skew of ACES. That is exactly what keeps warm windows orange instead of turning them yellow-white.
- **Calinou's guidance in the same thread.** For "punchy" AgX, use contrast and saturation around 1.3. In 4.6+, use `agx_contrast` instead.

---

## 4. Apply to *Unsent*'s opening

Current settings: AgX exposure 1.05; glow 0.7, bloom 0.06, threshold 1.4; fog density 0.011; sky ambient 0.3; Moon plus MoonFill directional lights; custom sky; porch and gable omnis; GPUParticles; camera_fx post shader.

### 4.1 Environment, tonemap, glow, adjustments

| Setting | Current | Recommended | Why |
|---|---|---|---|
| `tonemap_mode` | AgX | **AgX** | Keeps warm windows orange under bloom |
| `tonemap_exposure` | 1.05 | 1.0–1.1 (keep) | Fine; tune after the glow change |
| `tonemap_agx_contrast` (4.6+) | default | **1.15–1.25** | Restores punch without post-tonemap hue shift |
| `tonemap_agx_white` (4.6+) | 16.29 | **8–10** | Brighter emissives reach near-white sooner, so the lantern core burns |
| `ambient_light_source` | Sky | Sky | — |
| `ambient_light_sky_contribution` | 0.3 | **0.15–0.25** | Darker shadows let the warm practicals dominate (forum uses 0.1) |
| `ambient_light_energy` | — | 0.6–1.0, tint `#5a6f9c` if using Color | Cool moonlit shadow base |
| `glow_enabled` | on | on | — |
| `glow_blend_mode` | **check** | **Screen** (or Soft Light if too bright) | 4.6 default is much brighter than old Soft Light |
| `glow_intensity` | 0.7 | **0.35–0.5 (Screen)** / 0.7 (Soft Light) | Compensates for the 4.6 change |
| `glow_bloom` | 0.06 | **0.02–0.03** | 0.06 grey-washes dark snow |
| `glow_hdr_threshold` | 1.4 | **1.2–1.4** | Only emissives (≥3) bloom |
| `glow_hdr_scale` | — | 2.0 | Default; stronger overbright halo |
| `glow_levels` 1–7 | — | 0, 0.8, 0.6, 0.4, 0.2, 0, 0 | Tight halo plus mid haze around windows |
| `glow_map` | — | Optional subtle lens-dirt texture, strength 0.3 | Painterly reference |
| `adjustment_enabled` | — | on: brightness 1.0, contrast 1.0, saturation 1.08 | Light touch |
| `adjustment_color_correction` | — | 33³ LUT graded from a screenshot: teal-blue shadows, amber highlights, lifted blacks ≈ 0.02 | Matches the reference split-tone |
| SSAO | — | on: radius 1.0, intensity 1.5, power 1.5, light_affect 0.1, Half Size | Grounds posts, steps, shrubs |
| SSIL | — | on (High preset only): radius 3, intensity 0.7, normal_rejection 1.0 | Window and lantern bounce on snow |
| SDFGI | — | **off** | Use lightmaps instead |

### 4.2 Lights

| Light | Type | Key settings |
|---|---|---|
| **Moon** | DirectionalLight3D | energy 0.15–0.25; colour `#9fb4ff`; shadows on; PSSM 4 splits; `directional_shadow_max_distance` 40–50; split_1 ≈ 0.08; blend_splits on; bias 0.05, normal_bias 1.0–1.5; shadow_blur 1.0–1.5; angular_distance 0 (use blur; PCSS directional is pricey); `light_volumetric_fog_energy` **2–4** (drives shafts); bake mode Dynamic |
| **MoonFill** | DirectionalLight3D | energy 0.03–0.06, colour `#4a5a8a`, opposite azimuth; **no shadows**; fog energy **0**; `sky_mode` = Light Only so the custom sky draws one moon *(check property)* |
| **Lantern (hero)** | OmniLight3D | energy 4–8; colour `#ffad5c` (≈2200 K); range 10–14; attenuation 1.0–1.5; **shadow on, Cube mode**; **`light_size` 0.05–0.08** (contact-hardening fence shadows); shadow_normal_bias 1.0; fog energy 1.5–3 (halo); bake mode Dynamic; gentle flicker under 10% |
| Porch / gable | OmniLight3D | energy 2–4; same warm colour; porch shadows on (Dual Paraboloid acceptable); gable shadows off; size 0; fog energy 0.5–1 |
| **Window pools ×8** | SpotLight3D outside each window, aimed at the snow | energy 1–2; angle 40–55°; **projector texture = window mullion plus curtain silhouette**; shadows off; cull mask = ground/snow layer only; fog energy 0.3; distance fade 30 m |
| Interior glow (optional) | AreaLight3D (4.7) | **Doorway only**, size about 1.0 × 2.0 m; Ultra preset only due to Forward+ cost |
| Embers | GPUParticles emissive | Emission energy 4–8 (above threshold), no lights; additive; place on a cull layer excluded from decals |

Project settings: positional shadow atlas 4096, directional shadow 4096, soft shadow filter **Soft Medium** (High/Ultra on the top preset), 16-bit depth.

### 4.3 Fog

| Setting | Recommended |
|---|---|
| `volumetric_fog_density` | **0.008–0.011** (4.6 fog is brighter; drop slightly if shafts wash out) |
| albedo | `#b8c4dc` (cool mist) |
| emission | `#0b1020`, energy 0.5–1 (lifts the blacks the way the reference haze does) |
| anisotropy | **0.5–0.7** (forward scatter makes moon-side shafts glow) |
| length | 40–60 m |
| detail_spread | 2.0 |
| ambient_inject | 0.1; gi_inject 0 |
| sky_affect | 0.3–0.5 (haze over the lower sky and moon halo) |
| temporal_reprojection | on, amount 0.85–0.9 |
| Project: volume size / depth | **96 / 96** (High), 64/64 (Low) |
| FogVolume A | Box over the front garden and path, height falloff, density +0.01, NoiseTexture3D 64³ slowly scrolled via fog shader |
| FogVolume B | Ellipsoid around the lantern, radius 1.5 m, density +0.03, faint amber albedo (localised glow) |
| FogVolume C | Box between treeline and moon, density +0.02 (beam catcher for shafts) |
| FogVolume D | Box inside the house, density **−1** (keeps interior and windows clean) |

### 4.4 GI choice

| Item | Setting |
|---|---|
| GI | **LightmapGI**: Quality High, Bounces 3, Directional on, Supersampling on, Denoiser (OIDN if installed), Environment Mode = Scene, Shadowmask = None (or Overlay if moon max distance is kept short) |
| Mesh GI mode | Static for house, fence, path, terrain and trees; Disabled for particles, mailbox flag, characters |
| Lights | All Dynamic bake mode (indirect only, so shadows stay live) |
| Emissive windows | Emission energy 4–6 on panes; they bake warm bounce into sills and snow |
| ReflectionProbe | One box over porch and path, Update Once, Box Projection on, Interior off, cull mask excludes particles, Intensity 0.6–0.8 |

### 4.5 SSR for the cobblestones

| Setting | Recommended |
|---|---|
| `ssr_enabled` | on |
| `ssr_max_steps` | 48 (64 on High) |
| `ssr_fade_in` / `ssr_fade_out` | 0.15 / 2.0 |
| `ssr_depth_tolerance` | 0.5 (4.6 default) |
| Resolution | Half on Low/Medium, Full on High |
| Cobble material | Albedo darkened 35% in wet mask; roughness 0.12–0.2 in gaps and puddles, 0.45 on dry crowns; metallic 0; normal map strength 1.0, flattened in puddles |
| Wet decals | 2–4 Decals with `albedo_mix = 0`, ORM roughness ≈ 0.05, normal_fade 0.3, distance fade on |
| Snow at path edges | Separate decals (albedo + normal), cull mask terrain/path only |

### 4.6 God-ray approach (layered)

1. **Base (always on):** moon shadows through foreground pine branches with fog energy 3, anisotropy 0.6, and FogVolume C as the beam catcher. Real shafts, no extra pass.
2. **Hero accent:** a GPU Gems-style screen-space quad, adapted from godotshaders' "Screenspace Godray". Use 32 samples, `ambient_col` pale blue, exposure low. Drive `light_world_dir` from the Moon via a `@tool` script, and fade it out when the moon leaves the frame. Runs before camera_fx.
3. **Art-direction fill (optional):** 2–3 "Fake Godrays" cone meshes in additive mode with `repeat_disable` on the gradient, angled from the moon through the tree gap, with alpha 0.15–0.25 and slow UV scroll. They give exactly the streaks in the upper left of the reference.

### 4.7 Post stack order and camera

- Order: scene → fog → glow (pre-tonemap, 4.6+) → AgX → Adjustments/LUT → camera_fx (vignette, grain).
- Keep grain after the LUT so it does not get graded. Vignette strength 0.25–0.35, soft.
- CameraAttributesPractical: auto-exposure **off**. DOF far blur on, distance 25 m, transition 15 m, amount 0.05 (soften the treeline only).
- Anti-aliasing: TAA or SMAA (4.5+). TAA also stabilises fog and SSR noise.
- Export with Shader Baker (4.5+) to avoid first-frame hitches on the title shot.

### 4.8 Performance budget (estimates, 1080p mid-range)

| Feature | Approx. cost | Toggle in Low preset |
|---|---|---|
| Volumetric fog 96³ | 0.8–1.5 ms | → 64³, fewer FogVolumes |
| SSR half-res | 0.4–0.8 ms | off |
| SSIL | 0.5–1.0 ms | off |
| SSAO half | 0.3–0.5 ms | keep |
| Lantern PCSS cube shadow | 0.3–0.6 ms | `size` → 0 |
| Moon PSSM 4 splits | 0.5–1.0 ms | 2 splits, 2048 |
| Screen god-ray quad (32 samples) | 0.2–0.4 ms | off (fog shafts remain) |
| LightmapGI | ~0 (texture reads) | keep |

---

## Sources

1. https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/introduction_to_global_illumination.html
2. https://docs.godotengine.org/en/4.7/tutorials/3d/global_illumination/using_sdfgi.html
3. https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_lightmap_gi.html
4. https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/reflection_probes.html
5. https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html
6. https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html
7. https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html
8. https://docs.godotengine.org/en/stable/tutorials/3d/using_decals.html
9. https://docs.godotengine.org/en/stable/tutorials/3d/physical_light_and_camera_units.html
10. https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html
11. https://docs.godotengine.org/en/4.7/classes/class_arealight3d.html
12. https://godotengine.org/releases/4.4
13. https://godotengine.org/releases/4.5/
14. https://godotengine.org/releases/4.6/
15. https://godotengine.org/releases/4.7/
16. https://godotengine.org/article/hdr-output-arrives-in-godot-4-7/
17. https://godotengine.org/article/dev-snapshot-godot-4-6-dev-2/
18. https://godotengine.org/article/dev-snapshot-godot-4-6-dev-3/
19. https://godotengine.org/article/fog-volumes-arrive-in-godot-4
20. https://github.com/godotengine/godot/pull/106940
21. https://github.com/godotengine/godot-proposals/discussions/7545
22. https://github.com/SIsilicon/Godot-God-Rays-Plugin
23. https://godotshaders.com/shader/screen-space-god-rays-godot-4-3/
24. https://godotshaders.com/shader/screenspace-godray/
25. https://godotshaders.com/shader/fake-godrays-godot-4-2/
26. https://godotshaders.com/shader/rain-puddles-with-screen-space-reflections/
27. https://godotshaders.com/shader/rain-puddles-v1/
28. https://godotengine.org/asset-library/asset/4146 (SimplestGodRay3D)
29. https://godotengine.org/asset-library/asset/2754 (Volumetric Fog Demo)
30. https://forum.godotengine.org/t/tutorial-realistic-lighting-in-godot-4/87219
31. https://forum.godotengine.org/t/volumetric-fog-fades-out-at-the-edges-of-the-screen/130097
32. https://forum.godotengine.org/t/lightmap-baking-makes-scene-dark/58742
33. https://forum.godotengine.org/t/a-roughness-value-caused-reflection-issue-that-need-help-with/136820
34. https://www.strayspark.studio/blog/godot-46-rendering-deep-dive-ssr-lightmapper-performance (secondary; figures unverified)
35. https://bramwell.itch.io/godot-4-beginners/devlog/588028/volumetric-fog-and-god-rays
36. https://gamefromscratch.com/godot-4-x-3d-tutorial-lighting-shadows-and-global-illumination/
37. https://www.cgchannel.com/2026/01/discover-5-key-features-for-cg-artists-in-godot-4-6/
38. https://discourse.threejs.org/t/is-agx-tonemapping-implemented-correctly/60609
