extends Memory
## MEMORY 2: THE DRAWING (child's room).
## Three torn scraps of a crayon drawing lie on the floor. Once all are picked up, the desk
## becomes usable: the view moves above the desk and the player turns the four pieces until
## the drawing is whole. It then appears pinned on the wall.
##
## How to change it: move the DrawingPiece nodes under DrawingPieces (add/remove freely, the
## count is automatic); puzzle settings are on TornDrawingPuzzle.

@export var puzzle_hint := "Turn the pieces until it's whole again."
@export var restored_line := "\"My little artist.\""
@export var restored_voice := "v_artist"

@onready var pieces_root: Node3D = $DrawingPieces
@onready var puzzle: TornDrawingPuzzle = $TornDrawingPuzzle
@onready var drawing_on_wall: DrawingOnWall = $DrawingOnWall

var _pieces_left := 0


func _ready() -> void:
	puzzle.enabled = false
	puzzle.interacted.connect(_on_puzzle_used)
	puzzle.solved.connect(_on_puzzle_solved)


func begin() -> void:
	for p in pieces_root.get_children():
		if p is DrawingPiece:
			_pieces_left += 1
			p.reveal(true)
			p.picked_up.connect(_on_piece_picked_up)


func _on_piece_picked_up(piece: DrawingPiece) -> void:
	game.player.glance(piece.global_position, 0.4)
	_pieces_left -= 1
	if _pieces_left == 0:
		puzzle.enabled = true


func _on_puzzle_used() -> void:
	game.player.can_move = false
	game.player.cam.cinematic = true
	puzzle.start_puzzle(game.player.cam)
	get_tree().create_timer(puzzle.camera_move_time).timeout.connect(func(): game.hud.say(puzzle_hint, 3.0))


func _on_puzzle_solved() -> void:
	game.player.cam.cinematic = false
	game.player.can_move = true
	wake_figures()
	Sound.play("tape", -4.0)
	play_restore_moment(drawing_on_wall.global_position)
	drawing_on_wall.pop_in()
	game.hud.say(restored_line, 3.0, restored_voice)
	finish()


func debug_complete() -> void:
	for p in pieces_root.get_children():
		if p is DrawingPiece:
			p.on_interact()
	_on_puzzle_used()
	await get_tree().create_timer(puzzle.camera_move_time + 0.2).timeout
	for piece in puzzle.get_pieces():
		piece.snap_correct()
	puzzle.finish_puzzle()
