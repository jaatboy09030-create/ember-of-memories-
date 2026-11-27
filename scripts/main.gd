class_name GameDirector
extends Node3D
## GAME DIRECTOR (root of main.tscn). It only coordinates; every system does its own work.
##
## The story = the children of the "Memories" node, played top to bottom:
##   ArrivalMemory -> ScarfMemory -> DrawingMemory -> DoorMemory -> SuitcaseMemory
##   -> PhotoMemory -> FireplaceMemory
## To reorder the story, reorder those children. To add a step, add a scene whose script
## extends Memory and put it in the list.
##
## For each memory the director: points the ember at its EmberRestPoint, calls begin(),
## waits for `completed`, then applies the shared restore effects the memory asks for in
## the Inspector (colour, warm room, unlock door) and moves on.
##
## Main scene layout:
##   WorldEnvironment, Moon   -> night lighting
##   HouseLevel               -> garden + house + rooms (scenes/level/house_level.tscn)
##   Player, Ember            -> the player and the glowing companion
##   Memories                 -> the story steps (above)
##   Snowfall, TitleSequence  -> weather and the opening shot
##   HUD, ScreenEffects       -> on-screen UI and the film look
##   AmbienceMixer, OutdoorCulling, DevTests -> helpers

@export var player: PlayerBody
@export var ember: Ember
@export var hud: HUD
@export var screen_effects: ScreenEffects
@export var title_sequence: TitleSequence
@export var world_environment: WorldEnvironment
## World colour when the game starts (0 grey .. 1 full colour).
@export_range(0.0, 1.0) var start_saturation := 0.3
## Off = set everything up but don't play the title or the story (used by prototypes that
## reuse this scene, e.g. scenes/prototypes/blink_demo.tscn).
@export var autostart := true

@onready var memories_root: Node3D = $Memories
@onready var dev_tests: Node = $DevTests

var memories: Array[Memory] = []
var rooms := {}   # room_id -> Room
var doors := {}   # door_id -> InteriorDoor
var current_index := -1


func _ready() -> void:
	screen_effects.world_saturation = start_saturation
	hud.connect_interaction(player.interaction_raycast)
	for r in get_tree().get_nodes_in_group("room"):
		rooms[r.room_id] = r
	for d in get_tree().get_nodes_in_group("interior_door"):
		doors[d.door_id] = d
	for m in memories_root.get_children():
		if m is Memory:
			m.game = self
			m.completed.connect(_on_memory_completed.bind(m))
			memories.append(m)
	if not autostart:
		return
	if dev_tests.wants_to_run():
		dev_tests.run(self)
		return
	title_sequence.finished.connect(start_story)
	title_sequence.play(self)


func start_story() -> void:
	_start_memory(0)


func _start_memory(index: int) -> void:
	current_index = index
	if index >= memories.size():
		return
	var m := memories[index]
	if m.ember_rest_point:
		ember.lead_to(m.ember_rest_point)
	m.begin()


func _on_memory_completed(m: Memory) -> void:
	if m.saturation_after >= 0.0:
		screen_effects.fade_saturation(m.saturation_after, m.saturation_time)
	if m.warms_room and rooms.has(m.room_id):
		rooms[m.room_id].warm_up()
	if m.unlocks_door_id != "" and doors.has(m.unlocks_door_id):
		doors[m.unlocks_door_id].unlock_and_open()
	_start_memory(memories.find(m) + 1)


## Cutscene framing: letterbox bars and a heavier vignette (or back to normal).
func set_cinematic(on: bool, time := 1.2) -> void:
	hud.letterbox(on, time)
	if on:
		screen_effects.set_vignette(0.5, time)
	else:
		screen_effects.reset_vignette(time)
