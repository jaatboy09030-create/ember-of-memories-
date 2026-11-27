# 10: The VFX artist's workflow, learning path and community wisdom

How working real-time VFX artists spend their days, how they learned, and what the community (realtimevfx.com, VFX Apprentice, Riot, 80.lv interviewees, leads who hire) agrees makes effects outstanding. It ends with **20 commandments** distilled from all of it.

> Sourcing note: Reddit and X could not be read directly. Search returned only Telegram mirrors of r/vfx questions, with no answers. The best-known X "tips" thread (Harry Alisavakis asking artists for VFX tips) is cited through 80.lv's write-up [12]. Most of the "community wisdom" here therefore comes from realtimevfx.com threads, which hold the same people and the same discussions in a form that can be fetched.

---

## 1. Key takeaways

- **Timing and composition matter more than shaders.** The most common answer to "what would you tell your beginner self" is to spend less time on materials and more on timing, colour and behaviour over a particle's life. A shader setup can be copied exactly; timing has to be learned [1]. Keith Guerrette lists composition, colour, shape, timing, follow-through and secondary motion as the universal skills [14].
- **Pros block in first.** They build a deliberately crude version (greyscale, simple shapes, simple shaders, few emitters) to solve timing and composition. Textures, shaders and meshes come last [5][6]. Gabriel Aguiar works the same way: paper sketch, then core motion and proportions in engine, then visual refinement [9].
- **Every effect has a structure.** The phases are wind-up/anticipation, then climax/impact, then fall-off/dissipation. Each phase is either an *impulse* (a spike) or a *rhythm* (a sustained beat) [6]. Riot's version: the pop should be fully active within the first quarter of the lifetime, then a smooth erosion follows [7].
- **"If your FX feel long, they're waaay too long"** (Riot style guide via VFX Apprentice [7]). Lingering transparent particles are also the main overdraw cost.
- **Readability beats beauty.** Riot ranks gameplay clarity above theme. Primary elements get high value, a clear silhouette and high opacity; secondary elements get lower value, softer shapes and less motion. Avoid pure black and pure white [7][8].
- **Iterate in context, not in the editor void.** Check effects in game after every system change, because animators retime things without warning [3]. Ask design how the effect will be used before you build it [3][15][16].
- **Feedback early, and it must be specific.** Ask peers while the effect is still rough [17]. Good notes name something changeable, such as "impact needs more speed", "camera closer" or "colours clash". "Add more life" is not useful [4][18].
- **Learn by finishing small things, not by watching tutorials.** The community's path is campfire, then fireball, then impact. Learn one new thing at a time, then make, get feedback and iterate [19]. Tutorials teach recipes, not the thinking behind them [19].
- **Record everything, keep sources.** Capture every effect at every stage, alone and in game, in a format any default player opens. Keep PSDs and layered sources. Keep a daily solutions journal [1].
- **Portfolios: short, awesome, in context.** "Keep it short, make it awesome" (Bogdan Suman, lead [10]). Show effects hitting a target. Never make a placeholder sphere the focal point. Use a neutral background and a static camera. Show range across styles, and include one explosion that is distinctive [11][20][21].
- **Art tests:** expect about a weekend or 10–20 hours, one effect, and a clear power level and style. Breakdowns, wireframe and overdraw passes are extras. Reviewers judge hue, value, cohesion, timing, readability, and whether you made decisions on your own [18].
- **Asset packs are starting points.** The day-to-day pro habit is kitbashing: copy an emitter from a similar effect and retune colour, spawn rate and size [3][16]. A pack only looks stock if you ship its colours, timing and textures unchanged.

---

## 2. Deep dive

### 2.1 The day-to-day loop (how pros actually work)

A synthesis of the Rookies career piece [16], Travis McCallum's beginner thread [3], the 80.lv "Learning FX Workflow" article [15], Aguiar [9] and the "VFX staples" article [13]:

1. **Brief and purpose.** Start from a ticket in Jira or similar. Ask design what the effect *is for* (damage radius? hit confirmation? a heal?) and what priority it has [13][14]. Guerrette's first question is about function, not beauty [14]. Get the gameplay timing from design: in one shipped spell, the anticipation was a design setting adjustable from **0.5 s to 2 s** [13].
2. **Reference and mood board.** Concept art is often not provided, so the artist builds a board from ArtStation, Pinterest and Magesbox [16]. Look past the subject for a "hook", for example how silk moves in wind, used for a magic ribbon [15]. (Reference practice is covered in 2.2.)
3. **Element list.** List every element (core, flash, sparks, smoke, decal, light, camera shake, sound cue). The same document later tracks feedback [15].
4. **Block-in in engine, greyscale.** Animate the main motion roughly, "much like a character animator's first-pass blocking" (Matt Schwartz, summarised [17]). Reuse existing emitters [16]. Get it into the game quickly so design can test it [13].
5. **Timing pass.** Tune wind-up, climax, fall-off and spikes until the effect is satisfying with style removed [5][6]. Plan it from a sound or vocal reference: say "fwoosh-BANG" out loud, record it, and break it down [6].
6. **Build final elements in order.** Meshes first (quickest), then textures, then rough shaders and particle setups. Add emitters one at a time, and get each one right before adding the next [15].
7. **Integrate.** Attach to sockets and bones, sync to animation frames, wire to Blueprints or gameplay triggers [3]. Split the effect into **Start / Loop / End** so a designer can stretch or kill it [3]. In one example, a press-and-release shield loops forever with emitter duration and life of **0.1 s**, so it can be cut almost instantly [3].
8. **Optimise last, but check throughout.** Use shader-complexity and overdraw views, where bright means a problem. Trim sprites tight to their alpha. Lower the spawn rate until impact *starts* to drop, then go back one step. Set bounds to the reasonable extent, not to outlier particles. Add LODs for persistent effects. Scale a fully faded particle to zero [3][15].
9. **Record, document, version.** Make a short video of every iteration. Save a new version after each significant change. Annotate source files [1][3][16].

Time scales from the job: a simple effect built by reusing emitters takes **about an hour**; an effect with new behaviour takes **several days** [16].

### 2.2 Reference gathering: real footage, anime, slow motion

- **Real footage.** VFX Apprentice's first portfolio rule is to study real-world elements. Even fantasy effects must read instantly, and small fixes to shape and direction restored a reviewed tornado-portal's purpose [11]. Guerrette points real-time artists to **film VFX history and SIGGRAPH archives**, since real-time tools have trailed film by about a decade [14].
- **Slow motion.** High-speed reference is the standard way to read fast phenomena such as fire licks, debris arcs and shockwave rings. When filming your own, watch frame rate and motion blur, and export as a PNG sequence to step through it [22] (snippet).
- **Anime and sakuga.** The realtimevfx "inspirational resources for stylized effects" thread recommends Akira (its smoke), Fate/Stay Night (dramatic pauses *before* the explosion), Avatar and Korra, SAO's sword trails, Wind Waker for toon effects, and **Sakugabooru's effects tag** as a searchable clip archive [23]. Its method is to log the episode and timestamp of every effect you like and revisit it frame by frame. Study the pause and anticipation, not only the burst [23].
- **Games against games.** Compare LoL and Dota, which solve the same spell-readability problem in different styles [23]. Sirhaian's (Kevin Leroy's) LoL fan-art sources were released for study [24], and VFX Apprentice's free "League of Effects" course breaks them down with sandbox files [25].
- **Sound as timing reference.** VFX Apprentice plans timing from audio, recording vocal or sound iterations of the effect [6].

### 2.3 Block-ins: grey/white first

The realtimevfx "Block-ins and Timing" post defines a block-in as an effect built with *limited tools*: simple textures, shaders, meshes and **greyscale** [5]. Colour and polish hide weak timing, so you take them away. Once the timing works, re-map it to make variants: a slow friendly spell becomes a fast damaging one, and a slow projectile becomes a fast one. Balance values at this stage; the damaging version got darker darks next to its whites [5]. Some artists block in with two emitters, others with a fuller rig [5].

VFX Apprentice's timing model, for judging the block-in [6]:

| Phase | Role | Pattern |
|---|---|---|
| Wind-up | signals "something is coming" | crescendo (an impulse with build) or a rhythm |
| Climax | the pop | impulse, at peak value and saturation |
| Fall-off | dissipation | reduce each element's intensity *before* the effect ends |
| Spikes | high-intensity moments | not only "bright" or "many emitters" |

- **Crescendo recipe:** pair growing elements with shrinking ones, mix fast and slow elements, and give each element one distinct job. More elements allow richer timing but risk dissonance [6].
- **Heartbeat tempo trick:** pacing faster than a heartbeat reads as aggressive (attacks); slower than **60 BPM** reads as inviting (heals) [6].
- **Worked fireball:** build-up = rhythm, cast = impulse, travel = rhythm, impact = impulse [6].
- **Judge on intensity over time,** not on single properties such as position, scale or colour [6]. VFX Apprentice's timing chart runs over **48 frames**, where dense keys mean slow movement [6].
- **Riot's curve:** a non-linear three-stage life. A brief, fast wind-up warns the enemy; the pop reaches peak value and saturation **within the first 25% of the lifetime**; then a smooth, rhythmic erosion clears the ground [7].

### 2.4 Iterating in context

- Effects change because gameplay changes. Build in compartments, document, and expect to reorganise triggers [3].
- Use as few tools as possible. Every hop through another package makes a small tweak slower [3].
- Verify in game after every system change, because "QA may miss niche FX issues" (paraphrase of [3]).
- Character effects: set key poses and timing *first*, then build the VFX on that timing [13].
- Use triggers (HIT, END) so a spell's duration can change without breaking the effect [13].
- Build reusable shaders and instance materials rather than making new ones [15]. Use grayscale textures with gradient or LUT colouring so one texture serves many effects. The "VFX staples" article uses a **1–4 colour gradient → LUT** and packs R = colour mask, G = emission, B = alpha [13].

### 2.5 Feedback and critique culture

- **realtimevfx.com** (about 2,300 active users when Guerrette was interviewed, and indexed by Google) is the hub. It has WIP & Critique, Sketchbooks, a Discord and a Jobs board [2][14].
- **VFX Sketch challenges.** A monthly theme (Campfire, Shield, Neon, Glitch, Snow, Ghostly, Air Bending, Fan Art...) is posted in a "risk-free environment" [26]. Rules: cite all sources and references, post during the month, any tool is allowed, and keep presentation scenes simple. Winners are chosen by community vote on **process shown during the month**, technical and artistic execution, and following the rules [26]. The original series was about rough, fast iterations on an abstract idea, free of design constraints (snippet [27]).
- **What critique looks like in sketch threads** (snippets [27]): turn off a harsh background shadow so the effect reads; push the camera in so the effect fills more of the screen; speed up the impact for punch; try a greyscale palette.
- **Good feedback is actionable and specific.** In the art-test thread, candidates singled out notes such as "timing", "colour clash" and "too many simultaneous elements" as useful, and "add more life" as harmful. They also want to hear what is working [18].
- **Ask outsiders** (non-NDA) too. Fresh eyes catch timing and camera problems the author can no longer see [16][27].
- **Ask early.** Schwartz goes to peers as soon as a piece "is coming together", because early notes help more [17].

### 2.6 VFX tests and what leads look for

**Art tests** (realtimevfx "what does a great experience look like" thread [18]):
- Scope is a weekend or **10–20 hours**, or an hour budget (for example 40 h) spread over time. Seniors work 2–10× faster than juniors, so scale the test to the level.
- Deliverable: **one** effect. Breakdowns, extra camera angles and wireframe or shader-complexity passes should not count against the deadline.
- A good brief gives the parts (for example a tornado that builds from nothing, loops, then fades), a style, a **power level and scale**, references, and a starter scene with flash, glow and spark textures.
- A mid-test check-in at **50–65%** is valued.
- Reviewers judge **hue, value, cohesion, consistency, timing, creativity, readability** (Shannon Berke), whether the whole thing "looks right", and **independence**.

**Portfolios:**
- Lead Bogdan Suman wants **animation, lighting, sense of scale, physics, power and optimisation**. The effect should land within a split second. Be ready to discuss CPU vs GPU emitters, draw calls, overdraw, particle counts, culling, distance fade and sprite-geometry intersection [10]. Overcomplicated effects that "don't feel right" put him off however pretty they are [10].
- VFX Apprentice's rules: study real elements; avoid placeholder spheres; neutral background and static camera; order effects small to big; place explosions side by side for scale; give every effect a **motivation** (a spear needs a portal or cloud burst to come from); and get timing right with the music off [11].
- A reel can be cut to a rhythmic song using big/medium/small pacing, then **exported without audio** [6].
- Community advice: show effects **hitting a target** (pair slashes with hits; a sphere or unanimated character is fine as the target), show range across styles, and include one *unique* explosion [20].
- The Rookies piece: a few polished pieces, stills plus a breakdown of your thinking, game-ready limits (particle count, translucent overdraw), and a clear purpose for each effect (heal, buff, element) [16].
- Riot's head of creative and job posts ask for colour, shape, ratio and timing sense plus gameplay readability (snippets [21][28]).

### 2.7 The learning path (free resources first)

The realtimevfx "Start Here" thread [2] gives this order: **tools → engine → particles → materials → mesh FX → advanced techniques → pick a style (stylized/realistic) → keep following the community.** Guerrette says to build artistic foundations first, then engine basics, then materials and shaders (nodes, then HLSL), then the scripting that triggers effects. Offline tools like Houdini are supplements [14]. Mederic Chasse says to start from the **12 principles of animation** and *The Illusion of Life* [29].

| Resource | What it's best for |
|---|---|
| realtimevfx.com: Start Here thread, VFX Dictionary, Sketches, Discord [2][26] | Terminology, critique, the community |
| Jason Keyser: "Artistic Principles of VFX" YouTube series; VFX Apprentice blog and free "League of Effects" course [2][25] | Timing, 2D FX, stylized design |
| Riot's public VFX Style Guide PDF [2][7] | Readability, value, colour hierarchy |
| Sirhaian (Kevin Leroy): released LoL fan-art sources and YouTube [2][24] | Dissecting pro stylized setups |
| Gabriel Aguiar Prod. (YouTube; Unity, plus Godot courses and tutorials) [9][30] | Practical step-by-step builds; Godot muzzle flash |
| ImbueFX (old, UDK) [2] | Said to cover "about 80%" of the fundamentals |
| Andreas Glad (Houdini for games), JangaFX/EmberGen tutorials, GDC VFX Bootcamp [2] | Realistic and simulated FX |
| Shaderbits (Ryan Brucks) [2] | Advanced technical depth |
| Unity's free CC0 flipbooks (fire, smoke, explosions) [31]; Epic's free Niagara examples (snippet) | Free source material to study and remix |
| Godot: official particle docs [32], 80.lv Godot tutorials by Le Lu (stylized fire, VFX textures), Tendex plasma ball, Aguiar's muzzle flash [30][33] | Engine-specific practice |

**A caution from the community:** Mez's "tutorial rant" argues that most tutorials are recipes, hide the experts' failures, and skip fundamentals. The thread's consensus was to stop consuming and start finishing: campfire, then fireball, then impact, one new skill at a time [19].

### 2.8 Asset packs, and how to make them not look stock

- **Vefects** (itch.io, Gumroad and Fab; mostly Unreal/Niagara, with paid bundles of over 1,000 systems and one free pack a year such as *Zap*) [34]. The *Unsent* project already uses Vefects Stylized Fire. Its licence bars redistribution, so the source must never go into a public repo (project rule).
- **Kenney:** *Particle Pack* (80 sprites, 512×512, CC0) and *Smoke Particles* (70 files, CC0); also on the Godot Asset Library [35].
- **Unity's CC0 flipbooks** (fire, smoke and explosion EXR/TGA sequences) [31]. The **Brackeys VFX bundle** remixes Kenney and others (check its licence) [35].
- **Godot-native packs:** BUKKBEEK's EffectBlocks (60+ effects; commercial use allowed, no redistribution), Binbun's free muzzle flashes, and others [36].

**De-stocking a pack** (pro habit from [3][16], analysis for the specifics):
1. **Retime first.** Stock packs are timed generically. Fit their wind-up and pop to *your* animation frames and sound.
2. **Recolour with your palette.** Replace baked colour with a gradient map, and set the dominant/accent ratio (Riot's rule [7]).
3. **Replace the hero texture.** Keep the pack's sparks and smoke, but paint or bake your own core shape. The silhouette is what players remember.
4. **Kitbash, don't drop in.** Take two or three emitters from different effects and add one element of your own, such as a mesh ribbon, decal, light flash or ground scorch [3].
5. **Tie it to the world.** Add a light pulse, a decal, camera response and sound. In-context integration is what separates "asset" from "effect" [11][20].
6. **Pull textures from the project itself** (leaves cut from your own foliage, your own weapon mesh) and repack them smaller [3].

### 2.9 "Tips that changed my effects" (community-sourced)

- **Vary sprites, sizes, timing and starting rotation** (Rafles, from the Alisavakis X thread [12]).
- **Start / Loop / End** structure [3].
- **Fade, then scale to zero** to kill invisible overdraw [15].
- **Lower the spawn rate until impact drops**, then step back once [3].
- **Use high-contrast greyscale masks** so erosion stays smooth [15].
- **Use a UV layout across the full 0–1 range for scrolling, and scale slightly to hide seams on trails.** Use **vertex colour** for fades, and **skin weights as spawn masks** [15].
- **Use motion vectors** to cut flipbook frame counts [13].
- **Use meshes with scrolling textures instead of particles** where scaling or control matters [13].
- **Keep a solutions journal; record clips that play in default players** [1].
- **Ask "what is this for" before "what does it look like"** [14].

---

## 3. Examples

- **League of Legends (Riot).** A ranked set of goals (clarity, then less clutter, then theme), primary/secondary element rules, no pure black or white, and a pop within the first 25% of life. In one case, a champion's bright basic-attack VFX broke the hierarchy and was flagged as distracting in fights [7][8]. *Why it works:* every value and saturation decision serves a 5v5 player's split-second reading.
- **Meteor Strike / Unstable Dome** (the stylized spell set in "VFX staples" [13]). Anticipation tunable from 0.5 s to 2 s, 2–5 animation states per spell, and HIT/END triggers. *Why it works:* design can change the timing without breaking the VFX.
- **Press-and-release shield** (Travis [3]). A looping effect with 0.1 s life, so release feels instant. *Why it works:* responsiveness is a VFX decision.
- **Fate/Stay Night and Akira** as sakuga reference [23]. The pause before the burst and hand-animated smoke volume both show that anticipation and held frames sell power.
- **Sirhaian's LoL fan art** (Unity) got its author hired at Riot [24]. *Why it works:* readable shapes, LoL-faithful timing, and released sources that prove craft.
- **Sketch entries** that win on *process shown across the month*, not just the final clip [26].

---

## 4. Common mistakes (as reported by pros)

1. **Obsessing over shaders and materials while ignoring timing and composition** [1].
2. **Effects too long and too busy.** Long effects hide silhouettes, block other spells and cost overdraw [7]. Overcomplicated effects "don't feel right" [10].
3. **No hierarchy.** Every element is at full brightness, saturation and opacity, so nothing reads [7]. Clipping to pure white or black [7].
4. **Linear timing.** Even, mechanical curves with no anticipation or follow-through [6][7].
5. **Effects with no motivation or origin**, such as a spear appearing from nothing [11].
6. **Judging in a vacuum**: in the particle editor, over black, on an orbiting camera, never in game or against the real background [3][11][20].
7. **Placeholder spheres as focal points** in reels [11]. Effects shown with no target or hit [20].
8. **Optimising at the end only.** Not checking overdraw, oversized sprites, bounds set to outliers, no LODs [3][15].
9. **Tool sprawl and no documentation.** Too many packages, unlabelled PSDs, lost sources [1][3].
10. **Learning by tutorial-watching** instead of finishing small effects and getting critique [19].
11. **Relying on simulation tools and forgetting animation principles** [29].
12. **Not recording your work.** One artist lost all footage of three shipped games [1].
13. **Getting attached.** Expect retakes; the art director decides [16].

---

## 5. Apply in Godot 4 (4.7, Forward+, AgX, glow)

### 5.1 Build a "VFX lab" scene (block-in and review bench)

A dedicated scene, `res://vfx_lab/vfx_lab.tscn`, mirrors the realtimevfx setup: neutral, simple and static.
- A `WorldEnvironment` with the **same AgX tonemap, exposure and glow settings as the game**. Otherwise glow and AgX highlight roll-off will look different in the lab and in the game.
- A mid-grey floor and back wall (albedo about 0.18 linear, roughness 1). Shadow casting off on the backdrop, as sketch critique suggests [27].
- A **fixed `Camera3D`** at gameplay distance, plus a second one at the real first-person view height (about 1.6–1.7 m). No orbit or fly-through cameras: judge from where the player will stand.
- A grey capsule or the actual hand rig as a **target**, so impacts have something to hit [20].

### 5.2 Grey block-in material

Make a block-in `StandardMaterial3D`: Shading Mode *Unshaded*, Transparency *Alpha*, Billboard Mode *Particle Billboard*, **Vertex Color → Use as Albedo** ON, albedo white, and a soft round or Kenney grey texture. Drive everything from `ParticleProcessMaterial` curves (`scale_curve`, `alpha_curve`, `color_ramp` in greys, `emission_curve`). Iterate only on `lifetime`, `explosiveness`, `speed_scale`, velocity and the curves until the timing satisfies. Add colour afterwards (analysis).

### 5.3 Timing with frames, not guesses

Trigger emitters from an `AnimationPlayer` (Call Method track → `restart()`, or a property track on `emitting`). Keys snap to frames, so you can block "wind-up 0–8, pop at 9, fall-off 9–40" at 60 fps, matching the 48-frame timing-chart thinking [6]. For a one-shot pop: `one_shot = true`, `explosiveness = 0.9–1.0`, and a short `lifetime`. Put the peak of `scale_curve` and `emission_curve` in the **first 25%** of the curve, per Riot [7].

### 5.4 Slow-motion review and recording

```gdscript
# vfx_lab/vfx_review.gd: attach to any node in the lab scene
extends Node

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1: Engine.time_scale = 1.0
            KEY_2: Engine.time_scale = 0.25   # read the pop
            KEY_3: Engine.time_scale = 0.05   # frame-step feel
            KEY_R: _restart_all(get_tree().current_scene)

func _restart_all(n: Node) -> void:
    if n is GPUParticles3D or n is CPUParticles3D:
        n.restart()
    for c in n.get_children():
        _restart_all(c)
```
`Engine.time_scale` scales process delta. Check that sub-emitters and `fixed_fps` emitters slow down as expected in your build (analysis). To **record every iteration** [1], use Godot's **Movie Maker mode** (`--write-movie lab_clip.avi --fixed-fps 60`, or the editor's movie button). It renders at a locked frame rate regardless of hardware, gives frame-perfect clips for critique, and the AVI (MJPEG) opens in default players.

### 5.5 Overdraw and cost checks (optimise throughout)

- In the 3D viewport, use Perspective menu → **Display Overdraw**. Bright areas mean stacked transparency [3][15].
- Trim quads to the alpha. Lower `amount` until the impact drops, then go back one step [3].
- Set a tight `visibility_aabb` with **Generate Visibility AABB**, not one stretched to outlier particles [3].
- Scale a particle to 0 at the end of `scale_curve` once it is invisible [15].
- For persistent ambient effects (candles, dust), use `visibility_range_end` and fade (`visibility_range_fade_mode`) as a cheap LOD.

### 5.6 Gradient-mapped erosion shader (the de-stocking workhorse)

One greyscale mask can serve many effects by recolouring through a `GradientTexture1D` and eroding by particle alpha (the LUT approach [13][15]):

```glsl
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D mask : hint_default_white, filter_linear_mipmap;   // greyscale, linear data
uniform sampler2D gradient : source_color, repeat_disable;           // GradientTexture1D, 1–4 colours
uniform float intensity : hint_range(0.0, 8.0) = 2.0;                // >1 feeds glow under AgX
uniform float softness : hint_range(0.001, 0.5) = 0.08;

void vertex() {
    // Particle billboard (camera-facing, keeps particle scale)
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
                                          INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
    MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
        vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
        vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
        vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
        vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
    float m = texture(mask, UV).r;
    float threshold = 1.0 - COLOR.a;               // alpha_curve/color_ramp alpha drives erosion
    float a = smoothstep(threshold, threshold + softness, m);
    vec3 col = texture(gradient, vec2(m, 0.5)).rgb; // map value to colour: core hot, edges cool
    ALBEDO = col * COLOR.rgb * intensity * a;
    ALPHA = a;
}
```
Use high-contrast masks so the erosion stays smooth [15]. Keep the gradient's darkest stop above pure black and its brightest below pure white before `intensity`, so AgX and glow produce the "hot" core rather than a texture clipped at 1.0 (Riot's value rule adapted, analysis).

### 5.7 Customising the Vefects fire for *Unsent* (no stock look)

- **Retime to the scene's pace.** Unsent is melancholy and slow, so flames should breathe slower than 60 BPM (heartbeat trick [6]). Raise `lifetime` and lower `speed_scale` slightly, and add more rhythm, less impulse.
- **Recolour.** Replace the pack's baked fire colours with a gradient-mapped version (5.6): deep ember red, then amber, then a pale (not white) core. Make one colour dominant, with accents only on sparks [7].
- **Add one element of your own:** paper-ash flakes using the existing falling-leaf particle shader, an `OmniLight3D` whose energy is keyed to the same AnimationPlayer as the flame's pop, and a scorch decal. Keep the Vefects files themselves out of the public repo (licence rule).
- **Review it in the lab, then in the real room** at first-person height, with the game's glow and AgX settings, at 0.25× time scale, and record it.

---

## 6. The 20 commandments of outstanding VFX

1. **Know what it's for.** Gameplay purpose before beauty [14].
2. **Gather real reference:** footage, slow motion, sakuga frame by frame. Log timestamps [11][23].
3. **Sketch it, then block it in grey.** Solve timing with colour switched off [5][9].
4. **Anticipate, pop, dissipate.** Every effect has a wind-up, a climax and a fall-off [6][7].
5. **Land the pop in the first quarter of the life** and never use linear curves [7].
6. **If it feels long, it's way too long** [7].
7. **Contrast in time:** fast against slow, growing against shrinking, a hold before the burst [6][23].
8. **One focal point.** Primary elements are bright, sharp and opaque; secondary ones are soft and dim [7].
9. **Mid values for the body; save the brightest value for the flash.** No pure black, no pure white [7].
10. **One dominant colour; accents are small and desaturated** [7].
11. **Shape is design.** Hand-made, readable silhouettes beat photo noise [7].
12. **Every effect has a motivation:** a source, a cause, a target, an aftermath [11][20].
13. **Vary everything a little:** sprite, size, rotation, timing [12].
14. **Build in Start / Loop / End** so design can stretch it and kill it [3].
15. **Judge it in context:** in game, at gameplay distance, with real lighting and sound [3][11].
16. **Ask for critique early and make your own notes actionable** [17][18].
17. **Make it cheap as you go:** overdraw view, tight sprites, tight bounds, scale-to-zero, LODs [3][15].
18. **Reuse smartly:** greyscale masks, gradient maps, instanced materials, kitbashed emitters. Never ship a pack unchanged [3][13][15].
19. **Record and document everything:** clips that play anywhere, sources kept, a solutions journal [1].
20. **Finish small things often.** Campfire, fireball, impact. Make, get feedback, iterate. The animation principles outrank any tool [19][29].

---

## 7. Sources

1. realtimevfx: "What is one thing you'd tell yourself if you'd travel back in time to when you started doing VFX?" https://realtimevfx.com/t/what-is-one-thing-youd-tell-yourself-if-youd-travel-back-in-time-to-when-you-started-doing-vfx/20155
2. realtimevfx: "Getting Started in Real Time VFX? Start Here!" https://realtimevfx.com/t/getting-started-in-real-time-vfx-start-here/3415
3. realtimevfx: "Beginning VFX Artist: Advice for beginners, from a beginner" (Travis McCallum). https://realtimevfx.com/t/beginning-vfx-artist-advice-for-beginners-from-a-beginner/3081
4. Search results: realtimevfx sketch threads (critique examples, snippet). Via https://realtimevfx.com/t/about-vfx-sketch-challenges/762
5. realtimevfx: "Block-ins and Timing." https://realtimevfx.com/t/block-ins-and-timing/29830
6. VFX Apprentice: "The Soul of Effects: What is Timing in VFX?" https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx
7. VFX Apprentice: "10 Design Tips from the League of Legends VFX Style Guide." https://www.vfxapprentice.com/blog/10-league-of-legends-vfx-design-tips (original PDF: https://nexus.leagueoflegends.com/wp-content/uploads/2017/10/VFX_Styleguide_final_public_hidpjqwx7lqyx0pjj3ss.pdf)
8. Riot: "Clarity in League" (snippet). https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/ and https://nexus.leagueoflegends.com/en-us/2017/10/dev-leagues-vfx-style-guide/
9. 80.lv: "Gabriel Aguiar Prod. on Indie Game Dev and VFX for Beginners." https://80.lv/articles/gabriel-aguiar-prod-on-indie-game-dev-and-vfx-for-beginners
10. Skillsearch: "Pyxel-Perfect Portfolios #7: What does a Lead VFX Artist Expect in a Portfolio" (Bogdan Suman). https://www.skillsearch.com/news/item/pyxel-perfect-portfolios-whatdoesaleadvfxartistexpect
11. VFX Apprentice: "5 Ways to Make Your Visual FX Portfolio Stand Out." https://www.vfxapprentice.com/blog/5-ways-make-vfx-portfolio-stand-out
12. 80.lv: "Practical Tips for VFX Artists" (summary of Harry Alisavakis's X thread). https://80.lv/articles/practical-tips-for-vfx-artists
13. 80.lv: "VFX Staples: Shape, Color and Motion." https://80.lv/articles/vfx-staples-shape-color-and-motion/
14. 80.lv: "Real-Time VFX Overview from Keith Guerrette." https://80.lv/articles/real-time-vfx-overview-from-keith-guerrette
15. 80.lv: "Learning FX Workflow." https://80.lv/articles/learning-fx-workflow/
16. The Rookies: "Career Advice: Working as a VFX Artist in Games." https://www.therookies.co/blog/career-advice-working-as-a-vfx-artist-in-games/
17. 80.lv interview with Matt Schwartz on block-outs and early peer feedback (snippet, via 80.lv VFX search). https://80.lv/articles/vfx
18. realtimevfx: "VFX Art Tests: What does a great experience look like?" https://realtimevfx.com/t/vfx-art-tests-what-does-a-great-experience-look-like/13659
19. realtimevfx: "Learning R-VFX on the Internet | A Tutorial Rant." https://realtimevfx.com/t/learning-r-vfx-on-the-internet-a-tutorial-rant/4088
20. realtimevfx: "What type of VFX are a must have in a Portfolio?" https://realtimevfx.com/t/what-type-of-vfx-are-a-must-have-in-a-portfolio/26082
21. VFX Apprentice: "What Riot Games Head of Creative Looks For in VFX Artists" (snippet). https://www.vfxapprentice.com/blog/riot-games-head-creative-vfx-artist-needs
22. AWN: "Creating Better Animation Reference Using High Speed Video" (snippet). https://www.awn.com/print/blog/creating-better-animation-reference-using-high-speed-video
23. realtimevfx: "Inspirational resources for stylized effects." https://realtimevfx.com/t/inspirational-resources-for-stylized-effects/625
24. realtimevfx: "Releasing my League VFXs Fan-Arts for Study Purposes" (Sirhaian). https://realtimevfx.com/t/releasing-my-league-vfxs-fan-arts-for-study-purposes/1435
25. VFX Apprentice: "League of Effects" (free course). https://www.vfxapprentice.com/courses/league-of-effects
26. realtimevfx: "About the Monthly VFX Sketches." https://realtimevfx.com/t/about-the-montly-vfx-sketches/18659
27. realtimevfx: "About VFX Sketch Challenges" plus sketchbook threads (snippet). https://realtimevfx.com/t/about-vfx-sketch-challenges/762
28. Workable: Senior Real-Time VFX Artist job posting (snippet). https://jobs.workable.com/jobs/f7249a1e-0f73-4ce3-8e9d-38f24bd06874.md
29. 80.lv: "Real-Time VFX Overview from Mederic Chasse." https://80.lv/articles/real-time-vfx-overview-from-mederic-chasse/
30. 80.lv: "Tutorial: Muzzle Flash VFX in Godot" (Gabriel Aguiar, snippet). https://80.lv/articles/tutorial-muzzle-flash-vfx-in-godot; Udemy "Godot VFX for Games" (snippet). https://www.udemy.com/course/godot-vfx-for-games
31. Unity: "Free VFX image sequences and flipbooks" (CC0). https://unity.com/en/blog/engine-platform/free-vfx-image-sequences-flipbooks
32. Godot docs: Particle systems (3D). https://docs.godotengine.org/en/4.5/tutorials/3d/particles/index.html
33. 80.lv Godot tutorials (snippets): stylized fire shader https://80.lv/articles/learn-how-to-create-stylized-fire-shader-in-godot; VFX textures https://80.lv/articles/learn-how-to-create-cool-vfx-textures-with-this-detailed-tutorial; plasma ball https://80.lv/articles/learn-how-to-recreate-vfx-inspired-by-plasma-ball-lamps-in-godot/
34. Vefects on itch.io (Zap free pack, Master Bundle; snippet). https://vefects.itch.io/zap-vfx-unreal-engine and https://vefects.itch.io/vfx-master-bundle-pack-unreal-engine
35. Kenney: Particle Pack and Smoke Particles (CC0). https://kenney.nl/assets/particle-pack and https://kenney.nl/assets/smoke-particles; Godot Asset Library entry https://godotengine.org/asset-library/asset/784; Brackeys VFX bundle https://brackeysgames.itch.io/brackeys-vfx-bundle
36. 80.lv: "Get over 60 customizable stylized VFX for your Godot project" (BUKKBEEK). https://80.lv/articles/get-over-60-customizable-stylized-vfx-for-your-godot-project; Godot forum and itch.io VFX pack listings (snippet). https://itch.io/game-assets/tag-godot/tag-vfx
