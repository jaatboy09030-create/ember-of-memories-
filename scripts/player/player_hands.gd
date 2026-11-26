class_name PlayerHands
extends Node
## PLAYER HANDS: lets the character hold something in both hands and look down at it.
## Two arm IK nodes on the skeleton (LeftArmHoldIK / RightArmHoldIK, TwoBoneIK3D) pull the
## wrists to two grip markers on the held object; the elbows point toward the ElbowPole
## markers; HeadBow tips the head down. Everything is off (influence 0) until hold().
##
## How to change it: blend_time = how long the arms take to come up; the elbow direction =
## BodyPivot/ElbowPoleLeft/Right; the grip points live on the held object (e.g. PhotoFrame).

@export var blend_time := 1.2

@onready var player: PlayerBody = get_parent()
@onready var left_ik: TwoBoneIK3D = $"../BodyPivot/CharacterModel/Skeleton3D/LeftArmHoldIK"
@onready var right_ik: TwoBoneIK3D = $"../BodyPivot/CharacterModel/Skeleton3D/RightArmHoldIK"
@onready var head_bow: HeadBow = $"../BodyPivot/CharacterModel/Skeleton3D/HeadBow"

var _tween: Tween


## Bring both wrists to `left_grip` / `right_grip` and bow the head, over `time` seconds.
func hold(left_grip: Node3D, right_grip: Node3D, time := blend_time) -> void:
	left_ik.set_target_node(0, left_ik.get_path_to(left_grip))
	right_ik.set_target_node(0, right_ik.get_path_to(right_grip))
	_blend(1.0, time)


## Let the arms fall back to the animation.
func release(time := blend_time) -> void:
	_blend(0.0, time)


func _blend(to: float, time: float) -> void:
	if _tween:
		_tween.kill()
	if time <= 0.0:
		left_ik.influence = to
		right_ik.influence = to
		head_bow.influence = to
		return
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(left_ik, "influence", to, time)
	_tween.tween_property(right_ik, "influence", to, time)
	_tween.tween_property(head_bow, "influence", to, time * 1.4)
