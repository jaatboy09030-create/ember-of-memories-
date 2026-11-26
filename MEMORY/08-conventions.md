# 08 — Conventions (owner's rules — follow exactly)

## Godot scene structure
- **Build in the scene tree, not at runtime.** Nodes that exist for the whole game live in `.tscn` files, visible in the editor.
- **One script per node**; a script only does its node's job. Coordination happens through signals and the GameDirector.
- **Reusable things are their own scene and are instanced** (doors, windows, interactables, figures, memories).
- **Node names are readable PascalCase** describing what they are (`StudyDoor`, `EmberRestPoint`, `PieceByTheBed`), never `Node3D2`.
- Group related nodes under named parents (`Exterior`, `House/Doors`, `Rooms/<Room>/Props`, `PackableItems`).
- **Tunables are `@export`** with a `##` doc comment so they can be changed in the Inspector without code.
- **Every script starts with a `##` header**: what it is (CAPS name), what it does, and "How to change it".
- File names snake_case; `class_name` PascalCase; scenes and scripts mirror each other's folder (`scenes/objects/x.tscn` ↔ `scripts/objects/x.gd`).
- Use static typing (`var x := ...`, typed function signatures) like the existing code.

## Interaction
- Everything usable extends `Interactable` (Area3D) and is found by the player's `InteractionRaycast` (RayCast3D).
- Objects never reference the story; they emit signals. Memories listen.

## Input
- Only Input Map actions — never raw keycodes / device checks in gameplay code.
- Every action needs **both** a keyboard/mouse binding **and** a gamepad binding.

## Scope
- Build **step by step**; don't jump ahead to features not asked for.
- **Mini-games only when the owner asks**, and each mini-game is its own scene.

## Tools
- Blender (via MCP) may be used for models/levels, but **always ask the owner before starting** Blender work.
- Prefer free/CC0 assets (Poly Haven, Quaternius); CC-BY needs a credit line in `assets/sketchfab/CREDITS.md`.

## Git
- Don't commit or push unless asked. If on `main`, create a branch first. PRs go through the fork.
- Commit messages: short imperative title + bullet list of what changed (see `git log`).

## This MEMORY folder
- Update it in the same change as the code (see README "How to maintain").
