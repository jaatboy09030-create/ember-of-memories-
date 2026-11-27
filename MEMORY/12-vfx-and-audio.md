# 12 — VFX, sound and voice: the effect and sound sheet

Built with the `idiot-vfx` skill and the research in `research/vfx/` (2026-11-27). The tone is restraint: few, slow, warm effects in a cold world, with **one wind** for everything and every effect tied to light and sound.

## VFX kit (`scripts/vfx/`)
| Script | What it is | Used by |
|---|---|---|
| `vfx_kit.gd` (`VFXKit`, static) | Shared builders: noise texture, HDR colour ramp, curve, soft dot, `particles()` with tight bounds, additive `spark_mesh()` | All effects below |
| `flicker_light.gd` (`FlickerLight`) | OmniLight that breathes: 2-layer smooth noise and a few cm of position jitter. **Tween `base_energy`, not `light_energy`** | Fireplace `FireLight` (flicker 0.35), street lamp `FenceShadowLight` (0.06), `PorchLanternLight` (0.08) |
| `fire_vfx.gd` (`FireVFX`) | Fire layers around a "Flames" emitter: hot core, rising cooling embers, thin smoke above. Re-skins the sibling Flames with the `ember_wisp` torn-edge shader and a hot→deep-red ramp. `heat` 0..1 | `fireplace.tscn` → `HearthFire/FireLayers` |
| `memory_motes.gd` (`MemoryMotes.burst(parent, pos)`) | One-shot burst of golden motes plus a 0.12 s warm light pop (no shadow, no fog), frees itself | `Memory.play_restore_moment()`, on the same frame as `memory_restore` + `memory_wake`, glance, shake, warm flash |
| `light_motes.gd` (`LightMotes`) | Slow warm dust drifting in a light pool | Gate scene: `StreetLamp/LampMotes`, `Porch/DoorwayMotes` |

Other changes:
- **Fireplace:** `HearthFire` moved up to the grate (`y 0.6`). It used to sit inside the stone base and glow through the ash slot.
- **Crackles:** random `fire_crackle` one-shots play every 1.8–5.5 s while the fire is lit.
- **One wind:** global shader param `wind_strength` (`project.godot [shader_globals]`, 1 = calm). `foliage_snow.gdshader` multiplies its sway by it and adds a lean on gusts. `AmbienceMixer` raises it to 2.6 for each gust, at the same moment the gust sound plays.
- **Moonlight through every window:** `house_window.tscn` has a `Moonlight` SpotLight3D. It is cool, angled 38° down, energy 4, soft shadows, and projects `assets/textures/window_cookie.png` (the window cross). It is the key light in the cold rooms; the cold `RoomFillLight`s dropped from 0.9 to 0.5.

## Sound mix (`scripts/systems/sound.gd`, `ambience_mixer.gd`)
- **Variants:** `Sound.play("step_snow")` picks randomly from `step_snow_1…6` and never repeats the last one. Any `<name>_N` set works the same way.
- **Buses** (made at start):
  - `Music`: ducks −8 dB under every voice line and recovers over 1.2 s.
  - `Voice`: the present-day inner voice. Close, light compression, a breath of room.
  - `Memory`: remembered voices and memory sounds. Low-pass plus a soft reverb.
- **Bus routing:** `Sound.memory_voices` (v_scarf, v_artist, v_letter, v_slam) go to Memory; every other `v_*` goes to Voice.
- **`Sound.play_voice(name)`** returns the line's length. `hud.say(text, dur, voice)` keeps the caption up at least that long.
- **File order:** `.ogg` is tried first. Loops should be OGG; MP3 adds a gap at the loop point.
- **Ambience:**
  - Outside: wind plus a `snow_night_loop` bed.
  - Inside: the house tone.
  - On top, random sprinkles: `wind_gust` outside (14–30 s apart, muffled inside) and `house_creak` inside (20–45 s apart).
  - A 3D `clock_tick_loop` ticks in the hallway at (0, 2, −8.7).
- **New one-shots:**
  - `door_rattle` for locked doors (was `door_slam`);
  - `ember_whoosh` when the ember sets off and at the gate;
  - `memory_wake`, layered under `memory_restore`;
  - `fire_crackle`.

## Voice cast (ElevenLabs, account voices)
| Voice | Character | Lines |
|---|---|---|
| **Child - Unsent** (library: "Jacob – Soft Comfort") | The grown child, inner voice, present day | `v_home` "...home.", `v_clock`, `v_notes`, `v_gamepad`, `v_postcards` (suitcase items, `PackableItem.memory_voice`), `v_left` "I left that night. I never came back." |
| **Mother - Unsent** (Valentyna) | The parent | `v_artist`, `v_letter`, `v_slam` "...then go!" (shouted, crying, stability 0) |
| **Grandma - Unsent** (Maria Moody) | Grandma | `v_scarf` |

How the lines are made (06 R12, extended):
1. Generate with `eleven_v3` and direction tags per line, e.g. `[softly, guilt creeping in] … [quieter] …`.
2. Pace each line individually in post: `atempo` 0.86–0.92, slowest for the heaviest lines (`v_left` 0.86).
3. Warm it: +2.5 dB at 180 Hz, −2.5 dB at 7 kHz, 2.5:1 compression.
4. High-pass at 70 Hz and normalise to −19 LUFS. Footsteps are peak-matched to the clips they replaced (short clips are too short to measure in LUFS).

The processing script is `process_audio.py`, which lives in the session scratchpad. Recreate it from these steps if needed: slice runs at onsets, then high-pass → fades → loudnorm → OGG.

## Blink demo voice-over (radio-drama cast)
- **119 recordings**, one per line, in `assets/audio/blink/`:
  - `bvn_<sha1(text)[:12]>.ogg`: the son narrating, on the Voice bus.
  - `bvm_<...>.ogg`: a character inside a memory, on the Memory bus.
  - `_manifest.json` lists the speaker and text for each file.
- **Lookup:** `BlinkCaption.say()` finds the file from the caption text itself, so no scene edits are needed.
  - The caption stays up until the line ends.
  - `cut()` (a blink, a scene cut) also cuts the voice. In the dialogue channel, a new line replaces the one still speaking.
- **Timing in `blink_demo.gd`:** authored lines never talk over each other; closed-eye lines and the ending wait for each line.
- **Cast:**
  - **Child - Unsent:** the son, all narration, including lines that quote others, audiobook-style.
  - **Mother - Unsent:** Mum, for the goodbye, the argument, her postcards (read in her voice) and "...safe".
  - **Dad - Unsent** (library: "Miller – Relatable Dad Vibe"): "Leave the light on for him", the overheard sums, the argument and the truth.
  - The existing `v_scarf` / `v_artist` / `v_letter` hotspot lines are unchanged.
- **Direction:**
  - every narration line gets a tone from its beat;
  - eyes-closed lines are close and almost whispered;
  - character lines are directed individually;
  - shouting and crying lines use stability 0.
  - Tempo: narrator 0.92, Mum 0.95, Dad 0.97. Same warm chain as the main game, at −19 LUFS.
- **Changing a line?** Its hash changes and it goes silent, but captions still show. Re-extract the lines and run `tools/blink_voice_over.py`; only new lines are generated.
- **Eyes-closed sounds:** `house_creak` for the floorboard and "Thursday", `clock_tick` (one-shot cut of the loop) for the hall clock, `wind_gust` for "nothing in the lane".
- **Credits:** ElevenLabs use after this pass is 11,813 of the owner's 30k cap.

## Verified / not verified
- **Verified:** storytest, doortest and walktest pass. Screenshots checked: gate scene, lit fireplace (`--tour` t8_fire_lit), kid's room moonlight.
- **Not verified:** the mix has not been listened to in a full playthrough (levels are matched by loudness, not by ear). The gust/creak timing and the clock level need a real play to tune.
