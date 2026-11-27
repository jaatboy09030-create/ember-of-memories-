shader_type spatial;
// BLINK DEMO â€” the "memory island in a black void" look (after Before Your Eyes).
// A full-screen quad in front of the camera. For every pixel it rebuilds the WORLD position
// from the depth buffer, so the islands are locked to the room, not the screen: turn the
// camera and the void cuts across walls and furniture with real parallax.
// Outside every island the pixel is painted pure black. The border is a clean ink splat:
// the ragged teeth and the round droplets are drawn in VIEW-DIRECTION space (like ink on a
// sheet in front of you), so the edge stays one continuous painted line instead of breaking
// into speckle where it crosses furniture at different depths.
// Driven by scripts/prototypes/blink_demo.gd (islands, fade).
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
// Islands: xyz = world centre, w = radius (m, <= 0 = off). island_shape: xyz = 1/axis scale, w = blend.
uniform vec4 islands[8];
uniform vec4 island_shape[8];
uniform int island_count = 0;
uniform float edge_amp = 0.35;      // how far the ink teeth bite in/out (m)
uniform float edge_freq = 2.2;      // (old world-space brush frequency, unused)
uniform float splat_freq = 4.5;     // size of the ink lobes (higher = smaller, more teeth)
uniform float teeth = 0.25;         // share of fine spiky teeth on top of the big lobes
uniform float droplet_band = 0.35;  // width of the droplet zone outside the edge (m)
uniform float droplet_density = 0.62; // lower = more droplets
uniform float droplet_scale = 60.0; // droplet grid (higher = smaller droplets)
uniform float boil_fps = 2.0;       // stepped, hand-drawn edge wobble (0 = still)
uniform float void_fade = 1.0;      // 1 = void shown, 0 = no void (whole scene visible)
uniform vec3 void_color : source_color = vec3(0.0);

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
	               mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
	           mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
	               mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float smin(float a, float b, float k) {
	if (k <= 0.001) return min(a, b);
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h * (1.0 - h);
}

// round ink droplets on a jittered grid: 1 inside a droplet, 0 outside
float droplets(vec3 d, float chance, float boil) {
	vec3 p = d * droplet_scale;
	vec3 i = floor(p);
	float best = 0.0;
	for (int x = -1; x <= 1; x++)
	for (int y = -1; y <= 1; y++)
	for (int z = -1; z <= 1; z++) {
		vec3 c = i + vec3(float(x), float(y), float(z));
		float h = hash(c + boil * 0.01);
		if (h > chance) continue;
		vec3 centre = c + vec3(hash(c + 3.1), hash(c + 7.7), hash(c + 1.9));
		float r = mix(0.12, 0.42, hash(c + 5.3));
		float dist = length(p - centre);
		best = max(best, 1.0 - smoothstep(r - 0.06, r + 0.06, dist));
	}
	return best;
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0); // full screen, always in front
}

void fragment() {
	float depth = texture(depth_tex, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, max(depth, 0.0));
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	if (depth <= 0.00001) {
		// sky: no depth, so pretend it's a painted dome 40 m away
		vec4 far_v = INV_PROJECTION_MATRIX * vec4(ndc.xy, 0.5, 1.0);
		view.xyz = normalize(far_v.xyz / far_v.w) * 40.0;
	}
	vec3 wp = (INV_VIEW_MATRIX * vec4(view.xyz, 1.0)).xyz;
	// the "sheet" the ink is painted on: world direction from the eye (stable when the view turns)
	vec3 dir = normalize(wp - CAMERA_POSITION_WORLD);

	float sdf = 1e5;
	for (int i = 0; i < 8; i++) {
		if (i >= island_count) break;
		vec4 c = islands[i];
		if (c.w <= 0.0001) continue;
		vec4 s = island_shape[i];
		float d = length((wp - c.xyz) * max(s.xyz, vec3(0.05))) - c.w;
		sdf = smin(sdf, d, s.w);
	}

	float boil = boil_fps > 0.0 ? floor(TIME * boil_fps) : 0.0;
	vec3 jitter = vec3(sin(boil * 12.99), cos(boil * 78.23), sin(boil * 37.71)) * 0.015;
	vec3 q = dir * splat_freq + jitter;
	// big soft lobes + a few sharp teeth (ridged noise) = a brush splat, not static
	float lobes = vnoise(q) * 0.75 + vnoise(q * 2.3 + 4.0) * 0.25;
	float ridge = pow(1.0 - abs(vnoise(q * 4.0 + 9.0) * 2.0 - 1.0), 6.0);  // thin spikes only
	float n = lobes + ridge * teeth;
	// the warp is scaled by distance from the eye so the edge bites the same on screen near or far
	float dist_eye = length(view.xyz);
	float warped = sdf - (n - 0.5) * 2.0 * edge_amp * clamp(dist_eye * 0.25, 0.4, 1.6);

	float aa = max(fwidth(warped), 0.004);
	float inside = 1.0 - smoothstep(-aa, aa, warped);

	// a few round droplets thrown just outside the edge, fewer the further out
	if (warped > 0.0 && warped < droplet_band) {
		float t = 1.0 - warped / droplet_band;
		float chance = (1.0 - droplet_density) * t * t * 0.9;
		inside = max(inside, droplets(dir, chance, boil));
	}

	ALBEDO = void_color;
	ALPHA = (1.0 - inside) * void_fade;
}
