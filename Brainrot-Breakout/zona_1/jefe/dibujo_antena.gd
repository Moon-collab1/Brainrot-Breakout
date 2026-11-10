extends Node2D

# Diseño de la antena del Influencer: un mástil con una luz de "grabando" (tipo transmisión en
# vivo) y ondas de señal que laten. Mide unos 25 px de radio, igual que su colisión.
func _process(_delta):
	queue_redraw()   # las ondas y la luz laten

func _draw():
	var pulso = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)
	# mástil y base
	draw_line(Vector2(0, 6), Vector2(0, 20), Color(0.18, 0.18, 0.26), 6.0)
	draw_line(Vector2(0, 6), Vector2(0, 20), Color(0.6, 0.62, 0.75), 3.0)
	draw_rect(Rect2(-9, 19, 18, 4), Color(0.18, 0.18, 0.26))
	# ondas de señal (la de afuera se apaga cuando la de adentro brilla)
	var onda = Color(1.0, 0.9, 0.3)
	draw_arc(Vector2(0, -4), 16.0, deg_to_rad(-150), deg_to_rad(-30), 12, Color(onda.r, onda.g, onda.b, 0.4 + 0.6 * pulso), 3.0)
	draw_arc(Vector2(0, -4), 22.0, deg_to_rad(-150), deg_to_rad(-30), 14, Color(onda.r, onda.g, onda.b, 1.0 - 0.6 * pulso), 3.0)
	# bola dorada con luz roja de "en vivo"
	draw_circle(Vector2(0, -4), 10.0, Color(0.35, 0.2, 0.0))
	draw_circle(Vector2(0, -4), 8.0, Color(1.0, 0.85, 0.2))
	draw_circle(Vector2(-2.5, -6.5), 2.5, Color(1, 1, 1, 0.8))
	draw_circle(Vector2(0, -4), 3.5, Color(0.9, 0.1, 0.2, 0.5 + 0.5 * pulso))
