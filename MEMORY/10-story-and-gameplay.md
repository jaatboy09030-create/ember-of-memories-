# 10 — Unsent: story, gameplay and flow (context for anyone new)

A one-page brief for teammates, collaborators and AI assistants. For code details see 02 (architecture) and
04 (per-memory wiring). For where the design is heading, see `research/07-synthesis.md`.

## In one line
A short first-person suspense / grief walking-sim: you come home, at night, in the snow, to a cottage you left
long ago — and piece back together the memories you let go of.

## The story

**Setup.** A grown child returns to their childhood cottage on a snowy night. The house is dark, cold and grey.
A small glowing **Ember** waits at the garden gate and leads them inside.

**The house remembers.** Every room holds a frozen memory: faint ember-gold ghosts of the family, caught
mid-moment, their **faces pixelated**. Restoring each memory brings back colour and warmth to the room.

**The arc, room by room**
1. **Arrival** — the gate, the snow, the first sight of the ghosts. "...home."
2. **Living room — the scarf.** Grandma knitting a scarf while the boy watches. A warm, safe memory.
3. **Kid's room — the drawing.** A child's drawing, torn up. You find the scraps and tape it back together;
   it goes back on the wall.
4. **Hallway — the door.** Muffled shouting behind the study door: the parents arguing. You try to hold the
   door shut. You always lose. It slams. The warmth drains back out.
5. **Bedroom — the suitcase.** The night you left. You pick up and pack your things one by one, and the colour
   drains from the world with each item. You close the suitcase. "I left that night..."
6. **Parent's room — the photo.** A photo turned face down. You flip it. The camera leaves your body for the
   first time and turns to show *your* face. Then the parent's letter: they waited, and **kept the fire going**.
7. **The fireplace.** You relight the fire. Full colour, full music, the camera cranes up over the warm house.
   End title.

**The twist.** You are the child who left and never came back. The letter was never sent — the parent kept the
fire going for someone who didn't return.

## Gameplay

- **Controls:** first-person walk and look, one interact button (raycast from the camera). No combat, no
  inventory screen, no failure state.
- **Loop per room:** the Ember leads you to the room → you find the memory → a small mini-game → the memory is
  restored (ghosts wake, warm flash, voice line) → the next door opens.
- **Mini-games:** knitting (alternate needle presses), torn drawing (collect 3 scraps, rotate 4 pieces at a
  desk), the door (mash to hold, always lose), the suitcase (inspect and pack 4 items, then close it), the photo
  (flip it; cutscene), the fireplace (light it; ending).
- **Length:** short — one sitting.

## Presentation (what makes it look and sound like Unsent)

- **Colour is the progress bar.** The world starts grey and gains colour as memories return; it drains during
  the door and suitcase rooms and floods back at the fire.
- **The mosaic rule.** Faces are pixelated because *you* forgot them. They start as coarse blocks, get finer
  with each memory you restore and when you look at them steadily, get coarser when the world goes grey, and
  clear fully the moment a memory comes back. Your own face, shown in the photo room, stays pixelated — the one
  face you never remembered.
- **Worn-camera look.** A slight lens bend, colour fringe, grain that grows in the dark, hand-held drift and
  sway, film vignette. Prompts and captions stay clean.
- **Snow, cold breath, warm firelight.** Cold vs warm is the emotional temperature of every scene.
- **Music:** solo piano on the title → a broken music-box theme during play → the full theme at the ending.

## Flow at a glance

```
Title (piano) → Gate (Ember waits) → Porch → Living room: scarf
  → Kid's room: drawing → Hallway: door (lose) → Bedroom: suitcase (colour drains)
  → Parent's room: photo → your face → letter → Fireplace → crane shot → End title
Colour: 0.3 → 0 → 0.35 → 0.6 → 0.3 → 0 → 0.55 → 1.0
```

## Where it's going (not built yet)

The game currently feels generic: every room runs the same loop and the house never reacts. Research in
`research/` proposes (see `research/07-synthesis.md`):
- **The house is watching** — one thing changes in each room behind your back.
- **One verb: hold** — needles, door, suitcase, match; at the end, holding means keeping the fire going.
- **You can lose things** — e.g. the suitcase only fits three items; what you leave is what the parent kept.
- **Deeper twist layers** — the unsent letter is *yours*; the Ember is the parent.
- **The door scene** — the prompt turns from HOLD to LET GO: you weren't losing, you were leaving.

Open decisions: who the Ember is, one ending or several, and how scary it should be.
