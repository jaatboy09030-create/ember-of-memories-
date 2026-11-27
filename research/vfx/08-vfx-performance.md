# 08 — VFX Performance and Optimisation

Scope: overdraw and fill rate, particle budgets, GPU vs CPU simulation, LOD and culling, pooling and pre-warming, shader and pipeline compilation stutter, atlases, tight particle meshes, platform budgets, profiling tools and scalability. Engine-agnostic first, then a Godot 4.7 (Forward+) section.

Notes on marking: "(snippet)" means the claim comes only from a search-result snippet I could not open. "(analysis)" means my own reasoning. Everything else comes from a page I fetched. Some numbers come from community guides rather than studios, and I say so where that applies.

---

## 1. Key takeaways

1. **Most VFX cost is pixels, not particles.** Epic's long-standing model is: overdraw cost = number of translucent layers × average pixels each layer covers × shader instructions per layer [1][2]. Ten huge smoke quads can cost more than 10,000 tiny sparks.
2. **Budget by "how many at once", not "how good is one".** Azur Games limits some unit effects to 3–10 particles because up to 200 units can fire the same effect at the same time [3]. The worst-case moment, not the showcase moment, sets the budget.
3. **Real studio budgets are small.** VFX notes from a DICE talk put *Star Wars Battlefront*'s whole effects budget at "just over 1 millisecond" of frame time (snippet; the original notes page blocked fetching) [4]. A community Unreal guide gives Niagara tick targets of under 2 ms on PS5/Series X, under 1.5 ms on PS4/Xbox One, and under 1 ms on mobile and VR [5]. These are community numbers, not official ones.
4. **Trim the quad.** Fitting a smoke puff's geometry to its alpha shape cut its pixel area to 69% (bounding box), 60% (4 vertices), 54% (6 vertices) and 52% (8 vertices) of the original quad [6]. Cropping wasted texture space does the same thing for free [3].
5. **GPU simulation only pays off at scale.** Epic says a 1-particle GPU simulation "can potentially take up the same resources" as a 64-particle one [7]. A community guide puts the crossover at about 1,000+ particles [5]. Small bursts of 5–50 particles are often cheaper on the CPU.
6. **Lowering `amount_ratio` in Godot saves nothing.** Buffers are allocated and processed for the full `amount` [8][9]. To cut cost, lower `amount`.
7. **First-use stutter is usually pipeline compilation, not loading.** Godot 4.4+ precompiles pipelines it can detect at load time, and ubershaders cover the rest. Particles spawned from script may still compile on first use, so keep a hidden instance alive [10]. The 4.5+ **shader baker** shortens first launch but "is not a replacement for pipeline precompilation" [10].
8. **Pool and prime, but don't "warm up" with simulation.** Epic recommends pooling and priming instances, but advises against simulation warmup, because each warmup frame runs sequentially and can hitch [7]. In Godot, high `preprocess` values are expensive for the same reason [9].
9. **Cull with tight, fixed bounds.** Fixed bounds are cheaper than dynamic bounds in Niagara [7]. Automatic bounds in Unity VFX Graph force "always recompute bounds and simulate" (snippet) [11]. Godot's `visibility_aabb` defaults to an 8 m box and should be generated per effect [9].
10. **Low-resolution off-screen particles are the classic big win for soft volumes.** GPU Gems 3 doubled the frame rate of a smoke-heavy scene (25 to 51 FPS) by rendering particles at 1/4 × 1/4 resolution with an edge fix-up pass [12]. It works poorly for sharp debris.
11. **Measure with real tools, at a fixed resolution, on target hardware.** Use RenderDoc, Godot's Visual Profiler and its pipeline monitors, Unreal Insights and Quad Overdraw, or PVRTune and Arm Streamline on mobile [10][13][14][15].
12. **Mobile is a different world.** On tile-based GPUs, transparency and full-screen passes are costly, and Godot's own docs say more complex opaque geometry can be faster than transparency [16]. Screen-SDF particle collision is "expected to be very slow on mobile" (snippet) [17].

---

## 2. Deep dive

### 2.1 Fill rate and overdraw: why big transparent quads hurt

**What it is.** Fill rate is how many pixels per second the GPU can shade and blend [18]. Overdraw happens when the same pixel is shaded more than once in a frame [16]. Opaque geometry is mostly protected by the depth buffer: hidden pixels get rejected early. Transparent (alpha-blended or additive) geometry has to be drawn back to front, and every layer gets shaded even when a later layer covers it completely [16]. A particle smoke column is a stack of exactly that kind of layer.

**The cost model.** Epic's formula (UE3 era, repeated in the 4.27 docs) [1][2]:

> overdraw cost ≈ layers × pixels per layer × instructions per layer

All three factors multiply. Halving any one of them halves the cost. The levers that follow from it:
- **Fewer layers:** lower the spawn rate and spread particles out with velocity so they don't pile up on one pixel. A realtimevfx poster cut overdraw noticeably by using bigger sprites and fewer of them [19].
- **Fewer pixels:** use smaller particles, tighter geometry and cropped textures. Fade or kill particles near the camera, since one particle in front of the lens can cover the whole screen [19][20].
- **Fewer instructions:** keep large effects to roughly 100–150 instructions, and use SceneColor or refraction only on effects that cover a small area of the screen [5].

**Scale is quadratic.** Doubling a quad's width and height quadruples its screen area [3]. A "slightly bigger" smoke puff is a lot more expensive.

**Typical overdraw.** Smoke and magic clouds commonly reach about 5–20× overdraw, meaning each covered pixel is shaded 5–20 times [5]. Unreal's Shader Complexity view turns bright red at about 300 instructions, pink at 600 and white at 900+ (snippet) [5].

**Resolution matters too.** A 4K frame has 8,294,400 pixels, 27 times as many as 640×480 [16]. An effect tuned at 1080p costs about 4× more pixel work at 4K (analysis).

**How to tell if you are fill-rate bound.** Godot's docs give the simplest test: turn off V-Sync, then compare FPS in a large window and a tiny window. A big FPS gain means pixel work is the bottleneck [16]. On mobile, PVRTune reports an overdraw value [20]. Arm Streamline can compute an overdraw factor, the average number of times each pixel is shaded, from Mali hardware counters (snippet) [18].

**Visualising overdraw:**
- Unreal: the Quad Overdraw and Shader Complexity view modes. Toggle emitters one at a time to find the worst one [13].
- Godot: the 3D viewport's *Display Overdraw* debug draw, also available at runtime as `Viewport.debug_draw = DEBUG_DRAW_OVERDRAW`. It renders geometry as additive translucent silhouettes, so hot spots glow (analysis, based on the engine's API; check the menu wording in 4.7).
- Any engine: make the effect's material additive with a dim, constant colour over a black background. Brightness then reads directly as layer count [21].
- RenderDoc: capture a frame, then use the texture viewer's *Quad Overdraw* overlay on the draw that renders particles (analysis, standard RenderDoc feature).

**Tricks to reduce overdraw:**
- **Alpha cutoff on faint particles.** Stop rendering a sprite once its alpha falls below a threshold. Near-invisible particles still cost full fill rate [19].
- **Dither instead of blending.** Dithered (alpha-tested) particles write depth and avoid blending, at a visual cost. Usually they need TAA to hide the pattern [19].
- **Opaque or masked for dense centres.** Use a masked material for the solid core of a mesh effect [19]. Snap suggests turning blending off where you can [21].
- **Render at lower resolution** (see 2.6).

### 2.2 Tight-mesh particles vs quads

A quad wastes every fully transparent texel in its corners. Humus's particle-trimming tool reads the texture's alpha and searches for the smallest enclosing polygon with N vertices [6]. Pixel area for a smoke puff, as a share of the full quad:

| Geometry | Pixel area | Saving |
|---|---|---|
| Full quad | 100% | — |
| Aligned bounding box | 69.2% | ~31% |
| Optimised 4-vertex polygon | 60.2% | ~40% |
| Optimised 6-vertex polygon | 53.9% | ~46% |
| Optimised 8-vertex polygon | 51.9% | ~48% |

Returns diminish quickly past 6–8 vertices [6]. Unreal ships this as **Sprite Cutout** (a "SubUV / cutout" asset with 4 or 8 vertices) [19]. Imagination (PowerVR) recommends the same thing: a circle-like mesh for a smoke puff [20]. Azur Games suggests extra-vertex meshes for large, simple shapes such as flashes, shockwaves and vortexes, but not for tiny particles, where the extra vertices aren't worth it [3].

Rule of thumb (analysis): use a tight mesh when a particle can cover more than about 5% of the screen. Keep quads for sparks and small embers. For flipbooks, fit the polygon to the union of all frames' alpha.

### 2.3 Particle counts, GPU vs CPU, and emitter overhead

**GPU vs CPU:**
- Godot: GPU particles "can render hundreds of thousands of particles on modern hardware". CPUParticles are "not as performant", but run on more hardware and older phones [22]. Since 4.2, new particle features land only in GPUParticles. CPUParticles is now the "lower-end, simpler alternative", not a feature-for-feature fallback [23].
- Unreal: all simulations carry some CPU overhead. GPU wins at large counts, and CPU wins for emitters with few particles because GPU work is allocated in coarse blocks [7]. If the GPU is the bottleneck, which is common on mobile, CPU simulation can come out ahead [7]. A community guide puts the GPU break-even at about 1,000 particles [5].
- Frostbite moved to GPU particles for *Battlefront II*, which allowed far more particles per effect (snippet) [24].

**Emitter count often matters more than particle count.** Each emitter carries fixed CPU overhead and usually costs at least one draw call [7]. Community measurements in Unreal [5]:

| Emitters | CPU | Draw calls |
|---|---|---|
| 1–5 | ~0.3–0.6 ms | 1–2 |
| 10–15 | ~0.8–1.2 ms | 3–5 |
| 30 | ~1.5–2.5 ms | 6–10 |

Epic's advice is to merge emitters that differ only in looks or starting data, and to use spawn groups or mesh arrays instead of duplicated emitters [7]. Unreal 5.4+ "Lightweight Emitters" skip the scripting VM. One measurement of 10 emitters showed CPU going from 1.2 ms to 0.4 ms and GPU from 0.6 ms to 0.3 ms [5][7].

**Fewer, bigger, better particles.** Azur Games' examples [3]:
- A projectile impact went from about 30 particles to 10 by baking an expanding wave into one textured particle, then to 2 (flash plus wave). Ten simultaneous impacts dropped from 300 particles to 20.
- Smoke plus sparks went from 200 particles to 50, with sparks kept only as accents.
- A tornado made of many particles became one mesh with a scrolling noise shader.

Snap adds a warning: don't raise the particle count to make up for particles that are too small or too transparent to see [21].

**Module cost.** In Unity's legacy Shuriken system, enabling one module (world space, collision, noise, trails, sub-emitters, or curves with more than 8 segments) switches a system from *procedural* to *non-procedural*. It then has to keep simulating while off-screen [25]. Azur Games replaces collision with *Limit Velocity over Lifetime*, tuned so particles stop at the floor, and replaces noise with hand-made velocity curves [3]. The general principle: anything that needs world state or per-frame randomness can't be skipped or fast-forwarded (analysis).

**Collision is expensive.** In Godot, GPU particle collision with screen-space SDF made particles very slow on Android. A maintainer pointed to SDF generation, not the particles, as the cost (snippet) [17]. Godot offers cheaper options: box or sphere colliders, a baked `GPUParticlesCollisionSDF3D`, or `GPUParticlesCollisionHeightField3D` for open ground [22].

### 2.4 LOD, culling and scalability

- **Bounds.** Culling only works if the bounds are right. Bounds that are too small make effects pop out at screen edges. Bounds that are too large waste simulation and draw time. Niagara recommends fixed bounds, except for small effects that travel far [7]. Unity VFX Graph recommends *Recorded* bounds over Automatic, which forces simulation every frame (snippet) [11]. Godot uses `visibility_aabb`, which defaults to AABB(-4,-4,-4, 8,8,8). The editor can generate it from the effect (*GPUParticles3D → Generate Visibility AABB*) [9].
- **Distance culling and LOD.** Unreal's docs recommend LODs for near and far emission, and checking for emitters stacked along a line [2]. Godot's general advice is to use visibility ranges to hide particle effects too far away to notice [26].
- **Significance and instance caps.** Niagara Effect Types control cull distance, maximum instances and spawn-count scale per quality level and platform. A community example: Medium quality halves the smoke trail spawn count, and Low keeps only the core emitter [5][7].
- **Unity custom culling.** `CullingGroup` bounding spheres pause off-screen systems. Call `Simulate` on resume so they don't appear frozen [25].
- **Off-screen behaviour.** Watch for effects that keep ticking after they stop rendering. Epic notes that a culling delay of about one second after an instance stops rendering adds ongoing overhead when many are spawned [13]. A Unity forum user saw an idle VFX Graph effect set to "always simulate" use about 10% GPU with no particles (snippet; may be editor-only) [11].

### 2.5 Pooling, priming and pre-warming

There are three different "warm" concepts, and they get confused:

1. **Object pooling** means reusing instances instead of creating and freeing them. On mobile, frequent create/destroy calls are a classic hitch source. Return an effect to the pool on its finish callback (snippet) [27]. Niagara has built-in pooling through *Spawn System at Location* and *Spawn System Attached*, with pool size and priming set per system. Epic warns that priming "can cause hitches if the asset is loaded dynamically" [7].
2. **Simulation pre-warm** means starting a looping effect as if it had already run (Unity *Prewarm*, Godot `preprocess`). It is costly: Epic says to avoid warmup because each warmup frame is evaluated in sequence [7]. Godot says high `preprocess` values "can be very expensive" and can even crash the GPU at extreme values [9]. Unity's prewarm only applies to looping systems (snippet) [27].
3. **Shader and pipeline warm-up** means making sure the GPU pipeline exists before the effect first appears. This is the usual "first explosion freezes the game" bug. Godot users report that `preload` alone does not fix it. The fix that works is rendering each effect once behind a loading screen or wall [28].

A related tip: spread big particle bursts across several frames, and add particles to an existing system for short repeated bursts such as impacts, rather than spawning a new instance each time [7].

### 2.6 Low-resolution (off-screen) particles

NVIDIA's GPU Gems 3, chapter 23, is still the reference [12]. Render soft particles into a buffer at 1/2 or 1/4 resolution, test against a downsampled depth buffer, then composite back. Taking the max of four depth samples during downsampling avoids halos. A Sobel edge pass marks blocky edges in a stencil mask, and those pixels are re-rendered at full resolution.

Results at 1600×1200 on a GeForce 8800 GTX with a 73-instruction particle shader:

| Mode | FPS |
|---|---|
| Full resolution | 25 (46.9M particle pixels) |
| Mixed resolution, 4×4 | 51 (3.5M particle pixels) |
| Low resolution, 4×4, max-z | 61 |

The win shrinks with cheap shaders and small particles. At about 3.5M full-resolution particle pixels the two approaches broke even [12]. Use it for smoke, fog and dust, not for sparks or debris.

### 2.7 Shader / pipeline compilation (Godot 4.4–4.7)

From Godot's pipeline-compilation docs [10]:

- **Ubershaders.** Godot uses specialisation constants so the driver can optimise each pipeline. It compiles one generic ubershader pipeline first and builds the specialised versions in the background, so specialisation costs some frame rate but doesn't stutter.
- **Load-time precompilation (4.4+).** When a mesh or material is loaded, Godot precompiles the pipelines it can predict. Load meshes on background threads to keep this off the main thread.
- **Monitors.** The debugger has pipeline-compilation monitors: *Canvas*, *Mesh*, *Surface*, *Draw* and *Specialization*. Values only go up. A rise outside a loading screen means a likely hitch. *Draw* compilations "should never happen" with ubershaders, so report them if you see any.
- **Gaps that matter for VFX:**
  - Particle effects instanced from script during play may not be precompiled until they have been instanced once.
  - Material overrides are not covered at the Mesh step.
  - Turning on renderer features mid-game (MSAA level, reflection probes, shadow precision, and so on) causes stutter. Enable them early.
- **Recommended workaround:** keep a hidden instance of each spawned effect attached to an always-present node, such as the player. Or render it for one frame behind a `ColorRect` or in an off-screen `SubViewport`.
- **Shader baker (4.5+).** Enable it per export preset with *Shader Baker → Enabled*. It stores compiled intermediate shaders (SPIR-V, DXIL or MIL) in the PCK, which makes the PCK a few MB larger. This mostly speeds up first launch, especially on D3D12 and Metal. It does not remove pipeline stutter. It only bakes for the selected `rendering/rendering_device/driver`. It needs a Windows host for D3D12 and a macOS host for Metal, and it is not available for web, Compatibility or `--headless` exports.
- **Compatibility renderer:** none of the above applies. Show every material and particle effect for at least one frame while loading.
- **Drivers** cache pipelines on disk, but a driver update usually clears that cache. Test with a cleared cache to see what a first-time player sees [10].

### 2.8 Texture atlases and materials

- Pack effect textures into shared atlases and use one master material driven by per-particle custom data (brightness, emissive, scroll speed, alpha mode). Fewer materials means fewer draw calls and fewer pipelines to compile [3].
- Fill the flipbook frame. Flipbook cells with lots of empty space mean more particles and more wasted quad area [19][3].
- Texture size: about 512–1024 px per texture on PC and console, with a shared master material (community guide) [5]. Turn off anisotropic filtering on particle textures [20].
- In Godot, VRAM compression doesn't support alpha on most Android devices. Plan alpha-heavy VFX textures with that in mind [16].
- Move uniform maths (UV panning, tiling, brightness) from the fragment shader to the vertex shader [3]. Avoid grab-pass or screen-texture reads on mobile [3].

### 2.9 Budgets by platform

There is no universal number. These are the figures I could find, with how reliable each one is:

| Source | Platform | Budget |
|---|---|---|
| DICE VFX lead (secondhand notes) [4] | PS4/XB1/PC, *Star Wars Battlefront* (2015) | Effects "just over 1 ms" of frame time (snippet) |
| Community Unreal guide [5] | High-end PC | Niagara tick under 2–3 ms |
| | PS5 / Series X | under 2 ms |
| | PS4 / Xbox One | under 1.5 ms |
| | Mobile / VR | under 1 ms |
| Same guide, pixel shader instructions (recommended / max) [5] | PC | 250–300 / 400+ |
| | PS5 / XSX | 250–350 / 400+ |
| | PS4 / XB1 | 180–220 / 250–280 |
| | Mobile | 80–120 / 150–180 |
| | VR / AR | 100–150 / 200 |
| Azur Games [3] | Mobile midcore | 3–10 particles per unit effect when 200 units may fire it |

**Frame budgets (analysis):** 60 FPS gives 16.67 ms, 30 FPS gives 33.3 ms, and 90 FPS VR gives 11.1 ms. A common habit is to give VFX about 5–10% of the GPU frame, roughly 1–1.5 ms at 60 FPS. That matches the Battlefront figure. Budget for the *worst* moment: every effect alive at once, closest to the camera, at the highest resolution you support. Measure tick (CPU) and GPU time separately. Epic's docs split particle cost into game-thread simulation, render-thread packing and draw calls, and GPU overdraw (snippet) [1].

### 2.10 Profiling toolkit

- **Godot:** Visual Profiler (CPU and GPU rendering categories, in ms or % of target FPS; compare at the same viewport size; macOS Compatibility not supported) [14]. Monitors, including the pipeline-compilation monitors [10]. Video RAM tab [14]. Overdraw debug draw (analysis). Godot also has a RenderDoc integration for frame captures.
- **Unreal:** Unreal Insights with `-StatNamedEvents`, which adds overhead, so capture again without it for real timings. Niagara Debugger, Performance mode, Quad Overdraw and Shader Complexity [13].
- **Unity:** VFX Graph Profiling and Debug panel, which shows culled or visible state per system (snippet) [11]. Unity Profiler.
- **Mobile:** Arm Performance Studio (Streamline plus RenderDoc for Arm) (snippet) [18]. PVRTune [20].
- **RenderDoc** on any platform: per-draw timings, Quad Overdraw overlay, and inspecting particle textures and blend states.

---

## 3. Examples

- ***Star Wars Battlefront* (DICE, 2015).** Effects had to fit in about 1 ms because the photogrammetry assets took most of the GPU, so the team used fewer particles than *Battlefield 4*. Distant dogfights were faked with particles standing in for X-wings, TIE fighters and blaster bolts. Lighting was cheap per-vertex lighting plus texture-based volumetric approximations (snippet) [4]. What works: a cheap representation chosen to fit the budget, at a distance where nobody can tell.
- ***Star Wars Battlefront II* (Frostbite).** The first Frostbite game to ship GPU particles. The cheaper simulation allowed much denser effects (snippet) [24].
- **Kingdom Clash (Azur Games, mobile).** Unit effects are capped at 3–10 particles because 200 units can trigger them. Impacts are two particles with baked textures. Tornadoes are a single noise-shaded mesh [3]. What works: budgeting for crowds, and moving complexity into textures and shaders.
- **Humus smoke puff.** An 8-vertex fitted polygon roughly halves fill cost compared with a quad, with no visual change [6].
- **GPU Gems 3 smoke scene.** 1/4-resolution off-screen particles took the frame rate from 25 to 51 FPS [12].
- **Realtimevfx Niagara smoke thread.** The poster used bigger and fewer sprites, more spread, alpha-threshold culling and near-camera fade, and overdraw dropped visibly [19].

---

## 4. Common mistakes

1. **Counting particles instead of pixels.** Profile overdraw before cutting spark counts.
2. **Huge soft quads close to the camera.** Fade particles out near the camera (Godot `proximity_fade` or a distance fade) and cap their screen size.
3. **Untrimmed textures.** A puff that fills 40% of its frame wastes the other 60% on every layer [3].
4. **Using `amount_ratio` (or alpha 0) as an LOD.** The cost stays [8]. Lower `amount` or disable the emitter.
5. **One effect, many emitters.** Every emitter adds fixed CPU cost and a draw call. Merge them [7].
6. **GPU simulation for 10-particle bursts.** The GPU block cost is wasted. Use CPU particles or merge into a shared GPU system [7].
7. **Wrong bounds.** Default or automatic bounds either cull visible effects or never cull them [9][11].
8. **"Preload" as a fix for first-use stutter.** Loading a resource doesn't compile its pipeline. The effect has to be rendered [28][10].
9. **Big `preprocess` / prewarm on spawn.** This creates the hitch you were trying to avoid [7][9].
10. **Instantiating and freeing effects every shot.** Pool them.
11. **Collision, trails and noise on everything.** Use these only where they read on screen. Fake collision with velocity curves [3][25].
12. **Profiling at a different resolution, or only in the editor.** Fill-rate cost scales with pixel count [14][16].
13. **Leaving effects ticking off-screen.** Watch instance counts over a real play session [13].

---

## 5. Apply in Godot 4 (4.7, Forward+)

### 5.1 A budget for a project like *Unsent* (analysis)

At 60 FPS on a mid-range PC GPU, aim for:
- **VFX GPU time** of about 1.0–1.5 ms in the busiest scene;
- **fewer than 10 GPU particle systems** active at once;
- **3× or less average overdraw** across the effect's screen area.

A slow, melancholy game rarely needs dense bursts. The likely problem cases are close-up fire (the Vefects pack plus the custom flame billboards) and burning-leaf sub-emitters stacking up.

### 5.2 Measure first

1. Run the game and open the **Debugger → Visual Profiler**. Set `debugger/profiler_target_fps` to 60 and compare runs at the same window size [14].
2. In the 3D editor viewport menu, switch to **Display Overdraw** and walk the camera into each fire. At runtime:

```gdscript
# Toggle with a debug key; F-key handling omitted.
get_viewport().debug_draw = Viewport.DEBUG_DRAW_OVERDRAW  # back to DEBUG_DRAW_DISABLED
```

3. Run the fill-rate test: V-Sync off, compare FPS in a tiny window and a full-screen window [16].
4. Watch the **Monitors → pipeline compilations** graphs while a leaf first ignites. Any rise during gameplay is a hitch to fix [10].
5. For a per-draw breakdown, capture a frame in RenderDoc and use the Quad Overdraw overlay.

### 5.3 GPUParticles3D settings checklist

- `amount`: the real cost. Size it to the visual minimum. Don't rely on `amount_ratio` for savings [9].
- `visibility_aabb`: select the node, then use **GPUParticles3D → Generate Visibility AABB** while the effect plays. Add a little padding for wind [9].
- `fixed_fps = 30` (the default) with `interpolate = true`: the simulation runs at 30 Hz and stays smooth. For slow embers and leaves, 20 Hz is often enough (analysis).
- `preprocess`: keep at 0 for spawned effects. Use it only on looping ambient emitters that exist from level load [9].
- `draw_order`: `INDEX` (cheapest; supports motion vectors). Use `VIEW_DEPTH` only when sorting errors are visible on blended smoke [9].
- `trail_enabled`, collision, attractors, turbulence: only where they're visible. Prefer box or sphere colliders or a baked `GPUParticlesCollisionSDF3D` over relying on scene-wide collision [22]. Avoid heavy collision on mobile [17].
- **Visibility range** (GeometryInstance3D → *Visibility Range End* plus fade): hide ambient emitters past 25–40 m [26].
- On the **Mobile** renderer or for low-end exports, convert small bursts to CPUParticles3D (right-click → *Convert to CPUParticles3D*) [22][23].

### 5.4 Cheaper particle materials

For flame and smoke billboards in a spatial shader:

```glsl
shader_type spatial;
// unshaded: no light loop per pixel. Additive for flame cores, mix for smoke.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
// For lit smoke, drop 'unshaded' and add 'vertex_lighting' instead (per-vertex lighting).

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 frames = vec2(8.0, 8.0);
uniform float near_fade_start = 0.4; // metres
uniform float near_fade_end = 1.2;
uniform float alpha_kill = 0.02;

varying float v_near;

void vertex() {
    // Particle billboarding is handled by the particle draw pass / billboard flags.
    // Distance fade computed per vertex = cheap. Leave stock flipbook UVs to ParticleProcessMaterial if used.
    float d = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
    v_near = smoothstep(near_fade_start, near_fade_end, d);
}

void fragment() {
    vec4 c = texture(atlas, UV) * COLOR;
    c.a *= v_near;               // fade out before it fills the screen
    if (c.a < alpha_kill) discard; // skip near-invisible pixels (helps blending cost on some GPUs)
    ALBEDO = c.rgb;
    ALPHA = c.a;
}
```

Notes (analysis):
- `discard` doesn't save the cost of shading the pixel. It only skips the blend and write. The real saving comes from tighter geometry.
- On desktop, avoid `hint_screen_texture` refraction on large effects [5].
- A soft-particle depth fade needs a depth-texture read. Use it on smoke that touches walls, and skip it on airborne embers.

### 5.5 Tight-mesh particles in Godot

Godot has no built-in sprite cutout, so give the draw pass a custom mesh. Build an octagon (8 vertices) fitted to the flipbook's union alpha in Blender, export it as a `.glb` or `.obj` mesh, and assign it as **Draw Passes → Pass 1**. The UVs must map the octagon's vertices into 0–1 quad space so atlas sampling stays the same. With billboard enabled in the material (`Billboard Mode: Particle Billboard`), the mesh faces the camera like a quad. Expect around 40–50% fewer fragments on round puffs [6]. A quicker option is to trim the textures themselves so the content fills the frame [3].

### 5.6 Pooling and warm-up script

```gdscript
# vfx_pool.gd — autoload. Pools one-shot effects and pre-renders them once to compile pipelines.
extends Node3D

@export var effects: Array[PackedScene] = []   # e.g. burning_leaf.tscn, ember_burst.tscn
@export var per_effect := 4

var _pools := {}  # PackedScene -> Array[GPUParticles3D]

func _ready() -> void:
    for scene in effects:
        _pools[scene] = []
        for i in per_effect:
            var fx: GPUParticles3D = scene.instantiate()
            fx.one_shot = true
            fx.emitting = false
            add_child(fx)
            _pools[scene].append(fx)
    await _warm_pipelines()

func _warm_pipelines() -> void:
    # Render one copy of each effect for a couple of frames in front of the camera but hidden by
    # the loading-screen ColorRect (Godot docs: must actually render to compile).
    var cam := get_viewport().get_camera_3d()
    for scene in _pools:
        var fx: GPUParticles3D = _pools[scene][0]
        if cam:
            fx.global_position = cam.global_position - cam.global_basis.z * 2.0
        fx.restart()
    await get_tree().process_frame
    await get_tree().process_frame
    for scene in _pools:
        _pools[scene][0].emitting = false

func play(scene: PackedScene, xform: Transform3D) -> void:
    for fx: GPUParticles3D in _pools.get(scene, []):
        if not fx.emitting:
            fx.global_transform = xform
            fx.restart()
            return
    # Pool exhausted: drop the effect (budget!) rather than instantiating mid-game.
```

The `ColorRect` cover and the "render once" approach come from Godot's own docs [10]. Dropping an effect when the pool is exhausted acts as a hard instance cap, the same idea as Niagara's max instances (analysis). For frequent identical impacts, a single GPUParticles3D can be reused and fired through `emit_particle()`, which works on Forward+ and Mobile only [9]. That follows Epic's "add particles to an existing system" advice [7].

### 5.7 Notes for *Unsent* specifically (analysis)

- **Burning leaves with a flame sub-emitter.** The child's `amount` is shared by every parent particle that triggers it, so a child sized for 3 leaves will starve when 30 leaves burn at once. Size it for the worst case on screen and keep it small (20–40). Give the child a short `lifetime` and its own tight `visibility_aabb`. Run the parent at `fixed_fps` 20–30.
- **Vefects Stylized Fire.** Check its flipbooks in Display Overdraw up close. Usual fixes are: lower `amount` on the smoke layer, add a near-camera fade, and use an octagon draw-pass mesh for the large smoke and flame sprites. Per the project rules, don't modify the pack's files; make tuned copies or override materials instead. Material overrides also need pipeline warm-up [10].
- **Burn/dissolve shader.** This is opaque with `discard`, so it's fine for overdraw. But alpha-scissor or discard on many objects disables some early-depth optimisations, so test GPU time when lots of letters burn at once.
- **Glow plus AgX.** Additive cores push brightness into glow cheaply. You can often lower particle alpha and count and let glow carry the light.
- **Export.** Turn on **Shader Baker** in the Windows export preset for faster first launch. Keep the warm-up pass, because the baker doesn't remove pipeline hitches [10].
- **Scalability.** Add a "VFX quality" option that multiplies `amount` (set before `restart()`), disables trails and collision, and shortens visibility ranges on Low.

---

## 6. Sources

1. Epic Games, "VFX Optimization Guide: Results" / "Concepts" (UDK / UE3 docs) — https://docs.unrealengine.com/udk/Three/VFXOptimizationResults.html , https://udn.epicgames.com/Three/VFXOptimizationConcepts.html (search snippets; pages returned 403)
2. Epic Games, "Particle Systems Optimization" (UE 4.27 docs) — https://docs.unrealengine.com/4.27/RenderingAndGraphics/ParticleSystems/Optimization (snippet)
3. PocketGamer.biz (Azur Games), "VFX optimisation in midcore games: commonly overlooked techniques and advanced methods" — https://www.pocketgamer.biz/vfx-optimisation-in-midcore-games-commonly-overlooked-techniques-and-advanced-methods/
4. Giant Bomb user blog, "VFX Talk notes for Star Wars Battlefront" (Anders Egléus talk) — https://www.giantbomb.com/profile/cybexx/blog/vfx-talk-notes-for-star-wars-battlefront/113269/ (snippet; 403 on fetch)
5. Adam Komarowski, "Unreal Tech Art — VFX" (community guide) — https://adamkomarowski.github.io/unrealtechart/book/vfx/
6. Humus (Emil Persson), "Particle trimming" — https://www.humus.name/index.php?ID=266
7. Epic Games, "Scalability and Best Practices for Niagara" — https://dev.epicgames.com/documentation/unreal-engine/scalability-and-best-practices-for-niagara
8. Godot docs, GPUParticles3D class (latest) — https://docs.godotengine.org/en/latest/classes/class_gpuparticles3d.html
9. Godot docs, GPUParticles3D class (4.7) — https://docs.godotengine.org/en/4.7/classes/class_gpuparticles3d.html
10. Godot docs, "Reducing stutter from shader (pipeline) compilations" (4.7) — https://docs.godotengine.org/en/4.7/tutorials/performance/pipeline_compilations.html
11. Unity, "Visual effect bounds" (VFX Graph 17) and forum "VFX Graph: Idle VFX objects wasting a lot of GPU?" — https://docs.unity3d.com/Packages/com.unity.visualeffectgraph@17.0/manual/visual-effect-bounds.html , https://discussions.unity.com/t/vfx-graph-idle-vfx-objects-wasting-a-lot-of-gpu/1689550 (snippets)
12. NVIDIA, GPU Gems 3, Ch. 23 "High-Speed, Off-Screen Particles" — https://developer.nvidia.com/gpugems/gpugems3/part-iv-image-effects/chapter-23-high-speed-screen-particles
13. Epic Games, "Measuring Performance in Niagara" — https://dev.epicgames.com/documentation/en-us/unreal-engine/measuring-performance-in-niagara
14. Godot docs, "Debugger panel" (4.7) — https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/debugger_panel.html
15. Unity, "Profiling and Debug Panels" (VFX Graph) — https://docs.unity3d.com/Packages/com.unity.visualeffectgraph@17.0/manual/performance-debug-panel.html (snippet)
16. Godot docs, "GPU optimization" (4.5) — https://docs.godotengine.org/en/4.5/tutorials/performance/gpu_optimization.html
17. Godot GitHub issue #83744 (particle collision slow on Android) — https://github.com/godotengine/godot/issues/83744 (snippet)
18. Arm, Mali best-practices / Mali Graphics Debugger and Performance Studio posts — https://developer.arm.com/community/arm-community-blogs/b/mobile-graphics-and-gaming-blog/posts/new-developer-guide-arm-mali-application-developer-best-practices , https://community.arm.com/arm-community-blogs/b/graphics-gaming-and-vr-blog/posts/new-mali-graphics-debugger-v1-2-features-improve-fragment-performance (snippets)
19. realtimevfx.com, "Niagara and VFX optimization, how?" — https://realtimevfx.com/t/niagara-and-vfx-optimization-how/25656
20. Imagination Technologies, "Optimal Particle Rendering on PowerVR" — https://docs.imgtec.com/performance-guides/graphics-recommendations/html/topics/optimal-particle-rendering-on-powervr.html
21. Snap Lens Studio, "VFX Graph Optimization" — https://developers.snap.com/lens-studio/learning-lens-studio/graphics/particles/vfx-editor/vfx-graph-optimization (snippet)
22. Godot docs, "Particle systems (3D)" (4.7) — https://docs.godotengine.org/en/4.7/tutorials/3d/particles/index.html
23. Godot blog, "Progress report: State of particles" — https://godotengine.org/article/progress-report-state-of-particles/
24. EA Answers HQ, "Community Transmission: Visual Effects in Star Wars Battlefront II" — https://answers.ea.com/t5/Announcements/Community-Transmission-Visual-Effects-in-Star-Wars-Battlefront/td-p/9036396 (snippet)
25. Unity blog, "#UnityTips: ParticleSystem Performance – Culling" — https://unity.com/blog/engine-platform/particlesystem-performance-culling-tips
26. Godot docs, "Optimizing 3D performance" — https://docs.godotengine.org/en/stable/tutorials/optimization/optimizing_3d_performance.html (snippet)
27. Unity docs "ParticleSystem.MainModule.prewarm" and DEV Community pooling article — https://docs.unity3d.com/ScriptReference/ParticleSystem.MainModule-prewarm.html , https://dev.to/unitysourcecode/unity-object-pooling-the-single-optimization-that-fixes-most-mobile-performance-issues-3g5b (snippets)
28. Godot Forum threads on first-emit particle stutter — https://forum.godotengine.org/t/particles-huge-lag-spike-on-first-instance/45839 , https://forum.godotengine.org/t/handling-particle-shader-compilation-lag-in-godot-4-web-compatibility-renderer/36170 (snippets)
