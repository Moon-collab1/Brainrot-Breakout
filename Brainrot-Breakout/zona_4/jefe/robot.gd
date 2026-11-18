extends RefCounted

# Dibujo placeholder del robot gemelo. Lo comparten el jefe real, los clones falsos y
# el reflejo, así los cuatro se ven iguales y solo cambia el color.
# Es una función "static": se llama así -> ROBOT.dibujar(self, color, alfa, aturdido)
# desde el _draw() del nodo que quiere dibujarse. Ahora usa el sprite assets/sprites/jefes/jefe_gemelo.png.

const HOJA = preload("res://comun/jefe/hoja_jefe.gd")
const SPRITE = preload("res://assets/sprites/jefes/jefe_gemelo.png")
const TAM = Vector2(170, 190)
const ORIGEN = Vector2(85, 98)

# 3 capas del mismo cuadro: fila 0 cuerpo (sin teñir), fila 1 bordes (color del robot), fila 2 visor
static func dibujar(nodo, tono, alfa, aturdido):
	var visor = Color(tono.r, tono.g, tono.b, alfa)
	if aturdido:
		visor = Color(0.4, 0.4, 0.45, alfa)   # visor apagado: desincronizado
	# base (sombra)
	nodo.draw_arc(Vector2(0, 66), 36.0, 0.0, TAU, 24, Color(0, 0, 0, alfa * 0.5), 6.0)
	HOJA.dibujar(nodo, SPRITE, 4, 0, TAM, ORIGEN, Color(1, 1, 1, alfa), 0.2)
	HOJA.dibujar(nodo, SPRITE, 4, 1, TAM, ORIGEN, Color(tono.r, tono.g, tono.b, alfa), 0.2)
	HOJA.dibujar(nodo, SPRITE, 4, 2, TAM, ORIGEN, visor, 0.2)
