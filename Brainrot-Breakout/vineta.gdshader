shader_type canvas_item;

uniform sampler2D pantalla : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 centro = vec2(0.5, 0.5);   // dónde está el jugador en la pantalla (0 a 1)
uniform float aspecto = 1.78;
uniform float fuerza = 0.0;             // 0 = sin efecto, 1 = efecto completo
uniform float radio_claro = 0.20;       // zona nítida alrededor del jugador
uniform float radio_borroso = 0.60;     // desde aquí todo está bien borroso
uniform float oscuro = 0.35;            // qué tanto se oscurece la orilla

void fragment() {
	vec2 uv = SCREEN_UV;
	float d = length((uv - centro) * vec2(aspecto, 1.0));
	float m = smoothstep(radio_claro, radio_borroso, d) * fuerza;
	vec3 suma = textureLod(pantalla, uv, 0.0).rgb;
	float pesos = 1.0;
	for (int i = 0; i < 8; i++) {
		float ang = float(i) * 0.785398;
		vec2 dir = vec2(cos(ang) / aspecto, sin(ang));
		suma += textureLod(pantalla, uv + dir * m * 0.012, 0.0).rgb;
		suma += textureLod(pantalla, uv + dir * m * 0.024, 0.0).rgb;
		pesos += 2.0;
	}
	vec3 col = suma / pesos;
	col *= 1.0 - m * oscuro;
	COLOR = vec4(col, 1.0);
}