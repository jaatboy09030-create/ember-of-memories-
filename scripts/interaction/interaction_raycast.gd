extends RayCast3D
## INTERACTION RAYCAST: sits on the player camera and finds what the player is looking at.
## It knows nothing about specific objects: it only talks to the Interactable base script
## (on_hover / on_stop_hover / on_interact / on_interact_held / on_interact_released).
##
## How to change it:
##   - interaction_distance: how far away things can be used (metres).
##   - Walls block the ray (it also hits the World layer), so you can't use things through walls.

## Emitted whenever the looked-at interactable changes (null = nothing). The HUD listens to this.
signal target_changed(target: Interactable)

## How far the player can reach, in metres.
@export var interaction_distance := 2.2:
	set(v):
		interaction_distance = v
		target_position = Vector3(0, 0, -v)

var current_target: Interactable


func _ready() -> void:
	target_position = Vector3(0, 0, -interaction_distance)
	collide_with_areas = true
	collide_with_bodies = true
	# World (layer 1) blocks the ray, Interactable (layer 3) is what we look for.
	collision_mask = 1 | (1 << 2)
	var body := owner as CollisionObject3D
	if body:
		add_exception(body)


func _physics_process(delta: float) -> void:
	var hit: Interactable = null
	if enabled:
		hit = _interactable_from(get_collider())
		if hit and not hit.enabled:
			hit = null
	_set_target(hit)
	if not current_target:
		return
	if Input.is_action_just_pressed("interact"):
		current_target.on_interact()
	# the object may have disabled itself in on_interact()
	if current_target and Input.is_action_pressed("interact"):
		current_target.on_interact_held(delta)
	if current_target and Input.is_action_just_released("interact"):
		current_target.on_interact_released()


## The ray may hit the Interactable area itself or a body inside it (e.g. a door leaf):
## walk up a few parents to find the Interactable that owns it.
func _interactable_from(collider: Object) -> Interactable:
	var n := collider as Node
	for i in 4:
		if n == null:
			return null
		if n is Interactable:
			return n
		n = n.get_parent()
	return null


func _set_target(t: Interactable) -> void:
	if t == current_target:
		return
	if current_target and is_instance_valid(current_target):
		current_target.on_stop_hover()
	current_target = t
	if current_target:
		current_target.on_hover()
	target_changed.emit(current_target)
