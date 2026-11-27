shader_type spatial;
// PHOTO GLASS: the glass over the photograph in memory 5.
// At reflect = 0 it is a faint clear sheen; as reflect rises the glass turns into a dark
// mirror showing reflection_tex (what PhotoFrame's ReflectionCamera sees: the face above it).
// The picture is flipped left-right like a real mirror. Used by scenes/objects/photo_frame.tscn.
render_mode unshaded, blend_mix, cull_back, depth_draw_opaque;

uniform sampler2D reflection_tex : source_color, filter_linear;
// 0 = clear glass, 1 = full mirror. PhotoFrame.set_reflection() tweens it.
uniform float reflect = 0.0;
// Faint cold tint of old glass.
uniform vec3 tint : source_color = vec3(0.82, 0.86, 0.92);
// Darkening toward the edges of the glass (0 = none).
uniform float edge_dark = 0.55;

void fragment() {
	vec2 uv = vec2(1.0 - UV.x, UV.y);
	vec3 refl = texture(reflection_tex, uv).rgb * tint;
	vec2 c = UV - 0.5;
	float vignette = 1.0 - edge_dark * smoothstep(0.18, 0.5, length(c * vec2(1.0, 0.8)));
	// a soft diagonal glare streak, like light lying on glass
	float streak = smoothstep(0.06, 0.0, abs(UV.x + UV.y * 0.6 - 0.62)) * 0.12;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = refl * vignette + vec3(streak + fres * 0.2);
	ALPHA = clamp(reflect + streak + fres * 0.15 + 0.03, 0.0, 1.0);
}
