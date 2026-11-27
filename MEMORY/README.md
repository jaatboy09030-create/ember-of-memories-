# MEMORY — shared project knowledge for AI assistants (and humans)

This folder is the **project's long-term memory**. Any AI (Claude, Copilot, Cursor, GPT, ...)
working on this repo should read it **before touching code**, and **update it after** any change
that alters structure, dependencies, conventions, or teaches a lesson.

Goal: nobody re-discovers the same dependency, re-makes the same mistake, or re-invents a
workflow that already has a recipe here.

Last full audit: **2026-11-26**, at commit `c806893` (main). Updated the same day for the uncommitted look/opening pass (see CHANGELOG).

---

## Read order

| # | File | Read it when |
|---|------|--------------|
| 1 | [01-project-overview.md](01-project-overview.md) | Always first. What the game is, engine, folders, how to run. |
| 2 | [02-architecture.md](02-architecture.md) | Before changing any system. Scene tree, story flow, dependency graph, layers, groups, input. |
| 3 | [03-scripts-reference.md](03-scripts-reference.md) | Looking up what a script does, its signals/API, and who depends on it. |
| 4 | [04-memories.md](04-memories.md) | Working on a story step / mini-game. Per-memory config and wiring. |
| 5 | [05-assets-shaders-audio.md](05-assets-shaders-audio.md) | Adding/replacing models, sounds, shaders, materials; licences. |
| 6 | [06-recipes.md](06-recipes.md) | Doing a repetitive task (new interactable, memory, sound, door, prop, test run...). Follow step by step. |
| 7 | [07-gotchas-and-learnings.md](07-gotchas-and-learnings.md) | **Before debugging anything.** Known pitfalls and their fixes. |
| 8 | [08-conventions.md](08-conventions.md) | Before writing code. The owner's rules — non-negotiable. |
| 9 | [09-camera.md](09-camera.md) | Touching the camera, screen look, lens, shake or comfort settings. Research + backlog. |
| 10 | [10-story-and-gameplay.md](10-story-and-gameplay.md) | Briefing someone new: story, gameplay, flow, presentation, where it's going. |
| 11 | [11-blink-demo.md](11-blink-demo.md) | Working on the Before Your Eyes style blink prototype (scenes/prototypes/blink_demo.tscn). |
| 12 | [CHANGELOG.md](CHANGELOG.md) | To see what changed recently and why. |
| 13 | [../research/00-unsent-opening-recipe.md](../research/00-unsent-opening-recipe.md) | **Before any lighting / art-direction work.** Researched recipe + index of 10 reports. |

---

## How to maintain this folder (rules for every AI)

1. **Update in the same change** that alters the code. A PR that renames a script, adds a memory,
   adds an asset folder, or changes a layer/group/input action must update the matching file here.
2. **New pitfall found?** Add it to `07-gotchas-and-learnings.md` with *symptom → cause → fix*.
3. **Did a task more than once?** Write it as a numbered recipe in `06-recipes.md`.
4. **Log it**: add a dated line to `CHANGELOG.md` (newest on top): what changed, why, files.
5. Keep facts **verifiable**: name the file/node/function. If something here is found wrong,
   fix it here immediately — stale memory is worse than none.
6. Don't paste whole scripts; summarise role, API, dependencies. The code is the source of truth
   for details, this folder is the map.
7. Split a file only when it gets hard to scan (~400+ lines); don't create one file per fact.
