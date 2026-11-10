extends Node2D

# Charco verde de la «Nube tóxica». Va en el grupo "franjas" (si el jefe se aturde, se borra).
# Sin física: mide la distancia al jugador cada frame.
# Primero un aviso tenue (sin efecto); luego activo: sube la dopamina sin parar mientras
# el jugador esté dentro; se apaga solo a los "duracion" segundos.
var radio = 60.0       # el jefe lo pone
var dopa_seg = 10.0    # dopamina por segundo dentro (el jefe lo pone)
var aviso = 0.6        # segundos de aviso antes de activarse (el jefe lo pone)
var duracion = 8.0     # segundos que dura ya activo (el jefe lo pone)
var t = 0.0

func activo():
	return t >= aviso

func _ready():
	add_to_group("franjas")

func _process(delta):
	t += delta
	if activo():
		var jug = get_parent().get_node("Jugador")
		if jug.global_position.distance_to(global_position) <= radio:
			jug.dopa += dopa_seg * delta
	if t >= aviso + duracion:
		queue_free()
	queue_redraw()

# Placeholder dibujado: reemplazar por el sprite real del charco
func _draw():
	if activo():
		var alfa = 0.35 + 0.08 * sin(t * 5.0)
		draw_circle(Vector2.ZERO, radio, Color(0.25, 0.85, 0.35, alfa))
		draw_arc(Vector2.ZERO, radio, 0.0, TAU, 40, Color(0.3, 1, 0.45, 0.9), 3.0)
	else:
		draw_circle(Vector2.ZERO, radio, Color(0.25, 0.85, 0.35, 0.1))
		for i in range(20):
			var a = TAU * i / 20.0
			draw_arc(Vector2.ZERO, radio, a, a + TAU / 40.0, 4, Color(0.4, 1, 0.5, 0.8), 3.0)
