# 03: Combat and attack VFX, and game feel

Topic: melee slashes and trails, hit sparks and impacts, hitstop, screen shake, ranged effects (muzzle flash, projectiles, explosions, shockwaves), telegraphs, damage numbers, hit flash and death dissolves, and how VFX, animation, sound and camera stack into "juice".

Tags used in this file:
- **(snippet)** marks a claim seen only in a search-result snippet; the page itself was not read.
- **(analysis)** marks my own reasoning or synthesis.
- Untagged claims come from pages I fetched and read.

---

## 1. Key takeaways

1. **An impact is a stack, not one effect.** A hit that "feels good" combines these, all landing on the same frame:
   - hitstop (both bodies freeze);
   - a hit pose or flinch;
   - a 1–2 frame white flash on the victim;
   - a spark or star burst at the contact point;
   - a short camera shake;
   - a bass-heavy sound with a high-frequency tail;
   - optionally rumble.

   Take any one layer out and the hit goes soft. The God of War 2018 analysis and the game-feel survey both describe it this way [4][10]. (analysis)
2. **Hitstop scales with hit strength.**
   - Street Fighter V reportedly uses 8, 12 and 15 frames for light, medium and heavy hits [1].
   - In Smash Ultimate, a 15%-damage hit gets 15 frames, and hitstop is capped at 30 frames [8].
   - Godot community recipes use 0.04–0.08 s for light hits and 0.10–0.18 s for heavy ones [13].
   - Use hitstop selectively. Devil May Cry 5 reportedly reserves it for heavy attacks so that light slashes still feel like they cut through [1].
3. **Freeze both bodies, and shake the victim during the freeze.**
   - Sakurai: both fighters freeze for the same duration. The victim vibrates, and the vibration starts large and shrinks across the freeze [9].
   - Grounded victims shake side to side; airborne victims shake up and down [9].
   - Freezing only the victim reads as a glitch. (analysis)
4. **Drive screen shake with "trauma", not random offsets.** This is Eiserloh's model from GDC 2016 [11][12]:
   - Trauma is a value from 0 to 1. Hits add to it and it decays linearly.
   - The visible shake is trauma² (or trauma³) multiplied by smooth noise, applied to offset and roll.
   - Smooth noise matters: per-frame `randf()` looks like static.
5. **Swipe meshes give control; ribbon trails are fast to set up.**
   - Hero slashes (anime action, Genshin-style, character-action games) are usually authored swipe meshes, with a panning, eroding texture and a gradient driven by UV.x.
   - Ribbons/anim-trails are "quick and dirty". Because they are built from animation-frame samples, they facet on fast swings: a 180° swing over 4 frames gives 4 hard segments [5][6].
6. **Every effect has build-up, climax and aftermath** [7].
   - Keep the frames before an impact clean, so the hit lands harder [7].
   - Elongated sparks that shrink to dots read as speed and power; round dots read as magic [7].
7. **Muzzle flashes are 1–2 frames long**, randomised from 4–8 variants, layered with a short light, sparks and lingering smoke [14].
8. **Readability beats spectacle in competitive and crowded games.**
   - Riot scales an effect's visual and audio weight by its gameplay importance (damage, crowd control, dodgeability) [15].
   - VALORANT shrank its headshot VFX so players can track enemies through it, and colours enemy fresnel red and ally fresnel blue [16][17].
9. **Telegraphs should match the real danger.**
   - Wind-ups need an audio cue as well as a visual one [15].
   - Ground indicators must match the true hitbox. VALORANT re-authored Raze's explosion VFX to show its hitbox more accurately and made it disappear faster (snippet) [17].
10. **Vlambeer-style feel comes from many small, cumulative tweaks.**
    - Nijman's "Art of Screenshake" turned a dull shooter into a good one with about 30 small changes [18], including:
      - a 1–2 frame white enemy flash and a few pixels of player recoil [10];
      - directional shake opposite the direction of fire [18];
      - permanence (bodies and shells stay on the ground);
      - occasional harmless death explosions (a 33% chance) [18].
11. **Separate time from feel in your engine.**
    - Global time scale freezes everything, including the timers that are meant to end the freeze.
    - Run the restore timer, flash tweens and shake decay in real time, and keep the code that writes `Engine.time_scale` in an autoload [13][19].
12. **Offer an accessibility setting.** Expose shake intensity and flash/impact-frame toggles. Players and Godot write-ups both ask for this [13][20].

---

## 2. Deep dive

### 2.1 The anatomy of a hit (timeline)

A synthesis across the sources [1][4][7][9][10] (analysis). At 60 fps, one frame is about 16.7 ms.

| t (frames @60) | Layer | Notes |
|---|---|---|
| −6 to 0 | Anticipation and swing; the trail starts as the swing gains momentum [7] | Keep the screen clean so the contrast is high [7]. |
| 0 | Contact. The victim snaps to its hit pose [4]. Spawn the spark burst, white flash, sound and shake. | All layers start on the **same frame**. Audio must not lag behind. |
| 0 to N | **Hitstop**. Attacker and victim hold; the victim jitters with decaying amplitude [9]. | N ≈ 3–5 (light), 8–12 (medium), 12–20 (heavy). SFV uses 8/12/15 [1]. |
| 0 to 2 | Victim flash at full white, then fade | Nijman: a 1–2 frame white sprite flash [10]. Godot recipes tween over 0.12–0.15 s [13][19]. |
| N | Release. Knockback impulse, spark particles fly out, the trail fades. | Knockback should be a velocity impulse that decays, not a teleport (snippet) [21]. |
| N to N+15 | Aftermath: dust, debris, a lingering glow, damage number | Floating sparks that rise, stop and hover longer suggest power [7]. |

Hitstop is a *visual* effect, distinct from hitstun (the gameplay stun). Sakurai describes it as conveying the force of the hit [9].

During the freeze, the attacker still creeps forward at a tiny speed, so the motion keeps a sense of resistance [9]. God of War's team made the same point: holding both bodies on the first frame of the hit pose "strongly emphasizes the connection of the swing" [4].

### 2.2 Hitstop numbers worth keeping

- **Street Fighter V:** 8, 12 and 15 frames for light, medium and heavy [1].
  - Capcom describes hit stop as usually a fixed amount per game, with 8 frames as its example (snippet; the page returned 403) [2].
- **Smash Bros. hitlag formulas** [8]:
  - Melee: `floor(d+3)`, capped at 20 frames.
  - Ultimate: `floor((d*0.65+6) * h * e * s)`, capped at 30 frames.
  - The electric multiplier is ×1.5. Crouch-cancel and shield multipliers are ×0.67.
  - Projectiles get less hitlag than melee hits [9].
  - The general pattern: a base value plus a fraction of damage, a cap, and multipliers by element and context. Copy it. (analysis)
- **DMC5:** hit pause only on heavy attacks [1].
- **God of War 2018:** a hit pause on every Kratos attack, to convey weight [1].
- **Bayonetta's Witch Time:** about 0.25 s of slowdown, not a pause [1].
- **Whole-game freezes:**
  - Hollow Knight freezes the whole game when the player takes damage [1].
  - SFV freezes on the start of a super, giving the player a beat to read it [1].
- **Godot community defaults:**
  - Light hits: 0.04–0.08 s. Heavy hits: 0.10–0.18 s [13].
  - Freeze scale: 0.0–0.2. One write-up recommends 0.05 instead of 0, so code never sees a zero `delta` [19].
- **A heuristic from tutorials:** 2–4 frames light, 5–8 medium, 12–20 heavy or finishers. Freezing on every small hit "feels sticky" (snippet; non-authoritative) [21].

### 2.3 Screen shake and camera kicks

**The trauma model** (Eiserloh, GDC 2016 [11]; constants from the Bevy reference implementation [12]):

- Trauma ∈ [0, 1]. Each event adds trauma (Bevy uses 0.4 per event) and the value is clamped.
- Trauma decays linearly. Bevy uses 0.5 per second, so full trauma lasts 2 s. That is long; combat games usually decay faster.
  - Godot recipes use decay 1.0–2.5 [13].
  - One example uses a start of 0.7 and decay 3.0/s, about 0.23 s in total [19].
- `shake = trauma ^ 2` (or ^3). Small hits barely register; big ones jump.
- Offsets come from smooth noise sampled at `time * speed`, with seeds offset for x, y and roll (+0, +100, +200). Bevy: noise speed 20, max translation 20 px, max roll 10°.
- Apply the shake after gameplay, then restore the transform, so game logic never sees it [12].
- **In 3D, prefer rotational shake** (yaw, pitch, roll) plus a small translation. Translation in 3D reveals parallax, while rotation reads like a handheld camera (analysis, consistent with Eiserloh's emphasis on rotational shake (snippet) [11]).

**Directional kicks beat random shake.**
- Nijman shakes the screen opposite to the direction of fire [18].
- The game-feel survey argues that shake should follow a "semantically meaningful direction" with easing [10].
- In Nuclear Throne, the camera also leads a few pixels toward the aim point (snippet) [18].

**Know when to cut shake.** God of War 2018 significantly reduced camera shake. The team accepted some loss of perceived impact in exchange for target legibility, and pushed the camera in close to sell force instead [4].

**More camera tools:**
- zoom punches (Tekken 7's extreme zoom on powerful attacks);
- tilts and pans on supers;
- shake that scales with attack strength and lasts for the length of the animation [1].

### 2.4 Melee: slashes and trails

**Three approaches:**

1. **Ribbon / anim-trail.** A ribbon is built from two sockets (blade base and tip) sampled each frame.
   - Fast to set up and camera-facing options exist [5].
   - Weaknesses [5]:
     - it facets when the animation has few frames per swing;
     - it breaks at uneven frame rates;
     - it lags behind fast weapons.
   - Use it for simple swings, thrown weapons and dashes.
2. **Swipe mesh.** An authored arc or crescent mesh, usually a flattened ring or disc segment, played by animating a shader parameter.
   - Gives total control over shape, density and timing. It is also forgiving of small misalignment on fast swings [5].
   - Downside: it must be re-made whenever the animation changes. Tools like Houdini curve-sweepers reduce the cost [5].
   - Most anime-style action games (Genshin, ZZZ, Honkai) use authored slash meshes with stylised gradients. ZZZ fan recreations in UE follow the same approach (snippet) [22]. (analysis)
3. **Particle "slash disk".** A mesh particle that spawns and rotates in place with a texture [23].
   - Good for spin attacks and a bank of reusable generic slashes.

**Shader recipe for a slash** [6]:
- **Gradient along UV.x:** take the TexCoord R channel as the gradient, and flip it with `1-x` so the bright head follows the blade.
- **Streak:** pan two noise textures and multiply them together. Multiply that by the gradient to shape the streak.
- **Edges:** mask the edges so the start cap is not hard-edged. Keep the trail no wider than the blade for short weapons.
- **Layers and lifetimes:**
  - the air trail has a 0.2 s lifetime and alpha fades over life;
  - two distortion trails at 0.2 s and 0.3 s add a motion-blur "volume";
  - a shorter life makes the weapon feel lighter.

**Layering and timing** [7]:
- Build a bright **core** with a softer **veil** around it, and control each layer's momentum on its own notify track.
- Use 3–4 virtual bones along the weapon as spawn anchors.
- Start the trail when the swing gains momentum and end it when the momentum dies.
- Panning alone looks like a static texture. Animate the pan speed and intensity with curves.

**Density goes at the head.** Put more density at the start of the trail, near the blade, so the eye tracks the weapon. Smooth the animation's arc first, because a trail exposes jerky curves [6].

**Trails slow perceived motion.** They act like animation smears, so in sword games remove them on hit [24].

### 2.5 Hit sparks and impact effects

**Contact sparks** [7]:
- Sparks are elongated along their velocity. They start long and shrink to dots, with drag so they decelerate hard.
- Two emitters work well together:
  - a fast radial spray on the hit plane;
  - a slower set that rises, stops and floats.

**Impact core** [7]:
- an energy flash at the core;
- a white shockwave ring layered with a tinted ring;
- surface damage (cracks with glow flowing in);
- debris and dust to ground it.

**Hit "stars" and flats.** Fighting and anime games use a 1–3 frame hand-drawn flash shape at the contact point, oriented along the hit direction. (analysis)

**Bayonetta** [25][26]:
- Hit effects were conceived early, around the idea of Okami-style petals flying off a hit (snippet) [26].
- Witch Time uses rotating crystal models coloured by lights. Its particle beams are a fine particle texture mapped onto a model and UV-scrolled, rather than thousands of separate particles [25].

**Sekiro's deflect** [27] (snippet; player perception, not developer documentation):
- The deflect spark is a gameplay signal: a perfect deflect gives a large orange-gold spark and a sharp metallic "ping"; a mistimed block gives a smaller, duller spark and a "klang".
- This is the cleanest example of VFX and audio encoding timing quality. (analysis)

### 2.6 Impact frames (anime style)

- **What they are:** 1–3 frames where the screen swaps to stark black and white or an inverted palette, often with radial speed lines (snippet) [28].
- **How they are built:**
  - In engines they are scripted post-process sequences.
  - One UE5 attack used seven one-frame post-process materials across a 12-frame sequence [29].
  - Roblox recreations layer speed lines, a black colour correction, a white silhouette on the character, then particles (snippet) [28].
- **How they are used:** ZZZ, Honkai Star Rail and Guilty Gear use them on ultimates, counter hits and finishers. Guilty Gear Strive pairs counter hits with slow motion and time distortion (snippet) [30].
- **Ready-made option for Godot:** Vefects publishes "Easy Impact Frames VFX" on the Godot Asset Store (snippet) [28].
- Keep impact frames rare: once per ultimate, not per hit. (analysis)

### 2.7 Ranged: muzzle flashes, projectiles, explosions, shockwaves

**Muzzle flash** [14]:
- A single flash stays on screen for 1–2 frames.
- Layers:
  - a circular core billboard;
  - directional "petal" billboards out the front and sides;
  - sparks (exaggerated beyond reality);
  - a short additive glow or point light;
  - smoke that appears just *after* the flash.
- Randomise from 4–8 flipbook frames, and give optional elements a spawn chance (a side flame at 50%). Pick among small, medium and large variants.
- Fresnel-fade billboards seen edge-on. Additive blending washes out on bright backgrounds.
- A hybrid of local space and world space with short lifetimes avoids flashes that smear or lag on a turning character.
- Keep separate first-person and third-person versions.

**Projectiles:**
- A projectile should show its direction of travel even when frozen, e.g. a blurred or tapered tail [15].
- Structure: a bright head, a trail (ribbon or stretched billboard) and an impact effect matched to the surface. (analysis)

**Explosions:**
- Order the layers: flash, fireball, then smoke, debris and shockwave.
- Reuse variants. One shipped game picks among three, including one with only the shockwave (snippet) [31].
- Most of the tuning time goes into timing and colour, so the explosion reads both up close and at a distance (snippet) [31].
- Vlambeer's lesson: make explosions bigger than seems reasonable, and leave permanent marks (scorch, smoke) [18][32].

**Shockwaves and distortion:**
- A refraction-only expanding ring that offsets screen UVs by a normal map or radial gradient, separate from the visible ring (snippet) [33].
- Run the ring over 0.2–0.4 s with the distortion strength fading as the radius grows. (analysis)

### 2.8 Telegraphs and charge-ups

- **Riot's hierarchy** [15]: an effect's visual and audio weight should scale with:
  - damage;
  - crowd control;
  - dodgeability (dodgeable spells deserve *more* attention);
  - gameplay impact.

  Big spells get an audio wind-up (Taric's stun, Zoe's Q). A ground indicator that implies more dodgeability than the spell allows is a bug.
- **Charge-ups** need visible discrete stages: particles converging inward, a growing core glow, a pitch-rising sound, and a "full" ping with a flash.
  - DMC5 gives partial credit for slightly mistimed presses, so charge feedback should show partial states [3].
  - (analysis for the stage breakdown)
- **Enemy telegraphs** in Souls-likes and Sekiro use:
  - a long, readable wind-up pose;
  - a glint or flash on the weapon at the commit frame;
  - a red kanji warning for unblockables (Sekiro).

  Put the glint 10–20 frames before contact so the player can react (analysis; typical human reaction time is roughly 200–250 ms).
- **Team colour coding:** VALORANT gives enemies a red fresnel and allies a neutral blue one. The fresnel is weighted to the upper body and boosted with distance [16]. Reactivatable placed abilities now share a teal colour (snippet) [17].

### 2.9 Damage numbers

- Damage numbers support other feedback and never replace it. Combat must still read with them turned off (snippet) [34].
- Guidelines (snippet) [34]:
  - outline the text;
  - colour-code by damage type, with heals in green that drift slower;
  - cap the number on screen (about 10);
  - keep normal hits plain and make crits pop.
- Recommended motion: a scale punch (start at 1.4–1.6×, ease-out to 1.0 over about 0.1 s), drift up 0.5–1 m, and fade out over the last 30% of a 0.6–0.9 s life. Add a small random x offset so stacked numbers don't overlap. (analysis)
- Hades, ZZZ and Genshin merge rapid multi-hits or stack them with a slight offset. (analysis)

### 2.10 Enemy hit flash and death dissolve

**Hit flash:**
- Mix the albedo/emission toward white for 1–2 frames, then fade over about 0.1–0.15 s [10][13][19].
- Keep the alpha, and use additive or emission so the flash survives lighting. (analysis)

**Hit flash in Hollow Knight:** a white flash on every hit is commonly cited, but the source is non-authoritative (snippet) [21].

**Health feedback:** Tekken-style health bars show the damaged chunk for about 1 s before draining, and the bar shakes during the hit reaction [1].

**Death:**
- dissolve with a noise threshold and a glowing edge (0.6–1.5 s);
- or a burst into particles;
- or ragdoll followed by a dissolve.

Doom-style chunking and glory kills turn death into feedback for the resource loop (snippet) [35]. (analysis)

### 2.11 Layering: the juice stack

- **Juice it or lose it** (Jonasson and Purho, GDC Europe 2012):
  - built a Breakout clone step by step: tweening with easing, squash and stretch, particles, screen shake, sound, and personality (eyes, smiles);
  - the survey cites it as the canonical step-by-step juicing demo [10]. (The step list is from my own background knowledge; the talk page was not fetched.)
- **Art of Screenshake** (Nijman, 2013), commonly cited steps (background knowledge plus [10][18], partly unverified):
  - animation and sound;
  - lower enemy HP;
  - a higher rate of fire;
  - bigger and faster bullets with some inaccuracy;
  - a muzzle flash;
  - impact effects;
  - a hit flash;
  - enemy knockback;
  - permanence (corpses, shells);
  - a camera lead toward the aim point;
  - screen shake;
  - player recoil;
  - "sleep" (a 10–20 ms freeze on hits);
  - more bass in the sounds;
  - random explosions;
  - meaningful deaths.
- **Sound design:** sound effects should be "full", with emphasised bass and mids, louder than the ambience, and lightly compressed [24].
  - God of War's axe impact is a low-end slam that ends in a high-frequency slash [4].
- **Survey evidence:** Kao's study found medium and high juiciness beat both the extremes and no juice [10].
  - So there is an optimum. Too much juice hides the information the effects are meant to give. (analysis)

---

## 3. Examples

| Game | Effect | Why it works |
|---|---|---|
| **God of War (2018)** | Hit pose plus a first-frame hold on every axe hit; heavy low-end sound with a high-frequency tail; little shake; close camera [1][4] | Weight comes from the pause and the sound, not from shaking, so targets stay legible. |
| **Street Fighter V / 6** | 8/12/15-frame hit stop; screen freeze on supers [1] | Consistent and learnable. The length of the freeze tells the player the strength of the hit. |
| **Smash Bros.** | Hitlag formula plus decaying victim vibration, horizontal on the ground and vertical in the air [8][9] | Systemic: every move gets the right weight without hand-tuning. |
| **DMC5** | Hit pause only on heavy hits [1]; partial charge success [3] | Light hits flow and heavy hits land. Responsiveness first. |
| **Bayonetta** | Witch Time: 0.25 s slowdown, crystal models plus UV-scrolled particle beams [1][25] | Time dilation marks the state change; cheap beams look dense. |
| **Hollow Knight** | Whole-game freeze when the player takes damage [1]; white flash on enemy hits (snippet) [21] | Pain is punctuated; hits read clearly at small sprite sizes. |
| **Sekiro** | Deflect spark size and colour plus "ping" vs "klang" [27] (snippet) | VFX and audio encode timing quality, so the player learns rhythm by ear. |
| **Hades** | Stylised boon VFX by Josh Barnett, with a distinct colour language per god [36] | Colour per god tells the player which effect is which during chaos. (analysis) |
| **Dead Cells** | Shake on ground slams and heavy hits; fighting games used as the reference for weapon impact (snippet) [37] | Each of 50 weapons gets its own impact signature. |
| **Nuclear Throne / Vlambeer** | Shake opposite the direction of fire; camera leads toward the aim; recoil; permanence [18] | Every shot moves the world a little. |
| **VALORANT** | Red/blue fresnel; smaller headshot VFX; hitbox-accurate Raze explosions [16][17] | Clarity is the feature in a competitive shooter. |
| **League of Legends** | Effect weight scales with damage, crowd control and dodgeability; audio wind-ups on big spells [15] | Telegraphs are honest. |
| **ZZZ / Honkai Star Rail / Guilty Gear Strive** | Impact frames, counter-hit slow motion, authored slash meshes [22][28][30] (snippet) | Borrow anime cinematography, but only on the big moments. |
| **Doom Eternal** | Weak points break off chunks; glory kills feed the resource loop (snippet) [35] | Damage is visible on the body, and feedback is also a reward. |

---

## 4. Common mistakes

1. **Hitstop on everything.** Combat feels sticky and DPS weapons stutter. Scale the freeze by strength, or skip it on light and multi-hit attacks [1][21].
2. **Freezing only the victim, or the whole world, by accident.** Freeze the attacker and the victim (or the global time scale for heavies) on purpose [9][21].
3. **A freeze that never ends.**
   - Restore timers that run in scaled time can't finish: at a time scale of 0.05, 0.08 s becomes 1.6 s.
   - Restore code that lives on an enemy that gets freed never runs.
   - Two overlapping hits can restore the time scale too early [19].
4. **Random-per-frame shake.** It looks like static. Use smooth noise with trauma² [11][13].
5. **Too much shake in 3D or first-person.** It causes motion sickness and hides targets. Prefer short rotational kicks, and offer a slider [4][20].
6. **Layers that don't sync.** A spark that spawns one frame late, or audio that lags, ruins the impact. Trigger everything from one hit event. (analysis)
7. **Ribbon trails on low-frame animation.** They facet. Subsample, or switch to a swipe mesh [5].
8. **Hard-edged or overly wide trails.** Mask the start cap and match the blade's width [6].
9. **Lingering muzzle flashes.** More than 2 frames reads as a flamethrower [14].
10. **Additive blending on bright scenes.** It washes out to white. Use premultiplied or screen-like blending, or darker cores [14].
11. **Dishonest telegraphs.** The indicator doesn't match the hitbox, or the effect outlives the damage [15][17].
12. **Effects that hide the target.** Oversized hit VFX on the enemy's head (VALORANT fixed this) [17].
13. **Damage-number walls in AoE fights.** Cap them, merge them, or make them optional [34].
14. **Ignoring sound.** VFX without a punchy, bass-weighted sound feels weightless [3][24].

---

## 5. Apply in Godot 4

Context: Godot 4.7, Forward+, AgX, glow on.

*Unsent* is a slow first-person narrative game, so tone everything down: a soft 40 ms hitstop on a dramatic moment, rotational shake under 1°, no impact frames. The recipes below are general. (analysis)

### 5.1 Hitstop autoload (real-time restore)

Based on [13][19]. The 4th argument of `create_timer` is `ignore_time_scale`.

```gdscript
# hit_stop.gd: add as Autoload "HitStop"
extends Node
var _gen := 0

func stop(seconds := 0.08, scale := 0.05) -> void:
    _gen += 1
    var my_gen := _gen
    Engine.time_scale = scale          # assign; never *= (compounds)
    await get_tree().create_timer(seconds, true, false, true).timeout
    if my_gen == _gen:
        Engine.time_scale = 1.0

# Usage: HitStop.stop(0.05) light, HitStop.stop(0.12) heavy, HitStop.stop(0.18, 0.0) finisher
```

Notes:
- **Audio:** `AudioStreamPlayer` ignores `time_scale` [19], so impact sounds play through the freeze. That is what you want.
- **Shaders:** the `TIME` built-in follows the time scale. Pass a real-time uniform if a glow must keep pulsing.
- **Freezing only the participants:** for a local freeze instead of a global one, set the attacker's and victim's `AnimationPlayer.speed_scale = 0` (or `AnimationTree` time scale) and pause their `velocity` for N frames. Leave the rest of the world running. Smash and SFV-style freezes work this way. (analysis)
- **Victim jitter:** while frozen, offset the victim's mesh (not its collider) by `sin(t*60)*amp`, with `amp` decaying to 0 over the freeze [9].

### 5.2 Trauma shake for Camera3D

`h_offset` and `v_offset` move the view without touching the transform, so gameplay raycasts are unaffected. Roll goes on a child pivot.

```gdscript
# shake_cam.gd: on a Node3D pivot that is the parent of Camera3D
extends Node3D
@export var max_yaw := 1.5      # degrees (FPS: keep 0.5–2)
@export var max_pitch := 1.5
@export var max_roll := 2.0
@export var max_offset := 0.04  # metres, via Camera3D h/v_offset
@export var decay := 1.8        # trauma per real second
@export var noise_speed := 25.0
var trauma := 0.0
var _noise := FastNoiseLite.new()
var _t := 0.0
var _last_us := Time.get_ticks_usec()
@onready var cam: Camera3D = $Camera3D

func add_trauma(a: float) -> void:
    trauma = clampf(trauma + a, 0.0, 1.0)

func _process(_d: float) -> void:
    var now := Time.get_ticks_usec()
    var real_dt := (now - _last_us) / 1_000_000.0   # keeps shaking during hitstop
    _last_us = now
    _t += real_dt * noise_speed
    trauma = maxf(trauma - decay * real_dt, 0.0)
    var s := trauma * trauma
    rotation_degrees = Vector3(
        max_pitch * s * _noise.get_noise_1d(_t),
        max_yaw   * s * _noise.get_noise_1d(_t + 100.0),
        max_roll  * s * _noise.get_noise_1d(_t + 200.0))
    cam.h_offset = max_offset * s * _noise.get_noise_1d(_t + 300.0)
    cam.v_offset = max_offset * s * _noise.get_noise_1d(_t + 400.0)
```

Settings and usage:
- Set `_noise.frequency` to about 0.5.
- `FastNoiseLite` returns values in about [-1, 1]; multiply by 1.5–2 if the shake feels weak.
- Trauma presets: 0.25 for a light hit, 0.5 for a heavy one, 0.8 for an explosion.
- For a directional **kick** (recoil), tween `rotation_degrees.x` by −1.5 to −3° over 0.04 s, then ease back over 0.15 s with `TRANS_EXPO, EASE_OUT`.
- Add rumble with `Input.start_joy_vibration(0, 0.3, 0.6, 0.12)`.
- Scale all amplitudes by a settings value `shake_intensity` (0–1).

### 5.3 Hit flash without touching materials (`material_overlay`)

```glsl
// hit_flash_overlay.gdshader
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;
void fragment() {
    ALBEDO = flash_color.rgb * flash * 2.0; // >1 so glow catches it under AgX
}
```

How to use it:
- On hit, set `mesh.material_overlay = flash_mat` and set `flash = 1`.
- Hold for 2 frames, then tween `shader_parameter/flash` to 0 over 0.12 s using `tween.set_ignore_time_scale(true)`, then clear the overlay [19].
- For skinned meshes, `material_overlay` on the `MeshInstance3D` works with skeletons. (analysis)
- Use a tinted `flash_color` for crits, poison and similar. Keep pure white for the generic hit.

### 5.4 Swipe-mesh slash shader

Mesh: a flat arc/crescent made in Blender, with UV.x running along the arc (0 = tail, 1 = head) and UV.y across its width. Per the project rules, model in Blender. Animate `progress` 0→1 over the swing (4–8 frames) with an `AnimationPlayer` track keyed to the attack animation.

```glsl
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D noise_a : repeat_enable;
uniform sampler2D noise_b : repeat_enable;
uniform vec4 core_col : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform vec4 edge_col : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float progress : hint_range(0.0, 1.2) = 0.0; // head position along UV.x
uniform float length_ = 0.6;                          // tail length in UV
uniform float erosion : hint_range(0.0, 1.0) = 0.0;   // ramp 0→1 after the swing
uniform float intensity = 3.0;
void fragment() {
    float head = progress;
    float g = clamp((UV.x - (head - length_)) / length_, 0.0, 1.0); // 0 tail → 1 head
    g *= step(UV.x, head);                                           // nothing ahead of blade
    float across = 1.0 - abs(UV.y * 2.0 - 1.0);                      // soft across-width
    float streak = texture(noise_a, UV * vec2(1.0, 2.0) + vec2(-TIME * 2.0, 0.0)).r
                 * texture(noise_b, UV * vec2(0.5, 1.0) + vec2(-TIME * 3.1, 0.0)).r * 2.0;
    float m = g * g * smoothstep(0.0, 0.35, across) * streak;
    m = smoothstep(erosion, erosion + 0.15, m);                      // dissolve-out
    vec3 c = mix(edge_col.rgb, core_col.rgb, smoothstep(0.5, 1.0, across * g));
    ALBEDO = c * m * intensity;
}
```

Notes:
- `g*g` concentrates density at the blade [6].
- Two multiplied pans make the streak [6].
- Fade `erosion` from 0→1 over about 0.15 s after contact for the aftermath.
- To add a **distortion layer**, duplicate the mesh with the screen-texture refraction shader from 5.6 at lower strength. That gives the 0.2/0.3 s distortion trails [6].

### 5.5 Ribbon trails with GPUParticles3D

Use these for quick trails (dash, thrown weapon, projectile).

Node setup:
- `GPUParticles3D` → enable `trail_enabled`, set `trail_lifetime = 0.15–0.25`, `amount = 1`, `lifetime ≈ trail_lifetime`.
- `local_coords = false` (world-space trail).
- Draw pass: `RibbonTrailMesh` (flat) or `TubeTrailMesh`, with `sections` set to 8 or more for smoothness.
- Material: enable `use_particle_trails` (StandardMaterial3D: Transform → Use Particle Trails), unshaded, additive, with a horizontal gradient texture. In a custom shader, the trail's UV.x behaves like the gradient above.
- Raise `fixed_fps` (e.g. 60 or 0 = uncapped) on the particles so fast swings don't facet [5].

For blade trails driven by two sockets, a small `ImmediateMesh` script that records (base, tip) positions each frame and Catmull-Rom subsamples between frames is more controllable than particles. It removes the faceting problem [5]. (analysis)

### 5.6 Shockwave and heat distortion (screen texture)

```glsl
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D normal_noise : hint_normal, repeat_enable;
uniform float strength = 0.03;   // animate → 0 as ring expands
uniform float ring_width = 0.15;
uniform float radius : hint_range(0.0, 1.0) = 0.5; // on a quad, UV-space ring
void fragment() {
    float d = distance(UV, vec2(0.5));
    float ring = smoothstep(radius - ring_width, radius, d) * (1.0 - smoothstep(radius, radius + 0.02, d));
    vec2 n = texture(normal_noise, UV * 2.0).xy * 2.0 - 1.0;
    vec2 dir = normalize(UV - vec2(0.5) + 1e-4);
    vec2 off = (dir * 0.7 + n * 0.3) * ring * strength;
    ALBEDO = textureLod(screen_tex, SCREEN_UV + off, 0.0).rgb;
}
```

- Put this on a camera-facing quad or a flat ground disc.
- Tween `radius` from 0.05 to 0.5 and `strength` from 0.04 to 0 over 0.3 s, using `TRANS_QUART, EASE_OUT`.
- Layer it under a thin additive white ring that is visible for only about 3 frames [7].

### 5.7 Muzzle flash and explosion recipe

**Muzzle flash** [14]:
- **Flash:** `GPUParticles3D`, `one_shot = true`, `explosiveness = 1`, `amount` 1–3, `lifetime = 0.035` (about 2 frames).
  - Billboard flipbook with 4 variants, random frame via `anim_offset_max = 1`, random rotation and scale 0.8–1.3.
  - Use local coordinates for the first-person view model.
- **Light:** `OmniLight3D` with energy 4–8, range 3–5, warm colour, shadows off. Show it for 1 frame, then hide it.
- **Sparks:** 6–12 stretched particles (velocity-aligned billboards or `particle_flag_align_y`) with a lifetime of 0.1–0.2 and damping.
- **Smoke:** start 1–2 frames late, with a lifetime of 0.6–1.2 s, in world space.

**Explosion:**
- Order: flash (2 frames), fireball flipbook (0.3–0.5 s), smoke (2–4 s), debris sub-emitter, shockwave (5.6), a scorch decal (permanence [18]), plus `add_trauma(0.6–0.8)` scaled by distance.
- For anything over about 1.0 in emission, rely on glow. Under AgX, push emission colours to 2–6× HDR so glow blooms without clipping to flat white. (analysis)

### 5.8 Damage numbers

- Use a pooled `Label3D` with:
  - `billboard = BILLBOARD_ENABLED`, `no_depth_test = true`, `fixed_size = true` (pixel_size about 0.0008);
  - `outline_size` 8–12 and a dark `outline_modulate`.
- Spawn at the hit point with a random x jitter of ±0.15 m.
- Tween with `set_ignore_time_scale(true)`:
  - scale 1.5→1.0 over 0.08 s (`TRANS_BACK, EASE_OUT`);
  - `position.y` +0.8 over 0.7 s (`EASE_OUT`);
  - `modulate.a` 1→0 over the final 0.25 s.
- Cap the pool at about 10 active labels and merge hits on the same target within 0.1 s [34].

### 5.9 Death dissolve: reuse the burn shader

Unsent already has a burn/dissolve shader. For combat deaths, drive its threshold from 0→1 over 0.8–1.2 s after the ragdoll settles:
- emissive edge colour at 3–5× HDR;
- emit embers from the surface with a `GPUParticles3D` whose `emission_shape = EMISSION_SHAPE_POINTS`, using points baked from the mesh (or `MESH` with an emission mesh).

The existing falling-leaf sub-emitter pattern (a particle shader plus a flame sub-emitter) maps directly onto "body breaks into burning motes". (analysis)

### 5.10 Impact frames (use sparingly)

- Use a full-screen `ColorRect` on a `CanvasLayer` (layer 100) with a `canvas_item` shader that reads `hint_screen_texture`.
- For one frame, output `step(0.45, luminance)` (black and white). For the next frame, output it inverted. Then disable the rect.
- Combine with `HitStop.stop(0.1, 0.0)` and a radial speed-line texture.
- Vefects' "Easy Impact Frames VFX" pack exists for Godot (snippet) [28]. As with the existing Vefects fire pack, keep the asset out of git per the project licence rule.
- Add a photosensitivity toggle that replaces the inversion with a dim vignette. (analysis)

### 5.11 One "hit event" to rule them all

```gdscript
# combat_feedback.gd: autoload; every damage source calls this once
func on_hit(pos: Vector3, normal: Vector3, target: Node3D, strength: float) -> void:
    var tier := 0 if strength < 0.34 else (1 if strength < 0.67 else 2)
    if tier > 0: HitStop.stop([0.0, 0.07, 0.14][tier])
    Fx.spawn_sparks(pos, normal, tier)          # pooled GPUParticles3D, restart()
    Fx.flash(target)                             # 5.3
    Cam.add_trauma([0.15, 0.3, 0.55][tier])      # 5.2
    Sfx.play_at("hit_%d" % tier, pos)            # same frame; bass-heavy for tier 2
    Ui.damage_number(pos, strength)              # 5.8
```

All layers fire from one call on the same frame. That is the single most important rule in this document [1][4]. (analysis)

---

## 6. Sources

1. Jason de Heras, thread on hit pause, freezes, slowdown and camera (SFV, DMC5, GoW, Bayonetta, Hollow Knight, Tekken 7). https://threadreaderapp.com/thread/1385104062157254660
2. Capcom, SFV "SF Seminar" column on hit stop (page returned 403; snippet only). https://game.capcom.com/cfn/sfv/column/131545?lang=en
3. Kotaku, "Devil May Cry 5's director tells us how they made combat". https://kotaku.com/devil-may-cry-5s-director-tells-us-how-they-made-combat-1833642299
4. PlayStation Blog, "Game developers explain what makes God of War (2018)'s combat tick". https://blog.playstation.com/?p=370399
5. RealtimeVFX, "UE4 – Weapon slash: Meshes vs AnimTrail Data". https://realtimevfx.com/t/ue4-weapon-slash-meshes-vs-animtrail-data/5628
6. Edgeless Corner, "VFX of Combat Attack Trails". https://edgelesscorner.blogspot.com/2019/04/vfx-of-combat-attack-trails.html
7. 80.lv, "Trail & Impact VFX Production". https://80.lv/articles/trail-impact-vfx-production
8. SmashWiki, "Hitlag". https://ssbwiki.com/Hitlag
9. Source Gaming, "Thoughts on Hitstop" (Sakurai, Famitsu column vol. 490). https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/
10. Pichlmair and Johansen, "Designing Game Feel: A Survey" (arXiv 2011.09201). https://ar5iv.arxiv.org/html/2011.09201
11. Squirrel Eiserloh, "Math for Game Programmers: Juicing Your Cameras With Math", GDC 2016. https://gdcvault.com/play/1023146/Math-for-Game-Programmers-Juicing (video: https://www.youtube.com/watch?v=tu-Qe66AvtY)
12. Bevy example, "2D screen shake" (trauma implementation). https://bevy.org/examples/camera/2d-screen-shake/
13. Godot Forum, "[Tutorial] Hit-stop and screen shake in Godot 4 (autoload + trauma camera, MIT)". https://forum.godotengine.org/t/tutorial-hit-stop-and-screen-shake-in-godot-4-autoload-trauma-camera-mit/145240
14. RealtimeVFX, "Wondering how good muzzle flashes are made". https://realtimevfx.com/t/wondering-how-good-muzzle-flashes-are-made/13540
15. Riot Games, "Clarity in League". https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/
16. Riot Games Tech, "VALORANT Shaders and Gameplay Clarity". https://www.riotgames.com/en/news/valorant-shaders-and-gameplay-clarity
17. PC Gamer, "Here's how to read Valorant's hit effects…" and esports.gg patch 10.10 / 11.07 notes (snippets). https://www.pcgamer.com/heres-how-to-read-valorants-hit-effects-following-the-latest-patch ; https://esports.gg/news/valorant/valorant-patch-notes-10-10-razes-explosion-vfx-update-masters-toronto-pickems-and-more/
18. Game Developer, "Vlambeer co-founder shares advice on building better action games" (Art of Screenshake). https://gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games
19. Uhiyama Lab, "Godot Hitstop Basics: Slow Time Only at the Moment of Impact". https://uhiyama-lab.com/en/notes/godot/hit-feedback-hitstop/
20. DEV Community, "The Art of Screen Shake" (intensity tiers, accessibility slider). https://dev.to/selfish_dev/the-art-of-screen-shake-33bi
21. Search snippets from coddy.tech "hit stop" and freegamesprites "game feel 2d combat juice tricks" (non-authoritative). https://coddy.tech/learn/pygame/sound_and_game_feel/hit_stop ; https://freegamesprites.com/ar/news/game-feel-2d-combat-juice-tricks
22. 80.lv, "Check out this fancy real-time attack VFX for Zenless Zone Zero animation" (snippet). https://80.lv/articles/check-out-this-fancy-real-time-attack-vfx-for-zenless-zone-zero-animation
23. Roblox DevForum, "Crescent Sword Slash Effect" (snippet). https://devforum.roblox.com/t/crecent-sword-slash-effect/1113871
24. Game Developer, "Squeezing more juice out of your game design". https://gamedeveloper.com/design/squeezing-more-juice-out-of-your-game-design-
25. PlatinumGames blog, Bayonetta 3 Witch Time / Demon Masquerade VFX (Takahiro Yasuda). https://platinumgames.com/official-blog/article/13708
26. PlatinumGames, interview with Takuo Yamamoto (head of VFX), plus the Bayonetta hit-effect blog snippet. https://www.platinumgames.com/interview/takuo-yamamoto
27. Sekiro deflect feedback: SuperJump, "The Art and Science of Sekiro's Combat", and the r/Sekiro thread (snippets). https://www.superjumpmagazine.com/the-art-and-science-of-sekiros-combat/
28. Impact-frame snippets: Godot Asset Store, Vefects "Easy Impact Frames VFX"; Roblox DevForum "Advanced impact frames". https://store.godotengine.org/asset/vefects/easy-impact-frames-vfx/ ; https://devforum.roblox.com/t/advanced-impact-frames/2468478
29. 80.lv, "My Hero Academia-style attack VFX in Unreal Engine 5". https://80.lv/articles/my-hero-academia-style-attack-vfx-in-unreal-engine-5/
30. "What does Guilty Gear Strive do right?" (Substack) and Dustloop attack attributes (snippets). https://gamesoftrobo.substack.com/p/what-does-guilty-gear-strive-do-right
31. PC Gamer, "How great game explosions are made" (snippet). https://www.pcgamer.com/how-great-game-explosions-are-made
32. Pichlmair and Johansen survey PDF (alt). https://arxiv.org/pdf/2011.09201
33. RealtimeVFX, "Brais' Sketchbook" (refraction-only shockwave) and "Radial Screen Space Distortion" (snippets). https://realtimevfx.com/t/brais-sketchbook/31406 ; https://realtimevfx.com/t/cels-sketchbook/8069/5
34. Damage-number practice: gamejuice "damage numbers satisfying feedback" and the Unreal forum "Damage text on hit – best practice" (snippets). https://gamejuice.pages.dev/articles/damage-numbers-satisfying-feedback ; https://forums.unrealengine.com/t/damage-text-on-hit-best-practice/2671681
35. Game Developer, "The aggressive resource management of Doom Eternal" (snippet). https://www.gamedeveloper.com/design/the-aggressive-resource-management-of-i-doom-eternal-i-
36. 80.lv, "A behind-the-scenes look at the effects in Hades". https://80.lv/articles/a-behind-the-scenes-look-at-the-effects-in-hades
37. PC Gamer, "Dead Cells' combat evolved from tower defense games and Team Fortress 2" (snippet). https://www.pcgamer.com/dead-cells-combat-evolved-from-tower-defense-games-and-team-fortress-2
