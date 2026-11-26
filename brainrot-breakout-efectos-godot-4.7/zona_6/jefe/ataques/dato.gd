extends Node2D

# Dato («0» o «1») de la «Tormenta de datos». Cae o vuela en línea recta formando patrones.
# Grupos: "destruibles" (la cachetada lo revienta, sin sumar a «Liberados») y "proyectiles"
# (si el jefe se aturde, se borra). Sin física: mide la distancia al jugador.
const RADIO = 12.0
const RADIO_JUGADOR = 20.0
const FUERA = 60.0

var vel = Vector2(0, 200)   # el jefe lo pone
var dano = 5.0              # vida al tocar al jugador (el jefe lo pone)
var dopa = 4.0              # dopamina al tocar (el jefe lo pone)
var texto = "1"

func _ready():
	add_to_group("destruibles")
	add_to_group("proyectiles")

func _process(delta):
	global_position += vel * delta
	var jug = get_parent().get_node("Jugador")
	if global_position.distance_to(jug.global_position) <= RADIO + RADIO_JUGADOR:
		jug.vida -= dano
		jug.dopa += dopa
		queue_free()
		return
	var p = global_position
	if p.x < -FUERA or p.x > 1152 + FUERA or p.y < -FUERA or p.y > 648 + FUERA:
		queue_free()
		return
	queue_redraw()

# La llama jugador.dar_cachetada()
func reventar():
	queue_free()

# Placeholder dibujado: reemplazar por el sprite real del dato
func _draw():
	draw_circle(Vector2.ZERO, RADIO, Color(0.05, 0.12, 0.25, 0.9))
	draw_arc(Vector2.ZERO, RADIO, 0.0, TAU, 20, Color(0.3, 1, 0.6), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-6, 6), texto, HORIZONTAL_ALIGNMENT_CENTER, 12, 18, Color(0.5, 1, 0.7))
