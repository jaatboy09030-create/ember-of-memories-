class_name PackableItem
extends Interactable
## PACKABLE ITEM (memory 4, "pack the suitcase").
## A belonging lying in the bedroom. Using it lifts it in front of the player's eyes, it
## turns slowly while its memory line is shown, and "interact" again packs it into the
## suitcase. SuitcaseMemory does the inspecting (it owns the camera); this script only
## holds the item's data and flies it into the suitcase.
##
## How to change it: memory_line = the caption shown while inspecting it.
## Swap the model by replacing the ItemModel child.

signal chosen(item: PackableItem)

## Caption shown while the player holds this item.
@export_multiline var memory_line := "Something I left behind."
## Seconds the item takes to fly into the suitcase.
@export var pack_time := 0.7


func _ready() -> void:
	super._ready()
	enabled = false


func on_interact() -> void:
	super.on_interact()
	enabled = false
	chosen.emit(self)


## Turns the item slowly while it is being looked at.
func spin(delta: float) -> void:
	rotate_y(delta * 0.7)


func fly_into(suitcase_point: Vector3) -> void:
	Sound.play("pack_item", -4.0, 0.1)
	var spot := suitcase_point + Vector3(randf_range(-0.25, 0.25), 0.3, randf_range(-0.12, 0.12))
	var tw := create_tween()
	tw.tween_property(self, "global_position", spot, pack_time).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(self, "rotation", Vector3(0, randf() * TAU, 0), pack_time)
