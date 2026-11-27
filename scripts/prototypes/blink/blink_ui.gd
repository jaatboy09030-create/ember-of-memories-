class_name BlinkUI
extends Control
## BLINK UI (blink demo): everything drawn on top of the memory.
## - The reticle: two thin ink arcs around the cursor. They tighten over an eye hotspot,
##   telling you "a blink now LOOKS at this instead of skipping time".
## - The eye icon: a white line-drawn eye floating on the active hotspot.
## - The metronome: a small swinging pendulum at the bottom. While it ticks, your next
##   blink lets go of this memory.
## The cursor follows the mouse, or the right stick (look_* actions).
##
## How to change it: sizes and colours below.

## A metronome tick (swing reached the end).
signal metronome_tick

## The camera used to place the eye icon on its 3D point.
@export var camera: Camera3D
## Gamepad cursor speed (pixels per second).
@export var stick_speed := 900.0
@export var reticle_radius := 30.0
## How close the reticle must be to an eye to "look at" it (pixels).
@export var hover_radius := 70.0
@export var eye_size := 24.0
## Seconds per metronome swing.
@export var metronome_beat := 0.8
@export var ink := Color(1, 1, 1, 0.8)

var cursor := Vector2.ZERO
## Active eye hotspot (set by the demo). Null = none.
var hotspot: EyeHotspot
var hovering := false
var hotspot_position := Vector3.ZERO
var metronome_on := false

var _r := 30.0
var _time := 0.0
var _swing := 0.0
var _metro_alpha := 0.0
var _eye_alpha := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor = get_viewport_rect().size * 0.5


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		cursor = (event as InputEventMouseMotion).position


## Cursor as -1..1 on each axis (0 = screen centre).
func normalized_cursor() -> Vector2:
	var s := get_viewport_rect().size
	return ((cursor / s) * 2.0 - Vector2.ONE).clamp(-Vector2.ONE, Vector2.ONE)


func _process(delta: float) -> void:
	_time += delta
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	cursor = (cursor + stick * stick_speed * delta).clamp(Vector2.ZERO, get_viewport_rect().size)
	var eye_visible := hotspot != null and hotspot.is_active() and camera != null \
		and not camera.is_position_behind(hotspot.global_position)
	hovering = false
	if eye_visible:
		hotspot_position = hotspot.global_position
		hovering = camera.unproject_position(hotspot_position).distance_to(cursor) < hover_radius
	_eye_alpha = move_toward(_eye_alpha, 1.0 if eye_visible else 0.0, delta * 1.5)
	_r = lerpf(_r, reticle_radius * (0.55 if hovering else 1.0), 1.0 - exp(-10.0 * delta))
	_metro_alpha = move_toward(_metro_alpha, 1.0 if metronome_on else 0.0, delta * 2.5)
	if metronome_on:
		var before := floori(_swing)
		_swing += delta / metronome_beat
		if floori(_swing) != before:
			metronome_tick.emit()
	queue_redraw()


func _draw() -> void:
	_draw_eye()
	_draw_reticle()
	_draw_metronome()


func _draw_reticle() -> void:
	var c := ink
	c.a *= 0.55 if not hovering else 0.95
	draw_arc(cursor, _r, PI * 0.62, PI * 1.38, 24, c, 2.0, true)
	draw_arc(cursor, _r, -PI * 0.38, PI * 0.38, 24, c, 2.0, true)
	draw_circle(cursor, 1.8, c)


func _draw_eye() -> void:
	if _eye_alpha <= 0.01 or not hotspot or not camera or camera.is_position_behind(hotspot_position):
		return
	var p := camera.unproject_position(hotspot_position)
	var pulse := 1.0 + 0.06 * sin(_time * 3.0)
	var s := eye_size * pulse * (1.3 if hovering else 1.0)
	var c := ink
	c.a = _eye_alpha * (1.0 if hovering else 0.75)
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for i in 21:
		var x := lerpf(-s, s, i / 20.0)
		var y := s * 0.55 * (1.0 - pow(x / s, 2.0))
		upper.append(p + Vector2(x, -y))
		lower.append(p + Vector2(x, y))
	draw_polyline(upper, c, 2.0, true)
	draw_polyline(lower, c, 2.0, true)
	draw_arc(p, s * 0.32, 0.0, TAU, 24, c, 2.0, true)
	draw_circle(p, s * 0.13, c)


func _draw_metronome() -> void:
	if _metro_alpha <= 0.01:
		return
	var c := ink
	c.a = _metro_alpha * 0.85
	var s := get_viewport_rect().size
	var pivot := Vector2(s.x * 0.5, s.y - 118.0)
	var base_y := s.y - 58.0
	# body: a narrow trapezoid
	var body := PackedVector2Array([
		Vector2(pivot.x - 6.0, pivot.y - 8.0), Vector2(pivot.x + 6.0, pivot.y - 8.0),
		Vector2(pivot.x + 20.0, base_y), Vector2(pivot.x - 20.0, base_y), Vector2(pivot.x - 6.0, pivot.y - 8.0)])
	draw_polyline(body, c, 2.0, true)
	var angle := 0.42 * cos(PI * _swing)
	var tip := pivot + Vector2(sin(angle), cos(angle)) * 46.0
	draw_line(pivot, tip, c, 2.0, true)
	draw_circle(pivot + Vector2(sin(angle), cos(angle)) * 30.0, 4.0, c)
