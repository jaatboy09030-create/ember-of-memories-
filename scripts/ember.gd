extends Node3D
## Ember companion: floats near the player and leans toward the next goal.

var player: Node3D
var target: Node3D
var light: OmniLight3D
var t := 0.0
var follow := true
var anchor := Vector3.INF  # where it waits when not following
var mat: StandardMaterial3D


func _ready() -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.08
	s.height = 0.16
	mi.mesh = s
	mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.5, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.45, 0.1)
	mat.emission_energy_multiplier = 6.0
	mi.material_override = mat
	add_child(mi)

	light = OmniLight3D.new()
	light.light_color = Color(1, 0.55, 0.2)
	light.light_energy = 2.2
	light.omni_range = 6.5
	light.omni_attenuation = 1.3
	light.light_size = 0.05
	light.shadow_enabled = true
	add_child(light)
	if anchor != Vector3.INF:
		global_position = anchor
	elif player:
		global_position = player.global_position + Vector3(0.5, 1.4, 0)


func _process(delta: float) -> void:
	t += delta
	if not player or not follow:
		if anchor != Vector3.INF:
			global_position = global_position.lerp(anchor + Vector3(0, sin(t * 2.0) * 0.08, 0), 2.0 * delta)
		return
	# The ember doesn't lead you around: it waits above where you need to go.
	var goal := global_position
	if target:
		goal = target.global_position + Vector3(0, 1.55, 0)
	elif anchor != Vector3.INF:
		goal = anchor
	goal.y += sin(t * 2.0) * 0.08
	global_position = global_position.lerp(goal, clampf(1.2 * delta, 0.0, 1.0))
	light.light_energy = 2.2 + sin(t * 7.0) * 0.15 + sin(t * 13.0) * 0.08
