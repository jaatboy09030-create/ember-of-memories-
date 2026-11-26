class_name PuzzlePiece
extends Area3D
## PUZZLE PIECE: one quarter of the torn drawing on the desk (memory 2).
## It starts turned the wrong way; every turn_quarter() rotates it 90 degrees.
## The piece is correct when it has been turned back to 0.
##
## How to change it: start_quarter_turns (0..3) = how it starts rotated.

## How many 90-degree turns away from correct the piece starts (0 = already correct).
@export_range(0, 3) var start_quarter_turns := 1
## Seconds one turn takes.
@export var turn_time := 0.18

const HIGHLIGHT_SHADER := preload("res://shaders/interact_highlight.gdshader")

var quarter_turns := 0
var _overlay: ShaderMaterial


func _ready() -> void:
	quarter_turns = start_quarter_turns
	rotation.y = quarter_turns * PI * 0.5


func is_correct() -> bool:
	return quarter_turns % 4 == 0


func turn_quarter() -> void:
	quarter_turns = (quarter_turns + 1) % 4
	Sound.play("paper_pickup", -6.0, 0.15)
	create_tween().tween_property(self, "rotation:y", rotation.y + PI * 0.5, turn_time).set_trans(Tween.TRANS_SINE)


## Instantly put the piece the right way round (used by the dev tests).
func snap_correct() -> void:
	quarter_turns = 0
	rotation.y = 0.0


func set_selected(on: bool) -> void:
	if _overlay == null:
		_overlay = ShaderMaterial.new()
		_overlay.shader = HIGHLIGHT_SHADER
		_overlay.set_shader_parameter("strength", 1.2)
	for g in find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).material_overlay = _overlay if on else null
