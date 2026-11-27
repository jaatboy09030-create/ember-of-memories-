# 07 — Synthesis: why Unsent feels generic, and what gives it an identity

Combines files 01–05 (06 adds sourcing). Where several reports reached the same idea on their own,
that is noted — those are the strongest signals.

## 1. Diagnosis

1. **One loop, six skins.** Every room: walk in → mini-game → colour returns → door opens. After room 2 the
   player can predict the rest, and predictability kills suspense (01, 02).
2. **The mini-games reward skill; the story is about feeling.** Knitting, rotating pieces and packing are
   "complete the task" verbs. Nothing in the input itself means anything, nothing changes partway, nothing
   can be visibly lost (02).
3. **The house never reacts.** Nothing changes behind you, nothing is withheld, nothing is wrong. A suspense game
   needs expectation + uncertainty; we have neither (01).
4. **The twist is already given away.** The premise tells you you're the child; "you never came back" is a guilt
   beat, not a reveal. The Ember has no secret (04).
5. **Our one unique thing is unused.** The pixelated faces are the moment that works — and they are pure style,
   with no rule, no story reason, no payoff (01, 03, 04, 05 all said this independently).

## 2. Identity pillars (the rules every room must obey)

1. **The mosaic is memory.** *(reached independently by 01, 02, 03, 04, 05)*
   Faces are pixelated because **you** forgot them. One global value (`face_resolution`) drives it everywhere:
   ghost faces, photos, names in letters, your own face in mirrors, even captions and voices (bit-crushed).
   It sharpens when you look steadily / restore a memory, coarsens when colour drains.
   Payoff: in the photo room the parent's face goes clear — and **yours** is the one that stays blurred.
2. **The house is watching.** Every room has one change you didn't see happen (a prop moved, a second cup,
   footprints that only go in, a light on upstairs). The front hall changes a little on every pass (01, 03).
3. **One verb: hold.** A shared "hold" input threads the game — hold the needles, hold the door, hold the
   suitcase shut, hold the match. After the twist, holding becomes *keeping the fire going*, the parent's
   verb, now yours (02).
4. **You can lose things.** Each memory has a visible, slow loss: the rhythm fades, the grip slips, the suitcase
   only fits three things. What you leave behind matters later (02, 03).
5. **Silence before every reveal; the next room is heard through the wall.** Sound leads, image follows (05).

## 3. Story spine (from 04)

Keep the current arc, add three layers that need no new systems:
- **A — The faces are your forgetting.** Seeded from the gate onward.
- **B — The unsent letter is yours.** The parent's letter is a reply to one you wrote and never sent.
  Final beat: you finish/burn your letter to relight the fire (03's "letter built from what you looked at").
- **C — The Ember is the parent** (or their last warmth). It goes out between rooms 3 and 4 (01) — the house
  goes dark and you carry on alone; at the end you carry the light (02).
Endings (04): Send / Keep / Leave, plus a secret one on a replay.

## 4. Room-by-room redesign (best idea per room, effort S/M/L)

| Room | Now | Redesign | Suspense beat | Effort |
|---|---|---|---|---|
| Arrival / hall | walk to gate, porch | Footprints in the snow go **in** only. Hall changes on every pass (one cup → two cups → one). Answering machine with a rising message count. | Lamp in an upstairs window goes off as you reach the porch. | S |
| 1 Scarf | alternate presses | Rhythm fades as the memory fades; **dropped stitches stay in the scarf** (it's in the ending). Music box plays in time with your presses (05). | A silhouette gathers behind you while you knit; gone when you turn. | M |
| 2 Drawing | collect & rotate | Scraps only line up from a **child's crouched height** (03). One piece was redrawn by the parent and almost fits (02). | A scrap you didn't pick up is back on the floor. | M |
| 3 Door | mash, always lose | Prompt turns **HOLD → LET GO** (04): you weren't losing, you were leaving. Grip slips on its own while you press (02); it *almost* holds (01). | Ember goes out after the slam. | S |
| 4 Suitcase | pack 4 items | **Room for three.** What you leave is what the parent kept by the fire (02, 03). One item keeps reappearing on the bed (04). Clock chime as a soft timer (01). | Unpacked items stay grey; colour drains as you choose. | M |
| 5 Photo | flip, cutscene, letter | Parent's face clears; **mirror shows your face still pixelated**. Letter quotes small things you did earlier (02). | Hard silence before the flip (05). | M |
| 6 Fireplace | relight, ending | Feed the fire with what you restored / burn your unsent letter. Hold to keep it going. Ending varies by choice. | — | M |

## 5. Cheap wins to try first (each S, mostly independent)

1. Shared mosaic shader with one global `face_resolution` uniform (05).
2. One off-screen prop change per room (01).
3. Door prompt HOLD → LET GO + grip slip (04, 02).
4. Suitcase holds three items (02).
5. Footprints going in only + phone that rings and is unplugged when you reach it (01).
6. Audio buses + next room's memory heard muffled through the wall (05).

## 6. Suggested build order

1. Pillar 1 (mosaic system) — it's what already works; make it a rule.
2. The cheap wins above.
3. Door + suitcase rework (lose / choose).
4. Story layers A–C and the Ember going out.
5. Knitting rhythm, drawing crouch, letter memory, endings.

## 7. From the web pass (06)

- Nothing in 01–05 was found clearly wrong; 02 misnames the Unpacking GDC talk (real: "Unpacking a Narrative
  Through 1,000 Household Items").
- Strongest real dev sources: Shibata on Fatal Frame's camera, the Exit 8 dev interview, Ken Wong on Florence
  playtests, Before Your Eyes blink interviews, Paratopic's IGF interview, Ryan Green on That Dragon, Cancer.
- New references worth a look: Wayward Harbor and A Mirror, Darkly (mirror mechanics → room 5 mirror),
  Home Safety Hotline / Don't Hang Up (phone horror → answering machine), Almost Home Now, Chasing Static.
- **Overlap risk:** Steam app 3916390 has nearly our premise (return to childhood home at night, 40–60 min).
  Check it before committing to the story.

## 8. Open decisions for the owner

- Keep "Ember = parent" or another identity (04 lists five)?
- One ending or multiple?
- How much horror: uncanny-quiet (Gone Home/Edith Finch) or real scares (P.T./Exit 8)? Most ideas here assume
  **uncanny-quiet with 2–3 real spikes**.
