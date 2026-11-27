# 08 — Night skies, the moon, clouds and moonlight

Research for *Unsent* (Godot 4.7, custom `shader_type sky` in `shaders/night_sky.gdshader`). The target is `research/reference_target.webp`. It shows a modest bright moon at the top left, half-hidden by dark rimlit cumulus, god rays falling down-left through pines, a navy gradient, dense small stars and a faint blue Milky Way at the top right.

---

## 1. Takeaways

1. **No shipped game uses a physically correct night sky, and none should.** The real full moon is about 0.5° across, and a full moon washes out the Milky Way. Real moonlight is warm, around 4000 K. Every admired game and film night breaks at least one of these rules. RDR2 gets close, with real constellations, eight moon phases and moonlight that drowns nearby stars. It still uses a heavy blue grade and a Milky Way that is brighter than it would be under a full moon.
2. **Blue moonlight is a convention that rests on real perception.** The Purkinje shift moves the eye's peak sensitivity toward blue at scotopic (night-vision) light levels. Cameras and displays don't reproduce this, so film adds the blue by hand. Fury Road's night scenes were graded about 95% blue. The **moon disc** can stay warm ivory, but the **light it casts** and the **sky around it** should read cool.
3. **The moon is drawn several times larger than reality, but "modest" in the reference still means only about 10× real size, not 30×.** The moon illusion makes people remember the moon as large, so a moon at true size looks wrong on screen. A cinematic moon is usually 5–12× real angular size. Unsent's current `moon_size = 0.15` rad radius is about 33× real size and much bigger than the target.
4. **Clouds near the moon are backlit.** They need dark bodies and thin, bright, forward-scattered edges (the silver lining), not flat grey fills. In the Nubis papers the look comes from three terms: Beer's-law extinction, which darkens the body; a Henyey-Greenstein forward phase, which brightens the region near the moon; and a "dark edges" (powder) term. A 2D fbm cloud can fake all three.
5. **The sky should be dark, but not the darkest value in the frame.** Under a full moon the sky is roughly 18 mag/arcsec², about 0.007 cd/m². Moonlit snow (albedo about 0.8, under about 0.1–0.25 lux) is about 0.03–0.06 cd/m², so **moonlit snow is 4–8× brighter than the sky.** Moonlit grass and bark are about equal to the sky. Tree silhouettes must be darker than the sky behind them. Only the moon disc, its glow and the cloud rims should be brighter than the snow.
6. **The moon washes out the area around it.** Thin out stars within about 20–30° of the moon and keep the Milky Way well away from it. RDR2 does this, and astrophotographers note that only the brightest stars survive near the moon.
7. **God rays from the moon are almost always faked.** Games use three methods: volumetric fog shadowed by geometry, a screen-space radial blur from the light's screen position, or hand-placed additive cards. Clouds can modulate any of them.
8. **The sky is the biggest single colour field in an outdoor frame.** Jane Ng's Firewatch talk makes this point. Choose the sky value and hue first, then light the ground against it.

---

## 2. Techniques

### 2.1 Physically based vs stylised skies

- **Physically based atmosphere.** Hillaire's EGSR 2020 paper (used in Unreal) and the earlier Frostbite course model Rayleigh and Mie scattering with small lookup tables and a multiple-scattering approximation. It looks excellent at dawn and dusk. At night it gives near-black output, and artists then raise the exposure. Ghost of Tsushima (Patry, SIGGRAPH 2021) uses a physically based sky for the sky, clouds, haze and fog particles, then pushes the look through custom tonemapping. The physics sets the values and the grade sets the mood.
- **Stylised gradient skies.** Firewatch, Journey, Genshin Impact and Sea of Thieves treat the sky as a designed gradient: zenith colour, horizon colour, and an optional band around the light direction. Genshin's moon and many of its clouds are fixed textures, according to a ReShade modder's notes. Sea of Thieves builds art-directable 3D cloud shapes without ray-marching (Rare said clouds can even form skulls). Journey's team faked a sense of light direction mostly through texturing, without real dynamic shadows (CGW).
- **For Unsent:** a stylised gradient with physically informed *ratios*. That is what the existing shader already does.

### 2.2 Stars and the Milky Way

- **Texture approach.** An equirectangular star map or a photographic Milky Way panorama mapped with `SKY_COORDS`. It gives real constellations, as in RDR2, but stars blur at low resolution and the map shows pole pinching.
- **Procedural approach.** This is the standard Shadertoy technique. Divide direction space into a 3D grid of cells (`floor(dir * scale)`) and hash each cell. A cell gets a star only if its hash is below a density threshold. Jitter the star inside its cell, and draw a point with a tight core plus an exponential glow. Use several layers at different scales. Raise magnitudes to a power, for example `pow(hash, 3)`, so most stars are faint and a few are bright. Give each star a temperature tint (a few orange, most white, some blue) and a per-star twinkle phase. Marian42's "No Man's Starfield" and Godot's "Starry sky" (a Voronoi port of Shadertoy ldl3Dl) use this pattern. **Unsent already does this.**
- **Milky Way band.** Use a great circle defined by a pole vector, with the band equal to `exp(-(dot(d,pole))²/w²)`. Multiply by low-frequency fbm for body, mid fbm for clumps, and ridged fbm for the dark dust lanes. Raise star density inside the band. Godot community skies (Mahamaya, the GDQuest stylized sky, "Stylized sky with procedural sun and moon") use similar layering. Their clouds occlude the moon, the moon occludes the stars, and the horizon occludes everything.

### 2.3 The moon

- **True size:** about 0.0087 rad diameter (0.5°), which is the same value Godot gives for `LIGHTn_SIZE` of the sun. The moon illusion (NASA, timeanddate) is perceptual. The horizon moon is the same size on the retina, or about 1.5% smaller, yet it is remembered as huge. Telephoto photos reinforce this memory.
- **Cinematic moons:** Japanese games and anime often show a hugely oversized moon (GiantBomb's "Oversized Moon" concept). Elden Ring's Moonlight Altar uses a looming moon as a set piece. Early GTA games used a big static moon that RDR2 later shrank. Rule of thumb: **5–12× real size for a believable moody moon, 20×+ for fantasy or symbolic moons.**
- **Draw the disc from `LIGHT0_DIRECTION`.** Use a limb-darkened sphere, low-frequency maria, and a light crater pass. Keep detail subtle at small sizes, because detail that reads on a giant moon becomes noise on a small one.
- **Glow:** two or three exponentials outside the limb, a tight one (the aureole/corona) and a broad one (the haze), plus engine bloom. Keep the disc above the glow threshold so it blooms.

### 2.4 Halos and coronas

- **Corona.** Small, often faintly coloured rings within a few moon diameters. They come from diffraction by water droplets in thin cloud. Visually this is the soft bright aureole around the moon in the reference.
- **22° halo.** A large ring of radius 22° (0.384 rad). It comes from refraction through hexagonal ice crystals in cirrostratus. The inner edge is reddish and sharp, the sky inside it is darker, and the outside fades softly. Paraselenae (moon dogs) can appear just outside the ring. Folklore treats it as a weather omen (EarthSky, HyperPhysics, Wikipedia).
- **Use:** in a sky shader a halo is a cheap ring (`exp(-pow((ang-0.384)/0.02,2))`). It signals "high ice cloud, weather turning." The reference has a corona-like glow, **not** a 22° ring.

### 2.5 Cloud-edge lighting (silver lining)

- **Beer's law** (`T = exp(-σ·density·distance)`) sets how dark the body is.
- **Henyey-Greenstein phase** with g of about 0.6–0.85 (real droplets are about 0.8) gives strong forward scattering. A cloud between viewer and moon glows at its thin edges. A survey paper describes it as a bright silhouette from forward scattering at the boundary.
- **Powder / "dark edges".** The Nubis lighting slide describes the term as `1 - exp(-density·k)`. It darkens the thin outer edges that face *away* from the light and makes crevices read as cauliflower detail. Nubis Evolved (2022) and Nubis Cubed (2023) changed the lighting model, but the artistic goal stayed the same: thick dark cores, bright thin rims.
- **2D fake.** For each pixel, sample density a short step toward the moon in sky-UV space (one to three samples). `lit = clamp((n_here - n_toward_moon)·k)` gives the moon-facing edge, which Unsent already uses. Multiply the rim by `(1 - thickness)` and by a phase term in the angle to the moon. A Blender user trying to reproduce this found that the rim cloud must not be in shadow itself. Rims only appear where light reaches the edge.

### 2.6 Volumetric vs painted clouds

| Approach | Used by | Pros | Cons |
|---|---|---|---|
| Ray-marched volumetric (Nubis) | Horizon, RDR2 (Bauer, SIGGRAPH 2019), Unreal, Mahamaya for Godot | Correct parallax, flyable, self-shadowing | 1–2 ms on PS4 even after years of optimisation; heavy for an indie Godot game |
| 2D noise in a sky shader | Most Godot skies, Unsent | Cheap, art-directable, can be rendered in `use_half_res_pass` | No parallax; edges need faked lighting |
| Painted cards or matte paintings | Firewatch-style backdrops, Blizzard cinematics (Vue clouds plus a Photoshop night sky), 80.lv game-background breakdowns | Total control over shape and rim | Static; can break with a moving camera |

A fixed or near-fixed opening camera favours the 2D or painted approach. Horizon's team rejected baked polygon clouds, billboards and skydomes only because their clouds had to evolve and pass overhead (80.lv).

### 2.7 Cloud-to-moon interaction and god rays

- **Volumetric fog (occlusion shafts).** Fog shadowed by geometry or a cloud shadow map produces shafts. Godot 4's `Environment.volumetric_fog` with a shadowed `DirectionalLight3D` produces real shafts through pine branches. It cannot see sky-shader clouds.
- **Screen-space radial blur (bloom shafts).** Project the light to screen space, mask the bright sky (depth equals far plane), and radially blur toward the light. This is GPU Gems 3 chapter 13, and it matches Unreal's "bloom shafts." Godot options are the "Screen Space God Rays (4.3)" shader, a `CompositorEffect` lens-flare/god-rays add-on, and SIsilicon's plugin, which ties rays to the Sky so that **sky clouds break up the rays.**
- **Cards.** Additive gradient quads or cones with scrolling noise, faded by view angle. The cheapest option and fully art-directed.
- **In-sky crepuscular fans.** Inside the sky shader, add radial streaks around the moon (noise in the moon-relative polar angle), masked where clouds thin. This sells "light breaking between clouds" with no post-processing.

### 2.8 Skybox vs sky shader vs HDRI

- **Skybox (cubemap or panorama image).** Fastest and fully painted. Static unless you layer it.
- **HDRI.** Mostly a *lighting* source for ambient light and reflections. Forum consensus (Unreal forums, Unity docs) is to use an HDRI for lighting and a procedural sky for the visible background when you need motion.
- **Sky shader.** Animated and parametric. In Godot it also feeds the radiance cubemap. The docs say to avoid needless radiance updates. Using `TIME` updates the cubemap every frame, and so does changing a uniform or the light. Use `AT_CUBEMAP_PASS` to output a cheap version, and put expensive clouds in a half-resolution subpass.

### 2.9 Composition and the sky-to-ground ratio

- Firewatch's Jane Ng noted the sky sometimes fills half the screen, so it sets the palette.
- Practical ratios: **sky ≈ 1/3 of the frame** when the ground or building is the subject, **≈ 2/3** when the sky is the subject, and avoid exactly half. The reference shows about 35–40% visible sky (the roofline sits at about 25–30% height, but the trees eat into the sky), so the house is the subject and the sky is the frame.
- The moon sits on an upper-left third intersection. Diagonals run moon → god rays → lantern and moon → cloud bank → Milky Way. The warm/cool split (warm windows and lantern against cool sky and snow) does most of the storytelling.
- Deakins' night village in 1917 is lit by a single moving source (flares) plus a giant fire rig. He chose a slightly warmer flare colour because very blue flares looked wrong, and he designed the set so the flares threw moving shadows. Lesson: one dominant night key, and one warm practical light against the cool.

---

## 3. Examples

- **Red Dead Redemption 2.** Real northern-hemisphere constellations, a rotating sky, eight moon phases, moonlight that drowns nearby stars, and a Milky Way hidden by Saint Denis smog (GameRant). The clouds use a world-wide two-layer density map and ray-marching (Bauer, SIGGRAPH 2019, via the imgeself graphics study). Takeaway: sky realism comes from details, such as the moon dimming stars and light pollution, more than from scale.
- **Horizon Zero Dawn / Forbidden West.** The Nubis series (2015, 2017, 2022, 2023) defined modern real-time clouds: Perlin-Worley noise, height gradients by cloud type, Beer's law, the powder effect, Henyey-Greenstein. Burning Shores pushed them into flyable cloudscapes.
- **Ghost of Tsushima.** A physically based sky drives clouds, haze and fog particles, and custom tonemapping keeps the grade expressive (Patry 2021).
- **Sea of Thieves.** Stylised 3D clouds without ray-marching, art-directable shapes, and a lighting video ("Let There Be Light") about time-of-day mood. Players praise the storms and note that the moon is visible through clouds.
- **Firewatch.** Bold graphic gradients adapted from Olly Moss's key art. Skies built with Marmoset Skyshop. The sky colour drives the whole palette.
- **Journey.** The sense of light direction is painted into textures rather than computed. A sky that is mostly gradient plus a glowing light source.
- **Elden Ring.** The Moonlight Altar's oversized moon is a narrative set piece. FromSoftware's CEDEC 2022 talk describes a painterly concept built from skybox and volumetric fog tools.
- **Death Stranding.** Kojima Productions added an art-controlled height-fog layer on top of Decima's physical scattering, because physics alone lacked artistic control.
- **The Witcher 3.** Modders mostly *reduce* the moon brightness and flare. One player noticed a crescent's water reflection brighter than the moon itself. Even AAA moons need tuning.
- **No Man's Sky.** Fully procedural stars, planets and skies (GDC 2015/2016 talks). Saturated, colour-coded skies per planet.
- **Genshin Impact.** Fixed-texture moon and clouds inside a stylised PBR pipeline. Fans recreating the "Moon Song" scene use procedural star shaders and rings.
- **Mad Max: Fury Road.** Day for night shot about 2 stops *over*exposed, then graded about 95% blue. Skies were graded separately and often replaced with star fields (FilmLight/Eric Whipp, ASC).
- **1917.** Real magnesium flares as moving keys, chosen warmer than blue, with set geometry designed for travelling shadows (AFC, ASC).

---

## 4. Apply to Unsent's opening

These are concrete changes to `shaders/night_sky.gdshader`. All colours are **sRGB as entered in the Inspector** (`source_color`). Linear values are in brackets where useful. The values are measured by eye from `reference_target.webp` (2000×1083).

### 4.1 Moon size and glow

- The reference moon has a radius of about 45 px in a 1083 px-high frame. With Godot's default vertical FOV of 75°, that is an angular radius of about **0.05 rad**. Set **`moon_size = 0.05`** (range 0.04–0.06). That is about 11× real size, not the current 0.15 (33×). If the opening camera's FOV differs, scale linearly: `moon_size ≈ 0.05 × fov_deg / 75`.
- `moon_color` = **(1.00, 0.96, 0.88)** sRGB. This is pale ivory, less gold than now. The reference disc is almost white with faint maria.
- `moon_energy` = **1.6–1.8**, so the disc sits just above the 1.4 glow threshold and blooms softly. With a smaller disc, reduce **`sparkle` to 0.2–0.3**, because the specks become noise at 0.05 rad. Halve the crater amplitudes if the disc looks gritty.
- `glow_color` = **(0.92, 0.88, 0.80)** sRGB. That is a near-white warm haze; the reference glow is not orange. The haze should also cool with distance from the moon. Mix the outer haze toward the horizon blue: `mix(glow_color, vec3(0.45,0.55,0.70), smoothstep(0.1,0.5,ang))`.
- Glow falloffs scale with the smaller moon. The inner aureole is `exp(-beyond*40.0)*0.5`, about one moon radius wide. The broad haze is `exp(-ang*4.0)*0.10 + exp(-ang*1.2)*0.015`. Keep `halo = 1.0`. Don't add a 22° halo for the opening. Keep it as a possible later "weather turns" beat (ring at 0.384 rad, width 0.015, intensity 0.03, slightly red inner edge).
- In the Environment, set glow/bloom with HDR threshold of about 1.2–1.4, intensity about 0.6, and enable levels 3–5 so the moon and cloud rims bloom wide and soft.

### 4.2 Heavy rimlit cumulus

The reference clouds are dark navy-charcoal masses with domed tops and bright thin rims on the moon side. The moon is half-buried at its lower right, a large bank sits above and right of the moon, and wisps drift to its left.

1. **Shape:** keep the domain-warped fbm and add **billow** shaping for cauliflower tops: `n = 1.0 - abs(fbm(...)*2.0 - 1.0)` blended 40% with the existing `c`. Raise `cloud_scale` to about 2.5 for smaller lobes inside large masses. Add a **vertical cumulus profile** in moon-frame coordinates. Let `v = mq.y - base_y`, then density `*= smoothstep(0.0, 0.03, v)` for a flatter base, and use rounder thresholds upward.
2. **Placement:** extend the bank *above* the moon as well as below. Set `cloud_focus_offset = (0.10, 0.02)` and `cloud_focus_spread = (0.18, 0.85, 0.20, 0.25)`. Keep `cloud_far = 0.14` so the right half of the sky stays clear for the Milky Way. Lower `cloud_cover` to about 0.42 for heavier masses.
3. **Body colour:** `cloud_body_color` = **(0.10, 0.12, 0.17)** [linear about 0.010, 0.013, 0.024]. That is darker than now and slightly darker than the nearby sky, so the masses read as heavy and occlude the glow. Near the moon, lighten the body only slightly (×1.5, not ×2.0) so the contrast comes from the rim, not the fill.
4. **Lighting (2D Nubis fake):**
   - Transmittance: `T = exp(-thick * 3.0)`, then `body *= mix(0.6, 1.0, T)`.
   - Forward phase toward the moon: `phase = mix(hg(cosθ, 0.75), hg(cosθ, -0.2), 0.3)`, where `θ` is the angle between the view direction and the moon. Normalise it so `phase ≈ 1` at 10°.
   - Rim: `rim = lit * (1.0 - thick) * phase`, plus `(1.0 - thick)` for edges within about 0.25 rad of the moon. Multiply by `exp(-beyond*6.0)`.
   - Powder / dark-edge term for edges facing away from the moon: `body *= 1.0 - 0.4*(1.0 - exp(-dens*4.0))*(1.0-lit)`.
   - `cloud_lining_color` = **(0.95, 0.90, 0.80)** sRGB. That is pale warm white, much less gold than (1.0, 0.83, 0.62). Allow rim peaks of about 1.3–1.5 linear so the rims bloom.
5. **Cost:** move the whole cloud block into `render_mode use_half_res_pass;`. Compute it when `AT_HALF_RES_PASS` is true and write `COLOR` and `ALPHA`. In the main pass, composite with `mix(col, HALF_RES_COLOR.rgb, HALF_RES_COLOR.a)` after the moon. Clouds must also occlude stars, which the current over-composite already does.

### 4.3 Star density

- The reference has many small, evenly spread stars, slightly denser to the upper right. Few have glows.
- Keep three layers, but **suppress stars near the moon**: `fade *= smoothstep(0.15, 0.55, ang)`. Stars vanish within about 3 moon radii and recover by 30°.
- Layer densities: `star_layer(d, 260, 0.004, 1.3, 0.3)`, `(d, 520, 0.03 + band*0.06, 0.7, 0)`, `(d, 900, 0.05 + band*0.3*(0.4+clumps), 0.45, 0)`. This gives more tiny stars and fewer medium ones. Use `bright_stars` density **0.001** and tint (0.80, 0.86, 1.0).
- Halve the twinkle amplitude (`0.88 + 0.12*sin`). Strong twinkle reads as a game effect, and twinkling `TIME` already forces a radiance update each frame, so output no stars in `AT_CUBEMAP_PASS` (already done).

### 4.4 Milky Way placement

- In the reference the band is faint and sits only in the **upper-right quadrant**, running from about mid-frame top toward the top-right corner, well away from the moon. A real full moon would wash it out, so keeping it far from the moon is the honest cheat.
- Re-derive the pole from two new screen points with the same camera basis as in the shader comment. Use **P1 = F + 0.15R + 0.75U** (top centre) and **P2 = F + 0.95R + 0.55U** (right edge, upper), then `pole = normalize(cross(P1,P2))`. Alternatively, keep the current pole and set **`band_offset ≈ +0.35`** to slide the band away from the moon, then fine-tune in the Inspector.
- `milky_way` = **0.55**, `band_width` = **0.13**. `milky_way_color` = (0.40, 0.50, 0.70) and `milky_way_core` = (0.70, 0.78, 0.92). Fade the band by moon distance: `mw *= smoothstep(0.6, 1.2, ang)`.

### 4.5 Sky gradient colours

Sampled from the reference and nudged for a clean gradient:

| Position | sRGB | Hex | Note |
|---|---|---|---|
| Zenith / top right | (0.043, 0.063, 0.118) | #0B1020 | darker and less saturated than the current #121D35 |
| Mid sky | (0.071, 0.102, 0.165) | #121A2A | |
| Horizon behind trees | (0.118, 0.157, 0.224) | #1E2839 | must stay lighter than the pine silhouettes |
| Moon-side lift (within about 0.5 rad) | (0.23, 0.27, 0.34) | #3A4557 | cool blue-grey that the glow fades into |

Set `zenith_color = (0.043, 0.063, 0.118)` and `horizon_color = (0.118, 0.157, 0.224)`. Use a 3-stop gradient, `smoothstep(-0.02, 0.25, h)` to mid and `smoothstep(0.25, 0.8, h)` to zenith. Add a slight brightening on the moon's side of the horizon (`+0.02*max(dot(d.xz, M.xz),0)`) so the sky is asymmetric, as in the reference.

**Values against the ground.** The DirectionalLight3D "Moon" should be cool: colour about (0.60, 0.70, 0.95), energy about 0.2–0.35. Moonlit snow then lands about 3–6× brighter than the sky, matching the measured physical ratio. Moonlit bark and needles stay at or below the horizon sky value, so the pines silhouette. Ambient comes from the radiance cubemap (sky contribution about 0.3–0.5) to keep shadows navy, not black.

### 4.6 Faking moon god rays in Godot

Layer two cheap methods; neither needs the clouds to be volumetric:

1. **In-sky crepuscular fan** (in `night_sky.gdshader`, background pass only). Compute the polar angle around the moon, `a = atan(mq.y, mq.x)`, and streaks `s = pow(vnoise(vec2(a*18.0, 0.0) + TIME*0.01), 3.0)`. Restrict to the lower-left sector (`smoothstep(0.2, 0.9, dot(normalize(mq), normalize(vec2(-0.7,-0.7))))`). Fade with `exp(-beyond*2.5)`, and multiply by `(1.0 - dens_at_moon_side)` so clouds break the fan. Add it in `glow_color * 0.05`. This gives the slanting down-left rays in the sky itself.
2. **World-space rays through the pines.** Two options:
   - **Preferred (real shafts):** enable `Environment.volumetric_fog` with density about 0.01–0.02, albedo (0.75, 0.80, 0.90), and anisotropy **0.6–0.75** (forward-scattering, so the shafts show when looking toward the moon). On the Moon DirectionalLight3D, enable shadows and set `light_volumetric_fog_energy` to about 4–8, so the dim moonlight still lights the fog. Pine branch geometry then cuts real shafts. Limit it with a `FogVolume` box over the upper-left trees if the whole scene gets hazy.
   - **Cheapest:** 3–6 additive `MeshInstance3D` cards or cones angled from the moon direction (`-light.global_basis.z`). Use an unshaded, additive, depth-test-on material with a vertical gradient times scrolling noise, colour (0.55, 0.62, 0.80) and alpha about 0.05–0.12. Fade them with `pow(max(dot(view_dir, moon_dir),0), 4)` so they show only when the camera looks toward the moon.
   - Optional polish: a screen-space radial blur `CompositorEffect` from the moon's projected position, masking only sky pixels so cloud gaps modulate it. Clamp the effect when the moon is off-screen.

### 4.7 Order of work

1. Shrink the moon and recolour the glow.
2. Recolour the gradient.
3. Move the Milky Way and fade stars near the moon.
4. Billow the clouds, darken the bodies and apply pale rims.
5. Move the clouds into the half-res pass.
6. Add the in-sky fan.
7. Add volumetric fog shafts.

Compare against the reference at each step with a fixed screenshot of the opening camera.

---

## 5. Sources

Note: searches scoped to Reddit (r/godot, r/gamedev, r/astrophotography) and X returned no direct threads. Real night-sky values come from astronomy references instead, and the Godot community material comes from the Godot forum and godotshaders.com.

1. https://www.advances.realtimerendering.com/s2015/The%20Real-time%20Volumetric%20Cloudscapes%20of%20Horizon%20-%20Zero%20Dawn%20-%20ARTR.pdf
2. https://www.guerrilla-games.com/read/the-real-time-volumetric-cloudscapes-of-horizon-zero-dawn
3. https://advances.realtimerendering.com/s2017/Nubis%20-%20Authoring%20Realtime%20Volumetric%20Cloudscapes%20with%20the%20Decima%20Engine%20-%20Final%20.pdf
4. https://advances.realtimerendering.com/s2022/SIGGRAPH2022-Advances-NubisEvolved-NoVideos.pdf
5. https://advances.realtimerendering.com/s2023/Nubis%20Cubed%20(Advances%202023).pdf
6. https://www2.slideshare.net/guerrillagames/nubis-realtime-volumetric-cloudscapes-in-a-nutshell
7. https://80.lv/articles/creating-clouds-in-horizon-zero-dawn
8. https://blog.playstation.com/?p=377555 (Horizon Burning Shores clouds)
9. https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/sky_shader.html
10. https://godotengine.org/article/custom-sky-shaders-godot-4-0/
11. https://en.wikipedia.org/wiki/Day_for_night
12. https://en.wikipedia.com/wiki/Purkinje_shift
13. https://www.premiumbeat.com/blog/why-color-grade-moonlight-blue/
14. https://gizmodo.com/why-is-total-darkness-colored-blue-in-the-movies-5561633
15. https://www.filmlight.ltd.uk/customers/meet-the-colourist/eric_whipp.php
16. https://theasc.com/?p=32532 (John Seale, day for night in Fury Road)
17. https://lowepost.com/casestudies/mad-max-fury-road-r9/
18. https://afcinema.com/The-Theatre-of-Operations.html
19. https://theasc.com/article/lives-under-siege-the-goldfinch-and-1917/
20. https://en.wikipedia.org/wiki/22%C2%B0_halo
21. https://earthsky.org/space/what-makes-a-halo-around-the-moon/
22. https://hyperphysics.gsu.edu/hbase/atmos/halo22.html
23. https://www.timeanddate.com/astronomy/moon/horizon.html
24. https://science.nasa.gov/earth/moon/the-moon-illusion-why-does-the-moon-look-so-big-sometimes/
25. https://giantbomb.com/wiki/Concepts/Oversized_Moon
26. https://advances.realtimerendering.com/s2021/jpatry_advances2021/index.html (Ghost of Tsushima)
27. https://www.seaofthieves.com/it/news/short-haul-3 (Creating Clouds)
28. https://www.seaofthieves.com/news/inn-side-story-4 (Let There Be Light)
29. https://history.siggraph.org/?p=84316 (The Technical Art of Sea of Thieves)
30. https://www.pcgamesn.com/firewatch/there-was-a-lot-of-copy-pasting-jane-ng-talks-creating-firewatchs-wyoming-wilderness
31. https://www.thumbsticks.com/gdc-2015-the-art-of-firewatch
32. https://gamerant.com/red-dead-redemption-2-night-sky-detail-realism-rockstar-games/
33. https://imgeself.github.io/posts/2020-06-19-graphics-study-rdr2
34. https://diglib.eg.org/handle/10.1111/cgf14050 (Hillaire 2020)
35. https://www.ea.com/frostbite/news/physically-based-sky-atmosphere-and-cloud-rendering
36. https://wikipedia.com/wiki/Sky_brightness
37. https://en.wikipedia.org/wiki/Orders_of_magnitude_(illuminance)
38. https://www.planetary.org/articles/night-sky-photography-for-beginners
39. https://skyatnightmagazine.com/astrophotography/astrophoto-tips/astrophotography-during-full-moon
40. https://docs.techsoft3d.com/luminate/latest/book/subjects/bk_sm/bk_sky_model_night.html
41. https://godotshaders.com/shader/screen-space-god-rays-godot-4-3/
42. https://GitHub.com/SIsilicon/Godot-God-Rays-Plugin
43. https://store.godotengine.org/asset/arez/compositor-lens-flare-godrays/
44. https://dev.epicgames.com/documentation/en-us/unreal-engine/using-light-shafts-in-unreal-engine
45. https://godotshaders.com/shader/stylized-sky-with-procedural-sun-and-moon/
46. https://forum.godotengine.org/t/mahamaya-sky-shader-a-totally-procedural-and-realtime-sky-shader-for-godot-4/143941
47. https://www.Github.com/gdquest-demos/godot-4-stylized-sky
48. https://godotshaders.com/shader/starry-sky/
49. https://marian42.github.io/article/no-mans-starfield/
50. https://lamp.ms.wits.ac.za/~branden/CGV/_book/demos/c11/phase-function.html
51. https://blenderartists.org/t/cloud-rendering-in-cycles-study-using-the-horizon-zero-dawns-volume-rendering-techniques/1392665
52. https://blenderartists.org/t/orange-edges-on-clouds/1637388
53. https://forums.unrealengine.com/t/procedural-skies-vs-hdri-what-s-your-lighting-workflow/94294
54. https://80.lv/articles/moonlit-clouds-simulation-made-with-houdini
55. https://80.lv/articles/making-fantasy-house-on-cliff-environment-in-3d
56. https://80.lv/articles/interview-with-blizzards-cgi-artist/
57. https://www.cgw.com/Publications/CGW/2012/Volume-35-Issue-4-June-July-2012/Mysterious-Journey.aspx
58. https://game.watch.impress.co.jp/docs/kikaku/1434499.html (Elden Ring CEDEC 2022)
59. https://www.thegamer.com/elden-ring-best-looking-areas-locations/
60. https://www.dualshockers.com/death-stranding-fog-model-ps4/
61. https://gamedeveloper.com/production/video-learning-to-love-procedural-art-while-making-i-no-man-s-sky-i-
62. https://kingsleysitu.github.io/posts/Moon (Genshin moon / ReShade notes)
63. https://nexusmods.com/witcher3/mods/7434 (Witcher 3 moon brightness)
