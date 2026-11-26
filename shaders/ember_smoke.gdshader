shader_type spatial;
// Smoke wisps curling off the ember: thin, translucent, warm-lit near the ember and cooling to
// grey as they rise. Ridged noise gives the silky ribbon look rather than round puffs.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
uniform float density = 0.55;

varying float v_seed;
varying float v_age;

void vertex() {
	mat4 w = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	float a = INSTANCE_CUSTOM.x;
	w = w * mat4(vec4(cos(a), -sin(a), 0.0, 0.0), vec4(sin(a), cos(a), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * w;
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	v_seed = fract(INSTANCE_CUSTOM.x * 0.159 + 0.61);
	v_age = INSTANCE_CUSTOM.y;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	vec2 q = UV * 0.45 + vec2(v_seed * 5.0, v_seed * 9.0 - v_age * 0.35);
	// warp, then ridge: thin bright filaments like the reference smoke
	vec2 warp = vec2(texture(noise_tex, q * 1.7).r, texture(noise_tex, q * 1.7 + 0.5).r) - 0.5;
	float n = texture(noise_tex, q + warp * (0.5 + v_age * 0.8)).r;
	float ridge = 1.0 - abs(n * 2.0 - 1.0);
	ridge = pow(ridge, 3.0);
	float mask = smoothstep(1.0, 0.2, r) * ridge;
	ALBEDO = COLOR.rgb;
	ALPHA = clamp(COLOR.a * mask * density, 0.0, 1.0);
}
