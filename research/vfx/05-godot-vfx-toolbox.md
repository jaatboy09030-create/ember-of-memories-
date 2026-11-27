# 05 — Making VFX in Godot 4: the complete toolbox

Scope: every built-in tool Godot 4.x gives a VFX artist, from GPUParticles to CompositorEffects. It covers how the tools combine, what changed between 4.0 and 4.7 (plus a peek at 4.8), where the community resources are, and the known limitations with their workarounds.
Tags used below: "(snippet)" means the claim comes only from a search-result snippet. "(analysis)" means my own reasoning or engine knowledge that I did not re-verify against a page during this research.

---

## 1. Key takeaways

- **GPUParticles3D/2D with a ParticleProcessMaterial is the workhorse. CPUParticles is frozen.** Since 4.2, new CPUParticles features are accepted only if they have a GPU counterpart. CPUParticles also lacks trails, collision nodes, attractors and sub-emitters. [1][4]
- **A particle has two shaders.** The *process* side (a ParticleProcessMaterial or `shader_type particles`) moves the particle. The *draw* side (StandardMaterial3D or a spatial/canvas_item shader on the draw-pass mesh) renders it. Colour ramps, flipbooks and alpha curves only show up if the draw material reads them: Vertex Color > Use As Albedo, Billboard = Particle Billboard. [2][10]
- **Godot 4.2 overhauled ParticleProcessMaterial** and added:
  - `amount_ratio` and `interp_to_end`;
  - `velocity_pivot`, directional, radial and orbit velocity curves;
  - `velocity_limit`, `scale_over_velocity` and `inherit_velocity_ratio`;
  - a separate `alpha_curve` and `emission_curve`;
  - damping-as-friction.

  Most tutorials written before 4.2 under-use these properties. [4]
- **`amount_ratio` is the intensity knob.** You can drive it at runtime without restarting the system. It saves no GPU memory, because the full `amount` is still allocated. Changing `amount` itself restarts the system. [11]
- **To fire a burst, call `restart()`.** Setting `emitting = true` on a one-shot system does nothing until every particle is dead. The `finished` signal fires only for one-shot systems. [11]
- **Sub-emitters chain without a depth limit.** The child's own `amount` caps how many particles it can have alive, and its `explosiveness` is ignored. A custom particle shader can spawn sub-particles anywhere with `emit_subparticle()`. [7][3]
- **Trails are built in, but need work for sword slashes.**
  - Turn on `trail_enabled`, give the draw pass a RibbonTrailMesh or TubeTrailMesh, and enable `use_particle_trails` on the draw material.
  - Trails don't work in the Compatibility renderer.
  - For sword-slash arcs, most people use swipe meshes or the GPUTrail addon. Godot 4.8-dev adds a native `Trail3D` node. [5][18][25]
- **Collision and attractors are GPU-only proxies.** Particles can't see the physics world. They see Box/Sphere/SDF/Heightfield colliders and Box/Sphere/VectorField attractors, filtered by cull mask and the particle system's visibility AABB. Neither exists in 2D. [6][9]
- **Turbulence uses 3D noise, which is expensive.** Keep it to a few systems on screen, and avoid it on mobile and web. [8]
- **Screen-space effects:**
  - For distortion, use `hint_screen_texture`. It is copied after the opaque pass, so it never contains other transparents.
  - For soft particles, use `hint_depth_texture` or StandardMaterial3D Proximity Fade.
  - For full-screen passes, use a CompositorEffect (4.3+, Forward+/Mobile only, runs on the render thread). [14][13][16]
- **Shader-compile hitches on first emission are real.** Godot 4.4 added ubershaders and pipeline precompilation, and 4.5 added a shader baker. Even so, warming every effect for one frame behind a cover is still common practice. [17][19][20]
- **The 4.6 glow change matters for VFX.** Glow is now blended before tonemapping, and the default blend mode is Screen. Emissive VFX tuned in 4.5 or earlier may look different, so re-check bloom-heavy effects after upgrading. [21]

---

## 2. Deep dive

### 2.1 GPUParticles3D / 2D node properties

Defaults below are from the 4.7 class reference [11].

| Property | Default | Notes |
|---|---|---|
| `amount` | 8 | Emission rate = amount ÷ lifetime. For example, 32 particles over 4 s emit 8 per second [10]. Changing it restarts the system. |
| `amount_ratio` | 1.0 | Runtime 0–1 multiplier. It doesn't restart the system or touch live particles [10][11]. |
| `lifetime` | 1.0 | Seconds. |
| `one_shot`, `explosiveness`, `randomness` | false, 0, 0 | `randomness` does nothing when explosiveness = 1 [10]. |
| `preprocess` | 0 | Pre-warms the system. Very large values are expensive and can crash the GPU in extreme cases [11]. |
| `fixed_fps` | 30 | Simulation rate. Leave `interpolate` on (the default) to hide the steps. Set it to 0 for smooth flipbooks [12]. Raise it so fast particles don't tunnel through thin colliders [6]. |
| `fract_delta` | true | Spreads emission times across sub-frames. |
| `interp_to_end` | 0 | Pushes every particle toward end-of-life together. Good for a graceful "kill". Works only with ParticleProcessMaterial [4][11]. |
| `local_coords` | **false** | World-space by default, so particles stay behind a moving emitter. Turn it on for effects that should move with the emitter, such as a held torch flame, auras and muzzle flashes [10]. |
| `draw_order` | INDEX | Lifetime, Reverse Lifetime and View Depth also exist. Only INDEX supports motion vectors, so it gives the least TAA ghosting on opaque particles [11]. |
| `transform_align` | Disabled | Options: Z-Billboard, Y-to-Velocity, or Z-Billboard + Y-to-Velocity. Use Y-to-Velocity for sparks and stretched streaks [10]. |
| `visibility_aabb` | (-4,-4,-4, 8,8,8) | The system is culled outside this box, and collision only happens inside it. Use *Generate Visibility AABB* to fit it [6][11]. |
| `collision_base_size` | 0.01 | Collision radius. Particles always collide as spheres [11]. |
| `trail_enabled` / `trail_lifetime` | false / 0.3 | See 2.4. |
| `use_fixed_seed` / `seed` | false / 0 | Gives a deterministic effect, such as an identical impact every time. `restart(keep_seed)` keeps the same seed [11]. Believed to have arrived in 4.4 (analysis). |
| `draw_passes` | 1 | Up to 4 meshes per particle, for example a glow quad plus a core mesh (analysis). |

Methods [11]:
- `emit_particle(xform, vel, color, custom, flags)` spawns one particle from script. Flags: POSITION = 1, ROT_SCALE = 2, VELOCITY = 4, COLOR = 8, CUSTOM = 16. Not available in Compatibility.
- `capture_aabb()` returns the bounds of the live particles.
- `convert_from_particles()` copies settings from a CPU system.
- `request_particles_process(t)` fast-forwards the simulation.

### 2.2 ParticleProcessMaterial: the properties worth knowing

Grouped as in the inspector [1][12].

**Spawn**
- `emission_shape`: Point, Sphere, Sphere Surface, Box, Ring (axis, height, radius, inner radius, cone angle), Points, or Directed Points.
- `emission_shape_offset` and `_scale` (4.2+).
- Points and Directed Points read baked textures. Generate them with *Create Emission Points From Mesh/Node*, which gives you embers off a burning book or sparks along a sword edge.
- Direction alone does nothing. Also set a velocity or an acceleration, since both default to 0 [12].
- `spread`: 0 is a laser, 180 is omnidirectional debris. `flatness` = 1 flattens the spread onto the XZ plane, which suits ground splashes.

**Velocity**
- `initial_velocity_min/max`.
- `inherit_velocity_ratio`: the share of emitter velocity a particle takes at spawn. Use it for exhaust and for footstep dust that should drift with the player.
- `velocity_pivot`, plus radial, orbit and directional velocity, each with curves. Orbit and directional velocity need a CurveXYZTexture.
- `velocity_limit_curve`: a hard speed cap over the particle's life [4].

**Accelerations**
- `gravity` (default `(0,-9.8,0)`).
- `linear_accel`, `radial_accel`, `tangential_accel`. Tangential acceleration makes spirals whose radius grows.
- `damping`, or `damping_as_friction` for a percentage-of-speed falloff, which reads better for sparks [1][12].

**Display**
- `scale_min/max` and `scale_curve`. A CurveXYZTexture gives per-axis scale. For billboards, enable Keep Size on the material.
- `scale_over_velocity` stretches particles as they speed up.
- `color` and `color_initial_ramp` (variation per particle at spawn).
- `color_ramp` (colour over life).
- `alpha_curve` and `emission_curve`. Both multiply COLOR, so the draw shader must use COLOR [4].
- `hue_variation`.
- `angle` and `angular_velocity`. These need the Rotate Y flag unless the draw material uses Particle Billboard [12].

**Animation**
- `anim_speed`: 1 = one full flipbook cycle per lifetime.
- `anim_offset` sets the starting frame (0–1).
- Flipbook FPS = frames ÷ lifetime. A 64-frame sheet over 8 s plays at about 8 fps, which looks choppy. Raise the speed or shorten the lifetime [12].

**Turbulence**
- `turbulence_noise_strength` (default 1). The docs show 1 as soft and 20 as distinct.
- `turbulence_noise_scale` (default 9). 1.5 gives fine detail, 6 gives coarser swirls.
- `turbulence_noise_speed` pans the noise; it is not particle speed. `turbulence_noise_speed_random` (0.2) hides repetition.
- `turbulence_influence_min/max` (0.1) and `influence_over_life`.
- `initial_displacement` breaks up regular spawn shapes; the docs show 5 as moderate and ±20 as strong.
- Turbulence bends motion that already exists. It does not create motion [8].

**Collision**
- `collision_mode`: Disabled, Rigid, or Hide On Contact. `bounce` and `friction` range 0–1.
- `collision_use_scale` makes the collision size follow the particle's scale [1].

**Sub-emitter**
- `sub_emitter_mode`: Constant (uses `frequency`), At End, At Collision, or At Start, each with its own amount.
- `sub_emitter_keep_velocity` passes on the parent's velocity [1].

**Attractors**
- `attractor_interaction_enabled` must be on [9].

**Lifetime**
- `lifetime_randomness`: the lifetime is scaled by `1 − rand × value` [1].

**Converting to code**
- Right-click the material and choose **Convert to ShaderMaterial**. You get readable shader code with every enabled feature, which is the best way to learn `shader_type particles` [12].

### 2.3 `shader_type particles`

Built-ins per the 4.7 reference [3]:

- **`start()`** runs on spawn and restart. **`process()`** runs every simulation tick.
- Particle shaders keep their data between frames. Use `render_mode keep_data` to keep it across a restart as well.
- **Other render modes:** `disable_force` (ignores attractors), `disable_velocity` (you move TRANSFORM yourself), `collision_use_scale`.
- **Read/write (inout):** `TRANSFORM`, `VELOCITY`, `COLOR`, `CUSTOM` (vec4), `MASS` (default 1, used by attractors), `ACTIVE` (set it to false to kill the particle).
- **Inputs:**
  - `LIFETIME`, `DELTA`, `INDEX`, `NUMBER`, `RANDOM_SEED`;
  - `EMISSION_TRANSFORM`, `EMITTER_VELOCITY`;
  - `INTERPOLATE_TO_END`, `AMOUNT_RATIO`;
  - `USERDATA1..6`.
- **Process-only inputs:** `RESTART`, `COLLIDED`, `COLLISION_NORMAL`, `COLLISION_DEPTH`, `ATTRACTOR_FORCE`.
- **Start-only inputs:** the `RESTART_POSITION`, `RESTART_ROT_SCALE`, `RESTART_VELOCITY`, `RESTART_COLOR` and `RESTART_CUSTOM` booleans. They tell you whether `emit_particle()` or `emit_subparticle()` already supplied that value, so you don't overwrite it.
- **Sub-particle spawning:** `bool emit_subparticle(mat4 xform, vec3 velocity, vec4 color, vec4 custom, uint flags)`, with flags `FLAG_EMIT_POSITION | FLAG_EMIT_ROT_SCALE | FLAG_EMIT_VELOCITY | FLAG_EMIT_COLOR | FLAG_EMIT_CUSTOM`. The node's `sub_emitter` path decides which system receives the particle.
- **Passing data to the draw shader:** whatever you write to `CUSTOM` arrives in the spatial shader as `INSTANCE_CUSTOM`. It is the main channel for per-particle data such as age, seed or a dissolve threshold.
- **How the generated ParticleProcessMaterial code uses CUSTOM (analysis; confirm by converting a material):**
  - `CUSTOM.x` holds the rotation angle.
  - `CUSTOM.y` holds normalised age (0→1).
  - `CUSTOM.z` holds the flipbook frame.
  - `CUSTOM.w` holds the lifetime scale.

  Built-in billboard materials read `INSTANCE_CUSTOM.z` for the flipbook frame. Keep this layout if you mix custom code with StandardMaterial3D draw passes.

### 2.4 Trails

- **Setup** [5]:
  - Set `trail_enabled` and `trail_lifetime` (about 0.8 s is a good start).
  - Put a RibbonTrailMesh or TubeTrailMesh in Draw Pass 1.
  - Tick *Use Particle Trails* in the draw material's Transform group.
- **Ribbon properties** [5]:
  - `shape`: Flat suits billboards; Cross makes two perpendicular quads.
  - `size`, `sections` × `section_length` (= length), `section_segments`, and a width `curve` from head to tail.
- **Tube properties** [5]:
  - `radius`, `radial_steps`, `sections`, `section_rings` and `curve`.
  - Set `transform_align` to Y-to-Velocity, or tubes flatten when they turn.
- **Limitations:**
  - Trails don't work in Compatibility [5].
  - Each trail belongs to one particle, so a weapon arc needs an emitter that moves with the blade and has `local_coords` off.
  - Forum users report that sword slashes are awkward to build this way (snippet) [26].
- **Alternatives:**
  - celyk's **GPUTrail** addon: GPU ribbon, colour ramp, width curve, billboard mode, dewiggle and clip-overlaps. It has no flipbooks and no custom materials yet [25].
  - **Trail3D**, a native node merged by QbieShay in 4.8-dev4 that handles mesh and UVs automatically [18].

### 2.5 Collision, attractors, sub-emitters

**Colliders** (`GPUParticlesCollision*`) [6]:
- **Box and Sphere:** cheap, and can be animated.
- **HeightField:** built at runtime from meshes. Update mode is When Moved or Always, and it can follow the camera. It can't represent room-over-room geometry. Best for outdoor rain and snow.
- **SDF:** baked in the editor at a resolution from 16 to 256, with a `thickness` setting for thin walls. Static only, Forward+/Mobile only, more expensive. Best for interiors.
- **Requirements:** at least one of the particle system's visibility layers must be enabled in the collider's cull mask, and the two AABBs must overlap.

**Attractors** (`GPUParticlesAttractor*`) [9]:
- **Box, Sphere and VectorField.** The vector field takes a 3D texture where mid-grey means no force, and its Y axis is flipped. A NoiseTexture3D with a colour ramp makes a quick field.
- **Settings:**
  - `strength`: negative values repel.
  - `attenuation`: a curve.
  - `directionality`: 0 pulls toward the centre, 1 pushes along the attractor's local −Z.
  - `cull_mask`.
- **Uses:** soul-suck, mana pickups flowing to the player, and vortex portals.

**Sub-emitters** [7]:
- On the parent, set `sub_emitter` to the child system and choose a mode other than Disabled.
- A child stops emitting on its own as soon as it becomes a sub-emitter.
- A system can't be its own sub-emitter.
- In instanced scenes, the child needs Editable Children.

**Collision as a trigger (Matt Ostertag's burning sphere)** [22][23]:
- A base particle system covers a mesh and is set to Hide On Contact with sub-emitter At Collision.
- A moving collision node "touches" it, which spawns embers.
- He calls it a hack: particles spawn across the whole mesh, not only at the contact point.

### 2.6 Draw side: billboards, soft particles, VisualShader vs code

**Billboard modes (StandardMaterial3D)** (analysis):
- Disabled.
- Enabled: faces the camera.
- Y-Billboard: rotates around Y only, which suits upright flames and trees.
- Particle Billboard: faces the camera, honours the particle's `angle`, and unlocks the Particles Anim (flipbook) group.
- Add *Keep Scale* so the particle's scale isn't lost.

**Billboarding in a spatial shader** (analysis):
- Write `MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);`.
- Then multiply in the scale taken from MODEL_MATRIX.
- "Convert to ShaderMaterial" on a Particle Billboard material gives you the exact generated code.

**Soft particles**
- On StandardMaterial3D, enable *Proximity Fade* and set the distance.
- In a custom shader, compare scene depth with `VERTEX.z`. The godotshaders "Mesh Blend / Soft Particles" shader does this with one smoothstep line [27]:
  - sample `hint_depth_texture`;
  - reconstruct view-space depth with `INV_PROJECTION_MATRIX`;
  - set `ALPHA *= clamp(1 - smoothstep(view.z + fade, view.z, VERTEX.z), 0, 1)`.
- Compatibility builds NDC differently. Use `#if CURRENT_RENDERER == RENDERER_COMPATIBILITY` [27].
- Per that page's author, Proximity Fade on OpenGL was fixed in 4.6 (snippet-level; unverified) [27].

**Screen texture**
- Declare `uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;`. Use a mipmap filter if you want blurred reads through `textureLod`.
- In 3D the copy is taken after opaques and before transparents. A heat-haze quad therefore can't see the fire billboards behind it, and the material using it is itself treated as transparent [14].
- `hint_normal_roughness_texture` is Forward+ only [14].

**VisualShader vs code**
- VisualShader has a Particles mode with Start, Process, Collide and custom stages, plus emitter nodes (analysis).
- 4.3 added reroute and frame nodes [16]. 4.4 added a material preview dock and lets you drag meshes into the graph to create mesh emitters [19].
- 4.8-dev adds node groups [18].
- Code shaders are better for anything with loops, hash functions or `emit_subparticle`. They also diff cleanly in git (analysis).
- Le Lu's stylized-fire tutorial (a cylinder plus shader math in VisualShader) is the canonical VisualShader VFX walkthrough [28][29].

**Blend modes**
- Mix, Add and Premultiplied Alpha (3D since 4.3).
- Premultiplied alpha lets one texture be additive where alpha = 0 and normal where alpha = 1. In 4.3's flame example, a single particle carries both the glow and the smoke [16].

### 2.7 Mesh-based effects, decals, AnimationPlayer

**Swipe and slash meshes**
- Model a curved ribbon (an arc of about 120–270°) with UVs running along the arc.
- In the shader, pan or erode a mask along UV.x driven by one `progress` uniform, multiply it by a gradient, and add.
- Drive `progress` with an AnimationPlayer: ramp it 0→1 over roughly 4–6 frames, then fade over the next 6–10 (analysis).
- GDQuest's juicy-attack demo uses a smear shown only during the forward swing. Its other timing tools [24]:
  - a one-frame anticipation;
  - a hit flash, using a shader `active` bool keyed in the AnimationPlayer;
  - hit-stop: `Engine.time_scale = 0.07` for 0.3 s of real time.

**Shockwave rings**
- Use a flat ring or torus mesh, scaled up from 0 with an ease-out curve.
- Alpha and thickness fall off over 0.5–2 s, matching the durations in Vefects' 90-variant shockwave pack [30].
- A distortion variant samples `screen_texture` offset by the ring's normal or UV gradient.

**Decals**
- Albedo, normal, ORM and emission textures, with `modulate` and `albedo_mix`. Albedo mix = 0 gives normal-only decals for footprints and puddles.
- `normal_fade`, upper/lower fade, and distance fade.
- No custom shaders. Cost scales with screen coverage more than with count [15].
- In Forward+, decals share the 512 clustered-element budget with lights and probes. On Mobile, a mesh receives at most 8 decals [15].
- Animate fade-out and emission energy for scorch marks that cool from orange to black.
- 4.8-dev brings decals to Compatibility, with a hard cap of 8 per surface [18].

**AnimationPlayer as the VFX sequencer** (analysis):
- One `.tscn` per effect, with a root Node3D and an AnimationPlayer.
- Tracks:
  - call `restart()` on each GPUParticles node;
  - key shader parameters (`progress`, `dissolve`, emission energy);
  - key light energy for a short flash light;
  - key mesh scale;
  - end with `queue_free` or return the effect to a pool.
- This is how Vefects, Binbun and most asset-store packs ship their effects: drag-and-drop scenes with editable ShaderMaterials [30][31].

### 2.8 CompositorEffects

- **Setup** [13]:
  - Subclass `CompositorEffect` (`@tool`).
  - Set `effect_callback_type` in `_init()`, for example `EFFECT_CALLBACK_TYPE_POST_TRANSPARENT`.
  - Override `_render_callback(type, render_data)`.
- **Inside the callback** [13]:
  - Get `RenderSceneBuffersRD`, then `get_internal_size()`.
  - For each view, wrap `get_color_layer(view)` in an `RDUniform` and use `UniformSetCacheRD.get_cache()`.
  - Run a compute list: begin, bind pipeline, bind uniforms, set push constants, dispatch in 8×8 groups, end.
  - Push constants must be 16-byte aligned.
- **Attaching:** add the effect to a `Compositor` on a WorldEnvironment or a Camera3D.
- **Constraints:** 3D pipeline only, Forward+/Mobile only, runs on the render thread (use a Mutex for shared data). Precompiled `.glsl` is better than runtime compilation for shipping.
- **Uses:** radial blur on big hits, chromatic aberration pulses, god rays, outlines, full-screen shockwave distortion that *does* include transparents, and colour-grade flashes.
- **References:**
  - the official compute post-process demo (snippet) [32];
  - ARez's MIT lens-flare and god-rays effect (4.4+) (snippet) [33].

### 2.9 Version timeline, 4.0 → 4.7 (and 4.8-dev)

- **4.0:**
  - GPUParticles rewritten with collision nodes, attractors, sub-emitters and trails.
  - Turbulence landed during the 4.0 cycle (analysis).
  - Particle shaders gained `start()` and `emit_subparticle` [34][3].
- **4.2:**
  - The ParticleProcessMaterial overhaul listed in section 1.
  - `amount_ratio` and `interp_to_end`.
  - A CPU→GPU converter.
  - CPUParticles feature-frozen [4].
- **4.3:**
  - CompositorEffects.
  - Premultiplied-alpha blend for 3D.
  - Render graph: 5–15 % faster, more with heavy GPUParticles use.
  - VisualShader reroute and frame nodes.
  - Depth fog [16].
- **4.4:**
  - Ubershaders and pipeline precompilation, which cut first-use hitches.
  - Editor visualisation of 3D emission shapes.
  - AgX tonemapper.
  - VisualShader preview dock and mesh-emitter drag-in [19][17].
- **4.5:**
  - Stencil buffer, useful for portals, x-ray outlines and "inside the bubble" masks.
  - Shader baker (up to 20× faster loads on Metal and D3D12).
  - SMAA 1x [20].
- **4.6:**
  - Glow blended before tonemapping, with Screen as the default blend.
  - AgX `white` and `contrast` controls.
  - SSR overhaul.
  - Octahedral reflection probes [21].
- **4.7:**
  - Tweakable 3D particle scale and rotation (release notes are vague about the details).
  - AreaLight3D, HDR output and DrawableTexture2D.
  - Conic gradients (`FILL_CONIC`), useful for radial wipes and cooldown rings.
  - Inline shader previews [35].
- **4.8-dev:**
  - Native `Trail3D`.
  - Compatibility decals.
  - VisualShader node groups [18].

### 2.10 Community resources (curated)

- **godotshaders.com:**
  - the *particle* tag;
  - soft-particle and mesh-blend shaders;
  - the Slash shader;
  - the decal shader with Y-fade and alpha-scissor support;
  - the Synty-style unlit particle shader (soft fade, camera fade) [27][36].
- **GDQuest:**
  - the *juicy attack* guide;
  - the VFX tag in their library;
  - the `godot-4-VFX-assets` repo. Code is MIT, art is CC BY-NC-SA, so you can't use the art commercially [24][37].
- **Vefects:** fire, trails and shockwave packs on the official Godot Asset Store. The shockwaves pack is free, has 90 variants, and needs 4.7+ with Forward+ [30].
- **Binbun (binbun3d):**
  - itch.io packs covering fire, impact, muzzle flash, poison, projectiles, orbs, portals, beams and ice;
  - an Ultimate Toon Shader;
  - a free CC0 Flame FX pack;
  - most pages ship source shaders [31].
- **Le Lu:** YouTube stylized-fire tutorial using VisualShader on a cylinder (realtimevfx.com thread, 80.lv write-up). The GPUTrail README credits her [28][29][25].
- **StayAtHomeDev:** my searches surfaced no specific VFX tutorial from this channel. The channel is known for Godot shader and rendering content (analysis). Search YouTube directly.
- **Courses:** Gabriel Aguiar's *Godot VFX for Games* on Udemy covers particles and VisualShader (snippet) [38].
- **GitHub:**
  - celyk/GPUTrail [25];
  - paddy-exe/GodotVisualShader-Extras (extra VisualShader nodes) (snippet);
  - alexnikop/VFEZ-godot (stackable 2D/3D VFX materials) (snippet) [26].
- **Reddit r/godot:** I could not fetch threads directly. Searches surfaced a confetti tutorial: copy the burst, zero its velocity, lower damping, and let gravity do the rest (snippet) [39].
- **Kenney Particle Pack:** 80 CC0 particle textures [40].
- **Forum:** a senior VFX artist's critique of Godot particles (section 4) is a useful map of the gaps [41].

---

## 3. Examples

1. **Matt Ostertag's burning sphere** (80.lv) [22][23]
   - An erosion/dissolve spatial shader combines vertex offset, a sphere SDF, alpha cutout and emission.
   - A `@tool` script feeds the shader the position and scale of a Node3D, so the burn front updates live in the editor.
   - Embers are spawned by collision-triggered sub-emitters.
   - Why it works: a single SDF drives both the shader and the particles, so the fire edge and the embers agree.
2. **GDQuest juicy attack (2D)** [24]
   - The VFX is cheap: a static smear sprite, a white-flash shader and two GPUParticles2D systems. The ice sword has scale-curve snowflakes and a hit burst rotated `get_angle_to(source) + PI`.
   - Why it works: timing does the heavy lifting. Anticipation, ease-out swings, hit-stop at time scale 0.07, and knockback lerped at `delta × 10`.
3. **Vefects Easy Shockwaves** [30]
   - 90 drag-in scenes: ground rings and vertical waves, 3 sizes × 3 durations (500 ms / 1 s / 2 s), 10 colours, plus a screen-distortion variant.
   - Why it works: one parameterised shader produces the whole matrix, which is a good template for building your own library.
4. **REEBOO Stylized VFX sample** [26]
   - A hit spark, sword slash and pickup sparkle, each under 100 particles (snippet).
   - Why it works: stylised effects rely on shape and timing, not particle count.
5. **Godot 4.3 premultiplied-alpha barrel fire** [16]
   - One particle material shows both an additive flame core and an alpha-blended smoke body.
   - Why it works: it halves the systems and sort problems of a fire-plus-smoke pair.
6. **Binbun portals and beams** [31]
   - The portal's shape comes from a swappable gradient texture.
   - Beams can track a target.
   - Both have open/close animations.
   - Why it works: one shader template produces many shapes through texture inputs, the same principle as Vefects' matrix.

---

## 4. Common mistakes

- **Colour ramp or flipbook "does nothing".** The draw material lacks Vertex Color as Albedo, or Billboard is not set to Particle Billboard. In a custom shader, COLOR or INSTANCE_CUSTOM isn't being read [12].
- **Setting `emitting = true` to replay a one-shot burst.** Use `restart()`. If you replay in a loop, wait for `finished` [11].
- **Changing `amount` at runtime.** It restarts the system. Use `amount_ratio`, and keep in mind it doesn't reduce memory [11].
- **Particles vanish at screen edges, or collisions silently fail.** The visibility AABB is too small. Regenerate it [6][10].
- **Setting Direction but not Velocity.** Nothing moves [12].
- **Turbulence on everything.** It is expensive 3D noise, and it doesn't move particles by itself [8].
- **Choppy flipbooks.** Fixed FPS is 30 and the frames ÷ lifetime ratio is too low. Set Fixed FPS to 0 or raise anim speed [12].
- **Fast sparks tunnelling through floors.** Raise `collision_base_size`, collider thickness or Fixed FPS, each within reason [6][11].
- **A heat-haze quad that "erases" fire behind it.** The screen texture excludes transparents. Distort the opaque scene only, or move the distortion into a CompositorEffect [14].
- **Sorting pops between overlapping smoke systems.** Godot sorts transparent objects per node origin and has no order-independent transparency. Use `sorting_offset`, `render_priority`, View Depth draw order within a system, or alpha-scissor/hash for dense smoke [42].
- **A hitch the first time an effect fires.** Warm every effect for one frame behind a ColorRect or in an off-screen SubViewport during loading, and use the debugger's pipeline-compilation monitors. 4.4+ precompilation helps but doesn't cover everything, and Compatibility has no ubershaders [17][43].
- **Assuming CPUParticles parity.** It has no trails, collision nodes, attractors or sub-emitters, and it is frozen [4].
- **Building 2D effects that need attractors or 3D colliders.** 2D has no attractors and collides only with LightOccluder2D [1][9].
- **Upgrading to 4.6 without re-checking emissive values.** The glow pipeline order changed [21].

### Known limitations and workarounds

| Limitation | Workaround |
|---|---|
| Particle → draw-shader bridge is thin; only COLOR and alpha map automatically [41] | Write data to `CUSTOM` (→ `INSTANCE_CUSTOM`), pack extras into COLOR channels, use `instance uniform` per emitter (analysis) |
| No per-particle lights | Emissive + glow, plus one animated OmniLight3D per effect, keyed in the AnimationPlayer (analysis) |
| Trails unsuited to sword arcs; none in Compatibility [5] | Swipe meshes, GPUTrail [25], 4.8 Trail3D [18] |
| SDF colliders are static; heightfields can't do room-over-room [6] | Mix Box/Sphere colliders for moving objects; one SDF per room |
| Screen texture excludes transparents [14] | CompositorEffect post-transparent pass [13] |
| Compositor is 3D-only, RD renderers only [13] | 2D: BackBufferCopy + `hint_screen_texture` [14] |
| `interp_to_end` and `emit_particle` gaps (custom shaders; Compatibility) [11] | Read `INTERPOLATE_TO_END` in your own shader; use sub-emitters on web |
| Decals can't use custom shaders [15] | Projected-box mesh with a depth-reconstruction spatial shader (analysis) |
| Inspector is noisy and curve support is inconsistent [41] | Convert to ShaderMaterial for complex effects; keep presets as `.tres` |

---

## 5. Apply in Godot 4 (Unsent: 4.7, Forward+, AgX, glow)

### 5.1 Effect scene template

```
BurnLeafFX (Node3D)            # one .tscn per effect
├─ Leaves (GPUParticles3D)     # custom shader_type particles
├─ LeafFlames (GPUParticles3D) # sub-emitter target (emitting is ignored)
├─ Smoke (GPUParticles3D)      # billboard, premultiplied alpha, proximity fade
├─ FlashLight (OmniLight3D)    # energy keyed 0 -> 2 -> 0 over ~0.25 s
└─ AnimationPlayer             # "play": restart() calls, light, shader params
```

- Drive overall intensity from gameplay with `amount_ratio` on each emitter (0.2 = idle embers, 1.0 = full burn), not with `amount`.
- Fire bursts with `restart()`.

### 5.2 Falling burning leaves: process shader with `emit_subparticle`

```glsl
shader_type particles;
render_mode disable_velocity; // we integrate position ourselves

uniform float fall_speed = 0.6;
uniform float sway = 0.35;
uniform float ember_rate = 6.0;   // embers per second per leaf
uniform vec3  wind = vec3(0.3, 0.0, 0.1);

uint hash(uint x){ x = ((x >> 16u) ^ x) * 0x45d9f3bu; x = ((x >> 16u) ^ x) * 0x45d9f3bu; return (x >> 16u) ^ x; }
float rnd(inout uint s){ s = hash(s); return float(s) / 4294967295.0; }

void start() {
    uint s = RANDOM_SEED + INDEX * 7919u;
    if (RESTART_POSITION) {
        vec3 p = vec3(rnd(s) - 0.5, 0.0, rnd(s) - 0.5) * 6.0;
        TRANSFORM = EMISSION_TRANSFORM * mat4(vec4(1,0,0,0), vec4(0,1,0,0), vec4(0,0,1,0), vec4(p, 1.0));
    }
    CUSTOM = vec4(rnd(s) * TAU, 0.0, 0.0, rnd(s)); // x = phase, y = age, w = per-leaf random
}

void process() {
    CUSTOM.y += DELTA / LIFETIME;                     // normalised age, read as INSTANCE_CUSTOM.y
    float t = CUSTOM.y * LIFETIME + CUSTOM.x;
    vec3 v = vec3(sin(t * 1.7) * sway, -fall_speed, cos(t * 1.3) * sway) + wind;
    TRANSFORM[3].xyz += v * DELTA;
    COLOR.a = 1.0 - smoothstep(0.75, 1.0, CUSTOM.y);  // burn out

    uint s = RANDOM_SEED + INDEX * 104729u + uint(CUSTOM.y * 1000.0);
    if (rnd(s) < ember_rate * DELTA && CUSTOM.y < 0.9) {
        emit_subparticle(TRANSFORM, v * 0.3 + vec3(0.0, 0.4, 0.0), vec4(1.0, 0.45, 0.1, 1.0), vec4(0.0),
                         FLAG_EMIT_POSITION | FLAG_EMIT_VELOCITY | FLAG_EMIT_COLOR);
    }
    if (CUSTOM.y >= 1.0) { ACTIVE = false; }
}
```

- On `Leaves`, set `sub_emitter` to `../LeafFlames`.
- Give `LeafFlames` a ParticleProcessMaterial with:
  - `amount` of about 64–128 (it caps the live sub-particles);
  - gravity `(0, 0.5, 0)` so embers rise;
  - `damping_as_friction` on, damping about 2;
  - a scale curve that rises then falls;
  - a `color_ramp` from white-yellow to orange to transparent dark red.
- Set Fixed FPS to 0 on both emitters for smooth slow motion (analysis).

### 5.3 Smoke and flame billboards: draw material

- **StandardMaterial3D settings:**
  - Billboard = Particle Billboard, with Keep Scale on.
  - Vertex Color > Use As Albedo.
  - Transparency = Alpha, Blend = Premultiplied Alpha.
  - Shading = Unshaded for flames. Smoke can stay lit to pick up the scene's warm key light (analysis).
  - Proximity Fade enabled, distance 0.3–0.8 m, so smoke never shows a hard line on the floor.
- **On the GPUParticles3D:** Draw Order = View Depth for the smoke system.
- **For the existing noise-torn spatial billboard shaders:** add the depth-fade line from section 2.6 and read `INSTANCE_CUSTOM.y` as age, so tearing and erosion advance per particle instead of by global `TIME`.

### 5.4 Heat haze over the fire

```glsl
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D noise : repeat_enable;
uniform float strength = 0.008;
void fragment() {
    vec2 n = texture(noise, UV * 2.0 + vec2(0.0, -TIME * 0.4)).rg * 2.0 - 1.0;
    float mask = smoothstep(0.0, 0.3, UV.y) * (1.0 - smoothstep(0.6, 1.0, UV.y)) * (1.0 - abs(UV.x * 2.0 - 1.0));
    ALBEDO = textureLod(screen_tex, SCREEN_UV + n * strength * mask, 0.0).rgb;
}
```

- The haze will not refract the transparent flame billboards (section 2.6). Keep it subtle and above the flames, or move it to a CompositorEffect if it must bend them.
- For a melancholy tone, keep `strength` at 0.005–0.01 and the noise speed slow (analysis, matching the project's slow-and-cinematic taste).

### 5.5 Ash scorch decal for the burn/dissolve moments

Create a `Decal` and set:
- albedo: a soot texture;
- emission: an ember-crack texture, with `emission_energy` keyed from 3 down to 0 over 4–6 s so it cools;
- `normal_fade` 0.3;
- distance fade on;
- cull mask set to exclude the player's hands and props.

### 5.6 Warm-up, tonemap and glow hygiene

- On scene load:
  - instance each effect scene under a node in front of the camera;
  - cover the view with a black ColorRect;
  - call `restart()` on every emitter;
  - wait one frame, then free the scene.
- Check *Debugger > Monitors > Pipeline compilations* while playing [17].
- AgX compresses bright highlights. Push emissive VFX colours to HDR values of 2–6 so glow and AgX still show a hot core.
- Since 4.6, glow is applied before tonemapping. Re-tune glow intensity and threshold with the fire on screen, rather than reusing numbers from older tutorials [21] (analysis on exact ranges).
- The Vefects fire pack already ships its own shaders and scenes [30]. Tint and scale it through its exposed parameters and `amount_ratio`, rather than editing its source shaders, so the asset stays updatable (analysis; follow the project's own rules on that pack).

---

## 6. Sources

1. ParticleProcessMaterial — Godot 4.7 class reference. https://docs.godotengine.org/en/stable/classes/class_particleprocessmaterial.html
2. Particle systems (3D) — index. https://docs.godotengine.org/en/stable/tutorials/3d/particles/index.html
3. Particle shaders — shading reference. https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/particle_shader.html
4. Progress report: State of particles (Godot blog, 4.2). https://godotengine.org/article/progress-report-state-of-particles/
5. 3D Particle trails. https://docs.godotengine.org/en/stable/tutorials/3d/particles/trails.html
6. 3D Particle collisions. https://docs.godotengine.org/en/stable/tutorials/3d/particles/collision.html
7. Particle sub-emitters. https://docs.godotengine.org/en/stable/tutorials/3d/particles/subemitters.html
8. Particle turbulence. https://docs.godotengine.org/en/stable/tutorials/3d/particles/turbulence.html
9. 3D Particle attractors. https://docs.godotengine.org/en/stable/tutorials/3d/particles/attractors.html
10. 3D Particle system properties. https://docs.godotengine.org/en/stable/tutorials/3d/particles/properties.html
11. GPUParticles3D — class reference. https://docs.godotengine.org/en/stable/classes/class_gpuparticles3d.html
12. Process material properties. https://docs.godotengine.org/en/stable/tutorials/3d/particles/process_material_properties.html
13. The Compositor. https://docs.godotengine.org/en/stable/tutorials/rendering/compositor.html
14. Screen-reading shaders. https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html
15. Using decals. https://docs.godotengine.org/en/stable/tutorials/3d/using_decals.html
16. Godot 4.3 release page. https://godotengine.org/releases/4.3/
17. Reducing stutter from shader (pipeline) compilations. https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html
18. Dev snapshot: Godot 4.8 dev 4. https://godotengine.org/article/dev-snapshot-godot-4-8-dev-4/
19. Godot 4.4 release page. https://godotengine.org/releases/4.4/
20. Godot 4.5 release page. https://godotengine.org/releases/4.5/
21. Godot 4.6 release page. https://godotengine.org/releases/4.6/
22. 80.lv — VFX Technical Artist on Creating Non-Photorealistic Visual Effects in Godot (Matt Ostertag). https://80.lv/articles/vfx-technical-artist-on-creating-non-photorealistic-visual-effects-in-godot
23. 80.lv — Stylized Fire Embers VFX Set-Up in Godot. https://80.lv/articles/stylized-fire-embers-vfx-set-up-in-godot/
24. GDQuest — Juicing up your game attacks. https://gdquest.com/library/juicy_attack
25. celyk/GPUTrail (GitHub). https://github.com/celyk/GPUTrail
26. Search results: Godot asset library VFX samples (REEBOO, Stylized 2D VFX Lite), VFEZ-godot, GodotVisualShader-Extras, forum "Slash-Animation with Trails" (snippets). https://godotengine.org/asset-library/asset/5561 ; https://forum.godotengine.org/t/slash-animation-with-trails/52513 ; https://github.com/paddy-exe/GodotVisualShader-Extras
27. godotshaders.com — Mesh Blend / Alpha Blend / Soft Particles. https://godotshaders.com/shader/mesh-blend-alpha-blend-soft-particles-blend-between-water-and-ground/
28. realtimevfx.com — Stylized Fire in GODOT. https://realtimevfx.com/t/stylized-fire-in-godot/24567
29. 80.lv — Learn How to Create Stylized Fire Shader in Godot (Le Lu) (snippet). https://80.lv/articles/learn-how-to-create-stylized-fire-shader-in-godot
30. Godot Asset Store — Vefects, Easy Shockwaves VFX. https://store.godotengine.org/asset/vefects/easy-shockwaves-vfx/
31. Godot Forum — Binbun VFX Effects. https://forum.godotengine.org/t/binbun-vfx-effects/137169
32. Godot demo projects — compute/post_shader (Compositor demo) (snippet). https://notabug.org/godotengine/godot-demo-projects/src/master/compute/post_shader
33. Godot Asset Store — Compositor Lens Flare & Godrays (ARez) (snippet). https://store.godotengine.org/asset/arez/compositor-lens-flare-godrays/
34. Godot blog — Improvements to GPUParticles in Godot 4.0 (snippet). https://godotengine.org/article/improvements-gpuparticles-godot-40
35. Godot 4.7 release page. https://godotengine.org/releases/4.7/
36. godotshaders.com — particle tag / Synty unlit particle shader / Slash shader (snippets). https://godotshaders.com/shader-tag/particle/ ; https://godotshaders.com/shader/slash-shader/
37. gdquest-demos/godot-4-VFX-assets (GitHub). https://github.com/gdquest-demos/godot-4-VFX-assets
38. Udemy — Godot VFX for Games (Gabriel Aguiar) (snippet). https://www.udemy.com/course/godot-vfx-for-games
39. r/godot "Everyone likes confetti" tutorial, via mirror/search (snippet; Reddit not fetched directly). https://redlib.hackliberty.org/r/godot/comments/1ipgr1e/tutorial_everyone_likes_confetti/
40. Godot Forum — How does VFX work in Godot? (for a complete newbie). https://forum.godotengine.org/t/how-does-vfx-work-in-godot-for-a-complete-newbie/69356
41. Godot Forum — Senior VFX Artist testing Godot particles: where to submit structured feedback? https://forum.godotengine.org/t/senior-vfx-artist-testing-godot-particles-where-to-submit-structured-feedback/138687
42. 3D rendering limitations (transparency sorting) (snippet). https://docs.godotengine.org/en/stable/tutorials/3d/3d_rendering_limitations.html
43. Godot Forum — Particles huge lag spike on first instance / web particle compilation lag (snippets). https://forum.godotengine.org/t/particles-huge-lag-spike-on-first-instance/45839 ; https://forum.godotengine.org/t/handling-particle-shader-compilation-lag-in-godot-4-web-compatibility-renderer/36170
44. Godot 2D particle systems. https://docs.godotengine.org/en/stable/tutorials/2d/particle_systems_2d.html
