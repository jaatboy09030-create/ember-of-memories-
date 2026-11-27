class_name TornDrawingPuzzle
extends Interactable
## TORN DRAWING PUZZLE at the child's desk (memory 2).
## The desk becomes usable once all scraps are found. Using it calls `interacted`;
## DrawingMemory then calls start_puzzle(). The view moves to PuzzleCamera above the desk
## and the player turns the four pieces until the drawing is whole.
##   Mouse:   point at a piece, press "interact" (left click) to turn it.
##   Gamepad: "select_next" / "select_previous" (d-pad) to choose, "interact" (A) to turn.
##
## How to change it: each PuzzlePiece's start_quarter_turns sets how scrambled it is;
## move PuzzleCamera to change the view; camera_move_time = how long the camera glides.

signal solved

## Pieces live on physics layer 4 ("PuzzlePiece") so only the puzzle's mouse ray finds them.
const PUZZLE_PIECE_LAYER_BIT := 1 << 3

@export var camera_move_time := 1.0
## Pause after the last turn before the puzzle closes (seconds).
@export var solved_pause := 1.7

@onready var puzzle_camera: Camera3D = $PuzzleCamera
@onready var pieces_root: Node3D = $Pieces

var is_running := false
var _pieces: Array[PuzzlePiece] = []
var _selected := -1
var _return_camera: Camera3D
var _camera_rest: Transform3D


func _ready() -> void:
	super._ready()
	for c in pieces_root.get_children():
		if c is PuzzlePiece:
			_pieces.append(c)
	pieces_root.visible = false
	_camera_rest = puzzle_camera.transform
	# the glide starts at the player's eyes: never render the inside of their head
	puzzle_camera.cull_mask = PlayerBody.CAMERA_MASK_WITHOUT_BODY


## Glide from the player's camera to the puzzle view and start taking input.
func start_puzzle(from_camera: Camera3D) -> void:
	is_running = true
	enabled = false
	_return_camera = from_camera
	pieces_root.visible = true
	puzzle_camera.global_transform = from_camera.global_transform
	puzzle_camera.make_current()
	var tw := create_tween()
	tw.tween_property(puzzle_camera, "transform", _camera_rest, camera_move_time).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): Input.mouse_mode = Input.MOUSE_MODE_VISIBLE)
	_select(0)


func _unhandled_input(event: InputEvent) -> void:
	if not is_running:
		return
	if event is InputEventMouseMotion:
		_select(_piece_under_mouse(event.position))
	elif event.is_action_pressed("select_next"):
		_select((_selected + 1) % _pieces.size())
	elif event.is_action_pressed("select_previous"):
		_select((_selected - 1 + _pieces.size()) % _pieces.size())
	elif event.is_action_pressed("interact") and _selected >= 0:
		_pieces[_selected].turn_quarter()
		_check_solved()


func _piece_under_mouse(mouse_pos: Vector2) -> int:
	var from := puzzle_camera.project_ray_origin(mouse_pos)
	var query := PhysicsRayQueryParameters3D.create(from, from + puzzle_camera.project_ray_normal(mouse_pos) * 3.0)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = PUZZLE_PIECE_LAYER_BIT
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return _pieces.find(hit.get("collider")) if not hit.is_empty() else -1


func _select(index: int) -> void:
	if _selected >= 0:
		_pieces[_selected].set_selected(false)
	_selected = index
	if _selected >= 0:
		_pieces[_selected].set_selected(true)


func _check_solved() -> void:
	for p in _pieces:
		if not p.is_correct():
			return
	finish_puzzle()


## Ends the puzzle (also used by the dev tests after snapping the pieces).
func finish_puzzle() -> void:
	is_running = false
	_select(-1)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(func(): Sound.play("tape", -2.0))
	tw.tween_interval(solved_pause - 0.5)
	tw.tween_property(puzzle_camera, "global_transform", _return_camera.global_transform, camera_move_time).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		_return_camera.make_current()
		pieces_root.visible = false
		solved.emit())


func get_pieces() -> Array[PuzzlePiece]:
	return _pieces
