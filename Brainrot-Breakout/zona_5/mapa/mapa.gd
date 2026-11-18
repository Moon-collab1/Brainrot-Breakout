extends Node2D

# Mapa de la Zona 5 «Laboratorio Secreto». Fondo: zona_5/assets/laboratorio.png (generado con
# las mesas en las posiciones de abajo); cerebros y burbujas de los tanques se animan aquí.
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

const FONDO = preload("res://zona_5/assets/laboratorio.png")   # pared, tanques, piso y mesas ya dibujados

func _process(_delta):
	queue_redraw()   # cerebros flotando y burbujas en los tanques

func _draw():
	draw_texture(FONDO, Vector2.ZERO)
	var t = Time.get_ticks_msec() / 1000.0
	for i in range(TUBOS.size()):
		var c = TUBOS[i]
		# cerebro flotando dentro del tanque
		var p = c + Vector2(sin(t * 1.3 + i) * 4.0, sin(t * 2.0 + i * 1.7) * 6.0)
		draw_circle(p, 17.0, Color(0.95, 0.5, 0.65))
		draw_arc(p, 17.0, 0.0, TAU, 24, Color(0.7, 0.25, 0.4), 2.0)
		draw_line(p + Vector2(0, -16), p + Vector2(0, 16), Color(0.7, 0.25, 0.4), 1.5)
		draw_arc(p + Vector2(-7, -3), 6.0, PI, TAU, 8, Color(0.7, 0.25, 0.4), 1.5)
		draw_arc(p + Vector2(7, 4), 6.0, 0.0, PI, 8, Color(0.7, 0.25, 0.4), 1.5)
		draw_circle(p + Vector2(-6, -1), 2.5, Color(0.2, 0.1, 0.15))
		draw_circle(p + Vector2(6, -1), 2.5, Color(0.2, 0.1, 0.15))
		# burbujas que suben
		for k in range(4):
			var u = fmod(t * 0.6 + k * 0.25 + i * 0.13, 1.0)
			var b = c + Vector2(-20 + k * 13 + sin(t * 3.0 + k) * 3.0, 38 - u * 76)
			draw_arc(b, 2.5 + (k % 2), 0.0, TAU, 10, Color(0.85, 1, 0.95, 0.8 * (1.0 - u)), 1.2)
