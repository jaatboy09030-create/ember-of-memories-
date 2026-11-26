extends Node
## PLAYER ANIMATOR: plays idle / walk on the character model depending on movement.
## Mixamo exports one animation per file, so the walk clip is borrowed from walk_animation
## and added next to the idle clip that came with the model.
##
## How to change it: assign different Mixamo files to walk_animation, or a different
## character model (CharacterModel under BodyPivot). blend_time = crossfade seconds.

## Mixamo FBX whose animation is used for walking.
@export var walk_animation: PackedScene
@export var blend_time := 0.25

@onready var player: PlayerBody = get_parent()

var _anim: AnimationPlayer


func _ready() -> void:
	var model := player.get_node_or_null("BodyPivot/CharacterModel")
	if not model:
		return
	ModelUtils.fix_cull(model)
	_anim = ModelUtils.find_animation_player(model)
	if not _anim:
		return
	var lib := AnimationLibrary.new()
	var idle := _first_clip(_anim)
	if idle:
		lib.add_animation("idle", _looped(idle))
	if walk_animation:
		var walk_scene := walk_animation.instantiate()
		var walk_ap := ModelUtils.find_animation_player(walk_scene)
		var walk := _first_clip(walk_ap) if walk_ap else null
		if walk:
			lib.add_animation("walk", _looped(walk))
		walk_scene.free()
	_anim.add_animation_library("player", lib)
	if lib.has_animation("idle"):
		_anim.play("player/idle")


func _physics_process(_delta: float) -> void:
	if not _anim:
		return
	var want := "player/walk" if player.is_moving() else "player/idle"
	if _anim.current_animation != want and _anim.has_animation(want):
		_anim.play(want, blend_time)


func _first_clip(ap: AnimationPlayer) -> Animation:
	for lib_name in ap.get_animation_library_list():
		var lib := ap.get_animation_library(lib_name)
		for a in lib.get_animation_list():
			if a != "RESET":
				return lib.get_animation(a)
	return null


func _looped(a: Animation) -> Animation:
	var copy := a.duplicate() as Animation
	copy.loop_mode = Animation.LOOP_LINEAR
	return copy
