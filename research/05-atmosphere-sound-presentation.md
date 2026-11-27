# 05 - Atmosphere, Sound Design and Presentation Identity (Unsent)

> Research note. Live web access in this pass was limited to search-result snippets (no full talks/transcripts fetched). Claims marked *(snippet)* come from search summaries; claims marked *(known)* are widely documented design knowledge about the reference games and should be double-checked against the linked sources before quoting publicly.

## 1. Diagnosis: why Unsent feels generic

- The building blocks (snowy cottage, glowing guide, grey-to-colour memories, piano) are common to many "emotional walking sim" games. None of them is *owned*.
- The game has a signature already: **pixelated ember-gold ghost faces**. It shows up once and then isn't used again. A distinctive game makes one rule and keeps leaning on it (Obra Dinn's 1-bit look, Mouthwashing's smeared faces, Fatal Frame's camera, P.T.'s single hallway).
- Suspense fails because the soundscape is continuous and friendly (music box plus companion glow). Suspense comes from **silence, off-screen sound and withheld information**, not from loud cues.

**Thesis:** make "the faces you can't remember" the *rule* of the whole game, in visuals, audio, UI and story. The pixelation is not a stylistic glitch. It is the player-character's **guilt and forgetting**: they left, so they can't picture their parent's face. Resolution (de-pixelation) becomes the game's currency, and the face reveal in room 5 pays it off.

## 2. Techniques and reference games

### Sound
| Technique | Reference | Takeaway for Unsent |
|---|---|---|
| Audio that "listens" to gameplay; music synced to player rhythm and breath | INSIDE / Limbo, Martin Stig Andersen, GDC 2016 "A Game That Listens" *(snippet)* | Sync the music box to knitting presses and the mash rhythm in room 3. |
| Organic, physically processed sound sources (Inside ran audio through a human skull) *(snippet)* | INSIDE | Re-record the music box *through* objects: inside a teapot, in a wardrobe, through a door. It gives a cheap, unique timbre. |
| Binaural voices that circle the head, close-mic'd whispers | Hellblade I/II (Xbox Wire, Galante GDC 2025) *(snippet)* | Use one close, dry, binaural-style whisper layer for the parent's voice only. |
| Silence as an instrument; long ambient beds with rare dissonant hits | Silent Hill (Akira Yamaoka) *(known)* | Allow 20-40 second stretches with only house tone, snow and breath. |
| Diegetic broadcast as narrator | P.T. radio, Iron Lung's sparse hum *(known)* | Use an old **answering machine / radio** in the cottage as the diegetic music and voice source. |
| Filling the void with something wrong ("space is quiet, so we filled it with screaming") | Mouthwashing, Martin Halldin talk 2025 *(snippet)* | The empty house shouldn't be empty: add distant thumps, a kettle, a TV through a wall. |
| Sounds from other rooms | Common horror practice | Room N+1's memory is audible, muffled, from room N. This pulls the player forward and creates dread. |

### Visual identity
| Technique | Reference | Takeaway |
|---|---|---|
| One strict render rule | Return of the Obra Dinn (1-bit dithering) | Rule: **people are never rendered at full resolution until the end**. |
| Degraded faces as the theme | Mouthwashing (low-poly, smeared faces), Signalis (PS1 or anime contrast) *(known)* | The faces carry the meaning: the pixelation is memory loss. |
| Diegetic capture device as the lens | Fatal Frame camera, Unrecord / Bodycam / Don't Scream (real-time body-cam) | The body-cam lens is the parent's or child's camera. Treat it as an *object* (battery, REC dot, timestamp). |
| Analog decay as tone | Paratopic (VHS, abrupt hard cuts) *(known)* | Use hard cuts on story beats, not fades. |
| Lighting as story | Firewatch, Gone Home, Inside | The only warm light is the Ember and the memories. The house is blue moonlight. The fire at the end makes the whole palette warm. |

### Typography, title cards, UI
- Title cards: one font, one size, small, lower-left, with a timestamp like a camcorder ("DEC 23 — 22:41"). Each room opens on a date card from the memory's year, which carries the hidden-timeline story.
- Captions: lowercase, unattributed, slightly late, like memory. Voices with pixelated faces get captions with **scrambled glyphs** that resolve as colour returns.
- UI minimalism: no HUD. Prompts appear as the camcorder's on-screen text (e.g. "[E] FOCUS").

## 3. Turning the pixelated face into a motif (core proposal)

1. **Mosaic level as global state.** Use one variable, `face_resolution` (for example, 8 px blocks rising to full). Each restored memory raises it a step, and every face in the game reads it.
2. **Spread it to objects.** Photos on walls, the family portrait, and the reflection in a window are all mosaicked at the current level. The player sees "progress" in the house itself.
3. **The player's own face.** Mirrors show the *player* fully pixelated, with blocks that never resolve, until the twist. After the room 5 reveal, the mirror resolves to show they are older than in every memory.
4. **Audio counterpart.** Pixelated faces speak through **bitcrushed or sample-rate-reduced** voice. The crush drops in step with `face_resolution`, which is the same rule applied to sound.
5. **Text counterpart.** Captions scramble at the same level.
6. **Inversion at the climax (room 5).** In the photo flip, the parent's face is clear and the *child* in the photo is the mosaicked one. The parent remembered; the child is the one who faded.
7. **Ending.** Relighting the fire resolves every face in the house at once in a single "focus pull". This is the one reward moment.

## 4. Room-by-room proposals

| Room | Atmosphere / sound | Presentation | Suspense beat |
|---|---|---|---|
| Hall / arrival | Snow crunch, wind, the door's long creak. No music for the first 60 s. An answering machine blinks "1 NEW MESSAGE" but doesn't play yet. | Camcorder boot-up title card, REC dot | The unplayed message hangs over the game until the end. |
| 1 Knitting | Needle clicks drive the music box tempo. A miss detunes it. Mother humming, bitcrushed. | Grey fades to colour from the yarn outward (shader mask) | Halfway through, a second set of footsteps upstairs (the next room). |
| 2 Drawing scraps | Paper rustle positioned in 3D so you find scraps by ear. A child's laugh from the scrap's position. | Each scrap is pixelated until you rotate it right | The completed drawing shows 3 people, but the third is mosaicked heavier. |
| 3 Study door | Argument muffled through the door (low-pass), rising. Heartbeat and breath close-mic. Music stops entirely. | Camera shake, lens bend increases with pushes | The losing state: door opens to silence and an empty room, then a hard cut. |
| 4 Suitcase | Clock ticking replaces music. Each colour drain step = one tick louder. Car idling outside. | Colour drains *toward* the camera edges | Packing the 4th item cuts the clock. Total silence, then a car door. |
| 5 Photo / letter | Answering machine finally plays: parent's voice, **clear, un-crushed** for the first time | Face reveal (inversion, see 3.6). The letter is typed on screen in handwriting font. | Mirror reveal of the player. |
| 6 Fireplace | Fire crackle builds into the full theme on piano. The music box is "fixed" by being re-recorded clean. | Lens effects fade out, grain reduced. All faces resolve. | Kept quiet. No jump scare, the release is the point. |

## 5. Sound design plan

**Layers (bus layout):**
- `Master`
  - `Ambience`: house tone (low fridge or boiler hum, 50-60 Hz), wind, snow on windows. Always on, never fully silent.
  - `Foley`: footsteps (snow / wood / rug material switch), cloth, breath. Breath gets louder in suspense rooms.
  - `Memory`: ghost voices, with Distortion (bitcrush) and LowPass effects driven by `face_resolution`.
  - `NextRoom`: muffled audio from the next memory, LowPass at ~600 Hz plus reverb.
  - `Music`: music box (broken), piano. Ducked by a sidechain from `Memory`.
  - `UI`: camcorder beeps, very sparse.

**Rules:**
- Music never plays during suspense beats. Silence comes before every reveal.
- Every room has one **diegetic** source the music can come from (radio, music box, TV, answering machine).
- The music box is "broken": missing teeth (drop notes), wow/flutter pitch drift. Each restored memory restores notes.
- Off-screen cue per room (footsteps upstairs, a door closing, a phone ringing once). Never explain it.
- Mix headroom: keep ambience around -30 LUFS short-term so silence reads as dread, not as a bug.

**Asset sourcing:** record your own foley (snow = cornstarch in a pouch, door creaks, a real music box played slowly). It's cheap and unique, and avoids stock-library sameness.

## 6. Godot 4 implementation notes (effort S/M/L)

| Item | How | Effort |
|---|---|---|
| Global `face_resolution` | Autoload holding a float. Set a global shader uniform via `RenderingServer.global_shader_parameter_set("face_res", v)`. Add it in Project Settings > Shader Globals. | S |
| Mosaic face shader | Spatial shader on the face mesh / sprite: `uv = floor(UV * face_res) / face_res;` sample the albedo, add an emission tint in ember-gold. Use the same shader on photo frames and mirrors. | S |
| Mirror showing pixelated player | `SubViewport` + camera reflection, or a ShaderMaterial with a mosaic pass on a `screen_texture` region. Simpler option: fake the reflection with a pre-placed mosaicked player mesh. | M |
| Bitcrushed voices | `AudioEffectDistortion` (mode LoFi) plus `AudioEffectLowPassFilter` on the `Memory` bus. Tween `drive` / `cutoff_hz` from `face_resolution` using `AudioServer.get_bus_effect`. | S |
| Next-room muffled audio | `AudioStreamPlayer3D` in the next room routed to the `NextRoom` bus. Enable `attenuation_filter_cutoff_hz` (around 800). Doors raise the cutoff when opened. | S |
| Pseudo-binaural whisper | Godot has no HRTF. Use short `AudioStreamPlayer3D` with `panning_strength` above 1 and small orbit movement around the camera, or pre-render binaural stems in Reaper (free HRTF plugin) and play them as 2D stereo. | S-M |
| Broken music box | Split the theme into per-note samples. Play them via a script sequencer with random dropouts and `pitch_scale` jitter (0.97-1.02). Restore notes per memory. | M |
| Music synced to knitting / mashing | Use the sequencer above, advancing one step per correct input (the INSIDE "game that listens" idea). | M |
| Sidechain ducking | `AudioEffectCompressor` on `Music` with `sidechain = "Memory"`. | S |
| Caption scramble | RichTextLabel with a custom `RichTextEffect` that substitutes random glyphs where `randf() > face_resolution_norm`. | S |
| Camcorder title cards / timestamps | CanvasLayer, monospace pixel font, `Tween` type-on. REC dot blink. | S |
| Colour return masks | Existing desaturation post-process; add a world-space radius uniform (spreads from the memory object) instead of a global fade. | M |
| Hard-cut transitions | Instant `visible` swap plus 0.2 s black plus an audio cut (set bus volume to -80 instantly). Cheaper and scarier than fades. | S |
| Final "focus pull" | Tween `face_res` to full, lens-effect strength to 0 and grain to low, while the piano enters. One timeline in `AnimationPlayer`. | S |

## 7. Priorities for a small team
1. (S) Global `face_resolution` and the shared mosaic shader on faces, photos and mirrors. This is the identity win.
2. (S) Bus layout, silence rules, and next-room muffled audio. This is the suspense win.
3. (M) Broken music box sequencer tied to inputs.
4. (S) Camcorder typography and date cards, plus scrambled captions.
5. (M) Mirror and room 5 inversion reveal.

## Sources
- GDC Vault, "A Game That Listens - The Audio of INSIDE" (Martin Stig Andersen): https://gdcvault.com/play/1023731/contactUs *(snippet)*
- Game Developer, video of the INSIDE audio talk: https://gamedeveloper.com/audio/video-designing-the-audio-for-i-inside-i-a-game-that-listens *(snippet)*
- Audiokinetic blog, INSIDE game audio using Wwise: https://www.audiokinetic.com/en/blog/inside-game-audio-using-wwise *(snippet)*
- PC Gamer, Inside used a human skull for its sound: https://pcgamer.com/inside-used-a-real-life-human-skull-to-create-its-music-and-sound *(snippet)*
- MCV, interview with Limbo audio creator Martin Stig Andersen: https://mcvuk.com/?p=68239 *(snippet)*
- Xbox Wire, Hellblade II binaural audio: https://news.xbox.com/en-us/2024/05/17/hellblade-2-audio-design-is-like-nothing-youve-ever-heard/ *(snippet)*
- A Sound Effect, Hellblade II game audio: https://www.asoundeffect.com/senuas-saga-hellblade-ii-game-audio/ *(snippet)*
- PCGamesN, Hellblade binaural microphone: https://pcgamesn.com/hellblade/hellblade-gives-us-a-look-into-its-audio-development-shows-us-a-microphone-with-actual-ears *(snippet)*
- Nordic Game, Martin Halldin, "Composing Music and SFX for Mouthwashing": https://nordicgame.com/speaker/martin-halldin *(snippet)*
- Godot docs, Audio buses and effects: https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html
- Godot docs, Global shader uniforms: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html#global-uniforms
- Not fetched in this pass (from general knowledge; verify): Return of the Obra Dinn dev log (Lucas Pope, TIGSource), Signalis, Paratopic, Fatal Frame, Unrecord, Bodycam, P.T., Iron Lung, Akira Yamaoka interviews.
