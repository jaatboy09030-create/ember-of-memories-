shader_type canvas_item;
// BLINK DEMO — "where you look is a little clearer": a soft circle around the reticle stays
// sharp, the rest of the screen goes SLIGHTLY soft. Screen-space and radial (not a depth band).
// Driven by scripts/prototypes/blink/blink_ui.gd (cursor).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 cursor = vec2(0.5);       // 0..1 screen UV
uniform float sharp_radius = 0.22;     // fully sharp within this (fraction of screen height)
uniform float soft_radius = 0.75;      // max softness reached here
uniform float max_blur = 1.1;          // mip level at the far edge (keep low: slight)

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 d = (SCREEN_UV - cursor) * vec2(res.x / res.y, 1.0);
	float t = smoothstep(sharp_radius, soft_radius, length(d));
	COLOR = vec4(textureLod(screen_tex, SCREEN_UV, t * max_blur).rgb, 1.0);
}
