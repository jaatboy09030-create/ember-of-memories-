class_name Memory
extends Node3D
## BASE SCRIPT for one memory (one step of the story).
## The GameDirector (main.gd) runs the memories in order: it calls begin(), waits for the
## `completed` signal, applies the shared "memory restored" effects below, then starts the next.
## Each memory scene only handles its own mini-game; the shared look-and-feel lives here.
##
## How to change a memory without code (select its node in main.tscn, look at the Inspector):
##   room_id            -> which room warms up when it is restored (matches a Room node's room_id)
##   unlocks_door_id    -> which door opens afterwards (matches an InteriorDoor's door_id)
##   saturation_after   -> how much colour returns to the world (0 = grey, 1 = full colour)
##   ember_rest_point   -> where the ember waits while this memory is active

signal completed

## Room that warms up when this memory is restored ("" = none).
@export var room_id := ""
## Door that unlocks and swings open when this memory is restored ("" = none).
@export var unlocks_door_id := ""
## World colour after this memory (0 grey .. 1 full colour). Negative = leave unchanged.
@export_range(-1.0, 1.0) var saturation_after := -1.0
## How long the colour change takes, in seconds.
@export var saturation_time := 2.5
## Should the room's lights turn warm when this memory is restored?
@export var warms_room := true
## Where the ember floats while the player works on this memory.
@export var ember_rest_point: Node3D

## Set by the GameDirector before begin(): gives access to player, hud, ember, effects.
var game: GameDirector


## Called by the GameDirector when this memory becomes the active one. Override it.
func begin() -> void:
	pass


## Wakes the frozen parent/child figures that belong to this memory.
func wake_figures() -> void:
	for f in find_children("*", "", true, false):
		if f is MemoryFigure:
			f.wake()


## The shared "a memory comes back" moment: sound, a glance, a breath of warmth.
func play_restore_moment(look_at_point: Vector3) -> void:
	Sound.play("memory_restore", -2.0)
	Sound.play("memory_wake", -6.0)  # a breath of the people coming back, layered over the swell
	game.player.glance(look_at_point, 0.45)
	MemoryMotes.burst(self, look_at_point)  # golden motes + a warm light pop, same frame as the sound
	game.player.add_shake(0.15, 0.8)
	game.screen_effects.warm_flash()
	game.screen_effects.remember()  # the mosaic rule: every face gets a little clearer


## Call when the mini-game is finished. The director takes it from there.
func finish() -> void:
	completed.emit()
