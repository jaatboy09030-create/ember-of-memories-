shader_type particles;
// LEAF FALL: how a dry leaf really comes down. It doesn't drop or tumble. It glides side to side
// like a pendulum, rocking as it goes: flat and quick through the middle of each swing, tipped
// up and almost stopping at each end (where it even rises a little), then sliding back the other way.
// The whole time it slowly turns, and a light wind drifts it sideways.
//
// While it burns (from burn_start of its life) it throws off flame tongues and sparks through
// the sub-emitter (see title_sequence.gd: "LeafFlames").
//
// CUSTOM.x = seed, CUSTOM.y = age 0..1 (read by burning_leaf.gdshader), CUSTOM.z = scale,
// CUSTOM.w = swing phase offset.

uniform vec3 box_extents = vec3(6.5, 0.6, 4.5);
uniform float fall_speed = 0.22;     // m/s, average sink rate
uniform float swing = 0.55;          // m, half the side-to-side glide
uniform float swing_period = 3.4;    // s, one full there-and-back
uniform float lift = 0.16;           // m, how much it rises at the end of each swing
uniform float rock = 1.0;           // rad, how far it tips at the end of a swing
uniform vec3 wind = vec3(0.10, 0.0, 0.02);
uniform float scale_min = 0.32;
uniform float scale_max = 0.46;
uniform float burn_start = 0.08;
uniform float flame_rate = 16.0;     // flame tongues per second while burning

uint hash_u(uint x) {
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = (x >> uint(16)) ^ x;
	return x;
}

float rnd(inout uint s) {
	s = hash_u(s + uint(0x9E3779B9));
	return float(s & uint(0xFFFFFF)) / 16777215.0;
}

mat3 axis_rot(vec3 axis, float a) {
	axis = normalize(axis);
	float s = sin(a);
	float c = cos(a);
	float oc = 1.0 - c;
	return mat3(vec3(oc * axis.x * axis.x + c, oc * axis.x * axis.y + axis.z * s, oc * axis.z * axis.x - axis.y * s),
		vec3(oc * axis.x * axis.y - axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z + axis.x * s),
		vec3(oc * axis.z * axis.x + axis.y * s, oc * axis.y * axis.z - axis.x * s, oc * axis.z * axis.z + c));
}

void start() {
	uint s = hash_u(NUMBER + uint(1) + RANDOM_SEED * uint(7919));
	vec3 p = (vec3(rnd(s), rnd(s), rnd(s)) * 2.0 - 1.0) * box_extents;
	CUSTOM = vec4(rnd(s), 0.0, mix(scale_min, scale_max, rnd(s)), rnd(s) * 6.2832);
	TRANSFORM = mat4(vec4(1, 0, 0, 0), vec4(0, 1, 0, 0), vec4(0, 0, 1, 0), vec4((EMISSION_TRANSFORM * vec4(p, 1.0)).xyz, 1.0));
	VELOCITY = vec3(0.0);
}

void process() {
	CUSTOM.y += DELTA / LIFETIME;
	if (CUSTOM.y >= 1.0) {
		ACTIVE = false;
	}
	float seed = CUSTOM.x;
	float t = CUSTOM.y * LIFETIME;
	float w = 6.2832 / (swing_period * (0.8 + 0.45 * seed));
	float ph = CUSTOM.w + t * w;
	// each leaf swings along its own direction
	float dir_a = seed * 37.0;
	vec3 dir = vec3(cos(dir_a), 0.0, sin(dir_a));
	vec3 side = vec3(-dir.z, 0.0, dir.x);
	// pendulum glide: x = swing*sin(ph), and it is highest at the ends: y = lift*sin(ph)^2
	float sway_v = swing * w * cos(ph);
	float rise_v = lift * w * sin(2.0 * ph);
	VELOCITY = dir * sway_v + vec3(0.0, -fall_speed + rise_v, 0.0) + wind * (0.7 + 0.6 * seed);

	// orientation: rock with the swing (tipped most at the ends), a small flutter, a slow spin
	float tip = rock * sin(ph) + 0.12 * sin(t * 7.3 + seed * 20.0);
	float yaw = seed * 6.2832 + t * (seed - 0.5) * 0.7;
	mat3 basis = axis_rot(side, tip) * axis_rot(dir, 0.55 * sin(ph * 0.5 + seed * 4.0)) * axis_rot(vec3(0.0, 1.0, 0.0), yaw)
		* axis_rot(vec3(1.0, 0.0, 0.0), 0.15 * sin(t * 2.1 + seed * 9.0));
	float sc = CUSTOM.z;
	TRANSFORM[0].xyz = basis[0] * sc;
	TRANSFORM[1].xyz = basis[1] * sc;
	TRANSFORM[2].xyz = basis[2] * sc;

	// burning: flame tongues lick off the burning rim
	float burn = smoothstep(burn_start, 0.97, CUSTOM.y);
	if (burn > 0.0 && CUSTOM.y < 0.96 && ACTIVE) {
		uint s = hash_u(INDEX * uint(131) + uint(t * 1000.0) + RANDOM_SEED);
		if (rnd(s) < DELTA * flame_rate * (0.6 + burn)) {
			// a point on the leaf's outline, shrinking inward as it burns
			float a = rnd(s) * 6.2832;
			float r = sc * 0.55 * (1.0 - burn * 0.75);
			vec3 local = vec3(cos(a) * r, 0.0, sin(a) * r * 1.2);
			vec3 pos = TRANSFORM[3].xyz + basis * local;
			mat4 xf = mat4(vec4(1, 0, 0, 0), vec4(0, 1, 0, 0), vec4(0, 0, 1, 0), vec4(pos, 1.0));
			vec3 v = VELOCITY * 0.6 + vec3(0.0, 0.25 + rnd(s) * 0.2, 0.0);
			emit_subparticle(xf, v, vec4(1.0), vec4(0.0), FLAG_EMIT_POSITION | FLAG_EMIT_VELOCITY);
		}
	}
}
