shader_type spatial;
// Anime-shading (cel): ljuset delas i tydliga toner i stället för mjuka gradienter.
// Skuggsidan får sin färg av omgivningsljuset (kallt), den belysta sidan av lampor
// och sol. Valfria mönster ritas i världskoordinater: kakel, tegelkakel och plankor.

uniform vec4 albedo : source_color = vec4(1.0);
// Glans: blank högdager i en hård fläck (kyl, metall, glaserat kakel).
uniform float gloss = 0.0;
uniform float gloss_size = 0.92;
// Självlysande (fönsterglas, lampskärmar).
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
// 0 = inget, 1 = kakel på golvet (xz), 2 = tegelkakel på vägg (xy), 3 = plankor (xz),
// 4 = tegelkakel på vägg (zy), 5 = rutnät på lodräta ytor (xy), 6 = liggande panel
// (fasad, jordlager), 7 = mjuka fläckar på marken (gräs, asfalt), 8 = tegel som följer
// väggens riktning (xy eller zy).
uniform int pattern = 0;
uniform float pattern_size = 0.4;
uniform vec4 line_color : source_color = vec4(0.6, 0.55, 0.5, 1.0);

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

float grid_line(vec2 p, float width) {
	vec2 g = fract(p);
	vec2 d = min(g, 1.0 - g);
	return 1.0 - smoothstep(width * 0.5, width, min(d.x, d.y));
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec3 c = albedo.rgb;
	float line = 0.0;
	if (pattern == 1) {
		line = grid_line(world_pos.xz / pattern_size, 0.03);
	} else if (pattern == 2 || pattern == 4 || pattern == 8) {
		bool along_z = pattern == 4 || (pattern == 8 && abs(world_normal.x) > abs(world_normal.z));
		vec2 p = (along_z ? world_pos.zy : world_pos.xy) / vec2(pattern_size * 2.0, pattern_size);
		p.x += step(1.0, mod(floor(p.y), 2.0)) * 0.5;
		line = grid_line(p, 0.04);
	} else if (pattern == 5) {
		// Rutmönster på lodräta ytor (xy), t.ex. rutigt tyg.
		line = grid_line(world_pos.xy / pattern_size, 0.25);
	} else if (pattern == 3) {
		vec2 p = world_pos.xz / vec2(pattern_size * 6.0, pattern_size);
		p.x += fract(sin(floor(p.y) * 12.9898) * 43758.5453);
		float tone = fract(sin(floor(p.y) * 78.233 + floor(p.x) * 3.1) * 43758.5453);
		c *= 0.94 + tone * 0.08;
		line = max(grid_line(vec2(0.5, p.y), 0.05), grid_line(vec2(p.x, 0.5), 0.02));
	} else if (pattern == 6) {
		// Liggande panel: varje bräda mörknar mot underkanten, med en fog emellan.
		float board = world_pos.y / pattern_size;
		c *= 0.93 + fract(board) * 0.07;
		line = grid_line(vec2(0.5, board), 0.06);
	} else if (pattern == 7) {
		float n = value_noise(world_pos.xz / pattern_size) * 0.6 + value_noise(world_pos.xz / (pattern_size * 0.27)) * 0.4;
		c *= 0.92 + n * 0.14;
	}
	ALBEDO = mix(c, line_color.rgb, line * 0.7);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = emission.rgb * emission_energy;
}

void light() {
	float ndl = max(dot(NORMAL, LIGHT), 0.0);
	float intensity = ndl * ATTENUATION;
	// Två hårda steg: halvljus och fullt ljus.
	float band = smoothstep(0.02, 0.07, intensity) * 0.6 + smoothstep(0.3, 0.36, intensity) * 0.4;
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * band;
	if (gloss > 0.0) {
		vec3 h = normalize(LIGHT + VIEW);
		float s = step(gloss_size, dot(NORMAL, h)) * ATTENUATION;
		SPECULAR_LIGHT += LIGHT_COLOR / PI * s * gloss;
	}
}
