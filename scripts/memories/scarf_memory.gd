extends Memory
## MEMORY 1: THE SCARF (living room) - also the tutorial.
## The unravelled red scarf hangs on the coat rack by the front door. The player knits it
## back with alternating needle presses. Grandma (in the armchair) and the boy are frozen
## mid-moment until it's done.
##
## How to change it: restored_line / restored_voice = what is heard when it's finished.
## Knitting difficulty is on the ScarfCoatRack node.

@export var restored_line := "\"There. Now you won't get cold.\""
@export var restored_voice := "v_scarf"

@onready var coat_rack: ScarfCoatRack = $ScarfCoatRack


func _ready() -> void:
	coat_rack.enabled = false
	coat_rack.stitch_knitted.connect(func(): game.player.add_shake(0.04, 0.15))
	coat_rack.knitted.connect(_on_knitted)


func begin() -> void:
	coat_rack.enabled = true


func _on_knitted() -> void:
	wake_figures()
	play_restore_moment(coat_rack.global_position + Vector3(0, 1.4, 0))
	game.hud.say(restored_line, 7.0, restored_voice)
	finish()


func debug_complete() -> void:
	for i in coat_rack.stitches_needed:
		coat_rack._knit_stitch("left" if i % 2 == 0 else "right")
