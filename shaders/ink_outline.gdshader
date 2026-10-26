shader_type spatial;
// Tuschkonturer som efterbehandling, som linjerna i Anima-bilderna: en heltäckande
// fyrkant framför kameran letar kanter i djup och normaler och mörkar dem. Linjen tar
// färg av det den ligger på (en mörkare variant), så den blir varm i stället för svart.
// Kanterna mäts mjukt i åtta riktningar och viktas, så att linjerna blir jämna och inte
// bryts upp i prickar eller kryper när kameran rör sig.
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest;
uniform float thickness = 1.0;
// Hur stort hopp i djup (andel av avståndet) som räknas som en kant.
uniform float depth_threshold = 0.03;
uniform float normal_threshold = 0.4;
uniform float darkness = 0.32;
uniform float strength = 0.35;
uniform vec4 ink_tint : source_color = vec4(0.35, 0.2, 0.18, 1.0);
// Linjerna bleknar med avståndet (meter), så att omgivningen långt bort blir mjuk.
uniform float fade_begin = 1000.0;
uniform float fade_end = 2000.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_projection) {
	float d = texture(depth_tex, uv).r;
	vec4 view = inv_projection * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -view.z / view.w;
}

// Hur mycket kant det är mot en granne: mjuk övergång i stället för ett hårt steg.
float edge_to(vec2 uv, float d, vec3 n, mat4 inv_projection) {
	float dn = linear_depth(uv, inv_projection);
	float depth_edge = smoothstep(depth_threshold, depth_threshold * 2.5, (dn - d) / d);
	vec3 nn = texture(normal_tex, uv).xyz * 2.0 - 1.0;
	float normal_edge = smoothstep(normal_threshold, normal_threshold + 0.35, 1.0 - dot(n, nn));
	return max(depth_edge, normal_edge);
}

void fragment() {
	vec2 px = thickness / VIEWPORT_SIZE;
	float d = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 n = texture(normal_tex, SCREEN_UV).xyz * 2.0 - 1.0;
	// Raka grannar väger fullt, diagonala lite mindre; resultatet blir en mjukare linje.
	float edge = 0.0;
	edge += edge_to(SCREEN_UV + vec2(px.x, 0.0), d, n, INV_PROJECTION_MATRIX);
	edge += edge_to(SCREEN_UV - vec2(px.x, 0.0), d, n, INV_PROJECTION_MATRIX);
	edge += edge_to(SCREEN_UV + vec2(0.0, px.y), d, n, INV_PROJECTION_MATRIX);
	edge += edge_to(SCREEN_UV - vec2(0.0, px.y), d, n, INV_PROJECTION_MATRIX);
	float diagonal = 0.0;
	diagonal += edge_to(SCREEN_UV + px, d, n, INV_PROJECTION_MATRIX);
	diagonal += edge_to(SCREEN_UV - px, d, n, INV_PROJECTION_MATRIX);
	diagonal += edge_to(SCREEN_UV + vec2(px.x, -px.y), d, n, INV_PROJECTION_MATRIX);
	diagonal += edge_to(SCREEN_UV + vec2(-px.x, px.y), d, n, INV_PROJECTION_MATRIX);
	edge = clamp(edge * 0.5 + diagonal * 0.25, 0.0, 1.0);
	edge *= 1.0 - smoothstep(fade_begin, fade_end, d) * 0.85;
	vec3 color = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	vec3 ink = color * darkness * mix(vec3(1.0), ink_tint.rgb * 2.0, 0.5);
	ALBEDO = mix(color, ink, edge * strength);
}
