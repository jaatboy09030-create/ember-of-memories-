shader_type spatial;
render_mode cull_disabled;
// The scarf on the coat rack, knitted back row by row: everything below `cut_y` (world height)
// is still unravelled. A faint warm edge marks the row being knitted.
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_tex = false;
uniform vec4 tint : source_color = vec4(0.78, 0.13, 0.11, 1.0);
uniform float cut_y = -100.0;

varying float wy;

void vertex() {
	wy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	if (wy < cut_y) {
		discard;
	}
	vec3 c = has_tex ? texture(albedo_tex, UV).rgb : vec3(0.7);
	float l = dot(c, vec3(0.3, 0.59, 0.11));
	ALBEDO = tint.rgb * (0.85 + l * 1.3);
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
	float e = smoothstep(0.035, 0.0, wy - cut_y);
	EMISSION = vec3(1.0, 0.42, 0.12) * e * 1.2;
}
