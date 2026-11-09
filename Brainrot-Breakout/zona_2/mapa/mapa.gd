extends Node2D

# Mapa de la Zona 2 «Edificio Social». Todo se dibuja con _draw() (placeholder):
# para usar PNG reales, reemplaza cada bloque marcado con "REEMPLAZAR" por un Sprite2D
# en zona_2/assets/. Las colisiones NO se dibujan aquí: están en MapaZona2.tscn.
const PISO_Y = 124.0     # el piso empieza aquí; arriba hay edificios y pantallas
const BALDOSA = 72.0
const COLOR_PISO = Color(0.13, 0.14, 0.28)
const COLOR_LINEA = Color(0.17, 0.18, 0.34)
const COLOR_FONDO = Color(0.07, 0.07, 0.15)
const COLOR_EDIFICIO = Color(0.13, 0.14, 0.27)
const COLOR_BORDE_PANTALLA = Color(0.45, 0.3, 1.0)
const COLOR_SOFA = Color(0.47, 0.35, 0.2)
const COLOR_MACETA = Color(0.15, 0.55, 0.25)

# Centros de los sprites (deben coincidir con los StaticBody2D del .tscn)
const SOFAS = [Vector2(245, 262), Vector2(245, 462), Vector2(545, 572), Vector2(855, 472)]
const MACETAS = [Vector2(60, 330), Vector2(1092, 330)]
const PANTALLAS = [Vector2(200, 65), Vector2(580, 65), Vector2(960, 65)]
const ALTURAS = [90, 70, 110, 80, 100, 65, 95, 85, 105, 75, 90, 100]

func _draw():
	# REEMPLAZAR: fondo de edificios (arriba del piso)
	draw_rect(Rect2(0, 0, 1152, PISO_Y), COLOR_FONDO)
	for i in range(ALTURAS.size()):
		var h = ALTURAS[i]
		draw_rect(Rect2(i * 96.0, PISO_Y - h, 94, h), COLOR_EDIFICIO)
		for fx in range(3):
			for fy in range(int(h / 24.0) - 1):
				var luz = Color(0.85, 0.7, 0.25) if (i + fx + fy) % 3 == 0 else Color(0.08, 0.09, 0.2)
				draw_rect(Rect2(i * 96.0 + 12 + fx * 28, PISO_Y - h + 8 + fy * 24, 12, 14), luz)

	# REEMPLAZAR: piso de baldosas de 72 px
	draw_rect(Rect2(0, PISO_Y, 1152, 648 - PISO_Y), COLOR_PISO)
	var x = 0.0
	while x <= 1152.0:
		draw_line(Vector2(x, PISO_Y), Vector2(x, 648), COLOR_LINEA, 2.0)
		x += BALDOSA
	var y = PISO_Y
	while y <= 648.0:
		draw_line(Vector2(0, y), Vector2(1152, y), COLOR_LINEA, 2.0)
		y += BALDOSA

	# REEMPLAZAR: 3 pantallas decorativas (sin colisión), 224x90
	for c in PANTALLAS:
		draw_rect(Rect2(c - Vector2(112, 45), Vector2(224, 90)), COLOR_BORDE_PANTALLA)
		draw_rect(Rect2(c - Vector2(106, 39), Vector2(212, 78)), Color(0.05, 0.05, 0.12))
		draw_rect(Rect2(c + Vector2(-96, -29), Vector2(60, 58)), Color(0.85, 0.25, 0.55))
		draw_rect(Rect2(c + Vector2(-28, -29), Vector2(60, 58)), Color(0.3, 0.7, 0.85))
		draw_rect(Rect2(c + Vector2(40, -29), Vector2(56, 58)), Color(0.85, 0.7, 0.25))

	# REEMPLAZAR: sofás 154x68 (colisión 146x56 en el .tscn)
	for c in SOFAS:
		draw_rect(Rect2(c - Vector2(77, 34), Vector2(154, 68)), COLOR_SOFA)
		draw_rect(Rect2(c - Vector2(77, 34), Vector2(154, 14)), COLOR_SOFA.darkened(0.25))
		draw_rect(Rect2(c + Vector2(-62, -16), Vector2(58, 36)), Color(0.3, 0.8, 1.0))
		draw_rect(Rect2(c + Vector2(4, -16), Vector2(58, 36)), Color(1.0, 0.3, 0.6))

	# REEMPLAZAR: macetas (diámetro 48, colisión círculo r=22)
	for c in MACETAS:
		draw_circle(c, 24.0, COLOR_MACETA)
		draw_circle(c, 14.0, COLOR_MACETA.lightened(0.3))
