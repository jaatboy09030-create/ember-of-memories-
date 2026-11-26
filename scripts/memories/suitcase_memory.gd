extends Memory
## MEMORY 4: PACK THE SUITCASE (bedroom).
## Belongings the parent kept lie around the room. Picking one up lifts it in front of the
## eyes while its memory is read out; "interact" again packs it. Every packed item drains
## a little more colour. When all are packed, closing the suitcase fades to black:
## "I left that night." Then the parent's room opens.
##
## How to change it: each PackableItem's memory_line; add/remove items under PackableItems
## (the count is automatic); the lines below.

@export var pack_prompt := "pack it"
@export var leave_line := "I left that night. I never came back."
## Colour at the start of this memory (it drains to 0 as items are packed).
@export var start_saturation := 0.3

@onready var items_root: Node3D = $PackableItems
@onready var suitcase: Suitcase = $Suitcase

var _items_total := 0
var _items_left := 0
var _held: PackableItem
var _ready_to_pack := false
var _lift: Tween


func _ready() -> void:
	suitcase.closed.connect(_on_suitcase_closed)


func begin() -> void:
	for it in items_root.get_children():
		if it is PackableItem:
			_items_total += 1
			it.enabled = true
			it.chosen.connect(_inspect)
	_items_left = _items_total


## Lift the item in front of the eyes and let its memory speak.
func _inspect(item: PackableItem) -> void:
	_held = item
	_ready_to_pack = false
	game.player.can_move = false
	Sound.play("paper_pickup", -6.0, 0.1)
	var cam: Camera3D = game.player.cam
	_lift = create_tween()
	var tw := _lift
	tw.tween_property(item, "global_position", cam.global_transform * Vector3(0, -0.04, -0.5), 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		_ready_to_pack = true
		game.player.cam.focus(0.5)
		game.hud.say(item.memory_line, 3.5)
		game.hud.show_prompt(pack_prompt))
	game.screen_effects.set_vignette(0.55)


func _process(delta: float) -> void:
	if not _held:
		return
	_held.spin(delta)
	if _ready_to_pack and Input.is_action_just_pressed("interact"):
		_pack_held()


func _pack_held() -> void:
	var item := _held
	_held = null
	if _lift and _lift.is_valid():
		_lift.kill()
	game.hud.show_prompt("")
	game.player.cam.focus(-1.0)
	game.screen_effects.reset_vignette()
	game.player.can_move = true
	item.fly_into(suitcase.pack_point.global_position)
	_items_left -= 1
	game.screen_effects.fade_saturation(start_saturation * _items_left / float(_items_total), 1.5)
	if _items_left == 0:
		suitcase.enabled = true


func _on_suitcase_closed() -> void:
	game.player.can_move = false
	Sound.play_music("", 0.0, 3.0)
	var tw := game.hud.fade_to(1.0, 1.5)
	tw.tween_callback(func(): game.hud.say(leave_line, 3.5))
	tw.tween_interval(3.5)
	tw.tween_callback(func():
		finish()
		game.player.can_move = true)
	tw.tween_property(game.hud.screen_fade, "color:a", 0.0, 1.5)


func debug_complete() -> void:
	for it in items_root.get_children():
		if it is PackableItem:
			it.on_interact()
			_ready_to_pack = true
			_pack_held()
	suitcase.on_interact()
