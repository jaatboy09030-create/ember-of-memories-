# 07 — Practical Lights: Lit Windows, Lanterns, Doorways and Long Cast Shadows

*Research for **Unsent**, a Godot 4.7 Forward+ project. This covers the opening shot: a snowy two-storey house at night, 19 warm windows, an open door with a flame inside, a wall lantern, a foreground lamp-post on the fence, picket shadows reaching toward the camera, and a cobblestone path with a warm sheen.*

---

## 1. Takeaways

1. **"Practicals" are light sources you can see in the frame.** Windows, lanterns, the door and the flame are all practicals. They do two jobs at once: they light the scene and they act as graphic elements in the composition. Treat their visible glow (emissive) and their effect on the world (real lights or decals) as **separate, separately tuned** systems. Almost every shipped game decouples them.
2. **A glowing window is mostly a texture.** In a typical shipped game, a window at night is an emissive surface with some fake depth. It is rarely a real light. Real lights are saved for the 2–4 places where light has to *touch* something the player looks at, such as a sill, snow, a path or a fence.
3. **Value hierarchy beats light count.** Lighting artists keep repeating that the job is controlling value, separation and focal hierarchy, not adding lights. In the reference image, 19 windows read as a single pattern, a mid-tone "texture" of warmth. Only three things are hot: the foreground lantern, the door flame and the wall lantern.
4. **The door is the focal point.** It is the warmest, brightest and highest-contrast spot. It sits in the frame centre at the end of a leading line (the path). Everything else should be dimmer, less saturated or both.
5. **Shadows toward the camera come from backlight.** Put the light *behind* the occluder relative to the lens. Cinematographers use this because it gives depth and shape and needs fewer lights. In games it also turns a fence into a set of leading lines that point into the frame.
6. **Wet stone shows its sheen through specular, not diffuse.** Wetness darkens and saturates albedo and drops roughness sharply. Standing water in the low spots goes almost mirror-smooth. Without a bright source in the reflection direction, a wet surface just looks dark. The warm glint needs the door light *behind* the path, seen from the camera.
7. **Soft, distance-dependent shadows sell scale.** A small lantern still has a physical size. In Godot, a non-zero `light_size` gives PCSS contact-hardening shadows: sharp at the picket base, soft at the tips. That is exactly what makes the long shadows in the reference feel real.
8. **Attenuation is an art control, not physics homework.** True inverse-square falloff (`attenuation = 2`) makes lanterns hot right next to them and dead a few metres out. For a stylised postcard look, a softer curve (≈0.8–1.2) plus a tight range reads more like a painting.

---

## 2. Techniques

### 2.1 Lit windows from the outside

**Emissive glass and the "emissive blob."** The cheapest version is an emissive texture behind or on the glass. Polycount artists recommend painting simple shapes (rectangles, gradients, strokes for frames and curtains) rather than detailed interiors. They also recommend avoiding true transparency on glass because it is expensive and prone to sorting errors. Fake the glass with high metalness or low roughness so it reflects, and put the glow on an opaque layer behind it. A known trap: a flat emissive plane hides everything behind it, so the window reads as a solid card. The fix is variation inside the window: a gradient, curtain folds, silhouettes, and occasionally a darker room.

**Curtains and back-lit fabric.** Sheer curtains are the most useful trick for cozy scenes. They hide the fact that there is no interior, and they turn a flat emissive into something soft and layered. Brightness falls off from a warm centre toward darker, gathered folds at the edges. Window frames and mullions silhouette against them. In Godot's `BaseMaterial3D`, `backlight_enabled` and `backlight` (colour/texture) let light from *behind* a surface show through thin geometry. Subsurface transmittance is the alternative. For a window that is always lit, emissive is cheaper and fully controllable.

**Interior mapping / parallax rooms.** Joost van Dongen's 2008 CGI paper *Interior Mapping* casts a ray from the eye into a virtual grid of floors, ceilings and walls inside the building. The walls are treated as infinite planes at regular spacing, so only three planes need testing: one floor-or-ceiling and two walls. The nearest hit picks both the texture and the UV. Extensions include random rooms from an atlas, uneven wall spacing, and extra furniture layers. SimCity (2013) used an atlas version. Van Dongen thinks Marvel's Spider-Man uses the technique too: its rooms have real perspective depth but give themselves away with doors where windows should be and furniture that looks like flat cards. Unreal ships an `InteriorCubeMap` node. Gaijin's Dagor engine has a `rendinst_interior_mapping` shader. Godot has several community versions on godotshaders.com and the Asset Library, including an atlas-based one with no cubemap that stores rear-wall depth in alpha. A Polycount reply suggests a split: plain emissive at distance, parallax cubemap up close.

**Spill onto sills and snow.** Spill is what makes windows feel like *light sources* rather than stickers. It shows as a warm wash on the sill, a soft trapezoid on the snow below, and warm rim highlights on the frame. A real light per window is usually too expensive and too noisy. Common substitutes are:
- an emissive or projected **decal** on the ground (a soft trapezoid);
- one unshadowed spot per *group* of windows;
- a baked or painted gradient on the facade under each window.

**Window light cookies.** When light leaves a window, its shape is a cookie: a projected mask showing mullions and curtain gaps. A spot light with a projector texture throws a window-pane pattern onto the snow. It is very cheap if shadows are off, because the cookie *is* the shadow.

### 2.2 Lanterns and street lamps

- **Emissive housing.** The glass panes carry an emissive texture brighter at the centre. The metal frame stays dark and acts as a silhouette, and a small bloom halo does the rest. Keep the emissive colour slightly more saturated than the light's colour so the source reads as "hot."
- **Flicker.** Real flame flicker is low-amplitude (±5–12% energy) and low-frequency with occasional dips. Drive energy *and* emissive from the same noise so the housing and its light pulse together. Godot's Asset Library has a "Flickering Light (2D & 3D)" add-on that uses Quake-style lightstyle strings. A `FastNoiseLite` sample in `_process` works just as well. Avoid moving the light position too much, because shadows will swim.
- **IES profiles.** These are measured photometric distribution curves from fixture manufacturers. Unreal applies them to point, spot and rect lights. They are cheap and shape the bright cone under a street lamp and the dark "cap" above it. Godot has no native IES. Approximate it with a spot projector texture, or with an omni light plus a dark upper hemisphere painted into a panorama projector.
- **Light cookies / projectors.** In Godot 4, OmniLight3D and SpotLight3D take `light_projector`. Omni lights need a 360° panorama. Spots behave like a decal. Projectors *multiply* the light colour, so raise energy to compensate. The project-wide filter is under Rendering → Textures → Light Projectors.
- **Fence and picket shadows.** Any shadowed light placed low and just behind a picket fence throws a fan of long stripes. The lower and closer the light is to the fence, the longer and more spread out the stripes.
- **Backlighting toward camera.** Put the source on the far side of the occluders from the camera. You get long shadows running toward the lens, rim light on the pickets' edges, and a lit-from-behind silhouette. Film lighting guides recommend this for night exteriors precisely because one backlight can do the work of several lights.

### 2.3 Open doorways as focal points

A bright opening in a dark wall is the oldest focal device in painting and level design. The "light at the end" works because:
- it is the **highest local contrast** in frame;
- it sits at the end of a **leading line** (the path);
- the frame-within-frame (door jamb and porch) **crops** it;
- light spills **outward** onto the step and path, connecting it to the viewer.

In practice the doorway is an emissive interior plane, an optional flame, and a single real warm light just inside the door. That light throws a trapezoid of light out onto the porch and path, and it supplies the specular source for the wet cobbles.

### 2.4 Warm light pooling on wet stone

Sébastien Lagarde's *Observe rainy world* blog series (Dontnod, Remember Me) and later porous-media papers set out the model:
- porous materials such as stone, brick and soil get **darker and more saturated** when wet;
- **specularity rises and roughness falls**;
- **puddles** collect in low areas and become almost mirror-smooth;
- upward-facing surfaces get wet first.

Community starting values:
- wet roughness ≈ 0.07–0.2 and specular ≈ 0.3–0.5 for rain-soaked surfaces;
- puddle roughness ≈ 0.005–0.05;
- albedo multiplied by ≈ 0.5–0.75.

Rain ripples are a normal-map effect, separate from these. For a still, snowy night you want *damp* stones: a mid-low roughness on the stone tops, near-mirror in the grout puddles, and dry, rough snow at the edges.

Roughness **variation** matters more than any one roughness value. A uniformly glossy path looks like plastic. A mottled one (some stones dull, some glinting, grout pooling) reads as wet stone.

### 2.5 Shadow softness and contact shadows

- **PCSS / contact-hardening.** In Godot, a light with non-zero `light_size` (omni/spot) or `light_angular_distance` (directional) gives shadows that are sharp at the contact point and blur with distance. That is the correct look for picket shadows. Higher values are also more temporally stable.
- **`shadow_blur`** multiplies the filter radius. It is softer and more stable but shows more dither noise.
- **Bias.** Prefer raising `shadow_normal_bias` over `shadow_bias`, because it causes less peter-panning. The defaults are 0.1 and 2.0.
- **Contact shadows.** Small gaps under objects (the mailbox base, fence posts on snow) need SSAO or screen-space contact shadows. Recent Godot builds add screen-space contact shadows for Forward+; this is community-reported, so check it in the 4.7 project settings. Otherwise use SSAO with a small radius.
- **Cull masks.** `light_cull_mask` removes objects from a light's *lighting* but **they still cast shadows**. To stop casting, use the geometry's Cast Shadow setting or the light's `shadow_caster_mask` (default all layers). This pairing is the key tool for "shadow-only" cheats.

### 2.6 Falloff and attenuation

- Godot `omni_attenuation` / `spot_attenuation` behave as follows:
  - **0**: almost flat brightness, fading only near the edge of the range;
  - **2**: physically correct inverse-square;
  - **above 2**: distant receivers starve.
- Range is a hard cut-off and is not affected by node scale.
- `distance_fade_*` culls lights far from the camera. It is useful for the window spill lights if the camera moves.
- Physical light units are optional (Project Settings → Rendering → Lights and Shadows → Use Physical Light Units). They add `light_temperature` in Kelvin (6500 K = white, lower = warmer) and lumen intensities. The camera exposure then needs tuning (aperture ≈ 2–4 for night or interior). For a stylised single shot, staying in non-physical units with hand-picked colours is simpler.

### 2.7 How many practicals?

There is no fixed number, but a hierarchy holds up across references:
- **1 hero**: the brightest, warmest and most contrasty source, ideally at the focal point;
- **1–2 secondaries**: they frame or lead toward the hero;
- **any number of "pattern" lights**: repeated windows at matched, lower intensity, read as one texture.

The scene loses focus when two sources compete for "brightest" at similar size, or when pattern lights vary too wildly. Skyrim ENB users complain about exactly this: windows outshining candles. In the reference, the foreground lantern is the brightest *object*, but the door wins as the focal point because it is centred, framed and at the end of the path.

---

## 3. Examples

- **Red Dead Redemption 2 towns (Valentine, Saint Denis at night):** heavily baked indirect light with a few dynamic practicals. Moon and lamps cast dynamic shadows only at High/Ultra lighting quality. Windows are warm emissive with curtains and silhouettes, and the gas lamps throw pools on mud and boardwalks with strong roughness variation. Lesson: bake or fake most of it, and spend dynamic shadows where the eye lands.
- **The Witcher 3 villages:** modders describe much of the village lighting as faked. Night torches were overexposed enough that mods exist to tame them. Lesson: clamp emissive or bloom on fire so it stays a shape, not a white blob.
- **Kingdom Come: Deliverance 1 & 2:** naturalistic CryEngine darkness where you genuinely cannot see past torchlight. KCD2 is seen as more art-directed, with warmer, more controlled pools. Lesson: darkness between pools is what makes pools read.
- **Skyrim + ENB / ELFX:** ENB has a dedicated "Windowlight" glow setting split by time of day and interior/exterior. ELFX retunes window emittance. Lanterns-of-Skyrim-style mods turn emissive on at dusk. Lesson: window glow needs its own intensity curve, separate from real lights.
- **Marvel's Spider-Man / SimCity:** interior mapping at city scale. Close up it reads as parallax depth, at distance as variety. Lesson: even a cheap atlas of 4–8 rooms kills repetition.
- **The Last of Us (1 & Part II):** dominant directionality and ambient shadows. A community note says the flashlight bounce used a point light sampling the hit colour for fake GI. Lesson: a small bounce light near a hot practical sells it cheaply.
- **Alan Wake 2:** single light sources set against oppressive darkness. Harsh or coloured practicals carry meaning, and grading was done in HDR by colourists. Lesson: let practicals clip into bloom deliberately, and keep everything else low.
- **A Plague Tale: Innocence:** fire is both mechanic and composition (rats avoid torch radii), and the lighting references Claude Lorrain paintings. Lesson: warm pools are also gameplay-readable safe zones.
- **Hogwarts Legacy winter:** snowy dusk-to-night with warm windows against cool snow. Its lighting artists' ArtStation work shows strong warm/cool split and soft spill on snow. Lesson: the complementary contrast (amber against blue snow) does most of the work.
- **Firewatch:** stylised, graphic colour with fog for depth and a dynamic sky solution for shifting palettes. Lesson: a stylised palette can outweigh physical accuracy.
- **Cozy games** (e.g. A Short Hike, Unpacking-adjacent dioramas, Spiritfarer): soft attenuation, fully lit windows, bloom, and nearly no hard darkness. Lesson: lower contrast plus warm saturation reads as "safe."

---

## 4. Apply to Unsent's opening

**Assumed scale:** 1 unit = 1 m, camera roughly 8–10 m from the fence, house about 10 m behind the fence. Values are starting points to tune by eye with Glow on.

### 4.0 Light budget for the shot

| Role | Node | Shadows | Notes |
|---|---|---|---|
| Hero focal | Door interior OmniLight + flame emissive | Yes (cube) | Gives the cobble glint |
| Secondary 1 | Foreground fence lamp-post OmniLight | Yes, PCSS | Gives the picket shadows |
| Secondary 2 | Wall lantern OmniLight | Optional (dual-paraboloid) | Lights the porch |
| Pattern | 19 window emissives | — | No real lights |
| Spill | 2–3 unshadowed SpotLights or Decals under window groups | No | Lights the snow and sills |
| Fill | Moon DirectionalLight, cool and weak | Yes | Uses `light_angular_distance` ≈ 0.5 |

That is **3 shadowed point lights**. It is comfortable for Forward+ (the clustered limit is 512 elements; the cost is shadow atlas space). Set Project Settings → Rendering → Lights and Shadows → Positional Shadow → Atlas Size to 4096 (the default). Give the fence lamp the largest quadrant subdivision.

### 4.1 Colour palette (K → RGB, approximate blackbody)

| Source | K | RGB 0–255 | Godot Color (linear-ish, editor sRGB) |
|---|---|---|---|
| Flame in doorway | 1800 K | 255, 126, 0 | `Color(1.0, 0.49, 0.0)` |
| Lantern glass, fence lamp | 2000 K | 255, 137, 14 | `Color(1.0, 0.54, 0.06)` |
| Wall lantern light | 2200 K | 255, 147, 44 | `Color(1.0, 0.58, 0.17)` |
| Window curtains (centre) | 2400 K | 255, 155, 61 | `Color(1.0, 0.61, 0.24)` |
| Window curtains (edges/folds) | 1900 K, darker | 200, 95, 25 | `Color(0.78, 0.37, 0.10)` |
| Moon fill | 7500–9000 K | 200, 215, 255 | `Color(0.62, 0.70, 1.0)` at energy 0.08–0.15 |

If you enable Physical Light Units, set `light_temperature` to these Kelvin values and leave `light_color` white. Otherwise use the RGB column with `light_temperature` ignored.

### 4.2 Emissive curtain-window shader

Apply this to each dark glass quad (replace its material). Use an `instance uniform` so the 19 windows vary without 19 materials.

```glsl
shader_type spatial;
render_mode unshaded, cull_back; // emissive-only surface behind glass

uniform vec3 warm_center : source_color = vec3(1.0, 0.61, 0.24);
uniform vec3 warm_edge   : source_color = vec3(0.78, 0.37, 0.10);
uniform float emission_energy = 3.0;          // >1 so Glow picks it up
uniform float curtain_gap = 0.22;             // width of the bright gap between panels
uniform float fold_count = 7.0;
uniform vec2 mullions = vec2(2.0, 2.0);       // panes across, panes down (match the frame)
uniform float mullion_width = 0.035;
instance uniform float window_seed = 0.0;     // set per MeshInstance (0..1)
instance uniform float brightness = 1.0;      // 0.7..1.1 per window; 0 for an unlit room

float hash(float n) { return fract(sin(n * 91.345) * 47453.53); }

void fragment() {
    vec2 uv = UV;
    // 1. warm radial core, slightly low (lamp on a table inside)
    float core = 1.0 - smoothstep(0.0, 0.75, distance(uv, vec2(0.5, 0.42)));
    vec3 col = mix(warm_edge, warm_center, core);

    // 2. sheer curtain panels: gathered folds darker toward the outer edges
    float side = abs(uv.x - 0.5);
    float panel = smoothstep(curtain_gap * 0.5, curtain_gap * 0.5 + 0.05, side);
    float folds = 0.5 + 0.5 * sin(uv.x * fold_count * 6.2831 + window_seed * 10.0);
    float density = panel * mix(0.55, 0.85, folds) * smoothstep(0.0, 0.5, side + 0.1);
    col *= 1.0 - density * 0.55;               // backlit fabric: dims but never goes black

    // 3. optional silhouette (plant on sill): dark blob along the bottom
    float plant = smoothstep(0.12, 0.08, distance(uv * vec2(1.0, 2.2),
                    vec2(0.3 + hash(window_seed) * 0.4, 0.06 * 2.2)));
    col *= 1.0 - plant * 0.85;

    // 4. mullions as silhouettes
    vec2 g = fract(uv * mullions);
    float bar = step(g.x, mullion_width) + step(1.0 - mullion_width, g.x)
              + step(g.y, mullion_width) + step(1.0 - mullion_width, g.y);
    col *= 1.0 - clamp(bar, 0.0, 1.0) * 0.9;

    // 5. sill glow: brighter bottom edge (light hitting the sill)
    col += warm_center * smoothstep(0.12, 0.0, uv.y) * 0.25;

    ALBEDO = vec3(0.0);
    EMISSION = col * emission_energy * brightness * mix(0.85, 1.1, hash(window_seed + 3.0));
}
```

Notes:
- If the Tripo frames already contain mullions, drop step 4.
- Keep the actual **glass** as a separate thin quad in front with `metallic 0.0, roughness 0.05, specular 0.6`, alpha ≈ 0.15. Or skip alpha and add only a faint reflection via a ReflectionProbe. This gives the frosty sheen in front of the glow.
- With `unshaded`, the material ignores scene lights, which is what you want for a fixed postcard shot.
- Set **Environment → Glow**: enabled, intensity 0.8, strength 1.0, bloom 0.05, HDR threshold 1.0, blend mode Softlight or Additive. Levels 3–5 on.
- Use the single existing upstairs "glow mesh + silhouette" as the hero window. Give it `brightness 1.15` and a person silhouette. Keep the others 0.75–1.0 so they read as pattern, not competition.

**Optional interior-mapping version** (if the camera ever moves close). Replace the colour build-up above with a parallax room lookup, then apply the curtain multiply on top:

```
// tangent-space view ray, glass at z=0, room extends to z = -depth
vec3 ro = vec3(UV * 2.0 - 1.0, 0.0);              // entry point in [-1,1]^2
vec3 rd = normalize(tangent_space_view_dir);      // pointing into the room (z < 0)
vec3 box_min = vec3(-1.0, -1.0, -room_depth);
vec3 box_max = vec3( 1.0,  1.0,  0.0);
vec3 t_pos = (box_max - ro) / rd;
vec3 t_neg = (box_min - ro) / rd;
vec3 t_far = max(t_pos, t_neg);                   // exit distance per axis
float t = min(min(t_far.x, t_far.y), t_far.z);   // nearest exit = visible surface
vec3 hit = ro + rd * t;
// choose face: x-wall, y-floor/ceiling, or back wall (z)
// map hit.xy / hit.zy / hit.xz to an atlas cell picked by hash(window_seed)
// sample room atlas -> room_col; add warm lamp falloff; then:
col = room_col * lamp_tint;   // then apply curtain density, mullions, sill as above
```

The atlas-based Godot 4 interior-mapping shader on the Asset Library ("no cubemap") is a drop-in starting point. With sheer curtains on top, 4 room tiles are plenty.

### 4.3 Doorway glow and flame

- Inner door plane: `StandardMaterial3D`, emission enabled, colour 2400 K, energy 4–6. Paint a vertical gradient: brighter at the floor near the flame, darker at the lintel.
- Flame: a billboarded `GPUParticles3D` or animated quad, `unshaded`, additive, emission energy 8–12, colour 1800 K. A few spark particles rise slowly, matching the reference.
- **Door light (hero):** OmniLight3D, 0.6 m inside the threshold, 0.4 m high.

```
light_color = Color(1.0, 0.55, 0.12)   # ~2000 K
light_energy = 4.0
light_indirect_energy = 1.5            # helps SDFGI/VoxelGI bounce warm onto porch
light_size = 0.15                      # soft door-jamb shadow edges
light_specular = 1.5                   # boosts glint on wet cobbles
omni_range = 9.0                       # must reach the gate
omni_attenuation = 1.0
shadow_enabled = true
shadow_normal_bias = 1.5
omni_shadow_mode = OmniLight3D.SHADOW_CUBE
```

The door jamb then naturally casts a trapezoid of light onto the step and path.

### 4.4 Wall lantern by the door

- Housing glass emissive: 2200 K, energy 5, with flicker driven by script (below).
- OmniLight3D at the lantern centre:

```
light_color = Color(1.0, 0.58, 0.17)   # ~2200 K
light_energy = 2.0
light_size = 0.05
omni_range = 4.5
omni_attenuation = 1.2
shadow_enabled = false                 # or DUAL_PARABOLOID if budget allows
light_projector = <panorama: bright lower 2/3, dark top band with frame bars>
```

The projector darkens the wall above the lantern (the metal cap) and adds faint frame-bar streaks. That is a cheap IES-like falloff.

### 4.5 Foreground fence lamp-post and long picket shadows (the key effect)

**Geometry.** The shadows must fall *toward the camera*, so the light must be on the **house side** of the pickets.
- Place the visible lantern head roughly in line with the fence posts.
- Put the **actual OmniLight3D 0.25–0.4 m behind the fence plane** (toward the house), at about 1.5–1.7 m height (just below the lantern glass) and about 0.3 m above the picket tops.
- The lower the light sits relative to the picket tops, the longer the shadows. If you need 3–4 m stripes on the ground, drop it to about 0.1–0.2 m above the picket tops.

```
# FenceLampLight (OmniLight3D)
light_color = Color(1.0, 0.54, 0.06)   # ~2000 K
light_energy = 3.5
light_indirect_energy = 0.8
light_specular = 0.8
light_size = 0.08                      # PCSS: crisp at picket base, soft at tips
omni_range = 8.0                       # long enough for stripes to reach the camera foreground
omni_attenuation = 0.9                 # flatter curve keeps the far stripe ends visible
shadow_enabled = true
shadow_bias = 0.05
shadow_normal_bias = 1.0               # thin pickets: keep low or shadows thin out
shadow_blur = 1.2
shadow_opacity = 1.0
omni_shadow_mode = SHADOW_CUBE
```

**Cheat if the stripes are not long enough.** Add a second light, a SpotLight3D ("FenceShadowCaster"), at the same spot.
- Aim it down and toward the camera, at 25–35° below horizontal.
- Settings: `spot_angle 70`, `spot_range 10`, `spot_attenuation 0.8`, energy 2.5, same colour, `light_size 0.1`, shadows on.
- Set `light_cull_mask` to the **ground layer only** (e.g. layer 2), so it lights only the snow and path and does not double-light the fence.
- Set `shadow_caster_mask` to the **fence layer** (e.g. layer 3), so only pickets cast stripes and not the lamp-post itself or the mailbox.

You get stripes as long as you want with no extra glare on the fence. Then lower the omni's energy so the two together match the reference.

**Ground receiving shadows.** The snow must have low roughness variation (0.6–0.85) and a slightly bright albedo (≈0.75) so the warm stripes read. Shadowed gaps fall to the cool moon fill, which gives the warm/cool zebra pattern.

**Flicker script** (shared by both lanterns, plus the housing emissive):

```gdscript
extends OmniLight3D
@export var base_energy := 3.5
@export var amount := 0.08          # ±8 %
@export var speed := 1.6
@export var housing: MeshInstance3D
var noise := FastNoiseLite.new()
var t := 0.0
func _ready(): noise.frequency = 0.9; noise.seed = randi()
func _process(d):
    t += d * speed
    var n := noise.get_noise_1d(t)                     # -1..1
    var dip := 1.0 - 0.15 * pow(max(noise.get_noise_1d(t * 0.21 + 50.0), 0.0), 3.0) # rare sag
    light_energy = base_energy * (1.0 + n * amount) * dip
    if housing:
        housing.set_instance_shader_parameter("flicker", light_energy / base_energy)
```

Do not jitter the light position by more than 1–2 mm. The shadow stripes would crawl.

### 4.6 Window spill on sills and snow (no per-window lights)

- **Sills:** the window shader's sill glow already lights the inner sill. For the outer sill and the plants, add a small emissive strip or rely on Glow.
- **Snow below ground-floor windows:** one `Decal` node per window, projecting downward onto the snow layer (`cull_mask` = ground).
  - Use `texture_emission` set to a soft trapezoid with faint mullion bars (a window cookie).
  - Settings: `emission_energy 0.6–1.0`, `modulate Color(1.0, 0.6, 0.25)`, `upper_fade 0.3`, `lower_fade 0.3`.
  - This costs almost nothing and gives the "light falling from the window onto the snow" read.
- **Alternatively**, two SpotLight3Ds, one per side of the door, each covering 2–3 windows. Use energy 0.6, range 5, angle 60, shadows off, and a projector of window panes. These give real specular on the snow and path.

### 4.7 Wet cobblestone material

Use `StandardMaterial3D` with a detail mask, or a small shader. Treat the target as damp from melted snow, with puddles only in the grout.

| Channel | Stone tops | Grout / low spots | Path edge (snow-dusted) |
|---|---|---|---|
| Albedo | base × 0.65, saturation +10% | base × 0.5 | mix to snow white via a world-space noise mask |
| Roughness | 0.22–0.38 (noise-varied per stone) | 0.04–0.08 (puddles) | 0.75–0.9 |
| Metallic | 0.0 | 0.0 | 0.0 |
| Specular | 0.5 | 0.5 | 0.5 |
| Normal strength | 1.0 | 0.2 (water flattens) | 0.6 |

Shader logic:

```glsl
float h = texture(height_tex, UV).r;                 // stone height
float puddle = smoothstep(0.35, 0.25, h);            // low areas hold water
float stone_var = texture(noise_tex, UV * 0.37).r;   // per-stone wet variation
float wet = mix(0.6, 1.0, stone_var);
ALBEDO   = base.rgb * mix(1.0, 0.65, wet) * mix(1.0, 0.8, puddle);
ROUGHNESS = mix(mix(0.6, 0.25, wet), 0.05, puddle);
NORMAL_MAP = mix(normal_tex, vec3(0.5, 0.5, 1.0), puddle * 0.8);
```

Supporting settings:
- **Environment → SSR on**: max steps 64, fade in 0.15, fade out 2.0, depth tolerance 0.2. This catches the door glow in the puddles. As a backup, add a ReflectionProbe (box, interior off, update Once) over the path.
- The glint direction depends on the **door light sitting behind the path from the camera's view**. Raise `light_specular` on the door light (1.5) rather than overall energy.
- Optionally add a thin decal of "warm puddle streaks" (emission 0.2) straight down the path centre. This mimics the stretched specular streak seen in the reference.

### 4.8 Shadows, contact and environment

- **SSAO:** radius 0.6, intensity 1.5, light affect 0.1. It grounds the fence posts, mailbox and step.
- **Godot 4.7:** check for screen-space contact shadows in Project Settings (Forward+). If they exist, enable them for the fence lamp. Otherwise rely on PCSS and SSAO.
- **Volumetric fog** (optional): density 0.01–0.02, albedo cool grey. Give each lantern `light_volumetric_fog_energy 1.5` so the lantern heads get a soft halo. Keep the door fog energy low so the focal point stays crisp.
- **Tonemap:** Filmic or AgX, exposure about 1.0. Let the lantern and flame clip into Glow, and keep the windows under about 1.5 luminance so they never outshine the door.
- **Final focus check:** squint at the frame or blur the screenshot. The brightest blobs should rank **door > fence lantern > wall lantern > upstairs hero window > other windows**. If any window beats a lantern, lower its `brightness` instance uniform.

---

## 5. Sources

1. Joost van Dongen, *Interior Mapping: rendering real rooms without geometry* (blog): https://joostdevblog.blogspot.com/2018/09/interior-mapping-real-rooms-without.html
2. 80.lv repost of the same article: https://80.lv/articles/interior-mapping-rendering-real-rooms-without-geometry
3. Game Developer repost: https://gamedeveloper.com/programming/interior-mapping-rendering-real-rooms-without-geometry
4. Papers We Love, *Interior Mapping* paper entry: https://paperswelove.org/papers/interior-mapping-enhanced-indoor-illusion-in-games-7b28a80e/
5. UDK Gems, Interior Mapping: https://docs.unrealengine.com/udk/Three/DevelopmentKitGemsInteriorMapping.html
6. Gaijin DagorEngine, `rendinst_interior_mapping`: https://gaijinentertainment.github.io/DagorEngine/assets/shaders/rendinst_interior_mapping.html
7. Automaton, *Are there really rooms behind every window in Spider-Man?*: https://automaton-media.com/en/news/20231201-23558/
8. Polycount, *Interior mapping in Spider-Man PS4*: https://polycount.com/discussion/204601/interior-mapping-in-spider-man-ps4
9. GDC Vault, *Marvel's Spider-Man: A Technical Postmortem* (Ruskin, 2019): https://gdcvault.com/play/1026496
10. 80.lv, *Marvel's Spider-Man: a technical postmortem*: https://80.lv/articles/marvels-spider-man-a-technical-postmortem
11. Godot Asset Library, *Godot 4 interior mapping shader (no cubemap)*: https://godotengine.org/asset-library/asset/1564
12. godotshaders, *Interior mapping shader*: https://godotshaders.com/shader/interior-mapping-shader/
13. godotshaders, *Fake Interior Shader*: https://godotshaders.com/shader/fake-window-interior-shader/
14. godotshaders, *Fake 3D Interior Projection Shader Fixed & Adjustable*: https://godotshaders.com/shader/fake-3d-interior-projection-shader-fixed-adjustable/
15. Godot docs, *3D lights and shadows*: https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html
16. Godot docs, *3D lights and shadows* (4.7): https://docs.godotengine.org/en/4.7/tutorials/3d/lights_and_shadows.html
17. Godot docs, `Light3D` class: https://docs.godotengine.org/en/stable/classes/class_light3d.html
18. Godot docs, `OmniLight3D` class: https://docs.godotengine.org/en/latest/classes/class_omnilight3d.html
19. Godot docs, *Physical light and camera units*: https://docs.godotengine.org/en/4.2/tutorials/3d/physical_light_and_camera_units.html
20. Godot docs, `BaseMaterial3D` (backlight, transmittance): https://docs.godotengine.org/en/4.2/classes/class_basematerial3d.html
21. Godot docs, *Standard Material 3D*: https://docs.godotengine.org/en/latest/tutorials/3d/standard_material_3d.html
22. Godot Forum, *Screen-space shadows* (contact shadows, Forward+): https://forum.godotengine.org/t/screen-space-shadows/70197
23. Godot Forum, *OmniLight3D flickers when camera moves*: https://forum.godotengine.org/t/omnilight3d-flickers-weirdly-when-i-move-my-camera/125792
24. Godot Asset Library, *Flickering Light (2D & 3D)*: https://godotengine.org/asset-library/asset/4170
25. Epic, *Using IES Light Profiles in Unreal Engine*: https://dev.epicgames.com/documentation/en-us/unreal-engine/using-ies-light-profiles-in-unreal-engine
26. UE 4.26 docs, *IES Light Profiles*: https://docs.unrealengine.com/4.26/BuildingWorlds/LightingAndShadows/IESLightProfiles
27. NVIDIA GameWorks, *Soft Shadows (PCSS) sample*: https://docs.nvidia.com/gameworks/content/gameworkslibrary/graphicssamples/opengl_samples/softshadowssample.htm
28. GameDev.net, *Contact-hardening Soft Shadows Made Fast*: https://gamedev.net/tutorials/programming/graphics/contact-hardening-soft-shadows-made-fast-r4906
29. Polycount, window glow / night building texture advice: https://polycount.com/discussion/comment/2782166
30. Polycount, shader-based structure / no-transparency glass advice: https://polycount.com/discussion/201391/help-with-shader-based-model-technique-for-a-simple-structure
31. Unreal forums, *How to make windows glow*: https://forums.unrealengine.com/t/how-to-make-windows-glow-archviz/351465
32. 80.lv, *Melancholic city at night in Blender*: https://80.lv/articles/how-to-build-a-melancholic-environment-of-a-city-at-night-with-blender
33. 80.lv, *Lighting in 3D art: why it matters*: https://80.lv/articles/lighting-in-3d-art-why-it-matters-how-to-improve-it/
34. Adobe Substance, *3D lighting techniques*: https://www.adobe.com/products/substance3d/discover/3d-lighting.html
35. 3DVF, Sébastien Lagarde rain series summary: https://3dvf.com/actualite-5676-sebastien-lagarde-simulation-pluie-en-jeu-video-html/
36. GitHub gist, wet surface shader with puddles (after Lagarde): https://gist.github.com/eviltak/e04b83ffdb91aa3d477bbfe0ca370da7
37. HAL, *Real-time wetting of porous media*: https://hal.archives-ouvertes.fr/hal-01026512
38. Nguyenova, *Rendering Wet Roads in Driving Simulations* (CESCG): https://cescg.org/wp-content/uploads/2021/03/Nguyenova-Rendering-Wet-Roads-in-Driving-Simulations-1.pdf
39. Rain drop shader write-up: https://lowysole.github.io/post/rain-shader
40. godotshaders, *Rain Puddles*: https://godotshaders.com/shader/rain-puddles-v1/
41. Superhive, *Procedural Wet Puddles* docs (roughness ranges): https://superhivemarket.com/products/procedural-wet-puddles-master/docs
42. Polycount, wet albedo vs roughness by material: https://polycount.com/discussion/comment/2313787/
43. ProVideo Coalition, *Backlight is best light*: https://www.provideocoalition.com/a-cheats-manifesto-part-2-backlight-is-best-light/
44. Adorama, *Basic cinematography lighting techniques*: https://www.adorama.com/alc/basic-cinematography-lighting-techniques
45. Shacknews, *RDR2 PC graphics guide* (dynamic night lighting): https://shacknews.com/article/115067/red-dead-redemption-2-pc-graphics-settings-guide
46. imgeself, *Graphics study: Red Dead Redemption 2*: https://imgeself.github.io/posts/2020-06-19-graphics-study-rdr2
47. Nexus Mods, Witcher 3 lighting mod (fire overexposure): https://nexusmods.com/witcher3/mods/4895
48. 80.lv, *A Witcher-inspired village in UE5*: https://80.lv/articles/a-witcher-inspired-village-made-in-unreal-engine-5
49. Steam, KCD2 art direction discussion: https://steamcommunity.com/app/1771300/discussions/0/601894356967820905
50. STEP wiki, *ENBSeries Windowlight* (Skyrim SE): https://stepmodifications.org/wiki/SkyrimSE:ENBSeries_INI_Reference/Windowlight
51. Nexus forums, *ENB candles too dark, windows too bright*: https://forums.nexusmods.com/topic/1684803-enb-candles-too-dark-windows-too-bright
52. GDC Vault, *In-Game and Cinematic Lighting of The Last of Us*: https://gdcvault.com/play/1020475/contactUs
53. SIGGRAPH archive, *Lighting Technology of The Last of Us Part II*: https://history.siggraph.org/?p=76961
54. Remedy, *How Northlight makes Alan Wake 2 shine*: https://remedygames.com/article/how-northlight-makes-alan-wake-2-shine
55. ArtStation Magazine, *Alan Wake 2 Art Blast*: https://magazine.artstation.com/2023/12/remedy-entertainment-alan-wake-2-art-blast/
56. ArtStation Magazine, *A Plague Tale: Innocence Art Blast*: https://magazine.artstation.com/2019/06/asobo-studio-a-plague-tale-innocence-art-blast/
57. Push Square, *A Plague Tale devs on Middle Ages setting* (Claude Lorrain): https://www.pushsquare.com/news/2019/01/a_plague_tale_innocence_devs_discuss_middle_ages_setting_in_new_video
58. ArtStation, Ford Gabriel T, *Hogwarts Legacy lighting*: https://fordgabrielt.artstation.com/projects/BXnvql
59. ArtStation, Molly Warner, *Hogwarts Legacy Lower Hogsfield Hamlet*: https://mollywarner.artstation.com/projects/RyK0rW
60. Thumbsticks, *GDC 2015: The Art of Firewatch*: https://www.thumbsticks.com/gdc-2015-the-art-of-firewatch
61. GDC Vault, *The Art of Firewatch*: https://gdcvault.com/play/1022295/contactUs
