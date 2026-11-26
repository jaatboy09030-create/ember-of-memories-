# 00: The first-scene lighting recipe (synthesis)

> **Which shot this is for:** the **first gameplay scene**, where the player stands at the gate after "tap to continue". It is **not** the title screen. The title keeps its own look, which `TitleSequence` swaps in and out (see `MEMORY/CHANGELOG.md`, 2026-11-27).

This combines files 01–10 into one plan for *Unsent*'s opening shot. Numbers in brackets point to the source file.
Status column: ✅ done in this pass · ⏳ next · 💭 optional or later.

## The idea in one line
**"Someone kept this warm for me."** A large, cold, blue, quiet frame holds a few small warm pools (windows, door, lantern). One of them, the flame in the doorway, is the brightest thing on screen, and every line in the image leads to it. [03, 04, 10]

## Rules everyone agreed on
1. **One key light per shot.** The door flame is the key. The moon is a cool counter-light behind the house. The lantern and windows support. If the shot goes muddy, delete lights and rebuild from the key. [01, 02, 04]
2. **Brightness ranking:** door flame > foreground lantern (keep it ~30–40% dimmer than in the reference, which over-weights it) > wall lantern > windows (~50–60% of the flame) > moon glow and cloud rims > moonlit snow > sky > pine silhouettes. Check it by desaturating a screenshot. [04, 07, 08]
3. **Value before hue.** In the reference, ~84% of pixels are below 25% luminance and the mean is ~17%. Blacks are coloured (`#08141a`), never pure black. [05]
4. **Warm vs cool, motivated:** amber means home, fire and the parent; blue means the cold world. Keep the blue gentle and desaturated, and keep saturated orange for the focal points. Red is reserved for the mailbox (the letters). [01, 03, 05]
5. **The moon is a back/side light, never a front light.** It rims the roof snow and pine edges. The disc stays ivory while its light and the sky around it read cool. Draw it smaller than now: ~0.05 rad, not 0.15. [01, 08]
6. **Atmosphere comes in two layers.** Lit volumetric fog gives halos and shafts up close; dark blue distance fog handles the far planes. God rays need a source, an occluder with gaps (pines, cloud edges) and local density, not more fog everywhere. [06, 09]
7. **Glowing panes are emissive; real lights go only where light touches something you look at:** the sill and snow, the path, the fence. [07, 09]
8. **Wet stone means darker albedo and low roughness, not blue,** and it only reads if a warm light sits behind the path to reflect. [07, 10]
9. **Snow is a mirror for the light's colour:** near-white albedo (0.80–0.88), never pure white. It turns gold under the lantern and blue elsewhere. Sparse sparkle. [10]
10. **Composition:** a frontal, symmetric, eye-level view of the house from just outside the open gate, which reads as calm and "home". Asymmetric accents break it up: moon left, mailbox right, embers right. Dark framing foreground, lit midground, soft background. Vertical FOV 36–46°. [04]

## Godot 4.7 settings (this project)
| Area | Setting | Value | From | Status |
|---|---|---|---|---|
| Camera | the player's own view at the gate (eye ~1.6 m, fov 70) already frames it like the reference | 04 | ✅ |
| Glow | blend mode / intensity / bloom | check `glow_blend_mode`; bloom 0.06 → 0.03 (4.6 glow is brighter) | 09 | ✅ |
| Tonemap | AgX contrast / white | 1.2 / 9 | 05, 09 | ✅ |
| Ambient | sky ambient energy | 0.3 → 0.2 (darker shadows, practicals dominate) | 01, 09 | ✅ |
| Moon | direction / size / fog energy | behind the house, top-left of frame (~30° left, ~22° up); `moon_size` 0.05; `light_volumetric_fog_energy` 1.6 | 06, 08 | ✅ |
| Lantern | real StreetLamp + title-only shadow light behind the fence | 2200 K `#ffad5c`, energy ~3.5, shadow on, `light_size` 0.06 → picket shadows toward camera | 07, 09 | ✅ |
| Door | the Ember rests at the doorway as the focal flame; warm light at the door | 1900 K | 04, 07 | ✅ |
| Windows | every pane emissive warm behind curtains during the opening (curtain shader, per-window variation), dimmer than the door | 2400 K | 07 | ✅ |
| Path | wet cobbles: darker, roughness ~0.3 + SSR | 07, 10 | ✅ |
| Transition | from the title: turn to the ember, eyes close, and the first scene opens with the gameplay look swapped in | 04 | ✅ |
| GI | LightmapGI instead of SDFGI for the exterior | 09 | 💭 |
| LUT | 33³ teal-shadow / amber-highlight colour-correction LUT | 05, 09 | 💭 |
| God rays | FogVolume beam-catcher by the pines + optional screen-space ray quad / additive cone cards | 06, 09 | ⏳ |
| Window pools | SpotLights with mullion projector textures onto the snow under each window | 07, 09 | 💭 |
| Snow | sparkle + colour response in the snow shaders; modelled fence-cap and mailbox-lid snow | 10 | 💭 |
| Story touch | footprints to the mailbox, its lid snow untouched (never opened) | 10 | 💭 |
| Accent | the mailbox keeps its red even when the world greys (per-material saturation exemption) | 05 | 💭 |

## Review loop (from 02 / 04)
1. Take `--titleshot` screenshots.
2. Desaturate them: is the flame the brightest point?
3. Squint test: does the notan (simple light/dark pattern) read?
4. Compare side by side with the reference.
5. Change **one** thing and repeat.
