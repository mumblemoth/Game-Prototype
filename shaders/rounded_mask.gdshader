// Rundar hörnen på allt en kontroll ritar (bild, stylebox, egna draw-anrop) med en
// mjuk kant. size är kontrollens storlek och radius hörnens rundning, i pixlar.
// Används av telefonen (PhoneTheme.round_corners) i stället för nästlad clip_children.
shader_type canvas_item;

uniform vec2 size = vec2(100.0, 100.0);
uniform float radius = 12.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec2 half_size = size * 0.5;
	vec2 q = abs(local_position - half_size) - half_size + vec2(radius);
	float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	vec4 color = texture(TEXTURE, UV) * COLOR;
	color.a *= clamp(0.5 - distance, 0.0, 1.0);
	COLOR = color;
}
