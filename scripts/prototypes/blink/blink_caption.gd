class_name BlinkCaption
extends Label
## BLINK CAPTION (blink demo): a line of text that fades in and out. cut() kills it
## instantly, the way a blink cuts a memory off mid-sentence.
##
## How to change it: fade_time; font and size in the Inspector (Theme Overrides).

@export var fade_time := 0.6

var _tw: Tween


func _ready() -> void:
	modulate.a = 0.0


## Show `line` for `duration` seconds. duration <= 0 = stay until cut() or another say().
func say(line: String, duration := 3.0) -> void:
	if _tw:
		_tw.kill()
	text = line
	modulate.a = 0.0
	_tw = create_tween()
	_tw.tween_property(self, "modulate:a", 1.0, fade_time)
	if duration > 0.0:
		_tw.tween_interval(duration)
		_tw.tween_property(self, "modulate:a", 0.0, fade_time + 0.3)


## Gone, right now.
func cut() -> void:
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(self, "modulate:a", 0.0, 0.06)
