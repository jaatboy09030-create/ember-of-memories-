shader_type canvas_item;
// BLINK DEMO — eyelids closing over the view (after Before Your Eyes).
// closure 0 = eyes open .. 1 = shut. The lids come from top and bottom with an almond
// curve (meeting in the middle first at the centre), a soft lash feather, and the open
// slit darkens and loses focus a little as they close.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float closure : hint_range(0.0, 1.0) = 0.0;
uniform float curve = 0.55;     // almond bend of the lids
uniform float feather = 0.035;  // softness of the lash line

void fragment() {
	vec2 uv = SCREEN_UV;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float x = (uv.x - 0.5) * aspect;
	// distance from the eye's centre line; the lids are curved, so the corners close first
	float e = abs(uv.y - 0.5) + curve * x * x * 0.35;
	float open_h = (1.0 - closure) * (0.5 + curve * 0.35 * 0.25 * aspect * aspect) + 0.0001;
	float lid = smoothstep(open_h - feather, open_h + feather * 0.3, e);
	// the slit: darker and slightly defocused as the lids come down
	float blur = closure * 3.0;
	vec3 c = textureLod(screen_tex, uv, blur).rgb;
	c *= mix(1.0, 0.35, smoothstep(0.2, 0.9, closure));
	float shut = step(0.97, closure);
	COLOR = vec4(mix(c, vec3(0.0), max(lid, shut)), 1.0);
}
