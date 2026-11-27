# Research: lighting and art direction for *Unsent*

The 2026-11-26 research pass. Ten parallel researchers, about 47,000 words and about 510 cited sources (GDC/SIGGRAPH talks, studio blogs, 80.lv, ArtStation, the Godot docs and forums, cinematography sites, astronomy references). Each file ends with **"Apply to Unsent's opening"** and a **Sources** list.

Target image: [reference_target.webp](reference_target.webp). It shows a snowy house at night, seen straight on from the lane: every window warm, a flame in the open door, a wet cobble path, a foreground lantern throwing fence shadows toward the camera, and a moon behind clouds with god rays.

**Start here:** [00-unsent-opening-recipe.md](00-unsent-opening-recipe.md). It combines all ten files into one prioritised plan for this project.

| # | File | Topic | Sources |
|---|---|---|---|
| 01 | [night-lighting-fundamentals](01-night-lighting-fundamentals.md) | Key/fill/rim lighting, warm vs cool, value structure (notan), moonlight convention, ratios and stops | 46 |
| 02 | [aaa-studio-case-studies](02-aaa-studio-case-studies.md) | Naughty Dog, Rockstar, Sucker Punch, Santa Monica, Remedy, Guerrilla, CDPR, FromSoftware, Insomniac | 38 |
| 03 | [indie-narrative-case-studies](03-indie-narrative-case-studies.md) | Firewatch, Edith Finch, INSIDE/Limbo, Journey, Kena, Gris, Season, The Long Dark and about 15 more | 55 |
| 04 | [composition-and-focal-points](04-composition-and-focal-points.md) | Leading lines, framing, the "weenie", symmetry, camera height and lens, title placement | 39 |
| 05 | [color-script-and-grading](05-color-script-and-grading.md) | Colour scripts, coloured blacks, accents, AgX/LUTs, measured palette of the reference | 80 |
| 06 | [atmosphere-volumetrics-particles](06-atmosphere-volumetrics-particles.md) | Two-layer fog, god-ray recipes, aerial perspective, snow and embers | 46 |
| 07 | [practical-lights-windows-lanterns](07-practical-lights-windows-lanterns.md) | Emissive vs casting lights, curtain windows, interior mapping, fence shadows, wet stone | 61 |
| 08 | [night-sky-moon-clouds](08-night-sky-moon-clouds.md) | Moon size, rimlit clouds (Nubis), Purkinje shift, star thinning, sky-to-ground ratio | 63 |
| 09 | [godot4-lighting-implementation](09-godot4-lighting-implementation.md) | Godot 4.6/4.7 settings: LightmapGI, glow changes, AgX contrast, SSR, FogVolumes, god-ray layers | 38 |
| 10 | [winter-snow-environments](10-winter-snow-environments.md) | Snow as a light mirror, sparkle, modelled hero snow, wet surfaces, cozy vs lonely | 46 |

**Caveats from the researchers:**
- The shared web-search budget ran out partway through, so Reddit and X threads are thin. Community practice comes mostly from the Godot, Unreal and Polycount forums.
- Claims backed only by a search snippet, or by the researcher's own analysis, are marked in each file.
- Godot values are starting points from the docs, not measurements from this project.

## VFX research

A separate 10-report study on VFX (combat, environmental, stylised, shaders, Godot tooling, performance, integration, workflow): start at [vfx/VFX-RESEARCH.md](vfx/VFX-RESEARCH.md).
