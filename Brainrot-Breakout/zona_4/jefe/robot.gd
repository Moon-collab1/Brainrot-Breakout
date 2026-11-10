extends RefCounted

# Dibujo placeholder del robot gemelo. Lo comparten el jefe real, los clones falsos y
# el reflejo, así los cuatro se ven iguales y solo cambia el color.
# Es una función "static": se llama así -> ROBOT.dibujar(self, color, alfa, aturdido)
# desde el _draw() del nodo que quiere dibujarse. Reemplazar por el PNG real del Gemelo.

static func dibujar(nodo, tono, alfa, aturdido):
	var cuerpo = Color(0.05, 0.1, 0.22, alfa)
	var borde = Color(tono.r, tono.g, tono.b, alfa)
	var visor = Color(tono.r, tono.g, tono.b, alfa)
	if aturdido:
		visor = Color(0.4, 0.4, 0.45, alfa)   # visor apagado: desincronizado
	# cuerpo
	nodo.draw_rect(Rect2(-40, -30, 80, 90), cuerpo)
	nodo.draw_rect(Rect2(-40, -30, 80, 90), borde, false, 4.0)
	nodo.draw_rect(Rect2(-40, -5, 80, 8), Color(1, 0.2, 0.7, alfa))
	nodo.draw_rect(Rect2(-60, -2, 120, 5), borde)
	# cabeza y visor
	nodo.draw_circle(Vector2(0, -58), 32.0, cuerpo)
	nodo.draw_arc(Vector2(0, -58), 32.0, 0.0, TAU, 32, borde, 4.0)
	nodo.draw_rect(Rect2(-24, -68, 48, 18), visor)
	nodo.draw_rect(Rect2(-14, -63, 8, 8), Color(0.05, 0.1, 0.22, alfa))
	nodo.draw_rect(Rect2(6, -63, 8, 8), Color(0.05, 0.1, 0.22, alfa))
	# base (sombra)
	nodo.draw_arc(Vector2(0, 66), 36.0, 0.0, TAU, 24, Color(0, 0, 0, alfa * 0.5), 6.0)
