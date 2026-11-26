# Critique v1: target concept vs in-engine render (`o7_eyes.png`)

Target: `research/reference_target.webp` (2000x1083). Render: `_shots/o7_eyes.png` (1920x1061, the file is not 1080 tall).
All positions are % of frame (x from left, y from top). Luminance L = Rec.709 weights on sRGB-encoded 0-1 values (perceptual, not linear). "Dark %" = pixels with L < 0.10. The measurement script is in the session scratchpad. The region boxes were placed by hand on each image so they cover the same object in both.

**The short version:** the render has the right props in roughly the right places, but the lighting is backwards. In the target the house is a dark silhouette, and light comes out of it (door, windows) and from the lamp, then pools on snow in the foreground. In the render the house wall is the brightest midtone in the frame (2.1x too bright, and purple). The lamp is dead, the door is shut, the ground is brown dirt instead of snow, and the fence is black instead of rim-lit. Fix the light sources and surfaces first and the framing second. The sky extras (Milky Way, cloud bank, god rays) come last.

---

## 1. Framing

| Feature | Target y% | Render y% | Note |
|---|---|---|---|
| Roof ridge top | 24.0 | 24.7 | same |
| Eave line | 30.5 | 29.2 | |
| House base (foundation) | 64.6 | 57.7 | render house too short |
| Horizon / distant treeline base | ~62 | ~54.7 | render horizon 7 pts too high |
| Gate post tops | 59.6 | 53.7 | |
| Front fence picket tops | 65.5 | 59.2 | |
| Front fence bottom rail | 83.6 | 73.5 | |
| Lamp head top | 52.8 | 49.0 | |
| Foreground ground band (below fence) | 84-100 (16% of frame) | 74-100 (26% of frame) | render shows 60% more empty ground |
| Moon centre (x, y) | 22.1, 10.4 | 27.1, 16.5 | render moon too low and too central |
| Moon diameter (% width) | 4.5 | 5.6 | render moon 25% too big, and visibly oval/tilted, not round |

| Width / size | Target | Render | Ratio T/R |
|---|---|---|---|
| House wall width (% frame width) | 40.5 (x 27.8-68.3) | 36.1 (x 29.9-66.0) | 1.12 |
| House height, ridge to base (% frame height) | 40.6 | 33.0 | 1.23 |
| Fence height, picket top to rail (% frame height) | 18.1 | 14.3 | 1.27 |
| House centre x | 48.0 | 48.0 | yaw is already correct |

**Implied camera change:**
- The fence-to-house height ratio is the same in both (0.45 vs 0.43), so the gap is mostly **magnification, not distance**. The house needs to be about 1.17x bigger (average of width and height) and the fence about 1.25x.
- **FOV:** the player camera is `fov = 70` (vertical, keep_height). tan(35°)/1.17 → **vFOV ≈ 62°**.
- **Dolly:** to give the fence its extra ~7% over the house, move the camera **~0.5-0.8 m closer to the fence** as well. The fence must grow more than the house, and dollying does exactly that.
- **Pitch:** after the zoom, the render's horizon would sit at ~56% and its fence top at ~61%. The target has them at ~62% and 65.5%, so **pitch the camera up ~3-4°**. Content moves down ~5% of the frame; with a 62° FOV that is atan(0.1·tan31°) ≈ 3.4°.
- **Height:** eye height 1.62 m is fine. After the pitch fix, the gap between horizon and house base (render ~3.6 pts, target ~2.6 pts) is within measurement error. If anything, go 5-10 cm lower, not higher.
- **Yaw:** no change; the house is centred at 48% in both.
- If gameplay must stay at 70°, open at 62° and tween to 70° when the player gets control. The first frame is the one that has to match the concept.

---

## 2. Value structure

| Region | Target L | Render L | Render/Target | Target dark % | Render dark % | Verdict |
|---|---|---|---|---|---|---|
| Whole frame | 0.172 | 0.200 | 1.16 | 24.0 | 25.7 | render 16% too bright overall, and the brightness sits in the wrong places |
| Open sky (x55-90, y2-20) | 0.086 | 0.083 | 0.96 | 83 | 92 | level OK; render sky is flatter (no Milky Way texture) |
| Sky around moon / cloud bank | 0.374 | 0.331 | 0.89 | 4.6 | 0 | render 11% too dark, no lit cloud mass |
| Moon disc | 0.831 | 0.711 | 0.86 | 0 | 0 | render moon 14% too dim |
| House wall (between windows) | **0.135** | **0.284** | **2.10** | 3.3 | 0 | **far too bright**: needs to drop to ~0.13 |
| Roof (snow) | 0.272 | 0.289 | 1.06 | 0 | 0 | OK in value; hue wrong |
| Window glass | 0.326 | **0.682** | **2.09** | 0 | 0 | **blown out**: double the target |
| Door | 0.282 (mean of a high-contrast glow) | 0.318 (flat panel) | 1.13 | | | mean OK, but the structure is wrong (see §4) |
| Cobble path | 0.267 | 0.242 | 0.91 | 0 | 0 | slightly dark; lit only near the door |
| Front fence (right run) | **0.115** | **0.047** | **0.41** | 35 | **97** | **far too dark**: 2.4x brighter needed |
| Right gate post | 0.323 | 0.452 | 1.40 | 1 | 2 | too bright, and yellow |
| Lamp glass | **0.491** | **0.338** | 0.69 | | | **lamp is not lit**; target glass core is near white |
| Lamp light pool on ground | 0.311 | 0.384 | 1.23 | | | render ground is lit, but evenly, with no stripes; wrong light source |
| Ground foreground (bottom 12-15%) | 0.168 | 0.207 | 1.24 | 11 | 15 | too bright and the wrong colour (brown, not snow) |
| Trees left | 0.180 | **0.307** | **1.70** | 4 | 0 | **far too bright** |
| Trees right | 0.114 | 0.127 | 1.11 | 47 | 35 | slightly bright, too saturated |
| Mailbox | 0.260 | 0.142 | 0.55 | 33 | 47 | too dark (target is warmly lit by the lamp) |

Whole-frame statistics:

| | Target | Render |
|---|---|---|
| L p5 / p50 / p95 / p99.5 | 0.067 / 0.134 / 0.403 / 0.776 | 0.043 / 0.180 / 0.428 / 0.715 |
| % pixels L < 0.05 (crushed) | 0.4 | 6.0 |
| % pixels L > 0.6 (highlights) | 1.7 | 1.3 |
| Corner / centre L (vignette) | 0.126 / 0.190 (0.66) | 0.157 / 0.266 (0.59) |
| Warm-pixel share (R>B, of L>0.05) | 23.9% | 34.9% |

Row-band means (10 horizontal bands, top to bottom):
- Target: `.141 .171 .189 .143 .143 .166 .209 .192 .210 .157`, darkest at 30-50% (the house), brightest at 60-90% (doorway, path, lamp-lit snow).
- Render: `.145 .169 .195 .216 .228 .234 .197 .192 .222 .202`, **brightest at 30-60%, exactly where the target is darkest**.

**Diagnosis:**
1. The render's midtones are too high (median 0.180 vs 0.134). The house wall and left trees take that excess, so the image looks moonlit-daytime rather than night.
2. Its blacks are crushed (6% vs 0.4% below 0.05). The target has lifted, hazy blacks: p5 is 0.067.
3. Its top highlights are weaker (p99.5 0.715 vs 0.776) because the lamp and doorway, the two hottest points in the target, are not emitting.
4. The warm-pixel share is *higher* in the render (35% vs 24%), but the warmth sits on the brown dirt ground, not in tight pools around light sources. The target is cold overall with small, intense warm islands.

---

## 3. Colour

Mean colour per region (sRGB hex), with HSV of that mean (H°/S/V).

| Region | Target hex | Render hex | Target H/S/V | Render H/S/V | Shift needed |
|---|---|---|---|---|---|
| Whole frame | `#2a2c2e` | `#34313f` | 212/0.10/0.18 | 254/0.23/0.25 | hue −40° (purple → blue-grey), sat ×0.45, V ×0.7 |
| Open sky | `#081821` | `#0d1527` | 201/0.74/0.13 | 221/0.67/0.16 | hue −20° toward teal-navy |
| Moon-side sky/clouds | `#5f5f5d` | `#525368` | 54/0.02/0.37 | 238/0.21/0.41 | desaturate to neutral grey; warm the cloud linings |
| Moon disc | `#e5d1b7` | `#c0b3a6` | 34/0.20/0.90 | 30/0.14/0.76 | brighter (+0.14 V), slightly more saturated cream |
| House wall | `#1d2327` | `#4b455b` | 205/0.27/0.16 | 255/0.24/0.36 | **hue −50° (violet → slate blue-grey), V ×0.45** |
| Roof | `#33485b` | `#364a79` | 209/0.44/0.36 | 222/0.55/0.48 | hue −13°, sat ×0.8, V ×0.75 |
| Window glass | `#744c34` | `#c3a99d` | 22/0.55/0.46 | 18/0.20/0.77 | **sat ×2.7, V ×0.6**: amber, not cream-white |
| Door | `#6c4023` | `#7c463b` | 24/0.67/0.42 | 10/0.52/0.49 | hue +14° (red → orange), sat ×1.3 |
| Path | `#544035` | `#523834` | 21/0.37/0.33 | 8/0.36/0.32 | hue +13° (magenta-brown → amber-brown) |
| Front fence | `#171e24` | `#0a0b17` | 208/0.36/0.14 | 234/0.56/0.09 | hue −26°, sat ×0.65, V ×1.6 |
| Gate post | `#6c4d35` | `#93702c` | 27/0.51/0.42 | 40/0.70/0.58 | **hue −13°, sat ×0.7, V ×0.7**: weathered cream wood, not mustard |
| Lamp glass | `#a4764a` (core ≈ `#fff0c8`) | `#60525b` | 29/0.55/0.65 | 324/0.15/0.38 | make emissive amber |
| Lamp ground pool | `#654a3c` | `#7a5b54` | 21/0.40/0.40 | 11/0.31/0.48 | hue +10°, and confine it to a pool |
| Ground foreground | `#2b2a2d` | `#443030` | 273/0.07/0.18 | 2/0.29/0.27 | **sat ×0.25, V ×0.65**: neutral blue-grey snow, not red-brown dirt |
| Trees left | `#262f35` | `#404e76` | 204/0.27/0.21 | 224/0.46/0.46 | **hue −20°, sat ×0.6, V ×0.45** |
| Trees right | `#141e26` | `#152137` | 205/0.47/0.15 | 220/0.61/0.22 | hue −15°, sat ×0.75, V ×0.7 |
| Mailbox | `#5f3b30` | `#4e1819` | 13/0.49/0.37 | 359/0.69/0.31 | hue +14°, sat ×0.7, V ×1.2: rust-red, not fire-engine red |

**Global colour read:**
- Everything cool in the render is pushed toward **blue-violet (hue 220-255)**. The target's cools are **teal-slate (hue 200-210)** with low saturation (0.1-0.3).
- The render's ambient `Color(0.3, 0.38, 0.6)` and moon `Color(0.55, 0.66, 1.0)` are the violet source. Move both toward `#7f97a8`-ish (≈ Color(0.50, 0.59, 0.66)).
- Everything warm in the render leans **red (hue 0-18)**. The target's warms are **amber-orange (hue 21-29)**.

---

## 4. Element-by-element differences (ranked by visual impact)

### 1. Lamp (the left-foreground street lamp): highest impact
- **Wrong:**
  - In the target it is the key light of the whole lower half. The glass glows near white with an amber falloff (`#a4764a` mean). It throws **long picket-fence shadow stripes toward the camera** across the snow (x 5-35%, y 84-92%).
  - In the render the glass is dead grey-violet (`#60525b`, L 0.34). There are no fence-shadow stripes. The lamp head reads as a black silhouette.
  - `StreetLamp` has `glow_surfaces = ["glass","bulb"]` with `glow_energy = 7`, so the surface names almost certainly do not match the glTF's material/surface names and no emission is applied.
  - `FenceShadowLight` (energy 5, range 8) sits at z 9.72, 1.28 m *in front of* the lamp. Its shadows of the fence are not landing on the near ground the way they do in the target.
- **Fix:**
  - Debug `snowy_prop.gd` surface matching: print the surface/material names of `street_lamp_02` and set `glow_surfaces` to the real ones. Emission `#ffb766`, energy 6-8, so the glass core clips above the glow threshold (1.4).
  - Put one shadowed OmniLight3D **inside the glass**: colour `#ffad5c`, energy 4-6, range 7-9 m, attenuation ~1.2, `shadow_enabled`, `light_size` 0.03-0.05 (crisp stripes).
  - It must sit **on the house side of the fence** (or the fence must lie between light and camera), so the picket shadows fall toward the viewer as in the target. If the lamp is on the camera side of the fence, move the light to just behind the fence line at y ≈ 1.6 m, offset ~0.3 m toward the house.
  - Drop the separate `StreetLampLight` (0.5 energy) or fold it in.
  - Target result: glass region L ≈ 0.50, ground pool L ≈ 0.31 with clearly alternating light/shadow stripes.

### 2. Door and doorway
- **Wrong:**
  - The target's door is **open**: a deep doorway with a warm interior glow, a flame/ember figure at the threshold, and sparks drifting up. Two lit wall lanterns sit right of the door, and a column porch frames it. Warm spill runs down the steps onto the path.
  - The render's door is a closed, flat red-brown panel (`#7c463b`, hue 10). It has one tiny sconce and no spill beyond a small specular patch.
- **Fix (cheap):**
  - Swap the door albedo for a dark recess and put an emissive interior card behind the frame (`#ff9a3c`, energy 3-5, gradient brighter at the floor).
  - Place an OmniLight3D just inside the threshold: `#ffa050`, energy 3, range 5 m, shadows on, so it lights the steps and the first 3 m of path.
  - Raise `PorchLanternLight` from 1.2 to ~2.5 and add a second sconce on the right of the door. Give both sconce glasses emission.
- **Fix (geometry, costly):** open the door (rotate the leaf ~70° inward) and model a shallow interior vestibule so the glow has depth.

### 3. Windows
- **Wrong:**
  - Render glass is nearly uniform cream-white, L 0.68 (`#c3a99d`, sat 0.20): twice the target's value and a third of its saturation.
  - The target's windows are amber (`#744c34`, sat 0.55) with **curtains, cross mullions and plant silhouettes on the sill**, brighter at the centre and darker at the edges.
- **Fix:**
  - In `house_exterior.gd`, the `_glow_mat` is unshaded with `albedo = window_color * 1.6`. Drop the multiplier to ~0.9 and set `window_color` to ≈ `#e08a45`.
  - Better: add a texture with curtain drapes plus a radial gradient (centre `#ffb36b`, edges `#6a3a1c`) and dark mullions.
  - Target: glass mean L ≈ 0.33, peak L ≈ 0.75 at the centre only.

### 4. House wall and roof (value inversion)
- **Wrong:**
  - The wall measures L 0.284 vs 0.135 (2.1x), hue 255 (violet) vs 205 (slate).
  - The target house is a near-silhouette lit only by its own openings and a faint cold rim. The render lights it front-on like a stage set.
  - The roof is too blue and saturated (sat 0.55 vs 0.44). It has no icicles and no snow-edge texture.
- **Fix:**
  - Darken the wall albedo ~40% toward `#3a4248`.
  - Cut `MoonFill` energy from 0.08 to 0.02-0.03 (it is the front fill hitting the wall). Cut `ambient_light_energy` from 0.12 to 0.06 and change `ambient_light_color` to ≈ Color(0.42, 0.50, 0.58).
  - Reduce `sdfgi_energy` 1.1 → 0.7. SDFGI bounce off the bright ground is probably lifting the wall.
  - Target wall L ≈ 0.13-0.15.
- **Geometry (cheap):** an icicle strip along the eave.

### 5. Snow and ground
- **Wrong:**
  - Render foreground ground is red-brown dirt with leaf litter (`#443030`, hue 2, sat 0.29). The target is a thin, frosted snow layer over dark ground (`#2b2a2d`, sat 0.07), with whiter drifts against the fence base, posts, path edges and the right half.
  - There is no snow on the fence tops, post caps, mailbox or lamp roof in the render. The target has snow caps on all of them.
- **Fix:**
  - Blend a snow layer into the ground material: world-normal-up mask × noise, snow albedo `#c9d2dc`, roughness 0.6, coverage ~60% with dirt showing through, more along the fence line.
  - Apply the same top-facing snow mask to the fence, posts, mailbox and lamp. `snowy_prop.gd` already exists, so make sure it is applied to these props.
  - Target ground foreground mean ≈ `#2b2a2d`, L 0.17, with bright lamp-lit snow crests reaching L 0.4-0.5.

### 6. Fence and gate posts
- **Wrong:**
  - The front fence is near-black: L 0.047, 97% dark pixels, violet `#0a0b17`. The target fence is weathered light wood with warm lamp rim light and cold moon rim (L 0.115, `#171e24`), and individual pickets read clearly.
  - The right gate post is saturated mustard yellow (`#93702c`) and reads as a hazard post. The target posts are pale weathered wood with moss stains and snow caps (`#6c4d35` in shadow, cream where lit).
- **Fix:**
  - Raise picket albedo to ≈ `#8a7d6c` (weathered grey-cream) and roughness 0.85. Once the lamp light (fix 1) and door light (fix 2) are behind and among the pickets, they will rim-light.
  - Retint both gate posts' albedo from yellow to ≈ `#a89a84`, keeping the stain texture.
  - Target fence region L ≈ 0.11-0.12.

### 7. Pines
- **Wrong:**
  - Left trees are L 0.307 vs 0.180 (1.7x) and saturated periwinkle (`#404e76`). They are low-poly flat cards lit evenly by the front moon fill, which reads as papercraft.
  - The target pines are dense, dark slate (`#262f35`), with snow only on the upper surfaces of the branch tiers and deep shadow under each tier. Distant trees fade into haze.
- **Fix:**
  - Darken the foliage albedo to ≈ `#1f2a2c` (desaturated green-slate).
  - Add a world-up snow mask so only the tops of the branch tiers catch snow (`#b8c4d0`).
  - Turn on shadow casting among the tiers.
  - Raise volumetric fog density (fix 9) so the back rows drop in contrast.
  - Target trees left L ≈ 0.18, saturation ≤ 0.3.
- **Geometry (optional, moderate):** higher-tier-count pine meshes, or billboards with alpha-cut branch silhouettes.

### 8. Sky and clouds
- **Wrong:**
  - The target has a large, **dark cumulus bank** running from the moon to the right across ~10-45% x, 0-25% y. Its edges are lit warm silver. Cloud wisps sit in front of the moon and the bank opens up toward the Milky Way.
  - The render has one small grey wisp under the moon. The sky near the moon is violet (`#525368`) instead of neutral grey (`#5f5f5d`).
- **Fix (sky shader):**
  - `cloud_far` 0.4 → 0.12; `cloud_cover` 0.46 → 0.38; `cloud_scale` 2.0 → 1.4 (bigger puffs).
  - `cloud_focus_spread` right lobe 0.75 → 1.1 and down lobe 0.25 → 0.35.
  - `cloud_body_color` → ≈ `#262b33` and `cloud_lining_color` → `#e9d2a8`.
  - Target: the moon-side sky region L ≈ 0.37, saturation < 0.05.

### 9. God rays
- **Wrong:** the target has clear crepuscular shafts fanning down-right from the moon through the left pines toward the house roof (x 10-35%, y 15-45%). The render has none, despite volumetric fog and `light_volumetric_fog_energy = 1.6`.
- **Fix:**
  - Volumetric fog density 0.011 is too thin for shafts. Raise `volumetric_fog_density` to ~0.025 and `anisotropy` 0.7 → 0.8.
  - Raise the Moon DirectionalLight's `light_volumetric_fog_energy` to 4-6.
  - The moon light must come from **upper-left, behind the trees**, with the trees' shadows cutting the fog. The current Moon transform lights the left trees front-on, so they cast no visible shafts toward the camera.
  - Fallback: 3-4 additive, soft-edged, depth-faded ray cards (`#9fb0c0`, alpha 0.08-0.15) parented near the left treeline.

### 10. Moon
- **Wrong:**
  - Render moon is at (27%, 16.5%). It should be at (22%, 10%).
  - Its diameter is 5.6% of frame width; it should be 4.5%.
  - It is too dim (L 0.71 vs 0.83) and greyer (`#c0b3a6` vs `#e5d1b7`).
  - It is **visibly elliptical/tilted**, which looks like a bug in the sky-shader projection (or `moon_size` combined with the aspect ratio).
- **Fix:**
  - Rotate the moon direction ~4° left and ~5° up in view terms. At vFOV 62 the shift is ≈ −5% x and −6% y.
  - Set `moon_size` so the disc is ~4.5% of frame width after the FOV change. Rendered size scales with 1/FOV, so a FOV of 62 makes it ~13% larger: cut `moon_size` from 0.05 to ≈ 0.036.
  - Raise `moon_energy` until the disc centre reaches L ≈ 0.85 after tonemapping.
  - Check that the disc is computed from the angle between the view direction and the moon direction (`acos(dot(EYEDIR, moon_dir))`), not in a UV space that stretches.

### 11. Milky Way
- **Wrong:** the target has a visible diagonal band, bluish with bright clumps, from (55%, 25%) to (100%, 0%). In the render it is absent from this view even though `milky_way = 3.5`.
- **Fix:** rotate `milky_way_pole` or slide `band_offset` so the band crosses the upper-right quadrant, rising from right of the roof to the top-right corner. Keep the strength at 2-3. Target open-sky region: same mean L (~0.086) but with visible structure.

### 12. Embers / ember-moths
- **Wrong:**
  - Both images have the spark trail streaming off the right roof corner; that part matches well.
  - The target has **4-5 distinct glowing moth/butterfly shapes**: amber `#ffb050` with a bright core, at (74%, 28%), (83%, 36%), (75%, 46%), (88%, 46%).
  - The render has two orange blobs (~74%, 42% and 89%, 40%) that read as glitches or fruit, not moths.
- **Fix:** use a wing-shaped sprite texture (two lobes, soft glow) with emission `#ffa84a` at energy 4-6 so glow catches it, and ~16-24 px apparent size. Add a slow flap via a scale-x sine and a tiny trailing spark emitter on each. Spread 4-5 of them over x 70-90%, y 25-50%.

### 13. Snowfall
- **Wrong:** the target has sparse, soft, large out-of-focus flakes (bokeh discs at ~(13%, 2%), (64%, 16%), (93%, 60%) etc.) plus fine mid-distance snow. No falling snow is readable in the render.
- **Fix:** in `snowfall.tscn` add a second, near-camera emitter: 15-30 large soft discs (alpha 0.25-0.4, 6-14 px, slow fall). Keep the fine layer but make sure it is lit by the lamp and door lights (unshaded white looks wrong). Make sure snowfall is active in the opening frame.

### 14. Framing branch
- **Wrong:** the target has a dark pine bough hanging into the top-left corner (x 0-25%, y 0-40%), with a warm/silver rim from the moon. It frames the moon and pushes the eye toward the house. The render has an awkward partial pine trunk and flat branches cut by the left edge, which reads as a clipping tree rather than a deliberate frame.
- **Fix:** `title_sequence.gd` already has `foreground_branches`; give the player's opening view an equivalent. Parent a pine-bough mesh or alpha card to the opening camera at ~1.5 m, upper-left, dark albedo `#10161a` with moon backlight. Remove or shift the left-edge tree so it does not compete.
- **Geometry:** small new prop.

### 15. Vignette and post
- **Measured:** corner/centre ratio target 0.66, render 0.59. The render's vignette is similar or slightly stronger, but its centre is too bright (the house). Once the house darkens, `vignette = 0.32` will feel about right; maybe lower it to 0.25.
- **Fix:**
  - Lift the blacks. Target p5 0.067 vs render 0.043, and the render has 6% crushed pixels vs 0.4%. Lower `adjustment_contrast` 1.08 → 1.0 and `tonemap_agx_contrast` 1.2 → 1.05.
  - Add a faint blue-grey fog/haze floor through fog (fix 9) rather than by lifting exposure.
  - Lower `adjustment_saturation` 1.05 → 0.9 to tame the violet.
  - Keep `tonemap_exposure` 0.82 until the house/ground are fixed, then re-measure: the frame mean should end near 0.17.

### 16. Mailbox (minor)
- **Wrong:** saturated red `#4e1819` vs rust-red `#5f3b30`. No snow cap, no "POST" lettering.
- **Fix:** albedo toward `#8a3a2a` with roughness 0.7, a top snow mask, and a decal reading "POST".

### 17. Path (minor)
- **Wrong:** the render's path is narrow and only lit by a wet specular patch at the door, and its hue is magenta-brown. The target's path is wide and well-defined: rounded cobbles brightly lit along its whole length from the doorway, with frosted edges and grass tufts.
- **Fix:** more warm light reaching it (fix 2). Retint to amber-brown (`#544035`), add a cobble normal map with stronger relief, roughness 0.45 (damp, not mirror), and edge snow.

---

## 5. Top 10 fixes (priority order)

1. **Light the street lamp properly.** Fix `glow_surfaces` names so the glass emits (`#ffb766`, energy 6-8). Put one shadowed OmniLight in the glass (`#ffad5c`, energy 4-6, range 8, `light_size` ~0.04), placed so picket shadows stripe toward the camera. Targets: glass L 0.50 (now 0.34); ground pool L ~0.31 with stripes.
2. **Kill the front fill on the house.** `MoonFill` 0.08 → 0.02-0.03; `ambient_light_energy` 0.12 → 0.06; ambient colour → Color(0.42, 0.50, 0.58); `sdfgi_energy` 1.1 → 0.7; wall albedo −40% toward `#3a4248`. Target: wall L 0.135 (now 0.284), hue ~205 (now 255).
3. **Make the doorway glow.** Dark recess plus emissive interior card (`#ff9a3c`, energy 3-5) and an OmniLight at the threshold (`#ffa050`, energy 3, range 5, shadows). Porch sconce light 1.2 → 2.5, add a second sconce. Opening the door leaf is the geometry upgrade.
4. **Turn the ground into snow.** World-up snow blend on the ground (albedo `#c9d2dc`, ~60% coverage, more at the fence line), plus snow caps on fence, posts, mailbox and lamp. Target ground-foreground colour `#2b2a2d`, sat ≤ 0.1 (now `#443030`, sat 0.29).
5. **Reframe the opening shot.** Player camera vFOV 70 → **62**, dolly **0.5-0.8 m** toward the fence, pitch **+3.5°**. Targets: ridge 24%, house base 64.5%, fence top 65.5%, fence bottom 83.5%, house width 40.5% of frame.
6. **De-blow the windows.** `_glow_mat` multiplier 1.6 → ~0.9, `window_color` ≈ `#e08a45`, and a curtain/mullion/gradient texture. Target: glass mean L 0.33 (now 0.68), saturation 0.55 (now 0.20).
7. **Retint all the cools from violet to slate and darken the pines.** Moon light colour → ≈ Color(0.62, 0.72, 0.85); foliage albedo → `#1f2a2c` with top-only snow; `adjustment_saturation` 1.05 → 0.9. Targets: left trees L 0.18 (now 0.31); cool hues 200-210 (now 220-255).
8. **Fence and gate posts.** Pickets to weathered `#8a7d6c` so they catch lamp and door rim light; gate posts from mustard `#93702c` to `#a89a84`. Target: fence region L 0.115 (now 0.047, 97% black).
9. **Sky composition.** Moon to (22%, 10%), diameter 4.5% of width (`moon_size` ≈ 0.036 at FOV 62), and fix the oval disc. Clouds: `cloud_far` 0.4 → 0.12, `cloud_cover` 0.46 → 0.38, `cloud_scale` 2.0 → 1.4, a wider right lobe for the lit cumulus bank. Rotate the Milky Way into the upper-right quadrant.
10. **Atmosphere and finishing.**
    - God rays: fog density 0.011 → 0.025, Moon `light_volumetric_fog_energy` → 5, with the moon light coming from behind the left pines.
    - Lift the blacks: `adjustment_contrast` → 1.0, AgX contrast → 1.05; target < 1% of pixels below L 0.05 (now 6%).
    - Ember-moths as wing sprites (4-5 of them, emission `#ffa84a`).
    - Near-camera bokeh snowflakes.
    - A top-left framing pine bough on the opening camera.

**Geometry items (costly; flag only):**
- open front door with interior vestibule;
- eave icicle strip;
- higher-detail pine meshes;
- framing bough prop;
- second door sconce and porch columns to match the target.
