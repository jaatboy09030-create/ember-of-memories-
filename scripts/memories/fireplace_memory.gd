extends Memory
## MEMORY 6: RELIGHT THE FIRE (parent's room) - the ending.
## The ember goes into the cold hearth and the fire catches. The whole house turns warm:
## full colour, warm light in every room, the full melody. A slow crane shot pulls back,
## then the title card.
##
## How to change it: the camera shot points below; ending_music; end_delay = seconds of
## the wide shot before the fade to the title.

@export var ending_music := "theme_full"
@export var hearth_camera_position := Vector3(-5.5, 0.55, -4.85)
@export var hearth_camera_look := Vector3(-6.6, 0.35, -5.75)
@export var crane_camera_position := Vector3(-3.0, 2.3, -4.9)
@export var crane_camera_look := Vector3(-6.3, 0.9, -7.2)
@export var warm_ambient_color := Color(0.9, 0.65, 0.45)
@export var end_delay := 10.5

@onready var fireplace: Fireplace = $Fireplace


func _ready() -> void:
	fireplace.chosen.connect(_play_ending)


func begin() -> void:
	fireplace.enabled = true


func _play_ending() -> void:
	var player: PlayerBody = game.player
	var cam: PlayerCamera = player.cam
	player.can_move = false
	cam.cinematic = true
	game.ember.wait_at(fireplace.get_fire_position())
	game.set_cinematic(true)
	# 1. Low on the hearth: the ember goes in, the fire catches
	cam.global_position = hearth_camera_position
	cam.look_target = hearth_camera_look
	cam.fov = 40.0
	cam.focus(1.3)
	fireplace.ignite()
	player.add_shake(0.25, 1.2)
	Sound.play_music(ending_music, -6.0, 4.0)
	var env: Environment = game.world_environment.environment
	var tw := create_tween().set_parallel(true)
	tw.tween_property(game.screen_effects, "world_saturation", 1.0, 5.0)
	tw.tween_property(env, "ambient_light_color", warm_ambient_color, 5.0)
	tw.tween_property(env, "ambient_light_energy", 0.3, 5.0)
	game.screen_effects.tween_shader("warmth", 0.8, 6.0)
	for room in game.rooms.values():
		room.warm_up(1.8)
	# 2. Slow crane back and up: the whole room glowing again
	var crane := create_tween()
	crane.tween_interval(3.0)
	crane.tween_property(cam, "global_position", crane_camera_position, 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	crane.parallel().tween_property(cam, "look_target", crane_camera_look, 7.0)
	crane.parallel().tween_property(cam, "fov", 55.0, 7.0)
	crane.parallel().tween_callback(func(): cam.focus(5.0)).set_delay(2.0)
	# 3. Fade to the title
	var end := create_tween()
	end.tween_interval(end_delay)
	end.tween_property(game.hud.screen_fade, "color:a", 1.0, 3.0)
	end.tween_callback(func():
		game.hud.show_end_title()
		finish())


func debug_complete() -> void:
	fireplace.on_interact()
