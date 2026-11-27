<div align="center">

# Unsent

**A short first-person suspense game about coming home, in the snow, to a house that remembers you.**

![Godot](https://img.shields.io/badge/Godot-4.7-478CBF?style=for-the-badge&logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-only-355570?style=for-the-badge&logo=godotengine&logoColor=white)
![Renderer](https://img.shields.io/badge/Renderer-Forward%2B-5C6BC0?style=for-the-badge)
![Genre](https://img.shields.io/badge/Genre-Narrative%20%C2%B7%20Psychological%20Thriller-8E3B46?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Status](https://img.shields.io/badge/Status-Prototype-E0A030?style=for-the-badge)

![Playtime](https://img.shields.io/badge/Playtime-one%20sitting-6A994E?style=flat-square)
![Combat](https://img.shields.io/badge/Combat-none-lightgrey?style=flat-square)
![Voiced](https://img.shields.io/badge/Voiced-narrator%20%C2%B7%20Mum%20%C2%B7%20Dad-F4A261?style=flat-square)
![Made with Claude](https://img.shields.io/badge/Built%20with-Claude%20Code-D97757?style=flat-square)

</div>

---

## About

*Unsent* (repo name `ember-of-memories-`) is a short, quiet game about grief, guilt and what people keep for you while you are away.

You are a grown child who returns, at night, to the cottage you left long ago. The house is dark, cold and grey. A small glowing **Ember** waits at the gate and leads you inside. Every room holds a frozen memory: faint ember-gold ghosts of the family, caught mid-moment, with their faces pixelated, because you forgot them.

There is no combat, no inventory and no failing. The project has two playable parts:

| | What it is | Scene |
|---|---|---|
| **The walking game** | Walk the house, restore seven memories with small mini-games, and relight the fire. | `res://scenes/main.tscn` |
| **The Blink demo** | A "memory in the dark" prototype where you play by *blinking*. A psychological thriller in 22 short beats. | `res://scenes/prototypes/blink_demo.tscn` |

---

## The walking game

Colour is the progress bar. The world starts grey and gains colour as each memory returns.

1. **Arrival.** The gate, the snow, the first ghosts.
2. **Living room.** Grandma knits a scarf while the boy watches.
3. **Kid's room.** A torn drawing: collect the scraps, tape it back together, and it goes back on the wall.
4. **Hallway.** Shouting behind the study door. You try to hold it shut, and you always lose.
5. **Bedroom.** The night you left. You pack your things one by one and the colour drains out.
6. **Parent's room.** A photo turned face down. A letter: someone waited and kept the fire going.
7. **The fireplace.** You relight the fire. Full colour, full music, and the camera cranes up over the warm house.

**What it looks and sounds like**

- **The mosaic rule.** Faces are pixelated because you forgot them. They sharpen as memories return, and your own face stays pixelated.
- **Worn-camera look.** Gentle lens bend, colour fringe, grain that grows in the dark, hand-held drift, film vignette.
- **Snow, cold breath, warm firelight.** Cold against warm is the emotional temperature of every scene.
- **Sound.** Solo piano on the title, a broken music-box theme in play, the full theme at the ending. Every caption is voiced.

---

## The Blink demo

A playable prototype of a *Before Your Eyes*-style mechanic, staged inside the real house. You do not walk. You stand in one spot inside a memory, and **blinking is how you play**.

![Blink](https://img.shields.io/badge/Input-blink-8E3B46?style=flat-square)
![Beats](https://img.shields.io/badge/Beats-22-6A994E?style=flat-square)
![Look](https://img.shields.io/badge/Look-memory%20islands%20in%20a%20black%20void-111111?style=flat-square)

**The rules of a blink**

1. **Early in a memory a blink is safe.** The lids close and open, and nothing changes.
2. **Blink while the reticle is on the white eye** and you look closer: ghosts wake, the room blooms in, colour and warmth return.
3. **When the metronome ticks, your next blink lets go.** The memory is cut and you open your eyes somewhere else, years apart. The metronome only appears once every line has been said.
4. **Keep your eyes shut** and you hear what the memory hides.

Every swap happens while the lids are fully shut, so you never see the cut. If you blink mid-sentence, the words you heard stay on screen with a dash and fade, so you know something was left unsaid.

**How it looks**

- **Memory islands in a black void.** Only the patches of the room you are remembering show. Everything else is ink black with a ragged, boiling edge.
- **Soft focus where you look.** A gentle radial focus follows the reticle.
- **Solid, faded ghosts** with pixelated faces that never fully clear.
- **Snow, footprints and a six-panel wooden door**, all built from generated textures and meshes.

**The story, in spoiler-free terms.** A son returns after twelve years to a house he believes he was thrown out of. The memory he keeps is half a sentence. The rest is behind closed eyes. Details are in `MEMORY/11-blink-demo.md`.

---

## Running it

You need **Godot 4.7** (the project was built and tested with 4.7.2). It is GDScript only, so no .NET build is needed.

```powershell
# play the walking game
& "C:\Program Files\Godot\Godot.exe" --path .

# play the Blink demo
& "C:\Program Files\Godot\Godot.exe" --path . res://scenes/prototypes/blink_demo.tscn

# open in the editor
& "C:\Program Files\Godot\Godot.exe" --path . --editor
```

Adjust the executable path to wherever Godot lives on your machine.

**Controls.** Keyboard and mouse, or a gamepad. The inputs are defined in `project.godot` (move, look, sprint, interact, rotate item). In the Blink demo:

| Action | Input |
|---|---|
| Blink (tap) | Space, left mouse or gamepad A |
| Keep eyes closed | Hold the blink input |
| Move the reticle | Mouse or right stick |

**Optional asset.** The ember flame uses *Vefects Stylized Fire* from the Godot Asset Store. Its licence forbids public repositories, so it is git-ignored. Install it locally into `res://Vefects/` to see the original flame.

---

## Testing

Automated tests run headless and print `TEST ... PASS` or `FAIL`:

```powershell
& "C:\Program Files\Godot\Godot.exe" --headless --path . -- --storytest   # the whole story
& "C:\Program Files\Godot\Godot.exe" --headless --path . -- --walktest    # walking
& "C:\Program Files\Godot\Godot.exe" --headless --path . res://scenes/main.tscn -- --doortest
```

Blink demo helpers (add after `--`):

| Flag | Does |
|---|---|
| `--blinkshots=<folder>` | Plays the demo automatically and saves screenshots |
| `--blinkonly=<BeatName>` | With `--blinkshots`, only that beat |
| `--blinkcheck` | Checks every figure and prop is placed on a surface, not clipping |
| `--blinknovoid` | Debug: shows the whole room without the black void |

---

## Project layout

```
project.godot            engine config, input map, autoload, shader globals
scenes/                  main.tscn, the house, player, memories, objects, prototypes
scripts/                 one script per node, mirroring scenes/
shaders/                 camera, ghost, void, eyelids, snow, fire shaders
assets/                  audio, characters, textures, models
tools/                   one-off headless scripts (level builder, voice-over generator)
research/                design notes and reference studies
MEMORY/                  the project's knowledge base: architecture, recipes, gotchas
```

**Where to start reading.** `MEMORY/README.md` is the index. Good first stops are `01-project-overview.md`, `02-architecture.md`, `10-story-and-gameplay.md` and `11-blink-demo.md`.

---

## Credits

- **Models and textures.** [Poly Haven](https://polyhaven.com) (CC0) and [Quaternius](https://quaternius.com) (CC0).
- **Sketchfab models** (CC-BY 4.0): credited in [`assets/sketchfab/CREDITS.md`](assets/sketchfab/CREDITS.md).
- **Characters and animation.** Mixamo.
- **The house.** Tripo AI parts assembled and modelled in Blender.
- **Font.** Bodoni Moda (SIL Open Font License).
- **Voices.** Generated with ElevenLabs (narrator, Mum, Dad). Re-run `tools/blink_voice_over.py` after changing a caption, or it plays silent.
- **Built with** [Claude Code](https://claude.com/claude-code) and the Godot engine.

**Team.** XMavrik (original build), Agrim Singh (restructure), Suyash (owner).

> No licence file is included yet. Until one is added, all rights are reserved by the authors.
