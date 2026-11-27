shader_type sky;
// NIGHT SKY: a painted, sad winter night, looking up past the house.
//  - deep navy sky, lighter blue toward the horizon (reads as night blue, not black)
//  - a huge warm golden-ivory moon: seas, craters, plus a fine "sparkle" of bright specks and
//    thin bright filaments, like a glowing painted moon; an inner bloom halo and a wide warm haze.
//    Placed by the Moon DirectionalLight3D (LIGHT0_DIRECTION points toward it).
//  - puffy cumulus banks gathered round the lower half of the moon, trailing off to the right,
//    drawn OVER the moon so it is partly hidden; gold-lit tops near the moon, blue-grey bodies.
//    Away from the moon cloud is sparse and dim, so most of the sky stays clear and starry.
//  - a cool blue Milky Way band with darker lanes and dense small stars, from just right of the
//    moon up toward the upper right of the opening shot
//  - crisp stars in three layers, plus a few bright blue-white ones with a small glow
//
// How to change it: everything is a uniform (Inspector, on the Sky material).
//   Colour uniforms use source_color, so Godot treats the Inspector value as sRGB and converts it
//   to linear. The defaults below are the sRGB encodings of the intended linear values (noted in
//   each comment), e.g. zenith 0.070/0.112/0.206 sRGB = 0.006/0.012/0.035 linear.
//   moon_size is the moon radius in radians (0.15 fills about a quarter of the frame).
//   moon_energy sets the disc brightness (linear peak ~ moon_energy); the glow threshold is 1.4,
//   so keep it near 1.3-1.6 or the craters wash out into bloom.
//   Clouds: cloud_cover is the overall threshold (lower = more cloud); cloud_focus_* place the
//   bank relative to the moon; cloud_far thins out the clouds away from the moon.
//   milky_way_pole is the axis the band wraps around; band_offset slides it across the sky
//   (more negative = closer to the moon).

// --- sky ---
uniform vec3 zenith_color : source_color = vec3(0.070, 0.112, 0.206);   // sky straight up: deep navy (linear ~0.006, 0.012, 0.035)
uniform vec3 horizon_color : source_color = vec3(0.152, 0.206, 0.293);  // sky near the horizon: lighter night blue (linear ~0.02, 0.035, 0.07)

// --- moon ---
uniform vec3 moon_color : source_color = vec3(1.0, 0.936, 0.832);       // disc tint, golden ivory (linear ~1.0, 0.86, 0.66)
uniform vec3 glow_color : source_color = vec3(1.0, 0.81, 0.60);         // tint of the halo and haze round the moon (linear ~1.0, 0.62, 0.32)
uniform float moon_size = 0.15;      // moon radius in radians
uniform float moon_energy = 1.45;    // disc brightness, linear peak (glow threshold is 1.4)
uniform float halo = 1.0;            // strength of the inner bloom halo and the wide warm haze
uniform float sparkle = 1.0;         // bright specks and filaments over the moon surface (0 = plain moon)

// --- stars and Milky Way ---
uniform float star_amount = 1.0;     // overall star brightness (0 = no stars)
uniform float milky_way = 1.0;       // Milky Way brightness (0 = off)
uniform vec3 milky_way_color : source_color = vec3(0.485, 0.584, 0.767); // band body, pale blue (linear ~0.20, 0.30, 0.55)
uniform vec3 milky_way_core : source_color = vec3(0.767, 0.832, 0.955);  // bright clumps, cool blue-white (linear ~0.55, 0.66, 0.90)
// Default pole: the band is the great circle through two points of the opening shot.
//   Camera forward F = (-0.55, 0.30, -0.78); right R = norm(F x Y) = (0.817, 0, -0.576);
//   up U = R x F = (0.173, 0.954, 0.245). Moon M = (-0.727, 0.588, -0.355) sits at screen
//   (x, y) = (M.R, M.U) / M.F = (-0.46, 0.41), i.e. upper left.
//   P1 = F - 0.25 R + 0.30 U (just right of / below the moon centre) = (-0.702, 0.586, -0.563)
//   P2 = F + 0.60 R + 0.85 U (upper right of frame)                  = ( 0.087, 1.111, -0.918)
//   pole = norm(P1 x P2) = (0.08, -0.639, -0.765). Check: M.pole = -0.16, so the band centre
//   runs ~0.16 rad (about one moon radius) to the right of the moon centre, grazing its edge.
uniform vec3 milky_way_pole = vec3(0.08, -0.639, -0.765); // axis the band wraps around
uniform float band_offset = 0.0;     // slides the band across the sky (negative = toward the moon)
uniform float band_width = 0.17;     // half-width of the band in radians

// --- clouds ---
uniform float cloud_amount = 1.0;    // cloud opacity (0 = no clouds)
uniform float cloud_cover = 0.46;    // cloud threshold: lower = more cloud
uniform float cloud_speed = 0.003;   // drift speed
uniform float cloud_scale = 2.0;     // size of the cloud pattern: higher = smaller, puffier clouds
uniform float cloud_focus = 1.0;     // how strongly cloud gathers round the moon (0 = evenly spread)
uniform vec2 cloud_focus_offset = vec2(0.05, -0.13);             // bank centre relative to the moon centre, radians (x = right, y = up)
uniform vec4 cloud_focus_spread = vec4(0.22, 0.75, 0.25, 0.10);  // bank extent in radians: left, right, down, up
uniform float cloud_far = 0.14;      // raises the threshold away from the moon: higher = fewer far clouds
uniform vec3 cloud_body_color : source_color = vec3(0.183, 0.209, 0.267);   // shadowed cloud body, blue-grey (linear ~0.028, 0.036, 0.058)
uniform vec3 cloud_lining_color : source_color = vec3(1.0, 0.832, 0.618);   // moonlit cloud tops, warm gold (linear ~1.0, 0.66, 0.34)

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x), mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p, int oct) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < oct; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash13(i), hash13(i + vec3(1.0, 0.0, 0.0)), f.x), mix(hash13(i + vec3(0.0, 1.0, 0.0)), hash13(i + vec3(1.0, 1.0, 0.0)), f.x), f.y);
	float b = mix(mix(hash13(i + vec3(0.0, 0.0, 1.0)), hash13(i + vec3(1.0, 0.0, 1.0)), f.x), mix(hash13(i + vec3(0.0, 1.0, 1.0)), hash13(i + vec3(1.0, 1.0, 1.0)), f.x), f.y);
	return mix(a, b, f.z);
}

float fbm3(vec3 p, int oct) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < oct; i++) {
		v += a * vnoise3(p);
		p = p * 2.07 + vec3(1.7, 9.2, 4.1);
		a *= 0.5;
	}
	return v;
}

// Craters on the moon sphere: dark bowl, bright raised rim. Returns a brightness offset.
float craters(vec3 p, float amount) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	float res = 0.0;
	for (int x = -1; x <= 1; x++)
	for (int y = -1; y <= 1; y++)
	for (int z = -1; z <= 1; z++) {
		vec3 g = vec3(float(x), float(y), float(z));
		vec3 c = i + g;
		if (hash13(c + 57.0) > amount) {
			continue;
		}
		vec3 o = vec3(hash13(c), hash13(c + 11.0), hash13(c + 23.0));
		float rad = 0.18 + 0.32 * hash13(c + 41.0);
		float d = length(g + o - f) / rad;
		res += -0.15 * (1.0 - smoothstep(0.55, 1.0, d));
		res += 0.13 * exp(-pow((d - 1.0) * 5.0, 2.0));
	}
	return res;
}

// Bright specks on the moon disc (q = disc coords, -1..1). One cell, no neighbours: cheap.
float specks(vec2 q, float scale, float keep) {
	vec2 p = q * scale;
	vec2 cell = floor(p);
	float r = hash12(cell);
	if (r < keep) {
		return 0.0;
	}
	vec2 c = cell + 0.5 + (vec2(hash12(cell + 7.0), hash12(cell + 13.0)) - 0.5) * 0.6;
	float dist = length(p - c);
	return smoothstep(0.3, 0.0, dist) * (0.4 + 0.6 * hash12(cell + 29.0));
}

// One layer of stars on a grid of cells over the sphere of directions.
vec3 star_layer(vec3 d, float scale, float density, float gain, float glow) {
	vec3 p = d * scale;
	vec3 cell = floor(p);
	float r = hash13(cell);
	if (r > density) {
		return vec3(0.0);
	}
	vec3 c = cell + 0.5 + (vec3(hash13(cell + 7.0), hash13(cell + 13.0), hash13(cell + 19.0)) - 0.5) * 0.7;
	float dist = length(p - c);
	float mag = pow(hash13(cell + 29.0), 3.0);           // most stars faint, a few bright
	float temp = hash13(cell + 31.0);
	vec3 tint = temp < 0.25 ? vec3(1.0, 0.8, 0.62) : (temp > 0.6 ? vec3(0.72, 0.82, 1.0) : vec3(0.93, 0.95, 1.0));
	float tw = 0.75 + 0.25 * sin(TIME * (1.3 + temp * 3.0) + r * 900.0);
	float core = smoothstep(0.5, 0.0, dist);
	float s = core * core + glow * exp(-dist * 3.0) * mag;
	return tint * s * (0.25 + mag * 1.6) * tw * gain;
}

// A sparse layer of bright blue-white stars with a small glow.
vec3 bright_stars(vec3 d, float density) {
	vec3 p = d * 120.0;
	vec3 cell = floor(p);
	float r = hash13(cell + 101.0);
	if (r > density) {
		return vec3(0.0);
	}
	vec3 c = cell + 0.5 + (vec3(hash13(cell + 3.0), hash13(cell + 17.0), hash13(cell + 37.0)) - 0.5) * 0.6;
	float dist = length(p - c);
	float tw = 0.8 + 0.2 * sin(TIME * 2.1 + r * 1300.0);
	float core = smoothstep(0.16, 0.0, dist);
	float glow = exp(-dist * 9.0) * 0.35 + exp(-dist * 30.0) * 0.6;
	return vec3(0.74, 0.84, 1.0) * (core * 1.5 + glow) * tw;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;
	vec3 col = mix(horizon_color, zenith_color, smoothstep(-0.02, 0.5, h));
	col = mix(col, horizon_color * 0.7, smoothstep(0.0, -0.2, h));
	float above = smoothstep(-0.02, 0.12, h);

	vec3 M = normalize(LIGHT0_DIRECTION);
	float mcos = dot(d, M);
	float ang = acos(clamp(mcos, -1.0, 1.0));
	float beyond = max(ang - moon_size, 0.0);

	// moon glow: inner bloom-like halo hugging the limb + a wide faint warm haze
	float inner_glow = exp(-beyond * 16.0) * 0.42 + exp(-beyond * 5.0) * 0.1;
	float haze = exp(-ang * 2.2) * 0.07 + exp(-ang * 0.8) * 0.012;

	if (AT_CUBEMAP_PASS) {
		// the lighting/reflection pass only needs the broad colours: blue sky + warm moon glow
		col += glow_color * (inner_glow * 0.5 + haze) * halo;
		COLOR = col;
	} else {
		// --- Milky Way: cool blue band, darker lanes, only evaluated near the band ---
		float b = dot(d, normalize(milky_way_pole)) - band_offset;
		float band = exp(-(b * b) / (band_width * band_width));
		float clumps = 0.5;
		if (band > 0.004 && h > -0.05) {
			float inner = exp(-(b * b) / (band_width * band_width * 0.25));
			float body = fbm3(d * 5.0, 5);
			clumps = fbm3(d * 16.0 + 3.0, 4);
			float lanes = 1.0 - abs(fbm3(d * 9.0 + 11.0, 5) * 2.0 - 1.0);  // ridged: thin dark rifts
			float grit = vnoise3(d * 140.0);                               // fine star-cloud grain
			float mw = band * (0.12 + body * 0.55) * (0.25 + clumps * clumps * 1.9) * (0.55 + grit * 0.9);
			mw *= 1.0 - 0.8 * smoothstep(0.72, 0.95, lanes) * inner;
			mw *= 1.0 - 0.5 * smoothstep(0.55, 0.75, body) * inner;
			vec3 mw_col = mix(milky_way_color, milky_way_core, clamp(inner * clumps * 1.1, 0.0, 1.0));
			col += mw_col * mw * milky_way * 0.22 * above;
		}

		// --- stars: denser inside the band ---
		if (h > -0.05) {
			float fade = smoothstep(-0.02, 0.2, h) * star_amount;
			col += star_layer(d, 260.0, 0.0055, 1.6, 0.5) * fade;
			col += star_layer(d, 520.0, 0.022 + band * 0.06, 0.75, 0.0) * fade;
			col += star_layer(d, 900.0, 0.036 + band * 0.35 * (0.4 + clumps), 0.4, 0.0) * fade;
			col += bright_stars(d, 0.002) * fade;
		}

		// moon frame: rt ~ screen right, up ~ screen up (for the opening camera)
		vec3 rt = normalize(cross(M, vec3(0.0, 1.0, 0.0)));
		vec3 up = cross(rt, M);
		vec2 mq = vec2(dot(d, rt), dot(d, up));   // ~angular offset from the moon centre (radians)

		// --- moon glow (most of the haze sits behind the clouds, some in front) ---
		col += glow_color * (inner_glow + haze * 0.6) * halo;

		// --- moon disc ---
		if (mcos > 0.0 && ang < moon_size * 1.02) {
			vec2 q = mq / sin(moon_size);
			float r = length(q);
			float z = sqrt(max(0.0, 1.0 - r * r));
			vec3 sp = vec3(q, z);
			float maria = fbm3(sp * 1.6 + vec3(3.1, 1.2, 0.4), 5);
			float seas = smoothstep(0.42, 0.6, maria);
			float grain = fbm3(sp * 38.0, 3);
			float alb = 0.97 - seas * 0.38 + (grain - 0.5) * 0.2;
			alb += craters(sp * 4.0, 0.4);
			alb += craters(sp * 10.0 + 7.0, 0.5) * 0.8;
			alb += craters(sp * 26.0 + 3.0, 0.55) * 0.55;
			// sparkle: thin bright filaments (sharpened ridges) + scattered bright specks
			float ridge = 1.0 - abs(fbm3(sp * 7.0 + 19.0, 3) * 2.0 - 1.0);
			float fil = pow(clamp(ridge, 0.0, 1.0), 14.0) * smoothstep(0.35, 0.65, vnoise3(sp * 3.0 + 5.0));
			float spk = specks(q, 60.0, 0.82) + specks(q + 0.37, 130.0, 0.9) * 0.7;
			float spark = (fil * 0.45 + spk * 0.6) * sparkle * (0.6 + 0.4 * (1.0 - seas));
			float limb = mix(0.6, 1.0, pow(z, 0.35));
			vec3 moon = moon_color * moon_energy * (clamp(alb, 0.15, 1.08) + spark) * limb;
			float edge = smoothstep(1.0, 0.985, r);
			col = mix(col, moon, edge);
		}

		// --- clouds: puffy banks round the lower moon, drawn over it ---
		if (h > 0.0 && cloud_amount > 0.0) {
			// where the bank gathers: an asymmetric blob below/right of the moon, rising slightly to the right
			vec2 o = mq - cloud_focus_offset;
			o.y -= max(o.x, 0.0) * 0.12;
			float sx = o.x < 0.0 ? cloud_focus_spread.x : cloud_focus_spread.y;
			float sy = o.y < 0.0 ? cloud_focus_spread.z : cloud_focus_spread.w;
			float f = exp(-(o.x * o.x) / (sx * sx) - (o.y * o.y) / (sy * sy)) * cloud_focus * (mcos > 0.0 ? 1.0 : 0.0);

			vec2 uv0 = d.xz / (h + 0.12) * cloud_scale;
			vec2 muv = M.xz / (max(M.y, 0.02) + 0.12) * cloud_scale;
			vec2 to_moon = normalize(muv - uv0 + vec2(1e-4, 0.0));
			vec2 uv = uv0 + vec2(TIME * cloud_speed, TIME * cloud_speed * 0.3) * cloud_scale;
			vec2 warp = vec2(fbm(uv * 0.5 + 3.0, 3), fbm(uv * 0.5 + 9.0, 3));
			float c = fbm(uv + warp * 1.1, 5);
			float c2 = fbm(uv * 2.7 + warp * 1.5 + 5.0, 4);                    // billows inside
			float n = c + (c2 - 0.5) * 0.22;
			float thr = cloud_cover + mix(cloud_far, -0.05, clamp(f, 0.0, 1.0));
			float layer = smoothstep(0.03, 0.12, h) * (1.0 - smoothstep(0.82, 0.97, h));
			float dens = smoothstep(thr, thr + 0.09, n) * layer * cloud_amount;
			if (dens > 0.001) {
				float thick = smoothstep(thr, thr + 0.25, n);
				// lit side: density falls off toward the moon -> edge faces the moon (top edges here)
				float nl = fbm(uv + to_moon * 0.12 + warp * 1.1, 4) + (c2 - 0.5) * 0.22;
				float lit = clamp((n - nl) * 7.0, 0.0, 1.0);
				float moonlit = exp(-beyond * 4.0);
				vec3 body = mix(cloud_body_color, cloud_body_color * 2.0 + glow_color * 0.025, moonlit);
				body *= (0.7 + c2 * 0.6) * (1.0 - 0.35 * thick);
				vec3 lining = cloud_lining_color * (lit * 0.95 + (1.0 - thick) * 0.4) * moonlit * halo;
				col = mix(col, body + lining, dens * (0.82 + 0.16 * thick));
			}
		}

		// haze in front of the clouds
		col += glow_color * haze * 0.4 * halo;
		COLOR = col;
	}
}
