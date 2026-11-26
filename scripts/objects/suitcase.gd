class_name Suitcase
extends Interactable
## SUITCASE in the bedroom (memory 4). It stays disabled until every PackableItem is in it;
## then the player can close it ("interact"), which emits `closed` and ends the memory.
## PackPoint marks where packed items land.

signal closed

@onready var pack_point: Marker3D = $PackPoint


func _ready() -> void:
	super._ready()
	enabled = false


func on_interact() -> void:
	super.on_interact()
	enabled = false
	Sound.play("suitcase_close", -2.0)
	closed.emit()
