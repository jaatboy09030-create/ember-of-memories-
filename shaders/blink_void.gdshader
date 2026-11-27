shader_type spatial;
// BLINK DEMO — the "memory island in a black void" look (after Before Your Eyes).
// A full-screen quad in front of the camera. For every pixel it rebuilds the WORLD position
// from the depth buffer, so the islands are locked to the room, not the screen: turn the
// camera and the void cuts across walls and furniture with real parallax.
// Outside every island the pixel is painted pure black; the border is a ragged, boiling
// ink edge with loose stipple droplets.
// Driven by scripts/prototypes/blink_demo.gd (islands, fade).
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
// Islands: xyz = world centre, w = radius (m, <= 0 = off). island_shape: xyz = 1/axis scale, w = blend.
uniform vec4 islands[8];
uniform vec4 island_shape[8];
uniform int island_count = 0;
uniform float edge_amp = 0.35;      // how far the ink teeth bite in/out (m)
uniform float edge_freq = 2.2;      // brush frequency (per m)
uniform float droplet_band = 0.35;  // width of the loose droplet zone outside the edge (m)
uniform float droplet_density = 0.62; // lower = more droplets
uniform float boil_fps = 6.0;       // stepped, hand-drawn edge wobble
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

float fbm(vec3 p) {
	float a = 0.5, s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * vnoise(p);
		p = p * 2.03 + vec3(11.7, 3.1, 7.3);
		a *= 0.5;
	}
	return s;
}

float smin(float a, float b, float k) {
	if (k <= 0.001) return min(a, b);
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h * (1.0 - h);
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
	vec3 jitter = vec3(sin(boil * 12.99), cos(boil * 78.23), sin(boil * 37.71)) * 0.06;
	float n = fbm(wp * edge_freq + jitter);
	float warped = sdf - (n - 0.5) * 2.0 * edge_amp;

	float aa = max(fwidth(warped), 0.01);
	float inside = 1.0 - smoothstep(-aa, aa, warped);

	// loose ink droplets just outside the edge
	if (warped > 0.0 && warped < droplet_band) {
		float t = 1.0 - warped / droplet_band;
		float dots = vnoise(wp * 14.0 + jitter * 3.0);
		float th = mix(0.99, droplet_density, t * t);
		inside = max(inside, smoothstep(th - 0.02, th + 0.02, dots));
	}

	ALBEDO = void_color;
	ALPHA = (1.0 - inside) * void_fade;
}
