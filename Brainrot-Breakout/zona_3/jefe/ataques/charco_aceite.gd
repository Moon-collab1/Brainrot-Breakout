extends Node2D

# Charco de aceite del Capataz: una mancha redonda en el piso que FRENA al jugador.
# No quita vida. Sirve para que esquivar las cajas sea más difícil.
#   1. AVISO: se ve el borde del charco (todavía no frena).
#   2. ACTIVO: mientras el jugador esté dentro, se mueve más lento.
#   3. Al pasar "duracion" segundos se borra solo.
# Usa las mismas variables del jugador que el Shadowban de la Zona 2 (mult_vel y lento_t).

var radio = 90.0      # tamaño del charco (el jefe lo pone)
var aviso = 0.8       # segundos de aviso antes de frenar
var duracion = 6.0    # segundos que dura activo
var mult = 0.5        # velocidad del jugador dentro (0.5 = la mitad)
var t = 0.0

func _ready():
	add_to_group("franjas")   # si el jefe muere, oleadas.gd borra todo este grupo

func _process(delta):
	t += delta
	if t >= aviso + duracion:
		queue_free()
		return
	if t >= aviso:
		var jug = get_parent().get_node("Jugador")
		if jug.global_position.distance_to(global_position) <= radio:
			jug.mult_vel = mult
			jug.lento_t = 0.1   # jugador.gd quita la lentitud solo si dejamos de renovarla
	queue_redraw()

# Placeholder dibujado: mancha oscura con brillo. Reemplazar por un sprite si se quiere.
func _draw():
	if t < aviso:
		# aviso: solo el borde, parpadeando
		var pulso = 0.4 + 0.3 * sin(t * 14.0)
		draw_arc(Vector2.ZERO, radio, 0.0, TAU, 40, Color(0.9, 0.75, 0.2, pulso), 4.0)
		return
	# los últimos 1,5 s se va borrando para avisar que se acaba
	var alfa = clamp((aviso + duracion - t) / 1.5, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radio, Color(0.07, 0.06, 0.1, 0.75 * alfa))
	draw_circle(Vector2(-radio * 0.25, -radio * 0.2), radio * 0.45, Color(0.16, 0.13, 0.22, 0.6 * alfa))
	draw_circle(Vector2(radio * 0.3, radio * 0.25), radio * 0.2, Color(0.5, 0.45, 0.7, 0.35 * alfa))
	draw_arc(Vector2.ZERO, radio, 0.0, TAU, 40, Color(0.9, 0.75, 0.2, 0.6 * alfa), 2.0)
