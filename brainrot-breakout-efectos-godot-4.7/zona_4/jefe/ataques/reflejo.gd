extends Node2D

# «Reflejo»: una perla mágica que copia los movimientos del jugador con 1 s de retraso.
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
		Fx.sonar("perla", 0.8)
	# tocarlo duele (con un respiro entre golpes)
	if listo and t_golpe <= 0.0 and global_position.distance_to(jug.global_position) <= RADIO + RADIO_JUGADOR:
		t_golpe = ENFRIA_GOLPE
		jug.vida -= dano
		jug.empujar((jug.global_position - global_position).normalized() * EMPUJE)
	if t >= duracion:
		queue_free()
	queue_redraw()

func _draw():
	# una perla mágica magenta que brilla y deja destellos
	var tt = Time.get_ticks_msec() / 1000.0
	var pulso = 0.5 + 0.5 * sin(tt * 6.0)
	draw_circle(Vector2.ZERO, RADIO + 10.0 + 4.0 * pulso, Color(1, 0.3, 0.8, 0.15))
	draw_circle(Vector2.ZERO, RADIO - 2.0, Color(0.85, 0.35, 0.75))
	draw_circle(Vector2(3, 4), RADIO - 8.0, Color(0.65, 0.2, 0.6))
	draw_circle(Vector2(-4, -5), RADIO - 12.0, Color(1, 0.6, 0.92))
	draw_circle(Vector2(-8, -9), 5.0, Color(1, 1, 1, 0.9))
	draw_circle(Vector2(6, 9), 2.5, Color(1, 1, 1, 0.5))
	for k in range(4):
		var a = tt * 2.0 + k * TAU / 4.0
		var p = Vector2.from_angle(a) * (RADIO + 12.0)
		draw_line(p + Vector2(-4, 0), p + Vector2(4, 0), Color(1, 0.8, 1, 0.8), 1.5)
		draw_line(p + Vector2(0, -4), p + Vector2(0, 4), Color(1, 0.8, 1, 0.8), 1.5)
	draw_arc(Vector2.ZERO, RADIO, 0.0, TAU, 24, Color(1, 0.3, 0.8, 0.9), 3.0)
