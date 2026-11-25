shader_type spatial;
// Triplanar textured surface (walls, floors, brick...) that follows the memory colour level.
global uniform float world_sat;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_normal = false;
uniform vec4 tint : source_color = vec4(1.0);
uniform float uv_scale = 0.5; // texture repeats per metre
uniform float roughness_value = 0.85;
uniform float normal_strength = 0.8;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec4 tri(sampler2D t, vec3 p, vec3 w) {
	const float b = 1.6; // mip bias: softer, painted-looking surfaces
	return texture(t, p.zy, b) * w.x + texture(t, p.xz, b) * w.y + texture(t, p.xy, b) * w.z;
}

void fragment() {
	vec3 w = pow(abs(wnorm), vec3(6.0));
	w /= (w.x + w.y + w.z);
	vec3 p = wpos * uv_scale;
	vec4 c = tri(albedo_tex, p, w) * tint;
	c.rgb = mix(c.rgb, vec3(dot(c.rgb, vec3(0.333))), -0.12); // a touch richer
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(l), c.rgb, clamp(world_sat, 0.0, 1.0));
	ROUGHNESS = roughness_value;
	if (has_normal) {
		NORMAL_MAP = tri(normal_tex, p, w).rgb;
		NORMAL_MAP_DEPTH = normal_strength;
	}
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
