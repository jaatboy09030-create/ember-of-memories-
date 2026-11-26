shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
// MegaKit foliage in winter: PBR, alpha-cut leaves, a slow wind sway, snow on upward faces.
global uniform float world_sat;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool has_tex = false;
uniform bool has_normal = false;
uniform vec4 tint : source_color = vec4(1.0);
uniform float alpha_cut = 0.5;
uniform float snow = 0.8;
uniform float sway = 0.0;      // 0 = rigid (bark, rocks), 1 = leaves
uniform float roughness_value = 0.9;
uniform vec3 snow_color : source_color = vec3(0.72, 0.76, 0.84);  // never pure white: lets the lights colour it (research/10)

varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (sway > 0.0) {
		// height-weighted, very slow: heavy branches in cold air
		float h = max(VERTEX.y, 0.0);
		float ph = dot(MODEL_MATRIX[3].xz, vec2(0.37, 0.61));
		float s = sin(TIME * 0.7 + ph + w.y * 0.4) * 0.5 + sin(TIME * 1.9 + ph * 2.0 + w.x) * 0.15;
		VERTEX.x += s * 0.012 * h * sway;
		VERTEX.z += s * 0.008 * h * sway;
	}
	wpos = w;
}

void fragment() {
	vec4 c = tint;
	if (has_tex) {
		c *= texture(albedo_tex, UV);
	}
	if (c.a < alpha_cut) {
		discard;
	}
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(vec3(l), c.rgb, clamp(world_sat, 0.0, 1.0));
	float rough = roughness_value;
	if (has_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	if (snow > 0.0) {
		vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		float n = noise(wpos.xz * 3.0 + wpos.y * 1.7);
		float up = smoothstep(0.15 + n * 0.35, 0.7, wn.y);
		float cover = clamp(up * snow * (0.75 + n * 0.5), 0.0, 1.0);
		col = mix(col, snow_color, cover);
		rough = mix(rough, 0.55, cover);
	}
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.35;
	// thin leaves let a little light through
	BACKLIGHT = vec3(sway * 0.1) * col;
}
