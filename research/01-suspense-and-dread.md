# 01 - Suspense and Dread Without Enemies (for "Unsent")

## Summary

Games with no enemies build dread out of four things: **expectation** (the player thinks something will happen), **withheld information** (the player can't see or understand something yet), **wrongness** (a familiar place breaks its own rules), and **rhythm** (long quiet stretches with rare spikes, never a constant drone). P.T., The Exit 8, Gone Home, Edith Finch, Visage, Mouthwashing, Iron Lung and Anatomy all use a domestic or mundane space that changes slowly, and almost none of them rely on a monster.

Unsent's problem is that every room runs the same loop: walk in, play the mini-game, colour comes back, move on. Nothing in that loop is uncertain, the house never reacts to the player, and the twist (you are the child who left) isn't hinted at until the end. Three changes would help most:

1. **The house changes behind the player's back.** Over the course of the game the cottage should come to show that someone lived here for years waiting, through details like a second cup set out, doors that close, or a chair that has turned.
2. **The pixelated ghosts become the identity.** Make the faces a rule the player learns: the mosaic sharpens when the ghosts face you and breaks up when you look away. Reveal *your own* face last.
3. **Each mini-game gets a source of pressure from outside the mini-game itself**, such as sound, something watching, or the space changing. Then the "boring" tasks become the moments when the player is vulnerable.

Rough Godot effort: S = under 1 day, M = 1-3 days, L = about a week.

---

## Techniques

### 1. Changes made while the player isn't looking
- **What:** Something in the room changes while the camera is turned away. Players notice it either consciously or only half-consciously.
- **Games:** P.T. (the hallway gets worse on each loop), The Exit 8 (players spot changes out of the corner of their eye), Visage, Layers of Fear (rooms rebuild themselves behind you), Anatomy.
- **Why it works:** The player can no longer trust what they remember, which feels unsafe even though nothing attacks them. And because the change happened off-screen, it suggests someone else is in the house.
- **Unsent:** In Room 1 (knitting), the rocking chair is still when the player arrives. After the first restore, it faces the player. In the hallway between rooms 2 and 3, a coat hangs on the hook, and after Room 3 it is gone. In Room 4 (packing), the item you just packed is back on the shelf. This only happens once, and nothing ever comments on it.
- **Godot:** S. Use `VisibleOnScreenNotifier3D`, or a dot product between the camera's forward vector and the direction to the object. Swap the transform or visibility only when the object is off-screen for more than 1 second.

### 2. Finding the differences (familiar space, slightly off)
- **What:** The player crosses the same space several times, and something is slightly different each time.
- **Games:** The Exit 8 and its imitators (Platform 8, etc.), P.T., Anatomy (the tapes degrade the house).
- **Why it works:** It turns walking, which is normally dead time, into active watching. Repetition makes the player relaxed, and the change then breaks that.
- **Unsent:** The front hall is the hub, and the player passes it after every room. Each pass changes one thing: the clock moves back a year, the photos on the wall lose a person, or there are more footprints in the snow by the door, all going *in*. The last pass shows the hall the way the parent kept it: dusted, one cup, a lamp left on in the window. This is how the "kept the fire going" twist gets foreshadowed.
- **Godot:** S-M. Give the hub a `pass_count` and apply a list of node toggles per pass.

### 3. Holding back what the player wants to see (framing and corners)
- **What:** Use corners, door frames, partly open doors, and light the player can't see clearly to delay a reveal.
- **Games:** P.T. (Killscreen argues the corner, not the corridor, is the key piece of architecture), Fatal Frame (you only see properly through the camera), Gone Home (locked rooms, notes found later).
- **Why it works:** Suspense is the time between knowing that something is there and seeing it.
- **Unsent:** In Room 5 (the photo flip), make the photo face-down in a frame on a high shelf, so the player sees its back over several rooms (it shows up in Room 2's doorway and Room 4's mirror) before they can reach it. In Room 3, the player should never see the parents directly, only shadows under the door and ghost light through the keyhole.
- **Godot:** S for placing props, M for the keyhole view (`SubViewport` plus a mask).

### 4. Rules that apply to the ghosts' faces
- **What:** A visual effect becomes a learnable rule with consequences, so it stops being decoration.
- **Games:** Fatal Frame (the camera shows things), The Exit 8 (the man's face is the tell), Mouthwashing (a damaged face is the theme), Signalis (images that break down).
- **Why it works:** The one moment that already feels unique in Unsent is seeing the ghosts' faces. Make it a system and build tension around it.
- **Unsent:** The mosaic block size depends on distance and on whether the player is looking. Up close and looking directly, the faces get *almost* sharp, but never fully. Players will lean in, and leaning in should feel risky. In Room 4, when colour drains, the ghost-child's mosaic gets coarser, so the memory is forgetting you. In the Room 5 cutscene, the face that finally resolves is the player's own, older. Elsewhere, the player's reflection in windows or mirrors is pixelated too, and this should be planted early in Room 1's window.
- **Godot:** M. Use a screen-space or billboard pixelate shader with a uniform `block_size` driven by distance and angle in `_process`.

### 5. A false safe zone that is later broken
- **What:** Set up a place or companion as safe, then break that once.
- **Games:** Firewatch (the radio voice you trust, then the camp you find), Inscryption, Pony Island, Stories Untold (a cosy desk that becomes a trap), Doki Doki-style betrayals.
- **Why it works:** Something that was taken away from the player is worse than something that was never there.
- **Unsent:** The Ember is the safe zone: warm light and a guide. Once, between rooms 3 and 4, the Ember goes out or leaves without the player. The house goes fully dark, the body-cam grain spikes, and the player hears the front door open downstairs, the night they left playing back. When the Ember returns, it is dimmer for the rest of the game. This also foreshadows the Room 6 ending: the fire is something someone has to keep alive.
- **Godot:** S-M. Use a state on the Ember script plus an audio event and a post-process tween.

### 6. Rhythm: long quiet, rare spikes, and no spike where one is expected
- **What:** Writers on horror pacing say tension needs to build and then release. Story-driven horror often fails because it builds and never releases, or because nothing is happening at all. Also plan *fake* spikes, where the player braces for something that never comes.
- **Games:** P.T., Iron Lung (constant low pressure with very few events), Paratopic (sudden cuts), Visage.
- **Why it works:** A constant drone stops registering. Contrast is what makes the quiet frightening.
- **Unsent:** Plot one tension curve for the whole game. Rooms 1-2 are quiet and cosy with one tiny wrongness each. Room 3 is the first real spike (the argument). Rooms 3-4 hold the blackout and the drain. Room 5 is the biggest spike, the face reveal. Room 6 is the release. Don't place two spikes back to back. Add one fake: a phone rings in the hall, and by the time you reach it, it stops and is unplugged.
- **Godot:** S as design work. Keep the curve in a doc or in `MEMORY/`.

### 7. Sound as the threat
- **What:** Off-screen sound that has a location in space: footsteps upstairs, a door, a kettle, breathing, someone saying your name. Silence used as an event.
- **Games:** P.T. (the radio, a baby crying, the phone), Gone Home (storm and creaks), Visage, Kitty Horrorshow games (droning tones), Puppet Combo (low-fi foley), Lake (plain sounds that cut against the mood).
- **Why it works:** The ear can't be turned away, and imagination fills in the gap.
- **Unsent:** Footsteps on the floor above should match the player's own pace and stop half a step after the player stops. A kettle should start boiling somewhere in the house, because the parent is still making tea for two. During knitting, the clicks of the needles should drift slightly out of sync with the player's presses, as if someone else is knitting. Cut all ambience for 2 seconds right before each restore.
- **Godot:** S-M. Use `AudioStreamPlayer3D`, plus a bus with a low-pass filter for "through the walls".

### 8. Pressure on the mini-game from outside it
- **What:** The task itself is simple, but the world around it gets worse while the player's attention is locked on it.
- **Games:** Iron Lung (taking photos while the hull creaks), Five Nights-style split attention, Mouthwashing (doing chores while things fall apart), Fatal Frame (you lose peripheral vision while looking through the viewfinder).
- **Why it works:** Focusing on the task means the player can't look around.
- **Unsent:** Narrow the field of view and add a vignette during every mini-game.
  - **Knitting:** while you knit, a ghost silhouette gathers at the window behind you. The audio cue (cold air, the curtain) is your only warning, and it is gone when you turn around.
  - **Drawing scraps:** one scrap is a drawing of the player as an adult, which the child couldn't have drawn.
  - **Packing:** colour drains from the edges inward, plus a timer the game never mentions: the downstairs clock chimes. Each item you inspect shows a memory; each item you leave stays grey for ever. Choosing what to pack *is* the suspense, because something gets left behind (the parent).
  - **Door mash:** the player always loses, but the door should hold *almost* long enough. Hide a false hope inside the mechanic, then crush it.
- **Godot:** M per room.

### 9. A player who is wrong about who they are
- **What:** The truth about the player-character is held back, but the clues are fair.
- **Games:** Mouthwashing, What Remains of Edith Finch (the frame story), Stories Untold, Signalis, Firewatch.
- **Why it works:** Each clue makes the player suspect, and suspecting is suspense about the past.
- **Unsent:** Seed clues. Your footprints in the snow lead *out* of the cottage but never in. Letters on the hall table are stamped "return to sender". The door frame has height marks that stop at age 12. The parent's ghost never looks at the child-ghost, only at the door. Every door the player opens says "welcome home" to them in the parent's voice, and only from Room 4 onward.
- **Godot:** S (props and text).

### 10. Wrongness in time and logic (lighting, physics, space)
- **What:** Small violations of how the world works: a room bigger than the hall outside it, snow falling indoors, a clock running backwards, light coming from a source that isn't there.
- **Games:** Kitty Horrorshow (Anatomy's house grows), Paratopic, Layers of Fear, Dread Delusion.
- **Why it works:** It turns the cosy setting against the player without any blood.
- **Unsent:** After Room 4, the corridor gets one door longer. Snowflakes float in the cottage air near any memory that hasn't been restored yet. Room 6's fireplace is already warm before you light it.
- **Godot:** S-M.

### 11. Degrading the camera and the medium
- **What:** The image itself (the tape, the lens, the screen) shows the stress.
- **Games:** Anatomy (tape degradation), Stories Untold, Paratopic and Puppet Combo's VHS look, Iron Lung's photos, Pony Island (the interface lies).
- **Why it works:** Unsent already has a body-cam lens. Make it react, so it carries story instead of being a filter.
- **Unsent:** The lens fogs near memories that haven't been restored, then clears. When a ghost face gets close, chromatic aberration should spike. In Room 4, the lens itself should drain of colour along with the room. A timestamp in the corner of the body-cam reads the date the child left, and it ticks forward only once, at the end.
- **Godot:** S. Expose the existing shader uniforms and tween them.

---

## Top 10 for Unsent (ranked by impact per effort)

1. **The hub hall changes on every pass** to foreshadow "kept the fire going" (techniques 2 and 9). S-M.
2. **Ghost faces sharpen and break up by rule, ending with your own face** (technique 4). M. This builds on the one moment that already feels unique.
3. **Off-screen prop swaps, about once per room** (technique 1). S.
4. **Footsteps upstairs that match the player's pace; a kettle making tea for two** (technique 7). S.
5. **The Ember goes out between Room 3 and Room 4** (technique 5). S-M.
6. **Packing as a choice with loss: unpicked items stay grey, and the clock chimes as a timer** (technique 8). M.
7. **Pressure from outside each mini-game** (a narrowed field of view plus something happening behind the player). M.
8. **A planned tension curve with one fake spike (the phone)** (technique 6). S.
9. **The body-cam reacts: fog, chromatic aberration near faces, a timestamp** (technique 11). S.
10. **Fair clues to the twist (footprints only going out, height marks, returned letters)** (technique 9). S.

---

## Sources

- Killscreen, "The corridor and the corner" (P.T.): https://killscreen.com/pt-turns-corner-horror
- Press Start (Glasgow), academic paper on the uncanny in P.T.: https://press-start.gla.ac.uk/press-start/article/download/121/78/700
- Hardcore Gaming 101, P.T.: https://www.hardcoregaming101.net/p-t/
- Dread Central, "P.T. is the scariest video game that never was": https://dreadcentral.com/editorials/435309/p-t-is-the-scariest-video-game-that-never-was
- Wireframe, the lasting influence of P.T.: https://wireframe.raspberrypi.com/articles/the-lasting-influence-of-hideo-kojimas-p-t
- BFI, P.T. at 10 years: https://bfi.org.uk/features/pt-10-years-hideo-kojima-guillermo-del-toros-horror-micro-masterpiece
- AV Club, P.T. 10-year anniversary: https://www.avclub.com/pt-10-year-anniversary-look-behind-you-explained
- Adrian Hon on The Exit 8: https://adrianhon.substack.com/p/the-exit-8
- Aftermath on The Exit 8: https://aftermath.site/the-exit-8-japanese-subway-system-ocd-game-backrooms-liminal-space
- Automaton, Exit 8 "no anomaly" bug reports: https://automaton-media.com/en/news/20231208-23845/
- Game Developer, "The balancing act of tension in horror game design": https://www.gamedeveloper.com/design/the-balancing-act-of-tension-in-horror-game-design
- Game Developer, "The back half problems of horror design": https://www.gamedeveloper.com/design/the-back-half-problems-of-horror-design
- Game Developer, scary secrets of Silent Hill 4: The Room (the apartment as a safe zone that gets corrupted): https://www.gamedeveloper.com/design/the-scary-secrets-of-horror-design-from-silent-hill-4-the-room
- Gamasutra, eight tools for horror from the maker of FAITH: https://gamasutra.com/design/eight-tools-for-creating-chilling-horror-from-the-maker-of-i-faith-i-
- GameDev.net, pacing and building tension in horror: https://gamedev.net/blogs/entry/2274395-how-to-use-pacing-and-build-tension-in-a-horror-game
- GameDev.net, "Defining horror as tension" (Silent Hill f, GDC): https://gamedev.net/news/4735-defining-horror-as-tension-silent-hill-f/
- GDC Vault, adapting linear audio techniques for horror: https://gdcvault.com/play/1026396/

Notes on sources:
- Reddit and X were not fetched directly. Community views here come from reviews and coverage that quote players.
- The game examples not linked above (Gone Home, Edith Finch, Firewatch, Mouthwashing, Iron Lung, Anatomy, Visage, Signalis, Inscryption, Paratopic, Stories Untold, Fatal Frame, Lake, Puppet Combo) are described from general knowledge of those games, not from a fetched source.
