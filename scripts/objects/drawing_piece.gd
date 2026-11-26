class_name DrawingPiece
extends Interactable
## DRAWING PIECE: one torn scrap of the child's drawing lying on the floor (memory 2).
## Look at it and press "interact" to pick it up. It then disappears and emits `picked_up`.
## It starts hidden and disabled; DrawingMemory shows it when the memory begins.

signal picked_up(piece: DrawingPiece)


func _ready() -> void:
	super._ready()
	reveal(false)


## Show or hide the piece (hidden pieces can't be used).
func reveal(on: bool) -> void:
	visible = on
	enabled = on


func on_interact() -> void:
	super.on_interact()
	Sound.play("paper_pickup", -4.0, 0.1)
	enabled = false
	picked_up.emit(self)
	queue_free()
