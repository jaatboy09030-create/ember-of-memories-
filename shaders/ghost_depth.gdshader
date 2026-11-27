shader_type spatial;
// Memory ghost, pass 1 of 2: writes the figure's depth and nothing else (invisible).
// The faded ghost (ghost.gdshader) draws after it, so only the OUTER surface shows: no body
// through the clothes, no eyeballs through the face - a solid figure, just faded.
// Clipped to the blink demo's islands like the ghost itself (island_count 0 = no clipping).
// Set up by scripts/objects/memory_figure.gd.
render_mode unshaded, blend_mix, depth_draw_always, cull_back, shadows_disabled, fog_disabled;

uniform vec4 islands[8];
uniform vec4 island_shape[8];
uniform int island_count = 0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (island_count > 0) {
		float sdf = 1e5;
		for (int i = 0; i < 8; i++) {
			if (i >= island_count) break;
			vec4 ic = islands[i];
			if (ic.w <= 0.0001) continue;
			sdf = min(sdf, length((world_pos - ic.xyz) * max(island_shape[i].xyz, vec3(0.05))) - ic.w);
		}
		if (sdf > 0.1) discard;
	}
	ALBEDO = vec3(0.0);
	ALPHA = 0.0;
}
