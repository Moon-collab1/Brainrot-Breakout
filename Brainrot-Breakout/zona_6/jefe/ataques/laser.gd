extends Node2D

# Línea láser de la «Rejilla láser». Va en el grupo "franjas" (si el jefe se aturde, se borra).
# Sin física: mide la distancia del jugador a la línea cada frame.
#   1. AVISO: línea tenue y punteada (1 s) que no hace daño.
#   2. ACTIVO: la línea brilla y BARRE la arena moviéndose hacia un lado; daña al tocarla.
# Una línea vertical está en x = position.x; una horizontal, en y = position.y.
const LARGO_X = 1152.0
const LARGO_Y = 648.0
const ESPESOR = 10.0           # ancho visual
const MARGEN_DANO = 14.0       # distancia a la línea que ya cuenta como tocarla
const ENFRIA_GOLPE = 0.6       # segundos entre un golpe y el siguiente
const FUERA = 80.0             # cuánto se puede salir del mapa antes de borrarse

var vertical = true    # true = línea vertical (barre de lado a lado); false = horizontal
var color = Color(1.0, 0.25, 0.75)   # rosa o cian (el jefe lo pone)
var dir = 1.0          # 1 o -1: hacia dónde barre (el jefe lo pone)
var vel = 140.0        # px/s (el jefe lo pone)
var aviso = 1.0        # segundos de aviso (el jefe lo pone)
var dano = 15.0        # vida por golpe (el jefe lo pone)
var t = 0.0
var t_golpe = 0.0

func activo():
	return t >= aviso

func _ready():
	add_to_group("franjas")

func _process(delta):
	t += delta
	t_golpe -= delta
	if activo():
		if vertical:
			position.x += dir * vel * delta
		else:
			position.y += dir * vel * delta
		var jug = get_parent().get_node("Jugador")
		var d = 0.0
		if vertical:
			d = abs(jug.global_position.x - global_position.x)
		else:
			d = abs(jug.global_position.y - global_position.y)
		if d <= MARGEN_DANO and t_golpe <= 0.0:
			t_golpe = ENFRIA_GOLPE
			jug.vida -= dano
		# se borra al salir del mapa
		if position.x < -FUERA or position.x > LARGO_X + FUERA or position.y < -FUERA or position.y > LARGO_Y + FUERA:
			queue_free()
	queue_redraw()

# Placeholder dibujado: reemplazar por el sprite real del láser
func _draw():
	var a = Vector2.ZERO
	var b = Vector2.ZERO
	if vertical:
		a = Vector2(0, -global_position.y)
		b = Vector2(0, LARGO_Y - global_position.y)
	else:
		a = Vector2(-global_position.x, 0)
		b = Vector2(LARGO_X - global_position.x, 0)
	if activo():
		draw_line(a, b, Color(color.r, color.g, color.b, 0.35), ESPESOR + 8.0)
		draw_line(a, b, Color(1, 1, 1, 0.9), 3.0)
		draw_line(a, b, color, ESPESOR - 4.0)
	else:
		# aviso: línea punteada tenue
		var largo = (b - a).length()
		var dir_l = (b - a).normalized()
		var s = 0.0
		while s < largo:
			draw_line(a + dir_l * s, a + dir_l * min(s + 14.0, largo), Color(color.r, color.g, color.b, 0.7), 3.0)
			s += 28.0
