shader_type spatial;
// Hover highlight drawn on top of an interactable (set as material_overlay).
// A soft glowing rim that breathes slowly. Colour/strength come from interactable.gd.
render_mode unshaded, blend_add, depth_draw_never, cull_back;

uniform vec4 highlight_color : source_color = vec4(1.0, 0.7, 0.35, 1.0);
uniform float strength = 0.6;

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	float pulse = 0.75 + 0.25 * sin(TIME * 3.0);
	ALBEDO = highlight_color.rgb * (rim * 0.9 + 0.08) * strength * pulse;
}
