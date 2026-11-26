class_name Ember
extends Node3D
## EMBER: the glowing companion. It never drags you around: it waits, softly bobbing,
## above where you need to go next.
##   follow = true  -> drifts to float above `target` (a Node3D), or to `anchor`
##   follow = false -> sits at `anchor` (a world position); Vector3.INF = stay put
## The story (main.gd) moves the target from memory to memory.
##
## How to change it: drift_speed, hover_height, bob_amount, flicker below; colour and
## brightness are on EmberCore and EmberLight in the Inspector.

@export var follow := false
@export var drift_speed := 1.2
## Height above the target it floats at.
@export var hover_height := 1.55
@export var bob_amount := 0.08
@export var base_light_energy := 2.2

var target: Node3D
var anchor := Vector3.INF

@onready var light: OmniLight3D = $EmberLight

var _time := 0.0


func _ready() -> void:
	add_to_group("colour_source")  # MemoryGrade brings colour back in a halo around the ember


func _process(delta: float) -> void:
	_time += delta
	var bob := Vector3(0, sin(_time * 2.0) * bob_amount, 0)
	if not follow:
		if anchor != Vector3.INF:
			global_position = global_position.lerp(anchor + bob, 2.0 * delta)
		return
	var goal := global_position
	if target:
		goal = target.global_position + Vector3(0, hover_height, 0)
	elif anchor != Vector3.INF:
		goal = anchor
	global_position = global_position.lerp(goal + bob, clampf(drift_speed * delta, 0.0, 1.0))
	light.light_energy = base_light_energy + sin(_time * 7.0) * 0.15 + sin(_time * 13.0) * 0.08


## Wait at a fixed point (not following).
func wait_at(point: Vector3) -> void:
	follow = false
	anchor = point


## Float above a node, following it.
func lead_to(node: Node3D) -> void:
	follow = true
	target = node
