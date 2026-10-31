// Ritar konturer runt allt i 3D-scenen genom att hitta kanter i djup- och normalbuffern.
// Läggs på en fyrkant framför kameran som täcker hela skärmen (se House3D).
shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform sampler2D normal_texture : hint_normal_roughness_texture, filter_nearest;
uniform vec4 line_color : source_color = vec4(0.36, 0.23, 0.14, 1.0);
uniform float thickness = 1.5;
// Skillnad i djup (meter) och i normalens riktning som räknas som en kant.
uniform float depth_threshold = 0.04;
uniform float normal_threshold = 0.5;

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_projection) {
	float depth = texture(depth_texture, uv).r;
	vec4 view = inv_projection * vec4(uv * 2.0 - 1.0, depth, 1.0);
	return -view.z / view.w;
}

vec3 view_normal(vec2 uv) {
	return normalize(texture(normal_texture, uv).xyz * 2.0 - 1.0);
}

void fragment() {
	vec2 pixel = thickness / VIEWPORT_SIZE;
	float depth = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 normal = view_normal(SCREEN_UV);
	float edge = 0.0;
	vec2 offsets[4] = vec2[](vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0));
	for (int i = 0; i < 4; i++) {
		vec2 uv = SCREEN_UV + offsets[i] * pixel;
		float other_depth = linear_depth(uv, INV_PROJECTION_MATRIX);
		vec3 other_normal = view_normal(uv);
		if (abs(other_depth - depth) > depth_threshold * max(1.0, depth * 0.1)) {
			edge = 1.0;
		}
		if (1.0 - dot(normal, other_normal) > normal_threshold) {
			edge = 1.0;
		}
	}
	ALBEDO = line_color.rgb;
	ALPHA = edge * line_color.a;
}
