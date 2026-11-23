shader_type canvas_item;

uniform float kekuatan : hint_range(0.0, 1.0) = 0.0;   // 0 = tanpa vignette, 1 = sangat gelap
uniform float radius : hint_range(0.1, 1.5) = 0.75;     // makin kecil, lingkaran terang makin sempit
uniform float kelembutan : hint_range(0.05, 1.0) = 0.5;

void fragment() {
	vec2 pusat = SCREEN_UV - vec2(0.5);
	pusat.x *= 1.3;   // sedikit lonjong mengikuti layar lebar
	float jarak = length(pusat);
	float gelap = smoothstep(radius - kelembutan, radius, jarak);
	COLOR = vec4(0.0, 0.0, 0.0, gelap * kekuatan);
}