shader_type spatial;
// BURNING LEAF: a dry leaf (assets/vfx/burning_leaf.glb, modelled in Blender) tumbling down as a
// particle (motion: leaf_fall.gdshader). Soon after it appears it starts burning in from the edge: a glowing rim eats
// inward, leaving charred black behind it, until nothing is left.
// Uses the particle's age (INSTANCE_CUSTOM.y) and a per-particle seed (INSTANCE_CUSTOM.x).
render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
uniform vec3 leaf_color : source_color = vec3(0.55, 0.24, 0.07);
uniform vec3 fire_color : source_color = vec3(1.0, 0.42, 0.08);
uniform float fire_energy = 5.0;
uniform float burn_start = 0.08;   // fraction of its life before it catches (match leaf_fall.gdshader)

varying float v_age;
varying float v_seed;

mat3 rot(vec3 axis, float a) {
	axis = normalize(axis);
	float s = sin(a);
	float c = cos(a);
	float oc = 1.0 - c;
	return mat3(vec3(oc * axis.x * axis.x + c, oc * axis.x * axis.y + axis.z * s, oc * axis.z * axis.x - axis.y * s),
		vec3(oc * axis.x * axis.y - axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z + axis.x * s),
		vec3(oc * axis.z * axis.x + axis.y * s, oc * axis.y * axis.z - axis.x * s, oc * axis.z * axis.z + c));
}

void vertex() {
	v_age = INSTANCE_CUSTOM.y;
	v_seed = fract(INSTANCE_CUSTOM.x * 7.31 + 0.27);
	// a gentle curl that breathes as the leaf rocks (the fall itself is shaders/leaf_fall.gdshader)
	float curl = 0.18 + 0.06 * sin(TIME * 3.0 + v_seed * 20.0);
	VERTEX.y += (VERTEX.x * VERTEX.x) * curl;
}

void fragment() {
	float burn = smoothstep(burn_start, 0.97, v_age);
	vec2 p = UV - vec2(0.5, 0.55);
	float edge = clamp(length(p * vec2(2.5, 2.1)), 0.0, 1.0);    // 0 middle .. 1 rim
	float n = texture(noise_tex, UV * 0.9 + vec2(v_seed * 5.0, v_seed * 3.0)).r;
	float solid = (1.0 - edge) * 0.85 + (n - 0.5) * 0.3 + 0.15;  // the middle survives longest
	float front = solid - (1.08 - burn * 1.15);                  // < 0 = burnt away
	if (burn > 0.0 && front < 0.0) {
		discard;
	}
	float glow = (burn > 0.0) ? 1.0 - smoothstep(0.0, 0.06, front) : 0.0;
	float char_ = (burn > 0.0) ? 1.0 - smoothstep(0.03, 0.2, front) : 0.0;
	// midrib and side veins, a little darker than the leaf
	float mid = 1.0 - smoothstep(0.0, 0.012, abs(UV.x - 0.5));
	float side = 1.0 - smoothstep(0.0, 0.05, abs(fract((UV.y - abs(UV.x - 0.5) * 0.9) * 7.0) - 0.5) * 0.5);
	float vein = max(mid, side * 0.5 * (1.0 - edge));
	vec3 base = leaf_color * (0.75 + 0.5 * n) * (1.0 - vein * 0.35);
	ALBEDO = mix(base, vec3(0.02, 0.015, 0.01), char_);
	ROUGHNESS = 0.9;
	float flick = 0.8 + 0.4 * sin(TIME * 17.0 + v_seed * 30.0);
	// the rim of fire, plus a softer heat glow running ahead of it through the leaf
	float heat = (burn > 0.0) ? (1.0 - smoothstep(0.0, 0.35, front)) * (1.0 - char_ * 0.7) : 0.0;
	// the whole leaf smoulders: a warm ember glow under the char, so it reads as burning even against the sky
	float smoulder = (burn > 0.0) ? (0.35 + 0.65 * (1.0 - char_)) * (0.6 + 0.4 * n) : 0.0;
	EMISSION = fire_color * (glow * fire_energy + heat * 1.6 + smoulder * 0.9) * flick;
}
