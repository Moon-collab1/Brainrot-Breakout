extends Node2D

signal vida_cambiada(valor, maximo)
signal murio

# --- Balance (se ajusta en la Parte 7) ---
const VIDA_MAX = 56
const FASE2_VIDA = 28            # fase 2 al bajar de este valor
const ANTENAS = [8, 8, 10, 10]   # vida de las antenas sucesivas
const ANTENA_REPETIDA = 10       # si se acaban, se repite este valor
const DANO_ANTENA = 4            # vida que pierde el jefe al romper una antena
const TIEMPO_INTRO = 2.0
const TIEMPO_ATURDIDO = 5.0
const PARPADEO_FINAL = 1.0
const ALCANCE_JUGADOR = 100.0    # igual a "alcance" de jugador.gd
const RADIO_CUERPO = 70.0
const RADIO_ANTENA = 25.0
# Posiciones de la antena: 0 arriba, 1 izquierda, 2 derecha
const POS_ANTENA = [Vector2(0, -95), Vector2(-95, 0), Vector2(95, 0)]
const COLOR_NORMAL = Color(1, 0.45, 0.8)
const COLOR_ATURDIDO = Color(0.5, 0.6, 1.0)

enum Estado { INTRO, ATACANDO, CAMBIANDO, ATURDIDO }

var vida = VIDA_MAX
var fase = 1
var estado = Estado.INTRO
var antena_vida = 0
var antenas = Lista.new()
var id_ataque = 0        # sube al cancelar; las corrutinas de ataque lo comparan tras cada await
var muerto = false
var tw_aviso = null
var tw_parpadeo = null

@onready var antena = $Antena

func _ready():
	add_to_group("jefe")
	for v in ANTENAS:
		antenas.agregar_final(v)
	nueva_antena()
	vida_cambiada.emit(vida, VIDA_MAX)
	# aparece con un fundido durante la intro
	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.0)
	$TimerEstado.timeout.connect(_al_terminar_estado)
	cambiar_estado(Estado.INTRO)

# El aro del jefe (se reemplaza por el sprite real)
func _draw():
	draw_arc(Vector2.ZERO, RADIO_CUERPO, 0.0, TAU, 48, Color(1, 0.9, 0.3), 4.0)

# ---------------- Estados ----------------

func cambiar_estado(nuevo):
	estado = nuevo
	$TimerEstado.stop()
	detener_parpadeo()
	$Sprite2D.modulate = COLOR_NORMAL
	if nuevo == Estado.INTRO:
		$TimerEstado.start(TIEMPO_INTRO)
	elif nuevo == Estado.ATURDIDO:
		$Sprite2D.modulate = COLOR_ATURDIDO
		$TimerEstado.start(TIEMPO_ATURDIDO)
		# el último segundo parpadea la antena nueva
		tw_aviso = create_tween()
		tw_aviso.tween_interval(TIEMPO_ATURDIDO - PARPADEO_FINAL)
		tw_aviso.tween_callback(parpadear_antena)
	print("Jefe: ", Estado.keys()[nuevo])

func _al_terminar_estado():
	if estado == Estado.INTRO or estado == Estado.ATURDIDO:
		cambiar_estado(Estado.ATACANDO)   # Parte 5: aquí arranca la cola de ataques

func aturdir():
	id_ataque += 1          # cancela el ataque en curso
	limpiar_ataques()
	cambiar_estado(Estado.ATURDIDO)

func limpiar_ataques():
	# get_nodes_in_group devuelve una copia, es seguro liberar dentro del bucle
	for p in get_tree().get_nodes_in_group("proyectiles"):
		p.queue_free()
	for f in get_tree().get_nodes_in_group("franjas"):
		f.queue_free()
	# los zombis NO se borran

# ---------------- Antena ----------------

func nueva_antena():
	var v = antenas.quitar_primero()
	if v == null:
		v = ANTENA_REPETIDA
	antena_vida = v
	if fase == 2:
		antena.position = POS_ANTENA[randi() % 3]
	else:
		antena.position = POS_ANTENA[0]
	mostrar_antena(true)

func mostrar_antena(valor):
	antena.visible = valor
	$Antena/Forma.set_deferred("disabled", not valor)

func parpadear_antena():
	tw_parpadeo = create_tween()
	tw_parpadeo.set_loops(5)   # 5 x 0,2 s = 1 s
	tw_parpadeo.tween_property(antena, "modulate:a", 0.2, 0.1)
	tw_parpadeo.tween_property(antena, "modulate:a", 1.0, 0.1)

func detener_parpadeo():
	if tw_aviso != null and tw_aviso.is_valid():
		tw_aviso.kill()
	if tw_parpadeo != null and tw_parpadeo.is_valid():
		tw_parpadeo.kill()
	antena.modulate.a = 1.0

# ---------------- Daño ----------------

# pos = posición del jugador al dar la cachetada
func recibir_golpe(pos):
	if muerto or estado == Estado.INTRO or estado == Estado.CAMBIANDO:
		return
	var en_cuerpo = pos.distance_to(global_position) <= ALCANCE_JUGADOR + RADIO_CUERPO
	var en_antena = antena.visible and pos.distance_to(antena.global_position) <= ALCANCE_JUGADOR + RADIO_ANTENA
	if estado == Estado.ATURDIDO:
		if en_cuerpo or en_antena:
			quitar_vida(1)
	elif en_antena:
		golpear_antena()
	# si solo alcanza el cuerpo estando bloqueado: no pasa nada

func golpear_antena():
	antena_vida -= 1
	if antena_vida <= 0:
		romper_antena()

func romper_antena():
	quitar_vida(DANO_ANTENA)
	if muerto:
		return
	aturdir()
	nueva_antena()   # la antena nueva ya está, pero no cuenta hasta que termine el aturdimiento

func quitar_vida(n):
	vida = max(vida - n, 0)
	vida_cambiada.emit(vida, VIDA_MAX)
	if vida <= 0:
		morir()
	elif fase == 1 and vida < FASE2_VIDA:
		entrar_fase_2()

func entrar_fase_2():
	fase = 2
	antena.position = POS_ANTENA[randi() % 3]   # la antena actual se reubica
	print("Jefe: FASE 2")   # Parte 5: aquí entra "Directo en vivo" a la cola

func morir():
	muerto = true
	murio.emit()
	queue_free()

# ---------------- Teclas de debug (borrar al final) ----------------

func _unhandled_input(event):
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			aturdir()
		elif event.keycode == KEY_F4 and fase == 1:
			quitar_vida(vida - FASE2_VIDA + 1)
		elif event.keycode == KEY_F6:
			recibir_golpe(antena.global_position)   # golpe de prueba a la antena
		elif event.keycode == KEY_F7:
			recibir_golpe(global_position)          # golpe de prueba al cuerpo
