# 02 — AAA Studio Case Studies: Lighting and Art Direction

*Research for* Unsent *(Godot 4.7, Forward+, AgX, volumetric fog). Opening shot: a snowy two-storey house at night, warm windows, an open door with a small flame as the focal point, a wet cobble path, a fence lantern throwing picket shadows toward camera, the moon behind clouds top-left, god rays through pines, a Milky Way sky, embers, snow, a red mailbox and a vignette.*

> **Reliability note.** Each section separates **documented** material (talks, studio blogs, interviews, listed in Sources) from **observed** notes (what the games visibly do on screen, with no developer statement behind it). Some studios have published far more than others about lighting. Naughty Dog, Sucker Punch, Guerrilla and Rockstar (tech side) are well documented. FromSoftware and Insomniac's winter work are thinly documented in English. No Digital Foundry article could be fetched during this pass. The search budget ran out before the FromSoftware CEDEC talks could be followed up.

---

## 1. Takeaways summary

1. **One master light per shot.** Naughty Dog's lighting artists build each shot around a single dominant key and treat every other light as support. If a shot turns muddy, they delete the lights and rebuild from the key. For *Unsent*, the door flame is that key; the windows, lantern and moon support it.
2. **Every light needs a believable source.** Naughty Dog's rule is that a light should never look as if it comes from nowhere. Bounce and fill are allowed, but they have to read as bounce from something in the scene.
3. **Decide colour before lighting.** TLOU2 ran a colour "image system" across the whole game, with red for revenge and blue for grief. Ghost of Tsushima's concept artists deliberately pushed concepts past realism, knowing the final game would tone them down. Both studios set the colour story first and then lit to serve it.
4. **Painting references, not photos, drive the mood.** Rockstar's lighting director drew on Turner, Rembrandt and Bierstadt. Guerrilla also cites Bierstadt and the luminists for its skies. The Yharnam recreation discussed in section 9 used a Dahl moonlight painting for its sky. For moonlight in particular, 19th-century nocturne painting is the shared language.
5. **Make night read as night, not dim day.** Sucker Punch built a Purkinje-shift model so that dark areas turn cool and blue yet stay readable. Night should be cool, low in saturation and blue-shifted, with warm practical lights as the only saturated colour.
6. **Atmosphere is a lighting tool.** RDR2 integrates fog, clouds and sky ambient into one scattering system. Guerrilla limits fog to one approved density per time of day. TLOU2 rewrote its fog system for mood. Volumetric fog is what turns a lamp into a visible shaft and a moon into god rays.
7. **One global wind drives everything that moves.** Ghost of Tsushima runs a single wind direction through foliage, cloth, smoke and particles. Snow, embers and branch sway in *Unsent* should all share one wind vector.
8. **Use fewer, stronger, simpler elements.** Tsushima limits foliage variety in each biome. Control left walls bare and let the lighting carry them. Akiman praises Elden Ring for engaging the viewer's imagination rather than its raw fidelity. A small team should cut detail and spend the effort on light and shape.
9. **Hand-grade the final image.** Remedy graded Alan Wake 2 by hand for both HDR and SDR. Naughty Dog leans heavily on LUTs and post. Sucker Punch gave artists a white-balance control expressed as "what should white become". The grade is an authored step, not a default.
10. **Build in a review loop.** Naughty Dog paints over in-game screenshots and blocks out sightlines early. Witcher 3's team built "beautiful corners" to final quality before scaling up. Lock one hero frame and compare it with the reference every iteration.

---

## 2. Naughty Dog — *The Last of Us* Part I/II, *Uncharted 4*

### What makes the look work
Naughty Dog's environments look naturalistic but are art-directed hard. The light feels motivated, soft and directional at the same time, and colour carries the story. In TLOU2 the art director treated colour and lighting as the main levers. Cook & Becker's interview describes a deliberate image system: **red** in underground spaces (the theatre basement) to make Ellie's revenge feel surreal, and **blue** to echo the trauma of Joel's death in Jackson, building across the three Seattle days. The farm sequence resets the palette as a visual breather.

### Documented techniques
- **Single-key philosophy.** Lighting artist Gabe Betancourt tells developers to anchor each scene with one dominant light that everything else supports. He also recommends matching a reference frame with a single light before adding anything else. His summary: "Less is more. The key light is master." When a setup goes muddy, he strips it back and restarts from the key.
- **Baked bounce plus hand-sculpting.** In TLOU2, sky and sun bounce form a baked base. Artists then place lights and sculpt each area by hand. They **painted ambient shadows** around trees, buildings and mountains so that overcast scenes would not go flat.
- **Interiors use fake windows.** Inside buildings, real sun and sky light was blocked and replaced with **soft area lights placed just outside windows and doors**. This keeps the light's direction without flattening the room.
- **No unmotivated lights.** The team's rule, reported by 80.lv, is that no light should seem to come from an unseen source.
- **Flashlight bounce.** The player's flashlight computes bounce light in real time, but the team used it sparingly because of the frame-rate cost. Cinematic lights then imitated that environmental bounce. Vivian Ding's GDC 2014 talk on the first game already covered directional lighting, ambient shadowing and flashlight bounce, and explained how in-game and cinematic lighting differ.
- **Ambient light is the hard part.** The SIGGRAPH 2020 abstract for Doghramachi's "Lighting Technology of TLOU2" notes that most of the world is overcast, which made ambient lighting the crucial component.
- **Post as authorship.** Palettes follow film references and story beats, and LUTs and post-processing produce much of the final image. Uncharted 4's technical-art session lists HDR colour LUTs, "mip fog", BRDF micro-shadowing, and wetness, moss and glass shaders.
- **Lighting as storytelling.** The GDC 2017 Uncharted 4 environment talk (Nakata and Pangilinan) emphasised detail, contrast and lighting as narrative tools.
- **Artist practice.** Joey Lenz (Senior Level Lighting Artist on TLOU2) starts from physically based values and Kelvin temperatures, then makes a deliberate artistic pass. He also uses helper lights to steer the player along a path. His view is that PBR "should be treated as a guide", not as law.

### Pipeline habits
Early block-meshes plan sightlines and blockers. Environment artists sit in on layout. Concepts exist for nearly every space, and the concept team later **paints over in-game screenshots** to suggest fixes. Artists and graphics programmers work in a continuous loop; TLOU2 rewrote its fog and improved character AO because the art asked for it.

### Transferable to a tiny team
- Adopt "one key, rebuild if muddy" as a house rule.
- Fake bounce with a few large, soft, low-energy lights (in Godot, OmniLight3D with a large `light_size` and shadows off), placed where real bounce would come from.
- Give every scene a one-line colour rule. For example: *the outside world is blue-grey; only things connected to the letters are amber.*
- Paint over your own screenshots in Krita or Photoshop before tweaking values.

---

## 3. Rockstar — *Red Dead Redemption 2* (night, lanterns, weather)

### What makes the look work
RDR2's nights are dark. The moon gives soft, cool directional light, and every warm source (lantern, campfire, window) becomes a pool of safety. The atmosphere (fog, cloud, haze) is lit by the same sky model as everything else, so weather changes the light in the scene, not just the backdrop.

### Documented techniques
- **One integrated atmosphere.** Fabian Bauer's SIGGRAPH 2019 Advances talk describes a single system for clouds, fog, volumetrics and an ambient model that approximates indirect light from the sky. It voxelises and raymarches scattering and transmittance, and shares that data between the main view, the reflection maps and a sky-irradiance probe grid. The goal was physically grounded light transport that artists could still steer for story and mood.
- **Night frame anatomy.** A RenderDoc study of a night frame shows **moonlight as the directional light**, with baked top-down lightmap data supplying much of the ambient light. Local lights are drawn additively. Most static lights use **baked point-light shadow cubemaps**, while **campfires and lanterns cast real-time shadows**. In other words, the lights the player moves close to get the expensive treatment. Bloom grows with distance, so fog and translucent surfaces glow more far away, which adds aerial perspective at night.
- **Painting lineage.** Art director Aaron Garbut said lighting had direct painterly inspiration. Lighting director Owen Shepherd looked to Turner, Rembrandt, Bierstadt, Frank Johnson and Charles Russell.

### Observed (not documented)
The player's lantern is a warm, short-range key with strong falloff. Nights are rarely pitch black; the cool fill keeps silhouettes readable. Rain and wet ground add specular highlights that pick out lights.

### Pipeline habits
Lighting gets its own director, and the team works from painting references. Expensive features (real-time shadows) are spent only where the player looks.

### Transferable to a tiny team
- **Only the hero lights cast shadows.** In *Unsent*, the fence lantern (for the picket shadows) and possibly the door flame get shadows. Window lights do not.
- Use the moon as a cool DirectionalLight3D with soft shadows, and let volumetric fog scatter it.
- Collect Rembrandt and Bierstadt nocturnes as the mood board, not game screenshots.

---

## 4. Sucker Punch — *Ghost of Tsushima*

### What makes the look work
"Stylized realism": the shading is physically based, but colour and composition are pushed toward samurai cinema and painting. Each biome has a small number of bold, saturated colour fields (red maple, gold pampas grass, white flowers), and everything moves in one wind.

### Documented techniques
- **Exaggerate in concept, expect the game to tone it down.** Concept art deliberately overshot the colour themes because shipped content always ends up softer. The concept team called it "an expressive art form", not an imitation of reality.
- **Limit variety for impact.** The studio limited foliage variety within each biome, treating foliage as a distinct visual element, so each area reads clearly. The world blog describes the environment as "a living character."
- **Silhouette readability.** Enemy types were given distinct shapes (triangular archers, rectangular brutes) so they read at a distance.
- **One global wind.** A single main wind direction, varied in strength by Perlin noise (Rockenbeck, GDC 2021), drives grass, trees, cloth, smoke and particles. Wind also shows the player where to go (the Guiding Wind) and adds tension behind still standoffs.
- **VFX is environment.** Tens of thousands of leaves, floating lanterns, candles that blow out, and fog parting in duels. A biome-driven ambience system places effects automatically by area.
- **Rendering for cinema (Patry, SIGGRAPH 2021 "Real-Time Samurai Cinema").** Spherical-harmonic probes relit at runtime by the sky. A froxel haze and fog volume that particles also sample. Exposure based on illuminance. A **local tonemapper** so dim interiors and bright skies both hold detail. A modified ACEScg primary so **reds don't drift to yellow**. A white-balance control that asks artists what white should become. And a **Purkinje-shift model** so night looks like night but stays readable.

### Pipeline habits
An art direction deck from day one, with wind and bold colour as headline goals. Concept leads, and the tech adapts to match. Colour grading LUTs survive engine changes because the white-balance work was folded into the tonemapper.

### Transferable to a tiny team
- Pick **three colour fields** for the opening (navy sky, cool snow, amber light) plus **one accent** (the red mailbox). Nothing else should be saturated.
- One `wind_direction` global shader uniform shared by the snow, ember and pine shaders.
- Purkinje shift in Godot: push shadows and midtones toward desaturated blue through the colour-correction LUT, and keep highlights warm.
- Watch reds under AgX: the mailbox and flame may shift toward orange. Check the red against a calibrated swatch.

---

## 5. Santa Monica Studio — *God of War* (2018) and *Ragnarök* (snowy Midgard)

### What makes the look work
Ragnarök's Midgard sits under Fimbulwinter: constant snowfall, deep snow everywhere, and cold, overcast light with warm firelight in interiors and camps. Snow is a gameplay surface (it deforms) as well as a mood.

### Documented techniques
- **Art goal first.** The art team wanted every realm to show Fimbulwinter's effect. In Midgard that meant constant snowfall and deep, interactive snow almost everywhere (Surricchio, 80.lv).
- **Displacement snow.** Hardware-tessellated displacement replaced the earlier parallax method. Capsules on characters and physics objects carve trails, falling particles collide with the displaced surface, and VFX writes a runtime mask for extra detail.
- **Designed for artists.** The goal was to turn on displacement for a mesh with one checkbox, with a few global controls for the whole game. Their principle: "You don't need to tweak parameters, unless you want to."
- **Wind and vegetation.** Sean Feeley's SIGGRAPH 2019 Advances talk covered *God of War*'s interactive wind, vegetation and the authoring workflow behind them.
- Stephen McAuley's GDC 2023 rendering talk (PDF listed below) covers the deep-snow requirement and a lighting-pipeline overhaul meant to save lighting artists' time. The PDF could not be read during this pass.

### Observed
Midgard's snow scenes are mostly low-contrast blue-grey, with warm fires providing focal points. Snow reads well because the albedo stays a little below pure white and grazing light brings out surface detail.

### Pipeline habits
State the art goal per area, then build the tech as global, low-fiddle defaults.

### Transferable to a tiny team
- Keep snow albedo around 0.8, not 1.0, so AgX has headroom and the snow doesn't clip under the lantern.
- Put a few falling-snow particles in front of the lantern so they catch its light.
- Fake deformation with a decal or vertex-painted trail along the path edges. Full displacement is unnecessary for a static opening shot.

---

## 6. Remedy — *Alan Wake 2* and *Control*

### What makes the look work
**Control:** bare brutalist concrete, carried almost entirely by strong lighting and sharp shape contrast against the formless Hiss. **Alan Wake 2:** wet Pacific Northwest darkness, fog, and a single hand-held light against the night, with a heavy, deliberate grade.

### Documented techniques
- **Leave surfaces bare and let light work.** For Control, Remedy said the sculptural spaces needed strong lighting. Better tech let them stop covering walls in stains, cables and pipes and hand the walls to the lighting artists. Persuading environment artists to leave walls alone was itself a challenge.
- **Ray-traced indirect light** made objects "sit" in the scene more naturally (Remedy and NVIDIA, Control).
- **Alan Wake 2 Northlight.** Fully ray-traced direct lighting with improved denoising. Fog that simulates multiple scattering, with finer designer control over where fog sits. Transparent surfaces (fog, water, particles) drawn at several resolutions so they blend smoothly, with per-pixel lighting on transparents. Rain-blocker volumes keep rain out of covered areas.
- **Hand-graded image.** Colourists graded HDR by hand, with a new tonemapping approach so the mood holds in both HDR and SDR. Remedy: "Alan Wake 2 is authored in HDR."
- **Separate palettes per world.** The Pacific Northwest and the Dark Place were treated as different art languages, so materials rarely crossed over (80.lv, Substance interview). Material values stay in PBR ranges via a checker tool.
- GDC 2024 included eleven Alan Wake 2 talks, among them environment-art workflows and "Crafting an Evolving Nightmare Dimension" (the Dark Place).

### Pipeline habits
Live editing in the engine; an art director with a strong single vision (Janne Pulkkinen); colourists as a named role.

### Transferable to a tiny team
- Treat grading as a real step. Build one LUT for the opening in DaVinci Resolve or Krita from a screenshot and load it as Godot's colour-correction texture.
- Let the house walls stay plain and dark. The windows are the detail.
- Use local FogVolumes for deliberate pockets of fog (around the door and along the path) rather than raising global density.

---

## 7. Guerrilla — *Horizon Zero Dawn* / *Forbidden West*

### What makes the look work
Big luminist skies. Clouds are treated as part of the composition, and time of day changes everything coherently.

### Documented techniques
- **Sky as composition.** Guerrilla cites 19th-century luminists such as Bierstadt, using clouds and light to create depth and drama over the land. Clouds set the mood and act as emotional punctuation.
- **Painted first, volumetric later.** HZD used painted, fixed cloud layers before real-time volumetrics were practical. Forbidden West added fly-through clouds. Burning Shores sculpts voxel "Frankencloudscapes" the way a terrain artist shapes land.
- **Every upgrade must pay for itself.** A new feature could cost no more than the system it replaced.
- **Time-of-day lighting (80.lv HZD interview).** Indirect sunlight baked at **four times of day** and blended. An **Ambience Manager** blends sky, fog, sun, colour correction and exposure together. Volumetric height fog on the sun gives god rays tunable per environment and time. Artists **paint with baked-only lights** to place colour and intensity gradients.
- **Fog discipline.** As reported by Kotaku, once a fog amount looked right for a time of day, that became the only fog amount allowed at that time.
- SIGGRAPH 2017's "Decima Engine: Advances in Lighting and AA" covered spherical area lights and atmospheric scattering with height fog.

### Transferable to a tiny team
- **Paint the sky.** For *Unsent*, a hand-painted panorama (navy, Milky Way, cloud bank around the moon) will look better than a procedural sky and cost almost nothing to render.
- Bundle sky, fog, sun, exposure and LUT into **one preset resource** per mood (in Godot, an `Environment` plus `CameraAttributes` pair), and swap whole presets rather than individual values.
- Use baked-only fill lights (LightmapGI with `bake_mode = static`) to paint gradients across the snow.

---

## 8. CD Projekt Red — *The Witcher 3* (nights, Skellige)

### What makes the look work
A grounded, painterly, "realistic but very stylized" look. Weather and time of day are tuned per region (Skellige gets coastal storms and sunny mountains), and players can light and extinguish candles and torches.

### Documented techniques
- **Lighting, colour, composition and vegetation together** make the world feel alive (Janiszewski, 80.lv). He likens it to painting in 3D, checked against real-world reference.
- **Change mood without rebuilding.** Mist, colour and plant state (old, dry trees) shift an area's feel.
- **"Beautiful corners."** Grey-box first, then build small areas to near-final quality, then scale outward.
- **Weather is weighted per region.** Swamps are almost always foggy, and Skellige has thunderstorms near the coast. The hardest part was making every location look right under every combination of time and weather while players could also toggle torches (Game Informer).
- Backgrounds use settlements to add depth to Skellige vistas.

### Observed
Witcher 3 nights are strongly moonlit and blue, with sharp warm pools from windows and torches. Skellige's look depends on rim-lit silhouettes against a bright sky.

### Transferable to a tiny team
- **Build the opening frame as your "beautiful corner"** before any other scene. It becomes the quality bar for everything else.
- Because the opening is static, author for **one** time and weather state, not every combination.

---

## 9. FromSoftware — *Elden Ring* and *Bloodborne*

### What makes the look work
Composition and silhouette rather than fidelity. Landmarks sit on strong sightlines (the Erdtree, castles on the horizon). Bloodborne layers vertical gothic silhouettes against a large moon, with cool, foggy streets and warm lamplight in safe havens.

### Documented / reported
- A Vice review notes Elden Ring's **sightline design**: distant structures pull the player from one point of interest to the next.
- Capcom veteran Akiman argues Elden Ring holds up against higher-fidelity games because it constantly engages the viewer's imagination: suggestion beats detail.
- FromSoftware gave a CEDEC 2022 talk on Elden Ring's atmosphere tools (skybox and volumetric fog), and a CEDEC 2025 talk on *Shadow of the Erdtree* reportedly stressed basic compositional rules. Neither could be fetched here, so this is reported, not verified.
- Kill Screen reads Bloodborne's architecture as sublime through **verticality** and excess: spires and a leaning clocktower pull the eye up, and the mass feels near collapse.
- A fan recreation of a Yharnam street (not FromSoftware's pipeline, but instructive) uses the **moon as the single directional key**, placed opposite the cathedral to backlight it. It pairs a hand-painted sky with an emissive moon mask (inspired by Dahl's *View of Dresden by Moonlight*), light overcast that softens shadows without hiding forms, local volumetric fog and fog cards for depth, and a few spot and point lights only on important areas.

### Observed
Bloodborne's moon is enlarged well beyond realistic scale for drama. Elden Ring's golden Erdtree is a warm light source visible from almost anywhere. Interiors use warm sites of grace against cold surroundings, the same warm-safe / cool-threat code as *Unsent*.

### Transferable to a tiny team
- **Scale the moon up** (2–3× realistic angular size) and treat it as a compositional object, not just a light.
- Put the moon **behind** something (pine branches or a cloud edge) so the god rays have occluders to cut through.
- Strong silhouettes: the roofline, chimney and pine tips must read against the sky with the textures turned off.

---

## 10. Insomniac — *Spider-Man: Miles Morales* (winter night) and *Spider-Man 2*

### What makes the look work
A festive, wet winter New York at night. Snow sits in small patches tucked into shadowed areas rather than covering everything. Streets look icy and wet, and holiday lights reflect in puddles and on cars. The palette is saturated, with warm decoration lights against cool night.

### Documented / reported
- Game Informer describes snow kept to **small clumps in shadowed areas**, icy, wet streets, and ray-traced reflections in puddles and cars. It describes the colour as dense and saturated: "Colors burst from every vector."
- Trusted Reviews notes Christmas lights reflecting off dark winter streets, and that the game looks best at night.
- Spider-Man 2 shipped with ray tracing in every mode; glass and water reflections are the visible payoff. Interiors use near-path-traced lighting with simple geometry (Digital Foundry interview, as reported).
- Insomniac's lighting artists do a final **lighting polish pass** that adds highlights for drama and lifts characters out of the background (Well Played, on Jackie Bornstein and Miki Eliza Hansen). ArtStation credits show mission lighting and separate polish passes by different artists.

### Transferable to a tiny team
- **Wet beats snowy for light.** A wet, dark path reflects the door flame and lantern and makes a leading line of light. Keep snow on the edges and in the shadows, not on the path.
- Do a dedicated **polish pass** at the end: add small highlight lights (rim on the gate posts, a glint on the mailbox) only for drama.
- In Godot, use SSR plus low roughness (about 0.15–0.3) and a puddle mask on the cobbles. A ReflectionProbe can back up SSR at the frame edges.

---

## 11. Cross-studio patterns

| Pattern | Who does it | What it means for *Unsent* |
|---|---|---|
| **One dominant key, motivated support** | Naughty Dog, Bloodborne recreation, RDR2 lantern | The door flame is the key; the windows and lantern are motivated supports; the moon is a cool counter-key. |
| **Warm safety vs cool world** | RDR2, Bloodborne, Witcher 3, GoW Midgard, Elden Ring grace | Amber = home, memory, letters. Blue = the outside, grief. Never mix them on the same surface without a source. |
| **Colour is decided per beat, before lighting** | TLOU2 image systems, Tsushima concept exaggeration | Write a colour script for the whole game; the opening's line is "cold world, warm house." |
| **Painting references for night** | Rockstar (Turner, Rembrandt, Bierstadt), Guerrilla (luminists), Yharnam (Dahl) | Build a nocturne mood board: Dahl, Atkinson Grimshaw, Bierstadt, Whistler's *Nocturnes*. |
| **Atmosphere integrated with light** | RDR2 unified scattering, AW2 multi-scatter fog, HZD fog-per-ToD | Volumetric fog density is low; lights carry `volumetric_fog_energy`. Fog makes rays, not murk. |
| **Night must still read** | Sucker Punch Purkinje, Witcher moon, RDR2 cool fill | Keep the silhouettes readable; never let the house fall to pure black. |
| **One wind** | Sucker Punch, GoW, Uncharted 4 global wind | One shared wind vector for snow, embers and branches. |
| **Restraint and simplification** | Tsushima, Control bare walls, Elden Ring imagination | Fewer props, plain walls, a strong silhouette. |
| **Shadows only on hero lights** | RDR2 lanterns, ND flashlight bounce used sparingly | Shadowed: moon, fence lantern. Unshadowed: windows, porch lamps. |
| **Grade is authored** | Remedy colourists, ND LUTs, Sucker Punch white balance | One hand-made LUT, plus exposure locked for the opening. |
| **Review loop** | ND paintovers, CDPR beautiful corners, Insomniac polish pass | Side-by-side with the reference, paintover, then adjust, each iteration. |

---

## 12. Apply to *Unsent*'s opening — checklist

**A. Before touching lights**
- [ ] Write the one-line colour rule: *navy and blue-grey world; amber only from the house and lantern; one red accent (mailbox).*
- [ ] Build a mood board: the reference image plus 4–6 nocturne paintings (Dahl, Grimshaw, Bierstadt) plus 2 RDR2 / TLOU night stills.
- [ ] Grey-box the shot. Lock camera position, FOV (about 40–50° for the flattened, symmetric look) and the house's centred symmetry. Check that the roofline, chimney and pine silhouettes read with all lights set to flat white.
- [ ] Make this frame the "beautiful corner" quality bar before building anything else.

**B. Key and supports (Naughty Dog rule)**
- [ ] **Key: the door flame.** OmniLight3D, roughly 1900–2200 K amber, shadows on, small range, so it lights the door frame, the step and the first cobbles. Add an emissive flame mesh or sprite with bloom-friendly HDR values.
- [ ] **Counter-key: the moon.** DirectionalLight3D from the top-left, cool (about 7000–9000 K or a pale blue tint), low energy, soft shadows on. Set `light_volumetric_fog_energy` high enough for god rays through the pines.
- [ ] **Story support: the windows.** Emissive curtain planes or a backlit curtain material. Add at most two or three unshadowed omni lights behind the glass to spill warm light onto the sills and snow. Vary the brightness slightly between windows so they don't look copy-pasted.
- [ ] **Foreground lantern:** an OmniLight3D (or downward SpotLight3D) with **shadows on**, placed low and behind the fence relative to camera so the picket shadows stretch toward the viewer. Tune shadow blur and bias until the stripes are crisp near the posts and soften with distance.
- [ ] **Porch lamps:** small, unshadowed, warm, dimmer than the door, framing the focal point.
- [ ] **Fill:** a very low cool ambient from the sky so the house façade reads as dark navy, not black (Purkinje idea).
- [ ] Test: turn off everything except the key, then add each light back. If any light has no visible source, delete it.

**C. Atmosphere**
- [ ] Global volumetric fog at low density, slightly blue albedo, with a small amount of `sky_affect`.
- [ ] A FogVolume pocket in the open doorway and along the path so the door light glows outward.
- [ ] Pine branches between the moon and the camera as god-ray occluders.
- [ ] One fixed fog density for this shot (Guerrilla rule). Don't drift it.

**D. Sky**
- [ ] A **hand-painted panorama** (navy gradient, Milky Way diagonal toward top-right, cloud bank around the moon) as a PanoramaSkyMaterial, rather than a procedural sky.
- [ ] An enlarged, emissive moon disc (about 2–3× realistic size) with cloud edges catching rim light.

**E. Surfaces**
- [ ] Snow albedo around 0.75–0.85, slightly cool, with sparkle via a fine noise in roughness or normal.
- [ ] Cobbles: wet, roughness about 0.15–0.3 with a puddle mask, SSR on. The reflection of the door flame forms the leading line.
- [ ] Snow on fence tops, roof, window ledges and in shadowed corners; not on the path (Insomniac).
- [ ] Mailbox red: check it under AgX; adjust the albedo so it stays red, not orange (Sucker Punch red-primary issue).
- [ ] Plain, dark walls. Let the windows carry the detail (Control).

**F. Motion (one wind)**
- [ ] A global shader uniform `wind_dir` / `wind_strength` used by the snow GPUParticles3D, the ember particles and the pine vertex sway.
- [ ] Embers rise from the door flame and drift with the wind, with a few passing through the lantern light.
- [ ] Snow particles near the lantern and door so they catch warm light; distant snow stays cool.

**G. Grade and post**
- [ ] AgX with exposure **locked** for the opening (no auto-exposure swings).
- [ ] Glow tuned so only the flame, lantern and windows bloom.
- [ ] A hand-made 3D LUT: shadows toward desaturated blue, highlights warm, mid-saturation trimmed.
- [ ] Vignette via a small CanvasLayer or post shader (Godot has no built-in vignette), darkening the corners toward navy rather than black.
- [ ] A slight film grain, if any, applied after the LUT.

**H. Review loop**
- [ ] Every iteration: screenshot beside the reference, at full size and at thumbnail size (does the door still win at thumbnail?), plus a greyscale check (is the door the brightest value?).
- [ ] Paint over the screenshot before changing numbers.
- [ ] Final polish pass: add only drama highlights (gate-post rims, mailbox glint, icicle sparkle).
- [ ] Performance budget: shadows only on the moon, lantern and door; check the frame time before adding more.

---

## Sources

1. Game Developer — "*Last of Us* lighting artist offers devs a tip: set the mood with a single light" — https://gamedeveloper.com/art/-i-last-of-us-i-lighting-artist-offers-devs-a-tip-set-the-mood-with-a-single-light
2. Cook & Becker — "Art Directing The Last of Us Part II" — https://cookandbecker.com/en/article/250/art-directing-the-last-of-us-part-ii.html
3. 80.lv — "How Naughty Dog Created the Immersive World of The Last of Us Part II" — https://80.lv/articles/how-naughty-dog-created-the-immersive-world-of-the-last-of-us-part-ii
4. 80.lv — "Lighting Encyclopedia from Joey Lenz" — https://80.lv/articles/lighting-encyclopedia-from-joey-lenz/
5. GDC Vault — Vivian Ding, "In-Game and Cinematic Lighting of The Last of Us" (GDC 2014) — https://gdcvault.com/play/1020475/contactUs
6. ACM SIGGRAPH History — Doghramachi, "Lighting Technology of The Last of Us Part II" — https://history.siggraph.org/?p=76961
7. Advances in Real-Time Rendering — "The Technical Art of Uncharted 4" (SIGGRAPH 2016) — https://advances.realtimerendering.com/other/2016/naughty_dog/index.html
8. 80.lv — "Tips on Cinematic Environment Production from Naughty Dog" — https://80.lv/articles/tips-on-cinematic-environment-production-from-naughty-dog/
9. 80.lv — "Boon Cotter: Light Magic with Uncharted 4" — https://80.lv/articles/boon-cotter-light-magic-with-uncharted-4/
10. imgeself — "Graphics Study: Red Dead Redemption 2" — https://imgeself.github.io/posts/2020-06-19-graphics-study-rdr2
11. Advances in Real-Time Rendering, SIGGRAPH 2019 course page (Bauer, "Creating the Atmospheric World of RDR2"; Feeley, "Interactive Wind and Vegetation in God of War") — https://advances.realtimerendering.com/s2019/index.htm
12. Screen Rant — "RDR2 landscapes and the Hudson River School" — https://screenrant.com/rdr2-landscapes-hudson-river-school-art-western-paintings/
13. PlayStation Blog — "From brush to blade: The concept art process behind Ghost of Tsushima" — https://blog.playstation.com/?p=342594
14. PlayStation Blog — "Crafting the world of Tsushima" — https://blog.playstation.com/?p=333111
15. PlayStation Blog — "How stunning visual effects bring Ghost of Tsushima to life" — https://blog.playstation.com/?p=345372
16. Jasmin Patry — "Real-Time Samurai Cinema" (SIGGRAPH 2021 Advances) — https://www.advances.realtimerendering.com/s2021/jpatry_advances2021/index.html
17. Game Developer — "Using vorticles to simulate wind in Ghost of Tsushima" — https://gamedeveloper.com/design/using-vorticles-to-simulate-wind-in-i-ghost-of-tsushima-i-
18. 80.lv — "Santa Monica's Senior Programmer on How God of War Ragnarök's Snow System Was Made" — https://80.lv/articles/santa-monica-s-senior-programmer-on-how-god-of-war-ragnar-k-s-snow-system-was-made
19. Santa Monica Studio — Stephen McAuley, "Rendering God of War Ragnarök" (GDC 2023 PDF; not readable during this pass) — https://sms.playstation.com/media/documents/GOWR_Stephen_Mcauley_RenderingGOWR_GDC23.pdf
20. Remedy — "How Northlight makes Alan Wake 2 shine" — https://www.remedygames.com/article/how-northlight-makes-alan-wake-2-shine
21. Remedy — "Explore Remedy's GDC 2024 talks on creating Alan Wake 2" — https://www.remedygames.com/article/explore-remedys-gdc2024-talks-on-creating-alan-wake-2
22. 80.lv — "Remedy's use of Substance 3D in the environment art of Alan Wake 2" — https://80.lv/articles/remedy-s-use-of-substance-3d-in-environment-art-of-alan-wake-2/
23. Game Developer — "How Remedy harnessed the ethereal beauty of brutalism to shape Control" — https://gamedeveloper.com/design/how-remedy-harnessed-the-ethereal-beauty-of-brutalism-to-shape-i-control-i-
24. TechRadar — "How Remedy and Nvidia teamed up to push PC gaming to its limits with Control" — https://techradar.com/news/how-remedy-and-nvidia-teamed-up-to-push-pc-gaming-to-its-limits-with-control
25. 80.lv — "Horizon Zero Dawn: Interview with the Team" — https://80.lv/articles/horizon-zero-dawn-interview-with-the-team
26. PlayStation Blog — "Pushing the envelope: next-level clouds in Horizon Forbidden West: Burning Shores" — https://blog.playstation.com/?p=377555
27. Guerrilla — "Decima Engine: Advances in Lighting and AA" (SIGGRAPH 2017) — https://www.guerrilla-games.com/read/decima-engine-advances-in-lighting-and-aa
28. Kotaku — Horizon Zero Dawn skies and fog rules — https://kotaku.com/1726493049
29. 80.lv — "World Building of Witcher 3" — https://80.lv/articles/world-building-of-witcher-3/
30. Game Informer — "CD Projekt explains The Witcher 3's ever-changing weather" — https://gameinformer.com/b/features/archive/2015/05/12/cd-projekt-explains-the-witcher-3s-ever-changing-weather-with-exclusive-screenshots.aspx
31. Vice — "Elden Ring review" (sightline design) — https://www.vice.com/en/article/elden-ring-review
32. GamesRadar — Akiman on why Elden Ring's visuals hold up — https://www.gamesradar.com/games/action-rpg/legendary-capcom-artist-says-elden-rings-visuals-hold-up-against-higher-fidelity-games-like-crimson-desert-because-the-viewers-imagination-is-constantly-stimulated-to-the-fullest/
33. Kill Screen — "Understanding the sublime architecture of Bloodborne" — https://killscreen.com/understanding-sublime-architecture-bloodborne
34. Games Artist — "Yharnam's Street" (fan environment breakdown) — https://gamesartist.co.uk/yharnams-street/
35. Game Informer — "New York's Only Spider-Man" (Miles Morales cover story) — https://www.gameinformer.com/spider-man/new-yorks-only-spider-man
36. Trusted Reviews — "Marvel's Spider-Man: Miles Morales" review — https://www.trustedreviews.com/reviews/marvels-spider-man-miles-morales
37. Well Played — "Illuminate yourself with the incredible lighting work of Marvel's Spider-Man 2" — https://www.well-played.com.au/illuminate-yourself-with-the-incredible-lighting-work-of-marvels-spider-man-2/
38. PlayStation Blog — "Marvel's Spider-Man 2 PC features and ray-tracing options" — https://blog.playstation.com/2025/01/29/marvels-spider-man-2-pc-features-and-ray-tracing-options-detailed-out-tomorrow/
