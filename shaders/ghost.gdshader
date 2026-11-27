shader_type spatial;
// Memory ghost: the real character, faded to low opacity, softly glowing ember-warm.
render_mode blend_mix, depth_prepass_alpha, cull_back, shadows_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform bool has_tex = false;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.68, 0.42, 1.0);
uniform float strength = 1.0;   // tweened when the memory returns
uniform float opacity = 0.45;
// Blink demo: ghosts are see-through, so the black void (which tests the depth BEHIND them,
// e.g. a far wall) would black out a figure standing inside the memory. So they draw OVER
// the void and clip themselves to the same islands. island_count 0 = no clipping (main game).
uniform vec4 islands[8];
uniform vec4 island_shape[8];
uniform int island_count = 0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float keep = 1.0;
	if (island_count > 0) {
		float sdf = 1e5;
		for (int i = 0; i < 8; i++) {
			if (i >= island_count) break;
			vec4 ic = islands[i];
			if (ic.w <= 0.0001) continue;
			sdf = min(sdf, length((world_pos - ic.xyz) * max(island_shape[i].xyz, vec3(0.05))) - ic.w);
		}
		keep = 1.0 - smoothstep(0.0, 0.1, sdf);
		if (keep <= 0.001) discard;
	}
	vec4 c = tint;
	if (has_tex) {
		c *= texture(albedo_tex, UV);
	}
	float l = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	// faded, warm-washed version of the real colours
	vec3 base = mix(vec3(l), c.rgb, 0.45) * mix(vec3(1.0), glow_color.rgb, 0.35);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float flicker = 0.92 + 0.08 * sin(TIME * 5.3) * sin(TIME * 2.1 + 1.3);
	ALBEDO = base;
	EMISSION = (base * 0.35 + glow_color.rgb * rim * 0.9) * strength * flicker;
	ALPHA = clamp(opacity * (0.85 + rim * 0.5) * min(strength, 1.3), 0.0, 0.9) * keep;
}
