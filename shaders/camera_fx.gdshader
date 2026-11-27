shader_type canvas_item;
// FILM / WORN-CAMERA LOOK drawn over the 3D view (ScreenEffects > FilmLook).
// Values are driven by scripts/systems/screen_effects.gd.
// Order: lens bend -> face mosaics -> colour fringe -> frozen-memory grey -> vignette
//        -> warm/cold tint -> sensor grain.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float vignette = 0.32;
uniform float grain = 0.03;
uniform float aberration = 0.0012;
uniform float warmth = 0.0; // -1 cold .. 1 warm tint
// Face mosaics: xy = centre (px), z = half size (px), w = 0 off, else 1 + clarity
// (clarity 0 = coarse blocks .. 1 = clear face, no mosaic).
// Given in the FLAT (unbent) screen pixels, as Camera3D.unproject_position returns them.
uniform vec4 faces[4];
uniform int face_count = 0;
uniform float world_sat = 1.0;
// Lens bend (Brown-Conrady radial k1, k2). 0 = flat image. The bent image is scaled so the
// corners stay filled: no black or smeared edges, at the cost of a slight zoom.
uniform float lens_k1 : hint_range(0.0, 0.5) = 0.0;
uniform float lens_k2 : hint_range(0.0, 0.5) = 0.0;
// Colour fringe that grows toward the edges of the lens.
uniform float lens_fringe : hint_range(0.0, 0.05) = 0.0;
// 0..1: extra grain in dark areas (cheap camera sensor).
uniform float shadow_noise : hint_range(0.0, 1.0) = 0.0;

// For a pixel of the bent picture, where to read in the flat render.
vec2 lens_uv(vec2 uv, float aspect) {
	vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
	float r2 = dot(p, p);
	float rc2 = 0.25 * (aspect * aspect + 1.0); // squared distance to a corner
	float s = 1.0 + lens_k1 * rc2 + lens_k2 * rc2 * rc2;
	p *= (1.0 + lens_k1 * r2 + lens_k2 * r2 * r2) / s;
	return p / vec2(aspect, 1.0) + 0.5;
}

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = lens_uv(SCREEN_UV, res.x / res.y);
	vec2 px = uv * res;
	for (int i = 0; i < 4; i++) {
		if (i >= face_count) break;
		vec4 f = faces[i];
		float clarity = f.w - 1.0;
		if (f.w > 0.5 && clarity < 0.98 && abs(px.x - f.x) < f.z && abs(px.y - f.y) < f.z * 1.15) {
			// fewer, bigger blocks when forgotten; many small ones as it comes back
			float cell = max(f.z / mix(2.0, 14.0, clarity * clarity), 2.0);
			vec2 q = (floor((px - f.xy) / cell) + 0.5) * cell + f.xy;
			uv = q / res;
		}
	}
	vec2 d = SCREEN_UV - 0.5;
	vec2 dl = uv - 0.5;
	vec2 shift = d * aberration * 2.0 + dl * lens_fringe * dot(dl, dl) * 4.0;
	float r = texture(screen_tex, clamp(uv + shift, vec2(0.0), vec2(1.0))).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, clamp(uv - shift, vec2(0.0), vec2(1.0))).b;
	vec3 c = vec3(r, g, b);
	// frozen memory: grey, except bright light sources keep their warmth
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	float keep = max(world_sat, smoothstep(0.55, 1.1, lum));
	c = mix(vec3(lum), c, clamp(keep, 0.0, 1.0));
	float v = smoothstep(0.9, 0.25, length(d * vec2(1.0, 0.8)));
	c *= mix(1.0 - vignette, 1.0, v);
	c *= mix(vec3(1.0), warmth > 0.0 ? vec3(1.06, 1.0, 0.9) : vec3(0.92, 0.97, 1.06), abs(warmth));
	// sensor grain on the sensor itself (flat screen coords), stronger in the dark
	float n = fract(sin(dot(SCREEN_UV * (TIME + 1.0) * 61.0, vec2(12.9898, 78.233))) * 43758.5453);
	float lum2 = dot(c, vec3(0.299, 0.587, 0.114));
	c += (n - 0.5) * grain * (1.0 + shadow_noise * 1.5 * (1.0 - smoothstep(0.0, 0.5, lum2)));
	COLOR = vec4(c, 1.0);
}
