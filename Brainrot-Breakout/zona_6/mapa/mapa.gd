extends Node2D

# Mapa de la Zona 6 «Supercomputadoras» (el cuarto del Núcleo-∞). Todo se dibuja con
# _draw() (placeholder): reemplaza cada bloque "REEMPLAZAR" por un Sprite2D en zona_6/assets/.
# Las colisiones NO se dibujan aquí: están en MapaZona6.tscn.
const COLOR_FONDO = Color(0.04, 0.05, 0.13)
const COLOR_GRILLA = Color(0.08, 0.1, 0.22)
const COLOR_RACK = Color(0.1, 0.12, 0.3)
const COLOR_BORDE_RACK = Color(0.3, 0.35, 0.8)
const COLOR_CARRIL = Color(0.8, 0.2, 0.7)

# Centros de los racks (deben coincidir con los StaticBody2D del .tscn)
const RACKS = [Vector2(110, 240), Vector2(110, 440), Vector2(310, 545), Vector2(700, 545), Vector2(1040, 205), Vector2(1040, 505)]
# Dígitos decorativos (posición fija, así no cambian en cada dibujo)
const DIGITOS = [Vector2(650, 130), Vector2(720, 150), Vector2(770, 125), Vector2(690, 205), Vector2(840, 135), Vector2(560, 400), Vector2(620, 430), Vector2(900, 440), Vector2(430, 200), Vector2(480, 330)]

func _draw():
	# REEMPLAZAR: fondo azul oscuro con cuadrícula
	draw_rect(Rect2(0, 0, 1152, 648), COLOR_FONDO)
	var x = 0.0
	while x <= 1152.0:
		draw_line(Vector2(x, 0), Vector2(x, 648), COLOR_GRILLA, 1.0)
		x += 48.0
	var y = 0.0
	while y <= 648.0:
		draw_line(Vector2(0, y), Vector2(1152, y), COLOR_GRILLA, 1.0)
		y += 48.0

	# REEMPLAZAR: líneas de circuito (decoración)
	draw_polyline(PackedVector2Array([Vector2(0, 330), Vector2(300, 330), Vector2(300, 250), Vector2(520, 250)]), Color(0.2, 0.3, 0.9), 3.0)
	draw_circle(Vector2(300, 330), 7.0, Color(0.3, 0.4, 1.0))
	draw_circle(Vector2(520, 250), 7.0, Color(0.3, 0.4, 1.0))
	draw_line(Vector2(260, 240), Vector2(700, 240), Color(0.3, 0.7, 1.0, 0.5), 2.0)
	draw_line(Vector2(260, 400), Vector2(700, 400), Color(0.3, 0.7, 1.0, 0.5), 2.0)

	# REEMPLAZAR: carriles magenta verticales (decoración)
	for cx in [320, 420, 520, 620]:
		var cy = 80.0
		while cy < 648.0:
			draw_line(Vector2(cx, cy), Vector2(cx, cy + 18), COLOR_CARRIL, 4.0)
			cy += 28.0

	# REEMPLAZAR: dígitos 0/1 flotando
	for i in range(DIGITOS.size()):
		var texto = "101"
		if i % 2 == 1:
			texto = "011"
		draw_string(ThemeDB.fallback_font, DIGITOS[i], texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.3, 1, 0.6, 0.55))

	# REEMPLAZAR: racks de servidores 72x130 (colisión 64x122)
	for c in RACKS:
		draw_rect(Rect2(c - Vector2(36, 65), Vector2(72, 130)), COLOR_RACK)
		draw_rect(Rect2(c - Vector2(36, 65), Vector2(72, 130)), COLOR_BORDE_RACK, false, 3.0)
		for fila in range(7):
			var py = c.y - 50 + fila * 16.0
			draw_rect(Rect2(c.x - 26, py, 52, 8), Color(0.05, 0.06, 0.16))
			draw_circle(Vector2(c.x - 18, py + 4), 2.5, Color(0.3, 1, 0.9))
			draw_circle(Vector2(c.x - 8, py + 4), 2.5, Color(1, 0.3, 0.8))
