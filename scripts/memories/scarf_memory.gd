extends Memory
## MEMORY 1: THE SCARF (living room) - also the tutorial.
## The unravelled red scarf hangs on the coat rack by the front door. When the ember
## settles over it, a subtitle tells the player to interact. Using the rack glides the view
## into the DarningMinigame: mending the hole in the scarf on a darning loom, row by row
## (flick the hooks, draw the needle through), while colour seeps back into the room.
## When it's done the view glides back facing grandma (in the armchair) and the boy, and
## the boy puts the scarf on. The step-by-step prompts come from the minigame itself.
##
## How to change it: the lines below; the minigame's own settings are on DarningMinigame.

@export var interact_hint := "LMB to interact"
@export var restored_line := "\"There. Now you won't get cold.\""
@export var restored_voice := "v_scarf"
## Colour in the knitting close-up: starts at the first value and rises to the second as
## stitches are made, so the red yarn reads clearly. (After the close-up the world settles
## to this memory's saturation_after.)
@export var closeup_saturation_start := 0.6
@export var closeup_saturation_end := 1.0
## How close the ember must be to its resting spot before the hint appears (metres).
@export var ember_arrival_distance := 0.35
## When the knitting ends, the view glides back to face these (grandma and the boy).
@export var look_at_after_knitting: Array[Node3D] = []
## Height above their feet to look at (about chest height).
@export var look_height := 0.85
## The boy, and the animation he plays once the scarf is done (putting it on).
@export var boy_figure: MemoryFigure
@export var boy_wear_clip: PackedScene
## Seconds after the view lands on them before the boy starts.
@export var boy_wear_delay := 0.6

@onready var coat_rack: ScarfCoatRack = $ScarfCoatRack
@onready var minigame: DarningMinigame = $DarningMinigame

var _waiting_for_ember := false


func _ready() -> void:
	coat_rack.enabled = false
	coat_rack.interacted.connect(_open_minigame)
	minigame.stitch_completed.connect(_on_stitch_completed)
	minigame.prompt_changed.connect(func(text: String): game.hud.show_prompt(text))
	minigame.finished.connect(_on_knitted)


func begin() -> void:
	coat_rack.enabled = true
	_waiting_for_ember = true


func _process(_delta: float) -> void:
	if not _waiting_for_ember:
		return
	var rest := ember_rest_point.global_position + Vector3(0, game.ember.hover_height, 0)
	if game.ember.global_position.distance_to(rest) < ember_arrival_distance:
		_waiting_for_ember = false
		game.hud.say(interact_hint, 5.0)


func _open_minigame() -> void:
	_waiting_for_ember = false
	game.player.can_move = false
	game.player.cam.cinematic = true
	game.hud.set_crosshair_visible(false)
	game.hud.clear_caption()
	game.set_cinematic(true, camera_glide_time())
	game.screen_effects.fade_saturation(closeup_saturation_start, camera_glide_time())
	minigame.open(game.player.cam)
	get_tree().create_timer(camera_glide_time()).timeout.connect(func(): game.hud.set_progress(0.0))


func camera_glide_time() -> float:
	return minigame.camera_move_time


func _on_stitch_completed(done: int, total: int) -> void:
	var p := float(done) / total
	coat_rack.set_progress(p)
	game.hud.set_progress(p)
	game.screen_effects.fade_saturation(lerpf(closeup_saturation_start, closeup_saturation_end, p), 0.8)
	if done >= total:
		game.hud.show_prompt("")
		game.hud.set_progress(-1.0)
		# turn the (hidden) first-person view toward them now, so the camera glides out
		# of the close-up straight onto grandma and the boy
		game.player.look_at_point(_figures_point())
		game.player.cam.snap_to_head()


## Between the figures, at chest height: where the view turns after knitting.
func _figures_point() -> Vector3:
	if look_at_after_knitting.is_empty():
		return coat_rack.global_position + Vector3(0, 1.4, 0)
	var sum := Vector3.ZERO
	for f in look_at_after_knitting:
		sum += f.global_position
	return sum / look_at_after_knitting.size() + Vector3(0, look_height, 0)


func _on_knitted() -> void:
	game.set_cinematic(false)
	game.player.cam.cinematic = false
	game.player.can_move = true
	game.hud.set_crosshair_visible(true, 0.8)
	wake_figures()
	if boy_figure and boy_wear_clip:
		get_tree().create_timer(boy_wear_delay).timeout.connect(func(): boy_figure.play_clip(boy_wear_clip))
	play_restore_moment(_figures_point())
	game.hud.say(restored_line, 3.5, restored_voice)
	finish()


func debug_complete() -> void:
	coat_rack.on_interact()
	await get_tree().create_timer(camera_glide_time() + 0.2).timeout
	minigame.debug_weave_all()
