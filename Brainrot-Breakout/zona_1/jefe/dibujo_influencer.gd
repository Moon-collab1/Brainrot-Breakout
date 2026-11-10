extends Node2D

# Diseño del Influencer, dibujado por código (sin texturas): pelo morado, lentes, sudadera rosa
# y celular en la mano. Cabe dentro del aro del jefe (radio 70, se dibuja en jefe_influencer.gd).
# Va en un nodo hijo para que jefe_influencer.gd lo pueda teñir (aturdido) con su modulate.
const PIEL = Color(0.96, 0.74, 0.6)
const PIEL_SOMBRA = Color(0.83, 0.56, 0.44)
const ROSA = Color(0.97, 0.27, 0.63)
const ROSA_OSC = Color(0.68, 0.1, 0.4)
const PELO = Color(0.5, 0.25, 0.72)
const PELO_OSC = Color(0.32, 0.13, 0.48)
const CONTORNO = Color(0.14, 0.05, 0.2)

var caja_lente = StyleBoxFlat.new()
var caja_celular = StyleBoxFlat.new()

func _ready():
	caja_lente.bg_color = Color(0.1, 0.55, 0.8)
	caja_lente.border_color = CONTORNO
	caja_lente.set_border_width_all(2)
	caja_lente.set_corner_radius_all(4)
	caja_celular.bg_color = Color(0.07, 0.07, 0.15)
	caja_celular.border_color = Color(0.92, 0.92, 1.0)
	caja_celular.set_border_width_all(2)
	caja_celular.set_corner_radius_all(5)

func _process(_delta):
	# se balancea un poquito, como si respirara (no mueve las colisiones del jefe)
	position.y = sin(Time.get_ticks_msec() / 350.0) * 2.0

func _draw():
	# sombra en el piso
	draw_set_transform(Vector2(0, 64), 0.0, Vector2(1.0, 0.17))
	draw_circle(Vector2.ZERO, 54.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# pelo de atrás (melena hasta los hombros)
	draw_circle(Vector2(0, -30), 34.0, PELO_OSC)
	draw_rect(Rect2(-34, -30, 68, 32), PELO_OSC)

	# brazo izquierdo (el de la derecha de la pantalla es el del celular)
	draw_line(Vector2(-38, 12), Vector2(-50, 46), ROSA_OSC, 15.0)
	draw_line(Vector2(-38, 12), Vector2(-50, 46), ROSA, 11.0)
	draw_circle(Vector2(-50, 50), 6.5, PIEL)

	# cuello y sudadera
	draw_rect(Rect2(-10, -8, 20, 16), PIEL_SOMBRA)
	var cuerpo = PackedVector2Array([
		Vector2(-46, 64), Vector2(-44, 18), Vector2(-34, 6), Vector2(-12, 2),
		Vector2(12, 2), Vector2(34, 6), Vector2(44, 18), Vector2(46, 64)])
	draw_colored_polygon(cuerpo, ROSA)
	var contorno = cuerpo.duplicate()
	contorno.append(cuerpo[0])
	draw_polyline(contorno, ROSA_OSC, 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 2), Vector2(0, 22), Vector2(12, 2)]), PIEL_SOMBRA)
	draw_polyline(PackedVector2Array([Vector2(-14, 2), Vector2(0, 24), Vector2(14, 2)]), ROSA_OSC, 3.0)
	# cordones y bolsillo
	draw_line(Vector2(-6, 18), Vector2(-7, 36), Color(1, 1, 1), 2.5)
	draw_line(Vector2(6, 18), Vector2(7, 36), Color(1, 1, 1), 2.5)
	draw_circle(Vector2(-7, 37), 2.5, Color(1, 1, 1))
	draw_circle(Vector2(7, 37), 2.5, Color(1, 1, 1))
	draw_polyline(PackedVector2Array([Vector2(-22, 46), Vector2(-16, 57), Vector2(16, 57), Vector2(22, 46)]), ROSA_OSC, 2.5)

	# cabeza
	draw_circle(Vector2(0, -30), 27.0, PIEL)
	draw_arc(Vector2(0, -30), 27.0, 0.0, TAU, 40, CONTORNO, 2.0)
	# mechones laterales y flequillo
	draw_rect(Rect2(-33, -32, 9, 34), PELO)
	draw_rect(Rect2(24, -32, 9, 34), PELO)
	var pelo = PackedVector2Array()
	for i in range(17):
		var a = PI + PI * i / 16.0
		pelo.append(Vector2(cos(a) * 29.0, -31.0 + sin(a) * 29.0))
	for p in [Vector2(27, -33), Vector2(16, -40), Vector2(4, -34), Vector2(-8, -42), Vector2(-20, -35), Vector2(-28, -33)]:
		pelo.append(p)
	draw_colored_polygon(pelo, PELO)
	draw_arc(Vector2(0, -31), 22.0, PI * 1.15, PI * 1.55, 10, Color(1, 1, 1, 0.25), 3.0)

	# lentes de sol
	draw_style_box(caja_lente, Rect2(-23, -34, 20, 12))
	draw_style_box(caja_lente, Rect2(3, -34, 20, 12))
	draw_line(Vector2(-19, -31), Vector2(-12, -31), Color(1, 1, 1, 0.6), 2.0)
	draw_line(Vector2(7, -31), Vector2(14, -31), Color(1, 1, 1, 0.6), 2.0)
	draw_line(Vector2(-3, -30), Vector2(3, -30), CONTORNO, 2.5)
	draw_line(Vector2(-23, -30), Vector2(-29, -31), CONTORNO, 2.0)
	draw_line(Vector2(23, -30), Vector2(29, -31), CONTORNO, 2.0)
	# cachetes y sonrisa
	draw_circle(Vector2(-17, -15), 4.0, Color(1, 0.45, 0.55, 0.5))
	draw_circle(Vector2(17, -15), 4.0, Color(1, 0.45, 0.55, 0.5))
	draw_arc(Vector2(0, -19), 9.0, PI * 0.25, PI * 0.75, 10, Color(0.6, 0.1, 0.2), 2.5)

	# celular en alto (brazo derecho doblado)
	draw_style_box(caja_celular, Rect2(48, -42, 24, 46))
	draw_rect(Rect2(52, -37, 16, 34), Color(0.2, 0.35, 0.7, 0.55))
	draw_circle(Vector2(60, -32), 5.0, Color(1, 0.9, 0.3, 0.35))
	draw_circle(Vector2(60, -32), 3.0, Color(1, 0.9, 0.3))
	draw_line(Vector2(38, 12), Vector2(56, 30), ROSA_OSC, 15.0)
	draw_line(Vector2(56, 30), Vector2(60, 8), ROSA_OSC, 15.0)
	draw_line(Vector2(38, 12), Vector2(56, 30), ROSA, 11.0)
	draw_line(Vector2(56, 30), Vector2(60, 8), ROSA, 11.0)
	draw_circle(Vector2(60, 2), 7.0, PIEL)
