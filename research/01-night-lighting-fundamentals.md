# 01 — Night Exterior Lighting Fundamentals (Games and Film)

*Research topic for the Unsent lighting and art-direction knowledge base. Target shot: the snowy two-storey house at night (`reference_target.webp`).*

> **Research note:** the shared web-search budget ran out partway through this task. Film, 80.lv, GDC/Game Developer and engine-doc sources are well covered. Reddit, X/Twitter and ArtStation coverage is thin: the "community" material comes mostly from Roblox DevForum, itch.io and Unreal forum threads that appeared in searches. Numbers marked *(general practice)* are common industry figures that no fetched source in this set states.

---

## 1. Key takeaways

1. **Night is designed, not simulated.** Film and games both aim for "Hollywood darkness": the scene should *feel* dark while the viewer can still see what matters (radiator blog, Lighting Theory pt. 4). A black frame is a failure, not a mood (Videomaker; Sony Cinematography).
2. **One key, then everything supports it.** Start with a single motivated key light, match it to a reference, and only then add more. If the scene gets muddy, delete the lights and start again from the key (Gabe Betancourt, Naughty Dog, via Game Developer).
3. **Moonlight is a hard, high back- or side-light, never a front light.** Deakins placed his "moon" so it hit his large night set from the side or back, almost never from the front (British Cinematographer masterclass, via search summary). The rim is what sells night: the edge light sits about **1–1.5 stops over**, the fill about **1.5–2 stops under** (TV Technology).
4. **Blue moon, warm practicals: keep the blue gentle.** Moonlight is not actually blue. It looks bluish because of the Purkinje shift and because warm sources sit next to it. Film cools the moon only **¼–½ CTB** against a tungsten scene. Deep, saturated blue is called a cliché (TV Technology; Wikipedia, Day for night; StudioBinder).
5. **Plan contrast as a ratio and a value map.** Key-to-fill ratios run from about **2:1–3:1** (gentle) to **4:1** (drama) to **7:1–8:1+** (thriller). For game spaces, start near **3:1** and push from there (Game Developer, contrast fundamentals). Lock a 2–3 value *notan* read before you think about colour.
6. **Ambient is a navy floor, not a light.** Outdoor ambient works as a dark navy fill so shadows never go pitch black (radiator blog). Too much ambient flattens form; zero ambient creates "black holes" that put audiences off (Sony Cinematography).
7. **Colour is a reward, so ration it.** Make most of the frame muted blue and save the saturated complementary orange for the focal point (Stephen Falk, 80.lv night scene).

---

## 2. Principles and actionable techniques

### 2.1 Key, fill and rim at night

- **Translate the three-point setup into game terms.** The GDC 2018 "How to Light a Level" talk maps the roles directly: **Key** is the directional light (sun or moon), **Fill** is ambient or SH probes, and **Rim** is Fresnel or reflection probes (radiator blog / SlideShare deck). The same deck notes that no fill level is "too dark" by default, and advises adding fill when in doubt.
- **Rim beats key for set pieces.** In games the player moves the camera, so a rim light can turn into a key light from another angle. For hero set pieces, rim and background lights read more reliably than a key. Light the critical path roughly *perpendicular* to the direction of travel so it reads as rim (radiator blog, GDC 2018).
- **Use TV Technology's three-step night rig.** (1) A hard edge or backlight above head height, about **+1 to +1.5 stops** over key exposure. (2) Soft fill about **−1.5 to −2 stops** under, just enough to show detail. (3) A *background backlight* that edges the environment the way the edge light edges the subject. Front-lighting the background looks fake.
- **Night light is mostly hard.** Moon, street lamps and lanterns are small sources, so shadows should be crisp and falloff visible: brighter near the source, darker away from it (Videomaker). The exception is the broad "moon box" fill: film crews hang a large diffused overhead source to set a base level, then add small hidden "specials" to pick out tree trunks and walls (Sony Cinematography).
- **Separate the planes.** Foreground, midground and background each need their own light level to read as depth. Typical film practice keeps the subject in fill while the background falls darker, but never to black (Sony Cinematography).

### 2.2 Motivated light sources

- **Every light needs a believable source:** moon, lamp, candle, window or TV (Videomaker; StudioBinder). Adriano Grasso describes giving each light a realistic motivation and composing outward from the focal point (80.lv).
- **Practicals do double duty.** A visible lamp, candle or window both lights the scene and *explains* the lighting (StudioBinder; No Film School, Julia Swain demo). Swain shows three versions: bare moonlight, moonlight plus practicals, and practicals alone. The combined version reads as the most "lived-in" night.
- **Prefer in-scene sources to invisible fills.** The 80.lv "moody lighting" breakdown advises it directly. When you must cheat, keep fill lights low on specular. Set them to "Not Important" in Unity or raise min roughness in Unreal so they don't leave stray highlights that reveal the cheat (radiator blog).
- **Guide the player with motivated hierarchy.** Light main routes more than side routes, and keep each object type's lighting language consistent (radiator blog). In *The Last of Us*, directed light picks out the path, cold searchlights mark danger, and yellow and red accents flag interactables (80.lv, TLOU level design).

### 2.3 Warm vs cool contrast

- **Use real colour temperatures as a starting point:**
  - Moonlight: about **4100 K** (Artlist), or a range of **4100–4500 K** (Videvo). It is physically *warmer* than daylight sky light, but reads blue next to tungsten.
  - Tungsten and practicals: **~2700–3200 K**. Candles and fire: **~1800–2000 K** *(general practice)*.
  - Shooting moonlight with the camera set to **3200 K** makes daylight-temperature light read blue (Videomaker). Day-for-night historically used tungsten-balanced (3200 K) stock instead of daylight (5000 K) stock for the same reason (Wikipedia).
- **The contrast between the two does the work, not the absolute values.** B&H notes that the mind reads moonlight as blue *because* warm campfires and windows sit beside it (search summary). In engine terms: white-balance your scene to the warm practicals, and the cool key will read as moonlight.
- **Ration the warm.** Falk's 80.lv night scene keeps nearly the whole frame in muted blues and reserves the complementary orange for the garage interior, which is the focal point. A small orange "battery" light on the opposite side balances the composition.
- **Desaturate the moon.** TV Technology prefers silvery moonlight to blue. Cool the moon a quarter to half step, desaturate it in the grade, and keep front fill near neutral.

### 2.4 Value structure and the notan / 3-value read

- **Notan** (濃淡, "dark–light") was taught in the West by Arthur Wesley Dow (*Composition*, 1899). It reduces an image to flat light and dark shapes. A **2-value** notan is black and white. A **3-value** notan adds one middle grey (Wikipedia; MasterClass).
- **Do it for lighting.** Before tuning any colour, squint at a greyscale frame and check for three clear groups: **darks** (silhouettes, facade, pines), **mids** (sky, snow in moonlight, path), and **lights** (practicals, focal point). If two groups merge, the shot won't read.
- **Keep the full range, and anchor it.** Falk kept "at least one bright area" so the night frame still uses the full value range. Night means *most* of the frame is dark, not that nothing is bright.
- **Perceived brightness is relative.** A Vermeer comparison shows that an image with more dark area reads as *brighter* even when its whites match (Game Developer, contrast). Dim the unimportant areas instead of brightening the important ones (radiator blog).
- **Watch the white point.** In UE4, a pure-white pick in a blank scene came out at 209/209/209, which silently compresses the range (80.lv moody lighting). Check where your tonemapper actually puts white.

### 2.5 Low-key exposure: dark but not muddy

- **Muddy means the values are compressed in the middle,** not that the frame is too dark. The usual causes are too much flat ambient, too many competing lights, heavy fog, or a "very high contrast and saturation" grade that makes light sources render darker than expected (Roblox DevForum).
- **Expose bright, grade down.** Cinematographers expose a little brighter than the target and pull it down in the grade to keep detail and avoid noise (In Depth Cine; *Mad Max: Fury Road* overexposed on set and darkened in post, per Wikipedia). Day-for-night is commonly about **2 stops under** (Wikipedia). The game equivalent is to light the scene so it reads at normal exposure, then lower exposure and contrast in post. Don't build it dark from the start.
- **Set a base level so the deepest shadows still hold detail.** "Black holes" put audiences off (Sony Cinematography). The goal is "you can just barely make out objects" (Roblox DevForum, for non-horror games).
- **Use fog to separate, not to wash out.** On *Left 4 Dead*, a designer writes that simple exponential fog greatly improved readability by separating enemies from backgrounds (search summary of the GameDesignerNotes post). But the 80.lv moody-lighting artist found his first fog too strong: the reference had weaker fog, stronger sources, and areas falling into darkness.
- **Don't rely on the brightness slider.** Developers tune in dark studios on good monitors; players don't play that way. Former id director Tim Willits calls the slider a "necessary evil" (Kotaku). Check the shot on a cheap monitor and in a lit room.

### 2.6 Day for night, and the moonlight-reads-blue convention

- **Classic recipe:** shoot or render in daylight, then underexpose (about 2 stops), compress contrast, desaturate and cool. Use **hard back- or side-sun** so the shadows look like moon shadows. Avoid visible cloud detail and bright sky, which give the trick away (In Depth Cine; Wikipedia).
- **Why blue:** the **Purkinje effect** shifts the eye's peak sensitivity toward blue as light dims (mesopic vision), so blues stay visible and **reds darken** (Wikipedia, Purkinje effect). Ghost of Tsushima's SIGGRAPH 2021 talk (Jasmin Patry) simulated this low-light behaviour of human vision to sell its nights (search summary of the slides).
- **Know the convention's limits.** Far Cry 5's team tinted the moon light blue and treated it as a separate light, "following film practice", and flagged the risk of blue spreading over the whole scene (SIGGRAPH 2018 notes, search summary). TV Technology calls saturated blue moonlight a cliché. Use blue as a *tint* on the key and ambient, not a wash over everything.
- **The moon is weak.** It reflects only about **12%** of sunlight (In Depth Cine). Real productions add an artificial "moon" overhead: moon boxes, Musco cranes, balloon lights (Sony Cinematography). In a game you are free to make the moon as strong as the shot needs.

### 2.7 How much ambient to allow

- **Make ambient a dark navy or blue-purple floor** (radiator blog, Lighting Theory pt. 4). Its job is to stop shadows going pure black, not to show form. Ambient is flat and gives no sense of direction, so if it gets bright enough to be noticed, the scene flattens.
- **Interior "room tone" is the film parallel:** a large bounce several stops under the key, so the space feels sourceless (TV Technology).
- **Engine pitfalls:** a daytime template's leftover blue skylight lifts every shadow (Unreal tutorial, search summary). The opposite mistake is setting ambient to zero, which turns everything without direct light into black (Roblox and Unreal forums). Remember that SSAO only affects ambient, so at very low ambient it will be barely visible (Godot docs).
- **Rule of thumb from the sources:** ambient should sit about **2+ stops below** the moon key and further below the practicals. That lines up with TV Technology's fill at −1.5 to −2 stops.

### 2.8 How lighting artists start

1. **Reference and moodboard first.** Grasso sorts about 30 references into movement, palette and weather/time-of-day groups (80.lv). The moody-lighting artist uses a Pinterest board and cuts anything off-tone (80.lv).
2. **Greybox with baking off.** Turn off precomputed lighting while blocking out (radiator blog: Unreal "Force No Precomputed Lighting", Unity "Auto-Generate" off).
3. **Do a clay/grey pass.** Replace every material with one *mid* grey, not white, so form, shadow shape and value groups show without texture noise (clay-render guides; Blender Studio says lighting can start as soon as the first blocking exists).
4. **Set the global mood:** time of day, key direction, ambient (radiator blog). Then light the focal point or character first and build outward (Grasso).
5. **Use one light at a time.** Match the reference with only the key, then add support lights. Reset when the scene gets muddy (Betancourt).
6. **Albedo pass.** Lighter albedos bake more plausibly. Aim for the upper midtones of the histogram (radiator blog).
7. **Iterate exposure in tests and compare with the reference** (Falk). Rough out contrast in Photoshop Curves, then carry it into the post volume (80.lv moody lighting).
8. **Post and grade last** (Grasso).

---

## 3. Examples from games and films

| Work | What it does with night light | Lesson for Unsent |
|---|---|---|
| ***1917*** (Deakins) | The night ruins are lit almost entirely by a 50 ft, six-tier burning-church rig plus flares. Every unit is on dimmers, ridden live as the camera moves (ASC). | One dominant warm motivated source can carry a whole night exterior; animate its intensity. |
| ***No Country for Old Men*** (Deakins) | The "moon" is placed on a bluff, so it only ever side- or back-lights the set (British Cinematographer, via search). | Put Unsent's moon behind and to the side so it rims snow and roofs instead of flattening the facade. |
| ***Before Sunrise*** | Warm street lights key the actors, with a little blue moonlight as fill (StudioBinder). | Warm key on what matters, cool on what doesn't. |
| ***E.T.*** | Cool-temperature units stand in for moonlight in the woods (StudioBinder). | The cool backlight through trees is iconic. |
| ***Nope*** / ***Killers of the Flower Moon*** | Infrared day-for-night and blue-hour sky plates (In Depth Cine). | "Night" is a constructed look; build the sky separately. |
| ***The Last of Us*** | Directed light shows the path, cold lamps mean danger, warm accents flag interactables (80.lv). The lighting artist's rule is to start with one light (Game Developer). | The door flame is the "interactable" warm accent. |
| ***Cyberpunk 2077*** | Night City treated as a "living, digital film set". GDC 2022 talk on night interiors and the open world (Game Developer / GDC Vault). | Even huge night worlds are lit shot by shot. |
| ***Far Cry 5*** | A separate blue-tinted moon light, borrowed from film, with care so blue doesn't take over (SIGGRAPH 2018). | Tint the key and keep the grade neutral. |
| ***Ghost of Tsushima*** | Simulates human night vision (Purkinje) for convincing nights (SIGGRAPH 2021). | Desaturate shadows and let reds darken. |
| ***Red Dead Redemption 2*** | Praised for its night skies and dynamic moonlight, but some players find its nights too bright and mod them darker (GameRant, Twinfinite, Steam, Nexus). | There is no universal "right" darkness; pick it per shot and test on varied screens. |
| ***Firewatch*** (underrated-style example) | Stylized shapes and colour, coloured fog and procedural skies, so the palette shifts as the player moves (Jane Ng, via PC Gamer / Boing Boing summaries). | Coloured fog is a cheap, powerful mood tool for a small team. |
| ***Left 4 Dead*** | Simple exponential fog improves silhouette readability at night (GameDesignerNotes, via search). | Fog = separation. |
| **Falk's UE night scene** (80.lv) | Blue moon rays through trees on the left and right obscure detail and frame a warm orange focal interior. A small orange light balances the frame. | This is almost exactly Unsent's composition. |
| **Novart's "When the Lights Are On"** (80.lv, Blender) | Window emission × stretched noise fakes uneven room light behind glass, and volume scatter adds melancholy. | Don't make the windows flat; vary them. |

---

## 4. Common mistakes

1. **Crushing to black.** "Eliminating all light" hides the action (Videomaker), and black holes disconcert viewers (Sony Cinematography).
2. **Saturated blue everywhere.** Over-lit "ultra-blue" distracts (Videomaker) and reads as a cliché (TV Technology). Blue that spreads into the whole scene was a known risk on Far Cry 5.
3. **Ambient too high, or zero.** Too high flattens form and turns everything grey-blue. Zero makes every unlit area pitch black.
4. **Too many lights.** Competing directions and muddy shadows; Betancourt's fix is to delete them and restart from the key.
5. **Unmotivated lights.** A light with no source breaks believability (Videomaker; Grasso).
6. **Front-lighting the moon or the background.** It flattens the scene and looks artificial (TV Technology; Deakins).
7. **Fog too dense.** It washes out the scene and kills the value range (80.lv moody lighting). In Godot it can also cause banding.
8. **No bright anchor.** Without one, the frame has no full value range and reads muddy (Falk).
9. **Leaving auto-exposure on.** It lifts a dark scene back to mid-grey, or blows out the practicals when the player looks at them (Battlefield forum complaint, via search).
10. **Tuning on one good monitor only.** Players use bright rooms and cheap screens (Kotaku).
11. **Pure-white albedo on snow.** Snow then becomes the brightest thing in a moonlit frame and competes with the focal point. This is the outdoor version of the over-bright mortar problem in Game Developer's contrast article.

---

## 5. Apply to Unsent's opening (checklist)

**Goal read (3-value notan):** **Darks** are the facade, the pine masses, the frame edges and the foreground ground. **Mids** are the navy sky, the moonlit snow on roofs and branches, and the cobbles. **Lights** are the door flame (brightest), the lantern (second), the windows (third), and the moon disc. Check this with saturation at 0 before any colour work.

### Blockout / grey pass
- [ ] Blocked-out house, fence, path, pines and lantern. All materials set to one ~0.4–0.5 linear mid-grey (no white snow yet). Use Godot's viewport *Display Lighting* / `DEBUG_DRAW_LIGHTING` mode to judge light alone.
- [ ] Place **only the moon** (`DirectionalLight3D`) first. Then add the door flame and check the notan at each step.
- [ ] Take a greyscale screenshot and a blurred/squint version. Confirm the door is the brightest shape and the facade is a clean dark silhouette against the mid-navy sky.

### Key (moon)
- [ ] Put the moon **top-left and behind** the house (back- or three-quarter side-light). It should rim the snowy roof edge, chimney, icicles and pine branch tips, and must not light the front facade flatly.
- [ ] Colour: a slightly cool, *desaturated* silver-blue (e.g. ~6500–8000 K equivalent against a ~3000 K white point; Godot: light colour around `#B8C8E8`, tuned by eye). Avoid saturated blue.
- [ ] Shadows on with soft-ish blur, so the pine shadows on the snow give large shapes.
- [ ] Moon `light_volumetric_fog_energy` raised for **god rays through the left pines**. Restrict the visible rays with a local `FogVolume` around those branches rather than raising global density.

### Fill (ambient)
- [ ] Environment ambient source = **Color** (or Sky with `ambient_light_sky_contribution` < 1), set to a **dark navy** (~`#141B2E`). Energy low: shadows should be about 2 stops under the moon-lit snow and never pure black.
- [ ] If SDFGI or VoxelGI is on, check that snow bounce doesn't lift the facade into grey mush. Lower the GI energy before lowering the key.

### Practicals (warm, motivated)
- [ ] **Door flame:** the hottest point (~1800–2000 K, deep orange). Small `OmniLight3D` with shadows, animated flicker. Highest exposure in frame; it lights the threshold and the wet cobbles.
- [ ] **Windows:** amber (~2700–3000 K). Emissive curtain material with a noise/gradient variation per window, as in Novart's breakdown, so they don't look stamped. Add small, low-range omnis inside to spill onto the sills and the snow below. Keep them all *dimmer than the door*. Consider making one or two dimmer for narrative ("someone isn't home").
- [ ] **Porch sconces:** small and warm, low range, as secondary support for the door.
- [ ] **Fence lantern (foreground left):** warm, shadow-casting omni placed so the **picket shadows stretch toward the camera**. This is the foreground rim and the leading-line device. Keep its energy below the door's even though it is closer.

### Contrast, ratios and exposure
- [ ] Target ratios: moonlit snow to ambient shadow at about **3:1–4:1**; door pool to surrounding facade at **8:1+** (thriller-level contrast confined to the focal point).
- [ ] **Fixed manual exposure** for this shot (disable auto exposure or clamp min/max tightly), so the camera never "adapts" the night to grey.
- [ ] Tonemap **AgX** (defaults: contrast 1.25, white ~16.3, exposure 1.0). Light it bright enough to read, then lower exposure about 1–2 stops rather than building it dark. Use AgX contrast before adding post contrast.
- [ ] Glow: **Softlight** blend (best on dark scenes, per the Godot docs), with the threshold set so only the flame, lantern, windows and moon bloom.

### Materials
- [ ] Snow albedo ~0.7–0.8, not 1.0, so moonlit snow stays a *mid* value beneath the practicals.
- [ ] **Cobblestones wet:** low roughness (~0.15–0.3) and darker albedo, so they reflect the door flame as a warm streak up the path (the leading line). Check that screen-space or probe reflections actually capture the flame.
- [ ] **Red mailbox:** Purkinje darkens reds at night, so make sure lantern spill or a tiny local fill reaches it. Otherwise it will go brown-black and the accent is lost.

### Atmosphere and sky
- [ ] Sky: deep navy gradient with stars and the Milky Way, *darker* than the snow but lighter than the facade, so the roofline silhouette reads.
- [ ] Volumetric fog: low global density (the Godot docs suggest starting at 0.0001 for light shafts, then raising light fog energy, 200–5000 if needed). Use a slightly blue albedo and a touch of emission so the distant pines recede. Enable temporal reprojection and check for banding.
- [ ] Use a distance fog / aerial-perspective step to lift the far pines one value step. Keep the near pines as dark frames.
- [ ] Embers: emissive particles with `volumetric_fog_energy = 0` on any attached lights (the Godot docs say fast-moving lights ghost). Snowfall particles should be lit by the moon and lantern, not self-lit.
- [ ] Vignette last, subtle, darkening the corners toward the frame pines.

### Final checks
- [ ] Saturation-0 check: three clean value groups, with the door the brightest.
- [ ] Colour check: at least 80% of the frame cool and muted, with warm reserved for practicals and their spill.
- [ ] Display check: a cheap or laptop screen and a lit room. The path, fence and house outline must still read.
- [ ] Remove any light you can't name a source for.

---

## 6. Sources

Fetched and read:
1. Robert Yang, "GDC 2018: How to light a level (slides and notes)" — https://www.blog.radiator.debacle.us/2018/03/gdc-2018-how-to-light-level-slides-and.html
2. Robert Yang, "Lighting theory for 3D games, part 4" — https://www.blog.radiator.debacle.us/2015/07/lighting-theory-for-3d-games-part-4.html
3. Game Developer, "Lighting design fundamentals: using contrast in your game" — https://www.gamedeveloper.com/art/lighting-design-fundamentals-using-contrast-in-your-game
4. 80.lv, Stephen Falk, "Working on Lighting and Composition for a Night Scene" — https://80.lv/articles/working-on-lighting-and-composition-for-a-night-scene
5. 80.lv, "How to Build a Melancholic Environment of a City at Night with Blender" — https://80.lv/articles/how-to-build-a-melancholic-environment-of-a-city-at-night-with-blender
6. 80.lv, "Building Moody Lighting for Environments" — https://80.lv/articles/building-moody-lighting-for-environments
7. 80.lv, "Importance of Lighting and Visual Composition in a Video Game" (Adriano Grasso) — https://80.lv/articles/importance-of-lighting-and-visual-composition-in-a-video-game
8. 80.lv, "Studying Lighting in Games" — https://80.lv/articles/studying-lighting-in-games
9. 80.lv, "See How Level Design Lighting Helped Make The Last of Us More Immersive" — https://80.lv/articles/see-how-level-design-lighting-helped-make-the-last-of-us-more-immersive
10. Game Developer, "Last of Us lighting artist offers devs a tip: set the mood with a single light" — https://www.gamedeveloper.com/art/-i-last-of-us-i-lighting-artist-offers-devs-a-tip-set-the-mood-with-a-single-light
11. Game Developer / GDC, "Find out how Cyberpunk 2077 lit up Night City (GDC 2022)" — https://www.gamedeveloper.com/marketing/find-out-how-cyberpunk-2077-lit-up-night-city-in-this-gdc-2022-session
12. No Film School, "The Thought Process Behind Lighting an Exterior Shot at Night" — https://nofilmschool.com/2018/06/thought-process-behind-lighting-exterior-shot-night
13. No Film School, "5 Tips for Shooting Night Exteriors" — https://nofilmschool.com/tips-shooting-night-exteriors
14. In Depth Cine, "5 Ways to Shoot Night Exteriors" — https://www.indepthcine.com/videos/moonlight-lighting
15. Videomaker, "Light the Night: How to Light a Realistic Night Scene" — https://www.videomaker.com/light-the-night-how-to-light-a-realistic-night-scene/
16. TV Technology, "Lighting Up the Night" — https://tvtechnology.com/opinions/lighting-up-the-night
17. Sony Cinematography, "Night Lighting Part 1: Tackling Large Night Exteriors" — https://sony-cinematography.com/articles/night-lighting---part-1---tackling-large-night-exteriors/
18. American Cinematographer (ASC), "Lives Under Siege: The Goldfinch and 1917" — https://theasc.com/articles/lives-under-siege-the-goldfinch-and-1917
19. StudioBinder, "Low Light Photography Settings" — https://www.studiobinder.com/blog/low-light-photography-settings/
20. Wikipedia, "Day for night" — https://en.wikipedia.org/wiki/Day_for_night
21. Wikipedia, "Purkinje effect" — https://en.wikipedia.org/wiki/Purkinje_effect
22. Wikipedia, "Notan" — https://en.wikipedia.org/wiki/Notan
23. Godot docs, "Volumetric fog and fog volumes" — https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html
24. Godot docs, "Environment and post-processing" — https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html
25. Kotaku, "The Brightness Slider Is the Dimmest Idea in Video Games" — https://kotaku.com/the-brightness-slider-is-the-dimmest-idea-in-video-game-1845785658
26. Roblox DevForum, "Why does my game look good at day, but terrible at night?" — https://devforum.roblox.com/t/why-does-my-game-look-good-at-day-but-terrible-at-night/1493670

Used via search-result summaries only (fetch failed or was not attempted):
27. Ubisoft, "The Challenges of Rendering an Open World in Far Cry 5" (SIGGRAPH 2018 notes) — https://www.advances.realtimerendering.com/s2018/The%20Challenges%20of%20Rendering%20an%20Open%20World%20in%20Far%20Cry%205%20(With%20Notes).pdf
28. Jasmin Patry, Ghost of Tsushima, SIGGRAPH Advances 2021 — https://www.advances.realtimerendering.com/s2021/jpatry_advances2021.pdf
29. GDC 2018 Level Design Workshop slides, "How to Light a Level" (SlideShare) — https://www.slideshare.net/HudsonHawk2/gdc-2018-level-design-workshop-how-to-light-a-level-slidespdf
30. GDC Vault, "Advanced Graphics Summit: Cyberpunk 2077" — https://gdcvault.com/play/1027959/Advanced-Graphics-Summit-Cyberpunk-2077
31. GDC Vault, "In-Game and Cinematic Lighting of The Last of Us" — https://gdcvault.com/play/1020475/contactUs
32. British Cinematographer, "Masterclass: Sir Roger Deakins" — https://britishcinematographer.co.uk/?p=33310
33. B&H Explora, "Lighting Tips: The Basics of Day for Night Cinematography" — https://www.bhphotovideo.com/explora/video/tips-and-solutions/lighting-tips-basics-day-night-cinematography
34. Artlist, "The Connection Between Color Temperature and Video Lighting" — https://artlist.io/blog/color-temperature/
35. Videvo blog, moonlight colour temperature — https://www.videvo.net/blog/?p=43944
36. PremiumBeat, "Lighting Day for Night Interiors" — https://www.premiumbeat.com/blog/lighting-day-for-night-interiors
37. GameDesignerNotes (Patreon), "Left 4 Dead" — https://www.patreon.com/GameDesignerNotes/posts/left-4-dead-161836386
38. PC Gamer, "Why less is more when it comes to Firewatch's beautiful trees" — https://pcgamer.com/why-less-is-more-when-it-comes-to-firewatchs-beautiful-trees
39. Boing Boing, "How a small art team created Firewatch's beautiful environment" — https://boingboing.net/2015/03/27/how-a-small-art-team-created-f.html
40. Polycount, "The Art of Firewatch (GDC 2015)" thread — https://polycount.com/discussion/150447/the-art-of-firewatch-gdc-2015
41. GameRant, "Red Dead Redemption 2 night sky detail" — https://gamerant.com/red-dead-redemption-2-night-sky-detail-realism-rockstar-games/
42. Steam Community, RDR2 "nights too bright" discussion — https://steamcommunity.com/app/1174180/discussions/0/5053621389079096918
43. MasterClass, "Nōtan in Art" — https://www.masterclass.com/articles/notan
44. Blender Studio, "Artist guide: Lighting" — https://studio.blender.org/tools/artist-guide/shot-production/lighting
45. itch.io community post on dark atmosphere vs. physical darkness — https://itch.io/post/3675530
46. EA Forums, Battlefield 6 auto-exposure complaint — https://forums.ea.com/discussions/battlefield-6-general-discussion-en/turn-down-or-remove-the-blinding-auto-exposure/12756445/replies/12802350

Books (summarised from general knowledge, not fetched): Arthur Wesley Dow, *Composition* (1899), the origin of notan teaching. James Gurney, *Color and Light* (2010), on moonlight as a low-saturation, cool-shifted key and the importance of warm/cool pairs. Blain Brown, *Motion Picture and Video Lighting*, on lighting ratios and motivated night lighting.
