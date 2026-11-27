# 11 — Blink demo (Before Your Eyes style prototype)

A standalone, playable prototype of a blink mechanic, staged inside the real house.
Research it is based on: `research/Before You Blink/` (00 index, 01 mechanics, 04 Godot blueprint).

## Run
```powershell
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --path . res://scenes/prototypes/blink_demo.tscn
# automatic playthrough + screenshots (for checking without playing):
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --path . res://scenes/prototypes/blink_demo.tscn -- --blinkshots=<folder>
```
Controls: input action **`blink`** (Space / left mouse / pad A). Tap = blink. Hold = eyes closed.
Mouse or right stick (`look_*`) moves the reticle; the view leans toward it.

## How it works
- `scenes/prototypes/blink_demo.tscn` instances `main.tscn` with **`GameDirector.autostart = false`**
  (no title, no story, player disabled, HUD hidden). The house, figures, doors, fire are reused.
- **Beats** (`MemoryBeat`, `scripts/prototypes/blink/memory_beat.gd`): one remembered moment, one
  camera spot. Children: `CameraPoint`, `LookTarget`, `Islands/` (MemoryIsland), optional `EyeHotspot`,
  `MemoryLight`, `EmberPoint`, `BeatCue` nodes. Played top to bottom under `Beats`.
- **Blink rules** (`blink_demo.gd`): safe until `protect_time` → metronome appears → next blink cuts.
  Reticle on an eye + blink = look closer (hotspot wins over the cut). Holding the eyes closed plays
  `closed_eyes_sound` + `closed_eyes_caption` or the `closed_eyes_lines` sequence (only while shut;
  resumes where it stopped). `montage_lines` = each blink is one step. `wait_for_closed_lines` keeps
  the metronome away until every hidden line was heard. Final beat: `auto_end_after` +
  `ending_lines` vs `ending_lines_if_blinked` (blinking before the last line changes the ending).
- **Every swap happens while the lids are fully shut** (`Eyelids.shut` signal).
- Look: `shaders/blink_void.gdshader` — full-screen quad on `MemoryCamera`; rebuilds world position
  from depth, paints everything outside the islands black with a ragged ink edge (world-locked).
  `shaders/eyelids.gdshader` — curved lids. `MemoryCamera` — clamped diorama sway + rack focus DoF.
  The screen look (grain, face mosaics) still comes from main's ScreenEffects.
- `BeatCue`: timed sound / synth / method call when a beat opens (door swing, headlights, steps).
  `SweepLight`: headlights crossing the windows. `SynthTone`: generated metronome tick, lid thump,
  car engine (no audio files needed).

## The story (22 beats) - psychological thriller
Built with the thriller-writing skill (unreliable narrator, self-deceiving type; twist ladder).
- Surface: a son returns after 12 years to a house he was "thrown out of" (Dad: "If he wants to go, then go-").
- Twist 1 (sad): half a sentence. Holding the eyes shut in the TruthBeat plays the rest: "-and I'll drive
  him... tell him about St. Brigid's... Christmas." The art school was paid (receipt, kitchen calendar).
- Twist 2 (shock): the "door slamming" he heard on the lane that night was Dad's car going into the ditch
  at Ferrow Bend while looking for him. LaneNightBeat: a figure closer each blink, then the wreck's one
  headlight; eyes shut = engine, skid, horn ("It wasn't a door."). The clipping on the photo confirms it.
  Mum's postcards kept Dad alive on paper for twelve years (coat on the hook, his cup, "he won't let me
  touch the switch"). The Ember = the light from the bend, "about as high as a car's lamp".
- Twist 3 (fear, then relief): the same engine and headlights come up the lane again. Mum, home from
  hospital. Don't blink and she finishes the goodbye cut off 12 years ago ("-safe"), face clears.
- Fair-play clues planted early: bus driver won't pass the bend; Dad: "That ditch has had two cars";
  keys on the nail / empty nail; Dad's face is the one mosaic that never clears; one set of footprints out.
- Show-not-tell devices: figure in the window gone after the first blink (`first_blink_hide`); montage
  figure stepping closer per blink (`montage_show`); calendar stuck on that December; clipping prop.
Order: Road, Gate, Porch -> Living (7), Kid (7), Kitchen (9), Grandma gone (11), Letter (15), Door (17),
Torn, Leaving, Goodbye, Lane -> Postcards, Winters (her postcards), Kitchen now, Taped, Truth, Lane at
night, Photo, Fireplace -> Headlights.

## Placement check
`-- --blinkcheck` (headless ok): every MemoryFigure is tested from its posed skeleton (legs, spine, head)
against level colliders and the floor, with a suggested free spot when it overlaps; every beat prop is
tested for resting on a surface. Room floors are visual 6 cm boxes without colliders (treated as floor).
Seated figures may touch their chair. Run it after moving any figure or prop.

## Dialogue pace and cut-off cue
- `blink_demo.gd` exports `voice_speed` (1.12: voices play faster at the same pitch via
  `Sound.voice_speed` + a `<bus>_Paced` pitch-fix bus) and `line_pace` (0.85: multiplies `line_times`).
  Gap after a spoken line is 0.3 s.
- The metronome (blink offer) never arms while a line is being said: it waits until the beat's last
  line (and any voice still playing, e.g. a hotspot caption) has ≤ 0.35 s left (`_talk_end`,
  `Sound.voice_time_left()`).
- Blinking over a line (`_cut`): `BlinkCaption.interrupt()` leaves the heard words up with a dash, dim,
  then fades. Blinking just before the next line plays a 0.45 s snatch of it + its first two words with
  a dash, so the player knows something was left unsaid. `Sound.voice_progress()` gives 0..1 of the line.

## "Keep your eyes shut" cue
- `BlinkUI.listen_on`: a small eye at the bottom slowly shuts and STAYS shut while a ring fills
  (loops), with the word "hold" under it for the first 3 beats that use it (`listen_words`).
- `blink_demo._update_listen_hint()` turns it on when the beat has something behind closed eyes
  (`closed_eyes_sound` / `_caption` / `_lines`) that hasn't been heard yet, once nobody is talking.
  The first time it shows in a beat, a faint leak of the hidden sound (or the first hidden line's
  voice) plays at -26 dB - the murmur you'd have to close your eyes to hear properly.

## Doors, snow, footprints
- Doors: `scripts/objects/panel_door_model.gd` (`PanelDoorModel`, @tool) builds a six-panel door
  (stiles, rails, raised fields, beads, lever handles, hinges) and optionally its frame (jamb lining,
  stop, architrave, plinth blocks) from meshes, textured with Poly Haven `fine_grained_wood`.
  Used by `interior_door.tscn` (LeafModel + FrameModel) and `study_door.tscn`. The old box
  FrontDoorFrame in the house is hidden.
- `scripts/objects/snow_track.gd` (`SnowTrack`, @tool): footprints as Decals with generated
  textures, walking along local -Z; `fill` = half-snowed-over, `snow_patch` lays snow first (porch).
  Used: PorchBeat/StepPrints ("one set, going out"), RoadBeat/MyPrints, LaneBeat/OneSetOut.
  Keep prints where the camera focuses: depth of field blurs the near ground and the world is
  desaturated, so faint prints vanish.
- PorchBeat/Props/DadsCoat: coat rack + a hanging coat (meshes) with grey snow on the shoulders,
  lit by CoatLight, so the hotspot line "On the hook inside, Dad's coat" shows when the door opens.

## Voice-over
Every caption is voiced (narrator / Mum / Dad), found by a hash of its text: see `12-vfx-and-audio.md`. Edit a line → re-run `tools/blink_voice_over.py` or it plays silent.

## Gotchas
- The automatic run disables BlinkUI mouse input: a real mouse over the window would steer it.
- `Sound.play` on a stream someone else looped with `_set_loop` loops forever — don't use
  `*_loop` files (wind, house tone, fire) as one-shot closed-eyes sounds.
- tscn files written from PowerShell 5.1 with `Set-Content -Encoding utf8` get a BOM; write with
  `[IO.File]::WriteAllText(path, text, (New-Object Text.UTF8Encoding $false))`.
- Grandma's armchair faces +X: film her from x≈0.3, not from the room's front.
- Kitchen table was a 42 cm side table (WoodenTable_02) with the tea set floating at 0.8 m: replaced by
  round_wooden_table_01 at scale 0.76 (top 0.82); builder now takes an optional 5th scale field; kitchen
  RoomFillLight raised to 2.5 m so the cups don't blow out.
