shader_type spatial;
// CURTAIN WINDOW: the glass behind every house window. Dark when nobody is home; with `warmth` up,
// each pane glows amber through sheer curtains (vertical folds, a brighter middle where the curtains
// part, slightly different brightness per window so they read as rooms, not a pattern).
// Research: research/07-practical-lights-windows-lanterns.md (emissive panes, ~2400 K, dimmer than the door).
// Driven by HouseExterior.all_windows_warmth (the opening sets it; the game fades it out).

uniform float warmth : hint_range(0.0, 1.0) = 0.0;
uniform vec3 dark_glass : source_color = vec3(0.03, 0.035, 0.05);
uniform vec3 lamp_color : source_color = vec3(1.0, 0.56, 0.26);   // ~2400 K
uniform float energy = 1.7;            // emissive strength (glow threshold is 1.4; the door should stay brighter)
uniform float fold_density = 34.0;     // curtain folds per metre
uniform float variation = 0.45;        // how much windows differ from each other

varying vec3 v_world;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// which window this is: cells roughly a window apart along the wall and per storey
	vec2 cell = floor(vec2(v_world.x + v_world.z, v_world.y) / vec2(1.7, 2.6));
	float id = hash(cell);
	float across = v_world.x + v_world.z;
	// sheer curtain folds, softly
	float folds = 0.62 + 0.38 * sin(across * fold_density + sin(across * 5.0 + id * 6.0) * 1.6);
	// the gap where the curtains part glows a little brighter
	float gap = 1.0 + 0.35 * smoothstep(0.22, 0.0, abs(fract(across / 1.7 + id * 0.3) - 0.5));
	// warmer at the bottom (lamp on a table), a touch dimmer up top
	float vgrad = mix(1.1, 0.8, fract(v_world.y / 2.6));
	float lit = warmth * clamp(1.0 - variation * 0.5 + variation * id, 0.0, 1.4);
	ALBEDO = dark_glass;
	ROUGHNESS = 0.15;
	SPECULAR = 0.5;
	EMISSION = lamp_color * energy * folds * gap * vgrad * lit;
}
