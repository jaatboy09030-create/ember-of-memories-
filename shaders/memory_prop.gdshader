shader_type spatial;
// Textured props share the world colour level: grey in a frozen memory, full colour when restored.
// Outdoor props can carry snow on their upward-facing surfaces.
global uniform float world_sat;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool has_tex = false;
uniform float roughness_value = 0.85;
uniform float snow = 0.0;
uniform float paint_bias = 2.2; // softer, painted-looking textures // 0 = none, 1 = full snow cover on top faces

varying vec3 wnorm;
varying vec3 wpos;

void vertex() {
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec4 c = tint;
	if (has_tex) {
		c *= texture(albedo_tex, UV, paint_bias);
	}
	if (c.a < 0.4) {
		discard;
	}
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(vec3(l), c.rgb, 1.15); // a touch richer
	vec3 col = mix(vec3(l), c.rgb, clamp(world_sat, 0.0, 1.0));
	float rough = roughness_value;
	if (snow > 0.0) {
		float up = smoothstep(0.25, 0.75, wnorm.y);
		float cover = clamp(up * snow, 0.0, 1.0);
		col = mix(col, vec3(0.9, 0.93, 1.0), cover);
		rough = mix(rough, 0.6, cover);
	}
	ALBEDO = col;
	ROUGHNESS = rough;
}


// ---- Stylized (toon / painterly) lighting shared by every surface ----
void light() {
	float ndl = dot(NORMAL, LIGHT);
	// soft two-step banding: lit / half-lit / shadow, with gentle edges
	float band = smoothstep(-0.05, 0.12, ndl) * 0.62 + smoothstep(0.42, 0.58, ndl) * 0.38;
	DIFFUSE_LIGHT += band * ATTENUATION * LIGHT_COLOR / PI;
	vec3 h = normalize(LIGHT + VIEW);
	float spec = smoothstep(0.86, 0.92, dot(NORMAL, h)) * 0.12;
	SPECULAR_LIGHT += spec * ATTENUATION * LIGHT_COLOR;
}
