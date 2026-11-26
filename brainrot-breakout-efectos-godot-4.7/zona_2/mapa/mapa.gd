extends Node2D

# Mapa de la Zona 2 «Edificio Social». Fondo: zona_2/assets/edificio.png (generado con los
# sofás y macetas en las posiciones de abajo); las pantallas se animan aquí. Las colisiones NO se dibujan aquí: están en MapaZona2.tscn.
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

const FONDO = preload("res://zona_2/assets/edificio.png")   # ciudad, sofás, alfombras y macetas ya dibujados
const COLORES_POST = [Color(0.95, 0.3, 0.6), Color(0.3, 0.75, 0.95), Color(0.95, 0.75, 0.25), Color(0.6, 0.4, 1.0)]

func _process(_delta):
	queue_redraw()   # las pantallas gigantes pasan publicaciones

func _draw():
	draw_texture(FONDO, Vector2.ZERO)
	# pantallas gigantes: un feed infinito que se desliza (el «scroll» del que te liberas)
	var t = Time.get_ticks_msec() / 1000.0
	for i in range(PANTALLAS.size()):
		var c = PANTALLAS[i]
		var area = Rect2(c - Vector2(104, 37), Vector2(208, 74))
		var off = fmod(t * 40.0 + i * 37.0, 70.0)
		for k in range(4):
			var x = area.position.x + k * 70.0 - off
			var r = Rect2(Vector2(x + 4, area.position.y + 6), Vector2(60, 50)).intersection(area)
			if r.size.x > 2:
				draw_rect(r, COLORES_POST[(k + i + int((t * 40.0 + i * 37.0) / 70.0)) % 4])
		# barra de likes que late
		var pulso = 0.5 + 0.5 * sin(t * 4.0 + i)
		draw_rect(Rect2(area.position + Vector2(6, 60), Vector2(196 * (0.3 + 0.7 * pulso), 8)), Color(1, 0.35, 0.6, 0.9))
		draw_circle(area.position + Vector2(196, 64), 6.0, Color(1, 0.3, 0.5))
