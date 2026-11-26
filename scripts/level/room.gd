class_name Room
extends Node3D
## ROOM: one room of the house (floor, ceiling, wall lining, props, lights).
## Its RoomFillLight is cold and dim while the memory is frozen; warm_up() turns it warm
## when the room's memory is restored. The story finds rooms by room_id.
##
## How to change it: room_id must match the Memory.room_id that warms it.
## Edit RoomFillLight in the Inspector for the cold look; warm_color for the restored look.

@export var room_id := ""
@export var warm_color := Color(1.0, 0.7, 0.45)
@export var warm_time := 2.5

@onready var fill_light: OmniLight3D = $RoomFillLight


func _ready() -> void:
	add_to_group("room")


func warm_up(energy := 1.6) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fill_light, "light_color", warm_color, warm_time)
	tw.tween_property(fill_light, "light_energy", energy * 0.9, warm_time)
