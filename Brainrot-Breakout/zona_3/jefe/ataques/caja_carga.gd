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

# ¿Hay algo redondo (de ese radio) debajo de la caja?
func esta_debajo(pos, radio):
	var d = pos - global_position
	return abs(d.x) <= LADO / 2.0 + radio and abs(d.y) <= LADO / 2.0 + radio

func caer():
	cayo = true
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

# Placeholder dibujado: reemplazar por el sprite real de la caja
func _draw():
	var color = Color(0.62, 0.42, 0.22)
	if not cayo:
		# aviso: círculo rojo que late
		var pulso = 0.25 + 0.15 * sin(t * 12.0)
		draw_circle(Vector2.ZERO, RADIO_AVISO, Color(0.9, 0.15, 0.15, pulso))
		draw_arc(Vector2.ZERO, RADIO_AVISO, 0.0, TAU, 32, Color(1, 0.3, 0.3, 0.8), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(-8, 10), "!", HORIZONTAL_ALIGNMENT_CENTER, 16, 30, Color(1, 0.4, 0.4))
	elif rota:
		# caja rota: cuatro pedazos que se separan y se van borrando
		var avance = t_rota / TIEMPO_ROTA
		var alfa = 1.0 - avance
		for esquina in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var centro = esquina * (20.0 + 30.0 * avance)
			draw_rect(Rect2(centro - Vector2(16, 16), Vector2(32, 32)), Color(color.r, color.g, color.b, alfa))
	else:
		# caja entera en el piso
		draw_rect(Rect2(-40, -40, 80, 80), color)
		draw_rect(Rect2(-40, -40, 80, 80), color.darkened(0.35), false, 3.0)
		draw_line(Vector2(-40, 0), Vector2(40, 0), color.darkened(0.35), 3.0)
		draw_line(Vector2(0, -40), Vector2(0, 40), color.darkened(0.35), 3.0)
