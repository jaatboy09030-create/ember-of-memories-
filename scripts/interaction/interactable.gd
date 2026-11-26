class_name Interactable
extends Area3D
## BASE SCRIPT for everything the player can point at and use.
## The player's InteractionRaycast finds this Area3D and calls the functions below.
## It knows nothing about valves, doors or scarves: object scripts extend this one
## and override only what is unique to them.
##
## How to make a new interactable:
##   1. New scene, root = Area3D, give it a CollisionShape3D a little bigger than the mesh.
##   2. Attach a script that starts with `extends Interactable`.
##   3. Override on_interact() (and on_hover / on_interact_held if you need them).
## No changes to the player or the raycast are ever needed.

signal hovered
signal unhovered
signal interacted

## Text shown under the crosshair while the player looks at this object.
@export var prompt_text := "interact"
## When false the player can't hover or use it (e.g. before its memory starts).
@export var enabled := true:
	set = set_enabled
## Glow drawn around the object while it is hovered.
@export var highlight_color := Color(1.0, 0.7, 0.35)
## 0 = no glow, 1 = strong glow.
@export_range(0.0, 2.0) var highlight_strength := 0.6

const HIGHLIGHT_SHADER := preload("res://shaders/interact_highlight.gdshader")
const INTERACTABLE_LAYER := 3

var is_hovered := false
var _overlay: ShaderMaterial


func _ready() -> void:
	# Only the raycast needs to find us: we sit on the Interactable layer and detect nothing.
	collision_layer = 1 << (INTERACTABLE_LAYER - 1)
	collision_mask = 0
	monitoring = false
	monitorable = true


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled and is_hovered:
		on_stop_hover()


## Text for the HUD prompt. Override to make it change (e.g. "open" / "close").
func get_prompt() -> String:
	return prompt_text


## 0..1 to show a progress bar under the prompt, or -1 for no bar.
func get_progress() -> float:
	return -1.0


## Called once when the crosshair lands on this object.
func on_hover() -> void:
	is_hovered = true
	_set_highlight(true)
	hovered.emit()


## Called once when the crosshair leaves this object (or it gets disabled).
func on_stop_hover() -> void:
	is_hovered = false
	_set_highlight(false)
	unhovered.emit()


## Called when the "interact" action is pressed while hovering.
func on_interact() -> void:
	interacted.emit()


## Called every physics frame while "interact" is held down on this object.
func on_interact_held(_delta: float) -> void:
	pass


## Called when "interact" is released while hovering.
func on_interact_released() -> void:
	pass


func _set_highlight(on: bool) -> void:
	if highlight_strength <= 0.0:
		return
	if _overlay == null:
		_overlay = ShaderMaterial.new()
		_overlay.shader = HIGHLIGHT_SHADER
	_overlay.set_shader_parameter("highlight_color", highlight_color)
	_overlay.set_shader_parameter("strength", highlight_strength)
	for g in find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).material_overlay = _overlay if on else null
