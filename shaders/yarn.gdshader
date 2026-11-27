shader_type spatial;
// Yarn: soft wool with twisted plies spiralling along the strand and a fuzzy halo at the
// edges. Expects the UVs from YarnMesh (u = along the strand, v = around it).
render_mode cull_back;

uniform vec4 yarn_color : source_color = vec4(0.72, 0.1, 0.09, 1.0);
// How many plies are twisted together.
uniform float plies = 3.0;
// How tightly they spiral (turns per strand circumference).
uniform float twist = 0.35;
// Light glow so the red reads even in the grey memory (0 = none).
uniform float warmth = 0.12;

void fragment() {
	float s = fract((UV.y + UV.x * twist) * plies);
	float ply = smoothstep(0.0, 0.3, s) * smoothstep(1.0, 0.7, s);   // dark grooves between plies
	float fibre = 0.9 + 0.1 * sin(UV.x * 90.0 + UV.y * 40.0);        // fine fibre streaks
	vec3 c = yarn_color.rgb * (0.5 + 0.5 * ply) * fibre;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);  // fuzz catching light
	ALBEDO = c + yarn_color.rgb * rim * 0.35;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
	EMISSION = yarn_color.rgb * warmth;
}
