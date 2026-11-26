extends Node2D

# Mapa de la Zona 1 «Calle». Todo se dibuja con _draw() (placeholder), igual que la Zona 2:
# para usar PNG reales, reemplaza cada bloque marcado con "REEMPLAZAR" por un Sprite2D
# en zona_1/assets/. Las colisiones NO se dibujan aquí: están en Mapa.tscn.
const ACERA_ALTO = 104.0       # acera de arriba: y = 0 a 104; acera de abajo: y = 544 a 648
const BORDILLO_ALTO = 8.0
const CALZADA_ARRIBA = 112.0
const CALZADA_ABAJO = 536.0
const BALDOSA = 64.0

const COLOR_ACERA = Color(0.56, 0.57, 0.6)
const COLOR_JUNTA = Color(0.47, 0.48, 0.51)
const COLOR_BORDILLO = Color(0.79, 0.8, 0.82)
const COLOR_CALZADA = Color(0.23, 0.24, 0.28)
const COLOR_RAYA = Color(0.95, 0.79, 0.3)
const COLOR_CEBRA = Color(0.8, 0.81, 0.84)
const COLOR_CONTORNO = Color(0.07, 0.07, 0.07)
const COLOR_FARO = Color(1.0, 0.96, 0.63)
const COLOR_BASURERO = Color(0.18, 0.435, 0.243)
const COLOR_BASURERO_BORDE = Color(0.12, 0.31, 0.17)
const COLOR_TAPA = Color(0.24, 0.54, 0.31)

# Centros de los sprites (deben coincidir con los StaticBody2D de Mapa.tscn)
# "mira": -1 = el auto mira a la izquierda, 1 = a la derecha (de ahí salen los faros)
const AUTOS = [
	{"pos": Vector2(210, 190), "color": Color(0.894, 0.341, 0.18), "cristal": Color(0.77, 0.82, 0.88), "mira": -1},
	{"pos": Vector2(130, 480), "color": Color(0.95, 0.79, 0.3), "cristal": Color(0.78, 0.89, 0.91), "mira": -1},
	{"pos": Vector2(870, 480), "color": Color(0.18, 0.525, 0.894), "cristal": Color(0.67, 0.85, 0.98), "mira": 1},
]
const BASUREROS = [Vector2(792, 174), Vector2(352, 545)]
const FAROLAS = [Vector2(63, 22), Vector2(704, 22), Vector2(1004, 22)]

func _draw():
	# REEMPLAZAR: aceras (arriba y abajo) con baldosas de 64 px
	for y0 in [0.0, CALZADA_ABAJO + BORDILLO_ALTO]:
		draw_rect(Rect2(0, y0, 1152, ACERA_ALTO), COLOR_ACERA)
		var x = BALDOSA
		while x < 1152.0:
			draw_line(Vector2(x, y0), Vector2(x, y0 + ACERA_ALTO), COLOR_JUNTA, 2.0)
			x += BALDOSA

	# REEMPLAZAR: bordillos y calzada
	draw_rect(Rect2(0, ACERA_ALTO, 1152, BORDILLO_ALTO), COLOR_BORDILLO)
	draw_rect(Rect2(0, CALZADA_ABAJO, 1152, BORDILLO_ALTO), COLOR_BORDILLO)
	draw_rect(Rect2(0, CALZADA_ARRIBA, 1152, CALZADA_ABAJO - CALZADA_ARRIBA), COLOR_CALZADA)

	# REEMPLAZAR: línea amarilla discontinua (rayas de 70 px cada 120 px)
	var rx = 10.0
	while rx < 1152.0:
		draw_rect(Rect2(rx, 319, 70, 10), COLOR_RAYA)
		rx += 120.0

	# REEMPLAZAR: paso de cebra (6 franjas de 28 px que cruzan la calle de arriba a abajo)
	for i in range(6):
		draw_rect(Rect2(400 + i * 40, 120, 28, 408), COLOR_CEBRA)

	for a in AUTOS:
		dibujar_auto(a)
	for c in BASUREROS:
		dibujar_basurero(c)
	for c in FAROLAS:
		dibujar_farola(c)

# Rectángulo con esquinas redondeadas (y borde opcional)
func caja(rect, relleno, radio, borde_color = Color(0, 0, 0, 0), borde = 0):
	var s = StyleBoxFlat.new()
	s.bg_color = relleno
	s.set_corner_radius_all(radio)
	if borde > 0:
		s.border_color = borde_color
		s.set_border_width_all(borde)
	draw_style_box(s, rect)

# REEMPLAZAR: auto 142x66 (colisión 134x54 en el .tscn)
func dibujar_auto(a):
	var c = a["pos"]
	var m = a["mira"]
	caja(Rect2(c - Vector2(71, 33), Vector2(142, 66)), a["color"], 16, COLOR_CONTORNO, 3)
	caja(Rect2(c + Vector2(-32, -26), Vector2(64, 52)), a["cristal"], 9)
	# dos faros del lado hacia donde mira
	for dy in [-22.0, 6.0]:
		caja(Rect2(c + Vector2(m * 55.0 - 7.0, dy), Vector2(14, 10)), COLOR_FARO, 3)

# REEMPLAZAR: basurero con tapa (colisión 66x42 en el .tscn)
func dibujar_basurero(c):
	caja(Rect2(c + Vector2(-33, -19), Vector2(66, 50)), COLOR_BASURERO, 6, COLOR_BASURERO_BORDE, 2)
	caja(Rect2(c + Vector2(-36, -31), Vector2(72, 12)), COLOR_TAPA, 4)

# REEMPLAZAR: farola (sin colisión): halo de luz, poste hasta el bordillo y foco
func dibujar_farola(c):
	draw_circle(c, 44.0, Color(1.0, 0.9, 0.5, 0.14))
	draw_rect(Rect2(c.x - 3.0, c.y, 6.0, ACERA_ALTO - 2.0 - c.y), Color(0.09, 0.09, 0.08))
	draw_circle(c, 14.0, Color(1.0, 0.87, 0.42))
