extends Control

# Borde punteado con esquinas redondeadas (marca el hueco donde irá la imagen del celular).
# Se dibuja con _draw() y no atrapa el mouse.
const RADIO = 14.0
const RAYA = 7.0
const HUECO = 5.0
const GROSOR = 2.0
const COLOR = Color(0.82, 0.83, 0.86, 0.85)

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw():
	var a = GROSOR * 0.5
	var l = a
	var r = size.x - a
	var t = a
	var b = size.y - a
	# lados rectos con rayitas
	raya_linea(Vector2(l + RADIO, t), Vector2(r - RADIO, t))
	raya_linea(Vector2(r, t + RADIO), Vector2(r, b - RADIO))
	raya_linea(Vector2(r - RADIO, b), Vector2(l + RADIO, b))
	raya_linea(Vector2(l, b - RADIO), Vector2(l, t + RADIO))
	# esquinas
	draw_arc(Vector2(r - RADIO, t + RADIO), RADIO, deg_to_rad(270), deg_to_rad(360), 8, COLOR, GROSOR)
	draw_arc(Vector2(r - RADIO, b - RADIO), RADIO, deg_to_rad(0), deg_to_rad(90), 8, COLOR, GROSOR)
	draw_arc(Vector2(l + RADIO, b - RADIO), RADIO, deg_to_rad(90), deg_to_rad(180), 8, COLOR, GROSOR)
	draw_arc(Vector2(l + RADIO, t + RADIO), RADIO, deg_to_rad(180), deg_to_rad(270), 8, COLOR, GROSOR)

func raya_linea(desde, hasta):
	var largo = desde.distance_to(hasta)
	var dir = (hasta - desde).normalized()
	var pos = 0.0
	while pos < largo:
		var fin = min(pos + RAYA, largo)
		draw_line(desde + dir * pos, desde + dir * fin, COLOR, GROSOR)
		pos += RAYA + HUECO
