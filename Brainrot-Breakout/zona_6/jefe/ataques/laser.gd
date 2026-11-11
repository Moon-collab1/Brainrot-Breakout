extends Node2D

# Línea láser de la «Rejilla láser». Va en el grupo "franjas" (si el jefe se aturde, se borra).
# Sin física: mide la distancia del jugador a la línea cada frame.
# Hay DOS clases de láser:
#   ROJO  (verde = false): hace daño al tocarlo. Es el peligroso.
#   VERDE (verde = true):  NO hace daño. Si el jugador lo toca, TODOS los rojos se vuelven
#                          verdes y dejan de hacer daño. Es la forma de esquivar la rejilla.
# El jefe siempre pone el verde en un lado de la pantalla distinto al de los rojos, y los
# rojos esperan más tiempo antes de moverse, para que alcances a tocar primero el verde.
#
# Cada láser tiene dos momentos:
#   1. AVISO: línea punteada y quieta en el borde. No hace daño (el verde sí se puede tocar ya).
#   2. ACTIVO: la línea brilla y BARRE la arena moviéndose hacia un lado.
# Una línea vertical está en x = position.x; una horizontal, en y = position.y.
const LARGO_X = 1152.0
const LARGO_Y = 648.0
const ESPESOR = 10.0           # ancho visual
const MARGEN_DANO = 14.0       # distancia a la línea que ya cuenta como tocar un rojo
const MARGEN_VERDE = 26.0      # el verde es más fácil de tocar que el rojo
const ENFRIA_GOLPE = 0.6       # segundos entre un golpe y el siguiente
const FUERA = 80.0             # cuánto se puede salir del mapa antes de borrarse
const TIEMPO_APAGADO = 0.7     # lo que tarda en desvanecerse un láser ya neutralizado
const COLOR_ROJO = Color(1.0, 0.2, 0.25)
const COLOR_VERDE = Color(0.3, 1.0, 0.45)

var vertical = true    # true = línea vertical (barre de lado a lado); false = horizontal
var verde = false      # true = es el láser verde que neutraliza a los rojos (el jefe lo pone)
var dir = 1.0          # 1 o -1: hacia dónde barre (el jefe lo pone)
var vel = 140.0        # px/s (el jefe lo pone)
var aviso = 1.0        # segundos quieto y punteado antes de barrer (el jefe lo pone)
var dano = 15.0        # vida por golpe, solo los rojos (el jefe lo pone)
var t = 0.0
var t_golpe = 0.0
var neutral = false    # true = ya no hace daño (un rojo neutralizado, o el verde ya usado)
var t_apagado = 0.0    # tiempo que lleva desvaneciéndose
var lado_antes = 0.0   # de qué lado de la línea estaba el jugador en el frame anterior (signo)

func activo():
	return t >= aviso

func _ready():
	add_to_group("franjas")
	if not verde:
		add_to_group("laser_rojo")   # el verde busca este grupo para neutralizarlos

# La llama el láser verde cuando el jugador lo toca: este rojo se vuelve verde e inofensivo
func neutralizar():
	neutral = true

func _process(delta):
	t += delta
	t_golpe -= delta
	# un láser neutralizado solo se desvanece y se borra
	if neutral:
		t_apagado += delta
		if t_apagado >= TIEMPO_APAGADO:
			queue_free()
		queue_redraw()
		return
	if activo():
		if vertical:
			position.x += dir * vel * delta
		else:
			position.y += dir * vel * delta
	# distancia del jugador a la línea (con signo: positivo de un lado, negativo del otro)
	var jug = get_parent().get_node("Jugador")
	var lado = 0.0
	if vertical:
		lado = jug.global_position.x - global_position.x
	else:
		lado = jug.global_position.y - global_position.y
	var d = abs(lado)
	# ¿la línea y el jugador se cruzaron entre el frame anterior y este? (cambió el signo)
	# Así el toque cuenta aunque los dos vayan muy rápido y «se salten» en un solo frame.
	var cruzo = lado_antes != 0.0 and lado != 0.0 and sign(lado) != sign(lado_antes)
	lado_antes = lado
	if verde:
		# el verde se puede tocar siempre (también mientras está quieto en el borde)
		if d <= MARGEN_VERDE or cruzo:
			for rojo in get_tree().get_nodes_in_group("laser_rojo"):
				rojo.neutralizar()
			neutral = true                 # el verde ya cumplió: también se desvanece
			MusicaGlobal.sonar_golpe()     # sonido para confirmar que lo tocaste
	elif activo() and (d <= MARGEN_DANO or cruzo) and t_golpe <= 0.0:
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
	# color: rojo si hace daño; verde si es el verde o si ya fue neutralizado
	var color = COLOR_ROJO
	if verde or neutral:
		color = COLOR_VERDE
	var alfa = 1.0
	if neutral:
		alfa = 1.0 - t_apagado / TIEMPO_APAGADO   # se va borrando
	if activo() or neutral:
		draw_line(a, b, Color(color.r, color.g, color.b, 0.35 * alfa), ESPESOR + 8.0)
		draw_line(a, b, Color(1, 1, 1, 0.9 * alfa), 3.0)
		draw_line(a, b, Color(color.r, color.g, color.b, alfa), ESPESOR - 4.0)
	else:
		# aviso: línea punteada (la verde parpadea para llamar la atención)
		var brillo = 0.7
		if verde:
			brillo = 0.6 + 0.4 * sin(t * 14.0)
		var largo = (b - a).length()
		var dir_l = (b - a).normalized()
		var s = 0.0
		while s < largo:
			draw_line(a + dir_l * s, a + dir_l * min(s + 14.0, largo), Color(color.r, color.g, color.b, brillo), 4.0 if verde else 3.0)
			s += 28.0
