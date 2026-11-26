extends Node2D

# Diseño de la antena del Influencer: un mástil con una bola de luz y ondas de señal que laten.
# Mide unos 25 px de radio, igual que su colisión.
# La bola funciona como SEMÁFORO (los valores los pone jefe_influencer.gd):
#   ROJO = el jefe está tirando habilidades: no se le puede hacer daño.
#   AZUL = tiempo muerto o aturdido: ¡pégale ahora!

var azul = false          # true = azul (se le puede pegar), false = rojo
var por_cambiar = false   # true el último segundo antes de cambiar de color (parpadea)

func _process(_delta):
	queue_redraw()   # las ondas y la luz laten

func _draw():
	var pulso = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)
	# color del semáforo
	var color = Color(0.95, 0.15, 0.2)       # rojo
	if azul:
		color = Color(0.25, 0.65, 1.0)       # azul
	# parpadeo rápido cuando está por cambiar de color
	var alfa = 1.0
	if por_cambiar and sin(Time.get_ticks_msec() / 60.0) < 0.0:
		alfa = 0.35
	# mástil y base
	draw_line(Vector2(0, 6), Vector2(0, 20), Color(0.18, 0.18, 0.26), 6.0)
	draw_line(Vector2(0, 6), Vector2(0, 20), Color(0.6, 0.62, 0.75), 3.0)
	draw_rect(Rect2(-9, 19, 18, 4), Color(0.18, 0.18, 0.26))
	# resplandor grande alrededor (se ve de lejos): más fuerte en azul
	var brillo = 0.18
	if azul:
		brillo = 0.3 + 0.15 * pulso
	draw_circle(Vector2(0, -4), 24.0, Color(color.r, color.g, color.b, brillo * alfa))
	# ondas de señal del color del semáforo (la de afuera se apaga cuando la de adentro brilla)
	draw_arc(Vector2(0, -4), 16.0, deg_to_rad(-150), deg_to_rad(-30), 12, Color(color.r, color.g, color.b, (0.4 + 0.6 * pulso) * alfa), 3.0)
	draw_arc(Vector2(0, -4), 22.0, deg_to_rad(-150), deg_to_rad(-30), 14, Color(color.r, color.g, color.b, (1.0 - 0.6 * pulso) * alfa), 3.0)
	# bola del semáforo con borde oscuro y un brillito blanco
	draw_circle(Vector2(0, -4), 11.0, Color(0.1, 0.1, 0.14))
	draw_circle(Vector2(0, -4), 9.0, Color(color.r, color.g, color.b, alfa))
	draw_circle(Vector2(-3, -7), 2.5, Color(1, 1, 1, 0.8 * alfa))
