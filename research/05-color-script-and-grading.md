# 05: Colour Script, Palettes, Grading and Tonemapping for Mood

*Research topic for Unsent (Godot 4.7, Forward+, AgX, exposure 1.05, glow on). Compiled 2026-11-26.*

---

## 1. Takeaways

1. **Plan the colour of the whole game, not one scene at a time.** A colour script is a strip of small, rough paintings that maps the emotional arc. For Unsent, the arc is literal: the opening is in full colour and the world loses saturation as the story progresses. Draw the strip before tuning any `Environment`.
2. **Value comes first and hue second.** The reference reads as night because about 84% of its pixels sit below 25% luminance. The teal and amber are mood on top of that value structure. If a grayscale screenshot does not read, no grade will fix it.
3. **Keep blacks coloured.** In the reference, even the darkest pixels are blue-teal (`#08141a`), never `#000000`. In Godot, set this through the ambient light, fog colour and the LUT shadows, not through materials.
4. **Warm against cool works when the story motivates it.** The orange/teal look is cheap when it is pasted on. In Unsent it is motivated: warm light means people, home and the letters, while cool light means the cold world outside. Keep the warm accents rare so they stay precious.
5. **Use one accent and keep it alive.** The red mailbox is the only saturated red in the frame, and it is the story object. Because Unsent desaturates the world over time, the accent should be protected per material rather than by the global post-process saturation (see section 5).
6. **AgX is a good base for this scene.** AgX rolls saturated lights such as lanterns and fire smoothly toward white, instead of skewing them the way ACES 1.x and Filmic do. It starts out less saturated, so the "look" has to be added afterwards with AgX contrast and a LUT.
7. **Readable night means dark but not empty.** Use lowered exposure and a cool shadow tint, keep a little lifted fill so silhouettes survive, add a vignette to frame the shot, and place warm practical lights where you want the player's eye to go.

---

## 2. Principles and techniques

### 2.1 Colour scripts and colour keys

- **What it is.** At Pixar, the colour script is a sequence of thumbnails, one or a few per scene, read left to right like music. Each panel sets mood, value and dominant hue rather than staging. Ralph Eggleston made the first one for *Toy Story*. He described it as a map that the lighting department checks its work against. ([MoMA audio guide](https://www.moma.org/audio/playlist/192/2581), [MoMA Eggleston interview](https://www.moma.org/interactives/redstudio/interviews/behind/content/eggleston/assets/transcripts.php))
- **Lou Romano** (*The Incredibles*, *Up*) worked digitally with bold, abstract shapes. His aim was the emotional tone of each sequence, not accurate layout. His *Up* script was used to set the lighting of each scene. ([SlashFilm, Romano Up script](https://www.slashfilm.com/503975/cool-stuff-lou-romanos-color-script-for-pixars-up/), [Gizmodo, Up in 120 frames](https://gizmodo.com/pixars-up-in-120-frames-5274639))
- **Dice Tsutsumi** (often misspelled "Tsutsumida") was the colour and lighting art director on *Toy Story 3* and *Monsters University*. For *TS3* he painted two or three colour keys per sequence that fixed colour, value and mood. He later co-founded Tonko House. ([Computer Graphics World](https://digital.copcomm.com/i/14320/19), [Cartoon Brew](https://www.cartoonbrew.com/shorts/sketchtravel-film-by-dice-tsutsumi-51172.html))
- **Colour script vs colour key.** A *script* covers the whole arc in small, rough panels. A *key* is one larger, more finished painting that lighting matches exactly. Games use both: a script for the campaign and keys for hero moments. Naughty Dog has refined colour-scripting since the first *Uncharted*. Game Informer published a *Last of Us* script that reduces each location to its basic colours and shapes. ([Game Informer, Uncharted 4 art](https://gameinformer.com/b/features/archive/2015/01/21/the-secret-depth-of-uncharted-4-s-art-design), [Game Informer, TLOU environments](https://gameinformer.com/b/features/archive/2012/02/17/nature-s-ruinous-revenge-the-environments-of-the-last-of-us))
- **Lighting leads in games.** *The Last of Us Part II*'s art director said colour and lighting were what he spent the most time on ([Cook & Becker](https://cookandbecker.com/en/article/250/art-directing-the-last-of-us-part-ii.html)). Naughty Dog's SIGGRAPH notes say most of that world is overcast, so ambient light carries the mood ([Naughty Dog SIGGRAPH 2020](https://www.naughtydog.com/blog/naughty_dog_at_siggraph_2020)). A TLOU lighting artist argues for setting the mood "with a single light" ([Game Developer](https://gamedeveloper.com/art/-i-last-of-us-i-lighting-artist-offers-devs-a-tip-set-the-mood-with-a-single-light)).
- **Studies of the practice.** A SCAD thesis and animation-school writing make the same point: the script exists to tie the look to the *emotional arc*, and you can start one at any stage of pre-production ([BINUS Animation](https://animation.binus.ac.id/2025/12/09/lighting-keys-and-the-power-of-color-scripting/), [SCAD thesis](https://scad.lunaimaging.com/luna/servlet/detail/SCAD~3~3~1788~14765)).

### 2.2 Warm/cool complementary schemes (the orange/teal debate)

- **Why it works.** Skin, fire and tungsten light sit in the orange range, and teal is roughly their complement. Pushing shadows toward teal therefore separates the warm subject from its surroundings ([PetaPixel](https://petapixel.com/2017/02/23/orange-teal-look-popular-hollywood/), [DIYPhotography](https://www.diyphotography.net/reasons-orange-teal-look-popular-movies/)).
- **Why it gets mocked.** In the 2000s it became a blanket Hollywood default applied regardless of story. It also flattens hues: everything warm drifts to the same orange and everything cool to the same teal.
- **When it's earned.** It is earned when the light sources really are warm and cool: fire or tungsten against moonlight or skylight. It is also earned when the split *means* something, such as inside against outside, safety against exposure, or memory against the present. Unsent's reference meets both conditions. Lanterns and windows are physically 1900–2700 K and moon/sky fill is perceived as cool. Warm also stands for the people the letters are written to.
- **How to keep it subtle.** Split-tone the lift (shadows) toward teal and leave the gain (highlights) nearly neutral or slightly warm. Let the *lights themselves* supply the orange. Lift, gamma and gain each control a broad tonal range, so make small moves ([Kdenlive LGG docs](https://docs.kdenlive.org/en/tips_and_tricks/how-tos/lift_gamma_gain.html), [PetaPixel on split toning](https://petapixel.com/2018/12/13/find-your-creative-style-with-split-toning/)).

### 2.3 Limited palettes and gamut masking

- James Gurney's *Color and Light* popularised **gamut masking**: draw a shape over a colour wheel and paint only with the hues inside it. The result feels complete but stays harmonious ([Gurney Journey: colour wheel masking](https://gurneyjourney.blogspot.com/2022/05/color-wheel-masking-basics.html), [Lines and Colors](https://linesandcolors.com/2011/09/19/james-gurney-on-gamut-masking/)).
- The reference fits a **narrow triangular mask**: a large, low-chroma blue-teal region, a small high-chroma amber region and one red-orange point (the mailbox). There is no green, no purple and no saturated blue except a hint in the Milky Way.
- Games use the same idea. Analyses of *Ori and the Blind Forest* describe an analogous blue-green palette with pink placed *outside* it to signal danger ([Game Developer, colour palettes and game design](https://www.gamedeveloper.com/design/where-colour-meets-design-colour-palettes-and-game-design)). *Ghost of Tsushima* limited foliage variety and pushed colour values so that each area has a clear palette and mood ([PlayStation Blog, Crafting Tsushima](https://blog.playstation.com/?p=333111), [ArtStation Art Blast](https://magazine.artstation.com/2020/08/sucker-punch-productions-ghost-of-tsushima-art-blast/)). Olly Moss's *Firewatch* palette came from WPA-era national park posters. Campo Santo wrote a custom fog shader to control colour over distance, and the palette shifts with each scene's emotion ([Thumbsticks, GDC 2015 Art of Firewatch](https://www.thumbsticks.com/gdc-2015-the-art-of-firewatch), [PC Gamer](https://www.pcgamer.com/uk/why-less-is-more-when-it-comes-to-firewatchs-beautiful-trees/)).

### 2.4 Saturation control and coloured blacks

- Real "black" objects read as very dark, coloured greys. Pure `#000` placed next to colour looks dead and overpowers the image ([Ian Storm Taylor, "Never use black"](https://ianstormtaylor.com/design-tip-never-use-black/)). A common painting mistake is shading with dull black instead of a darker, cooler hue ([ImagineFX, Colour your shadows](https://pocketmags.com/imaginefx/july-2024/articles/part-6-colour-your-shadows)).
- **Saturation rises as light falls, up to a point, then collapses.** In the reference, the shadows are dark but still clearly hued (navy/teal, about 35–50% HSV saturation). Mid-greys like the snow and walls are almost neutral. Lit areas are strongly warm.
- **Use a saturation budget.** Spend chroma on lights and the accent. Keep large surfaces (walls, snow, ground) at low chroma so the accents carry weight.

### 2.5 Value vs hue

- Most painters agree that value does the structural work and hue sets the theme and mood. Check by reducing to grayscale or to a two- or three-value notan ([Oil Painters of America, "Value does the work"](https://www.oilpaintersofamerica.com/2024/12/value-does-the-work-color-gets-the-credit-by-william-schneider-opam/), [Sandy Allnock, hue vs value](https://sandyallnock.substack.com/p/hue-vs-value-which-is-most-important)).
- Pixar's lighting staff likewise describe varying *luminance* as their main emotional lever ([Business Insider on Pixar lighting](https://www.businessinsider.in/4-genius-ways-pixar-uses-lighting-to-tell-breathtaking-stories/articleshow/50114232.cms)). Sharon Calahan's view is that lighting sets the mood without breaking believability ([AWN, Calahan on The Good Dinosaur](https://www.awn.com/print/animationworld/sharon-calahan-talks-lighting-and-visual-development-good-dinosaur), [ASC podcast](https://theasc.com/podcasts/disney-pixar-features-sharon-calahan-asc)).
- **Practical rule for Unsent:** keep a grayscale toggle in a debug menu (set `adjustment_saturation = 0`). This matters doubly here, because the late game *is* grayscale. If the composition only works in colour, it will fall apart as the story desaturates.

### 2.6 Grading pipeline: LUTs, lift/gamma/gain, split-toning

- **Order in Godot:** DOF → auto-exposure → glow → **tonemap** → adjustments (brightness, contrast, saturation, colour-correction LUT). The LUT runs *after* tonemapping, in SDR 0–1 ([Godot Environment docs](https://docs.godotengine.org/en/latest/classes/class_environment.html), [Godot environment & post-processing](https://docs.godotengine.org/en/4.5/tutorials/3d/environment_and_post_processing.html)). Big studios grade in the same order: a small 3D LUT indexed by the tonemapped colour. Frostbite later moved grading into HDR for HDR displays ([Frostbite HDR grading, GDC 2017](https://www.ea.com/frostbite/news/high-dynamic-range-color-grading-and-display-in-frostbite), [NVIDIA, Rise of the Tomb Raider HDR](https://developer.nvidia.com/implementing-hdr-rise-tomb-raider)).
- **LUT workflow:** take a screenshot with a neutral identity LUT strip embedded. Grade the screenshot in Krita, GIMP or DaVinci Resolve. Crop the graded strip back out and import it as a `Texture3D` (or as `GradientTexture1D` for a simple luminance-to-colour ramp). Grade *on top of the tonemapped image*, so the tonemapper and its settings must be locked first.
- **Lift/gamma/gain:** lift sets shadows and black level, gamma sets midtones and gain sets highlights. Split-toning tints shadows and highlights separately. Shifting the balance point decides where "shadow" ends.

### 2.7 Tonemapping: Filmic, ACES, AgX

- **ACES 1.x** gives punchy contrast, but bright saturated colours skew in hue: blue goes to purple, and red/orange go to yellow. Its own successor proposal admits unacceptable hue and saturation distortions ([ACES 2.0 proposal, Display Daily](https://displaydaily.com/a-proposal-for-aces-2-0/), [Unity forum, ACES outdated](https://discussions.unity.com/t/unitys-aces-implementation-is-outdated/1567683), [Godot PR #52476 discussion](https://github.com/godotengine/godot/pull/52476)).
- **Filmic (Blender v1)** handles dynamic range well but has the "notorious six" hue skews on bright saturated colours ([Blender devtalk](https://devtalk.blender.org/t/blender-support-for-aces-academy-color-encoding-system/13972/209)).
- **AgX** (Troy Sobotka's design, now Blender's default) compresses toward white more evenly across hues. Users still report some hue shift and lower default saturation and contrast, so it is a *neutral base*, not a look ([Blender PR #106355](https://projects.blender.org/blender/blender/pulls/106355), [BlenderArtists "AgX changes hue"](https://blenderartists.org/t/agx-changes-hue/1527123), [three.js discourse](https://discourse.threejs.org/t/is-agx-tonemapping-implemented-correctly/60609), [AgX reverse-engineered](https://thecodecofficial.github.io/Blog/AgES)). Game developers swapping ACES for AgX report better results under moody, low-key lighting. A scene lit for ACES needs relighting, though, because AgX is flatter at first ([Who needs a tonemapper?](https://cgmeerkat.github.io/blog/who-needs-a-tonemapper)).
- **Godot's AgX controls:** `tonemap_agx_white` (default 16.29; lower values make highlights blow out sooner and raise contrast) and `tonemap_agx_contrast` (default 1.25). The docs say the latter gives better quality than `adjustment_contrast` at no extra cost. Both came in PR #106940 ([GitHub PR #106940](https://github.com/godotengine/godot/pull/106940), [Godot AgX proposal #7545](https://github.com/godotengine/godot-proposals/discussions/7545)).
- **Why AgX suits the reference:** the lantern and windows are bright saturated orange. Under ACES they would shift to yellow and look sickly. Under AgX they roll off to a creamy white-yellow core with an orange falloff, which matches the reference's lantern (`#f5c172` core).

### 2.8 Exposure and white balance

- Change scene brightness with `tonemap_exposure` (applied before tonemapping), not with `adjustment_brightness` ([Godot docs](https://docs.godotengine.org/en/latest/classes/class_environment.html)).
- **White balance is a story decision.** If the camera is balanced for tungsten, the moonlight reads blue. If it is balanced for daylight, tungsten reads orange. The reference sits in between: warm lights clearly orange, moon fill clearly blue, the moon disc itself cream. That suggests a neutral balance of about 4500–5000 K, with the cool cast added deliberately in the shadows.

### 2.9 Grading night so it reads as night but stays readable

- **Perception.** In low light the eye shifts toward blue sensitivity (the Purkinje effect): reds darken, blues seem relatively brighter, colours desaturate and fine detail is lost ([Purkinje effect, Wikipedia](https://en.wikipedia.com/wiki/Purkinje_shift), [Thompson et al., "A spatial post-processing algorithm for images of night scenes", Utah](https://collections.lib.utah.edu/dl_files/57/7c/577ca88e4f76a8606acad05a07842f5a6b43460d.pdf)). Cameras and displays do not reproduce this, so we fake it with a grade ([Unreal forum, Purkinje night filter](https://forums.unrealengine.com/t/unlocking-the-night-crafting-an-blue-night-filter-with-the-purkinje-effect/1750941)).
- **Day-for-night practice from film:** lower exposure, cool the shadows, reduce saturation, darken the sky with a gradient and lift the shadows slightly at the end to keep detail. Avoid a flat blue wash, because night still contains many colours ([Mixing Light, day-for-night](https://mixinglight.com/color-tutorial/day-for-night/), [CineD](https://www.cined.com/sunlight-in-disguise-ways-to-approach-day-for-night-scenes/), [B&H Explora](https://www.bhphotovideo.com/explora/video/tips-and-solutions/lighting-tips-basics-day-night-cinematography)).
- **Game-specific rules:**
  1. Keep **silhouettes**: the sky must be slightly *lighter* than the trees and roof. In the reference the sky is about 7–10% luminance and the tree masses about 5–7%.
  2. Use **rim and top light from the moon** so snow on roofs and branches traces the shapes.
  3. Add **practicals as wayfinding**: warm pools of light where the player should walk (path, door, mailbox).
  4. **Do not crush to zero.** The ambient floor should be blue-teal at about 3–6% luminance.
  5. A **vignette** keeps the eye in the centre and makes the corners feel colder and darker.

### 2.10 Colour as emotion and accent

- **Melancholy:** low key, cool and desaturated, with high contrast between small warm pockets and a large cool field. Feeling outside the warmth is the emotion.
- **Warmth and home:** amber 1900–2700 K light, soft glow, bloom on practicals.
- **Nostalgia:** warm, lifted blacks (faded film), slightly lower contrast, gentle highlight bloom. Use it for flashback or letter-reading moments rather than the exterior.
- **The single accent.** *Schindler's List*'s red coat shows that one saturated colour in a muted field directs the eye and gives an individual moral weight. Spielberg later greyed it to mark loss ([No Film School](https://nofilmschool.com/girl-in-the-red-coat-in-schindlers-list), [SlashFilm on Spielberg's intent](https://www.slashfilm.com/1914463/steven-spielberg-schindlers-list-red-coat-girl-meaning)). That is almost exactly Unsent's mechanic. The red mailbox can be the last thing to lose its colour, or the first to regain it.

---

## 3. Examples

| Work | What to steal |
|---|---|
| Pixar *Toy Story 3* (Tsutsumi keys) | Two or three keys per sequence for colour, value and mood. Lighting matches the keys, not the other way round. |
| Pixar *Up* (Romano script) | Abstract shape-and-colour panels for the emotional tone, including Carl's grey, desaturated world that regains colour. A direct parallel to Unsent in reverse. |
| *The Last of Us* (Naughty Dog) | Locations reduced to basic colours and shapes in the script. Mood carried by ambient light under overcast skies. |
| *Firewatch* (Moss / Ng) | A poster-derived limited palette. Colour fog does the depth layering. The palette shifts with emotion and time of day. |
| *Ghost of Tsushima* (Sucker Punch) | Bold, limited per-area palettes with reduced texture noise, so colour can organise the world. |
| *Ori and the Blind Forest* (Moon Studios) | An analogous blue-green base. An out-of-palette accent colour as a gameplay signal. |
| *Schindler's List* | A single red accent in monochrome. Desaturating the accent becomes a story beat. |

---

## 4. Reference palette analysis (`reference_target.webp`)

Image size 2000×1083. Values come from sampling 12×12-pixel patches and from 10-colour quantisation of a downscaled copy. Luminance uses Rec.709 weights on 8-bit sRGB.

### 4.1 Estimated palette

| Role | Hex | Notes |
|---|---|---|
| Deepest shadow / sky top | `#08141a`, `#0a1922` | Near-black but clearly teal-navy. Hue about 200°, saturation about 65% HSV, value 8–13%. |
| Sky mid / night air | `#0c1c26`, `#0d1b23` | The main background field. |
| Milky Way band | `#182e43` | Lifted, more saturated blue, about 210°. |
| Moonlit roof snow | `#2e475d` | Steel blue. The brightest *cool* surface. |
| House wall (shadow) | `#171f24` | Almost neutral charcoal, slightly cool. |
| Fence / foreground cool | `#2b313a`, `#1d2831` | Blue-grey. |
| Ground (neutral dark) | `#282627`, `#3f3a3b` | Slightly warm grey where lantern spill mixes in. |
| Moon disc | `#eddabf` | Cream, warm white (about 4500 K look), not blue. |
| Moonlit cloud edge | `#ccac8a` | Warm bounce on the cloud rims, tying the moon to the warm family. |
| Window glow (with frame) | `#7f533b`, cores about `#e0a060` | Amber. Frames and curtains reduce the average. |
| Door / hearth glow | `#d89656` | Orange-amber. |
| Lantern core | `#f5c172` | The brightest warm value, close to clipping. |
| Warm path / ground spill | `#5b402f`, `#766153` | Desaturated brown where the warm light hits snow and stone. |
| **Mailbox accent** | `#6f3123` (lit edge about `#a84a35`) | A dark, earthy red. It stands out through **hue**, not value. |
| Firefly accents | about `#ffb060` | Tiny high-chroma points. |

### 4.2 Value distribution (rough histogram)

Mean luminance is **17%** (44/255) and the median is **13.5%** (34/255).

```
0-12%   ######################  43.4%   sky, tree masses, wall, shadowed ground
12-25%  ####################    40.5%   fence, roof snow, mid ground, clouds
25-37%  #####                   10.4%   lit snow, path, warm spill
37-50%  ##                       3.1%   window panes, moonlit cloud
50-62%  #                        1.3%
62-75%  .                        0.8%   lantern/door halos
75-87%  .                        0.3%
87-100% .                        0.1%   moon disc, lantern core, fireflies
```

**Reading:** this is a strongly **low-key** image with a long, thin highlight tail. About 84% of pixels fall in the bottom quarter. Fewer than 1% exceed 75%, and those are *only* the light sources: moon, lantern, door and windows. The eye therefore jumps straight to them. There is almost no mid-grey plateau, so the image feels deep without being murky. Pure black (0) and pure white (255) barely appear. The darks are tinted and the highlights are cream rather than paper white.

### 4.3 Hue structure

- **Two families plus one accent.** The cool field (190–215°) covers roughly 80% of the frame area at low chroma. The warm family (25–40°) covers about 8–10%, with high chroma concentrated in the lights. The red mailbox (about 10°) is under 0.5% of the frame.
- **Temperature follows light, not surface.** The same snow is blue under moonlight (`#2e475d`) and brown-gold under lantern light (`#5b402f`). This is a lighting-driven palette, so it can be rebuilt in-engine with lights instead of painted textures.
- **Vignette:** the corners fall to about 6–9% luminance and shift cooler. The centre around the door is the warmest and brightest area.
- **Depth:** the background trees fade into a slightly lighter, bluer haze (atmospheric perspective). The foreground fence is darker and higher in contrast.

---

## 5. Apply to Unsent's opening

### 5.1 Colour script first

Paint 8–12 thumbnails (each about 320×180) for the full game before tuning. Suggested arc:

1. Opening exterior: the reference look, full colour.
2. Interior: warm, about 2400 K, intimate.
3. First letter: nostalgia key with lifted warm blacks.
4. Middle chapters: saturation falls step by step. The cool field stays and the warm family loses chroma first.
5. Late game: near-grayscale, with only the mailbox red remaining.
6. Ending: colour returns, or doesn't.

Check every thumbnail in grayscale.

### 5.2 Environment: tonemap and exposure

Values below are starting points to tune by eye against the reference. They are not measured outputs.

| Property | Value | Why |
|---|---|---|
| `tonemap_mode` | `TONE_MAPPER_AGX` (4) | Clean roll-off on the orange practicals. |
| `tonemap_exposure` | **0.9–1.05**. Start at 1.05 and reduce if the mean luminance of a screenshot exceeds about 20%. | Low-key target: mean about 17%. |
| `tonemap_agx_white` | **6.0–8.0** (default 16.29) | A lower white lets the lantern, moon and door cores reach cream-white at practical HDR intensities (about 4–8). The default 16.29 would keep them dull orange. |
| `tonemap_agx_contrast` | **1.35–1.5** | Deepens the shadow mass and gives AgX's flat base the punch of the reference. Use this instead of `adjustment_contrast`. |
| Auto-exposure (`CameraAttributesPractical`) | **Off** for the opening, or a narrow range | Auto-exposure would brighten the night and defeat the low key. |

### 5.3 Adjustments and the story saturation global

| Property | Value |
|---|---|
| `adjustment_enabled` | `true` |
| `adjustment_brightness` | 1.0 (leave it alone) |
| `adjustment_contrast` | 1.0 (contrast comes from AgX) |
| `adjustment_saturation` | Opening **1.10–1.15** (AgX desaturates slightly), then driven by the story global down to about 0.05 |
| `adjustment_color_correction` | The 3D LUT described below |

**Important design note.** `adjustment_saturation` is global and runs after tonemapping, so it will grey out the mailbox and the lanterns too. To keep the red accent alive late in the game, choose one of these:

- (a) Drive saturation **per material**, using a shared global shader uniform `story_saturation` in a material include and an exempt flag on accent materials.
- (b) Use a custom `CompositorEffect` that desaturates everything except pixels flagged by a stencil or mask.

Option (a) is simplest in Godot 4.x.

### 5.4 Colour-correction LUT idea ("Unsent_Night_Open")

Build the LUT in Resolve, Krita or GIMP from a screenshot taken with the AgX settings above. Import it as `Texture3D` at 32³.

- **Lift (shadows):** push toward teal-navy, R −0.010, G +0.005, B +0.020. Target the darkest pixel at about `#08141a`, never `#000`. Raise the black floor about 2–3%.
- **Gamma (mids):** slightly cool, hue about 205° at low strength (around 5%). This keeps walls and snow in the blue-grey `#171f24`–`#2e475d` range.
- **Gain (highlights):** slightly warm toward cream (hue about 40°, around 4%). The moon then reads as `#eddabf` rather than pure white.
- **Saturation by luminance:** reduce saturation about 15% in the darkest 10% (Purkinje-style desaturation) and keep full saturation in highlights, so the practicals stay rich.
- **Hue protection:** leave the 0–20° red band untouched, so the mailbox survives the teal push.
- **Make two more LUTs** for the colour script: `Nostalgia_Interior` (warm, lifted blacks around `#1e1812`, lower contrast) and `Grey_Late` (neutral, with cool lift only). Godot has no built-in LUT cross-fade, so blend with a small custom post shader, or swap LUTs at chapter cuts.

### 5.5 Glow

| Property | Value |
|---|---|
| `glow_enabled` | `true` |
| `glow_intensity` | 0.6–0.8 |
| `glow_strength` | 1.0–1.2 |
| `glow_bloom` | 0.0–0.03. Keep it very low, or the dark sky turns milky. |
| `glow_hdr_threshold` | 0.9–1.0. Only practicals and the moon should bloom. |
| `glow_hdr_scale` | 2.0 |
| `glow_blend_mode` | `SOFTLIGHT` for subtle results, or `SCREEN` for stronger halos like the reference lantern |
| `glow_levels` | 1: 0.0, 2: 0.6, 3: 0.8, 4: 0.6, 5: 0.3, 6–7: 0.0. Wide, soft halos around the lantern and windows. |

### 5.6 Fog, god rays, sky and vignette

- **Volumetric fog:** density about 0.01–0.02, albedo `#1d2a36`, low emission. The moon `DirectionalLight3D` gets a `light_volumetric_fog_energy` of about 1.5–3 to cut visible shafts through gaps in the trees. Lantern omni lights get about 0.5–1 for a warm halo in the air.
- **Depth fog colour:** `#0f1e2a`, so distant trees fade lighter and bluer (atmospheric perspective).
- **Ambient light:** source *Color*, `#1a2a3a`, energy 0.3–0.5, or sky at about 0.3. This is the coloured black floor.
- **Sky:** a panorama or shader sky with a top colour of `#08141a` and a horizon of `#132535`. Use a stars and Milky Way texture at about `#182e43`, and a moon disc at `#eddabf` with HDR energy around 6, so it reaches cream-white under `agx_white` 6–8 and blooms.
- **Vignette:** Godot has none built in. Add a full-screen `ColorRect` shader on a `CanvasLayer`, or a `CompositorEffect`. Use smoothstep from radius 0.45 to 1.0, a strength of about 0.45 in the corners, multiplied toward `#0a1620` (cool), not black.

### 5.7 Lights: temperature, colour and intensity

The RGB values come from Tanner Helland's Kelvin approximation ([Helland](https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html)). Godot 4 lights also offer `light_temperature` when physical light units are enabled. Without physical units, set `light_color` directly.

| Light | Kelvin | RGB (0–1) | Hex | Energy (non-physical) | Notes |
|---|---|---|---|---|---|
| Hearth / door fire | 1900 K | 1.00, 0.52, 0.00 | `#ff8400` | 3–5, range 6 m | Flicker ±10%. The deepest orange. |
| Lantern on post | 2200 K | 1.00, 0.57, 0.15 | `#ff9227` | 4–6, range 8 m, shadows on | Its fence shadows on the snow are a key composition element. |
| Windows (interior spill) | 2400 K | 1.00, 0.61, 0.24 | `#ff9b3d` | 1.5–2.5, plus emissive panes at about 3 | Use emissive curtain or glass material for the glow. |
| Porch wall lamp | 2700 K | 1.00, 0.66, 0.34 | `#ffa757` | 2–3 | Slightly cooler, to vary the warm family. |
| Fireflies / letter particles | 2000 K (emissive) | 1.00, 0.69, 0.38 | `#ffb060` | Emission 4–8 | Tiny points above the glow threshold. |
| Moon key (directional) | Artistic 7500 K, physically about 4100 K | 0.90, 0.92, 1.00 | `#e6ebff` | 0.15–0.3, shadows on, low angle | Physically moonlight is warmer than daylight. Perceptually (Purkinje) it reads blue, so tint it cool. |
| Sky fill / ambient | 12000 K | 0.75, 0.83, 1.00 | `#bfd3ff`, applied to a dark ambient (`#1a2a3a`) | See ambient | This produces the teal shadow floor. |
| Moon disc / god-ray source | about 4500 K look | 0.93, 0.85, 0.75 | `#eddabf` | Sky emission about 6 | Warm-cream, to link moon and lanterns. |

### 5.8 Accent: the red mailbox

- Albedo about `#8a2a1c`, with roughness 0.6 and a slight clearcoat for snow wetness. Do not use pure `#ff0000`, because AgX and the night grade would make it neon. The reference's red is earthy (`#6f3123` in shadow).
- Give it **its own subtle light**: a small 2200 K omni from the lantern side, so its lit edge reaches about `#a84a35`. Alternatively use a faint rim light.
- Exempt it from the story desaturation (section 5.3). It is the one colour the player should never lose until the story chooses to take it.

### 5.9 Validation checklist

1. Screenshot, convert to grayscale and compare with the reference. The silhouettes of the house, trees and fence must read.
2. Histogram: mean luminance about 15–20%, more than 80% of pixels below 25%, and only the lights above 75%.
3. Sample the darkest pixel. It must be tinted blue-teal (B > R) and above 3%.
4. Lantern core: cream-white with an orange falloff, with no yellow-green or pink skew.
5. With story saturation set to 0, the scene must still be beautiful, and only the mailbox should remain red.

---

## 6. Sources

1. https://www.moma.org/audio/playlist/192/2581
2. https://www.moma.org/interactives/redstudio/interviews/behind/content/eggleston/assets/transcripts.php
3. https://www.animationartconservation.com/design-with-a-purpose,-an-interview-with-ralph-eggleston.html
4. https://www.slashfilm.com/503975/cool-stuff-lou-romanos-color-script-for-pixars-up/
5. https://gizmodo.com/pixars-up-in-120-frames-5274639
6. https://digital.copcomm.com/i/14320/19
7. https://www.cartoonbrew.com/shorts/sketchtravel-film-by-dice-tsutsumi-51172.html
8. https://comicfrenzy.github.io/post/artbook/art-of-pixar-25th-anniversary-complete-color-scripts-select-art-from-25-years-of-animation
9. https://animation.binus.ac.id/2025/12/09/lighting-keys-and-the-power-of-color-scripting/
10. https://scad.lunaimaging.com/luna/servlet/detail/SCAD~3~3~1788~14765
11. https://www.awn.com/print/animationworld/sharon-calahan-talks-lighting-and-visual-development-good-dinosaur
12. https://theasc.com/podcasts/disney-pixar-features-sharon-calahan-asc
13. https://www.businessinsider.in/4-genius-ways-pixar-uses-lighting-to-tell-breathtaking-stories/articleshow/50114232.cms
14. https://gameinformer.com/b/features/archive/2015/01/21/the-secret-depth-of-uncharted-4-s-art-design
15. https://gameinformer.com/b/features/archive/2012/02/17/nature-s-ruinous-revenge-the-environments-of-the-last-of-us
16. https://cookandbecker.com/en/article/250/art-directing-the-last-of-us-part-ii.html
17. https://www.naughtydog.com/blog/naughty_dog_at_siggraph_2020
18. https://gamedeveloper.com/art/-i-last-of-us-i-lighting-artist-offers-devs-a-tip-set-the-mood-with-a-single-light
19. https://www.thumbsticks.com/gdc-2015-the-art-of-firewatch
20. https://www.pcgamer.com/uk/why-less-is-more-when-it-comes-to-firewatchs-beautiful-trees/
21. https://blog.playstation.com/?p=333111
22. https://magazine.artstation.com/2020/08/sucker-punch-productions-ghost-of-tsushima-art-blast/
23. https://www.gamedeveloper.com/design/where-colour-meets-design-colour-palettes-and-game-design
24. https://petapixel.com/2017/02/23/orange-teal-look-popular-hollywood/
25. https://www.diyphotography.net/reasons-orange-teal-look-popular-movies/
26. https://petapixel.com/2018/12/13/find-your-creative-style-with-split-toning/
27. https://docs.kdenlive.org/en/tips_and_tricks/how-tos/lift_gamma_gain.html
28. https://gurneyjourney.blogspot.com/2022/05/color-wheel-masking-basics.html
29. https://linesandcolors.com/2011/09/19/james-gurney-on-gamut-masking/
30. https://ianstormtaylor.com/design-tip-never-use-black/
31. https://pocketmags.com/imaginefx/july-2024/articles/part-6-colour-your-shadows
32. https://www.oilpaintersofamerica.com/2024/12/value-does-the-work-color-gets-the-credit-by-william-schneider-opam/
33. https://sandyallnock.substack.com/p/hue-vs-value-which-is-most-important
34. https://docs.godotengine.org/en/latest/classes/class_environment.html
35. https://docs.godotengine.org/en/4.5/tutorials/3d/environment_and_post_processing.html
36. https://github.com/godotengine/godot/pull/106940
37. https://github.com/godotengine/godot-proposals/discussions/7545
38. https://github.com/godotengine/godot/pull/52476
39. https://projects.blender.org/blender/blender/pulls/106355
40. https://devtalk.blender.org/t/blender-support-for-aces-academy-color-encoding-system/13972/209
41. https://blenderartists.org/t/agx-changes-hue/1527123
42. https://discourse.threejs.org/t/is-agx-tonemapping-implemented-correctly/60609
43. https://thecodecofficial.github.io/Blog/AgES
44. https://cgmeerkat.github.io/blog/who-needs-a-tonemapper
45. https://displaydaily.com/a-proposal-for-aces-2-0/
46. https://discussions.unity.com/t/unitys-aces-implementation-is-outdated/1567683
47. https://www.ea.com/frostbite/news/high-dynamic-range-color-grading-and-display-in-frostbite
48. https://developer.nvidia.com/implementing-hdr-rise-tomb-raider
49. https://en.wikipedia.com/wiki/Purkinje_shift
50. https://collections.lib.utah.edu/dl_files/57/7c/577ca88e4f76a8606acad05a07842f5a6b43460d.pdf
51. https://forums.unrealengine.com/t/unlocking-the-night-crafting-an-blue-night-filter-with-the-purkinje-effect/1750941
52. https://mixinglight.com/color-tutorial/day-for-night/
53. https://www.cined.com/sunlight-in-disguise-ways-to-approach-day-for-night-scenes/
54. https://www.bhphotovideo.com/explora/video/tips-and-solutions/lighting-tips-basics-day-night-cinematography
55. https://nofilmschool.com/girl-in-the-red-coat-in-schindlers-list
56. https://www.slashfilm.com/1914463/steven-spielberg-schindlers-list-red-coat-girl-meaning
57. https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html

*Coverage gaps:* searches returned no usable Reddit (r/colorists, r/gamedev, r/vfx) threads, X threads or Digital Foundry articles on this topic. Practitioner-forum views come from BlenderArtists, the Blender devtalk, Unity, Unreal and three.js forums, and ACES Central instead. Blender Studio's colour-scripting blog returned HTTP 403 and was not used. Hex values in section 4 are measured from the reference file. All Godot values in section 5 are untested starting points.
