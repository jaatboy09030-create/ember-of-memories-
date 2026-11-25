shader_type spatial;
// Blurs whatever is behind it: used to hide faces in memories.
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_lod = 4.0;

void fragment() {
	// soft edge: stronger blur in the middle, fades out at the rim
	float rim = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	ALBEDO = textureLod(screen_tex, SCREEN_UV, blur_lod).rgb;
	ALPHA = smoothstep(0.05, 0.45, rim);
}
