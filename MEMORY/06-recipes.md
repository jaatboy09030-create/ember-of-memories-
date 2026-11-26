# 06 — Recipes (repeatable tasks)

Follow these step by step. If you do a new kind of task twice, add a recipe here.
`GODOT = "C:\Program Files\Godot\Godot.exe"`; run from the project root.

---

## R1. Run the automated tests (do this after every gameplay change)
```powershell
& "C:\Program Files\Godot\Godot.exe" --headless --path . -- --storytest
& "C:\Program Files\Godot\Godot.exe" --headless --path . -- --walktest
& "C:\Program Files\Godot\Godot.exe" --headless --path . -- --walktest --gate
& "C:\Program Files\Godot\Godot.exe" --headless --path . -- --doortest
```
Read the `TEST ...` lines; every one must say PASS (doortest also covers locked-door rattle and the one-way front door). The `--` separates engine args from user args
(`OS.get_cmdline_user_args`). Storytest has a 45 s timeout per memory.
If you move an interactable that storytest ray-checks (ScarfCoatRack, StudyDoor, PhotoFrame, Fireplace),
**update the stand/target positions in `scripts/dev/dev_tests.gd::_story_test`**.

## R2. Add a new interactable object
1. New scene `scenes/objects/<thing>.tscn`, root **Area3D** named in PascalCase.
2. Add `CollisionShape3D` slightly bigger than the mesh; add the model as a child.
3. Script `scripts/objects/<thing>.gd`: `class_name Thing` / `extends Interactable`, `##` header comment
   (what it is, how to change it), `@export` tunables.
4. If you override `_ready`, call `super._ready()` first. Override `on_interact()` (call `super.on_interact()`).
   Optional: `get_prompt()`, `get_progress()`, `on_interact_held(delta)`.
5. Expose results as **signals** (`chosen`, `closed`...). Do not reach into the story from the object.
6. Start `enabled = false` if a memory should switch it on.
7. Nothing to change in player/raycast/HUD.

## R3. Add a new memory (story step)
1. Scene `scenes/memories/<name>_memory.tscn`, root Node3D `<Name>Memory`, script `extends Memory`.
2. Put its objects inside as instances; add `EmberRestPoint` (Marker3D) and assign it to `ember_rest_point`.
3. Set on the root in the Inspector: `room_id`, `unlocks_door_id`, `saturation_after`, `warms_room`.
4. In the script: `@onready` refs, connect object signals in `_ready()`, enable objects in `begin()`,
   call `finish()` when done. Use `game.player / game.hud / game.screen_effects / play_restore_moment()`.
5. Implement `debug_complete()` (completes it without input) for DevTests.
6. Instance it under `Main/Memories` **at the position in the story** (child order = play order).
7. Add a row to `MEMORY/04-memories.md`. Run R1.
Mini-games are only added when the owner asks (see 08-conventions).

## R4. Add a sound
1. Drop `<name>.mp3` (or .ogg/.wav) into `assets/audio/`; let Godot import it (open editor or run once).
2. Call `Sound.play("<name>", db)` / `Sound.play_at("<name>", pos, db, looped)` / `Sound.play_music("<name>")`.
3. Missing files fail silently — if you hear nothing, check the name and that the `.import` exists.
4. Add it to the audio table in 05.

## R5. Add / wire a door
1. Instance `scenes/objects/interior_door.tscn` under `HouseLevel/House/Doors`, rotate to fit the wall.
2. Set `door_id` (unique) and leave `locked = true`.
3. Set the same id on the Memory that should open it (`unlocks_door_id`).

## R6. Add a ghost figure to a memory
Instance `scenes/objects/memory_figure.tscn` inside the memory scene → add Mixamo FBX child named `CharacterModel`
→ optional `SeatPoint` Marker3D + assign `seat_point` → tune `frozen_at`. Memory calls `wake_figures()` on success.
Mixamo FBX must contain `mixamorig_Head` (face pixelation) / `mixamorig_Hips` (seating).

## R7. Add a prop to the level
Preferred: open `scenes/level/house_level.tscn` in the editor and place it under `Rooms/<Room>/Props` (or `Exterior/...`).
For outdoor models wrap in a Node3D with `snowy_prop.gd` (grey + snow) or `snowy_foliage.gd` (MegaKit foliage);
add it to group `outdoor_only` if it should hide when indoors. Give it a collider if the player must not walk through.
Poly Haven: download glTF 1k into `assets/polyhaven/<id>/`. Sketchfab: put glb in `assets/sketchfab/` and credit it.

## R8. Regenerate the level (destructive)
```powershell
& "C:\Program Files\Godot\Godot.exe" --headless --path . -s res://tools/level_builder.gd
```
Throws away every hand edit in `house_level.tscn` and rewrites `materials/level/`. Only do it if asked; prefer editing the scene.
Afterwards re-check the memory scenes still line up (it prints `PLACED` positions of the furniture memories use: desk,
chairs, dresser, nightstands, bedroom table), run R12 (overlap check) and R1.

## R9. Add an input action
Add it in `project.godot [input]` (or Project Settings → Input Map) with **both** a keyboard/mouse and a gamepad event.
Read it only via `Input.is_action_*` / `event.is_action_pressed`. Update the table in 02.

## R10. Inspect an imported model's node tree
Edit the path in `tools/debug_model.gd`, then:
```powershell
& "C:\Program Files\Godot\Godot.exe" --headless --path . -s res://tools/debug_model.gd
```
Useful to find `scarf_mesh_path`-style NodePaths inside glb/fbx imports.

## R12. Check that nothing passes through anything
```powershell
& "C:\Program Files\Godot\Godot.exe" --headless --path . -s res://tools/overlap_check.gd
```
Last line must be `overlap_check: 0 problem(s)`. `known` lines (the study door set into the hallway wall) are fine. Run it
after moving props, regenerating the level (R8) or moving memory objects. Ghost figures are not checked: look at seated
figures from the side in the editor.

## R11. Finish any change
Update the relevant `MEMORY/*.md`, add a dated entry to `MEMORY/CHANGELOG.md`, run R1, then commit.
Commit/push only when the owner asks; branch first if on `main`.
