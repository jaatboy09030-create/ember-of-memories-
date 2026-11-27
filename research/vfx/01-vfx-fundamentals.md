# 01 — VFX Design Fundamentals: What Separates Outstanding Game VFX from Average

*Research file 01 of the VFX knowledge base. Focus: art and design principles rather than tools. Godot-specific recipes are at the end.*

Notation: "(snippet)" means the claim comes only from a search-result snippet I could not open. "(analysis)" marks my own synthesis or recommended starting values that no single source states.

---

## 1. Key takeaways

- **Gameplay information comes first, beauty second.** Riot ranks clarity above theme. When League's VFX updates hit a conflict, "readability wins". Accurate hitbox indicators are the top priority [3][4]. Blizzard's Diablo IV team uses "Gameplay First" in the same way [12]. An effect that looks great but lies about its area or timing is a failed effect.
- **Attention should match importance.** Riot says the amount of attention an ability grabs should match its level of importance [3]. Ultimates may be loud. Basic attacks and ambient effects must stay quiet. Diablo IV raises visual intensity with skill power and lets weak skills "blend into the background" [12].
- **Solve shape and timing in greyscale before you polish.** The realtimevfx block-in threads and VFX Apprentice both say to block in the effect with simple shapes, simple shaders and no colour, then retime it until it feels good [6][8]. A simple shape is far easier to retime than a finished multi-emitter effect.
- **Think in intensity over time.** Ask how intensity rises and falls, not how each property animates. Most effects follow **anticipation → impact → dissipation**. The impact is fully active within roughly the first quarter of the effect's life, and it should never sit on a linear curve [7][8].
- **The brightest value is a budget.** Avoid absolute 0% black and 100% white. Paint the body of the effect in mid-values, and save the top values for the instant flash at the impact point or core [7]. Darker darks next to the whites make an effect read as damaging [6].
- **Layer the effect: primary, secondary, tertiary.** The primary layer carries the gameplay read with a clear silhouette and high opacity. The secondary layer supports motion and impact at lower value and with more transparency. The tertiary layer (sparks, motes, dust) is optional flavour that must never overpower the primary [7][16].
- **Shape language is communication.** Circles read as safe or friendly, triangles and spikes as dangerous, squares as stable [15]. That mapping comes from character design, so test it in play. Halo Infinite gives each weapon a different muzzle-flash shape so players can identify the weapon at range even when the palettes are similar [11].
- **Colour has no built-in meaning.** Make its meaning consistent within your own game. Shared palettes should reinforce shared mechanics [11]. Use one dominant hue plus a small, desaturated complementary accent [7]. Give VFX the widest saturation range in the game, and keep environment saturation low so effects cut through [7].
- **Borrow animation principles.** Use anticipation, follow-through, slow-in/slow-out, squash and stretch, and secondary motion [9][13][17]. Fast elements should stretch along their velocity, and an impact can be sold with a 1–2 frame spiky flash [16].
- **Shorter is almost always better.** "If your FX feel long, they're way too long" [7]. Lingering transparent particles clutter the screen and cost overdraw.
- **Critique at several scales.** Step through the effect frame by frame. Use a blur test to check that the large shapes read through the detail. Check the effect on every map and in every lighting condition [3][12][16].
- **Coherence beats isolated hero effects.** The gap between good and great work is often whether all the effects form one consistent system (snippet [20]).

---

## 2. Deep dive

### 2.1 The canon: who defined these fundamentals

- **GDC 2017, "Visual Effects Bootcamp: Artistic Principles of VFX".** Jason Keyser (Riot) and Hadidjah Chamberlin (Blizzard) gave this talk [5]. A community outline lists its sections as Gameplay First, Shape & Area of Effect, Contrast & Focal Point, Color & Identity, and Timing & Threat Level (snippet [5]). Keyser later posted a five-video series on realtimevfx.com. It was built from that talk and the League VFX style guide and covers shape, value, colour, timing, and how each ties back to gameplay [2].
- **League of Legends VFX Style Guide (Riot, 2017).** This is the most-cited public document on the subject. The PDF now redirects, but VFX Apprentice summarises its ten tips [7]. Its goals are, in order: clarity for gameplay, minimal clutter, emphasis on the focal point, and saturation and contrast as focus tools.
- **Riot "Clarity in League" and "Behind the scenes of VFX updates"** [3][4]. These set out the priority order: gameplay is conveyed, hierarchy is preserved, noise is minimal.
- **GDC 2018, "Zip! Thwack! Ping! Animation Principles of VFX".** Mike Lyndon (SideFX) applies Disney's 12 principles to effects. He focuses on the reasoning behind the sliders rather than the sliders themselves [9].
- **GDC 2024, "Attention Overload! Creating Readable VFX for Suicide Squad: KTJL".** Hanno Hinkelbein (Rocksteady) argues that readability problems start when VFX artists are left out of early design or features are finalised late [10].
- **GDC 2026, "Controlled Chaos: 12 Principles of Design for VFX".** Rachel Quitevis (Beyond-FX) gives a demonstration that turns a first-pass effect into a finished one (snippet [18]).
- **Other talks:** Blizzard's "World of Warcraft VFX Pillars" (Sarah Carmody) and Julian Love's GDC 2013 Diablo III effects talk (snippet [12b]). Keith Guerrette (founder of realtimevfx.com) has given overviews [14].
- **VFX Apprentice blog**, run by Jason Keyser. It covers timing and the artistic principles [6][7][8].

### 2.2 Shape language and silhouette

- **Shape is the first read.** It is often the quickest attribute for a player to perceive (snippet [15]). Bruno's advice on realtimevfx is to get the silhouette and motion right before the inner shapes. Adding internal texture detail does not fix a weak silhouette [19].
- **Meaning by shape (heuristic):**
  - circle: safe, friendly, healing, pickup;
  - triangle, spike or shard: danger, aggression, speed;
  - square or block: stable, defensive, a wall.
  - (analysis) Use the same language at every scale. A healing ring should be built from soft round blobs. A curse should be built from jagged shards, down to the individual sparks.
- **Directionality.** A projectile should show its travel direction even when it is not moving, for example with a blurred tail [3]. Without motion blur, put the highest brightness and sharpest contrast on the leading edge against dark, low-frequency values behind it. This pulls the eye forward [7].
- **Area-of-effect truth.** The silhouette of a ground decal or telegraph **is** the hitbox. Riot cites Arcane Comet's oversized circle as a spell that looks more dodgeable than it is [3]. In Halo Infinite, Fusion Coil explosion particles approximate the damage radius [11].
- **Clusters, not clouds.** Use clusters of small fragments that follow larger chunks [19]. Spawn debris in several directional bursts or cones, not in a uniform sphere with a point force. A ground explosion throws material up in roughly a 45° cone [16].
- **Hand-made over photographic.** Riot avoids photo textures and noisy procedural detail. It mixes soft and hard hand-painted shapes [7].

### 2.3 Timing: anticipation → impact → dissipation

VFX Apprentice's timing framework [8]:

- **Impulse.** Intensity spikes. It comes in two forms:
  - *Instant:* no wind-up, so it is punchy but the viewer cannot react.
  - *Crescendo:* a build-up the viewer can react to.
- **Rhythm.** Intensity varies without one spike:
  - *flowing:* loops such as campfires, waterfalls and pickups;
  - *disruptive:* staged changes.
- **Mixing is normal.** A fireball can use rhythm while charging, impulse on cast, rhythm in flight, and impulse on impact.
- **Heartbeat rule.** Pacing faster than about 60 BPM reads as aggressive. Slower pacing reads as calm or inviting, so keep a heal pulse under 60 BPM and run an attack faster.
- **Speed contrast.** Pair a fast element with a slow one. For example, a ring that expands quickly while the core shrinks slowly. The realtimevfx block-in thread shows a slow friendly spell turned into a fast damaging one by retiming alone [6].

The League guide's three-stage curve, as summarised in [7]:

1. **Anticipation / cast:** a short wind-up that warns the opponent.
2. **Impact / pop:** peak value and saturation, fully active within the first quarter of the lifespan.
3. **Dissipation / erosion:** a smooth fade. Particles dissolve cleanly and give the ground back.

**Frame counts.** No single authoritative table exists. These are the numbers the sources give:

- **Flash.** A spiky muzzle flash or flash light lasts **1–2 frames**, with the light radius about 2–3× the fireball [16]. Impact frames in animation are single frames followed by a return to normal (snippet [21]).
- **Hit flash.** Full strength on frame 0, then an exponential decay, finished in about **100–200 ms**. It should never ramp in (snippet [21]).
- **Hitstop.** Light weapons pause for **2–3 frames at 60 fps**. A Godot developer recommends 60–120 ms, about 4–7 frames, and says longer feels laggy (snippet [22]). Freeze the attacker and the target together.
- **Punch.** A punch that lands in 2 frames feels more powerful than one that takes 5 [13].
- **Telegraphs.** Telegraphed enemy attacks get longer wind-ups, and bigger attacks get longer ones still [13].

Working timing table at 60 fps (analysis; it synthesises the numbers above and should be tuned by eye):

| Effect | Anticipation | Impact peak | Dissipation | Total |
|---|---|---|---|---|
| Light melee hit spark | 0–2 f (none needed: the animation is the wind-up) | f0–f2 flash, 2–3 f hitstop | 8–15 f | ~0.25–0.3 s |
| Heavy hit / slam | 10–30 f charge glow (enemy: 30–60 f telegraph) | 1–2 f flash + 4–7 f hitstop | 20–40 f dust/smoke | ~1 s |
| Projectile muzzle | 0–4 f | 1–2 f spiky flash | 4–8 f smoke wisp | ~0.2 s |
| Enemy AoE telegraph | 0.6–1.5 s ground marker that fills in, ending exactly on damage | damage frame | 10–20 f | per design |
| Heal / buff | 15–30 f gather | soft peak, no white flash | 30–60 f, pulse < 1 Hz | 1–2 s |
| Ambient loop (embers, fog) | n/a (rhythm) | none | n/a | looping |

**Dissipation matters even for instant effects.** Fade the parts at different times so the effect has a graceful outro [8][16]. Watch the cost: dissipation that runs a few frames too long adds overdraw on low-end hardware [7]. In fighting games the effect must line up exactly with the damage frame [8].

### 2.4 Readability and gameplay clarity

**Signal vs. noise.** Riot's three-step priority is:

1. Gameplay is conveyed.
2. Hierarchy is preserved: the most important moment gets the most attention.
3. Noise is kept to a minimum.

Exception: spells with big gameplay impact may be noisy "to a degree" [3].

Riot's attention scaling [3]:

- **Damage.** Higher damage means brighter and more saturated, plus an audio cue beforehand (Zoe Q).
- **Hard crowd control.** A bright effect, an audio wind-up and a clear hitbox (Taric stun).
- **Dodgeability.** Never make a spell look easier to dodge than it is.
- **Direction.** Show it even on static frames.

**Hierarchy across the screen.** Diablo IV's lead VFX artist Daniel Briggs asks players to rank primary, secondary and tertiary reads [12]. Things that need immediate attention are highlighted, and environmental effects are present but stay out of the way. Effects must read "in all areas and lighting conditions". Briggs built a shader library that bends PBR on purpose, adding emissive light in dark dungeons where pure PBR would make effects disappear.

**Telegraphing.**

- God of War Ragnarök's parry cue is a growing yellow circle. It is deliberately non-diegetic, so it gives the same timing information for every enemy [11].
- Halo's Fusion Coils leak violently before they explode, and the speed of the leak signals that they are volatile [11].
- Telegraphs work best paired with an audio wind-up [3].

**Friend/foe colour coding.**

- Colour has no fixed meaning [11]. Players are, however, trained by convention: red for enemy or fire, blue for ice, green for healing, orange-red for gunpowder [7] (Overwatch commentary, snippet [23]).
- Choose a team convention and never break it. Many team games tint enemy ground telegraphs red and ally ones blue or green (analysis).
- Don't rely on hue alone, because of colour-blind players. Double the read with shape: friendly is round and soft-edged, hostile is spiky and hard-edged (snippet [23]; analysis).
- Within one hue family, distinguish effects by their accents. Ragnarök's Hex is magenta with black accents, and its Bifrost is indigo with rainbow accents [11].

**Clarity parity.** A skin or variant must be at least as readable as the base version [3].

**Placement.** Halo's muzzle flashes rarely overlap the crosshair, so they never hide the target [11].

### 2.5 Value and contrast inside an effect

- **Value range** [7]:
  - Avoid pure black and pure white so the effect does not merge with the UI or the world.
  - Use mid-values for the body.
  - Spike the top values only at the instant of the flash or the core.
  - A local emissive glow, or light cast on the ground, widens the apparent value range without changing textures. A fading glow can also show how much duration is left.
- **Hot core, falloff, dark accents (analysis, consistent with [7][17]).** A fire or energy effect reads as hot when value climbs toward the centre. Build the falloff from:
  - a near-white core (values above 1.0 in HDR, which bloom);
  - a saturated mid-ring;
  - a darker, desaturated edge, sometimes tipped with a dark accent.
  - Map colour by temperature. One realtimevfx critic suggests driving the colour with a blackbody lerp from 0 to 3,500 K. He also says real explosion light should be more desaturated yellow-orange than artists expect [16].
- **Dark elements sell bright ones.** The UE5 League-style explosion uses dark purple low-value particles and a "dark star" inside the bright impact. The darkest shades lean blue, the complement of the gold highlights [24]. Damage effects use darker darks next to the whites [6].
- **Saturation hierarchy.** Keep the environment low and muted, UI saturation local and controlled, and give VFX the widest and highest saturation range [7].
- **Complementary balance.** Use a dominant hue with a small accent. The accent should be desaturated and limited to highlights or low-frequency secondaries [7].
- **Noise frequency, not just contrast.** Too much high-frequency detail hides the low-frequency forms. Use a power-law distribution: a few large puffs for form, then fine detail on top. Check this with a blur test [16].

### 2.6 Layering: core, secondary, tertiary

| Layer | Job | Typical elements | Value / opacity |
|---|---|---|---|
| Primary (core) | Carries the gameplay read: where, how big, when | Flash, fireball core, telegraph decal, projectile head | Highest value and saturation, high opacity, clear silhouette |
| Secondary | Sells motion and impact | Shockwave ring, dark swirl, smoke body, ground dust | Lower value, smaller, more transparent |
| Tertiary | Grounds it in the world, adds richness | Sparks, embers, motes, debris, scorch decal, light | Small, brief; optional; must not overpower |

Sources: [7][16]; the forum layering debate is a snippet [25]. Whether dust counts as secondary or tertiary depends on how much it carries the read [25].

A good explosion, built from the realtimevfx critique [16]:

1. A spiky flash and light lasting 1–2 frames.
2. A fireball made of several flipbooks with randomised lifetimes.
3. A shockwave ring whose spawn radius expands on a curve, with drag.
4. Leader sparks that emit short-lived child sparks and inherit the parent's velocity.
5. Brown dust that lingers and sinks.
6. Grey smoke that rises.
7. Thin whitish-blue wisps from the crater.
8. A spiky, radial, dark scorch decal.

Each part fades at a different time.

Keep alpha stacking restrained. Too many overlapping alpha shapes turn the silhouette to mud in a team fight [7].

### 2.7 Motion principles from 2D animation

- **Anticipation.** Even a single frame of wind-up improves readability [13]. Make enemy wind-ups longer so players can react.
- **Squash and stretch.** Stretch fast elements along their velocity. A fireball that spawns perfectly round looks wrong [16]. More squash reads as rubbery and less reads as hard [13], so tune it to the material. Keep stretch brief on anything with collision.
- **Ease (slow-in/slow-out).** Don't let default curves decide the timing [8]. Impacts use **ease-out**, peaking on frame 0. Charges use **ease-in**. Halo's explosion grows on a **logarithmic** curve, fast at first and then lingering, so players can read the final radius [11].
- **Overshoot.** Scale a pop briefly past its target, about 110–120% (analysis), then settle. This gives rings, shields and UI bursts a snap. Riot's League-style projectile uses a star that shrinks from big to small against elements that expand [24].
- **Follow-through and secondary motion.** Use lingering smoke and embers that inherit velocity [16], and cloth or fur that keeps moving after the action [13].
- **Arcs.** Debris and sparks should fall on gravity arcs. Lowering the curl noise keeps sparks from swirling unnaturally [16].
- **Smears and holds.** Use stretch or smear frames for quick action, combined with anticipation (snippet [8b]). Hold a strong pose or frame briefly after a hit so the player can read it [13].

### 2.8 Scale and secondary motion

- **Size must match importance and fiction.** "A weak attack shouldn't look like an ultimate" [7]. A critic noted that one explosion's fireball read as huge while its overall size read like a grenade, and the mismatch broke the effect [16].
- **Scale non-uniformly.** When Diablo IV scales a skill up, artists adjust spawn rate, velocity, emissive strength and colour ranges by hand at every supported size [12].
- **Scale for distance.** God of War Ragnarök's fast-travel door particulates grow with camera distance. They stay visible from afar without swamping the player up close [11].
- **Size variation.** A lack of scale variation and directionality makes dust look fake more than any texture problem does [19].

### 2.9 How VFX artists critique effects

The habits that recur in realtimevfx feedback threads [6][16][19] and Riot's process [4]:

1. **Reference first.** Get real footage and step through it frame by frame next to yours [16].
2. **Strip it back.** Judge "pure composition": greyscale, simple shapes, timing only [6].
3. **Blur and squint tests.** Do the big shapes survive once the detail is blurred away [16]?
4. **Scale checks.** Is the size consistent with the fiction? Are the parts at matching texel density [16]?
5. **Noise check.** Is it too busy, and does it fire too often? Soften it and lower the frequency (snippet [25b]).
6. **Context check.** Check it on every map, in day and night lighting, from every camera angle, and next to other effects [3][12].
7. **Gameplay check.** Does the visual match the hitbox and the damage frame? Does its loudness match its importance [3][4]?
8. **Feedback quality.** Riot looks for actionable, objective, broadly agreed feedback rather than personal taste [4].

---

## 3. Examples

- **League of Legends.** VFX updates fix the hitbox indicator first, then readability and noise, then theme [4].
  - Taric's stun shows how to make crowd control read: a bright effect, an audio wind-up and a clean hitbox [3].
  - Skins are tiered by price, but none may be less clear than the base [3][4].
- **Halo Infinite** [11]:
  - Weapon-specific muzzle-flash shapes let players identify weapons at range.
  - Each damage type has its own palette: kinetic is yellow-orange, shock is pale to deep blue.
  - Fusion Coils telegraph with a violent leak, then explode on a log curve that roughly matches the damage radius.
- **God of War Ragnarök** [11]:
  - The non-diegetic yellow parry circle gives consistent timing for every enemy.
  - Atreus's shield stays readable in every biome.
  - Wisp Pillars use a tall purple glow to flag interactables.
  - Sluice whitewater and steam show the system state diegetically.
- **Diablo IV** [12]:
  - Lit PBR VFX that pick up sunlight or torchlight, with emissive cheats added in the dark for readability.
  - Whirlwind changed from a cylinder that ticked damage every few frames into an animated pie-slice payload.
  - Hit effects follow the direction of the attack.
- **Suicide Squad: KTJL.** An honest post-mortem of a four-hero, many-weapon game that drifted toward "total chaos on screen". Its lesson is to involve VFX artists in design early [10].
- **Hades / Hades II.** I found no Supergiant developer source. Player and critic commentary praises the first game's clarity and flags legibility problems with some Hades II boss telegraphs, such as Cerberus's stomps (snippet [26]). That shows how fast a dense, saturated style can tip into noise.

---

## 4. Common mistakes

1. **Linear curves everywhere.** Linear fades and linear growth feel mechanical. The impact must peak early with an ease-out [7][8].
2. **Ramping a hit flash in.** An impact has no wind-up, so the flash should be full on frame 0 (snippet [21]).
3. **Everything at max.** Every effect is bright, saturated and loud, so nothing stands out. This breaks the hierarchy [3][7].
4. **Pure white blowouts and big solid-white alpha areas** [7][16].
5. **Lying telegraphs.** The visual radius doesn't match the hitbox, or the timing doesn't match the damage frame [3][4].
6. **Effects that linger.** They clutter the screen and cost overdraw [7].
7. **Detail before form.** Polishing textures on a weak silhouette, or curl noise and high-frequency grain that hide the shape [16][19].
8. **Uniform spawning.** A sphere-shaped burst, uniform sizes and identical lifetimes. Randomise lifetime, size and direction, and spawn in clusters or cones [16][19].
9. **Scale mismatch** between elements, or between the effect and its fiction [16].
10. **Hue-only coding.** Friend and foe differ only by colour, which fails for colour-blind players (snippet [23]).
11. **Parts that don't inherit velocity.** Children counter-move against their parent [16].
12. **Retiming late.** Trying to fix timing after shaders and flipbooks are finished [6][8].

---

## 5. Apply in Godot 4 (4.7, Forward+, AgX, glow)

### 5.1 Greyscale block-in mode

Add a global debug toggle so every VFX shader can render as value only. Put a shader global in Project Settings → Shader Globals: `vfx_greyscale` (bool). In each custom VFX shader:

```glsl
global uniform bool vfx_greyscale;
// ... at end of fragment():
if (vfx_greyscale) {
    float v = dot(ALBEDO, vec3(0.2126, 0.7152, 0.0722));
    ALBEDO = vec3(v);
}
```

Toggle it with `RenderingServer.global_shader_parameter_set("vfx_greyscale", true)`. With colour gone, judge the shape, the value hierarchy and the timing (analysis; workflow from [6]).

### 5.2 Anticipation → impact → dissipation with curves

For a one-shot impact, use a `GPUParticles3D` with:

- `one_shot = true`
- `explosiveness = 1.0` for the flash and spark layers; about 0.6–0.8 for smoke
- `lifetime` per layer: flash 0.05 s, sparks 0.25–0.4 s, smoke 0.8–1.2 s
- `randomness` on lifetime: 0.3–0.5, so the parts fade at different times [16]

On the `ParticleProcessMaterial`:

- **`scale_curve` (CurveTexture).** For the flash: 1.0 at t=0, then an exponential drop to 0 by t=1. For the shockwave ring: start at 0.2, ease-out to 1.0 (log-like, after [11]). For a pop with overshoot: 0 → 1.15 at t≈0.15 → 1.0 at t≈0.3.
- **`alpha_curve`.** Full by t≈0.05, hold until about 0.25, then a smooth falloff. This keeps the peak within the first quarter [7].
- **`emission_curve`.** Multiplies the HDR brightness. Peak at t=0, fall fast. This is the hot core that blooms.
- **`color_ramp` (GradientTexture1D).** Run white-yellow → saturated orange → dark desaturated red-brown with low alpha. The dark accent sits at the end.

Separate the layers into child nodes: `Flash`, `Core`, `Ring`, `Sparks`, `Smoke`, `Dust`. Then mute any one of them to check what it contributes.

Stretch fast sparks along their velocity:

- `transform_align = TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY`;
- a quad mesh longer on Y;
- or drive Y-scale from velocity in a custom `shader_type particles`. The project already has one for the leaves.

### 5.3 Hot-core billboard shader (value-mapped colour)

```glsl
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D shape_mask : hint_default_black;           // greyscale hand-painted blob
uniform sampler2D heat_ramp : source_color, repeat_disable;  // dark edge -> sat mid -> white core
uniform float core_power = 2.5;   // > 1 tightens the hot core
uniform float hdr_boost = 3.0;    // > 1 feeds AgX + glow

void vertex() {
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
        INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);   // camera-facing billboard
}

void fragment() {
    float m = texture(shape_mask, UV).r * COLOR.a;   // COLOR = particle colour/alpha
    float heat = pow(m, core_power);                 // value climbs toward centre
    vec3 c = texture(heat_ramp, vec2(heat, 0.5)).rgb;
    ALBEDO = c * COLOR.rgb * mix(1.0, hdr_boost, heat * heat); // only the core goes HDR
    ALPHA = m;
}
```

Why this works (analysis):

- Only the highest-heat pixels go above 1.0, so glow blooms only the core.
- AgX pushes very bright values toward white, which gives a natural white-hot centre without pure-white blowouts across the whole body.
- Keep the ramp's left end dark and desaturated rather than black, as [7] advises.

The glow threshold in `Environment` (`glow_hdr_threshold`, about 1.0) decides what blooms. Keep the environment and the UI below it.

### 5.4 Flash light and hitstop

```gdscript
# One-shot impact flash: 1–2 frames of a big light, then gone [16].
func flash_light(at: Vector3, radius := 6.0) -> void:
    var l := OmniLight3D.new()
    l.omni_range = radius            # ~2–3x the fireball size
    l.light_energy = 8.0
    l.light_color = Color(1.0, 0.85, 0.6)  # desaturated warm, not pure orange
    l.shadow_enabled = false
    add_child(l); l.global_position = at
    var t := create_tween()
    t.tween_property(l, "light_energy", 0.0, 0.08).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
    t.tween_callback(l.queue_free)

# Hitstop: 2–3 frames for light hits, ~60–120 ms for heavy (snippet [22]).
func hitstop(duration := 0.05) -> void:
    Engine.time_scale = 0.0
    await get_tree().create_timer(duration, true, false, true).timeout  # ignore_time_scale
    Engine.time_scale = 1.0
```

### 5.5 Telegraph decal that tells the truth

- Use a `Decal` node, or a flat `MeshInstance3D` with an unshaded shader. Size it from the **same variable** the hit query uses, so the visual and the hitbox cannot drift apart [3][4].
- Drive a `fill` uniform from 0 to 1 over the wind-up with a tween, linear or ease-in. Fire the damage on the same frame `fill` reaches 1.0.
- Use a hard, spiky edge for enemy telegraphs and a soft, round edge for allied ones, so shape doubles the colour code.

### 5.6 Notes for *Unsent* (a melancholy, slow, dark game)

- **Rhythm over impulse.** The burning leaves and embers should be "flowing rhythm" pulsing under 60 BPM, so a flicker rate below 1 Hz on the main intensity [8]. Keep fast flicker for small tertiary embers only.
- **Dark accents.** In a dark scene the flame's body should sit in mid-values. Only the core should cross the glow threshold, and the smoke should be a dark desaturated accent rather than grey-white. That preserves mood and focus [7].
- **Layer audit for the leaf effect** (analysis):
  - primary: the leaf silhouette with the burn/dissolve edge;
  - secondary: the sub-emitter flame;
  - tertiary: sparse sparks and smoke.
  - If the flames read stronger than the leaf, lower the flame's emission curve.
- **Dissipation is where the mood is.** Use long, quiet fades where ash lingers and sinks, but cap the particle count and lifetime to limit overdraw [7].
- **Vefects fire.** Treat it as a value and timing reference. Run it through the greyscale toggle and match the custom shaders' value structure to it, so the pack and the hand-made effects read as one system [20].

---

## 6. Sources

1. Riot Games, "/dev: League's VFX Style Guide" (2017) — https://nexus.leagueoflegends.com/en-us/2017/10/dev-leagues-vfx-style-guide/ (now redirects; PDF: https://nexus.leagueoflegends.com/wp-content/uploads/2017/10/VFX_Styleguide_final_public_hidpjqwx7lqyx0pjj3ss.pdf — summarised via [7])
2. realtimevfx.com, "Artistic Principles of VFX" (Keyserito video series thread) — https://realtimevfx.com/t/artistic-principles-of-vfx/4081
3. Riot Games, "/dev: Clarity in League" — https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/
4. Riot Games, "/dev: Behind the Scenes of VFX Updates" — https://www.leagueoflegends.com/en-us/news/dev/dev-behind-the-scenes-of-vfx-updates/
5. GDC Vault, "Visual Effects Bootcamp: Artistic Principles of VFX" (Keyser & Chamberlin, GDC 2017) — https://www.gdcvault.com/play/1024439/Visual-Effects-Bootcamp-Artistic-Principles ; community outline (snippet): https://3dreference.notion.site/Visual-Effects-Bootcamp-Artistic-Principles-of-VFX-GDC-2017-fcd0698c31cf4621a70ed8a7621e17da
6. realtimevfx.com, "Block-ins and Timing" — https://realtimevfx.com/t/block-ins-and-timing/29830
7. VFX Apprentice, "10 Design Tips from the League of Legends VFX Style Guide" — https://www.vfxapprentice.com/blog/10-league-of-legends-vfx-design-tips ; also "The Must-Know Artistic Principles of Video Game VFX" — https://www.vfxapprentice.com/blog/five-artistic-principles-gaming-vfx
8. VFX Apprentice, "The Soul of Effects: What is Timing in VFX?" — https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx ; [8b] FX Timing Principles course page (snippet) — https://www.vfxapprentice.com/courses/fx-timing-principles
9. GDC Vault, "Visual Effects Bootcamp: Zip! Thwack! Ping! Animation Principles of VFX" (Mike Lyndon, GDC 2018) — https://gdcvault.com/play/1025301/
10. GDC Vault, "Attention Overload! Creating Readable VFX for Suicide Squad: Kill the Justice League" (Hanno Hinkelbein, Rocksteady, GDC 2024) — https://gdcvault.com/play/1034360/Attention-Overload-Creating-Readable-VFX
11. Game Developer, "VFX as Game Design Tools: The Ludology of VFX in God of War Ragnarök and Halo Infinite" — https://gamedeveloper.com/design/vfx-as-game-design-tools-the-ludology-of-vfx-in-god-of-war-ragnarok-and-halo-infinite
12. Blizzard, "Diablo IV Quarterly Update — December 2021" (VFX section by Daniel Briggs) — https://news.blizzard.com/en-us/article/23746639/diablo-iv-quarterly-updatedecember-2021 ; [12b] GDC Vault "World of Warcraft VFX Pillars" (snippet) — https://gdcvault.com/play/1029418/Visual-Effects-Summit-World-of
13. Game Developer, "The 12 Principles of Animation in Video Games" — https://www.gamedeveloper.com/production/the-12-principles-of-animation-in-video-games
14. 80.lv, "Real-Time VFX Overview from Keith Guerrette" — https://80.lv/articles/real-time-vfx-overview-from-keith-guerrette
15. Search results on shape language (snippets): Mighty Bear Games, "How UX design can help with VFX" — https://medium.com/mighty-bear-games/how-ux-design-can-help-with-vfx-a0925f80e0f0 (403 on fetch); Rocketbrush, "Shape language in game character design" — https://rocketbrush.com/blog/shape-language-in-game-character-design-how-to-make-characters-readable-and-consistent
16. realtimevfx.com, "Looking for feedback on Explosion VFX" (detailed critique thread) — https://realtimevfx.com/t/looking-for-feedback-on-explosion-vfx/29528
17. Game Developer, "12 Principles for Game Animation" — https://www.gamedeveloper.com/game-platforms/12-principles-for-game-animation
18. GDC 2026 schedule, "Controlled Chaos: 12 Principles of Design for VFX" (Rachel Quitevis; snippet) — https://schedule.gdconf.com/session/controlled-chaos-12-principles-of-design-for-vfx/914747
19. realtimevfx.com, "What Makes a Great Texture?" — https://realtimevfx.com/t/what-makes-a-great-texture/8060
20. Game Juice, "Particles & VFX: a practical system" (snippet) — https://gamejuice.pages.dev/articles/particles-vfx-practical-system
21. Hit-flash timing (snippets): gamedev.net "Hit flash and damage tint" — https://gamedev.net/shaderlab/36-hit-flash-and-damage-tint/ (403 on fetch)
22. Hitstop numbers (snippets): Godot Forum, "Game feel effects that stack…" — https://forum.godotengine.org/t/game-feel-effects-that-stack-without-fighting-your-code-trauma-shake-real-time-hit-stop-and-apply-the-difference/146379 ; "Game feel 2D combat juice tricks" — https://freegamesprites.com/es/news/game-feel-2d-combat-juice-tricks
23. Overwatch colour conventions (snippets): VFX Voice profile of Rachel Day — https://vfxvoice.com/?p=624080 ; Cook & Becker, "Designing Overwatch" — https://cookandbecker.com/en/article/378/designing-overwatch.html
24. 80.lv, "Creating League of Legends-Inspired Explosion VFX with UE5" — https://80.lv/articles/creating-league-of-legends-inspired-explosion-vfx-with-ue5
25. IndieDB, "Dev Log 04: VFX Break Down" (primary/secondary/tertiary debate; snippet) — https://www.indiedb.com/tutorials/dev-log-04-vfx-break-down ; [25b] realtimevfx "Looking for a Mentor" (snippet) — https://realtimevfx.com/t/looking-for-a-mentor/28373
26. Hades II legibility commentary (snippets): "Hades II Has a Legibility Problem" — https://nex-3.com/tag/hades ; 80.lv "A Behind-the-Scenes Look at the Effects in Hades" — https://80.lv/articles/a-behind-the-scenes-look-at-the-effects-in-hades
