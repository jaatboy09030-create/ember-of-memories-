shader_type canvas_item;
// Film look: vignette, grain, slight chromatic fringe. Values are animated by main.gd.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float vignette = 0.32;
uniform float grain = 0.03;
uniform float aberration = 0.0012;
uniform float warmth = 0.0; // -1 cold .. 1 warm tint
// Face mosaics: xy = centre (px), z = half size (px), w = 1 active
uniform vec4 faces[4];
uniform int face_count = 0;
uniform float world_sat = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 px = uv * res;
	for (int i = 0; i < 4; i++) {
		if (i >= face_count) break;
		vec4 f = faces[i];
		if (f.w > 0.5 && abs(px.x - f.x) < f.z && abs(px.y - f.y) < f.z * 1.15) {
			float cell = max(f.z / 3.5, 4.0);
			vec2 q = (floor((px - f.xy) / cell) + 0.5) * cell + f.xy;
			uv = q / res;
		}
	}
	vec2 d = SCREEN_UV - 0.5;
	float r = texture(screen_tex, uv + d * aberration * 2.0).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv - d * aberration * 2.0).b;
	vec3 c = vec3(r, g, b);
	// frozen memory: grey, except bright light sources keep their warmth
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	float keep = max(world_sat, smoothstep(0.55, 1.1, lum));
	c = mix(vec3(lum), c, clamp(keep, 0.0, 1.0));
	float v = smoothstep(0.9, 0.25, length(d * vec2(1.0, 0.8)));
	c *= mix(1.0 - vignette, 1.0, v);
	c *= mix(vec3(1.0), warmth > 0.0 ? vec3(1.06, 1.0, 0.9) : vec3(0.92, 0.97, 1.06), abs(warmth));
	float n = fract(sin(dot(uv * (TIME + 1.0) * 61.0, vec2(12.9898, 78.233))) * 43758.5453);
	c += (n - 0.5) * grain;
	COLOR = vec4(c, 1.0);
}
