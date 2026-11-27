class_name PackableItem
extends Interactable
## PACKABLE ITEM (memory 4, "pack the suitcase").
## A belonging lying in the bedroom. Using it lifts it in front of the player's eyes while
## its memory line is shown (the player can look around; holding "rotate_item" turns the
## item through turn_by()), and "interact" again packs it into the suitcase. SuitcaseMemory
## does the holding; this script only holds the item's data, turns it and flies it away.
##
## How to change it: memory_line = the caption shown while inspecting it.
## Swap the model by replacing the ItemModel child.

signal chosen(item: PackableItem)

## Caption shown while the player holds this item.
@export_multiline var memory_line := "Something I left behind."
## Voice clip spoken with the caption (assets/audio/<name>), "" = caption only.
@export var memory_voice := ""
## Seconds the item takes to fly into the suitcase.
@export var pack_time := 0.7


func _ready() -> void:
	super._ready()
	enabled = false


func on_interact() -> void:
	super.on_interact()
	enabled = false
	chosen.emit(self)


## Turns the held item the way the mouse/stick moves: amount.x around the view's up axis,
## amount.y around the view's right axis (radians). view = the camera's global basis.
func turn_by(amount: Vector2, view: Basis) -> void:
	global_rotate(view.y.normalized(), amount.x)
	global_rotate(view.x.normalized(), amount.y)


func fly_into(suitcase_point: Vector3) -> void:
	Sound.play("pack_item", -4.0, 0.1)
	var spot := suitcase_point + Vector3(randf_range(-0.25, 0.25), 0.3, randf_range(-0.12, 0.12))
	var tw := create_tween()
	tw.tween_property(self, "global_position", spot, pack_time).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(self, "rotation", Vector3(0, randf() * TAU, 0), pack_time)
