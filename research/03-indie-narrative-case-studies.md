# 03 — Indie & Underrated Narrative Games: How Small Teams Build Outstanding Mood

*Research file for **Unsent** (Godot 4.7, Forward+, AgX, volumetric fog). Topic: how small studios get first-class atmosphere through colour, light and restraint rather than budget. Focus: night, snow, melancholy-cozy scenes, lanterns and lit windows.*

> **Method note.** The web search budget for this research turn ran out partway through, so some games (Sable, The Pathless, Lost in Random, The Last Campfire, The Long Dark) have thinner primary sourcing. Their technique notes are partly my own analysis of the shipped games and are marked *(analysis)*. I couldn't reach Reddit or X/Twitter threads. All summaries are paraphrased, with at most one short quote per source.

---

## 1. Key takeaways

1. **Plan colour before you light it.** Firewatch, Gris and Journey all started from a colour script, a strip of key frames mapping palette to story beats, before building levels. Each team decided the emotion first and then chose the hue. For Unsent's opening, decide the single feeling you want (*"someone kept this warm for me"*) and derive every value from it.
2. **The sky is your biggest light source, even at night.** Jane Ng said Firewatch's sky sets most of the colour in frame, sometimes covering half the screen. At night, the sky gradient and fog colour do the same job: they tint every silhouette.
3. **Distance should simplify and tint, not just fade.** Firewatch's colour-gradient fog and stylised distant trees, and Season's detail-by-distance rules, show that atmospheric perspective is a deliberate art-direction tool, not a realism setting.
4. **Use one or two accent hues, very sparingly.** INSIDE is almost monochrome, with colour kept for the player and key beats. Journey's grey cloth turns red when activated. Pathless uses red towers as waypoints. Unsent has two accents to protect: **amber** (home, fire, the parent) and **red** (the mailbox, i.e. the letters).
5. **Darkness is a design material.** Limbo, INSIDE and Little Nightmares get their mood from what they *don't* light. A child-sized protagonist with a single small light source (Six's lighter) reads as fragile and brave.
6. **Warm-inside / cold-outside is the oldest emotional contrast in the book.** Gone Home's storm-lashed house, Kena's crafted cave transitions, Firewatch's lookout at dusk and Spiritfarer's warm boat on a dark sea all rely on a lit interior seen from a cold exterior.
7. **Small teams win by constraint.** Limbo had a core of about 8 people, Firewatch 11, Hellblade about 20, Gone Home 4, Sable 2, Kentucky Route Zero 3, A Short Hike 1. Each picked a constraint (monochrome, flat shapes, low resolution, one house, one character) and turned it into the style.
8. **Cheat with emissives and fake lights.** Most indie "lighting" is emissive textures, painted gradients, billboards and a handful of real shadow-casting lights placed where the eye goes.
9. **Hide transitions in architecture.** Kena's team used linear paths through caves and structures to swap lighting setups without the player noticing. Unsent's doorway does the same job: the shot outside and the shot inside can be lit completely differently.
10. **Mood has to survive gameplay readability.** Gris changed camera angles and level design for readability. A Short Hike added a soft outline. Season found its no-bounce-light shadows too hard to read in forests. Test the opening at gameplay brightness, not just as a screenshot.

---

## 2. Per-game case studies

### Firewatch (Campo Santo, 2016) — colour script, sky gradients, Olly Moss

- **Mood goal.** Lonely but beautiful isolation in the Wyoming wilderness, a man running from grief. The world needed to feel both like a poster and like a real place.
- **Technique.**
  - Development began from one Olly Moss painting. He drew on New Deal-era National Park Service posters for the bold, flat colour.
  - Environment and lighting artist Jane Ng turned the painting into 3D. Moss painted over screenshots to fix shapes, for example sharpening a rock or moving a tree.
  - The team built custom Unity tools for **colour fog** and **procedural skies**, and used Marmoset Skyshop and Amplify Color. The fog is a post effect that looks up its colour in a **gradient texture by distance**, so near hills stay saturated and far ridges dissolve into sky colour. Distance-based fog is preferred over depth-based fog because the gradient doesn't slide when the player turns their head.
  - A **colour script** tied each day's palette to narrative beats.
  - Distant trees become **more stylised** the further away they are. The team built 23 hand-made tree types, about 4,600 placed instances, and billboards for the far distance.
- **Why it works.** The sky-tinted fog unifies everything into a few large, harmonious colour masses, which reads as memory or illustration rather than simulation. That matches a story about a man processing loss. Ng credits the stylised, shape-and-colour approach with letting two or three artists build the whole world.
- **For Unsent.** Build a **night gradient fog**: deep navy-teal in the distance and warmer near the house. The colour script is the single most transferable habit here.

### What Remains of Edith Finch (Giant Sparrow, 2017)

- **Mood goal.** A melancholy-wondrous family house, each room a shrine to someone who died.
- **Technique.** Art lead Brandon Martynowicz did lighting alongside modelling and set dressing. He gave **each bedroom its own palette and lighting direction**, which steers where the player looks. Creative director Ian Dallas described tuning lighting to dial how realistic or storybook a vignette feels. Three artists built hundreds of assets.
- **Why it works.** Light functions as characterisation. A room lit warm-gold, cold-blue or green tells you who lived there before you read a word. The exterior shot of the leaning house at dusk, with its glowing windows, is a direct cousin of Unsent's opening.
- **For Unsent.** Light each upstairs window slightly differently (warmer, cooler, a flickering candle, a steadier lamp), so the house feels like *rooms where people lived* and not a uniform emissive grid.

### Gone Home (The Fullbright Company, 2013)

- **Mood goal.** Coming home at night to an empty house during a storm, with tension that never pays off as horror and instead turns intimate.
- **Technique.** The four-person team cut combat and open-world scope down to one dense house. The game opens on rain, thunder and **lightning flickering through windows**, and the player turns lights on room by room. Kate Craig and Steve Gaynor's GDC "Level Design in a Day" talk covers bringing the house to life. Fullbright treated **lighting and layout as level-design jobs**, not art polish.
- **Why it works.** Turning on lights is itself the emotional verb: you reclaim a dark home. The contrast between the storm outside and the incandescent lamps inside sells "home" more than any prop does.
- **For Unsent.** This is the closest narrative sibling. Consider letting the player light lamps inside, so the opening's "every window glows" becomes a promise that the interior keeps or breaks.

### Limbo (Playdead, 2010) and INSIDE (Playdead, 2016)

- **Mood goal.** Dread, fragility, a lone child in a hostile world.
- **Technique.**
  - *Limbo*: monochrome, film grain, focus and depth blur, film-noir and German Expressionist influence. Director Arnt Jensen chose minimalism so the core team of about 8 could focus on gameplay.
  - *INSIDE*: near-monochrome desaturated palette, with **colour used sparingly** to highlight the boy and key spaces. The GDC Europe 2016 talk "Low Complexity, High Fidelity" (Gjøl and Svendsen) covered **local shadowed volumetrics**, analytic AO, water and SSR. It also covered stochastic or dithered sampling cleaned up by Playdead's **temporal reprojection AA**, the subject of a separate GDC 2016 talk by Lasse Jon Fuglsang Pedersen, with the source released openly.
- **Why it works.** Volumetric shafts from a few lights and an almost colourless world make every light source feel precious or dangerous. The simple shapes keep the image calm enough for the light to carry the emotion.
- **For Unsent.** Godot's volumetric fog works the same way: noisy samples smoothed by temporal reprojection. Use **few shadow-casting lights with volumetric contribution** (moonlight, the door flame, the lantern) rather than many weak ones. Keep the house mostly unlit and dark-valued so the amber reads.

### Little Nightmares (Tarsier Studios, 2017)

- **Mood goal.** Childhood fear seen through a dollhouse.
- **Technique.** A side-on **dollhouse camera** with full 3D depth, an oversized world, and a protagonist who carries only a **lighter**. Light is scarce and meaningful, and enemies' lights are threats. Writer Dave Mervik described Six as a tiny glimmer of light in the darkness. Art director Per Bergman cited older horror films and *Akira*. The sequel's Unreal interview highlights the play of light and dark as the core of its unease.
- **Why it works.** A small warm point light in a huge dark space instantly reads as vulnerability plus hope.
- **For Unsent.** The flame in the open door is a "Six's lighter" moment: small, warm and fragile against a big dark frame. Keep it **small in frame and the brightest value on screen**.

### Journey (thatgamecompany, 2012)

- **Mood goal.** Awe and smallness, plus an emotional arc that follows Campbell's monomyth through life stages. That includes a **cold, snowy mountain climb** that strips the player of warmth before a radiant release.
- **Technique.** John Edwards' GDC 2013 talk "Sand Rendering in Journey" broke the sand into a diffuse-contrast term, Fresnel **rim light** to separate dunes in a limited palette, a water-like **"ocean specular"**, **glitter specular** from grains, and steepness-blended ripple normals. The whole team visited Pismo Beach to study real sand. Art director Matt Nava kept each level to a tight palette. Grey cloth turns vibrant red when activated. The team grew from 7 to 18.
- **Why it works.** Light on the ground surface (glints and rim) makes the environment feel alive. The snow section uses desaturation, wind and a low, cold key to make the player physically want warmth, which pays off emotionally.
- **For Unsent.** (a) The wet cobblestones are your "ocean specular": a strong, low-roughness highlight streak pointing to the door. (b) Snow can take a subtle **glitter term**, a sparse sparkle in the normal or roughness map catching the lantern. (c) The game *begins* where Journey's snow section ends: cold outside, warmth just ahead.

### Kena: Bridge of Spirits (Ember Lab, 2021)

- **Mood goal.** Animated-film warmth around grief and letting go of spirits.
- **Technique.** **Crafted, hand-placed lighting** was central to the cinematic look and to emotional beats. The team used the linear path to **conceal lighting and atmosphere transitions** inside caves and structures. The "Deadzone Regrowth" system blends corrupted and restored states with render-target masks. The studio came from animation and VFX and kept a small core team.
- **Why it works.** Lighting is authored per beat, like film, rather than simulated per hour.
- **For Unsent.** Treat the opening as a **locked, authored lighting set**, not a time-of-day system. Put the light change (exterior blue to interior amber) at the doorway threshold.

### Gris (Nomada Studio, 2018)

- **Mood goal.** Grief and recovery.
- **Technique.** Conrad Roset's watercolour style starts **colourless**. Colours are restored area by area (desert red, forest green, underwater blue, city of light) as the heroine recovers. The team made a colour script up front to check that each area's palette suited the story. They consulted a psychologist on grief, and the team changed cameras and levels when beauty hurt readability.
- **Why it works.** Saturation tracks emotional state, which players read intuitively.
- **For Unsent.** Consider a **saturation arc**: the opening is near-monochrome navy except the amber windows and the red mailbox. Later reconciliation can add warmth to the palette.

### Season: A Letter to the Future (Scavengers Studio, 2023)

- **Mood goal.** Calm nostalgia before the end of the world, capturing one last beautiful moment.
- **Technique.** Unreal's material, light, cloud and fog shaders were reworked, and some physically based maths was **quantised** for a stylised result. Lighting is close to binary (lit or shadow) with **no bounce light**. Sharp shadows and dense foliage made shadowed paths hard to read. Detail-by-distance rules simplify trees and bushes. References were Terrence Malick's golden hour and Norman Wilkinson's poster art, deliberately not other games. Sunsets glow purple and gold.
- **Why it works.** A poster-like simplified palette with warm light against impending doom creates bittersweet comfort, the exact register of Unsent.
- **For Unsent.** Borrow the **"warm against doom" balance** and the habit of using film and poster references. Don't copy the no-bounce lighting: give shadowed snow a little ambient fill (sky contribution) so the fence shadows stay readable.

### Oxenfree (Night School Studio, 2016)

- **Mood goal.** A spooky teenage night on an island.
- **Technique.** Lead artist Heather Gross's watercolour-like backgrounds became more cinematic over production, like **parallaxing feature-animation matte paintings**. Most of the game is at night, but the island was kept organic and inviting. Supernatural elements are **bright, geometric and otherworldly** so they read as foreign. Backgrounds in the first game were fully static. It won the IGF Excellence in Visual Art award.
- **Why it works.** The night stays cozy and the uncanny is a different *kind* of light (hard, saturated, geometric), so the two never blur.
- **For Unsent.** If the embers or butterflies are magical, give them a **distinct light language** (softer, more saturated orange with additive glow) from the "real" amber of the windows.

### Night in the Woods (Infinite Fall, 2017)

- **Mood goal.** Going home to a declining town, with autumn melancholy and depression wrapped in warm cartoon colour.
- **Technique.** Scott Benson's flat, animated shapes and strong colour contrast against a bleak setting. The GDC 2018 design talk and IGF coverage frame the town as feeling like coming home again. *(analysis)* Night scenes use flat navy and violet skies with warm windows and streetlights as cut-out shapes.
- **Why it works.** Flat colour fields make lit windows read like a children's-book "someone is home" icon.
- **For Unsent.** Silhouette clarity matters: the house roofline, chimney and window rectangles should read as a clean shape against the sky gradient.

### Spiritfarer (Thunder Lotus, 2020)

- **Mood goal.** "Cozy death": warmth while ferrying spirits to the afterlife.
- **Technique.** Hand-drawn 2D with a paper texture, drawing on woodblock printing and watercolour (one widely repeated reading says Hiroshi Yoshida, with darkness built from dark reds, blues and greys rather than pure black). The trailer team said colour, lighting, music and timing carry the emotion.
- **Why it works.** Darks that are never black stay tender, not threatening.
- **For Unsent.** **Avoid pure black.** Set the darkest values to deep navy (around #0B1220) and warm umber, and let AgX roll highlights instead of crushing shadows.

### Hellblade: Senua's Sacrifice (Ninja Theory, 2017)

- **Mood goal.** Psychosis and grief, intimate and oppressive.
- **Technique.** About 20 people working on an "independent AAA" model, with cheap mocap (IKEA poles, LED panels) and one fully realised character. Binaural audio carries much of the atmosphere. *(analysis)* Heavy fog, desaturated cold palettes, and fire and torchlight as the only warmth.
- **Why it works.** Focusing the budget on a single character and an audio and fog atmosphere outclasses broad but thin content.
- **For Unsent.** Spend the polish budget on the **one opening shot**. Sound (crackle, wind, distant chimes) is half the lighting.

### A Short Hike (adamgryu, 2019)

- **Mood goal.** Cozy, nostalgic island exploration.
- **Technique.** A solo developer renders 3D to a **low-resolution render target** and upscales without AA, adding a **soft outline** for readability. Pixel size is adjustable. He has said low resolution leaves room for the imagination and makes the world feel lush. Palettes were reportedly sampled from autumn photos.
- **Why it works.** Low detail invites projection, and the player fills the gaps with memory.
- **For Unsent.** Even in a realistic-leaning look, **soft focus and grain in the far distance** (DOF, fog) does the same imaginative work.

### Tunic (Andrew Shouldice / Finji, 2022)

- **Mood goal.** A wondrous, slightly melancholic toy world.
- **Technique.** The game began as **lighting experiments with bounce light on isometric geometry**. Shouldice used dynamic lights and GI with a strictly limited light count, because forward rendering with an orthographic camera can't afford many lights. Node-based shaders (Shader Forge) were used for fast iteration.
- **For Unsent.** Budget real lights like Shouldice did. List every shadow-casting light in the opening and justify each one.

### Unpacking (Witch Beam, 2021)

- **Mood goal.** A life told wordlessly through possessions.
- **Technique.** Pixel-art rooms, over 14,000 foley sounds, no text. Rooms change across years. *(analysis)* Window light and time of day shift subtly between rooms.
- **For Unsent.** Window details (curtains, a plant on the sill, a silhouette of an object) let the exterior shot hint at the interior story.

### Sable (Shedworks, 2021) *(partly analysis)*

- Two people made it, with a Moebius-inspired **line-drawn, flat-shaded** look, hand-crafted environments and a day and night cycle. Its night scenes rely on **flat sky gradients and very limited shading steps**, which proves a night scene can be beautiful with almost no lighting complexity. Lesson: *strong shape design plus a gradient sky can carry a scene alone.*

### The Pathless (Giant Squid, 2020) *(partly analysis)*

- Matt Nava's follow-up to his Journey and Abzû art direction. A muted, foggy forest is punctuated by **glowing red towers as waypoints** and a red storm at the start of each region. Lesson: **one saturated accent colour equals navigation**. Unsent's red mailbox should be the only saturated red in frame.

### The Last Campfire (Hello Games, 2020) *(partly analysis)*

- A small Hello Games team made a folk-tale storybook look, influenced by Brian Froud. The protagonist, a lost soul, is literally named **Ember**. Its campfires are warm radial pools in cool, dark landscapes, a tonal sibling of Unsent's ember and letter theme. Lesson: **the fire as an emotional "home base"**, glowing and particle-rich, framed by cold.

### Lost in Random (Zoink, 2021) *(partly analysis)*

- A gothic fairy-tale look inspired by stop-motion, Burton, *Over the Garden Wall* and Shaun Tan, with each realm given its own design. Lesson: **slightly crooked, hand-made proportions** (leaning fence posts, uneven windows) make a dark scene feel storybook rather than horror.

### Underrated titles worth studying

- **The Long Dark (Hinterland).** The best reference for **snowy nights in a stylised, painterly 3D style**. A remote team built a full day and night cycle with much colder nights, and critics single out its lighting and atmosphere. Its interiors lit by a stove seen from snowy exteriors are almost exactly Unsent's premise. *(Mostly analysis: study its aurora nights and stove light spill on snow.)*
- **Kentucky Route Zero (Cardboard Computer).** Three people, with **theatrical stage lighting** influenced by theatre scripts and magical realism. Night scenes are flat dark planes with isolated pools of light, like a stage. It won IGF visual art. Lesson: **light only what matters; let the rest be stage-black navy.**
- **Season** and **Oxenfree** (above) are both underrated in lighting discussions relative to their craft.

---

## 3. Small-team tricks (synthesis)

| Trick | Who did it | Godot 4.7 equivalent |
|---|---|---|
| **Colour script first** | Firewatch, Gris, Journey | 5–8 paintover keyframes of the opening (approach, gate, path, door) before tuning lights |
| **Gradient / distance-tinted fog** | Firewatch | `Environment.fog` (depth fog with `fog_light_color`, `fog_sky_affect`) plus `volumetric_fog` with `albedo` tinted navy; optional custom sky-colour fog via a `FogVolume` shader or post pass |
| **Painted / procedural sky** | Firewatch, Sable, NITW | `Sky` with a custom `sky_shader`: vertical navy gradient, Milky Way band texture, moon disc, cloud layer. Cheap and fully art-directable |
| **Stylise with distance** | Firewatch, Season | Lower-detail pine cards or billboards in the background; heavier fog density far away |
| **Emissive cheats for windows** | Most | `StandardMaterial3D` emission on the window panes plus a curtain texture; one cheap `OmniLight3D` (no shadows) per room just inside to spill light on sills and snow |
| **Few real shadow lights** | INSIDE, Tunic | 3 shadowed lights max: moon `DirectionalLight3D`, foreground lantern `OmniLight3D` (shadows ON, for the fence shadows), door flame `OmniLight3D` |
| **Volumetric shafts from key lights only** | INSIDE | `Light3D.light_volumetric_fog_energy`: high on moon and lantern, zero on window fill lights |
| **One accent hue for meaning** | INSIDE, Journey, Pathless | Amber = home; red = mailbox and letters only. Everything else is desaturated navy, grey and umber |
| **No pure black** | Spiritfarer | AgX tonemap, a slight ambient sky contribution, darkest albedo around 0.04 |
| **Constraint as style** | A Short Hike, Limbo | Optional film grain plus vignette in a full-screen `CanvasLayer` shader; mild DOF on far pines |
| **Hide light changes at thresholds** | Kena | Swap `WorldEnvironment` or exposure as the player crosses the door |
| **Surface specular as leading line** | Journey | Cobblestones at low roughness (~0.15–0.25) with a puddle normal map; a `ReflectionProbe` at the path catches the door glow |
| **Glitter / sparkle** | Journey | A noise texture in snow roughness or emission at tiny scale catching the lantern |
| **Sound as lighting** | Hellblade, Gone Home | Fire crackle positioned at the door; wind; snow creak |

---

## 4. Apply to Unsent's opening — checklist

Reference: symmetric front view of a dark two-storey house at night, every window amber behind curtains, an open door with a small flame, a wet cobble path, a foreground lantern with long fence shadows, a moon behind clouds with god rays through pines, a navy sky with the Milky Way, snowy pines framing the sides, embers, snow, a red mailbox and a vignette.

**Emotion and colour script**
- [ ] Write the one-line mood goal above the scene file, for example *"cold world, one warm promise: someone kept the fire going."* Reject any change that doesn't serve it.
- [ ] Paint or paintover 4–6 key frames (first view, at the gate, mid-path, on the step, in the doorway) as a mini colour script.
- [ ] Lock the palette: sky navy (~#0E1A2E to #1B2A44 at the horizon), snow blue-grey (~#8C9BB0 in shadow), window amber (~#FFB45A core, #E07A2A falloff), door flame (hotter, ~#FFD08A core), mailbox red (~#B3262A, the only red), and dark values never pure black.

**Sky, moon and fog (Firewatch, Journey)**
- [ ] Custom sky shader: vertical gradient, Milky Way band, moon disc plus halo, a slow cloud layer partly occluding the moon.
- [ ] Moon `DirectionalLight3D`: cool (~7000–9000K look), low energy, shadows on, `light_volumetric_fog_energy` high enough for visible shafts through the left pines.
- [ ] Volumetric fog on: low density near the camera and denser in the tree line. Albedo slightly blue so the shafts read cool and the amber stays warm by contrast.
- [ ] Depth fog colour sampled from the horizon sky so the far pines dissolve into the sky (Firewatch's distance-gradient idea).

**The house (Edith Finch, Gone Home, NITW)**
- [ ] Keep the facade dark-valued and slightly desaturated. The windows carry it.
- [ ] Windows: emissive panes plus a curtain texture with soft transmission. Vary each window ±10% in hue and intensity, and give one a subtle flicker (candle).
- [ ] One unshadowed `OmniLight3D` inside each lit window, or a shared one per floor, spilling a soft warm pool onto the sill snow and bushes.
- [ ] Confirm the roofline, chimney and window grid read as a clean silhouette against the sky gradient.
- [ ] Icicles and roof-edge snow catch the moon rim (a Fresnel/rim boost in the material).

**Focal point: the door flame (Little Nightmares, Last Campfire)**
- [ ] The flame is the brightest value on screen and small in frame, on the vertical centre axis.
- [ ] Door `OmniLight3D`: warm, shadowed, gentle flicker (noise on energy ±8%, not strobing), volumetric energy moderate so the doorway exhales a warm haze.
- [ ] Embers and sparks (`GPUParticles3D`, additive emissive, rising slowly) drift from the door. Give magical embers or butterflies a distinct, more saturated light language than the windows (Oxenfree).
- [ ] Glow/bloom: HDR threshold set so only the flame, the lantern and the window cores bloom. The facade must not haze over.

**Leading line: wet cobblestone path (Journey's ocean specular)**
- [ ] Cobbles at low roughness with a puddle mask, plus a `ReflectionProbe` (or SSR) catching the door glow as a streak pointing at the door.
- [ ] Snow pushed to the path edges, so the dark wet stone versus pale snow makes a clear converging wedge.

**Foreground lantern and fence shadows**
- [ ] Lantern `OmniLight3D`: shadows ON, placed so the picket shadows stretch toward the camera (light behind and above the fence). Tune shadow bias and blur for crisp near shadows.
- [ ] Emissive lantern glass plus a tiny bloom. A snow cap on top.
- [ ] Give the shadowed snow a little sky ambient so the fence shadows read as blue on lit amber snow, not black holes (a lesson from Season).

**Framing pines and snow (The Long Dark, Firewatch)**
- [ ] Left and right pines as dark, low-detail frames. Use heavier fog and simpler cards in the far tree line.
- [ ] Falling snow: two particle layers (near, large and soft with DOF; far, small and dense), lit by the scene so flakes near the lantern glow amber.
- [ ] Optional snow glitter: sparse sparkle in the snow roughness or emission near the lantern.

**Accent and finishing (INSIDE, Pathless, Spiritfarer)**
- [ ] The red mailbox is the only saturated red, placed right of the path to balance the lantern on the left.
- [ ] AgX tonemap. Grade with slight warm highlights and cool shadows, and lift the darkest values off black.
- [ ] Vignette plus very light film grain as a final `CanvasLayer` pass. Subtle DOF on the far tree line only.
- [ ] Exposure and environment can switch at the door threshold so the interior can have its own lighting (Kena's trick).

**Readability and performance**
- [ ] Test at gameplay brightness on a mid-range monitor. Squint test: house silhouette, door flame and path wedge must read in under a second.
- [ ] Budget: at most 3 shadow-casting lights, cheap window fills, volumetric fog at a moderate resolution with temporal reprojection on.
- [ ] Sound pass alongside lighting: fire crackle at the door, wind in the pines, soft snow footsteps.

---

## 5. Sources

**Firewatch**
1. GDC Vault — *The Art of Firewatch* (Jane Ng): https://www.gdcvault.com/play/1023707/contactUs
2. Thumbsticks — GDC 2015: The Art of Firewatch: https://www.thumbsticks.com/gdc-2015-the-art-of-firewatch
3. PCGamesN — Jane Ng on creating Firewatch's wilderness: https://www.pcgamesn.com/firewatch/there-was-a-lot-of-copy-pasting-jane-ng-talks-creating-firewatchs-wyoming-wilderness
4. PC Gamer — Why less is more with Firewatch's trees: https://www.pcgamer.com/uk/why-less-is-more-when-it-comes-to-firewatchs-beautiful-trees/
5. Campo Santo Quarterly — Moss Day: https://camposanto.com/quarterlyreview/volume-1/issue-2/moss-day
6. Game Developer — Inside the art design of Firewatch (video): https://gamedeveloper.com/art/video-inside-the-art-design-of-i-firewatch-i-
7. grrava blog — Stylistic fog from Firewatch: https://grrava.blogspot.com/2018/08/stylistic-fog-from-firewatch-with.html
8. Wikipedia — Firewatch: https://en.wikipedia.org/wiki/Firewatch

**Playdead (Limbo / INSIDE)**
9. GDC Vault — Low Complexity, High Fidelity: INSIDE Rendering: https://gdcvault.com/play/1023002/contactUs
10. GDC Vault — Temporal Reprojection Anti-Aliasing in INSIDE: https://www.gdcvault.com/play/1022970/Temporal-Reprojection-Anti-Aliasing-in
11. 80.lv — The Rendering of INSIDE: https://80.lv/articles/the-rendering-of-inside-low-complexity-high-fidelity
12. arXiv — Optimisations for Real-Time Volumetric Cloudscapes (cites Gjøl & Svendsen 2016): https://arxiv.org/pdf/1609.05344
13. Wikipedia — Inside: https://en.wikipedia.org/wiki/Inside_(video_game)
14. Wikipedia — Limbo: https://en.wikipedia.org/wiki/Limbo_(video_game)

**Journey / The Pathless**
15. GDC Vault — Sand Rendering in Journey (John Edwards): https://gdcvault.com/play/1017742/Sand-Rendering-in
16. Alan Zucconi — A Journey into Journey's Sand Shader: https://www.alanzucconi.com/2019/10/08/journey-sand-shader-1/
17. Polycount — The technical art behind Journey: https://polycount.com/discussion/125544/the-technical-art-behind-journey
18. Wikipedia — Journey: https://en.wikipedia.org/wiki/Journey_(2012_video_game)
19. Unreal Engine — Giant Squid and The Pathless: https://www.unrealengine.com/spotlights/giant-squid-aims-to-connect-with-players-in-the-pathless
20. Vice — The Pathless review: https://www.vice.com/en/article/wx8d4x/pathless-review

**Edith Finch / Gone Home**
21. Red Bull — What Remains of Edith Finch interview (Martynowicz): https://www.redbull.com/us-en/what-remains-of-edith-finch-interview
22. Unreal forums — Inside Unreal: Building the Art for Edith Finch: https://forums.unrealengine.com/t/livestream-building-the-art-for-what-remains-of-edith-finch-inside-unreal/610445
23. Game Developer — How Gone Home's design constraints led to a powerful story: https://www.gamedeveloper.com/design/how-i-gone-home-i-s-design-constraints-lead-to-a-powerful-story
24. GDC Vault — Level Design in a Day (Gone Home): https://gdcvault.com/play/1022112/Level-Design-in-a-Day
25. GDC 2015 Narrative Review (Shilts, PDF): https://media.gdcvault.com/gdc2015/GameNarrativeReview/Shilts_GDCNarrativeReview.pdf

**Little Nightmares**
26. Game Developer — Crafting the off-kilter world of Little Nightmares: https://gamedeveloper.com/design/crafting-the-bizarre-off-kilter-gameworld-of-i-little-nightmares-i-
27. Unreal Engine — How Little Nightmares II plumbs adolescent angst: https://www.unrealengine.com/en-US/developer-interviews/how-little-nightmares-ii-plumbs-the-depths-of-adolescent-angst
28. Xbox Wire — Little Nightmares 2 interview: https://news.xbox.com/en-us/2021/03/12/little-nightmares-2-interview/
29. IBTimes — Little Nightmares interview (Mervik): https://www.ibtimes.co.uk/little-nightmares-interview-fear-nothing-without-beating-heart-1618382
30. Wikipedia — Little Nightmares: https://en.wikipedia.org/wiki/Little_Nightmares

**Kena / Hellblade**
31. 80.lv — Visual identity development of Kena: https://80.lv/articles/visual-identity-development-of-kena-bridge-of-spirits
32. Unreal Engine — The magic of creating Kena: https://www.unrealengine.com/developer-interviews/the-magic-of-creating-kena-bridge-of-spirits
33. Wikipedia — Hellblade: Senua's Sacrifice: https://en.wikipedia.org/wiki/Hellblade:_Senua%27s_Sacrifice
34. Xbox Wire — 10 things about Hellblade: https://news.xbox.com/en-us/2018/12/19/10-things-hellblade-xbox-one/

**Gris / Season / Oxenfree / Night in the Woods / Spiritfarer**
35. Wikipedia — Gris: https://en.wikipedia.org/wiki/Gris_(video_game)
36. Jackson's Art — Artist Insights: Gris: https://www.jacksonsart.com/blog/?p=1563782
37. Game Developer — Love like a sunset: Season's hazy visuals: https://gamedeveloper.com/art/love-like-a-sunset-the-inspiration-and-ideology-behind-season-s-hazy-visuals
38. Wikipedia — Season: A Letter to the Future: https://en.wikipedia.org/wiki/Season:_A_Letter_to_the_Future
39. Game Developer — Road to the IGF: Oxenfree: https://gamedeveloper.com/design/road-to-the-igf-night-school-studio-s-i-oxenfree-i-
40. DigiPen — Heather Gross, art lead on Oxenfree: https://news.digipen.edu/alumni/digipen-graduate-heather-gross-art-lead-oxenfree-winning-awards-working-indie-games-whats-next
41. Game Developer — Road to the IGF: Night in the Woods: https://gamedeveloper.com/business/road-to-the-igf-infinite-fall-s-i-night-in-the-woods-i-
42. 80.lv — GDC18: The Design of Night in the Woods: https://80.lv/articles/gdc18-the-design-of-night-in-the-woods
43. Game Developer — Inside the thoughtful design of Spiritfarer: https://www.gamedeveloper.com/design/inside-the-thoughtful-design-of-thunder-lotus-i-spiritfarer-i-
44. Toon Boom — Spiritfarer's animated trailer: https://www.toonboom.com/?p=13714
45. Destructoid — Spiritfarer documentary: https://www.destructoid.com/spiritfarer-documentary-cozy-afterlife-game/

**A Short Hike / Tunic / Unpacking / Sable / others**
46. PlayStation Blog — Crafting a tiny open world (A Short Hike): https://blog.playstation.com/2021/08/05/crafting-a-tiny-open-world-a-look-behind-the-scenes-at-the-creation-of-a-short-hike/
47. j-red — Arcade flight proof of concept (low-res render-texture technique): https://j-red.github.io/arcadeflight
48. Unity Blog — Smoke, mirrors and scrolling textures: behind the scenes of TUNIC: https://blog.unity.com/games/smoke-mirrors-and-scrolling-textures-behind-the-scenes-of-tunic
49. Game Developer — How TUNIC weaves wondrous worlds: https://www.gamedeveloper.com/road-to-igf-2023/how-tunic-weaves-wondrous-unknowable-worlds-inspired-by-inscrutable-nes-manuals
50. Wikipedia — Unpacking: https://en.wikipedia.org/wiki/Unpacking_(video_game)
51. Wikipedia — Sable: https://en.wikipedia.org/wiki/Sable_(video_game)
52. Wikipedia — The Last Campfire: https://en.wikipedia.org/wiki/The_Last_Campfire
53. Wikipedia — Lost in Random: https://en.wikipedia.org/wiki/Lost_in_Random
54. Wikipedia — The Long Dark: https://en.wikipedia.org/wiki/The_Long_Dark
55. Wikipedia — Kentucky Route Zero: https://en.wikipedia.org/wiki/Kentucky_Route_Zero

*Gaps to fill in a follow-up pass: Reddit and X threads by the artists (not reached), the full text of the GDC talks (Vault is paywalled; the YouTube uploads exist), Sable and Long Dark art-director interviews, and The Art of Journey / The Art of Firewatch art books.*
