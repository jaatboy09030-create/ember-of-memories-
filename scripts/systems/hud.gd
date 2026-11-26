class_name HUD
extends CanvasLayer
## HUD: everything drawn flat on the screen.
##   InteractPrompt + InteractProgress -> what you're looking at (fed by the InteractionRaycast)
##   Crosshair       -> the small dot in the middle
##   Caption         -> spoken lines / memory text (say())
##   LetterboxTop/Bottom -> cinema bars for cutscenes (letterbox())
##   ScreenFade      -> black fade in/out (fade_to())
##   EndTitle        -> the final title card
##
## How to change it: fonts, colours and positions are on the child nodes in the Inspector.
## caption_fade_time = how fast captions appear/disappear.

@export var caption_fade_time := 0.6
## Width-to-height ratio of the letterboxed picture during cutscenes.
@export var letterbox_aspect := 2.35

@onready var prompt_label: Label = $InteractPrompt
@onready var progress_bar: ProgressBar = $InteractProgress
@onready var crosshair: Label = $Crosshair
@onready var caption: Label = $Caption
@onready var screen_fade: ColorRect = $ScreenFade
@onready var end_title: Label = $EndTitle
@onready var letterbox_top: ColorRect = $LetterboxTop
@onready var letterbox_bottom: ColorRect = $LetterboxBottom

var _target: Interactable
var _manual_prompt := ""
var _manual_progress := -1.0
var _caption_tween: Tween


## Listen to a raycast so the prompt follows whatever the player looks at.
func connect_interaction(raycast: Node) -> void:
	raycast.target_changed.connect(func(t: Interactable): _target = t)


func _process(_delta: float) -> void:
	var text := _manual_prompt
	var progress := _manual_progress
	if _target and is_instance_valid(_target) and _target.enabled:
		text = _target.get_prompt()
		progress = _target.get_progress()
	prompt_label.visible = text != ""
	prompt_label.text = text
	progress_bar.visible = progress >= 0.0
	progress_bar.value = maxf(progress, 0.0) * 100.0


## Show a prompt that isn't tied to a looked-at object (e.g. during a mini-game). "" hides it.
func show_prompt(text: String) -> void:
	_manual_prompt = text


## Show a progress bar that isn't tied to a looked-at object. Negative hides it.
func set_progress(value: float) -> void:
	_manual_progress = value


## Show a caption for `duration` seconds. voice = optional audio clip name to play with it.
func say(text: String, duration := 3.0, voice := "") -> void:
	if voice != "":
		Sound.play(voice, 0.0)
	if _caption_tween:
		_caption_tween.kill()
	caption.text = text
	caption.modulate.a = 0.0
	_caption_tween = create_tween()
	_caption_tween.tween_property(caption, "modulate:a", 1.0, caption_fade_time)
	_caption_tween.tween_interval(duration)
	_caption_tween.tween_property(caption, "modulate:a", 0.0, caption_fade_time + 0.2)


## Hide the current caption right away.
func clear_caption() -> void:
	if _caption_tween:
		_caption_tween.kill()
	caption.modulate.a = 0.0


## Fade the screen to black (alpha 1) or back to clear (alpha 0).
func fade_to(alpha: float, time: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(screen_fade, "color:a", alpha, time)
	return tw


## Cinema bars in or out.
func letterbox(on: bool, time := 1.2) -> void:
	var vs := get_viewport().get_visible_rect().size
	var h := maxf((vs.y - vs.x / letterbox_aspect) * 0.5, 0.0)
	create_tween().tween_property(letterbox_top, "offset_bottom", h if on else 0.0, time).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(letterbox_bottom, "offset_top", -h if on else 0.0, time).set_trans(Tween.TRANS_SINE)


func set_crosshair_visible(on: bool, fade_time := 0.0) -> void:
	crosshair.visible = on
	if on and fade_time > 0.0:
		crosshair.modulate.a = 0.0
		create_tween().tween_property(crosshair, "modulate:a", 1.0, fade_time)


func show_end_title(fade_time := 2.5) -> void:
	end_title.visible = true
	create_tween().tween_property(end_title, "modulate:a", 1.0, fade_time)
