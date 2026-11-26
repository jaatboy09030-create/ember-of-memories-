class_name MemoryGrade
extends ColorRect
## MEMORY GRADE: how a frozen memory looks on screen (shaders/memory_grade.gdshader).
## Replaces the old flat grey with:
##   - a moonlit duotone: shadows sink into deep blue, highlights go cold silver; lamps, fire
##     and the ember keep their warm colour
##   - colour glowing back in a halo around the ember (any node in group "colour_source"),
##     so the companion visibly carries warmth through the grey house
##   - frost creeping in from the screen edges that slowly breathes while frozen
##   - a warm ring of colour sweeping out from the centre when a memory is restored (ripple())
## It sits first inside ScreenEffects, before GradeCopy + FilmLook (lens, vignette, grain).
## ScreenEffects.world_saturation drives it through set_world_saturation().
##
## How to change it: the @export values below; colours, frost reach and breathing speed are on
## Material in the Inspector (memory_grade.gdshader uniforms).

## Halo radius around the ember, in screen heights, when the ember is 2 m away.
@export var halo_size := 0.22
## How strongly colour comes back around the ember (0 = off, 1 = full colour).
@export_range(0.0, 1.0) var halo_strength := 0.85
## How fast the halo fades in/out when the ember goes behind a wall or off screen (per second).
@export var halo_fade_speed := 3.0
## Seconds the restore ripple takes to cross the screen.
@export var ripple_time := 1.6
## Seconds the colour inside the ripple lingers before the new world colour takes over.
@export var ripple_fade_time := 1.4

@onready var grade: ShaderMaterial = material

var _halo := 0.0
var _ripple: Tween


func set_world_saturation(value: float) -> void:
	grade.set_shader_parameter("world_sat", value)


## A memory comes back: a warm ring of colour sweeps out from the middle of the screen.
func ripple() -> void:
	if _ripple and _ripple.is_valid():
		_ripple.kill()  # a new restore restarts the ring instead of fighting the old one
	grade.set_shader_parameter("ripple_hold", 1.0)
	_ripple = create_tween()
	var tw := _ripple
	tw.tween_method(func(r: float): grade.set_shader_parameter("ripple", r), 0.0, 1.6, ripple_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(h: float): grade.set_shader_parameter("ripple_hold", h), 1.0, 0.0, ripple_fade_time)
	tw.tween_callback(func(): grade.set_shader_parameter("ripple", -1.0))


## Every frame: where the ember is on screen, how big its halo is, and whether it is visible.
func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var src := get_tree().get_first_node_in_group("colour_source") as Node3D
	var target := 0.0
	var centre := Vector2.ZERO
	var radius := 0.0
	if cam and src and src.is_visible_in_tree() and not cam.is_position_behind(src.global_position):
		var p := src.global_position
		centre = cam.unproject_position(p)
		var dist := maxf(cam.global_position.distance_to(p), 0.5)
		radius = get_viewport_rect().size.y * halo_size * clampf(2.0 / dist, 0.35, 1.5)
		target = halo_strength
		# hidden behind a wall? then no colour bleeds through it
		var hit := src.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(cam.global_position, p))
		if not hit.is_empty() and (hit.position as Vector3).distance_to(p) > 0.4:
			target = 0.0
	_halo = move_toward(_halo, target, delta * halo_fade_speed)
	grade.set_shader_parameter("ember", Vector4(centre.x, centre.y, radius, _halo))
