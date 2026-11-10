extends Node2D

# «Reflejo»: una sombra que copia los movimientos del jugador con 1 s de retraso.
# Tocarla duele. Para el retraso guarda las posiciones del jugador en una COLA (Lista):
#   - cada 0,05 s se hace agregar_final(posición del jugador)
#   - cuando la cola tiene más de "retraso / 0,05" posiciones, se hace quitar_primero()
#     y esa posición (de hace 1 s) es donde se pone el reflejo.
# Va en el grupo "franjas" (si el jefe se aturde, el reflejo desaparece).
const ROBOT = preload("res://zona_4/jefe/robot.gd")
const PASO_MUESTRA = 0.05    # cada cuánto se guarda una posición
const RADIO = 24.0
const RADIO_JUGADOR = 20.0
const ENFRIA_GOLPE = 0.8     # segundos entre un golpe y el siguiente
const EMPUJE = 120.0

var retraso = 1.0      # segundos de atraso (el jefe lo pone)
var dano = 12.0        # vida que quita al tocarlo (el jefe lo pone)
var duracion = 8.0     # segundos que dura (el jefe lo pone)
var historial = Lista.new()
var t = 0.0
var t_muestra = 0.0
var t_golpe = 0.0
var listo = false      # true cuando ya hay historial suficiente

func _ready():
	add_to_group("franjas")
	visible = false   # no se ve hasta tener historial (pasa 1 s)

func _process(delta):
	t += delta
	t_golpe -= delta
	t_muestra -= delta
	var jug = get_parent().get_node("Jugador")
	if t_muestra <= 0.0:
		t_muestra = PASO_MUESTRA
		historial.agregar_final(jug.global_position)
	var necesarias = int(retraso / PASO_MUESTRA)
	if historial.tam > necesarias:
		global_position = historial.quitar_primero()   # dónde estaba el jugador hace "retraso" s
		listo = true
		visible = true
	# tocarlo duele (con un respiro entre golpes)
	if listo and t_golpe <= 0.0 and global_position.distance_to(jug.global_position) <= RADIO + RADIO_JUGADOR:
		t_golpe = ENFRIA_GOLPE
		jug.vida -= dano
		jug.empujar((jug.global_position - global_position).normalized() * EMPUJE)
	if t >= duracion:
		queue_free()
	queue_redraw()

func _draw():
	# se ve como un jugador fantasma magenta
	var icono = preload("res://icon.svg")
	var lado = 128.0 * 0.4
	draw_texture_rect(icono, Rect2(Vector2(-lado, -lado) / 2.0, Vector2(lado, lado)), false, Color(1, 0.3, 0.8, 0.6))
	draw_arc(Vector2.ZERO, RADIO, 0.0, TAU, 24, Color(1, 0.3, 0.8, 0.9), 3.0)
