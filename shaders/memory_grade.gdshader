shader_type canvas_item;
// MEMORY GRADE: how a frozen memory looks (ScreenEffects > MemoryGrade, runs before FilmLook).
// Driven by scripts/systems/memory_grade.gd. Instead of flat grey:
//   - a moonlit duotone: shadows sink into deep blue, highlights turn cold silver
//   - warm light sources (lamps, fire, the ember itself) keep their colour
//   - colour glows back in a halo around the ember (it carries the warmth through the house)
//   - frost creeps in from the screen edges and slowly breathes while the memory is frozen
//   - a warm ring of colour sweeps out from the centre when a memory is restored
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
// 0 = frozen memory .. 1 = full colour (ScreenEffects.world_saturation).
uniform float world_sat = 1.0;
uniform vec3 shadow_tint : source_color = vec3(0.10, 0.17, 0.36);
uniform vec3 highlight_tint : source_color = vec3(0.86, 0.92, 1.0);
// Extra contrast in the frozen look (0 = none).
uniform float frozen_contrast : hint_range(0.0, 1.0) = 0.25;
// 0..1: how far the frost reaches in from the edges when fully frozen.
uniform float frost : hint_range(0.0, 1.0) = 0.6;
// Breaths per second of the frost (a slow, uneasy pulse).
uniform float frost_breath = 0.45;
// Ember halo: xy = centre (px), z = radius (px), w = strength 0..1.
uniform vec4 ember = vec4(0.0);
// Restore ripple: radius in screen heights (< 0 = off) and how much colour it carries.
uniform float ripple = -1.0;
uniform float ripple_hold = 0.0;
uniform vec3 ripple_color : source_color = vec3(1.0, 0.62, 0.3);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 px = SCREEN_UV * res;
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float lum = luma(c);
	float frozen = 1.0 - clamp(world_sat, 0.0, 1.0);

	// 1. moonlit duotone (keeps brightness, changes only the hue)
	float l = mix(lum, smoothstep(0.0, 1.0, lum), frozen_contrast);
	vec3 st = shadow_tint / max(luma(shadow_tint), 0.001);
	vec3 ht = highlight_tint / max(luma(highlight_tint), 0.001);
	vec3 duo = l * mix(st, ht, smoothstep(0.02, 0.45, lum));

	// 2. how much real colour survives here
	float keep = max(world_sat, smoothstep(0.55, 1.1, lum));      // warm lights stay warm
	float d_ember = distance(px, ember.xy);
	float halo = ember.w * (1.0 - smoothstep(ember.z * 0.25, ember.z, d_ember));
	keep = max(keep, halo);
	vec2 q = (SCREEN_UV - 0.5) * vec2(res.x / res.y, 1.0);
	float dr = length(q);
	float rim = 0.0;
	if (ripple >= 0.0) {
		keep = max(keep, (1.0 - smoothstep(ripple - 0.08, ripple, dr)) * ripple_hold);
		rim = exp(-pow((dr - ripple) * 12.0, 2.0)) * ripple_hold;
	}
	vec3 outc = mix(duo, c, clamp(keep, 0.0, 1.0));
	outc += rim * ripple_color * 0.35;

	// 3. frost creeping in from the edges, breathing slowly; the ember's halo melts it
	float breath = 0.5 + 0.5 * sin(TIME * frost_breath * 6.2832);
	float n = vnoise(px / 140.0 + vec2(TIME * 0.02, 0.0)) * 0.65 + vnoise(px / 28.0) * 0.35;
	float reach = frost * frozen * (0.85 + 0.15 * breath);
	float edge = length(q * vec2(0.8, 1.0)) + (n - 0.5) * 0.22;
	float f = smoothstep(0.78 - reach * 0.38, 0.95, edge) * (1.0 - halo);
	vec3 ice = mix(vec3(l) * ht, ht * 0.75, 0.35);
	outc = mix(outc, ice, f * 0.6 * frozen);
	// thin bright crystal veins inside the frost
	float vein = 1.0 - smoothstep(0.0, 0.035, abs(vnoise(px / 55.0) - 0.5));
	outc += vein * f * frozen * 0.08 * ht;

	COLOR = vec4(outc, 1.0);
}
