class_name GardenGate
extends Node3D
## GARDEN GATE: starts wide open. Once the story arms it (arm()), the first time the
## player walks through the CloseTrigger strip inside the garden, both leaves swing shut
## behind them and an invisible blocker stops them going back out.
##
## How to change it: close_time = swing duration; move/resize CloseTrigger to change
## where the gate shuts.

signal closed

## Seconds the leaves take to swing shut.
@export var close_time := 1.6

@onready var left_hinge: Node3D = $LeftLeafHinge
@onready var right_hinge: Node3D = $RightLeafHinge
@onready var blocker_shape: CollisionShape3D = $ClosedGateBlocker/BlockerShape
@onready var close_trigger: Area3D = $CloseTrigger

var armed := false
var is_closed := false


func _ready() -> void:
	blocker_shape.disabled = true
	close_trigger.body_entered.connect(_on_close_trigger_body_entered)


## Called by the story once the player has reached the gate.
func arm() -> void:
	armed = true


func _on_close_trigger_body_entered(body: Node3D) -> void:
	if armed and not is_closed and body is CharacterBody3D:
		close(body)


func close(player: Node = null) -> void:
	is_closed = true
	var sound_pos := global_position + Vector3(0, 1.0, 0)
	Sound.play_at("door_creak", sound_pos, -4.0)
	var tw := create_tween().set_parallel(true)
	for hinge in [left_hinge, right_hinge]:
		tw.tween_property(hinge, "rotation:y", 0.0, close_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		Sound.play_at("door_slam", sound_pos, -10.0)
		if player and player.has_method("add_shake"):
			player.add_shake(0.08, 0.3)
		blocker_shape.disabled = false
		closed.emit())
