# 09 — VFX integration: lighting, post-processing, camera, sound, animation, haptics and UI

*What makes an effect feel like part of the world, not a sticker on top of it.*

---

## 1. Key takeaways

- **An effect is a bundle of events, not a particle system.** Celeste's dash (from the shipped `Player.cs`) fires the following *on one frame*: a 0.05 s freeze, a screen-space displacement ring, a directional screen shake along the dash vector, a strong controller rumble, a slash sprite burst and an afterimage trail. Take any one away and the dash feels weaker [1]. A Unity primer makes the same point. Flash, hit-stop, shake and sound each *carry a piece of information*: it landed, it mattered, how hard it was [12].
- **Everything lands on the impact frame.** Anticipation happens in the character's animation, before the hit. The VFX, the sound transient, the light flash, the hit-stop and the rumble all start on the same frame. After that comes a slow release: debris, smoke, scorch and embers. (analysis, built from [1][2][12])
- **Hit-stop is the strongest single tool.** God of War (2018) snaps the target to its hit pose and holds *both* Kratos and the target on that first frame for a moment [2]. Typical values are 0.03–0.15 s depending on weight [12]. Celeste uses 0.05 s for a dash and 0.1 s for an explosion launch [1]. Sakurai caps the maximum freeze, so huge hits never stall the game for too long [7].
- **Wider camera, less shake? Then pay it back in audio and animation.** God of War pulled its camera back and cut camera shake "significantly". The impact it lost was won back with heavier sound and bigger pose changes [2].
- **Shake should come from trauma, not random jitter.** Store trauma from 0 to 1 and let it decay. Offset = trauma² × max, with the direction sampled from smooth noise. Clamp trauma so mass kills can't throw the camera around [9][10]. Make shakes directional where you can: Celeste shakes along the dash direction [1].
- **Emissive light doesn't light the world.** Fake it with a short-lived light. A surface that glows only lights itself [14]. A flash needs a real light (OmniLight or SpotLight) for a few frames, with **no shadows** and a small range, and it should stay **out of volumetric fog** when temporal reprojection is on. Otherwise it leaves ghost trails [16][17].
- **Bloom is decided by luminance, and the tonemapper decides the colour of the core.** Pure magenta or blue emissive blooms badly because luminance weights are 0.21 R, 0.72 G and 0.07 B [14]. Aggressive tonemappers bleach hot cores to white; AgX keeps hue best in Godot [13][15]. Author emissive *well above* the scene's brightest reflective highlight, or the bloom can't be isolated to it [14].
- **Readability before spectacle.** Doom ranks effects by importance: muzzle flashes and impacts are brighter and bigger, while ambient embers and mist sit back [5]. Halo Infinite keeps muzzle flashes off the crosshair and sizes explosions to their actual damage radius [6]. God of War Ragnarök gives look-alike status effects different hue and accent colours [6].
- **The world reacts, so the world feels real.** Ghost of Tsushima runs one wind field through leaves, grass, cloth, ropes, smoke and fire. Sword swings blow out candles, and blood lands on nearby geometry and drifts in water [3]. Persistent residue (Vlambeer's "permanence", Doom's scorch decals, Control's layered destruction dust) is what makes an event *have happened* [4][8][19].
- **Audio–visual sync has a tolerance window, and it is lopsided.** For an impact like a hammer, people don't notice audio leading the picture by about 75 ms or trailing it by about 188 ms [11]. In games, play the sound on the impact frame. Never let it arrive before the visual.
- **Haptics follow sound-design rules: restraint and hierarchy.** Returnal kept most haptics at a medium baseline so that pulses for the biggest threats and weapons stand out. It also uses haptics to say things (cooldown ready, parasite grip), not just to add rumble [18].
- **Limit how much can start per frame.** If an attack hits 80 enemies, cap new shakes and hit-stops at about one per frame and new sounds at two or three, or the feedback becomes noise [10].

---

## 2. Deep dive

### 2.1 Dynamic lights from effects

**Why.** Emission adds light only to the emitting surface. In a forward or deferred real-time renderer, another mesh's glow never reaches the floor [14]. Without a light, a fireball travels through a corridor and the walls never notice. Light is the strongest "this is in the world" cue there is. It also travels through fog, wet surfaces and character faces. (analysis)

**Shape the flash like a VFX curve.** The pattern that works is a fast attack and a slower decay:

- **Muzzle flash:** a light that lasts 1–3 frames (about 16–50 ms at 60 fps), randomly rotated or varied in intensity each shot. (analysis; common practice)
- **Explosion:** peaks on frame 0–1, decays over 150–400 ms, and its colour shifts from white-yellow toward deep orange as it fades. That sells the cooling of the fireball. (analysis)
- **Fire and candles:** keep the light alive, but drive its energy with low-frequency noise of about 2–6 Hz plus a tiny high-frequency jitter. Pure random values per frame strobe. (analysis)

**Cost rules (Godot docs).**

- Forward+ allows 512 clustered elements in view by default, and lights, decals and probes all share that budget [17].
- Omni shadows render six cube faces, or two with dual-paraboloid; spot shadows render one. That makes them "significantly" cheaper [17].
- Shadow maps are cached, so a light that moves or pops in every frame forces re-renders [17].
- Energy itself is free [17]. **Range** (screen coverage) and **shadows** are what cost.

For flashes, then: no shadows, a tight range, and distance fade on. Unreal's guidance agrees: watch radius and falloff to limit overlap, and spend dynamic shadows carefully (snippet, [21]).

**How many.** Doom Eternal treats many dynamic particle effects as emissive light sources in its hybrid forward/deferred renderer (snippet, [20]). On a smaller budget, use one light per *event* (one per explosion, not one per spark) and a pool of reusable light nodes. A burst of 40 sparks gets one light at the centre of the burst. (analysis)

**Fake light as a cheaper alternative.** Use an additive ground-glow decal or quad under the fire, or a soft additive sprite with a big low-opacity glow. A realtimevfx thread suggests a second sprite with a blurred copy of the texture at very low opacity, to get coloured glow without pushing emissive into white [13]. (snippet + thread)

### 2.2 Bloom, HDR emissive and tonemapping

Here is the pipeline:

1. Render linear HDR.
2. Run bloom on pixels above a luminance threshold.
3. Tonemap.
4. Apply colour grading.

Godot applies its Adjustments *after* tonemapping [15][14].

Practical consequences:

- **Bloom keys off luminance, not RGB magnitude.** With Rec.709 weights, #FF00FF at "100" is only about 28.5 luminance [14]. Blue and magenta magic needs much more emissive multiplier than green or yellow to bloom equally. Alternatively, add a lighter core tint, like cyan-white inside blue. (analysis from [14])
- **Hot cores go white.** That's the tonemapper doing its job, and it is often the *desired* look: a white-hot core with a saturated halo. When it's not desired, use a hue-preserving tonemapper (AgX in Godot "best at keeping hue as colours brighten" [15]). You can also paint the core colour into the texture instead of pushing intensity. In Unreal, one artist needed about 30× emissive on red to get bloom, by which point the core was almost white (snippet, [13]).
- **Separation is what makes it read.** Emissive should sit well above the brightest lit highlight in the scene. If bloom catches walls and skin, your emissive isn't bright enough relative to the scene [14]. One reference setup used a bloom threshold of 10 nits, strength 0.5, AgX and exposure 0.5 [14].
- **Godot glow knobs [15]:**
  - **HDR Threshold:** 1.0 is the expected starting point.
  - **Blend mode:** Softlight is the default and weakest (good in dark scenes), Screen is the "all-round" choice, and Additive is the strongest.
  - **Levels:** small levels give tight halos; large levels give hazy, screen-wide glow.
  - **Glow Map:** masks glow per screen area.
  - **Auto-exposure + glow:** together they produce bloom around anything above White.

Exposure matters here. Auto-exposure will *swallow* a big flash if it adapts quickly, so either keep the adaptation speed low or exclude flashes from it. (analysis)

### 2.3 Chromatic aberration, radial blur, distortion

These are **impact punctuation**, never a constant state:

- **Distortion / heat-haze / shockwave ring.** Celeste spawns a displacement burst on every dash. Its parameters read as a ring that expands from radius 8 to 64 px over 0.4 s at 0.5 strength, with quad ease-out. The red dash uses 0 → 80 px over 0.666 s [1]. (Parameter meaning is inferred from the call order; analysis.) A refraction ring that expands and fades with ease-out is the cheapest "pressure wave".
- **Chromatic aberration.** Spike it to its peak on the impact frame and decay it over about 100–250 ms. Keep it radial, zero at the centre of the screen, so the target stays crisp. Constant CA reads as a cheap lens or nausea. (analysis)
- **Radial / zoom blur.** Use it for dashes, charge releases and the "time slows" moment. Centre it on the action, not the screen, so it doesn't fight the camera. (analysis)
- **Doom's toolset** mixes particles with animated geometry, scrolling-texture meshes, ribbons, lens flares and *post effects* [5]. Post-processing is part of the effect's layer stack, authored by the VFX artist, not bolted on afterwards.

### 2.4 Colour grading, LUT hits and fog

- **LUT or grade "hits":** a short global grade change on a significant event.
  - A desaturated or cold grade when the player takes heavy damage or time slows.
  - A warm lift for a heal.
  - A one-frame near-white flash for a lightning strike.
  - A slow blend toward a sepia "memory" LUT for a story beat.

  Use them sparingly. If every hit tints the screen, the grade stops meaning anything. Hits are usually 1–4 frames in and 200–800 ms out. (analysis)
- **Godot:** Color Correction accepts a 1D gradient or a 3D LUT (Texture3D import; 17/33/51/65 slices; lower resolution is cheaper), applied after tonemapping [15]. Godot can't cross-fade two LUTs natively, so either tween brightness, contrast and saturation, or blend in your own full-screen shader. (analysis)
- **Volumetric fog.** Fog is lit by every light that passes through it, so a flash that lights the fog sells "the air itself lit up". But Godot's temporal reprojection leaves trails behind fast-moving or short-lived lights. The docs recommend setting `light_volumetric_fog_energy = 0` on short-lived dynamic lights [16]. For a deliberate "god-ray flash", lower the reprojection Amount instead. A FogVolume with emission can tint the air locally, around a fire for example, without casting light [16].

### 2.5 Decals, scorch and lingering residue

- **Permanence is a juice principle in its own right.** The Art of Screenshake outline goes "Bigger Explosions → Even More Permanence (Smoke)" (snippet, [4]). Bodies, shells, smoke and scorch stay behind, so the battle leaves a record.
- **Layered destruction** (Control): mesh particles, rigid-body hierarchies and material decals add detail, and then a final layer of sprites, ember particles and sand fills in the rest (snippet, [19]). Doom has historically leaned heavily on decals and moved to mesh decals for more detail (snippet, [20]).
- **Residue should *evolve*.** A scorch mark starts emissive (orange, cooling), then smokes for a few seconds, then stays as a dark albedo/normal stain for a long time or until a budget cap is hit. Ghost of Tsushima also lets residue migrate: blood droplets land on nearby geometry, and in water they form clouds that drift with the current. Mud builds up on knees, elbows and shoulders as the player rolls and slides [3].
- **Godot Decal [22]:**
  - Separate albedo, normal, ORM and emission textures, plus `emission_energy` and `modulate`.
  - `albedo_mix = 0` gives normal-only decals (footprints, wet patches).
  - Distance fade culls decals, and `cull_mask` keeps scorch off characters.
  - Cost scales with *screen coverage*, so keep the projection depth (extents Y) short.
  - Decals share the 512-element cluster budget with lights.
  - Fade, then `queue_free()`. Mobile supports only 8 decals per mesh, and Compatibility has no decals at all.

### 2.6 Sound × VFX

- **Layer anatomy.** An explosion is built from several layers: an immediate transient, then a body/sustain, a low-end "sweetener" for weight, and debris in the tail [23]. A weapon sound splits into body, mechanics, low end, detail and tail, and the tail may be triggered separately from the onset [24].

  Map these one-to-one to VFX layers (analysis):

  | Sound layer | VFX layer |
  |---|---|
  | Transient | Flash, light and hit-stop |
  | Body | Fireball and shockwave |
  | Sweetener | Camera kick and rumble |
  | Tail and debris | Smoke, embers, falling debris, scorch |

- **Sync tolerance.** For a hammer-on-peg clip, the "no asynchrony noticed" window ran from about 75 ms audio-*lead* to about 188 ms audio-*lag* [11]. Viewers forgive late sound far more than early sound. One study found interactive gameplay raised the audio-lag threshold by about 40 ms, though gamers in general judge synchrony better (snippet, [11]).

  Rules (analysis):
  - Trigger the sound on the impact frame. Never pre-roll the *transient*; a pre-roll "whoosh" belongs to the anticipation.
  - For distant events, deliberately delay the sound at about 343 m/s (thunder, artillery). That *adds* realism.
  - Hit-stop should not pause audio. The sound should ring through the freeze, which is what makes the freeze feel heavy.
- **Dynamic mixing.** Duck ambience under a big blast (sidechain) so the event owns the mix for a moment (snippet, [25]).
- **Variation.** Randomise pitch and layer choice per instance so repeats don't machine-gun. Cap simultaneous starts per frame [10][12].

### 2.7 Camera

- **Trauma model** (Eiserloh, GDC 2016) [9][10]:
  - Each hit adds trauma, clamped to 0–1.
  - Trauma decays linearly, by `decay × delta` per frame.
  - Shake = trauma² (or trauma³) × max offset/angle.
  - Use smooth noise with a different seed per axis.
  - In 3D first-person, prefer **rotational** shake: pitch, yaw and especially roll, at a few degrees at most. Translation shake makes first-person nauseating. (analysis)
- **Apply the difference.** Add each frame's shake delta to the camera instead of overwriting its transform, so gameplay camera motion survives and stacked effects settle back cleanly [10].
- **Directional kicks.** Push the shake *along* the force: Celeste shakes along the dash direction [1], and Vlambeer pushes the camera back against the firing direction [4][26].
- **FOV punch.** Narrowing or widening FOV for a few frames reads as a lunge. Widen for speed or a dash; narrow for a charge or a focused danger. Epic of Kings narrows FOV on some enemy attacks, but only in one-on-one fights, because in crowds it distracts [27]. Typical punch: ±3–8° in, 60–120 ms out, ease-out. (analysis)
- **Reduce shake when the camera pulls back.** God of War [2]. Scale shake by camera distance too: Sakurai changes shake amount with camera distance (snippet, [7]).

### 2.8 Animation sync

- **Anticipation belongs to the character, payoff to the VFX.** Wind-up frames, often with a charge glow building in the hand or weapon, then a fast, smear-like swing, then everything fires on the contact frame. (analysis)
- **Hit-stop mechanics.** Freeze both attacker and victim in the first frame of the hit pose [2]. Sakurai's refinements (snippet, [7]):
  - Shake the *victim* more than the attacker.
  - Keep the attacker moving very slightly so the freeze doesn't look like lag.
  - Interpolate into the damage pose.
  - Cap the maximum freeze.
- **Hit reactions** (Epic of Kings, [27]):
  - Start from a damaged pose with **zero cross-fade**, because blending in makes hits floaty.
  - Add additive shake layers on enemies whose attacks can't be interrupted.
  - Use directional reactions.
  - Give heavy attacks a larger shake frequency and amplitude.
- **Squash and stretch on the impact frame.** Celeste sets sprite scale to (0.6, 1.4) on jumps, (0.5, 1.5) or (1.5, 0.5) on wall bounces, and (1.4, 0.6) on landings, then eases back [1].
- **Drive VFX from animation events.** Never use timers that guess the impact frame. If the animation is retimed, the effect must move with it. (analysis)

### 2.9 Haptics

- Treat the actuator like a speaker. Returnal's sound designer authored haptics with sound-design principles, and its rain is synthesised procedurally at runtime [18].
- **Hierarchy:** most haptics sit at a medium baseline, and the maximum is saved for the biggest threats and weapons [18].
- **Directional haptics:** a dash weighted to the matching side of the controller [18].
- **Semantic haptics:** an "alt-fire ready" pulse paired with the audio and visual cues, and a distinct gripping texture for parasite damage [18].
- **Celeste's vocabulary** is just Light, Medium and Strong × Short and Medium. Light/Short for small contacts, Medium for wall bounces, Strong/Medium for the dash and explosions [1]. A small, consistent vocabulary is better than bespoke curves everywhere. (analysis)
- Spider-Man on PS5 adds web-swing trigger resistance, with a little extra tension at the end of the pull (snippet, [28]).

### 2.10 UI feedback effects

- **Diegetic vs. non-diegetic.** God of War Ragnarök shows parry timing with a growing circle, a deliberate *non-diegetic* overlay, while barrels spray and sluices steam to show state in-world [6]. GoW 2018's yellow/red attack rings became Ghost of Tsushima's blue/red glints [2].
- **The same bundle applies to UI.** A hit flash (the target turns white for about 80 ms [12]), damage numbers that pop with scale overshoot, a screen-edge damage vignette that pulses and decays, a slight UI shake on taking damage, and pickups that fly toward the HUD counter and bump it on arrival. (analysis)
- **Feedback colour must match the world's colour language.** Doom: one colour family for health, another for damage, a fixed colour per weapon [5]. Doom Eternal's bright green armour shards tell you instantly that you're doing the right thing (snippet, [29]).

---

## 3. Examples

| Game | Effect | What makes it work |
|---|---|---|
| **Celeste** | Dash | Freeze 0.05 s, directional shake 0.2 along the dash, displacement ring 8→64 px over 0.4 s, Strong/Medium rumble, slash burst, trail every 0.08 s. Every channel fires on one frame [1]. In a 2D pixel game the *displacement* stands in for a light flash. |
| **Celeste** | Explosion launch (Puffer/boost) | A longer freeze of 0.1 s plus Strong rumble. Freeze length scales with the size of the event [1]. |
| **God of War (2018)** | Leviathan Axe hits | Hit-stop holds attacker and victim on the hit pose. Shake was cut because the camera sits close behind Kratos, and the punch comes back through a heavy low-end slam into a high-frequency slash sound, plus big pose changes and juggles [2]. The recall's catch adds rumble and camera settle (analysis). |
| **God of War Ragnarök** | Status effects and markers | Hex is magenta with black accents and Bifrost is indigo with rainbow accents. Fast-travel doors shrink as you approach. The parry circle is deliberately non-diegetic [6]. |
| **Doom / Doom Eternal** | Combat VFX | Priority ranking (muzzle flash and impacts brightest), lit particles, particle lighting decoupled from drawing, rendering into a reduced off-screen buffer [5]. Eternal makes many particles emissive light sources (snippet, [20]) and strips demons down as visible damage feedback [29]. Mixing and score sit tightly on top of the combat (snippet, [29]). |
| **Ghost of Tsushima** | Wind and duels | One global wind direction drives smoke, fire, sparks, grass, trees, cloth and leaves. Player movement adds local wind. Duel candles go out when sword-swing wind crosses a threshold, and spawn a smoke wisp. Leaves part around fast-moving duellists, then settle. Blood lands on geometry and drifts in water. The wind even works as quest navigation [3]. Effects feel *in* the world because they obey the same forces as the world. |
| **Control** | Destruction | Layered stack: mesh chunks, then material decals, then dust, embers and sand sprites. Residue stays behind (snippet, [19]). |
| **Marvel's Spider-Man (PS5)** | Web-swing | Trigger resistance with extra tension at the end of the pull. Spider-Man 2 shifted haptics toward amplifying cinematic beats (snippet, [28]). |
| **Hades** | Boon effects | Supergiant's VFX and UI were made by the same artist (Josh Barnett) [30], so in-world and HUD feedback share one visual language. Third-party analyses credit short impact pauses on dash-strikes (snippet, [31]); unverified. |
| **Returnal** | Haptics | Medium baseline and rare maximum pulses. Semantic patterns: a gripping parasite texture, a granular tap per Obolite, directional dashes [18]. |
| **Vlambeer, *The Art of Screenshake*** | 30 tweaks to a dull shooter | Bigger bullets, muzzle flash, hit flash, enemy knockback, screen shake against the fire direction, permanence (shells, bodies, smoke), sleep/hit-pause, bigger explosions, a 33% chance enemies explode on death [4][26]. The point: no single effect matters, the *stack* does. |

---

## 4. Common mistakes

1. **Effects that don't touch the world.** No light, no decal, no response from fog, foliage or water. The effect reads as a sticker. (analysis, [14])
2. **Shadowed, wide-range flash lights.** They cost a lot, flicker the shadow atlas, and blow the cluster budget in big fights [17]. Short-lived lights left in volumetric fog leave ghost trails [16].
3. **Pushing emissive until it's white, then complaining it's white.** Choose the tonemapper first, tint the core, and remember that blue and magenta carry little luminance [13][14].
4. **Constant post FX.** Permanent chromatic aberration, vignette or grain dulls the hits, because punctuation needs a quiet baseline. (analysis)
5. **Sound early, or sound paused by hit-stop.** Audio leading the visual is noticed sooner than audio lagging [11]. Freezing audio during a hit-stop makes the freeze feel like a hitch. (analysis)
6. **Random-number shake, linear trauma, no clamp.** It jitters, small hits feel as big as big ones, and multi-kills wreck the camera [9][10].
7. **Translation shake in first person.** Use rotation, mostly roll and pitch, at small angles. (analysis)
8. **Timer-driven VFX instead of animation events.** Effects drift off the contact frame when the animation gets retimed. (analysis)
9. **Cross-fading into hit reactions.** It produces floaty hits; use zero blend into the damage pose [27].
10. **No hierarchy.** Every hit at max rumble, max shake and max flash means nothing stands out. Returnal's medium baseline and Doom's ranking show the fix [5][18].
11. **Uncapped feedback in AoE.** 80 simultaneous sounds and shakes. Cap the starts per frame [10].
12. **Residue without a budget.** Unlimited decals and debris eventually tank the framerate. Use a ring buffer and fade the oldest. [22]
13. **Hit-stop that breaks timers.** Counting down with `delta` while `time_scale = 0` never ends; use real time [10].

---

## 5. Apply in Godot 4

*(Godot 4.7, Forward+, AgX, glow on. Unsent is slow, dark and melancholy, so the defaults below are deliberately restrained. Combat games can multiply the numbers.)*

### 5.1 One "FX event" dispatcher (the bundle)

Make every effect a *recipe* that fires all channels on one frame. Use one autoload and per-frame start caps [10].

```gdscript
# fx.gd  (autoload "FX")
extends Node

var _trauma := 0.0
var _starts_this_frame := {}
@export var trauma_decay := 1.2           # per second
@export var max_roll_deg := 2.5           # first-person: rotational shake only
@export var max_pitch_deg := 1.5
var _noise := FastNoiseLite.new()
var _t := 0.0
var _applied := Vector3.ZERO              # "apply the difference" [10]
var _last_us := Time.get_ticks_usec()

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 1000               # run after gameplay camera code
    _noise.frequency = 2.0

func _can_start(kind: StringName, cap: int) -> bool:
    var n: int = _starts_this_frame.get(kind, 0)
    if n >= cap: return false
    _starts_this_frame[kind] = n + 1
    return true

func add_trauma(amount: float) -> void:
    if _can_start(&"shake", 1):
        _trauma = clampf(_trauma + amount, 0.0, 1.0)

func hit_stop(duration: float) -> void:
    if not _can_start(&"stop", 1): return
    var prev := Engine.time_scale
    Engine.time_scale = 0.0
    # 4th arg ignore_time_scale = true, so the timer runs while time is frozen
    await get_tree().create_timer(duration, true, false, true).timeout
    Engine.time_scale = prev

func _process(delta: float) -> void:
    _starts_this_frame.clear()
    # real (unscaled) time, so shake keeps decaying during hit-stop
    var now := Time.get_ticks_usec()
    var real_dt := clampf((now - _last_us) / 1_000_000.0, 0.0, 0.1)
    _last_us = now
    _t += real_dt
    _trauma = maxf(_trauma - trauma_decay * real_dt, 0.0)
    var cam := get_viewport().get_camera_3d()
    if cam == null: return
    var s := _trauma * _trauma
    var target := Vector3(
        deg_to_rad(max_pitch_deg) * s * _noise.get_noise_2d(_t * 60.0, 0.0),
        0.0,
        deg_to_rad(max_roll_deg) * s * _noise.get_noise_2d(_t * 60.0, 100.0))
    cam.rotation += target - _applied     # add the delta, don't overwrite
    _applied = target
```

`AudioStreamPlayer` nodes keep playing during `Engine.time_scale = 0`, so the sound rings through the freeze. Keep it that way.

### 5.2 Flash and flicker lights

Use a pooled `OmniLight3D` with `shadow_enabled = false`, a small `omni_range` (2–6 m), `distance_fade_enabled = true`, `light_volumetric_fog_energy = 0.0` (to avoid reprojection ghosting [16]) and `light_specular` of about 0.5.

```gdscript
var _light_pool: Array[OmniLight3D] = []   # in the FX autoload

func flash_light(pos: Vector3, color: Color, energy := 4.0, out_time := 0.25) -> void:
    var l: OmniLight3D = _light_pool.pop_back() if _light_pool.size() > 0 else OmniLight3D.new()
    if l.get_parent() == null:
        add_child(l)
        l.shadow_enabled = false
        l.omni_range = 4.0
        l.light_volumetric_fog_energy = 0.0
        l.distance_fade_enabled = true
        l.distance_fade_begin = 25.0
        l.distance_fade_length = 10.0
    l.global_position = pos
    l.visible = true
    l.light_color = Color(1.0, 0.92, 0.75)          # white-hot at peak
    l.light_energy = energy
    var tw := create_tween().set_parallel()
    tw.tween_property(l, "light_energy", 0.0, out_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
    tw.tween_property(l, "light_color", color, out_time * 0.6)   # cools toward orange
    tw.chain().tween_callback(func(): l.visible = false; _light_pool.append(l))
```

**Flicker for fires and candles.** Use `light_energy = base * (1.0 + 0.25 * noise.get_noise_1d(t * 3.0) + 0.05 * randf_range(-1, 1))`.

**For Unsent.** GPUParticles3D can't spawn lights. For the burning-leaf system, put *one* flickering OmniLight on the emitter. Bias its position toward the falling cluster's centre, and scale its energy with the sub-emitter flame count, read from a gameplay-side estimate. Avoid one light per leaf. For the letter-burn dissolve, drive one OmniLight's energy from the same `burn_progress` uniform the shader uses: rising as the burn edge grows, dying out as it finishes. Then the paper's glow and the room's light are a single event.

### 5.3 Emissive authoring for glow

- **Environment:** `glow_enabled = true`, `glow_hdr_threshold = 1.0`, `glow_blend_mode = GLOW_BLEND_MODE_SOFTLIGHT` for dark scenes (or SCREEN), small levels (1–3) for tight halos, plus a little of level 5–6 for haze [15]. Keep `glow_bloom = 0` so only HDR emissive blooms.
- **Materials:** in spatial shaders write `EMISSION = color.rgb * energy`, or in unshaded add-blend billboards `ALBEDO = color.rgb * energy` with energy 2–8 for flames and 8–20 for flash cores. Ambient props stay below about 1.5 so they never bloom. Compensate blue and magenta with extra energy or a lighter core tint (luminance weights [14]).
- **Tonemapper:** AgX keeps flame hue at high energy [15]. If cores still bleach, colour the *core texture* yellow-white and leave the halo saturated, rather than pushing energy.

### 5.4 Impact post-process: chromatic aberration, radial blur and shockwave

Use a full-screen `ColorRect` on a `CanvasLayer` (layer 100, `mouse_filter = IGNORE`) with a `canvas_item` shader. Drive `strength` from the FX autoload: spike on the impact frame, then tween to 0 over about 0.2 s. (Godot 4.3+ can also do this as a `CompositorEffect` if it needs to sit before UI or glow.)

```glsl
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 center = vec2(0.5);       // impact point in screen UV
uniform float strength = 0.0;          // 0..1, tweened
uniform float ring_radius = 0.0;       // shockwave: tween 0 -> 0.6
uniform float ring_width = 0.08;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 d = uv - center;
    float dist = length(d);
    // shockwave refraction ring
    float ring = smoothstep(ring_width, 0.0, abs(dist - ring_radius));
    uv -= normalize(d + 1e-5) * ring * 0.02 * strength;
    // radial chromatic aberration, zero at the impact centre
    vec2 ca = d * 0.012 * strength;
    float r = texture(screen_tex, uv + ca).r;
    float g = texture(screen_tex, uv).g;
    float b = texture(screen_tex, uv - ca).b;
    // cheap 6-tap radial blur
    vec3 blur = vec3(r, g, b);
    for (int i = 1; i <= 6; i++) {
        blur += texture(screen_tex, uv - d * float(i) * 0.006 * strength).rgb;
    }
    COLOR = vec4(mix(vec3(r, g, b), blur / 7.0, strength * 0.6), 1.0);
}
```

### 5.5 Grade "hits"

Tween `environment.adjustment_saturation`, `adjustment_brightness` and `adjustment_contrast` (with `adjustment_enabled = true`): 2–4 frames in, 300–800 ms out. Example: saturation 1.0 → 0.4 for a memory flash. LUTs: `adjustment_color_correction` takes a Texture3D (33³ is the usual template, or a smaller one for speed) [15]. To blend between two LUTs, sample both in the post shader above and `mix`.

### 5.6 Scorch, residue and decals

Spawn a `Decal` at the impact with:

- `texture_albedo` (dark soot with alpha), `texture_normal`, and `texture_emission` (an orange rim);
- `cull_mask` excluding characters;
- `size.y` kept small (about 0.3–0.5 m) so culling stays tight;
- `distance_fade_enabled` on.

Then animate it:

```gdscript
var tw := create_tween()
tw.tween_property(decal, "emission_energy", 0.0, 4.0).from(3.0).set_ease(Tween.EASE_OUT)  # embers cool
tw.parallel().tween_property(decal, "modulate", Color(0.8, 0.8, 0.8, 1), 4.0)
tw.tween_interval(60.0)
tw.tween_property(decal, "albedo_mix", 0.0, 3.0)
tw.tween_callback(decal.queue_free)
```

Keep a ring buffer (for example 32 decals) and fade the oldest when a new one spawns [22]. Add a short-lived smoke GPUParticles3D at the decal for the first 2–5 s. For Unsent's falling leaves, a leaf that lands while burning can leave a small ash decal that cools from emissive to grey: quiet permanence.

### 5.7 Animation-synced triggering

In `AnimationPlayer`, add a **Call Method track** with a key on the contact frame that calls `fx_impact()` on the character. Or emit a signal from the track. Anticipation VFX (charge glow, a dust kick on the plant foot) go on earlier keys. Never spawn the impact from a `Timer`.

```gdscript
func fx_impact() -> void:   # called by the animation on the contact frame
    var p := $Hand.global_position
    impact_particles.global_position = p; impact_particles.restart()
    $ImpactSFX.global_position = p; $ImpactSFX.play()           # same frame, never earlier
    FX.flash_light(p, Color(1.0, 0.45, 0.15))
    FX.add_trauma(0.35)
    FX.hit_stop(0.06)
    Input.start_joy_vibration(0, 0.3, 0.6, 0.12)                # weak, strong, seconds
    _post.punch(get_viewport().get_camera_3d().unproject_position(p) / get_viewport().get_visible_rect().size)
```

For audio, use `AudioStreamRandomizer` (pitch random about 1.05, several variants) and a sidechain `AudioEffectCompressor` on the ambience bus, keyed from the SFX bus, for ducking. For distant events, delay the sound by `distance / 343.0` s.

### 5.8 FOV punch

```gdscript
func fov_punch(cam: Camera3D, delta_deg := 4.0, t := 0.12) -> void:
    var base := cam.fov
    var tw := create_tween()
    tw.tween_property(cam, "fov", base + delta_deg, 0.03)
    tw.tween_property(cam, "fov", base, t).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
```

For Unsent, keep `delta_deg` at 1–2° and use it only on narrative beats, such as a letter catching fire. That fits the slow, cinematic camera direction.

### 5.9 Haptics vocabulary

Define 3 × 2 presets, like Celeste's [1]: light (0.15/0.0), medium (0.3/0.3) and strong (0.2/0.8) for weak/strong magnitude, each with short (0.08 s) and medium (0.2 s) durations. Call them through one helper so a settings slider can scale or disable them. Use `Input.vibrate_handheld(ms)` on mobile.

### 5.10 UI feedback

- **Hit flash:** a `flash_amount` uniform in the enemy shader (`ALBEDO = mix(ALBEDO, vec3(1.0), flash_amount)`), set to 1 for about 0.08 s and retriggered on each hit [12].
- **Damage vignette:** a radial-gradient `TextureRect` whose `modulate.a` tweens 0.6 → 0 over 0.4 s.
- **HUD counters:** scale-punch with `TRANS_BACK` and `EASE_OUT`, 1.0 → 1.15 → 1.0 over 0.15 s.

---

## 6. Sources

1. NoelFB / Maddy Thorson, *Celeste* `Player.cs` (official source release, GitHub). https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs
2. PlayStation Blog, "Game developers explain what makes God of War (2018)'s combat tick". https://blog.playstation.com/?p=370399
3. Matt Vainio (Sucker Punch), "How stunning visual effects bring Ghost of Tsushima to life", PlayStation Blog. https://blog.playstation.com/?p=345372
4. University of Bayreuth, "GxD 10 Game Feel" (lecture slides outlining *The Art of Screenshake*). https://medienwissenschaft.uni-bayreuth.de/wp-content/uploads/GxD-10-Game-Feel.pdf
5. 80.lv, "The secrets of VFX production for DOOM" (Wirginia Romanowska, id Software). https://80.lv/articles/the-secrets-of-vfx-production-for-doom/
6. Game Developer, "VFX as game design tools: the ludology of VFX in God of War Ragnarök and Halo Infinite". https://gamedeveloper.com/design/vfx-as-game-design-tools-the-ludology-of-vfx-in-god-of-war-ragnarok-and-halo-infinite
7. Sakurai hit-stop coverage: GoNintendo, "Sakurai's latest game dev video features 8 'hit stop' techniques" https://www.gonintendo.com/contents/13581-sakurai-s-latest-game-dev-video-features-8-hit-stop-techniques ; Source Gaming, "Thoughts on Hitstop" (Famitsu translation) https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/
8. 80.lv, "Insights into building VFX for Ghost of Tsushima". https://80.lv/articles/insights-into-building-vfx-for-ghost-of-tsushima/
9. Squirrel Eiserloh, "Math for Game Programmers: Juicing Your Cameras With Math" (GDC 2016). https://gdcvault.com/play/1023146/Math-for-Game-Programmers-Juicing (+ Bevy 2D screen-shake example https://bevy.org/examples/camera/2d-screen-shake/)
10. Godot Forum, "Game feel effects that stack without fighting your code: trauma shake, real-time hit-stop and 'apply the difference'". https://forum.godotengine.org/t/game-feel-effects-that-stack-without-fighting-your-code-trauma-shake-real-time-hit-stop-and-apply-the-difference/146379
11. "Perceived synchrony for realistic and dynamic audiovisual events" (PMC4451240) https://pmc.ncbi.nlm.nih.gov/articles/PMC4451240 ; AES e-library, audio-lag threshold in interactive games https://www.aes.org/e-lib/browse.cfm?elib=12881
12. Uhiyama Lab, "Fixing 'My Attacks Don't Feel Like They Hit': hit stop, flash, shake and sound" (Unity). https://uhiyama-lab.com/en/notes/unity/unity-game-feel-hit-feedback/
13. realtimevfx.com, "High intensity material going white". https://realtimevfx.com/t/high-intensity-material-going-white/24152
14. Don McCurdy, "Emission and bloom" (2024). https://www.donmccurdy.com/2024/04/27/emission-and-bloom/
15. Godot docs, "Environment and post-processing". https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html
16. Godot docs, "Volumetric fog and fog volumes". https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html
17. Godot docs, "3D lights and shadows". https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html
18. PlayStation Blog, "How Housemarque created Returnal's immersive DualSense controller effects". https://blog.playstation.com/2021/05/13/how-housemarque-created-returnals-immersive-dualsense-controller-effects/
19. Johannes Richter (Remedy), "Destructible Environments in Control: Lessons in Procedural Destruction", GDC Summer 2020. https://gdcvault.com/play/1030643/Destructible-Environments-in-Control-Lessons (+ 80.lv announcement https://80.lv/articles/gdc-talk-destructible-environments-in-control)
20. GamingBolt, "DOOM Eternal graphics analysis" (snippet) https://gamingbolt.com/doom-eternal-graphics-analysis-ps4-pro-vs-xbox-one-x-vs-pc-comparison ; "How the DOOM Eternal frame is rendered" (snippet) https://tech-en.netlify.app/articles/en518724
21. Unreal Engine docs, "In-Camera VFX best practices" (snippet). https://docs.unrealengine.com/4.27/ko/WorkingWithMedia/IntegratingMedia/InCameraVFX/InCameraVFXBestPractices
22. Godot docs, "Using decals". https://docs.godotengine.org/en/stable/tutorials/3d/using_decals.html
23. Sound on Sound, "Sound design for visual media" (snippet). https://www.soundonsound.com/techniques/sound-design-visual-media-radio
24. Splice, "How to design a weapon sound for video games" (snippet). https://splice.com/blog/?p=16617
25. PC Gamer, "How great game explosions are made" (snippet). https://www.pcgamer.com/uk/how-great-game-explosions-are-made/
26. Game Developer, "Vlambeer co-founder shares advice on building better action games". https://gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games
27. Game Developer, "The role of animations in hit effects" (Epic of Kings). https://gamedeveloper.com/programming/the-role-of-animations-in-hit-effects
28. Game Watch Impress, interview with DualSense PM Toshimasa Aoki (snippet) https://game.watch.impress.co.jp/docs/interview/1540222.html ; Shacknews, "Spider-Man 2 DualSense features" (snippet) https://shacknews.com/article/137120/spider-man-2-dualsense-features
29. PC Gamer, "Doom Eternal has ruined all other shooters for me" (snippet) https://www.pcgamer.com/doom-eternal-has-ruined-all-other-shooters-for-me ; Game Developer, "Q&A: Evolving the combat design of Doom Eternal" (snippet) https://gamedeveloper.com/design/q-a-evolving-the-combat-design-of-id-software-s-i-doom-eternal-i-
30. 80.lv, "A behind-the-scenes look at the effects in Hades". https://80.lv/articles/a-behind-the-scenes-look-at-the-effects-in-hades
31. FreeGameSprites, "Game feel: 2D combat juice tricks" (snippet; third-party, unverified). https://freegamesprites.com/es/news/game-feel-2d-combat-juice-tricks
