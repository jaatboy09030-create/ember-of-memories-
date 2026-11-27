class_name MemoryIsland
extends Marker3D
## MEMORY ISLAND (blink demo): one patch of the remembered room that shows through the
## black void (shaders/blink_void.gdshader). Everything outside every island is black.
## The island is a (stretchable) sphere in WORLD space, so it stays glued to the room
## when the camera moves. bloom() grows it like ink spreading on wet paper.
##
## How to change it: move the node, set radius and stretch in the Inspector.
## hidden_at_start islands only appear when something blooms them (an EyeHotspot).

## Size in metres.
@export var radius := 1.0
## Stretch per axis (2 on X = twice as wide).
@export var stretch := Vector3.ONE
## How softly this island melts into neighbours (metres). 0 = hard separate islands.
@export var blend := 0.3
## True = starts invisible; an EyeHotspot blooms it.
@export var hidden_at_start := false
## Seconds for the ink bloom.
@export var bloom_time := 1.6

## 0 = gone .. 1 = full size.
var amount := 0.0
var _tw: Tween


## The beat starts: visible islands bloom open, hidden ones wait.
func enter() -> void:
	amount = 0.0
	if not hidden_at_start:
		bloom()


func bloom(time := -1.0) -> void:
	_tween_to(1.0, bloom_time if time < 0.0 else time, Tween.EASE_OUT)


## Shrink toward `to` (0..1) over `time` seconds: the memory slipping away.
func wither(to: float, time: float) -> void:
	_tween_to(to, time, Tween.EASE_IN_OUT)


func packed_centre() -> Vector4:
	var p := global_position
	return Vector4(p.x, p.y, p.z, radius * amount)


func packed_shape() -> Vector4:
	var s := stretch.max(Vector3.ONE * 0.05)
	return Vector4(1.0 / s.x, 1.0 / s.y, 1.0 / s.z, blend)


func _tween_to(value: float, time: float, ease_type: Tween.EaseType) -> void:
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(self, "amount", value, time).set_trans(Tween.TRANS_CUBIC).set_ease(ease_type)
