class_name BlinkCaption
extends Label
## BLINK CAPTION (blink demo): a line of text that fades in and out. cut() kills it
## instantly, the way a blink cuts a memory off mid-sentence.
##
## Every line is also spoken: the voice file is found from the text itself
## (assets/audio/blink/bvn_<sha1>.ogg = narrator, bvm_<sha1>.ogg = someone in the memory), so any line
## with a recording plays it, and the caption stays up until the line ends. cut() also cuts the voice.
## Regenerate the recordings after changing a line (see MEMORY/12-vfx-and-audio.md).
##
## How to change it: fade_time; voiced = false for text only; font and size in the Inspector.

@export var fade_time := 0.6
@export var voiced := true

var _tw: Tween


func _ready() -> void:
	modulate.a = 0.0


## Show `line` for `duration` seconds. duration <= 0 = stay until cut() or another say().
func say(line: String, duration := 3.0) -> void:
	if voiced:
		var v := voice_for(line)
		if v != "":
			var length: float = Sound.play_voice(v)
			if duration > 0.0:
				duration = maxf(duration, length + 0.3)
	if _tw:
		_tw.kill()
	text = line
	modulate.a = 0.0
	_tw = create_tween()
	_tw.tween_property(self, "modulate:a", 1.0, fade_time)
	if duration > 0.0:
		_tw.tween_interval(duration)
		_tw.tween_property(self, "modulate:a", 0.0, fade_time + 0.3)


## The recording for a line ("" if none).
static func voice_for(line: String) -> String:
	var h := line.sha1_text().substr(0, 12)
	for prefix in ["blink/bvn_", "blink/bvm_"]:
		if Sound.get_stream(prefix + h):
			return prefix + h
	return ""


## How long the recording of a line lasts (0 if none).
static func voice_length(line: String) -> float:
	var v := voice_for(line)
	return Sound.voice_length(v) if v != "" else 0.0


## Cut off mid-sentence by a blink: the words already heard (or the first words of the line that
## was coming) stay up with a dash, dim, then fade - so you know something was left unsaid.
## heard = 0..1 how much of the line was spoken; < 0 = it hadn't started (a snatch of it plays).
func interrupt(line: String, heard := -1.0) -> void:
	var words := line.split(" ", false)
	var keep: int
	if heard < 0.0:
		keep = clampi(2, 1, words.size())
		if voiced:
			var v := voice_for(line)
			if v != "":
				Sound.play_voice(v)
				var snatch := line
				get_tree().create_timer(0.45).timeout.connect(func():
					if text.ends_with("—") and snatch.begins_with(text.trim_suffix("—")):
						Sound.stop_voice())  # only if a new line hasn't started meanwhile
	else:
		Sound.stop_voice()
		keep = clampi(int(ceil(words.size() * heard)), 1, maxi(1, words.size() - 1))
	text = " ".join(words.slice(0, keep)).rstrip(".,;:!?-") + "—"
	if _tw:
		_tw.kill()
	modulate.a = 0.75
	_tw = create_tween()
	_tw.tween_interval(0.9)
	_tw.tween_property(self, "modulate:a", 0.0, 0.8)


## Gone, right now (text and voice).
func cut() -> void:
	Sound.stop_voice()
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(self, "modulate:a", 0.0, 0.06)
