extends Node2D

# Mini-cerebro mutante de «Cerebros mutantes». Rápido: va directo hacia el jugador y EXPLOTA
# al tocarlo (daña y sube la dopamina). Grupos: "destruibles" (la cachetada lo revienta sin
# sumar a «Liberados») y "proyectiles" (si el jefe se aturde, se borra).
const RADIO = 16.0
const RADIO_JUGADOR = 20.0

var vel = 240.0       # px/s (el jefe lo pone)
var dano = 10.0       # vida al explotar (el jefe lo pone)
var dopa = 8.0        # dopamina al explotar (el jefe lo pone)
var vida_util = 7.0   # segundos antes de desaparecer solo
var t = 0.0

func _ready():
	add_to_group("destruibles")
	add_to_group("proyectiles")

func _process(delta):
	t += delta
	if t >= vida_util:
		queue_free()
		return
	var jug = get_parent().get_node("Jugador")
	var dir = (jug.global_position - global_position).normalized()
	global_position += dir * vel * delta
	# explota al tocar al jugador
	if global_position.distance_to(jug.global_position) <= RADIO + RADIO_JUGADOR:
		jug.vida -= dano
		jug.dopa += dopa
		queue_free()
		return
	queue_redraw()

# La llama jugador.dar_cachetada()
func reventar():
	queue_free()

# Placeholder dibujado: reemplazar por el sprite real del cerebro
func _draw():
	draw_circle(Vector2.ZERO, RADIO, Color(0.95, 0.45, 0.6))
	draw_arc(Vector2.ZERO, RADIO, 0.0, TAU, 20, Color(1, 0.75, 0.8), 2.0)
	draw_line(Vector2(0, -RADIO + 3), Vector2(0, RADIO - 3), Color(0.7, 0.2, 0.35), 2.0)
	draw_circle(Vector2(-5, -2), 3.0, Color(1, 1, 1))
	draw_circle(Vector2(5, -2), 3.0, Color(1, 1, 1))
	draw_circle(Vector2(-5, -2), 1.5, Color(0.1, 0.05, 0.1))
	draw_circle(Vector2(5, -2), 1.5, Color(0.1, 0.05, 0.1))
