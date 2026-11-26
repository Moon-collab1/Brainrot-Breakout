extends Node2D

# Franja vertical del "Directo en vivo". Va en el grupo "franjas" (NO en "proyectiles":
# la cachetada no la destruye). La crea el jefe en el aviso y la activa después.
const ALTO = 648.0   # de borde a borde del mapa

var ancho = 90.0       # los pone el jefe (DIRECTO_ANCHO y DIRECTO_DOPA)
var dopa_seg = 15.0
var activa = false     # false = aviso (no hace daño)
var t = 0.0

func activar():
	activa = true

func _process(delta):
	t += delta
	if activa:
		var jug = get_parent().get_node("Jugador")
		# position.x es el centro de la franja
		if abs(jug.global_position.x - global_position.x) <= ancho / 2.0:
			jug.dopa += dopa_seg * delta
	queue_redraw()

# Placeholder dibujado: reemplazar por el sprite real de la franja
func _draw():
	var rect = Rect2(-ancho / 2.0, 0.0, ancho, ALTO)
	if activa:
		var alfa = 0.35 + 0.1 * sin(t * 8.0)   # late un poco mientras está activa
		draw_rect(rect, Color(1, 0.1, 0.4, alfa))
		draw_rect(rect, Color(1, 0.4, 0.6, 0.9), false, 3.0)
	else:
		draw_rect(rect, Color(1, 0.1, 0.4, 0.12))
		draw_rect(rect, Color(1, 0.4, 0.6, 0.5), false, 2.0)
