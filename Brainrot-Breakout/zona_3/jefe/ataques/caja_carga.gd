extends StaticBody2D

# Caja de la «Lluvia de cajas». Tiene dos momentos:
#   1. AVISO: un círculo rojo con «!» en el piso (sin colisión, no estorba).
#   2. CAE: daña si el jugador está debajo y se queda como OBSTÁCULO (rebota ataques,
#      bloquea el paso y hace que el Capataz se aturda si embiste contra ella).
# El cuerpo físico y su forma se crean por código para no escribir un .tscn a mano.

const LADO = 76.0          # mismo tamaño que las cajas del mapa
const RADIO_AVISO = 46.0
const RADIO_JUGADOR = 18.0

var aviso = 1.0   # segundos entre la marca y la caída (el jefe lo pone)
var dano = 15.0   # vida que quita si cae encima (el jefe lo pone)
var t = 0.0
var cayo = false

func _ready():
	# Sin colisión mientras avisa; se activa al caer
	collision_layer = 0
	collision_mask = 0
	# oleadas.gd y el jefe buscan un hijo llamado "Colision" con la forma del obstáculo
	var col = CollisionShape2D.new()
	col.name = "Colision"
	var forma = RectangleShape2D.new()
	forma.size = Vector2(LADO, LADO)
	col.shape = forma
	add_child(col)
	# Mientras avisa va en "franjas": si el jefe se aturde, la marca se borra
	add_to_group("franjas")

func _process(delta):
	t += delta
	if not cayo and t >= aviso:
		caer()
	queue_redraw()

func caer():
	cayo = true
	var jug = get_parent().get_node("Jugador")
	var mitad = LADO / 2.0 + RADIO_JUGADOR
	var d = jug.global_position - global_position
	# ¿está el jugador debajo de la caja?
	if abs(d.x) <= mitad and abs(d.y) <= mitad:
		jug.vida -= dano
		# se saca al jugador por el lado más cercano para que no quede atrapado dentro
		if abs(d.x) > abs(d.y):
			var signo = 1.0
			if d.x < 0.0:
				signo = -1.0
			jug.global_position.x = global_position.x + signo * (mitad + 2.0)
		else:
			var signo = 1.0
			if d.y < 0.0:
				signo = -1.0
			jug.global_position.y = global_position.y + signo * (mitad + 2.0)
	# los zombis que queden debajo se aplastan (no suman a «Liberados»)
	for z in get_tree().get_nodes_in_group("zombis"):
		var dz = z.global_position - global_position
		if abs(dz.x) <= LADO / 2.0 + 20.0 and abs(dz.y) <= LADO / 2.0 + 20.0:
			z.queue_free()
	# ahora es un obstáculo de verdad: capa 4 (obstáculos) y grupo "rebotables"
	remove_from_group("franjas")
	add_to_group("rebotables")
	collision_layer = 4

# Placeholder dibujado: reemplazar por el sprite real de la caja
func _draw():
	if not cayo:
		var pulso = 0.25 + 0.15 * sin(t * 12.0)
		draw_circle(Vector2.ZERO, RADIO_AVISO, Color(0.9, 0.15, 0.15, pulso))
		draw_arc(Vector2.ZERO, RADIO_AVISO, 0.0, TAU, 32, Color(1, 0.3, 0.3, 0.8), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(-8, 10), "!", HORIZONTAL_ALIGNMENT_CENTER, 16, 30, Color(1, 0.4, 0.4))
	else:
		var color = Color(0.62, 0.42, 0.22)
		draw_rect(Rect2(-40, -40, 80, 80), color)
		draw_rect(Rect2(-40, -40, 80, 80), color.darkened(0.35), false, 3.0)
		draw_line(Vector2(-40, 0), Vector2(40, 0), color.darkened(0.35), 3.0)
		draw_line(Vector2(0, -40), Vector2(0, 40), color.darkened(0.35), 3.0)
