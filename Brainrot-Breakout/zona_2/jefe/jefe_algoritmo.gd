extends Node2D

# Jefe de la Zona 2 «El Algoritmo» (Parte 2: base sin ataques).
# Referencia de patrones: zona_1/jefe/jefe_influencer.gd (no depende de él).

signal vida_cambiada(valor, maximo)
signal murio

# --- Balance (todo se ajusta aquí) ---
const VIDA_MAX = 60
const FASE2_VIDA = 30            # fase 2 al bajar de este valor
const RADIO_CUERPO = 100.0
const DANO_CONTACTO = 25.0       # vida por segundo dentro del cuerpo
const ALCANCE_JUGADOR = 100.0    # igual a "alcance" de jugador.gd
const TIEMPO_INTRO = 2.0
const TIEMPO_ATURDIDO = 5.0
const PARPADEO_FINAL = 1.0       # el último segundo parpadean las insignias nuevas
# Insignias de notificación (su vida = golpes que le faltan)
const RADIO_ORBITA = 140.0
const RADIO_INSIGNIA = 22.0
const VEL_ORBITA = 40.0          # grados por segundo
const MULT_ORBITA_F2 = 1.6       # fase 2: giran más rápido
const DANO_INSIGNIA = 1          # vida del jefe al reventar una insignia
const DANO_ATURDIDO = 1          # vida del jefe por cachetada estando aturdido
const TANDAS = [[3, 4, 5], [3, 4, 5], [4, 5, 6]]
const TANDA_REPETIDA = [4, 5, 6] # cuando se acaban las tandas
const ALFA_ESPERA = 0.3          # alfa de las insignias nuevas mientras no cuentan
# Visual (placeholder)
const COLOR_NORMAL = Color(0.42, 0.36, 0.88)
const COLOR_ATURDIDO = Color(0.5, 0.6, 1.0)
const COLOR_OJO = Color(1, 0.25, 0.4)
const COLOR_SALMON = Color(1, 0.55, 0.5)
const RADIO_DIBUJO = 108.0       # el orbe visual es un poco más grande que el cuerpo

enum Estado { INTRO, ATACANDO, CAMBIANDO, ATURDIDO }

# Insignia: círculo rojo con los golpes que le faltan (se reemplaza por sprite real)
class Insignia extends Node2D:
	var vida = 0
	var ang = 0.0          # ángulo actual de su órbita (radianes)
	var radio = 22.0
	var etiqueta = null

	func _ready():
		etiqueta = Label.new()
		etiqueta.size = Vector2(44, 44)
		etiqueta.position = Vector2(-22, -22)
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		etiqueta.add_theme_font_size_override("font_size", 18)
		add_child(etiqueta)
		poner_vida(vida)

	func poner_vida(v):
		vida = v
		if etiqueta != null:
			etiqueta.text = str(v)

	func _draw():
		draw_circle(Vector2.ZERO, radio, Color(1, 0.17, 0.3))
		draw_arc(Vector2.ZERO, radio, 0.0, TAU, 32, Color(1, 0.7, 0.75), 2.0)

var vida = VIDA_MAX
var fase = 1
var estado = Estado.INTRO
var muerto = false
var id_ataque = 0          # sube al cancelar; las corrutinas de ataque lo comparan tras cada await
var en_aviso = false       # true mientras un ataque muestra su aviso
var t_pelea = 0.0          # duración de la pelea (F5)
var vel_orbita = deg_to_rad(VEL_ORBITA)
var tandas = Lista.new()   # tandas de vida de las insignias
var insignias = []         # insignias vivas
var tw_intro = null

@onready var jug = get_parent().get_node("Jugador")
@onready var etiqueta_nombre = $NombreAtaque

func _ready():
	add_to_group("jefe")
	for t in TANDAS:
		tandas.agregar_final(t)
	etiqueta_nombre.position = Vector2(-160, 160)
	etiqueta_nombre.size = Vector2(320, 24)
	etiqueta_nombre.visible = false
	nueva_tanda(-PI / 2.0)
	vida_cambiada.emit(vida, VIDA_MAX)
	# aparece con un fundido durante la intro
	modulate.a = 0.0
	tw_intro = create_tween()
	tw_intro.tween_property(self, "modulate:a", 1.0, 1.0)
	$TimerEstado.timeout.connect(_al_terminar_estado)
	cambiar_estado(Estado.INTRO)

func _process(delta):
	if muerto:
		return
	t_pelea += delta
	orbitar(delta)
	dano_contacto(delta)
	queue_redraw()

# ---------------- Dibujo placeholder ----------------

func _draw():
	var aturdido = estado == Estado.ATURDIDO
	var tono = COLOR_NORMAL
	if aturdido:
		tono = COLOR_ATURDIDO
	var t = Time.get_ticks_msec() / 1000.0
	# 3 tentáculos curvos debajo (llegan a y = +150)
	for i in range(3):
		var x0 = -55.0 + 55.0 * i
		var pts = PackedVector2Array()
		for k in range(11):
			var f = k / 10.0
			pts.append(Vector2(x0 + sin(t * 2.5 + i * 2.0 + f * 4.0) * 14.0 * f, 60.0 + f * 90.0))
		draw_polyline(pts, tono.darkened(0.2), 12.0, true)
	# orbe con aro claro
	draw_circle(Vector2.ZERO, RADIO_DIBUJO, tono)
	draw_arc(Vector2.ZERO, RADIO_DIBUJO, 0.0, TAU, 64, tono.lightened(0.45), 5.0)
	var ojo = Vector2(0, -6)
	if aturdido:
		# ojo cerrado (párpado) y pupila de «cargando»
		draw_set_transform(ojo, 0.0, Vector2(1.0, 0.12))
		draw_circle(Vector2.ZERO, 52.0, Color(0.9, 0.9, 0.95))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_line(ojo + Vector2(-54, 0), ojo + Vector2(54, 0), Color(0.1, 0.1, 0.2), 6.0)
		draw_arc(ojo, 20.0, t * 7.0, t * 7.0 + PI * 1.5, 24, Color(1, 1, 1), 5.0)
	else:
		# ojo abierto: el iris sigue un poco al jugador
		draw_set_transform(ojo, 0.0, Vector2(1.0, 0.7))
		draw_circle(Vector2.ZERO, 54.0, Color(1, 1, 1))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var d = jug.global_position - global_position
		var iris = ojo + d.normalized() * min(d.length() / 20.0, 14.0)
		draw_circle(iris, 26.0, COLOR_OJO)
		draw_circle(iris, 11.0, Color(0.1, 0.05, 0.15))

# ---------------- Estados ----------------

func cambiar_estado(nuevo):
	estado = nuevo
	$TimerEstado.stop()
	if nuevo == Estado.INTRO:
		$TimerEstado.start(TIEMPO_INTRO)
	elif nuevo == Estado.ATURDIDO:
		$TimerEstado.start(TIEMPO_ATURDIDO)
	print("Jefe: ", Estado.keys()[nuevo])

func _al_terminar_estado():
	if estado == Estado.INTRO or estado == Estado.ATURDIDO:
		cambiar_estado(Estado.ATACANDO)
		iniciar_ataques()

# «Visto»: cancela el ataque en curso y limpia el piso. Los zombis se quedan.
func aturdir():
	id_ataque += 1
	en_aviso = false
	ocultar_nombre()
	limpiar_ataques()
	if insignias.is_empty():
		nueva_tanda()   # las nuevas ya existen, pero no cuentan hasta que termine
	cambiar_estado(Estado.ATURDIDO)

func limpiar_ataques():
	# get_nodes_in_group devuelve una copia, es seguro liberar dentro del bucle
	for p in get_tree().get_nodes_in_group("proyectiles"):
		p.queue_free()
	for f in get_tree().get_nodes_in_group("franjas"):
		f.queue_free()
	get_parent().get_node("HUD").mostrar_banner(false)   # por si estaba el aviso de Suscriptores
	# los zombis NO se borran

# Aquí arrancará la cola de ataques (Parte 4). Por ahora el jefe se queda quieto.
func iniciar_ataques(_directo = false):
	id_ataque += 1
	en_aviso = false

# Espera sin usar el árbol global: si el jefe se libera, la corrutina simplemente no continúa
func esperar(seg):
	var t = Timer.new()
	t.one_shot = true
	add_child(t)
	t.start(seg)
	await t.timeout
	t.queue_free()

# ---------------- Nombre del ataque ----------------

func mostrar_nombre(texto):
	etiqueta_nombre.text = texto.to_upper() + " ◂"
	etiqueta_nombre.visible = true

func ocultar_nombre():
	etiqueta_nombre.visible = false

# ---------------- Insignias ----------------

# Crea 3 insignias separadas 120° con la siguiente tanda de vidas
func nueva_tanda(ang_inicio = null):
	var t = tandas.quitar_primero()
	if t == null:
		t = TANDA_REPETIDA
	if ang_inicio == null:
		ang_inicio = randf() * TAU   # las tandas siguientes empiezan en un ángulo al azar
	for i in range(3):
		var ins = Insignia.new()
		ins.vida = t[i]
		ins.radio = RADIO_INSIGNIA
		ins.ang = ang_inicio + TAU * i / 3.0
		add_child(ins)
		insignias.append(ins)
	posicionar_insignias()

func orbitar(delta):
	for ins in insignias:
		ins.ang += vel_orbita * delta
	posicionar_insignias()
	# las nuevas insignias se ven tenues mientras no cuentan; parpadean al final del aturdimiento
	var alfa = 1.0
	if estado == Estado.ATURDIDO:
		alfa = ALFA_ESPERA
		var falta = $TimerEstado.time_left
		if falta <= PARPADEO_FINAL and fmod(falta, 0.2) < 0.1:
			alfa = 1.0
	for ins in insignias:
		ins.modulate.a = alfa

func posicionar_insignias():
	for ins in insignias:
		ins.global_position = global_position + Vector2.from_angle(ins.ang) * RADIO_ORBITA

func reventar_insignia(ins):
	insignias.erase(ins)
	ins.queue_free()
	quitar_vida(DANO_INSIGNIA)
	if muerto:
		return
	if insignias.is_empty():
		aturdir()   # la tercera insignia: «Visto»

# ---------------- Contacto ----------------

func dano_contacto(delta):
	if estado == Estado.INTRO or estado == Estado.CAMBIANDO:
		return
	if jug.global_position.distance_to(global_position) <= RADIO_CUERPO:
		jug.vida -= DANO_CONTACTO * delta

# ---------------- Daño ----------------

# pos = posición del jugador al dar la cachetada
func recibir_golpe(pos):
	if muerto or estado == Estado.INTRO or estado == Estado.CAMBIANDO:
		return
	if estado == Estado.ATURDIDO:
		# solo cuenta el cuerpo; las insignias nuevas todavía no
		if pos.distance_to(global_position) <= ALCANCE_JUGADOR + RADIO_CUERPO:
			quitar_vida(DANO_ATURDIDO)
		return
	# bloqueado: se golpea a la insignia más cercana de las que alcanza
	var mejor = null
	var mejor_d = ALCANCE_JUGADOR + RADIO_INSIGNIA
	for ins in insignias:
		var d = pos.distance_to(ins.global_position)
		if d <= mejor_d:
			mejor_d = d
			mejor = ins
	if mejor != null:
		mejor.poner_vida(mejor.vida - 1)
		if mejor.vida <= 0:
			reventar_insignia(mejor)
	# si solo alcanza el cuerpo estando bloqueado: no pasa nada

func quitar_vida(n):
	vida = max(vida - n, 0)
	vida_cambiada.emit(vida, VIDA_MAX)
	if vida <= 0:
		morir()
	elif fase == 1 and vida < FASE2_VIDA:
		entrar_fase_2()

func entrar_fase_2():
	fase = 2
	vel_orbita = deg_to_rad(VEL_ORBITA) * MULT_ORBITA_F2
	print("Jefe: FASE 2")

func morir():
	muerto = true
	print("Pelea terminada en ", snappedf(t_pelea, 0.1), " s")
	murio.emit()
	queue_free()

# ---------------- Teclas de debug (borrar al final) ----------------
# F1 (invocar al jefe) vive en comun/sistema/oleadas.gd

func _unhandled_input(event):
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			aturdir()
		elif event.keycode == KEY_F3:
			# provisional: muestra el nombre del ataque 2 s (el forzado real llega en la Parte 4)
			mostrar_nombre("Spam de notificaciones")
			await esperar(2.0)
			ocultar_nombre()
		elif event.keycode == KEY_F4 and fase == 1:
			quitar_vida(vida - FASE2_VIDA + 1)
		elif event.keycode == KEY_F5:
			print("Duración de la pelea: ", snappedf(t_pelea, 0.1), " s")
		elif event.keycode == KEY_F6:
			# golpe de prueba a la insignia más cercana al jugador
			if estado == Estado.ATACANDO and not insignias.is_empty():
				recibir_golpe(insignias[0].global_position)
		elif event.keycode == KEY_F7:
			recibir_golpe(global_position)   # golpe de prueba al cuerpo
		elif event.keycode == KEY_F8 or event.keycode == KEY_F9:
			print("Debug: cambio de set / Suscriptores llegan en la Parte 4")
		elif event.keycode == KEY_F10 and estado == Estado.ATACANDO:
			# revienta todas las insignias de golpe (copia: la lista cambia mientras se recorre)
			for ins in insignias.duplicate():
				if not muerto and is_instance_valid(ins):
					reventar_insignia(ins)
