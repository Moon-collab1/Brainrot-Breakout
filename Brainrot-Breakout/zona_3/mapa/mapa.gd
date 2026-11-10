extends Node2D

# Mapa de la Zona 3 «Zona de Carga» (un almacén). Todo se dibuja con _draw() (placeholder):
# para usar PNG reales, reemplaza cada bloque marcado con "REEMPLAZAR" por un Sprite2D
# en zona_3/assets/. Las colisiones NO se dibujan aquí: están en MapaZona3.tscn.

# --- Colores y medidas (todo se ajusta aquí) ---
const PISO_Y = 124.0          # el piso empieza aquí; arriba está la pared del fondo
const BALDOSA = 72.0          # tamaño de cada cuadro del piso
const COLOR_PARED = Color(0.16, 0.15, 0.14)
const COLOR_PISO = Color(0.2, 0.2, 0.21)
const COLOR_LINEA = Color(0.26, 0.26, 0.28)
const COLOR_AMARILLO = Color(0.95, 0.75, 0.15)   # franjas de seguridad
const COLOR_NEGRO = Color(0.08, 0.08, 0.09)
const COLOR_CAJA = Color(0.62, 0.42, 0.22)
const COLOR_ESTANTE = Color(0.3, 0.38, 0.55)
const COLOR_PILAR = Color(0.55, 0.55, 0.58)

# Centros de los objetos (deben coincidir con los StaticBody2D de MapaZona3.tscn)
const CAJAS = [Vector2(240, 250), Vector2(240, 480), Vector2(520, 560), Vector2(900, 200), Vector2(880, 490)]
const ESTANTES = [Vector2(600, 175)]
const PILARES = [Vector2(96, 200), Vector2(1056, 200)]

# _draw() se llama sola una vez; dibuja el mapa completo con rectángulos y círculos
func _draw():
	# REEMPLAZAR: pared del fondo con ventanas (arriba del piso)
	draw_rect(Rect2(0, 0, 1152, PISO_Y), COLOR_PARED)
	for i in range(8):
		draw_rect(Rect2(40 + i * 140.0, 30, 90, 46), Color(0.1, 0.12, 0.18))
		draw_rect(Rect2(46 + i * 140.0, 36, 78, 34), Color(0.25, 0.32, 0.45))

	# REEMPLAZAR: piso de baldosas
	draw_rect(Rect2(0, PISO_Y, 1152, 648 - PISO_Y), COLOR_PISO)
	var x = 0.0
	while x <= 1152.0:
		draw_line(Vector2(x, PISO_Y), Vector2(x, 648), COLOR_LINEA, 2.0)
		x += BALDOSA
	var y = PISO_Y
	while y <= 648.0:
		draw_line(Vector2(0, y), Vector2(1152, y), COLOR_LINEA, 2.0)
		y += BALDOSA

	# REEMPLAZAR: pasillo central amarillo y negro (por aquí embiste el Capataz)
	var carril_y = 324.0
	for k in range(0, 1152, 48):
		var color = COLOR_AMARILLO
		if (k / 48) % 2 == 1:
			color = COLOR_NEGRO
		draw_rect(Rect2(k, carril_y - 78, 48, 6), color)
		draw_rect(Rect2(k, carril_y + 72, 48, 6), color)

	# REEMPLAZAR: cajas de cartón 80x80 (colisión 76x76 en el .tscn)
	for c in CAJAS:
		draw_rect(Rect2(c - Vector2(40, 40), Vector2(80, 80)), COLOR_CAJA)
		draw_rect(Rect2(c - Vector2(40, 40), Vector2(80, 80)), COLOR_CAJA.darkened(0.35), false, 3.0)
		draw_line(c + Vector2(-40, 0), c + Vector2(40, 0), COLOR_CAJA.darkened(0.35), 3.0)
		draw_line(c + Vector2(0, -40), c + Vector2(0, 40), COLOR_CAJA.darkened(0.35), 3.0)

	# REEMPLAZAR: estantes 160x40 (colisión 152x32)
	for c in ESTANTES:
		draw_rect(Rect2(c - Vector2(80, 20), Vector2(160, 40)), COLOR_ESTANTE)
		draw_rect(Rect2(c - Vector2(80, 20), Vector2(160, 8)), COLOR_ESTANTE.lightened(0.25))

	# REEMPLAZAR: pilares (diámetro 48, colisión círculo r=22)
	for c in PILARES:
		draw_circle(c, 24.0, COLOR_PILAR)
		draw_circle(c, 14.0, COLOR_PILAR.lightened(0.25))
