extends Node2D

# Mapa de la Zona 5 «Laboratorio Secreto». Todo se dibuja con _draw() (placeholder):
# reemplaza cada bloque "REEMPLAZAR" por un Sprite2D en zona_5/assets/.
# Las colisiones NO se dibujan aquí: están en MapaZona5.tscn.
const PISO_Y = 124.0
const BALDOSA = 64.0
const COLOR_PARED = Color(0.14, 0.2, 0.24)
const COLOR_BALDOSA_A = Color(0.88, 0.95, 0.95)
const COLOR_BALDOSA_B = Color(0.78, 0.88, 0.88)
const COLOR_NEON = Color(0.2, 0.9, 0.5)
const COLOR_MESA = Color(0.45, 0.55, 0.6)

# Centros de las mesas (deben coincidir con los StaticBody2D del .tscn)
const MESAS = [Vector2(240, 250), Vector2(240, 470), Vector2(600, 560), Vector2(900, 530)]
const TUBOS = [Vector2(70, 60), Vector2(260, 60), Vector2(450, 60), Vector2(640, 60), Vector2(830, 60), Vector2(1020, 60)]

func _draw():
	# REEMPLAZAR: pared del fondo con tubos de cultivo (cerebros en frascos)
	draw_rect(Rect2(0, 0, 1152, PISO_Y), COLOR_PARED)
	for c in TUBOS:
		draw_rect(Rect2(c - Vector2(35, 50), Vector2(70, 100)), Color(0.35, 0.6, 0.7, 0.55))
		draw_rect(Rect2(c - Vector2(35, 50), Vector2(70, 100)), Color(0.6, 0.85, 0.9), false, 2.0)
		draw_circle(c + Vector2(0, 5), 18.0, Color(0.95, 0.5, 0.65))
		draw_circle(c + Vector2(-6, 0), 3.0, Color(0.2, 0.1, 0.15))
		draw_circle(c + Vector2(6, 0), 3.0, Color(0.2, 0.1, 0.15))
	# franja verde neón entre la pared y el piso
	draw_rect(Rect2(0, PISO_Y - 12, 1152, 12), COLOR_NEON)

	# REEMPLAZAR: piso de baldosas en tablero de ajedrez
	var y = PISO_Y
	var fila = 0
	while y < 648.0:
		var x = 0.0
		var col = 0
		while x < 1152.0:
			var color = COLOR_BALDOSA_A
			if (fila + col) % 2 == 1:
				color = COLOR_BALDOSA_B
			draw_rect(Rect2(x, y, BALDOSA, BALDOSA), color)
			x += BALDOSA
			col += 1
		y += BALDOSA
		fila += 1

	# REEMPLAZAR: mesas de laboratorio 170x70 (colisión 162x62)
	for c in MESAS:
		draw_rect(Rect2(c - Vector2(85, 35), Vector2(170, 70)), COLOR_MESA)
		draw_rect(Rect2(c - Vector2(85, 35), Vector2(170, 70)), Color(0.25, 0.3, 0.33), false, 3.0)
		draw_rect(Rect2(c + Vector2(-70, -18), Vector2(14, 34)), Color(0.2, 0.85, 0.5))
		draw_rect(Rect2(c + Vector2(-46, -18), Vector2(14, 34)), Color(1, 0.3, 0.45))
		draw_circle(c + Vector2(40, 0), 17.0, Color(0.4, 0.8, 1.0))
