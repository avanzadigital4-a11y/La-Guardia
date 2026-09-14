shader_type canvas_item;
// Post-proceso: cuantizacion de color, grano tipo VHS, scanlines y vineta.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float color_levels : hint_range(4.0, 64.0) = 40.0;
uniform float grain_amount : hint_range(0.0, 0.5) = 0.05;
uniform float scanline_amount : hint_range(0.0, 1.0) = 0.12;
uniform float vignette_amount : hint_range(0.0, 2.0) = 0.9;
uniform float chroma_shift : hint_range(0.0, 4.0) = 0.7;
uniform float dread : hint_range(0.0, 1.0) = 0.0;
uniform float time_seed = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(233.34, 851.73));
	p += dot(p, p + 23.45);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;

	// Aberracion cromatica leve, mas fuerte cuanto mas lejos del centro.
	float edge = length(uv - vec2(0.5)) * 2.0;
	float shift = chroma_shift * (1.0 + dread * 2.0) * edge;
	vec3 col;
	col.r = texture(screen_tex, uv + vec2(px.x * shift, 0.0)).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - vec2(px.x * shift, 0.0)).b;

	// Cuantizacion de color (bandas tipo 16 bits).
	col = floor(col * color_levels + 0.5) / color_levels;

	// Grano.
	float n = hash21(uv * vec2(1024.0, 768.0) + vec2(TIME * 60.0 + time_seed));
	col += (n - 0.5) * grain_amount * (1.0 + dread);

	// Scanlines.
	float scan = sin(uv.y / max(px.y, 0.00001) * 3.14159);
	col *= 1.0 - scanline_amount * scan * scan;

	// Vineta.
	float vig = smoothstep(1.25, 0.25, edge * (1.0 + dread * 0.35));
	col *= mix(1.0, vig, clamp(vignette_amount, 0.0, 1.0));

	COLOR = vec4(clamp(col, vec3(0.0), vec3(1.0)), 1.0);
}
