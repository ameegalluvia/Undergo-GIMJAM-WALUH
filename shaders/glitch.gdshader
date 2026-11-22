shader_type canvas_item;

uniform sampler2D layar : hint_screen_texture, filter_nearest, repeat_disable;
uniform float intensitas : hint_range(0.0, 1.0) = 0.0;
uniform float benih = 0.0;

float acak(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// 1. Irisan layar bergeser (blok tebal dan tipis)
	float blok_besar = floor(uv.y * 8.0);
	float blok_kecil = floor(uv.y * 60.0);

	float aktif_besar = step(0.5, acak(vec2(blok_besar, benih)));
	float aktif_kecil = step(0.8, acak(vec2(blok_kecil, benih + 3.0)));

	float geser_besar = (acak(vec2(blok_besar, benih + 7.0)) - 0.5) * 0.6;
	float geser_kecil = (acak(vec2(blok_kecil, benih + 9.0)) - 0.5) * 0.35;

	uv.x += (geser_besar * aktif_besar + geser_kecil * aktif_kecil) * intensitas;

	// Jaga uv tetap di dalam layar supaya tidak muncul area kosong
	uv = clamp(uv, vec2(0.0), vec2(1.0));

	// 2. RGB split besar
	float pisah = 0.045 * intensitas;
	float r = texture(layar, clamp(uv + vec2(pisah, pisah * 0.3), vec2(0.0), vec2(1.0))).r;
	float g = texture(layar, uv).g;
	float b = texture(layar, clamp(uv - vec2(pisah, pisah * 0.3), vec2(0.0), vec2(1.0))).b;
	vec3 warna = vec3(r, g, b);

	// 3. Scanline
	float garis = sin(SCREEN_UV.y * 900.0) * 0.5 + 0.5;
	warna *= 1.0 - garis * 0.35 * intensitas;

	// 4. Noise statis (halus)
	float noise = acak(SCREEN_UV * 500.0 + benih);
	warna = mix(warna, vec3(noise), 0.1 * intensitas);

	COLOR = vec4(warna, 1.0);
}