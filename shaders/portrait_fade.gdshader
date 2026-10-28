shader_type canvas_item;
// Tonar ut porträttets underkant i dialogrutan, så att den raka avskärningen inte syns
// när textrutan är smalare än porträtten. Måtten är i rektangelns egna koordinater.

uniform float fade_from = 320.0;
uniform float fade_to = 480.0;

varying float local_y;

void vertex() {
	local_y = VERTEX.y;
}

void fragment() {
	COLOR.a *= 1.0 - smoothstep(fade_from, fade_to, local_y);
}
