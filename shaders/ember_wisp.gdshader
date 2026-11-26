shader_type spatial;
// Soft, torn-edged particle for the ember: flame tongues (additive) and smoke wisps (see
// ember_smoke.gdshader). Billboarded per particle; the edge is broken up with scrolling noise
// so no two puffs look the same.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
uniform float energy = 3.0;
uniform float wisp = 0.75;      // how torn the edge is
uniform float stretch = 1.0;    // >1 makes tongues taller than wide

varying float v_seed;
varying float v_age;

void vertex() {
	mat4 w = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	float a = INSTANCE_CUSTOM.x;
	w = w * mat4(vec4(cos(a), -sin(a), 0.0, 0.0), vec4(sin(a), cos(a), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * w;
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz) * stretch, 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	v_seed = fract(INSTANCE_CUSTOM.x * 0.159 + 0.37);
	v_age = INSTANCE_CUSTOM.y;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	vec2 q = UV * 0.6 + vec2(v_seed * 7.0, v_seed * 3.0 - v_age * 0.8);
	float n = texture(noise_tex, q).r;
	float n2 = texture(noise_tex, q * 2.3 + vec2(0.0, -v_age * 1.4)).r;
	float edge = r + (n - 0.5) * wisp + (n2 - 0.5) * wisp * 0.5;
	float mask = smoothstep(1.0, 0.15, edge);
	mask *= mask;
	ALBEDO = COLOR.rgb * energy * (0.6 + n2 * 0.8);
	ALPHA = clamp(COLOR.a * mask, 0.0, 1.0);
}
