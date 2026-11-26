extends StaticBody2D

# Caja de la «Lluvia de cajas». Tiene tres momentos:
#   1. AVISO: un círculo rojo con «!» en el piso. No tiene colisión, no estorba.
#   2. CAE: se revisa quién está debajo.
#        - Si está el jugador: le hace daño y la caja SE ROMPE (no lo encierra ni lo empuja).
#        - Si está el Capataz: también se rompe (así el jefe nunca queda atrapado dentro).
#        - Si no hay nadie: se queda en el piso como OBSTÁCULO.
#   3. OBSTÁCULO: bloquea el paso del jugador, de los zombis y del Capataz,
#      hasta que el jefe tire cajas nuevas (él mismo las borra).
# El cuerpo físico y su forma se crean por código para no escribir un .tscn a mano.

const LADO = 76.0            # mismo tamaño que las cajas del mapa
const RADIO_AVISO = 46.0
const RADIO_JUGADOR = 18.0
const TIEMPO_ROTA = 0.35     # cuánto se ven los pedazos antes de desaparecer

var aviso = 1.0   # segundos entre la marca y la caída (el jefe lo pone)
var dano = 15.0   # vida que quita si cae encima (el jefe lo pone)
var t = 0.0
var cayo = false
var rota = false  # true = le cayó a alguien y se rompió
var t_rota = 0.0

func _ready():
	# Sin colisión mientras avisa; se activa al caer (solo si no le cayó a nadie)
	collision_layer = 0
	collision_mask = 0
	# oleadas.gd y el jefe buscan un hijo llamado "Colision" con la forma del obstáculo
	var col = CollisionShape2D.new()
	col.name = "Colision"
	var forma = RectangleShape2D.new()
	forma.size = Vector2(LADO, LADO)
	col.shape = forma
	add_child(col)
	# Mientras avisa va en "franjas": si el jefe muere, la marca se borra sola
	add_to_group("franjas")

func _process(delta):
	t += delta
	if not cayo and t >= aviso:
		caer()
	if rota:
		t_rota += delta
		if t_rota >= TIEMPO_ROTA:
			queue_free()   # ya se vieron los pedazos: se borra
	queue_redraw()

# El Capataz la rompe cuando se le atraviesa mientras escapa
func romper():
	if rota or not cayo:
		return
	rota = true
	t_rota = 0.0
	remove_from_group("rebotables")
	collision_layer = 0
	Fx.chispas(global_position, Color(0.75, 0.52, 0.3), 14, 220.0, 0.45, 5.0)
	Fx.texto_flotante(global_position + Vector2(0, -40), "¡CRASH!", Color(1, 0.8, 0.4), 20)
	Fx.sonar("crash")
	Fx.temblor(4.0, 0.12)

# ¿Hay algo redondo (de ese radio) debajo de la caja?
func esta_debajo(pos, radio):
	var d = pos - global_position
	return abs(d.x) <= LADO / 2.0 + radio and abs(d.y) <= LADO / 2.0 + radio

func caer():
	cayo = true
	Fx.sonar("crash", 0.7, -8.0)   # golpe seco al caer
	Fx.polvo(global_position + Vector2(0, 30))
	var golpeo = false
	# 1) ¿le cayó al jugador? Daño y la caja se rompe
	var jug = get_parent().get_node("Jugador")
	if esta_debajo(jug.global_position, RADIO_JUGADOR):
		jug.vida -= dano
		golpeo = true
	# 2) ¿le cayó al jefe? No le hace daño, pero se rompe para no encerrarlo
	for j in get_tree().get_nodes_in_group("jefe"):
		if esta_debajo(j.global_position, j.radio_choque):
			golpeo = true
	# 3) los zombis que queden debajo se aplastan (no suman a «Liberados»)
	for z in get_tree().get_nodes_in_group("zombis"):
		if esta_debajo(z.global_position, 20.0):
			z.queue_free()
	if golpeo:
		rota = true    # se queda en "franjas" y sin colisión: solo muestra los pedazos
		return
	# 4) no le cayó a nadie: ahora sí es un obstáculo de verdad
	remove_from_group("franjas")
	add_to_group("rebotables")
	collision_layer = 4   # capa 3 «obstaculos» (su valor en bits es 4)

const SPRITE = preload("res://zona_3/assets/caja.png")
const CAIDA = 0.3   # los últimos 0,3 s del aviso se ve la caja cayendo desde arriba

func _draw():
	if not cayo:
		# aviso: círculo rojo que late
		var pulso = 0.25 + 0.15 * sin(t * 12.0)
		draw_circle(Vector2.ZERO, RADIO_AVISO, Color(0.9, 0.15, 0.15, pulso))
		draw_arc(Vector2.ZERO, RADIO_AVISO, 0.0, TAU, 32, Color(1, 0.3, 0.3, 0.8), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(-8, 10), "!", HORIZONTAL_ALIGNMENT_CENTER, 16, 30, Color(1, 0.4, 0.4))
		var falta = aviso - t
		if falta < CAIDA:
			# la caja viene cayendo: la sombra crece y la caja baja
			var u = 1.0 - falta / CAIDA
			draw_circle(Vector2(0, 6), 38.0 * u, Color(0, 0, 0, 0.35 * u))
			draw_texture(SPRITE, Vector2(-48, -48 - 260.0 * (1.0 - u) * (1.0 - u)))
	elif rota:
		# caja rota: cuatro pedazos de cartón que se separan y se van borrando
		var avance = t_rota / TIEMPO_ROTA
		var alfa = 1.0 - avance
		for esquina in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var centro = esquina * (20.0 + 30.0 * avance)
			draw_set_transform(centro, esquina.x * avance * 1.2, Vector2.ONE)
			draw_rect(Rect2(Vector2(-16, -16), Vector2(32, 32)), Color(0.72, 0.5, 0.28, alfa))
			draw_rect(Rect2(Vector2(-16, -16), Vector2(32, 32)), Color(0.1, 0.07, 0.1, alfa), false, 2.0)
			draw_rect(Rect2(Vector2(-4, -16), Vector2(8, 32)), Color(0.88, 0.78, 0.59, alfa))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		# caja entera en el piso (mismo dibujo que las cajas del mapa)
		draw_texture(SPRITE, Vector2(-48, -48))
