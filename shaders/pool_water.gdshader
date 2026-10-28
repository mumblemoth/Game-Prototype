shader_type spatial;
// Poolens vatten: ljusare vid kanterna, djupare blått mot mitten, och ljusringlar
// (kaustik) som rör sig långsamt. Ogenomskinligt, så att den som badar syns ovanför
// ytan men inte under. Solen och poollampan ljussätter det som allt annat.
render_mode blend_mix, cull_back, specular_schlick_ggx;

uniform vec4 shallow : source_color = vec4(0.52, 0.86, 0.92, 1.0);
uniform vec4 deep : source_color = vec4(0.2, 0.58, 0.8, 1.0);
// Vattenytans storlek i meter, så att ringlarna blir lika stora i alla pooler.
uniform vec2 pool_size = vec2(5.0, 2.5);
uniform float speed = 0.6;

void fragment() {
	vec2 p = UV * pool_size * 2.4;
	float t = TIME * speed;
	float w = sin(p.x * 1.7 + t) + sin(p.y * 2.3 - t * 1.3) + sin((p.x + p.y) * 1.1 + t * 0.7);
	float caustic = 1.0 - smoothstep(0.0, 0.35, abs(w - 0.6));
	float edge = min(min(UV.x, 1.0 - UV.x) * pool_size.x, min(UV.y, 1.0 - UV.y) * pool_size.y);
	vec3 color = mix(shallow.rgb, deep.rgb, smoothstep(0.0, 0.9, edge));
	ALBEDO = color + caustic * 0.22;
	ROUGHNESS = 0.12;
	SPECULAR = 0.7;
}
