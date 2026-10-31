shader_type spatial;
// Fönsterglas: nästan helt klart, så att omgivningen (Surroundings) syns igenom, med en
// svag ton och två sneda blänk som i anime, så att glaset ändå läses som glas.
// Frostat glas (badrum) visar en suddig bild av det bakom i stället för en klar.
// Kvällen och natten speglar glaset lite av himlens färg (sätts av TimeOfDayRig).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.8, 0.92, 1.0, 1.0);
// Hur mycket av tonen som ligger över utsikten (0 = helt klart).
uniform float haze = 0.06;
uniform vec4 sky : source_color = vec4(1.0);
// Spegling (0 på dagen, mer på natten).
uniform float reflection = 0.0;
uniform float glint = 0.28;
uniform float frosted = 0.0;
// Rutans storlek i meter, så att blänken får samma bredd i små och stora fönster.
uniform vec2 pane_size = vec2(1.0, 1.0);

float band(float x, float center, float width) {
	return 1.0 - smoothstep(width * 0.5, width * 0.5 + 0.012, abs(x - center));
}

void fragment() {
	// Sned koordinat i meter: blänken går från övre vänstra hörnet nedåt åt höger.
	float s = (UV.x * pane_size.x + UV.y * pane_size.y * 0.55) / max(pane_size.x + pane_size.y * 0.55, 0.01);
	float shine = max(band(s, 0.34, 0.11), band(s, 0.5, 0.035) * 0.8);
	if (frosted > 0.5) {
		vec3 behind = textureLod(screen_tex, SCREEN_UV, 4.0).rgb;
		ALBEDO = mix(behind, vec3(0.94, 0.97, 0.99), 0.5) + shine * glint * 0.25;
		ALPHA = 1.0;
	} else {
		ALBEDO = mix(mix(tint.rgb, sky.rgb, reflection), vec3(1.0), shine);
		ALPHA = clamp(haze + reflection * 0.3 + shine * glint, 0.0, 1.0);
	}
}
