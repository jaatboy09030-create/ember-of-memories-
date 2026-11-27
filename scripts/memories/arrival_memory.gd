extends Memory
## MEMORY 0: ARRIVAL. Outside at night in the snow.
## The ember waits on the garden gate. Walking up to it (GateTrigger) makes the ember lead
## the way to the porch and arms the gate so it shuts behind you. Reaching the porch
## (PorchTrigger) finishes the memory: the director opens the front door and drains the colour.
##
## How to change it: move/resize GateTrigger and PorchTrigger; edit home_line.

@export var home_line := "...home."
@export var home_voice := "v_home"
## Where the camera glances when the front door opens.
@export var glance_point := Vector3(0, 1.2, -3.0)

@onready var gate: GardenGate = $GardenGate
@onready var gate_trigger: Area3D = $GateTrigger
@onready var porch_trigger: Area3D = $PorchTrigger
@onready var porch_point: Marker3D = $PorchPoint

var _reached_gate := false
var _active := false


func _ready() -> void:
	gate_trigger.body_entered.connect(_on_gate_trigger_body_entered)
	porch_trigger.body_entered.connect(_on_porch_trigger_body_entered)


func begin() -> void:
	_active = true
	# the player may already be standing in a trigger when the memory starts
	for b in gate_trigger.get_overlapping_bodies():
		_on_gate_trigger_body_entered(b)


func _on_gate_trigger_body_entered(body: Node3D) -> void:
	if not _active or _reached_gate or not body is PlayerBody:
		return
	_reached_gate = true
	game.ember.lead_to(porch_point)
	gate.arm()
	Sound.play("ember_chime", -4.0)
	Sound.play_at("ember_whoosh", game.ember.global_position, -6.0)
	game.hud.say(home_line, 2.5, home_voice)


func _on_porch_trigger_body_entered(body: Node3D) -> void:
	if not _active or not _reached_gate or not body is PlayerBody:
		return
	_active = false
	game.player.glance(glance_point, 0.25)
	# as you step onto the porch the windows go out one by one: nobody is home
	var house := get_tree().get_first_node_in_group("house_exterior") as HouseExterior
	if house:
		create_tween().tween_property(house, "all_windows_warmth", 0.0, 2.5).set_trans(Tween.TRANS_SINE)
	finish()


## Dev tests: complete this memory without walking.
func debug_complete() -> void:
	_on_gate_trigger_body_entered(game.player)
	_on_porch_trigger_body_entered(game.player)
