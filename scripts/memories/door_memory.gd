extends Memory
## MEMORY 3: HOLD THE DOOR (hallway).
## A muffled argument behind the study door. The player tries to hold the door open while
## it shoves back; they can slow it but never win. It slams, colour drains, and the
## bedroom opens. (StudyDoor holds the mini-game; this script reacts to it.)
##
## How to change it: argument_sound_point / lines below; difficulty is on StudyDoor.

@export var struggle_prompt := "keep pressing interact to hold it"
@export var slam_line := "\"...then go!\""
@export var slam_voice := "v_slam"

@onready var study_door: StudyDoor = $StudyDoor
@onready var argument_point: Marker3D = $ArgumentSoundPoint


func _ready() -> void:
	study_door.enabled = false
	study_door.struggle_started.connect(_on_struggle_started)
	study_door.pushed.connect(func(): game.player.add_shake(0.35, 0.25))
	study_door.shoved.connect(func(): game.player.add_shake(0.5, 0.35))
	study_door.slammed.connect(_on_slammed)


func begin() -> void:
	study_door.enabled = true
	Sound.play_at("argument_muffled", argument_point.global_position, -2.0)


func _on_struggle_started() -> void:
	game.player.can_move = false
	game.hud.show_prompt(struggle_prompt)


func _process(_delta: float) -> void:
	if study_door.is_struggling:
		game.hud.set_progress(study_door.push_amount)


func _on_slammed() -> void:
	game.hud.show_prompt("")
	game.hud.set_progress(-1.0)
	Sound.play("door_slam", 2.0)
	game.player.add_shake(1.0, 0.9)
	game.screen_effects.pulse(0.7, 0.012)
	var flash := game.hud.fade_to(0.6, 0.05)
	flash.tween_property(game.hud.screen_fade, "color:a", 0.0, 0.6)
	game.hud.say(slam_line, 2.5, slam_voice)
	game.player.can_move = true
	finish()


func debug_complete() -> void:
	study_door.on_interact()
