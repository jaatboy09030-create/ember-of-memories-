# 04 — Composition and Focal Points for Establishing Shots and Title Screens

Research topic: composition and level art direction for *Unsent*'s opening shot and title screen (Godot 4.7, first-person, melancholy, snowy house at night).

Research note: the web-search budget ran out partway through, so some film and game examples (the Spielberg oner, Ori, Hollow Knight, Bloodborne, Death Stranding, Ghibli backgrounds) come from general craft knowledge rather than a fetched source. They are marked *(general knowledge)*. Every other claim summarises a source in the Sources list.

---

## 1. Takeaways

1. **One shot needs one boss.** Every frame needs a single dominant: the brightest, highest-contrast, most detailed spot. Every other element (counterpoints, framing, lines) should serve it. In the reference, that dominant is the flame in the doorway.
2. **Light is the strongest leading line.** Players and viewers go to the brightest warm spot in a dark frame. Level artists use value and colour temperature more than geometry to steer the eye. Naughty Dog's artists call colour and lighting the most powerful guidance tools.
3. **A weenie is a promise.** Disney's "wienie" is a distant landmark that pulls people toward it and pays off when they arrive. The open door with a flame is the weenie of *Unsent*'s opening. It promises that someone is home, or was.
4. **Symmetry reads as "made, calm, home."** Asymmetry reads as "organic, tense, travelling." A frontal, centred house suits a nostalgic, memory-like opening. Small asymmetric accents (moon left, mailbox right, embers right) stop the image from feeling dead.
5. **Frame with dark foreground, then fade back.** Use a dark, cool, silhouetted foreground (pines, branches, fence), a lit midground (the house), and a lighter, low-contrast background (sky and fog). That gives three readable depth planes, as in Firewatch's layered palette.
6. **Camera height is emotional.** Eye level or slightly below it, with a level horizon and a mid-length lens, reads as "home." A low camera, wide lens close up, a tilted horizon or telephoto voyeurism reads as "menace."
7. **The rule of thirds is a fallback, not a law.** Research suggests it plays a minor role in highly rated images. A centred subject on a strong symmetry axis is a valid choice, especially for a title card.
8. **The title belongs in quiet space.** Put the wordmark in a low-detail, low-contrast region on the composition's axis, below the focal point and never on top of it. The prompt should be smaller still and should never be brighter than the flame.

---

## 2. Principles and techniques

### 2.1 Focal points and the "weenie"
- **Origin.** Walt Disney called his beckoning landmarks "wienies," after the sausage a trainer uses to lure a dog. The castle at the end of Main Street is the classic case. The Rocket to the Moon and the Mark Twain steamboat pulled guests left and right from the central hub. (above-the-garage.com; Scott Rogers' GDC talk via Boing Boing; Tim Cain's "Everything I learned from Disneyland")
- **Techniques from the wienie literature:**
  - Make the landmark tall, distinctive and unobstructed.
  - Use forced perspective, such as Main Street's buildings shrinking toward the castle.
  - Use sound to pull people before the landmark is visible.
  - Use "anti-wienies," such as dull doors, to discourage dead ends.
  - Note that overgrown trees ruined some of Disneyland's own sightlines.
- **Chains of weenies.** A Game Developer analysis of *Super Mario Odyssey* shows each landmark visible from the previous one. Each pays off on arrival, and secondary landmarks hint at content without fully revealing it. The cues it names are scale, shape, colour, motion and staged visibility.
- **Dominants and counterpoints.** Mateusz Piaskiewicz's level-design.org article (republished on Game Developer) calls the main focal object the *dominant*. It should be the best lit and most detailed. Smaller *counterpoints* support it without competing.
- **Emphasis gives players a reason to stop.** Direction moves the player through a space; an emphasis point, the "hero object", is what makes them pause and look. (Game Developer, "Elements and principles of design in level art")

### 2.2 Leading lines
- **Practical and virtual lines.** Practical lines are real edges: paths, fences, rails and rooflines. Virtual lines are implied, such as a character's gaze or a row of lights. Each kind of line carries a mood:
  - Horizontal lines feel calm (the *Dear Esther* sea).
  - Vertical lines feel monumental (the chimneys in *Half-Life 2*).
  - Curved lines feel soft.
  - Diagonal lines feel dynamic. (Piaskiewicz)
- **Lines need a choice to matter.** Unity's level-design primer notes that pipes, hedges and texture changes guide the eye. They only help when the player actually has a choice to make.
- **Directional patterns work.** GameAnalytics summarises player research that found directional line patterns among the most effective cues, such as evenly spaced ledges with a shared orientation. Scale was the most reliable cue.
- **Line quality carries meaning.** Straight, angular lines feel direct and aggressive; curves feel soft and organic. (80.lv, "The art of the background: shapes and lines")

### 2.3 Symmetry and asymmetry
- **Centred feels made; off-centre feels natural.** A centred dominant feels man-made and clean, as with the *BioShock Infinite* monument. An off-centre dominant feels organic, as with *Dishonored*'s tower. (Piaskiewicz)
- **Balance has emotional weight.** The eye treats screen centre as a fulcrum. Symmetrical balance reads calm and peaceful. Asymmetrical balance reads as excitement, curiosity or anxiety. Large, dark, detailed elements are "heavy" and need counterweight on the other side. (Game Developer, elements and principles)
- **Break symmetry in small amounts.** For a melancholy "home" shot, keep the architecture symmetrical and the atmosphere asymmetrical: moon on one side, constellation or embers on the other, an object of story weight (the mailbox) on one side only.

### 2.4 Framing devices
- **What framing does.** Framing blocks parts of the environment so attention lands on what remains. Windows, arches, doorways and overhanging branches all work. (Game Developer composition articles; GameAnalytics, "framing destinations")
- **Foreground silhouettes.** Foreground elements are often silhouettes that frame the dominant. Background layers get muted colour, less detail and aerial perspective. (Piaskiewicz)
- **Framing a goal at the handover.** One technique is a cutscene-to-control transition where the camera looks through a window at the goal. This maps directly onto a title screen dissolving into gameplay. (GameAnalytics)
- **A frame between camera and subject changes the mood.** A long lens through a door, window or tree reads as voyeuristic. (No Film School on lenses)

### 2.5 Value hierarchy: the brightest point is the destination
- **The best-lit object is the most important one.** Light contrast separates it from everything else. (Piaskiewicz; Game Developer "Level Design Lesson 8: Eye-catching")
- **On a dark map, lit objects pop.** Use this selectively, or players learn the trick. (Lesson 8)
- **Shadow is a tool.** Leave large areas in shadow for a cleaner read. Merge the shadows of clustered props into one shape to cut noise. Use detail clusters as "rest areas" for the eye. (Andres Rodriguez, 80.lv)
- **What you don't light matters.** Deakins repeats John Alton's idea that what you don't light matters as much as what you do. He is known for single motivated sources and letting the rest of the frame fall to black. In *Skyfall*'s chapel sequence the burning house is effectively the only source. (StudioBinder; FilmLocal; BFI "Deakins in ten shots")
- **Signal-to-noise.** Concentrate detail where attention should go and keep the rest sparse. Use "dynamic range," meaning saturation or brightness contrast, for emphasis. (Game Developer, "6 elements of visual guidance")

### 2.6 Foreground, midground and background layering, and depth cues
- **Firewatch's method.** Jane Ng (GDC, "The Art of Firewatch") describes the palette as bold colours in distinct layers, each layer adding depth. The layers get lighter toward the horizon, with flat shapes, strong silhouettes and coloured fog. The game began from a single Olly Moss painting styled after WPA national-park posters.
- **Depth cues to stack:**
  - overlap;
  - atmospheric perspective (lighter, bluer and lower contrast with distance);
  - size diminution;
  - converging lines;
  - detail falloff;
  - warm-near and cool-far, or the reverse when the warm light is the goal;
  - parallax from slight camera drift.
- **Layer people at different depths.** Deakins stages actors at varying depths to give a shot layers. (StudioBinder) The *Spielberg oner* applies the same idea to time *(general knowledge, popularised by Tony Zhou's "Every Frame a Painting")*. It is a single unbroken shot in which blocking moves characters between foreground and background. That builds several "shots" without a cut, so depth replaces editing.
- **2D games do the same in parallax.** *Ori* and *Hollow Knight* *(general knowledge)* push the foreground into near-black silhouette and the background into hazy, desaturated planes. The gameplay plane keeps the mid values and the highest contrast.

### 2.7 Silhouette readability and shape language
- **Shape carries meaning.** Shapes are geometric (built) or organic (natural), static or dynamic. (Game Developer, elements and principles) A geometric house in an organic forest of pines is a contrast-of-shape weenie, the same trick as *Journey*'s angular towers in the soft desert. (GameAnalytics)
- **Common shape vocabulary:**
  - Squares and rectangles read as stability and shelter (a house).
  - Triangles read as direction and danger, but tall triangular pines in rhythm read as a protective palisade.
  - Circles read as softness (the moon, glows).
- **Test in black and white.** Fill every element black on a mid-grey sky. If the house, gate, lantern, mailbox and pines still read, the composition works.
- **Bloodborne inverts this for dread** *(general knowledge)*. Yharnam's spires are spiky, vertical, overlapping silhouettes against a pale moon. Too many points and no rest areas produce menace.

### 2.8 Rule of thirds and the golden ratio, and when to break them
- **The rule of thirds** places subjects on a 3×3 grid. It comes from John Thomas Smith's 1797 *Remarks on Rural Scenery*, which favoured roughly two-thirds to one-third splits over halves. (Wikipedia) StudioBinder frames it as the opposite of dead-centre framing and as a source of "eye room."
- **The evidence is weak.** A 2014 study (Amirshahi et al.) found highly rated photographs followed the rule no more than ordinary images. 19th-century critics already called it neither accurate nor universal. (Wikipedia)
- **The golden ratio and rabatment** are offered as placement aids. (Piaskiewicz) Treat them as one more grid, not as magic.
- **Level designers use thirds practically.** They put pickups or exits on a third intersection of the spawn view so players notice them on entry. (Game Developer, "Lesson 22")
- **When to break the rule:**
  - Break it when the subject *is* the architecture of the frame: a frontal house, a monument, a door.
  - Break it when you want stillness, ritual or memory, as in Kubrick and Wes Anderson *(general knowledge)*.
  - Break it on title cards, where text needs a central axis.
  - Use thirds instead for secondary elements: moon, mailbox, horizon line.

### 2.9 Negative space and sky ratio
- **Negative space means isolation.** Empty space around a small subject reads as loneliness, isolation or foreboding (*Punch-Drunk Love*, *Ex Machina*, *Blade Runner 2049*). (StudioBinder)
- **Emptiness can do narrative work.** *Shadow of the Colossus* is built on *ma*, meaningful emptiness, and Fumito Ueda's "design by subtraction." Vast empty land makes each colossus land like a brushstroke. (Yahoo/Polygon essay on *ma*)
- **Choose the sky ratio by mood:**
  - About 1/3 sky reads grounded and intimate. The subject dominates.
  - About 1/2 sky reads balanced and static.
  - About 2/3 sky reads lonely, open and sublime. This is Journey's and Death Stranding's register *(general knowledge)*: tiny figures under huge skies.
- **For *Unsent*.** A sky share of roughly 35–45% keeps the house dominant while leaving room for the moon and the Milky Way. Push it toward 55–60% in a later, lonelier shot of the empty house.

### 2.10 Camera height and lens: "home" vs "menace"
- **Camera angle.**
  - A low angle reads as power, which is good or bad depending on the subject. Combined with a Dutch tilt or confinement, it reads as trapped and vulnerable.
  - A high angle reads as vulnerability.
  - Eye level reads as connection. (StudioBinder)
  - These readings depend on context and are conventions, not laws.
- **Lens.**
  - Wide lenses close to the subject put the viewer *in* the space. They exaggerate depth, and at extremes they read as fear or madness.
  - Telephoto lenses read as distant, observational and voyeuristic.
  - 24–50 mm-equivalent lenses read as neutral and objective. (No Film School; PremiumBeat/Fiveable summaries)
  - Deakins favours primes, a stable camera and fairly wide lenses with deep focus, so the world stays legible. (StudioBinder)
- **"Home" recipe:**
  - eye level or slightly below (child's-eye memory);
  - level horizon and straight verticals;
  - frontal, one-point perspective;
  - 35–50 mm equivalent;
  - warm light *inside* the building.
- **"Menace" recipe:**
  - low camera close to the ground with a wide lens, so the building looms;
  - a tilt or Dutch angle;
  - dark windows with one cold light;
  - or a long lens from behind foliage, as if being watched.
- ***Unsent* should sit in "home with an ache."** Use the home recipe, with one wrong note: the door is open, it's night, and the only fire is small.

### 2.11 Guiding the eye with light in level art
- **Plan light direction from blockout.** Use it to lead players to key locations, and reveal places through contrast, such as a dark corridor opening into a bright courtyard. (Rodriguez, 80.lv)
- **Light marks exits, paths and first sightings of new things,** and sets mood. (Unity)
- **Consistent light and colour rules teach the player.** Uncharted 4 gave every grab ledge a white edge. (Martin Teichmann via Game Developer) Shadows give the eye rest and isolate focal points. (Game Informer on Uncharted 4)
- **Journey's opening is the textbook case.** Cresting a dune reveals a bright light above a distant mountain, and the title appears over it. That one shot states the whole goal. Designers also playtested by watching faces and adjusted light placement and angles until eyes landed correctly. (GDC Game Narrative Review on Journey; GamesBeat on Hunicke/Santiago)
- **Half-Life 2's Citadel** is the dark counterpart. It is a vertical, alien landmark visible across City 17, a menacing weenie: you start at its foot and end on its roof. (Valve Developer wiki; PC Gamer)
- **Every light needs a motivation.** Ask "what's the source?" before placing a light. (FilmLocal on Deakins) In the reference, each light has a source: moon, lantern, windows, door flame. Ember particles are the one stylised exception.

### 2.12 Title-screen and key-art composition
- **A title screen sets the mood like a book cover.** Subdued screens suit heavy games; *The Last of Us* I and II use quiet menus. (SuperJump)
- **The menu is the opening chapter.** Build it from level assets, light the focal point and use leading lines toward a destination. *Dragon Age: Inquisition*'s marching armies point at a building that then explodes when you press New Game. (Game Developer, "Setting the tone")
- **A wordmark can break a composition.** The *Alien: Isolation* team found the "Isolation" subtitle wrecked the reveal composition, so it stayed only in the static logo. (Art of the Title)
- **Typical key-art layout** (*general knowledge*: *Firewatch*, *Journey*, *Death Stranding* posters):
  - The subject sits on a vertical axis.
  - The upper sky is left for atmosphere.
  - The wordmark sits in the quietest band, usually lower third or upper sky.
  - Type is set in a value close to the background so it reads by shape, not glare.

---

## 3. Game and film examples (quick reference)

| Work | Technique | Lesson for *Unsent* |
|---|---|---|
| Disneyland Main Street | Castle wienie with forced perspective | The door flame is the castle; the path is Main Street |
| *Super Mario Odyssey* | Chained landmarks, each visible from the last | After the title, the next weenie (a lit window or letter) should be visible from the porch |
| *Journey* | Light over mountain, title revealed above it | A centred light goal plus the title on the same axis works |
| *Shadow of the Colossus* | *Ma*, subtraction, empty space | Cut props that don't serve the flame |
| *Half-Life 2* | Citadel as a menacing vertical weenie | Vertical dark mass reads as threat; keep the house horizontal and low |
| *Firewatch* | Distinct colour layers, lighter with distance, coloured fog | Pine layers in three values; navy sky lightens toward the horizon |
| *Uncharted 4* / *TLOU* | Light and colour as guidance; consistent rules; quiet menus | Warm = "go here" for the whole game |
| *Dishonored* / *BioShock Infinite* | Off-centre vs centred dominant | Centred house = constructed, remembered |
| *Ori*, *Hollow Knight* *(gen.)* | Black foreground silhouettes, hazy background | Pines and branches framing the corners should sit near black |
| *Bloodborne* *(gen.)* | Spiky overlapping silhouettes = dread | Avoid spiky clutter around the house |
| *Death Stranding* *(gen.)* | Tiny figure, huge sky | Save the high-sky ratio for a later lonely beat |
| Deakins (*Skyfall*, *1917*, *BR2049*) | Single motivated source, deep layered staging, primes | One fire, everything else subordinate |
| Spielberg oner *(gen.)* | Depth staging replaces cuts | A slow push from gate to door can do the "tap to continue" transition in one move |
| Ghibli / Kazuo Oga backgrounds *(gen.)* | Lush, specific nature; warm interior light against cool exteriors; lived-in detail | Warm curtained windows and specific objects (the mailbox) make "home" believable |

---

## 4. Analysis of the reference composition (`reference_target.webp`)

Positions are approximate, as percentages of frame width and height from the top-left.

**Structure.**
- The frame is a frontal, one-point perspective. The vanishing point is roughly at the door threshold (x ≈ 50%, y ≈ 64%).
- The house body spans about x 27–70% and y 24–65%, a wide horizontal rectangle with its roof ridge near the top third (y ≈ 27%).
- The fence is a horizontal band from y ≈ 62% to 85% across the full width. It walls off the viewer, but the gate is open, which turns the barrier into an invitation.

**Focal point (the weenie).**
- The small flame in the open door sits at x ≈ 50%, y ≈ 60%. It is dead centre horizontally and just below the frame's vertical centre.
- Every major line converges on it:
  - the cobblestone path, which is wet and so reflects warm light back toward the camera;
  - the gateposts, a frame within a frame;
  - the porch columns, a third frame;
  - the doorway, a fourth.
- The nested frames act like a tunnel to the flame. This is the strongest move in the image.

**Value hierarchy.**
- *Intended order:* door flame, then the lantern, then the windows, then the moon, then the embers and snow.
- *Actual risk:* the foreground lantern (x ≈ 25%, y ≈ 62–70%) is larger and nearly as bright as the flame, and it sits close to the left-third line. Its picket shadows also rake bright stripes into the lower-left foreground. The eye currently goes lantern first, then flame.
- *Fix:* in the game build, dim the lantern 30–40%, reduce its bloom, or crop it partly out of frame. Keep the doorway the single brightest and warmest pixel cluster. Its reflection on the wet path can be the second brightest.

**Balance.**
- The architecture is symmetric: gateposts, windows (four up and two plus door down) and roof.
- The atmosphere is asymmetric. Left side: moon, god rays, lantern, overhanging branches. Right side: Milky Way, red mailbox, ember "moths."
- The heavy, bright left is counterweighted by saturated red and moving particles on the right.
- This is the "symmetric architecture, asymmetric atmosphere" approach recommended in §2.3.

**Framing.**
- Dark pine masses frame left and right. The top-left branch overhang closes the corner and filters the moon into god rays.
- Branches act as a vignette, which keeps the eye from leaking out of the frame.

**Depth.**
- Foreground: fence, lantern, mailbox and snowy ground. It is warm-lit and textured.
- Midground: the house, warm windows, shrubs.
- Background: pines fading into fog, then the sky.
- Depth cues present: overlap, size diminution, atmospheric haze behind the house, and converging path lines.
- Weakness: background pines are similar in value to midground pines. Add more fog between the layers, Firewatch-style.

**Sky ratio.**
- The sky and tree crowns take about 30–35% of the frame. That keeps the shot intimate rather than sublime, which is right for "home."

**Shape language.**
- Rectangles (house, windows, door) mean shelter.
- Repeated vertical pickets give rhythm. The gap at the gate breaks the rhythm, which is an emphasis device (§2.2, "rhythm and disruption").
- Triangular pines act as sentinels.
- Round moon and round glows add softness.
- There is no spiky clutter.

**Story read.**
- Every window is lit, but no figure is visible. The door is open with only a small flame inside. The red mailbox sits outside the gate.
- It reads as "someone kept the light on, and a letter never went in." That matches *Unsent*.
- The mailbox is the story's counterpoint and should stay the only saturated non-warm hue.

**Where the title should sit.**
- The quietest large region is the dark ground band below the fence, from y ≈ 86% to 97%. It is low in detail and on the central axis, directly under the path.
- Placing "UNSENT" there (centred, cap height about 6–8% of frame height, baseline around y ≈ 90%) creates a vertical stack: flame, then path, then title. The title becomes the base of the leading line, not a competitor to it.
- Keep the wordmark in a cool off-white or pale warm grey at about 70–80% brightness. It should be dimmer than the flame and lit by the scene, not glowing on top of it.
- The lower-right band (under the mailbox) is the fallback. The upper-right sky around the Milky Way is the alternative if the title must ever move up. Never put text across the door, path or roofline.
- "Tap to continue" goes below the title at y ≈ 95%, about a third of the title's size, at 40–55% opacity. Pulse it slowly in sync with the flame's flicker rather than blinking.
- *Collision to watch:* the lantern's raking picket shadows reach the bottom-left at y ≈ 85–95%. Either shift the shadow fan so it ends before the title band, or make sure the title's left edge stays right of x ≈ 35%.

---

## 5. Apply to *Unsent*'s opening — checklist

### Camera position and height
- [ ] Place the camera on the path's centre line, 1.5–2.5 m outside the open gate. The gateposts should frame the path at about 40–60% of frame width.
- [ ] Set camera height to **1.2–1.4 m**, slightly below adult eye level. This puts the horizon near the door threshold (y ≈ 60–65%), roughly at fence-top height, for a child's-eye or memory feel. Do not go below 1.0 m, or the house starts to loom (menace).
- [ ] Keep pitch at 0° and roll at 0°. Verticals stay parallel and the house reads stable and constructed. Any tilt reads as unease.
- [ ] Set the house front about 16–22 m from the camera, so the roof ridge lands near the top-third line and sky plus tree crowns take about 30–40% of the frame.
- [ ] Optionally add a very slow idle drift (±3–5 cm sway, 8–12 s period) for parallax depth between the fence, house and pines. No rotation.

### Lens / FOV (Godot `Camera3D`)
- [ ] Godot's `fov` is **vertical** by default (`keep_aspect = KEEP_HEIGHT`). Use **36–40° vertical**, about a 35 mm full-frame equivalent and about 60–65° horizontal at 16:9. That is a neutral "home" lens.
- [ ] Avoid more than 55° vertical (wide distortion, menace or fear) and less than 25° (telephoto voyeurism) for this shot. A narrower FOV is fine for a later "being watched" beat.
- [ ] Use a light depth of field through `CameraAttributesPractical`. Blur the far pines and sky slightly, and keep the fence through the door sharp. Leave the near fence sharp too, as Deakins-style deep focus.
- [ ] Test the frame at 16:9, 21:9, 4:3 and phone portrait-crop. With `KEEP_HEIGHT`, wider screens reveal more pines at the sides, which is safe. On narrow screens, make sure the gateposts and mailbox stay in.

### Focal light (the flame)
- [ ] The **door flame is the single brightest, warmest element on screen.** Use an emissive mesh plus `OmniLight3D` (warm 1800–2200 K, flicker on energy ±10–15%). Let the glow from `WorldEnvironment` bloom it slightly.
- [ ] Make the wet path reflect the flame. Use low roughness on the cobbles, with screen-space reflections or a reflection probe. The reflection becomes a light trail toward the camera, a light-based leading line.
- [ ] **Dim the lantern** relative to the reference so it ranks second or third. Use lower energy, a smaller glow radius, or partial cropping. Its picket shadows can stay, but shorten them so they don't cross the title band.
- [ ] Windows should be warm but dimmer than the door (about 50–60% of the flame's luminance). Curtains help: some soft shadow shapes, no figures.
- [ ] The moon is the cool counter-light (top-left third intersection). Run god rays through the branches using a `DirectionalLight3D` with volumetric fog. Keep it at low intensity, because it frames the shot and is not the subject.
- [ ] Keep embers and snow as small, low-contrast motion events. Embers drift right and upward to balance the moon. None should be brighter than the window glow.
- [ ] The red mailbox stays the only saturated non-warm hue. Keep it in shadow-side light so its colour reads without glare.
- [ ] Run a grayscale check: desaturate the frame. The flame must still be the brightest point, and the house silhouette must read against the sky.

### Title wordmark and prompt
- [ ] Place "UNSENT" **low-centre**: horizontally centred on the path axis, baseline around y ≈ 88–91%, in the dark ground band below the fence. Cap height should be about 6–8% of frame height.
- [ ] Make it dimmer than the flame, with a pale cool grey or desaturated warm tint. Add a slight drop or inner shadow for legibility. No glow halo bigger than the letter stroke.
- [ ] Put "Tap to continue" at about y ≈ 94–96%, about 30–35% of the title's size, at 40–55% opacity. Pulse it slowly (2–3 s cycle), ideally phased with the flame flicker.
- [ ] Keep all text inside a 5% title-safe margin, and make sure nothing overlaps the door, path, gateposts or roofline.
- [ ] Add a vignette that darkens the lower corners slightly, which gives the text a quiet bed. Keep the centre-bottom band darker than the path.
- [ ] Fade the title in after the scene has settled (1.5–2.5 s), so the eye finds the flame first and drops to the title second.
- [ ] Transition on tap: fade the title, then push the camera slowly through the gate and along the path toward the door. This is a single continuous move in the oner spirit, and it hands control to the player facing the weenie, with the next goal framed in view.

---

## Sources

1. https://www.gamedeveloper.com/design/what-mario-learned-from-mickey-mouse---part-3-decision-making-and-weenies
2. https://www.above-the-garage.com/wienies/
3. https://boingboing.net/2009/03/27/gamedesign-lessons-f.html
4. https://turbo-wiki.pages.dev/tim-cain/level-design/everything-i-learned-from-disneyland
5. https://www.gamedeveloper.com/design/composition-in-level-design (Mateusz Piaskiewicz, originally level-design.org)
6. https://www.gamedeveloper.com/design/6-elements-of-visual-guidance
7. https://www.gamedeveloper.com/art/applying-the-elements-of-design-and-principles-of-design-in-level-art
8. https://www.gamedeveloper.com/design/level-design-lesson-22-rule-of-thirds
9. https://www.gamedeveloper.com/design/level-design-lesson-8-eye-catching
10. https://www.gamedeveloper.com/design/-i-uncharted-4-i-artist-shares-tips-on-making-your-game-more-readable
11. https://www.gamedeveloper.com/design/setting-the-tone-main-menus-are-the-game
12. https://unity.com/blog/level-design-basics
13. https://www.gameanalytics.com/blog/five-simple-ways-use-level-design-improve-player-experience
14. https://80.lv/articles/andres-rodriguez-environment-art-interview/
15. https://80.lv/articles/the-art-of-the-background-shapes-and-lines
16. https://80.lv/articles/boon-cotter-light-magic-with-uncharted-4
17. https://80.lv/articles/tips-on-cinematic-environment-production-from-naughty-dog/
18. https://gameinformer.com/b/features/archive/2015/01/21/the-secret-depth-of-uncharted-4-s-art-design
19. https://media.gdcvault.com/gdc2024/GNR/Papers/DeanGoodson-GameNarrativeReview2024.pdf (Journey narrative review)
20. https://gamesbeat.com/?p=23457 (How thatgamecompany designed Journey)
21. https://www.gamedeveloper.com/art/video-deconstructing-the-art-design-of-i-journey-i-
22. https://www.gdcvault.com/play/1023707/ (The Art of Firewatch, GDC)
23. https://boingboing.net/2015/03/27/how-a-small-art-team-created-f.html
24. https://blogs.ulster.ac.uk/bethbuchanan/2021/03/05/ixd104-further-looking-into-the-art-of-firewatch
25. https://developer.valvesoftware.com/wiki/Citadel
26. https://www.pcgamer.com/games/fps/half-life-2s-2003-beta-reveals-the-mystery-behind-a-city-17-river-that-once-led-players-to-the-foot-of-the-citadel
27. https://www.yahoo.com/entertainment/shadow-colossus-art-ma-140056786.html
28. https://www.studiobinder.com/blog/roger-deakins-cinematography/
29. https://filmlocal.com/?p=1446849 (Deakins style guide)
30. https://www.bfi.org.uk/sight-and-sound/features/remain-light-roger-deakins-ten-shots
31. https://www.studiobinder.com/blog/rule-of-thirds/
32. https://www.studiobinder.com/blog/what-is-negative-space-definition/
33. https://www.studiobinder.com/blog/low-angle-shot-camera-movement-angle/
34. https://nofilmschool.com/2017/06/how-to-capture-different-emotions-different-lenses
35. https://www.premiumbeat.com/blog/various-focal-lengths-for-images/
36. https://en.wikipedia.org/wiki/Rule_of_thirds
37. https://en.wikipedia.org/wiki/Kazuo_Oga
38. https://www.superjumpmagazine.com/the-unappreciated-beauty-of-the-title-screen/
39. https://www.artofthetitle.com/title/alien-isolation/

Gaps: the search budget ran out before Reddit threads (r/leveldesign, r/cinematography), X/Twitter threads, World of Level Design and a Spielberg-oner source could be gathered. Items marked *(general knowledge)* should be verified if they become load-bearing.
