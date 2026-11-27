# 10 — Winter & Snow Environment Art for Melancholy-Cozy Night Scenes

Research for *Unsent* (Godot 4.7). Target frame: `research/reference_target.webp`. A two-storey house at night with snow on the roof, icicles on the eave, warm windows and an open glowing door. A wet cobblestone path runs to a picket gate. A lit lantern sits on the left and a red POST mailbox capped with snow on the right. Snowy pines stand under a moon-lit, starry navy sky, light snow falls, and the ground has a thin cover of snow, gold near the lantern and blue elsewhere.

---

## 1. Takeaways

1. **Snow is a mirror for light colour, not a white material.** Give it a near-neutral, slightly cool albedo that is never pure white (roughly 0.80–0.88), and let the lights do the work. Moon and sky make it blue, the lantern makes it gold. Breakdowns repeatedly warn that pure-white snow blows out and flattens the image (80.lv UE5 snow shader). Several also advise a mid-tone base so that sparkles have something to contrast with (Unreal forum).
2. **Sparkle sells snow more than any other cue.** It also aliases badly. The approach that works is a sparse set of world-space "flakes" with jittered normals and low roughness, faded out with distance. It then catches whatever light hits it, so it glints gold under the lantern and silver-blue under the moon. Bloom does the rest.
3. **Accumulation follows a simple rule plus hand edits.** An up-facing mask in world space with noise in the threshold covers most surfaces. Hero surfaces (the roof, fence-post caps, the mailbox lid) get modelled snow meshes, because shader-only snow cannot overhang, droop or round over edges. Andrew Lund's winter street breakdown reached the same split: a Z-up shader everywhere, plus separate snow meshes on roofs and copings.
4. **Contrast warm and cold, and keep the warm areas few and small.** Cosy comes from a handful of warm pools (windows, door, lantern) inside a large cold field. Loneliness comes from how much cold, empty space surrounds them. Batman: Arkham Origins deliberately set a festive Christmas Eve against an emptied, noir city. Frostpunk's art team describes a palette that is "cold and bleached," with warmth as life.
5. **Wetness means darker albedo, lower roughness and Fresnel, not "add blue."** Wet porous stone gets darker and more saturated along a non-linear curve, and its roughness drops sharply. Reflections stay weak looking straight down (about 2% at normal incidence) and strong at grazing angles (Lagarde via fxguide). The path reads as wet mainly because it reflects the lantern and door light in long streaks.
6. **Pines read through their top edges.** Against a dark sky, a pine is a dark silhouette with a lit rim. Snow on the upper side of each bough, plus moon backlight and fog layering, keeps it from disappearing into the navy sky.
7. **Snow tells stories.** Untouched snow on the mailbox lid, a single line of footprints, a cleared path versus an uncleared one, and icicles only above the heated rooms all say something about who lives here and what has or hasn't happened.
8. **Deformable snow is AAA tech, and you need very little of it.** Batman's snow, Rise of the Tomb Raider's deferred deformation, God of War Ragnarök's capsule carving and RDR2's tracks all rely on render-target height fields and tessellation. A fixed-camera narrative opening can fake all of it with normal/ORM-only decals.

---

## 2. Techniques

### 2.1 Snow material layers

- **Base colour.** Use a white-to-pale-blue gradient around RGB(200, 214, 230), with a bluish tint pushed into small cavities by AO (80.lv, "Setting up a detailed snow shader in UE5"). Batman: Arkham Origins tinted the diffuse in deformation transition zones with sky colour to fake subsurface scattering cheaply (Barré-Brisebois, GDC 2014).
- **Subsurface / translucency.** Nearly every breakdown adds SSS, and the winter tips article adds "a faint light-blue subsurface". Leah Augustine's snowy-forest breakdown notes that SSS flattens normal detail, so she boosted a noise detail normal to compensate. In Godot the cheap equivalents are `BACKLIGHT`, or a Fresnel-driven edge brightening. True SSS (`SSS_STRENGTH`) costs more and is subtle at night.
- **Fresnel.** Fresnel blends a second roughness at grazing angles, tints the diffuse, and makes edges read as thinner and brighter (UE5 snow shader breakdown). This is what gives the soft, glowing outline on roof snow.
- **Roughness.** Snow is fairly rough overall (around 0.6–0.8), broken up by fine noise in the roughness map so that micro-highlights appear. Ice and wet surfaces are the low-roughness exceptions.
- **Detail normals.** Combine a large-shape normal with a fine noise detail normal, blended with Reoriented Normal Mapping rather than a lerp (Batman GDC slides).

### 2.2 Sparkle and glints

- **Cheap version.** Use a high-frequency noise in roughness plus a tiled "very rough" normal map, so that tiny facets catch the light, and then push it with bloom (Unreal forum, Brian Johnstone). FyreNight's variant multiplies a screen-space noise by a UV-space noise, which produces twinkling as the camera moves.
- **Robust version.** Wang & Bowles (2016) intersect a jittered 3D grid of sparkle points with the surface. They add depth-dependent scaling and anti-aliasing so the sparkle neither crawls nor shimmers at distance. Without a view term, sparkles look painted onto the surface.
- **Flake texture version.** The UE5 snow breakdown stores flake tilt in RG, peak-brightness angle in B and a mask in A. It also masks flakes out where the main light is blocked.
- **Godot precedent.** The godotshaders "Glitter Material" samples a 3D cellular noise in world space and offsets `NORMAL_MAP` by `(noise − 0.5) * 0.2`, with high specular. It is a good starting point, because world space keeps flake size constant across meshes of any scale. The Patreon "Interactive Snow w/ Tessellation" tutorial warns that mipmapping a sparkle texture blurs the sparkles away. Use procedural hashes or disable mipmaps on that texture.

### 2.3 Accumulation

- **World-up mask.** Compare the world normal to (0, 1, 0) and smoothstep it with a noise-modulated threshold. godotshaders' "Snow-Covered Surface" takes the `max` of the normal-mapped mask and the vertex-normal mask, and flattens `NORMAL_MAP` toward neutral under snow, so the snow hides the detail beneath it. Kasper Arnklit's "World Normal Mix" shader does the same blend as a reusable two-material mix.
- **Vertex paint override.** Paint vertex colours to remove snow under eaves, on the wet path or where heat would melt it (80.lv winter castle breakdown, Lund's winter street).
- **Skyrim's approach.** Skyrim assigns a "directional material" per static mesh: one snow material applies a top-down snow projection to every instance. Its known failure modes are stretching on steep faces and snow covering things it shouldn't, which are good reminders to clamp the mask.
- **Branches.** Augustine painted snow directly into the branch textures in Substance Painter and added a world-aligned layer on top. Alpha-card foliage has unreliable normals, so drive the mask with "spherical" normals from the canopy centre or with vertex colour.
- **Roofs and fences.** Displacement and tessellation break down on slopes ("wonky" when pushed too far), so roofs and copings get modelled snow slabs (Lund). The same applies to fence-post caps and the mailbox lid: a rounded "pillow" mesh with a small overhang and droop.

### 2.4 Footprints and deformation

- **Batman: Arkham Origins (GDC 2014).** An ankle-high orthographic frustum under each snow surface renders the actors that touch the snow into a heightmap each frame, then blurs and accumulates it. It subtracts a small amount every frame so that snow refills "since it's snowing." Heightmaps are at most 512², and only about two surfaces update per frame. On PC, DX11 tessellation adds real displacement.
- **Rise of the Tomb Raider (SIGGRAPH 2015, GPU Pro 7).** "Deferred deformation" is computed with compute shaders, independent of the snow mesh.
- **God of War Ragnarök (GDC 2023, Paolo Surricchio via 80.lv).** Physics capsules carve the snow every frame. The team moved from screen-space parallax to hardware tessellation, and tessellates only the terrain chunks that need it, with two draw calls per mesh. A runtime top-down mask drives a second normal map, and art-placed meshes spawn around the displaced edges.
- **Indie and Godot route.** godotshaders' "Car Tracks on Snow or Sand" draws trails into a viewport texture. For static scenes, Godot's own docs suggest decals for footprints and puddles: set albedo to 0 for normal/ORM-only decals, but keep an albedo texture for its alpha. Keep the projection depth short, and fade decals over time.

### 2.5 Icicles and frost

- Ice looks like "coloured glass" if it is only transparent. Convincing ice needs inclusions, a thickness-driven colour shift and refraction (80.lv winter village deep dive). Cheaper art routes use a cloud-noise opacity or SSS mask to vary clarity (80.lv cracked ice), with an IOR of about 1.31 (CG Cookie).
- For a game this size, use **opaque** icicles: a pale cyan-grey albedo, roughness 0.05–0.15, strong Fresnel rim, and a little `BACKLIGHT`. Taper them, vary their lengths, and cluster them. Real icicles grow where heat leaks through the roof, so they gather above warm rooms and at gutter ends. That is a free storytelling cue.
- **Frost** on window panes belongs in the corners and edges, as a vignette mask plus fern/crystal noise, lit from behind by the warm interior. godotshaders' "Frost Overlay for Any Mesh" and "Screen Space Frost" are possible starting points.

### 2.6 Wet versus dry surfaces and cobblestones

- **Lagarde's rules (fxguide).** Only porous materials change much when wet. Darkening is non-linear and strongest in the mid-range albedos. Saturation rises slightly. Rough surfaces become smoother. Water obeys Fresnel (IOR 1.33). Thin water layers keep the surface normal, while deep puddles flatten it, so blend toward the vertex normal by water height. While drying, specular disappears before the darkening does.
- **Unity's production weather samples.** Puddles are restricted to flat, up-facing areas, and wetness darkens and saturates the colour while increasing smoothness. A forum tip warns against tinting puddles blue: darken them instead.
- **Cobblestones.** Water collects in the mortar gaps first, so the inverted height or AO map makes a good puddle mask. A damp, darkened border around each reflective patch reads better than a hard edge.

### 2.7 Snowfall density and art direction

- **Light snowfall reads as "quiet."** Dense snow reads as "storm" or "danger" (Skellige's heavy weather, God of War's Fimbulwinter with constant snowfall). Michael Gerard's Skellige study found the game's reference "wasn't as snowy" as memory suggested, so restraint is faithful.
- **Use layers.** Use a few big, slow, out-of-focus flakes near the camera, many small flakes in the mid-ground, and fog for the far distance. The UE5 winter village used thousands of collision particles near the camera and GPU particles at distance, with density scaled by camera distance.
- **Godot specifics.** `GPUParticlesCollisionHeightField3D` is the documented collider for weather, and can follow the camera. Collision requires `collision_mode` on the process material, plus a visibility AABB that overlaps the collider.

### 2.8 Pines against a night sky

- The silhouette comes first: break up the outline and avoid clean cones (80.lv winter castle).
- Paint value bands. Near trees are darkest, with bright snow on the tops of their boughs. Each layer further back is lighter and bluer through fog. The sky behind is a mid-dark navy, not black, so the silhouettes separate.
- Rim light is faked with a separate light or light channel aimed back toward the camera (Lund, Augustine). Lund also aimed spotlights at an invisible sphere behind the buildings to brighten the sky and pick out the roofline. The moon behind the left-hand pines in the reference does exactly this.
- Fog and darkness hide bark, so one Polycount artist added snow to the trunk itself for readability.

### 2.9 Storytelling props

Mailboxes, lanterns and gates are where snow becomes narrative. A cap of snow nobody has disturbed means nothing has been posted or collected. A shovelled path means someone is home. A lantern that is lit while no one is in the yard means someone is waiting. A gate left open with drifted snow against it means it has been open a while. Hitman's art director described Hokkaido's "clean, stark" look as hard to make beautiful. Sparse scenes need each prop to carry more weight.

---

## 3. Game examples

- **The Long Dark.** Hinterland built a deliberately "storybook, painterly" look with bold colour and dramatic skies. The art team noted the style risks reading as too realistic or too whimsical. Its lesson for *Unsent* is to simplify the textures and let the colour of the light carry the emotion. The loneliness comes from vast empty space around tiny shelters.
- **Frostpunk.** The palette is royal and steel blue, "cold and bleached." Heat and light equal life, and the generator glow is the emotional centre. Warmth is rationed visually.
- **Batman: Arkham Origins.** Christmas Eve with the streets emptied by a blizzard. Decorations are lit to look eerie rather than jolly, which is the inverse of cozy, created by lighting choices alone. Its GDC 2014 deformable snow talk is the canonical footprint reference.
- **God of War (2018) and Ragnarök's Fimbulwinter.** The 2018 game used parallax snow. Ragnarök moved to tessellated, capsule-carved snow with constant snowfall. Kevin Quinn's Niflheim breakdowns show procedural Houdini ice.
- **RDR2 (Colter chapter).** Deep, persistent tracks and a crushing blizzard. Fan breakdowns aiming for its mood (Augustine) lean on dense fog, cool post-processing and SSS edge glow. Rockstar has not published its method; hobbyist versions use a player-locked render target.
- **Rise of the Tomb Raider.** Deferred, compute-driven snow deformation (SIGGRAPH 2015, GPU Pro 7).
- **Skyrim.** Directional snow materials on statics. It shows that a single projection rule plus per-mesh fixes can scale to a whole world.
- **Hitman (Hokkaido).** A stark, minimal snow-and-concrete palette. It is a warning that clean snow scenes need strong lighting design to look good.
- **Spider-Man: Miles Morales.** A snowy, pre-Christmas New York. The winter setting was framed as heightening the city's festive beauty: warm shop and window light against blue snow, plus wet, reflective streets.
- **The Witcher 3 (Skellige).** Heavy, location-specific snow and per-region foliage libraries. Fan recreations note the actual snow coverage is lighter than remembered.
- **Kingdom Come, Snowrunner, A Plague Tale, Dredge, Firewatch winter mods.** No official snow breakdowns surfaced for these. As observed references: Snowrunner shows persistent terrain deformation as a gameplay read, and the KCD community asks for "real" rather than painted-on ground snow. Dredge and A Plague Tale show how a small warm light source in a hostile, dark world creates dread and comfort at the same time, which is the emotional mechanism *Unsent* wants.

---

## 4. Apply to Unsent's opening

All snippets target Godot 4.x spatial shaders and slot into the existing `foliage_snow.gdshader` / `memory_prop.gdshader` pattern: `wpos` varying, the `world_sat` global, and the `snow` uniform.

### 4.1 Snow colour response (shared snow function)

Replace the current hard-coded `vec3(0.86, 0.9, 0.98)` with a slightly darker, neutral-cool albedo. The lights then produce the blue and gold. Add a Fresnel brightening and fake SSS:

```glsl
uniform vec3 snow_albedo : source_color = vec3(0.80, 0.83, 0.88); // never 1.0
uniform float snow_rough = 0.72;
uniform float snow_backlight = 0.25;   // fake SSS

// inside fragment(), after computing `cover`:
float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
vec3 snow_col = snow_albedo * (1.0 + fres * 0.15);   // soft bright edge
col   = mix(col, snow_col, cover);
rough = mix(rough, mix(snow_rough, 0.45, fres), cover); // shinier at grazing
BACKLIGHT = mix(BACKLIGHT, vec3(snow_backlight) * vec3(0.85, 0.92, 1.0), cover);
```

**Lighting that makes it work**

- **Moon (`DirectionalLight3D`).** Colour `#8EA6D6`, energy 0.15–0.3, shadows on. Place it behind and left of the house, matching the reference moon, so roofs and boughs get a rim.
- **Ambient (`WorldEnvironment`).** A sky or background colour of deep navy `#1B2638`, ambient energy about 0.3. This produces the "blue in shadow" look.
- **Lantern (`OmniLight3D`).** Colour `#FFB25E`, energy 2–3, range 5–6 m, shadows on, `light_volumetric_fog_energy` about 1.5 so the halo is visible. Add a second, very low-energy omni at ground level if the gold pool on the snow needs to be wider.
- **Windows.** One `SpotLight3D` or `OmniLight3D` per window pane, aimed outward, colour `#FFC27A`. They throw warm rectangles onto the snow and path.
- **Door.** The brightest warm source, as the narrative focal point.
- **Tonemap and glow.** Use AgX or ACES tonemapping. Enable glow with the HDR threshold at about 1.0, so only the lantern, windows and sparkles bloom. Keep glow intensity low, around 0.4–0.6.
- **Volumetric fog.** Density 0.01–0.02, albedo a cool grey-blue. This lifts the sky behind the pines and creates light shafts under the moon.

### 4.2 Snow sparkle (add to both snow shaders)

```glsl
uniform float sparkle_density = 60.0;   // cells per metre
uniform float sparkle_amount  = 0.06;   // fraction of cells that glint
uniform float sparkle_far     = 12.0;   // fade distance (m) to stop aliasing

float hash3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }

// in fragment(), after `cover` is known:
vec3 sp = wpos * sparkle_density;
vec3 cell = floor(sp);
float h = hash3(cell);
float in_cell = step(length(fract(sp) - 0.5), 0.18);      // small dot, not whole cell
float glint = step(1.0 - sparkle_amount, h) * in_cell;
float dist = length(VERTEX);                               // view-space distance
glint *= (1.0 - smoothstep(sparkle_far * 0.5, sparkle_far, dist)) * cover;
// each flake gets its own tilt -> it flashes only at one view/light angle
vec2 tilt = vec2(hash3(cell + 3.1), hash3(cell + 9.7)) - 0.5;
NORMAL_MAP = mix(NORMAL_MAP, vec3(0.5 + tilt * 0.9, 1.0), glint);  // or vec3(0.5,0.5,1) if no map
rough = mix(rough, 0.06, glint);
SPECULAR = mix(0.35, 0.9, glint);
```

Because the glint is a real specular highlight, it takes the light's colour automatically: gold sparkles in the lantern pool and pale-blue ones under the moon. If the camera is locked, add a slow twinkle by hashing `cell + floor(TIME * 0.5)` into `h`. Keep `sparkle_amount` low: a few dozen visible glints in the lantern pool is the target, not glitter everywhere.

### 4.3 Wet cobblestone path (`wet_cobble.gdshader` or a branch of `memory_prop`)

```glsl
uniform sampler2D albedo_tex : source_color;
uniform sampler2D height_tex;          // 1 = stone top, 0 = mortar gap
uniform sampler2D normal_tex : hint_normal;
uniform float wetness = 0.85;
uniform float puddle_level = 0.35;     // height below which water pools
uniform float edge_snow = 0.6;         // snow creeping in from path edges

void fragment() {
    vec3 a = texture(albedo_tex, UV).rgb;
    float ht = texture(height_tex, UV).r;
    float n = noise(wpos.xz * 0.8);                       // reuse existing noise()
    float puddle = smoothstep(puddle_level + 0.08, puddle_level - 0.05, ht + (n - 0.5) * 0.2) * wetness;
    // non-linear darkening (Lagarde): stronger on mid albedo, plus a touch more saturation
    vec3 wet_a = pow(a, vec3(1.0 + 0.9 * wetness));
    wet_a = mix(vec3(dot(wet_a, vec3(0.299, 0.587, 0.114))), wet_a, 1.15);
    ALBEDO = mix(a, wet_a, wetness);
    float r_dry = 0.85;
    ROUGHNESS = mix(mix(r_dry, 0.35, wetness), 0.04, puddle); // damp stone -> mirror puddle
    NORMAL_MAP = mix(texture(normal_tex, UV).rgb, vec3(0.5, 0.5, 1.0), puddle); // flat water
    SPECULAR = 0.5;
    // snow at the path border: UV.x across the path, 0..1
    float border = 1.0 - smoothstep(0.0, 0.18, min(UV.x, 1.0 - UV.x));
    float s = clamp(border * edge_snow * (0.6 + n), 0.0, 1.0) * (1.0 - puddle);
    ALBEDO = mix(ALBEDO, vec3(0.80, 0.83, 0.88), s);
    ROUGHNESS = mix(ROUGHNESS, 0.72, s);
}
```

- Turn on **SSR** in the `Environment` (max steps 64, fade in/out about 0.15/2.0). The long streak of door and lantern light running down the path is what makes it read as wet in the reference. Add one `ReflectionProbe` covering the path and porch, updated once, as a fallback where SSR misses.
- Keep the path snow-free in the middle, implying it was walked or cleared. The contrast between the dark wet path and the pale snow beside it is the strongest graphic line in the frame.

### 4.4 Fence-cap and mailbox snow

- **Model the caps.** Each post top gets a separate pillow mesh: 1–2 cm overhang, rounded edges, a slight sag, and 5–15% random height variation. Give the mailbox lid one long, drooping cap with a small lip over the front edge. Use the shared snow material (4.1 plus 4.2). Picket points get either nothing or a tiny dab on every third one, because a uniform pattern looks procedural.
- **Shader accumulation on rails.** Rails use `memory_prop` with `snow ≈ 0.9`. Widen the mask so snow creeps a little way over the edge:

```glsl
vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
float n = noise(wpos.xz * 6.0 + wpos.y * 2.0);
float up = smoothstep(0.05 + n * 0.3, 0.6, wn.y);
// a little lip down the side, only near the top of the object (local y)
float lip = smoothstep(0.92, 1.0, local_y01) * smoothstep(-0.2, 0.2, wn.y);
float cover = clamp(max(up, lip * 0.7) * snow, 0.0, 1.0);
```

Here `local_y01` is a varying holding normalised local height (`VERTEX.y / mesh_height`), passed from `vertex()`.

- **Vertex paint "no snow"** applies under the porch roof, on the gate hinge side that was swung open, and in the lantern's immediate base.

### 4.5 Pines

- In `foliage_snow`, compute the up mask from a **canopy-spherical normal** (`normalize(wpos - tree_center)`, with `tree_center` from `MODEL_MATRIX[3].xyz + vec3(0, height * 0.5, 0)`) blended about 50/50 with the card normal. Snow then sits on the top of each bough tier instead of speckling randomly.
- Use a `snow` of about 0.9 on the near pines and 0.6 on far ones. Far ones get more fog, so they read lighter and bluer.
- Raise `BACKLIGHT` on snowy texels (around 0.35) so the moon behind the trees gives the bough tops a glowing rim.

### 4.6 Icicles and window frost

- **Icicles:** opaque material, albedo `#CFE3EE`, roughness 0.08, specular 0.6. Fresnel emission `pow(1 - NdotV, 4) * 0.3` in pale blue, plus `BACKLIGHT 0.3`. Make them longest above the two warm upstairs windows (heat leaks there), shorter elsewhere, and absent above the cold side.
- **Window glass:** a corner frost mask of `smoothstep` on distance-to-edge times fern noise, albedo near white with `EMISSION` taken from the interior colour times 0.3. The frost glows warm rather than grey.

### 4.7 Ground snow and footprints

- Use thin ground snow: the same snow material, with `cover` multiplied by a large-scale noise so dark earth and grass tufts show through, as in the reference. No displacement is needed.
- Add 6–10 **normal/ORM-only `Decal`s** as a single line of footprints from the gate toward the mailbox: albedo alpha only, albedo mix 0, normal on, roughness slightly lower inside the print. Their story is that someone walked to the mailbox and back, but the mailbox snow is undisturbed, so they never opened it. Set the decals' cull mask to the ground layer only.

### 4.8 Snowfall settings (`GPUParticles3D`)

**Mid layer (the main fall)**

- **Emitter and amount:** box emission 24 × 1 × 18 m, positioned 8 m above the yard. Amount 1,800.
- **Timing:** lifetime 9 s, preprocess 9 s so the scene opens mid-snowfall.
- **Process material:**
  - gravity `(0.15, -0.7, 0)`, initial velocity 0.1–0.3;
  - turbulence enabled, noise strength 0.4, noise scale 4, influence 0.08–0.15;
  - scale 0.6–1.2.
- **Draw pass:** a 2.5 cm quad with a `StandardMaterial3D` set to billboard particle mode, alpha with a soft round texture, shading **on**, so flakes passing the lantern and windows light up warm. Set `distance_fade` so flakes within 0.5 m of the camera don't pop.

**Foreground layer**

- Amount 40, lifetime 12 s, size 6–8 cm.
- A blurred disc texture at 30–40% alpha, slower fall (`-0.35`), more sway. This gives the bokeh-like out-of-focus flakes in the reference corners.

**Collision and wind**

- Use a `GPUParticlesCollisionHeightField3D` covering the yard at resolution 256 with collision mode "Hide on contact". Alternatively, simply kill particles below y = 0.05.
- Regenerate the visibility AABB after positioning.
- Gusts: a script that eases `gravity.x` between 0.05 and 0.4 every 6–12 s. Keep it subtle, since this is "light snowfall," not a storm.

### 4.9 The cozy/lonely balance (composition checklist)

- Keep warm light to about 15% of the frame's area: windows, the door, the lantern pool. Everything else is navy, blue-grey or silver.
- Make the door the warmest and brightest spot, and the lantern second. The windows sit dimmer and are partly curtained, which reads as intimate but closed.
- The only saturated non-light colour is the red mailbox. Its snow cap pulls it back into the palette.
- Leave the empty space: open snow in the foreground with no clutter. The fence separates the viewer from the warmth, which is the core lonely note.
- Keep the post-process grade cool in shadows and midtones and neutral-warm in highlights (Lund pushed blue into midtones and shadows). Avoid lifting the blacks into grey.

---

## 5. Sources

1. https://80.lv/articles/winter-environments-tips-tricks/
2. https://80.lv/articles/winter-street-scene-environment-production-breakdown-in-ue4
3. https://80.lv/articles/a-photorealistic-winter-village-in-unreal-engine-5-a-technical-deep-dive
4. https://80.lv/articles/setting-up-a-detailed-snow-shader-in-unreal-engine-5
5. https://80.lv/articles/001agt-004adk-creating-a-snowy-forest-in-ue4
6. https://80.lv/articles/snow-shader-with-a-subsurface-profile-created-in-unreal-engine-5-4-with-lumen
7. https://80.lv/articles/breakdown-building-a-winter-environment-of-a-castle-in-a-mountain
8. https://80.lv/articles/santa-monica-s-senior-programmer-on-how-god-of-war-ragnar-k-s-snow-system-was-made
9. https://80.lv/articles/a-look-at-god-of-war-ragnar-k-s-snow-and-ice
10. https://80.lv/articles/snow-nanite-tessellation-for-the-witcher-3-s-skellige-inspired-scene
11. https://80.lv/articles/how-to-build-cracked-ice-in-material-editor/
12. https://www.slideshare.net/colinbb/gdc2014-deformable-snow-rendering-in-batman-arkham-origins
13. https://www.gdcvault.com/play/1020177/Deformable-Snow-Rendering-in-Batman
14. https://history.siggraph.org/learning/labs-rd-rendering-techniques-in-rise-of-the-tomb-raider
15. https://www.gameenginegems.com/gemsdb/article.php?id=1314
16. https://gdcvault.com/play/1028846/Rendering-God-of-War-Ragnarok
17. https://hal.archives-ouvertes.fr/hal-01252637v1 (Wang & Bowles, procedural sparkle anti-aliasing)
18. https://forums.unrealengine.com/t/ue4-how-to-make-snow-sparkle/428881
19. https://discussions.unity.com/t/sparkle-shader/492850
20. https://godotshaders.com/shader/snow-covered-surface/
21. https://godotshaders.com/shader/world-normal-mix-shader/
22. https://godotshaders.com/?p=14605 (Glitter Material, world-space noise)
23. https://godotshaders.com/shader-tag/snow
24. https://godotshaders.com/shader/car-tracks-on-snow-or-sand-using-viewport-textures-and-particles/
25. https://godotshaders.com/shader/frost-overlay-for-any-mesh/
26. https://www.patreon.com/posts/interactive-snow-25641162
27. https://docs.godotengine.org/en/4.5/tutorials/3d/particles/collision.html
28. https://docs.godotengine.org/en/stable/tutorials/3d/using_decals.html
29. https://forum.godotengine.org/t/spatial-shader-render-mode-world-vertex-coords-doesnt-seem-to-put-normal-in-world-space/123917
30. https://www.fxguide.com/?p=43362 (Lagarde, making wet environments)
31. https://docs.unity3d.com/Packages/com.unity.shadergraph@14.0/manual/Shader-Graph-Sample-Production-Ready-Weather.html
32. https://cgcookie.com/posts/make-realistic-3d-ice-in-blender-procedural-shaders
33. https://blog.playstation.com/?p=350772 (Frostpunk art team)
34. https://www.dualshockers.com/frostpunk-interview-11-bit-studios/
35. https://www.gameinformer.com/b/features/archive/2013/04/10/the-world-of-batman-arkham-origins.aspx
36. https://www.shacknews.com/article/79016/batman-arkham-origins-aims-to-look-like-film-noir
37. https://www.pcgamer.com/the-long-darks-creative-director-explains-why-it-doesnt-need-zombies
38. https://www.creativebloq.com/how-to/how-to-create-stylised-game-artwork
39. https://Www.Wikipedia.org/wiki/Hokkaido_(Hitman)
40. https://www.nexusmods.com/skyrimspecialedition/mods/9121 (Skyrim directional snow notes)
41. https://gameinformer.com/b/features/archive/2015/05/12/cd-projekt-explains-the-witcher-3s-ever-changing-weather-with-exclusive-screenshots
42. https://store.epicgames.com/news/inside-the-inspiration-that-shaped-marvel-s-spider-man-miles-morales
43. https://gamedev.net/forums/topic/700247-snow-physics-in-red-dead-redemption-2/
44. https://gamedeveloper.com/art/creating-a-sense-of-magical-realism-through-in-game-lighting
45. https://www.premiumbeat.com/blog/lighting-day-for-night-interiors
46. https://polycount.com/discussion/comment/2349244
